# Vayl — Session Handoff

> Working doc for resuming in a fresh chat. Branch: `spec/contextphase-2x3-redesign`.
> Last active thread: **redesigning how onboarding teaches the swipe-up gesture (NamePhase).**

---

## TL;DR — where we are right now

The OB swipe-up confirm gesture wasn't discoverable (3 non-technical testers failed it). We decided to
**teach it explicitly via the dealer in NamePhase**, then reuse it everywhere. Two segments are
**implemented and building**; they need Bryan's **on-device feel-check** (haptics don't fire in the sim,
and the lesson is interactive).

- ✅ `LiftHalo.swift` extracted (shared lift ring) — ModeSelect + ExperienceLevel migrated onto it.
- ✅ `NamePhase.swift` guided lesson: face-up card → "Tap the card to pick it up." → tap lifts (matches
  the selection phases exactly) → "Now swipe up to hand it to me." → swipe → pocket → advance.
- ⏳ Not yet verified on device. Open follow-ups below.

`** BUILD SUCCEEDED **` as of last edit.

---

## The gesture-teaching decision (read this first)

**Problem:** swipe-up is the *flow-wide* confirm gesture — NamePhase is its only teacher; Gender,
ModeSelect, ExperienceLevel, Context all assume the user learned "lift a card → swipe up to confirm"
there. 3 non-technical users (friend, gf, another friend) couldn't discover it. Ambient/animated hints
(chevron trail, flowy stream, single subtle chevron) were all **rejected as "too noisy / arcade."**

**Decision:** NamePhase = **the dealer's explicit one-time lesson.** The dealer (copy = the dealer's
voice, always on screen) walks the user through the two-step grammar on their first (name) card:
1. Type name → **Return**.
2. "Hi [name]" greeting → **card stays FACE UP** (like the selection phases' face-up cards).
3. Dealer: **"Tap the card to pick it up."** → tap → card lifts (shared `LiftHalo`; same transform as
   the selection phases) + soft haptic.
4. Dealer: **"Now swipe up to hand it to me."** → swipe → pocket → advance.

Taught once; every later phase reuses the identical lift+swipe so it transfers by sight.
**Misclick-safety** (the swipe's original reason for existing) is preserved: a tap only **lifts**, never
commits; commit is deliberate (swipe). The **dealer-grab failsafe** + **ConfirmationPhase** are the floors.

Full rationale in memory: `ob_gesture_teaching`, `feedback_ux_validation`.

---

## What's implemented (both build)

**Segment 1 — shared lift affordance**
- `Vayl/Features/Onboarding/Components/LiftHalo.swift` — the spectrum focus ring shown around a lifted
  OB card. Was duplicated inline in ModeSelect + ExperienceLevel; extracted to one source of truth.
- `ModeSelectPhase.swift` / `ExperienceLevelPhase.swift` — migrated onto `LiftHalo(visible:)`
  (identical look, no behavior change).

**Segment 2 — NamePhase guided lesson** (`Vayl/Features/Onboarding/Phases/NamePhase.swift`)
- Card **stays face up** through the lesson (removed the flip-back).
- Tap-to-lift drives `cardOffset`/`cardScale` to **screen y = 0.42, centered, scale 1.12, on
  `AppAnimation.cardLift`** — the literal values from `ThreeCardFanController.lift` (Vayl/Design/
  Components/Cards/CardPhysics/ThreeCardFanController.swift:241-245) so it feels identical to
  ExperienceLevel/ModeSelect. Plus `LiftHalo` + a soft `.impact` haptic.
- Explicit copy: `"Tap the card to pick it up."` → `"Now swipe up to hand it to me."` (placeholders —
  voice pass pending).
- Chevron (old Layer 6) **removed** — the dealer's words carry the instruction.
- New: `handleLiftTap()` / `teachSwipeUp()`, `@State waitingForCardLift`/`cardLifted`/`liftTeachTask`,
  `impactSoft`. The tap is on the card (`cardLayer().onTapGesture`), so it can't fight the name TextField.

---

## Open items / next steps (in priority order)

1. **Device feel-check (Bryan)** — does the NamePhase lift land/feel like ModeSelect/ExperienceLevel?
   Beat timings (420ms lift-settle, 300ms holds)? Tap clean vs keyboard? This is what makes the segment
   "done" per the build protocol.
2. **Swipe threshold consistency** — NamePhase's return-swipe still uses `AppLayout.swipeSubmitThreshold`
   (80pt); the selection phases (`VaylCardFace` FaceGestures) fire at `-cardHeight*0.14` OR velocity
   `-400`. Align so the *swipe* feels identical too. NOT done.
3. **Dealer-grab failsafe (Segment 3)** — if a user never taps/swipes they linger. The "dealer just takes
   the card" (snark line + card slides up as if pulled + haptic → normal pocket) was **prototyped** in
   `docs/prototypes/namephase-gesture.html` but **not wired into Swift NamePhase.**
4. **Copy voice pass** — the two dealer lines are functional placeholders; the dealer's personality is its
   own pass (snark direction TBD).

### Parallel / older threads (not the active one)
- **StatPhase polish** — 3 changes prototyped + locked in `docs/prototypes/statphase-arrival.html`.
  Segment 1 (**arrival ignition**) is IMPLEMENTED in Swift (StatPhase + `AppFonts.statHero` +
  `AppLayout.statHeroSize` + `AppAnimation.statIgnition*` tokens; also removed the cast-shadow "orb").
  Segments 2 (**void breath** in `OnboardingAtmosphere`/`OBVoidBloom`) and 3 (**3-act exit handoff**)
  are NOT yet ported.
- **Onboarding audit** — full visual/motion audit + remediation roadmap lives in
  `~/.claude/plans/you-are-a-senior-wild-unicorn.md`. Headline: craft ceiling is high (StatPhase,
  VaylButton, AppAnimation tokens are genuinely premium) but the flow doesn't land — **BuildDeck +
  FounderLetter are unbuilt dev stubs (2/10)**, `ProjectedTextView`/`DealPointView` are placeholders,
  `CredentialEditorSheet` is raw iOS chrome, token contract leaks. The finale is the biggest gap.
- A **separate session** is working the foil/case "open" ceremony (`docs/prototypes/builddeck-foil.html`,
  3D metallic case). Don't conflict with that thread.

---

## Build / run / verify

```bash
# Build for sim
xcodebuild -project Vayl.xcodeproj -scheme Vayl \
  -destination 'platform=iOS Simulator,name=iPhone 16e' -configuration Debug build

# App + bundle id
APP=~/Library/Developer/Xcode/DerivedData/Vayl-fmyuhjtudetqsqdwuvrohaczxpji/Build/Products/Debug-iphonesimulator/Vayl.app
# bundle id: com.bryanjorden.Vayl

# Install + launch on the booted sim
xcrun simctl install "iPhone 16e" "$APP"
xcrun simctl terminate "iPhone 16e" com.bryanjorden.Vayl 2>/dev/null
xcrun simctl launch "iPhone 16e" com.bryanjorden.Vayl
xcrun simctl io "iPhone 16e" screenshot /tmp/v.png   # static screenshot only
```

App opens at **StatPhase** (onboarding). To reach NamePhase: Begin → type name → Return. Haptics + the
interactive lesson require a real device / live interaction; `simctl` can't tap/type.

**Prototypes** (HTML, `docs/prototypes/`): `node docs/prototypes/server.js` serves on **:7333** — but the
server keeps getting killed between turns, so **restart it when needed**. Use the **full path**
(`http://localhost:7333/namephase-gesture.html`); root `/` defaults to `confirmation-phase.html`.
rAF-driven loops are throttled in a backgrounded preview tab — view in a **focused** browser tab.

---

## Build protocol (CLAUDE.md — non-negotiable)

- Break features into **named segments**; **one thing** each; **verify FEEL on device before the next**;
  list constraints. "**Build succeeds is not done. Feel is correct is done.**"
- **Confirm scope before writing code.**
- Timing/feel verified in an **interactive reference before Swift** — EXCEPT complex Swift-rendered
  visuals (3D/shaders/cracks-on-geometry), which iterate directly in Swift on device (memory
  `feedback_swift_over_html_proto`).

## Architecture gotchas

- `.glassCard()` / `.hairline()` are mandated by CLAUDE.md but **DO NOT EXIST** — use `.themedCard`
  (memory `ob_contract_gotchas`).
- The lift affordance is now shared via `LiftHalo.swift` (was duplicated).
- Design tokens: `AppColors / AppFonts / AppSpacing / AppRadius / AppAnimation / AppGlows / AppLayout /
  AppElevation`. "Zero raw values in views" is the contract (aspirational — leaks exist).
- `director.advance()` is the only way to change OB phase; `VaylDirector` owns `tableFade`.

## Relevant memory (auto-loaded each session via MEMORY.md)

`ob_gesture_teaching`, `feedback_ux_validation`, `ob_contract_gotchas`, `confirmation_phase_direction`,
`feedback_swift_over_html_proto`, `tab_visual_redesign_deferred`.
