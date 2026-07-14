---
target: SessionCloseView (peeking-sheet redesign)
total_score: 31
p0_count: 1
p1_count: 1
timestamp: 2026-07-12T06-17-52Z
slug: eatures-play-sessions-views-sessioncloseview-swift
---
# Critique — SessionCloseView.swift (re-architected: backdrop + peeking sheet)

Method: dual-agent (A: design-review · B: deterministic scan). Native iOS SwiftUI; HTML detector inapplicable (ran, exit 0, empty), browser overlay skipped (no DOM).

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Peek/grabber signals "more," but nothing confirms a word registered beyond the visual settle. |
| 2 | Match System / Real World | 4 | "afterglow", "went N cards deep", "future-you" — native to the moment. |
| 3 | User Control and Freedom | 2 | Two opposite unlabeled gestures (drag up = engage, swipe down = leave); scrim-tap silently exits. |
| 4 | Consistency and Standards | 4 | Routes through .vaylSheet detents, tokens throughout. |
| 5 | Error Prevention | 2 | Scrim-tap + swipe-down both fire irreversible exit-to-home, no undo. |
| 6 | Recognition Rather Than Recall | 3 | Words recognizable, but the swipe-to-skip exit must be recalled — unnamed. |
| 7 | Flexibility and Efficiency | 4 | Detent peek, optional note, FlowLayout fallback. |
| 8 | Aesthetic and Minimalist | 4 | Restrained, gravitational, one earned gradient. |
| 9 | Error Recovery | 2 | Exits are silent and terminal; no path back after skip. |
| 10 | Help and Documentation | 3 | Self-documenting for the confident; zero affordance labels for the hesitant. |
| **Total** | | **31/40** | **Good, ship-worthy with fixes** |

## Anti-Patterns Verdict

Not AI slop — authored, opinionated work. The word bank's honesty gradient ("raw/heavy/distant" beside "warm/close/seen"), hour-branched copy, and designed-together Reduce Motion fallbacks are all craft tells. Deterministic scan: ZERO real token/contract violations. All literals resolve to sanctioned exceptions (minHeight:44, height:1 hairline, screenWidth*ratio geometry, spacing:0); all 21 em-dash hits are in comments, none in user-facing strings. iOS-26 APIs, raw fonts/colors/opacity/presentation: all clean.

## Priority Issues

- **[P0] The exit gesture is invisible and the discoverable gesture is its opposite.** Drag-up = reflect (invited by peek + grabber); swipe-down = leave (no affordance); scrim-tap also silently exits (L358). Inverts the humility off-ramp: leaving should be at least as easy/obvious as engaging, but the easy discoverable path is ENGAGE and the hidden path is LEAVE. The removed skip *button* was over-heavy; the correction over-swung to nothing. Fix: a quiet always-visible label (not a button) — low-contrast "swipe down when you're done" microcopy under the grabber, or a tertiary "not tonight" tap-target calling skipReflection().
- **[P1] Scrim-tap on the recap exits straight home, no confirmation.** The backdrop recap is content the user wants to read; tapping it to admire "you went 8 cards deep" ends the session (L358 onTapGesture→dismiss). The most natural thing to touch is a silent terminal exit, and at the 0.34 peek ~66% of screen is scrim. Fix: exclude the recap bounds from the scrim tap target, or make scrim-tap collapse-to-peek rather than dismiss, or shrink the tappable scrim.
- **[P2] "Save" is the wrong label when an empty Save == skip.** VaylButton "Save" (L170) calls saveReflection() even with zero words/note; an empty Save persists nothing and goes home, yet gets the "kept, just for you" beat — a small dishonesty on a brand built on honesty. Fix: relabel "Done" (truthful for the empty case), or disable/soften Save until content exists, or route empty Save through the plain skip path.
- **[P2] Peek shows content that's scrollable-but-cramped with no signal there's more.** At 0.34 the peek shows only header + hairline + "only you'll see this"; the word field is fully below the fold with no word poking up. A user may read the header, see no action, and leave — never discovering reflection. Fix (feel-gate): tune peek fraction / header height so the top edge of the word field (one or two words) peeks above the fold — the strongest "there's more up here" signal, far better than a grabber alone.
- **[P3] Three acknowledgment beats risk over-narrating a quiet moment.** Backdrop recap hero + reflection header + container "kept" beat = three app-voice beats about one talk, on a brand that is "unhurried, humble." Fix: protect the "kept" terminal beat; consider dialing the recap hero's weight down (it's closeHero gradient competing with the sheet) so the sheet is the focus and the recap is ambient context.

## Persona Red Flags

- **Partner who wants OUT after a hard session:** worst-served. Lands into an upward-moving sheet (app reaching for them), must guess the invisible swipe-down or risk tapping a word, or accidentally taps the recap-scrim and gets dumped home with no acknowledgment they *chose* to leave. Their honest "not tonight" has no visible expression.
- **Emotionally raw first-timer:** two opposite gestures, no labels, on a surface that just auto-moved, at near-zero cognitive surplus. Freezes (app looks broken/waiting) or taps a word by accident. The 44pt work protects their taps but nothing protects their understanding.
- **VoiceOver / Reduce-Motion:** best-served — .accessibilityAction(.escape) maps to skip, words carry .isSelected + live count, RM fallbacks real. Gap: VoiceOver focus order on auto-peek arrival is unspecified — does a blind user know reflection was offered above?

## Emotional Journey (load-bearing lens)

The auto-peek is the central risk — mostly right but under-guarded. A sheet that animates UPWARD on arrival is physically the app moving toward the user; on a heavy night a raw partner reads it as "the app wants something." The header comment claims "reflection never shoves itself up" but an auto-rising sheet is the app's gentle conclusion, not the user's. Swipe-to-dismiss as a guilt-free exit is conceptually perfect but not discoverable — the discoverable read is "drag up," so the easy path is engage and the hidden path is leave, inverting the humility goal. And three acknowledgments (recap, header, "kept") risk over-narrating; peak-end says the last beat ("kept") should land clean and own the moment.

## Minor Observations

- "You went 1 card deep tonight" reads oddly; a 1-card session may want bespoke copy (L136).
- WordConstellation height is screenWidth*0.70 (height from width) — verify on SE inside the 0.92 large detent.
- ForEach id: \.element breaks if the bank ever has duplicate words (currently unique).
- Note field reserves 4 lines; with keyboard up, verify Save reachability in the scroll.
- showNote can't be re-hidden once opened (only text cleared).

## Questions to Consider

1. If swiping down is the honest "no," why does the sheet swipe up on its own — isn't an auto-rising sheet the app making the first move the humility principle says the user should make?
2. Should leaving without reflecting be *easier* than reflecting, not harder? Right now the discoverable gesture is engage, the hidden one is leave.
3. Is "Save" a promise the screen can't always keep, when empty Save and swipe-skip reach the same nothing-persisted home?
4. Three acknowledgments — recap, header, "kept." If you kept only one as the thing the couple remembers, which is it?
