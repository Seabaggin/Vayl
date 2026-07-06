# Card Sessions — Single-Device "Feel" Walkthrough

**For:** one simulator device, DEBUG build. **Date:** 2026-07-02.
**What this is:** a walkable checklist of the whole session sequence, with what to **look** for and what to
**feel** for at each beat, so you can judge the choreography, timing, tokens, and emotional register solo.

## Read this first (the single-device caveat)
Card Sessions is a two-device couple loop. On one device the **sync beats are faked** by the DEBUG local
mock path (`CoupleSessionStore.armPresence()` auto-arrives the partner after a beat; `confirmSynced()`
crosses the airlock solo; reveals auto-complete the partner's side). So you CAN feel every screen, timing,
haptic, and transition. You CANNOT judge: real presence join/leave, true lockstep advance, cross-device
simultaneous reveal, or the dual safe-word exit. Those are marked ⚠️ 2-DEVICE and go on the separate
two-device run.

## Legend
- 👁 **Look** — layout, tokens, copy, does it read right
- 🫀 **Feel** — timing, haptics, choreography, the emotional register
- 🎚️ **Tune** — a feel value you may want to change; note your preferred number
- ⚠️ **2-DEVICE** — faked here; don't trust it until the two-phone run

## How to get in (solo)
Dev build seeds a partner, so you appear paired. Start a session from **Play** (open a deck → Begin) or
**Home** (Settle in). The airlock runs on the local mock path automatically. If a beat stalls waiting on a
partner, that is the mock timer, give it a second.

---

## 1. Entry + builder
- [ ] **Deck → Begin.** 👁 The deck detail reads as a collectible object; Begin is obvious. 🫀 Tapping Begin has a light haptic and a moment of ceremony, not an instant jump.
- [ ] ⚠️ 2-DEVICE: the **"…set up a session" join banner** on Home + Play. You can see it renders, but the real "partner started one" arrival needs the second phone.
- [ ] **Builder sheet** (`SessionBuilderView`, rises as a `.vaylSheet`). 👁 Fast-path chips up top (Quick start / same-as-last / presets), then the editable card list. 🫀 It should feel like an *invitation to tweak*, not a form you must fill. The authored order is already right there, playable untouched.
- [ ] **Quick start** and a **custom edit** (reorder, drop a card, change a timer). 👁 Live time estimate updates; a soft nudge appears if you make it long. 🫀 Trimming feels light; nothing scolds you.

## 2. Lobby
- [ ] **`SessionLobbyView`.** 👁 A calm "here's the shape you're about to enter" summary (deck, count, timers). 🫀 The waiting state feels alive, not a spinner (ambient pulse; it stills under Reduce Motion). Cancel is present and unforbidding.

## 3. Airlock — the first emotional beat
- [ ] **Screen 1A: house rules** (`AirlockView`). 👁 Six spectrum bullet rows + a "We're ready" affordance. On a **repeat** session this should collapse to a one-line "settle in" (start a second session to check the collapse). 🫀 This should feel like a held breath before a dive, ceremonial, not a legal agreement.
- [ ] **Screen 1B: bandwidth.** 👁 Three detents: Light / Open / Deep (`BandwidthSlider`). You set it *privately*. 🫀 Choosing feels considered.
- [ ] **Hold-to-lock** (`HoldToLockInRing`). 🫀 Press and hold ~3s; a spectrum arc sweeps to completion then locks. 🎚️ **Hold duration = 3.0s** and the arc ramp, tune both; too short feels trivial, too long feels stuck. (Stills under Reduce Motion.)
- [ ] ⚠️ 2-DEVICE: **"both here → active" flip.** Solo, the mock arrives the partner and you cross. The real exactly-once flip when both are present + consented is a two-phone check.

## 4. Transition
- [ ] **The held beat** (`CardSessionContainerView`). 👁 "look at each other." and a breathing ✦, nothing else. Confirm the phrase is exactly that, and that **"put your phones down" is NOT present** (it was cut). 🫀 A real pause. 🎚️ **~2.5s**, does it land, or rush/drag? (Stills under Reduce Motion.)

## 5. Player — the cards
- [ ] **First card** (`SessionPlayerView`). 👁 Card face is legible; a soft turn cue shows whose turn it is (whoStarts). 🫀 Landing on card 1 feels like arrival, continuous from the transition.
- [ ] **Advance** (Next / Skip). 🫀 On one device it just moves. ⚠️ 2-DEVICE: true lockstep (either advances → both move; simultaneous taps don't double-advance) is a two-phone check.
- [ ] **Timer bar** (`SessionTimerBar`). 👁 Countdown + "wrap up when you're ready"; at zero it does NOT auto-advance. 🫀 The chime is a **light haptic** today. 🎚️ Decide if it needs an actual audio chime (deliberately left off). "keep going" clears it for both.
- [ ] **Context beat overlay** (`ContextBeatOverlayView`). 👁 A banner that auto-dismisses (~5s) or a tap-through interstitial before a heavier card. 🫀 It frames, it doesn't interrupt.
- [ ] **Card-back flip** (`CardBackFlipView`). 🫀 The flip to the back copy is a satisfying 3D turn (stills to a cross-fade under Reduce Motion).
- [ ] **Local living faces** (`LocalCardFaceView`, 9 types: dare, greenLight, coolOff, bodyCheck, permissionCard, appreciationInterrupt, openingRitual, closingRitual, pause). 👁 Each has its own treatment (label/icon/accent). The **pause** card is a distinct held-breath face with no prompt. 🫀 They should feel like a change of texture mid-session, not just another card.

## 6. Reveals — one of each mechanic
Hit a card of each type across decks. Solo, you seal your side and the partner's seal is mocked so it
completes. ⚠️ 2-DEVICE for true simultaneity + "neither sees until both seal."
- [ ] **Whisper** (`WhisperRevealView`). 👁 Private compose → seal → 3-2-1 → side-by-side, color-coded per side. Screenshots are blocked (`.screenshotProtected`) — try one, confirm it's black. 🫀 The 3-2-1 is a held-breath, not a jump-scare.
- [ ] **Unspoken slider** (`UnspokenSliderView`). 👁 Both answers land as points on one spectrum. 🫀 Reads as "where we each are," not a score.
- [ ] **Mirror** (`MirrorRevealView`). 👁 Role-aware A/B framing.
- [ ] **Snapshot** (`SnapshotRevealView`). 👁 One word each. 🫀 Spare, lands clean.
- [ ] Privacy gut-check: after any reveal, nothing should feel like it exposed the partner's *raw* answer beyond the shared mechanic.

## 7. Safe word
- [ ] **Raise "red."** 👁 → `SafeWordCloseView`: neutral, warm, immediate. **No** reflection, no stats, no "are you sure." 🫀 Zero guilt, an off-ramp, not a failure. ⚠️ 2-DEVICE: that it ends the session on *both* phones.

## 8. Close
- [ ] **`SessionCloseView`.** 👁 Stat line reads **"N cards · reached [depth] · M min"** (cards · depth · duration), then a one-word field and a "how full are you now" bandwidth slider (`ReflectionSlider`). 🫀 A gentle landing, not a scorecard. Depth is a named band, never a number, never the partner's reading.
- [ ] **Persistence.** Close, reopen the deck. 👁 It resumes where you left off (DeckProgress). Check the Map Pulse reflects the closing bandwidth.

## 9. Reduce Motion pass (do it once)
- [ ] Turn on iOS **Settings → Accessibility → Reduce Motion**, then re-walk the airlock hold arc, the transition ✦, the card-back flip, and any reveal countdown. 👁 Each should degrade to a still/cross-fade with no looping motion, and nothing should break or feel dead.

---

## Note-taking: capture these as you go
The 🎚️ values are the whole point of the solo pass. Jot your preferred number for each:
- Hold-to-lock duration (default 3.0s): ______
- Transition held beat (default 2.5s): ______
- Timer chime: haptic-only, or add audio? ______
- Anything that rushed, dragged, or read wrong: ______

## Then: the two-device run (the real done condition)
Everything marked ⚠️ 2-DEVICE lives in `docs/superpowers/specs/2026-07-02-card-sessions-closeout-verification.md`
§R1. Solo you're judging feel; two phones you're judging truth (presence, lockstep, simultaneous reveal,
dual safe-word exit).
