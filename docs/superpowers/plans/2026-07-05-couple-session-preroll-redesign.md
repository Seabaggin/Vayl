# Couple Session Pre-Roll Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the couple-session pre-roll into two screens — a boxless **chest** (card selection + settings + capacity) and one merged **"Before we start"** screen (capacity mirror + optional centering ritual + the two-device lock-in), replacing the invented chrome/slider/bespoke-CTA with real tokens and components.

**Architecture:** SwiftUI, 4-layer (View → Store → Service → Model). The pre-roll is a `.vaylCover` hosted by `CardSessionContainerView` and driven by `CoupleSessionStore`. This plan reuses `VaylButton`, `VaylMark`, `PulseAura`, and `CardCarousel`; reworks the lock-in ring into a two-device "release-together" mini-game; deletes `BandwidthSlider`; adds a small partner-capacity read and a `SessionSettings` model. Every visual value resolves to an `AppColors`/`AppFonts`/`AppSpacing`/`AppRadius`/`AppAnimation` token; the four net-new feel durations are added to `AppAnimation` in Segment 0.

**Tech Stack:** Swift 6, iOS 16+ baseline, SwiftUI, `@Observable @MainActor` stores, Supabase (partner-capacity share), XCTest (`VaylTests`), pgTAP/Deno (backend).

**Visual source of truth:** `docs/prototypes/couple-session-settle-in.html` (chest + Before-we-start), `docs/prototypes/couple-session-hero-v2.html` (in-session, out of scope here).

**Design rationale (the "why"):** The lock-in is a deliberate threshold — it *marks the boundary* from the everyday, *requires intention* (friction as care), and *certifies presence* (the release-together can't be faked solo). The ritual settles emotion; the lock-in settles attention. Capacity is a **mirror, never a verdict** — it shows where each partner is, sets nothing (the couple already picked the cards).

---

## Segment Protocol (per CLAUDE.md Build Protocol)

Each segment does ONE thing, names the files it may touch, and is **not done on "build succeeds" — done is "compiles clean AND Bryan has confirmed the feel on device."** Claude compile-verifies only (`xcodebuild`); Bryan runs on device. Do not begin the next segment until the current one is device-confirmed. New test files must be wired into the `VaylTests` PBXGroup (see [vayltests-not-synchronized] convention: `AA00000N…` ids).

**Non-negotiable constraints for every segment:**
- Zero raw values in Views (color/font/spacing/radius/opacity/duration) — tokens only.
- No `.sheet`/`.fullScreenCover` — route through `.vaylSheet` / `.vaylCover`.
- Card Session stays a `.vaylCover` (confirm-on-exit); never a sheet.
- Every tap: press state + `.sensoryFeedback` + action. Every loop: `.ambientAnimation()`. RM **and** Low-Power gates on all ambient motion.
- `director.advance()` / store methods own state; Views never mutate models directly.

---

## Ordered Segments

0. **Tokens + teardown** — add the 4 feel durations to `AppAnimation`; delete `BandwidthSlider`.
1. **Partner capacity read** — verify the prod share, build `CoupleCapacityStore` (build first, per decision).
2. **CapacityMirror view** — `PulseAura`-based You·Alex strip.
3. **SessionSettings model + SettingsSheet** — who-reads-first + length/pace.
4. **Chest refinements** — `CardCarousel` cog-top-left settings entry + dim-over-Home fix.
5. **SyncRing** — empty, thick, two-device release-together mini-game (replaces `HoldToLockInRing`).
6. **Ritual** — breathe + one-good-thing, hosted on the ring, with the two symbols.
7. **BeforeWeStartView** — assemble mirror + ritual + ring + presence + "how it works ⓘ" sheet.
8. **Flow wiring + atmosphere seam** — replace `AirlockView` bandwidth screen; single-line atmosphere swap.

---

### Task 0: Token additions + BandwidthSlider teardown

**Files:**
- Modify: `Vayl/App/Theme/AppAnimation.swift`
- Delete: `Vayl/Features/Sessions/Components/BandwidthSlider.swift`
- Grep-verify no references: `Vayl/Features/Sessions/AirlockView.swift`

- [ ] **Step 1: Add the four feel durations to AppAnimation.** These are the only net-new durations the design needs; all other motion maps to existing tokens (`enter`, `arrive`, `fast`, `spring`, `ambientPulse`, `auraBreathe`, `borderFill`).

Add to `AppAnimation` (in the ambient / raw-Double section, matching the existing `candleBreathDuration` style):

```swift
// MARK: - Session pre-roll (feel-tuned on device)

/// Two-device lock-in — hold-to-fill ramp, seconds. Frame-driven (like HoldToLockInRing),
/// not a spring. Reduce Motion collapses the fill to a timed sleep.
static let syncRingFill: TimeInterval = 2.5

/// How close both partners' release points must land (0…1 of the arc) to count as "in sync".
/// Gameplay tolerance, not an animation — lives here so the value is centralized, not raw in a View.
static let syncReleaseTolerance: Double = 0.12

/// Guided-breath ritual — one inhale OR one exhale, seconds (slower than candleBreathDuration's 2.2).
/// Ambient: gate with `reduceMotion || AppAnimation.lowPower`.
static let breathePhase: TimeInterval = 4.0

/// Number of inhale/exhale cycles before the breath resolves to "there you are".
static let breatheCycles: Int = 3
```

- [ ] **Step 2: Compile-verify.** Run: `xcodebuild -scheme Vayl -destination 'generic/platform=iOS' build 2>&1 | tail -20` — Expected: build succeeds (tokens are additive).

- [ ] **Step 3: Delete BandwidthSlider and remove its use.** Delete `BandwidthSlider.swift`. In `AirlockView.swift`, remove the `bandwidthScreen` slider usage (the whole `bandwidthScreen` is replaced in Task 8; for now, stub it to call the existing lock-in so the file compiles). Grep to confirm zero remaining references:

Run: `grep -rn "BandwidthSlider" Vayl` — Expected: no matches.

- [ ] **Step 4: Commit.**

```bash
git add Vayl/App/Theme/AppAnimation.swift Vayl/Features/Sessions/
git commit -m "feat(session): add pre-roll feel tokens; remove BandwidthSlider

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

**Done condition:** Compiles clean. (No device check — pure token/teardown.)
**Constraints — may NOT touch:** any View's visuals, `HoldToLockInRing` (reworked in Task 5), `AppColors`.

---

### Task 1: Partner capacity read (`CoupleCapacityStore`)

Builds the read **before** the mirror UI (per decision). The capacity a partner sees is a **tier only** — `PulseCapacityColor` (rose/magenta/indigo/cyan → Empty/Low/Good/Abundant) — never the underlying answers.

**Files:**
- Investigate (read-only): prod schema for the pulse-share mechanism (a `share_pulse_with_partner` flag is known to exist in prod per [prod-schema-drift]).
- Create: `Vayl/Features/Sessions/Store/CoupleCapacityStore.swift`
- Create: `Vayl/Features/Sessions/Services/CoupleCapacityService.swift`
- Create test: `VaylTests/Sessions/CoupleCapacityStoreTests.swift`
- Model reuse: `Vayl/Core/Models/Enums/AppPulseEnums.swift` (`PulseCapacityColor`, `PulseQuadrant.capacityColor`)

- [ ] **Step 1: Verify the backend share exists.** Use the Supabase MCP (`list_tables` / `execute_sql`) to confirm how a partner's latest pulse tier is exposed and whether RLS permits the partner to read the tier (not the answers). Record findings inline in the service file's header comment. If the read path does **not** exist, PAUSE and surface it (a `get-partner-capacity` edge function or an RLS-scoped view may be needed) — do not fabricate a client that reads columns that aren't partner-visible.

Run: (MCP) `list_tables` on the pulse/user_profiles tables; `execute_sql` a SELECT simulating the partner read under RLS.
Expected: either a confirmed read path (view/function/column), or a documented gap to resolve first.

- [ ] **Step 2: Write the failing store test.** The store maps a fetched tier string → `PulseCapacityColor` and exposes a stale/absent state.

```swift
// VaylTests/Sessions/CoupleCapacityStoreTests.swift
@MainActor
func test_partnerCapacity_mapsTierAndStale() async {
    let svc = MockCoupleCapacityService(result: .success(.init(tier: .indigo, isFresh: true)))
    let store = CoupleCapacityStore(service: svc, coupleContext: .stub)
    await store.load()
    XCTAssertEqual(store.partnerTier, .indigo)          // "Good"
    XCTAssertFalse(store.partnerNotCheckedIn)
}

@MainActor
func test_partnerCapacity_absentWhenNoCheckin() async {
    let svc = MockCoupleCapacityService(result: .success(nil))
    let store = CoupleCapacityStore(service: svc, coupleContext: .stub)
    await store.load()
    XCTAssertNil(store.partnerTier)
    XCTAssertTrue(store.partnerNotCheckedIn)             // → "not checked in" mirror state
}
```

- [ ] **Step 3: Run test to verify it fails.** Run: `xcodebuild test -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VaylTests/CoupleCapacityStoreTests 2>&1 | tail -30` — Expected: FAIL (types not defined).

- [ ] **Step 4: Implement the service + store.** Service is protocol-injected (no Store→Service concretion). Store is `@Observable @MainActor`.

```swift
// CoupleCapacityService.swift
struct PartnerCapacity { let tier: PulseCapacityColor; let isFresh: Bool }
protocol CoupleCapacityService { func fetchPartnerCapacity() async throws -> PartnerCapacity? }

// CoupleCapacityStore.swift
@Observable @MainActor
final class CoupleCapacityStore {
    private(set) var partnerTier: PulseCapacityColor?
    private(set) var partnerNotCheckedIn = false
    private let service: CoupleCapacityService
    init(service: CoupleCapacityService, coupleContext: CoupleContext) { self.service = service }
    func load() async {
        do {
            if let cap = try await service.fetchPartnerCapacity(), cap.isFresh {
                partnerTier = cap.tier; partnerNotCheckedIn = false
            } else { partnerTier = nil; partnerNotCheckedIn = true }
        } catch { partnerTier = nil; partnerNotCheckedIn = true }
    }
}
```

- [ ] **Step 5: Run tests to verify they pass.** Run the same command as Step 3 — Expected: PASS.

- [ ] **Step 6: Wire the test file into the VaylTests PBXGroup** (`AA00000N…` id convention), then re-run to confirm it's discovered.

- [ ] **Step 7: Commit.**

```bash
git add Vayl/Features/Sessions/Store/CoupleCapacityStore.swift Vayl/Features/Sessions/Services/CoupleCapacityService.swift VaylTests/Sessions/CoupleCapacityStoreTests.swift Vayl.xcodeproj/project.pbxproj
git commit -m "feat(session): read partner's shared capacity tier (mirror, tier-only)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

**Done condition:** Tests green; the prod read path is confirmed (or the gap surfaced and resolved). Privacy verified: only the tier crosses, never answers.
**Constraints — may NOT touch:** any View, `PulseStore` (local-only; do not add partner state to it), UI.

---

### Task 2: `CapacityMirror` view

**Files:**
- Create: `Vayl/Features/Sessions/Components/CapacityMirror.swift`
- Reuse: `Vayl/Features/Pulse/Components/PulseAura.swift` (`PulseAura(quadrant:size:)`), `AppColors` aura ramps, `PulseCapacityColor`
- Preview: inject a stub `CoupleCapacityStore`

- [ ] **Step 1: Build the mirror.** A compact strip: `You · <tier>` + a soft "us" connector + `Alex · <tier>`, over a `borderSubtle` rounded rect. Your tier from `PulseStore.currentPosition` → quadrant → tier; partner tier from `CoupleCapacityStore`. Absent partner → dashed empty orb + "not checked in". Maps to `.capStrip` in the mockup.

```swift
struct CapacityMirror: View {
    let youQuadrant: PulseQuadrant          // from PulseStore.currentPosition.quadrant
    let partnerTier: PulseCapacityColor?    // from CoupleCapacityStore
    let partnerNotCheckedIn: Bool
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            capacityItem(name: "You", orb: .init(quadrant: youQuadrant, size: 16),
                         tier: youQuadrant.capacityColor.label)
            connector
            partnerItem
        }
        .padding(.vertical, AppSpacing.sm).padding(.horizontal, AppSpacing.md)
        .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(AppColors.borderSubtle, lineWidth: 1))
        .overlay(alignment: .topLeading) { eyebrow("where you're each at") }   // AppFonts.overline, textSectionLabel
    }
    // connector: 2pt capsule, spectrumBorder gradient + AppColors.pulseCapsuleGlow (the "us" language)
    // orbs: PulseAura; tier label: AppFonts.caption, textSecondary/primary
}
```

- [ ] **Step 2: Compile + preview.** Confirm both states (partner present / not-checked-in) render. Run: `xcodebuild -scheme Vayl -destination 'generic/platform=iOS' build 2>&1 | tail -20` — Expected: succeeds.

- [ ] **Step 3: Commit**, then **device check** — Bryan confirms the orbs read as capacity and the connector reads as "us," not a control.

**Done condition:** Compiles; Bryan confirms it reads as a mirror (no implied determination).
**Constraints — may NOT touch:** `PulseAura` internals, `AppColors`, the ring or ritual.

---

### Task 3: `SessionSettings` model + `SessionSettingsSheet`

**Files:**
- Create: `Vayl/Core/Models/SessionSettings.swift` (pure struct)
- Create: `Vayl/Features/Sessions/Views/SessionSettingsSheet.swift`
- Modify: `Vayl/Features/Sessions/CoupleSessionStore.swift` (hold `sessionSettings`, expose setters)
- Create test: `VaylTests/Sessions/SessionSettingsTests.swift`
- Present via: `.vaylSheet` (from `VaylPresentation.swift`) — NEVER raw `.sheet`

- [ ] **Step 1: Write the model + a failing store test.** Two knobs only (per decision): who reads first, length/pace. `length` implies the in-session gentle timer (built in the follow-on plan) — encode it now.

```swift
// SessionSettings.swift
struct SessionSettings: Equatable, Codable {
    enum Reader: String, Codable, CaseIterable { case you, partner, either }   // "Let it decide"
    enum Length: String, Codable, CaseIterable { case short, full, unhurried } // ~10 / ~20 / no-cap
    var reader: Reader = .you
    var length: Length = .full
    /// nil == no timer (unhurried); minutes otherwise. Consumed by the in-session timer.
    var softCapMinutes: Int? { switch length { case .short: 10; case .full: 20; case .unhurried: nil } }
}
```

```swift
// SessionSettingsTests.swift
func test_unhurried_hasNoTimer() {
    XCTAssertNil(SessionSettings(length: .unhurried).softCapMinutes)
    XCTAssertEqual(SessionSettings(length: .full).softCapMinutes, 20)
}
```

- [ ] **Step 2: Run to verify fail → implement → verify pass** (`-only-testing:VaylTests/SessionSettingsTests`).

- [ ] **Step 3: Build the sheet.** Two `.seg`-style segmented rows (reuse the app's pill/segment pattern; tokens: `AppColors.spectrumBorder` for the on-state, `AppFonts.buttonLabelSmall`, `AppRadius.md`). Include the honest helper line under Length: *"Sets a gentle timer on the session — a soft nudge near the end, never a hard stop. Unhurried adds no timer."* (`AppFonts.caption`, `textTertiary`). A `VaylButton(label: "Done", size: .compact)` closes it. Presented via `.vaylSheet` at a small detent.

- [ ] **Step 4: Compile + commit + device check** — Bryan confirms the ⅓-height sheet feels right and both knobs persist to `CoupleSessionStore`.

**Done condition:** Tests green; sheet reads/writes `CoupleSessionStore.sessionSettings`; Bryan confirms feel.
**Constraints — may NOT touch:** the chest layout (Task 4 wires the entry point), the ring, capacity.

---

### Task 4: Chest refinements (`CardCarousel` entry point + dim fix)

The chest is `CardCarousel` hosted over Home. Two changes only: (a) a **cog top-left** that opens the settings sheet, opposite the corner deck; (b) the engaged **dim covers ALL of Home including the getting-started bar**. No container box (already correct — `CardCarousel` renders cards on a `dimmingBackdrop`, per audit).

**Files:**
- Modify: the chest host view (the one that presents `CardCarousel` in selecting mode + the Settle-in CTA — trace from `HomeDashboardView` / the session-launch presenter; confirm exact host during Task).
- Modify (only if the dim is scoped too shallow): `Vayl/Design/Components/Cards/CardCarousel.swift:182-189` (`dimmingBackdrop`) — verify it sits **above** the getting-started widget in z-order.
- Reuse: `VaylButton` (Settle-in CTA — already correct), `AppColors.scrimHeavy`

- [ ] **Step 1: Fix the dim coverage.** In the chest host, ensure the engaged dim/scrim (`AppColors.scrimHeavy` or `CardCarousel`'s `dimmingBackdrop`) is layered **above the getting-started card and tab bar**, so "only the card container is visible." The bug in the screenshot is the getting-started bar rendering above the dim. Confirm the dim's container spans the full screen and the getting-started widget is beneath it.

- [ ] **Step 2: Add the cog top-left.** A 44pt rounded settings button anchored top-left of the engaged chest (opposite the corner deck top-right), opening `SessionSettingsSheet` via `.vaylSheet`. Tokens: `AppColors.borderDefault`, `AppRadius.lg`, SF Symbol `gearshape`, press-state + `.sensoryFeedback(.impact(.light))`. Do not alter `CardCarousel`'s card physics.

- [ ] **Step 3: Compile + commit + device check** — Bryan confirms: Home (incl. getting-started bar) fully obscured behind the chest; cog opens settings; card selection + fly-to-corner + Settle-in unchanged.

**Done condition:** Compiles; the getting-started bar is obscured; cog → settings works; card selection physics untouched. Bryan confirms.
**Constraints — may NOT touch:** `CardCarousel` selection/physics logic (`handleCarouselTap`, drag, fan geometry), the card faces.

---

### Task 5: `SyncRing` — the two-device lock-in mini-game

Replaces `HoldToLockInRing`. Empty center (no ✦), thicker, larger. Both partners hold (arc fills over `AppAnimation.syncRingFill`) and **release together**; the two release fractions must land within `AppAnimation.syncReleaseTolerance`. Over-fill or apart → miss + reset. The compare is real-time across two devices.

**Files:**
- Create: `Vayl/Features/Sessions/Components/SyncRing.swift`
- Modify: `Vayl/Features/Sessions/CoupleSessionStore.swift` — publish local hold/release; receive partner's release fraction; compute `synced`. Verify the existing session realtime channel (curated-session realtime, already built) can carry a `releaseFraction` event; if not, add it to the session channel payload (surface as a sub-decision if the channel is closed).
- Create test: `VaylTests/Sessions/SyncMatchTests.swift` (pure tolerance logic, device-independent)
- Reuse: `AppColors.spectrumBorder` (arc), `AppColors.borderSubtle` (track), `spectrumBorderGlow`, `AppFonts.label` (hint), RM/LPM gates

- [ ] **Step 1: Write the failing tolerance test** (the mini-game's win condition — the only unit-testable piece):

```swift
// SyncMatchTests.swift
func test_release_withinTolerance_isSynced() {
    XCTAssertTrue(SyncMatch.isSynced(you: 0.62, partner: 0.70, tolerance: AppAnimation.syncReleaseTolerance)) // .08 ≤ .12
}
func test_release_apart_isMiss() {
    XCTAssertFalse(SyncMatch.isSynced(you: 0.30, partner: 0.72, tolerance: AppAnimation.syncReleaseTolerance))
}
```

- [ ] **Step 2: Fail → implement `SyncMatch.isSynced(you:partner:tolerance:)` → pass** (`-only-testing:VaylTests/SyncMatchTests`).

- [ ] **Step 3: Build `SyncRing`.** Geometry from the mockup (`docs/prototypes/couple-session-settle-in.html` ring: empty center, base track ~8pt, fill arc ~11pt spectrum, glow pass; size feel-tuned ~220–240pt on device — a documented ring constant, like the old `ringSize`). States: `waiting` (dormant, low opacity) → `ready` (glow breathes via `ambientPulse`, gated) → `holding` (fill ramps, frame-driven over `syncRingFill`) → `synced` / `miss`. Center stays empty; the hint (`AppFonts.label`, `textSecondary`) sits in the middle, the mini-game copy below is owned by the parent screen (Task 7). Local hold/release calls into `CoupleSessionStore`; store drives `synced`/`miss` from the two release fractions.

- [ ] **Step 4: Compile + commit + device check (two devices).** Bryan confirms on two phones: both-hold-both-release lands in sync within tolerance; over-hold and apart both miss + reset; empty center + thick stroke read as intended; the ring is dominant.

**Done condition:** `SyncMatch` tests green; two-device release-together works on real devices; Bryan confirms feel + dominance.
**Constraints — may NOT touch:** `CapacityMirror`, ritual, settings. Do not reintroduce a center glyph.

---

### Task 6: Ritual — breathe + one-good-thing (hosted on the ring)

Two optional pills above the ring. **Breathe together** turns the ring center into a paced breath guide (a `PulseAura` cyan orb scaling over `AppAnimation.breathePhase` for `breatheCycles`); **One good thing** surfaces a gratitude prompt. Symbols per the mockup: concentric breath-rings (cyan) and a **1 + up-arrow** (magenta). Breathing owns the ring while it runs, then hands it back to `ready`.

**Files:**
- Create: `Vayl/Features/Sessions/Components/RitualPills.swift` (the two pills + their SVG-equivalent Shape symbols)
- Create: `Vayl/Features/Sessions/Components/BreathGuide.swift` (the paced orb overlay for the ring center)
- Reuse: `PulseAura` (breath orb), `AppAnimation.breathePhase` / `breatheCycles`, RM/LPM gates, `AppColors.spectrumMagenta`/`spectrumCyan`

- [ ] **Step 1: Build the two symbols as `Shape`s** (no assets): breathe = 3 concentric circles (`AppColors.spectrumCyan` ramp); one-good-thing = an up-arrow + numeral "1" (`AppColors.spectrumMagenta`), sized ~20pt. Match the mockup's icons.

- [ ] **Step 2: Build `BreathGuide`.** A `PulseAura`-cyan orb in the ring center that scales inhale↔exhale over `AppAnimation.breathePhase`, cycling `breatheCycles` times, with hint text `breathe in…` / `and out…` → `there you are`. Gate the loop with `reduceMotion || AppAnimation.lowPower` (RM: show a static "take a slow breath, together"). Use `.ambientAnimation`.

- [ ] **Step 3: Wire pills → ring state** (in Task 7's parent): tapping a pill sets ritual state; tapping the active pill ends it; starting a hold cancels an active ritual. (State machine lives in `BeforeWeStartView`.)

- [ ] **Step 4: Compile + commit + device check** — Bryan confirms the symbols read (breath vs 1↑), the breath paces calmly, and the ritual is clearly optional.

**Done condition:** Compiles; symbols + breath pacing feel right; ritual optional, ring reclaims cleanly. Bryan confirms.
**Constraints — may NOT touch:** the `SyncMatch` logic, capacity, settings.

---

### Task 7: `BeforeWeStartView` — the merged screen

Assembles the whole screen: header, `✦ Settle in` / **Before we start**, `CapacityMirror`, `RitualPills`, the dominant `SyncRing` (+ `BreathGuide` when breathing), presence row, and **"how it works ⓘ"** → a `.vaylSheet` with the **animated two-ring demo** + the why-blurb. Owns the state machine.

**Files:**
- Create: `Vayl/Features/Sessions/Views/BeforeWeStartView.swift`
- Create: `Vayl/Features/Sessions/Components/HowItWorksSheet.swift` (two mini rings filling + flashing in sync on a loop; RM → static partial fill)
- Reuse: everything above; `AppFonts.cardTitle`/`overline`/`caption`/`label`; presence dots (`AppColors.spectrum*`); `.vaylSheet`

- [ ] **Step 1: Lay out the screen** top-to-bottom per the mockup, with the ring dominant (surrounding elements compact). Copy strings verbatim from the mockup, including the **mini-game brief** two-liner (action + objective) and the miss/too-long copy.

- [ ] **Step 2: Wire the state machine** — `waiting → ready` on partner presence (from `CoupleSessionStore`); ritual pills; hold/release → `SyncRing`/store → `synced` (→ `CoupleSessionStore.confirmSynced()` → deal-in) / `miss`.

- [ ] **Step 3: Build `HowItWorksSheet`** — two `SyncRing`-style mini rings side by side (You ↔ Alex), looping fill + sync-flash (gate the loop; RM → both static at partial fill), a one-line rule caption, divider, and the "Why it's here" blurb. Trigger = "how it works" + circled-i.

- [ ] **Step 4: Compile + commit + device check** — Bryan confirms the merged screen reads calm-not-crowded, ring dominant, the how-it-works animation teaches the move, and the flow reaches `synced`.

**Done condition:** Compiles; the merged screen matches the mockup and reaches synced; Bryan confirms.
**Constraints — may NOT touch:** the child components' internals (compose only).

---

### Task 8: Flow wiring + atmosphere seam

Replace `AirlockView`'s old rules + bandwidth screens with `BeforeWeStartView`; route settings from the chest; set the atmosphere behind a one-line seam (default `SessionAtmosphere`, swappable to `OnboardingAtmosphere(.stat)`).

**Files:**
- Modify: `Vayl/Features/Sessions/AirlockView.swift` (host `BeforeWeStartView`; drop the old `rulesScreen`/`bandwidthScreen`)
- Modify: `Vayl/Features/Sessions/CardSessionContainerView.swift` (inject `CoupleCapacityStore`; keep `.vaylCover` + confirm-on-exit)
- Create: `Vayl/Features/Sessions/SessionBackdrop.swift` — one view that returns the chosen atmosphere; swapping `SessionAtmosphere()` ↔ `OnboardingAtmosphere(config: .stat)` is a single line here

- [ ] **Step 1: Introduce `SessionBackdrop`** (the atmosphere seam) and use it in the pre-roll screens instead of a hardcoded atmosphere. Default to `SessionAtmosphere()`; comment the one-line `OnboardingAtmosphere(.stat)` alternative.

- [ ] **Step 2: Swap `AirlockView`** to present `BeforeWeStartView` for a fresh session (keep the lobby/reconnect branches). Ensure `CoupleSessionStore.confirmSynced()` still transitions to the deal.

- [ ] **Step 3: Full compile + commit + end-to-end device check** — Bryan runs the whole pre-roll on two devices: chest (dim + cog + settings + capacity) → Settle-in → Before-we-start (mirror + ritual + lock-in) → synced → session. Confirms the atmosphere choice (flip the seam if OB wins).

**Done condition:** End-to-end pre-roll works on device; atmosphere confirmed; `.vaylCover` confirm-on-exit intact.
**Constraints — may NOT touch:** the in-session player (separate plan), the close/safe-word screens.

---

## Out of scope (follow-on plan: in-session refinements)

Tracked separately, per the mockup `couple-session-hero-v2.html`: the fan-deck deal source, **hold-to-deal pill using the Vayl mark**, whole-screen idle **dim**, the **gentle low-stakes timer** (consumes `SessionSettings.softCapMinutes`), the care-mark protected sheet, and the deal-in-from-fan start transition. None of these block the pre-roll.

## Dependencies to confirm during execution
- **Partner-capacity read path** (Task 1) — verify the prod `share_pulse_with_partner` mechanism + RLS before building the client. Pause if absent.
- **Session realtime channel** (Task 5) — confirm it can carry a `releaseFraction` event for the two-device compare; extend the payload if needed.

## Self-review notes
- Every screen element in `couple-session-settle-in.html` maps to a task: chest dim/cog → T4, capacity → T1/T2, settings → T3, ritual+symbols → T6, ring → T5, merged screen + how-it-works → T7, atmosphere/wiring → T8, tokens → T0.
- All durations resolve to tokens: existing (`enter`/`arrive`/`fast`/`spring`/`ambientPulse`/`auraBreathe`/`borderFill`) or the four added in T0. No raw durations in Views.
- Type consistency: `PulseCapacityColor`, `PulseQuadrant.capacityColor`, `SessionSettings.{Reader,Length}`, `SyncMatch.isSynced`, `CoupleCapacityStore.{partnerTier,partnerNotCheckedIn}` used consistently across tasks.
