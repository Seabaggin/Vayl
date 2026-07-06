# 22 — Pulse Teaching (the door + the first-landing annotation)

**Goal:** Implement teaching decision **3B** from the decided teaching-strategy spec
(`docs/superpowers/specs/2026-07-03-feature-teaching-strategy-design.md`): Pulse's invented
vocabulary (two axes, four spaces) and its sharing contract get (1) a permanent, optional reference
**door** (a real `PulseInfoSheet`, replacing the placeholder that exists today as unreachable dead
UI), and (2) a **once-ever annotated landing beat** inside the check-in, shown the first time a
user's check-in ever completes, teaching the map at the exact moment their own light first lands on
it. Nothing gates on reading anything; the check-in itself stays untouched as a flow.

**Architecture:** View-layer only, plus one enum computed property (Model) and one UserDefaults key.
No Store or Service changes; no schema changes.

---

> ## ⚡ ONE-SHOT LICENSE — convention override (read first)
>
> Same license as plans 16-21: implement this ENTIRE plan in ONE pass, build-green, no per-segment
> device stops. The license waives pacing only. Still mandatory: 4-layer architecture, tokens only
> (no raw color/font/spacing/radius/opacity/animation literals in Views), `.vaylCover`/`.vaylSheet`
> grammar, iOS 26 compliance, Reduce Motion fallbacks, press-state + haptic + action on every tap
> target. Every file path and symbol below was verified against the repo on **2026-07-03** (after
> the Pulse finalization pass landed). If reality differs, trust the repo and note the drift.
>
> Verification is deferred to Bryan's device pass (he runs the app himself; compile-green is your
> finish line). Items marked 🎚️ are feel/copy values Bryan tunes on device.

---

## Context Fable needs

- **Pulse just reached "final" (A-E)** per `docs/handoffs/2026-07-03-pulse-finalization-goal.md`.
  Bryan's on-device pass (F) is still pending, and THIS plan deliberately lands before it so the
  check-in surface gets verified once, not twice. Be surgical in `PulseCheckInView` — the aura
  drift/hitch behavior was a hard-won fix; this plan must not touch `selectPill`, `currentPosition`,
  `currentRamp`, `PulseAnswers`, `PulseAura`, or any `AppAnimation` member.
- **The door already has wiring on Home.** `PulseInfoSheet` exists as a placeholder struct at the
  bottom of `HomePulseRail.swift` (~line 199: a void + "About the Pulse" text, nothing else).
  `HomeDashboardView.swift` already presents it via
  `.vaylSheet(isPresented: $showPulseInfo, heightFraction: 0.75, screenHeight: layout.screenHeight)`
  (~line 331) — but `showPulseInfo` (declared line 94) is **never set true anywhere**. The sheet is
  unreachable dead UI. This plan makes the sheet real and gives it two entry points.
- **The check-in's landing beat** is `PulseCheckInView.bloomReveal` (space name + sublabel + Done
  button), shown when `bloomDone` flips true after Q5 (`selectPill`, line ~299). The check-in's
  `PulseField` is rendered at size 264 **without** axis labels (`fieldSection`, line ~148);
  `PulseField` already supports `showAxisLabels: Bool` (renders Charged/Depleted/Guarded/Open rim
  labels).
- **Vocabulary single source of truth:** `PulseQuadrant` (`AppPulseEnums.swift`, line ~60) already
  owns `spaceName` and `sublabel`. The four per-space character one-liners currently live privately
  in `MapPulseHero.swift`'s `MapFieldSheet.descCopy` ("High energy and open. A good day to connect
  and explore." etc.). Step 1 promotes them onto `PulseQuadrant` so the info sheet and the field
  sheet share one copy source.
- **First-run flag pattern:** `UserDefaultsKey` (`Vayl/Core/Models/Enums/UserDefaultsKey.swift`) is
  the canonical home for these (`hasCompletedCoupleSession` is the precedent). Not server-persisted
  by design: a lost flag on reinstall means one harmless re-teach.
- **Sharing-contract copy anchor:** Settings promises "Your partner sees your Pulse capacity, not
  your answers." (`SettingsPrivacyView.swift`). The info sheet's sharing line must agree with it.
- **No em dashes in any user-facing copy** (standing Vayl copy rule; use commas/periods/colons).

## Files

| Action | File | Responsibility |
|---|---|---|
| Modify | `Vayl/Core/Models/Enums/AppPulseEnums.swift` | `PulseQuadrant.characterLine` (promoted from MapFieldSheet) |
| Create | `Vayl/Features/Pulse/Components/PulseInfoSheet.swift` | The real door: axes, four spaces, sharing contract |
| Modify | `Vayl/Features/Home/Components/HomePulseRail.swift` | Delete the placeholder `PulseInfoSheet`; add `onInfo` + dormant-state "what is this?" affordance |
| Modify | `Vayl/Features/Home/Views/HomeDashboardView.swift` | Wire `onInfo` → `showPulseInfo = true` (presentation already exists) |
| Modify | `Vayl/Features/Map/Components/MapPulseHero.swift` | `onInfo` affordance in `sectionHeader`; `MapFieldSheet.descCopy` delegates to `characterLine` |
| Modify | `Vayl/Features/Map/MapView.swift` | Own the info-sheet presentation for the Map entry point (matches its existing `showPulseSheet` `.vaylSheet` pattern, line ~68) |
| Modify | `Vayl/Core/Models/Enums/UserDefaultsKey.swift` | `hasSeenPulseFieldAnnotation` |
| Modify | `Vayl/Features/Pulse/PulseCheckInView.swift` | Once-ever two-beat annotation before the bloom reveal |

The app target auto-joins new files (only VaylTests needs manual pbxproj wiring), so
`PulseInfoSheet.swift` needs no project-file edit.

## Build steps

### Step 1 — Promote the space character lines onto `PulseQuadrant`

In `AppPulseEnums.swift`, after `sublabel` (line ~82), add:

```swift
/// One-sentence character of each space, in second person where it applies.
/// Single copy source for MapFieldSheet's description and PulseInfoSheet's
/// space rows (was duplicated privately in MapFieldSheet.descCopy).
var characterLine: String {
    switch self {
    case .expansive:  return "High energy and open. A good day to connect and explore."
    case .friction:   return "High energy, turned inward. Things feel charged right now."
    case .sovereign:  return "Grounded and open, moving at your own pace."
    case .protective: return "Low energy and guarded. You need space right now."
    }
}
```

In `MapPulseHero.swift`, replace `MapFieldSheet.descCopy`'s switch body with a delegation:

```swift
private var descCopy: String { quadrant.characterLine }
```

### Step 2 — The real `PulseInfoSheet`

Delete the placeholder `struct PulseInfoSheet` from the bottom of `HomePulseRail.swift` entirely.
Create `Vayl/Features/Pulse/Components/PulseInfoSheet.swift`:

```swift
// Features/Pulse/Components/PulseInfoSheet.swift
//
// The Pulse's "door" (teaching spec 2026-07-03, Tier 4): an always-optional
// reference sheet for the invented vocabulary (two axes, four spaces) and the
// sharing contract. Presented via .vaylSheet by its hosts (HomeDashboardView,
// MapView); never a gate, never shown unprompted.

import SwiftUI

struct PulseInfoSheet: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("The Pulse")
                    .font(AppFonts.cardTitleCompact)
                    .foregroundStyle(AppColors.textPrimary)

                Text("A daily reading of your capacity: how much energy you have, and how open you feel. Five quick questions place you on the map. It's a reading, not a grade.")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    axisRow("Charged · Depleted", detail: "the vertical axis, your energy")
                    axisRow("Open · Guarded",     detail: "the horizontal axis, how approachable the world feels")
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ForEach(PulseQuadrant.allCases, id: \.self) { quadrant in
                        spaceRow(quadrant)
                    }
                }

                Text("Your partner sees where you are on the map, never your answers.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xl)
        }
    }

    private func axisRow(_ label: String, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
            Text(label)
                .font(AppFonts.buttonLabelSmall)
                .foregroundStyle(AppColors.textPrimary)
            Text(detail)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
    }

    private func spaceRow(_ quadrant: PulseQuadrant) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
            Circle()
                .fill(quadrant.capacityColor.auraCore)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(quadrant.spaceName)
                    .font(AppFonts.buttonLabelSmall)
                    .foregroundStyle(AppColors.textPrimary)
                Text(quadrant.characterLine)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
```

Verify before using: `PulseQuadrant` must be `CaseIterable` (add conformance in
`AppPulseEnums.swift` if it isn't; it's a plain 4-case enum, so `enum PulseQuadrant: CaseIterable`
plus whatever raw type it already has). Verify `capacityColor.auraCore` is the right member for the
dot (it's what `MapUsLayer` uses for aura tints); if the type differs, match `MapUsLayer`'s usage
exactly.

### Step 3 — Entry point 1: Home's dormant card

`HomePulseRail.swift`: add an optional info callback and thread it into the dormant state only
(the active state's door lives on the Map hero, where the user lands when they tap the card).

```swift
var onTap:     (() -> Void)? = nil   // → Map Pulse
var onCheckIn: (() -> Void)? = nil   // → check-in
var onInfo:    (() -> Void)? = nil   // → PulseInfoSheet (dormant state only)
```

In the dormant branch of `body`, the `card(...)` call currently passes `timestamp: nil`. Add a
trailing affordance instead: give `card(...)` a new optional parameter
`infoAction: (() -> Void)? = nil`, rendered at the bottom of the sub-block:

```swift
// inside card(...)'s sub-block VStack, after the timestamp:
if let infoAction {
    Button {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        infoAction()
    } label: {
        Text("what is this?")
            .font(AppFonts.caption)
            .foregroundStyle(AppColors.textTertiary)
            .underline()
    }
    .buttonStyle(_PressableTextStyle())
}
```

Pass `infoAction: onInfo` in the dormant `card(...)` call only; the active call passes nothing
(default nil keeps it identical). For the press style, reuse the file's existing idiom: if no
ButtonStyle exists in this file, add a private one matching `_RaterPressStyle` in
`DesireMapView.swift` (scaleEffect 0.95 on `configuration.isPressed`, `AppAnimation.fast`) — name
it `_PressableTextStyle`, private to this file. The Button-inside-tappable-card layering already
works here (`checkInPill` is the precedent; the inner Button wins its own hit area).

`HomeDashboardView.swift`: at the `HomePulseRail(...)` call site inside `pulseModule(columnWidth:)`
(~line 343), add:

```swift
onInfo: { showPulseInfo = true }
```

That's the whole Home wiring — `showPulseInfo`'s `.vaylSheet` presentation already exists and now
becomes reachable.

### Step 4 — Entry point 2: the Map hero

`MapPulseHero.swift`: add `var onInfo: () -> Void` alongside `onCheckIn`/`onOpenHistory` (make it a
required closure like the others; MapView is the only caller). In `sectionHeader`, before the
"tap to map →" button, add a quiet icon button:

```swift
Button {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    onInfo()
} label: {
    Image(systemName: "questionmark.circle")
        .font(AppFonts.caption)
        .foregroundStyle(AppColors.textMuted)
        .frame(width: 24, height: 24)
        .contentShape(Rectangle())
}
.buttonStyle(.plain)
.accessibilityLabel("About the Pulse")
```

Place it so it is present in BOTH the has-history and empty states (outside the `if hasHistory`
guard that currently wraps "tap to map →") — the door is permanent, not state-dependent.

`MapView.swift`: add `@State private var showPulseInfo = false`, pass
`onInfo: { showPulseInfo = true }` at the `MapPulseHero(...)` call site (line ~183), and attach the
presentation next to the existing `showPulseSheet` `.vaylSheet` (line ~68), matching that call
site's `heightFraction`/`screenHeight` idiom exactly:

```swift
.vaylSheet(isPresented: $showPulseInfo, heightFraction: 0.75 /* match the file's existing pattern for screenHeight */) {
    PulseInfoSheet()
}
```

Read the existing `showPulseSheet` call first and mirror its parameters — if it passes
`screenHeight:`, pass the same source; if not, don't.

Also update `MapPulseHero`'s `#Preview` to pass the new `onInfo: {}`.

### Step 5 — The once-ever landing annotation (decision 3B)

`UserDefaultsKey.swift`, after `hasCompletedCoupleSession`:

```swift
/// Set true after the check-in's one-time two-beat field annotation has played
/// (teaching decision 3B, spec 2026-07-03). Deliberately not server-persisted:
/// a lost flag on reinstall means one harmless re-teach.
static let hasSeenPulseFieldAnnotation = "vayl.hasSeenPulseFieldAnnotation"
```

`PulseCheckInView.swift` — the surgical part. Add one state property beside `bloomDone` (line ~30):

```swift
/// nil = not teaching. 1/2 = the two worded annotation beats that play once
/// ever (UserDefaultsKey.hasSeenPulseFieldAnnotation), between Q5's bloom and
/// the space-name reveal, teaching the axes the first time the user's own
/// light lands on the map. 3 = beats done, show the normal bloomReveal.
@State private var teachBeat: Int? = nil
```

In `selectPill(_:qIndex:)`, where `bloomDone = true` is set (inside the
`if qIndex == PulseAnswers.all.count - 1` branch), add the trigger BEFORE the flag flip:

```swift
if !UserDefaults.standard.bool(forKey: UserDefaultsKey.hasSeenPulseFieldAnnotation) {
    teachBeat = 1
}
bloomDone = true
```

In `revisit(_:)`, where `bloomDone = false` is reset, also reset `teachBeat = nil` (revisiting an
answer and re-finishing restarts the teach cleanly; the flag is only written when the beats
complete, so this stays consistent).

`fieldSection` (line ~148): turn the rim labels on while teaching, off otherwise (existing behavior
preserved exactly when `teachBeat == nil`):

```swift
PulseField(
    entries: [ /* unchanged */ ],
    size: 264,
    showAxisLabels: teachBeat != nil
)
```

In `body`, the landing branch currently reads `if bloomDone { bloomReveal } else { questionSection }`.
Change to:

```swift
if bloomDone {
    if let beat = teachBeat, beat < 3 {
        annotationBeat(beat)
    } else {
        bloomReveal
    }
} else {
    questionSection
}
```

Add the beat view near `bloomReveal`:

```swift
// MARK: - First-landing annotation (once ever — teaching decision 3B)

/// Two worded beats before the first-ever bloom reveal. Tap anywhere on the
/// panel to advance; the third tap lands in the normal reveal and writes the
/// seen-flag. Words + choreography, per the teaching spec (implicit-only
/// teaching is banned); tap-driven, so no Reduce Motion concern.
private func annotationBeat(_ beat: Int) -> some View {
    VStack(spacing: AppSpacing.md) {
        Text(beat == 1
             ? "This is your map. Up is charged, down is depleted."
             : "Right is open, left is guarded. It's a reading, not a grade.")
            .font(AppFonts.prompt)
            .foregroundStyle(AppColors.textPrimary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)

        Text("tap to continue")
            .font(AppFonts.caption)
            .foregroundStyle(AppColors.textTertiary)
    }
    .padding(.top, AppSpacing.lg)
    .frame(maxWidth: .infinity)
    .contentShape(Rectangle())
    .onTapGesture {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(AppAnimation.standard) {
            if beat >= 2 {
                teachBeat = 3
                UserDefaults.standard.set(true, forKey: UserDefaultsKey.hasSeenPulseFieldAnnotation)
            } else {
                teachBeat = beat + 1
            }
        }
    }
    .id(beat)
    .transition(.asymmetric(
        insertion: .opacity.combined(with: .offset(x: 0, y: 6)),
        removal:   .opacity.combined(with: .offset(x: 0, y: -6))
    ))
}
```

🎚️ Beat copy is a draft for Bryan's editorial pass. Do NOT touch `selectPill`'s drift block,
`currentPosition`, `currentRamp`, `commitEntry`, or the `advancing` debounce.

### Step 6 — Compile check

`xcodebuild -scheme Vayl -destination 'generic/platform=iOS Simulator' -configuration Debug build`
must succeed. Also grep-verify: zero remaining references to the deleted placeholder location
(`HomePulseRail.swift` no longer declares `PulseInfoSheet`), and `showPulseInfo` now has a setter.

## Definition of Done (build-green)

- [ ] `PulseQuadrant.characterLine` exists; `MapFieldSheet.descCopy` delegates to it; the field
      sheet's rendered copy is character-for-character what it was before.
- [ ] `PulseInfoSheet.swift` is a real sheet (axes, four spaces from `PulseQuadrant.allCases`,
      sharing line agreeing with `SettingsPrivacyView`'s promise); the placeholder in
      `HomePulseRail.swift` is gone.
- [ ] Home dormant card shows "what is this?" and it opens the sheet (the previously-dead
      `showPulseInfo` wiring now fires); the active card is unchanged.
- [ ] Map hero's header shows the `questionmark.circle` door in both empty and has-history states;
      it opens the same sheet via MapView.
- [ ] First-ever check-in completion: bloom → beat 1 → beat 2 → normal reveal, axis labels on
      during the teach; `hasSeenPulseFieldAnnotation` written on beat 2's tap.
- [ ] Every later check-in completion is pixel-identical to today (no beats, no axis labels).
- [ ] `revisit()` during the teach resets cleanly (re-finishing restarts at beat 1).
- [ ] Zero new raw literals in Views beyond copy strings; every new tap target has press feedback +
      haptic + action.
- [ ] No em dashes in any new copy.

## Bryan verifies on device

- Fresh install (or clear the flag): complete a check-in, confirm the two beats read well, tap
  through, land in the reveal. Re-run a check-in: confirm no beats.
- Mid-teach, tap a step number to revisit an answer, re-finish: confirm the teach restarts rather
  than half-playing.
- Home dormant: "what is this?" opens the sheet; sheet copy reads as Vayl. Map hero: the `?` opens
  the same sheet from both empty and populated states.
- 🎚️ Wordsmith: beat copy, axis detail lines, space character lines (they now render in two places).
- Confirm the check-in aura still behaves exactly as before (drift on answer, no hitch) — this is
  the surface the Pulse finalization pass just stabilized.

## Constraints / do-not-touch

- Do not touch `PulseAnswers.swift`, `PulseAura.swift`, `PulseStore.swift`, `PulseSyncService.swift`,
  `AppAnimation.swift`, or `PulseField`'s aura layer/drift animation.
- Do not add a Pulse reminder, streak, or any additional teach trigger — the door is optional and
  the annotation plays once, ever.
- `.vaylSheet` only for the door (both hosts); no raw `.sheet`.

## Open decisions

1. 🎚️ Beat copy + info-sheet copy phrasing: defaults as written, Bryan wordsmiths on device.
2. Whether the active Home card also gets the door: default NO (tap already leads to the Map hero,
   which has it); revisit only if device feel disagrees.
