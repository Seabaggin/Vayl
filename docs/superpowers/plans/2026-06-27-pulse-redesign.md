# Pulse Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Pulse's 1D capacity graph with the 2D circumplex model + the "living caustic under glass" aura, across Map (hero) and Home (widget), keeping the existing data plumbing and check-in question logic.

**Architecture:** Vayl is a SwiftUI iOS app, 4-layer (View / Store / Service / Model), design-token-driven, dark-first. Capacity becomes a 2D point (energy × openness) whose quadrant is one of the existing `PulseTier` "Spaces." The aura is a reusable token-driven component. The check-in keeps its Q1-Q5 answer logic but feeds two axes and resolves into the field + an aura bloom instead of a line draw.

**Tech Stack:** Swift 6, SwiftUI, `@Observable @MainActor` stores, UserDefaults + Supabase (capacity sync), XCTest (`VaylTests`, app-hosted).

## VISUAL SOURCE OF TRUTH — open these in a browser before each visual segment

These HTML mockups ARE the visual spec. The CSS in them is the reference implementation to port to SwiftUI (layer order, gradients, geometry, motion cadence). Open the file with `open <path>` or in a browser. Do not invent the look; match these.

- **`docs/prototypes/pulse-aura-glass.html`** — the aura ("living caustic under glass"): the four layers (body / drifting caustic / incremental glass sweep / rim) shown across all four tier colours. → **Segment 2**.
- **`docs/prototypes/map-pulse-us.html`** — the 2D field (corner colour zones + Charged/Quiet/Guarded/Open axis labels, no grid), the **Us comparison** (two auras + the enclosing **capsule**, both a wide-day and a same-space state), and the **last-30-logged split-circle grid**. The capsule + orb geometry in this file is the *fixed, working* version: a CSS stadium living in the SAME coordinate space as the percentage-positioned orbs (NOT an SVG viewBox — that mismatch was the bug). Replicate that approach. → **Segments 3, 4, 5**.
- **`docs/prototypes/map-pulse-final.html`** — the three Map panels together: glance (aura hero), your-map (field = NOW only), Us. → **Segment 4**.
- **`docs/prototypes/home-pulse-aura.html`** — the Home Pulse widget, dormant ("tap to check in") and active rows. → **Segment 6**.
- **`docs/handoffs/2026-06-27-pulse-design-handoff.md`** — full design rationale, every settled decision, the non-negotiable guardrails, and the real tokens. **READ THIS FIRST.**

**Executor note (Sonnet):** you have zero conversation context; the handoff above is your context. Follow the segments in order. Logic/data segments are TDD and you finish them. Visual segments compile-verify only, then STOP and hand to the human for the on-device feel pass before continuing (build-protocol rule).

---

## Build-protocol contract (READ FIRST)

This is a Vayl build, so this plan obeys `CLAUDE.md`'s Build Protocol, NOT pure web-TDD:
- **Segments, not one pass.** Each `## Segment N` below is one build-protocol segment: ONE job, a **done-condition verified on device**, and a **constraints list** (files it may not touch).
- **Logic/data/model tasks use real TDD** (write failing XCTest → run → implement → pass → commit). Concrete test + impl code is given.
- **Visual tasks compile-verify only, then feel on device.** Claude does NOT run the simulator or guess feel values (glow radii, animation timings); those are tuned on device against the HTML mockup. The plan gives the component's **structure, layers, and token usage**; exact feel constants are marked `// FEEL: tune on device vs <mockup>`.
- **A segment is not done until Bryan confirms the feel on device.** Do not start the next segment until then.
- Commit frequently. Branch off `master` (or current feature branch) first; never commit on `master`.
- No raw values in Views (tokens only). No em dashes in copy.
- Run the test suite with: `xcodebuild test -scheme VaylTests -destination "platform=iOS Simulator,name=iPhone 16 Pro"` (adjust device name to an installed sim). Compile-check the app with: `xcodebuild build -scheme Vayl -destination "platform=iOS Simulator,name=iPhone 16 Pro"`.

---

## What changes vs what stays

**STAYS (reused):**
- `PulseStore` (add/remove/entries, UserDefaults `pulse.entries.v1`) + the env-injection pattern.
- The check-in **answer logic** (Q1-Q5 pills, the deltas) in `DailyCheckInView` — repurposed to two axes.
- `PulseSyncService` shape (extended to carry 2 axes).
- `PulseTier` names ("The Expansive/Sovereign/Friction/Protective Space") become the four **quadrants**.
- `.vaylCover` / `.vaylSheet`, the Map masthead Me/Us toggle (`MapStore.layer`), the Home 3-module layout.

**REPLACED (retired or rebuilt):**
- `PulseGraph` / `PulseGraphCanvas` (the line chart) → the **PulseField** (2D circumplex) + grid.
- `DailyCheckInView`'s cinematic camera/line-draw resolution → the **aura-bloom-in-field** ceremony.
- `PulseDotSummary` (burn overlay) → a day-detail sheet on the field (later/optional).
- `MapPulseHero` / `MapUsLayer`'s graph → the aura glance / field / Us comparison.
- `HomePulseRail`'s graph → the **compact aura widget** (dormant/active).
- The 1D `capacityScore`-only model → adds `energy` + `openness`.

**NEW components:**
- `PulseAura` (reusable living-caustic-under-glass view).
- `PulseField` (the 2D atmospheric quadrant space, with zones + axis labels).
- `PulseCapsule` (the Us connector — a CSS-mockup-equivalent enclosing capsule).
- `PulseHistoryGrid` (last-30-logged; Me solid / Us split).
- `PulseCheckInView` (the new field-based ceremony) replacing the graph ceremony.

---

## File structure (create / modify / retire)

**Create:**
- `Vayl/Core/Models/PulsePosition.swift` — the 2D model + quadrant resolution (pure logic).
- `Vayl/Features/Pulse/Components/PulseAura.swift` — the aura view.
- `Vayl/Features/Pulse/Components/PulseField.swift` — the 2D field (zones, axes, places auras).
- `Vayl/Features/Pulse/Components/PulseCapsule.swift` — the Us enclosing capsule.
- `Vayl/Features/Pulse/Components/PulseHistoryGrid.swift` — last-30 grid (Me + Us split).
- `Vayl/Features/Pulse/CheckIn/PulseCheckInView.swift` — the new ceremony (field + bloom).
- `Vayl/Core/Models/PulseHistory.swift` — last-30-logged derivations (pure logic).
- `VaylTests/PulsePositionTests.swift`, `VaylTests/PulseHistoryTests.swift`.

**Modify:**
- `Vayl/Core/Models/PulseEntry.swift` — add `energy`, `openness`; keep `capacityScore` derived.
- `Vayl/Features/Pulse/DailyCheckInView.swift` — emit `energy`/`openness` from the answers.
- `Vayl/Core/Services/PulseSyncService.swift` — sync the 2-axis partner position.
- `Vayl/Features/Map/MapView.swift` + `MapStore.swift` — Me glance/field, Us comparison.
- `Vayl/Features/Home/Components/HomePulseRail.swift` — the aura widget.
- `Vayl/Core/Models/Enums/AppPulseEnums.swift` — `PulseQuadrant` + axis copy.

**Retire (delete after their replacements ship + compile):**
- `PulseGraph.swift`, `PulseGraphCanvas` (whatever file holds it), `CheckInShell.swift`'s graph half, `PulseDotSummary.swift` (unless the day-detail reuses its burn — decide in Segment 6).

> Retire LAST (Segment 8), only once nothing references them, to keep each prior segment compiling.

---

## Segment 1 — The 2D capacity model (logic, TDD)

**Goal:** Capacity is a 2D point (energy × openness) that resolves to one of the four quadrants/Spaces. Pure logic, fully tested, no UI.

**Done-condition:** `PulsePositionTests` pass; app still compiles; no visual change.

**Constraints — may NOT touch:** any View file, `PulseGraph*`, `PulseSyncService`, the check-in UI. Model + enums only.

**Files:**
- Create: `Vayl/Core/Models/PulsePosition.swift`
- Modify: `Vayl/Core/Models/Enums/AppPulseEnums.swift` (add `PulseQuadrant`)
- Modify: `Vayl/Core/Models/PulseEntry.swift`
- Test: `VaylTests/PulsePositionTests.swift`

- [ ] **Step 1: Add `PulseQuadrant` to `AppPulseEnums.swift`.** Append:
```swift
/// The four quadrants of the capacity circumplex (energy × openness).
/// These are the same four "Spaces" as PulseTier, addressed two-dimensionally.
enum PulseQuadrant: String, CaseIterable, Codable {
    case expansive   // charged + open   (top-right)
    case friction    // charged + guarded(top-left)
    case sovereign   // quiet  + open    (bottom-right)
    case protective  // quiet  + guarded (bottom-left)

    /// The display "Space" name + sublabel (matches PulseTier copy).
    var spaceName: String {
        switch self {
        case .expansive:  return "The Expansive Space"
        case .friction:   return "The Friction Space"
        case .sovereign:  return "The Sovereign Space"
        case .protective: return "The Protective Space"
        }
    }
    var sublabel: String {
        switch self {
        case .expansive:  return "Connected · Adventurous"
        case .friction:   return "Anxious · Defensive"
        case .sovereign:  return "Grounded · Secure"
        case .protective: return "Overwhelmed · Need Space"
        }
    }
    /// Capacity-tier colour token for the aura body (resolved in AppColors).
    var capacityColor: PulseCapacityColor {
        switch self {
        case .expansive:  return .cyan      // Abundant
        case .sovereign:  return .indigo    // Good
        case .friction:   return .magenta   // Low
        case .protective: return .rose      // Empty
        }
    }
}
```
(Axis copy "Charged / Quiet / Guarded / Open" lives in the View, not here.)

- [ ] **Step 2: Create `PulsePosition.swift`.**
```swift
import Foundation

/// A capacity reading as a point in the circumplex.
/// Axes are normalised 0...1: energy 0 = quiet, 1 = charged; openness 0 = guarded, 1 = open.
struct PulsePosition: Equatable, Codable {
    var energy: Double      // 0...1 (vertical)
    var openness: Double    // 0...1 (horizontal)

    init(energy: Double, openness: Double) {
        self.energy   = Self.clamp(energy)
        self.openness = Self.clamp(openness)
    }

    private static func clamp(_ v: Double) -> Double { max(0, min(1, v)) }

    /// Which quadrant this point falls in. Midline (0.5) ties resolve toward the higher/open side.
    var quadrant: PulseQuadrant {
        let charged = energy >= 0.5
        let open    = openness >= 0.5
        switch (charged, open) {
        case (true,  true):  return .expansive
        case (true,  false): return .friction
        case (false, true):  return .sovereign
        case (false, false): return .protective
        }
    }

    /// Distance to another reading (for the Us "wide vs close" read). 0 = same point, ~1.41 = opposite corners.
    func distance(to other: PulsePosition) -> Double {
        let de = energy - other.energy
        let dop = openness - other.openness
        return (de * de + dop * dop).squareRoot()
    }

    /// Legacy 1D capacity score (1...4) derived from energy, so existing tier callers keep working.
    var capacityScore: Double { 1 + energy * 3 }
}
```

- [ ] **Step 3: Extend `PulseEntry.swift`.** Add `position`; keep `capacityScore` as a stored field for backward-compatible decoding, but prefer `position`. Modify the struct to:
```swift
struct PulseEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var capacityScore: Double               // kept for back-compat decode
    var glowColor: PulseCapacityColor
    var speed: String
    var nervousSystem: String
    var focus: String
    var feeling: String
    var position: PulsePosition?            // NEW; nil for pre-redesign entries

    /// Effective position: the new field, or reconstructed from legacy capacityScore (openness defaults to mid).
    var resolvedPosition: PulsePosition {
        position ?? PulsePosition(energy: (capacityScore - 1) / 3, openness: 0.5)
    }
    var quadrant: PulseQuadrant { resolvedPosition.quadrant }
}
```
(Decoding old entries: `position` is an optional key, so old JSON still decodes. Do NOT remove `capacityScore`.)

- [ ] **Step 4: Write the failing tests `VaylTests/PulsePositionTests.swift`.**
```swift
import XCTest
@testable import Vayl

final class PulsePositionTests: XCTestCase {
    func test_quadrants_byCorner() {
        XCTAssertEqual(PulsePosition(energy: 0.9, openness: 0.9).quadrant, .expansive)
        XCTAssertEqual(PulsePosition(energy: 0.9, openness: 0.1).quadrant, .friction)
        XCTAssertEqual(PulsePosition(energy: 0.1, openness: 0.9).quadrant, .sovereign)
        XCTAssertEqual(PulsePosition(energy: 0.1, openness: 0.1).quadrant, .protective)
    }
    func test_clampsOutOfRange() {
        let p = PulsePosition(energy: 2, openness: -1)
        XCTAssertEqual(p.energy, 1); XCTAssertEqual(p.openness, 0)
    }
    func test_distance_oppositeCorners_isLargest() {
        let a = PulsePosition(energy: 1, openness: 1)
        let b = PulsePosition(energy: 0, openness: 0)
        XCTAssertEqual(a.distance(to: b), 2.0.squareRoot(), accuracy: 0.0001)
        XCTAssertEqual(a.distance(to: a), 0, accuracy: 0.0001)
    }
    func test_legacyEntry_reconstructsPosition() {
        let e = PulseEntry(date: Date(), capacityScore: 4, glowColor: .cyan,
                           speed: "x", nervousSystem: "x", focus: "x", feeling: "x", position: nil)
        XCTAssertEqual(e.resolvedPosition.energy, 1, accuracy: 0.0001)
        XCTAssertEqual(e.quadrant, .sovereign) // energy 1 + openness 0.5 → charged + open boundary → sovereign? see note
    }
    func test_capacityScore_roundTrip() {
        XCTAssertEqual(PulsePosition(energy: 1, openness: 0.5).capacityScore, 4, accuracy: 0.0001)
        XCTAssertEqual(PulsePosition(energy: 0, openness: 0.5).capacityScore, 1, accuracy: 0.0001)
    }
}
```
> NOTE for the implementer: decide the midline tie rule (openness 0.5 with energy 1 → `expansive` if `>=` is used). Fix the test expectation to match the chosen rule; the rule must be deterministic and documented in `PulsePosition.quadrant`.

- [ ] **Step 5: Run, watch fail, implement to green.**
Run: `xcodebuild test -scheme VaylTests -only-testing:VaylTests/PulsePositionTests -destination "platform=iOS Simulator,name=iPhone 16 Pro"`
Expected first run: FAIL (types missing). Then PASS after Steps 1-3.

- [ ] **Step 6: Compile the app** (`xcodebuild build -scheme Vayl …`). Existing `PulseEntry(...)` call sites now need the new `position:` arg — add `position: nil` at each (search `PulseEntry(`), including `PulseEntry.previews`. Expected: build succeeds.

- [ ] **Step 7: Commit.** `git commit -m "feat(pulse): 2D circumplex capacity model (PulsePosition + quadrants)"`

---

## Segment 1B — Extract reusable logic + gut the view layer to stubs (clear the ground)

**Goal:** Clear the dead 1D-graph view layer up front so the new components build into a clean, compiling space. The data/logic layer stays; only Views are gutted. This is the gut-first decision: do not carry dead graph code through the visual segments.

**Done-condition:** the app compiles with the Pulse views reduced to empty/placeholder stubs; the reusable check-in answer logic is extracted into a pure model; the dead graph components are deleted; every remaining compile error is captured as the "wiring checklist" for Segments 2-7.

**Constraints — may NOT touch:** `PulseStore`, `PulseEntry` (Segment 1 already extended it), `PulseSyncService`, `AppPulseEnums` data/logic. Do NOT build any new visuals here. Views and deletions only.

- [ ] **Step 1: Extract the check-in answer logic** out of `DailyCheckInView` into a pure model `Vayl/Core/Models/PulseAnswers.swift`: the Q1-Q5 pill definitions (label + delta + glow) and `static func position(nervousSystem:focus:feeling:) -> PulsePosition` (the energy/openness mapping that Segment 3 will consume). This survives the gutting. Add `VaylTests/PulseAnswersTests.swift` later in Segment 3 (or now if convenient).
- [ ] **Step 2: Delete the pure-dead graph stack.** Search first: `grep -rn "PulseGraph\|PulseGraphCanvas\|PulseDotSummary" Vayl`. Then delete `PulseGraph.swift`, the `PulseGraphCanvas` file, `PulseDotSummary.swift`, and the cinematic camera/line-draw resolution code inside `DailyCheckInView`/`CheckInShell`. Remove their pbxproj references.
- [ ] **Step 3: Stub the host/integration views.** Reduce each to a minimal compiling placeholder that KEEPS its public init signature + callbacks (so callers compile): `MapPulseHero`, `MapUsLayer`, `HomePulseRail`, `PulseWidget`, `CheckInShell`, `PulseSheetView`, `PulseFullView`. Body = a small placeholder (e.g. `Color.clear` or a `Text("Pulse").foregroundStyle(AppColors.textMuted)`), no graph.
- [ ] **Step 4: Compile the app.** `xcodebuild build -scheme Vayl -destination "platform=iOS Simulator,name=iPhone 16 Pro"`. Fix any straggler references until green. Record the seams (each stub) as the wiring checklist for the build segments.
- [ ] **Step 5: Commit.** `git commit -m "chore(pulse): extract answer logic + gut 1D graph views to stubs"`

---

## Segment 2 — The PulseAura component (visual, compile + feel)

**Goal:** A reusable `PulseAura` view: "living caustic under glass" — tier-colour body + drifting caustic + the StatPhase glass sweep (incremental, ~8s) + rim. Parameterised by quadrant/colour + size. Matches `pulse-aura-glass.html` across all four tiers.

**Done-condition:** renders at hero (≈150pt), field (≈44pt), and widget (≈32pt) sizes; the glass sweep crosses once then rests; reduce-motion shows a static aura; **Bryan confirms the feel on device** against the mockup.

**Visual reference:** `docs/prototypes/pulse-aura-glass.html` — port its layer order and gradients directly: `.body` (radial tier colour, no 3D specular), `.caustic` (screen-blended drifting light blobs), `.glass` (the `@keyframes sweep` incremental specular band, the StatPhase recipe), `.rim` (inset highlight). The four tier blocks (`.cyan/.indigo/.magenta/.rose`) define each quadrant's colour ramp.

**Constraints — may NOT touch:** the field, check-in, Map, Home, or any store/service. One new self-contained component file + a `#Preview`.

**Files:** Create `Vayl/Features/Pulse/Components/PulseAura.swift`.

- [ ] **Step 1: Scaffold the component.** Port the four HTML layers (body / caustic / glass sweep / rim) to SwiftUI. Structure (feel constants tuned on device):
```swift
import SwiftUI

struct PulseAura: View {
    let quadrant: PulseQuadrant
    var size: CGFloat = 44

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sweepX: CGFloat = -0.64   // parked off-frame (matches HTML keyframe)
    @State private var causticPhase: Bool = false

    // Body gradient comes from the quadrant's capacity colour tier.
    private var body0: Color { quadrant.capacityColor.auraCore }    // see AppColors extension below
    private var bodyLight: Color { quadrant.capacityColor.auraLight }
    private var bodyDeep: Color { quadrant.capacityColor.auraDeep }
    private var glow: Color { quadrant.capacityColor.auraGlow }

    var body: some View {
        ZStack {
            // 1. body — radial tier colour (NOT a 3D ball: no off-centre specular)
            Circle().fill(RadialGradient(colors: [bodyLight, body0, bodyDeep],
                                         center: .center, startRadius: 0, endRadius: size * 0.5))
            // 2. caustic — drifting light blobs, screen-blended, clipped to the circle
            causticLayer.blendMode(.screen)
            // 3. glass sweep — incremental specular band (StatPhase recipe)
            glassSweep
            // 4. rim — glass edge highlight
            Circle().stroke(.white.opacity(0.0)) // placeholder; rim via inner shadow overlay below
                .overlay(rimHighlight)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .shadow(color: glow, radius: size * 0.14)       // FEEL: tune vs mockup (contained, not a big halo)
        .onAppear(perform: start)
        .accessibilityHidden(true)
    }

    // causticLayer, glassSweep, rimHighlight: build per the mockup's gradients.
    // glassSweep animates sweepX from parked → across → parked on a long timer so it rests
    // (NOT a continuous loop). Use a repeating animation whose visible portion is a small fraction
    // of the cycle (≈ 8.5s total, ~1.3s visible), matching pulse-aura-glass.html @keyframes sweep.

    private func start() {
        guard !reduceMotion else { return }
        // caustic drift (≈7s, autoreverse) + glass sweep (≈8.5s incremental).
        // FEEL: timings tuned on device vs pulse-aura-glass.html.
    }
}
```

- [ ] **Step 2: Add the aura colour ramp to `AppColors` (or a small extension on `PulseCapacityColor`).** Each tier needs core / light / deep / glow. Use existing primitives:
  - `.cyan` → core `spectrumCyan`, light `cyanLight` (#4DD8FF/#7FE0FF), deep `cyanDark`, glow cyan@0.30.
  - `.indigo` → electricViolet/#8B5CF6 family.
  - `.magenta` → `spectrumMagenta` family.
  - `.rose` → a rose ≈ `#C76A86` (add primitive if missing).
  Mirror the HTML `.cyan/.indigo/.magenta/.rose` blocks in `pulse-aura-glass.html`. Keep these as tokens (no raw hex in the View).

- [ ] **Step 3: `#Preview`** showing all four quadrants at hero / field / widget sizes on `AppColors.void`. Compile-check.

- [ ] **Step 4: Device pass.** Bryan runs it; tune the caustic, sweep cadence, glow radius, rim until it matches `pulse-aura-glass.html`. Iterate on feel values only.

- [ ] **Step 5: Commit** once confirmed: `git commit -m "feat(pulse): PulseAura living-caustic-under-glass component"`

---

## Segment 3 — The field + the new check-in ceremony (visual + logic)

**Goal:** `PulseField` (the 2D atmospheric quadrant space: four soft colour zones, axis labels Charged/Quiet/Guarded/Open, no grid, places one or two auras at their positions). The new `PulseCheckInView` ceremony: the aura expands into the field, each answer drifts the aura toward its quadrant (colour resolving as it homes in), the final answer blooms the aura; collapses back. Reuses `DailyCheckInView`'s Q1-Q5 pills but now mapping to `energy`/`openness`.

**Done-condition:** the check-in runs end-to-end from the Map/Home cover, writes a `PulseEntry` with a real `position`, the aura visibly moves and blooms; reduce-motion degrades to instant; **Bryan confirms the feel.**

**Visual reference:** `docs/prototypes/map-pulse-us.html` (the field: corner colour zones, the Charged/Quiet/Guarded/Open axis labels, no grid lines, how an aura sits at a position) and `docs/handoffs/2026-06-27-pulse-design-handoff.md` §"what happens upon expansion" (the ceremony beats: expand → answers drift the aura → final-answer bloom → collapse).

**Constraints — may NOT touch:** `PulseGraph*` (leave them until Segment 8), the history grid, the Us comparison. May modify `DailyCheckInView` answer→axis mapping + `CheckInShell` to host the field instead of the graph.

**Files:**
- Create `Vayl/Features/Pulse/Components/PulseField.swift`
- Create `Vayl/Features/Pulse/CheckIn/PulseCheckInView.swift`
- Modify `Vayl/Features/Pulse/DailyCheckInView.swift` (answers → energy/openness)
- Modify `Vayl/Features/Pulse/CheckInShell.swift` (host the field)

- [ ] **Step 1 (logic, TDD): map answers → axes.** `PulseAnswers` was extracted in Segment 1B; here, finalise its mapping and test it. Mapping (from the existing pills + the handoff):
  - **energy** ← Q1 nervous-system (Overwhelmed→low … Energized→high), reusing Q1's existing `dy` deltas.
  - **openness** ← Q2 focus (Inward→guarded … Reaching Out→open) + Q3 feeling (Defensive→guarded … Adventurous→open).
  - Q4 (glowColor) and Q5 (speed) unchanged.
  Add `VaylTests/PulseAnswersTests.swift`: each canonical answer-set lands in the expected quadrant (tune the deltas until they do). The new check-in UI (Steps 3-4) builds `PulseEntry(position:)` via `PulseAnswers.position(...)`.

- [ ] **Step 2 (visual): `PulseField`.** Port `map-pulse-us.html` field: four `.zone` radial washes in the corners (cyan/magenta/rose/indigo, blurred, low opacity), axis labels, optional faint quadrant names. API: `PulseField(positions: [(PulsePosition, PulseAura-config, label)], connector: Capsule?)`. Places auras with `position(in:)` mapping openness→x, energy→y (note y inverts: charged = top). No grid lines.

- [ ] **Step 3 (visual): `PulseCheckInView` ceremony.** The aura starts centred large, the field fades in, the question panel slides up; each answer animates the aura toward the running `PulsePosition`; the aura colour cross-fades to the resolving quadrant; the final answer triggers the **bloom** (a soft outward breath + the zone brightening) replacing the old line draw. Then collapse back. Use `AppAnimation` tokens; FEEL constants tuned on device vs the handoff §"what happens upon expansion".

- [ ] **Step 4: Host it.** Point `CheckInShell` (and the `.vaylCover` callers in `HomeDashboardView` + `MapView`) at `PulseCheckInView` instead of the graph half. Keep `onComplete(PulseEntry)` → `store.add`.

- [ ] **Step 5: Compile + device feel pass.** Confirm with Bryan.

- [ ] **Step 6: Commit** `feat(pulse): circumplex field + aura-bloom check-in ceremony`.

---

## Segment 4 — Map Pulse views: glance, your-map, Us comparison

**Goal:** Rebuild the Map's Pulse surfaces per `map-pulse-final.html`: **Me glance** (aura hero + Space name + sublabel + weather one-liner), **your-map** (the field showing your current position only, no history plotted), **Us comparison** (two auras + the enclosing **capsule**, the "You're in the X space, Alex is in the Y space" copy). Build `PulseCapsule`.

**Done-condition:** Me/Us toggle swaps these correctly; the capsule encloses both orbs and stretches/contracts with distance; reduce-motion safe; **Bryan confirms.**

**Visual reference:** `docs/prototypes/map-pulse-final.html` (the glance + your-map panels) and `docs/prototypes/map-pulse-us.html` (the Us comparison). The capsule in `map-pulse-us.html` is the working, fixed geometry, port the `.capsule` CSS approach exactly: a stadium in the orbs' own coordinate space, caps centred on each orb with clearance greater than the orb's visible radius (body + glow). Do NOT reintroduce the SVG-viewBox version.

**Constraints — may NOT touch:** the history grid (Segment 5), Home (Segment 6), the check-in. Rebuild `MapPulseHero` + `MapUsLayer` + add `PulseCapsule`; read partner position from `MapStore` (stub the partner value until Segment 7 wires sync).

**Files:**
- Create `Vayl/Features/Pulse/Components/PulseCapsule.swift`
- Modify `Vayl/Features/Map/MapView.swift` (`meLayer`/`usLayer`), `MapStore.swift` (expose `myPosition`, `partnerPosition`, the read copy)

- [ ] **Step 1: `PulseCapsule`.** An enclosing capsule around two field points. IMPORTANT (the bug from this session): build it in the **same coordinate space as the auras** — a SwiftUI shape/Canvas sized from the two positions, a stadium whose rounded caps centre on each orb with clearance > the orb's visible radius (body + glow), gradient stroke (blend of the two tier colours), transparent interior. It collapses to a tight ring when the two positions coincide. See `map-pulse-us.html` `.capsule` for the proven geometry (rounded-rect, height = orb + clearance, length = centre-distance + height, rotated to the axis). Do NOT reproduce the SVG-viewBox mismatch — keep orbs and capsule in one coordinate system.
- [ ] **Step 2: `meLayer`** = `PulseAura` hero (large) + `quadrant.spaceName` + `quadrant.sublabel` + a movement one-liner, with `onCheckIn` → the cover. Tap → `your-map` field (a `.vaylSheet` or inline expand) showing the single current aura in the field.
- [ ] **Step 3: `usLayer`** = `PulseField` with my aura + partner aura + `PulseCapsule`, headline ("A wide day between you" / "Close today" derived from `myPosition.distance(to: partnerPosition)`), and the descriptive copy. Partner data from `MapStore.partnerPosition` (stub now).
- [ ] **Step 4: Compile + device feel.** Confirm.
- [ ] **Step 5: Commit** `feat(pulse): Map glance + field + Us capsule comparison`.

---

## Segment 5 — History grid (last-30-LOGGED) + split circles (logic + visual)

**Goal:** `PulseHistory` derivation + `PulseHistoryGrid`. The grid is the **last 30 entries (logged), never calendar days** — no gaps, never a streak. Me grid = solid tier-colour cells; Us grid = split circles (half you / half partner, solid when same quadrant, one half if only one logged that time).

**Done-condition:** `PulseHistoryTests` pass; the grid renders in the glance (Me) and the Us comparison (split); a daily logger and a rare logger both show exactly their last 30 with no empty cells; **Bryan confirms.**

**Visual reference:** `docs/prototypes/map-pulse-us.html` — the `.grid` / `.sgd` split-circle grid at the bottom of both phones (Me = solid cells; Us = diagonal half-you / half-Alex; solid when the quadrants match), and the "YOUR LAST 30 CHECK-INS" label (note: check-ins, never "days").

**Constraints — may NOT touch:** the field, capsule, check-in. Pure derivation (`PulseHistory.swift`) + one grid view.

**Files:**
- Create `Vayl/Core/Models/PulseHistory.swift`, `VaylTests/PulseHistoryTests.swift`
- Create `Vayl/Features/Pulse/Components/PulseHistoryGrid.swift`
- Modify the Map glance + Us views to host the grid.

- [ ] **Step 1 (TDD): derivations.**
```swift
// PulseHistory.swift
enum PulseHistory {
    /// Last N logged entries (most-recent last), regardless of calendar gaps.
    static func lastLogged(_ entries: [PulseEntry], count: Int = 30) -> [PulseEntry] {
        Array(entries.suffix(count))
    }
    /// Us pairing: for each of YOUR last-N check-ins, the partner's quadrant at that time
    /// (carried forward from their most-recent prior entry). nil partner half when none yet.
    static func pairedLastLogged(mine: [PulseEntry], partner: [PulseEntry], count: Int = 30)
        -> [(mine: PulseQuadrant, partner: PulseQuadrant?)] { /* implement */ }
}
```
  Tests: `lastLogged` caps at 30 and preserves order; a 90-entry user yields exactly 30; a 5-entry user yields 5 (no padding). `pairedLastLogged`: partner half carries forward; nil before the partner's first entry; same-quadrant pairs flagged (compare in the view for the solid render).

- [ ] **Step 2 (visual): `PulseHistoryGrid`.** A 10-wide grid of circles. Me mode: `Circle().fill(quadrant.capacityColor token)`. Us mode: a split circle (a diagonal two-colour fill; solid when both halves equal; single half when partner nil). Port from `map-pulse-us.html` `.sgd`. Label "Your last 30 check-ins" (Me) / "… · you / Alex" (Us). NO "days" wording.

- [ ] **Step 3: Host** in the Me glance (solid) and Us comparison (split).
- [ ] **Step 4: Compile + device. Commit** `feat(pulse): last-30-logged history grid (solid + split)`.

---

## Segment 6 — Home Pulse widget (aura swap)

**Goal:** `HomePulseRail` (Module 2) shows the **compact aura widget**: dormant (dim/dashed "tap to check in") before today's check-in, active (live aura + Space name + "Nh ago") after. Tap → the existing in-place `.vaylCover` check-in. No streak/badge.

**Done-condition:** Home shows the aura in both states; the existing in-place check-in still works and writes to the shared store; reduce-motion safe; **Bryan confirms.**

**Visual reference:** `docs/prototypes/home-pulse-aura.html` — the dormant row (dim dashed aura + "How's your capacity? · Check in") and the active row (live `PulseAura` small + the Space name + "Nh ago" + chevron), sitting as Module 2 between the Deck and the Lexicon.

**Constraints — may NOT touch:** the Deck or Lexicon modules, the Map. Modify `HomePulseRail` only (+ remove its graph usage). Keep its `onCheckIn`/`onInfo` API.

**Files:** Modify `Vayl/Features/Home/Components/HomePulseRail.swift`.

- [ ] **Step 1:** Replace the `PulseGraph`/rail body with: if `store.entries.last` is today → active aura row (`PulseAura(quadrant:)` small + `quadrant.spaceName` + relative time + chevron); else → dormant row (dashed dim aura + "How's your capacity? · Check in"). Port `home-pulse-aura.html`.
- [ ] **Step 2:** Keep the `expansion`/collapse param if Home still animates it, else simplify (the aura does not need the graph's expand). Confirm `onTap`/`onCheckIn` still fire.
- [ ] **Step 3: Compile + device. Commit** `feat(pulse): Home aura widget (dormant/active)`.

---

## Segment 7 — Partner position sync (backend/logic)

**Goal:** Sync the partner's 2-axis **position** (not just a 1D score), so the Us comparison + split grid show the partner's quadrant. Extend `PulseSyncService` + the Supabase `pulse_shared_capacity` table (add `energy`, `openness` columns), under the existing `share_pulse_with_partner` + RLS.

**Done-condition:** `MapStore.partnerPosition` is populated from sync (RLS-gated); the Us view shows the real partner quadrant; a unit test covers the encode/decode + carry-forward; **verified on device with a paired account.**

**Constraints — may NOT touch:** the visual components. Service + store + a migration. Supabase MCP is read-only — write the migration SQL into `supabase/migrations/` and apply via the Supabase CLI / dashboard; reconcile prod schema drift (see `prod_schema_drift_from_migrations` memory).

**Files:** Modify `Vayl/Core/Services/PulseSyncService.swift`, `Vayl/Features/Map/MapStore.swift`; add a migration `supabase/migrations/<ts>_pulse_position.sql`.

- [ ] **Step 1:** Migration: `ALTER TABLE pulse_shared_capacity ADD COLUMN energy double precision, ADD COLUMN openness double precision;` (keep `capacity_score` for back-compat). Keep RLS policies.
- [ ] **Step 2:** `pushCurrentCapacity` → also push `energy`/`openness` from the latest entry's `position`. `fetchPartnerCapacity` → `fetchPartnerPosition() -> PulsePosition?` decoding the two axes (fallback to score→energy if columns null). Unit-test the decode + the `pairedLastLogged` carry-forward against fixture rows.
- [ ] **Step 3:** `MapStore.loadPartnerPosition()` calls the service, publishes `partnerPosition`; `usLayer` reads it.
- [ ] **Step 4: Compile + device (paired). Commit** `feat(pulse): sync partner circumplex position`.

---

## Segment 8 — Final dead-reference sweep

**Goal:** Confirm no graph-era code lingers (the bulk was deleted in Segment 1B; this is the safety net once all new views are live).

**Done-condition:** zero references to retired symbols; no remaining placeholder stubs from 1B (each has been replaced by its real component in Segments 2-7); app + tests compile.

- [ ] **Step 1:** `grep -rn "PulseGraph\|PulseDotSummary\|PulseGraphCanvas\|placeholder\|rebuilding" Vayl/Features/Pulse Vayl/Features/Map Vayl/Features/Home` → confirm every 1B stub was replaced and nothing dangles. Delete any leftover stub files/symbols, remove from pbxproj, build, commit `chore(pulse): final graph-era cleanup`.

---

## Open decisions for the implementer (resolve before/at the relevant segment)
- **Quadrant midline tie rule** (Segment 1): `>= 0.5` vs strict; document it; fix the test expectation.
- **Energy/openness mapping weights** (Segment 3): the exact pill→axis deltas. Start from the existing `dy` values; tune so canonical answers land in the intended quadrant; cover with the `PulseAnswers.position` test.
- **your-map presentation** (Segment 4): inline-expand vs `.vaylSheet`. Mockup shows it as a deeper view; pick per the Map's nav grammar (drilling = push/sheet).
- **Day-detail on grid tap** (Segment 5): whether tapping a grid cell opens that day's field now or later. Defer to a follow-up unless trivial.
- **rose primitive** (Segment 2): add `VaylPrimitives.rose ≈ #C76A86` if not present; it is the Empty/Protective tier and the partner colour in the mockups.

---

## Self-review notes (done by the planner)
- **Spec coverage:** aura ✓ (Seg2), 2D model ✓ (Seg1), field-is-now ✓ (Seg3/4), Us capsule + copy ✓ (Seg4), last-30-logged split grid ✓ (Seg5), Home widget ✓ (Seg6), partner sync ✓ (Seg7), ceremony ✓ (Seg3), guardrails (no streak/calendar-gap, weather copy, no in-field history) ✓ (Seg5 + Seg4 copy). Glance weather-grid ✓ (Seg5 hosts it in Seg4's glance).
- **Type consistency:** `PulsePosition`, `PulseQuadrant`, `PulseEntry.position/resolvedPosition/quadrant`, `PulseHistory.lastLogged/pairedLastLogged`, `PulseAura(quadrant:size:)`, `PulseField`, `PulseCapsule`, `PulseHistoryGrid` used consistently across segments.
- **Placeholders:** visual feel-constants are intentionally deferred to device per the build protocol and marked `// FEEL`; that is the Vayl workflow, not a plan gap. Logic tasks carry real test + impl code.
