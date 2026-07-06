# 18 — Pulse Foundations + Ball Feel + Check-In Presentation (Pulse Phases A–C)

**Goal:** Finish wiring the Pulse feature's own internals — one position-mapping source of truth,
position-is-the-only-color-source, the locked ball behaviors (drift/silver-to-start — idle-float was
built then reverted, see Step 4), a
stable full-screen check-in presentation, and the dead-code purge — so Plan 19 has a complete, correct
Pulse to wire into the Map tab. Supersedes Phases A, B, C of
`docs/handoffs/2026-06-30-pulse-audit-and-one-shot-plan.md` (re-verified against source on 2026-07-01;
Phase D of that doc is already done — see Context).

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

## Context Fable needs

- **Current state, re-verified 2026-07-01 (do not trust the older handoff doc's prose except where
  cited below):**
  - **Phase A not started.** `PulseCheckInView.currentPosition` (`PulseCheckInView.swift:170-195`)
    re-implements the exact math `PulseAnswers.position()` (`PulseAnswers.swift:110-126`) already does,
    incrementally per-question. `commitEntry` (`PulseCheckInView.swift:226-228`) still lets a Q4 pill's
    `glowOverride` replace the position-derived color. The 6 dead files still exist:
    `DailyCheckInView.swift`, `CheckInShell.swift`, `PulseCheckInCover.swift`, `PulseWidget.swift`,
    `PulseSheetView.swift`, `TierGuideSheet.swift` (all in `Vayl/Features/Pulse/`). `PulseTier`
    (`AppPulseEnums.swift:60-101`) is dead — its only caller, `PulseEntry.tier`
    (`PulseEntry.swift:42-43`), itself has zero callers anywhere in the app (verified by grep).
  - **Phase B not started.** No `pulseBallDrift` token exists in `AppAnimation.swift`. `PulseAura.swift`
    has no idle-float/bob state, and nothing implements "silver until the ball first lands."
  - **Phase C not started.** Both check-in sites (`HomeDashboardView.swift:288-294`,
    `MapView.swift:57-63`) still present `PulseCheckInView` via `.vaylSheet(heightFraction: 0.82)`.
  - **Phase D is DONE, better than the old handoff doc describes** — `HomePulseRail.swift` was rebuilt
    this session (row-paired hero+orb, 84pt orb, `AppFonts.pulseWidgetTitle`, `PulseAura.haloSpread`,
    spectrum hairline, `onTap` wired to Map). No action needed here.
- **Canonical patterns to imitate:** `PulseAura.swift`'s existing `haloSpread` param (an opt-in, additive
  visual behavior with a `0`/no-op default) is the template for adding the idle-float param the same
  way — additive, defaulted off, so every existing caller (`MapPulseHero`, `MapUsLayer`, `PulseField`,
  `HomePulseRail`) is unaffected unless it opts in.
- **The "Stable" tie problem:** `PulsePosition.quadrant` (`PulsePosition.swift:20-27`) resolves a `0.5`
  tie toward charged/open (`>= 0.5`). Q1's "Stable" pill has `energy: 0.0` delta, which resolves to
  `energy = 0.5` exactly — landing every "Stable" answer in the charged half by coin-flip of the tie
  rule, never truly centered. This plan adds a small off-axis nudge so a genuinely neutral answer still
  reads as *a* space, not a boundary artifact.

---

## Files

| Action | File | Responsibility |
|---|---|---|
| Modify | `Vayl/Features/Pulse/PulseCheckInView.swift` | Dedupe position math (A1), drop Q4 color override (A2), silver-to-start (B3), full-screen presentation (C1) |
| Modify | `Vayl/Core/Models/PulseAnswers.swift` | Add the off-axis snap so a boundary result never lands exactly on 0.5 |
| Modify | `Vayl/App/Theme/AppAnimation.swift` | Add `pulseBallDrift` spring token |
| Modify | `Vayl/Features/Pulse/Components/PulseAura.swift` | (idle-float built then reverted — no net change here) |
| Modify | `Vayl/Features/Home/Views/HomeDashboardView.swift` | Swap check-in `.vaylSheet` → `.vaylCover` |
| Modify | `Vayl/Features/Map/MapView.swift` | Swap check-in `.vaylSheet` → `.vaylCover` |
| Modify | `Vayl/Core/Models/PulseEntry.swift` | Delete the dead `tier` computed property |
| Modify | `Vayl/Core/Models/Enums/AppPulseEnums.swift` | Delete the dead `PulseTier` enum |
| Delete | `Vayl/Features/Pulse/DailyCheckInView.swift`, `CheckInShell.swift`, `PulseCheckInCover.swift`, `PulseWidget.swift`, `PulseSheetView.swift`, `TierGuideSheet.swift` | Confirmed zero live callers |

---

## Build steps

### Step 1 (A1) — One position source, with the off-axis snap

Add the snap to `PulseAnswers.swift`, replacing the `position(...)` function body
(`PulseAnswers.swift:110-126`):

```swift
static func position(
    nervousSystem nervousSystemAnswer: String,
    focus focusAnswer: String,
    feeling feelingAnswer: String
) -> PulsePosition {
    let energyDelta     = delta(for: nervousSystemAnswer, in: nervousSystem, axis: .energy)
    let opennessDeltaQ2 = delta(for: focusAnswer,         in: focus,         axis: .openness)
    let opennessDeltaQ3 = delta(for: feelingAnswer,        in: feeling,       axis: .openness)

    let rawEnergy   = 0.5 + energyDelta * 0.5
    let rawOpenness = 0.5 + (opennessDeltaQ2 * 0.6 + opennessDeltaQ3 * 0.4) * 0.5

    return PulsePosition(energy: snap(rawEnergy), openness: snap(rawOpenness))
}

/// Nudges an exact-midline result (a genuinely neutral answer, e.g. "Stable") off the 0.5
/// boundary so it lands clearly inside a quadrant instead of riding the tie-break rule.
/// 🎚️ FEEL: the 0.16 offset and direction (push toward charged/open, matching
/// PulsePosition.quadrant's own tie rule) — confirm on device, don't re-derive.
private static func snap(_ value: Double) -> Double {
    guard abs(value - 0.5) < 0.001 else { return value }
    return 0.5 + 0.16
}
```

Then replace `PulseCheckInView.currentPosition` (`PulseCheckInView.swift:170-195`) to call it instead of
re-deriving the math:

```swift
private var currentPosition: PulsePosition {
    PulseAnswers.position(
        nervousSystem: answers[0] ?? "Stable",
        focus:         answers[1] ?? "Balanced",
        feeling:       answers[2] ?? "Content"
    )
}
```

*Done: `PulseCheckInView` has no inline energy/openness math; only `PulseAnswers.position` computes it.
A completed check-in with all-neutral answers ("Stable"/"Balanced"/"Content") lands clearly inside a
quadrant, not on a boundary.*

### Step 2 (A2) — Position is the only color source

In `commitEntry` (`PulseCheckInView.swift:223-242`), remove the Q4 override:

```swift
private func commitEntry() {
    let pos = currentPosition

    let entry = PulseEntry(
        date:          Date(),
        capacityScore: pos.capacityScore,
        glowColor:     pos.quadrant.capacityColor,
        speed:         answers[4] ?? "Light Connection",
        nervousSystem: answers[0] ?? "Stable",
        focus:         answers[1] ?? "Balanced",
        feeling:       answers[2] ?? "Content",
        position:      pos
    )
    store.add(entry)
    onClose()
}
```

Q4's answer (`answers[3]`) stays recorded on the entry as reflective metadata (the `PulseEntry` struct
already stores raw answers elsewhere in its init — do not remove `answers[3]` from anywhere it's
persisted, only stop it from overriding the color).

*Done: the committed orb color always equals `pos.quadrant.capacityColor` — never a Q4 override.*

### Step 3 (B1) — Drift spring token

Add to `AppAnimation.swift`, next to the existing aura timing constants (near line 803-811):

```swift
/// The check-in ball's position-change spring (Q1-Q3 drift). 🎚️ FEEL: confirm on device.
static let pulseBallDrift: Animation = .spring(response: 1.20, dampingFraction: 0.70)
```

Use it in `PulseCheckInView.selectPill` (`PulseCheckInView.swift:199-219`) — replace both
`withAnimation(AppAnimation.spring)` calls that touch `answers`/position with
`withAnimation(AppAnimation.pulseBallDrift)`, and in `PulseField.auraLayer`
(`PulseField.swift:111-125`) wrap the `.position(x:y:)` modifier with
`.animation(AppAnimation.pulseBallDrift, value: pt)` so the aura's on-screen move (not just the state
change) actually animates with this spring.

*Done: the check-in ball's drift between questions uses `pulseBallDrift`, not the generic `.spring`.*

### Step 4 (B2) — Idle float — BUILT THEN REVERTED, do not re-add

An opt-in `idleFloat` param was added to `PulseAura` exactly as originally specced here (additive,
`haloSpread`-style, wired only into the check-in's `rampOverride` path in `PulseField.auraLayer`), then
removed in full on Bryan's explicit device feedback: the ball should only move when it has a reason to
(drift on answer, via `pulseBallDrift`), never bob continuously at rest. **There is no idle-float
behavior in the shipped code** — `PulseAura` has no `idleFloat` param, `floatOffset` state, or
conditional block in `startAmbient()`. If a future pass considers re-adding ambient motion to the
check-in ball, that's a new product decision, not a resurrection of this step.

*Done: confirmed absent — `grep -rn "idleFloat" Vayl` returns zero results.*

### Step 5 (B3) — Silver-to-start

The ball should read neutral (silver) until both axes have a real answer, then color, and never revert.
Add a computed ramp to `PulseCheckInView`:

```swift
/// Silver (neutral) until the first axis-committed answer lands; then the quadrant color,
/// permanently — mirrors "the ball is the color of its position" once it has one.
private var currentRamp: AuraColors {
    guard answers[0] != nil || answers[1] != nil || answers[2] != nil else {
        return AuraColors(light: .white, core: Color(white: 0.7), deep: Color(white: 0.5), glow: Color.white.opacity(0.3))
    }
    return AuraColors(currentPosition.quadrant.capacityColor)
}
```

In `fieldSection` (`PulseCheckInView.swift:68-80`), `PulseFieldEntry` takes a `quadrant`-derived aura via
`PulseField.auraLayer` today, which always resolves color from `entry.quadrant.capacityColor`
(`PulseField.swift:120`) — that path has no ramp-override hook. Add one: change
`PulseFieldEntry` (`PulseField.swift:19-28`) to carry an optional ramp override:

```swift
struct PulseFieldEntry: Identifiable {
    var id: String = "primary"
    var position: PulsePosition
    var auraSize: CGFloat = 44
    var isBloom:  Bool    = false
    /// Overrides the position-derived ramp (e.g. the check-in's silver-to-start state).
    /// nil (default) = every existing caller is unaffected.
    var rampOverride: AuraColors? = nil

    var quadrant: PulseQuadrant { position.quadrant }
}
```

In `PulseField.auraLayer` (`PulseField.swift:111-125`), use it:

```swift
private var auraLayer: some View {
    GeometryReader { geo in
        ForEach(entries) { entry in
            let pt = fieldPoint(for: entry.position, in: geo.size)
            ZStack {
                if entry.isBloom {
                    BloomRing(color: entry.quadrant.capacityColor.auraCore, size: entry.auraSize)
                }
                if let ramp = entry.rampOverride {
                    PulseAura(ramp: ramp, size: entry.auraSize)
                } else {
                    PulseAura(quadrant: entry.quadrant, size: entry.auraSize)
                }
            }
            .position(x: pt.x, y: pt.y)
            .animation(AppAnimation.pulseBallDrift, value: pt)
        }
    }
}
```

Then `PulseCheckInView.fieldSection` passes `rampOverride: currentRamp` on its `PulseFieldEntry`.

*Done: the check-in ball starts silver, colors on the first Q1-Q3 answer, and never reverts to silver
afterward (since `currentRamp`'s guard only checks "any answer exists", not "the most recent one").*

### Step 6 (C1) — Full-screen check-in presentation

Both sites currently do:

```swift
.vaylSheet(
    isPresented: $showPulseCheckIn,   // or $showCheckIn in MapView
    heightFraction: 0.82,
    screenHeight: layout.screenHeight
) {
    PulseCheckInView(store: pulseStore, onClose: { showPulseCheckIn = false })
}
```

Replace with (same pattern at both `HomeDashboardView.swift:288-294` and `MapView.swift:57-63`):

```swift
.vaylCover(isPresented: $showPulseCheckIn, confirmOnExit: false) {
    PulseCheckInView(store: pulseStore, onClose: { showPulseCheckIn = false })
}
```

(`MapView.swift` uses `$showCheckIn` and `pulse` instead of `pulseStore` — same substitution, its own
variable names.) `confirmOnExit: false` because a check-in is a quick, low-stakes task, not a protected
two-device session — it doesn't need the confirm-on-exit guard `.vaylCover` reserves for Card Session.

*Done: `PulseCheckInView` is presented as a full-screen cover at both sites; `PulseField` inside it gets
real screen-derived geometry instead of a sheet's measured-content sizing (the bug that made it not
land reliably).*

### Step 7 (A3) — Delete dead code

Delete these 6 files entirely (all in `Vayl/Features/Pulse/`): `DailyCheckInView.swift`,
`CheckInShell.swift`, `PulseCheckInCover.swift`, `PulseWidget.swift`, `PulseSheetView.swift`,
`TierGuideSheet.swift`.

Delete `PulseEntry.tier` (`PulseEntry.swift:42-43`):

```swift
var tier: PulseTier {
    PulseTier.tier(for: capacityScore)
}
```

Delete the `PulseTier` enum (`AppPulseEnums.swift:60-101`) in full.

*Done: `grep -rn "PulseTier" Vayl` returns zero results; the 6 files no longer exist; build is green.*

---

## Definition of Done (build-green)

- [ ] `PulseCheckInView.currentPosition` calls `PulseAnswers.position(...)`; no duplicated math anywhere.
- [ ] All-neutral answers land off the exact 0.5/0.5 midline.
- [ ] `commitEntry` never overrides color from Q4 — `glowColor` always equals `pos.quadrant.capacityColor`.
- [ ] `AppAnimation.pulseBallDrift` exists and drives both the check-in's answer-driven drift and
      `PulseField`'s aura `.position` animation.
- [ ] The check-in ball sits dead-center (0.5/0.5) before any answer, and stays still except when it
      drifts to a newly-answered position — no continuous bob at any point (idle-float was reverted).
- [ ] The check-in ball starts silver and colors permanently on first answer.
- [ ] Both check-in presentation sites use `.vaylCover`, not `.vaylSheet`.
- [ ] The 6 dead files and `PulseTier` are gone; build is green with zero references to either.
- [ ] Zero raw literals introduced in any changed View.

## Bryan verifies on device

- Run a check-in start to finish: confirm the ball starts silver and dead-center, sits still until the
  first answer, then drifts on each Q1-Q3 answer with a visibly slower/heavier spring than before
  (`pulseBallDrift`), holding still between answers (no idle bob), and locks to its quadrant color
  permanently once any axis answer lands.
- Answer all-neutral ("Stable"/"Balanced"/"Content") and confirm the ball lands clearly inside a space,
  not hovering on a boundary — while leaving all three unanswered still shows it dead-center.
- Confirm the check-in now fills the whole screen (both from Home and from Map), the field is properly
  sized (not the old sheet-clipping bug), and swiping down/dismissing still works normally (no accidental
  confirm-on-exit prompt — this should feel exactly as easy to leave as it did as a sheet).
- 🎚️ Tune `pulseBallDrift`'s response/damping if the drift feels off.

## Constraints / do-not-touch

- Do not touch `HomePulseRail.swift`, `MapPulseHero.swift`, or `MapUsLayer.swift`'s rendering in this
  plan — applying the new drift/float behaviors to those surfaces is Plan 19's job (Phase E), which
  depends on this plan landing first.
- Do not add Supabase/network calls — this plan is entirely local (Store + View + Model layers).
- Do not change `PulseEntry`'s stored properties beyond removing the dead `tier` computed property —
  Q4/Q5 raw answers stay recorded.
- `PulseStore` stays UserDefaults-only (Phase G, unchanged, out of scope here).

## Open decisions

1. **`snap()`'s exact offset (0.16) and direction.** Recommended default: as written above (matches
   `PulsePosition.quadrant`'s own >=0.5 tie-break direction, so a neutral answer's fate is at least
   consistent with the existing rule, just no longer exactly on the boundary). 🎚️ Tune on device if the
   resulting space feels wrong for a genuinely neutral check-in.
2. **Pop-out choreography (the original Phase C2 idea — widget blooms open into the check-in, collapses
   back on close) vs. plain cover.** Recommended default: **plain cover**, per the original plan's own
   documented fallback. The choreography is a nice-to-have polish pass, not required for the presentation
   bug fix, and it's a meaningfully bigger, feel-driven build — defer it to a dedicated follow-up plan if
   Bryan wants it.
