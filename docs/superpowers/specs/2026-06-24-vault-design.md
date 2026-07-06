# The Vault — Design Spec (2026-06-24)

> Segment 5 of the Map build. The Vault is the couple's shared-but-consented space, reached
> from the Map's Us layer. This spec covers the three net-new features plus the Desire Map
> reuse, the shared backend foundation they sit on, and the build sequence. **No code is
> written until this spec is approved** (the agreed gate for the production-DB + privacy work).

---

## 0. Scope and locked decisions

The Vault holds four parts:

| Part | Status | Source of decision |
|---|---|---|
| **Desire Map** | mostly reuse | existing `DesireRevealStore` + paywall |
| **Agreements** | net-new, **fully synced** | kickoff decision (2026-06-24) |
| **Consent exchange** | net-new, **full two-sided, "a decline never discloses"** | kickoff decision (2026-06-24) |
| **Event Log** | net-new, **richer** (mood + tags + who + private/shared), **no photos, no connection modeling** | this session (2026-06-24) |

Locked this session for the Event Log: **who = free text** (no stored connection records; multi-partner
modeling stays Act 2), **media = none in V1** (photos deferred; outing-risk + encrypted-sync work).

**Tiers (free vs Core), settled 2026-06-24.** Safety and core utility are free; the paid hook stays the
full Desire Map reveal.
- **Free:** 1 deck, 1 Desire Map match, all of Learn, the Pulse, the **Event Log**, **Agreements + safe word**.
- **Core ($24.99):** the full Desire Map reveal and its consent openings, plus the rest of the decks.
- **Principle:** safety primitives (safe word, agreements) are never paywalled; gating a couple's
  boundaries would be wrong for an NM app. The consent exchange is not a separate SKU; it rides on
  whatever Desire Map access the couple already has.

This is a backend mini-project, not a single segment. It gets its own sequenced build (section 6).

---

## 1. The shared foundation (build once, reuse for all three)

### 1.1 Private vs shared data — the core primitive

The app already encodes this split, and we reuse it exactly:

- **Private** (only the author ever sees it): user-scoped. Precedent = `desire_ratings` — RLS gates
  every row by `user_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid())`, and there is
  **no policy that lets a partner read it**. A partner physically cannot SELECT another user's rows.
- **Shared** (both partners see it): couple-scoped. Precedent = `desire_matches` / `desire_map_status`
  — RLS gates by couple membership (template in 1.3).

Swift mirror: a model exposes `isSyncable` (precedent = `DesireMapEntry.isSyncable`); the sync layer
only ever pushes syncable rows.

### 1.2 Sync mechanics (follow the existing path)

- New synced rows enqueue a durable `SyncTask(taskType:entityId:payload:)` via
  `SyncManager.enqueueSyncTask`; `processTaskQueue()` gains a `case` per new `taskType`.
- Service methods upsert with the supabase client: `.from(table).upsert(rows, onConflict: "…").execute()`
  (precedent = `DesireSyncService`).
- **Sensitive, server-authoritative logic goes through Edge Functions** (service role), never direct
  client writes. Precedent = server-side match computation + entitlement grants. The consent exchange
  (section 4) depends on this.

### 1.3 RLS templates (MUST match these exactly)

Auth maps to profile via `(SELECT id FROM user_profiles WHERE auth_id = auth.uid())`. Two templates:

**Couple-scoped (shared) — SELECT/INSERT/UPDATE/DELETE:**
```sql
couple_id IN (
  SELECT couples.id FROM couples
  WHERE couples.user_a IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid())
     OR couples.user_b IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid())
)
```

**User-scoped (private) — SELECT/INSERT/UPDATE, NO partner-read policy:**
```sql
user_id IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid())
```

### 1.4 Migrations

- New `@Model`s are added to `SchemaV1.models` on the commit their file compiles (the project rule).
  `AppMigrationPlan.stages` is empty by design ("no real users yet") — additive models/optional fields
  are lightweight; if this ships to real users first, add a `MigrationStage`.
- New Supabase tables via `apply_migration` **at implementation time** (the MCP is read-only in this
  session). After each DDL change, run `get_advisors(type: security)` to confirm RLS is present — this
  is the gate that catches a table shipped without policies.

### 1.5 The Vault sheet UI

- One `.vaylSheet` presented from the Us layer's Vault row.
- A shared segmented control (promote `LearnSegmented`, the Seg 6 cohesion task) with three segments:
  **Desire Map · Agreements · Log**.
- Every surface uses the canonical `.vaylGlassCard`; every segment has its empty/forming state.

---

## 2. Desire Map (reuse)

Minimal new work. The segment renders:
- "Your map" summary (counts: rated / yes / curious / private) from local `DesireMapEntry`.
- "Where you align" = revealed `DesireMatch` (mutual/adjacent), item names via `ContentLoader.loadDesireItems()`.
- "Locked more" → `PaywallSheet` gated on `EntitlementStore.isCore` (add a `.vault` entry case, or reuse `.reveal`).
- The privacy line ("only you ever see what you keep private") is already true at the RLS layer (1.1).

Reuses `DesireRevealStore`. The "open a conversation" block in the mockup is the consent exchange (section 4).

---

## 3. Agreements (net-new, synced, dual-lock)

**Tier: free** (safety primitive; no `isCore` check).

An agreement is something both partners agreed to, so it follows a **dual-lock**: neither partner can
create, change, or retire one alone. Each such action is *proposed* by one partner and only takes effect
once the other *accepts*. That mutual step is the stability friction (no unilateral or two-seconds-apart
changes). Both partners openly see pending proposals (nothing here is hidden, unlike the consent exchange
in section 4).

**Swift model** `Agreement` (`@Model`, registered in `SchemaV1.models`):
```
id: UUID, coupleId: UUID,
text: String,            // the active, accepted text
proposedText: String?,   // a pending change awaiting the partner; nil when none
status: String,          // "active" | "pendingCreate" | "pendingChange" | "pendingRetire"
proposedBy: UUID?,       // who proposed the pending action (profile id)
createdAt: Date, updatedAt: Date,
isActive: Bool = true    // soft-retire; history is never destroyed
```
The safe word is NOT here; it lives on `Couple.sharedSafeWord` (local) and `couples.shared_safe_word` (remote).

**Supabase table** `agreements`: mirror the model (`id, couple_id → couples, text, proposed_text null, status, proposed_by → user_profiles null, created_at, updated_at, is_active default true`).
**RLS:** couple-scoped (template 1.3) for SELECT + INSERT + UPDATE. Both partners read and write; the dual-lock is enforced in app logic via the proposal state, not by RLS (both legitimately see the row).

**Flow (propose / accept):**
- Propose create: a row with `status = pendingCreate`, `proposedBy = me`, `text` = the proposal. The partner sees it as pending.
- Propose change: the active row gains `proposedText` + `status = pendingChange`, `proposedBy = me`. The live `text` is untouched until accepted.
- Propose retire: `status = pendingRetire`, `proposedBy = me`.
- Accept (the OTHER partner only): commits it. Create/change writes `text`; retire sets `isActive = false`; then `status = active`, clear `proposedText`/`proposedBy`.
- Decline / withdraw: reverts to the prior state. A declined proposal is openly visible (unlike consent).
- Guard: the proposer cannot accept their own proposal (the accept action is gated to `proposedBy != me`).

**Sync:** on any propose or accept, enqueue `SyncTask(taskType: "agreement.upsert")`; the service upserts to `agreements`.

**UI (Agreements segment):** the shared safe word at top, then the active agreements, then any pending proposals flagged "proposed by you, awaiting [partner]" or "[partner] proposed, your call" with accept / decline. An "Add an agreement" affordance opens a small `.vaylSheet` (text + propose). Empty state: "No agreements yet."

---

## 4. Consent exchange (net-new, privacy-critical)

**Tier: rides on Desire Map access** (gated with the paid reveal; not a separate SKU). A free couple can
open conversations on their one free match; opening more requires Core.

> The hard one. The guarantee: **a decline never discloses.** The asker must never be able to
> distinguish "my partner declined" from "still private / not yet answered." A bug here outs a
> partner's boundary, so this is the part that most needs review + a dedicated RLS/edge-function test.

**Why RLS alone is not enough.** A couple-scoped row is readable by both partners, so it can never hold
a "declined" status (the asker would read it). RLS alone also cannot both hide the decline from the asker
AND prevent infinite re-asking. So the flow is **Edge-Function-mediated** (service role), exactly like the
existing match computation and entitlement grants.

**Tables:**
- `consent_requests` (couple-scoped, asker-readable): `id, couple_id, item_id text, asker_id uuid,
  status text check in ('pending','opened'), created_at`. **It never holds 'declined'.** RLS: couple-scoped SELECT.
- Decline is recorded **service-role only** (no asker-readable row) so the server can suppress re-nudging
  the decliner without the asker ever learning. Either a private `consent_responses` row (user-scoped to
  the responder) or a service-role-only column; decided at implementation, but the invariant is: **no
  asker-visible artifact of a decline.**

**Edge Functions (service role):**
- `consent-ask(item_id)` → creates/refreshes a `pending` request, nudges the partner (4.notes). If a prior
  decline exists, it silently no-ops or rate-limits — the asker gets the same "pending" UI either way.
- `consent-respond(request_id, open | decline)`:
  - **open** → set `status = 'opened'`, generate ONE neutral discussion card for both (same card regardless
    of where each landed — never telegraphs the answer).
  - **decline** → record privately (service-role), leave the asker's view indistinguishable from pending.

**Client reads** only what RLS permits: its own `pending`/`opened` requests. The asker's UI shows
"asked · waiting" for both genuinely-pending and declined states — identical by construction.

**Notifications:** RESOLVED (2026-06-24): **in-app only for V1.** The partner sees a pending request when
they next open the Vault (an unobtrusive badge or row), no push. This fits the no-push-spam principle. A
Banner nudge (`UNAuthorizationOptionBanner`, never `…Alert`) can be added later if in-app proves too quiet.

**State machine (asker / responder):** idle → asked(pending) → opened(both) · declined(responder-only, asker still sees pending).

---

## 5. Event Log (net-new, private/shared)

**Tier: free** (personal/couple utility; no `isCore` check).

**Swift model** `EventLogEntry` (`@Model`, registered):
```
id: UUID, authorId: UUID, coupleId: UUID?,        // couple_id set for shared, nil for private
date: Date, title: String, note: String?,
mood: String,                                      // EventMood.rawValue (distinct from PulseTier)
tags: [String],                                    // EventTag.rawValue list, curated set
who: String,                                       // free text, no stored connection records
visibility: String,                                // "private" | "shared"
createdAt: Date
// All entries sync (backup); visibility + RLS, not a sync skip, control who can read.
```

**`EventMood`** (net-new enum, deliberately NOT the four `PulseTier`s, so the two never blur):
proposed `.light, .good, .mixed, .tender, .hard` with NM-appropriate labels (Bryan refines copy).

**`EventTag`** (net-new enum, small curated set, not freeform):
proposed `.date, .play, .metamour, .milestone, .hardConvo, .reconnection` (Bryan refines).

**Storage / privacy — RESOLVED (2026-06-24): remote, with split RLS.** All entries sync to one
`event_log_entries` table (backed up + cross-device); `tags` as `jsonb`. Visibility + RLS, not a sync
skip, control who can read:
- **Shared** rows (`visibility = 'shared'`) are couple-scoped (template 1.3): both partners read.
- **Private** rows (`visibility = 'private'`) are user-scoped: only the author can SELECT them (a partner
  literally cannot), exactly like `desire_ratings`. Backed up but partner-unreadable. Honest copy: "only
  you can ever see this." (Remote storage is not the same as not-private; the RLS is the privacy.)
- One combined SELECT policy: visible if (`visibility = 'shared'` AND couple-membership) OR
  (`visibility = 'private'` AND `author_id` is me). Both `author_id` and `couple_id` columns are present.

**UI (Log segment):** a date-grouped timeline of entries; tapping an entry opens it; an "Add" affordance
opens an entry editor `.vaylSheet` (date, title, note, mood picker, tag chips, who field, and a prominent
**private / shared** toggle). Shared entries show a small shared marker. Author can edit/delete their own.
V1: shared entries are authored by one and visible to both (no dual-perspective/comments — that is later).
Empty state: "No entries yet. Log a date, a night, a feeling."

---

## 6. Build sequence (recommended — the open sequencing call)

Ascend in risk; each is its own segment with a device-verified done condition.

1. **Foundation** — the private/shared sync + RLS templates + the Vault `.vaylSheet` shell with the
   3-segment control + Desire Map reuse wired in. *Done:* Vault opens, Desire Map segment renders.
2. **Agreements (dual-lock):** proves the couple-scoped shared-write path plus a simple, openly-visible
   propose/accept flow. *Done:* one partner proposes an agreement or a change, the other accepts, it syncs
   and both see it (two-device check).
3. **Event Log** — proves the private/shared split. High user value, self-contained. *Done:* private entry
   stays local/unreadable to partner; shared entry appears for both.
4. **Consent exchange** — last, on proven rails: the riskiest RLS + the edge functions + the discussion-card
   generation + notifications, with a dedicated **privacy test** (asker cannot distinguish decline from pending).
   *Done:* the two-device decline-never-discloses test passes.

Rationale for putting the Event Log (3) before the Consent exchange (4): the event log exercises the
private/shared primitive in a low-stakes way first, so the consent exchange is built once that primitive is
proven on device, not simultaneously.

---

## 7. Decisions (all RESOLVED 2026-06-24)

1. **Private event entries:** user-scoped remote, backed up and partner-unreadable via RLS (not device-only); honest "only you" copy. (section 5)
2. **Consent decline record:** implementer's choice (private responder row vs service-role-only column); both preserve the invariant and neither changes user-visible behaviour. (section 4)
3. **Mood + tag sets:** use the proposed `EventMood` / `EventTag` lists; revisit copy later. (section 5)
4. **Agreements editing:** dual-lock; create / change / retire are each proposed by one partner and require the other's acceptance, which is the anti-flip-flop friction. (section 3)
5. **Consent notifications:** in-app only for V1; Banner deferred. (section 4)
6. **Paywall entry** — RESOLVED (2026-06-24): the only gated Vault surface is the Desire Map reveal, so
   reuse `PaywallSheet.Entry.reveal`; add a `.vault` case only if the locked-map copy should differ.

---

## 8. Carry-over constraints

- iOS 26: `UNAuthorizationOptionBanner` (not `…Alert`); no `UIScreen.main`; `WKWebView`/`URLSession` only.
- Tokens only; `.vaylSheet`/`.vaylCover`; canonical `.vaylGlassCard`; empty state on every block.
- 4-layer: View → `MapStore` (or a dedicated `VaultStore`) → services/edge functions → models.
- Supabase MCP is read-only here; the human/CLI applies migrations, then `get_advisors` confirms RLS.
- No em dashes in copy.
- Branch `spec/contextphase-2x3-redesign`; never `git add -A`; never commit `project.pbxproj`.

---

## 9. References

- Visual: `docs/prototypes/map-dashboard.html` (Vault sheet: segmented Desire Map / Agreements + consent flow).
- Reuse: `DesireRevealStore`, `DesireSyncService`, `EntitlementStore`, `PaywallSheet`, `SyncManager`/`SyncTask`,
  `Couple.sharedSafeWord`, `ContentLoader.loadDesireItems()`.
- Schema precedents (prod `vayl` project): `desire_ratings` (private/user-scoped), `desire_matches` +
  `desire_map_status` (couple-scoped), `curated_sessions` (two-sided consent + status machine + service role).
- Mine-visually-only: `PrismView.swift` (dead; privacy-label + agreements treatment).
