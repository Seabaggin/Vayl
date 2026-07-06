# BuildDeck Reveal + Tempo (S1–S4) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement task-by-task. Steps use `- [ ]` checkboxes.

**Goal:** Finish BuildDeck's tail so the third crack resolves into a browseable, named "welcome deck" (no void), re-sequence the founder letter to follow the deck, and make the whole ceremony unhurried-but-never-empty.

**Architecture:** All four segments edit `BuildDeckPhase.swift` (the autonomous `runSequence()` + the `beginShatter()` landing + the case drivers). S1 adds a small `WelcomeDeck` model and a reveal layer that reuses `VaylCardCarousel` (the ContextPhase pattern) against placeholder cards. S2 moves the existing peek/expand machinery to fire *after* the reveal browse/idle. S3 retimes the sequence and strengthens the table's "working" visual. S4 re-orders the `latticeWake` assignment. No new phase, no director phase-gate changes.

**Tech stack:** SwiftUI, the OB canvas (`VaylDirector`, `TableSurfaceView`, `MetallicCaseView`), `VaylCardCarousel` + `CarouselPhysics`, `FoilDeckTheme`/`OpenerDeckType`.

**Verification model (per CLAUDE.md, NOT pytest):** each timing-bearing task has (a) a **reference gate** — feel the choreography in an HTML/React reference or Swift-on-device *before* committing values, and (b) a **device done-condition** — run the OB to `.buildDeck` in the simulator/device and confirm the stated visual outcome. "Build succeeds" is never the done-condition. Hardcoded durations below are **starting points to tune**, never final.

**Design of record:** `docs/superpowers/specs/2026-06-13-builddeck-reveal-finish-design.md` (+ the 06-10 ceremony spec).

---

## File structure

- **Create** `Vayl/Features/Onboarding/Models/WelcomeDeck.swift` — pure data: the forged deck's name + purpose + colorway per `OpenerDeckType`, plus placeholder prompt-card content. One responsibility: deck identity for the reveal.
- **Modify** `Vayl/Features/Onboarding/Phases/BuildDeckPhase.swift` — all four segments land here (reveal layer + state; `beginShatter` landing; peek trigger; `runSequence` tempo; `latticeWake` order).
- **Modify** `Vayl/Features/Onboarding/Canvas/TableSurfaceView.swift` — S3 only: a forge-point convergence pulse so the "table working" interim reads as active (driven by the existing `forgeEnergy`; no new director-owned state).
- **Reference (read, don't edit):** `ContextPhase.swift` (carousel + `CarouselPhysics` wiring to mirror), `MetallicCaseView.swift` (wake/dissolve drivers), `FounderLetterSheet.swift` (shared letterhead, already reused by the peek).

---

## Segment S1 — The reveal: out of the bloom, the deck

### Task 1: WelcomeDeck model (deck identity per openerDeckType)

**Files:** Create `Vayl/Features/Onboarding/Models/WelcomeDeck.swift`

- [ ] **Step 1 — Write the model.** Working-title names/purposes are **provisional** (flagged for the content pass); they map to `OpenerDeckType`'s semantics (see `AppOBEnums.swift:208` + `evaluateOpenerDeckType`).

```swift
// Vayl/Features/Onboarding/Models/WelcomeDeck.swift
import SwiftUI

/// The forged starter deck revealed at the end of BuildDeck. Identity derives
/// from `OpenerDeckType` (set by `VaylDirector.evaluateOpenerDeckType()` at the
/// end of Curiosity). Card CONTENT is placeholder pending the content pass;
/// name + purpose + colorway are real so the reveal feels personalised.
struct WelcomeDeck: Equatable {
    let name: String        // embossed/announced — the genuine name reveal
    let purpose: String     // one line above the carousel
    let colorway: FoilColorway

    /// Placeholder prompt cards — shared set; the content pass replaces these.
    /// Tuple shape mirrors `VaylCardFace.context(number:title:subtitle:detail:)`.
    static let placeholderCards: [(number: String, title: String, subtitle: String, detail: String)] = [
        ("01", "Name it",     "What pulled you toward this",  "A first card to open the conversation."),
        ("02", "Out loud",    "Say one true thing",           "Practice putting words to the want."),
        ("03", "The edge",    "Where it gets tender",         "The place you usually go quiet."),
        ("04", "Their side",  "What you'd want to hear",      "Imagine it from across the table."),
        ("05", "Small step",  "One thing this week",          "Low stakes, real movement."),
        ("06", "Check in",    "How it actually felt",         "Come back and tell the truth about it."),
    ]

    static func of(_ type: OpenerDeckType) -> WelcomeDeck {
        switch type {
        case .anxious:        return .init(name: "STEADY",  purpose: "Start slow. Find your footing.",        colorway: .solo)
        case .excited:        return .init(name: "OPENING", purpose: "Lean into the momentum.",               colorway: .solo)
        case .reflectiveCalm: return .init(name: "RETURN",  purpose: "Revisit what you already know.",        colorway: .solo)
        case .reflectiveOpen: return .init(name: "WIDER",   purpose: "Build on the ground you've covered.",   colorway: .solo)
        }
    }
}
```

- [ ] **Step 2 — Device check.** Add a temporary `#Preview` (or use the DevWrapper) printing `WelcomeDeck.of(.excited).name`. Done: each of the 4 variants returns its name/purpose. Remove the temp preview.
- [ ] **Step 3 — Commit.** `git add Vayl/Features/Onboarding/Models/WelcomeDeck.swift && git commit -m "feat(ob): WelcomeDeck identity for the BuildDeck reveal"`

### Task 2: Reveal layer (name + purpose + browseable carousel)

**Files:** Modify `BuildDeckPhase.swift` (state block ~36–67; `body` ZStack ~84–162)

- [ ] **Step 1 — Read the reuse pattern.** Open `ContextPhase.swift` and note its `CarouselPhysics` declaration and the `VaylCardCarousel(...)` call (lines ~108–134). Mirror it exactly; the welcome deck has no confirm/exit selection — it's browse-only.
- [ ] **Step 2 — Add reveal state** (after line 67, with the other `@State`):

```swift
    // Beat 6 — the reveal (segment 7): the forged deck presents and browses.
    @State private var revealShown:   Bool = false
    @State private var revealPhysics  = CarouselPhysics()   // mirror ContextPhase's init if it takes args
    @State private var revealBrowsed:  Int = 0              // distinct cards seen → S2 peek trigger
    private var welcomeDeck: WelcomeDeck { WelcomeDeck.of(director.openerDeckType) }
```

- [ ] **Step 3 — Add the reveal layer** to the `body` ZStack (place it AFTER the `caseShown` block, BEFORE the spark field so sparks read on top during the bloom→deck handoff). Card faces reuse `VaylCardFace.context` (compliant + proven in ContextPhase):

```swift
            // Beat 6 — out of the bloom, the forged deck. Browse freely.
            if revealShown {
                VStack(spacing: AppSpacing.lg) {
                    VStack(spacing: AppSpacing.xs) {
                        Text(welcomeDeck.name)
                            .font(AppFonts.screenTitle)
                            .foregroundStyle(LinearGradient(
                                colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                                startPoint: .leading, endPoint: .trailing))
                        Text(welcomeDeck.purpose)
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textBody)
                    }
                    VaylCardCarousel(
                        count:    WelcomeDeck.placeholderCards.count,
                        cardSize: deckSize,
                        physics:  revealPhysics,
                        content: { index, isFront in
                            let c = WelcomeDeck.placeholderCards[index]
                            VaylCardFace(
                                content: .context(number: c.number, title: c.title,
                                                  subtitle: c.subtitle, detail: c.detail),
                                isFront: isFront, confirmed: false
                            )
                        }
                    )
                    .frame(height: deckSize.height * 1.3)
                }
                .frame(maxWidth: .infinity)
                .position(x: screenSize.width / 2, y: screenSize.height * 0.42) // = floatCenter; deck stays where the case was
                .transition(.opacity)
                .onChange(of: revealPhysics.currentIndex) { _, _ in revealBrowsed += 1 }  // S2 uses this
                .accessibilityLabel("Your \(welcomeDeck.name) deck")
                .accessibilityHint("Swipe left or right to browse your cards.")
            }
```

- [ ] **Step 4 — Device check (forced).** Temporarily set `@State private var revealShown = true` and run the DevWrapper → `.buildDeck`. Done: the named deck title, purpose, and a browseable carousel of 6 placeholder cards render at the float center and swipe horizontally. Revert to `false`.
- [ ] **Step 5 — Commit.** `git add -A && git commit -m "feat(ob): BuildDeck reveal layer (welcome deck carousel, placeholders)"`

### Task 3: Bloom resolves INTO the deck (replace the void jump)

**Files:** Modify `BuildDeckPhase.swift` `beginShatter()` (lines 270–290)

- [ ] **Step 1 — Reference gate.** Before touching Swift, feel the bloom→deck materialisation (the case dissolves as the deck rises into its place — object continuity) in a reference or Swift-on-device. Establish the handoff timing (the deck should begin resolving *as* the flood peaks, ~1.0–1.6s after `caseDissolve`, not after a dead beat). Record the felt value.
- [ ] **Step 2 — Swap the landing.** Replace the peek tail (lines 285–288) so the bloom resolves into the reveal instead of bare void → peek:

```swift
            spawnSparks(at: CGPoint(x: 0.5, y: 0.5), count: 34, style: .burst)
            // The flood resolves INTO the deck — object continuity, no void.
            // (value from the Step-1 feel gate)
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.3 : <FELT_HANDOFF>))
            withAnimation(AppAnimation.enter.reduceMotionSafe) { revealShown = true }
```

- [ ] **Step 3 — Confirm `evaluateOpenerDeckType()` ran.** It is called in `VaylDirector.onCuriosityDeckExhausted` (`VaylDirector.swift:569`), upstream of `.buildDeck` — so `director.openerDeckType` is set by the time this phase renders. Add a debug assert in `onAppear` (`assert(director.openerDeckType == director.onboardingData.openerDeckType)`) and remove it after one device run.
- [ ] **Step 4 — Device done-condition.** Run the full OB (or DevWrapper from `.confirmation`), strike the case 3×. Done: the shatter resolves **with no void** into the named deck + carousel; the deck name matches the path taken (e.g. anxious→"STEADY"). Scrub the shatter→reveal frames: continuous, no black gap.
- [ ] **Step 5 — Commit.** `git add -A && git commit -m "feat(ob): shatter resolves into the welcome deck (kills the post-shatter void)"`

---

## Segment S2 — Letter handoff: after the deck, not instead of it

**Files:** Modify `BuildDeckPhase.swift` — `beginShatter()` (done in S1), `runSequence()` idle peek (lines 378–380), and add the reveal's own peek trigger + carousel→deck collapse.

- [ ] **Step 1 — Remove the superseded peeks.** Delete the idle-peek tail in `runSequence()` (lines 378–380: the `sleep 12.0` → `peekShown = true`). The reveal now owns the path forward, so a pre-reveal idle peek is wrong. (The shatter→peek was already replaced in S1.)
- [ ] **Step 2 — Add the reveal's browse-or-idle peek trigger.** Add a method and call it when `revealShown` flips true (e.g. an `.onChange(of: revealShown)` or inside the S1 Step-2 animation Task):

```swift
    /// After the user browses a few cards OR idles on the reveal, raise the
    /// founder-letter peek. The carousel stays interactive above it (the peek
    /// is the destination, not a modal).
    private func armRevealExit() {
        // browse trigger
        Task { @MainActor in
            let browseTarget = 3
            while revealBrowsed < browseTarget, !peekShown { try? await Task.sleep(for: .milliseconds(120)) }
            if !peekShown { withAnimation(AppAnimation.enter.reduceMotionSafe) { peekShown = true } }
        }
        // idle fallback (value tuned at the Step-4 gate; spec: ~5–6s)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.5 : <FELT_IDLE>))
            if !peekShown { withAnimation(AppAnimation.enter.reduceMotionSafe) { peekShown = true } }
        }
    }
```

  Call `armRevealExit()` immediately after `revealShown = true` in S1's `beginShatter` landing.

- [ ] **Step 3 — Carousel squares back into the deck as the sheet rises.** When the sheet expands (`expandSheet()`), collapse the carousel into a single deck beneath it so the throughline holds. In `expandSheet()` (line 437), before advancing, add:

```swift
        withAnimation(AppAnimation.enter.reduceMotionSafe) { revealCollapsed = true }
```

  and add `@State private var revealCollapsed = false`; in the reveal layer (S1 Step 3), drive the carousel toward a squared deck when collapsed (fade the title/purpose, settle cards to a single stack at `deckSize`):

```swift
                    .opacity(revealCollapsed ? 0 : 1)          // title+purpose fade
                    // carousel → deck: scale the stack to deckSize and centre
                    .scaleEffect(revealCollapsed ? deckW / deckSize.width : 1.0, anchor: .center)
```

  (Feel-tune the collapse so the deck is visibly *under* the rising sheet, not just fading.)

- [ ] **Step 4 — Device done-condition.** Run to the reveal. Done: browsing ~3 cards OR idling ~5–6s raises the labelled peek; the carousel stays browseable above it; pull/tap expands → the deck collapses under the rising sheet → `advance(.founderLetter)`; **no empty gap** anywhere in the handoff. Confirm the peek→full swap is seamless (shared `FounderLetterSheet` geometry, `expandedTopInset` == `FounderLetterPhase.topInsetFrac` = 0.22).
- [ ] **Step 5 — Commit.** `git add -A && git commit -m "feat(ob): letter peek follows the deck browse; carousel squares into the deck under the sheet"`

---

## Segment S3 — Tempo: unhurried but never empty

**Files:** Modify `BuildDeckPhase.swift` `runSequence()` (294–382) + `startRimOscillation()` (388–401); `TableSurfaceView.swift` (forge convergence pulse).

- [ ] **Step 1 — Reference gate (whole runway).** Build a quick timeline reference (HTML/React per Build Protocol) of confirm→invitation with the living beats slow and the empty stretches filled. The empty stretch today is between `deckShown = false` (316) and `caseShown = true` (332): the `0.8s breath` (319) + the tail of line2's hold (328) play over a felt that's done oscillating subtly. Establish, by feel: the breath duration, whether to begin `caseOpacity` fade *under* the tail of line2 (overlap), and the new hold values. Record them. **Do not guess these — feel them.**
- [ ] **Step 2 — Forge "working" visual** in `TableSurfaceView.swift`. The lateral `forgeEnergy` sway alone reads as dead air at phone scale. Add a **convergence pulse**: the topo contour lines tighten/pulse toward the forge point (deal point `dpX,dpY`) with amplitude scaled by `forgeEnergy`. Drive it from the existing `forgeEnergy` (already in `animatableData`) — no new director state. Done (device): with `forgeEnergy` high, the felt visibly reads as "something is being made here," not idle.
- [ ] **Step 3 — Apply the felt retimes** to `runSequence()` — replace the empty tail, keep the living beats unhurried. Overlap the `caseOpacity` fade under line2's hold if Step 1 felt better that way (move `caseShown = true; withAnimation(...) { caseOpacity = 1 }` earlier, before the full line2 hold elapses).
- [ ] **Step 4 — Device done-condition.** Screen-record `.buildDeck` and scrub frame-by-frame from melt→invitation. Done: **no frame where nothing is in motion**; the pace still reads calm/weighty (not rushed); the t160–165 interim now reads as the table working. (Total will land well under 22s purely from removing the empty stretch — but tune to feel, not a number.)
- [ ] **Step 5 — Commit.** `git add -A && git commit -m "feat(ob): BuildDeck tempo — fill the forge interim, no dead frames"`

---

## Segment S4 — Wake ↔ arrival sync

**Files:** Modify `BuildDeckPhase.swift` `runSequence()` (`latticeWake` assignment, line 355) + possibly `MetallicCaseView.swift` (band sustain).

- [ ] **Step 1 — Reference/device feel gate.** Confirm on device the current desync: `latticeWake = .now` fires at line 355 — *after* `caseFloat` (345) + the 2.2s dolly sleep (351) — so the hex peaks ~2s before "Break it open." finishes typing, then the tilt-driven band sweeps and dims through the CTA. Decide the target: hex ignites during the flat→vertical rise and holds vibrancy through the invitation + first strike.
- [ ] **Step 2 — Move the wake into the rise.** Assign `latticeWake = .now` at/just after `caseRiseStart = .now` (line 339) so the lattice powers on AS the case stands (the case-view already designed this — see the 06-10 spec "the material wakes up as the deck stands"). Remove the separate post-dolly wake + its 1.3s hold (lines 355–356) — fold that time into the now-overlapping rise/dolly.
- [ ] **Step 3 — (If the feel gate requires) sustain band vibrancy** through the armed/invite window. The band is tilt-driven (`MetallicCaseView` `bandTravel`/`bandGain`), so it naturally sweeps off after wake. If holding vibrancy through "Break it open." needs it, add a `bandSustain` factor to `MetallicCaseView` that floors the band gain while `caseArmed` and the invite is on screen. Keep it minimal; only if Step 1 proved it necessary.
- [ ] **Step 4 — Device done-condition.** Run to the invitation. Done: the case is at its **most alive** exactly when the dealer says "Break it open." and when the first strike lands — never dimming into the CTA.
- [ ] **Step 5 — Commit.** `git add -A && git commit -m "feat(ob): sync hex wake to the case rise + CTA"`

---

## Self-review

**Spec coverage:** S1 reveal → Tasks 1–3 (model, layer, bloom handoff) ✓. S2 letter-after-deck + carousel-squares-into-deck → S2 Steps 1–3 ✓. S3 fill-don't-cut + forge visual → S3 Steps 2–3 ✓. S4 wake↔CTA → S4 Steps 2–3 ✓. Reduce-Motion paths: reveal/arrival use `AppAnimation.enter.reduceMotionSafe`; carousel static-but-browseable ✓. Placeholder-card scope honored (real content out of scope) ✓.

**Placeholder scan:** `<FELT_HANDOFF>` / `<FELT_IDLE>` and the S3 retimes are intentional **feel-gate outputs**, not lazy TODOs — each has a preceding reference-gate step that produces the value (per Build Protocol: never guess timing). All structural code is complete. The one external lookup (`CarouselPhysics` init) is an explicit "mirror ContextPhase" step, not an undefined type.

**Type consistency:** `revealShown`/`revealPhysics`/`revealBrowsed`/`revealCollapsed`, `WelcomeDeck.of(_:)`, `WelcomeDeck.placeholderCards`, `welcomeDeck` are used consistently across S1/S2. `VaylCardCarousel`/`CarouselPhysics`/`VaylCardFace.context` match ContextPhase's signatures. `expandedTopInset` (0.22) == `FounderLetterPhase.topInsetFrac` (0.22) ✓.

**Constraints honored:** `advance()` stays the sole gate (only `expandSheet`→`advance(.founderLetter)`, unchanged); `tableFade` written only by the director (`recedeTableForForge` untouched); no `VaylCardFace` shell edits (reused as-is); crack engine untouched (S3/S4 don't touch `addFoilTear`/`beginShatter` internals beyond the S1 landing swap).
