# 14 — Map Us Layer + Pulse Partner Data (T3 Seg 4 · Pulse Phase F)

**Goal:** wire real, consent-gated partner Pulse data end to end so the Map tab's **Us** layer stops being a stub, replacing `MapStore.partnerPosition`'s hardcoded `nil` with a fetched 2D circumplex position, and bringing the two prod-only DB objects (`pulse_shared_capacity`, `user_profiles.share_pulse_with_partner`) into a **tracked** migration whose shared row stores an **energy/openness position**, not just a scalar.

---

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

## ⚠️ ONE-SHOT CAVEAT — read before you scope this

**This is the "couple layer" of Pulse, and it is a SCOPE decision.** See **Open decisions #1**.

The **schema + fetch are one-shottable and build-provable.** But the visible payoff — "two real auras +
capsule + split grid in the Us layer" — cannot be proven by a build or by one device. It needs **two
paired, mutually-consenting accounts on two devices** actually logging Pulse check-ins. That proof lives
in **Bryan's device checklist**, not in the Definition of Done.

**Definition of Done for this pass = build-green + migration tracked + push/fetch wired + honest empty
state.** The two-account partner-visibility and consent-gate proof is Bryan's.

If Bryan decides **not** to ship the Us couple-data layer in V1 (Open decision #1), the honest fallback is
already correct in the code: `MapStore.partnerPosition` stays `nil`, `MapUsLayer` shows its no-partner-data
copy, and **no fake capsule ever renders.** You still land **F1 (tracked migration)** regardless, because
the untracked prod drift is a latent break independent of the UI decision (a fresh `db reset` would drop
`pulse_shared_capacity` and `share_pulse_with_partner` and silently break the sync code that already ships).

---

## Context Fable needs

- **What this is.** The Map tab has a **Me / Us** lens toggle (the header name-toggle in `MapView.swift`).
  The **Us** layer (`Vayl/Features/Map/Components/MapUsLayer.swift`) is designed to render **two auras** (you
  + partner) inside a shared `PulseField`, wrapped by a `PulseCapsule` (the "distance between you" band),
  with a distance-derived headline and a paired split-grid of the last-logged quadrants. It is **fully built
  and preview-correct** — its previews pass a literal `partnerPosition` — but at runtime it receives
  `store.partnerPosition`, which is **hardcoded `nil`** (`MapStore.swift:75`, a "Segment 7" TODO). So today
  the capsule, distance headline, `You/Partner` labels, and paired grid **never render** in the running app.

- **The exact stub to kill.** `MapStore.swift:74-75`:
  ```swift
  /// The partner's current circumplex position. nil until Segment 7 wires PulseSyncService.
  private(set) var partnerPosition: PulsePosition? = nil
  ```
  `MapView.swift:214` already threads it into the Us layer: `partnerPosition: store.partnerPosition`. Nothing
  assigns it. This plan makes `MapStore` **fetch** it (via `PulseSyncService`) and publish it.

- **The service seam already exists — but half of it has ZERO callers.** `PulseSyncService`
  (`Vayl/Core/Services/PulseSyncService.swift`) has four methods:
  - `pushCurrentCapacity(score:)` — **HAS a caller**: `PulseStore.add(_:)` (`PulseStore.swift:43`) fires it on
    every check-in. It pushes a **scalar** `capacity_score`.
  - `fetchPartnerCapacity() -> Double?` — **ZERO callers.** Returns a scalar.
  - `fetchSharing() -> Bool` — **ZERO callers.**
  - `setSharing(_:) async` — **ZERO callers.** (Note: there is a *separate*, live sharing-write path —
    `ProfileService.updateSharePulse(_:)` → `SyncManager.pushSharePulse(_:)` — that already writes
    `share_pulse_with_partner`. See F2's coordination note; do **not** create a third writer.)
  The Phase-F handoff explicitly kept these partner methods as "seed for Phase F." This plan **wires the
  fetch and upgrades it from scalar to 2D position.**

- **The correctness call (why a scalar can't drive the Us view).** `pushCurrentCapacity` sends a single
  `capacity_score` (1…4). But `PulsePosition` (`Vayl/Core/Models/PulsePosition.swift`) is **2D**: `energy`
  + `openness` (each 0…1). The circumplex places a point by *both* axes; a scalar collapses it onto the
  energy line with `openness` guessed at mid (see `PulseEntry.resolvedPosition`, which reconstructs a lost
  `openness` as `0.5`). **A scalar literally cannot express which quadrant the partner is in.** So the shared
  row **must store `energy` + `openness`** (the position), not only `capacity_score`. This is the load-bearing
  decision of the whole plan.

- **The prod-drift (why F1 is not optional).** `pulse_shared_capacity` (table) and
  `user_profiles.share_pulse_with_partner` (column) **exist only in prod** and in **no tracked migration**
  (`grep` over `supabase/migrations/` finds zero hits; only `supabase/tests/README.md` mentions them; the
  baseline has `0` occurrences of `share_pulse_with_partner`). A fresh `supabase db reset` would recreate a
  DB **without** them, and the already-shipping `PulseSyncService.pushCurrentCapacity` + `ProfileService.
  updateSharePulse` would then fail silently (they `try?` / catch non-fatally). F1 brings both into a tracked,
  **idempotent** migration.

- **Canonical patterns to imitate.**
  - **Migration + couple-scoped RLS:** model the new migration on
    `supabase/migrations/20260617000000_desire_map_backend.sql` (idempotent `create table if not exists`,
    `enable row level security`, `drop policy if exists` then `create policy … for select to authenticated
    using (couple_id in (select couples.id … where couples.user_a in (select id from user_profiles where
    auth_id = auth.uid()) or couples.user_b in (…)))`). This is the **exact** couple-membership predicate
    used across `desire_map_status`, `consent_requests`, and `couples`' own policies (baseline
    lines 451-483) — reuse it verbatim.
  - **Store fetch pattern:** model the async fetch on `MapStore.loadServerAlignData(...)` (already in
    `MapStore.swift:250`) — an `async` private method awaited from `load(...)` via `Task { … }`, assigning
    `private(set)` state.
  - **Position math already exists:** `PulseAnswers.position(nervousSystem:focus:feeling:)`
    (`PulseAnswers.swift:110`) builds a `PulsePosition` from answers; the entry already carries a stored
    `position` (`PulseEntry.position`). You are **transporting** a `PulsePosition`, not recomputing it.

---

## Files

### Create

| File | Responsibility |
|---|---|
| `supabase/migrations/20260701000000_pulse_shared_position.sql` | Bring `pulse_shared_capacity` + `user_profiles.share_pulse_with_partner` into a **tracked, idempotent** migration; **add `energy` + `openness` columns** to the shared row; couple-scoped consent-gated SELECT RLS; service-safe upsert/delete by owner. |
| `supabase/tests/pulse_shared_position_test.sql` | pgTAP: table + columns exist, RLS enabled, partner reads the row **only when both share**, a decline/off hides it. (Author-run; not a build gate.) |

### Modify

| File | Line anchor | Change |
|---|---|---|
| `Vayl/Core/Services/PulseSyncService.swift` | whole file (structs `CapacityRow`/`CapacityUpsert` ~:34-47; `pushCurrentCapacity` :61; `fetchPartnerCapacity` :85) | Upgrade the shared row from scalar to **2D position**: `pushCurrentPosition(_:)` now sends `energy`/`openness` (keeps `capacity_score` for back-compat); add `fetchPartnerPosition() -> PulsePosition?`. Keep `fetchSharing`/`setSharing` as-is. |
| `Vayl/Features/Pulse/Store/PulseStore.swift` | `add(_:)` :40-44 | Push the entry's **position** (`entry.resolvedPosition`), not the scalar, so the partner's circumplex point is real. |
| `Vayl/Features/Map/MapStore.swift` | :74-75 (stub), `load(...)` :102, add async method near :250 | Delete the `nil` TODO; add `loadPartnerPosition(appState:)` that calls `PulseSyncService.fetchPartnerPosition()` and assigns `partnerPosition`; call it from the load path (gated on `linkState == .linked`). |
| `Vayl/Features/Map/MapView.swift` | `.task` :109-113 | Await `store.loadPartnerPosition(appState:)` alongside the existing `loadPartner`. |

### Delete

_None._ (The `fetchPartnerCapacity`/`fetchSharing`/`setSharing` seed methods stay; `fetchPartnerCapacity`
is superseded by `fetchPartnerPosition` but keeping it is harmless and it may still back a future scalar
consumer. If you prefer zero dead code, delete `fetchPartnerCapacity` + its `CapacityRow`-only usage — see
Open decision #3.)

---

## Build steps (segments)

### Segment 1 (F1) — Reconcile the schema, store the 2D position

**One thing:** a tracked, idempotent migration that (a) adds the two prod-only objects and (b) makes the
shared row carry `energy`/`openness`, with couple-scoped consent-gated RLS.

**Shape decision (load-bearing):** the shared row stores the **position** (`energy`, `openness`), keeping
`capacity_score` nullable for back-compat with the older scalar writer. The Us layer reads `energy`/`openness`;
the legacy `capacity_score` is derivable (`1 + energy*3`, cf. `PulsePosition.capacityScore`) and no longer the
source of truth.

**Consent gate:** the SELECT policy lets a caller read a row that is either **their own** OR **their partner's
`AND` that partner has `share_pulse_with_partner = true`**. "Both consent" is enforced two ways working
together: the writer only *inserts* a row while their own `share_pulse_with_partner` is true (and *deletes* it
when they turn sharing off — already in `pushCurrentCapacity`/`setSharing`), and the reader's RLS re-checks the
owner's flag. So a partner sees your position only while **you** are sharing; you see theirs only while **they**
are. There is no way to read a non-sharing partner's row.

Create `supabase/migrations/20260701000000_pulse_shared_position.sql`:

```sql
-- Pulse Phase F1 — Track the (until-now prod-only) shared-capacity objects and upgrade the
-- shared row from a 1D capacity scalar to the 2D circumplex position the Map "Us" layer needs.
--
-- DRIFT NOTE: `public.pulse_shared_capacity` and `public.user_profiles.share_pulse_with_partner`
-- were applied directly to prod (never in a tracked migration). A fresh `supabase db reset` would
-- drop them and silently break PulseSyncService.pushCurrent* / ProfileService.updateSharePulse.
-- This migration is fully idempotent, so it reconciles prod (via `migration repair --status applied`)
-- AND makes a clean reset reproduce the schema. Apply on a Supabase branch, run the pgTAP test,
-- then merge. Convention: couple membership via user_profiles.auth_id = auth.uid().
--
-- THE INVARIANT — a partner reads your position ONLY while you are sharing:
--   * The row is written only when the owner's share_pulse_with_partner = true, and deleted when they
--     turn it off (client path in PulseSyncService/ProfileService).
--   * The SELECT policy independently re-checks: caller sees own row always, and the partner's row only
--     when that partner's share_pulse_with_partner is true. Both conditions must hold. No fake data path.

-- 1) The share preference (prod-only column → tracked). Default TRUE = on by default (matches
--    fetchSharing()'s `?? true` and the existing writers).
alter table public.user_profiles
  add column if not exists share_pulse_with_partner boolean not null default true;

-- 2) The shared position row. One row per profile (upsert on profile_id). Stores the 2D position;
--    capacity_score kept nullable for back-compat with the older scalar writer.
create table if not exists public.pulse_shared_capacity (
  profile_id      uuid primary key references public.user_profiles(id) on delete cascade,
  couple_id       uuid references public.couples(id) on delete cascade,
  energy          double precision not null default 0.5,
  openness        double precision not null default 0.5,
  capacity_score  double precision,
  updated_at      timestamptz not null default now()
);

-- If the table pre-exists in prod with only capacity_score, add the position columns idempotently.
alter table public.pulse_shared_capacity
  add column if not exists energy   double precision not null default 0.5;
alter table public.pulse_shared_capacity
  add column if not exists openness double precision not null default 0.5;
alter table public.pulse_shared_capacity
  add column if not exists couple_id uuid references public.couples(id) on delete cascade;
alter table public.pulse_shared_capacity
  add column if not exists updated_at timestamptz not null default now();
alter table public.pulse_shared_capacity
  alter column capacity_score drop not null;

alter table public.pulse_shared_capacity enable row level security;

-- SELECT: own row, OR the partner's row while THAT partner is sharing. Consent is mutual by
-- construction (each side writes only while sharing; each side's RLS re-checks the owner's flag).
drop policy if exists "pulse_shared_read_self_or_sharing_partner" on public.pulse_shared_capacity;
create policy "pulse_shared_read_self_or_sharing_partner"
  on public.pulse_shared_capacity for select to authenticated
  using (
    -- your own row
    profile_id in (select id from public.user_profiles where auth_id = auth.uid())
    or
    -- your partner's row, ONLY while they share
    profile_id in (
      select owner.id
      from public.user_profiles owner
      join public.couples c
        on owner.id in (c.user_a, c.user_b)
      where owner.share_pulse_with_partner = true
        and c.id in (
          select couples.id from public.couples
          where couples.user_a in (select id from public.user_profiles where auth_id = auth.uid())
             or couples.user_b in (select id from public.user_profiles where auth_id = auth.uid())
        )
        and owner.id not in (select id from public.user_profiles where auth_id = auth.uid())
    )
  );

-- INSERT/UPDATE: a caller may write ONLY their own row (upsert on profile_id from the client).
drop policy if exists "pulse_shared_write_own" on public.pulse_shared_capacity;
create policy "pulse_shared_write_own"
  on public.pulse_shared_capacity for insert to authenticated
  with check (profile_id in (select id from public.user_profiles where auth_id = auth.uid()));

drop policy if exists "pulse_shared_update_own" on public.pulse_shared_capacity;
create policy "pulse_shared_update_own"
  on public.pulse_shared_capacity for update to authenticated
  using (profile_id in (select id from public.user_profiles where auth_id = auth.uid()))
  with check (profile_id in (select id from public.user_profiles where auth_id = auth.uid()));

-- DELETE: clear your own row when you turn sharing off.
drop policy if exists "pulse_shared_delete_own" on public.pulse_shared_capacity;
create policy "pulse_shared_delete_own"
  on public.pulse_shared_capacity for delete to authenticated
  using (profile_id in (select id from public.user_profiles where auth_id = auth.uid()));
```

**done:** the migration file exists, is idempotent (`create … if not exists` / `add column if not exists` /
`drop policy if exists`), reconciles the prod drift, and stores `energy`/`openness`. (Applying it to a branch +
the pgTAP proof is Bryan's, not a build gate.)

---

### Segment 2 (F2a) — Push and fetch the 2D position

**One thing:** `PulseSyncService` sends and reads a `PulsePosition`, not a scalar.

In `Vayl/Core/Services/PulseSyncService.swift`, replace the scalar row structs and both position methods.
Change the decode/encode structs (`CapacityRow` ~:34-41, `CapacityUpsert` ~:43-47) to carry the axes:

```swift
    private struct PositionRow: Decodable {
        let profileId: UUID
        let energy: Double
        let openness: Double
        enum CodingKeys: String, CodingKey {
            case profileId = "profile_id"
            case energy
            case openness
        }
    }

    private struct PositionUpsert: Encodable {
        let profile_id: String
        let couple_id: String?
        let energy: Double
        let openness: Double
        let capacity_score: Double   // back-compat: 1 + energy*3
    }
```

Replace `pushCurrentCapacity(score:)` (:61) with a position-based push. It keeps the same
sharing-gate + clear-when-off behavior, just carries both axes:

```swift
    /// Broadcast the latest circumplex POSITION when sharing is on; clear it when off so nothing
    /// lingers server-side. Fire-and-forget from the check-in. RLS gates partner visibility.
    func pushCurrentPosition(_ position: PulsePosition) async {
        guard let profile = await currentProfile() else { return }

        if profile.sharePulseWithPartner {
            let row = PositionUpsert(
                profile_id: profile.id.uuidString,
                couple_id: profile.coupleId?.uuidString,
                energy: position.energy,
                openness: position.openness,
                capacity_score: position.capacityScore   // legacy scalar, still written
            )
            _ = try? await supabase
                .from("pulse_shared_capacity")
                .upsert(row, onConflict: "profile_id")
                .execute()
        } else {
            _ = try? await supabase
                .from("pulse_shared_capacity")
                .delete()
                .eq("profile_id", value: profile.id.uuidString)
                .execute()
        }
    }
```

Replace `fetchPartnerCapacity()` (:85) with a position fetch (RLS already yields only own + a *sharing*
partner's row; the partner's is the one that isn't ours):

```swift
    /// The partner's current circumplex POSITION, or nil (not paired / not shared / not yet logged).
    /// RLS returns only rows the caller may see (own + a sharing partner's).
    func fetchPartnerPosition() async -> PulsePosition? {
        guard let profile = await currentProfile() else { return nil }
        let rows: [PositionRow]? = try? await supabase
            .from("pulse_shared_capacity")
            .select("profile_id, energy, openness")
            .execute()
            .value
        guard let partner = rows?.first(where: { $0.profileId != profile.id }) else { return nil }
        return PulsePosition(energy: partner.energy, openness: partner.openness)
    }
```

Leave `fetchSharing()` (:98) and `setSharing(_:)` (:103) **unchanged** — `setSharing`'s off-branch already
deletes the row, which is exactly the "stop sharing → clear the position" behavior F1's RLS assumes.

**done:** `PulseSyncService` compiles with `pushCurrentPosition(_:)` + `fetchPartnerPosition()`; the shared
row round-trips `energy`/`openness`.

---

### Segment 3 (F2b) — Push the real position from the check-in

**One thing:** the check-in broadcasts the 2D position instead of the scalar.

In `Vayl/Features/Pulse/Store/PulseStore.swift`, `add(_:)` (:40-44), swap the scalar push for the position:

```swift
    func add(_ entry: PulseEntry) {
        let cal = Calendar.current
        entries.removeAll { cal.isDate($0.date, inSameDayAs: entry.date) }
        entries.append(entry)
        entries.sort { $0.date < $1.date }
        save()
        // Broadcast current POSITION to the partner (if sharing is on). Fire-and-forget; local save
        // above is the source of truth. RLS gates partner visibility.
        let position = entry.resolvedPosition
        Task { await PulseSyncService.shared.pushCurrentPosition(position) }
    }
```

(`entry.resolvedPosition` always yields a `PulsePosition` — the stored 2D field for redesigned entries, or a
reconstructed one for legacy entries. `PulseStore` stays UserDefaults-local; only the single current position
is ever sent.)

**done:** every check-in pushes `energy`/`openness`; no scalar-only path remains at the live call site.

---

### Segment 4 (F2c) — MapStore fetches and publishes `partnerPosition`

**One thing:** kill the `nil` stub; fetch the partner's position and publish it, gated on being linked.

In `Vayl/Features/Map/MapStore.swift`, replace the stub (:74-75):

```swift
    // MARK: - Pulse positions

    /// The partner's current circumplex position, fetched from the shared row via PulseSyncService.
    /// nil when unpaired, not shared by the partner, or the partner hasn't checked in yet — the Us
    /// layer treats nil as its honest "no partner data" empty state (no fake capsule).
    private(set) var partnerPosition: PulsePosition? = nil
```

Add the fetch method (place it near `loadServerAlignData`, ~:296, following that method's async/`private(set)`
pattern):

```swift
    /// Async: fetches the partner's current Pulse position for the Us layer. Consent-gated at the DB
    /// (RLS returns the partner's row only while THEY share). Leaves partnerPosition nil on any miss —
    /// the Us layer's empty state is honest, never a fabricated capsule.
    func loadPartnerPosition(appState: AppState) async {
        guard appState.linkState == .linked else {
            partnerPosition = nil
            return
        }
        partnerPosition = await PulseSyncService.shared.fetchPartnerPosition()
        #if DEBUG
        // Dev-only: without a live sharing partner, seed a position so the Us capsule can be seen in
        // the simulator. Never compiled into release — release stays honest (nil → empty state).
        if partnerPosition == nil {
            partnerPosition = PulsePosition(energy: 0.28, openness: 0.30)
        }
        #endif
    }
```

> **Solo/release honesty (per Global context):** the `#if DEBUG` seed must **never** leak into release —
> it is wrapped exactly like `loadPartner`'s existing `#if DEBUG partnerName = "Alex"` block (`MapStore.swift:
> 121-125`), so release behavior is `nil → honest empty state`. Do not remove the `#else`-implied release path
> (there is no `#else` needed here because the release value is already `nil`).

**done:** `MapStore.partnerPosition` is assigned from the service; the "Segment 7 TODO" comment is gone; release
build yields `nil` when there's no consenting partner.

---

### Segment 5 (F2d) — MapView awaits the fetch

**One thing:** the Us layer receives real data on appear.

In `Vayl/Features/Map/MapView.swift`, `.task` (:109-113), add the await next to the existing partner-name load:

```swift
        .task {
            store.load(appState: appState, context: modelContext, isCore: entitlements.isCore)
            await vaultStore.loadDesire(appState: appState, context: modelContext, isCore: entitlements.isCore)
            await store.loadPartner(appState: appState)
            await store.loadPartnerPosition(appState: appState)
        }
```

`MapView.swift:214` already threads `partnerPosition: store.partnerPosition` into `MapUsLayer`; no view change
is needed there. `MapUsLayer` already renders the two auras + `PulseCapsule` + `You/Partner` labels + paired
grid **only** `if let partner = partnerPosition` (`MapUsLayer.swift:95, 125`), and shows
`"Partner hasn't checked in yet today."` when `nil` (:47-48) — so the honest empty state is already correct.

**done:** with a real fetched position, the running Us layer shows two auras + capsule + split grid; with
`nil`, it shows the honest no-partner copy and **no** capsule.

---

### Segment 6 (F2e) — The sharing toggle: Store method + read (coordination)

**One thing:** expose *where* the sharing toggle reads/writes, so the Settings surface can bind it — without
creating a duplicate writer.

**Coordination note — DO NOT build a second write path.** There are already two write paths for
`share_pulse_with_partner`:
1. **The live one:** `ProfileService.updateSharePulse(_:)` (`ProfileService.swift:235`) →
   `SyncManager.pushSharePulse(_:)` (`SyncManager.swift:152`). This updates the column by `auth_id`.
2. **The seed one:** `PulseSyncService.setSharing(_:)` (`PulseSyncService.swift:103`), which ALSO deletes the
   shared row when turned off — the behavior F1's RLS relies on.

**The correct toggle for Settings is `PulseSyncService.setSharing(_:)`**, because it does the full job
(update the flag **and** clear the broadcast row on off). The `ProfileService`/`SyncManager` path only updates
the flag and does **not** clear the row, so on its own it would leave a stale position readable until the next
push. **Recommendation:** the Settings toggle calls `PulseSyncService.setSharing(_:)` and reads
`fetchSharing()`; leave `ProfileService.updateSharePulse` in place (it's used by `SyncManager`'s broader
profile sync) but do not route the user-facing Pulse-sharing toggle through it.

**Scope boundary — the Settings *surface* is Plan 04, not this plan.** This plan does **not** add a row to the
Settings screen. It only (a) confirms the Store method the toggle will call (`PulseSyncService.setSharing`) and
(b) confirms the read (`PulseSyncService.fetchSharing`). If Plan 04 hasn't landed a Settings Pulse-sharing row
yet, that is Plan 04's job; here, just ensure the seam is callable and note the dependency in **Open
decisions #2**. Do **not** wire a toggle into a random view to "prove" it — that violates the presentation
grammar and the plan's scope.

**done:** the sharing toggle's Store method (`PulseSyncService.setSharing`) and read (`fetchSharing`) are
confirmed callable; no duplicate writer is introduced; the Settings row itself is explicitly deferred to
Plan 04 with the dependency flagged.

---

## Definition of Done (build-green)

- [ ] `supabase/migrations/20260701000000_pulse_shared_position.sql` exists, is **idempotent**, brings both
      prod-only objects (`pulse_shared_capacity`, `user_profiles.share_pulse_with_partner`) into tracking, and
      the shared row carries `energy` + `openness` (not only `capacity_score`).
- [ ] Couple-scoped, consent-gated SELECT RLS: a caller reads own row always, partner's row **only while the
      partner shares**; write/delete scoped to own row.
- [ ] `PulseSyncService` compiles with `pushCurrentPosition(_:)` + `fetchPartnerPosition() -> PulsePosition?`;
      the shared row round-trips both axes.
- [ ] `PulseStore.add(_:)` pushes `entry.resolvedPosition` (2D), not the scalar.
- [ ] `MapStore.partnerPosition` is assigned from `PulseSyncService.fetchPartnerPosition()` via
      `loadPartnerPosition(appState:)`; the "Segment 7 TODO" `nil` stub is gone; **release** yields `nil` with
      no consenting partner (the `#if DEBUG` seed never compiles into release).
- [ ] `MapView.task` awaits `store.loadPartnerPosition(appState:)`.
- [ ] With `partnerPosition == nil`, `MapUsLayer` shows the honest "Partner hasn't checked in yet today." copy
      and renders **no** capsule / labels / paired grid (already true — do not regress it).
- [ ] No new second writer for `share_pulse_with_partner`; the user-facing toggle seam is
      `PulseSyncService.setSharing`/`fetchSharing`.
- [ ] Project builds green. No raw tokens introduced in any View (this plan touches Store/Service/migration —
      no new View literals).

---

## Bryan verifies on device (the part a build can't prove)

- [ ] **Two accounts, two devices, both consenting.** Pair account A and B. Both toggle Pulse-sharing **on**.
      Both complete a Pulse check-in. On A's Map → **Us**: two real auras appear, the `PulseCapsule` spans
      between them, the `You / <partner>` labels sit at the right orbs, and the distance headline reads
      sensibly. Repeat symmetrically on B.
- [ ] **Consent gate — off means gone.** B turns Pulse-sharing **off**. On A's Map → Us, B's aura + the
      capsule **disappear**; A sees the honest empty copy. (Confirms the delete-on-off + RLS both hold.)
- [ ] **No fake data, ever.** Unpaired, or a partner who has never checked in, or a partner sharing-off →
      the Us layer shows the empty copy and **no capsule**. Fresh install, no `#if DEBUG` seed in the release
      build.
- [ ] 🎚️ **Distance headline threshold.** "A wide day between you" vs "Close today" flips at `distance > 0.45`
      (`MapUsLayer.swift:43`). Tune the threshold on device against real two-person positions.
- [ ] 🎚️ **Aura-label offset.** `You/Partner` tags sit at `fieldSize * 0.18` from the orb center
      (`MapUsLayer.swift:141`). Confirm it reads clean with two real orbs (they can overlap when partners are
      close).
- [ ] **DB reconciliation.** Apply the migration on a Supabase branch, run the pgTAP test, then
      `supabase migration repair --status applied 20260701000000` against prod (prod already has the objects;
      this records the history so a future `db reset` reproduces them).

---

## Constraints / do-not-touch

- **No fake partner data in release.** The only seed is `#if DEBUG`-fenced in `loadPartnerPosition`, exactly
  mirroring the existing `loadPartner` DEBUG block. Release with no consenting partner → `partnerPosition == nil`
  → honest empty state.
- **The 2D position is the shape.** Never let the Us layer be driven by a scalar `capacity_score` — a scalar
  cannot express the partner's quadrant. Store and fetch `energy`/`openness`.
- **Consent is mutual and DB-enforced.** Do not add any client-side shortcut that reads a partner's position
  without the RLS gate. The row exists only while the owner shares; RLS re-checks it.
- **One writer for the sharing flag's row-clear.** Route the user-facing Pulse-sharing toggle through
  `PulseSyncService.setSharing` (it clears the broadcast row on off). Do not add a third writer; do not
  silently reroute `SyncManager.pushSharePulse`.
- **Do not touch `MapUsLayer.swift`'s rendering.** It is already correct for both the present-partner and
  `nil` cases. This plan feeds it data; it does not restyle it.
- **`PulseStore` stays device-local.** Only the single current position is ever sent; full history remains in
  UserDefaults (`pulse.entries.v1`). Do not server-sync the history here (that's the separate persistence
  decision).
- **Migration idempotency is mandatory** (`if not exists` / `drop policy if exists`) so it reconciles a prod
  that already has the objects.

---

## Open decisions (each with a recommended default — proceed on the default, flag it)

1. **Ship the Us couple-data layer in V1, or Me-only + honest empty state?** _(the biggest scope lever)_
   This is the top-level SCOPE call flagged in the caveat and in the Phase-F handoff. The full couple layer
   needs two consenting accounts on two devices to *prove*, and adds a live cross-user data dependency.
   **Recommended default:** land **F1 (the tracked migration) unconditionally** — it fixes a latent prod-drift
   break regardless of the UI decision — and land F2 (fetch + wire) too, since it degrades safely to the honest
   empty state when there's no partner. If Bryan wants to defer the *visible* Us couple view for V1, the code
   already hides everything behind `partnerPosition == nil`, so deferral is a product/marketing choice, not a
   code change. **Proceeding on: build F1 + F2; honest empty state covers the deferral case.**

2. **Settings sharing-toggle row — this plan or Plan 04?** The toggle *surface* belongs to the Settings plan
   (Plan 04). **Recommended default:** this plan confirms and exposes the seam
   (`PulseSyncService.setSharing`/`fetchSharing`) but does **not** add a Settings row; Plan 04 binds it.
   **Proceeding on: seam only; Settings row deferred to Plan 04 with the dependency noted.**

3. **Keep or delete the now-superseded scalar seed methods** (`fetchPartnerCapacity` + `CapacityRow`).
   `fetchPartnerPosition` replaces `fetchPartnerCapacity`; the scalar method has zero callers after this plan.
   **Recommended default:** **delete `fetchPartnerCapacity`** (and its scalar-only decode) to avoid dead code,
   since Plan 01 (dead-code purge) is the house style; keep `pushCurrentPosition`, `fetchSharing`, `setSharing`.
   **Proceeding on: delete `fetchPartnerCapacity`; keep the rest.** (Low-risk; if Bryan wants a scalar consumer
   later, `PulsePosition.capacityScore` derives it.)

4. **`updated_at` freshness / staleness.** The plan stores `updated_at` but the Us layer treats any present
   partner row as "today." A partner's position could be days old. **Recommended default:** ship without a
   staleness filter in V1 (the copy already says "today" loosely; carry-forward is the Pulse model's own
   convention per `PulseHistory.pairedLastLogged`). **Proceeding on: no staleness gate in V1; revisit if the
   "today" claim feels wrong on device.**
