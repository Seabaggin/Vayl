# 16 — Card Sessions Front-to-Back (master one-shot)

**Goal:** In one pass, ship the complete couple card-session feature: two-device server-authoritative Lock In handshake, entry/lobby/airlock UI per the cover-family mockup, the synced player (advance, timer, pause, safe word, reconnect, depth ceiling), the five-mechanic RevealEngine with its views, the local living-card faces + context beats + card backs, the session builder with fast paths, the composition/reveal-merge migration, and the bible-aligned 12-deck launch catalog with two fully-authored exemplar decks. The app compiles green with all unit tests + the content lint passing; two-device proof is Bryan's checklist.

**Spec:** `docs/superpowers/specs/2026-07-01-card-sessions-front-to-back-design.md` (approved 2026-07-01). This plan **supersedes fable-plans 08, 09, 10, 11 and the deck-authoring segments of 15** — do not execute those alongside this.

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

## How this plan is organized (read before building)

This master plan was produced by four repo-verifying section writers and assembled. Build the sections
**in order** — each consumes symbols the previous one creates:

| Section | Scope | Absorbs |
|---|---|---|
| **1** | Migration (composition + `update_reveal_state` + pgTAP) · `RealtimeSessionService` reveal/stream extensions · `SessionPlan` + `RevealEnvelope` models · `AirlockStore` + tests | plan 08 |
| **2** | Entry (PlayStore flow, joiner banner) · `SessionLobbyView` · real `AirlockView` per the cover-family mockup · transition beat · AppShell tab fix · EntitlementStore wiring · `SessionSyncCoordinator` + player remote sync (advance/timer/pause/safe word/reconnect/depth ceiling) | plans 09 + 10 (minus reveals) + 05 |
| **3** | `RevealEngine` + 4 reveal views · local living-card faces · context beats · card backs · `SessionBuilderStore/View` + fast paths + tests | plans 10 (Whisper, generalized) + 11 |
| **4** | Catalog re-cut to the 12 launch decks · per-deck blueprints · 2 fully-authored exemplar decks · build-time authoring instructions · content lint test | plan 15 (deck authoring only) |
| **5** | Spec §9 glue: composition derivation + pairing one-tap confirm + Settings "Card wording" row · `user_profiles.gender_identity` column + `get-partner` extension · `set_connection_composition` RPC (second migration, `20260701001000`) | new (no prior plan) |

Each section carries its own Files table, build segments, build-green DoD, Bryan checklist, constraints,
and open decisions (every open decision has an implemented default — proceed and flag, never block).

## ⚠️ SEAM RECONCILIATION — authoritative overrides (the assembler's rulings)

The sections were written in parallel and their interface seams drifted in four places. **These rulings
win over any conflicting line inside a section:**

1. **Builder output type = `SessionPlan` (the Codable struct).** Section 1 deletes the dead SwiftData
   `@Model SessionPlan` (zero call sites, verified), deregisters it from SchemaV1, and creates
   `Vayl/Core/Models/SessionPlan.swift` with a `var draft: CuratedSessionDraft` bridge. Section 3's
   builder emits `SessionPlan` via `onStart(SessionPlan)`. Section 2's PlayStore seam is therefore
   **amended**: `builderDidFinish(_ plan: SessionPlan)` (not `CuratedSessionDraft`), converting with
   `plan.draft` at the `openSession` call site; `SessionBuilderView(deck:onConfirm:onCancel:)`'s
   `onConfirm` carries `SessionPlan`.
2. **Reveal reconnect write = `clearRevealCard(sessionId:cardId:)`.** Section 3's seam block calls it
   `clearSeal(sessionId:cardId:role:)`; the canonical service method is Section 1's whole-card
   `clearRevealCard` (per spec §5: a lost in-flight answer re-prompts the CARD, both flags reset).
   Wherever Section 3 says `clearSeal(...)`, call `clearRevealCard(sessionId:cardId:)`.
3. **Reveal flag type = `RevealCardState`.** Section 3's seam block names it `RevealFlags`; Section 1's
   implemented type is `RevealCardState` (with `sealed(for:)`). Use `RevealCardState` everywhere.
4. **Resend naming.** Service level (Section 1): `requestResend` / `resendRequests`. Coordinator level
   (Section 2): `sendResendRequest(cardId:)` / `onResendRequest`. The coordinator adapts the service;
   Section 3's engine talks ONLY to the coordinator's names.
5. **VaylTests pbxproj ids collide.** Sections 1, 3, and 4 each claim `AA00000C…` for their new test
   files. Assign uniquely, in build order: Section 1 `AirlockStoreTests` = `AA00000C…`; Section 3
   `RevealEngineTests` = `AA00000D…` and `SessionBuilderStoreTests` = `AA00000E…`; Section 4's content
   lint = `AA00000F…`; Section 5's derivation tests = `AA00000G…` (as written). Check
   `project.pbxproj` for the current highest `AA00000N` before wiring and shift up if the range moved.
6. **Local `Couple` rows may not exist.** Section 5 verified that nothing in the app creates local
   SwiftData `Couple` rows today; its writes are mirror-if-present. Anywhere a section reads
   `couple.connectionComposition` for card filtering (Section 2's hand assembly, Section 3's builder
   input, Section 4's `Deck.cards(for:)` call sites), fall back to the remote couple row's value via
   the existing couple fetch, and default `.flexible` when unknown. Never crash or block on a missing
   local Couple.
7. **Second migration.** Section 5 adds `20260701001000_composition_touchpoint.sql`
   (`user_profiles.gender_identity` + `set_connection_composition` RPC) on top of Section 1's
   `20260701000000…` file. Same process guard applies to both: `supabase db diff --linked` first;
   Bryan deploys (the CLI token here is read-only) including the `get-partner` edge-function redeploy.

**Migration safety:** the SchemaV1 change (delete `SessionPlan` @Model, add `Couple.connectionComposition`)
is pre-launch-safe (no users, empty `AppMigrationPlan.stages`) but Bryan's dev installs may need a
store wipe on first launch. Run `supabase db diff --linked` BEFORE applying the SQL migration (known
prod drift); flag any drift, never auto-apply from this plan.

**Copy rule (repo-wide):** no em dashes in ANY user-facing string or card copy. The content lint enforces
it for deck JSON; hold yourself to it in Swift strings too.

---

# ═══════════════════ SECTION 1 — Backend + Handshake (absorbs plan 08) ═══════════════════

# SECTION 1 — Backend, Transport, Models, Airlock (Master Segments A–C)

_Absorbs and supersedes `docs/fable-plans/08-session-realtime-handshake.md` in full. Where the 2026-07-01 spec (`docs/superpowers/specs/2026-07-01-card-sessions-front-to-back-design.md`, sections 4.1–4.3, 5, 6, 8, 9) changed nothing, plan 08's verified code is reused wholesale below (marked "from plan 08, verified"). Where the spec changed things (states, streams, reveal merge), this section is the new source of truth._

---

## Drift ledger — plan 08 claims re-verified against the repo 2026-07-01

Every symbol cited in this section was checked against the working tree today. Differences from plan 08 and from the spec's assumptions:

1. **`SessionPlan` name collision (the big one).** The spec (4.1) calls for a NEW `struct SessionPlan` at `Vayl/Core/Models/SessionPlan.swift`. But a SwiftData `@Model final class SessionPlan` ALREADY exists at `Vayl/Features/Sessions/SessionPlan.swift` and is registered in `SchemaV1.models` (`Vayl/App/ModelContainer.swift` line 42). Its only references in the entire app target are that registration and its own `.stub(coupleId:)` extension (zero call sites; `grep -rn "SessionPlan" Vayl --include="*.swift"` returns only the file itself, ModelContainer.swift:42, and a comment in RealtimeSessionService.swift:47). Two types named `SessionPlan` in one target will not compile. **Resolution (see Segment C1 + Open Decision 1): delete the dead `@Model`, deregister it from SchemaV1, create the spec's struct.** Pre-launch, no users, `AppMigrationPlan.stages` is empty, so this is safe; Bryan's dev installs may need a store wipe on first launch after the schema change (removing an entity + adding a `Couple` property in the same pass).
2. **`RealtimeSessionService` is exactly as plan 08 described** (re-verified line by line): `CuratedSessionStatus` L24, `SessionRole` L38 (with `bandwidthColumn`/`consentColumn`/`presenceColumn`), `CuratedSessionDraft` L49, `CuratedSessionDTO` L62 (reveal_state deliberately omitted, per the comment at L58 — this section adds it), `openSession` L147, `fetchOpenSession` L176, `fetchCoupleId` L192, `setBandwidth` L206, `setConsent` L214, `setPresence` L222, `setStatus` L230, `advance` L243, `sessionChannel` L277, `trackPresence` L284, `leaveChannel` L289. The private `SupabaseTable.curatedSessions` constant is at L18.
3. **SDK is supabase-swift 2.48.0** (Package.resolved, revision `e5020ae`). API shapes verified against the checked-out sources: `channel.presenceChange()`, `channel.postgresChange(UpdateAction.self, schema:table:filter:)` returning `AsyncStream<UpdateAction>`, `UpdateAction.decodeRecord(as:decoder:)` (PostgresAction.swift L40/L79), `channel.broadcastStream(event:)` → `AsyncStream<JSONObject>` (RealtimeChannel+AsyncAwait.swift L158), `channel.broadcast(event:message: some Codable) async throws` (RealtimeChannelV2.swift L293), `supabase.rpc(_:params:)` (PostgrestClient.swift L139, note it is `throws` before the `await .execute()`). **Broadcast nesting gotcha (verified in RealtimeChannelV2.swift L543–548):** the `JSONObject` yielded by `broadcastStream` is the WHOLE message payload; the sender's Codable message sits under its `"payload"` key. Decode `message["payload"]`, not the message itself.
4. **`PresenceDebugStore`** (`Vayl/Features/Sessions/Debug/PresenceDebugView.swift`, `#if DEBUG`) compiles against 2.48.0 and remains the ground truth for channel call shapes (listeners registered BEFORE `subscribeWithError()`, `track` after).
5. **Baseline migration** (`supabase/migrations/20260101000000_baseline.sql`): `is_couple_member(uuid)` L62 (SECURITY DEFINER, maps `auth.uid()` → `user_profiles.auth_id` → membership); `couples` table L173 (NO composition column today); `curated_sessions` L186 with `reveal_state jsonb DEFAULT '{}' NOT NULL` L204 and `REPLICA IDENTITY FULL` L211; one-open-per-couple partial unique index L361; `trg_curated_sessions_updated_at` BEFORE UPDATE trigger L369 (already bumps `updated_at` — the merge function sets it explicitly anyway, harmless); RLS policy `"couple members manage their curated session"` L570; realtime publication L600. Only `couple_id` has an FK on `curated_sessions` (L403) — `initiator_id` does not, which the pgTAP seed exploits.
6. **`AirlockStore` still does not exist** (plan 08 was never built). The spec's state names (`waitingForPartner → bothPresent → bandwidthSet → consented → activating → active` + `failed(reason)`) REPLACE plan 08's `lobby/airlock/active/error`. Plan 08's channel lifecycle, exactly-once flip, and poll-loop code survive inside the new shape.
7. **No service protocols exist anywhere in the app target** (`grep -rn "protocol.*Service" Vayl` → zero). Existing tests mock via closure seams (`CoupleSessionPlaythroughTests` injects `enqueueSync`; `presenceSeconds: 0.01` shortens waits). The AirlockStore tests below introduce the repo's first protocol seam (`AirlockTransport`) because the store consumes *streams*, which a closure seam cannot script cleanly.
8. **VaylTests pbxproj:** manual wiring confirmed; existing ids run `AA000001…` through `AA00000B…` in four places (PBXBuildFile ~L23–33, PBXFileReference ~L64–74, group children ~L166–176, Sources phase ~L367+). The new test file takes `AA00000C`.
9. **Prod drift standing risk:** prod ≠ `supabase/migrations` (known, e.g. `user_profiles.share_pulse_with_partner`). The migration segment below is written against the migration schema; the process guard is mandatory.

---

## Files (this section's scope only)

### Create

| File | Responsibility |
|---|---|
| `supabase/migrations/20260701000000_card_sessions_composition_and_reveal_merge.sql` | `couples.connection_composition` column + check; `update_reveal_state` deep-merge SECURITY DEFINER function; grants |
| `supabase/tests/card_sessions_invariants.test.sql` | pgTAP: composition constraint, merge preserves sibling keys, non-member rejected (11 assertions) |
| `Vayl/Core/Models/SessionPlan.swift` | Spec 4.1 value struct: tonight's card order + timers, maps 1:1 onto the `curated_sessions` plan columns |
| `Vayl/Core/Models/RevealEnvelope.swift` | Spec 4.1 broadcast payload for reveal mechanics (text / position / word). Never persisted |
| `Vayl/Features/Sessions/AirlockStore.swift` | The handshake brain: `AirlockTransport` seam + `LiveAirlockTransport` adapter + `@Observable @MainActor` store running `waitingForPartner → … → active`, poll fallback, exactly-once flip |
| `VaylTests/AirlockStoreTests.swift` | State-machine unit tests against `MockAirlockTransport` |

### Modify

| File | Line anchor | Change |
|---|---|---|
| `Vayl/Core/Services/RealtimeSessionService.swift` | `SessionRole` enum L38–45 | Add `sealedKey` computed property |
| `Vayl/Core/Services/RealtimeSessionService.swift` | `CuratedSessionDTO` L62–106 | Add `revealState: [String: RevealCardState]` + CodingKey; add `RevealCardState` struct above the DTO |
| `Vayl/Core/Services/RealtimeSessionService.swift` | after the presence extension (file ends L293) | Append two extensions: reveal-state RPC merge-writes + broadcast send/receive; postgres-changes stream + presence stream + plan 08's `flipToActiveIfBoth` / `heartbeatOpenSession` |
| `Vayl/Core/Models/Couple.swift` | after `sharedSafeWord`/`relationshipTenure` block L33–36, and `init` L63–80 | Add `connectionComposition: GenderDynamic` stored property + defaulted init parameter |
| `Vayl/App/ModelContainer.swift` | `SchemaV1.models` L42 | Remove `SessionPlan.self` (the `@Model` is deleted; the replacement is a plain struct, never registered) |
| `Vayl/Features/Sessions/Debug/PresenceDebugView.swift` | whole `#if DEBUG` body | Repoint the harness at the real `AirlockStore` (plan 08 Segment 4, adapted to the new state names) |
| `Vayl.xcodeproj/project.pbxproj` | four anchors, see Segment C4 | Wire `AirlockStoreTests.swift` into VaylTests (`AA00000C…` convention) |

### Delete

| File | Why |
|---|---|
| `Vayl/Features/Sessions/SessionPlan.swift` | Dead `@Model` (zero call sites beyond its own stub + SchemaV1 registration); collides with the spec's struct name. See Open Decision 1 |

**Do-not-touch within this section:** `CoupleSessionStore.swift`, `AirlockView.swift`, `CardSessionContainerView.swift`, `SessionPlayerView`, `SessionCloseView`, `PairingStore.swift` (the §9 composition-confirm touchpoint is Section 2's, see the handoff note at the end), the legacy `couple_session_records` table, `SessionSyncService`.

---

## Segment A1 — Migration: composition column + `update_reveal_state`

**One thing it does:** ships the single migration file the spec's section 8 defines: the `couples.connection_composition` column and the concurrent-safe jsonb deep-merge function for `curated_sessions.reveal_state`.

**Process guard (mandatory, before writing the file):** run `supabase db diff --linked` and reconcile any drift FIRST. Prod is known to have drifted from `supabase/migrations` (memory: `prod_schema_drift_from_migrations`). If the diff shows drift touching `couples` or `curated_sessions`, STOP and flag it — do not fold reconciliation into this migration and do not auto-apply anything. The Supabase MCP is read-only from Claude; applying to prod is Bryan's `supabase db push` after review. This pass only ADDS the file to `supabase/migrations/` and proves it on the local stack (`supabase start && supabase test db`).

**Exact changes** — create `supabase/migrations/20260701000000_card_sessions_composition_and_reveal_merge.sql`:

```sql
-- Card Sessions front-to-back, master segment A (spec 2026-07-01 §8).
--
-- 1. couples.connection_composition — which gendered card variants the couple
--    sees (Deck.cards(for:) filter). Wayfinding vocabulary, not identity.
-- 2. update_reveal_state — server-side deep merge for curated_sessions.reveal_state.
--    Clients only ever send their DELTA ({"card-07": {"a_sealed": true}}); the
--    function merges per-card sub-objects so concurrent seals from both partners
--    never clobber each other. SECURITY DEFINER (bypasses RLS to read+write the
--    row), therefore the explicit is_couple_member guard is load-bearing.

-- ── 1. connection_composition ────────────────────────────────────────────────

alter table "public"."couples"
  add column if not exists "connection_composition" text not null default 'flexible';

alter table "public"."couples"
  add constraint "couples_connection_composition_check"
  check ("connection_composition" in ('mf', 'mm', 'ff', 'flexible'));

comment on column "public"."couples"."connection_composition" is
  'Which gendered card variants this couple sees: mf | mm | ff | flexible. Default flexible. Set at pairing (one-tap confirm), changeable in Settings.';

-- ── 2. update_reveal_state ───────────────────────────────────────────────────
-- Merge semantics: for each card key in p_delta, the existing per-card object
-- and the delta's per-card object are merged (existing || delta), then the
-- result is merged over the whole column (existing || merged-cards). Sibling
-- card keys and sibling flags within a card are always preserved.
-- SELECT ... FOR UPDATE serializes two simultaneous seals on the same row.

create or replace function "public"."update_reveal_state"(
  "p_session_id" uuid,
  "p_delta" jsonb
) returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_couple_id uuid;
begin
  select couple_id into v_couple_id
  from curated_sessions
  where id = p_session_id
  for update;

  if v_couple_id is null then
    raise exception 'session not found';
  end if;

  if not is_couple_member(v_couple_id) then
    raise exception 'not a member of this couple';
  end if;

  if p_delta is null or jsonb_typeof(p_delta) <> 'object' then
    raise exception 'delta must be a jsonb object';
  end if;

  update curated_sessions cs
  set reveal_state = cs.reveal_state || coalesce(
        (
          select jsonb_object_agg(
                   d.key,
                   coalesce(cs.reveal_state -> d.key, '{}'::jsonb) || d.value
                 )
          from jsonb_each(p_delta) as d(key, value)
        ),
        '{}'::jsonb
      ),
      updated_at = now()
  where cs.id = p_session_id;
end;
$$;

alter function "public"."update_reveal_state"(uuid, jsonb) owner to "postgres";

revoke all on function "public"."update_reveal_state"(uuid, jsonb) from public;
revoke all on function "public"."update_reveal_state"(uuid, jsonb) from anon;
grant execute on function "public"."update_reveal_state"(uuid, jsonb) to authenticated;
grant execute on function "public"."update_reveal_state"(uuid, jsonb) to service_role;
```

Notes baked into the SQL, for the record: `updated_at = now()` is redundant with `trg_curated_sessions_updated_at` (baseline L369) but explicit per spec §8, and harmless. `add column if not exists` keeps the migration re-runnable against a drifted prod that might already carry the column.

**done:** `supabase test db` on the local stack runs this migration cleanly and the Segment A2 pgTAP file passes; the file is NOT applied to prod by this pass.

---

## Segment A2 — pgTAP invariants

**One thing it does:** proves the composition check constraint, the non-clobbering merge, and the non-member rejection, in the house pgTAP style (`begin; … plan(N); … finish(); rollback;`, synthetic fixed UUIDs, `session_replication_role = replica` seeding, `request.jwt.claim.sub` GUC impersonation — the exact pattern of `supabase/tests/desire_map_integration.test.sql`).

**Exact changes** — create `supabase/tests/card_sessions_invariants.test.sql`:

```sql
-- supabase/tests/card_sessions_invariants.test.sql
--
-- pgTAP invariants for the Card Sessions backend (spec 2026-07-01 §8):
--   1. couples.connection_composition exists, defaults to flexible, and the
--      check constraint rejects anything outside mf/mm/ff/flexible.
--   2. update_reveal_state deep-merges the delta: sibling flags within a card
--      and sibling card keys are preserved, never clobbered.
--   3. A non-member of the couple cannot call update_reveal_state (the
--      SECURITY DEFINER guard, since RLS does not apply inside it).
--
-- Runs on the LOCAL stack inside a transaction that rolls back:
--   supabase start && supabase test db
--
-- Impersonation: is_couple_member reads auth.uid(), which resolves from the
-- request.jwt.claim.sub GUC — setting the GUC is sufficient (no role switch
-- needed because the function under test is SECURITY DEFINER, not RLS-gated).

begin;
create extension if not exists pgtap with schema extensions;
set search_path to extensions, public;

select plan(11);

-- ── Seed (as superuser; FK triggers off while inserting synthetic identities) ──
set local session_replication_role = 'replica';

insert into public.user_profiles (id, auth_id) values
  ('a1a1a1a1-0000-0000-0000-000000000001', 'a0a0a0a0-0000-0000-0000-000000000001'),
  ('b1b1b1b1-0000-0000-0000-000000000002', 'b0b0b0b0-0000-0000-0000-000000000002'),
  ('c1c1c1c1-0000-0000-0000-000000000003', 'c0c0c0c0-0000-0000-0000-000000000003');

insert into public.couples (id, user_a, user_b) values
  ('c0117e00-0000-0000-0000-000000000001',
   'a1a1a1a1-0000-0000-0000-000000000001',
   'b1b1b1b1-0000-0000-0000-000000000002');

insert into public.curated_sessions
  (id, couple_id, initiator_id, deck_id, status, reveal_state) values
  ('5e551011-0000-0000-0000-000000000001',
   'c0117e00-0000-0000-0000-000000000001',
   'a1a1a1a1-0000-0000-0000-000000000001',
   'the-opener', 'active',
   '{"card-1": {"a_sealed": true}}'::jsonb);

set local session_replication_role = 'origin';

-- ── 1–4. connection_composition column + constraint ──────────────────────────

select has_column('public', 'couples', 'connection_composition',
  'couples.connection_composition exists');

select col_default_is('public', 'couples', 'connection_composition',
  $$'flexible'::text$$,
  'connection_composition defaults to flexible');

select throws_ok(
  $$update public.couples
      set connection_composition = 'xy'
      where id = 'c0117e00-0000-0000-0000-000000000001'$$,
  '23514', null,
  'connection_composition rejects values outside mf/mm/ff/flexible');

select lives_ok(
  $$update public.couples
      set connection_composition = 'mm'
      where id = 'c0117e00-0000-0000-0000-000000000001'$$,
  'connection_composition accepts mm');

-- ── 5–6. update_reveal_state exists and is SECURITY DEFINER ──────────────────

select has_function('public', 'update_reveal_state', array['uuid', 'jsonb'],
  'update_reveal_state(uuid, jsonb) exists');

select is_definer('public', 'update_reveal_state', array['uuid', 'jsonb'],
  'update_reveal_state is SECURITY DEFINER (so the member guard is load-bearing)');

-- ── 7–10. Merge semantics as partner B: deltas merge, siblings survive ───────

select set_config('request.jwt.claim.sub', 'b0b0b0b0-0000-0000-0000-000000000002', true);

select lives_ok(
  $$select public.update_reveal_state(
      '5e551011-0000-0000-0000-000000000001',
      '{"card-1": {"b_sealed": true}, "card-2": {"a_sealed": true}}'::jsonb)$$,
  'a couple member can call update_reveal_state');

select is(
  (select reveal_state -> 'card-1' ->> 'a_sealed'
     from public.curated_sessions
    where id = '5e551011-0000-0000-0000-000000000001'),
  'true',
  'merge preserves the sibling flag inside the same card (a_sealed untouched)');

select is(
  (select reveal_state -> 'card-1' ->> 'b_sealed'
     from public.curated_sessions
    where id = '5e551011-0000-0000-0000-000000000001'),
  'true',
  'merge lands the delta flag (b_sealed now true)');

select is(
  (select reveal_state -> 'card-2' ->> 'a_sealed'
     from public.curated_sessions
    where id = '5e551011-0000-0000-0000-000000000001'),
  'true',
  'merge adds a new card key without touching card-1');

-- ── 11. Non-member rejected ──────────────────────────────────────────────────

select set_config('request.jwt.claim.sub', 'c0c0c0c0-0000-0000-0000-000000000003', true);

select throws_ok(
  $$select public.update_reveal_state(
      '5e551011-0000-0000-0000-000000000001',
      '{"card-1": {"revealed": true}}'::jsonb)$$,
  'P0001', 'not a member of this couple',
  'a non-member of the couple cannot mutate reveal_state');

select * from finish();
rollback;
```

**done:** `supabase test db` reports the existing 38 assertions plus these 11, all green, on the local stack.

---

## Segment B1 — Service: reveal-state merge-writes + broadcast plumbing

**One thing it does:** gives `RealtimeSessionService` the reveal transport: `setSealed` / `setRevealed` / `clearRevealCard` via the `update_reveal_state` RPC (delta-only, never whole-column), `RevealCardState` decoding on the DTO, and the broadcast send/receive pair (`sendReveal` / `revealBroadcasts` + the lightweight resend request). Pure data access, as ever — no state, no Store/View/SwiftData.

**Exact changes to `Vayl/Core/Services/RealtimeSessionService.swift`:**

**(a)** In the `SessionRole` enum (L38–45), add one property after `presenceColumn`:

```swift
enum SessionRole: String, Sendable {
    case a
    case b

    var bandwidthColumn: String { self == .a ? "a_bandwidth" : "b_bandwidth" }
    var consentColumn: String   { self == .a ? "a_consented" : "b_consented" }
    var presenceColumn: String  { self == .a ? "a_present" : "b_present" }
    /// The seal flag this role owns inside a reveal_state per-card object.
    var sealedKey: String       { self == .a ? "a_sealed" : "b_sealed" }
}
```

**(b)** Directly above `CuratedSessionDTO` (L62), add the per-card reveal flags type, and replace the stale comment block at L57–60 (which says reveal_state is "intentionally omitted until Phase D") with the new reality:

```swift
// MARK: - RevealCardState (one card's flags inside curated_sessions.reveal_state)
// Shape on the wire (spec §6): {"card-07": {"a_sealed": true, "b_sealed": true, "revealed": true}}
// Absent flags mean false — the server only ever merges deltas in, so a card's
// object grows flag by flag. decodeIfPresent keeps partial objects valid.

struct RevealCardState: Codable, Sendable, Equatable {
    var aSealed: Bool
    var bSealed: Bool
    var revealed: Bool

    enum CodingKeys: String, CodingKey {
        case aSealed = "a_sealed"
        case bSealed = "b_sealed"
        case revealed
    }

    init(aSealed: Bool = false, bSealed: Bool = false, revealed: Bool = false) {
        self.aSealed = aSealed
        self.bSealed = bSealed
        self.revealed = revealed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        aSealed  = try container.decodeIfPresent(Bool.self, forKey: .aSealed)  ?? false
        bSealed  = try container.decodeIfPresent(Bool.self, forKey: .bSealed)  ?? false
        revealed = try container.decodeIfPresent(Bool.self, forKey: .revealed) ?? false
    }

    /// Whether a given role has sealed this card.
    func sealed(for role: SessionRole) -> Bool {
        role == .a ? aSealed : bSealed
    }
}
```

**(c)** In `CuratedSessionDTO`, add the field and its key (the column is `NOT NULL DEFAULT '{}'` so it is present on every select and, thanks to `REPLICA IDENTITY FULL`, on every postgres-changes record):

```swift
    let timerStartedAt: String?
    let revealState: [String: RevealCardState]
    let safeWordUsed: Bool
```

and in `CodingKeys`:

```swift
        case timerStartedAt = "timer_started_at"
        case revealState = "reveal_state"
        case safeWordUsed = "safe_word_used"
```

**(d)** Append this extension after the existing presence extension (file currently ends at L293):

```swift
// MARK: - Reveal state (merge-writes) + reveal broadcast
// Durable flags go through the update_reveal_state Postgres function — the
// client only ever sends its DELTA, the server deep-merges per card, so
// concurrent seals from both partners cannot clobber each other (spec §6).
// Ephemeral answer PAYLOADS ride Broadcast only and are never persisted.

extension RealtimeSessionService {

    private struct RevealStateParams: Encodable {
        let sessionId: UUID
        let delta: [String: [String: Bool]]

        enum CodingKeys: String, CodingKey {
            case sessionId = "p_session_id"
            case delta = "p_delta"
        }
    }

    /// Marks THIS role's seal flag on one card. Merge-write — never overwrites
    /// the partner's flag or sibling cards.
    func setSealed(sessionId: UUID, cardId: String, role: SessionRole) async throws {
        try await supabase
            .rpc("update_reveal_state", params: RevealStateParams(
                sessionId: sessionId,
                delta: [cardId: [role.sealedKey: true]]
            ))
            .execute()
    }

    /// Marks one card revealed (either device calls it after the countdown).
    func setRevealed(sessionId: UUID, cardId: String) async throws {
        try await supabase
            .rpc("update_reveal_state", params: RevealStateParams(
                sessionId: sessionId,
                delta: [cardId: ["revealed": true]]
            ))
            .execute()
    }

    /// Resets one card's flags (the reconnect re-prompt path: an in-flight
    /// broadcast answer was lost pre-reveal, so the card composes again).
    func clearRevealCard(sessionId: UUID, cardId: String) async throws {
        try await supabase
            .rpc("update_reveal_state", params: RevealStateParams(
                sessionId: sessionId,
                delta: [cardId: ["a_sealed": false, "b_sealed": false, "revealed": false]]
            ))
            .execute()
    }

    // MARK: Broadcast (ephemeral answer payloads + resend requests)

    /// Sends a sealed answer payload to the partner. Best-effort — the seal
    /// FLAG on the row is the durable authority; loss triggers the resend path.
    func sendReveal(_ envelope: RevealEnvelope, on channel: RealtimeChannelV2) async throws {
        try await channel.broadcast(event: BroadcastEvent.reveal, message: envelope)
    }

    /// Asks the partner to re-send their payload for one card (flag set on the
    /// row but the broadcast never arrived — RevealEngine's 5s watchdog).
    func requestResend(cardId: String, on channel: RealtimeChannelV2) async throws {
        try await channel.broadcast(event: BroadcastEvent.resend, message: ResendRequest(cardId: cardId))
    }

    /// Partner answer payloads arriving on the channel.
    /// SDK nesting (verified 2.48.0): broadcastStream yields the WHOLE message
    /// object; the Codable payload sits under its "payload" key.
    func revealBroadcasts(on channel: RealtimeChannelV2) -> AsyncStream<RevealEnvelope> {
        let raw = channel.broadcastStream(event: BroadcastEvent.reveal)
        return AsyncStream { continuation in
            let task = Task {
                for await message in raw {
                    guard let envelope = try? message["payload"]?.decode(as: RevealEnvelope.self) else {
                        logger.warning("reveal broadcast did not decode — ignored (resend path covers loss)")
                        continue
                    }
                    continuation.yield(envelope)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Partner resend requests arriving on the channel.
    func resendRequests(on channel: RealtimeChannelV2) -> AsyncStream<String> {
        let raw = channel.broadcastStream(event: BroadcastEvent.resend)
        return AsyncStream { continuation in
            let task = Task {
                for await message in raw {
                    guard let request = try? message["payload"]?.decode(as: ResendRequest.self) else {
                        logger.warning("resend request did not decode — ignored")
                        continue
                    }
                    continuation.yield(request.cardId)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

// MARK: - Broadcast wire types

private enum BroadcastEvent {
    static let reveal = "reveal"
    static let resend = "reveal_resend"
}

struct ResendRequest: Codable, Sendable {
    let cardId: String
}
```

**done:** the service compiles with `setSealed`/`setRevealed`/`clearRevealCard` (all RPC delta-writes), `sendReveal`/`requestResend`/`revealBroadcasts`/`resendRequests`, and `CuratedSessionDTO.revealState` decoding; no whole-column `reveal_state` write exists anywhere in the app target.

---

## Segment B2 — Service: presence + row streams and the plan 08 helpers

**One thing it does:** adds the two typed streams the handshake consumes (`presenceChanges(on:)`, `rowUpdates(on:sessionId:)`) and carries over plan 08's verified `flipToActiveIfBoth` + `heartbeatOpenSession` unchanged in behavior.

**Exact changes** — append after the Segment B1 extension in `Vayl/Core/Services/RealtimeSessionService.swift`:

```swift
// MARK: - Typed presence delta

/// One presence change on the session channel, reduced to profile-id strings.
struct PresenceDelta: Sendable {
    let joinedIds: Set<String>
    let leftIds: Set<String>
}

// MARK: - Realtime streams + poll fallback + active-flip guard
// The CONSUMER registers all listeners BEFORE subscribeWithError() and tracks
// AFTER (the PresenceDebugStore-proven ordering). The service stays a pure
// factory + helpers.

extension RealtimeSessionService {

    /// Presence joins/leaves on the session channel, keyed by profile id.
    /// Register BEFORE subscribing.
    func presenceChanges(on channel: RealtimeChannelV2) -> AsyncStream<PresenceDelta> {
        let presence = channel.presenceChange()
        return AsyncStream { continuation in
            let task = Task {
                for await change in presence {
                    continuation.yield(PresenceDelta(
                        joinedIds: Set(change.joins.keys),
                        leftIds: Set(change.leaves.keys)
                    ))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Every UPDATE to THIS session row, decoded to the full DTO (including
    /// reveal_state — REPLICA IDENTITY FULL guarantees the whole post-image).
    /// Filtered by session id per spec §4.2. Register BEFORE subscribing.
    /// An UPDATE that fails to decode is logged and skipped — the consumer
    /// re-fetches on silence (the poll fallback proves reconstructability).
    func rowUpdates(on channel: RealtimeChannelV2, sessionId: UUID) -> AsyncStream<CuratedSessionDTO> {
        // Snake_case columns are handled by CuratedSessionDTO's explicit
        // CodingKeys, so a plain decoder is correct (no keyDecodingStrategy).
        let decoder = JSONDecoder()
        let changes = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: SupabaseTable.curatedSessions,
            filter: .eq("id", value: sessionId.uuidString)
        )
        return AsyncStream { continuation in
            let task = Task {
                for await change in changes {
                    guard let record = try? change.decodeRecord(
                        as: CuratedSessionDTO.self, decoder: decoder
                    ) else {
                        logger.warning("curated_sessions UPDATE did not decode — consumer should re-fetch")
                        continue
                    }
                    continuation.yield(record)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Flips the row to `active` ONLY if it is still an open pre-active status
    /// (lobby/airlock) AND both partners are present AND both consented.
    /// Conditional on the server so a race between the two devices resolves to
    /// exactly one write. Returns true if THIS call performed the flip.
    /// Mirrors `advance(sessionId:expectedIndex:)`. (From plan 08, verified.)
    @discardableResult
    func flipToActiveIfBoth(sessionId: UUID) async throws -> Bool {
        let flipped: [CuratedSessionDTO] = try await supabase
            .from(SupabaseTable.curatedSessions)
            .update(["status": CuratedSessionStatus.active.rawValue])
            .eq("id", value: sessionId.uuidString)
            .in("status", values: [CuratedSessionStatus.lobby.rawValue,
                                   CuratedSessionStatus.airlock.rawValue])
            .eq("a_present", value: true)
            .eq("b_present", value: true)
            .eq("a_consented", value: true)
            .eq("b_consented", value: true)
            .select()
            .execute()
            .value

        return !flipped.isEmpty
    }

    /// Poll fallback tick (no realtime). Writes this device's presence
    /// heartbeat via the row, then reads the couple's open session back.
    /// Called on a timer by AirlockStore when realtime is unavailable.
    /// Modeled on PairingService.pollForClaim's re-fetch-per-tick shape but
    /// stateless — the loop lives in the Store. (From plan 08, verified.)
    func heartbeatOpenSession(coupleId: UUID, role: SessionRole) async throws -> CuratedSessionDTO? {
        if let open = try await fetchOpenSession(coupleId: coupleId) {
            try await setPresence(sessionId: open.id, role: role, present: true)
        }
        return try await fetchOpenSession(coupleId: coupleId)
    }
}
```

**done:** the service compiles with both streams and both helpers; `rowUpdates` filters by `id` (spec §4.2 — a deliberate change from plan 08's `couple_id` filter, now possible because the row always exists before the airlock subscribes); the service still has zero Store/View/SwiftData references and no `@Observable`.

---

## Segment C1 — Models: `SessionPlan` (struct), `RevealEnvelope`, `Couple.connectionComposition`, SchemaV1

**One thing it does:** lands the spec 4.1 value types, resolves the `SessionPlan` name collision, and extends the local `Couple`.

**(a) Delete `Vayl/Features/Sessions/SessionPlan.swift`** (the `@Model` — see Drift ledger item 1 and Open Decision 1). Then remove its registration: in `Vayl/App/ModelContainer.swift`, delete line 42:

```swift
        SessionPlan.self,
```

The replacement struct below is a plain value type and is NEVER added to `SchemaV1.models` (builder "same as last time" persistence is UserDefaults per spec 4.3, owned by the Builder section).

**(b) Create `Vayl/Core/Models/SessionPlan.swift`** — exactly the spec 4.1 shape, plus the one bridge the transport needs:

```swift
//
//  SessionPlan.swift
//  Vayl
//
//  Tonight's session shape — the Builder's output and openSession's input.
//  Maps 1:1 onto the curated_sessions plan columns (card_ids / per_card_timer /
//  global_timer_seconds / deck_variant). A plain value type: the LIVE session
//  state is the server row; "same as last time" persistence is UserDefaults
//  (Codable), keyed by deckId. Never registered in SchemaV1.
//
//  Replaces the dead @Model of the same name (deleted 2026-07-01; it had zero
//  call sites and predated the server-authoritative row design).
//

import Foundation

struct SessionPlan: Codable, Sendable {
    let deckId: String
    let cardIds: [String]                     // tonight's order, subset allowed
    let perCardTimerSeconds: [String: Int]?   // nil = untimed card
    let globalTimerSeconds: Int?              // nil = no session budget
    let deckVariant: String?                  // nil = authored order
}

extension SessionPlan {

    /// The value snapshot openSession writes to the row. Draft's timer dict is
    /// non-optional; a nil plan timer means "no per-card timers" = empty dict.
    var draft: CuratedSessionDraft {
        CuratedSessionDraft(
            deckId: deckId,
            deckVariant: deckVariant,
            cardIds: cardIds,
            perCardTimer: perCardTimerSeconds ?? [:],
            globalTimerSeconds: globalTimerSeconds
        )
    }
}
```

**(c) Create `Vayl/Core/Models/RevealEnvelope.swift`** — exactly the spec 4.1 shape:

```swift
//
//  RevealEnvelope.swift
//  Vayl
//
//  The Broadcast payload for reveal mechanics (whisper, unspoken, mirror,
//  snapshot, whatIf). EPHEMERAL BY DESIGN: sent only after the local seal,
//  buffered in the store until the reveal fires, NEVER persisted anywhere.
//  Durable truth is only the seal/reveal FLAGS in curated_sessions.reveal_state.
//
//  Codable synthesis on the Body enum produces case-keyed nesting
//  ({"text": {"_0": "..."}}) — both devices use the same coder, so the wire
//  shape is symmetric and private to the app.
//

import Foundation

struct RevealEnvelope: Codable, Sendable {
    let cardId: String
    let role: SessionRole          // sender
    let body: Body

    enum Body: Codable, Sendable {
        case text(String)          // whisper, whatIf, mirror answers
        case position(Double)      // unspoken slider 0.0-1.0
        case word(String)          // snapshot single word
    }
}
```

(`SessionRole` is `String`-raw and `Sendable` already; conforming it to `Codable` is required for synthesis — add `Codable` to its declaration in `RealtimeSessionService.swift` L38: `enum SessionRole: String, Codable, Sendable`.)

**(d) Modify `Vayl/Core/Models/Couple.swift`** — after the Shared Config block (L33–36) add:

```swift
    // MARK: - Connection Composition
    // Which gendered card variants this couple sees (mf / mm / ff / flexible).
    // Wayfinding vocabulary, never identity: derived from both partners' OB
    // gender answers at pairing (one-tap confirm), changeable in Settings,
    // consumed by Deck.cards(for:). Mirrors couples.connection_composition.

    var connectionComposition: GenderDynamic = GenderDynamic.flexible
```

and in `init` (L63–80) add the defaulted parameter and assignment so existing call sites are untouched:

```swift
    init(
        partnerAId: UUID,
        partnerBId: UUID,
        connectionType: ConnectionPlan = .primary,
        relationshipTenure: RelationshipTenure? = nil,
        connectionComposition: GenderDynamic = .flexible
    ) {
        ...existing body unchanged...
        self.connectionComposition = connectionComposition
    }
```

`GenderDynamic` (`Vayl/Core/Models/Enums/AppCardEnums.swift` L164) is already `String, CaseIterable, Codable` — SwiftData stores it as its raw value. The inline `= GenderDynamic.flexible` default is what lets SwiftData lightweight-migrate an existing store that lacks the attribute. **SchemaV1 note:** this pass changes SchemaV1 twice (adds a `Couple` attribute, removes the `SessionPlan` entity). `AppMigrationPlan.stages` stays empty — correct pre-launch per the file's own comment — but flag to Bryan that dev devices with an existing `Vayl.store` may need a delete-and-reinstall if launch crashes on schema mismatch.

**done:** the target compiles with exactly one `SessionPlan` type (the struct), `RevealEnvelope` round-trips through `JSONEncoder`/`JSONDecoder`, and `Couple(partnerAId:partnerBId:)` still compiles unchanged at every existing call site.

---

## Segment C2 — `AirlockStore`: transport seam + the spec state machine

**One thing it does:** creates the handshake brain per spec 4.3, absorbing plan 08's verified channel lifecycle, exactly-once flip, and poll loop into the new state ladder — behind a protocol seam so the state machine is unit-testable without a network.

**Design (one paragraph, since it departs from plan 08 in shape):** plan 08 had the store hold the concrete `RealtimeSessionService` and the `RealtimeChannelV2` directly. The spec's test mandate (§11: "AirlockStore state machine against a mock RealtimeSessionService") requires a seam, and the store's inputs are *streams*, which the repo's existing closure-seam convention can't script. So: `AirlockTransport` (protocol) is everything the store consumes; `LiveAirlockTransport` (final class, same file) is the production conformance that owns the channel and delegates every call to `RealtimeSessionService` — the service itself stays a pure factory + helpers, and no View ever sees any of this. The store remains `@Observable @MainActor final class` modeled on `PairingStore`.

**Exact changes** — create `Vayl/Features/Sessions/AirlockStore.swift`:

```swift
//
//  AirlockStore.swift
//  Vayl
//
//  The two-device "both here → active" handshake brain (spec 2026-07-01 §4.3).
//  Owns ONLY the handshake: the curated_sessions channel (via AirlockTransport),
//  this device's SessionRole, the bandwidth + consent ladder, and the
//  server-authoritative flip to `active`. It does NOT own the card flow — that
//  stays in CoupleSessionStore. Wiring into the real .vaylCover is Section 2.
//
//  States: waitingForPartner → bothPresent → bandwidthSet → consented →
//  activating → active, plus failed(reason). The ladder is recomputed from
//  facts (partner presence, my commits) so a partner leaving pre-active drops
//  the ladder back; activating/active/failed are sticky.
//
//  Identity rule (hard): role derives from couple.partnerAId == myProfileId
//  where myProfileId is local SwiftData UserProfile.id. NEVER the auth id.
//
//  Poll fallback: transport connect failure OR no presence signal within
//  presenceTimeout (10s) drops to a 2s row-poll loop — same state machine,
//  worse latency, identical behavior (the row reconstructs everything).
//

import Foundation
import SwiftData
import Supabase
import OSLog

private let logger = Logger(subsystem: "com.vayl.app", category: "AirlockStore")

// MARK: - AirlockTransport (the store's seam — mocked in VaylTests)

/// Everything the handshake consumes. LiveAirlockTransport is the production
/// conformance; MockAirlockTransport (VaylTests) scripts the streams.
protocol AirlockTransport: AnyObject {
    func fetchOpenSession(coupleId: UUID) async throws -> CuratedSessionDTO?
    func setBandwidth(sessionId: UUID, role: SessionRole, value: Float) async throws
    func setConsent(sessionId: UUID, role: SessionRole, consented: Bool) async throws
    func setPresence(sessionId: UUID, role: SessionRole, present: Bool) async throws
    func flipToActiveIfBoth(sessionId: UUID) async throws -> Bool
    func heartbeatOpenSession(coupleId: UUID, role: SessionRole) async throws -> CuratedSessionDTO?
    /// Subscribes the channel and returns the live streams. Throws on
    /// subscribe failure (the store falls back to polling).
    func connect(coupleId: UUID, profileId: UUID, sessionId: UUID) async throws -> AirlockStreams
    func disconnect() async
}

/// The two live streams the airlock consumes. (Reveal broadcasts are the
/// player's concern — SessionSyncCoordinator, Section 2 — not the airlock's.)
struct AirlockStreams {
    let presence: AsyncStream<PresenceDelta>
    let rows: AsyncStream<CuratedSessionDTO>
}

// MARK: - LiveAirlockTransport (production conformance)

/// Owns the RealtimeChannelV2 lifecycle so the service stays a pure factory.
/// Ordering is load-bearing (PresenceDebugStore-proven): register BOTH stream
/// listeners BEFORE subscribeWithError(), track ONLY AFTER it succeeds.
final class LiveAirlockTransport: AirlockTransport {

    private let service: RealtimeSessionService
    private var channel: RealtimeChannelV2?

    init(service: RealtimeSessionService = RealtimeSessionService()) {
        self.service = service
    }

    func fetchOpenSession(coupleId: UUID) async throws -> CuratedSessionDTO? {
        try await service.fetchOpenSession(coupleId: coupleId)
    }

    func setBandwidth(sessionId: UUID, role: SessionRole, value: Float) async throws {
        try await service.setBandwidth(sessionId: sessionId, role: role, value: value)
    }

    func setConsent(sessionId: UUID, role: SessionRole, consented: Bool) async throws {
        try await service.setConsent(sessionId: sessionId, role: role, consented: consented)
    }

    func setPresence(sessionId: UUID, role: SessionRole, present: Bool) async throws {
        try await service.setPresence(sessionId: sessionId, role: role, present: present)
    }

    func flipToActiveIfBoth(sessionId: UUID) async throws -> Bool {
        try await service.flipToActiveIfBoth(sessionId: sessionId)
    }

    func heartbeatOpenSession(coupleId: UUID, role: SessionRole) async throws -> CuratedSessionDTO? {
        try await service.heartbeatOpenSession(coupleId: coupleId, role: role)
    }

    func connect(coupleId: UUID, profileId: UUID, sessionId: UUID) async throws -> AirlockStreams {
        let channel = service.sessionChannel(coupleId: coupleId, userId: profileId)
        self.channel = channel
        // Listeners BEFORE subscribe.
        let presence = service.presenceChanges(on: channel)
        let rows = service.rowUpdates(on: channel, sessionId: sessionId)
        try await channel.subscribeWithError()
        // Track AFTER subscribe.
        try await service.trackPresence(on: channel, userId: profileId)
        return AirlockStreams(presence: presence, rows: rows)
    }

    func disconnect() async {
        if let channel {
            self.channel = nil
            await service.leaveChannel(channel)
        }
    }
}

// MARK: - AirlockState

enum AirlockState: Equatable {
    case waitingForPartner
    case bothPresent
    case bandwidthSet
    case consented
    case activating
    case active(sessionId: UUID)
    case failed(reason: String)
}

// MARK: - AirlockStore

@Observable
@MainActor
final class AirlockStore {

    // MARK: - Public state (read surfaces for AirlockView / the harness)

    private(set) var state: AirlockState = .waitingForPartner
    /// Live transport mode. Flips to `.poll` on connect failure or presence timeout.
    private(set) var transport: Transport = .realtime
    private(set) var partnerPresent = false
    private(set) var selfBandwidthCommitted = false
    private(set) var selfConsented = false
    private(set) var partnerConsented = false
    private(set) var session: CuratedSessionDTO?

    /// min(a_bandwidth, b_bandwidth) once BOTH are on the row — the session's
    /// depth ceiling (spec §4.3). Each device computes it independently and
    /// deterministically; neither partner's raw reading is ever displayed.
    var depthCeiling: Float? {
        guard let a = session?.aBandwidth, let b = session?.bBandwidth else { return nil }
        return min(a, b)
    }

    enum Transport: String { case realtime, poll }

    // MARK: - Identity

    let coupleId: UUID
    let myProfileId: UUID
    let role: SessionRole

    private var partnerRole: SessionRole { role == .a ? .b : .a }

    // MARK: - Dependencies + tunables

    private let transportLayer: AirlockTransport
    /// 🎚️ Seconds with no presence signal before dropping to poll (default 10).
    private let presenceTimeout: TimeInterval
    /// 🎚️ Poll heartbeat interval in seconds (default 2).
    private let pollInterval: TimeInterval

    // MARK: - Private lifecycle

    private var presenceTask: Task<Void, Never>?
    private var rowsTask: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?
    private var pollTask: Task<Void, Never>?
    /// Any presence OR row signal proves the pipe is live and cancels the timeout.
    private var sawAnySignal = false
    /// The SERVER flip is idempotent (conditional update); this only avoids
    /// re-issuing it locally.
    private var didRequestFlip = false

    // MARK: - Init

    init(
        coupleId: UUID,
        myProfileId: UUID,
        role: SessionRole,
        transport: AirlockTransport = LiveAirlockTransport(),
        presenceTimeout: TimeInterval = 10,
        pollInterval: TimeInterval = 2
    ) {
        self.coupleId = coupleId
        self.myProfileId = myProfileId
        self.role = role
        self.transportLayer = transport
        self.presenceTimeout = presenceTimeout
        self.pollInterval = pollInterval
    }

    /// Resolves this device's role from the LOCAL Couple (profile-id keyed).
    /// partnerAId == myProfileId → .a, else .b. NEVER supabase.auth's user id.
    /// Returns nil if the couple / profile can't be resolved locally (caller
    /// shows an error state).
    static func make(
        coupleId: UUID,
        modelContainer: ModelContainer,
        transport: AirlockTransport = LiveAirlockTransport()
    ) -> AirlockStore? {
        let context = ModelContext(modelContainer)
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else {
            logger.error("make — no local UserProfile")
            return nil
        }
        var coupleFetch = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
        coupleFetch.fetchLimit = 1
        guard let couple = try? context.fetch(coupleFetch).first else {
            logger.error("make — no local Couple \(coupleId)")
            return nil
        }
        let role: SessionRole = (couple.partnerAId == profile.id) ? .a : .b
        return AirlockStore(
            coupleId: coupleId,
            myProfileId: profile.id,
            role: role,
            transport: transport
        )
    }

    // MARK: - Entry

    /// The row is opened by the Builder/Lobby BEFORE the airlock (spec §5
    /// lifecycle) — the airlock only ever fetches. No open row = failed.
    func start() async {
        do {
            guard let row = try await transportLayer.fetchOpenSession(coupleId: coupleId) else {
                state = .failed(reason: "No open session for this couple.")
                return
            }
            session = row
            applyRow(row)
        } catch {
            logger.warning("fetch failed, dropping to poll: \(error.localizedDescription)")
            startPollFallback()
            return
        }

        guard let sessionId = session?.id else { return }

        let streams: AirlockStreams
        do {
            streams = try await transportLayer.connect(
                coupleId: coupleId, profileId: myProfileId, sessionId: sessionId
            )
            // Presence heartbeat boolean on the row too, so a poll-mode partner
            // still sees us (spec §4.3).
            try await transportLayer.setPresence(sessionId: sessionId, role: role, present: true)
            transport = .realtime
        } catch {
            logger.warning("connect failed, dropping to poll: \(error.localizedDescription)")
            await transportLayer.disconnect()
            startPollFallback()
            return
        }

        // Presence stream: partner joins/leaves, keyed by profile id.
        presenceTask = Task { [weak self] in
            guard let self else { return }
            for await delta in streams.presence {
                self.sawAnySignal = true
                let mine = self.myProfileId.uuidString
                if delta.joinedIds.contains(where: { $0 != mine }) { self.partnerPresent = true }
                if delta.leftIds.contains(where: { $0 != mine }) { self.partnerPresent = false }
                self.recomputeLadder()
                await self.tryFlipToActive()
            }
        }

        // Row stream: mirror partner facts + status, then check the flip.
        rowsTask = Task { [weak self] in
            guard let self else { return }
            for await row in streams.rows {
                self.sawAnySignal = true
                self.session = row
                self.applyRow(row)
                await self.tryFlipToActive()
            }
        }

        // No presence signal within the window → assume realtime is dead
        // (spec §4.3) and drop to poll.
        timeoutTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(self.presenceTimeout))
            guard !Task.isCancelled, !self.sawAnySignal, self.transport == .realtime else { return }
            logger.warning("no presence signal within \(self.presenceTimeout)s — dropping to poll")
            await self.dropToPoll()
        }
    }

    // MARK: - UI actions (this device)

    /// Bandwidth slider commit (Light/Open/Deep detent as a 0-1 Float).
    /// Set privately; the raw reading is never shown to the partner.
    func commitBandwidth(_ value: Float) async {
        guard let sessionId = session?.id else { return }
        do {
            try await transportLayer.setBandwidth(sessionId: sessionId, role: role, value: value)
            selfBandwidthCommitted = true
            recomputeLadder()
        } catch {
            logger.warning("bandwidth push failed: \(error.localizedDescription)")
        }
    }

    /// The 3-second lock-in press completes → this device consents.
    func consent() async {
        guard let sessionId = session?.id else { return }
        do {
            try await transportLayer.setConsent(sessionId: sessionId, role: role, consented: true)
            selfConsented = true
            recomputeLadder()
            await tryFlipToActive()
        } catch {
            logger.warning("consent push failed: \(error.localizedDescription)")
        }
    }

    // MARK: - State ladder

    /// Recomputes the pre-activation ladder from facts. activating / active /
    /// failed are sticky and never regress from here.
    private func recomputeLadder() {
        switch state {
        case .activating, .active, .failed: return
        default: break
        }
        if selfConsented {
            state = .consented
        } else if selfBandwidthCommitted, partnerPresent {
            state = .bandwidthSet
        } else if partnerPresent {
            state = .bothPresent
        } else {
            state = .waitingForPartner
        }
    }

    /// Mirrors the row's partner-side facts + status into local state. Row
    /// presence booleans are the backstop for a poll-mode partner.
    private func applyRow(_ row: CuratedSessionDTO) {
        let partnerPresentInRow = (partnerRole == .a) ? row.aPresent : row.bPresent
        if partnerPresentInRow { partnerPresent = true }
        partnerConsented = (partnerRole == .a) ? row.aConsented : row.bConsented
        selfConsented = selfConsented || ((role == .a) ? row.aConsented : row.bConsented)
        let myBandwidthInRow = (role == .a) ? row.aBandwidth : row.bBandwidth
        if myBandwidthInRow != nil { selfBandwidthCommitted = true }

        if row.status == CuratedSessionStatus.active.rawValue {
            state = .active(sessionId: row.id)
        } else {
            recomputeLadder()
        }
    }

    /// The EXACTLY-ONCE active flip. The server update is conditional (both
    /// present + both consented + still pre-active), so if both devices call
    /// it simultaneously exactly one write lands. Both devices then react to
    /// the row UPDATE, never to their own optimistic write (spec §4.3) —
    /// except in poll mode, where the winner advances locally.
    private func tryFlipToActive() async {
        if case .active = state { return }
        if case .failed = state { return }
        guard let sessionId = session?.id else { return }
        guard partnerPresent, selfConsented, partnerConsented, !didRequestFlip else { return }
        didRequestFlip = true
        state = .activating
        do {
            let didFlip = try await transportLayer.flipToActiveIfBoth(sessionId: sessionId)
            logger.info("flipToActive requested — thisDeviceWon=\(didFlip)")
            if didFlip, transport == .poll {
                state = .active(sessionId: sessionId)
            }
        } catch {
            didRequestFlip = false   // allow a retry on the next signal
            recomputeLadder()
            logger.warning("flipToActive failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Poll fallback

    private func dropToPoll() async {
        presenceTask?.cancel(); presenceTask = nil
        rowsTask?.cancel(); rowsTask = nil
        await transportLayer.disconnect()
        startPollFallback()
    }

    /// Every pollInterval seconds: presence heartbeat + row re-read + ladder +
    /// flip check. Runs ONLY when realtime failed or timed out — it never
    /// regresses the realtime path.
    private func startPollFallback() {
        transport = .poll
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                do {
                    if let row = try await self.transportLayer.heartbeatOpenSession(
                        coupleId: self.coupleId, role: self.role
                    ) {
                        self.session = row
                        self.applyRow(row)
                        await self.tryFlipToActive()
                        if case .active = self.state { break }
                    }
                } catch {
                    logger.warning("poll tick failed: \(error.localizedDescription)")
                }
                try? await Task.sleep(for: .seconds(self.pollInterval))
            }
        }
    }

    /// Debug/testing hook: force the poll path even if realtime is up.
    func forcePollMode() async {
        timeoutTask?.cancel(); timeoutTask = nil
        await dropToPoll()
    }

    // MARK: - Teardown

    /// Clean exit: presence boolean false on the row (spec §4.3), streams down.
    func leave() {
        presenceTask?.cancel(); presenceTask = nil
        rowsTask?.cancel(); rowsTask = nil
        timeoutTask?.cancel(); timeoutTask = nil
        pollTask?.cancel(); pollTask = nil
        let transportLayer = self.transportLayer
        let role = self.role
        let sessionId = session?.id
        Task {
            if let sessionId {
                try? await transportLayer.setPresence(sessionId: sessionId, role: role, present: false)
            }
            await transportLayer.disconnect()
        }
    }
}
```

**done:** `AirlockStore.swift` compiles; the ladder runs `waitingForPartner → bothPresent → bandwidthSet → consented → activating → active` with `failed(reason)`; role comes from `Couple.partnerAId == UserProfile.id` (profile id, never auth id); connect failure and the 10s presence silence both drop to the 2s poll loop; the flip is server-conditional + locally guarded.

---

## Segment C3 — Debug harness repoint (plan 08 Segment 4, adapted)

**One thing it does:** repoints the `#if DEBUG` `PresenceDebugView` at the real `AirlockStore` so two physical devices can drive the whole handshake before Section 2's real Airlock UI exists. One deliberate change from plan 08: the harness must now OPEN the row itself (the store only fetches), so the driver calls `RealtimeSessionService.openSession` directly with a stub draft — acceptable in a `#if DEBUG` throwaway, never in shipping code.

**Exact changes** — replace the body of `Vayl/Features/Sessions/Debug/PresenceDebugView.swift` (keep `#if DEBUG` / `#endif`). Reuse plan 08's Segment 4 harness verbatim EXCEPT: the driver gains an `openRow()` step, `Consent` becomes two buttons (`Bandwidth` committing `0.55`, then `Lock in`), and the readout's `stateLabel` maps the new enum:

```swift
    private func stateLabel(_ s: AirlockState) -> String {
        switch s {
        case .waitingForPartner:      return "waiting for partner"
        case .bothPresent:            return "both present"
        case .bandwidthSet:           return "bandwidth set"
        case .consented:              return "consented"
        case .activating:             return "activating"
        case .active:                 return "ACTIVE"
        case .failed(let reason):     return "failed: \(reason)"
        }
    }
```

and the driver's open/start pair:

```swift
    func openRow() {
        guard let coupleId = UUID(uuidString: coupleIdText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            status = "Couple ID must be a valid UUID."; return
        }
        Task {
            do {
                let context = ModelContext(modelContainer)
                guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else {
                    status = "No local UserProfile."; return
                }
                let draft = CuratedSessionDraft(
                    deckId: "debug", deckVariant: nil,
                    cardIds: [], perCardTimer: [:], globalTimerSeconds: nil
                )
                _ = try await RealtimeSessionService().openSession(
                    coupleId: coupleId, initiatorId: profile.id, draft: draft
                )
                status = "row opened — now Start on both devices"
            } catch {
                status = "open failed: \(error.localizedDescription)"
            }
        }
    }

    func startStore() {
        guard let coupleId = UUID(uuidString: coupleIdText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            status = "Couple ID must be a valid UUID."; return
        }
        guard let s = AirlockStore.make(coupleId: coupleId, modelContainer: modelContainer) else {
            status = "Could not resolve local Couple / UserProfile."; return
        }
        store = s
        status = "role \(s.role.rawValue) · starting"
        Task { await s.start() }
    }

    func bandwidth() { Task { await store?.commitBandwidth(0.55) } }
    func lockIn()    { Task { await store?.consent() } }
    func forcePoll() { Task { await store?.forcePollMode() } }
    func leave()     { store?.leave(); store = nil; status = "left" }
```

Everything else (the SwiftUI body with `AppSpacing.lg/md/sm/xs`, `AppFonts.screenTitle/caption/bodyMedium/cardTitle`, `AppColors.pageBackground/textPrimary/textSecondary/textTertiary/textBody`, `VaylButton`, `InteractiveField`, the empty state block) carries over from plan 08 Segment 4 unchanged — those tokens and components are all used by the CURRENT `PresenceDebugView.swift`, so they exist; read the token files while building and note any drift rather than inventing names. Button row becomes: `Open row` / `Start` on one line, `Bandwidth` / `Lock in` on the next, `Force poll` / `Leave` on the third, with the live readout showing `transport`, `state`, `partner present`, `you consented`, `partner consented`, and `depth ceiling` (`store.depthCeiling.map { String(format: "%.2f", $0) } ?? "-"`).

**done:** the harness compiles under `#if DEBUG`, drives the full ladder from a pasted Couple ID, and is excluded from release builds.

---

## Segment C4 — VaylTests: `AirlockStoreTests` + pbxproj wiring

**One thing it does:** proves the state machine against `MockAirlockTransport`: the happy ladder, the idempotent flip, the connect-failure poll path, the presence-timeout poll path, and role derivation.

**pbxproj wiring (VaylTests is a manual PBXGroup — the app target auto-joins, the test target does not).** Four insertions in `Vayl.xcodeproj/project.pbxproj`, continuing the `AA00000N` convention (last used: `AA00000B` for PulseHistoryTests):

1. PBXBuildFile section (after line 33's PulseHistoryTests entry):
   `AA00000CAAAA000000000001 /* AirlockStoreTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA00000CAAAA000000000002 /* AirlockStoreTests.swift */; };`
2. PBXFileReference section (after line 74):
   `AA00000CAAAA000000000002 /* AirlockStoreTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AirlockStoreTests.swift; sourceTree = "<group>"; };`
3. The `AA000001AAAA000000000003 /* VaylTests */` group's `children` array (after line 176):
   `AA00000CAAAA000000000002 /* AirlockStoreTests.swift */,`
4. The VaylTests Sources build phase `files` array (after the PulseHistoryTests line near line 377):
   `AA00000CAAAA000000000001 /* AirlockStoreTests.swift in Sources */,`

**Exact changes** — create `VaylTests/AirlockStoreTests.swift`:

```swift
//
//  AirlockStoreTests.swift
//  VaylTests
//
//  AirlockStore state machine against MockAirlockTransport — presence orders,
//  the poll fallback paths, the idempotent active flip, and role derivation
//  from the LOCAL profile id (never the auth id). No network, no channel.
//
//  Style note: whole-suite @MainActor + a polling waitUntil, matching
//  CoupleSessionPlaythroughTests. Timeouts are injected tiny so the poll and
//  presence-timeout paths resolve in milliseconds.
//

import XCTest
import SwiftData
@testable import Vayl

// MARK: - Mock transport

@MainActor
final class MockAirlockTransport: AirlockTransport {

    var openRow: CuratedSessionDTO?
    var connectError: Error?
    var flipResult = true
    private(set) var flipCount = 0
    private(set) var presenceWrites: [(role: SessionRole, present: Bool)] = []
    private(set) var consentWrites: [SessionRole] = []
    private(set) var bandwidthWrites: [(role: SessionRole, value: Float)] = []
    private(set) var heartbeatCount = 0
    /// Rows the poll loop hands back, consumed front-first; last repeats.
    var heartbeatRows: [CuratedSessionDTO] = []

    private(set) var presenceContinuation: AsyncStream<PresenceDelta>.Continuation?
    private(set) var rowsContinuation: AsyncStream<CuratedSessionDTO>.Continuation?

    struct MockError: Error {}

    func fetchOpenSession(coupleId: UUID) async throws -> CuratedSessionDTO? { openRow }

    func setBandwidth(sessionId: UUID, role: SessionRole, value: Float) async throws {
        bandwidthWrites.append((role, value))
    }

    func setConsent(sessionId: UUID, role: SessionRole, consented: Bool) async throws {
        consentWrites.append(role)
    }

    func setPresence(sessionId: UUID, role: SessionRole, present: Bool) async throws {
        presenceWrites.append((role, present))
    }

    func flipToActiveIfBoth(sessionId: UUID) async throws -> Bool {
        flipCount += 1
        return flipResult
    }

    func heartbeatOpenSession(coupleId: UUID, role: SessionRole) async throws -> CuratedSessionDTO? {
        heartbeatCount += 1
        guard !heartbeatRows.isEmpty else { return openRow }
        return heartbeatRows.count > 1 ? heartbeatRows.removeFirst() : heartbeatRows[0]
    }

    func connect(coupleId: UUID, profileId: UUID, sessionId: UUID) async throws -> AirlockStreams {
        if let connectError { throw connectError }
        let (presence, presenceCont) = AsyncStream<PresenceDelta>.makeStream()
        let (rows, rowsCont) = AsyncStream<CuratedSessionDTO>.makeStream()
        presenceContinuation = presenceCont
        rowsContinuation = rowsCont
        return AirlockStreams(presence: presence, rows: rows)
    }

    func disconnect() async {
        presenceContinuation?.finish()
        rowsContinuation?.finish()
    }
}

// MARK: - Row fixtures

private func makeRow(
    id: UUID = UUID(),
    coupleId: UUID,
    status: CuratedSessionStatus = .airlock,
    aPresent: Bool = false, bPresent: Bool = false,
    aBandwidth: Float? = nil, bBandwidth: Float? = nil,
    aConsented: Bool = false, bConsented: Bool = false
) -> CuratedSessionDTO {
    CuratedSessionDTO(
        id: id,
        coupleId: coupleId,
        initiatorId: UUID(),
        deckId: "the-opener",
        deckVariant: nil,
        cardIds: [],
        perCardTimer: [:],
        globalTimerSeconds: nil,
        status: status.rawValue,
        currentIndex: 0,
        aPresent: aPresent,
        bPresent: bPresent,
        aBandwidth: aBandwidth,
        bBandwidth: bBandwidth,
        aConsented: aConsented,
        bConsented: bConsented,
        timerStartedAt: nil,
        revealState: [:],
        safeWordUsed: false,
        createdAt: "2026-07-01T00:00:00Z",
        updatedAt: "2026-07-01T00:00:00Z"
    )
}

// MARK: - Tests

@MainActor
final class AirlockStoreTests: XCTestCase {

    private func waitUntil(_ message: String,
                           timeout: TimeInterval = 4,
                           _ condition: () -> Bool) async {
        let start = Date()
        while !condition() {
            if Date().timeIntervalSince(start) > timeout {
                XCTFail("Timed out waiting: \(message)")
                return
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    private func makeStore(
        mock: MockAirlockTransport,
        coupleId: UUID,
        role: SessionRole = .a,
        presenceTimeout: TimeInterval = 60   // effectively off unless a test wants it
    ) -> AirlockStore {
        AirlockStore(
            coupleId: coupleId,
            myProfileId: UUID(),
            role: role,
            transport: mock,
            presenceTimeout: presenceTimeout,
            pollInterval: 0.02
        )
    }

    // MARK: Ladder

    func testHappyPathLadderReachesActive() async {
        let coupleId = UUID()
        let sessionId = UUID()
        let mock = MockAirlockTransport()
        mock.openRow = makeRow(id: sessionId, coupleId: coupleId)
        let store = makeStore(mock: mock, coupleId: coupleId, role: .a)

        await store.start()
        XCTAssertEqual(store.state, .waitingForPartner)
        XCTAssertEqual(store.transport, .realtime)
        // Presence heartbeat boolean written on connect.
        XCTAssertTrue(mock.presenceWrites.contains { $0.role == .a && $0.present })

        // Partner joins.
        mock.presenceContinuation?.yield(PresenceDelta(joinedIds: [UUID().uuidString], leftIds: []))
        await waitUntil("both present") { store.state == .bothPresent }

        // I commit bandwidth.
        await store.commitBandwidth(0.55)
        XCTAssertEqual(store.state, .bandwidthSet)
        XCTAssertEqual(mock.bandwidthWrites.first?.value, 0.55)

        // I lock in.
        await store.consent()
        XCTAssertEqual(store.state, .consented)
        XCTAssertEqual(mock.consentWrites, [.a])

        // Partner's consent arrives on the row → activating → flip requested.
        mock.rowsContinuation?.yield(makeRow(
            id: sessionId, coupleId: coupleId,
            aPresent: true, bPresent: true,
            aBandwidth: 0.55, bBandwidth: 0.25,
            aConsented: true, bConsented: true
        ))
        await waitUntil("flip requested") { mock.flipCount == 1 }

        // Depth ceiling = min of the two readings, computed locally.
        XCTAssertEqual(store.depthCeiling, 0.25)

        // The row flips (server-authoritative) → both devices go active on the UPDATE.
        mock.rowsContinuation?.yield(makeRow(
            id: sessionId, coupleId: coupleId, status: .active,
            aPresent: true, bPresent: true,
            aBandwidth: 0.55, bBandwidth: 0.25,
            aConsented: true, bConsented: true
        ))
        await waitUntil("active") { store.state == .active(sessionId: sessionId) }
    }

    func testActiveFlipIsIdempotent() async {
        let coupleId = UUID()
        let sessionId = UUID()
        let mock = MockAirlockTransport()
        mock.openRow = makeRow(id: sessionId, coupleId: coupleId)
        let store = makeStore(mock: mock, coupleId: coupleId, role: .a)

        await store.start()
        mock.presenceContinuation?.yield(PresenceDelta(joinedIds: [UUID().uuidString], leftIds: []))
        await store.consent()

        let bothConsented = makeRow(
            id: sessionId, coupleId: coupleId,
            aPresent: true, bPresent: true,
            aConsented: true, bConsented: true
        )
        // The same both-consented row lands three times (dupe UPDATEs happen).
        mock.rowsContinuation?.yield(bothConsented)
        mock.rowsContinuation?.yield(bothConsented)
        mock.rowsContinuation?.yield(bothConsented)

        await waitUntil("flip requested once") { mock.flipCount >= 1 }
        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(mock.flipCount, 1, "didRequestFlip must gate re-issues locally")
    }

    func testPartnerLeavingRegressesLadder() async {
        let coupleId = UUID()
        let mock = MockAirlockTransport()
        mock.openRow = makeRow(coupleId: coupleId)
        let store = makeStore(mock: mock, coupleId: coupleId)

        await store.start()
        let partnerKey = UUID().uuidString
        mock.presenceContinuation?.yield(PresenceDelta(joinedIds: [partnerKey], leftIds: []))
        await waitUntil("both present") { store.state == .bothPresent }

        mock.presenceContinuation?.yield(PresenceDelta(joinedIds: [], leftIds: [partnerKey]))
        await waitUntil("back to waiting") { store.state == .waitingForPartner }
    }

    // MARK: Poll fallback

    func testConnectFailureFallsBackToPollAndReachesActive() async {
        let coupleId = UUID()
        let sessionId = UUID()
        let mock = MockAirlockTransport()
        mock.openRow = makeRow(id: sessionId, coupleId: coupleId)
        mock.connectError = MockAirlockTransport.MockError()
        // Poll ticks: partner present+consented, then (after our consent) active.
        mock.heartbeatRows = [
            makeRow(id: sessionId, coupleId: coupleId,
                    aPresent: true, bPresent: true, bConsented: true)
        ]
        let store = makeStore(mock: mock, coupleId: coupleId, role: .a)

        await store.start()
        XCTAssertEqual(store.transport, .poll)

        await waitUntil("poll sees partner") { store.partnerPresent }
        await store.consent()
        // In poll mode the flip winner advances locally.
        await waitUntil("active via poll") {
            if case .active = store.state { return true } else { return false }
        }
        XCTAssertEqual(mock.flipCount, 1)
        XCTAssertGreaterThanOrEqual(mock.heartbeatCount, 1)
    }

    func testPresenceSilenceTimeoutDropsToPoll() async {
        let coupleId = UUID()
        let mock = MockAirlockTransport()
        mock.openRow = makeRow(coupleId: coupleId)
        // Connect succeeds but the streams stay silent.
        let store = makeStore(mock: mock, coupleId: coupleId, presenceTimeout: 0.05)

        await store.start()
        XCTAssertEqual(store.transport, .realtime)
        await waitUntil("timeout drops to poll") { store.transport == .poll }
    }

    func testNoOpenRowFails() async {
        let mock = MockAirlockTransport()
        mock.openRow = nil
        let store = makeStore(mock: mock, coupleId: UUID())

        await store.start()
        XCTAssertEqual(store.state, .failed(reason: "No open session for this couple."))
    }

    // MARK: Role derivation (profile id, never auth id)

    func testMakeDerivesRoleFromLocalCouple() throws {
        let container = ModelContainer.previewContainer
        let context = ModelContext(container)

        let profile = UserProfile(displayName: "Jordan")
        context.insert(profile)
        let coupleAsA = Couple(partnerAId: profile.id, partnerBId: UUID())
        context.insert(coupleAsA)
        try context.save()

        let storeA = AirlockStore.make(
            coupleId: coupleAsA.id, modelContainer: container,
            transport: MockAirlockTransport()
        )
        XCTAssertEqual(storeA?.role, .a)
        XCTAssertEqual(storeA?.myProfileId, profile.id)

        let coupleAsB = Couple(partnerAId: UUID(), partnerBId: profile.id)
        context.insert(coupleAsB)
        try context.save()

        let storeB = AirlockStore.make(
            coupleId: coupleAsB.id, modelContainer: container,
            transport: MockAirlockTransport()
        )
        XCTAssertEqual(storeB?.role, .b)
    }
}
```

Build notes for this segment: `CuratedSessionDTO`'s synthesized memberwise init is internal, which `@testable import Vayl` reaches — if the DTO ever gains a custom `init(from:)`, keep an explicit memberwise init or these fixtures break. The `@MainActor` suite + polling `waitUntil` pattern is the house style (`CoupleSessionPlaythroughTests`); remember the DM-suite gotcha that @MainActor test classes can retain-pool through isolated deinits — keep stores locally scoped per test as above.

**done:** all seven tests pass with `xcodebuild test -scheme Vayl -only-testing:VaylTests/AirlockStoreTests` (or the full VaylTests run); the pbxproj carries the four `AA00000C` entries.

---

## Definition of Done (this section, build-green)

- [ ] Migration file exists with the composition column + check, the `update_reveal_state` deep-merge function (SECURITY DEFINER, `is_couple_member` guard, `FOR UPDATE` serialization, delta-only merge), and the grants; `supabase db diff --linked` was run first and any drift was flagged, not auto-reconciled; nothing was applied to prod.
- [ ] `supabase test db` passes 38 existing + 11 new pgTAP assertions locally.
- [ ] `RealtimeSessionService` gained: `SessionRole.sealedKey` + `Codable`; `RevealCardState`; `CuratedSessionDTO.revealState`; `setSealed`/`setRevealed`/`clearRevealCard` (RPC delta-writes only); `sendReveal`/`requestResend`/`revealBroadcasts`/`resendRequests`; `presenceChanges`/`rowUpdates` (id-filtered); `flipToActiveIfBoth`/`heartbeatOpenSession`. Still pure data access.
- [ ] Exactly one `SessionPlan` type exists (the Codable struct at `Vayl/Core/Models/SessionPlan.swift` with the `draft` bridge); the `@Model` is deleted and deregistered from SchemaV1.
- [ ] `RevealEnvelope` exists per spec 4.1 and round-trips through Codable.
- [ ] `Couple.connectionComposition: GenderDynamic` exists with a `.flexible` default; every existing `Couple(...)` call site compiles unchanged.
- [ ] `AirlockStore` runs the spec ladder with the transport seam, presence heartbeat booleans, 10s-silence poll fallback, 2s poll loop, and the exactly-once flip; `make(...)` derives role from the LOCAL profile id.
- [ ] The debug harness drives the full ladder under `#if DEBUG`; release builds exclude it.
- [ ] `AirlockStoreTests` (7 tests) pass; pbxproj wired via `AA00000C`.
- [ ] Untouched: `CoupleSessionStore.swift`, `AirlockView.swift`, `CardSessionContainerView.swift`, `SessionPlayerView`, `SessionCloseView`, `PairingStore.swift`, `couple_session_records`, `SessionSyncService`.
- [ ] No em dash in any user-facing string added by this section (harness copy, failure reasons, SQL comments are non-user-facing but kept clean anyway).

## Bryan verifies on device (carried from plan 08, still mandatory)

Two physical devices (at least one physical — simulator Sign-in-with-Apple is flaky and RLS requires real auth), same couple, distinct accounts, via the debug harness:

- [ ] Presence join/leave visible both ways within ~1–2s.
- [ ] One device's Lock in flips the other's "partner consented" within ~1s (row UPDATE stream end to end, now including `reveal_state` decoding without errors in the log).
- [ ] Both consented → exactly one `active` flip (dashboard shows one row, `status='active'`), both devices read ACTIVE.
- [ ] Force poll on one device → it still reaches ACTIVE on the 2s heartbeat; the realtime device is unaffected.
- [ ] Non-member device cannot read the row (RLS) and `update_reveal_state` rejects it (guard).
- [ ] 🎚️ presenceTimeout 10s / pollInterval 2s feel right; tune in `AirlockStore.init` defaults if not.

## Handoff notes to Sections 2+

- **Spec §9 (pairing touchpoint) storage is ready, behavior is NOT built here.** `couples.connection_composition` + `Couple.connectionComposition` exist; the derivation (both partners' OB `genderIdentity` binary and complementary/matching → propose `mf`/`mm`/`ff`, else silent `flexible`), the one-tap confirm at link completion, the remote column write, and the Settings row belong to the section that owns pairing/settings UI. Derivation source: `UserProfile.genderIdentity` (L29) and `UserProfile.partnerGenderIdentity` (L34).
- The player's `SessionSyncCoordinator` (spec 4.3) consumes `presenceChanges`/`rowUpdates`/`revealBroadcasts`/`resendRequests` off ONE channel: build it on `LiveAirlockTransport`'s pattern (listeners before subscribe) but as its own class — do not widen `AirlockTransport` for player needs.
- RevealEngine consumes `RevealCardState.sealed(for:)`, `setSealed`/`setRevealed`, `sendReveal`, and the resend pair; `clearRevealCard` is its reconnect re-prompt write.

## Open decisions (each with a recommended default — proceed and flag)

1. **Delete the `@Model SessionPlan` vs rename the new struct.** **Default (implemented): delete.** The `@Model` has zero call sites beyond SchemaV1 registration and its own stub, predates the server-authoritative design, and duplicates what UserDefaults + the row now own. Pre-launch, empty migration stages, so removal is safe; the alternative (naming the struct `SessionPlanSnapshot`) would permanently fork the spec's vocabulary across all remaining sections. Flag to Bryan because it is a SchemaV1 change (dev installs may need a store wipe).
2. **Where the airlock's row comes from.** **Default (implemented): the airlock only fetches; the Builder/Lobby opens.** This matches the spec §5 lifecycle exactly and removes plan 08's open-or-fetch race entirely. The debug harness opens its own row with a stub draft, `#if DEBUG` only.
3. **`AirlockTransport` protocol placement.** **Default (implemented): in `AirlockStore.swift` beside its only consumer,** not in the service file — the seam is the store's testing concern; the service stays protocol-free like every other service in the repo. Flag if Bryan prefers a `Vayl/Core/Services/Protocols/` convention starting now.
4. **Presence-silence timeout semantics.** **Default (implemented): ANY signal (presence or row UPDATE) within 10s keeps realtime;** pure partner-absence does not trigger the fallback once the pipe has proven live. This reads spec §4.3's "no presence event within 10s" as a dead-pipe detector, not a partner-tardiness detector (a partner may legitimately take minutes to arrive; polling would not make them arrive faster). Flag if Bryan wants strict presence-only.

# ═══════════════════ SECTION 2 — Entry + Airlock UI + Player Sync (absorbs plans 09 + 10 + 05) ═══════════════════

# SECTION 2 — Segments D + E: Entry, Lobby, Airlock UI + Player Remote Sync

_Part of the Card Sessions front-to-back one-shot (spec: `docs/superpowers/specs/2026-07-01-card-sessions-front-to-back-design.md`, sections 4.3, 4.4, 4.5, 5). Absorbs plans 09 + 10 (both SUPERSEDED), minus the Whisper/reveal views (Section 3 owns RevealEngine + all reveal surfaces) and minus the builder itself (Section 3 owns SessionBuilderStore/View; this section defines the PlayStore handoff seam only)._

---

## Drift log (repo verified 2026-07-01, trumps plans 09/10 where they disagree)

1. **`AppShell.swift` drifted from plan 09 Segment 8.** There is no `tabTrimValues` / `tabAnimating` hoist anymore. The current shape (`Vayl/App/AppShell.swift:11-64`) is a local `@State selectedTab` + `@State transitionDirection`, with the `RacetrackTabBar` binding intercepted inline to capture drift direction. Plan 09's verified fix is re-cut below (Segment D1) to the current shape. The bug itself is still live: `appState.selectedTab` is never read, so `HomeRouterView`'s tab writes are dead.
2. **`SessionPlan` already exists as a SwiftData `@Model`** at `Vayl/Features/Sessions/SessionPlan.swift` (fields `orderedCardIds`, `perCardTimerSeconds`, `globalTimerSeconds`, `deckVariant`, plus a `.stub`). The spec's "new struct `Core/Models/SessionPlan.swift`" collides with this name. **This section does NOT create or rename it.** The PlayStore seam consumes the existing value type `CuratedSessionDraft` (`RealtimeSessionService.swift:49-55`), which already maps 1:1 onto the row columns. Section 3's builder must output a `CuratedSessionDraft` (or convert to one at the seam); the naming reconciliation is Section 3's call, flagged in the seam block.
3. **The airlock sync-ring (hold + release tolerance) is superseded** by the cover-family mockup's two-screen airlock: house rules (one tap) then a 3-detent bandwidth slider + 3-second press-and-hold lock-in. Plan 09 said "do not retune the ring"; the approved spec 4.5 replaces it. The ring code is removed in Segment D5.
4. **"put your phones down." copy is CUT everywhere.** It currently lives in `CardSessionContainerView.swift:104` (`transitionBeat`). Spec 4.5: the transition keeps only the breathing spark + "look at each other." The mockup's 1B footer line ("both in → phones down, look up") is also not carried over.
5. **`CoupleSessionStore.Phase` gains one case (`safeClose`)** for the safe-word exit screen. Plan 09's "no new Phase case" constraint applied to the lobby only; the spec's zero-guilt close screen (4.4 table, "Safe-word close screen") is a genuinely distinct terminal phase, not a pre-roll.
6. **`AirlockView`'s bandwidth copy said "shared" (`AirlockView.swift:132`).** Spec 4.5: bandwidth is set privately and the raw reading is never shown to the partner. The rewrite fixes this; the presence row shows presence only, never the partner's reading.
7. **plan 10's `SessionBroadcast` timer messages are dropped.** Spec 4.3: "keep going" clears the card's timer via a **row write** (nulls that card's `per_card_timer` entry), not a broadcast. Broadcast carries reveal envelopes only (Section 1's `revealBroadcasts` stream).
8. **`PresenceDebugView.swift`** (`Vayl/Features/Sessions/Debug/`) still exists and is deleted here (plan 09 Segment 9, absorbed).
9. **`SafeWordButton`** (`Vayl/Design/Components/Buttons/SafeWordButton.swift`) exists but its copy ("This will pause the session") and alert body do not match the spec's abandon semantics, and it is unused by the session flow today. This section builds its own discreet control (Segment E4) rather than modifying the shared component; the component is untouched.

---

## Interface seams (assumed contracts; the assembler reconciles)

### Seam A — Section 1: `AirlockStore` + `RealtimeSessionService` streams

This section ASSUMES the following exist exactly as written. If Section 1 shipped different names, adapt call sites here, not the state machine.

```swift
// Features/Sessions/AirlockStore.swift  (SECTION 1 DELIVERABLE — consumed here)
@Observable @MainActor final class AirlockStore {
    enum State: Equatable {
        case waitingForPartner        // lobby: my presence tracked, partner not here yet
        case bothPresent              // both present flags true → show house rules / bandwidth
        case bandwidthSet             // my bandwidth committed to the row
        case consented                // my consent committed; waiting for partner's
        case activating               // both consented; setStatus(.active) written
        case active                   // row status == active → hand off to the player
        case failed(String)           // subscribe/poll failure, surfaced reason
    }
    private(set) var state: State
    private(set) var partnerPresent: Bool
    private(set) var partnerConsented: Bool
    private(set) var session: CuratedSessionDTO   // latest mirrored row

    init(session: CuratedSessionDTO, role: SessionRole, userId: UUID,
         service: RealtimeSessionService)
    func start()                                   // subscribe (poll fallback inside)
    func commitBandwidth(_ fraction: Float)        // setBandwidth → state .bandwidthSet
    func commitConsent()                           // setConsent → .consented / .activating
    func cancel() async                            // setStatus(.abandoned), leave channel
    func stop()                                    // leave channel, cancel tasks
}

// RealtimeSessionService (SECTION 1 EXTENSIONS — consumed by SessionSyncCoordinator)
func presenceChanges(on channel: RealtimeChannelV2) -> AsyncStream<Set<String>>   // present user ids
func rowUpdates(on channel: RealtimeChannelV2, sessionId: UUID) -> AsyncStream<CuratedSessionDTO>
func revealBroadcasts(on channel: RealtimeChannelV2) -> AsyncStream<RevealEnvelope>
func sendReveal(_ envelope: RevealEnvelope, on channel: RealtimeChannelV2) async throws
// CuratedSessionDTO gains: let revealState: [String: [String: Bool]]?  // "reveal_state"
```

Already real (verified in `Vayl/Core/Services/RealtimeSessionService.swift`): `openSession`, `fetchOpenSession(coupleId:)`, `setBandwidth`, `setConsent`, `setPresence`, `setStatus`, `advance(sessionId:expectedIndex:) -> Bool` (conditional update), `sessionChannel(coupleId:userId:)`, `trackPresence(on:userId:)`, `leaveChannel(_:)`, `CuratedSessionStatus.openStatuses`.

### Seam B — Section 3: builder output + RevealEngine

```swift
// Builder handoff (SECTION 3 produces, PlayStore consumes — Segment D2):
// SessionBuilderView is sheet-hosted by PlayView and calls back with a draft.
// NOTE: CuratedSessionDraft, NOT the SwiftData SessionPlan @Model (drift item 2).
SessionBuilderView(deck: Deck, onConfirm: (CuratedSessionDraft) -> Void, onCancel: () -> Void)

// RevealEngine (SECTION 3 DELIVERABLE — this section only forwards deltas to it):
@MainActor final class RevealEngine {          // owned by CoupleSessionStore
    func applyRow(_ revealState: [String: [String: Bool]])   // seal/reveal flags from the row
    func applyBroadcast(_ envelope: RevealEnvelope)          // partner payloads
    func reset(forCardId: String)                            // card changed
}
```

`CoupleSessionStore` gains `var revealEngine: RevealEngine?` (Section 3 assigns it); Segment E2's `applyRemoteRow` and the coordinator's broadcast callback forward into it with `revealEngine?.applyRow(...)` / `applyBroadcast(...)`. Nothing else about reveals lives in this section.

---

## Files (this section's scope only)

### Create

| File | Responsibility |
|---|---|
| `Vayl/Features/Sessions/SessionEntryStore.swift` | Joiner-side open-session fetch for Home + Play. Injected `RealtimeSessionService`; exposes `pendingSession` (rows in `lobby`/`airlock` not initiated by me) + `accept()`. |
| `Vayl/Features/Sessions/Components/PendingSessionBanner.swift` | Top-anchored "‹name› set up a session" banner, reused by Home + Play. Press state + haptic + action. |
| `Vayl/Features/Sessions/SessionLobbyView.swift` | Initiator waits (shape summary + cancel); joiner lands here from the banner. Driven by `AirlockStore.state == .waitingForPartner`. |
| `Vayl/Features/Sessions/Components/BandwidthSlider.swift` | The 3-detent private bandwidth slider (Light / Open / Deep) from mockup 1B. |
| `Vayl/Features/Sessions/Components/HoldToLockInRing.swift` | 3-second press-and-hold lock-in with spectrum arc ramp (🎚️ 3.0s default). |
| `Vayl/Features/Sessions/SessionSyncCoordinator.swift` | Plain `@MainActor` class owned by the store: channel lifecycle (register streams → subscribe → track), fans presence/rowUpdates/revealBroadcasts into async loops, pumps typed deltas to the store. No UI knowledge. |
| `Vayl/Features/Sessions/Components/SessionTimerBar.swift` | Deadline countdown from `timer_started_at` + per-card seconds; soft chime at zero; wrap-up / keep-going affordances. Never auto-advances. |
| `Vayl/Features/Sessions/SafeWordCloseView.swift` | Neutral, warm, zero-guilt close screen after the safe word. No reflection, no stats, no penalty copy. |

### Modify

| File | Line anchor | Change |
|---|---|---|
| `Vayl/App/AppShell.swift` | `:11` (`@State selectedTab`), `:41-64` (tab bar binding) | Two-way sync `selectedTab` ↔ `appState.selectedTab` so joiner banners can route tabs (fixes the verified dead-write bug). |
| `Vayl/Features/Play/Store/PlayStore.swift` | init `:43-50`, `resolveFeatured` `:67-76`, intents `:127-154` | Add `entitlements: EntitlementStore` dependency + live `isLocked(_:)`; flow becomes detail → ceremony → **builder** → **lobby**: `ceremonyFinished()` opens the builder, `builderDidFinish(_:)` calls `openSession` and presents the lobby cover. |
| `Vayl/Features/Play/PlayView.swift` | `:15` env, `:38-42` store build, `:83-88` cover | Inject `EntitlementStore`; host `SessionBuilderView` as a `.vaylSheet` (Section 3's view); re-key the `.vaylCover` on `store.launch`; add `SessionEntryStore` + `PendingSessionBanner`. Masthead / hero / deck wall / ceremony internals untouched. |
| `Vayl/Features/Home/Views/HomeDashboardView.swift` | `:103` (`sessionHand`), `:255` (`reflectionBanner` region), `:269-276` (cover) | Add `SessionEntryStore` + banner + joiner launch path; "Settle in" initiator path unchanged. |
| `Vayl/Features/Sessions/CoupleSessionStore.swift` | init `:111-138`, phase enum `:34`, actions `:186-220`, scaffold `:251-313` | Remote sync via `SessionSyncCoordinator`; server-authoritative advance (optimistic + rollback); depth ceiling trim; timer; pause; safe word; presence-loss grace; reconnect rebuild; `.safeClose` phase; `launch` context (role, remote id, safe word, partner name, timers). |
| `Vayl/Features/Sessions/CardSessionContainerView.swift` | `:18-45` (params + store build), `:83-125` (flow + transition) | Accept a `SessionLaunch`; route lobby → airlock screens via `AirlockStore`; cut the "phones down" line; render `.safeClose`; reconnect fetch on appear. |
| `Vayl/Features/Sessions/AirlockView.swift` | whole file | Rewrite to the mockup's two-screen airlock (house rules → bandwidth + lock-in + presence), driven by `AirlockStore`. Ring release mechanic removed (drift item 3). |
| `Vayl/Features/Sessions/SessionPlayerView.swift` | `:42-80` body, `:259-346` controls, `:352-384` care sheet | Mount `SessionTimerBar`; pause overlay; discreet safe-word control (labeled from the couple's word); partner-away banner; wire the care sheet Pause row to the store. Hold-to-deal mechanic untouched. |
| `Vayl/Features/Sessions/SessionCloseView.swift` | `:55-76` landing | Cover-family restyle: topspark row + stat line (cards / depth reached / duration). Reflection sheet unchanged. |
| `Vayl/Core/Services/RealtimeSessionService.swift` | after `advance` `:254` | Three row ops this section owns: `raiseSafeWord(sessionId:)`, `markTimerStarted(sessionId:)`, `setPerCardTimer(sessionId:timers:)`. (Streams + reveal ops are Section 1's; do not duplicate.) |

### Delete

| File | Why |
|---|---|
| `Vayl/Features/Sessions/Debug/PresenceDebugView.swift` | `#if DEBUG` throwaway harness; superseded by the real lobby + AirlockStore. Grep `PresenceDebugView\|PresenceDebugStore` first; expect only its own file. |

---

## Build steps

> Tokens verified present and used below: `AppColors` (`void`, `cardBg`, `cardBackground`, `inputBackground`, `textPrimary/Body/Secondary/Tertiary`, `spectrumCyan/Purple/Magenta`, `spectrumBorder`, `spectrumText`, `accentSecondary`, `borderDefault`, `borderSubtle`, `safetyAccent`, `shadowDeep`), `AppFonts` (`screenTitle`, `sectionHeading`, `caption`, `overline`, `bodyText`, `bodyMedium`, `buttonLabel`, `buttonLabelSmall`, `ctaLabel`, `displayHero`, `prompt`), `AppSpacing` (xxs…xxl), `AppRadius` (`sm/md/lg/container`), `AppAnimation` (`fast/standard/slow/spring/enter/tabSwitch/ambientPulse` + `.reduceMotionSafe`). Read the theme file before inventing anything beyond these.

### Segment D1 — AppShell honors `appState.selectedTab`

**One thing:** programmatic tab routing works, so a joiner banner (and `HomeRouterView`'s existing writes) can actually switch tabs.

In `Vayl/App/AppShell.swift`, add the environment read and the two-way mirror. The `RacetrackTabBar` binding's inline setter stays the tap-driven source (it captures `transitionDirection` before the change); the mirror covers the programmatic direction:

```swift
struct AppShell: View {

    @Environment(AppState.self) private var appState

    @State private var selectedTab:        AppTab  = .home
    @State private var transitionDirection: CGFloat = 1

    var body: some View {
        Group {
            // …existing switch on selectedTab, unchanged…
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // …existing RacetrackTabBar binding block, unchanged…
        }
        // Programmatic routing: HomeRouterView's appState.selectedTab writes (dead
        // today) and the joiner banner's route-to-Play both land here. The local
        // @State stays the tab bar's animation source; these keep it in lockstep.
        .onAppear { selectedTab = appState.selectedTab }
        .onChange(of: appState.selectedTab) { _, newTab in
            guard selectedTab != newTab else { return }
            let fromIdx = AppTab.allCases.firstIndex(of: selectedTab) ?? 0
            let toIdx   = AppTab.allCases.firstIndex(of: newTab) ?? 0
            transitionDirection = CGFloat(toIdx > fromIdx ? 1 : -1)
            withAnimation(AppAnimation.tabSwitch) { selectedTab = newTab }
        }
        .onChange(of: selectedTab) { _, newTab in
            if appState.selectedTab != newTab { appState.selectedTab = newTab }
        }
    }
    // driftTransition unchanged
}
```

`@Environment(AppState.self)` is safe here: every AppShell preview already injects `AppState`, and `AppState.selectedTab` exists (`Vayl/Core/Services/AppState.swift:80`).

**Done:** writing `appState.selectedTab = .play` switches the shell with the drift animation; tapping tabs still works and now updates `appState.selectedTab`.

---

### Segment D2 — PlayStore: live entitlements + the ceremony → builder → lobby flow

**One thing:** `PlayStore` reads `EntitlementStore` live (plan 05's verified approach, absorbed) and its begin flow ends in `openSession` + a lobby cover instead of dealing a hand directly.

**(a) Dependencies + lock state.** In `Vayl/Features/Play/Store/PlayStore.swift`:

```swift
    // deps
    private let catalog: DeckCatalogService
    private let modelContainer: ModelContainer
    private let appState: AppState
    private let entitlements: EntitlementStore          // M3: the single Core gate
    private let realtime: RealtimeSessionService        // opens the lobby row

    init(modelContainer: ModelContainer,
         appState: AppState,
         entitlements: EntitlementStore,
         catalog: DeckCatalogService = DeckCatalogService(),
         realtime: RealtimeSessionService = RealtimeSessionService()) {
        self.modelContainer = modelContainer
        self.appState = appState
        self.entitlements = entitlements
        self.catalog = catalog
        self.realtime = realtime
        load()
    }

    /// Live lock state: catalog flag AND not Core. One purchase flips
    /// entitlements.isCore and every gate below re-derives. Views call this,
    /// never summary.isLocked directly.
    func isLocked(_ summary: DeckSummary) -> Bool {
        summary.isLocked && !entitlements.isCore
    }
```

Update `resolveFeatured()` (`:69`) to use it:

```swift
        let availableIDs = Set(summaries.filter { !isLocked($0) }.map(\.id))
        // …and the fallback:
        let fallback = summaries.first { !isLocked($0) }?.id ?? summaries.first?.id
```

Also sweep the Play views that read the frozen flag to the live method (they receive the store already): `DeckDetailView.swift:58` and `:82` (`deck.isLocked` → `store.isLocked(deck)`), `DeckCaseView.swift:26` (thread a `locked: Bool` in from the wall, which has the store), `DeckSummary.swift:27` is a preview-only string, leave it.

**(b) Flow state.** Replace the direct hand-deal with builder + lobby state:

```swift
    // Hero / wall / detail / ceremony / builder / lobby / session
    var featuredID: String?
    var detailID: String?
    var ceremonyDeckID: String?
    /// Ceremony finished → the builder shapes tonight's plan for this deck.
    var builderDeck: Deck?
    /// Non-nil → present the session .vaylCover (lobby-first for remote sessions).
    var launch: SessionLaunch?
    var paywallDeck: DeckSummary?
    private(set) var openError: String?
```

`SessionLaunch` is the one value the cover needs (defined here, consumed by `CardSessionContainerView` in Segment D4):

```swift
/// Everything the session cover needs to boot: the hand, who I am, and (for
/// two-device sessions) the open row. `session == nil` = pure-local DEBUG path.
struct SessionLaunch: Identifiable, Equatable {
    enum Entry: Equatable { case initiator, joiner, localDebug }
    let id = UUID()
    let hand: [Card]
    let entry: Entry
    let role: SessionRole
    let session: CuratedSessionDTO?
    static func == (l: SessionLaunch, r: SessionLaunch) -> Bool { l.id == r.id }
}
```

**(c) Intents.** `ceremonyFinished()` now opens the builder; the builder's confirm opens the row:

```swift
    func ceremonyFinished() {
        guard let id = ceremonyDeckID, let deck = try? catalog.loadDeck(id: id) else {
            ceremonyDeckID = nil
            return
        }
        ceremonyDeckID = nil
        builderDeck = deck                    // SessionBuilderView presents (Seam B)
    }

    /// Reduce Motion / fallback path: skip the ceremony, still go through the builder.
    func begin(_ id: String) {
        guard let deck = try? catalog.loadDeck(id: id) else { return }
        detailID = nil
        builderDeck = deck
    }

    func cancelBuilder() { builderDeck = nil }

    /// SEAM B: the builder hands back a CuratedSessionDraft (NOT the SwiftData
    /// SessionPlan @Model — see drift item 2). Open the row, then the lobby.
    func builderDidFinish(_ draft: CuratedSessionDraft) {
        guard let deck = builderDeck else { return }
        builderDeck = nil
        guard let coupleId = appState.coupleId, let myId = localProfileId() else {
            // Solo / unpaired: keep the local single-device path behind DEBUG only.
            #if DEBUG
            launch = SessionLaunch(hand: deck.orderedCards, entry: .localDebug,
                                   role: .a, session: nil)
            #endif
            return
        }
        let hand = draft.cardIds.compactMap { id in deck.orderedCards.first { $0.id == id } }
        Task { @MainActor in
            do {
                let dto = try await realtime.openSession(
                    coupleId: coupleId, initiatorId: myId, draft: draft
                )
                launch = SessionLaunch(hand: hand, entry: .initiator,
                                       role: role(for: myId), session: dto)
            } catch {
                openError = "Couldn't start the session. Try again."
            }
        }
    }

    func endSession() { launch = nil }

    /// SessionRole identity rule (spec 4.2, hard): derives from the local Couple
    /// row's partnerAId vs my LOCAL profile id. Never supabase auth id.
    private func role(for profileId: UUID) -> SessionRole {
        let context = ModelContext(modelContainer)
        guard let coupleId = appState.coupleId else { return .a }
        var fetch = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
        fetch.fetchLimit = 1
        guard let couple = try? context.fetch(fetch).first else { return .a }
        return couple.partnerAId == profileId ? .a : .b
    }

    /// The local SwiftData profile id (auth-id vs profile-id convention: this is
    /// the PROFILE id, which is what couples rows reference).
    private func localProfileId() -> UUID? {
        let context = ModelContext(modelContainer)
        var fetch = FetchDescriptor<UserProfile>()
        fetch.fetchLimit = 1
        return try? context.fetch(fetch).first?.id
    }
```

Delete the old `sessionHand` property and its `ceremonyFinished` assignment. Update the `#if DEBUG preview` extension to pass an `EntitlementStore(modelContainer: .previewContainer, appState: AppState())`.

> Verify at build time: `UserProfile` fetch shape (the model exists in `SchemaV1`; if the id property differs, trust the model file). If `Couple` has no local row for the couple id (edge: pairing done remote-first), fall back to `.a` and log; the airlock's row columns are still role-correct because the initiator writes with the same fallback on both devices only when the local row is genuinely missing, which the pairing flow prevents.

**(d) PlayView wiring.** In `Vayl/Features/Play/PlayView.swift`:

```swift
    @Environment(EntitlementStore.self) private var entitlements
    // …
    .task {
        if store == nil && injectedStore == nil {
            store = PlayStore(modelContainer: modelContext.container,
                              appState: appState,
                              entitlements: entitlements)
        }
    }
```

Host the builder (Section 3's view, Seam B) and re-key the cover:

```swift
        .vaylSheet(
            isPresented: Binding(
                get: { store.builderDeck != nil },
                set: { if !$0 { store.cancelBuilder() } }
            ),
            heightFraction: 0.92
        ) {
            if let deck = store.builderDeck {
                SessionBuilderView(
                    deck: deck,
                    onConfirm: { draft in store.builderDidFinish(draft) },
                    onCancel: { store.cancelBuilder() }
                )
            }
        }
        .vaylCover(isPresented: Binding(
            get: { store.launch != nil },
            set: { if !$0 { store.endSession() } }
        )) {
            if let launch = store.launch {
                CardSessionContainerView(launch: launch)
            }
        }
```

The existing paywall `.vaylSheet` stays as is (`PaywallSheet` already calls `entitlements.purchase()` and `onUnlocked`; with (a) in place the wall now unlocks in place when it fires).

**Done:** compiles; a locked deck unlocks live after `purchase()`; Begin runs detail → ceremony → builder sheet → (confirm) → `openSession` → lobby cover; solo/unpaired Begin is a DEBUG-only local launch.

---

### Segment D3 — Joiner entry: `SessionEntryStore` + `PendingSessionBanner` on Home and Play

**One thing:** when an open row sits in `lobby` or `airlock` for your couple and you did not start it, Home and Play show "‹name› set up a session"; tapping it joins into the lobby.

**(a)** Create `Vayl/Features/Sessions/SessionEntryStore.swift`:

```swift
//
//  SessionEntryStore.swift
//  Vayl
//
//  One question for Home + Play: "did my partner set up a session?"
//  Polls fetchOpenSession on appear/foreground; a row in lobby/airlock whose
//  initiator is NOT me becomes the pending banner. Accepting builds the joiner
//  SessionLaunch. Rows already active/paused are the reconnect path, handled by
//  the cover itself (Segment E2), not a banner.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.vayl.app", category: "SessionEntryStore")

@Observable
@MainActor
final class SessionEntryStore {

    struct Pending: Identifiable, Equatable {
        let id: UUID
        let initiatorName: String
        let deckTitle: String
        let dto: CuratedSessionDTO
        static func == (l: Pending, r: Pending) -> Bool { l.id == r.id }
    }

    private(set) var pendingSession: Pending?
    /// Set on accept; the host view presents the cover with it, then clears it.
    var acceptedLaunch: SessionLaunch?

    private let modelContainer: ModelContainer
    private let appState: AppState
    private let realtime: RealtimeSessionService
    private let catalog: DeckCatalogService
    /// Partner display name provider; nil-safe ("Your partner").
    private let partnerName: () -> String?
    private var dismissedSessionId: UUID?

    init(modelContainer: ModelContainer,
         appState: AppState,
         realtime: RealtimeSessionService = RealtimeSessionService(),
         catalog: DeckCatalogService = DeckCatalogService(),
         partnerName: @escaping () -> String? = { nil }) {
        self.modelContainer = modelContainer
        self.appState = appState
        self.realtime = realtime
        self.catalog = catalog
        self.partnerName = partnerName
    }

    func refresh() {
        guard let coupleId = appState.coupleId else { pendingSession = nil; return }
        Task { @MainActor in
            do {
                guard let dto = try await realtime.fetchOpenSession(coupleId: coupleId),
                      dto.status == CuratedSessionStatus.lobby.rawValue
                        || dto.status == CuratedSessionStatus.airlock.rawValue,
                      dto.initiatorId != localProfileId(),
                      dto.id != dismissedSessionId
                else { pendingSession = nil; return }
                let title = (try? catalog.loadSummaries())?
                    .first { $0.id == dto.deckId }?.title ?? dto.deckId
                pendingSession = Pending(
                    id: dto.id,
                    initiatorName: partnerName() ?? "Your partner",
                    deckTitle: title,
                    dto: dto
                )
            } catch {
                logger.warning("open-session fetch failed: \(error.localizedDescription)")
                pendingSession = nil
            }
        }
    }

    func accept() {
        guard let pending = pendingSession else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let dto = pending.dto
        guard let deck = try? catalog.loadDeck(id: dto.deckId) else { return }
        let hand = dto.cardIds.compactMap { id in deck.orderedCards.first { $0.id == id } }
        guard !hand.isEmpty, let myId = localProfileId() else { return }
        acceptedLaunch = SessionLaunch(
            hand: hand, entry: .joiner, role: role(for: myId), session: dto
        )
        pendingSession = nil
    }

    func dismissBanner() {
        dismissedSessionId = pendingSession?.id
        pendingSession = nil
    }

    private func localProfileId() -> UUID? {
        let context = ModelContext(modelContainer)
        var fetch = FetchDescriptor<UserProfile>()
        fetch.fetchLimit = 1
        return try? context.fetch(fetch).first?.id
    }

    private func role(for profileId: UUID) -> SessionRole {
        guard let coupleId = appState.coupleId else { return .b }
        let context = ModelContext(modelContainer)
        var fetch = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
        fetch.fetchLimit = 1
        guard let couple = try? context.fetch(fetch).first else { return .b }
        return couple.partnerAId == profileId ? .a : .b
    }
}
```

**(b)** Create `Vayl/Features/Sessions/Components/PendingSessionBanner.swift` (plan 09 Segment 2's verified component, copy carried with the spec's wording; no em dashes):

```swift
//
//  PendingSessionBanner.swift
//  Vayl
//
//  "<name> set up a session." Top-anchored, dismissible, reused by Home and
//  Play. Purely presentational; decisions live in SessionEntryStore.
//

import SwiftUI

struct PendingSessionBanner: View {

    let initiatorName: String
    let deckTitle: String
    let onJoin: () -> Void
    let onDismiss: () -> Void

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Circle()
                .fill(AppColors.spectrumBorder)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("\(initiatorName) set up a session")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textBody)
                Text("\(deckTitle) · tap to join")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(AppFonts.buttonLabelSmall)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
                .fill(AppColors.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
                        .strokeBorder(AppColors.spectrumBorder.opacity(0.5), lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .sensoryFeedback(.impact(.light), trigger: isPressed)
        .contentShape(Rectangle())
        .onTapGesture { onJoin() }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
```

**(c) Home wiring.** In `Vayl/Features/Home/Views/HomeDashboardView.swift`, next to the existing `@State private var sessionHand` (`:103`):

```swift
    @Environment(\.scenePhase) private var scenePhase
    @State private var entryStore: SessionEntryStore?
    @State private var joinerLaunch: SessionLaunch?
```

On the same scope that owns the `.vaylCover` (`:269`):

```swift
            .onAppear {
                if entryStore == nil {
                    entryStore = SessionEntryStore(
                        modelContainer: modelContext.container,
                        appState: appState,
                        partnerName: { [weak store] in store?.partnerName }
                    )
                }
                entryStore?.refresh()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { entryStore?.refresh() }
            }
            .onChange(of: entryStore?.acceptedLaunch) { _, launch in
                if let launch { joinerLaunch = launch; entryStore?.acceptedLaunch = nil }
            }
            .vaylCover(isPresented: Binding(
                get: { joinerLaunch != nil },
                set: { if !$0 { joinerLaunch = nil } }
            )) {
                if let launch = joinerLaunch {
                    CardSessionContainerView(launch: launch)
                }
            }
```

(`store` here is `HomeStore`, which has `partnerName` at `HomeStore.swift:48`; if the closure capture does not fit the file's store access, resolve the name inline the way the partner pill does. The existing initiator "Settle in" cover keys on `sessionHand` and becomes `CardSessionContainerView(launch: SessionLaunch(hand: sessionHand ?? [], entry: .localDebug, role: .a, session: nil))` wrapped `#if DEBUG` per the spec's out-of-scope rule 26: single-device couch mode survives only behind DEBUG. Release "Settle in" routes to Play: `appState.selectedTab = .play`.)

Add the banner to the ZStack hosting `reflectionBanner` (`:255`), same idiom:

```swift
    @ViewBuilder
    private var pendingSessionBanner: some View {
        if let pending = entryStore?.pendingSession {
            VStack {
                PendingSessionBanner(
                    initiatorName: pending.initiatorName,
                    deckTitle: pending.deckTitle,
                    onJoin: { entryStore?.accept() },
                    onDismiss: { entryStore?.dismissBanner() }
                )
                .padding(.horizontal, AppSpacing.sm)
                .padding(.top, AppSpacing.sm)
                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(AppAnimation.spring, value: entryStore?.pendingSession)
            .zIndex(2)
        }
    }
```

**(d) Play wiring.** Same trio in `PlayView` (`@State entryStore`, `refresh()` on the store-building `.task` + `scenePhase`, banner overlay inside the `ZStack(alignment: .top)` at `:47` with `.zIndex(20)`, above the ceremony's 10). On accept: `store.launch = launch` (the joiner reuses PlayStore's cover from D2(d)):

```swift
            .onChange(of: entryStore?.acceptedLaunch) { _, launch in
                if let launch {
                    store.launch = launch
                    entryStore?.acceptedLaunch = nil
                }
            }
```

**Done:** with a partner-initiated `lobby` row, both Home and Play show the banner; join presents the cover as `.joiner`; dismiss suppresses that session id until a new one appears; initiator surfaces untouched.

---

### Segment D4 — `SessionLobbyView` + container re-plumb

**One thing:** the cover boots from a `SessionLaunch`; before the airlock both devices sit in a lobby (initiator: waiting + shape + cancel; joiner: arriving) driven by `AirlockStore`.

**(a)** `Vayl/Features/Sessions/CardSessionContainerView.swift` gains the launch and the airlock store, and its flow becomes: `lobby/airlock (AirlockStore) → transition → session → close/safeClose → done`:

```swift
struct CardSessionContainerView: View {

    let launch: SessionLaunch

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var store: CoupleSessionStore?
    @State private var airlock: AirlockStore?

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            if let store {
                CoupleSessionFlow(store: store, airlock: airlock)
            }
        }
        .task {
            guard store == nil else { return }
            let realtime: RealtimeSessionService? =
                launch.session != nil ? RealtimeSessionService() : nil
            let built = CoupleSessionStore(
                launch: launch,
                modelContainer: modelContext.container,
                appState: appState,
                realtime: realtime
            )
            store = built
            if let session = launch.session, let realtime,
               let myId = built.localProfileId {
                let a = AirlockStore(session: session, role: launch.role,
                                     userId: myId, service: realtime)
                airlock = a
                a.start()
            }
            // Reconnect / app-kill: an already-active row skips the airlock and
            // rebuilds the player from the row (Segment E2).
            await built.resumeIfNeeded()
        }
        .onDisappear {
            airlock?.stop()
            store?.teardown()
        }
    }
}
```

Inside `CoupleSessionFlow`, the `.airlock` phase now routes on the airlock state (local DEBUG launch keeps the store's mocked path and renders `AirlockView` directly):

```swift
        case .airlock:
            if let airlock {
                switch airlock.state {
                case .waitingForPartner, .failed:
                    SessionLobbyView(store: store, airlock: airlock).transition(.opacity)
                case .bothPresent, .bandwidthSet, .consented, .activating:
                    AirlockView(store: store, airlock: airlock).transition(.opacity)
                case .active:
                    Color.clear.onAppear { store.airlockDidActivate() }
                }
            } else {
                AirlockView(store: store, airlock: nil).transition(.opacity)   // DEBUG local
            }
        case .safeClose:
            SafeWordCloseView(store: store).transition(.opacity)
```

`store.airlockDidActivate()` is Segment E2's entry into `.transition` (replaces `confirmSynced()` for the remote path). Also in this file: the transition beat drops the phones-down line (drift item 4):

```swift
    private var transitionBeat: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            Text("look at each other.")
                .font(AppFonts.sectionHeading)
                .foregroundStyle(AppColors.textPrimary)
            Text("✦")
                .font(AppFonts.displayHero)
                .foregroundStyle(AppColors.spectrumText)
                .scaleEffect(transitionBreathe && !reduceMotion ? 1.08 : 1.0)
                .opacity(transitionBreathe && !reduceMotion ? 1.0 : 0.7)
                .ambientAnimation(
                    .easeInOut(duration: AppAnimation.ambientPulse).repeatForever(autoreverses: true),
                    value: transitionBreathe
                )
                .padding(.top, AppSpacing.xl)
            Spacer()
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { transitionBreathe = true }
    }
```

**(b)** Create `Vayl/Features/Sessions/SessionLobbyView.swift`:

```swift
//
//  SessionLobbyView.swift
//  Vayl
//
//  The lobby: the row exists, one or both partners are not tracked on the
//  channel yet. Initiator: waiting + tonight's shape + cancel. Joiner: the same
//  screen reads as "you're here, waiting for the room". Auto-advances to the
//  airlock when AirlockStore reports bothPresent. Cover-family chrome.
//

import SwiftUI

struct SessionLobbyView: View {

    @Bindable var store: CoupleSessionStore
    let airlock: AirlockStore

    @Environment(\.vaylDismiss) private var vaylDismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var waitingPulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppSpacing.sm) {
                Text("✦")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.spectrumText)
                Text("session lobby")
                    .font(AppFonts.overline)
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.bottom, AppSpacing.lg)

            Text(store.entry == .initiator
                 ? "Waiting for \(store.partnerLabel)"
                 : "You're in the room")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)

            if case .failed(let reason) = airlock.state {
                Text(reason)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.top, AppSpacing.sm)
            }

            shapeCard
                .padding(.top, AppSpacing.lg)

            Spacer(minLength: 0)

            HStack(spacing: AppSpacing.md) {
                Circle()
                    .fill(AppColors.spectrumBorder)
                    .frame(width: 9, height: 9)
                    .opacity(waitingPulse ? 1 : 0.35)
                    .ambientAnimation(
                        .easeInOut(duration: AppAnimation.ambientPulse / 1.5)
                            .repeatForever(autoreverses: true),
                        value: waitingPulse
                    )
                Text(airlock.partnerPresent
                     ? "\(store.partnerLabel) is here"
                     : "waiting for \(store.partnerLabel)…")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.bottom, AppSpacing.lg)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                Task { @MainActor in
                    await airlock.cancel()
                    vaylDismiss(confirm: false)
                }
            } label: {
                Text(store.entry == .initiator ? "Cancel session" : "Not now")
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            .strokeBorder(AppColors.borderDefault, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.xxl)
        .padding(.bottom, AppSpacing.xl)
        .onAppear { waitingPulse = true }
    }

    private var shapeCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            shapeRow(icon: "rectangle.stack", label: "Deck", value: store.deckTitle)
            shapeRow(icon: "square.grid.2x2", label: "Cards", value: "\(store.hand.count)")
            shapeRow(icon: "clock", label: "Roughly",
                     value: "~\(max(1, store.hand.count * 2)) min")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
                .fill(AppColors.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
                        .strokeBorder(AppColors.spectrumBorder.opacity(0.4), lineWidth: 0.8)
                )
        )
    }

    private func shapeRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.spectrumText)
                .frame(width: 22)
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textBody)
        }
    }
}
```

(`store.entry`, `store.partnerLabel`, `store.deckTitle` are Segment E2 additions. Both-present auto-advance is the container's switch on `airlock.state`, no action needed here.)

**Done:** the cover boots from a `SessionLaunch`; initiator sees the lobby immediately after `openSession`; joiner lands in the same lobby from the banner; both flip to the airlock when `AirlockStore` reports `bothPresent`; cancel abandons the row and leaves without confirm friction.

---

### Segment D5 — `AirlockView` rewrite: house rules → bandwidth + lock-in

**One thing:** the airlock matches mockup 1A/1B: six bullets read aloud with one "We're ready" tap (repeat sessions collapse to one line), then a private 3-detent bandwidth slider with a 3-second press-and-hold lock-in ring and a presence row.

**(a)** Create `Vayl/Features/Sessions/Components/BandwidthSlider.swift`:

```swift
//
//  BandwidthSlider.swift
//  Vayl
//
//  3-detent bandwidth reading (Light / Open / Deep) per the cover-family mockup:
//  tactile "dial it in" without false precision. Set privately; never shown to
//  the partner. Snaps to the nearest detent on release.
//

import SwiftUI

struct BandwidthSlider: View {

    @Binding var selection: CoupleSessionStore.Bandwidth

    private let detents: [CoupleSessionStore.Bandwidth] = [.light, .open, .deep]

    private var fraction: CGFloat {
        switch selection {
        case .light: return 0
        case .open:  return 0.5
        case .deep:  return 1
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("tonight I'm…")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)

            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.borderSubtle)
                        .frame(height: 2)
                        .frame(maxHeight: .infinity, alignment: .center)

                    Capsule()
                        .fill(LinearGradient(
                            colors: [AppColors.spectrumCyan, AppColors.spectrumPurple],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, w * fraction), height: 2)
                        .frame(maxHeight: .infinity, alignment: .center)

                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(AppColors.void)
                            .overlay(Circle().strokeBorder(AppColors.borderDefault, lineWidth: 1))
                            .frame(width: 6, height: 6)
                            .position(x: w * CGFloat(i) / 2, y: geo.size.height / 2)
                    }

                    Circle()
                        .fill(LinearGradient(
                            colors: [AppColors.spectrumCyan, AppColors.spectrumMagenta],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 20, height: 20)
                        .overlay(Circle().strokeBorder(AppColors.borderDefault, lineWidth: 2))
                        .position(x: max(10, min(w - 10, w * fraction)), y: geo.size.height / 2)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { g in
                            let t = max(0, min(1, g.location.x / w))
                            let idx = Int((t * 2).rounded())
                            let next = detents[idx]
                            if next != selection {
                                UISelectionFeedbackGenerator().selectionChanged()
                                withAnimation(AppAnimation.fast) { selection = next }
                            }
                        }
                )
            }
            .frame(height: 24)

            HStack {
                stop("light", is: .light)
                Spacer()
                stop("open", is: .open)
                Spacer()
                stop("deep", is: .deep)
            }

            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "lock")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.spectrumPurple)
                Text("just for you: sets how deep the deck goes")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }

    private func stop(_ label: String, is b: CoupleSessionStore.Bandwidth) -> some View {
        Text(label)
            .font(AppFonts.overline)
            .tracking(1)
            .textCase(.uppercase)
            .foregroundStyle(selection == b ? AppColors.textBody : AppColors.textTertiary)
    }
}
```

**(b)** Create `Vayl/Features/Sessions/Components/HoldToLockInRing.swift`:

```swift
//
//  HoldToLockInRing.swift
//  Vayl
//
//  The 3-second press-and-hold lock-in (cover-family 1B). A sustained gesture
//  you can't do absentmindedly: the spectrum arc draws on over the hold and the
//  glow ramps with it. Release early and it drains back. 🎚️ holdSeconds = 3.0,
//  Bryan dials the ramp feel on device (Swift-over-HTML rule).
//

import SwiftUI

struct HoldToLockInRing: View {

    let locked: Bool
    let onLockIn: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Rendering constants (geometry, like ScoreRing / the old sync ring).
    private let ringSize: CGFloat = 168
    private let holdSeconds: Double = 3.0     // 🎚️ feel value

    @State private var fill: CGFloat = 0
    @State private var holding = false

    private var spectrumArc: AngularGradient {
        AngularGradient(
            colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
            center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)
        )
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.borderSubtle, lineWidth: 3)

            // Glow pass ramps with the fill (two-pass stroke, house recipe).
            Circle()
                .trim(from: 0, to: locked ? 1 : fill)
                .stroke(spectrumArc, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .blur(radius: 6)
                .opacity(0.2 + 0.5 * Double(locked ? 1 : fill))

            // Crisp pass.
            Circle()
                .trim(from: 0, to: locked ? 1 : fill)
                .stroke(spectrumArc, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("✦")
                .font(AppFonts.displayHero)
                .foregroundStyle(AppColors.spectrumText)
                .scaleEffect(locked ? 1.0 : 0.85 + 0.15 * fill)
        }
        .frame(width: ringSize, height: ringSize)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in startHold() }
                .onEnded { _ in endHold() }
        )
        .accessibilityLabel(locked ? "Locked in" : "Press and hold to lock in")
    }

    private func startHold() {
        guard !locked, !holding else { return }
        holding = true
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        if reduceMotion {
            // Reduce Motion: no ramp animation; a plain timed hold with a final snap.
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(holdSeconds))
                if holding { holding = false; complete() }
            }
            return
        }
        let start = Date()
        Task { @MainActor in
            while holding {
                fill = min(1, CGFloat(Date().timeIntervalSince(start) / holdSeconds))
                if fill >= 1 { holding = false; complete(); break }
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func endHold() {
        guard holding else { return }
        holding = false
        withAnimation(AppAnimation.standard) { fill = 0 }   // drains back, no penalty
    }

    private func complete() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(AppAnimation.standard) { fill = 1 }
        onLockIn()
    }
}
```

**(c)** Rewrite `Vayl/Features/Sessions/AirlockView.swift`. The ring/tolerance mechanic, the 2x2 grid, and the tutorial sheet go away; the header + `boxBackground` idiom stays. Two sub-steps inside the `.airlock` phase, tracked locally:

```swift
//
//  AirlockView.swift
//  Vayl
//
//  The airlock, two screens (cover-family 1A/1B):
//    1A house rules: six spectrum bullets, read aloud together, one tap on
//       "We're ready". Repeat sessions collapse to a one-line "settle in".
//    1B bandwidth + lock-in: private 3-detent slider, 3-second press-and-hold
//       lock-in, presence row. The gentler of the two readings becomes the
//       session's depth ceiling; the raw reading is never shown to the partner.
//
//  Driven by AirlockStore (real presence/consent). airlock == nil is the
//  DEBUG-only local path (mocked partner, unchanged store mock).
//

import SwiftUI

struct AirlockView: View {

    @Bindable var store: CoupleSessionStore
    let airlock: AirlockStore?

    @Environment(\.vaylDismiss) private var vaylDismiss

    private enum Step { case rules, bandwidth }
    @State private var step: Step = .rules
    @State private var lockedIn = false
    @State private var waitingPulse = false

    /// Repeat couples get the one-liner, not the six bullets (spec 4.5).
    private var isRepeatSession: Bool {
        UserDefaults.standard.bool(forKey: "vayl.hasCompletedCoupleSession")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            switch step {
            case .rules:     rulesScreen
            case .bandwidth: bandwidthScreen
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.xxl)
        .padding(.bottom, AppSpacing.xl)
        .animation(AppAnimation.enter.reduceMotionSafe, value: step)
        .onAppear {
            if airlock == nil { store.armPresence() }   // DEBUG local mock only
        }
    }

    private var header: some View {
        HStack {
            Button { vaylDismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(AppColors.cardBackground))
                    .overlay(Circle().strokeBorder(AppColors.borderDefault, lineWidth: 1))
            }
            .buttonStyle(.plain)
            Spacer()
            Text("\(store.deckTitle) · \(store.hand.count) \(store.hand.count == 1 ? "card" : "cards")")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    // MARK: - 1A · house rules

    private var rulesScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppSpacing.sm) {
                Text("✦").font(AppFonts.bodyMedium).foregroundStyle(AppColors.spectrumText)
                Text("settle in")
                    .font(AppFonts.overline).tracking(2).textCase(.uppercase)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.top, AppSpacing.lg)

            Text("Before we start")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.top, AppSpacing.sm)

            if isRepeatSession {
                Text("You know the room. Settle in, then say you're ready.")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.top, AppSpacing.md)
            } else {
                Text("Read these out loud, together.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.top, AppSpacing.xs)

                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    bulletRow("Take your time. Silence is fine.")
                    bulletRow("Both of you answer, every card.")
                    bulletRow("Listen first. Say what you heard before your turn.")
                    bulletRow("No fixing, no judging, just get each other.")
                    bulletRow("What's said here stays here.")
                    bulletRow("You can always pass.")
                }
                .padding(.top, AppSpacing.lg)
            }

            Spacer(minLength: 0)

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(AppAnimation.enter.reduceMotionSafe) { step = .bandwidth }
            } label: {
                Text("We're ready")
                    .font(AppFonts.ctaLabel)
                    .foregroundStyle(AppColors.textBody)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            .strokeBorder(AppColors.spectrumBorder, lineWidth: 1.2)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func bulletRow(_ text: String) -> some View {
        // SpectrumBulletRow (mockup): 7pt spectrum dot + one line.
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Circle()
                .fill(AppColors.spectrumBorder)
                .frame(width: 7, height: 7)
                .padding(.top, AppSpacing.xs + AppSpacing.xxs)
            Text(text)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 1B · bandwidth + lock-in

    private var bandwidthScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppSpacing.sm) {
                Text("✦").font(AppFonts.bodyMedium).foregroundStyle(AppColors.spectrumText)
                Text("lock in")
                    .font(AppFonts.overline).tracking(2).textCase(.uppercase)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.top, AppSpacing.lg)

            Text("How much have you\ngot for each other?")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.top, AppSpacing.sm)

            BandwidthSlider(selection: $store.bandwidth)
                .padding(.top, AppSpacing.xl)
                .disabled(lockedIn)
                .opacity(lockedIn ? 0.6 : 1)

            Spacer(minLength: 0)

            VStack(spacing: AppSpacing.md) {
                HoldToLockInRing(locked: lockedIn) {
                    lockedIn = true
                    if let airlock {
                        airlock.commitBandwidth(store.bandwidth.fraction)
                        airlock.commitConsent()
                    } else {
                        store.confirmSynced()   // DEBUG local path, mock unchanged
                    }
                }
                Text(lockedIn ? "you're locked in" : "press and hold to lock in")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                presenceRow
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var presenceRow: some View {
        HStack(spacing: AppSpacing.md) {
            presenceChip("You", ready: lockedIn, you: true)
            Text(partnerStatusLine)
                .font(AppFonts.overline)
                .foregroundStyle(AppColors.textTertiary)
                .frame(maxWidth: .infinity)
            presenceChip(store.partnerLabel,
                         ready: airlock?.partnerConsented ?? store.partnerPresent,
                         you: false)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + AppSpacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColors.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
                )
        )
    }

    private var partnerStatusLine: String {
        if airlock?.partnerConsented == true { return "both in" }
        return lockedIn ? "waiting for \(store.partnerLabel)…" : ""
    }

    private func presenceChip(_ name: String, ready: Bool, you: Bool) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Circle()
                .fill(ready
                      ? AnyShapeStyle(LinearGradient(
                            colors: you ? [AppColors.spectrumCyan, AppColors.accentSecondary]
                                        : [AppColors.spectrumMagenta, AppColors.accentSecondary],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                      : AnyShapeStyle(Color.clear))
                .frame(width: 9, height: 9)
                .overlay(Circle().strokeBorder(AppColors.textTertiary, lineWidth: ready ? 0 : 1.3))
                .opacity(ready ? 1 : (waitingPulse ? 1 : 0.35))
                .ambientAnimation(
                    .easeInOut(duration: AppAnimation.ambientPulse / 1.5).repeatForever(autoreverses: true),
                    value: waitingPulse
                )
            Text(name)
                .font(AppFonts.caption)
                .foregroundStyle(ready ? AppColors.textBody : AppColors.textSecondary)
        }
        .onAppear { waitingPulse = true }
    }
}
```

Presence dots pulse only while waiting; `.ambientAnimation` supplies the Reduce Motion stop. When both consents land, `AirlockStore` flips to `.activating`/`.active` (either device writes `setStatus(.active)`, idempotent) and the container's switch hands off to `store.airlockDidActivate()`. Set the repeat-session flag where the session completes (Segment E2's `finishSession` adds `UserDefaults.standard.set(true, forKey: "vayl.hasCompletedCoupleSession")`).

**Done:** first-timers read six bullets and tap once; repeats get one line; bandwidth is a private 3-detent slider; a 3-second hold with a spectrum arc ramp locks in (drains back on early release); the presence row shows presence, never the partner's reading; DEBUG local path still drives to the player via the store mock.

---

### Segment E1 — `SessionSyncCoordinator`

**One thing:** one plain class owns the channel lifecycle and fans Section 1's three streams into typed MainActor callbacks. The store never touches a channel.

Create `Vayl/Features/Sessions/SessionSyncCoordinator.swift`:

```swift
//
//  SessionSyncCoordinator.swift
//  Vayl
//
//  Consumer side of the two-device session. Owns exactly one channel:
//  register streams BEFORE subscribeWithError(), track presence AFTER
//  (ordering per the verified PresenceDebugStore pattern, now deleted).
//  Fans presence / rowUpdates / revealBroadcasts into async loops and pumps
//  typed deltas back to CoupleSessionStore. No UI knowledge, no SwiftData.
//
//  Stream factories (presenceChanges/rowUpdates/revealBroadcasts/sendReveal)
//  are SECTION 1 service extensions — see the plan's Seam A block.
//

import Foundation
import Supabase
import OSLog

private let logger = Logger(subsystem: "com.vayl.app", category: "SessionSyncCoordinator")

@MainActor
final class SessionSyncCoordinator {

    private let service: RealtimeSessionService
    private let coupleId: UUID
    private let userId: UUID
    private let sessionId: UUID

    private var channel: RealtimeChannelV2?
    private var tasks: [Task<Void, Never>] = []

    /// True once subscribed; the store's reconnect check reads this.
    private(set) var isConnected = false

    // Callbacks into the store; all fire on the MainActor.
    var onRowUpdate: ((CuratedSessionDTO) -> Void)?
    var onPresence: ((Set<String>) -> Void)?
    var onReveal: ((RevealEnvelope) -> Void)?
    var onSubscribeFailed: ((String) -> Void)?

    init(service: RealtimeSessionService, coupleId: UUID, userId: UUID, sessionId: UUID) {
        self.service = service
        self.coupleId = coupleId
        self.userId = userId
        self.sessionId = sessionId
    }

    func start() {
        guard channel == nil else { return }
        let channel = service.sessionChannel(coupleId: coupleId, userId: userId)
        self.channel = channel

        // Register BEFORE subscribe — ordering matters.
        let presence = service.presenceChanges(on: channel)
        let rows = service.rowUpdates(on: channel, sessionId: sessionId)
        let reveals = service.revealBroadcasts(on: channel)

        tasks.append(Task { [weak self] in
            guard let self else { return }
            do {
                try await channel.subscribeWithError()
                try await self.service.trackPresence(on: channel, userId: self.userId)
                self.isConnected = true
            } catch {
                logger.warning("session channel subscribe failed: \(error.localizedDescription)")
                self.onSubscribeFailed?(error.localizedDescription)
            }
        })
        tasks.append(Task { [weak self] in
            for await present in presence { self?.onPresence?(present) }
        })
        tasks.append(Task { [weak self] in
            for await dto in rows { self?.onRowUpdate?(dto) }
        })
        tasks.append(Task { [weak self] in
            for await envelope in reveals { self?.onReveal?(envelope) }
        })
    }

    /// Reveal payloads out (Section 3's engine calls through the store).
    func send(_ envelope: RevealEnvelope) {
        guard let channel, isConnected else { return }
        Task { try? await service.sendReveal(envelope, on: channel) }
    }

    func stop() {
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
        isConnected = false
        if let channel {
            self.channel = nil
            Task { await service.leaveChannel(channel) }
        }
    }
}
```

**Done:** compiles against Seam A's factories; register-then-subscribe-then-track ordering; `stop()` cancels loops and leaves the channel; zero UI/SwiftData imports beyond Foundation/Supabase.

---

### Segment E2 — `CoupleSessionStore`: launch context, row mirror, server-authoritative advance, depth ceiling, reconnect

**One thing:** the store boots from a `SessionLaunch`, mirrors the row as the source of truth (index forward-only, optimistic advance with rollback on failure), trims the hand to the couple's depth ceiling, and can rebuild everything from `fetchOpenSession` after an app kill.

**(a) Init.** Replace the loose scaffold params with the launch (keep a compatibility init for previews):

```swift
    // MARK: - Launch context

    let entry: SessionLaunch.Entry
    private let sessionRole: SessionRole
    private(set) var remoteSessionId: UUID?
    /// Safe word label + partner display name, resolved from the local Couple /
    /// profile rows at init; wayfinding copy only.
    private(set) var safeWordLabel: String = "red"
    private(set) var partnerLabel: String = "your partner"
    private(set) var deckTitle: String
    private(set) var localProfileId: UUID?
    private let perCardTimerSeconds: [String: Int]
    private let sessionStartedAt = Date()

    init(
        launch: SessionLaunch,
        modelContainer: ModelContainer,
        appState: AppState,
        realtime: RealtimeSessionService? = nil,
        presenceSeconds: Double = 1.4,
        transitionSeconds: Double = 2.5,          // 🎚️ spec 4.5: ~2.5s held beat
        enqueueSync: (@MainActor (SessionRecordPayload) -> Void)? = nil
    ) {
        self.hand = launch.hand
        self.effectiveHand = launch.hand
        self.entry = launch.entry
        self.sessionRole = launch.role
        self.remoteSessionId = launch.session?.id
        self.perCardTimerSeconds = launch.session?.perCardTimer ?? [:]
        self.deckTitle = launch.hand.first.map { _ in launch.session?.deckId ?? "Tonight's deck" }
            ?? "Tonight's deck"
        self.modelContainer = modelContainer
        self.appState = appState
        self.presenceSeconds = presenceSeconds
        self.transitionSeconds = transitionSeconds
        self.realtime = realtime
        self.initiatorId = launch.session?.initiatorId
        self.enqueueSync = enqueueSync ?? { payload in
            guard let data = try? JSONEncoder().encode(payload) else { return }
            SyncManager.shared.enqueueSyncTask(
                taskType: "sync_session", entityId: payload.id.uuidString, payload: data
            )
        }
        resolveLocalContext()
    }

    private func resolveLocalContext() {
        let context = ModelContext(modelContainer)
        var profileFetch = FetchDescriptor<UserProfile>()
        profileFetch.fetchLimit = 1
        localProfileId = try? context.fetch(profileFetch).first?.id
        if let coupleId = appState.coupleId {
            var coupleFetch = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
            coupleFetch.fetchLimit = 1
            if let couple = try? context.fetch(coupleFetch).first {
                safeWordLabel = couple.sharedSafeWord
            }
        }
        // Deck title: resolve the pretty name from the catalog when possible.
        if let deckId = hand.first?.deckId,
           let title = (try? DeckCatalogService().loadSummaries())?
               .first(where: { $0.id == deckId })?.title {
            deckTitle = title
        }
        // Partner label from HomeStore's source (UserProfile.partnerName mirror);
        // if unavailable, the honest generic stands (no hardcoded "Alex").
    }
```

Keep the old `init(hand:modelContainer:appState:…)` as a convenience delegating to `SessionLaunch(hand:entry:.localDebug, role:.a, session:nil)` so `AirlockView`/player previews and Home's DEBUG path still compile.

**(b) Remote mirror + advance.** Replace the `startRemoteSync()` stub (`:308-313`) and `advanceOrFinish` (`:214-220`):

```swift
    // MARK: - Remote sync (E2) — the row is the source of truth

    private var coordinator: SessionSyncCoordinator?
    private(set) var isLive = false
    private(set) var partnerPresentLive = false
    private(set) var isPaused = false
    private(set) var partnerAway = false
    private(set) var safeWordUsed = false
    private(set) var timerStartedAtRaw: String?
    /// Highest row index applied; the forward-only guard.
    private var confirmedIndex = 0
    /// Depth ceiling once both bandwidths are on the row.
    private(set) var depthCeiling: Bandwidth?
    /// The hand actually played tonight (ceiling-trimmed; == hand until then).
    private(set) var effectiveHand: [Card]
    /// Section 3 assigns this; row/broadcast reveal deltas are forwarded to it.
    var revealEngine: RevealEngine?

    /// AirlockStore reported .active — cross into the held transition beat.
    func airlockDidActivate() {
        guard phase == .airlock else { return }
        phase = .transition
        startRemoteSync()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(transitionSeconds))
            if phase == .transition { phase = .session }
        }
    }

    func startRemoteSync() {
        guard let realtime, let coupleId = appState.coupleId,
              let userId = localProfileId, let sid = remoteSessionId,
              coordinator == nil else { return }
        let coordinator = SessionSyncCoordinator(
            service: realtime, coupleId: coupleId, userId: userId, sessionId: sid
        )
        self.coordinator = coordinator
        coordinator.onRowUpdate = { [weak self] dto in self?.applyRemoteRow(dto) }
        coordinator.onPresence = { [weak self] present in
            guard let self, let me = self.localProfileId else { return }
            let partnerHere = present.contains { $0 != me.uuidString }
            self.partnerPresentLive = partnerHere
            partnerHere ? self.partnerReturned() : self.partnerLost()
        }
        coordinator.onReveal = { [weak self] envelope in
            self?.revealEngine?.applyBroadcast(envelope)
        }
        coordinator.start()
        isLive = true
    }

    func teardown() {
        coordinator?.stop()
        coordinator = nil
        graceTask?.cancel()
        timerTask?.cancel()
    }

    /// Mirror the authoritative row. Index only ever moves forward.
    private func applyRemoteRow(_ dto: CuratedSessionDTO) {
        if dto.currentIndex > confirmedIndex || (dto.currentIndex > index) {
            confirmedIndex = max(confirmedIndex, dto.currentIndex)
        }
        if dto.currentIndex != index, dto.currentIndex >= confirmedIndex,
           effectiveHand.indices.contains(dto.currentIndex) {
            index = dto.currentIndex
        } else if dto.currentIndex < index, dto.currentIndex == confirmedIndex {
            // Our optimistic bump outran a row that never moved: roll back.
            index = dto.currentIndex
        }
        timerStartedAtRaw = dto.timerStartedAt
        refreshTimer()
        recomputeCeiling(a: dto.aBandwidth, b: dto.bBandwidth)
        if dto.safeWordUsed, !safeWordUsed {
            safeWordUsed = true
            enterSafeClose()
        }
        isPaused = (dto.status == CuratedSessionStatus.paused.rawValue)
        if dto.status == CuratedSessionStatus.complete.rawValue, phase == .session {
            finishSession()                       // partner finished → follow to close
        }
        if dto.status == CuratedSessionStatus.abandoned.rawValue,
           !safeWordUsed, phase == .session {
            endEarly()                            // partner confirmed exit
        }
        if let revealState = dto.revealState {
            revealEngine?.applyRow(revealState)
        }
    }
```

Advance becomes optimistic with rollback (spec D7):

```swift
    private func advanceOrFinish() {
        if isLastCard { finishSession(); return }
        let expected = index
        index += 1                                   // optimistic, both paths
        revealEngine?.reset(forCardId: effectiveHand[expected].id)
        refreshTimer()
        guard isLive, let realtime, let sid = remoteSessionId else { return }
        Task { @MainActor in
            do {
                // Conditional write; a false just means the partner won the race
                // and the echoed UPDATE confirms the same landing index.
                _ = try await realtime.advance(sessionId: sid, expectedIndex: expected)
                self.startTimerIfLeader()
            } catch {
                // Network failure: roll the optimistic bump back; the next echo
                // or reconnect resolves the truth. Index never regresses below
                // the last confirmed row value.
                if self.index == expected + 1, self.confirmedIndex <= expected {
                    self.index = expected
                    self.refreshTimer()
                }
            }
        }
    }
```

Remove the now-redundant `liveAdvance(expectedIndex:)` calls from `dealNext()`/`pass()` (the write moved into `advanceOrFinish`); delete `liveAdvance` itself. `liveOpen()` is also deleted: the row is opened by `PlayStore.builderDidFinish` before the cover exists, and the DEBUG local path never opens one. `confirmSynced()` stays for the DEBUG mock path only.

**(c) Derived state now reads `effectiveHand`.** Update every `hand` read in the derived block (`:142-158`) and player-facing API to `effectiveHand`: `currentCard`, `isLastCard`, `upcomingCount`, `positionLabel`, and `SessionPlayerView.nextPromptText()`'s `store.hand` reads become `store.effectiveHand`.

```swift
    /// Depth ceiling (spec 4.3): min of the two private readings. Light keeps
    /// cards ≤ .split, Open ≤ .auroraBand, Deep everything. Closing ritual is
    /// never trimmed. Both devices derive this from the same row columns, so
    /// the trimmed hand (and therefore current_index) is identical on both.
    private func recomputeCeiling(a: Float?, b: Float?) {
        guard let a, let b, depthCeiling == nil else { return }
        let minFraction = min(a, b)
        let ceiling: Bandwidth = minFraction < 0.4 ? .light : (minFraction < 0.7 ? .open : .deep)
        depthCeiling = ceiling
        let maxIntensity: CardIntensity = {
            switch ceiling {
            case .light: return .split
            case .open:  return .auroraBand
            case .deep:  return .supernova
            }
        }()
        effectiveHand = hand.filter { $0.type == .closingRitual || $0.intensity <= maxIntensity }
    }
```

(The ceiling locks before `active`, at index 0, so trimming never strands a live index. `depthCeiling == nil` guard makes it latch-once, deterministic.)

**(d) Reconnect.** Called from the container's `.task` (Segment D4):

```swift
    /// Cover appeared with no live channel (app kill / relaunch): rebuild from
    /// the open row and resubscribe. Every UI state must be reconstructable
    /// from fetchOpenSession alone (spec section 5).
    func resumeIfNeeded() async {
        guard let realtime, coordinator == nil,
              let coupleId = appState.coupleId else { return }
        guard let dto = try? await realtime.fetchOpenSession(coupleId: coupleId),
              dto.id == remoteSessionId ?? dto.id else { return }
        remoteSessionId = dto.id
        switch dto.status {
        case CuratedSessionStatus.active.rawValue, CuratedSessionStatus.paused.rawValue:
            recomputeCeiling(a: dto.aBandwidth, b: dto.bBandwidth)
            confirmedIndex = dto.currentIndex
            index = min(dto.currentIndex, max(0, effectiveHand.count - 1))
            timerStartedAtRaw = dto.timerStartedAt
            isPaused = (dto.status == CuratedSessionStatus.paused.rawValue)
            if phase == .airlock { phase = .session }
            startRemoteSync()
            refreshTimer()
            if let revealState = dto.revealState { revealEngine?.applyRow(revealState) }
        default:
            break   // lobby/airlock: AirlockStore owns those states
        }
    }
```

Also in `finishSession()` add the repeat-session flag write:

```swift
        UserDefaults.standard.set(true, forKey: "vayl.hasCompletedCoupleSession")
```

**Done:** with realtime injected, `index` follows the row (forward-only) with an optimistic local bump that rolls back on a failed write; the trimmed hand is identical on both devices; killing the app mid-session and re-opening the cover rebuilds status/index/reveal flags from the row; DEBUG local path (`realtime == nil`) behaves exactly as on master.

---

### Segment E3 — Synced timer: store logic + `SessionTimerBar` + row ops

**One thing:** a per-card deadline both devices compute locally from `timer_started_at` + the plan's seconds; at zero, a soft chime and wrap-up / keep-going; "keep going" nulls that card's timer on the row for both. Nothing ever auto-advances.

**(a) Service row ops.** In `Vayl/Core/Services/RealtimeSessionService.swift`, after `advance` (`:254`):

```swift
    // MARK: Timer + safety row ops (Section 2 scope; streams live in Section 1)

    /// Stamps timer_started_at = now. Written by the role-a device when a timed
    /// card presents; the echoed UPDATE anchors both countdowns.
    func markTimerStarted(sessionId: UUID) async throws {
        try await supabase
            .from(SupabaseTable.curatedSessions)
            .update(["timer_started_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: sessionId.uuidString)
            .execute()
    }

    /// Replaces the per-card timer map ("keep going" removes one card's entry).
    /// Whole-map write: acceptable because only the tapping device writes it
    /// and the map is tiny; the echoed row is still the single truth.
    func setPerCardTimer(sessionId: UUID, timers: [String: Int]) async throws {
        try await supabase
            .from(SupabaseTable.curatedSessions)
            .update(["per_card_timer": timers])
            .eq("id", value: sessionId.uuidString)
            .execute()
    }

    /// The safe word: abandoned + safe_word_used in ONE write so both devices
    /// see a single atomic exit signal.
    func raiseSafeWord(sessionId: UUID) async throws {
        struct SafeWordUpdate: Encodable {
            let status: String
            let safeWordUsed: Bool
            enum CodingKeys: String, CodingKey {
                case status
                case safeWordUsed = "safe_word_used"
            }
        }
        try await supabase
            .from(SupabaseTable.curatedSessions)
            .update(SafeWordUpdate(status: CuratedSessionStatus.abandoned.rawValue,
                                   safeWordUsed: true))
            .eq("id", value: sessionId.uuidString)
            .execute()
    }
```

**(b) Store timer.** In `CoupleSessionStore` (uses the mirrored `timerStartedAtRaw` from E2; the live per-card map is mutable because keep-going trims it):

```swift
    // MARK: - Timer (E3) — derived locally from the shared anchor, never ticked over the wire

    private var liveTimers: [String: Int] = [:]     // seeded from perCardTimerSeconds
    private(set) var timerRemaining: TimeInterval?
    private(set) var timerElapsed = false
    private var timerTask: Task<Void, Never>?

    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoPlain = ISO8601DateFormatter()

    private var currentCardLimit: Int? {
        guard let id = currentCard?.id else { return nil }
        return liveTimers[id]
    }

    func refreshTimer() {
        timerTask?.cancel()
        timerElapsed = false
        if liveTimers.isEmpty { liveTimers = perCardTimerSeconds }
        guard let limit = currentCardLimit, let raw = timerStartedAtRaw,
              let started = Self.isoFractional.date(from: raw) ?? Self.isoPlain.date(from: raw)
        else { timerRemaining = nil; return }
        let deadline = started.addingTimeInterval(TimeInterval(limit))
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                let remaining = deadline.timeIntervalSinceNow
                timerRemaining = max(0, remaining)
                if remaining <= 0 { timerElapsed = true; break }   // soft: NEVER advances
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    /// Role-a stamps the anchor when a timed card presents (deterministic single
    /// writer; the echoed UPDATE starts both countdowns together).
    func startTimerIfLeader() {
        guard isLive, sessionRole == .a, let realtime, let sid = remoteSessionId,
              currentCardLimit != nil else { return }
        Task { @MainActor in try? await realtime.markTimerStarted(sessionId: sid) }
    }

    /// "keep going": null this card's timer for BOTH via the row (spec 4.3).
    func keepGoing() {
        guard let id = currentCard?.id else { return }
        liveTimers[id] = nil
        timerElapsed = false
        timerRemaining = nil
        timerTask?.cancel()
        guard isLive, let realtime, let sid = remoteSessionId else { return }
        let timers = liveTimers
        Task { @MainActor in try? await realtime.setPerCardTimer(sessionId: sid, timers: timers) }
    }
```

`applyRemoteRow` additionally mirrors the trimmed map so the partner's keep-going lands here: add `liveTimers = dto.perCardTimer` before `refreshTimer()` in E2's `applyRemoteRow`, and call `startTimerIfLeader()` after an index change applies. In the pure-local path there is no anchor, so `timerRemaining` stays nil and the bar renders nothing.

**(c) The bar.** Create `Vayl/Features/Sessions/Components/SessionTimerBar.swift`:

```swift
//
//  SessionTimerBar.swift
//  Vayl
//
//  The gentle per-card timer: a quiet mm:ss while running, and at zero a soft
//  chime (haptic) + "wrap up when you're ready / keep going". It never advances
//  the card and never hard-cuts. Presentation only.
//

import SwiftUI

struct SessionTimerBar: View {

    @Bindable var store: CoupleSessionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let remaining = store.timerRemaining {
            Group {
                if store.timerElapsed {
                    HStack(spacing: AppSpacing.md) {
                        Text("no rush, wrap up when you're ready")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        Button {
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            store.keepGoing()
                        } label: {
                            Text("keep going")
                                .font(AppFonts.buttonLabelSmall)
                                .foregroundStyle(AppColors.spectrumText)
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.opacity)
                } else {
                    Text(mmss(remaining))
                        .font(AppFonts.overline)
                        .tracking(2)
                        .foregroundStyle(AppColors.textTertiary)
                        .monospacedDigit()
                }
            }
            .animation((reduceMotion ? AppAnimation.fast : AppAnimation.standard),
                       value: store.timerElapsed)
            // 🎚️ soft chime at zero: haptic default (house idiom); Bryan may swap
            // for an audio chime on device.
            .sensoryFeedback(.impact(.light), trigger: store.timerElapsed)
        }
    }

    private func mmss(_ t: TimeInterval) -> String {
        let s = Int(t.rounded())
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
```

Mount it in `SessionPlayerView`'s `fanDeck` VStack, under the "N cards left" line (reads as ambient, not a stopwatch):

```swift
            SessionTimerBar(store: store)
                .padding(.top, AppSpacing.sm)
```

**Done:** with a per-card timer on the plan, both devices show the same mm:ss from the shared anchor; zero produces one soft haptic + the wrap-up line; keep-going clears it on both via the row; untimed cards and the local path render nothing.

---

### Segment E4 — Pause, safe word, presence-loss grace, `SafeWordCloseView`

**One thing:** either partner can pause (dim + held state, resume flips back); a discreet always-available control carries the couple's own safe word and lands both devices on a neutral zero-guilt close; losing the partner for 15s auto-pauses with a "waiting for ‹name›" line.

**(a) Store.** In `CoupleSessionStore`:

```swift
    // MARK: - Safety (E4)

    private var graceTask: Task<Void, Never>?

    func togglePause() {
        isPaused.toggle()
        guard isLive, let realtime, let sid = remoteSessionId else { return }
        let status: CuratedSessionStatus = isPaused ? .paused : .active
        Task { @MainActor in try? await realtime.setStatus(sessionId: sid, status: status) }
    }

    /// The safe word: an immediate, no-questions exit for BOTH devices.
    /// abandoned + safe_word_used in one write; no reflection, no penalty
    /// beyond cards already recorded.
    func raiseSafeWord() {
        safeWordUsed = true
        if isLive, let realtime, let sid = remoteSessionId {
            Task { @MainActor in try? await realtime.raiseSafeWord(sessionId: sid) }
        }
        enterSafeClose()
    }

    /// Both the local raise and the remote echo land here.
    private func enterSafeClose() {
        guard phase == .session || phase == .transition else { return }
        timerTask?.cancel()
        phase = .safeClose
    }

    /// Leaving the safe-word close: nothing else to save, just leave the cover.
    func acknowledgeSafeClose() { phase = .done }

    // Presence loss (called from the coordinator's presence callback, E2).
    private func partnerLost() {
        guard isLive, phase == .session, graceTask == nil else { return }
        graceTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(15))
            guard !Task.isCancelled, !partnerPresentLive else { return }
            partnerAway = true
            if !isPaused { togglePause() }
        }
    }

    private func partnerReturned() {
        graceTask?.cancel()
        graceTask = nil
        if partnerAway {
            partnerAway = false
            if isPaused { togglePause() }   // their return resumes
        }
    }
```

Add `case safeClose` to the `Phase` enum (`:34`). The container already routes it (Segment D4). The `.done` beat after a safe close skips the "kept, just for you" copy; in `CoupleSessionFlow.doneBeat`, branch:

```swift
    private var doneBeat: some View {
        VStack(spacing: AppSpacing.sm) {
            if store.safeWordUsed {
                Text("closed, no questions")
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textPrimary)
            } else {
                Text("kept, just for you")
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textPrimary)
                Text("it'll show up in your Map")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
```

**(b)** Create `Vayl/Features/Sessions/SafeWordCloseView.swift`:

```swift
//
//  SafeWordCloseView.swift
//  Vayl
//
//  The safe-word landing: neutral, warm, zero guilt, on BOTH devices. No
//  reflection prompt, no stats, no "are you sure". Saying the word worked;
//  this screen just holds the room while you leave it.
//

import SwiftUI

struct SafeWordCloseView: View {

    @Bindable var store: CoupleSessionStore

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Text("stopped, together")
                .font(AppFonts.overline)
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.accentSecondary)
            Text("Good call.")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text("The word did its job. Nothing else is asked of either of you tonight.")
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                store.acknowledgeSafeClose()
            } label: {
                Text("Close")
                    .font(AppFonts.ctaLabel)
                    .foregroundStyle(AppColors.textBody)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            .strokeBorder(AppColors.borderDefault, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

**(c) Player wiring.** In `SessionPlayerView`:

- **Safe word control**, discreet but always reachable, labeled with the couple's word, in `leftStack` under the presence capsule:

```swift
            Button {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                store.raiseSafeWord()
            } label: {
                Text(store.safeWordLabel)
                    .font(AppFonts.buttonLabelSmall)
                    .textCase(.uppercase)
                    .tracking(1)
                    .foregroundStyle(AppColors.safetyAccent)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        Capsule().fill(AppColors.safetyAccent.opacity(0.08))
                            .overlay(Capsule().strokeBorder(
                                AppColors.safetyAccent.opacity(0.25), lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Safe word: \(store.safeWordLabel). Ends the session immediately for both of you.")
```

  No confirm alert: the whole point of a safe word is that saying it once is enough. (This is why `SafeWordButton`'s alert pattern is not reused; see drift item 9.)

- **Care sheet Pause** (`:363`) actually pauses: `careOption("❚❚", "Pause", sub: "hold the room") { showCare = false; store.togglePause() }`.

- **Pause / partner-away overlay**, above the idle dim in the root ZStack:

```swift
            if store.isPaused {
                ZStack {
                    Rectangle().fill(AppColors.void).opacity(0.72).ignoresSafeArea()
                    VStack(spacing: AppSpacing.md) {
                        Text(store.partnerAway
                             ? "waiting for \(store.partnerLabel)…"
                             : "paused")
                            .font(AppFonts.sectionHeading)
                            .foregroundStyle(AppColors.textPrimary)
                        if !store.partnerAway {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                store.togglePause()
                            } label: {
                                Text("resume")
                                    .font(AppFonts.buttonLabel)
                                    .foregroundStyle(AppColors.spectrumText)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .transition(.opacity)
            }
```

  Gate the hold-to-deal on it: `startHold()` gains `guard !store.isPaused else { return }`.

- **Keep-awake** stays as is (`UIApplication.shared.isIdleTimerDisabled` at `:73/:77` is an application-level flag, not a banned scene API; plan 10's `connectedScenes` guard is folded in only if the audit sweep asks for it. Do not touch the idle-dim overlay).

**Done:** pause from either device dims and holds both (row echo drives the partner); resume flips back; tapping the couple's word exits both devices to `SafeWordCloseView` with `safe_word_used = true` on the row; a 15s presence gap auto-pauses with the waiting line and the partner's return resumes.

---

### Segment E5 — `SessionCloseView` restyle: cover-family stat line

**One thing:** the close keeps its landing + reflection flow but reads as cover-family screen 7: topspark row, cards-deep headline, and the stat line (cards / depth reached / duration).

In `SessionCloseView.swift`, replace `landing` (`:55-76`):

```swift
    private var landing: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppSpacing.sm) {
                Text("✦")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.spectrumText)
                Text("that's a wrap")
                    .font(AppFonts.overline)
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.bottom, AppSpacing.lg)

            Text("You went \(store.discussedCount) \(store.discussedCount == 1 ? "card" : "cards")\ndeep together.")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)

            HStack(spacing: AppSpacing.sm) {
                Circle()
                    .fill(AppColors.spectrumMagenta)
                    .frame(width: 5, height: 5)
                Text(store.sessionStatLine)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.top, AppSpacing.md)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.xxl)
    }
```

And in `CoupleSessionStore` the stat line derivation (uses E2's context):

```swift
    /// Cover-family screen 7 stat line: cards / depth reached / duration.
    var sessionStatLine: String {
        let cards = "\(discussedCount) \(discussedCount == 1 ? "card" : "cards")"
        let depth = "reached \(depthLabel)"
        let minutes = max(1, Int(Date().timeIntervalSince(sessionStartedAt) / 60))
        return "\(cards) · \(depth) · \(minutes) min"
    }

    /// Depth reached: the ceiling when live, else my own reading. Names the
    /// band, never a number, never the partner's reading (spec 4.5).
    private var depthLabel: String { (depthCeiling ?? bandwidth).label }
```

The reflection sheet (word bank, sliders, note, Save/Skip) is untouched: it already feeds `SessionReflection` and Pulse as built.

**Done:** the close opens with the topspark + cards-deep headline + one pip-led stat line, and the existing reflection sheet still auto-raises and persists.

---

## Definition of Done (build-green, this section)

1. Project compiles with all new files in the app target (no test files here, so no pbxproj test wiring).
2. `AppShell` honors `appState.selectedTab` both directions; `HomeRouterView`'s tab writes navigate.
3. `PlayStore` requires `EntitlementStore`; `isLocked(_:)` re-derives live; detail/case views read it; a `purchase()` unlocks the wall in place.
4. Begin flow: detail → ceremony → builder `.vaylSheet` (Seam B) → `builderDidFinish(CuratedSessionDraft)` → `openSession` → lobby inside the `.vaylCover`. No `.fullScreenCover`/`.sheet` raw calls anywhere new.
5. Home + Play show `PendingSessionBanner` for a partner-initiated `lobby`/`airlock` row; accept presents the cover as joiner; dismiss suppresses that session id.
6. The cover flow is lobby → house rules (six bullets first time, one line after) → bandwidth (3-detent, private) + 3s hold lock-in → transition (~2.5s, "look at each other." only, **no phones-down copy anywhere**) → player → close/safeClose → done. Grep for "phones down" returns nothing in Sessions.
7. `SessionSyncCoordinator` registers streams before subscribe, tracks after, and `stop()` leaves cleanly; `CoupleSessionStore` never touches a channel.
8. Advance is optimistic + conditional-write + forward-only row mirror with rollback on a failed write; `effectiveHand` ceiling trim is deterministic (closing ritual exempt) and identical on both devices by construction.
9. Timer derives from `timer_started_at` + plan seconds; zero = one soft haptic + wrap-up/keep-going; keep-going nulls the card's row entry; nothing auto-advances.
10. Pause, safe word (one tap, couple's own word, `raiseSafeWord` row op, `SafeWordCloseView` on both, no reflection), 15s presence grace → auto-pause + waiting banner, return resumes.
11. Reconnect: cover appear with no channel → `fetchOpenSession` rebuild (status, index, timers, reveal flags forwarded to Seam B's engine) + resubscribe.
12. Close shows the stat line; reflection persistence unchanged; `persistSession()`'s shape untouched.
13. `Debug/PresenceDebugView.swift` deleted, no dangling references; DEBUG-only local play path still compiles (previews included).
14. Zero raw tokens in new/changed view code; every loop has a Reduce Motion fallback (`.ambientAnimation` / `reduceMotion` guards); every new tappable has press state + haptic + action; no em dashes in any copy string; no iOS 26 banned APIs.

## Bryan verifies on device (two-device unless noted)

- [ ] 🎚️ Lock-in hold: 3.0s ramp feel (arc draw + glow); drain-back on early release.
- [ ] 🎚️ Transition beat: 2.5s hold with the breathing spark; confirm no phones-down copy.
- [ ] 🎚️ Timer chime: haptic vs audio at zero.
- [ ] Banner: partner opens a lobby → banner appears on your Home and Play within a foreground refresh; join lands in the lobby; both-present flips to house rules together.
- [ ] Repeat session: after one completed session the rules collapse to the one-liner.
- [ ] Depth ceiling: Light + Deep readings → hand trims to ≤ Split on BOTH devices, closing ritual survives; neither phone ever shows the other's reading.
- [ ] Lockstep + race: simultaneous advance taps move exactly one card; a mid-air network drop rolls the optimistic card back.
- [ ] Timer sync: same mm:ss both sides; keep-going on one clears both.
- [ ] Pause both ways; safe word from either side lands both on the neutral close with `safe_word_used` true in the dashboard; no reflection prompt after it.
- [ ] Presence loss: kill one app mid-card → other side auto-pauses after ~15s with "waiting for ‹name›"; relaunch → the killed side rebuilds onto the same card and the room resumes.
- [ ] Close stat line reads right (cards / depth / minutes); reflection still saves.
- [ ] Tab routing: Home partner-pill/Pulse/Lexicon/Settings writes now switch tabs; racetrack animation intact (single-device).

## Constraints / do-not-touch

- `SessionPlayerView`'s hold-to-deal mechanic, fan, warp, idle dim: wiring additions only, no retunes.
- `persistSession()` / `persistReflection()` shape frozen; `enqueueSync` and `couple_session_records`/`SessionSyncService` untouched.
- `PlayView` masthead / `PlayHeroView` / `DeckWallView` / `DeckBeginCeremony` internals off-limits (banner, entitlements read, builder/cover hosting only).
- Reveal answer payloads never persist; this section only forwards row/broadcast deltas to Section 3's engine and never stores envelope bodies.
- `VaylCardFace` shell untouched; `.drawingGroup()` stays; onboarding untouched; `SafeWordButton.swift` untouched (drift item 9).
- No new migration here (every column used exists in the baseline; Section 1 owns the reveal-merge function migration).
- `RealtimeSessionService` stays store/UI-ignorant; only the three named row ops are added here, streams belong to Section 1.

## Open decisions (defaults chosen, flag on delivery)

1. **Who persists `CardSession` when both devices reach `.close`?** Default: **both persist locally** (SwiftData is per-device and `DeckProgress`/history are device-local reads); `enqueueSync` de-dup is the server's concern and `SessionRecordPayload.id` differs per device today. If Bryan wants one canonical remote record, gate `enqueueSync` on `sessionRole == .a` when live: one-line change, flagged.
2. **Home "Settle in" in release.** Default: routes to Play (`appState.selectedTab = .play`) since single-device couch mode is DEBUG-only per the spec; the DEBUG build keeps the direct local cover. Flag if Bryan wants the bar hidden instead.
3. **Deck title on the DTO path.** Default: resolve via `DeckCatalogService.loadSummaries()`; falls back to the raw `deckId` string if the catalog misses (absorbed-deck renames from the content re-cut could briefly mismatch).
4. **Timer anchor writer.** Default: role `.a` stamps `timer_started_at` after each advance onto a timed card (single deterministic writer). Alternative (advance-winner writes) saves nothing and complicates the race story.

# ═══════════════════ SECTION 3 — RevealEngine + Living Cards + Builder (absorbs plans 10 + 11) ═══════════════════

# SECTION 3 — Reveal Engine, Living Card Faces, Context Beats, Session Builder (segments F–G)

_Part of the Card Sessions front-to-back one-shot (spec: `docs/superpowers/specs/2026-07-01-card-sessions-front-to-back-design.md` §4.3 RevealEngine + SessionBuilderStore, §4.4 reveal/local-card/context-beat rows, §6 reveal_state). This section absorbs fable-plan 11 (session builder) and generalizes fable-plan 10's Whisper reveal into the five-mechanic RevealEngine. Plans 10 and 11 are SUPERSEDED; verified code from them is reused where the spec did not change it, and every drift from them is flagged inline._

> The ONE-SHOT LICENSE from `docs/fable-plans/_SHARED-PREAMBLE.md` applies verbatim to this section.

---

## Interface seams assumed from Sections 1–2

Everything in this block is **built by Section 1 or Section 2, not here**. If a symbol below does not exist when you build this section, build Sections 1–2 first — do not re-declare these here.

```text
SECTION 1 (models + service):
- struct RevealEnvelope (Core/Models/RevealEnvelope.swift):
    { cardId: String, role: SessionRole, body: Body }
    enum Body: Codable, Sendable { case text(String), position(Double), word(String) }
- struct SessionPlan (Core/Models/SessionPlan.swift), Codable + Sendable:
    { deckId: String, cardIds: [String], perCardTimerSeconds: [String: Int]?,
      globalTimerSeconds: Int?, deckVariant: String? }
  ⚠️ DRIFT NOTE: the repo TODAY has a SwiftData `@Model final class SessionPlan`
  at Vayl/Features/Sessions/SessionPlan.swift (registered in SchemaV1). Section 1
  resolves that collision (the spec's Codable struct replaces the @Model; plan 11's
  SwiftData save-and-reuse path is dead — see drift log below). This section codes
  against the STRUCT. If Section 1 kept a different name, follow Section 1.
- RealtimeSessionService gains (merge-writes via the update_reveal_state RPC, §6):
    func setSealed(sessionId: UUID, cardId: String, role: SessionRole) async throws
    func setRevealed(sessionId: UUID, cardId: String) async throws
    func clearSeal(sessionId: UUID, cardId: String, role: SessionRole) async throws   // reconnect re-compose
- CuratedSessionDTO gains `revealState: [String: RevealFlags]` where
    struct RevealFlags: Codable, Sendable { let aSealed: Bool; let bSealed: Bool; let revealed: Bool }
  (snake_case keys a_sealed / b_sealed / revealed per spec §6).

SECTION 2 (coordinator + wiring):
- SessionSyncCoordinator (Features/Sessions/SessionSyncCoordinator.swift) exposes:
    func sendReveal(_ envelope: RevealEnvelope)          // broadcast event "reveal"
    func sendResendRequest(cardId: String)               // broadcast event "reveal_resend"
    var onRevealEnvelope: ((RevealEnvelope) -> Void)?
    var onResendRequest: ((String) -> Void)?             // cardId
    var onRowUpdate: ((CuratedSessionDTO) -> Void)?
- CoupleSessionStore already has (from Section 2): `isLive`, `coordinator`,
  `applyRemoteRow(_:)`, server-authoritative advance, `remoteSessionId`,
  `sessionRole`, injected `realtime: RealtimeSessionService?`.
- PlayStore flow: detail → ceremony → BUILDER → `openSession` → lobby. Section 2
  owns presenting SessionBuilderView (a .vaylSheet inside the pre-session flow)
  and calling `openSession` with the SessionPlan this section's builder returns.
  This section only defines the builder Store + View + the `onStart(SessionPlan)`
  callback shape; Section 2 plugs it in.
- applyRemoteRow(_:) must call `cardDidChange()` (added here, segment F5) when
  current_index moves, and must forward `dto.revealState[currentCard.id]` into
  `syncRevealFlags(from:)` (added here, segment F5) on every row update.
```

**Verified against the repo 2026-07-01 (this section's own checks):**
- `CardType` has all cases used here (`whisper, unspoken, mirror, snapshot, whatIf, dare, greenLight, coolOff, bodyCheck, permissionCard, appreciationInterrupt, openingRitual, closingRitual, pause`) — `Vayl/Core/Models/Enums/AppCardEnums.swift:17-55`. `ContextBeatType` = `.banner / .interstitial` (`:184-187`).
- `Card.isRevealMechanic / isCeremonial / isLivingCard / hasContextBeat / hasBackCopy` — `Vayl/Core/Models/Card.swift:39-76`. `Card` is `Codable, Identifiable`, NOT Hashable — key by `card.id` (String).
- `CoupleSessionStore` — `Vayl/Features/Sessions/CoupleSessionStore.swift` (phase machine `:34`, `hand`/`index` `:66-67`, `dealNext`/`pass` `:189-199`, `advanceOrFinish` `:214-220`, `startRemoteSync` stub `:308-313`).
- `SessionPlayerView` — `Vayl/Features/Sessions/SessionPlayerView.swift` (body `:42-80`, `screenLayer` `:129-144`, `.screenshotProtected()` on sensitive cards `:47`, card back face `:212-225`, `.if` helper is real, `ThemeModifiers.swift:101`).
- `SessionRole` = `.a / .b` — `RealtimeSessionService.swift:38-45`. `RealtimeSessionService.setStatus/advance/fetchOpenSession` exist as Section 2 consumes them.
- Tokens verified: `AppColors` `.void .cardBg .cardBackground .inputBackground .textPrimary .textBody .textSecondary .textTertiary .spectrumCyan .spectrumPurple .spectrumMagenta .accentPrimary .accentSecondary .success .safetyAccent .borderSubtle .borderDefault .shadowDeep`; gradients `.spectrumBorder .spectrumText` (both `LinearGradient`, `AppColors.swift:622,632`). `AppFonts` `.display(_:weight:relativeTo:) .displayHero .cardTitle .sectionHeading .bodyText .caption .overline .buttonLabel .buttonLabelSmall .prompt`. `AppAnimation` `.fast .standard .slow .spring .enter .exit .ambientPulse`; `.ambientAnimation(_:value:)` is real (`AppAnimation.swift:861`). `AppRadius` `.sm .md .lg .obCard .pill .container`. `AppSpacing` `.xxs…xxl`. Glow: `.spectrumBorderGlow(intensity:)` (`AppGlows.swift:325`); `VaylBorderEffect(width:height:cornerRadius:progress:glowIntensity:hairlineVisible:)` (`VaylBorderEffect.swift:12-30`).
- `.screenshotProtected()` = `ScreenshotProtectionModifier` (`Vayl/Design/Components/Progress/ScreenshotProtectionModifier.swift`), scene-resolved, iOS-26 clean.
- `.vaylSheet(isPresented:heightFraction:screenHeight:showsGrabber:content:)` and `.vaylCover(...)` — `VaylPresentation.swift:197-240`.
- `the-opener.json` card keys are snake_case (`context_beat_type`, `back_copy`, …) and decode through the existing `ContentLoader` — no schema work here.
- There is NO `Vayl/Features/Sessions/Components/` directory yet — this section creates it. No `RevealEngine` / `RevealEnvelope` symbols exist anywhere yet (grep-clean).
- VaylTests wiring: test files are NOT auto-synchronized; pbxproj entries use the `AA00000N…0001` (build file) / `AA00000N…0002` (file ref) convention, last used id `AA00000B` (`project.pbxproj:23-33`). This section adds `AA00000C` and `AA00000D`.

**Drift log vs plans 10/11 (superseded, honor the spec):**
1. Plan 10's `SessionBroadcast` enum (timer + reveal kinds multiplexed on one event) is replaced by Section 1's typed `RevealEnvelope` + a separate resend event. Timer broadcasts stay Section 2's concern.
2. Plan 10 sent the answer payload AT REVEAL TIME and drove the 3-2-1 from role `.a` via a `revealCountdown` broadcast. The spec (§4.3 RevealEngine) sends the payload AT SEAL TIME, gates `bothSealed` on row-flag AND buffered payload, and lets EACH device run its own local countdown once its own gate opens — no countdown broadcast, no driver role. Small skew is acceptable (shared breath, not a race).
3. Plan 10 kept `reveal_state` off the DTO ("Broadcast only"). The spec reverses this: seal/reveal FLAGS live in `reveal_state` jsonb (reconnect-safe), payloads stay Broadcast-only. Section 1 adds the DTO field.
4. Plan 11's SwiftData `SessionPlan` persistence (save-and-reuse list, presets, `saveDraftAsPlan`, `loadSavedPlans`) is CUT. The spec's fast paths are exactly two: Quick start + Same as last time, the latter persisted as one Codable blob in `UserDefaults` keyed by deckId.
5. Plan 11's `SessionDraft` / `SessionSettingsSection` (depth ceiling, sensitive toggle, firm cap, LDR) are CUT: the depth ceiling now comes from both partners' airlock bandwidths (spec §4.3 AirlockStore), not the builder. The builder's tools are exactly: reorder, trim (min 3, closing ritual protected), per-card or global timer.
6. Plan 11's trim rules ("rituals droppable, min 1 card") are replaced by the spec's: **minimum 3 cards, closing ritual untrimmable if present in tonight's slice**.
7. Plan 11 output a `[Card]` hand straight into the cover. The spec's builder outputs a `SessionPlan`; PlayStore (Section 2) calls `openSession` with it. The `[Card]` hand materializes on both devices from the row's `card_ids`.
8. Plan 11's `SessionPlan.stub` deletion note stands, but the whole `@Model` file is Section 1's to resolve (see seam block) — do not touch `Vayl/Features/Sessions/SessionPlan.swift` from this section.

---

## Files (this section's scope only)

### Create

| File | Responsibility |
|---|---|
| `Vayl/Features/Sessions/RevealEngine.swift` | ONE `@Observable @MainActor` state machine serving all five reveal mechanics (whisper, whatIf, unspoken, mirror, snapshot): composing → sealedMine → bothSealed → countdown → revealed, with the resend path and reconnect restore. Talks to the wire only through the `RevealTransporting` protocol seam (unit-testable). |
| `Vayl/Features/Sessions/Components/RevealCardChrome.swift` | The special-card treatment shared by all four reveal views: animated spectrum border (reuses `VaylBorderEffect`) + drifting spark particles (Canvas, Reduce-Motion stilled) around the reveal surface. No new primitives. |
| `Vayl/Features/Sessions/Components/WhisperRevealView.swift` | Whisper compose → seal → 3-2-1 → side-by-side color-coded reveal. `whatIf` reuses it with different framing copy. Compose field `.screenshotProtected()`. |
| `Vayl/Features/Sessions/Components/UnspokenSliderView.swift` | Unspoken: private slider → seal → both positions land on one spectrum bar. |
| `Vayl/Features/Sessions/Components/MirrorRevealView.swift` | Mirror: role-aware prompt (A answers about self, B guesses A's answer) → seal → gap reveal. |
| `Vayl/Features/Sessions/Components/SnapshotRevealView.swift` | Snapshot: one-word field → seal → two words land together. |
| `Vayl/Features/Sessions/Components/LocalCardFaceView.swift` | Per-type face treatment for the nine local (no-sync) living cards: dare, greenLight, coolOff, bodyCheck, permissionCard, appreciationInterrupt, openingRitual, closingRitual, pause (pause = held-breath screen, no prompt). |
| `Vayl/Features/Sessions/Components/ContextBeatOverlayView.swift` | The two pre-card context beats: banner (1-2 lines over the dimmed card, auto-dismiss 5s, tap-through) and interstitial (full screen, user-dismissed). |
| `Vayl/Features/Sessions/Components/CardBackFlipView.swift` | Card back flip affordance for `backCopy` cards: after discussion, before advance, flip the card to its responsive back. |
| `Vayl/Features/Sessions/Builder/SessionBuilderStore.swift` | Builder brain: input a composition-filtered card list + resume index, output a `SessionPlan`. Reorder, trim (floor 3 + closing-ritual protection), per-card/global timers, Quick start, Same-as-last (UserDefaults per deckId). |
| `Vayl/Features/Sessions/Builder/SessionBuilderView.swift` | The builder UI (hosted as a `.vaylSheet` by Section 2's pre-session flow): fast-path chips, reorderable card list, timer chips, Start CTA returning the `SessionPlan` via `onStart`. Empty state included. |
| `VaylTests/RevealEngineTests.swift` | Unit tests: seal orders, payload-before-flag, flag-before-payload, resend path, reconnect restore — against `MockRevealTransport`. |
| `VaylTests/SessionBuilderStoreTests.swift` | Unit tests: trim floor, closing-ritual protection, same-as-last persistence, defaults — against an isolated `UserDefaults` suite. |

### Modify

| File | Line anchor | Change |
|---|---|---|
| `Vayl/Features/Sessions/CoupleSessionStore.swift` | `:66-80` (state), `:186-220` (session actions), after `:313` (new section) | Own the `RevealEngine` + its transport adapter; add `cardDidChange()` / `syncRevealFlags(from:)` hooks (Section 2's `applyRemoteRow` calls them); add context-beat state (`activeContextBeat`, `dismissBeat()`), card-back state (`showingCardBack`, `flipCardBack()`), and reveal-completion gate (`revealSatisfied`). Local path: `advanceOrFinish()` calls `cardDidChange()` after the index bump. |
| `Vayl/Features/Sessions/SessionPlayerView.swift` | `:42-80` (body), `:129-144` (screenLayer) | Route the card face by type: reveal mechanic → the matching reveal view inside `RevealCardChrome`; local living card → `LocalCardFaceView`; else the existing hero prompt (untouched). Overlay `ContextBeatOverlayView` when a beat is active; show `CardBackFlipView` affordance on `hasBackCopy` cards. The hold-to-deal mechanic is not disturbed. |
| `Vayl.xcodeproj/project.pbxproj` | `:23-33` (build files), `:64-73` (file refs), VaylTests group + Sources phase | Wire the two new test files with ids `AA00000C…` and `AA00000D…` (follow the existing `AA00000B` rows exactly: one `…0001` PBXBuildFile, one `…0002` PBXFileReference, group child entry, Sources-phase entry). |

### Delete

_None from this section._ (`SessionPlan.swift`'s `@Model` + stub are Section 1's to resolve; dead content files are Section 4's.)

---

## Segment F1 — RevealEngine (the one state machine)

**One thing it does:** a single `@Observable` state machine that carries any reveal card from composing to revealed, with seal flags authoritative on the row, payloads ephemeral over broadcast, a resend path for lost payloads, and reconnect restore.

Create `Vayl/Features/Sessions/RevealEngine.swift`:

```swift
//
//  RevealEngine.swift
//  Vayl
//
//  ONE state machine for all five reveal mechanics (whisper, whatIf, unspoken,
//  mirror, snapshot). Owned by CoupleSessionStore; the reveal views are thin
//  skins over its phase.
//
//  Authority split (spec §4.3 / D6):
//  - Seal/reveal FLAGS live in curated_sessions.reveal_state (row = durable,
//    reconnect-safe). The engine never trusts a broadcast for "partner sealed".
//  - Answer PAYLOADS (RevealEnvelope) cross ONLY via broadcast, are buffered in
//    memory here, and are NEVER persisted. Not to SwiftData, not to the row,
//    not to enqueueSync. Privacy invariant, not a nicety.
//
//  bothSealed requires BOTH the partner's row flag AND their buffered payload.
//  Payload may arrive before or after the flag. Flag without payload for
//  `resendGraceSeconds` → send a resend request; the partner device answers by
//  re-sending its envelope. Once both gates open, EACH device runs its own
//  local 3-2-1 (no countdown broadcast; small skew is a shared breath).
//
//  All wire access goes through RevealTransporting so unit tests inject a mock.
//

import Foundation
import Observation

// MARK: - Transport seam

/// Everything the engine needs from the wire. CoupleSessionStore adapts the
/// real service + coordinator (Sections 1-2) behind this; tests inject a mock.
@MainActor
protocol RevealTransporting: AnyObject {
    /// Merge-write my seal flag into reveal_state (Section 1 RPC).
    func setSealed(cardId: String) async throws
    /// Merge-write the revealed flag (idempotent; both devices may write it).
    func setRevealed(cardId: String) async throws
    /// Clear my seal flag after a reconnect lost my local payload (re-compose).
    func clearSeal(cardId: String) async throws
    /// Broadcast my answer envelope (ephemeral).
    func sendEnvelope(_ envelope: RevealEnvelope)
    /// Ask the partner device to re-send its envelope for this card.
    func requestResend(cardId: String)
}

// MARK: - RevealEngine

@Observable
@MainActor
final class RevealEngine {

    enum Phase: Equatable {
        case composing
        case sealedMine
        case bothSealed
        case countdown(Int)     // 3, 2, 1
        case revealed
    }

    // MARK: State (views read these)

    private(set) var phase: Phase = .composing
    private(set) var cardId: String?
    /// My sealed answer — kept locally so the reveal renders without a round trip.
    private(set) var myEnvelope: RevealEnvelope?
    /// The partner's answer — arrives ONLY via broadcast. In-memory only.
    private(set) var partnerEnvelope: RevealEnvelope?
    /// Partner's seal flag as last seen on the ROW (never from broadcast).
    private(set) var partnerSealed = false

    /// True once the row says revealed (reconnect into an already-revealed card
    /// skips the countdown ceremony — no double 3-2-1).
    private var revealedOnRow = false

    // MARK: Dependencies

    private let role: SessionRole
    private weak var transport: RevealTransporting?
    /// Injected so tests run without real waits (matches CoupleSessionStore's
    /// presenceSeconds/transitionSeconds pattern).
    private let countdownStepSeconds: Double
    private let resendGraceSeconds: Double

    private var countdownTask: Task<Void, Never>?
    private var resendTask: Task<Void, Never>?

    init(
        role: SessionRole,
        transport: RevealTransporting?,
        countdownStepSeconds: Double = 1.0,
        resendGraceSeconds: Double = 5.0
    ) {
        self.role = role
        self.transport = transport
        self.countdownStepSeconds = countdownStepSeconds
        self.resendGraceSeconds = resendGraceSeconds
    }

    // MARK: - Lifecycle

    /// Arm the engine for a reveal card. Cancels any prior card's tasks.
    func beginCard(_ id: String) {
        cancelTasks()
        cardId = id
        phase = .composing
        myEnvelope = nil
        partnerEnvelope = nil
        partnerSealed = false
        revealedOnRow = false
    }

    /// Leaving the card (advance / session end). Payloads die here — by design.
    func teardown() {
        cancelTasks()
        cardId = nil
        myEnvelope = nil
        partnerEnvelope = nil
    }

    // MARK: - My side

    /// Seal my answer: freeze input, flag the row, broadcast the payload, keep
    /// it locally. Idempotent — a second call is a no-op.
    func seal(_ body: RevealEnvelope.Body) {
        guard let cardId, phase == .composing else { return }
        let envelope = RevealEnvelope(cardId: cardId, role: role, body: body)
        myEnvelope = envelope
        phase = .sealedMine
        transport?.sendEnvelope(envelope)
        Task { @MainActor in
            try? await self.transport?.setSealed(cardId: cardId)
        }
        evaluateGate()
    }

    // MARK: - Wire inputs (the store pumps these)

    /// Row update for THIS card's flags. The row is the only seal authority.
    func applyRowFlags(mySealed: Bool, partnerSealed: Bool, revealed: Bool) {
        guard cardId != nil else { return }
        if revealed { revealedOnRow = true }
        if partnerSealed, !self.partnerSealed {
            self.partnerSealed = true
        }
        evaluateGate()
    }

    /// A broadcast envelope arrived (may precede the row flag — buffer it).
    func receive(_ envelope: RevealEnvelope) {
        guard envelope.cardId == cardId, envelope.role != role else { return }
        partnerEnvelope = envelope
        evaluateGate()
    }

    /// The partner asked us to re-send (their buffer lost our payload).
    func receiveResendRequest(cardId requested: String) {
        guard requested == cardId, let myEnvelope else { return }
        transport?.sendEnvelope(myEnvelope)
    }

    // MARK: - Reconnect restore

    enum RestoreOutcome: Equatable {
        /// Phase rebuilt from the flags; missing payloads are being re-requested.
        case resumed
        /// The row says I sealed but my payload died with the process — the
        /// caller clears my flag (transport.clearSeal) and the card re-prompts.
        case recompose
    }

    /// Rebuild phase from the row after an app kill / channel drop (spec §4.3:
    /// "flags from the row restore the phase; missing payload → resend path").
    @discardableResult
    func restore(cardId id: String, mySealed: Bool, partnerSealed: Bool, revealed: Bool) -> RestoreOutcome {
        beginCard(id)
        if mySealed && myEnvelope == nil {
            // My in-flight answer is gone. Reset my flag and re-prompt compose.
            // Copy for the card acknowledges it plainly (view, segment F2):
            // "that one got lost in the air, type it again"
            Task { @MainActor in
                try? await self.transport?.clearSeal(cardId: id)
            }
            return .recompose
        }
        revealedOnRow = revealed
        self.partnerSealed = partnerSealed
        if mySealed, let mine = myEnvelope {
            // Unreachable today (myEnvelope was just reset by beginCard) but kept
            // for a future warm-restore; the guard above catches the cold case.
            _ = mine
            phase = .sealedMine
        }
        evaluateGate()
        return .resumed
    }

    // MARK: - The gate

    /// bothSealed requires: I sealed (have my envelope) AND the partner's row
    /// flag AND the partner's buffered payload. Flag-without-payload arms the
    /// resend loop instead.
    private func evaluateGate() {
        guard phase != .revealed, case .countdown = phase { } else if phase == .revealed { return }
        guard myEnvelope != nil else { return }               // I haven't sealed yet
        guard partnerSealed else { return }                   // row hasn't flagged them

        if partnerEnvelope != nil {
            resendTask?.cancel()
            resendTask = nil
            if phase == .sealedMine {
                phase = .bothSealed
                startCountdown()
            }
        } else {
            armResendLoop()
        }
    }

    /// Flag set but payload missing: after the grace window, request a re-send;
    /// keep requesting each window until the payload lands or the card changes.
    private func armResendLoop() {
        guard resendTask == nil, let cardId else { return }
        resendTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled, self.partnerEnvelope == nil {
                try? await Task.sleep(for: .seconds(self.resendGraceSeconds))
                guard !Task.isCancelled, self.partnerEnvelope == nil else { break }
                self.transport?.requestResend(cardId: cardId)
            }
        }
    }

    /// Both gates open → 3-2-1 → revealed. Reconnecting into an
    /// already-revealed card skips the ceremony (no double countdown).
    private func startCountdown() {
        countdownTask?.cancel()
        if revealedOnRow {
            phase = .revealed
            return
        }
        countdownTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for n in [3, 2, 1] {
                guard !Task.isCancelled else { return }
                self.phase = .countdown(n)
                try? await Task.sleep(for: .seconds(self.countdownStepSeconds))
            }
            guard !Task.isCancelled else { return }
            self.phase = .revealed
            if let cardId = self.cardId {
                // Idempotent merge-write; both devices writing it is harmless.
                try? await self.transport?.setRevealed(cardId: cardId)
            }
        }
    }

    private func cancelTasks() {
        countdownTask?.cancel()
        countdownTask = nil
        resendTask?.cancel()
        resendTask = nil
    }
}
```

> Note the `evaluateGate()` first line: the intent is "return early if already revealed or mid-countdown". Written straight it is:
> ```swift
> if phase == .revealed { return }
> if case .countdown = phase { return }
> ```
> Use that two-line form (the compressed guard above is illegible — prefer the plain one when you write the file).

**Done:** `RevealEngine` compiles, is `@Observable @MainActor`, touches the wire only through `RevealTransporting`, and both payload-before-flag and flag-before-payload orders reach `bothSealed` exactly once.

---

## Segment F2 — Reveal views (thin skins) + special-card chrome

**One thing it does:** four reveal surfaces that render the engine's phase, each wrapped in the shared special-card treatment (animated spectrum border + particles from existing components), compose inputs screenshot-protected.

**F2a — the shared chrome.** Create `Vayl/Features/Sessions/Components/RevealCardChrome.swift`:

```swift
//
//  RevealCardChrome.swift
//  Vayl
//
//  The special-card treatment for reveal-mechanic cards (spec §4.4): an
//  animated spectrum border + slow drifting sparks framing the reveal surface.
//  Reuses VaylBorderEffect + .spectrumBorderGlow — no new primitives.
//  Reduce Motion: border holds steady, sparks are stilled.
//

import SwiftUI

struct RevealCardChrome<Content: View>: View {

    /// Glow ramps up through the ceremony: composing 0.3 → countdown 1.0.
    let intensity: Double
    @ViewBuilder let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false

    var body: some View {
        content
            .padding(AppSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .fill(AppColors.cardBg)
            )
            .overlay(
                GeometryReader { geo in
                    VaylBorderEffect(
                        width: geo.size.width,
                        height: geo.size.height,
                        cornerRadius: AppRadius.lg,
                        progress: 1.0,
                        glowIntensity: breathe ? intensity : intensity * 0.6,
                        hairlineVisible: false
                    )
                    .allowsHitTesting(false)
                }
            )
            .overlay(sparkField.allowsHitTesting(false))
            .spectrumBorderGlow(intensity: intensity * 0.5)
            .onAppear {
                guard !reduceMotion else { return }
                breathe = true
            }
            .ambientAnimation(
                .easeInOut(duration: AppAnimation.ambientPulse).repeatForever(autoreverses: true),
                value: breathe
            )
    }

    /// A sparse ring of sparks that drift with the breath. Stilled under
    /// Reduce Motion (breathe stays false → fixed positions).
    private var sparkField: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ForEach(0..<6, id: \.self) { i in
                let t = Double(i) / 6.0
                Text("✦")
                    .font(AppFonts.display(8, weight: .medium, relativeTo: .caption2))
                    .foregroundStyle(AppColors.spectrumText)
                    .opacity(0.25 + 0.35 * intensity)
                    .position(
                        x: w * (0.08 + 0.84 * t),
                        y: (i.isMultiple(of: 2) ? (breathe ? -6 : 2) : h + (breathe ? 6 : -2))
                    )
            }
        }
    }
}
```

**F2b — Whisper (whatIf reuses it).** Create `Vayl/Features/Sessions/Components/WhisperRevealView.swift`. Structure and privacy invariant carried over from plan 10's verified D3 view; phase now reads the engine, seal sends a `.text` body, and color coding matches the player's existing convention (you = magenta, partner = cyan, per `SessionPlayerView.drawerRow:146-167`).

```swift
//
//  WhisperRevealView.swift
//  Vayl
//
//  Whisper reveal: private text → seal → 3-2-1 → side-by-side, color-coded.
//  whatIf is the same mechanic with different framing copy (spec §4.3).
//  Thin skin over RevealEngine — no wire access, no persistence. The compose
//  field is screenshot-protected; answers exist only in engine memory.
//

import SwiftUI

struct WhisperRevealView: View {

    @Bindable var store: CoupleSessionStore
    /// True when the card is a whatIf (framing changes, mechanic identical).
    let isWhatIf: Bool
    /// True when a reconnect re-prompted compose (restore → .recompose).
    let recomposing: Bool

    @State private var draft: String = ""
    @FocusState private var focused: Bool

    private var engine: RevealEngine { store.revealEngine }

    var body: some View {
        RevealCardChrome(intensity: chromeIntensity) {
            VStack(spacing: AppSpacing.lg) {
                switch engine.phase {
                case .composing, .sealedMine:
                    composer
                case .bothSealed:
                    waitingBeat
                case .countdown(let n):
                    countdownFace(n)
                case .revealed:
                    revealedFace
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, AppSpacing.xl)
    }

    private var chromeIntensity: Double {
        switch engine.phase {
        case .composing:  return 0.3
        case .sealedMine: return 0.5
        case .bothSealed: return 0.7
        case .countdown:  return 1.0
        case .revealed:   return 0.8
        }
    }

    // MARK: - Compose

    private var composer: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(framingLine)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)

            TextField(isWhatIf ? "what if…" : "type it, then seal", text: $draft, axis: .vertical)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
                .lineLimit(3, reservesSpace: true)
                .focused($focused)
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(AppColors.inputBackground)
                )
                .disabled(engine.phase != .composing)
                .screenshotProtected()

            sealRow
        }
    }

    private var framingLine: String {
        if recomposing {
            return "that one got lost in the air, type it again"
        }
        return isWhatIf
            ? "answer the what-if honestly, private until you both seal"
            : "just for this reveal, private until you both seal"
    }

    private var sealRow: some View {
        HStack {
            if engine.partnerSealed, engine.phase == .composing {
                Text("they sealed, waiting on you")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.spectrumCyan)
            } else if engine.phase == .sealedMine {
                Text("sealed, waiting on them")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                engine.seal(.text(draft.trimmingCharacters(in: .whitespacesAndNewlines)))
                focused = false
            } label: {
                Text(engine.phase == .sealedMine ? "sealed" : "seal")
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(AppColors.void)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .background(Capsule().fill(AppColors.spectrumBorder))
            }
            .buttonStyle(.plain)
            .scaleEffect(engine.phase == .sealedMine ? 0.96 : 1.0)
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty
                      || engine.phase != .composing)
        }
    }

    // MARK: - Waiting / countdown / reveal

    private var waitingBeat: some View {
        Text("both sealed")
            .font(AppFonts.cardTitle)
            .foregroundStyle(AppColors.spectrumText)
    }

    private func countdownFace(_ n: Int) -> some View {
        Text("\(n)")
            .font(AppFonts.displayHero)
            .foregroundStyle(AppColors.spectrumText)
            .contentTransition(.numericText(countsDown: true))
            .animation(AppAnimation.standard, value: n)
    }

    private var revealedFace: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            answerBlock("you", myText, tint: AppColors.spectrumMagenta)
            answerBlock("them", partnerText, tint: AppColors.spectrumCyan)
        }
        .transition(.opacity)
    }

    private var myText: String {
        if case .text(let t)? = engine.myEnvelope?.body { return t }
        return ""
    }
    private var partnerText: String {
        if case .text(let t)? = engine.partnerEnvelope?.body { return t }
        return "…"
    }

    private func answerBlock(_ who: String, _ text: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(who)
                .font(AppFonts.overline)
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(tint)
            Text(text)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColors.cardBackground)
        )
    }
}
```

**F2c — Unspoken.** Create `Vayl/Features/Sessions/Components/UnspokenSliderView.swift`:

```swift
//
//  UnspokenSliderView.swift
//  Vayl
//
//  Unspoken reveal: each partner privately places a slider on the card's
//  spectrum → seal → both positions land on ONE spectrum bar. Thin skin over
//  RevealEngine; the position payload is a Double 0…1 in the envelope body.
//

import SwiftUI

struct UnspokenSliderView: View {

    @Bindable var store: CoupleSessionStore
    let recomposing: Bool

    @State private var position: Double = 0.5

    private var engine: RevealEngine { store.revealEngine }

    var body: some View {
        RevealCardChrome(intensity: engine.phase == .revealed ? 0.8 : 0.5) {
            VStack(spacing: AppSpacing.lg) {
                switch engine.phase {
                case .composing, .sealedMine:
                    composer
                case .bothSealed:
                    Text("both sealed")
                        .font(AppFonts.cardTitle)
                        .foregroundStyle(AppColors.spectrumText)
                case .countdown(let n):
                    Text("\(n)")
                        .font(AppFonts.displayHero)
                        .foregroundStyle(AppColors.spectrumText)
                case .revealed:
                    revealedSpectrum
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, AppSpacing.xl)
    }

    private var composer: some View {
        VStack(spacing: AppSpacing.md) {
            Text(recomposing
                 ? "that one got lost in the air, place it again"
                 : "place yourself, private until you both seal")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)

            Slider(value: $position, in: 0...1)
                .tint(AppColors.accentPrimary)
                .disabled(engine.phase != .composing)
                .screenshotProtected()

            Button {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                engine.seal(.position(position))
            } label: {
                Text(engine.phase == .sealedMine ? "sealed" : "seal")
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(AppColors.void)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .background(Capsule().fill(AppColors.spectrumBorder))
            }
            .buttonStyle(.plain)
            .scaleEffect(engine.phase == .sealedMine ? 0.96 : 1.0)
            .disabled(engine.phase != .composing)

            if engine.phase == .sealedMine {
                Text("sealed, waiting on them")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    /// Both positions on one spectrum: a spectrum bar, a magenta dot (you),
    /// a cyan dot (them).
    private var revealedSpectrum: some View {
        VStack(spacing: AppSpacing.md) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.spectrumBorder)
                        .frame(height: AppSpacing.xs)
                        .frame(maxHeight: .infinity, alignment: .center)
                    dot(AppColors.spectrumMagenta)
                        .offset(x: geo.size.width * myPosition - AppSpacing.sm)
                    dot(AppColors.spectrumCyan)
                        .offset(x: geo.size.width * partnerPosition - AppSpacing.sm)
                }
            }
            .frame(height: AppSpacing.xl)

            HStack {
                legend("you", tint: AppColors.spectrumMagenta)
                Spacer()
                legend("them", tint: AppColors.spectrumCyan)
            }
        }
        .transition(.opacity)
    }

    private var myPosition: Double {
        if case .position(let p)? = engine.myEnvelope?.body { return p }
        return 0.5
    }
    private var partnerPosition: Double {
        if case .position(let p)? = engine.partnerEnvelope?.body { return p }
        return 0.5
    }

    private func dot(_ tint: Color) -> some View {
        Circle()
            .fill(tint)
            .frame(width: AppSpacing.md, height: AppSpacing.md)
            .frame(maxHeight: .infinity, alignment: .center)
    }

    private func legend(_ label: String, tint: Color) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Circle().fill(tint).frame(width: AppSpacing.sm, height: AppSpacing.sm)
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}
```

**F2d — Mirror.** Create `Vayl/Features/Sessions/Components/MirrorRevealView.swift`. Role-aware: role `.a` answers about themself; role `.b` guesses what A said. The reveal shows both texts framed as answer vs guess — the gap speaks for itself; the app never scores it (discovery-tool rule: compare two points, no verdict).

```swift
//
//  MirrorRevealView.swift
//  Vayl
//
//  Mirror reveal: A answers about themself, B guesses A's answer → both seal
//  → gap reveal (answer beside guess, no scoring, no verdict — the couple
//  reads the gap themselves). Thin skin over RevealEngine.
//

import SwiftUI

struct MirrorRevealView: View {

    @Bindable var store: CoupleSessionStore
    let recomposing: Bool

    @State private var draft: String = ""
    @FocusState private var focused: Bool

    private var engine: RevealEngine { store.revealEngine }
    /// Role .a is the subject; .b is the mirror.
    private var isSubject: Bool { store.sessionRoleForViews == .a }

    var body: some View {
        RevealCardChrome(intensity: engine.phase == .revealed ? 0.8 : 0.5) {
            VStack(spacing: AppSpacing.lg) {
                switch engine.phase {
                case .composing, .sealedMine:
                    composer
                case .bothSealed:
                    Text("both sealed")
                        .font(AppFonts.cardTitle)
                        .foregroundStyle(AppColors.spectrumText)
                case .countdown(let n):
                    Text("\(n)")
                        .font(AppFonts.displayHero)
                        .foregroundStyle(AppColors.spectrumText)
                case .revealed:
                    revealedGap
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, AppSpacing.xl)
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(roleLine)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)

            TextField(isSubject ? "your answer" : "your guess",
                      text: $draft, axis: .vertical)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
                .lineLimit(3, reservesSpace: true)
                .focused($focused)
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(AppColors.inputBackground)
                )
                .disabled(engine.phase != .composing)
                .screenshotProtected()

            HStack {
                if engine.phase == .sealedMine {
                    Text("sealed, waiting on them")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    engine.seal(.text(draft.trimmingCharacters(in: .whitespacesAndNewlines)))
                    focused = false
                } label: {
                    Text(engine.phase == .sealedMine ? "sealed" : "seal")
                        .font(AppFonts.buttonLabel)
                        .foregroundStyle(AppColors.void)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.sm)
                        .background(Capsule().fill(AppColors.spectrumBorder))
                }
                .buttonStyle(.plain)
                .scaleEffect(engine.phase == .sealedMine ? 0.96 : 1.0)
                .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty
                          || engine.phase != .composing)
            }
        }
    }

    private var roleLine: String {
        if recomposing { return "that one got lost in the air, type it again" }
        return isSubject
            ? "answer for yourself, they are guessing what you will say"
            : "guess what they will say, they are answering for real"
    }

    /// Answer beside guess. Subject's real answer always renders first.
    private var revealedGap: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            gapBlock(
                label: isSubject ? "what you said" : "what they said",
                text: isSubject ? myText : partnerText,
                tint: AppColors.spectrumMagenta
            )
            gapBlock(
                label: isSubject ? "what they guessed" : "what you guessed",
                text: isSubject ? partnerText : myText,
                tint: AppColors.spectrumCyan
            )
        }
        .transition(.opacity)
    }

    private var myText: String {
        if case .text(let t)? = engine.myEnvelope?.body { return t }
        return ""
    }
    private var partnerText: String {
        if case .text(let t)? = engine.partnerEnvelope?.body { return t }
        return "…"
    }

    private func gapBlock(label: String, text: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label)
                .font(AppFonts.overline)
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(tint)
            Text(text)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColors.cardBackground)
        )
    }
}
```

**F2e — Snapshot.** Create `Vayl/Features/Sessions/Components/SnapshotRevealView.swift`:

```swift
//
//  SnapshotRevealView.swift
//  Vayl
//
//  Snapshot reveal: one word each, private → seal → the two words land
//  together. Thin skin over RevealEngine; the payload is the .word body.
//

import SwiftUI

struct SnapshotRevealView: View {

    @Bindable var store: CoupleSessionStore
    let recomposing: Bool

    @State private var word: String = ""
    @FocusState private var focused: Bool

    private var engine: RevealEngine { store.revealEngine }

    var body: some View {
        RevealCardChrome(intensity: engine.phase == .revealed ? 1.0 : 0.5) {
            VStack(spacing: AppSpacing.lg) {
                switch engine.phase {
                case .composing, .sealedMine:
                    composer
                case .bothSealed:
                    Text("both sealed")
                        .font(AppFonts.cardTitle)
                        .foregroundStyle(AppColors.spectrumText)
                case .countdown(let n):
                    Text("\(n)")
                        .font(AppFonts.displayHero)
                        .foregroundStyle(AppColors.spectrumText)
                case .revealed:
                    landedWords
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, AppSpacing.xl)
    }

    private var composer: some View {
        VStack(spacing: AppSpacing.md) {
            Text(recomposing
                 ? "that one got lost in the air, one word again"
                 : "one word, private until you both seal")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)

            TextField("one word", text: $word)
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textBody)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focused)
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(AppColors.inputBackground)
                )
                .disabled(engine.phase != .composing)
                .screenshotProtected()
                .onChange(of: word) { _, new in
                    // Snapshot means ONE word — clamp at the first space.
                    if let space = new.firstIndex(of: " ") {
                        word = String(new[..<space])
                    }
                }

            Button {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                engine.seal(.word(word.trimmingCharacters(in: .whitespacesAndNewlines)))
                focused = false
            } label: {
                Text(engine.phase == .sealedMine ? "sealed" : "seal")
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(AppColors.void)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .background(Capsule().fill(AppColors.spectrumBorder))
            }
            .buttonStyle(.plain)
            .scaleEffect(engine.phase == .sealedMine ? 0.96 : 1.0)
            .disabled(word.trimmingCharacters(in: .whitespaces).isEmpty
                      || engine.phase != .composing)

            if engine.phase == .sealedMine {
                Text("sealed, waiting on them")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    /// The two words land together, side by side, color-coded.
    private var landedWords: some View {
        HStack(spacing: AppSpacing.xl) {
            landedWord(myWord, tint: AppColors.spectrumMagenta)
            landedWord(partnerWord, tint: AppColors.spectrumCyan)
        }
        .transition(.scale(scale: 0.8).combined(with: .opacity))
    }

    private var myWord: String {
        if case .word(let w)? = engine.myEnvelope?.body { return w }
        return ""
    }
    private var partnerWord: String {
        if case .word(let w)? = engine.partnerEnvelope?.body { return w }
        return "…"
    }

    private func landedWord(_ w: String, tint: Color) -> some View {
        Text(w)
            .font(AppFonts.display(28, weight: .medium, relativeTo: .title))
            .foregroundStyle(tint)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
    }
}
```

**Done:** all four reveal views compile as pure skins (no service, no persistence, no raw tokens); every compose input carries `.screenshotProtected()`; whatIf is Whisper with `isWhatIf: true`.

---

## Segment F3 — Local living-card faces (no sync)

**One thing it does:** the nine local living cards render with a per-type face treatment (accent, iconography, pacing) instead of the generic hero prompt; `pause` is a held-breath screen with no prompt.

Create `Vayl/Features/Sessions/Components/LocalCardFaceView.swift`:

```swift
//
//  LocalCardFaceView.swift
//  Vayl
//
//  Per-type face treatment for the LOCAL living cards (no sync, no reveal):
//  dare, greenLight, coolOff, bodyCheck, permissionCard, appreciationInterrupt,
//  openingRitual, closingRitual, pause. Rendered by the prompt engine in place
//  of the generic hero prompt. pause = a held-breath screen, no prompt at all.
//
//  Accent/icon/pacing per type; everything from tokens. The prompt text keeps
//  the player's highlight treatment via the shared helper below.
//

import SwiftUI

struct LocalCardFaceView: View {

    let card: Card

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var entered = false
    @State private var breathe = false

    var body: some View {
        Group {
            if card.type == .pause {
                pauseFace
            } else {
                typedFace
            }
        }
        .onAppear {
            withAnimation(reduceMotion ? AppAnimation.fast : face.enterAnimation) {
                entered = true
            }
            if !reduceMotion { breathe = true }
        }
        .onDisappear { entered = false }
    }

    // MARK: - Typed face

    private var typedFace: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: face.icon)
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(face.accent)
                Text(face.label)
                    .font(AppFonts.overline)
                    .tracking(3)
                    .textCase(.uppercase)
                    .foregroundStyle(face.accent)
            }
            .opacity(entered ? 1 : 0)

            Text(card.text)
                .font(AppFonts.display(26, weight: .medium, relativeTo: .title))
                .foregroundStyle(AppColors.textPrimary)
                .lineSpacing(AppSpacing.xs)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(entered ? 1 : 0)
                .offset(y: entered ? 0 : AppSpacing.sm)

            if let sub = face.subline {
                Text(sub)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .opacity(entered ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.xl)
    }

    // MARK: - Pause: the held breath

    private var pauseFace: some View {
        VStack(spacing: AppSpacing.lg) {
            Text("✦")
                .font(AppFonts.display(34, weight: .medium, relativeTo: .largeTitle))
                .foregroundStyle(AppColors.spectrumText)
                .scaleEffect(breathe ? 1.12 : 1.0)
                .ambientAnimation(
                    .easeInOut(duration: AppAnimation.ambientPulse).repeatForever(autoreverses: true),
                    value: breathe
                )
            Text("just breathe for a minute")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Per-type treatment

    private struct FaceTreatment {
        let label: String
        let icon: String
        let accent: Color
        let subline: String?
        let enterAnimation: Animation
    }

    private var face: FaceTreatment {
        switch card.type {
        case .dare:
            return .init(label: "Dare", icon: "flame",
                         accent: AppColors.spectrumMagenta,
                         subline: "do it now, together",
                         enterAnimation: AppAnimation.spring)
        case .greenLight:
            return .init(label: "Green light", icon: "arrowtriangle.forward.circle",
                         accent: AppColors.success,
                         subline: "one of you names a want, the other only says: tell me more",
                         enterAnimation: AppAnimation.enter)
        case .coolOff:
            return .init(label: "Cool off", icon: "wind",
                         accent: AppColors.spectrumCyan,
                         subline: "a pressure valve, take it slow",
                         enterAnimation: AppAnimation.slow)
        case .bodyCheck:
            return .init(label: "Body check", icon: "figure.mind.and.body",
                         accent: AppColors.spectrumPurple,
                         subline: "where does this conversation live in you right now",
                         enterAnimation: AppAnimation.slow)
        case .permissionCard:
            return .init(label: "Permission", icon: "checkmark.seal",
                         accent: AppColors.accentPrimary,
                         subline: "not a question, just read it to each other",
                         enterAnimation: AppAnimation.enter)
        case .appreciationInterrupt:
            return .init(label: "Appreciation", icon: "heart",
                         accent: AppColors.accentSecondary,
                         subline: "a reset, take it",
                         enterAnimation: AppAnimation.spring)
        case .openingRitual:
            return .init(label: "Opening", icon: "sparkle",
                         accent: AppColors.spectrumCyan,
                         subline: "the moment before card one",
                         enterAnimation: AppAnimation.slow)
        case .closingRitual:
            return .init(label: "Closing", icon: "moon.stars",
                         accent: AppColors.spectrumMagenta,
                         subline: "land it well",
                         enterAnimation: AppAnimation.slow)
        default:
            // pause is handled above; anything else falls back neutral.
            return .init(label: "Card", icon: "rectangle.portrait",
                         accent: AppColors.textSecondary,
                         subline: nil,
                         enterAnimation: AppAnimation.enter)
        }
    }
}
```

**Done:** every local living-card type renders a distinct labeled face; `pause` shows the breathing spark and no prompt; all pacing differences run through `AppAnimation` tokens with Reduce Motion fallbacks.

---

## Segment F4 — Context beats + card back flip

**One thing it does:** `contextBeatType` cards get their beat BEFORE the card presents (banner = 5s auto-dismiss over the dimmed card, tap-through; interstitial = full screen, user-dismissed); `backCopy` cards get a flip affordance after discussion, before advance.

**F4a — beat overlay.** Create `Vayl/Features/Sessions/Components/ContextBeatOverlayView.swift`:

```swift
//
//  ContextBeatOverlayView.swift
//  Vayl
//
//  Pre-card context beats (spec §4.4). banner: 1-2 lines over the dimmed card,
//  auto-dismiss after 5s, tap-through (never blocks the player). interstitial:
//  full screen, the user dismisses it. Both appear BEFORE the card presents —
//  never on it (AppCardEnums.swift:180-187). Presentation only; the store owns
//  when a beat is active.
//

import SwiftUI

struct ContextBeatOverlayView: View {

    let type: ContextBeatType
    let copy: String
    /// Store callback — banner fires it on its own after the dwell; the
    /// interstitial fires it from its button.
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 🎚️ Banner dwell before it slips away (spec: 5s).
    private static let bannerDwellSeconds: Double = 5.0

    var body: some View {
        switch type {
        case .banner:  banner
        case .interstitial: interstitial
        }
    }

    // MARK: - Banner: over the dimmed card, tap-through

    private var banner: some View {
        VStack {
            Text(copy)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(AppColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
                        )
                )
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.xxl)
            Spacer()
        }
        .background(
            // The dim behind the banner — also tap-through.
            AppColors.void.opacity(0.4).ignoresSafeArea()
        )
        .allowsHitTesting(false)   // tap-through: the player stays interactive
        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
        .task {
            try? await Task.sleep(for: .seconds(Self.bannerDwellSeconds))
            onDismiss()
        }
    }

    // MARK: - Interstitial: full screen, user-dismissed

    private var interstitial: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            VStack(spacing: AppSpacing.xl) {
                Text("worth knowing")
                    .font(AppFonts.overline)
                    .tracking(3)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.spectrumText)

                Text(copy)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textBody)
                    .lineSpacing(AppSpacing.xs)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, AppSpacing.xl)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onDismiss()
                } label: {
                    Text("got it")
                        .font(AppFonts.buttonLabel)
                        .foregroundStyle(AppColors.void)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.vertical, AppSpacing.sm)
                        .background(Capsule().fill(AppColors.spectrumBorder))
                }
                .buttonStyle(.plain)
            }
        }
        .transition(.opacity)
    }
}
```

**F4b — card back flip.** Create `Vayl/Features/Sessions/Components/CardBackFlipView.swift`:

```swift
//
//  CardBackFlipView.swift
//  Vayl
//
//  The back-copy flip (spec §4.4): backCopy cards earn a flip affordance after
//  discussion, before advance. Tapping flips the face over (3D turn, Reduce
//  Motion = crossfade) to the responsive back copy. Presentation only; the
//  store owns showingCardBack.
//

import SwiftUI

struct CardBackFlipView: View {

    let backCopy: String
    let showingBack: Bool
    let onFlip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if showingBack {
            backFace
        } else {
            flipAffordance
        }
    }

    private var flipAffordance: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onFlip()
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
                    .font(AppFonts.caption)
                Text("turn the card over")
                    .font(AppFonts.buttonLabelSmall)
            }
            .foregroundStyle(AppColors.spectrumText)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                Capsule().fill(AppColors.cardBackground.opacity(0.6))
                    .overlay(Capsule().strokeBorder(AppColors.borderDefault, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    private var backFace: some View {
        Text(backCopy)
            .font(AppFonts.bodyText)
            .foregroundStyle(AppColors.textBody)
            .lineSpacing(AppSpacing.xs)
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.obCard, style: .continuous)
                    .fill(AppColors.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.obCard, style: .continuous)
                            .strokeBorder(AppColors.spectrumBorder.opacity(0.6), lineWidth: 1.1)
                    )
            )
            .rotation3DEffect(
                .degrees(reduceMotion ? 0 : 0),   // lands flat; the turn is the transition
                axis: (x: 0, y: 1, z: 0)
            )
            .transition(reduceMotion
                        ? .opacity
                        : .asymmetric(
                            insertion: .scale(scale: 0.96).combined(with: .opacity),
                            removal: .opacity))
    }
}
```

**Done:** banner beats auto-dismiss after 5s without blocking taps; interstitials hold until "got it"; backCopy cards show the flip affordance and the back renders on tap.

---

## Segment F5 — Store wiring (CoupleSessionStore owns the engine + face routing state)

**One thing it does:** the store owns one `RevealEngine`, adapts the real transport behind `RevealTransporting`, and exposes the card-presentation state (context beat active, card back shown, reveal satisfied) that the player routes on. Local (no-realtime) path stays byte-for-byte playable.

Edit `Vayl/Features/Sessions/CoupleSessionStore.swift`. Add after the realtime scaffold block (after `:313`, `startRemoteSync`):

```swift
    // MARK: - Reveal engine (Section 3, segment F5)

    /// ONE engine serves all five reveal mechanics. Rebuilt lazily when the
    /// transport becomes available; in the pure-local path it exists with a nil
    /// transport (compose/seal work, bothSealed never fires — DEBUG preview
    /// only, matching the mocked-partner local flow).
    private(set) lazy var revealEngine = RevealEngine(
        role: sessionRole,
        transport: revealTransport
    )

    /// The views need the role for role-aware prompts (Mirror). Exposing the
    /// private let through a computed keeps the stored property private.
    var sessionRoleForViews: SessionRole { sessionRole }

    /// Set true by restore when the row said "sealed" but the payload died with
    /// the process — the reveal views show the re-compose copy once.
    private(set) var revealRecomposing = false

    /// Adapter: RevealTransporting over the injected service + Section 2's
    /// coordinator. nil when running pure-local.
    private var revealTransport: RevealTransportAdapter? {
        guard let realtime, let sid = remoteSessionId else { return nil }
        return RevealTransportAdapter(
            realtime: realtime,
            sessionId: sid,
            role: sessionRole,
            coordinator: coordinator            // ← SECTION 2 SEAM: the store's
        )                                       //   SessionSyncCoordinator?
    }

    // MARK: - Card presentation state (context beats, card backs)

    /// The beat waiting to play before the current card. nil = none / done.
    private(set) var activeContextBeat: (type: ContextBeatType, copy: String)?
    /// Beats play once per card per sitting.
    private var beatShownCardIds: Set<String> = []
    /// backCopy flip state for the current card.
    private(set) var showingCardBack = false

    /// A reveal card may only advance once revealed (the ceremony is the card).
    var revealSatisfied: Bool {
        guard currentCard?.isRevealMechanic == true else { return true }
        return revealEngine.phase == .revealed
    }

    func dismissContextBeat() {
        activeContextBeat = nil
    }

    func flipCardBack() {
        guard currentCard?.hasBackCopy == true else { return }
        showingCardBack = true
    }

    /// Central per-card setup. Called on session start and EVERY index move —
    /// the local path calls it from advanceOrFinish; Section 2's applyRemoteRow
    /// calls it when the echoed current_index changes.
    func cardDidChange() {
        showingCardBack = false
        revealRecomposing = false
        activeContextBeat = nil

        guard let card = currentCard else { return }

        if card.hasContextBeat,
           let type = card.contextBeatType,
           let copy = card.contextBeatCopy,
           !beatShownCardIds.contains(card.id) {
            beatShownCardIds.insert(card.id)
            activeContextBeat = (type, copy)
        }

        if card.isRevealMechanic {
            revealEngine.beginCard(card.id)
        } else {
            revealEngine.teardown()
        }
    }

    // MARK: - Reveal wire pumps (SECTION 2 SEAM: coordinator callbacks call these)

    /// Row update → this card's flags into the engine. Section 2's
    /// applyRemoteRow forwards dto.revealState[currentCard.id] here.
    func syncRevealFlags(from flags: RevealFlags?) {
        guard let card = currentCard, card.isRevealMechanic, let flags else { return }
        let mySealed = sessionRole == .a ? flags.aSealed : flags.bSealed
        let partnerSealed = sessionRole == .a ? flags.bSealed : flags.aSealed
        revealEngine.applyRowFlags(
            mySealed: mySealed,
            partnerSealed: partnerSealed,
            revealed: flags.revealed
        )
    }

    func receiveRevealEnvelope(_ envelope: RevealEnvelope) {
        revealEngine.receive(envelope)
    }

    func receiveRevealResendRequest(cardId: String) {
        revealEngine.receiveResendRequest(cardId: cardId)
    }

    /// Reconnect restore for the current card (Section 2 calls this after
    /// rebuilding state from fetchOpenSession).
    func restoreReveal(flags: RevealFlags?) {
        guard let card = currentCard, card.isRevealMechanic else { return }
        let mySealed = (sessionRole == .a ? flags?.aSealed : flags?.bSealed) ?? false
        let partnerSealed = (sessionRole == .a ? flags?.bSealed : flags?.aSealed) ?? false
        let outcome = revealEngine.restore(
            cardId: card.id,
            mySealed: mySealed,
            partnerSealed: partnerSealed,
            revealed: flags?.revealed ?? false
        )
        revealRecomposing = (outcome == .recompose)
    }
```

Two touch-ups inside existing methods (anchors verified):

1. `advanceOrFinish()` (`:214-220`) — after the local `index += 1`, call the per-card setup:

```swift
    private func advanceOrFinish() {
        if isLastCard {
            finishSession()
        } else {
            index += 1
            cardDidChange()      // Section 3: beats / back / reveal per-card setup
        }
    }
```

(When Section 2's live path is active and `index` moves via the echoed row instead, `applyRemoteRow` calls `cardDidChange()` — seam noted above. The two paths never double-fire because exactly one of them moves `index`.)

2. `confirmSynced()` (`:177-184`) — arm the first card's presentation when the session phase lands:

```swift
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(transitionSeconds))
            if phase == .transition {
                phase = .session
                cardDidChange()      // Section 3: first card's beat/reveal setup
            }
        }
```

**The transport adapter** (same file, bottom, below the store — or its own extension block; it is glue, not a Service):

```swift
// MARK: - RevealTransportAdapter (glue: engine seam → real wire)

/// Adapts the Section-1 service (row flag merge-writes) + Section-2 coordinator
/// (broadcast) to the engine's RevealTransporting seam. Owned per-session by
/// CoupleSessionStore; holds no state of its own.
@MainActor
final class RevealTransportAdapter: RevealTransporting {

    private let realtime: RealtimeSessionService
    private let sessionId: UUID
    private let role: SessionRole
    private weak var coordinator: SessionSyncCoordinator?   // SECTION 2 SEAM

    init(
        realtime: RealtimeSessionService,
        sessionId: UUID,
        role: SessionRole,
        coordinator: SessionSyncCoordinator?
    ) {
        self.realtime = realtime
        self.sessionId = sessionId
        self.role = role
        self.coordinator = coordinator
    }

    func setSealed(cardId: String) async throws {
        try await realtime.setSealed(sessionId: sessionId, cardId: cardId, role: role)
    }

    func setRevealed(cardId: String) async throws {
        try await realtime.setRevealed(sessionId: sessionId, cardId: cardId)
    }

    func clearSeal(cardId: String) async throws {
        try await realtime.clearSeal(sessionId: sessionId, cardId: cardId, role: role)
    }

    func sendEnvelope(_ envelope: RevealEnvelope) {
        coordinator?.sendReveal(envelope)
    }

    func requestResend(cardId: String) {
        coordinator?.sendResendRequest(cardId: cardId)
    }
}
```

> ⚠️ If Section 2 named its coordinator property differently, or Section 1's mutator signatures differ, **trust their landed code** and adjust the adapter only — the engine and its protocol do not change.

**Done:** the store compiles owning one engine + adapter; `cardDidChange()` fires on session start and every index move; reveal cards gate advance through `revealSatisfied`; the pure-local playthrough (no realtime) still deals end to end.

---

## Segment F6 — Player routing (SessionPlayerView renders by card type)

**One thing it does:** `SessionPlayerView` routes the face by card type (reveal view / local face / existing hero prompt), overlays context beats, shows the back-flip affordance, and blocks the hold-to-deal until a reveal card is revealed. The hold-to-deal mechanic itself is untouched.

Edit `Vayl/Features/Sessions/SessionPlayerView.swift`:

**1. `screenLayer` (`:129-144`)** — replace the single hero-prompt branch with a type router (the prompt/reflect branch is the EXISTING code, moved verbatim):

```swift
    private var screenLayer: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            drawerRow
            if let card = store.currentCard {
                cardFace(card)
                if card.hasBackCopy, !card.isRevealMechanic {
                    CardBackFlipView(
                        backCopy: card.backCopy ?? "",
                        showingBack: store.showingCardBack,
                        onFlip: { store.flipCardBack() }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.xl)
        .padding(.bottom, 150)
        .frame(maxHeight: .infinity, alignment: .center)
    }

    /// Face router: reveal mechanics get their reveal surface, local living
    /// cards get their typed face, discussion cards keep the hero prompt.
    @ViewBuilder
    private func cardFace(_ card: Card) -> some View {
        switch card.type {
        case .whisper:
            WhisperRevealView(store: store, isWhatIf: false,
                              recomposing: store.revealRecomposing)
        case .whatIf:
            WhisperRevealView(store: store, isWhatIf: true,
                              recomposing: store.revealRecomposing)
        case .unspoken:
            UnspokenSliderView(store: store, recomposing: store.revealRecomposing)
        case .mirror:
            MirrorRevealView(store: store, recomposing: store.revealRecomposing)
        case .snapshot:
            SnapshotRevealView(store: store, recomposing: store.revealRecomposing)
        case .prompt, .reflect:
            highlightedPrompt(card)                     // ← existing code, unmoved
                .font(AppFonts.display(26, weight: .medium, relativeTo: .title))
                .foregroundStyle(AppColors.textPrimary)
                .lineSpacing(AppSpacing.xs)
                .fixedSize(horizontal: false, vertical: true)
        default:
            LocalCardFaceView(card: card)               // the nine local living cards
        }
    }
```

(Note: `.padding(.bottom, 150)` is pre-existing layout debt in this view — keep it as-is, it is not this section's to fix.)

**2. `body` (`:42-80`)** — add the context-beat overlay above the idle dim, and gate the proceed control:

```swift
            controls
                .allowsHitTesting(store.revealSatisfied)   // reveal cards must reveal first
                .opacity(store.revealSatisfied ? 1 : 0.35)
                .animation(AppAnimation.standard, value: store.revealSatisfied)

            // Idle dim — (existing Rectangle, unchanged) …

            if let beat = store.activeContextBeat {
                ContextBeatOverlayView(
                    type: beat.type,
                    copy: beat.copy,
                    onDismiss: { store.dismissContextBeat() }
                )
                .zIndex(10)
            }
```

Also arm the first card when the player appears in the local/preview path (the store call is idempotent — `cardDidChange` on the same card just resets its per-card state):

```swift
        .onAppear {
            scheduleIdle()
            UIApplication.shared.isIdleTimerDisabled = true   // existing keep-awake
        }
```

(No change here beyond what exists — the first-card arm happens in `confirmSynced()`, segment F5. Do NOT re-introduce plan 10's `connectedScenes` keep-awake rewrite; that ships with Section 2's player transport work if it hasn't already.)

**Done:** a Whisper/whatIf/unspoken/mirror/snapshot card renders its reveal surface with the chrome; dare-through-pause render `LocalCardFaceView`; a banner beat slides over a dimmed card and dissolves; an interstitial holds; backCopy cards can flip; the proceed control is inert until a reveal card is revealed. Compiles.

---

## Segment G1 — SessionBuilderStore (plan → SessionPlan)

**One thing it does:** turns a composition-filtered card list + the deck's resume position into a `SessionPlan`, with reorder / trim (floor 3, closing-ritual protected) / timers, plus Quick start and Same-as-last (UserDefaults per deckId).

Create `Vayl/Features/Sessions/Builder/SessionBuilderStore.swift`:

```swift
//
//  SessionBuilderStore.swift
//  Vayl
//
//  Session Builder brain (spec §4.3, absorbing fable-plan 11). Input: a deck's
//  composition-filtered cards + the resume index (DeckProgress.currentCardIndex,
//  passed by PlayStore). Output: a SessionPlan (Section 1 struct) handed back
//  through the view's onStart; PlayStore calls openSession with it (Section 2).
//
//  Default = authored order, untimed, full remaining hand. Tools = reorder,
//  trim (min 3 cards; the closing ritual is untrimmable when it is in tonight's
//  slice), per-card or global timer. Fast paths = Quick start (defaults, one
//  tap) and Same as last time (last SessionPlan per deck in UserDefaults).
//
//  No SwiftData, no network, no service. Pure state → plan. UserDefaults is
//  injected so tests isolate a suite.
//

import Foundation
import Observation
import OSLog

private let logger = Logger(subsystem: "com.vayl.app", category: "SessionBuilderStore")

@Observable
@MainActor
final class SessionBuilderStore {

    // MARK: - Entry (one card in tonight's slice)

    struct Entry: Identifiable, Equatable {
        let cardId: String
        let text: String
        let isClosingRitual: Bool
        let isCeremonial: Bool
        var timerSeconds: Int?

        var id: String { cardId }

        static func == (lhs: Entry, rhs: Entry) -> Bool {
            lhs.cardId == rhs.cardId && lhs.timerSeconds == rhs.timerSeconds
        }
    }

    // MARK: - State

    private(set) var entries: [Entry]
    var globalTimerSeconds: Int?

    /// Cards trimmed out of tonight's slice (restorable until start).
    private(set) var trimmed: [Entry] = []

    // MARK: - Rules

    /// The floor: a session is never fewer than 3 cards (spec §4.3).
    static let minimumCards = 3
    /// Per-card timer ladder, cycled by the row chip. 🎚️ Bryan tunes on device.
    static let timerOptions: [Int?] = [nil, 60, 120, 180, 300]

    // MARK: - Dependencies

    private let deckId: String
    private let defaults: UserDefaults
    private static func lastPlanKey(_ deckId: String) -> String {
        "vayl.lastSessionPlan.\(deckId)"
    }

    // MARK: - Init

    /// `cards` is the deck's authored order ALREADY composition-filtered
    /// (PlayStore passes deck.cards(for: couple.connectionComposition), sorted).
    /// `startIndex` = DeckProgress.currentCardIndex — the remaining hand starts
    /// there. If fewer than minimumCards remain, the slice resets to the full
    /// hand (a nearly-finished deck starts a fresh run).
    init(deckId: String, cards: [Card], startIndex: Int, defaults: UserDefaults = .standard) {
        self.deckId = deckId
        self.defaults = defaults

        let ordered = cards.sorted { $0.sortOrder < $1.sortOrder }
        let clamped = min(max(0, startIndex), ordered.count)
        var remaining = Array(ordered.dropFirst(clamped))
        if remaining.count < Self.minimumCards {
            remaining = ordered
        }
        self.entries = remaining.map {
            Entry(cardId: $0.id,
                  text: $0.text,
                  isClosingRitual: $0.type == .closingRitual,
                  isCeremonial: $0.isCeremonial,
                  timerSeconds: nil)
        }
    }

    // MARK: - Derived

    var cardCount: Int { entries.count }
    var canTrimAny: Bool { entries.count > Self.minimumCards }

    /// Trim rule per card: floor of 3, and the closing ritual is protected
    /// whenever it is part of tonight's slice.
    func canTrim(_ cardId: String) -> Bool {
        guard entries.count > Self.minimumCards else { return false }
        guard let entry = entries.first(where: { $0.cardId == cardId }) else { return false }
        return !entry.isClosingRitual
    }

    // MARK: - Tools (reorder / trim / timers)

    func move(from offsets: IndexSet, to destination: Int) {
        entries.move(fromOffsets: offsets, toOffset: destination)
    }

    func trim(_ cardId: String) {
        guard canTrim(cardId) else { return }
        guard let idx = entries.firstIndex(where: { $0.cardId == cardId }) else { return }
        trimmed.append(entries.remove(at: idx))
    }

    /// Put a trimmed card back (appended to the end; the user re-orders freely).
    func restore(_ cardId: String) {
        guard let idx = trimmed.firstIndex(where: { $0.cardId == cardId }) else { return }
        entries.append(trimmed.remove(at: idx))
    }

    func setTimer(_ seconds: Int?, for cardId: String) {
        guard let idx = entries.firstIndex(where: { $0.cardId == cardId }) else { return }
        entries[idx].timerSeconds = seconds
    }

    /// Row chip: cycle the ladder nil → 1m → 2m → 3m → 5m → nil.
    func cycleTimer(for cardId: String) {
        guard let entry = entries.first(where: { $0.cardId == cardId }) else { return }
        let options = Self.timerOptions
        let idx = options.firstIndex(where: { $0 == entry.timerSeconds }) ?? 0
        setTimer(options[(idx + 1) % options.count], for: cardId)
    }

    // MARK: - Output

    /// The plan as currently authored. Per-card timers only include cards that
    /// actually have one; nil map when none do (untimed default).
    var plan: SessionPlan {
        var perCard: [String: Int] = [:]
        for entry in entries {
            if let s = entry.timerSeconds { perCard[entry.cardId] = s }
        }
        return SessionPlan(
            deckId: deckId,
            cardIds: entries.map(\.cardId),
            perCardTimerSeconds: perCard.isEmpty ? nil : perCard,
            globalTimerSeconds: globalTimerSeconds,
            deckVariant: nil
        )
    }

    /// Start: snapshot the plan, remember it for "Same as last time", return
    /// it for PlayStore → openSession (Section 2 owns that call).
    func start() -> SessionPlan {
        let built = plan
        persistAsLast(built)
        return built
    }

    // MARK: - Fast paths

    /// QUICK START: the untouched default — authored order, untimed, full
    /// remaining hand. One tap, no authoring.
    func quickStartPlan() -> SessionPlan {
        let built = SessionPlan(
            deckId: deckId,
            cardIds: entries.map(\.cardId),
            perCardTimerSeconds: nil,
            globalTimerSeconds: nil,
            deckVariant: nil
        )
        persistAsLast(built)
        return built
    }

    /// SAME AS LAST TIME: the last started plan for THIS deck, if its cards
    /// are still all present in the current filtered hand (stale ids = no chip).
    var lastPlan: SessionPlan? {
        guard let data = defaults.data(forKey: Self.lastPlanKey(deckId)),
              let stored = try? JSONDecoder().decode(SessionPlan.self, from: data)
        else { return nil }
        let known = Set(entries.map(\.cardId) + trimmed.map(\.cardId))
        guard !stored.cardIds.isEmpty, stored.cardIds.allSatisfy(known.contains)
        else { return nil }
        return stored
    }

    private func persistAsLast(_ plan: SessionPlan) {
        guard let data = try? JSONEncoder().encode(plan) else { return }
        defaults.set(data, forKey: Self.lastPlanKey(deckId))
        logger.info("builder: remembered plan for \(self.deckId) — \(plan.cardIds.count) cards")
    }
}
```

**Done:** default plan = authored-order remaining hand, untimed; trim refuses the floor and the closing ritual; `start()` persists and returns the plan; `lastPlan` round-trips through UserDefaults and rejects stale ids. No SwiftData, no service.

---

## Segment G2 — SessionBuilderView (the sheet UI + fast paths)

**One thing it does:** the builder surface — fast-path chips, reorderable card list with timer chips and trim, global timer row, Start CTA. Returns a `SessionPlan` through `onStart`; Section 2 hosts it as a `.vaylSheet` and routes the plan into `openSession`.

Create `Vayl/Features/Sessions/Builder/SessionBuilderView.swift`:

```swift
//
//  SessionBuilderView.swift
//  Vayl
//
//  Shape tonight's session (spec §4.4). Hosted as a .vaylSheet inside the
//  pre-session flow (Section 2 presents it and consumes onStart). Discrete
//  task you return from — never a cover. All output is a SessionPlan.
//

import SwiftUI

struct SessionBuilderView: View {

    @Bindable var store: SessionBuilderStore
    /// The finished plan goes up; the host (PlayStore via Section 2) calls
    /// openSession with it and moves to the lobby.
    let onStart: (SessionPlan) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            if store.cardCount == 0 {
                emptyState
            } else {
                content
            }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            header
            fastPathRow
            cardList
            footer
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: AppSpacing.xs) {
            Text("Shape tonight")
                .font(AppFonts.sectionHeading)
                .foregroundStyle(AppColors.textPrimary)
            Text("\(store.cardCount) cards, played in this order")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.top, AppSpacing.lg)
        .padding(.bottom, AppSpacing.md)
    }

    // MARK: - Fast paths

    private var fastPathRow: some View {
        HStack(spacing: AppSpacing.sm) {
            fastPathChip("Quick start") {
                onStart(store.quickStartPlan())
            }
            if let last = store.lastPlan {
                fastPathChip("Same as last time") {
                    onStart(last)
                }
            }
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.sm)
    }

    private func fastPathChip(_ label: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    Capsule().stroke(AppColors.spectrumBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Card list (reorder + trim + timer)

    private var cardList: some View {
        List {
            ForEach(Array(store.entries.enumerated()), id: \.element.id) { pair in
                row(index: pair.offset, entry: pair.element)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .onMove { store.move(from: $0, to: $1) }

            if !store.trimmed.isEmpty {
                trimmedSection
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))   // always reorderable
    }

    private func row(index: Int, entry: SessionBuilderStore.Entry) -> some View {
        HStack(spacing: AppSpacing.md) {
            Text("\(index + 1)")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .frame(width: AppSpacing.lg)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                if entry.isCeremonial {
                    Text(entry.isClosingRitual ? "CLOSING · STAYS" : "RITUAL")
                        .font(AppFonts.overline)
                        .tracking(2)
                        .foregroundStyle(AppColors.spectrumText)
                }
                Text(entry.text)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)
            }

            Spacer(minLength: AppSpacing.sm)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                store.cycleTimer(for: entry.cardId)
            } label: {
                Text(timerLabel(entry.timerSeconds))
                    .font(AppFonts.caption)
                    .foregroundStyle(entry.timerSeconds == nil
                                     ? AppColors.textTertiary : AppColors.textPrimary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(Capsule().stroke(AppColors.borderDefault, lineWidth: 1))
            }
            .buttonStyle(.plain)

            if entry.isClosingRitual {
                Image(systemName: "lock")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .accessibilityLabel("The closing ritual stays in the session")
            } else {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    store.trim(entry.cardId)
                } label: {
                    Image(systemName: "minus.circle")
                        .foregroundStyle(store.canTrim(entry.cardId)
                                         ? AppColors.textSecondary : AppColors.textTertiary)
                }
                .buttonStyle(.plain)
                .disabled(!store.canTrim(entry.cardId))
                .accessibilityLabel("Remove card \(index + 1)")
            }
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.md)
    }

    private var trimmedSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Set aside tonight")
                .font(AppFonts.overline)
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textTertiary)
            ForEach(store.trimmed) { entry in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    store.restore(entry.cardId)
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(AppColors.textTertiary)
                        Text(entry.text)
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.md)
    }

    private func timerLabel(_ seconds: Int?) -> String {
        guard let seconds else { return "no timer" }
        return "\(seconds / 60)m"
    }

    // MARK: - Footer (global timer + start)

    private var footer: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                Text("Whole-session budget")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                globalTimerChip
            }
            .padding(.horizontal, AppSpacing.md)

            VaylButton(label: "Start with \(store.cardCount) cards") {
                onStart(store.start())
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.lg)
        }
        .padding(.top, AppSpacing.sm)
    }

    /// 🎚️ Global budget ladder (minutes). nil = no budget (the default).
    private static let globalOptions: [Int?] = [nil, 15 * 60, 30 * 60, 45 * 60]

    private var globalTimerChip: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            let options = Self.globalOptions
            let idx = options.firstIndex(where: { $0 == store.globalTimerSeconds }) ?? 0
            store.globalTimerSeconds = options[(idx + 1) % options.count]
        } label: {
            Text(store.globalTimerSeconds.map { "\($0 / 60) min" } ?? "none")
                .font(AppFonts.caption)
                .foregroundStyle(store.globalTimerSeconds == nil
                                 ? AppColors.textTertiary : AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(Capsule().stroke(AppColors.borderDefault, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "rectangle.on.rectangle.slash")
                .font(AppFonts.displayHero)
                .foregroundStyle(AppColors.textTertiary)
            Text("Nothing to shape")
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text("This deck has no cards for tonight. Try another deck.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.xl)
    }
}
```

> Verify `VaylButton(label:action:)` matches the checked-out signature (plan 11 verified `VaylButton(label:style:size:isLoading:isDisabled:action:)` with defaults). If the label-only call does not compile, pass the defaults explicitly.
>
> ⚠️ **SECTION 2 SEAM:** this view is presented by the pre-session flow (`.vaylSheet(isPresented:heightFraction:screenHeight:showsGrabber:content:)` — signature verified `VaylPresentation.swift:224-240`), and `onStart` feeds `PlayStore` → `openSession`. Do not add a presentation site here.

**Done:** the sheet renders the remaining hand in authored order, reorderable and trimmable within the rules; timer chips cycle; Quick start and Same-as-last chips hand a plan straight up; Start builds + persists + hands up; empty state present. Compiles.

---

## Segment G3 — Unit tests (RevealEngine + SessionBuilderStore) + pbxproj wiring

**One thing it does:** the spec §11 unit coverage for this section, against mock seams, wired into the manually-maintained VaylTests target.

**pbxproj wiring (do this or the tests silently don't run):** VaylTests is a manual PBXGroup — new files need four pbxproj entries each, following the `AA00000N` convention exactly as the existing rows at `project.pbxproj:23-33` / `:64-73`. Last used id is `AA00000B`; use:
- `RevealEngineTests.swift` → build file `AA00000CAAAA000000000001`, file ref `AA00000CAAAA000000000002`
- `SessionBuilderStoreTests.swift` → build file `AA00000DAAAA000000000001`, file ref `AA00000DAAAA000000000002`

Each needs: the PBXBuildFile line, the PBXFileReference line, a child entry in the VaylTests group, and a line in the VaylTests Sources build phase — copy the `PulseHistoryTests.swift` rows and substitute.

**G3a — RevealEngineTests.** Create `VaylTests/RevealEngineTests.swift`:

```swift
//
//  RevealEngineTests.swift
//  VaylTests
//
//  RevealEngine state machine against a mock transport: seal orders,
//  payload-before-flag, flag-before-payload, the resend path, and reconnect
//  restore. Timings injected tiny so nothing waits in real time (matches
//  CoupleSessionPlaythroughTests' presenceSeconds pattern).
//

import XCTest
@testable import Vayl

@MainActor
final class RevealEngineTests: XCTestCase {

    // MARK: - Mock transport

    final class MockRevealTransport: RevealTransporting {
        var sealedCardIds: [String] = []
        var revealedCardIds: [String] = []
        var clearedCardIds: [String] = []
        var sentEnvelopes: [RevealEnvelope] = []
        var resendRequests: [String] = []

        func setSealed(cardId: String) async throws { sealedCardIds.append(cardId) }
        func setRevealed(cardId: String) async throws { revealedCardIds.append(cardId) }
        func clearSeal(cardId: String) async throws { clearedCardIds.append(cardId) }
        func sendEnvelope(_ envelope: RevealEnvelope) { sentEnvelopes.append(envelope) }
        func requestResend(cardId: String) { resendRequests.append(cardId) }
    }

    private var transport: MockRevealTransport!

    private func makeEngine(
        role: SessionRole = .a,
        countdownStep: Double = 0.01,
        resendGrace: Double = 0.05
    ) -> RevealEngine {
        transport = MockRevealTransport()
        let engine = RevealEngine(
            role: role,
            transport: transport,
            countdownStepSeconds: countdownStep,
            resendGraceSeconds: resendGrace
        )
        engine.beginCard("card-07")
        return engine
    }

    private func partnerEnvelope(_ text: String = "their answer") -> RevealEnvelope {
        RevealEnvelope(cardId: "card-07", role: .b, body: .text(text))
    }

    private func waitUntil(_ message: String,
                           timeout: TimeInterval = 3,
                           _ condition: () -> Bool) async {
        let start = Date()
        while !condition() {
            if Date().timeIntervalSince(start) > timeout {
                XCTFail("Timed out waiting: \(message)")
                return
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    // MARK: - Seal orders

    func testMySealFreezesAndFlagsAndBroadcasts() async {
        let engine = makeEngine()
        engine.seal(.text("mine"))

        XCTAssertEqual(engine.phase, .sealedMine)
        XCTAssertEqual(transport.sentEnvelopes.count, 1)
        XCTAssertEqual(transport.sentEnvelopes.first?.cardId, "card-07")
        await waitUntil("row seal flag written") { self.transport.sealedCardIds == ["card-07"] }
        // Sealing twice is a no-op.
        engine.seal(.text("again"))
        XCTAssertEqual(transport.sentEnvelopes.count, 1)
    }

    func testPartnerFirstThenMeReachesRevealed() async {
        let engine = makeEngine()
        // Partner's payload and flag both land before I even seal.
        engine.receive(partnerEnvelope())
        engine.applyRowFlags(mySealed: false, partnerSealed: true, revealed: false)
        XCTAssertEqual(engine.phase, .composing)   // nothing moves until I seal

        engine.seal(.text("mine"))
        await waitUntil("revealed after both gates") { engine.phase == .revealed }
        XCTAssertEqual(transport.revealedCardIds, ["card-07"])
        XCTAssertNil(transport.resendRequests.first)
    }

    // MARK: - Payload before flag

    func testPayloadBeforeFlag() async {
        let engine = makeEngine()
        engine.seal(.text("mine"))
        engine.receive(partnerEnvelope())          // payload arrives first
        XCTAssertEqual(engine.phase, .sealedMine)  // flag not seen yet → hold

        engine.applyRowFlags(mySealed: true, partnerSealed: true, revealed: false)
        await waitUntil("countdown ran to revealed") { engine.phase == .revealed }
        XCTAssertTrue(transport.resendRequests.isEmpty)
    }

    // MARK: - Flag before payload (+ resend path)

    func testFlagBeforePayloadArmsResendThenCompletes() async {
        let engine = makeEngine()
        engine.seal(.text("mine"))
        engine.applyRowFlags(mySealed: true, partnerSealed: true, revealed: false)
        XCTAssertEqual(engine.phase, .sealedMine)  // payload missing → no reveal

        await waitUntil("resend requested after grace") {
            self.transport.resendRequests.contains("card-07")
        }
        engine.receive(partnerEnvelope())          // the re-sent envelope lands
        await waitUntil("revealed after resend") { engine.phase == .revealed }
    }

    func testResendRequestAnsweredByReSendingMyEnvelope() {
        let engine = makeEngine()
        engine.seal(.text("mine"))
        XCTAssertEqual(transport.sentEnvelopes.count, 1)

        engine.receiveResendRequest(cardId: "card-07")
        XCTAssertEqual(transport.sentEnvelopes.count, 2)   // re-sent
        // A request for some other card is ignored.
        engine.receiveResendRequest(cardId: "card-99")
        XCTAssertEqual(transport.sentEnvelopes.count, 2)
    }

    // MARK: - Own-echo and stale-card hygiene

    func testOwnEchoAndOtherCardEnvelopesIgnored() {
        let engine = makeEngine()
        engine.seal(.text("mine"))
        engine.receive(RevealEnvelope(cardId: "card-07", role: .a, body: .text("echo")))
        engine.receive(RevealEnvelope(cardId: "card-99", role: .b, body: .text("stale")))
        XCTAssertNil(engine.partnerEnvelope)
    }

    // MARK: - Reconnect restore

    func testRestoreWithLostMyPayloadRecomposes() async {
        let engine = makeEngine()
        let outcome = engine.restore(
            cardId: "card-07", mySealed: true, partnerSealed: false, revealed: false
        )
        XCTAssertEqual(outcome, .recompose)
        XCTAssertEqual(engine.phase, .composing)
        await waitUntil("my flag cleared for re-compose") {
            self.transport.clearedCardIds == ["card-07"]
        }
    }

    func testRestoreWithPartnerSealedRequestsResend() async {
        let engine = makeEngine()
        let outcome = engine.restore(
            cardId: "card-07", mySealed: false, partnerSealed: true, revealed: false
        )
        XCTAssertEqual(outcome, .resumed)
        XCTAssertEqual(engine.phase, .composing)   // I still have to compose
        engine.seal(.text("mine"))
        await waitUntil("resend requested for missing payload") {
            self.transport.resendRequests.contains("card-07")
        }
        engine.receive(partnerEnvelope())
        await waitUntil("revealed") { engine.phase == .revealed }
    }

    func testRestoreIntoRevealedCardSkipsCountdownCeremony() async {
        let engine = makeEngine()
        _ = engine.restore(
            cardId: "card-07", mySealed: false, partnerSealed: true, revealed: true
        )
        engine.seal(.text("mine"))
        engine.receive(partnerEnvelope())
        // revealedOnRow short-circuits the 3-2-1: straight to revealed.
        await waitUntil("revealed without ceremony") { engine.phase == .revealed }
    }
}
```

**G3b — SessionBuilderStoreTests.** Create `VaylTests/SessionBuilderStoreTests.swift`:

```swift
//
//  SessionBuilderStoreTests.swift
//  VaylTests
//
//  Builder rules: trim floor, closing-ritual protection, same-as-last
//  persistence (isolated UserDefaults suite), remaining-hand seeding.
//  Card fixtures ride on Card.openerSamples (10 real opener cards) plus a
//  synthetic closing ritual — Card is a Codable struct, cheap to construct.
//

import XCTest
@testable import Vayl

@MainActor
final class SessionBuilderStoreTests: XCTestCase {

    private static let suiteName = "SessionBuilderStoreTests"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: Self.suiteName)
        defaults.removePersistentDomain(forName: Self.suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: Self.suiteName)
        super.tearDown()
    }

    // MARK: - Fixtures

    private func closingRitual(sortOrder: Int) -> Card {
        Card(
            id: "test-closing", deckId: "the-opener",
            text: "Before you put the phones down, each of you name one thing you heard tonight.",
            highlightWords: [], type: .closingRitual, intensity: .deepOcean,
            whoStarts: .both, isSensitive: false, canSkip: false,
            register: .flexible, contextBeatType: nil, contextBeatCopy: nil,
            backCopy: nil, isGenderedCard: false, genderedFor: nil,
            sortOrder: sortOrder
        )
    }

    /// First `n` opener samples + a closing ritual at the end.
    private func hand(_ n: Int) -> [Card] {
        Array(Card.openerSamples.prefix(n)) + [closingRitual(sortOrder: n + 1)]
    }

    private func makeStore(cards: [Card], startIndex: Int = 0) -> SessionBuilderStore {
        SessionBuilderStore(
            deckId: "the-opener", cards: cards,
            startIndex: startIndex, defaults: defaults
        )
    }

    // MARK: - Seeding

    func testDefaultIsAuthoredOrderRemainingHandUntimed() {
        let store = makeStore(cards: hand(5), startIndex: 2)
        // 6 cards total (5 + closing), resume at 2 → 4 remain, authored order.
        XCTAssertEqual(store.entries.map(\.cardId),
                       ["opener-03", "opener-04", "opener-05", "test-closing"])
        let plan = store.plan
        XCTAssertEqual(plan.deckId, "the-opener")
        XCTAssertNil(plan.perCardTimerSeconds)
        XCTAssertNil(plan.globalTimerSeconds)
    }

    func testNearlyFinishedDeckResetsToFullHand() {
        // startIndex leaves only 2 remaining (< minimum 3) → full hand seeds.
        let store = makeStore(cards: hand(5), startIndex: 4)
        XCTAssertEqual(store.cardCount, 6)
    }

    // MARK: - Trim floor

    func testTrimStopsAtThreeCards() {
        let store = makeStore(cards: hand(3))   // 4 cards
        XCTAssertTrue(store.canTrim("opener-01"))
        store.trim("opener-01")                 // → 3 cards, at the floor
        XCTAssertEqual(store.cardCount, 3)
        XCTAssertFalse(store.canTrim("opener-02"))
        store.trim("opener-02")                 // refused
        XCTAssertEqual(store.cardCount, 3)
    }

    // MARK: - Closing ritual protection

    func testClosingRitualCannotBeTrimmed() {
        let store = makeStore(cards: hand(5))   // 6 cards, plenty of headroom
        XCTAssertFalse(store.canTrim("test-closing"))
        store.trim("test-closing")
        XCTAssertTrue(store.entries.contains { $0.cardId == "test-closing" })
        // Ordinary cards still trim fine at the same count.
        store.trim("opener-01")
        XCTAssertEqual(store.cardCount, 5)
    }

    func testTrimmedCardCanBeRestored() {
        let store = makeStore(cards: hand(5))
        store.trim("opener-02")
        XCTAssertEqual(store.trimmed.map(\.cardId), ["opener-02"])
        store.restore("opener-02")
        XCTAssertTrue(store.entries.contains { $0.cardId == "opener-02" })
        XCTAssertTrue(store.trimmed.isEmpty)
    }

    // MARK: - Timers

    func testTimerCycleFollowsLadderAndLandsInPlan() {
        let store = makeStore(cards: hand(5))
        store.cycleTimer(for: "opener-01")      // nil → 60
        XCTAssertEqual(store.entries.first?.timerSeconds, 60)
        let plan = store.plan
        XCTAssertEqual(plan.perCardTimerSeconds?["opener-01"], 60)
        XCTAssertNil(plan.perCardTimerSeconds?["opener-02"])
    }

    // MARK: - Same as last time

    func testStartPersistsAndLastPlanRoundTrips() {
        let store = makeStore(cards: hand(5))
        store.trim("opener-01")
        store.cycleTimer(for: "opener-02")
        let started = store.start()

        // A fresh builder over the same deck sees the remembered plan.
        let fresh = makeStore(cards: hand(5))
        let last = fresh.lastPlan
        XCTAssertNotNil(last)
        XCTAssertEqual(last?.cardIds, started.cardIds)
        XCTAssertEqual(last?.perCardTimerSeconds?["opener-02"], 60)
    }

    func testLastPlanWithStaleCardIdsIsRejected() {
        let store = makeStore(cards: hand(5))
        _ = store.start()
        // The composition-filtered hand changed (a card vanished): stale plan hides.
        let narrower = makeStore(cards: Array(hand(5).dropFirst(2)))
        XCTAssertNil(narrower.lastPlan)
    }

    func testNoLastPlanBeforeFirstStart() {
        let store = makeStore(cards: hand(5))
        XCTAssertNil(store.lastPlan)
    }

    // MARK: - Quick start

    func testQuickStartIsTheUntimedDefaultAndPersists() {
        let store = makeStore(cards: hand(5))
        store.cycleTimer(for: "opener-01")           // authored a timer…
        let quick = store.quickStartPlan()           // …quick start ignores it
        XCTAssertNil(quick.perCardTimerSeconds)
        XCTAssertEqual(quick.cardIds, store.entries.map(\.cardId))
        XCTAssertNotNil(makeStore(cards: hand(5)).lastPlan)   // remembered
    }
}
```

**Done:** both test files compile in VaylTests (pbxproj entries `AA00000C`/`AA00000D` present in all four sections), and `xcodebuild test` runs them green alongside the existing suite.

---

## Definition of Done for Section 3 (build-green)

1. `RevealEngine` reaches `bothSealed` only on row-flag AND buffered payload, in either arrival order; flag-without-payload requests a resend after the grace; a resend request re-broadcasts the held envelope; `restore` rebuilds phase from flags and re-composes when my payload is gone (clearing my flag).
2. Answer payloads (`RevealEnvelope`, engine buffers, view `@State` drafts) are never written to any `@Model`, the row, or `enqueueSync` — grep `myEnvelope|partnerEnvelope|RevealEnvelope` shows zero persistence-path hits.
3. All four reveal views render every engine phase; compose inputs are `.screenshotProtected()`; whatIf = Whisper with alternate framing; special-card chrome reuses `VaylBorderEffect` / `.spectrumBorderGlow` only.
4. The nine local living-card types render `LocalCardFaceView` treatments; `pause` shows the held-breath screen with no prompt; all loops go through `.ambientAnimation` / Reduce-Motion guards.
5. Banner beats overlay the dimmed card, auto-dismiss in 5s, and never block taps (`allowsHitTesting(false)`); interstitials hold for "got it"; both fire once per card per sitting; `backCopy` cards flip.
6. Reveal cards cannot advance until revealed (`revealSatisfied` gates the proceed control); the hold-to-deal mechanic is otherwise untouched; the pure-local playthrough still persists `CardSession`/`CardResult`/`DeckProgress`.
7. `SessionBuilderStore` seeds authored-order remaining hand from `startIndex`, enforces the 3-card floor and closing-ritual protection, cycles timers, and round-trips Same-as-last through UserDefaults keyed by deckId (stale ids rejected).
8. `SessionBuilderView` compiles as a hosted view returning `SessionPlan` via `onStart` — no presentation site, no service call, no raw tokens; empty state present.
9. Both test files run green; pbxproj wiring follows the `AA00000C`/`AA00000D` convention.
10. Zero em dashes in any user-facing string added by this section; zero raw color/font/spacing/radius/duration literals in the new Views; no raw `.sheet`/`.fullScreenCover`; no iOS-26 banned APIs.

## Bryan verifies on device (this section's slice)

- [ ] Whisper on two devices: type privately, seal, 3-2-1 lands near-simultaneously, answers side by side, nothing about them appears anywhere later.
- [ ] Kill the app mid-compose after sealing, reopen: the card re-prompts with "that one got lost in the air" and the flow completes.
- [ ] Airplane-mode one device briefly after the partner seals: the resend path fills the missing answer within ~5-10s of reconnect.
- [ ] One reveal each of unspoken (two dots on one spectrum), mirror (answer vs guess reads clearly with no scoring), snapshot (two words land together). 🎚️ chrome intensity + spark count.
- [ ] Each local card type reads visually distinct at a glance; pause genuinely feels like a held breath. 🎚️ per-type pacing.
- [ ] Banner beat: card dims, line floats, taps still work, gone in ~5s. Interstitial holds until "got it". Back copy flips and reads before advance.
- [ ] Builder: reorder two cards, trim to the floor (watch it refuse), watch the closing ritual's lock, set a timer, Start; Quick start and Same as last time both land in the lobby with the right hand.

## Constraints / do-not-touch (this section)

- Do not modify `VaylCardFace` (shell frozen, `.drawingGroup()` stays) — none of these faces are OB card faces.
- Do not touch `persistSession()` / `persistReflection()` shape, `SessionCloseView`, `AirlockView`, `RealtimeSessionService` internals (Sections 1–2 own service changes), or `couple_session_records` / `SessionSyncService`.
- Do not add any persistence of reveal payloads — anywhere, ever.
- Do not present the builder or any reveal surface via raw `.sheet` / `.fullScreenCover`; hosting is Section 2's, through `.vaylSheet` / the existing `.vaylCover`.
- Do not re-register or duplicate `SessionPlan` — Section 1 owns that file's fate.
- The hold-to-deal gesture, fan deck, idle dim, and care sheet in `SessionPlayerView` stay functionally as-is beyond the named insertions.

## Open decisions (defaults chosen, flag them)

1. **Nearly-finished-deck seeding** (remaining < 3 → reseed full hand). Default as coded; alternative is blocking the builder with a "finish the deck" nudge. Flag for Bryan.
2. **Reveal advance gating** — proceed control disabled until `.revealed`. Default as coded (the ceremony is the card); alternative lets `pass()` skip a reveal card via the care sheet, which still works today (care-sheet Skip calls `store.pass()` and is intentionally left ungated as the escape hatch). Flag.
3. **Trimmed-cards restore section** — the spec names only "trim"; the set-aside list + restore is a small courtesy. Default: keep it. Flag if it reads as scope creep.
4. **Snapshot one-word clamp** (truncate at first space). Default as coded; alternative is allowing hyphenated compounds (already allowed — only spaces clamp).

# ═══════════════════ SECTION 4 — Content: 12-Deck Launch Catalog (absorbs plan 15 deck authoring) ═══════════════════

# SECTION 4 · Segment H — Content: Catalog Re-Cut, 12-Deck Blueprints, Exemplars, Lint

_This section absorbs and supersedes `docs/fable-plans/15-content-authoring.md`'s deck segments (its check-in/boundaries drafts are re-cut below; its desire/pulse/learn segments are NOT part of this plan). Spec authority: `docs/superpowers/specs/2026-07-01-card-sessions-front-to-back-design.md` sections 7 and 11. All schema facts below verified against the repo 2026-07-01._

**One sentence:** rewrite the deck catalog to the canonical 12-deck launch slate, blueprint every deck card by card, ship four decks as complete final copy (the-opener touch-up, the-check-in, after-last-night, appreciation), author the remaining eight at build time from the blueprints under the quality gates, and lock the structure with a VaylTests content lint.

---

## Files

### Create

| File | Responsibility |
|---|---|
| `Vayl/Resources/Decks/communication-intimacy.json` | Deck 3: renames/absorbs the `communication` stub (+ the usable `boundaries` seed), 11 cards |
| `Vayl/Resources/Decks/sex-and-pleasure.json` | Deck 4: absorbs the `desire-and-fantasy` stub where copy fits, 11 playable cards + gendered pair |
| `Vayl/Resources/Decks/jealousy.json` | Deck 5: absorbs the `jealousy-compersion` stub (its compersion seed survives as card j-10), 11 playable + gendered pair |
| `Vayl/Resources/Decks/flavors-discovery.json` | Deck 6: absorbs the `the-styles` stub, 10 cards, imagination-not-commitment |
| `Vayl/Resources/Decks/swinging.json` | Deck 7: new, practical style deck, 11 playable + gendered pair |
| `Vayl/Resources/Decks/after-last-night.json` | Deck 9: NEW, the most-needed deck. **Complete final copy in this section (exemplar 1)** |
| `Vayl/Resources/Decks/the-first-time.json` | Deck 10: new, emotional not logistical, 10 cards |
| `Vayl/Resources/Decks/when-it-gets-hard.json` | Deck 11: new, repair deck, excavation-ordering discipline, 11 cards |
| `Vayl/Resources/Decks/appreciation.json` | Deck 12: NEW, the warm one. **Complete final copy in this section (exemplar 2)** |
| `VaylTests/ContentLintTests.swift` | The content lint (full Swift below); manual pbxproj wiring required |

### Modify

| File | Line anchor | Change |
|---|---|---|
| `Vayl/Resources/Decks/deck-catalog.json` | whole file (16 lines) | Replace with the exact 12-entry catalog below |
| `Vayl/Resources/Decks/the-opener.json` | card `opener-02` (lines 32-49), tail of `cards` | Fix flagged back-copy line, de-em-dash the interstitial, add 2 flexible gendered variants, `schema_version` 1 → 2 |
| `Vayl/Resources/Decks/the-check-in.json` | whole file (1-card stub) | **Complete final copy in this section**, 6 cards, `schema_version` 2 |
| `Vayl/Resources/Decks/before-tonight.json` | whole file (1-card stub) | Author 10 cards from the blueprint, `schema_version` 2 |
| `Vayl/Core/Models/Deck.swift` | `cards(for:)` (lines 53-61) | Gendered-variant filter fix (old filter double-shows gendered cards to flexible couples once flexible variants exist) |
| `Vayl/Core/Models/Card.swift` | `openerSamples` card 2 (line ~116-117) | Sync sample `contextBeatCopy`/`backCopy` strings to the fixed opener-02 copy (preview data only, keeps the canonical line consistent) |
| `Vayl.xcodeproj/project.pbxproj` | VaylTests PBXGroup + Sources phase | Wire `ContentLintTests.swift` with ids `AA00000CAAAA000000000001` / `AA00000CAAAA000000000002` (next in the AA00000N convention after `AA00000B` = PulseHistoryTests) |

### Delete

| File | Reason |
|---|---|
| `Vayl/Resources/Decks/communication.json` | Renamed to `communication-intimacy.json` (seed card absorbed as ci-08) |
| `Vayl/Resources/Decks/desire-and-fantasy.json` | Absorbed into `sex-and-pleasure.json` |
| `Vayl/Resources/Decks/jealousy-compersion.json` | Absorbed into `jealousy.json` (seed = j-10) |
| `Vayl/Resources/Decks/the-styles.json` | Absorbed into `flavors-discovery.json` |
| `Vayl/Resources/Decks/boundaries.json` | Folds into opener/communication territory per spec 7.1; its seed card absorbed as ci-02 |
| `Vayl/Resources/Decks/trust-repair.json` | Later wave, off the launch catalog (spec 7.1) |
| `Vayl/Resources/Decks/right-now.json` | Later wave |
| `Vayl/Resources/Decks/metamour.json` | Later wave (multi-person, Act 2) |
| `Vayl/Resources/Decks/the-audit.json` | Later wave |
| `Vayl/Resources/Decks/unfinished-business.json` | Later wave |
| `Vayl/Resources/Decks/solo-prep.json` | Solo lane out of scope for V1 (spec section 1); also resolves the locked/free copy contradiction (spec 10.3) |
| `Vayl/Resources/Decks/deck-index.json` | Dead, zero Swift consumers (verified: only `assessment_questions` appears in `ContentLoader.swift:118`, and `loadAssessmentQuestions()` itself has zero call sites; plan 15 verified the same for all three) |
| `Vayl/Resources/Content/assessment_questions.json` | Dead: `loadAssessmentQuestions()` (ContentLoader.swift:117) has zero call sites |
| `Vayl/Resources/Content/cards.json` | Dead: `loadCards()` (ContentLoader.swift:113) has zero call sites; holds the "clinical" placeholder markers |

> **Deletion guardrails.** (1) Leave the dead `ContentLoader` accessor methods (`loadCards`/`loadAssessmentQuestions`, lines 113/117) alone; they compile unreferenced and belong to the dead-code plan. (2) Deleting decks pre-launch is safe: no live users, `DeckProgress` keys by `deckId`, and the removed ids never shipped. (3) Before deleting, re-run the zero-caller check: `grep -rn "deck-index\|assessment_questions\|solo-prep\|trust-repair\|right-now\|metamour\|the-audit\|unfinished-business\|boundaries" Vayl --include="*.swift"` and resolve any hit that is not `ContentLoader` itself or a comment. Known live hit to fix as part of this segment: any `PlayStore`/`PlayView` special-casing of `solo-prep` (the spec 10.3 contradiction) comes out with the file. (4) New `.json` files: the app target auto-syncs its file tree (only VaylTests is a manual PBXGroup), but verify the new deck files show under the app target's resources after creation.

---

## H1 — Catalog re-cut

**One thing it does:** makes `deck-catalog.json` the exact canonical 12-deck launch slate, and performs every rename/absorb/delete from the Files table.

The schema is `DeckSummary` (`Vayl/Features/Play/Models/DeckSummary.swift`, decoded snake_case via `ContentLoader`): `id, title, subtitle, category, intensity, card_count, is_locked, required_entitlement`. `card_count` is the **playable** count for a couple (what `deck.cards(for:).count` returns after the H1 filter fix), not the raw entry count.

Replace `Vayl/Resources/Decks/deck-catalog.json` with exactly:

```json
[
  { "id": "the-opener",              "title": "The Opener",                       "subtitle": "Where are we, actually.",              "category": "foundationEntry", "intensity": 2, "card_count": 10, "is_locked": false, "required_entitlement": null   },
  { "id": "the-check-in",            "title": "The Check-In",                     "subtitle": "A short, warm pulse.",                 "category": "foundationEntry", "intensity": 1, "card_count": 6,  "is_locked": false, "required_entitlement": null   },
  { "id": "communication-intimacy",  "title": "Communication & Intimacy",        "subtitle": "The unsaid things.",                   "category": "relationshipCore", "intensity": 3, "card_count": 11, "is_locked": true,  "required_entitlement": "core" },
  { "id": "sex-and-pleasure",        "title": "Sex & Pleasure",                   "subtitle": "Said out loud, on purpose.",           "category": "relationshipCore", "intensity": 6, "card_count": 11, "is_locked": true,  "required_entitlement": "core" },
  { "id": "jealousy",                "title": "Jealousy & What It's Telling You", "subtitle": "Information, if you'll read it.",      "category": "nmSpecific",       "intensity": 5, "card_count": 11, "is_locked": true,  "required_entitlement": "core" },
  { "id": "flavors-discovery",       "title": "Flavors: Discovery Edition",       "subtitle": "A fitting room, no purchase required.", "category": "nmSpecific",      "intensity": 3, "card_count": 10, "is_locked": true,  "required_entitlement": "core" },
  { "id": "swinging",                "title": "The Swinging Deck",                "subtitle": "Practical, specific, same team.",      "category": "styleSpecific",    "intensity": 5, "card_count": 11, "is_locked": true,  "required_entitlement": "core" },
  { "id": "before-tonight",          "title": "Before Tonight",                   "subtitle": "Set the frame, then play.",            "category": "experienceArc",    "intensity": 4, "card_count": 10, "is_locked": true,  "required_entitlement": "core" },
  { "id": "after-last-night",        "title": "After Last Night",                 "subtitle": "The morning-after conversation.",      "category": "experienceArc",    "intensity": 4, "card_count": 11, "is_locked": true,  "required_entitlement": "core" },
  { "id": "the-first-time",          "title": "The First Time",                   "subtitle": "The one before the first one.",        "category": "experienceArc",    "intensity": 4, "card_count": 10, "is_locked": true,  "required_entitlement": "core" },
  { "id": "when-it-gets-hard",       "title": "When It Gets Hard",                "subtitle": "The way back to each other.",          "category": "experienceArc",    "intensity": 7, "card_count": 11, "is_locked": true,  "required_entitlement": "core" },
  { "id": "appreciation",            "title": "The Appreciation Deck",            "subtitle": "The one that isn't hard.",             "category": "wildcard",         "intensity": 1, "card_count": 10, "is_locked": true,  "required_entitlement": "core" }
]
```

Free tier = `the-opener` + `the-check-in` only (spec D8). Everything else `"core"` and `is_locked: true` in the catalog; live unlock is PlayStore's job (spec 10.2, another segment of this plan).

**Also in H1 — the gendered-variant filter fix (`Vayl/Core/Models/Deck.swift:53-61`).** The current filter returns `genderedFor == dynamic || dynamic == .flexible`, which shows a flexible-composition couple BOTH the mf pair AND the flexible pair once flexible variants exist (double cards, same slots). Since the content contract in this re-cut is "every gendered slot ships exactly two variants, mf + flexible, sharing a sortOrder" and mm/ff copy is explicitly deferred (spec section 1), replace the body of `cards(for:)`:

```swift
    /// Cards for a specific gender dynamic.
    /// Content contract (2026-07-01 catalog re-cut): every gendered slot ships
    /// exactly two variants, mf + flexible, sharing a sortOrder. mm/ff copy is
    /// deferred; those compositions read the flexible variant.
    func cards(for dynamic: GenderDynamic) -> [Card] {
        cards.filter { card in
            guard card.isGenderedCard, let genderedFor = card.genderedFor else {
                return true
            }
            switch dynamic {
            case .mf:                     return genderedFor == .mf
            case .mm, .ff, .flexible:     return genderedFor == .flexible
            }
        }
        .sorted { $0.sortOrder < $1.sortOrder }
    }
```

**Done:** catalog decodes to exactly these 12 `DeckSummary` rows (the `#Preview("Catalog decodes")` in `DeckSummary.swift` shows 12), all 14 deleted files are gone with zero dangling Swift references, and `Deck.previewWithCards.cards(for: .flexible)` contains no `.mf` cards.

---

## H2 — The Opener touch-up (canonical 10 preserved)

**One thing it does:** fixes the flagged card-2 copy, removes every em dash from the file, and adds the flexible gendered variants, without touching the canonical 10 cards an mf couple sees.

The handoff doc flags opener card 2: _"'that's not a red flag' construction flagged for revision, avoid 'that's not X' constructions per style guide."_ The shipped JSON's back copy currently reads `"…that's a starting point, not a red flag…"`, which just inverts the same banned construction, and both the interstitial and the back copy carry em dashes. Exact replacements in `the-opener.json`, card `opener-02`:

```json
"context_beat_copy": "Something worth knowing before you go further:\n\nA boundary is a limit you set for yourself, not a rule you can set for someone else.\n\n\"I won't sleep with anyone without a condom\" is a boundary. It's yours. Your partner is still free to make their own choice. Now you both know where you actually stand.",
"back_copy": "If either of you answered no to the second question, you just found your starting point.\n\nWhat specific boundary has felt ignored? Name it out loud before the next card."
```

(The interstitial keeps its teaching but swaps the em dashes for a period; the back copy drops the red-flag framing entirely instead of negating it.) Sync the same two strings into `Card.openerSamples` card 2 in `Vayl/Core/Models/Card.swift` (preview-only data, lines ~116-117).

**Add the flexible gendered pair.** Cards 6 and 7 are `gendered_for: "mf"`. Append these two card objects to the `cards` array (they share sortOrder 6 and 7 with their mf siblings; after the H1 filter fix exactly one of each pair renders per composition, so ordering stays stable):

```json
{
  "id": "opener-06f",
  "deck_id": "the-opener",
  "text": "In most NM spaces, one of you may find the outside landscape slower than expected.\n\nFewer sparks. More waiting. A quiet question that can creep in...\n\nAm I enough?\n\nIf that turns out to be you, how do you want to be met?\n\nWhat do you want to promise each other before anyone finds out which way it goes?",
  "highlight_words": ["Am I enough?"],
  "type": "prompt",
  "intensity": 5,
  "who_starts": "both",
  "is_sensitive": false,
  "can_skip": true,
  "register": "flexible",
  "context_beat_type": null,
  "context_beat_copy": null,
  "back_copy": null,
  "is_gendered_card": true,
  "gendered_for": "flexible",
  "sort_order": 6
},
{
  "id": "opener-07f",
  "deck_id": "the-opener",
  "text": "And one of you may find more attention than you anticipated.\n\nThat can feel electric, but it can also complicate things. Enjoying the newness will take balance.\n\nIf that turns out to be you, how do you intend to find that balance?\n\nWhat feels exciting? What feels scary?",
  "highlight_words": ["electric", "balance"],
  "type": "prompt",
  "intensity": 5,
  "who_starts": "both",
  "is_sensitive": false,
  "can_skip": true,
  "register": "flexible",
  "context_beat_type": null,
  "context_beat_copy": null,
  "back_copy": null,
  "is_gendered_card": true,
  "gendered_for": "flexible",
  "sort_order": 7
}
```

Bump `"schema_version": 2`. Everything else in the file is untouched.

**The Opener's closing ritual exemption (state it, it drives the lint):** the Opener's closer is its canonical card 10, a `whisper` with the full special-card ceremony (handoff doc: "The Whisper Card closing ritual has a full ceremony"). Retyping it `closingRitual` would strip the reveal mechanic; adding an 11th card would break the canonical 10. So the Opener is the ONE deck whose closing ritual is implemented as a whisper, and the lint asserts exactly that instead of a `closingRitual`-typed card. The Opener is also exempt from the 3-4 living-card count (its canonical shape is 9 discussion + 1 whisper and it is feel-approved as shipped). Both exemptions are named constants in the lint, not silent skips.

**Done:** `the-opener.json` decodes; `cards(for: .mf)` returns the canonical 10; `cards(for: .flexible)` returns 10 with `opener-06f`/`opener-07f` in slots 6-7; zero em dashes anywhere in the file; `schemaVersion == 2`.

---

## H3 — The Check-In (complete final copy)

**One thing it does:** rewrites `the-check-in.json` as the 5-6 card repeatable ritual deck (the bible: "Not a journey deck, a ritual deck. The only deck designed to be used more than once.").

Design: 6 cards, intensity never above 2, whoStarts alternates, closing ritual concept = **"The Carry"** (each names one small thing to carry into the week). Living cards: snapshot + appreciationInterrupt + closingRitual (the check-in is exempt from the 3-4 floor by design, but it happens to hit 3). Full file:

```json
{
  "id": "the-check-in",
  "title": "The Check-In",
  "subtitle": "A short, warm pulse.",
  "category": "foundationEntry",
  "act": 1,
  "intensity": 1,
  "is_locked": false,
  "required_entitlement": null,
  "tags": ["foundation", "free", "ritual", "repeatable"],
  "sort_order": 2,
  "schema_version": 2,
  "cards": [
    {
      "id": "the-check-in-01",
      "deck_id": "the-check-in",
      "text": "Where are we, really, this week?",
      "highlight_words": ["really"],
      "type": "prompt",
      "intensity": 1,
      "who_starts": "partnerA",
      "is_sensitive": false,
      "can_skip": false,
      "register": "flexible",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 1
    },
    {
      "id": "the-check-in-02",
      "deck_id": "the-check-in",
      "text": "One word for how this week felt between us.",
      "highlight_words": ["One word"],
      "type": "snapshot",
      "intensity": 1,
      "who_starts": "both",
      "is_sensitive": false,
      "can_skip": false,
      "register": "flexible",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 2
    },
    {
      "id": "the-check-in-03",
      "deck_id": "the-check-in",
      "text": "When did you feel closest to me this week?\n\nWas there a moment you felt a little far away?",
      "highlight_words": ["closest"],
      "type": "prompt",
      "intensity": 2,
      "who_starts": "partnerB",
      "is_sensitive": false,
      "can_skip": true,
      "register": "anxious",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": "If a specific moment came up, resist solving it right now. Let it be heard first. You can come back to it after the deck.",
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 3
    },
    {
      "id": "the-check-in-04",
      "deck_id": "the-check-in",
      "text": "How full is your tank right now?\n\nWhat's been filling it? What's been draining it?",
      "highlight_words": ["your tank"],
      "type": "prompt",
      "intensity": 2,
      "who_starts": "partnerA",
      "is_sensitive": false,
      "can_skip": false,
      "register": "flexible",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 4
    },
    {
      "id": "the-check-in-05",
      "deck_id": "the-check-in",
      "text": "Look up from the phone.\n\nName one thing they did this week that you noticed and didn't mention.\n\nSay it now.",
      "highlight_words": ["Say it now."],
      "type": "appreciationInterrupt",
      "intensity": 1,
      "who_starts": "both",
      "is_sensitive": false,
      "can_skip": false,
      "register": "flexible",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 5
    },
    {
      "id": "the-check-in-06",
      "deck_id": "the-check-in",
      "text": "One small thing to carry into next week.\n\nEach of you names yours.\n\nMake it small enough to actually happen.",
      "highlight_words": ["carry into next week"],
      "type": "closingRitual",
      "intensity": 1,
      "who_starts": "both",
      "is_sensitive": false,
      "can_skip": false,
      "register": "flexible",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 6
    }
  ]
}
```

**Done:** decodes as a 6-card `Deck`, one `closingRitual`, max intensity 2, repeats well (no card assumes it's the first time you've played it).

---

## H4 — Per-deck blueprints (all 12) + authoring mandate

**One thing it does:** fixes the card-by-card structure of every launch deck so the eight build-time decks are an authoring task, not a design task.

### The authoring mandate (applies to every card Fable writes at build time)

- **Schema:** copy the field set from `the-opener.json` verbatim, snake_case, change only values (`ContentLoader` uses `.convertFromSnakeCase`, `ContentLoader.swift:61,89`; one wrong key or enum rawValue fails the whole deck at runtime). Enum rawValues come from `AppCardEnums.swift`: `type` = CardType cases, `intensity` = Int 1-8, `who_starts` ∈ `partnerA|partnerB|both` (**never `solo`**, the solo deck is gone), `register` ∈ `anxious|excited|flexible` (`AppEnums.swift:85`; never `unknown` in content), `gendered_for` ∈ `mf|flexible` only.
- **Quality gates, all four, every card** (handoff doc): **Bar Conversation Test** (a wise well-read friend over a drink, never clinical), **Dual Register Test** (works for the anxious AND the excited partner without defaulting to either), **Non-Assumption Test** (no assumed style, decision, orientation, or emotional state), **Temporal Test** (past/present/future card in the right deck position).
- **Style rules, verbatim from the handoff:** ellipsis for trailing thoughts that land harder than a period; line breaks are intentional (`\n\n` stanzas, each line readable as its own unit); two questions = two distinct lines, never joined with "and"; short sentences; NEVER "that's not X, it's Y" constructions or "it's not a warning, it's just true" lines; never clinical language (attachment, trauma, codependency, processing); never center the other partner inside a gendered card; never force one structural formula across cards. **NO EM DASHES anywhere in any copy field** (repo-wide rule; the lint enforces it, and also bans en dashes).
- **Structure per deck:** 10-11 playable cards (check-in 5-6 by design), 6-7 discussion + 3-4 living cards chosen via the dispatch matrix from the ALLOWED set only: `whisper, unspoken, mirror, snapshot, whatIf, dare, greenLight, coolOff, bodyCheck, permissionCard, appreciationInterrupt, openingRitual, closingRitual, pause`. **Deferred, never use:** `timeCapsule, echo, callback, beforeAfter, sharedCanvas, spectrum, wordCloud` (enum-only until Memory/Time + Shared Creation ship).
- **Unique closing ritual per deck, never reused, always the most carefully designed card.** Concept named per deck below. Keep every closing ritual `intensity <= 4` and `can_skip: false` so the airlock's bandwidth trim (which never trims the closer anyway) and skip logic never fight it.
- **Context beats** wherever copy would crowd the face: `banner` = 1-2 line normalizer, `interstitial` = full-screen reframe. Cards arrive clean.
- **`back_copy`** only where a branch on the couple's answer earns it (responsive, never setup).
- **Gendered pairs** in the four applicable decks (the-opener, sex-and-pleasure, jealousy, swinging): one His + one Her card written to the mf experience, PLUS a flexible variant of each written to the *experience* (not the gender), sharing the mf card's sortOrder. His card: written to what he carries, her role is support inside his card; Her card: written to what she carries, never centers him. mm/ff variants are explicitly deferred (spec section 1).
- **Intensity honesty + ordering:** deck-level `intensity` matches the deck's real job (appreciation 1, when-it-gets-hard 7). Card intensity rises then cools; safety before depth in every deck; when-it-gets-hard follows the Resentment-deck excavation discipline (the bible: "requires the most careful card ordering of any deck, safety first, depth earned").
- **`schema_version`:** 2 for the three touched existing ids (`the-opener`, `the-check-in`, `before-tonight`), 1 for the nine net-new ids. The lint pins the exact map.
- **Absorbed seeds:** each renamed stub has one on-voice seed card. Keep it in its marked slot below if it fits after a re-read; if it fights the slot's job, rewrite it in place (the id in the new deck is new either way).

Table key: **Int** = card intensity (1-8). **Temporal** = past / present / future / n.a. **Beat** = context beat type. **Back** = has back_copy. Living cards are **bold**.

### 4.1 the-opener — canonical, see H2

10 canonical + 2 flexible variants. 9 discussion (incl. gendered pair x2 variants) + 1 living (**whisper** closer, ceremonial exemption). No changes beyond H2.

### 4.2 the-check-in — final copy in H3

6 cards: prompt, **snapshot**, prompt, prompt, **appreciationInterrupt**, **closingRitual** ("The Carry").

### 4.3 communication-intimacy (11 · deck intensity 3 · sort_order 3 · schema_version 1)

The unsaid things. Not NM-specific: the relationship underneath the NM conversation. Temporal spine: how you learned to talk → where the gaps are now → what to build. Dispatch: reveal = **mirror** (assumption surfacing is this deck's whole product), regulation = **permissionCard** (anxious register), temperature = **snapshot**.

| # | id | Type | Int | Temporal | Starts | Beat | Back | Job |
|---|---|---|---|---|---|---|---|---|
| 1 | ci-01 | prompt | 2 | past | partnerA | – | – | How hard things were handled where each of you grew up; what you swore you'd do differently |
| 2 | ci-02 | prompt | 3 | present | partnerB | interstitial | – | **Absorbs the boundaries seed:** "What's one line you'd want drawn before anything new?" Interstitial re-teaches boundary-as-yours in fresh words (do NOT reuse the opener's interstitial copy; same idea, new phrasing, no banned constructions) |
| 3 | ci-03 | prompt | 3 | present | partnerA | – | – | The subject you both quietly route around |
| 4 | ci-04 | **mirror** | 4 | present | both | – | – | "When you're hurt, what do you actually do?" A answers for self, B answers what they think A said; the gap is the conversation |
| 5 | ci-05 | prompt | 4 | present | partnerB | – | – | When upset: fixed, held, or left alone? How is your partner supposed to know which one tonight is? |
| 6 | ci-06 | **permissionCard** | 3 | n.a. | both | – | – | "You're allowed to say it badly. First drafts count here." |
| 7 | ci-07 | prompt | 5 | present | partnerA | – | can_skip | The unmet need that has been showing up dressed as smaller complaints |
| 8 | ci-08 | prompt | 5 | future | partnerB | – | yes | **Absorbs the communication seed** ("When something's wrong, how do you want me to ask?"); back copy: agree tonight on the actual phrase either of you can say that means "we need to talk" without dread |
| 9 | ci-09 | **snapshot** | 3 | present | both | – | – | One word for how heard you feel lately (can_skip true) |
| 10 | ci-10 | prompt | 4 | future | partnerA | – | – | What would need to change for the hard conversations to feel safe by default |
| 11 | ci-11 | **closingRitual** | 3 | n.a. | both | – | – | **"The Unsaid, Said":** each says one sentence they've been carrying unsaid. The other may only respond "thank you for telling me." Then done |

### 4.4 sex-and-pleasure (11 playable + 2 flex variants · deck intensity 6 · sort_order 4 · schema_version 1)

Foundational sexual truth between these two people, not NM sex. Dual register everywhere: honesty about what hasn't worked (anxious) beside appetite and curiosity (excited). Dispatch: playful = **greenLight** (the signature: desire spoken without pre-negotiation) + **dare** (bring it back into the room), reveal = **unspoken** (appetite calibration, a number says more than words).

| # | id | Type | Int | Temporal | Starts | Beat | Back | Job |
|---|---|---|---|---|---|---|---|---|
| 1 | sp-01 | prompt | 3 | past | partnerA | banner | – | What you learned about wanting things, growing up; what you've had to unlearn. Banner: "Nobody arrives at honesty about sex fully formed. Start where you are." |
| 2 | sp-02 | prompt | 4 | present | partnerB | – | – | What reliably works for you that you've never said in plain words (is_sensitive) |
| 3 | sp-03 | **greenLight** | 5 | present | partnerA | – | – | Name one want you haven't said out loud. The only allowed reply: "tell me more." (is_sensitive) |
| 4 | sp-04 | prompt | 5 | past/present | partnerB | – | yes | What has never quite worked, and what you've performed instead of saying so (is_sensitive, can_skip). Back: if performance came up, no repair project tonight; just thank them for the honesty |
| 5 | sp-05 / sp-05f | prompt (gendered) | 5 | present | both | – | – | **His card (mf):** initiation pressure and desire disparity from his side; to her: what do you want him to know you see. **Flexible variant:** the partner who initiates more |
| 6 | sp-06 / sp-06f | prompt (gendered) | 5 | present | both | – | – | **Her card (mf):** carrying the safety calculus and managing the temperature of desire; to him: how he shows up so she can want freely. Never centers him. **Flexible variant:** the partner who does more of the emotional reading in bed |
| 7 | sp-07 | **unspoken** | 6 | present | both | – | – | Slider: tonight's appetite for adventure vs your everyday average. The gap or overlap is the conversation (is_sensitive) |
| 8 | sp-08 | prompt | 6 | present | partnerB | – | – | A curiosity you've been sitting on (register: excited, is_sensitive, can_skip) |
| 9 | sp-09 | prompt | 6 | present | partnerA | – | – | What makes you feel most wanted; what accidentally switches it off |
| 10 | sp-10 | **dare** | 4 | n.a. | both | – | – | Twenty seconds. One kiss like you mean it. Then keep going |
| 11 | sp-11 | **closingRitual** | 4 | future | both | – | – | **"The Keep":** each names one thing about your sex life together that stays sacred, whatever else you two ever explore |

### 4.5 jealousy (11 playable + 2 flex variants · deck intensity 5 · sort_order 5 · schema_version 1)

Jealousy as information, not failure. Full temporal spine (the bible names this deck first for it): past patterns → present state → future tools. Serves anxious (jealousy as unmet need) and excited (jealousy as boundary signal worth exploring). Dispatch: regulation = **bodyCheck** (the signature for this deck per the library), temperature = **snapshot**, playful = **whatIf** (breaking tension with imagination).

| # | id | Type | Int | Temporal | Starts | Beat | Back | Job |
|---|---|---|---|---|---|---|---|---|
| 1 | j-01 | prompt | 3 | past | partnerA | banner | – | Your earliest memory of jealousy, long before this relationship. Banner: "Jealousy has a memory. It's older than the two of you." |
| 2 | j-02 | prompt | 4 | past | partnerB | – | – | How jealousy was modeled around you: punished, romanticized, hidden? |
| 3 | j-03 | **bodyCheck** | 4 | present | both | – | – | Where jealousy lives in your body when it arrives. Don't explain it. Locate it |
| 4 | j-04 | prompt | 5 | present | partnerA | interstitial | – | The last time it flared: what set it off, and what was it pointing at underneath? Interstitial: the jealousy-as-information reframe, written fresh (a signal with a job, not a verdict on you or them; no banned constructions) |
| 5 | j-05 / j-05f | prompt (gendered) | 5 | present | both | – | – | **His card (mf):** the replaceability question; comparison arriving dressed as curiosity. **Flexible variant:** the partner who fears being outgrown |
| 6 | j-06 / j-06f | prompt (gendered) | 5 | present | both | – | – | **Her card (mf):** having her own feelings while managing his; the shrink-your-joy-to-keep-the-peace trap. Never centers him. **Flexible variant:** the partner who dims their own excitement to protect the other |
| 7 | j-07 | **snapshot** | 4 | present | both | – | – | One word for your relationship with jealousy right now |
| 8 | j-08 | prompt | 6 | present | partnerB | – | yes | What reassurance actually works on you (words, touch, time, proof), and which well-meant reassurance does nothing. Back: say the useless kind out loud too, so nobody keeps spending effort there |
| 9 | j-09 | **whatIf** | 5 | future | both | – | – | What if I came home lit up after a great date... what's the first thing you'd want me to do walking in the door? (whisper mechanic underneath; slightly uncomfortable in the laughing way) |
| 10 | j-10 | prompt | 5 | past/future | partnerA | – | – | **Absorbs the jealousy-compersion seed:** when have you felt something like pride watching me light up for someone else? What made that moment safe enough for pride, and what would it take to get more of them? |
| 11 | j-11 | **closingRitual** | 3 | future | both | – | – | **"The Working Signal":** each tells the other the exact sentence to say when jealousy shows up mid-experience. Both repeat the other's sentence back, once, out loud |

### 4.6 flavors-discovery (10 · deck intensity 3 · sort_order 6 · schema_version 1)

For couples genuinely undecided. Imagination work, not commitment; explicitly the exploration phase. Product-principle guard: this deck names what THEY say, it never concludes a style for them (discovery, never assessment). Dispatch: playful = **whatIf**, reveal = **unspoken** + **snapshot**.

| # | id | Type | Int | Temporal | Starts | Beat | Back | Job |
|---|---|---|---|---|---|---|---|---|
| 1 | f-01 | prompt | 2 | present | partnerA | banner | – | When you imagine "more open," what single image comes to mind first? Banner: "Nothing tonight is a commitment. This deck is a fitting room." |
| 2 | f-02 | prompt | 3 | present | partnerB | – | – | What draws you toward this at all? The honest pull underneath the curiosity |
| 3 | f-03 | **whatIf** | 3 | future | both | – | – | What if you were both at a party where flirting was allowed and expected... what do you picture yourself doing? |
| 4 | f-04 | prompt | 3 | present | partnerA | – | – | Which flavor sounds nothing like you two, and what exactly feels off about it? (naming by contrast; absorb the-styles seed here if it fits) |
| 5 | f-05 | **unspoken** | 4 | present | both | – | – | Slider: how much does "romantic connection with others" belong in your picture, versus "experiences only"? |
| 6 | f-06 | prompt | 4 | future | partnerB | – | – | What would stay just-ours in every version you can imagine? |
| 7 | f-07 | prompt | 4 | present | partnerA | – | – | Which of your worries is about a specific style, and which is about any change at all? |
| 8 | f-08 | **snapshot** | 3 | present | both | – | – | One word for where you are in this exploration today |
| 9 | f-09 | prompt | 3 | future | partnerB | – | – | What would you want to read, watch, or learn together before choosing anything? |
| 10 | f-10 | **closingRitual** | 2 | n.a. | both | – | – | **"Leave It Open":** each names one thing you're deliberately leaving undecided. Then say it together, once: "we don't have to know yet." |

### 4.7 swinging (11 playable + 2 flex variants · deck intensity 5 · sort_order 7 · schema_version 1)

Practical, specific, honest about the realities; the "Night Out" material. Non-assumption discipline: never assumes club vs party vs apps, soft vs full, together vs separate. Dispatch: reveal = **unspoken** (readiness), playful = **whatIf**, temperature = **coolOff** (team memory before the closer).

| # | id | Type | Int | Temporal | Starts | Beat | Back | Job |
|---|---|---|---|---|---|---|---|---|
| 1 | sw-01 | prompt | 3 | present | partnerA | – | – | What does swinging mean to YOU two: together-only, separate rooms, soft, full? Define it before anything else |
| 2 | sw-02 | prompt | 4 | future | partnerB | – | – | The setting question: club, house party, friends, apps. Which sounds fun? Which sounds terrifying? |
| 3 | sw-03 | **unspoken** | 5 | present | both | – | – | Slider: how ready do you feel for the nearest real step, today, honestly |
| 4 | sw-04 | prompt | 5 | future | partnerA | – | – | What needs to be agreed in advance, and what are you comfortable deciding in the room? |
| 5 | sw-05 / sw-05f | prompt (gendered) | 5 | present | both | – | – | **His card (mf):** the measuring-up worry in a room where everything is visible. **Flexible variant:** the partner who worries about performing |
| 6 | sw-06 / sw-06f | prompt (gendered) | 5 | present | both | – | – | **Her card (mf):** fielding the most attention while reading safety in the room; to him: how he makes the room feel safer without hovering. **Flexible variant:** the partner who gets read first and approached most |
| 7 | sw-07 | **whatIf** | 5 | future | both | – | – | What if someone approaches you two mid-party and only one of you is interested... |
| 8 | sw-08 | prompt | 6 | future | partnerB | – | yes | Sexual health, said plainly: protection, testing cadence, the non-negotiables (is_sensitive). Back: if you disagreed on any non-negotiable, that item is settled OUTSIDE a party, never at one |
| 9 | sw-09 | prompt | 5 | future | partnerA | – | – | The exit plan: what happens when one of you wants to leave and the other is having the night of their life? |
| 10 | sw-10 | **coolOff** | 3 | past | both | – | – | Your favorite memory of the two of you being a team in a room full of strangers |
| 11 | sw-11 | **closingRitual** | 4 | future | both | – | – | **"The Room Signal":** pick the word or gesture that means "find me" in any room. Practice it once now, seriously. Then once more, laughing |

### 4.8 before-tonight (10 · deck intensity 4 · sort_order 8 · schema_version 2)

Preparation for a specific planned experience; the only deck living entirely in present and future tense (every card passes the Temporal Test as present/future, no past cards). Dispatch: reveal = **snapshot** + **unspoken**, regulation = **permissionCard** (the call-it-off card).

| # | id | Type | Int | Temporal | Starts | Beat | Back | Job |
|---|---|---|---|---|---|---|---|---|
| 1 | bt-01 | prompt | 3 | future | partnerA | – | – | What are you hoping tonight feels like? One honest sentence each (absorb the before-tonight seed here if it fits) |
| 2 | bt-02 | **snapshot** | 3 | present | both | – | – | One word for what's in your chest right now |
| 3 | bt-03 | prompt | 4 | future | partnerB | – | – | Signals for tonight: what do green, yellow, and red each look like on you? |
| 4 | bt-04 | prompt | 4 | future | partnerA | – | – | The what-ifs worth saying now: one of you wants to leave; one of you connects and the other doesn't; the plan changes |
| 5 | bt-05 | **unspoken** | 4 | future | both | – | – | Slider: how far does tonight go, at most? Calibrate before the door, never at it |
| 6 | bt-06 | prompt | 5 | future | partnerB | – | – | What would make you check on me tonight? What should I do when you do? |
| 7 | bt-07 | prompt | 4 | future | partnerA | – | – | Aftercare, decided in advance: what does coming home look like? Debrief tonight or sleep first? Touch or space? |
| 8 | bt-08 | **permissionCard** | 3 | n.a. | both | – | – | Either of you can call tonight off, at any point, for any reason. It costs nothing. It proves the whole thing works |
| 9 | bt-09 | prompt | 3 | future | partnerB | – | – | What are you most looking forward to watching the other one enjoy? (register: excited) |
| 10 | bt-10 | **closingRitual** | 3 | future | both | – | – | **"The Thread":** each finishes, out loud: "whatever happens tonight, the thing I'm coming home to is..." Then go |

### 4.9 after-last-night — complete final copy in H5

11 cards: **snapshot** opener, 7 discussion, **bodyCheck**, **whisper**, **closingRitual** ("Again / Differently").

### 4.10 the-first-time (10 · deck intensity 4 · sort_order 10 · schema_version 1)

Emotional, not logistical; assumes this is THE first, not just the next. Milestone deck, so it earns the **openingRitual**. Dispatch: reveal = **whisper**, regulation = **permissionCard**, ceremony = **openingRitual** + **closingRitual**.

| # | id | Type | Int | Temporal | Starts | Beat | Back | Job |
|---|---|---|---|---|---|---|---|---|
| 1 | ft-01 | **openingRitual** | 2 | present | both | – | – | Before card one: each says out loud what you need from tonight's conversation. Then begin |
| 2 | ft-02 | prompt | 3 | past | partnerA | – | – | How long has this been an idea, and what finally made it real? |
| 3 | ft-03 | prompt | 4 | present | partnerB | – | – | What are you afraid this changes? Say the real fear, even if it sounds dramatic out loud (register: anxious, can_skip) |
| 4 | ft-04 | prompt | 4 | future | partnerA | – | – | What do you hope you find out about yourself? (register: excited) |
| 5 | ft-05 | **whisper** | 5 | present | both | – | – | The thing about the first time you haven't said out loud yet (is_sensitive) |
| 6 | ft-06 | prompt | 5 | present | partnerB | – | – | What from your story together do you want to hold onto tightest as you walk in? |
| 7 | ft-07 | **permissionCard** | 3 | n.a. | both | – | – | You're allowed to get all the way to the doorstep and turn around. Firsts don't expire |
| 8 | ft-08 | prompt | 4 | future | partnerA | – | – | How will you want to be found afterward: talking, touching, quiet, fed? |
| 9 | ft-09 | prompt | 3 | future | partnerB | – | – | What will you tell each other if it's wonderful? What if it's just fine? Both answers count |
| 10 | ft-10 | **closingRitual** | 3 | future | both | – | – | **"The Day After Promise":** each makes one small promise for the morning after, out loud. The deck ends when both are said |

### 4.11 when-it-gets-hard (11 · deck intensity 7 · sort_order 11 · schema_version 1)

Repair, not conflict resolution. Something happened; how do we come back to each other. This deck carries the excavation-ordering discipline: safety first, depth earned, warmth before the close. Dispatch: ceremony = **openingRitual** + **pause** (the silence IS a card here) + **closingRitual**, regulation = **bodyCheck**. The permission content rides the interstitial beat, not a card, to keep living cards at 4.

| # | id | Type | Int | Temporal | Starts | Beat | Back | Job |
|---|---|---|---|---|---|---|---|---|
| 1 | wh-01 | **openingRitual** | 3 | present | both | – | – | Each says what you need from tonight, and one thing that is still true about you two. Then begin |
| 2 | wh-02 | prompt | 4 | past | partnerA | interstitial | – | What happened, in each of your words, one at a time, no corrections while the other speaks. Interstitial: you don't have to fix all of it tonight; you only have to be honest in the same room |
| 3 | wh-03 | **bodyCheck** | 4 | present | both | – | – | Where is the hurt sitting right now? Locate it, don't argue it |
| 4 | wh-04 | prompt | 5 | past | partnerB | banner | – | Which part actually hurt most? Banner: "The headline and the wound are rarely the same size." |
| 5 | wh-05 | prompt | 6 | past | partnerA | – | – | What did you need in that moment that didn't come? (can_skip) |
| 6 | wh-06 | **pause** | 3 | n.a. | both | – | – | No prompt. A breath. Sometimes the silence is the card |
| 7 | wh-07 | prompt | 6 | present | partnerB | – | yes | Is there a piece of this that's yours to own? Say it without the word "but". Back: whoever went first just made it safer for the other one. Go again if there's more |
| 8 | wh-08 | prompt | 5 | present | partnerA | – | – | What do you need to hear right now? You're allowed to ask for it word for word |
| 9 | wh-09 | prompt | 5 | future | partnerB | – | – | What does repaired look like? Something each of you could do this week, small and real |
| 10 | wh-10 | prompt | 3 | present | both | – | – | What do you love about us that this didn't touch? |
| 11 | wh-11 | **closingRitual** | 4 | future | both | – | – | **"Started, Not Finished":** name it honestly: repair started tonight. Each says the next single step and when. Then stop. No relitigating after this card |

### 4.12 appreciation — complete final copy in H6

10 cards: 6 discussion, **snapshot**, **mirror**, **dare**, **closingRitual** ("Out Loud, For Keeps").

### Build-time authoring note (the eight remaining decks)

**Fable authors `communication-intimacy`, `sex-and-pleasure`, `jealousy`, `flavors-discovery`, `swinging`, `before-tonight`, `the-first-time`, and `when-it-gets-hard` at build time, in this pass, from the blueprints above, under the full mandate and all four quality gates.** The two exemplars below are the quality bar: match their warmth, specificity, line-break rhythm, and field discipline exactly. Per-deck tone guidance:

- **communication-intimacy:** the quiet deck. It never raises its voice; it names the things two people who love each other route around. Warm, a little sad in places, never accusatory; every card assumes goodwill on both sides.
- **sex-and-pleasure:** frank and unembarrassed without ever being crude. It treats desire as good news and awkwardness as normal; the excited partner should feel invited, the anxious partner should feel zero performance pressure.
- **jealousy:** steady and de-shaming. It talks about jealousy the way you'd talk about weather: real, survivable, informative. Curious about the feeling, never afraid of it, never lecturing about it.
- **flavors-discovery:** light on its feet. A fitting room, not a courtroom; every card is imagination work and says so. It must end with LESS pressure to decide than it started with (discovery, never assessment).
- **swinging:** practical and grinning. The register of two people planning a heist they're excited about: logistics, signals, contingencies, delivered with warmth and zero moralizing about the lifestyle.
- **before-tonight:** focused, present-tense, slightly electric. Pre-game energy: short cards, concrete questions, everything aimed at walking out the door calm and on the same team.
- **the-first-time:** tender and unhurried. It honors the size of the moment without inflating the fear; excitement and nerves sit on the same card as equals, and nothing in it is logistics.
- **when-it-gets-hard:** the gentlest hands in the catalog. Slow, plain, zero cleverness; every card lowers the temperature before asking anything, and nothing in it assigns fault. Safety before depth is the whole ordering.

**Done (H4):** the eight build-time deck files exist with exactly the blueprinted card ids, types, sortOrders, intensities, whoStarts, beats, backs, and gendered pairs; every card passes the four gates on read; the lint (H7) passes.

---

## H5 — Exemplar 1: `after-last-night.json` (complete, final)

**One thing it does:** ships the most-needed deck in the slate ("the one nobody else builds") as finished copy and the quality bar for the build-time eight.

```json
{
  "id": "after-last-night",
  "title": "After Last Night",
  "subtitle": "The morning-after conversation.",
  "category": "experienceArc",
  "act": 1,
  "intensity": 4,
  "is_locked": true,
  "required_entitlement": "core",
  "tags": ["experience", "core", "processing"],
  "sort_order": 9,
  "schema_version": 1,
  "cards": [
    {
      "id": "aln-01",
      "deck_id": "after-last-night",
      "text": "One word for last night.\n\nNot the word you think you should say.\n\nThe one that's actually there.",
      "highlight_words": ["One word"],
      "type": "snapshot",
      "intensity": 2,
      "who_starts": "both",
      "is_sensitive": false,
      "can_skip": false,
      "register": "flexible",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 1
    },
    {
      "id": "aln-02",
      "deck_id": "after-last-night",
      "text": "What surprised you?\n\nAbout them. About yourself.\n\nAbout how it actually felt.",
      "highlight_words": ["surprised"],
      "type": "prompt",
      "intensity": 3,
      "who_starts": "partnerA",
      "is_sensitive": false,
      "can_skip": false,
      "register": "flexible",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 2
    },
    {
      "id": "aln-03",
      "deck_id": "after-last-night",
      "text": "What was better than you expected?",
      "highlight_words": ["better"],
      "type": "prompt",
      "intensity": 3,
      "who_starts": "partnerB",
      "is_sensitive": false,
      "can_skip": false,
      "register": "excited",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 3
    },
    {
      "id": "aln-04",
      "deck_id": "after-last-night",
      "text": "Where is last night sitting in your body right now?\n\nDon't explain it.\n\nJust point to it.",
      "highlight_words": ["your body"],
      "type": "bodyCheck",
      "intensity": 3,
      "who_starts": "both",
      "is_sensitive": false,
      "can_skip": true,
      "register": "flexible",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 4
    },
    {
      "id": "aln-05",
      "deck_id": "after-last-night",
      "text": "Was there a moment you looked for each other?\n\nWhat were you checking for when you did?",
      "highlight_words": ["looked for each other"],
      "type": "prompt",
      "intensity": 4,
      "who_starts": "partnerA",
      "is_sensitive": false,
      "can_skip": false,
      "register": "flexible",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 5
    },
    {
      "id": "aln-06",
      "deck_id": "after-last-night",
      "text": "Is there a moment you keep replaying?\n\nWhat is it asking you?",
      "highlight_words": ["replaying"],
      "type": "prompt",
      "intensity": 5,
      "who_starts": "partnerB",
      "is_sensitive": false,
      "can_skip": true,
      "register": "anxious",
      "context_beat_type": "banner",
      "context_beat_copy": "Almost everyone replays something the morning after. Give it a minute of daylight.",
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 6
    },
    {
      "id": "aln-07",
      "deck_id": "after-last-night",
      "text": "Did anything land differently than you both agreed it would?\n\nName it plainly.\n\nNo verdicts yet. Just the truth of it.",
      "highlight_words": ["land differently"],
      "type": "prompt",
      "intensity": 6,
      "who_starts": "partnerA",
      "is_sensitive": false,
      "can_skip": true,
      "register": "flexible",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": "If something crossed a line, say which line, out loud.\n\nYou can decide together what it needs after the deck, when you've both been heard.",
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 7
    },
    {
      "id": "aln-08",
      "deck_id": "after-last-night",
      "text": "What's one thing about last night you haven't said out loud yet?",
      "highlight_words": ["haven't said out loud"],
      "type": "whisper",
      "intensity": 6,
      "who_starts": "both",
      "is_sensitive": true,
      "can_skip": false,
      "register": "flexible",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 8
    },
    {
      "id": "aln-09",
      "deck_id": "after-last-night",
      "text": "What did last night teach you about what you two need before the next time?\n\nBe specific.\n\nSmall things count.",
      "highlight_words": ["before the next time"],
      "type": "prompt",
      "intensity": 5,
      "who_starts": "partnerA",
      "is_sensitive": false,
      "can_skip": false,
      "register": "flexible",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 9
    },
    {
      "id": "aln-10",
      "deck_id": "after-last-night",
      "text": "What are you glad you did?\n\nSay it without softening it.",
      "highlight_words": ["glad"],
      "type": "prompt",
      "intensity": 4,
      "who_starts": "partnerB",
      "is_sensitive": false,
      "can_skip": false,
      "register": "excited",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 10
    },
    {
      "id": "aln-11",
      "deck_id": "after-last-night",
      "text": "One thing you'd do again.\n\nOne thing you'd do differently.\n\nSay both. Then tell each other one thing the other did last night, or this morning, that you're grateful for.",
      "highlight_words": ["again", "differently"],
      "type": "closingRitual",
      "intensity": 3,
      "who_starts": "both",
      "is_sensitive": false,
      "can_skip": false,
      "register": "flexible",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 11
    }
  ]
}
```

Structure check: 11 cards = 7 discussion + 4 living (snapshot, bodyCheck, whisper, closingRitual). Intensity arc 2-3-3-3-4-5-6-6-5-4-3: rises to the whisper, cools to the close. Registers: two excited cards, one anxious card, rest flexible. Dispatch: reveal (whisper + snapshot), regulation (bodyCheck), closing "Again / Differently". Zero em dashes, zero banned constructions.

**Done:** file decodes as an 11-card `Deck`; every field above verbatim.

---

## H6 — Exemplar 2: `appreciation.json` (complete, final)

**One thing it does:** ships the warm deck, the only one explicitly not hard, as finished copy.

```json
{
  "id": "appreciation",
  "title": "The Appreciation Deck",
  "subtitle": "The one that isn't hard.",
  "category": "wildcard",
  "act": 1,
  "intensity": 1,
  "is_locked": true,
  "required_entitlement": "core",
  "tags": ["wildcard", "core", "warm"],
  "sort_order": 12,
  "schema_version": 1,
  "cards": [
    {
      "id": "app-01",
      "deck_id": "appreciation",
      "text": "What's your favorite thing you two have survived together?",
      "highlight_words": ["survived together"],
      "type": "prompt",
      "intensity": 1,
      "who_starts": "partnerA",
      "is_sensitive": false,
      "can_skip": false,
      "register": "flexible",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 1
    },
    {
      "id": "app-02",
      "deck_id": "appreciation",
      "text": "What do they do that they don't even notice...\n\nthat you'd miss within a day if it stopped?",
      "highlight_words": ["don't even notice"],
      "type": "prompt",
      "intensity": 1,
      "who_starts": "partnerB",
      "is_sensitive": false,
      "can_skip": false,
      "register": "flexible",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 2
    },
    {
      "id": "app-03",
      "deck_id": "appreciation",
      "text": "One word for who they've been to you lately.",
      "highlight_words": ["One word"],
      "type": "snapshot",
      "intensity": 1,
      "who_starts": "both",
      "is_sensitive": false,
      "can_skip": false,
      "register": "flexible",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 3
    },
    {
      "id": "app-04",
      "deck_id": "appreciation",
      "text": "When did you last feel proud of them?\n\nTell the story. Take your time.",
      "highlight_words": ["proud"],
      "type": "prompt",
      "intensity": 2,
      "who_starts": "partnerA",
      "is_sensitive": false,
      "can_skip": false,
      "register": "flexible",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 4
    },
    {
      "id": "app-05",
      "deck_id": "appreciation",
      "text": "What's one thing about yourself you're quietly proud of right now?\n\nOne of you answers for yourself.\n\nThe other answers what they think you'll say.",
      "highlight_words": ["quietly proud"],
      "type": "mirror",
      "intensity": 2,
      "who_starts": "both",
      "is_sensitive": false,
      "can_skip": false,
      "register": "flexible",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 5
    },
    {
      "id": "app-06",
      "deck_id": "appreciation",
      "text": "What's something they taught you without meaning to?",
      "highlight_words": ["without meaning to"],
      "type": "prompt",
      "intensity": 2,
      "who_starts": "partnerB",
      "is_sensitive": false,
      "can_skip": false,
      "register": "flexible",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 6
    },
    {
      "id": "app-07",
      "deck_id": "appreciation",
      "text": "Right now: hold eye contact for ten slow seconds.\n\nNo talking.\n\nWhoever laughs first owes the other one true compliment, out loud.",
      "highlight_words": ["ten slow seconds"],
      "type": "dare",
      "intensity": 2,
      "who_starts": "both",
      "is_sensitive": false,
      "can_skip": true,
      "register": "excited",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 7
    },
    {
      "id": "app-08",
      "deck_id": "appreciation",
      "text": "What's a hard season they carried you through?\n\nDid you ever fully thank them for it?",
      "highlight_words": ["carried you through"],
      "type": "prompt",
      "intensity": 3,
      "who_starts": "partnerA",
      "is_sensitive": false,
      "can_skip": false,
      "register": "flexible",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": "If the answer was no, this is the moment.\n\nSay the thank you now, the whole thing, like it's overdue. Because it is.",
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 8
    },
    {
      "id": "app-09",
      "deck_id": "appreciation",
      "text": "What about the life you're building together still feels a little like getting away with something?",
      "highlight_words": ["getting away with something"],
      "type": "prompt",
      "intensity": 2,
      "who_starts": "partnerB",
      "is_sensitive": false,
      "can_skip": false,
      "register": "excited",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 9
    },
    {
      "id": "app-10",
      "deck_id": "appreciation",
      "text": "Look at each other.\n\nFinish this sentence out loud, one at a time:\n\n\"I'd choose all of this again because...\"",
      "highlight_words": ["choose all of this again"],
      "type": "closingRitual",
      "intensity": 2,
      "who_starts": "both",
      "is_sensitive": false,
      "can_skip": false,
      "register": "flexible",
      "context_beat_type": null,
      "context_beat_copy": null,
      "back_copy": null,
      "is_gendered_card": false,
      "gendered_for": null,
      "sort_order": 10
    }
  ]
}
```

Structure check: 10 cards = 6 discussion + 4 living (snapshot, mirror, dare, closingRitual "Out Loud, For Keeps"). Max intensity 3: explicitly not hard. The dare is the pressure-valve-in-reverse; the mirror is warm assumption-surfacing (what they think you're proud of). Zero em dashes, zero banned constructions.

**Done:** file decodes as a 10-card `Deck`; every field above verbatim.

---

## H7 — Content lint (`VaylTests/ContentLintTests.swift`)

**One thing it does:** makes the whole re-cut structurally unbreakable: any future copy edit that violates the slate, the counts, the closing rituals, the allowed card types, the gendered contract, the em-dash rule, or the schema versions fails the test target.

Full file (matches the existing VaylTests style: `XCTest`, `@testable import Vayl`, invariant-comment-first):

```swift
//
//  ContentLintTests.swift
//  VaylTests
//
//  Structural lint for the 2026-07-01 launch deck re-cut (spec: card-sessions
//  front-to-back, sections 7 + 11). These encode the content contract that has
//  no UI to catch a regression:
//   • the catalog is exactly the 12 canonical launch decks with the right tiers,
//   • every deck file decodes, and counts/rituals/living-card mix hold,
//   • no card uses a deferred (render-path-less) CardType,
//   • gendered slots ship the mf + flexible pair, symmetrically,
//   • no em dash or en dash anywhere in copy (repo-wide rule),
//   • schemaVersion is pinned per deck so silent edits are visible.
//

import XCTest
@testable import Vayl

final class ContentLintTests: XCTestCase {

    // MARK: - Fixture

    /// The canonical launch slate, in catalog order (spec section 7.1).
    private static let launchDeckIds: [String] = [
        "the-opener", "the-check-in",
        "communication-intimacy", "sex-and-pleasure",
        "jealousy", "flavors-discovery", "swinging",
        "before-tonight", "after-last-night", "the-first-time",
        "when-it-gets-hard", "appreciation"
    ]

    private static let freeDeckIds: Set<String> = ["the-opener", "the-check-in"]

    /// Decks whose gendered slots ship the mf + flexible variant pair.
    private static let genderedDeckIds: Set<String> = [
        "the-opener", "sex-and-pleasure", "jealousy", "swinging"
    ]

    /// CardTypes with no V1 render path (Memory/Time + Shared Creation).
    /// Using one is a content bug: the session would render nothing.
    private static let deferredTypes: Set<CardType> = [
        .timeCapsule, .echo, .callback, .beforeAfter,
        .sharedCanvas, .spectrum, .wordCloud
    ]

    /// The Opener is canonical and feel-approved as shipped: its closing
    /// ritual IS the whisper ceremony (card 10), and its living-card count
    /// predates the dispatch matrix. Named exemption, asserted explicitly
    /// in test_closingRituals / test_livingCardCounts, never skipped silently.
    private static let canonicalCeremonyDeckId = "the-opener"

    /// schemaVersion pin: 2 = existing id touched by the re-cut,
    /// 1 = net-new id introduced by it. Any content edit must bump these.
    private static let expectedSchemaVersions: [String: Int] = [
        "the-opener": 2, "the-check-in": 2, "before-tonight": 2,
        "communication-intimacy": 1, "sex-and-pleasure": 1, "jealousy": 1,
        "flavors-discovery": 1, "swinging": 1, "after-last-night": 1,
        "the-first-time": 1, "when-it-gets-hard": 1, "appreciation": 1
    ]

    private var decks: [Deck] = []

    override func setUpWithError() throws {
        decks = try Self.launchDeckIds.map { try ContentLoader.loadDeck(id: $0) }
    }

    // MARK: - Catalog

    func test_catalog_isExactlyTheTwelveLaunchDecks() throws {
        let summaries = try DeckCatalogService().loadSummaries()
        XCTAssertEqual(summaries.map(\.id), Self.launchDeckIds,
                       "deck-catalog.json must list exactly the 12 canonical decks, in order")
    }

    func test_catalog_tiersMatchTheFreeTierDecision() throws {
        // D8: the-opener + the-check-in free; the other 10 Core-locked.
        let summaries = try DeckCatalogService().loadSummaries()
        for summary in summaries {
            if Self.freeDeckIds.contains(summary.id) {
                XCTAssertFalse(summary.isLocked, "\(summary.id) must be free")
                XCTAssertNil(summary.requiredEntitlement, "\(summary.id) must be free")
            } else {
                XCTAssertTrue(summary.isLocked, "\(summary.id) must be Core-locked")
                XCTAssertEqual(summary.requiredEntitlement, "core", "\(summary.id) must require core")
            }
        }
    }

    func test_catalog_cardCountsMatchPlayableCounts() throws {
        let summaries = try DeckCatalogService().loadSummaries()
        for (summary, deck) in zip(summaries, decks) {
            XCTAssertEqual(summary.id, deck.id)
            XCTAssertEqual(summary.cardCount, deck.cards(for: .mf).count,
                           "\(deck.id): catalog card_count must equal the playable count")
        }
    }

    // MARK: - Deck structure

    func test_everyDeck_parses_andCountsAreInRange() {
        XCTAssertEqual(decks.count, 12)
        for deck in decks {
            let playable = deck.cards(for: .mf).count
            let range = deck.id == "the-check-in" ? 5...6 : 10...11
            XCTAssertTrue(range.contains(playable),
                          "\(deck.id): \(playable) playable cards, expected \(range)")
            // The mf and flexible hands are the same size (variant pairs are symmetric).
            XCTAssertEqual(playable, deck.cards(for: .flexible).count,
                           "\(deck.id): mf and flexible hands must be the same size")
        }
    }

    func test_everyDeck_hasExactlyOneClosingRitual_asItsLastCard() {
        for deck in decks {
            let ordered = deck.orderedCards
            let closers = ordered.filter { $0.type == .closingRitual }
            if deck.id == Self.canonicalCeremonyDeckId {
                // The Opener's closer is its canonical whisper ceremony.
                XCTAssertEqual(closers.count, 0, "the-opener carries no closingRitual card")
                XCTAssertEqual(ordered.last?.type, .whisper,
                               "the-opener must end on its canonical whisper ceremony")
            } else {
                XCTAssertEqual(closers.count, 1,
                               "\(deck.id): exactly one closingRitual, found \(closers.count)")
                XCTAssertEqual(ordered.last?.id, closers.first?.id,
                               "\(deck.id): the closingRitual must be the last card")
            }
        }
    }

    func test_everyDeck_livingCardCountIsThreeToFour() {
        // Exempt: the-check-in (5-6 card ritual deck by design) and the
        // canonical Opener (9 discussion + 1 whisper, feel-approved as shipped).
        let exempt: Set<String> = ["the-check-in", Self.canonicalCeremonyDeckId]
        for deck in decks where !exempt.contains(deck.id) {
            let living = deck.cards(for: .mf).filter(\.isLivingCard).count
            XCTAssertTrue((3...4).contains(living),
                          "\(deck.id): \(living) living cards, expected 3-4")
        }
    }

    func test_noCard_usesADeferredCardType() {
        for deck in decks {
            for card in deck.cards {
                XCTAssertFalse(Self.deferredTypes.contains(card.type),
                               "\(deck.id)/\(card.id): \(card.type) has no V1 render path")
            }
        }
    }

    func test_noCard_usesSoloWhoStarts() {
        // The solo lane left the couple catalog (spec section 1).
        for deck in decks {
            for card in deck.cards {
                XCTAssertNotEqual(card.whoStarts, .solo,
                                  "\(deck.id)/\(card.id): solo whoStarts in a couple deck")
            }
        }
    }

    // MARK: - Gendered contract

    func test_genderedDecks_shipSymmetricMfAndFlexiblePairs() {
        for deck in decks {
            let gendered = deck.cards.filter(\.isGenderedCard)
            if Self.genderedDeckIds.contains(deck.id) {
                let mf = gendered.filter { $0.genderedFor == .mf }
                let flex = gendered.filter { $0.genderedFor == .flexible }
                XCTAssertEqual(mf.count, 2, "\(deck.id): expected a His + Her mf pair")
                XCTAssertEqual(flex.count, 2, "\(deck.id): expected 2 flexible variants")
                // Variants pair up by shared sortOrder, so exactly one renders per slot.
                XCTAssertEqual(Set(mf.map(\.sortOrder)), Set(flex.map(\.sortOrder)),
                               "\(deck.id): mf and flexible variants must share sortOrders")
                // Only the two shipped dynamics exist; mm/ff copy is deferred.
                XCTAssertTrue(gendered.allSatisfy { $0.genderedFor == .mf || $0.genderedFor == .flexible },
                              "\(deck.id): only mf and flexible variants may ship")
            } else {
                XCTAssertTrue(gendered.isEmpty,
                              "\(deck.id): unexpected gendered card in a non-gendered deck")
            }
        }
    }

    // MARK: - Copy rules

    func test_noEmDashOrEnDash_inAnyCopyField() {
        let banned: Set<Character> = ["\u{2014}", "\u{2013}"]
        for deck in decks {
            var fields: [(String, String)] = [
                ("\(deck.id).title", deck.title),
                ("\(deck.id).subtitle", deck.subtitle)
            ]
            for card in deck.cards {
                fields.append(("\(card.id).text", card.text))
                for word in card.highlightWords {
                    fields.append(("\(card.id).highlightWords", word))
                }
                if let beat = card.contextBeatCopy { fields.append(("\(card.id).contextBeatCopy", beat)) }
                if let back = card.backCopy { fields.append(("\(card.id).backCopy", back)) }
            }
            for (label, value) in fields {
                XCTAssertFalse(value.contains(where: { banned.contains($0) }),
                               "em/en dash in \(label): \(value)")
            }
        }
    }

    // MARK: - Versioning

    func test_schemaVersions_arePinned() {
        for deck in decks {
            XCTAssertEqual(deck.schemaVersion, Self.expectedSchemaVersions[deck.id],
                           "\(deck.id): schemaVersion drifted; bump the pin with the edit")
        }
    }

    // MARK: - Dead files

    func test_deadContentFilesAreGone() {
        // Deleted by the re-cut; zero Swift callers (verified in plan 15 + this pass).
        for name in ["deck-index", "assessment_questions", "cards"] {
            XCTAssertNil(Bundle.main.url(forResource: name, withExtension: "json"),
                         "\(name).json should have been deleted from the bundle")
        }
        for deckId in ["boundaries", "trust-repair", "right-now", "metamour",
                       "the-audit", "unfinished-business", "solo-prep",
                       "communication", "desire-and-fantasy", "jealousy-compersion",
                       "the-styles"] {
            XCTAssertNil(Bundle.main.url(forResource: deckId, withExtension: "json"),
                         "\(deckId).json left the catalog and should be deleted")
        }
    }
}
```

**pbxproj wiring (VaylTests is a manual PBXGroup; the app target auto-syncs but the test target does not).** Next ids in the AA00000N convention (last used: `AA00000B…` = PulseHistoryTests). Add all four entries:

1. `PBXBuildFile` section: `AA00000CAAAA000000000001 /* ContentLintTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA00000CAAAA000000000002 /* ContentLintTests.swift */; };`
2. `PBXFileReference` section: `AA00000CAAAA000000000002 /* ContentLintTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ContentLintTests.swift; sourceTree = "<group>"; };`
3. The VaylTests `PBXGroup` children array: add `AA00000CAAAA000000000002 /* ContentLintTests.swift */,`
4. The VaylTests target's `PBXSourcesBuildPhase` files array: add `AA00000CAAAA000000000001 /* ContentLintTests.swift in Sources */,`

> Note on ContentLoader in tests: VaylTests runs hosted, so `ContentLoader`'s bundle lookups resolve against the app bundle; `loadDeck(id:)` and `DeckCatalogService().loadSummaries()` work as-is, no test doubles needed. If `ContentLoader` turns out to use `Bundle.main` explicitly and the hosted lookup fails, trust the repo and switch the test to `Bundle(for: ContentLintTests.self)`-adjacent app-bundle resolution; do not add a DI seam for this.

**Done:** `ContentLintTests` compiles in the VaylTests target and every test above passes against the authored slate.

---

## Definition of Done (this segment, build-green)

- [ ] `deck-catalog.json` is verbatim the 12-entry catalog from H1; `DeckSummary` preview decodes 12 rows.
- [ ] All 14 files in the Delete table are gone; `grep -rn` for their ids over `Vayl --include="*.swift"` returns only `ContentLoader`'s dead accessors and comments; any `solo-prep` special-casing in Play code is removed.
- [ ] `Deck.cards(for:)` uses the H1 variant filter; flexible/mm/ff compositions see exactly one variant per gendered slot.
- [ ] `the-opener.json`: canonical 10 intact for mf, fixed opener-02 copy (no red-flag framing, no em dashes), `opener-06f`/`opener-07f` present, `schema_version: 2`; `Card.openerSamples` card 2 strings synced.
- [ ] `the-check-in.json`, `after-last-night.json`, `appreciation.json` are verbatim the H3/H5/H6 files.
- [ ] The eight build-time decks exist, matching their blueprints slot for slot, every card passing the four quality gates and all style rules.
- [ ] Every deck: unique closing ritual (concepts: The Carry, The Unsaid Said, The Keep, The Working Signal, Leave It Open, The Room Signal, The Thread, Again/Differently, The Day After Promise, Started Not Finished, Out Loud For Keeps; the Opener's canonical whisper ceremony), none reused.
- [ ] `ContentLintTests.swift` wired into VaylTests via pbxproj (AA00000C ids) and green.
- [ ] Zero em dashes and zero en dashes in any content string written by this segment (the lint proves it).

## Bryan verifies on device

- [ ] Play wall shows exactly 12 decks; only The Opener and The Check-In open free; the other 10 show the Core lock.
- [ ] Play The Check-In front to back twice in a row: it should feel repeatable, not like a rerun. 🎚️
- [ ] Read After Last Night and Appreciation end to end on device: flag any card that reads clinical, preachy, or formulaic (tone is your call, the gates got it to 80%).
- [ ] Open a deck as a flexible-composition couple (Settings → composition) and confirm gendered slots show the flexible variant, once, in the right position.
- [ ] Confirm the Opener's card 2 interstitial and back copy read right with the new lines.
- [ ] Spot-read the eight build-time decks against their tone guidance; mark rewrites.

## Constraints / do-not-touch (this segment)

- **No schema changes.** `Card`, `Deck`, `DeckSummary`, and every enum in `AppCardEnums.swift` are frozen. The ONLY Swift logic touched is the `Deck.cards(for:)` filter body (H1) and the preview-string sync in `Card.openerSamples` (H2). If content won't express in the schema, cut the content.
- **Never use** a deferred CardType, `who_starts: "solo"`, `register: "unknown"`, or `gendered_for: "mm"/"ff"`.
- **The Opener's canonical 10** (mf view) are frozen except the two opener-02 strings given in H2.
- **Do not touch** `desire_items.json`, `companion_cards.json`, or anything else under `Resources/Content/` beyond the two deletions listed (those belong to plan 15's surviving segments, not this one).
- Snake_case keys exactly as in `the-opener.json`; `ContentLoader` uses `.convertFromSnakeCase` and a single wrong key fails the deck at runtime.

## Open decisions (proceed on the default, flag it)

- **O1 — Opener lint exemption vs retype.** Default: keep opener-10 as `whisper` and encode the named exemption in the lint (H2/H7). Alternative (rejected): retype it `closingRitual` and lose the reveal ceremony, or add an 11th card and break the canonical 10.
- **O2 — Gendered deck set.** Default: the-opener, sex-and-pleasure, jealousy, swinging (the four where the bible/handoff name a real asymmetry). If Bryan wants pairs in after-last-night or the-first-time too, they're additive later; the lint's `genderedDeckIds` set is the one place to update.
- **O3 — `before-tonight` keeps its id.** Default: yes, overwrite the stub in place (id already matches spec 7.1), `schema_version: 2`. No rename needed.
- **O4 — Deck-level intensity values.** Defaults set in H1's catalog (appreciation 1 … when-it-gets-hard 7) per spec 7.3 "set honestly per deck job." Bryan can retune single values; the lint doesn't pin deck-level intensity, only structure.

# ═══════════════════ SECTION 5 — Composition Touchpoint (spec §9 glue) ═══════════════════

# SECTION 5 — Pairing Touchpoint: Composition Derivation, Confirm Moment, Settings Row (spec §9 / D5)

_Small, final glue section. Section 1 already ships the STORAGE (`Couple.connectionComposition: GenderDynamic` in SwiftData + the `couples.connection_composition` column with check constraint, default `'flexible'`, in `supabase/migrations/20260701000000_card_sessions_composition_and_reveal_merge.sql`). This section ships the BEHAVIOR: derive a proposal from both partners' OB gender answers at link completion, one-tap confirm, silent `flexible` otherwise, and a Settings row to change it anytime. Copy is wayfinding (which card wordings the couple will see), never identity assignment._

---

## Drift ledger — verified against the repo 2026-07-01

1. **There is no client-side couples write anywhere today.** `grep -rn 'from("couples")'` → `RealtimeSessionService.swift:195` (`fetchCoupleId`, a SELECT) and `EntitlementService.swift:33` (`fetchTier`, a SELECT). Entitlement writes go through the `grant-entitlement` edge function. So "the service that owns couples writes" does not exist; this section puts the composition read/write on `PairingService` (it already owns the couple lifecycle from the client's side: `claimCode` returns the coupleId).
2. **`couples` has NO UPDATE RLS policy** — only `"Partners can view their couple"` (SELECT, baseline L499). A blanket member-UPDATE policy is banned by the entitlement rule (members must never be able to write `access_tier`). Resolution: a `SECURITY DEFINER` RPC `set_connection_composition` guarded by `is_couple_member(uuid)` (baseline L62), mirroring section 1's `update_reveal_state` pattern. New migration below.
3. **`UserProfile.partnerGenderIdentity` (L34) is nil in practice.** Its own doc comment promises "populated via pairing flow", but the pairing flow never does: `get-partner` (`supabase/functions/get-partner/index.ts`) selects and returns ONLY `name, pronouns`, and remote `user_profiles` has **no gender column at all** (`grep -n gender supabase/migrations/*.sql` → zero hits). The OB writer `OnboardingStore.swift:120` (`profile.partnerGenderIdentity = data.genderB`) is dead in effect — `OnboardingData.genderB` stays nil by design (`OnboardingData.swift:31,34`). So derivation needs a carrier: this section adds `user_profiles.gender_identity`, pushes it through the existing `SyncManager.pushDisplayIdentity` pipe (already called by `PairingStore.syncIdentityToRemote()` on **every** pairing action, both sides, BEFORE linking — so no race at link completion), and returns it from `get-partner`.
4. **Own gender values** (`UserProfile.genderIdentity`, L29, `String?`): the GenderPhase drum options are exactly `"Man", "Woman", "Trans Man", "Trans Woman", "Non-binary"` (`GenderSequencer.swift:63`), or nil when declined/skipped (`GenderSequencer.swift:411`).
5. **`GenderDynamic`** (`Vayl/Core/Models/Enums/AppCardEnums.swift:164`): `mf / mm / ff / flexible` raw values + `displayName` ("Man + Woman" etc.). Verified.
6. **Link completion sites** (`Vayl/Features/Pairing/PairingStore.swift`): `joinWithCode` L154–158 and the poll task in `pollForPartner` L173–178 — both do `persistLink → linkState = .linked → refreshPartner()`. The success UI is `linkedState(coupleId:)` in `PairingJoinView.swift:183` and `PairingInviteView.swift:219`. The confirm card slots there. `persistLink` (L245) touches only `UserProfile` — **nothing in the app ever inserts a local `Couple` row** (`EntitlementStore.apply` L188 explicitly "Never creates/owns Couple rows"), so all local-Couple updates below are mirror-if-present, same as EntitlementStore.
7. **Settings anatomy** (`Vayl/Features/Settings/`): `SettingsView.partnerSection` L377 (already gated `appState.linkState == .linked`), rows are `Button { … } label: { SettingsNavRow(icon:label:subtitle:value:) }` inside `SettingsCard` (`Vayl/Design/Components/Cards/SettingsCard.swift`), sub-screens are `.vaylSheet(isPresented:heightFraction:screenHeight:)` with an `onClose` closure (L74–92). `SettingsStore` (`Store/SettingsStore.swift`) is the brain; deps injected via init with the nil-resolved-inside pattern (L52–62, see the `accountService` MainActor note).
8. **pbxproj id collision across sections (flag for the builder):** sections 1, 3, and 4 each independently claim `AA00000C…` for their test files (section 3 also claims `AA00000D`). At build time assign sequentially — the four earlier test files consume `AA00000C/D/E/F`. **This section's test file takes `AA00000G`.**
9. **Prod deploy reality:** Supabase MCP is read-only from Claude and the CLI carries a read-only prod token (known drift: consent-ask/respond, delete-account, send-session-invite are NOT deployed). The migration + the `get-partner` redeploy in this section are file changes only; applying/deploying is Bryan's step, called out in his checklist.

---

## Files (this section's scope only)

### Create

| File | Responsibility |
|---|---|
| `supabase/migrations/20260701001000_composition_write_path.sql` | `user_profiles.gender_identity` column; `set_connection_composition` SECURITY DEFINER RPC + grants |
| `Vayl/Features/Pairing/CompositionConfirmCard.swift` | The one-tap confirm card shown in both linked states (view only, forwards taps to PairingStore) |
| `Vayl/Features/Settings/SettingsCompositionView.swift` | The small four-option picker sheet (view only, writes through SettingsStore) |
| `VaylTests/CompositionDerivationTests.swift` | Unit tests for the pure derivation function |

### Modify

| File | Line anchor | Change |
|---|---|---|
| `Vayl/Core/Models/Enums/AppCardEnums.swift` | after `GenderDynamic.displayName` (L170–177) | `static func proposal(myGender:partnerGender:)` pure derivation |
| `supabase/functions/get-partner/index.ts` | the two partner-read lines (select + response) | carry `gender_identity` as `gender` |
| `Vayl/Core/Services/ProfileService.swift` | `updateIdentity` L204 | add `gender:` param → `patch["gender_identity"]` |
| `Vayl/Core/Services/SyncManager.swift` | `pushDisplayIdentity` L125 | pass `localProfile.genderIdentity` through |
| `Vayl/Core/Services/PairingService.swift` | `PartnerIdentity` L46; end of class | `gender` field; `fetchComposition` + `setComposition` methods |
| `Vayl/Features/Pairing/PairingStore.swift` | `refreshPartner` L229; new MARK after it | persist partner gender; proposal state + confirm/dismiss |
| `Vayl/Features/Pairing/PairingJoinView.swift` | `linkedState` L183 | append `CompositionConfirmCard` |
| `Vayl/Features/Pairing/PairingInviteView.swift` | `linkedState` L219 | append `CompositionConfirmCard` (identical two lines) |
| `Vayl/Features/Settings/Store/SettingsStore.swift` | init L52; new MARK after `setShareCapacity` | `pairingService` dep; `composition` state + load/set |
| `Vayl/Features/Settings/SettingsView.swift` | sheet-state block L25–36; `partnerSection` L377 | `showComposition` flag + sheet + row inside the linked branch |
| `Vayl.xcodeproj/project.pbxproj` | four anchors (see Segment 5.1) | wire `CompositionDerivationTests.swift` as `AA00000G…` |

### Delete

None.

---

## Segment 5.1 — Derivation + service write path

**One thing it does:** a pure function that turns two OB gender answers into a `GenderDynamic` proposal (or nil for silent flexible), plus the remote carrier for partner gender and the guarded couples write — Store code comes in 5.2/5.3; this segment is Model + Service + SQL only.

### 1a. The pure derivation — `Vayl/Core/Models/Enums/AppCardEnums.swift`, extend `GenderDynamic` (after `displayName`, ~L177)

```swift
    /// Spec §9 derivation. Inputs are the raw GenderPhase drum strings
    /// ("Man" / "Woman" / "Trans Man" / "Trans Woman" / "Non-binary") or nil
    /// when a partner declined the drum. Returns the composition to PROPOSE
    /// (one-tap confirm at link completion), or nil when either answer is
    /// missing or non-binary — the caller then defaults .flexible silently.
    /// Trans men count as men and trans women as women for card-wording
    /// purposes; this maps what each person SAID, it never infers anything.
    /// Symmetric: proposal(a, b) == proposal(b, a).
    static func proposal(myGender: String?, partnerGender: String?) -> GenderDynamic? {
        func binaryAxis(_ raw: String?) -> Character? {
            switch raw?.trimmingCharacters(in: .whitespaces).lowercased() {
            case "man", "trans man":     return "m"
            case "woman", "trans woman": return "w"
            default:                     return nil   // Non-binary, declined, unknown
            }
        }
        guard let mine = binaryAxis(myGender),
              let theirs = binaryAxis(partnerGender) else { return nil }
        switch (mine, theirs) {
        case ("m", "m"): return .mm
        case ("w", "w"): return .ff
        default:         return .mf
        }
    }
```

### 1b. Migration — create `supabase/migrations/20260701001000_composition_write_path.sql`

Numbered after section 1's `20260701000000_…`. Same process guard as section 1: this pass only ADDS the file and proves it locally (`supabase start && supabase test db`); nothing is applied to prod (MCP read-only, `supabase db push` is Bryan's step after review).

```sql
-- Composition write path (spec §9 behavior; section-1 migration shipped the column).
--
-- 1. user_profiles.gender_identity — the OB GenderPhase answer, pushed by the
--    app's identity sync so get-partner can return it at link completion.
--    user_profiles RLS is unchanged (SELECT stays auth_id = auth.uid(); the
--    partner reads it ONLY through the column-scoped get-partner function).
-- 2. set_connection_composition — the only client write path to
--    couples.connection_composition. SECURITY DEFINER + is_couple_member guard,
--    because couples has no member UPDATE policy on purpose (a blanket one
--    would let clients write access_tier — entitlements are service-role-only).

-- ── 1. gender_identity ───────────────────────────────────────────────────────

alter table "public"."user_profiles"
  add column if not exists "gender_identity" text;

comment on column "public"."user_profiles"."gender_identity" is
  'Raw OB GenderPhase answer (Man / Woman / Trans Man / Trans Woman / Non-binary), nil if declined. Partner-visible via get-partner only.';

-- ── 2. set_connection_composition ────────────────────────────────────────────

create or replace function public.set_connection_composition(
  p_couple_id uuid,
  p_value     text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_couple_member(p_couple_id) then
    raise exception 'not a member of couple %', p_couple_id
      using errcode = '42501';
  end if;
  if p_value not in ('mf', 'mm', 'ff', 'flexible') then
    raise exception 'invalid connection_composition %', p_value
      using errcode = '23514';
  end if;

  update public.couples
     set connection_composition = p_value
   where id = p_couple_id;
end;
$$;

revoke all on function public.set_connection_composition(uuid, text) from public, anon;
grant execute on function public.set_connection_composition(uuid, text) to authenticated;
```

### 1c. Carry gender through the identity pipe

`Vayl/Core/Services/ProfileService.swift` — `updateIdentity` (L204) gains a `gender` parameter (patch stays partial and idempotent; RLS `auth_id = auth.uid()` permits it exactly like `name`/`pronouns`):

```swift
    func updateIdentity(name: String?, pronouns: String?, gender: String? = nil) async throws {
        let authId = try await supabase.auth.session.user.id
        var patch: [String: String] = [:]
        if let name, !name.isEmpty { patch["name"] = name }
        if let pronouns, !pronouns.isEmpty { patch["pronouns"] = pronouns }
        if let gender, !gender.isEmpty { patch["gender_identity"] = gender }
        guard !patch.isEmpty else { return }
        try await supabase
            .from("user_profiles")
            .update(patch)
            .eq("auth_id", value: authId.uuidString)
            .execute()
    }
```

`Vayl/Core/Services/SyncManager.swift` — `pushDisplayIdentity` (L125), one added argument in the existing call:

```swift
            try await profileService.updateIdentity(
                name: trimmedName.isEmpty ? nil : trimmedName,
                pronouns: pronouns,
                gender: localProfile.genderIdentity
            )
```

Because `PairingStore.syncIdentityToRemote()` already calls this on `generateInvite` (L113) AND `joinWithCode` (L151) AND every linked-surface load (`refreshPartner` L230), both partners' genders are remote BEFORE either device reaches `.linked`, and pre-existing couples back-fill on their next pairing-surface visit — the exact mechanism the name back-fill already uses. No new call sites.

### 1d. Return it from `get-partner` — `supabase/functions/get-partner/index.ts`

Two-line diff (the function's column-scoping comment is why this is safe: it stays a hand-picked list). Redeploy is Bryan's step (read-only CLI token; use the dashboard or a write-scoped token):

```ts
    // ── ONLY the partner's display identity — nothing else ────────────
    const { data: partner, error: partnerErr } = await serviceClient
      .from("user_profiles")
      .select("name, pronouns, gender_identity")
      .eq("id", partnerProfileId)
      .single()
    if (partnerErr || !partner) return json({ partner: null }, 200)

    return json(
      {
        partner: {
          name: partner.name ?? null,
          pronouns: partner.pronouns ?? null,
          gender: partner.gender_identity ?? null,
        },
      },
      200,
    )
```

### 1e. Service methods — `Vayl/Core/Services/PairingService.swift`

`PartnerIdentity` (L46) gains the field (decodes `{ partner: null }` and old deployments missing the key just as gracefully — all fields optional):

```swift
/// The linked partner's display identity, as returned by `get-partner`.
/// Any field may be nil if the partner hasn't set it yet.
struct PartnerIdentity: Decodable {
    let name: String?
    let pronouns: String?
    let gender: String?     // raw OB GenderPhase answer — composition derivation input
}
```

New methods at the end of the class (before `// MARK: - Private Helpers`). Read is direct PostgREST (the member SELECT policy covers it); write is the RPC. Note the identity rule: the RPC keys off `auth.uid()` via `is_couple_member`, the client never passes a profile id:

```swift
    // MARK: - Connection Composition (spec §9)

    /// Reads the couple's connection_composition. RLS scopes the row to couple
    /// members, so a non-member reads nothing → returns .flexible (the default).
    func fetchComposition(coupleId: UUID) async throws -> GenderDynamic {
        struct Row: Decodable {
            let connectionComposition: String
            enum CodingKeys: String, CodingKey {
                case connectionComposition = "connection_composition"
            }
        }
        let rows: [Row] = try await supabase
            .from("couples")
            .select("connection_composition")
            .eq("id", value: coupleId.uuidString)
            .execute()
            .value
        guard let raw = rows.first?.connectionComposition,
              let value = GenderDynamic(rawValue: raw) else { return .flexible }
        return value
    }

    /// Writes connection_composition via the set_connection_composition RPC
    /// (SECURITY DEFINER + is_couple_member guard — couples has no member
    /// UPDATE policy by design). Throws on non-membership or invalid value.
    func setComposition(coupleId: UUID, _ value: GenderDynamic) async throws {
        try await supabase
            .rpc("set_connection_composition", params: [
                "p_couple_id": coupleId.uuidString,
                "p_value": value.rawValue,
            ])
            .execute()
        logger.info("connection_composition set to \(value.rawValue)")
    }
```

### 1f. Unit test — create `VaylTests/CompositionDerivationTests.swift`

Matches the house style (`ContextOptionTests.swift`: plain XCTest, `@testable import Vayl`, behavior-named funcs):

```swift
import XCTest
@testable import Vayl

// Spec §9 derivation: both partners' OB gender answers → the composition to
// PROPOSE at link completion, or nil → silent .flexible. Inputs are the raw
// GenderPhase drum strings (GenderSequencer.options) or nil when declined.
// Source of truth: GenderDynamic.proposal in AppCardEnums.swift.
final class CompositionDerivationTests: XCTestCase {

    func test_binaryPairsDeriveTheirComposition() {
        XCTAssertEqual(GenderDynamic.proposal(myGender: "Man",   partnerGender: "Woman"), .mf)
        XCTAssertEqual(GenderDynamic.proposal(myGender: "Man",   partnerGender: "Man"),   .mm)
        XCTAssertEqual(GenderDynamic.proposal(myGender: "Woman", partnerGender: "Woman"), .ff)
    }

    func test_derivationIsSymmetric() {
        // Both devices derive independently — order must not matter.
        XCTAssertEqual(
            GenderDynamic.proposal(myGender: "Woman", partnerGender: "Man"),
            GenderDynamic.proposal(myGender: "Man", partnerGender: "Woman")
        )
    }

    func test_transAnswersCountOnTheirStatedAxis() {
        XCTAssertEqual(GenderDynamic.proposal(myGender: "Trans Man",   partnerGender: "Woman"),       .mf)
        XCTAssertEqual(GenderDynamic.proposal(myGender: "Trans Woman", partnerGender: "Trans Woman"), .ff)
        XCTAssertEqual(GenderDynamic.proposal(myGender: "Trans Man",   partnerGender: "Man"),         .mm)
    }

    func test_nonBinaryOrMissingAnswerMeansNoProposal() {
        XCTAssertNil(GenderDynamic.proposal(myGender: "Non-binary", partnerGender: "Man"))
        XCTAssertNil(GenderDynamic.proposal(myGender: "Man",        partnerGender: "Non-binary"))
        XCTAssertNil(GenderDynamic.proposal(myGender: nil,          partnerGender: "Woman"))
        XCTAssertNil(GenderDynamic.proposal(myGender: nil,          partnerGender: nil))
    }

    func test_inputNormalization() {
        // The remote round-trip must not break derivation on casing/whitespace.
        XCTAssertEqual(GenderDynamic.proposal(myGender: " man ", partnerGender: "WOMAN"), .mf)
        XCTAssertNil(GenderDynamic.proposal(myGender: "manly",  partnerGender: "Woman"))
    }
}
```

**pbxproj wiring (VaylTests is a manual PBXGroup — skip this and the tests silently don't run).** Four insertions following the existing `AA00000B` rows exactly (PBXBuildFile ~L23–33, PBXFileReference ~L64–74, VaylTests group children ~L166–176, VaylTests Sources phase ~L367+). Sections 1/3/4 collectively consume `AA00000C`–`AA00000F` (note: as drafted they collide on `AA00000C` — dedupe sequentially at build time). This file takes:

- build file: `AA00000GAAAA000000000001 /* CompositionDerivationTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA00000GAAAA000000000002 /* CompositionDerivationTests.swift */; };`
- file ref: `AA00000GAAAA000000000002 /* CompositionDerivationTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CompositionDerivationTests.swift; sourceTree = "<group>"; };`
- group child: `AA00000GAAAA000000000002 /* CompositionDerivationTests.swift */,`
- Sources phase: `AA00000GAAAA000000000001 /* CompositionDerivationTests.swift in Sources */,`

**Done:** derivation compiles, all five tests green via `xcodebuild test -only-testing:VaylTests/CompositionDerivationTests`, migration passes `supabase test db` locally, nothing applied to prod.

---

## Segment 5.2 — The confirm moment at link completion

**One thing it does:** when a device reaches `.linked`, derive once; if a proposal exists, show a one-tap confirm card on the existing linked screen (confirm → RPC write; skip/close → nothing, the DB default already IS `flexible`, which is exactly "default flexible silently"). If no proposal derives, show nothing and write nothing.

### 2a. Store — `Vayl/Features/Pairing/PairingStore.swift`

Add state + a MARK after `// MARK: - Partner Identity`. `refreshPartner` (L229) grows two responsibilities: persist the partner's gender locally (fulfilling `UserProfile.partnerGenderIdentity`'s existing "populated via pairing flow" contract, L32–34) and derive the proposal exactly once. Both devices reach `.linked` and both may show the card — the derivation is symmetric, so they propose the same value and the RPC write is idempotent (last write wins with the same value).

```swift
    // MARK: - Connection Composition (spec §9)

    /// The composition to propose on the linked screen. Nil = nothing to
    /// propose (non-binary / declined / already resolved) → silent .flexible,
    /// which is the DB default — no write needed.
    private(set) var compositionProposal: GenderDynamic? = nil

    /// Set once the user answers (either way) so a re-entered linked surface
    /// never re-asks. UserDefaults because it is per-device UI state, not data.
    private let proposalResolvedKey = "vayl.compositionProposalResolved"

    /// Derives the proposal from both partners' OB gender answers. Called from
    /// refreshPartner after the partner's gender lands. One-shot per device.
    private func deriveCompositionProposal(partnerGender: String?) {
        guard case .linked = linkState,
              !UserDefaults.standard.bool(forKey: proposalResolvedKey) else { return }
        let context = ModelContext(modelContainer)
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        compositionProposal = GenderDynamic.proposal(
            myGender: profile.genderIdentity,
            partnerGender: partnerGender
        )
        if compositionProposal == nil {
            // Nothing to propose — resolve silently so we never re-derive.
            UserDefaults.standard.set(true, forKey: proposalResolvedKey)
        }
    }

    /// One-tap confirm. Writes the proposal remotely (RPC), mirrors into the
    /// local Couple if one exists (same mirror-if-present rule as
    /// EntitlementStore.apply — this store never creates Couple rows).
    func confirmComposition() async {
        guard case .linked(let coupleId) = linkState,
              let proposal = compositionProposal else { return }
        do {
            try await pairingService.setComposition(coupleId: coupleId, proposal)
            mirrorCompositionLocally(proposal, coupleId: coupleId)
            compositionProposal = nil
            UserDefaults.standard.set(true, forKey: proposalResolvedKey)
            logger.info("Composition confirmed: \(proposal.rawValue)")
        } catch {
            // Non-fatal: the couple can set it anytime in Settings.
            compositionProposal = nil
            UserDefaults.standard.set(true, forKey: proposalResolvedKey)
            logger.error("Composition write failed (Settings row remains): \(error.localizedDescription)")
        }
    }

    /// "Keep it flexible" / card skipped. No network call — the column already
    /// defaults to flexible, which is the spec's silent fallback.
    func dismissComposition() {
        compositionProposal = nil
        UserDefaults.standard.set(true, forKey: proposalResolvedKey)
        logger.info("Composition proposal dismissed — staying flexible")
    }

    private func mirrorCompositionLocally(_ value: GenderDynamic, coupleId: UUID) {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
        guard let couple = try? context.fetch(descriptor).first else { return }
        couple.connectionComposition = value
        try? context.saveWithLogging()
    }
```

Replace the body of `refreshPartner` (L229–238) with:

```swift
    func refreshPartner() async {
        await syncIdentityToRemote()
        do {
            if let partner = try await pairingService.fetchPartner() {
                partnerName = partner.name
                persistPartnerGender(partner.gender)
                deriveCompositionProposal(partnerGender: partner.gender)
            }
        } catch {
            logger.error("Fetch partner failed: \(error.localizedDescription)")
        }
    }

    /// Fulfills UserProfile.partnerGenderIdentity's "populated via pairing
    /// flow" contract (UserProfile.swift L32–34). Best-effort.
    private func persistPartnerGender(_ gender: String?) {
        guard let gender else { return }
        let context = ModelContext(modelContainer)
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        profile.partnerGenderIdentity = gender
        try? context.saveWithLogging()
    }
```

### 2b. The card — create `Vayl/Features/Pairing/CompositionConfirmCard.swift`

View only; matches the pairing flow's visual language (token gradients on a `whisperFill` surface, `VaylButton` for the primary action, caption footnote — the same vocabulary as `codeInputField` in `PairingJoinView.swift:124–178`). Copy is pure wayfinding: it names what each person said and which card wording that unlocks; the quiet path is one tap; the Settings escape hatch is stated. No em dashes.

```swift
//
//  CompositionConfirmCard.swift
//  Vayl
//
//  Spec §9 one-tap confirm, shown on the pairing linked screen when a
//  composition proposal derives. Display only — PairingStore decides.
//

import SwiftUI

struct CompositionConfirmCard: View {

    let proposal: GenderDynamic
    let onConfirm: () -> Void
    let onKeepFlexible: () -> Void

    @State private var flexiblePressed = false

    /// Wayfinding: which card wording the couple will see. Never a statement
    /// about either person.
    private var wordingLine: String {
        switch proposal {
        case .mf:       return "worded for a man and a woman"
        case .mm:       return "worded for two men"
        case .ff:       return "worded for two women"
        case .flexible: return "kept flexible"   // unreachable: flexible never proposes
        }
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            VStack(spacing: AppSpacing.sm) {
                Text("One thing about your cards")
                    .font(AppFonts.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Some session cards come in a few wordings. Based on what you each shared, yours can be \(wordingLine).")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VaylButton(label: "Use that wording") {
                onConfirm()
            }

            Button {
                onKeepFlexible()
            } label: {
                Text("Keep it flexible")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .contentShape(Rectangle())
            }
            .scaleEffect(flexiblePressed ? 0.96 : 1.0)
            .sensoryFeedback(.impact(.light), trigger: flexiblePressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in flexiblePressed = true }
                    .onEnded { _ in flexiblePressed = false }
            )

            Text("You can change this anytime in Settings.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.container)
                .fill(AppColors.whisperFill)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.container)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    AppColors.accentPrimary.opacity(0.4),
                                    AppColors.accentSecondary.opacity(0.4),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
    }
}

#Preview {
    ZStack {
        AppColors.void.ignoresSafeArea()
        CompositionConfirmCard(proposal: .mf, onConfirm: {}, onKeepFlexible: {})
            .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
```

(Build note: the `0.4` stroke opacities and `0.96` press scale are the exact values the sibling pairing views already use at `PairingJoinView.swift:158–163`; reuse whatever opacity token those lines resolve to if a token exists at build time rather than inventing one.)

### 2c. Mount it — both linked states, identical two lines

`Vayl/Features/Pairing/PairingJoinView.swift`, inside `linkedState(coupleId:)` (L183), after the closing brace of the inner `VStack(spacing: AppSpacing.sm)` (after L201):

```swift
            if let proposal = store.compositionProposal {
                CompositionConfirmCard(
                    proposal: proposal,
                    onConfirm: { Task { await store.confirmComposition() } },
                    onKeepFlexible: { store.dismissComposition() }
                )
                .transition(.opacity)
                .animation(AppAnimation.standard, value: store.compositionProposal)
            }
```

`Vayl/Features/Pairing/PairingInviteView.swift`, the same block inside its `linkedState(coupleId:)` (L219), in the same position relative to the linked headline stack. Closing the sheet without answering counts as skip: nothing was written, the column default is already `flexible`, and the one-shot guard has NOT been set, so the Settings row (and any later linked-surface derivation) still works.

**Done:** on a fresh two-device link where both OB answers are binary, both linked screens grow the confirm card; "Use that wording" round-trips the RPC; "Keep it flexible" or closing the sheet leaves the row at `flexible` with zero network calls; a non-binary or declined answer on either side shows no card at all.

---

## Segment 5.3 — Settings row

**One thing it does:** a "Card wording" row inside the existing Partner section (already visible only when paired) that opens a small four-option picker sheet writing through the same Store → Service path.

### 3a. Store — `Vayl/Features/Settings/Store/SettingsStore.swift`

Init (L52–62) gains the dep with the exact `accountService` nil-resolved-inside pattern (the MainActor comment there explains why not a default argument):

```swift
    private let pairingService: PairingService

    init(
        modelContainer: ModelContainer,
        appState: AppState,
        authService: AuthService,
        accountService: AccountService? = nil,
        pairingService: PairingService? = nil
    ) {
        self.modelContainer = modelContainer
        self.appState = appState
        self.authService = authService
        self.accountService = accountService ?? AccountService()
        self.pairingService = pairingService ?? PairingService()
    }
```

New section after `// MARK: - Privacy preference (share capacity with partner)`:

```swift
    // MARK: - Connection composition (spec §9 Settings row)

    /// The couple's current composition, for the row value + picker checkmark.
    /// Hydrated from the local Couple mirror instantly, then the remote row.
    private(set) var composition: GenderDynamic = .flexible

    func loadComposition() async {
        guard let coupleId = appState.coupleId else { return }
        // Instant local mirror (may not exist — nothing creates Couple rows locally).
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
        if let couple = try? context.fetch(descriptor).first {
            composition = couple.connectionComposition
        }
        // Remote truth.
        if let remote = try? await pairingService.fetchComposition(coupleId: coupleId) {
            composition = remote
        }
    }

    /// Writes the chosen composition through the RPC and mirrors it into the
    /// local Couple if one exists. Optimistic UI; reverts on failure.
    func setComposition(_ value: GenderDynamic) async {
        guard let coupleId = appState.coupleId else { return }
        let previous = composition
        composition = value
        do {
            try await pairingService.setComposition(coupleId: coupleId, value)
            let context = ModelContext(modelContainer)
            let descriptor = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
            if let couple = try? context.fetch(descriptor).first {
                couple.connectionComposition = value
                try? context.saveWithLogging()
            }
        } catch {
            composition = previous
            logger.error("setComposition failed: \(error.localizedDescription)")
        }
    }
```

### 3b. Row — `Vayl/Features/Settings/SettingsView.swift`

State flag next to the other sheet flags (after `showPartner`, L29): `@State private var showComposition: Bool = false`.

Inside `partnerSection`'s linked branch (L381–…), directly after the existing "Linked" `Button`/`SettingsNavRow` (keep whatever divider treatment the surrounding rows use — match the neighbors exactly):

```swift
                        Button { showComposition = true } label: {
                            SettingsNavRow(
                                icon: "text.bubble",
                                label: "Card wording",
                                subtitle: "How some session cards are phrased",
                                value: store?.composition.settingsLabel ?? GenderDynamic.flexible.settingsLabel
                            )
                        }
```

Sheet, alongside the other `.vaylSheet` blocks (after the `showPartner` one, L90–92) — half-height, it is a four-row picker:

```swift
            .vaylSheet(isPresented: $showComposition, heightFraction: 0.5, screenHeight: layout.screenHeight) {
                if let store {
                    SettingsCompositionView(store: store, onClose: { showComposition = false })
                }
            }
```

And in the existing `.onAppear` (L61–68), after the store is built: `Task { await store?.loadComposition() }`.

### 3c. Picker sheet — create `Vayl/Features/Settings/SettingsCompositionView.swift`

Modeled on the other Settings sub-sheets (store + `onClose`, `SettingsCard` + `SettingsSectionLabel` internals, rows are plain Buttons like every other Settings row). Human labels per D5; the footer keeps the discovery-not-assessment line. No em dashes.

```swift
// Vayl/Features/Settings/SettingsCompositionView.swift
//
// Spec §9: the couple can change their card wording anytime. Four options,
// one checkmark, writes through SettingsStore → PairingService RPC.

import SwiftUI

struct SettingsCompositionView: View {

    @State var store: SettingsStore
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionLabel(text: "Card wording")

            Text("Some session cards come in a few phrasings. Pick the one that fits how you two want your cards to read.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.bottom, AppSpacing.sm)

            SettingsCard {
                VStack(spacing: 0) {
                    ForEach(GenderDynamic.allCases, id: \.self) { option in
                        Button {
                            Task { await store.setComposition(option) }
                        } label: {
                            HStack(spacing: AppSpacing.sm + AppSpacing.xs) {
                                Text(option.settingsLabel)
                                    .font(AppFonts.bodyMedium)
                                    .foregroundStyle(AppColors.textPrimary)
                                Spacer()
                                if store.composition == option {
                                    Image(systemName: "checkmark")
                                        .font(AppFonts.bodyMedium)
                                        .foregroundStyle(AppColors.accentPrimary)
                                        .accessibilityHidden(true)
                                }
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical, AppSpacing.sm + AppSpacing.xs)
                        }
                        .sensoryFeedback(.impact(.light), trigger: store.composition)
                        .accessibilityAddTraits(store.composition == option ? .isSelected : [])
                    }
                }
            }

            Text("This only changes how those cards are phrased. It is not a label on either of you.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.top, AppSpacing.sm)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.lg)
        .task { await store.loadComposition() }
    }
}

// MARK: - Human labels (D5 wording — settings-facing, distinct from the
// terser GenderDynamic.displayName used elsewhere)

extension GenderDynamic {
    var settingsLabel: String {
        switch self {
        case .mf:       return "Man and woman"
        case .mm:       return "Two men"
        case .ff:       return "Two women"
        case .flexible: return "Flexible, experience based"
        }
    }
}
```

(Build note: match the header/close treatment of `SettingsPrivacyView` exactly — if those sheets render an explicit close affordance calling `onClose`, replicate it verbatim here; the flag is otherwise cleared by the sheet's own dismiss.)

**Done:** paired build shows the "Card wording" row under Partner with the current value; the picker round-trips a change (checkmark moves optimistically, survives sheet reopen after `loadComposition`); unpaired/solo build shows no row (existing `appState.linkState == .linked` gate).

---

## Definition of Done (build-green)

- [ ] `GenderDynamic.proposal` exists; `CompositionDerivationTests` (5 tests) green; pbxproj wired via `AA00000G` (four entries).
- [ ] Migration `20260701001000_composition_write_path.sql` exists (gender column + guarded RPC + grants) and passes `supabase test db` locally; nothing applied to prod.
- [ ] `get-partner/index.ts` selects and returns `gender`; `PartnerIdentity.gender` decodes it (and tolerates its absence).
- [ ] Identity pipe carries gender: `ProfileService.updateIdentity(gender:)` → `SyncManager.pushDisplayIdentity` → existing `syncIdentityToRemote` call sites untouched.
- [ ] `PairingStore`: proposal derives once at link completion, `confirmComposition` writes the RPC + mirrors local Couple if present, dismiss/skip writes nothing (default is already flexible), one-shot UserDefaults guard set on every resolution path.
- [ ] Confirm card mounted in BOTH `linkedState` views; no card when either gender answer is non-binary or missing.
- [ ] Settings: "Card wording" row in the linked Partner section + half-height picker sheet, `SettingsStore.loadComposition`/`setComposition` through `PairingService`; hidden when unpaired.
- [ ] No raw `.sheet`/`.fullScreenCover`, no raw color/spacing literals beyond the two values matched to existing pairing-view siblings, no em dashes in any copy string.

## Bryan verifies on device

1. **Fresh two-device pair (both answered Man/Woman in OB):** both linked screens show the confirm card proposing "worded for a man and a woman"; tap "Use that wording" on one device, then confirm Settings → Partner → Card wording reads "Man and woman" on BOTH devices (after the second one opens the picker). Requires `supabase db push` + redeploying `get-partner` first (CLI token is read-only; use the dashboard if push is blocked).
2. **Skip path:** re-pair a test couple and close the linked sheet without answering; Settings row reads "Flexible, experience based" and the app never re-asks. 🎚️ Feel: the card should read as a small courtesy, not a gate.
3. **Non-binary path:** an OB run answering Non-binary (or declining the drum) on either device shows no confirm card anywhere; Settings row still works and can set any value.

## Constraints / do-not-touch

- **Do not touch the pairing handshake itself:** `generateCode` / `claimCode` / `pollForClaim` / `pollForPartner` / `persistLink` logic is off-limits; this section only adds behavior AFTER `.linked` (inside `refreshPartner` and the linked-state views).
- Do not add an UPDATE RLS policy on `couples` (entitlement columns must stay service-role-only); the RPC is the only client write path.
- Do not modify section 1's migration file; this section's SQL is its own file.
- Do not create local `Couple` rows (mirror-if-present only, per `EntitlementStore.apply`).
- `user_profiles` SELECT RLS stays `auth_id = auth.uid()`; partner gender crosses only via `get-partner`.
- Copy strings: wayfinding only, no identity assignment, no em dashes.

## Open decisions (proceed on the default, flag in the handoff)

1. **Trans answers map to their stated axis** (Trans Man → man, Trans Woman → woman) for card-wording purposes. This is the respectful reading of "binary and complementary/matching" and stays inside the bright line (it maps what the user said). Default: implemented as above; if Bryan prefers trans answers to fall to silent flexible, delete two cases in `binaryAxis` and two test assertions.
2. **Both devices see the confirm.** Derivation is symmetric and the write idempotent, so no coordination is needed; the alternative (joiner-only) saves nothing and leaves the inviter uninformed. Default: both.
3. **Cross-section gap, noted not fixed here:** section 3's PlayStore reads `couple.connectionComposition` from the LOCAL Couple row, but nothing in the app ever creates one, so that read falls back to `.flexible` until some feature hydrates local Couple rows. The remote row is always correct (this section's writes), and `PairingService.fetchComposition` exists for PlayStore to consume. Default: leave as-is and flag; wiring PlayStore to the remote value is a one-line follow-up in section 3's territory.
