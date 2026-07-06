# Pulse — Full Feature Audit + Plan — 2026-07-01

Requested before bed: audit the whole Pulse loop end-to-end (Home entry, Map entry, Supabase
persistence, Home/Map overlap) and produce a plan for finishing the Map Me/Us widgets, plus
flag any other blind spots before this feature is called done. Verified from source by 4
parallel agents reading the actual code, not from memory of earlier plan docs.

**Read this first if short on time:** Part 2's four P0/P1 items. Everything else is detail.

---

## PART 1 — WHAT'S CONFIRMED WORKING

- **Single shared `PulseStore`.** `VaylApp.swift:16,49` creates exactly one instance and injects
  it app-wide via `.environment(pulseStore)`. Home, Map-Me, Map-Us, and the check-in cover all
  read the same instance via `@Environment(PulseStore.self)` — no divergent copies in production
  code (only `#Preview` blocks construct their own, which is correct/expected).
- **Home check-in works end-to-end, no gates.** `HomePulseRail`'s "Check in" pill →
  `HomeDashboardView.swift:343-346` (`showPulseCheckIn = true`) → `.vaylCover` at
  `HomeDashboardView.swift:324-326` → `PulseCheckInView`. No entitlement/pairing gate anywhere
  in the chain.
- **Map "Me" check-in works end-to-end, no gates.** Same pattern: `MapPulseHero`'s `onCheckIn` →
  `MapView.swift:203-206` (`startCheckIn()`) → `.vaylCover` at `MapView.swift:58-60`. Identical
  presentation style (`confirmOnExit: false`) to Home.
- **Cross-tab reactivity is genuinely live.** Because `PulseStore` is `@Observable` and truly
  singular (not re-fetched), a check-in from Home is reflected on Map instantly with no manual
  refresh needed, and vice versa — this part of the architecture is clean.
- **Q3 ("Defensive"/"Anxious") persists correctly** — no data loss there, confirmed by the
  data-integrity agent.

---

## PART 2 — GAPS FOUND (P0 → P2)

| # | Gap | Severity |
|---|-----|----------|
| G1 | Q4 (capacity) answer is silently discarded — never stored anywhere | **P0** |
| G2 | Zero check-in history ever reaches Supabase — 100% local, lost on reinstall/device switch | **P0** |
| G3 | Map's "Us" lens has **no check-in entry point at all** | **P1** |
| G4 | `MapUsLayer`'s history grid hardcodes `partner: []` — partner column always empty | **P1** |
| G5 | Partner sync only pushes a 1D scalar; Us needs 2D position — unbuilt migration | **P1** |
| G6 | Us lens `partnerPosition` still fully unwired (hardcoded `nil`) | **P1** |
| G7 | The "your map" time-window trail (Plan 19) doesn't exist in code | **P1** |
| G8 | Home gates on *today's* entry; Map shows *last* entry regardless of age | **P2** |
| G9 | Partner-capacity-read path is 100% dead code (zero callers) | **P2** |
| G10 | `isDateInToday` / current-position logic duplicated across files | **P2** |
| G11 | `pulse_shared_capacity` RLS can't be verified — table untracked in migrations | **P2** |

### G1 — Q4's answer is discarded (real regression, not a design choice)

`PulseCheckInView.swift`, `commitEntry()`:
```swift
guard
    let nervousSystem = answers[0],
    let focus         = answers[1],
    let feeling       = answers[2],
    let speed         = answers[4]     // ← jumps straight from index 2 to 4
else { ... }
```
`answers[3]` (Q4, "How much do you have to give right now?") is read by `selectPill` only to
advance the flow, then never referenced again — `grep -n "answers\[3\]"` returns zero hits in
the file. `PulseEntry` has no field that could hold it either; the one field shaped like it
could (`glowColor: PulseCapacityColor`) is now derived purely from Q1-3 position
(`pos.quadrant.capacityColor`), not from the Q4 answer.

**This directly contradicts two of my own comments** written earlier today:
- `PulseAnswers.swift:76-79`: *"Q4: solo capacity/bandwidth — no axis effect (recorded metadata
  only...)"* — false, nothing records it.
- `PulseCheckInView.swift:12`: *"Q4 (capacity) and Q5 (speed) are recorded but don't affect
  position"* — Q5 is recorded; Q4 is not.
- `PulseEntry.swift:21` even carries a stale comment: `var glowColor: PulseCapacityColor // Q4
  answer` — no longer true.

**This is a real bug from today's rework**, not a deliberate scope cut — the comments prove the
intent was to keep it as reflective metadata, and the implementation just doesn't. Needs either
a `capacity: String` field added to `PulseEntry` (threaded through the guard + init), or an
explicit decision to drop Q4 entirely (in which case the false comments need correcting and the
question itself is arguably pointless to ask). **Recommend: add the field** — the question was
just added today specifically because it's the "removed the clinical 'holding space' phrasing"
rewrite; dropping the answer it collects would undercut the reason it exists.

### G2 — No check-in history reaches Supabase, at all

`PulseStore.add()` writes locally to `UserDefaults` (key `pulse.entries.v1`) and fires exactly
one Supabase side effect: `PulseSyncService.pushCurrentCapacity(score:)`, which upserts
`{profile_id, couple_id, capacity_score}` — **a single scalar** — into `pulse_shared_capacity`,
gated on `user_profiles.share_pulse_with_partner`. That row is **overwritten on every check-in**
(not historical) and **deleted outright if sharing is off**. Nothing else — not the 5 Q&A
answers, not the resolved 2D position, not the date — ever leaves the device.

**Concretely: a reinstall or device switch loses 100% of check-in history.** There is no
recovery path. This is worth a real product decision — is local-only acceptable for V1 (per the
"online-first" architecture memory, Pulse was deliberately scoped local-only originally), or does
losing a user's whole Pulse history on device loss need fixing before this ships as a finished
feature? I'd treat this as a decision for you, not something to silently fix — it's a real
scope/cost tradeoff (SwiftData + sync infra vs. "it's fine, it's ambient data").

### G3 — Map's "Us" lens has no check-in entry point

`MapUsLayer`'s full parameter list is `stats, align, lockedAlignCount, onOpenVault,
partnerPosition, partnerName` — no `onCheckIn`. `MapPulseHero` (which owns the check-in
affordance) is instantiated only inside `MapView.meLayer`; `usLayer` never touches it. **A user
looking at the Us lens has no way to check in without first switching to Me.** This is almost
certainly what "missing on Map" refers to — Us is arguably the more natural place to want to
check in from ("how are we doing"), and it's currently a dead end.

### G4 — Us history grid's partner column is hardcoded empty

Independent of G6 (below): `MapUsLayer.swift:56` calls
`PulseHistory.pairedLastLogged(mine: pulse.entries, partner: [])` — the `partner:` argument is a
**hardcoded empty array**, not `partnerPosition`-derived. Even once G5/G6 are fixed and a live
partner position exists for *today*, the **historical** paired grid will still show every
partner cell as blank, because it was never wired to real partner history at all. This needs its
own fix, not just "wire up partnerPosition."

### G5 — Partner sync is a scalar; Us needs a 2D position

`pushCurrentCapacity` sends only `capacity_score` (Double). `MapUsLayer`'s two-aura field needs a
full `PulsePosition` (energy + openness) to place the partner's orb. The existing sync mechanism
architecturally cannot supply what Us needs — this isn't a "call one more method" fix, it's a
schema + sync-shape change (energy/openness columns, not a capacity scalar). Plan 14
(`docs/fable-plans/14-map-us-layer-and-pulse-partner.md`) already specs this migration in detail
— **confirmed it has never been applied**: no `supabase/migrations/*pulse*` file exists in the
repo, and the plan's proposed `20260701000000_pulse_shared_position.sql` doesn't exist either.

### G6 — Us lens `partnerPosition` is still hardcoded nil

`MapStore.swift:75`: `private(set) var partnerPosition: PulsePosition? = nil` — no setter, never
assigned anywhere in the codebase (full-repo grep confirms). `MapView`'s `.task` calls
`store.loadPartner(appState:)`, but that only fetches the partner's *name*, never touches
`partnerPosition`. `MapUsLayer` is fully built to render the moment this becomes non-nil — the
render side is done, only the fetch/assignment is missing. This is Plan 14's core scope, still
unbuilt.

### G7 — The "your map" time-window trail doesn't exist in code

Plan 19 (`docs/fable-plans/19-map-pulse-integration-finish.md`) specs adding faded time-window
markers (1w/1m/3m echoes) to `MapFieldSheet`. Checked directly: `PulseHistory.swift` only
defines `lastLogged` and `pairedLastLogged` — no `TimeWindowMarker` type or
`nearestOnOrBefore` function exists anywhere in the tree. **Plan 19 was written but never
executed.** Worth deciding whether it's still wanted before finalizing Pulse, or explicitly
deferred.

### G8 — Home vs. Map disagree on what counts as "current"

`HomePulseRail` gates dormant/active on **today's** entry specifically
(`Calendar.current.isDateInToday`). `MapPulseHero` and `MapUsLayer` both use `pulse.entries.last`
**regardless of age** — if you last checked in 4 days ago, Home correctly shows the dormant
"How's your capacity?" invite, but Map will render your 4-day-old entry as if it were current
("You're in an Expansive day," a landed orb, no staleness indicator beyond a small relative
timestamp already visible elsewhere). This may be intentional ("Map shows your last known
position, Home shows today's ritual status") but it's worth explicitly confirming — as written,
it can read as Map contradicting Home about whether you've "checked in."

### G9, G10, G11 — Smaller items

- **G9**: `fetchPartnerCapacity`/`fetchSharing`/`setSharing` in `PulseSyncService` have zero
  callers anywhere in the app. Dead code today — worth deleting or wiring, not leaving live-but-
  unused indefinitely (matches the "no vestigial machinery" pattern from earlier cleanup today).
- **G10**: `isDateInToday` duplicated across `HomePulseRail`/`MapPulseHero`; the
  `pulse.entries.last?.resolvedPosition ?? PulsePosition(0.5, 0.5)` "current position" fallback
  duplicated between `MapPulseHero` and `MapUsLayer`. Not a bug, just worth consolidating into a
  `PulseStore` computed property (`currentPosition`, `hasCheckedInToday`) the next time any of
  these files are touched — one source of truth instead of three copies that could drift.
- **G11**: `pulse_shared_capacity`'s real RLS policy can't be verified from the repo (table isn't
  tracked in any migration — it's prod-only drift, per the pre-existing audit). Plan 14 drafts an
  intended consent-gated policy, but that's proposed SQL, not evidence of what prod actually
  enforces today.

---

## PART 3 — MAP ME/US WIDGET PLAN (updated for tomorrow)

Given the gaps above, here's a sequenced plan — each step is independently shippable, ordered by
dependency:

1. **Fix G1 (Q4 data loss)** — small, isolated, no dependencies. Do first; it's a straight bug.
2. **Fix G3 (Us check-in entry point)** — add an `onCheckIn` affordance to `MapUsLayer` (mirroring
   `MapPulseHero`'s pattern) and wire it in `MapView.usLayer`. Independent of the backend work;
   ships immediately even with local-only data.
3. **Decide G2's scope** (history sync) — this gates whether Phase 5 below is worth doing at all.
   If local-only is fine for V1, skip straight to step 4.
4. **Execute Plan 14 as originally specced** (G5 + G6) — the position-shaped migration, real
   partner fetch, `MapStore.partnerPosition` assignment. This is real backend work (a tracked
   migration, RLS policy, `PulseSyncService` reshape) — budget accordingly, and reconcile the
   untracked prod objects (`pulse_shared_capacity`, `share_pulse_with_partner`) as part of it, not
   as an unrelated cleanup.
5. **Fix G4 (history grid partner column)** — once G6 lands, this needs its own follow-up; wiring
   `partnerPosition` alone does NOT fix the grid, since it reads a separately hardcoded `[]`.
   Needs partner *history*, not just partner *current position* — a bigger ask than Plan 14
   currently scopes (partner's own `entries` array, not just their latest point). Worth deciding
   whether the Us grid needs true partner history synced, or a smaller compromise (e.g. only
   today's cell shows the partner, historical cells show mine-only).
6. **Decide on G7 (time-window trail)** — still wanted, or formally dropped? If wanted, Plan 19 is
   ready to execute as-is (I re-verified its file:line citations are still accurate against
   current source, aside from referencing the plain-dot step nav which has since evolved — that
   part of Plan 19 is unrelated to it and unaffected).
7. **G8 (Home/Map "current" disagreement)** — a product decision, not really a "build" step. Worth
   5 minutes of thought: should Map's copy soften when the shown entry isn't from today ("as of 4
   days ago" instead of "You're in an Expansive day")?
8. **Cleanup pass** — G9 (dead sync methods), G10 (dedupe helpers), only after the above land,
   since G5/G6 will touch the same files anyway.

---

## PART 4 — OPEN DECISIONS FOR YOU

1. **Is local-only Pulse history acceptable for V1**, or does losing everything on
   reinstall/device-switch need a real fix (SwiftData + sync) before calling this finished? (G2)
2. **Q4 fix**: add a `capacity` field to `PulseEntry` and actually record it, or formally drop the
   question? (G1 — I lean toward recording it, given the question was rewritten today
   specifically to be worth asking.)
3. **Us history grid**: full partner history sync (bigger backend lift) or a smaller compromise
   (today-only partner data, historical cells stay mine-only)? (G4)
4. **Is the "your map" time-window trail (Plan 19) still wanted for V1**, or dropped? (G7)
5. **Home vs. Map staleness copy** — worth softening Map's language when showing a non-today
   entry, or is "last known position" the intended framing regardless of age? (G8)

Nothing above was touched tonight — this is audit-only, as asked. Sleep well; happy to start on
whichever of these you want first tomorrow.
