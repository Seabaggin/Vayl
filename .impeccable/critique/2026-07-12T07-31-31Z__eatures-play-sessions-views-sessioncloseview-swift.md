---
target: critique sessioncloseview
total_score: 31
p0_count: 0
p1_count: 2
timestamp: 2026-07-12T07-31-31Z
slug: eatures-play-sessions-views-sessioncloseview-swift
---
# Critique — SessionCloseView.swift (afterglow + peeking-reflection close)

Method: dual-agent (A: design-review · B: deterministic contract/token scan). Native iOS SwiftUI; HTML detector + browser overlay inapplicable (no DOM), replaced by a rule-based contract scan against CLAUDE.md / DESIGN.md.

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Word count exposed only to VoiceOver (`accessibilityValue`); sighted users get no running "3 chosen" or in-view save confirmation. |
| 2 | Match System / Real World | 4 | "the afterglow", "not tonight", "a line for future-you" — native to the moment. |
| 3 | User Control and Freedom | 3 | Off-ramp now genuinely honest (button + swipe + `.escape`), a big lift from the prior P0; but a mis-aimed downward scroll silently skips, and a picked word can't be undone except by re-tapping. |
| 4 | Consistency and Standards | 4 | Tokens/presentation grammar fully clean (scan confirms); scatter↔FlowLayout split is a11y-justified. |
| 5 | Error Prevention | 3 | Empty "Done" handled honestly; silent swipe-away is the one un-guarded destructive path. |
| 6 | Recognition Rather Than Recall | 3 | Scatter words are visible but nothing says "pick a word" / signals tappability; after picking, no consolidated recall of what's chosen. |
| 7 | Flexibility and Efficiency | 3 | Note is progressively disclosed; peek/large detents efficient. No accelerators. |
| 8 | Aesthetic and Minimalist Design | 3 | Beautiful, but the acknowledgment side stacks overline + recap hero + duration chip + reflection header + divider + reassurance + 13 words + note + button. A lot for "a quiet dark room." |
| 9 | Error Recovery | 3 | No true error states; the gap is the unrecoverable silent-skip. |
| 10 | Help and Documentation | 2 | The scatter's tappability, the up=reflect / down=leave model, and "words feed your Map" are never explained in-screen. |
| **Total** | | **31/40** | **Good — a strong, shippable close held back by discoverability and one un-guarded exit.** |

## Anti-Patterns Verdict

**LLM assessment:** Not slop (~90% confidence). None of the usual AI tells (confetti hero, saccharine summary card, star-rating, "share your streak"). Code comments show real design reasoning. If anything it errs *over*-composed for an unhurried brand — three voice beats + a curated 13-word lexicon — a taste question, not a slop one.

**Deterministic scan:** Token/animation/iOS-26/presentation-grammar compliance is essentially spotless — 0 P0, colors/fonts/spacing/radius all tokenized, `.ambientAnimation` correctly wraps the only loop, Reduce-Motion honored, `.vaylSheet` used. **One genuine contract violation the design pass missed:** the "add a note" button (L347–360) has no `minHeight: 44` floor — caption font + `.padding(.vertical, .sm)` computes well under the 44pt iOS touch minimum, and it's the one tap target on the screen that skipped the floor every sibling has. Two P3 token-hygiene notes: raw `GlowOrb` sizes/offsets (L158–162, 245–250) and raw `.scaleEffect` magnitudes (164, 471) are inlined where the cited `PaywallSheet` precedent names them as constants.

## Overall Impression
This is a real close, authored with care, and it has clearly answered the last critique: the off-ramp is now honest (a 44pt "not tonight" + swipe + VoiceOver escape), scrim-tap no longer silently exits, and "Save" became the truthful "Done." What remains is a cluster around one theme — the reflection is *beautiful but under-signposted*: a raw, depleted partner may not realize the scatter is interactive, can't see what they picked, and can lose the whole moment to an accidental swipe. The single biggest opportunity: make the invitation legible and the exit deliberate, without adding chrome.

## What's Working
1. **The off-ramp is genuinely honest now.** Three redundant, equally-easy exits (top-of-sheet 44pt button, swipe-down, `.escape`) meet the brand's "declining is respected" bar better than almost any close screen — and it directly resolves the prior P0.
2. **"only you'll see this," pre-emptively placed.** In a two-device app it answers the exact fear ("is my partner seeing my word?") before it's asked. Best emotional move on the screen.
3. **Weight-not-scale selection in the scatter.** A picked word settles forward via weight + colour + a left-drawn underline, absolutely positioned so neighbours never nudge. Real restraint — resists the cheap "pop."

## Priority Issues

- **[P1] Silent swipe-away has no safety net.** `onChange(reflectionUp → false)` calls `skipReflection()` and lands home permanently (L80–84). A one-handed user dragging to *scroll* toward the note/Done who overshoots downward silently ends the app's most protected session, with no undo and no re-entry. **Fix:** treat a downward swipe as "collapse to peek" (not leave) whenever any word/note content exists — content = intent, don't discard it on a gesture; only skip from an empty peek. Or require crossing a deliberate threshold before it counts as skip.

- **[P1] "add a note" button misses the 44pt touch floor.** (Caught by the deterministic scan, missed by the design pass.) L347–360: caption font + `.padding(.vertical, .sm)` and no `minHeight: 44` — under the iOS minimum, and the lone tap target here without the floor every sibling has (L203, 294, 476). **Fix:** add `.frame(minHeight: 44)` + `.contentShape(Rectangle())` to match the "not tonight" and chip patterns.

- **[P2] "You went N cards deep" quantifies intimacy.** (Both assessments flagged this independently.) The hero renders a live count welded to the word "deep" (L172–182) — a number on emotional depth reads as a metric to beat next time, the one register a quiet, no-verdicts couples app should avoid. The neutral duration chip below already carries the factual stat. **Fix:** make the hero non-numeric ("You went there together, \(timeContext).") and let the count live only in the duration chip; or if the count stays, drop "deep" — "You turned N cards \(timeContext)" names the fact without scoring the depth.

- **[P2] The scatter never signals "tappable" or "pick a word."** 13 words float with no verb, no resting affordance (only a hairline), no instruction (L260–276, 445–486). A depleted first-timer may read it as a decorative word-cloud *summarizing* the session and tap "Done" having selected nothing. **Fix:** surface the teaching the a11y hint already carries — one line in `reflectionHeader`: "Pick any word that fit. Or none." Optionally give resting words a faint pickable affordance.

- **[P2] Word count is invisible to sighted users.** `reflectionWords.count` lives only in `accessibilityValue` (L215–219). After tapping 3 words in a loose scatter, a sighted user must re-scan the whole field to recall their own picks — recognition-over-recall inverted. **Fix:** a single quiet `caption`/`textTertiary` line near Done ("3 chosen", or the chosen words inline). No badge chrome.

## Persona Red Flags

**Emotionally-raw partner (just finished a hard talk — Vayl-specific):** The **"You went N cards deep" hero** is the element most likely to land wrong — a number framed as depth reads as a scoreboard on something that hurt. Secondary: at the 0.40 peek the scroll's *first* line is "not tonight" — the first thing they read is permission to bail, which can feel like the app expecting them to.

**Confused First-Timer (Jordan):** The **WordConstellation** fails them — no "pick a word" verb, no button affordance, no instruction. High risk they treat the scatter as a summary and hit "Done" with nothing selected, never discovering reflection existed.

**Distracted one-handed mobile user (Casey):** The **silent swipe-down = leave** model fails them — a thumb-scroll toward Done (which sits at the bottom of the large detent) that overshoots downward silently ends the session (see P1). Reaching Done one-handed already requires dragging the sheet fully up.

**VoiceOver user (Sam):** Mostly well-served — `.escape` action, `.isSelected` traits, combined labels, count in `accessibilityValue`. Gap: an absolutely-positioned scatter's reading order may not match the visual warm→neutral→hard tiering, and the "pick any that fit" framing only arrives on the container hint, not up front.

## Minor Observations
- `ForEach(anchors[index % anchors.count])` (L435) silently guards a words/anchors length mismatch — word 14 would stack on anchor 0 if `bankWords` grows. Prefer `zip`/assert over `%`.
- Selection reads slightly differently across the two modes: the FlowLayout chip adds a filled `whisperFill` capsule the scatter doesn't. Minor consistency drift.
- Sub-24pt spectrum accents: the "+" glyph (L352), "✦" (L121), and constellation underline use `spectrumText`/`spectrumText` fill where the spectrum-discipline rule wants a single `textAccent` below 24pt. The 1pt underline is arguably a "stroke" (fine); the "+" and "✦" are worth a glance.
- Copy discipline is clean: no em dashes, singular voice ("for you", "future-you"), no "we/our".
- Token hygiene P3s from the scan: raw `GlowOrb` sizes/offsets and `.scaleEffect` magnitudes are inlined; the `PaywallSheet` precedent this file cites names them as constants.

## Questions to Consider
1. Does the reflection need **13** words, or is the honest set closer to 6 (two warm, two neutral, two hard)? Would fewer make the *hard* words easier to reach for, not buried in a bottom tier?
2. Three voice beats (recap hero + reflection header + the container's "kept" beat) — for "unhurried," is the app narrating the experience back one time too many? Which beat could be silence?
3. Is a **scatter** the right form, or is it precious? A calm centered list of 6 words is more discoverable and more accessible at the app's most fragile moment — is the constellation earning its cost?
4. Should picking a *hard* word ("distant", "heavy") change anything downstream (a gentler landing, a Learn door), or does treating warm and hard identically as "Map trends" quietly flatten a partner's signal that tonight was rough?
