# 21 — Pulse Finalization (Staleness Honesty + Full Sync Loop + Cleanup)

> **Status: reference appendix, not the primary driver.** Superseded as "the plan to hand an agent" by
> `docs/handoffs/2026-07-03-pulse-finalization-goal.md`, which frames the same remaining work as
> outcomes against a rigorous Definition of Final rather than prescribed code — a better fit for an
> agent that needs less step-by-step direction. The code sketches below are still a verified-once
> (2026-07-03) concrete starting hypothesis for several of that document's gaps; re-verify against
> current source before using any of it, don't follow it blindly.

**Goal:** Close the last real gaps between Pulse's current, mostly-finished implementation and
"done": stop the Map tab from ever presenting a days-old reading with today's visual/textual
confidence (the "phantom day" problem), close the two remaining holes in the reinstall/offline
data-loss guarantee (one-directional sync, account deletion not wiping the local cache), harden the
sync path against a privacy edge case introduced by fixing the first hole, add the two small pieces
of mockup fidelity that never got wired up (Home's day-over-day trend line, the Us lens's "partner
hasn't checked in" echo), and remove one unsynced piece of dead code before it becomes a footgun.
Everything else about Pulse (the check-in flow itself, the 2-hour edit window, the partner
history-grid pairing, the position-only partner-privacy sync) is already built and correct — this
plan verifies that, it does not rebuild it.

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
> repo on **2026-07-03**, including a direct re-read of the live Supabase schema (not just the
> migration files) to catch drift between what earlier docs assumed and what's actually there. If
> reality differs when you build, **trust the repo and note the drift** — do not invent paths, tokens,
> or APIs to make the plan "fit."
>
> **Verification is deferred, not skipped:** finish by compiling green, then hand Bryan the
> **"Bryan verifies on device"** checklist at the end. Bryan runs on-device / feel confirmation himself
> (he does not want Claude/Fable running the simulator). Items marked 🎚️ are feel-values Bryan tunes on
> device — use the given default and move on; do not re-derive them.

---

## Context Fable needs

**Pulse is a couples' capacity/mood check-in: five questions map to a 2D circumplex position
(energy × openness), rendered as a drifting aura in four "spaces" (Expansive / Friction / Sovereign /
Protective). It's reachable from Home, Map's Me lens, and Map's Us lens.**

### Already built and correct — verify, do not rebuild

- **The check-in flow itself.** `PulseCheckInView.swift` — five questions, silver-to-color aura,
  numbered step nav (tap any answered step to revisit), full-screen `.vaylCover` presentation. Its
  drift animation and an unrelated ambient-animation bug (`AppAnimation.ambientAnimation` was
  reapplying on every unrelated re-render, causing the check-in's aura to visibly hitch on every pill
  tap) were both fixed earlier this session. Do not touch `PulseCheckInView.swift`, `PulseAnswers.swift`,
  `PulseAura.swift`, or `AppAnimation.pulseBallDrift`/`.ambientAnimation`.
- **The 2-hour edit window, anchored correctly across relaunch.** `PulseEntry.swift:41-53` —
  `createdAt: Date?`, `editWindow: TimeInterval = 2 * 60 * 60`, `resolvedCreatedAt`, `isEditable`.
  `PulseStore.add()` (`PulseStore.swift:58-77`) carries the original `createdAt` forward across a
  same-day re-edit, and enforces exactly **one entry per calendar day**. The server independently
  anchors the same thing: `pulse_entries.first_completed_at` (added by
  `supabase/migrations/20260702190000_pulse_entries_first_completed_at.sql`, specifically **because**
  a naive hydration merge would otherwise fall back to `entry_date` and silently re-extend the window
  on every relaunch) is written from `entry.resolvedCreatedAt` and read back into `createdAt` by
  `PulseSyncService.swift`'s `PulseEntryRow`/`toPulseEntry` — already correctly wired, do not touch.
  `PulseStore.canCheckInToday` (`PulseStore.swift:37-39`) is the single source of truth for whether the
  check-in CTA should be offered, and Home (`HomePulseRail.swift:103`), Map-Me (`MapPulseHero.swift:62`),
  and Map-Us (`MapUsLayer.swift:75`) all gate on it identically. Re-opening the check-in within the
  window is a **full redo of all five questions** (no pre-fill) — intended design, not a gap.
- **Full Supabase persistence, with partner privacy already tightened past the original design.**
  `pulse_entries` (created by `20260702160443_create_pulse_entries.sql`) is the sync source of truth.
  Two follow-on migrations already closed a real privacy gap in the original policy: **a partner can
  no longer read the raw Q1-Q5 text answers at all** — `20260702180000_pulse_entries_partner_position_only.sql`
  replaced the original any-couple-member-can-SELECT policy with an own-rows-only policy, plus a
  `SECURITY DEFINER` function `get_partner_pulse_positions()` that returns ONLY
  `profile_id/entry_date/energy/openness/capacity_score` — matching the existing Settings promise
  ("Your partner sees your Pulse capacity, not your answers.", `SettingsPrivacyView.swift`).
  `PulseSyncService.swift`'s `fetchPartnerEntries()` already calls this RPC (not a table `SELECT`) and
  reconstructs partner `PulseEntry`s with empty placeholder text fields — correct, since nothing ever
  reads a partner entry's `nervousSystem`/`focus`/`feeling`/`capacity`/`speed`. **Do not revert this to
  a direct table read of `pulse_entries` for the partner** — that would silently re-open the privacy
  gap those two migrations closed. `PulseStore.hydrateFromServer()` (`PulseStore.swift:90-101`) pulls
  the caller's own history down and merges it, called once at launch from `VaylApp.swift`'s `.task`,
  after auth is confirmed ready. This plan's Steps 1/6/7 close the three real holes left in this (see
  below) — everything else here is done.
- **The partner history grid.** `PulseHistory.pairedLastLogged` (`PulseHistory.swift:29-46`) pairs each
  of your last-30 logged entries with the partner's most-recent entry on or before that date
  (carry-forward, correct and intentional). `MapStore.partnerEntries`/`.loadPartnerPulse(appState:)`
  fetch it; `MapUsLayer.usGridPairs` (`MapUsLayer.swift:55-57`) feeds it to `PulseHistoryGrid`'s `.us`
  mode, which already renders a real split-bead grid. **Map's Us lens also already has its own
  check-in entry point** (`MapUsLayer.swift:207-223`) — not a dead end reachable only from Me.
- **No streak, no badge, no gamification.** `HomePulseRail.swift:17` and `PulseHistory.swift:5-7` both
  already say so explicitly in their own doc comments. This plan does not add any of that either.

### What's genuinely still open (this plan's actual scope)

1. **"Phantom day" — a stale reading shown with today's confidence.** `MapPulseHero` already softens
   its own sublabel when stale (`isStale`/`staleSublabel`, `MapPulseHero.swift:172-190`) — but nothing
   else does. The orb still renders at full opacity, `MapFieldSheet`'s "You're in an Expansive day"
   headline has zero staleness awareness, and `MapUsLayer`'s headline/desc copy never considers
   staleness for *either* person.
2. **The sync loop only pulls, and reaches back with no bound.** `hydrateFromServer()` never pushes a
   local entry the server is missing, so a single failed push (offline, dropped connection) can mean
   that day never reaches the server, ever. The naive fix (push every unsynced local day, unbounded)
   introduces a NEW privacy risk: `pushEntry` stamps `couple_id` from the profile's CURRENT couple at
   push time, so pushing an old, previously-unsynced entry from a prior relationship after an unlink +
   re-pair could silently attach that old entry to the new partner's couple. Step 1 fixes the pull/push
   gap with a bounded (7-day) reach-back specifically to avoid this.
3. **`hydrateFromServer()` only ever runs once, at cold launch.** It's inside `VaylApp.swift`'s single
   `.task`, not tied to `scenePhase`. A user who checks in offline and reconnects mid-session (without
   force-quitting) has no retry path until their next cold launch — which, given Vayl's low daily-open
   frequency, could be days. Step 6 adds a foreground-triggered reconciliation pass.
4. **Account deletion doesn't wipe the local Pulse cache.** `AccountService.wipeLocalStore()` clears
   SwiftData + four named `UserDefaults` keys, but not `PulseStore`'s own key
   (`"pulse.entries.v1"`) — even though the server-side delete is already correct (`pulse_entries`
   cascades via its FK to `user_profiles`). A user who deletes their account and re-onboards on the
   same device (the deletion flow's own stated intent: "same Apple ID re-onboards clean") would see
   their old Pulse history resurrected locally, even though the server record is genuinely gone. Step
   7 fixes this.
5. **Two small, already-scoped mockup details never got wired up.** Home's day-over-day trend line
   ("Brighter than yesterday · 2h ago") is already computed for Map (`MapPulseHero.weatherLine`) but
   was never ported to Home — `HomePulseRail.swift`'s own doc comment already flags this, tracked as
   "D1.5." And the Us lens's "partner hasn't checked in yet" state renders no visual echo for the
   partner's half of the field at all (just copy) — `map-pulse-coldstart.html`'s "Us, partner not yet"
   card specs a cycling four-space aura (the same one `PulseCyclingAura` already renders elsewhere for
   "no reading yet") in the partner's slot, tagged "Alex · not yet," so the empty half reads as
   *waiting*, not broken. Steps 4-5 build both.
6. **One trivial, self-flagged placeholder.** `MapPulseHero.swift:38` has `.scaleEffect(1.0) //
   placeholder for press state — wire if adding isPressed` on its compact aura button — every other
   tappable element in these files animates a press state per CLAUDE.md's tappable-element contract;
   this one is a literal no-op comment. One-line fix, folded into Step 3.
7. **One unsynced, dead method.** `PulseStore.remove(id:)` (`PulseStore.swift:79-82`) has zero callers
   anywhere in the app and no corresponding server-side delete. Deleted in Step 1.
8. **No database-level defense against a duplicate-per-day row.** `pushEntry`'s own delete-then-insert
   already enforces one row per profile per day from the client side, but nothing in the schema stops
   a future bug (or a second call site) from ever inserting a duplicate. Step 8 adds a cheap unique
   index as a backstop — not a fix for the same-day two-device race (see Open Decisions), but a
   guarantee against silent duplicate accumulation from anything else.

### Confirmed non-goals / accepted risk (do not build these; considered and deliberately left as-is)

- **Same-day, two-device write conflict is accepted last-write-wins, not resolved.** If a phone and a
  second device (a reinstall, an iPad) both push a completed check-in for the same day within the
  edit window, whichever `pushEntry` call's delete-then-insert lands last on the server wins outright
  — the loser's answers are gone, with no merge and no UI indication it happened. This is a real,
  low-frequency edge case for a solo-dev, single-primary-device, two-person daily ritual — building
  actual conflict resolution (versioning, a merge UI) would be a disproportionate lift for how rarely
  it can occur. Leave it as an accepted limitation, not a build item.
- **`first_completed_at`/`createdAt` is client-trusted, with no server-side constraint tying it to
  `entry_date`.** A compromised or buggy client could in principle push a timestamp that makes an
  already-locked entry appear freshly editable to the server. This is the same trust boundary every
  comparable client-authored wellness app accepts (Daylio, Apple Health's own mood/reflection entries)
  — Pulse is not an adversarial or competitive system where a user has an incentive to cheat their own
  mood tracker. Not worth a Postgres trigger for this threat model.
- **A transient partner-fetch failure and "partner has never logged" are not distinguished in the UI**
  on a brand-new Map session (before any successful fetch has populated `partnerEntries`). After the
  first successful fetch, a later transient failure correctly preserves the last-known state (`guard
  let entries = ... else { return }` in `MapStore.loadPartnerPulse` leaves existing data untouched) —
  only the very-first-load race is affected, and building a genuine loading/error/empty tri-state for
  that narrow window is disproportionate to how rarely it matters.
- **"Partner turned sharing off" and "partner has never checked in" read identically** (both produce
  zero rows from `get_partner_pulse_positions()`, by design — the function's own `WHERE
  share_pulse_with_partner = true` clause makes this true structurally). This is treated as a feature,
  not a gap: distinguishing "they're deliberately hiding this from you" from "they haven't logged yet"
  would surface a potentially hurtful signal about the partner's own privacy choice, which isn't
  Pulse's place to reveal.
- **No dedicated Pulse error/observability layer.** `PulseSyncService.swift` wraps every Supabase call
  in bare `try?` with no logging. This is a real blind spot (a silently-failing sync would never
  surface to Bryan) but it's an app-wide gap, not Pulse-specific — Plan 07 (`07-empty-loading-error-and-observability.md`)
  already scopes wiring Crashlytics behind a PII-safe façade. Do not build Pulse-specific logging here;
  Pulse's sync calls will benefit automatically once Plan 07 lands.
- **Backfill, a streak/badge/completion mechanic, and Pulse check-in reminder notifications** remain
  explicit non-goals, as in the prior version of this plan.

### Canonical patterns to imitate

- `PulseFieldEntry`'s existing `rampOverride`/`haloSpread` fields (`PulseField.swift:19-28`) are both
  opt-in, additive, default-off/no-op params — the template for this plan's new `opacity` field on the
  same struct.
- `MapPulseHero`'s existing `isStale`/`staleSublabel` (being promoted onto `PulseStore` in Step 1) is
  the template for how staleness should read everywhere else it isn't handled yet.
- `PulseCyclingAura` (already built, used by Home/Map-Me for "no reading yet at all") is the exact
  component `map-pulse-coldstart.html` specs reusing for "partner hasn't logged yet" — don't build a
  new component, reuse this one.

---

## Files

| Action | File | Responsibility |
|---|---|---|
| Modify | `Vayl/Features/Pulse/Store/PulseStore.swift` | Promote `isPositionStale`/`relativeDay(for:)`/`weatherLine` as shared helpers; bidirectional, 7-day-bounded reconciliation in `hydrateFromServer()`; delete dead `remove(id:)` |
| Modify | `Vayl/Features/Pulse/Components/PulseField.swift` | Add opt-in `opacity` to `PulseFieldEntry`, applied in `auraLayer` |
| Modify | `Vayl/Features/Map/Components/MapPulseHero.swift` | Delegate staleness/trend to the shared `PulseStore` helpers, dim the stale orb, fix the no-op press state, thread staleness into `MapFieldSheet`'s copy |
| Modify | `Vayl/Features/Map/Components/MapUsLayer.swift` | Independent mine/partner staleness in `headline`/`descCopy`, the partner "not yet" cycling-aura echo, dim stale auras |
| Modify | `Vayl/Features/Home/Components/HomePulseRail.swift` | Render the day-over-day trend line combined with the timestamp |
| Modify | `Vayl/App/VaylApp.swift` | Foreground-triggered (`scenePhase`) Pulse reconciliation, not just cold-launch |
| Modify | `Vayl/Core/Services/AccountService.swift` | `wipeLocalStore` also clears the local Pulse cache key |
| Create | `supabase/migrations/<timestamp>_pulse_entries_unique_per_day.sql` | Defense-in-depth unique index, one row per profile per day |

No other files change. This plan does not touch `PulseCheckInView.swift`, `PulseAnswers.swift`,
`PulseAura.swift`, `AppAnimation.swift`, `PulseHistory.swift`, `PulseHistoryGrid.swift`,
`MapStore.swift`, or `PulseSyncService.swift` — all of those are already correct.

---

## Build steps

### Step 1 — PulseStore: shared helpers, bounded bidirectional sync, delete dead code

Add three computed members after `canCheckInToday` (`PulseStore.swift:39`):

```swift
/// True when `currentPosition` reflects a stale prior entry, not today's. Map's
/// Me and Us lenses deliberately keep showing your last KNOWN position instead
/// of going blank (unlike Home, which switches to its dormant state when there's
/// no today entry) — but need to say so honestly rather than presenting a
/// days-old reading with today's confidence. Single source of truth: was
/// duplicated as MapPulseHero's own private `isStale`.
var isPositionStale: Bool {
    todayEntry == nil && !entries.isEmpty
}

/// Human copy for how stale a date is ("yesterday", "4 days ago"). Was
/// MapPulseHero's own private `relativeDay` — promoted here so MapUsLayer can
/// use the same phrasing for the partner's staleness, not just mine.
func relativeDay(for date: Date) -> String {
    let cal = Calendar.current
    let days = cal.dateComponents(
        [.day],
        from: cal.startOfDay(for: date),
        to: cal.startOfDay(for: Date())
    ).day ?? 0
    if days <= 1 { return "yesterday" }
    return "\(days) days ago"
}

/// "Brighter than yesterday" / "A bit quieter today" / "About the same as
/// yesterday" — nil if either day is missing an entry. Was MapPulseHero's own
/// private `weatherLine`; HomePulseRail needs the identical comparison (its own
/// doc comment already tracks this as the deferred "D1.5" item).
var weatherLine: String? {
    guard
        let today = entries.last(where: { Calendar.current.isDateInToday($0.date) }),
        let yesterday = entries.last(where: { Calendar.current.isDateInYesterday($0.date) })
    else { return nil }

    let delta = today.resolvedPosition.energy - yesterday.resolvedPosition.energy
    if abs(delta) < 0.05 { return "About the same as yesterday" }
    return delta > 0 ? "Brighter than yesterday" : "A bit quieter today"
}
```

Replace `hydrateFromServer()` (`PulseStore.swift:90-101`) with the same pull, plus a bounded push-back pass:

```swift
func hydrateFromServer() async {
    guard let serverEntries = await PulseSyncService.shared.fetchOwnEntries() else { return }
    let cal = Calendar.current
    var merged = entries
    for serverEntry in serverEntries {
        merged.removeAll { cal.isDate($0.date, inSameDayAs: serverEntry.date) }
        merged.append(serverEntry)
    }
    merged.sort { $0.date < $1.date }
    entries = merged
    save()

    // Push back any RECENT local day the server doesn't have yet — a check-in
    // made offline (or whose push silently failed) would otherwise never reach
    // the server, since add()'s push is fire-and-forget and only fires once, at
    // creation. Bounded to the last 7 days on purpose, for two reasons: (1) a
    // connectivity-caused sync gap should surface well within a week of normal
    // app use, so there's no real recovery value in reaching further back; and
    // (2) reaching further back risks re-pushing a genuinely old, pre-unlink
    // entry after a user re-pairs with a NEW partner — pushEntry stamps
    // couple_id from the CURRENT profile at push time, so an unbounded
    // reach-back could silently attach an old, prior-relationship entry to a
    // new partner's couple_id. A 7-day cap keeps this a narrow connectivity
    // fix, not a history-resurrection path. 🎚️ the exact window is tunable.
    let cutoff = cal.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    let serverDays = Set(serverEntries.map { cal.startOfDay(for: $0.date) })
    let unsynced = entries.filter { $0.date >= cutoff && !serverDays.contains(cal.startOfDay(for: $0.date)) }
    for entry in unsynced {
        await PulseSyncService.shared.pushEntry(entry)
    }
}
```

Delete `remove(id:)` (`PulseStore.swift:79-82`) entirely:

```swift
func remove(id: UUID) {
    entries.removeAll { $0.id == id }
    save()
}
```

It has zero callers anywhere in the app and no server-side delete counterpart. If entry deletion becomes
a real feature later, build `PulseStore.deleteEntry`/`PulseSyncService.deleteEntry` together from scratch
(the `pulse_entries delete own` RLS policy already exists and is ready) — don't resurrect this method.

*Done: `PulseStore` exposes `isPositionStale`/`relativeDay(for:)`/`weatherLine`; `hydrateFromServer()`
reconciles both directions bounded to 7 days; `remove(id:)` no longer exists anywhere in the file.*

### Step 2 — PulseField: an opt-in dim for a stale aura

In `PulseFieldEntry` (`PulseField.swift:19-28`), add one field:

```swift
struct PulseFieldEntry: Identifiable {
    var id: String = "primary"
    var position: PulsePosition
    var auraSize: CGFloat = 44
    var isBloom:  Bool    = false
    var rampOverride: AuraColors? = nil
    /// Dims a stale reading (e.g. a days-old position shown as "last known,"
    /// not "today"). 1.0 (default, no-op) = every existing caller unaffected.
    var opacity: Double = 1.0

    var quadrant: PulseQuadrant { position.quadrant }
}
```

In `auraLayer` (`PulseField.swift:114-134`), apply it:

```swift
private var auraLayer: some View {
    GeometryReader { geo in
        ForEach(entries) { entry in
            let r  = entry.auraSize * 0.5
            let pt = fieldPoint(for: entry.position, in: geo.size, inset: r)
            ZStack {
                if entry.isBloom {
                    BloomRing(color: entry.quadrant.capacityColor.auraCore,
                              size:  entry.auraSize)
                }
                if let ramp = entry.rampOverride {
                    PulseAura(ramp: ramp, size: entry.auraSize)
                } else {
                    PulseAura(quadrant: entry.quadrant, size: entry.auraSize)
                }
            }
            .position(x: pt.x, y: pt.y)
            .opacity(entry.opacity)
            .animation(AppAnimation.pulseBallDrift, value: pt)
        }
    }
}
```

*Done: `PulseFieldEntry.opacity` exists, defaults to 1.0, and every existing call site that doesn't
pass it renders identically to before.*

### Step 3 — MapPulseHero: delegate staleness/trend, dim the stale orb, fix the press-state, extend to the field sheet

Replace the private staleness/trend members (`isStale` at `MapPulseHero.swift:172-174`,
`staleSublabel` at `175-179`, `relativeDay` at `181-190`, and `weatherLine` at `192-202`) with:

```swift
/// True when the position shown is your last known one, not today's — Map
/// (unlike Home) shows the last entry regardless of age, so the sublabel/orb
/// need to say so rather than read like a live "today" status. Single source
/// of truth lives on PulseStore now (was duplicated here).
private var isStale: Bool { pulse.isPositionStale }

private var staleSublabel: String? {
    guard isStale, let last = pulse.entries.last else { return nil }
    return "As of \(pulse.relativeDay(for: last.date))"
}
```

(No change needed at either call site — `staleSublabel ?? currentQuadrant.sublabel`
at `MapPulseHero.swift:47`, and `if let wl = weatherLine` at `MapPulseHero.swift:52` becomes
`if let wl = pulse.weatherLine` — both keep working, just delegating now.)

Fix the press-state placeholder and dim the compact hero's orb when stale (`MapPulseHero.swift:29-38`):

```swift
@State private var isPressed = false

...

Button {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    showMap = true
} label: {
    PulseAura(quadrant: currentQuadrant, size: 148)
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.lg)
        .opacity(isStale ? 0.6 : 1.0)   // 🎚️ FEEL: confirm on device
}
.buttonStyle(.plain)
.scaleEffect(isPressed ? 0.96 : 1.0)
.sensoryFeedback(.impact(.light), trigger: isPressed)
.simultaneousGesture(
    DragGesture(minimumDistance: 0)
        .onChanged { _ in isPressed = true }
        .onEnded   { _ in isPressed = false }
)
```

(The existing `.impactOccurred()` call inside the button action stays as-is — CLAUDE.md's contract
wants scale + haptic + action on every tap target; this adds the missing scale, using
`simultaneousGesture` so the existing tap action isn't disturbed.)

Thread staleness into the field sheet — change the `.vaylCover` block (`MapPulseHero.swift:76-78`):

```swift
.vaylCover(isPresented: $showMap, confirmOnExit: false) {
    MapFieldSheet(
        position:   currentPosition,
        quadrant:   currentQuadrant,
        isStale:    isStale,
        staleSince: pulse.entries.last.map { pulse.relativeDay(for: $0.date) }
    )
}
```

Add the two new properties to `MapFieldSheet` (`MapPulseHero.swift:210-213`):

```swift
private struct MapFieldSheet: View {
    let position:   PulsePosition
    let quadrant:   PulseQuadrant
    let isStale:    Bool
    let staleSince: String?

    @Environment(\.vaylDismiss) private var dismiss
```

And rewrite `readCopy` (`MapPulseHero.swift:273-280`) to use them:

```swift
private var readCopy: String {
    guard isStale, let staleSince else {
        switch quadrant {
        case .expansive:  return "You're in an Expansive day"
        case .friction:   return "A Friction day"
        case .sovereign:  return "A Sovereign day"
        case .protective: return "A Protective day"
        }
    }
    return "Your last Pulse: \(quadrant.spaceName) (\(staleSince))"
}
```

`descCopy` stays unchanged — it describes the space's character, not a live status claim, so the
`readCopy` change alone is enough to communicate staleness honestly on this screen.

Update the field-sheet aura to use the new opt-in dim (`MapPulseHero.swift:227-231`):

```swift
PulseField(
    entries: [PulseFieldEntry(position: position, auraSize: 60, opacity: isStale ? 0.6 : 1.0)],
    size: w,
    showAxisLabels: true
)
```

*Done: a fresh (today) reading on Map-Me looks and reads exactly as before. A stale one dims the orb
(compact hero and field sheet both) and swaps "You're in an X day" for "Your last Pulse: X (N days
ago)." The compact hero's tap now scales like every other tappable element in the app. Home's trend
line and Map's trend line share one implementation.*

### Step 4 — MapUsLayer: independent mine/partner staleness + the partner "not yet" echo

Add after `hasHistory` (`MapUsLayer.swift:63`):

```swift
/// Mirrors PulseStore.isPositionStale but scoped to this layer's own copy.
private var myStale: Bool { pulse.isPositionStale }

private var partnerLastEntry: PulseEntry? { partnerEntries.last }

/// True when the partner has logged before, but not today. Independent of
/// `myStale` — the two people's freshness can differ.
private var partnerStale: Bool {
    guard let last = partnerLastEntry else { return false }
    return !Calendar.current.isDateInToday(last.date)
}
```

Replace `headline` (`MapUsLayer.swift:41-44`):

```swift
// "A wide day between you" vs "Close today" — FEEL: tune threshold on device.
// Neither reading is claimed to be "today" unless both actually are.
private var headline: String {
    guard partnerPosition != nil else {
        return partnerName.isEmpty ? "Pulse · together" : "\(partnerName) hasn't checked in"
    }
    guard !myStale, !partnerStale else { return "Comparing your last Pulses" }
    return distance > 0.45 ? "A wide day between you" : "Close today"
}
```

Replace `descCopy` (`MapUsLayer.swift:46-53`):

```swift
private var descCopy: String {
    guard let partner = partnerPosition else {
        return partnerName.isEmpty
            ? "Check in to see how you and your partner compare."
            : "Their space fills in the moment they take a reading."
    }
    let pName = partnerName.isEmpty ? "Your partner" : partnerName

    let myPhrase: String = {
        guard myStale, let mine = pulse.entries.last else {
            return "You're in the \(myQuadrant.spaceName)"
        }
        return "You were last in the \(myQuadrant.spaceName) (\(pulse.relativeDay(for: mine.date)))"
    }()

    let partnerPhrase: String = {
        guard partnerStale, let last = partnerLastEntry else {
            return "\(pName) is in the \(partner.quadrant.spaceName)"
        }
        return "\(pName) was last in the \(partner.quadrant.spaceName) (\(pulse.relativeDay(for: last.date)))"
    }()

    return "\(myPhrase); \(partnerPhrase)."
}
```

Add the partner "not yet" cycling-aura echo to `fieldBlock` (`MapUsLayer.swift:108-152`) — the
`if let partner = partnerPosition { ... }` block gets a new `else` branch:

```swift
if let partner = partnerPosition {
    PulseCapsule(
        myPosition:      myPosition,
        partnerPosition: partner,
        myColor:         myQuadrant.capacityColor.auraCore,
        partnerColor:    partner.quadrant.capacityColor.auraCore,
        fieldSize:       size,
        auraSize:        auraSize
    )
    auraLabel("You",
              position: myPosition,
              color:    myQuadrant.capacityColor.auraCore,
              above:    true,
              fieldSize: size)
    auraLabel(partnerName.isEmpty ? "Partner" : partnerName,
              position: partner,
              color:    partner.quadrant.capacityColor.auraCore,
              above:    false,
              fieldSize: size)
} else if !partnerName.isEmpty {
    // Partner is paired but hasn't logged yet — echo the same cycling
    // four-space aura Home/Map-Me use for "no reading yet," tagged with
    // their name, so their half of the field reads as waiting, not broken.
    // Matches map-pulse-coldstart.html's "Us, partner not yet" card exactly
    // (including its illustrative placement — there's no real reading to
    // place, this position is fixed, not derived from any data).
    let waitingPos = PulsePosition(energy: 0.30, openness: 0.30)
    let waitingPt  = CGPoint(x: waitingPos.openness * size, y: (1 - waitingPos.energy) * size)
    PulseCyclingAura(size: auraSize)
        .position(x: waitingPt.x, y: waitingPt.y)
    auraLabel("\(partnerName) · not yet",
              position: waitingPos,
              color:    AppColors.textTertiary,
              above:    false,
              fieldSize: size)
}
```

Dim the real auras — update `fieldEntries(auraSize:)` (`MapUsLayer.swift:154-162`):

```swift
private func fieldEntries(auraSize: CGFloat) -> [PulseFieldEntry] {
    var entries: [PulseFieldEntry] = [
        PulseFieldEntry(id: "me", position: myPosition, auraSize: auraSize, opacity: myStale ? 0.6 : 1.0)
    ]
    if let partner = partnerPosition {
        entries.append(PulseFieldEntry(id: "partner", position: partner, auraSize: auraSize, opacity: partnerStale ? 0.6 : 1.0))
    }
    return entries
}
```

*Done: a both-fresh comparison reads exactly as before. If either person's reading is stale, the
headline softens and the description names each person's own freshness independently. If the partner
is paired but has never logged, their half of the field now shows a cycling aura tagged "name · not
yet" instead of empty space, and the headline reads "name hasn't checked in."*

### Step 5 — HomePulseRail: the day-over-day trend line

Change the active-state call site (`HomePulseRail.swift:47-56`) to combine the trend with the timestamp:

```swift
if let entry = todayEntry {
    let quadrant = entry.resolvedPosition.quadrant
    card(
        orb:       PulseAura(quadrant: quadrant, size: orbSize, haloSpread: orbHaloSpread),
        hero:      quadrant.spaceName,
        heroColor: AppColors.textPrimary,
        sub:       quadrant.sublabel,
        subColor:  AppColors.textSecondary,
        timestamp: trendAndTimestamp(entry.date)
    )
}
```

Add the helper near `relativeTime` (`HomePulseRail.swift:188-194`):

```swift
/// Combines the day-over-day trend (if available) with the relative timestamp
/// on one line, matching home-pulse-widget-shine.html's "Brighter than
/// yesterday · 2h ago" — the mockup's one remaining unbuilt detail (previously
/// tracked as this file's own "D1.5" note, now built). Falls back to the plain
/// timestamp on a first-ever entry (no yesterday to compare against).
private func trendAndTimestamp(_ date: Date) -> String {
    guard let trend = pulse.weatherLine else { return relativeTime(date) }
    return "\(trend) · \(relativeTime(date))"
}
```

Delete the now-stale "NOTE (out of scope, tracked as D1.5)" doc comment at the top of the file
(`HomePulseRail.swift:20-21`) — it's in scope and built now.

*Done: Home's active state shows "Brighter than yesterday · 2h ago" (or the equivalent) whenever a
prior day's entry exists to compare against; a first-ever entry still shows just the timestamp, same
as before.*

### Step 6 — VaylApp: reconcile Pulse on every foreground, not just cold launch

Add a `scenePhase` observer (`VaylApp.swift`, alongside the existing `@State` properties at lines
14-19):

```swift
@Environment(\.scenePhase) private var scenePhase
```

Attach a handler after the existing `.task` block (`VaylApp.swift:52-69`, right before
`.modelContainer(...)` at line 70):

```swift
.onChange(of: scenePhase) { _, newPhase in
    guard newPhase == .active else { return }
    Task { await pulseStore.hydrateFromServer() }
}
```

*Done: returning to the app from the background re-runs Pulse's (now bidirectional) reconciliation,
closing the "only once per cold launch" gap — an offline check-in that reconnects mid-session no
longer has to wait for the next relaunch to sync.*

### Step 7 — AccountService: wipe the local Pulse cache on account deletion

`AccountService.wipeLocalStore()` (`AccountService.swift:82-92`) already clears four named
`UserDefaults` keys — add PulseStore's:

```swift
func wipeLocalStore(container: ModelContainer) {
    let context = ModelContext(container)
    for model in SchemaV1.models {
        try? context.delete(model: model)
    }
    try? context.saveWithLogging()
    for key in ["supabaseProfileId", "pendingProfileSync", "pendingOnboardingSync", "pendingDesireSync", "pulse.entries.v1"] {
        UserDefaults.standard.removeObject(forKey: key)
    }
    logger.info("Local store wiped")
}
```

*Done: deleting an account and re-onboarding on the same device starts with a genuinely empty Pulse
history, matching the deletion flow's own "same Apple ID re-onboards clean" intent — the server-side
delete was already correct, only the local mirror was stale.*

### Step 8 — Supabase: a defense-in-depth unique index

Create `supabase/migrations/<current-timestamp>_pulse_entries_unique_per_day.sql`:

```sql
-- pushEntry's own delete-then-insert already enforces one row per profile per
-- day from the client side, but nothing in the schema itself stops a future
-- bug (or a second call site) from ever inserting a duplicate. This makes "one
-- entry per profile per day" a database guarantee, not just an app-level
-- convention. Truncated in UTC as an approximation of the client's
-- Calendar.current (device-local) day boundary — the two won't always agree
-- exactly at a day edge, but this is a backstop against accidental
-- duplication, not a strict mirror of the client's day logic.
create unique index if not exists pulse_entries_one_per_day
  on public.pulse_entries (profile_id, (date_trunc('day', entry_date at time zone 'utc')));
```

Apply it via the Supabase MCP `apply_migration` tool (project `ynhjlabjzauamntbyxdp`), then run
`get_advisors` to confirm no new lint issues, then mirror the applied SQL into the migrations folder
exactly as `create_pulse_entries` was (verified pattern from this session).

*Done: a duplicate profile+day row is no longer possible even from a bug, only from the accepted
two-device race (Open Decisions) — which the existing delete-then-insert already tolerates (a
duplicate-key error from a losing concurrent insert is silently swallowed by `pushEntry`'s `try?`, and
self-heals on the next reconciliation pass once Step 6 lands, since that day still reads as "unsynced"
locally until its content matches the server).*

---

## Definition of Done (build-green)

- [ ] `PulseStore.isPositionStale`/`relativeDay(for:)`/`weatherLine` exist; `MapPulseHero`'s own
      private copies of all three are gone, delegating to these instead.
- [ ] `hydrateFromServer()` pushes any local-only day from the last 7 days back to the server after
      merging, not just pulls, and never reaches back further than that window.
- [ ] `PulseStore.remove(id:)` is deleted; zero references remain anywhere.
- [ ] `PulseFieldEntry` has an opt-in `opacity` field (default 1.0); every existing call site that
      doesn't pass it renders identically to before.
- [ ] Map-Me's compact orb and full-screen field sheet both visually (dimmed) and textually distinguish
      a stale reading from a fresh one; the compact orb's tap now scales like every other tap target.
- [ ] Map-Us's headline/description independently account for MY staleness and the PARTNER's
      staleness, and show a cycling "not yet" aura in the partner's slot when they're paired but
      haven't logged.
- [ ] Home's active state shows the day-over-day trend combined with the timestamp when a prior day
      exists to compare against.
- [ ] The app reconciles Pulse on every foreground transition, not just cold launch.
- [ ] Deleting an account clears the local `pulse.entries.v1` cache along with everything else.
- [ ] The `pulse_entries_one_per_day` unique index is applied and tracked in migrations.
- [ ] A fresh (today, both people) reading on every surface (Home, Map-Me, Map-Us) looks and reads
      exactly as it did before this plan — nothing regresses the common case.
- [ ] Build is green.
- [ ] Zero raw literals introduced beyond the accepted 🎚️ exceptions (the `0.6` dim opacity, the
      7-day reconciliation window).

## Bryan verifies on device

- With today's check-in fresh: confirm Home, Map-Me, and Map-Us all look exactly as they do now.
- Let a check-in age past today (or seed stale DEBUG preview data): confirm Map-Me's orb dims and both
  its sublabel and the full-screen field sheet read "last known," not "today."
- With a paired test device (or two accounts), let one partner's Pulse go stale while the other stays
  fresh: confirm Map-Us's headline/description name each person's own staleness independently.
- With a paired but never-checked-in-yet partner: confirm the Us field shows a cycling aura in their
  slot tagged "name · not yet," and the headline reads "name hasn't checked in."
- Check in on airplane mode, then reconnect WITHOUT force-quitting (just background/foreground the
  app): confirm the entry reaches Supabase without needing a full relaunch.
- Delete a test account with Pulse history, then re-onboard on the same device: confirm no old Pulse
  entries appear.
- Confirm the check-in flow itself (ball animation, edit window, Home/Map-Me/Map-Us parity) still
  feels exactly as it did before this pass.
- 🎚️ Tune the `0.6` stale-dim opacity, the staleness/trend copy phrasing, and the 7-day reconciliation
  window if any read off.

## Constraints / do-not-touch

- Do not touch `PulseCheckInView.swift`, `PulseAnswers.swift`, `PulseAura.swift`,
  `AppAnimation.pulseBallDrift`/`.ambientAnimation`, `PulseHistory.swift`, `PulseHistoryGrid.swift`,
  `MapStore.swift`, or `PulseSyncService.swift` — all already correct. In particular, do not change
  `PulseSyncService.fetchPartnerEntries()` back to a direct `pulse_entries` table read — it must stay
  on the `get_partner_pulse_positions()` RPC, which is what enforces the position-only partner-privacy
  boundary.
- Do not rebuild the edit window, the partner history-grid pairing, or the position-only partner sync
  — verify them, don't redesign them.
- Do not add backfill, a streak/badge/completion mechanic, or Pulse check-in reminder notification
  scheduling — all three are explicit non-goals.
- Do not attempt same-day two-device conflict resolution, a server-side constraint on
  `first_completed_at`, or a loading/error/empty tri-state for the partner-fetch race — all three are
  explicit accepted-risk non-goals (see Context) for this pass.
- Do not build Pulse-specific error logging/observability — that's Plan 07's scope; Pulse benefits
  automatically once it lands.

## Open decisions

1. **Stale-dim opacity (`0.6`), the staleness/trend copy phrasing, and the 7-day reconciliation
   window.** Recommended defaults: as written throughout this plan. 🎚️ Tune/wordsmith on device.
2. **Whether to ever build real entry deletion.** Recommended default: not now — delete the dead
   `remove(id:)` as part of this plan's cleanup; if wanted later, build `PulseStore.deleteEntry` +
   `PulseSyncService.deleteEntry` together (the RLS delete policy already exists and is ready).
3. **Same-day two-device conflict, client-trusted `first_completed_at`, and the partner-fetch-race
   tri-state.** Recommended default: accept all three as documented limitations (see Context), do not
   build fixes for them in this pass — each is low-frequency and disproportionately expensive to solve
   properly for how rarely it matters in a two-person daily ritual.
4. **The `pulse_entries_one_per_day` unique index's UTC-day approximation vs. the client's
   device-local day boundary.** Recommended default: accept the mismatch (it's a backstop against bugs,
   not a strict enforcement of the app's own day-boundary semantics) rather than engineering a
   timezone-aware index expression for a purely defense-in-depth guarantee.
