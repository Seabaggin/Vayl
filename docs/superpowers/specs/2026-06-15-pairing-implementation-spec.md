# Pairing — Implementation Spec

**Date:** 2026-06-15
**Phase:** 1 of 6 — "the hinge" (Build Playbook: `docs/roadmap/vayl-build-roadmap.html`)
**Status:** Segments 1, 2, 4 ✅ **device + DB verified** — a real couple formed in prod 2026-06-16 (couple `e1f6d035`). Onboarding-first routing unblock ✅ verified. **The hinge is closed.** Segment 3 ✅ **device + DB verified** (2026-06-16: both phones show the partner's real name — `ff9cec3b`="Bryan", `34874fdd`="Mylena", one couple `e1f6d035`). Remaining: P5, plus a newly-surfaced **reinstall/new-device relink gap** (see below). 6 deferred.
**Goal:** A real couple forms in prod, both partners see each other's name, and couple-scoped writes are not silently blocked.

> **Read this first if you're a fresh chat.** This spec is self-contained. It captures the verified production state, the exact flow, the fix already shipped, and the remaining segments with file-level detail. `CLAUDE.md` (architecture rules) and `MEMORY.md` (decisions) auto-load — don't re-derive them. Verify any prod claim below against the live DB before acting on it; this was true on 2026-06-15.

---

## Why pairing is first

Pairing is the product's hinge — Vayl is single-player without it, and **every** couple-scoped feature (Desire Map reveal, sessions, entitlements, the Map tab) is untestable until a couple can actually form. It is also the highest-risk technical area. Per the Day-1 user lens it comes right after auth (which already works).

The blocking fact when this spec was written: **the live `couples` table had 0 rows** — no couple had ever formed in production, despite the UI being complete. Segment 1 explains and fixes why.

---

## Verified production state (2026-06-15)

Supabase project: **`vayl` / `ynhjlabjzauamntbyxdp`** (the only `ACTIVE_HEALTHY` project; ignore `sb1-…` and `grapplr`).

| Fact | Value | Implication |
|---|---|---|
| `couples` rows | **0** (before the device test) | No couple had ever formed — Segment 1 root cause |
| `user_profiles` rows | **2** — auth `4f69…2101` (name **null**), auth `dc68…916d8e` ("Test Partner B") | Both test accounts have profiles → pairing guards pass |
| `pairing_codes` rows | 1, code `594692`, **expired** (Apr 30) | Don't reuse — generate a fresh code |
| `rapid-task` edge fn | **v4** deployed 2026-06-15 (FK-fixed) | The Segment-1 fix is live |
| Migration history | **EMPTY** (`list_migrations` = []) | Schema lives outside the repo → not reproducible (Segment 5) |
| `user_profiles` RLS | SELECT/INSERT/UPDATE all `auth_id = auth.uid()` only | **No cross-partner read** → can't show partner name (Segment 3) |
| `user_profiles.auth_id` | **not unique** (only `id` PK + `pairing_code` unique) | Profile creation must be idempotent or it duplicates (Segment 2) |
| `couples` columns | `id, user_a, user_b, shared_safe_word, matches_revealed, created_at` (6) | FK `user_a/user_b → user_profiles.id` (PROFILE ids). No tier column. |
| `couples` RLS | 1 policy only: SELECT "Partners can view their couple" (correct) | No client INSERT/UPDATE — couple created by service role; reveal/safe-word writes need a policy later |

`ProfileService.ensureProfileExists(authId:)` exists (used by `DesireSyncService`) — it resolves/creates the profile row and returns the PROFILE id. Relevant to Segment 2.

---

## How pairing works today (the flow)

**Person A (inviter)** — `PairingStore.generateInvite()` → `PairingService.generateCode()`:
- Inserts `pairing_codes { created_by: <auth uid>, code }` (RLS: `auth.uid() = created_by`). `expires_at` auto-defaults to `now()+24h`.
- Then `pollForPartner(code:)` → `PairingService.pollForClaim(code:)` — polls **the inviter's own** `user_profiles.couple_id` every 3s (because the function deletes the code and stamps `couple_id` on both profiles).

**Person B (joiner)** — `PairingStore.joinWithCode(code)` → `PairingService.claimCode(code)`:
- Invokes the edge function slug **`rapid-task`** (display name "create-couple") with `{ code }`.
- `rapid-task` (service role): fetches the unclaimed code → checks expiry → blocks self-link → **resolves PROFILE ids from auth ids** → guards "already paired" → inserts `couples { user_a: profileA, user_b: profileB }` → stamps `couple_id/is_linked/linked_at` on both `user_profiles` (matched by `auth_id`) → deletes the code → returns `{ couple_id }`.
- `PairingStore.persistLink(coupleId:)` writes `coupleId/isLinked/linkedAt` to the local `UserProfile` (SwiftData) and mirrors `appState.linkState = .linked` + `appState.coupleId`.

**State machine:** `PairingLinkState` = `idle → generating → waitingForPartner(code) → linked(coupleId)` (A side) / `idle → joining → linked` (B side) / `error`.

Key files:
- [`PairingService.swift`](../../../Vayl/Core/Services/PairingService.swift) — data layer (generateCode / claimCode / pollForClaim).
- [`PairingStore.swift`](../../../Vayl/Features/Pairing/PairingStore.swift) — `@Observable @MainActor` store (generateInvite / joinWithCode / pollForPartner / persistLink / cancelPolling / reset).
- [`rapid-task/index.ts`](../../../supabase/functions/rapid-task/index.ts) — the live edge function (repo copy == deployed v4).
- Views: `PairingInviteView`, `PairingJoinView`, `PairingSettingsView` (reachable via Map tab + Settings → Partner Pairing).

---

## Segments

| # | Does (one thing) | Done — on device | May not touch |
|---|---|---|---|
| **P1** | Deploy the FK-fixed `rapid-task` (auth-id → profile-id) | 2 devices: A code → B enter → `couples` 0→1, both link | Swift, schema, RLS, other fns |
| **P2** ✅ | Guarantee a `user_profiles` row exists before pairing | Fresh Apple ID → profile row in prod before Pairing opens | pairing UI, schema, RLS |
| **P3** | Partner identity read (show partner's name post-link) | Linked screen shows the partner's real name | couple creation, pairing fns |
| **P4** | Bound the infinite poll (timeout + expiry + regenerate) | Partner never joins → "expired, regenerate", not forever | edge fns, schema |
| **P5** | Reproducible schema + RLS hygiene (repo == prod) | `supabase db diff` clean; no duplicate/wrong policies | app code |
| P6 | *(defer)* Couple-model phantom fields + security advisors | Model decodes cleanly; advisor WARNs cleared | — (App-Store week) |

### P1 — Deploy FK-fixed `rapid-task` — ✅ DONE (device + DB verified 2026-06-16)
**Device proof:** two real phones linked — `couples` 0→1 (couple `e1f6d035`, user_a `ff9cec3b` = Bryan, user_b `34874fdd` = partner), both `user_profiles.couple_id` set + `is_linked=true` + matching `linked_at`, claimed code deleted by the function. First couple ever formed in prod.
**Root cause:** the deployed function (pre-2026-06) inserted `couples.user_a = pairingRow.created_by` — an **auth id**. `user_a/user_b` are FK → `user_profiles.id` (PROFILE ids), so every insert FK-violated → `"Failed to create couple record"` → `couples` stayed empty. The repo function (header "FIX (2026-06)") resolves profile ids first. Deployed as **v4** via MCP `deploy_edge_function` on 2026-06-15 (slug `rapid-task`, `verify_jwt: true` preserved).
**Verify (Claude, after Bryan's test):** `select count(*) from couples;` → 1; both `user_profiles.couple_id` set; the code row deleted.
**If it fails:** read the function logs (`get_logs`), check the error string the app surfaces. The most likely 409 is "Both partners must have a profile before linking" → that's P2.

### P2 — Reliable profile creation — ✅ DONE (verified on device 2026-06-16)
**Device proof:** Bryan's prod profile row was deleted → app deleted+reinstalled → on relaunch a **new** `user_profiles` row (`ff9cec3b…`, auth `4f69…`) was created at 19:38 before Pairing was reachable. Confirmed the create path fires and is non-duplicating. (Session restored from Keychain → landed on AppShell home, bypassing sign-in/OB; that's expected iOS Keychain persistence, unrelated to P2.)
**Problem:** the two test accounts already have profile rows (origin unknown — likely an earlier debug path), but there is **no guaranteed trigger** that creates a `user_profiles` row for a brand-new user. `SyncManager.syncProfileToSupabase` has zero callers; onboarding persists only to local SwiftData. So a fresh Apple sign-in can reach Pairing with no profile → `rapid-task` 409s at the "both must have a profile" guard.

**Spec correction found while building:** the originally-suggested `ProfileService.ensureProfileExists(authId:)` does **not** create — it returns a UserDefaults cache, else selects, else **throws `profileNotFound`**. The method that actually creates is `fetchOrCreateProfile` (select-before-insert, already idempotent on `auth_id`), and `SyncManager.syncProfileToSupabase` already wraps it **plus** caches the profile id **plus** flags a retry on failure. The dead loop is worse than stated: `syncProfileToSupabase`'s only caller is `retryPendingSyncs`, gated on `pendingProfileSync == true` (only set when the sync *fails*) **and** `localProfile != nil` (VaylApp passes `nil`) — so it can never fire for a fresh user.

**Decisions (Bryan, 2026-06-16):** create **silently at first sign-in** (not onboarding-finish); **row-existence only** (blank row OK — data push deferred to P3).

**Implemented (`AuthService.swift` only):** added private `ensureRemoteProfile()` → calls `SyncManager.shared.syncProfileToSupabase(authId:)`, gated on the `supabaseProfileId` cache being nil (≤1 round-trip/install, self-healing on failure since the cache stays nil → next launch retries). Called from **both** auth-confirm points — end of `checkSession()` (returning user) and end of `authorizationController(didComplete)` (fresh sign-in). No schema change (the existing select-before-insert is the idempotency guard; `auth_id` unique index stays deferred to P5).
**Done (device — Bryan):** sign in with a fresh Apple ID → a `user_profiles` row appears in prod before Pairing is reachable. *(Claude verifies: `select count(*) from user_profiles` goes 2→3 with the new `auth_id`.)*
**Constraints honored:** identity/profile layer only (one file). No pairing UI, no schema, no RLS.

### P3 — Partner identity read — ✅ BUILT (compile-verified 2026-06-16, edge fn deployed, awaiting device proof)
**Problem (reshaped while building):** `user_profiles` SELECT RLS is `auth_id = auth.uid()` only → no cross-partner read. **But the deeper issue: the onboarding name was never in the remote row to begin with.** The OB pipeline writes the rich profile to **local SwiftData only**; `fetchOrCreateProfile` inserts a row with hardcoded defaults (`name: nil`, `pronouns:"they/them"`), and nothing ever pushes the real name up. So both members of tonight's couple are `name=null` remotely. P3 therefore = **push, then read**.
**Decisions (Bryan, 2026-06-16):** push at pairing actions + linked-screen load (commit-time push is infeasible — in the onboarding-first flow commit precedes the session/row); read via **`get-partner` edge fn**; null fallback **"Your partner"**.
**Implemented:**
- **Push (P3a):** `ProfileService.updateIdentity(name:pronouns:)` (partial UPDATE by `auth_id`, RLS-safe) → `SyncManager.pushDisplayIdentity(localProfile:)` → `PairingStore.syncIdentityToRemote()`, fired on `generateInvite`/`joinWithCode`/`refreshPartner` (back-fills couples linked before P3).
- **Read (P3b):** `supabase/functions/get-partner/index.ts` (service role, column-scoped to name+pronouns, **deployed v1**) → `PairingService.fetchPartner()` → `PairingStore.refreshPartner()` + `partnerDisplayName`. Bound into both linked-celebration views **and** `PairingSettingsView` status (so the existing couple sees it without re-linking).
**Done — ✅ device + DB verified 2026-06-16:** after both opened Pairing, his phone showed "Linked with Mylena", hers "Linked with Bryan"; prod has `ff9cec3b`="Bryan" + `34874fdd`="Mylena", one couple, both stamped. (Her name pushed even though she'd reinstalled — `syncIdentityToRemote` runs on join before the claim.)
**Deferred:** binding the Home `PartnerChip` to the live partner name (needs `HomeStore` to fetch) — separate surface, out of P3's pairing scope.

### ⚠️ Reinstall / new-device relink gap (surfaced 2026-06-16)
Local link state (`AppState.linkState`/`coupleId` + `UserProfile.isLinked`) is restored **only from UserDefaults/SwiftData** — there is **no remote→local link restore** on sign-in. Delete+reinstall (or a new phone) wipes both, so a user who is still linked **remotely** comes back **unlinked locally**, and re-pairing is blocked by `rapid-task`'s "already paired" 409 → no clean recovery. (Mylena reinstalled tonight yet still showed linked — unexplained by the code; likely her reinstall didn't fully clear UserDefaults, OR a split state. Worth a deliberate reinstall test.) **Proposed fix:** on sign-in (P2's `ensureRemoteProfile` path), read the remote `user_profiles.couple_id` and, if set, restore `isLinked/coupleId/linkState` locally. Candidate for its own segment (P-relink) — coordinate with P5.

### P4 — Join-flow robustness — ✅ DONE (device-verified 2026-06-16)
**Device proof:** on the Invite screen, force-expiring the live code in prod flipped the screen to "Code expired" within ~3s (live-expiry detection), and "Generate new code" minted a fresh code (`regenerate()`). Done-condition met — no infinite spinner.
**Problem:** `PairingService.pollForClaim` was `while true` with no timeout/expiry surfacing.
**Decisions (Bryan, 2026-06-16):** on expiry → **prompt to regenerate** (not auto). Code TTL stays **24h** (shortening needs a schema change → P5). Notify-on-join is **in-app only** (push absent project-wide).
**Implemented (3 files, no enum-case churn — expiry carried as `PairingStore` props so `HomeStore`/`PairingJoinView` untouched):**
- `PairingService.generateCode()` now returns `(code, expiresAt)` (reads back the DB `expires_at`); `pollForClaim(code:deadline:)` is bounded — each tick checks couple_id (linked), the captured deadline, **and** the live DB `expires_at` (so a server-forced expiry surfaces within ~3s, which is how we device-test it), throwing `PairingError.expiredCode` on timeout.
- `PairingStore` gains `codeExpiresAt` + `codeExpired` + `regenerate()`; the poll catches `.expiredCode` → sets `codeExpired`.
- `PairingInviteView`: live countdown (`Text(timerInterval:)`), ambient breathe on the waiting pill (`.ambientAnimation(.cardBreathe)`), and a dedicated "Code expired → Generate new code" state.
**Done (device — Bryan):** partner never joins → "code expired — regenerate" state, not an infinite spinner. *(Claude device-tests by force-expiring his active code in prod: `update pairing_codes set expires_at = now() - interval '1 min' where ...` → his screen flips to expired within ~3s.)*
**May-not-touch honored:** no edge fns, no schema.

### ⚠️ Two-device blocker (surfaced building P4) — gates P1's couple proof
`PairingStore.persistLink` throws "No user profile found" if there's no **local** SwiftData `UserProfile`. A local profile is created **only** during onboarding (`OnboardingStore.persist`); `DataStore.fetchOrCreateProfile()` has **zero callers**, `hydrateOnboardingState` doesn't seed one, and `appContainer` lives in the app sandbox (wiped on delete). In the **current DEBUG build, onboarding is unreachable**: authed → `AppShell`; un-authed → `SignInView` (DEBUG override), both bypassing `OnboardingCanvas`. So neither Bryan's reinstalled phone nor a fresh partner phone has a local profile → **both** will error at `persistLink` tonight even though the `couples` row forms server-side (P1) and both `couple_id`s get stamped. This made the chosen "partner must onboard first" path temporarily **unsatisfiable**.

**Resolution (Bryan chose B, 2026-06-16): make onboarding reachable.** Investigation showed the "finale is stubbed" belief is **stale** — `FounderLetterPhase.finish()` (drag-to-dismiss) calls `director.finishOnboarding → OnboardingStore.commit`, which creates the local `UserProfile` and sets `isOnboardingComplete` (commit gate: `displayName` + `situationalRegister` + `curiositySelections`, all collected earlier). Fix = a one-file routing reorder in `AppRootView.routedDestination`: **onboarding gates first** (`!isOnboardingComplete → OnboardingCanvas` regardless of auth), then auth, then app — and the stale DEBUG "route un-onboarded → SignIn" override was removed. Compile-verified 2026-06-16. **Device proof (Bryan):** launch → routed into onboarding → complete it (drag the founder letter) → land on AppShell with a local profile; then pairing's `persistLink` succeeds → "You're linked!" fires. Both phones must complete onboarding before the couple test.

### P5 — Backend reproducibility + RLS hygiene — 🔶 IN PROGRESS (P5a applied 2026-06-16)
**Security audit (2026-06-16):** 0 errors / 38 warnings. RLS enabled on all 10 tables; every policy user-scoped (no `USING(true)`, no cross-user read). The "wrong" `desire_*` policies were dead (auth-id vs profile-id → never match), not leaky. No entitlement table exists; the one paywall gate (`couples.matches_revealed`) has no client write policy → can't self-unlock. **Forward risk for M1:** `user_profiles` UPDATE = `auth_id=auth.uid()` with no column restriction → a user can edit *all* own columns; entitlement/tier MUST be a service-role-only table (couples pattern), never a `user_profiles` column.
- **P5a ✅ applied** (migration `20260616120000_p5a_security_hygiene` — first tracked migration; repo file + remote both): dropped 6 dead `desire_*` policies, revoked EXECUTE on `rls_auto_enable()`, pinned `set_curated_sessions_updated_at` search_path. Warnings 38→35, zero behavior change.
- **P5b ✅ applied** (migration `20260616120100_p5b_lock_anon_role`): revoked ALL `anon` table grants (anon now has **0**; `authenticated` **70** intact) + locked `is_couple_member` from anon (kept `authenticated` — RLS needs it). Warnings 35→24. Intentionally did **not** revoke `authenticated` SELECT — the app needs it and RLS protects the rows, so the 10 "signed-in can see object" warns are expected and stay. Verified at grant level; live RLS unchanged.
- **P5c — partly applied** (migration `20260616120200_p5c_authid_index_and_scope`): ✅ `user_profiles.auth_id` unique index added (`user_profiles_auth_id_key`; P2 idempotency closed); ✅ all 20 public-table policies scoped `TO authenticated` (0 public-role policies remain). **Note:** scoping did NOT reduce the advisor count (still 24) — lint 0012 keys off the *anonymous-sign-ins Auth setting*, not policy roles. To clear those 10 warns, **disable anonymous sign-ins** in the dashboard (Auth → Sign-In/Providers → Anonymous). Vayl uses Apple only, so safe.
  - **Baseline dump (#1) ✅ DONE** (Bryan via CLI, 2026-06-16): `supabase db dump` → `20260101000000_baseline.sql` (937 lines, full schema). Collapsed to baseline-only — deleted the 5 incremental files, `migration repair --status reverted` the 3 MCP-recorded entries + `--status applied` the baseline. **`migration list` → Local==Remote (`20260101000000`): repo==prod, reproducible.** ⚠️ Don't use MCP `apply_migration` here anymore (it records mismatched timestamps); use `supabase migration new` + `db push`.
  - **P5d ✅ applied** (migration `20260616223000`, via `supabase db push`): revoked anon from the postgres-owned default privileges → future user tables (postgres-created = the normal path) no longer auto-grant anon. Benign residuals: supabase_admin-owned defaults still grant anon (only affects supabase_admin-created internals, not user tables; postgres can't alter them); `set_curated_sessions_updated_at` still anon-exec via PUBLIC (SECURITY INVOKER, harmless).
  - **✅ P5 COMPLETE** — repo==prod (single baseline migration, history aligned), anon locked out of existing + future tables, RLS verified, dead policies dropped, functions hardened, auth_id unique.
- **Remaining 24 warns:** 10 authenticated-exposed (intentional — app needs table access, RLS protects) + 1 `is_couple_member` authenticated (intentional — RLS uses it) + 10 anon-policy (cosmetic now; P5c) + 2 `cron.*` (Supabase-managed) + 1 leaked-password (N/A — Apple sign-in).
- *Noise (ignore):* leaked-password (Apple sign-in, no passwords); 2 `cron.*` anon-policy warns (Supabase-managed).

### P5 (original notes)
**Problem:** migration history is empty; the live schema (11 tables, policies, functions `is_couple_member`/`rls_auto_enable`, triggers) exists only on the hosted project. The two repo migrations don't represent prod. Also: `desire_ratings` has 6 policies (3 correct + 3 wrong `auth.uid() = user_id`), `desire_matches` has a correct read policy alongside wrong `auth.uid()` ones. **They function** (permissive policies OR — the correct one wins) but are confusing dead weight.
**Approach:** baseline-dump the live schema into a repo migration + mark migration history (so repo == prod, reproducible); drop the duplicate/wrong `desire_*` policies; add a `couples` UPDATE policy if the reveal needs client writes (coordinate with Monetization M1 / Desire D3). Optionally add the `user_profiles.auth_id` unique index for P2.
**Done:** `supabase db diff` shows repo == prod; no duplicate/contradictory policies.
**Constraints:** `supabase/migrations/` only. Apply via `apply_migration` (outward-facing — confirm with Bryan first). Note: MCP **can** write (P1 proved `deploy_edge_function` works — the old "read-only" memory is wrong).

### P6 — *(defer)* Couple-model + security hardening
Reconcile or annotate the non-entitlement `Couple` phantom fields (the Swift `Couple` @Model has ~13 fields but is **not decoded from the `couples` table anywhere** — it's local SwiftData, so this is latent, not blocking); revoke anon GraphQL SELECT exposure; tighten SECURITY DEFINER EXECUTE on `rls_auto_enable`/`is_couple_member`. **Entitlement/tier columns are NOT here** — they ship in Monetization M1. Schedule into the App-Store/security week.

---

## Open questions (Bryan decides)

- **P2:** Bar = "profile exists by the time Pairing opens", or must it exist at sign-in? Auto-create silently on first sign-in, or persist at onboarding-finish?
- **P3:** Partner sees name + pronouns only, or more? Edge function vs scoped RLS policy (recommend edge fn)? Fallback when partner name is null?
- **P4:** On expiry while waiting — auto-regenerate or prompt? Code TTL (currently 24h)? Push notify-on-join in V1, or in-app only?
- **P5:** OK to baseline live prod as the migration source of truth? Drop the wrong `desire_*` policies now or defer to Desire week?

---

## Architecture contracts (from CLAUDE.md)

- Views read from `PairingStore` and call its methods only — never a Service/DB directly. `PairingStore` (Store) calls `PairingService` (Service); `PairingService` has no Store/View references.
- No raw colors/fonts/spacing in the pairing views — design tokens only.
- The "linked" confirmation is the first emotional beat — a brief spectrum pulse; press-state + haptic on every tap.
- Couple records are created **server-side (service role)** — never client INSERT into `couples`.

## Follow-up specs (spun out 2026-06-16)
- **P-relink** — restore the couple link on reinstall/new-device: [`2026-06-16-pairing-relink-spec.md`](2026-06-16-pairing-relink-spec.md)
- **M1 entitlement security rule** — entitlements service-role-only, never a `user_profiles` column: [`2026-06-16-m1-entitlement-security-rule.md`](2026-06-16-m1-entitlement-security-rule.md)

## References
- Playbook cards P1–P6: `docs/roadmap/vayl-build-roadmap.html`
- Memory: `[[backend_app_reconciliation]]` (auth-id vs profile-id; FK bug), `[[v1_strategic_positioning]]`
- Edge fn: `supabase/functions/rapid-task/index.ts` (live) — note `create-pair` + `lookup-code` are **dead/orphaned** (obsolete schema, zero callers) — delete or ignore.

## How to execute (fresh chat)
`/segment P2` (once the command exists) — or: "Work Pairing Segment P2 from `docs/superpowers/specs/2026-06-15-pairing-implementation-spec.md`. Read the segment + the files it names, verify the prod state, confirm scope per the Build Protocol, answer the open questions with me, implement to the done-condition, then update the playbook status + log any decision to memory."
