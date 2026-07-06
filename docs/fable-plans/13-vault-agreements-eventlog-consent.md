# Plan 13 — The Vault: Desire Map · Agreements · Event Log · Consent Exchange (T3 Seg 5)

**Goal:** finish the Vault mini-project by **deploying its already-written backend** (5 tables + RLS + 2 edge functions), closing the small Swift↔backend gaps this deployment exposes, and handing Bryan a two-account **decline-never-discloses** proof checklist. When this pass is done: the Vault `.vaylSheet` opens from Map's Us layer with all four segments live against a real deployed backend (Desire Map reuse, Agreements dual-lock, Event Log private/shared, Consent exchange), the project compiles green, and `get_advisors(security)` reports zero RLS gaps on the new tables.

> ## ⚡ ONE-SHOT LICENSE — convention override (read first)
>
> Vayl's standing Build Protocol (`CLAUDE.md`) says: _"Never build a full feature in one pass.
> Break every feature into named segments. A segment is not complete until it has run on device."_
> **This plan deliberately suspends that pacing rule.** You (Fable) are authorized — and expected — to
> implement this ENTIRE plan in ONE pass, all segments end to end, without stopping between segments
> for a device check. Deliver one complete, build-green changeset.
>
> **What the license waives:** the _pacing_ rule only — the "one segment at a time, feel-verify on
> device before the next" cadence. Build it all at once.
>
> **What it does NOT waive (still mandatory — the license buys speed, not sloppiness):**
> - **4-layer architecture:** View → Store → Service → Model. Views never call a Service/DB/network
>   directly. Stores are `@Observable @MainActor final class`. `director.advance()` is the only way to
>   change an onboarding phase; no View writes `VaylCardModel`.
> - **Tokens only:** no raw colors / fonts / spacing / radius / opacity / animation-duration literals in
>   Views. Read the token file (`Vayl/App/Theme/*`) before using a token; **never invent one.**
> - **Presentation grammar:** route modals through `.vaylCover` / `.vaylSheet`, never raw
>   `.fullScreenCover` / `.sheet`. Card Session is always a `.vaylCover`.
> - **iOS 26:** zero banned APIs (`UIScreen.main`/`.bounds`, `keyWindow`, `UIWebView`,
>   `NSURLConnection`, `UNAuthorizationOptionAlert`/`…PresentationOptionAlert`).
> - **A11y + empties:** Reduce-Motion fallback on every looping animation (`.ambientAnimation` or a
>   `guard !reduceMotion`); an empty state (icon + headline + sub-label + optional CTA) on every data screen.
> - `.drawingGroup()` stays on `VaylCardFace`; no `VaylCardFace` shell edits.
>
> **Accuracy contract:** every file path, symbol, and line number in this plan was verified against the
> repo on **2026-07-01**. If reality differs when you build, **trust the repo and note the drift** — do
> not invent paths, tokens, or APIs to make the plan "fit."
>
> **Verification is deferred, not skipped:** finish by compiling green, then hand Bryan the
> **"Bryan verifies on device"** checklist at the end. Bryan runs on-device / feel confirmation himself
> (he does not want Claude/Fable running the simulator). Items marked 🎚️ are feel-values Bryan tunes on
> device — use the given default and move on; do not re-derive them.

---

## ⚠️ ONE-SHOT CAVEAT — read this before anything else

**This is the largest net-new backend piece in the Map phase: a mini-project of 5 tables + RLS + 2 edge
functions.** It can be done in one pass, and this plan is written for that. **But two facts change the
shape of the pass, and Fable must internalize both:**

1. **The Swift client, the migrations, and the edge-function source are ALREADY WRITTEN AND COMMITTED.**
   This is verified below. The Vault is not a from-scratch build. The remaining work is: **deploy the
   backend that the finished Swift already calls, fix the few real Swift↔backend mismatches that
   deployment exposes, and prove the privacy invariant.** Do NOT re-author `VaultStore`, the services,
   the sections, or the migration SQL from scratch — read them, deploy them, reconcile them.

2. **The couple-scoped RLS + the "a decline never discloses" invariant is the riskiest surface in the
   whole Map phase.** A bug here outs a partner's private boundary. Build it in one pass, but treat the
   RLS and the two consent edge functions as the part that MUST be proven with a **real paired account**
   (and ideally a Deno/pgTAP test) before this is called done. Build-green is not done here; the
   two-account decline-privacy proof is done.

**Definition of Done for this plan =** build-green **+** the 3 Vault migrations applied on prod (RLS
present, confirmed by `get_advisors`) **+** `consent-ask` / `consent-respond` deployed **+** the
single-user paths exercised. The **two-account consent + decline-privacy proof** lives in Bryan's device
checklist (it needs two real devices/accounts, which Fable cannot drive).

---

## Context Fable needs

- **What the Vault is:** the couple's shared-but-consented space, reached from the Map tab's Us layer.
  It hosts four parts in one `.vaylSheet`: **Desire Map** (reuse), **Agreements** (dual-lock, FREE),
  **Event Log** (private/shared, FREE), **Consent exchange** (edge-function-mediated, rides on Desire
  Map access). Canonical spec: `docs/superpowers/specs/2026-06-24-vault-design.md` (read it fully).
- **Current state — the Swift is DONE and committed.** Verified 2026-07-01: `git ls-files` shows the
  whole `Vayl/Features/Map/Vault/` tree tracked and the working tree clean for it. Present and wired:
  - `Vayl/Features/Map/Vault/VaultStore.swift` — `@MainActor @Observable final class VaultStore` with
    `loadDesire`, Agreements (`loadAgreements`/`propose`/`decideProposal`), Event Log
    (`loadLog`/`saveEntry`/`deleteEntry`/`syncLogDown`), Consent (`loadConsent`/`askToOpen`/`respondToOpen`),
    and the discussion card (`openDiscussion`/`closeDiscussion`). **This is the source of truth for the
    contract; do not rewrite it.**
  - `VaultSheet.swift` — the host `.vaylSheet` body with `LearnSegmented<VaultStore.Segment>` over
    `.desire / .agreements / .log`, plus the nested `.vaylSheet`s for the entry editor and the discussion card.
  - Sections: `Components/VaultDesireSection.swift`, `VaultAgreementsSection.swift`, `VaultLogSection.swift`,
    `DiscussionCardView.swift`; the editor `EventEntryEditor.swift`.
  - Services: `Vayl/Core/Services/AgreementsService.swift`, `EventLogService.swift`, `ConsentService.swift`.
  - Model + enums: `Vayl/Core/Models/EventLogEntry.swift` (`@Model`, **already in `SchemaV1.models`** at
    `Vayl/App/ModelContainer.swift:45`), `Vayl/Core/Models/Enums/EventLogEnums.swift`
    (`EventMood {light,good,mixed,tender,hard}`, `EventTag {date,play,metamour,milestone,hardConvo,reconnection}`,
    `EventVisibility {onlyMe="private", shared="shared"}`).
  - Attach point: `Vayl/Features/Map/MapView.swift:29` (`@State private var vaultStore = VaultStore()`)
    and `:96` (`VaultSheet(store: vaultStore, onUnlock: { showPaywall = true })`).
  - Migration SQL, committed but marked **"STATUS: UNVERIFIED / NOT APPLIED"** in each header:
    `supabase/migrations/20260624120000_vault_agreements.sql`, `…120100_vault_event_log.sql`,
    `…120200_vault_consent.sql`.
  - Edge functions, committed but **not deployed:** `supabase/functions/consent-ask/index.ts`,
    `supabase/functions/consent-respond/index.ts`.
- **Current state — the BACKEND IS NOT DEPLOYED.** Verified 2026-07-01 against prod `ynhjlabjzauamntbyxdp`:
  - `list_tables` returns 18 tables; **none of** `agreements`, `agreement_proposals`,
    `event_log_entries`, `consent_requests`, `consent_declines` exist.
  - `list_edge_functions` returns 8 functions; **neither** `consent-ask` **nor** `consent-respond` is deployed.
  - So every Vault Supabase call currently fails at runtime against a missing table/function. This plan's
    core job is to make the already-written client's backend real.
- **Backend preconditions that DO already hold (so the edge functions work as written):**
  - `user_profiles.couple_id uuid` EXISTS (the consent edge fns read `me.couple_id` — confirmed present).
  - `couples.shared_safe_word text default 'red'` EXISTS (Agreements segment reads it via `Couple`).
  - The couple-scoped RLS convention is `auth_id = auth.uid()` → profile id, matching live
    `desire_matches` / `desire_ratings` policies. The three migration files already follow it exactly.
- **Canonical patterns to imitate (all already followed in the committed code — verify, don't reinvent):**
  - RLS templates: spec §1.3 and the live `desire_ratings` (user-scoped, no partner-read) /
    `desire_matches` (couple-scoped) policies.
  - Service-role consent flow: `supabase/functions/compute-desire-matches/index.ts` and
    `grant-entitlement/index.ts` (service client + user client + `auth.getUser()` gate) — the two consent
    functions are already written in this exact shape.
  - Client service style: `Vayl/Core/Services/DesireSyncService.swift` (the three Vault services mirror it).

---

## Files

### Create

| File | Responsibility |
|---|---|
| `supabase/tests/vault_consent_privacy.test.ts` | Deno test proving the invariant: after a decline, the asker's `consent_requests` row is still `pending` and `consent_declines` returns **zero** rows for the asker. **Test-only; not shipped in the app.** |

### Modify

| File | Line anchor | Change |
|---|---|---|
| `supabase/functions/consent-respond/index.ts` | `discussion_card_id: "neutral"` (~line 68) | Reconcile the discussion-card contract with the Swift consumer (Segment 4). The Swift `openDiscussion` looks a card up by `itemId`; the edge fn writes the literal `"neutral"`. Change the edge fn to write **`item_id`** as the card key so `CompanionCardStore.card(forItemId:tier:)` resolves it, or accept the Swift fallback — decided in **Open decision A** (default: write `item_id`). |
| `supabase/migrations/20260624120000_vault_agreements.sql` | header (lines 1-3) | After a green apply on prod, update the `STATUS: UNVERIFIED / NOT APPLIED` header line to `STATUS: APPLIED <date>` (a one-line doc edit; no SQL change). |
| `supabase/migrations/20260624120100_vault_event_log.sql` | header (lines 1-3) | Same status-header update after apply. |
| `supabase/migrations/20260624120200_vault_consent.sql` | header (lines 1-2) | Same status-header update after apply. |

> **No Swift `VaultStore` / service / section rewrites are planned.** The only Swift touch that may be
> required is if Segment 3's verification reveals a real DTO/column mismatch — if so, fix the DTO to
> match the deployed schema and **note the drift**, do not change the schema to fit a guess.

### Delete

_None._

---

## Build steps (segments)

The segments mirror the spec's ascending-risk sequence (§6). All are built in **one pass**. Migrations
are applied via the Supabase MCP `apply_migration` at implementation time (the MCP is read-only for
schema *reads* in the planning session, but `apply_migration` is the write path Fable uses now).

### Segment 0 — read the committed reality first (no writes)

**One thing:** load the finished client so you deploy against the real contract, not a guess.

Read, in order, and hold their exact shapes:
- `Vayl/Features/Map/Vault/VaultStore.swift` (the whole file) — the method names + the DTO field names
  each service call expects.
- `Vayl/Core/Services/AgreementsService.swift`, `EventLogService.swift`, `ConsentService.swift` — the
  exact table names, column names, and RPC/function slugs the client calls.
- The three migration SQL files and the two edge-function `index.ts` files.

**Contract cross-check to hold in mind (all verified 2026-07-01):**
- `AgreementsService` reads `agreements(id, text, is_active)` and
  `agreement_proposals(id, target_agreement_id, action, proposed_text, proposed_by)` where
  `status='pending'`; inserts a proposal; updates `agreement_proposals.status`. → matches
  `20260624120000_vault_agreements.sql` exactly (the trigger `apply_agreement_proposal` applies an
  approved proposal; the `proposals_partner_decides` policy is the dual lock).
- `EventLogService` upserts `event_log_entries` on `id`, deletes by `id`, pulls all rows (RLS filters).
  DTO columns: `id, author_id, couple_id, occurred_on, title, note, mood, tags, who, visibility`. →
  matches `20260624120100_vault_event_log.sql` exactly (`tags jsonb`, compound read policy).
- `ConsentService` reads `consent_requests(id, item_id, asker_id, status, discussion_card_id)` and
  `consent_declines(item_id)` filtered to `decided_by` by RLS; calls the `consent-ask` /
  `consent-respond` functions with `{item_id}` / `{item_id, decision}`. → matches
  `20260624120200_vault_consent.sql` + the two edge fns exactly.

**Done:** you can state, per Vault feature, the exact table + policy set the client needs and have
confirmed the committed SQL provides it (or noted the one mismatch to fix in Segment 4).

### Segment 1 — deploy the Agreements backend (couple-scoped, dual-lock)

**One thing:** make the Agreements segment's Supabase calls real.

Apply `supabase/migrations/20260624120000_vault_agreements.sql` verbatim via `apply_migration`
(name `vault_agreements`). It creates `agreements` + `agreement_proposals`, enables RLS, and installs:
- `agreements_couple_read` (SELECT, couple-scoped; **no client write policy** — only the trigger writes).
- `proposals_couple_read` (SELECT), `proposals_propose` (INSERT, `proposed_by` = me),
  `proposals_partner_decides` (**the dual lock:** UPDATE only when `status='pending'` AND
  `proposed_by NOT IN (my profiles)`), `proposals_withdraw_own` (DELETE own pending).
- `apply_agreement_proposal()` `SECURITY DEFINER` trigger: on `pending → approved` it inserts/edits/
  retires the target `agreements` row; on `pending → declined` it just stamps `decided_at`.

**After apply, run `get_advisors(type: security)`** and confirm zero RLS findings for the two new tables.

**Done (build-green portion):** the migration applies clean; `get_advisors` is green; the app's
Agreements segment loads without a "relation does not exist" error (single-user: you see your own empty
agreements list + "No agreements yet." empty state).

### Segment 2 — deploy the Event Log backend (private/shared split)

**One thing:** make the Event Log's private-vs-shared RLS real.

Apply `supabase/migrations/20260624120100_vault_event_log.sql` verbatim (name `vault_event_log`).
It creates `event_log_entries` (with `tags jsonb`, `visibility check in ('private','shared')`), enables
RLS, and installs the **compound read policy** — visible if `author_id` is me **OR**
(`visibility='shared'` AND couple-membership) — plus author-only INSERT/UPDATE/DELETE.

**The load-bearing property:** a `private` row is readable ONLY by its author; a partner physically
cannot SELECT it (same guarantee as `desire_ratings`). "Remote/backed-up" is not "not private" — the
author-scoped RLS is the privacy.

**After apply, run `get_advisors(type: security)`** and confirm zero findings for `event_log_entries`.

**Done (build-green portion):** the migration applies clean; `get_advisors` is green; the Log segment
saves an entry (private and shared), and `syncLogDown` returns your own rows without error.

### Segment 3 — deploy the Consent backend (the invariant) + the two edge functions

**One thing:** stand up the consent tables and the two service-role functions so that **a decline never
discloses**.

**3a. Tables + RLS.** Apply `supabase/migrations/20260624120200_vault_consent.sql` verbatim
(name `vault_consent`). It creates:
- `consent_requests(id, couple_id, item_id, asker_id, status check in ('pending','opened'),
  discussion_card_id, created_at, opened_at)` with a **unique index on `(couple_id, item_id)`** and RLS
  policy `consent_requests_couple_read` (SELECT, couple-scoped). **There is no `'declined'` status and no
  client write policy — only the edge functions (service role) write here.**
- `consent_declines(id, couple_id, item_id, decided_by, created_at)` with RLS policy
  `consent_declines_read_own` (SELECT, `decided_by` = me). **No INSERT/UPDATE/DELETE policy — only the
  service role writes declines.** The asker is never `decided_by`, so the asker can never read a decline.

**3b. Deploy the edge functions** via `deploy_edge_function` (both already written, service-role shape):
- `consent-ask` (`supabase/functions/consent-ask/index.ts`): upserts a `pending` request for
  `(couple, item)` on `onConflict: couple_id,item_id`; if already `opened`, leaves it; if a prior decline
  exists, still returns the same `pending` — the asker's UI is identical either way.
- `consent-respond` (`supabase/functions/consent-respond/index.ts`): only the **partner** (never the
  asker) acts on a `pending` request. `open` → `status='opened'` + `discussion_card_id`. `decline` →
  **insert `consent_declines` and LEAVE `consent_requests` at `pending`.** The HTTP response is
  `{ok:true}` **identical** for open and decline, so even the response shape does not leak.

Both functions are `verify_jwt: true` by default (matches the other deployed functions); do not disable it.

**After apply, run `get_advisors(type: security)`** and confirm zero findings for both consent tables.

**3c. Verify the client DTOs against the deployed schema.** Run a read of each new table's columns
(`list_tables verbose` or a `select` on an empty table) and confirm `ConsentService`'s DTOs
(`ConsentRequestRow`, `ConsentDeclineRow`) decode the deployed column names. If any name differs, **fix
the Swift DTO to match the deployed column and note the drift** (do not alter the migration to fit).

**Done (build-green portion):** all three consent objects exist; both functions show `ACTIVE` in
`list_edge_functions`; `get_advisors` is green; single-user smoke: `loadConsent` returns an empty set
without error, and `askToOpen` on one of your own positive items returns 200 and creates a `pending`
row you can read.

### Segment 4 — reconcile the discussion-card key (small, real mismatch)

**One thing:** make the "open a conversation" discussion card resolve to a real card.

The Swift `VaultStore.openDiscussion(itemId:itemName:tier:)` resolves a card via
`companionCardStore.card(forItemId: itemId, tier: tier)`, falling back to a generic card if none is
found. The edge fn `consent-respond` currently writes the literal `discussion_card_id: "neutral"`, which
`CompanionCardStore` will not resolve (so the fallback always fires). Per **Open decision A** (default:
key by item), change the one line in `consent-respond/index.ts`:

```ts
// before
.update({ status: "opened", opened_at: new Date().toISOString(), discussion_card_id: "neutral" })
// after — key the card to the item so CompanionCardStore.card(forItemId:tier:) resolves it
.update({ status: "opened", opened_at: new Date().toISOString(), discussion_card_id: item_id })
```

Redeploy `consent-respond`. The neutrality guarantee is unaffected: the card is chosen by the **item**,
which is identical for both partners regardless of who opened, so it never telegraphs the answer. Leave
the Swift fallback in place (it covers items with no authored companion card).

**Done:** opening a consent request yields a discussion card tied to the item (or the neutral fallback),
never a broken/empty card.

### Segment 5 — write the decline-privacy test (Deno)

**One thing:** encode the invariant as a runnable test so a future change can't silently break it.

Create `supabase/tests/vault_consent_privacy.test.ts` (test-only, not shipped). It must, against a test
branch or local stack with two seeded profiles in one couple:

```ts
// Pseudocode contract — Fable writes the real Deno test against the local/branch stack.
// 1. Partner A calls consent-ask({item_id: X}). Expect consent_requests(couple,X).status == 'pending'.
// 2. Partner B calls consent-respond({item_id: X, decision: 'decline'}).
// 3. INVARIANT — as Partner A (the asker):
//      a. consent_requests(couple,X).status is STILL 'pending' (unchanged by the decline).
//      b. select on consent_declines as A returns ZERO rows (RLS: A is never decided_by).
//      c. the consent-respond response body A would see is {ok:true}, identical to an 'open'.
// 4. As Partner B (the decliner): select on consent_declines returns exactly ONE row for X.
// 5. Control — a second consent-ask({item_id: X}) by A after the decline still returns 'pending'
//      (silent no-op / rate-limit), never surfacing the decline.
```

This is the automated half of the invariant proof. The on-device two-account half is in Bryan's checklist.

**Done:** the test file exists and expresses assertions 1-5. (Running it needs a branch/local stack;
Bryan runs it — see his checklist. Do not block the Swift build on the test executing.)

### Segment 6 — compile green + advisor sweep

**One thing:** prove the whole pass builds and the backend is policy-clean.

- Build the app target: it must compile green (no Swift changed unless a Segment 3c DTO drift required it).
- Run `get_advisors(type: security)` once more across all five new tables; zero findings is the gate.
- Confirm `list_edge_functions` shows `consent-ask` and `consent-respond` `ACTIVE`.

**Done:** build-green + advisors-green + both functions active.

---

## Definition of Done (build-green)

When the single pass is finished, all of the following are true:

- [ ] All three Vault migrations are **applied on prod** (`vault_agreements`, `vault_event_log`,
      `vault_consent`); `list_tables` now shows `agreements`, `agreement_proposals`, `event_log_entries`,
      `consent_requests`, `consent_declines`.
- [ ] `get_advisors(type: security)` reports **zero** RLS findings for the five new tables.
- [ ] `consent-ask` and `consent-respond` are **deployed and `ACTIVE`** (`list_edge_functions`).
- [ ] `consent_requests` has **no `'declined'` status value** and **no client write policy** (writes are
      edge-function-only). `consent_declines` has **only** a `decided_by`-scoped SELECT policy (no write
      policy). This is the structural core of the invariant.
- [ ] `event_log_entries` private rows are author-only by RLS; shared rows are couple-scoped (compound
      read policy present).
- [ ] `agreements` is written **only** by the `apply_agreement_proposal` trigger; the
      `proposals_partner_decides` UPDATE policy blocks a proposer from deciding their own proposal.
- [ ] The app **compiles green.** No `VaultStore`, service, section, model, or enum was rewritten; the
      only Swift edit (if any) is a Segment 3c DTO reconciliation, with the drift noted.
- [ ] `consent-respond` writes `discussion_card_id = item_id` (Segment 4), and it is redeployed.
- [ ] `supabase/tests/vault_consent_privacy.test.ts` exists and encodes invariant assertions 1-5.
- [ ] The three migration headers are updated from `NOT APPLIED` to `APPLIED <date>`.

## Bryan verifies on device

**Two-account is mandatory here — the invariant cannot be proven single-user.** Use two real accounts
paired into one couple (or the two seeded profiles already on prod: `user_profiles` has 2 rows, `couples`
has 2 rows).

- [ ] **Vault opens** from Map → Us layer; the segmented control switches Desire Map / Agreements / Log.
- [ ] **Desire Map segment** renders your summary counts + any revealed matches; locked-more routes to
      `PaywallSheet` (gated on `isCore`); free couple sees its one free-reveal match.
- [ ] **Agreements dual-lock (two devices):** A proposes an agreement → B sees "your call" and accepts →
      it appears active for **both**. A cannot accept A's own proposal (the accept control is absent for
      the proposer). Editing and retiring follow the same propose→partner-approves path.
- [ ] **Event Log private (two devices):** A logs a **private** entry → it never appears for B (not in
      B's list, not via any refresh). A logs a **shared** entry → it appears for **both**.
- [ ] **🔒 Consent — decline never discloses (THE proof, two devices):** A asks to open a conversation
      on item X → B declines → **A's Vault still shows "asked · waiting" for X, indistinguishable from a
      genuinely-pending request.** A must have **no** signal — visual, timing, or copy — that B declined.
      Re-asking X still shows "waiting." Then a second run where B **opens** X → both get the **same**
      discussion card for X.
- [ ] **🔒 Automated half:** run `supabase/tests/vault_consent_privacy.test.ts` on a branch/local stack;
      assertions 1-5 pass.
- [ ] 🎚️ The Vault sheet height, segment transitions, and empty-state copy feel right (tune on device).

## Constraints / do-not-touch

- **Do NOT rewrite the committed Swift Vault.** `VaultStore.swift`, the three services,
  `VaultSheet.swift`, the three sections, `EventEntryEditor.swift`, `DiscussionCardView.swift`,
  `EventLogEntry.swift`, and `EventLogEnums.swift` are the finished contract. Deploy to match them; only
  reconcile a DTO if the deployed schema genuinely differs, and note the drift.
- **Do NOT alter the migration SQL** except the status-header doc line. The RLS is written correctly to
  the spec §1.3 templates and the live `desire_ratings`/`desire_matches` convention; changing it risks
  the invariant. If something must change, that is an Open decision, not a silent edit.
- **The consent invariant is load-bearing and structural:** `consent_requests` never holds `'declined'`;
  declines live only in `consent_declines` behind a `decided_by`-scoped SELECT; both consent tables are
  written only by the service-role edge functions. Do not add a client write policy to either.
- **Tiers:** Agreements and Event Log are **FREE** — never add an `isCore` gate to them (gating a
  couple's safety primitives is wrong for an NM app). Only the Desire Map reveal + its consent openings
  ride on Core, reusing `PaywallSheet.Entry.reveal`.
- **iOS 26 / tokens / presentation:** the sheet stays a `.vaylSheet`; surfaces stay `.vaylGlassCard`;
  no raw color/font/spacing literals; notifications, if ever added, are `UNAuthorizationOptionBanner`
  (V1 consent is **in-app only**, no push — spec §4).
- **No em dashes** in any copy you touch.
- **Never `git add -A`; never commit `project.pbxproj`.** (No pbxproj change is expected — no new Swift
  file is created for the app target.)
- **Supabase writes go through `apply_migration` / `deploy_edge_function`** (the MCP write path), never a
  raw prod DDL against the live tables. Run `get_advisors(type: security)` after **every** DDL apply —
  that is the gate that catches a table shipped without policies.

## Open decisions (each with a default so Fable is never blocked)

**A. Discussion-card key written by `consent-respond` on `open`.** The Swift `openDiscussion` resolves a
card by `itemId`; the edge fn currently writes the literal `"neutral"`.
→ **Default (proceed): write `discussion_card_id = item_id`** (Segment 4) so `CompanionCardStore`
resolves a real per-item card, keeping the neutral guarantee (the card is chosen by item, identical for
both partners). Keep the Swift generic fallback for items with no authored card. Flag it; Bryan can
revert to a single literal neutral card later if he prefers one shared prompt for all items.

**B. Consent decline record shape.** The spec (§4, decision 2) leaves "private responder row vs
service-role-only column" to the implementer; both preserve the invariant.
→ **Default (proceed): the committed `consent_declines` table** (a private, `decided_by`-scoped row) — it
is already written, tested-shaped, and deployed by this plan. No change. This matches
`ConsentService.fetchMyDeclines`. Do not switch to a column.

**C. Where to run the Deno privacy test.** It needs two seeded profiles in one couple.
→ **Default (proceed): write it against a Supabase branch** (create via `create_branch`, apply the three
migrations there, seed two profiles, run, then merge/discard). Bryan can also run it on the local stack.
The test file ships regardless; only its execution is Bryan-run. Flag that branch creation may incur cost
(confirm via `confirm_cost`/`get_cost` before creating).

**D. Apply-to-prod vs branch-first for the migrations.** The migration headers say "apply on a branch,
run tests, then merge to prod."
→ **Default (proceed): apply on a Supabase branch first, run the privacy test + `get_advisors` green,
then merge to prod.** This honors the migration authors' own gate for the privacy-critical work. If
branch cost is a blocker, the fallback is direct prod apply followed immediately by `get_advisors` — but
branch-first is the recommended default for the consent migration specifically.
