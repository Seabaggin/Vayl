# Vayl — Session Handoff
**Date:** 2026-05-30  
**Project:** Vayl iOS app — SwiftUI couples/solo exploration app  
**Codebase:** `/Users/bryanjorden/Documents/School/Code/Vayl`

---

## Who you're working with
Bryan — solo iOS dev, strong architecture instincts, building Vayl. Prefers tight build protocol: one segment at a time, verified on device before next segment begins. "Build succeeds" is not done — feel is done.

---

## Architecture (non-negotiable)
4-layer: **View** (renders, forwards taps only) → **Store** (`@Observable @MainActor`) → **Service** (network/IO) → **Model** (pure struct). `director.advance()` is the ONLY way to change OB phase. `tableFade` written ONLY by `VaylDirector`. No View writes to `VaylCardModel` directly.

**Design token contract:** zero raw values in Views. Use `AppColors`, `AppFonts`, `AppSpacing`, `AppRadius`, `AppAnimation`, `AppLayout`, `AppGlows`, `AppElevation`. All looping animations wrapped in `.ambientAnimation()`.

**iOS 26 mandatory:** no `UIScreen.main`, no `UIApplication.shared.keyWindow`. Use `AppLayout.from(geo)` for geometry (never `UIScreen.main.bounds`).

---

## OB Canvas Architecture
Single persistent canvas (`OnboardingCanvasView`) for the entire OB flow. Layer order:  
`void → atmosphere → TableSurfaceView (tableFade) → DealPoint → SpriteKit card flight → tableCards → inFlightCards → ProjectedText → phaseOverlay → CornerDeck`

**VaylDirector** (`Features/Onboarding/Canvas/VaylDirector.swift`) — `@Observable @MainActor` phase machine. Owns all state, animation, and sequencing. Key methods used this session:
- `advance(to: OBPhase)` — sole phase gate
- `tableFade` — 0.0 = table gone, 1.0 = table present. Only director writes this.
- `showDealerLine(_ text:, hideAfter:)` — auto-fading projected copy
- `showDealerLineManual(_ text:)` — persistent projected copy
- `hideDealerLine()`
- `recedeTableForContext()` — fades tableFade to 0
- `showContextHeadline()` — bridging copy, `hideAfter: 2.8`
- `showExpLevelExitLine(_ intensity:)` — selection-responsive exit copy
- `concludeContext(relationshipContext:, situationalRegister:)` — writes data, pockets credential, returns table, shows responsive copy, advances to `.compass`
- `commitExperienceLevel(_ intensity:)` — writes nmStage, pockets credential, pulses deck

---

## OB Phase Sequence
```
stat → name → modeSelect → gender → experienceLevel → context → compass → curiosity → confirmation → buildDeck → founderLetter
```

**Corner deck credentials:** name[1], gender[2], mode[3], experienceLevel[4], context[5], curiosity[6]. Compass is ephemeral — no deck card.

---

## What Was Built This Session

### New reusable components
| File | What it does |
|------|-------------|
| `Design/Components/Cards/CardPhysics/CarouselPhysics.swift` | 1D scalar browse engine. SwiftUI-native spring (`response 0.35`, `dampingFraction 0.70`). Drag 1:1 finger; release calls `settle(predictedVelocity:)` inside `withAnimation` — vsync-locked, no Task.sleep loop. |
| `Design/Components/Cards/VaylCardCarousel.swift` | Generic `VaylCardCarousel<Content: View>`. Inputs: `count`, `cardSize`, `physics`, `confirmedIndex`, `confirmedCardYHint`, `exiting`, `defocusUnselected`, `layout: StackLayout`. Recycled-window infinite scroll with stable modular node identity (no re-rasterization). Confirmed card: raises, spectrum ring, jiggle hint. Exit: hero flies up, unselected drift out of focus. |
| `Design/Components/Cards/CardFaces/ContextCardFace.swift` | Dark-only context card face. Renders number/title/subtitle/detail. Detail gated by `isFront`. |
| `Design/Components/Cards/CardPhysics/ThreeCardFanController.swift` | `@Observable @MainActor` fan controller for ExperienceLevel. 3-card deal/shuffle/flip/lift/confirm sequence via SpriteKit. |

### VaylCardFace changes
- Added `isFront: Bool` prop (forwarded to `ContextCardFace`)
- `.context(number:title:subtitle:detail:)` content case now renders `ContextCardFace` (was `EmptyView`)
- Added `FaceGestures` modifier — built-in tap/swipe gestures only attach when `onAction != nil`, so faces are inert inside the carousel

### OBPhase rename
`OBPhase.quiz` → `OBPhase.compass`. `QuizPhase.swift` deleted. `CompassPhase.swift` is a **stub** (advances to `.curiosity`). Full Compass build (3-question calibration — agency/motivation/register, `CompassStore`, `CoupleCompass` derivation) is the next planned task. Spec: `/Users/bryanjorden/Downloads/Vayl OB — Late May/CompassPhase — Spec.md`.

### ContextPhase (fully built, choreography tuned)
`Features/Onboarding/Phases/ContextPhase.swift`

**Data model:** `ContextCardData` (private struct, re-homed from deleted `ContextOption`). Writes `RelationshipContext` + `SituationalRegister` (not `EmotionalRegister` — that belongs to Compass Q3). Solo: 3 cards. Together: 4 cards.

**Sequence:**
1. Context arrives to clean silent felt (ExpLevel exit line has already cleared)
2. 700ms silence
3. `showContextHeadline()` — `"Now — how are you actually showing up to this?"` (solo) / `"...you two..."` (together) — breathes 1.6s on felt
4. Felt dissolves + carousel assembles **simultaneously** as copy fades (1.2s overlap)
5. Browse — tap front card to confirm → hero raises (−18% h), others recede (opacity 0.45, scale 0.88). Ring/glow on confirmed. Sparse swipe-up tug (3% flick, 2200ms initial delay, 6000ms rest).
6. Swipe up → hero flies up (`cardPocket`) → 150ms → others drift out of focus (`exit`)
7. `concludeContext()` → table returns, deck receives `.context`, responsive line, 2s hold → `advance(to: .compass)`

**Responsive exit copy (per `situationalRegister`):** `.anxious → "We'll take this slow."` / `.excited → "Let's keep that momentum."` / `.flexible → "Good — let's find the shape of it."`

### ExperienceLevelPhase changes
- `.done` case now shows selection-dependent exit line (`showExpLevelExitLine`) and delays `advance(to: .context)` by 2.6s, so Context always arrives to a clean, silent table
- Exit lines: `.curious → "Good place to start."` / `.exploring → "There's a lot to work with."` / `.experienced → "Let's build on that."`

---

## Data Fields Written by Context Phase
`OnboardingData.relationshipContext: String?` — `RelationshipContext.rawValue`  
`OnboardingData.situationalRegister: String?` — `SituationalRegister.rawValue`  
**NOT** `emotionalRegister` — that is Compass Q3's field exclusively.

**Key enums** (in `Core/Models/Enums/AppEnums.swift`):
- `SituationalRegister`: `.anxious` / `.excited` / `.flexible`
- `RelationshipContext`: `.notTalked` / `.talking` / `.someExperience` / `.needsReset` (together) + `.single` / `.partneredOpen` / `.partneredHidden` (solo)

---

## Deferred / Next Up
1. **CompassPhase** — full 3-question build. Spec at `/Users/bryanjorden/Downloads/Vayl OB — Late May/CompassPhase — Spec.md`. Currently a stub that advances to `.curiosity`.
2. **VaylCardCarousel → Home migration** — existing `CardCarousel.swift` (Home, 1 usage: `CardChestContainer`) still uses old discrete-step physics. Plan was to migrate it to use `CarouselPhysics` + `VaylCardCarousel` in a follow-up session.
3. **Context exit choreography** — the lay-flat + vacuum pull of remaining cards (per original spec) is not fully implemented. Currently the unselected cards just drift out of focus. The `defocusUnselected` flag is in place.
4. **Physics on-device feel** — the carousel spring (`response 0.35`, `dampingFraction 0.70`) was tuned in a browser demo and accepted as ground truth, but may need device adjustment. `CarouselPhysics.Config.standard` is the single tuning point.

---

## Key Files Map
```
Canvas:
  VaylDirector.swift                  — phase machine, all state/animation
  OnboardingCanvasView.swift          — layer stack, phase router
  TableSurfaceView.swift              — felt surface

Cards:
  VaylCardFace.swift                  — front face shell (content-switched)
  VaylCardBack.swift                  — back face
  VaylCardContent.swift               — content enum (add new face types here)
  VaylCardCarousel.swift              — reusable browse carousel (this session)
  CardPhysics/CarouselPhysics.swift   — scalar spring engine (this session)
  CardPhysics/ThreeCardFanController.swift — 3-card fan for ExpLevel (this session)
  CardFaces/ContextCardFace.swift     — context card face (this session)
  CardFaces/CandleCardFace.swift      — ExpLevel candle face

Phases (all in Features/Onboarding/Phases/):
  NamePhase          → deck[1]
  ModeSelectPhase    → deck[2]
  GenderPhase        → deck[3] (slot machine + dissolution sequence, complex)
  ExperienceLevelPhase → deck[4] (3-card fan, modified this session)
  ContextPhase       → deck[5] (fully built this session)
  CompassPhase       → STUB (next major build)
  CuriosityPhase     → deck[6]

Data:
  OnboardingData.swift               — all OB fields
  AppOBEnums.swift                   — OBPhase, OBCredential
  AppEnums.swift                     — EmotionalRegister, SituationalRegister, RelationshipContext
```

---

## Build / Debug
- **Project:** `Vayl.xcodeproj`, scheme `Vayl`
- **Dev jump menu:** `OnboardingCanvasView` `#Preview "Full OB Flow"` has a phase-jump toolbar
- **Build:** `xcodebuild -scheme Vayl -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/vayl-dd build CODE_SIGNING_ALLOWED=NO`
  (Use a fresh `-derivedDataPath` if Xcode has the DB locked)
- **CLAUDE.md** at project root has full token contract, iOS 26 rules, and violation checklist
