# Onboarding (OB) — Session Handoff · 2026-06-19

Continuation doc for picking this work up in a fresh chat. Covers everything done in this session across the OB phases.

---

## 0. State / ground rules

- **Branch:** `spec/contextphase-2x3-redesign`
- **All changes are working-tree, UNCOMMITTED.** Bryan commits himself — don't commit unless asked.
- **Every change here is compile-verified only** (`xcodebuild`). **None is device-verified.** Bryan runs the app on device and judges *feel*; Claude build-verifies (compile) only.
- **Build command:**
  ```
  xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' -configuration Debug build CODE_SIGNING_ALLOWED=NO
  ```
  (Run from the repo root: `/Users/bryanjorden/Documents/School/Code/Vayl`.)
- **"FEEL-GATE"** comments mark raw timing/size values intentionally left un-tokenized for on-device tuning (per the Build Protocol). They get promoted to `AppAnimation`/`AppLayout` tokens once the feel is locked.
- **Audit root causes** are in memory: `ob_code_audit_fixes_2026_06_17.md`.
- **Build Protocol:** segmented work, confirm before coding, device-verify feel before "done." Bryan iterates fast — propose → he picks → implement → he device-tests → tune.

---

## 1. OB code-level audit + 3-segment fix pass (start of session)

A full code-level audit of the OB, then fixes in easy/med/hard segments. **All implemented + compiling.**

**Headline root cause found & fixed — the post-Gender "felt scar":** `GenderSequencer.dissolutionT` ended pinned at `1` and was never reset after gender (only `runEntry` reset it, on *entry*). Its computed `dissolutionFlowOut`→`1.0` fed the persistent `TableSurfaceView`, so the topo lines deflected around the ghost gender-card for the rest of the OB. Fixed with `GenderSequencer.resetDissolution()` called on pocket. **Pattern to remember:** ceremony-scoped table state leaks into the persistent felt because phases rely on `advance()` for cleanup, but `advance()` only clears the dealer line — not director/sequencer *visual* state.

- **Segment 1 (Easy):** felt-scar reset · Demo keyboard waits for the line (`typeDuration + hang`) · ModeSelect question persists until tap (dropped 3s auto-hide) · gender drum float-division (latent off-by-half).
- **Segment 2 (Med):** Confirmation swipe-right cue (sooner + persistent, coupled to nudge) · task/line-leak sweep across 5 files (ModeSelect `speechTask` split, Confirmation untracked tasks, NamePhase/Demo uncancelled `asyncAfter`→spring, NamePhase defensive `hideDealerLine` at entry) · ContextPhase doubled `ProjectedTextView` suppressed during `.context` · NamePhase cross-phase staging removed (`placeCardSilently` was write-only dead).
- **Segment 3 (Hard):** BuildDeck lifecycle/leak hard-stop (`onDisappear`, cancel tasks, retire spark-field `TimelineView`, transaction hard-stop on the forge `tableRimBurst`/`tableForgeEnergy` bindings) · ExperienceLevel deal-hitch (synchronous `ImageRenderer.uiImage` deferred off the appearance frame).
- **Polish pass:** removed dead `dealerLine3Done`/`cardBlur` (NamePhase) · `reduceMotionSafe` consistency on Curiosity/Confirmation loops · `FounderLetter spacing → AppSpacing.xs`.

---

## 2. Per-phase work this session

### StatPhase (the largest chunk — near-final)
Lives in `Vayl/Features/Onboarding/Phases/StatPhase.swift`.

- **Ethos line reworked** from the cliché "You're not alone. / And this isn't new." → **"That's about as ordinary as / owning a cat."** (`EthosTextView`).
  - Researched the cat stat: US cat ownership is ~**1 in 3 households** (Gallup ~29%, individual-level question), **not** 1 in 5, and it did **not** rise post-COVID (that was dogs). So the copy is deliberately **number-free** — it borrows the *vibe* (cats = mundane) without a stat that fights the cited Haupert study.
  - Two lines: white setup over gradient punchline; **both bold** (uniform weight reads as one statement); 20pt; gap `AppSpacing.xs`.
- **Intro copy** (`StatNumberView` accessibility) and ethos sit fine; the body claim is now the citation host (below).
- **"About this research" pill → footnote ⓘ on the claim.** The claim is hand-set to **3 lines** so a **real gradient `Image` ⓘ** can ride the last line (a glyph inside `Text` can't carry a gradient). The whole claim sentence taps to reveal the citation. ⓘ size iterated down to **23.5pt** (FEEL-GATE). `minimumScaleFactor(0.8)` holds 3 lines on narrow widths. **Caveat:** the 3 line breaks are now hard-coded — if the claim copy changes, re-balance them by hand.
- **Citation is a pop-out overlay** (not inline — the inline expand collided with the punchline/Begin). Tapping the claim dims everything (`Color.black.opacity(0.62)` scrim) and centers the card; tap scrim to dismiss. **Calm cross-fade** via `.easeInOut(duration: 0.32)` (the old `materialExpand` read as a "bubble pop").
- **Citation card restyled in-app** (`CitationCard` struct): `AppColors.cardBg` (purple OB surface) + **spectrum gradient border** (`strokeBorder(AppColors.spectrumText)`) + `AppRadius.lg`. Made **squarer** via `minHeight: 250` (≈ its 300pt width once padded), copy vertically centered. Body text **17pt** to fill the box proportionally; small spectrum overline header **"THE FINDING"** (uppercase, tracked, `spectrumText` gradient) for structure.
- **Dead code removed:** `kGlassFill`/`kGlassBorder` (old pill), `showCiteTap` (`@State` + both cascade setters), single-child `VStack` wrapper in `CitationTapView`. (`bodyText` kept — still used in the `hasContent` guard.)
- **StatPhase FEEL-GATEs to tune on device:** ⓘ `23.5`, citation header text/wording, card `minHeight: 250` vs body `17pt`, overlay fade `0.32`, ethos gap `AppSpacing.xs`, the 3 hard-coded claim line breaks.

### DemoPhase
`Vayl/Features/Onboarding/Phases/DemoPhase.swift`.

- **Deal sequence reordered & paced:** copy 1 → **deal** → dramatic-flair rest → copy 2 (over the rested card) → center → flip. Center + flip slowed and broken into discrete beats (was rushed/back-to-back). Demo-local timings (FEEL-GATEs) so the shared `cardCenter`/`cardFlipHalf` tokens (used by Gender/Experience) stay untouched.
- **Copy 2 ("Consider this your introduction.")** now **hangs** through the move + flip and clears on flip land (tighter than the old hide-then-pause).
- **Flip jitter fixed** (dual-mount pre-warm — see §3).
- **Noun input overhaul** ("I [verb] [noun]" snapshot):
  - **Allows short phrases** (e.g. "a threesome", "to explore") — the filter no longer strips spaces; it blocks leading space, collapses doubles, caps length.
  - **Cap `maxNounLength = 18`** (a couple of short words, not a poem).
  - **Shrink-to-fit** so it never overflows/truncates: a gentle char-count gradient (`~1.0%/char` past ~5 chars, floored 0.62) `min`'d with a hard fit-cap, applied to **both** the invisible `TextField` and the `LivingText` overlay (so the caret stays aligned). Same logic in `SnapshotCardFace` (kills the "freed.." truncation).
  - **"Press return when you're ready." prompt removed** — once they type, the dealer steps back; the prompt only shows on first, untouched entry (sticky `hasEngaged` flag means erasing does NOT bring it back).
  - `pulseNoun` `asyncAfter` → single self-settling spring (leak fix).

### NamePhase
`Vayl/Features/Onboarding/Phases/NamePhase.swift`.

- **No re-deal — "set-down" entrance** (`setDownCard()`): the card fades in already at center and eases down to rest (no off-screen flight; that ceremony belonged to Demo). The old `dealCard`/`centerCard` are left in place but **unused** — reverting to the flight is one line.
- **Copy reworked:** opener "That's a good place to begin." → **"Noted."**; name pivot "Let's get acquainted." → **"And who am I dealing in?"** (desire→identity bridge, dealer prompting).
- **Sequential pacing:** "Noted." lands → *beat* → card sets down + settles → *beat* → flips → *beat* → "And who am I dealing in?" (was overlapping/rushed). Beats are FEEL-GATEs in `runDealerIntro`.
- **Flip jitter fixed** (dual-mount pre-warm — see §3).
- **Directing copy lifted off the corner deck:** `dealerCopyY` lifted state `0.16 → 0.21` (FEEL-GATE).

### ExperienceLevelPhase
`Vayl/Features/Onboarding/Phases/ExperienceLevelPhase.swift`.

- **Deal-hitch:** synchronous `ImageRenderer.uiImage` card-back snapshot deferred ~32ms off the appearance frame (tracked `entranceTask`, cancelled on disappear).
- **Flip pre-warm** (dual-mount candle faces — see §3).
- **30fps flame cap:** `TimelineView(.animation(minimumInterval: 1.0/30.0))` — halves/quarters the per-frame candle redraw + drawingGroup cost; card *movement* stays smooth (it's `withAnimation`-driven, not the clock).

### GenderPhase / ModeSelectPhase
- Both flips **pre-warmed** this session (were cold-mounting) — see §3.
- Gender drum float-division fix (audit Segment 1).

### ConfirmationPhase
- Swipe-right cue + task-leak fixes (audit Segment 2). The swipe-RIGHT confirm cue appears sooner and stays coupled to the nudge.

### BuildDeckPhase
- Lifecycle/leak hard-stop (audit Segment 3). **NOTE:** this phase is NOT-FINAL / actively being iterated (Bryan has a separate shatter-redesign in progress — see memory `build_deck_shatter_redesign`). Only correctness was touched, not choreography. There's a recent linter/Bryan edit to this file too.

---

## 3. Cross-cutting: ALL card flips are now pre-warmed

Every flip that swapped faces at the edge-on midpoint was cold-mounting the new face (Canvas + drawingGroup alloc) right at the pivot → "jittery flip." Fix pattern = **dual-mount**: keep both faces mounted, swap by opacity at the (invisible) edge-on midpoint so the revealed face is already warm.

| Flip | Status |
|---|---|
| Demo · Name · ExperienceLevel · Gender · ModeSelect | ✅ fixed this session (dual-mount) |
| Confirmation · CuriosityFlipCard · ConversationCard | ✅ already dual-mount |
| CardCarousel | n/a (depth tilt, no face swap) |

If a *new* flip is ever added, apply the same dual-mount idiom.

---

## 4. Open / pending

**Device verification of everything above is still pending** — it's all compiled, none felt on device. That's the gate before committing.

**Deferred (with reasons), from the audit:**
- **H3** feel additions — BuildDeck "break it open" cue persistence; FounderLetter pull-down completion affordance. (Choreography on NOT-FINAL phases.)
- **H4** canvas `SpriteView` idle-gating — the suggested `inFlightCards` gate is a different mechanism than the SpriteKit scene; needs device profiling.

**"Your call" items (design decisions, not bugs):**
- NamePhase `fireFlipBurst` — dead code: wire the flip bloom back vs delete.
- Demo swipe-up seal — live but untaught: re-teach vs remove (+ stale header comment).
- `GenderSequencer.placeCardSilently`/`pendingCard` — vestigial scaffolding (cross-phase call already removed): wire vs delete.
- BuildDeck Beat-3c settle — only revisit if the felt still oscillates during the reveal on device (the `onDisappear` hard-stop covers the letter-bleed; the in-phase settle was left as choreography).
- ExperienceLevel "option B" (warm candle faces in the still settle) — only if the entrance feels rough after the flip pre-warm.

**Token-drift batch (needs Bryan's token-naming decisions):** the many `FEEL-GATE` raw values across Stat/Demo/Name should be promoted to `AppAnimation`/`AppLayout`/`AppColors` tokens once feel is locked. Don't invent token names unilaterally.

---

## 5. Patterns / conventions established this session

- **Dual-mount pre-warm** for any face-swap flip (see §3).
- **FEEL-GATE** raw values for un-tokenized feel timings/sizes; tune on device, tokenize later.
- **Ceremony-state-leak** guard: reset director/sequencer *visual* state on phase exit (not just the dealer line) — `advance()` doesn't do it.
- **Inline gradient impossible in `Text`** — a gradient glyph must be a real `Image` with `.foregroundStyle(gradient)`; this forces hand-set line breaks if it must sit inline (see StatPhase claim ⓘ).
- **Demo-local timings** where a shared `AppAnimation` token is used by other phases — don't retune the shared token.

---

## 6. Suggested next steps

1. **Device pass** on Stat / Demo / Name / Experience / Gender / ModeSelect — confirm: felt scar gone after Gender; all flips smooth (no cold-mount jitter); Demo deal pacing + noun shrink-to-fit; Name set-down + "Noted."→"And who am I dealing in?"; StatPhase citation pop-out + filled card.
2. **Tune the FEEL-GATEs** flagged above to taste.
3. **Decide the "your call" items** (§4).
4. **Commit** once the feel is locked (Bryan's call), then **tokenize** the FEEL-GATE values.
5. ContextPhase 2×3 work (the branch's namesake) is still its own thread — the data matrix exists in `ContextOption.swift`; the phase still presents a carousel with NOT-FINAL choreography.
