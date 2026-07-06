# Onboarding (OB) — Session Handoff · 2026-06-20

Continuation doc for a fresh chat. Covers a long session walking the OB phases **in screen
order**, refining copy + choreography. Picks up from `docs/ob-handoff-2026-06-19.md`.

---

## 0. State / ground rules

- **Branch:** `spec/contextphase-2x3-redesign`
- **All changes are working-tree, UNCOMMITTED.** Bryan commits himself — don't commit unless asked.
- **Compile-verified only** (`xcodebuild`). **None device-verified.** Bryan runs on device and judges *feel*; Claude build-verifies (compile) only. (memory `feedback_no_sim_runs`)
- **Build command** (from repo root):
  ```
  xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' -configuration Debug build CODE_SIGNING_ALLOWED=NO
  ```
  Tests: swap `build` → `build-for-testing`.
- **FEEL-GATE** comments mark raw timing/size values left un-tokenized for on-device tuning. Promote to `AppAnimation`/`AppLayout` tokens once feel is locked (Bryan's naming call).
- **OB-VOICE RULE (locked, memory `ob_voice_individual`):** OB copy always addresses the **individual** — "you" / "I", **never "we" / "our" / "let's"**, even in couple mode (two-device; each partner onboards alone). Couple-context *selections* are the user's own first-person statement ("I'm excited to explore this with my partner", not "we're excited" / "you both").
- **Working rhythm:** propose → Bryan picks → implement → he device-tests → tune. Surface choices, don't assume confidence (memory `feedback_ask_dont_assume_confidence`).

Phases walked this session: **Demo · ModeSelect · Gender · Experience · Context** (all done, compile-verified, pending device-feel). **NEXT: Curiosity, then Confirmation** (see §3–4). BuildDeck is out of scope (Bryan's other thread).

---

## 1. Work done this session (per phase)

### DemoPhase — copy
- Card-land/turn line `"Consider this your introduction."` → **"So let's bring one up."** (pays off line 1 "…rarely surface on their own"; "bring up" avoids the card-game "draw" collision and is plainly readable).
- Compose line `"Say what's true — one word."` → **"Finish the sentence."** (the noun field now accepts short phrases, so "one word" was inaccurate; matches the `I want ___` blank).

### ModeSelectPhase — copy + auto-select
- Question `"Anyone at the table with you?"` → **"How are you exploring?"**
- **Auto-select couples:** the right (couples) card auto-lifts after the question gate (couples-first default). User taps the solo card to switch, swipes up to confirm. Done in `askQuestion`'s post-gate Task.

### GenderPhase — blank-start dials + shared decline bar
- Both drums open **blank** (`—` placeholder, display-only). Card lift is **gated on `armedToLift`** (both dials tuned to a real option OR declined) — fixes the weak pickup cue (the `LiftHalo` now appears on the resting card only once armed). This reverses the old "defaults valid, nothing gated" contract *on purpose* — blank-start means no valid default to passively accept, so it strands no one (the prior "did you scroll?" gate stranded default-accepters; see the runEntry comment).
- The `Man · she/her` default contradiction is gone (nothing preselected).
- **Shared "Prefer not to say" bar** under both dials (`declineBar` in GenderPhase): tap clears both dials to `—` and arms the lift. Pronouns drum dropped its in-drum "prefer not to say" (moved to the bar); "any pronouns" stays.
- Files: `GenderSequencer` (selectedIndex/pronounsSelectedIndex = -1 sentinel, `declined`, `armedToLift`, `declineIdentity()`, gated `liftCard`/`confirmSelection`), `GenderPhase` (`—` display strips, `declineBar`, push-up `pickerOffsetY`, halo cue), `CredentialEditorSheet` (shared opt-out row).
- FEEL-GATEs: `declineBarHeight` (40), the `pickerOffsetY` push-up.

### ExperienceLevelPhase — the largest chunk
1. **Copy split.** On lift: **level name + enlarged duration only** (`No experience` / `3 months – 1 year` / `1.5+ years`, sized up to `sectionHeading` gradient). The encouraging "dealer's read" line moved to the **swipe-up CONFIRM response** (`director.showExpLevelExitLine`): *"You're new to the table. Best seat there is."* / *"You've played a few hands. I'll help you read them better."* / *"You know this game well. I'll help you play it sharper."* Card-metaphor, dealer-to-you, no "we".
2. **Render-glitch ROOT CAUSE + fix.** The flip-reveal jitter was: `onAction: showFace ? {…} : nil` toggled at the flip pivot → flipped `FaceGestures`' `if enabled` **structural branch** inside `VaylCardFace` → re-identified the face subtree → **cold-re-rasterized the candle** (its own `@State` breathe + `drawingGroup`) at the worst moment. Fix = keep `onAction` **constant** + gate with `.allowsHitTesting(showFace)` (the working ModeSelect pattern). See §2.
3. **Monotonic fan.** Deal/z were `[0,2,1]` (center-on-top — not how cards lap). Now **deal L→C→R, `z=[0,1,2]`** (rightward fan, each card laps the one to its left). `ThreeCardFanController` + `monteFanLayout`.
4. **Ribbon-spread turnover** (replaced the empty open→sway→close flourish + flat `scaleX` squish). New `spreadTurnoverReveal`: **deal → open into a ribbon → sweep-turn (real 3D edge-turn via `rotation3DEffect`, ConfirmationPhase idiom, L→R wave) → re-collect to the fan**. `flipScaleX` removed; the view drives the turn off `showFace` with a `rotation3DEffect` dual-mount + `.animation(.timingCurve(…0.52), value: showFace)`.
5. **Flat resting row.** `monteFanLayout`: tilt `17°→5°`, rise `fanH*0.05→0`, dx `0.58→0.60` (the ±rise arc + 17° read "unorganized").
6. **Auto-select curious** after the question (the `.faceUp` handler auto-lifts `.curious`); removed the singled-out center tug.
- Files: `ExperienceLevelPhase`, `ThreeCardFanController`, `AppLayout.monteFanLayout`, `VaylDirector.showExpLevelExitLine`.
- FEEL-GATEs: turnover wave stagger (150ms), turn curve (`timingCurve …0.52`), open spread (`×1.5` width, `×0.30` angle, level), open/re-collect durations (0.42s), `monteFanLayout` (dx 0.60 / tilt 5 / rise 0).

### ContextPhase — the overhaul (branch namesake)
- **Spec:** `docs/superpowers/specs/2026-06-20-contextphase-redesign-design.md`.
- **2×3 matrix (6 sets) → 4 sets:** solo/couple × **{curious, in-it}** (exploring + experienced merged — the experienced cohort treats NM as lower-stakes). Resolver maps `.exploring` and `.experienced` to the same "in it" set.
- **Reason-based content** (all first-person "I", register-mapped):
  - *Solo · Curious:* I'm here to learn (flex) · I don't know how to bring it up (anxious) · I want to gain clarity (flex) · **I'm single** (excited → greeting).
  - *Solo · In it:* I want to explore more intentionally (excited) · I want to expand my knowledge (flex) · I'm just checking it out (flex) · **I'm single** (excited → greeting).
  - *Couple · Curious:* I'm excited to explore this with my partner (excited) · I want this, but I'm nervous (anxious) · I brought this to my partner (anxious) · I'm still figuring out what I want (flex).
  - *Couple · In it:* I want to go deeper with my partner (excited) · I want to get better at the hard parts (flex) · Something's shifted — I want to work through it (anxious) · I want to keep it fun (flex).
- **`RelationshipContext`:** 24 situation-cases → **15 reason-cases** (`single` shared across both solo sets). `derivedRegister` rewritten. **Blast radius is small** — nothing branches on the specific context; `evaluateOpenerDeckType` keys on `(NMStage, SituationalRegister)`, the exit line uses the register, and the stored `relationshipContext` rawValue is only persisted. No migration needed.
- **Single greeting:** confirming "I'm single" → swipe up → card flies → **`SingleGreetingOverlay`** (new file `SingleGreetingSheet.swift`) rises: *"AN HONEST MOMENT / Vayl gets the most out of two people right now…"* + feature list via `SpectrumBulletRow` + "Got it". Hosted outside the canvas at `OnboardingCanvasView` (both the wrapper + dev-preview sites), driven by `director.showSingleGreeting` / `presentSingleGreeting` / `continueFromSingleGreeting` (which calls `concludeContext`).
- **`contextResponse` voice fix:** `"We'll take this slow"` / `"Let's keep that momentum"` → `"I'll take this slow"` / `"I like that momentum"` / `"No need to force it"`.
- **Card size:** Context-only `bump = 1.1` in `cardSize` (FEEL-GATE) — leaves ModeSelect/Name/Gender alone.
- **Glow** turned down (`0.42/0.26` → `0.34/0.18`, FEEL-GATE).
- **Dealer headline centering saga (resolved):** the visible line is the **phase-local** `ProjectedTextView` (canvas copy is suppressed during `.context`). Three real fixes: (a) anchor it at `0.20` (was the default ~0.32, too low under the bigger cards); (b) the **glow's `cardSize.width*2.2` frame (~1.5× screen) inflated the ZStack → the absolutely-`.position`'d text landed left** — contained the glow's layout footprint with `.frame(width: screenSize.width…)` and pinned the text in its own screen frame; (c) the typing *reveal* itself leaned left — added a **`centerGrow`** mode to `ProjectedTextView` (single-line: reveal the real substring in a **static full-width, centre-aligned frame** so it grows symmetrically from centre). See §2.
- **Entrance re-choreography** (it felt underwhelming): cards now **lift up off the receding felt** — `scale 0.82→1`, `rise 0.13·H→0`, livelier `spring(0.6, 0.74)` (overshoot), silent beat trimmed `900→700`. FEEL-GATEs. The bigger swing (not done): actually *deal* the carousel in from the corner deck.
- **Removed** the stale "undecided card" 0.82-opacity dimming (the last card is now `single`, a real option).
- **Tests** rewritten (`ContextOptionTests`): 4-per-cell, single-anchored solo, exploring==experienced, new register buckets. Compiles (`build-for-testing` passes).

---

## 2. Key gotchas / patterns established (don't let these recur)

- **`FaceGestures` onAction-toggle = cold re-raster.** Toggling `VaylCardFace.onAction` between `nil`↔closure flips the `if enabled` *structural* branch inside `FaceGestures`, which re-identifies the whole face subtree and cold-re-rasterizes it (`.drawingGroup`). Worst on the candle (self-animating). **Always keep `onAction` constant; gate interaction with `.allowsHitTesting` instead** (ModeSelect does this; ExperienceLevel didn't → the flip glitch).
- **An oversized decorative child inflates a ZStack's layout width**, breaking *absolutely* `.position`'d siblings (they measure against the wider box and drift off-centre). Relatively-centered children (ZStack alignment) are fine. Fix: contain the big child's *layout* footprint (`.frame` to screen — it still renders large, frame doesn't clip) OR pin the positioned view to its own screen-sized frame. (Context glow → ProjectedTextView landing left.)
- **Centre-out typing reveal** needs a **static full-width, centre-aligned frame** around the growing `Text`; a tight resizing box lets `.position` pin the leading edge so it grows from the left. (`ProjectedTextView.centerGrow`.)
- **Ribbon-spread turnover** = the premium reveal: `rotation3DEffect` edge-turn (ConfirmationPhase dual-mount idiom) cascaded as a wave, bracketed by a spread + re-collect. Beats a flat `scaleX` squish.
- **Auto-select where a default is harmless, force-choose where assuming is disrespectful**: Mode (couples) + Experience (curious) auto-select; Gender stays blank/force-choice (identity).

---

## 3. NEXT — CuriosityPhase (the priority)

**Bryan's ask:** *"the way the cards are dealt — the stack is large and ugly — we need to greatly improve the presentation."* Plus a copy pass (he's still thinking on the sort-card copy).

**Current state (`CuriosityPhase.swift`, `pileCard`):** a pile of ~7 sort cards dealt from off-screen-top (`offScreenY = -(screenHeight*0.5 + cardHeight)`) into a stagger:
- `staggerX = depth * 1.5 * sign` where `sign` **alternates** by `depth % 2` → the pile tilts irregularly (the "messy" read).
- `staggerY = depth * 4.0` (a tall stack), `restRotate = depth * 1.2 * sign`, `cardOpacity = 1 − depth*0.05`.
- `dealDelay = (pileCount−1−depth) * 0.06` (bottom cards arrive first). Deal flight via `AppAnimation.cardSlide.delay(dealDelay)`, triggered by `allCardsDealt`.
- Only top + immediate-next card carry content; deeper cards are shells. The departing card is a separate `flyingCardView` overlay. Swipe L/R = pass/keep; the deck "forges" into a summary at the end.

**The problem:** the alternating-sign stagger + the `depth*4` vertical spread makes a tall, irregular, ugly pile — it doesn't read as a clean dealt deck. The deal-in is a plain off-screen slide.

**Goal directions to explore (greatly improve the presentation):**
- A **clean, tight stack** (consistent small offset/rotation, not alternating) — reads as a neat deck with a slight peek, not a messy pile.
- Consider a **premium deal-in** (cascade from the dealer/corner-deck, or a single confident deal) instead of the plain slide.
- Keep it readable for the swipe sort (top card clearly front-and-center).
- Iterate the look **in Swift on device** (memory `feedback_swift_over_html_proto` — card physics, not HTML).

This is the first thing to tackle in the new chat. Confirm the stack look with Bryan before building (Build Protocol: feel it first).

---

## 4. Then — ConfirmationPhase

From Bryan's original brief: slight tweaks per edit sheet; the **swipe-RIGHT confirm cue** (note: `"If that's you — swipe right."` + a rightward nudge **already exist** — his ask is really *sooner / clearer*, not *add it*); and review the **fan→deck collapse flip** (the `rotation3DEffect` exit) so it doesn't read buggy.

---

## 5. Files touched this session (all uncommitted)

`DemoPhase` · `ModeSelectPhase` · `GenderPhase` · `GenderSequencer` · `CredentialEditorSheet` · `ExperienceLevelPhase` · `ThreeCardFanController` · `AppLayout` · `VaylDirector` · `AppEnums` (RelationshipContext) · `ContextOption` · `ContextPhase` · `ProjectedTextView` · `OnboardingCanvasView` · **new** `SingleGreetingSheet.swift` · `VaylTests/ContextOptionTests` · spec + this handoff in `docs/`.

Everything compiles; all of it is awaiting Bryan's device-feel pass + FEEL-GATE tuning before commit.
