---
target: SessionCloseView
total_score: 30
p0_count: 0
p1_count: 2
timestamp: 2026-07-12T01-59-01Z
slug: eatures-play-sessions-views-sessioncloseview-swift
---
# Critique — SessionCloseView.swift

Method: dual-agent (A: design-review · B: deterministic token/contract scan). Native iOS SwiftUI target; HTML detector inapplicable (ran, exit 0, empty), browser overlay skipped (no DOM).

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Save produces no acknowledgment; cover just dismisses. No selected-word count. |
| 2 | Match System / Real World | 3 | Copy excellent, but "N cards deep" frames an intimate talk as a metric. |
| 3 | User Control and Freedom | 3 | No way back from .reflect to landing once Reflect is tapped. |
| 4 | Consistency and Standards | 4 | Tokens, VaylButton, .vaylPressable, .vaylDepth all consistent. |
| 5 | Error Prevention | 2 | Typing a note then tapping skip silently discards it. |
| 6 | Recognition Rather Than Recall | 4 | All words present; nothing to recall. |
| 7 | Flexibility and Efficiency | 3 | Note progressively disclosed; fine. |
| 8 | Aesthetic and Minimalist Design | 4 | Genuinely restrained, on-brand. |
| 9 | Error Recovery | 2 | Accidental skip is unrecoverable and silent; no states. |
| 10 | Help and Documentation | 2 | Scatter multi-select is novel and untaught; no cue it's optional/multi. |
| **Total** | | **30/40** | **Good, with real gaps** |

## Anti-Patterns Verdict

Not AI slop. Authored, opinionated work — the header comments prove intent ("a breath, not a badge"). Singular voice, no em dashes in copy, tokens throughout. The WordConstellation is a genuinely non-generic choice. The one place it fights its own "quiet dark room, not a dashboard" brand: the hero quantifies an intimate conversation ("You went N cards deep").

Deterministic scan: 2 real violations — raw opacity literals at L200 (`.opacity(0.35)`) and L253 (`.opacity(noteFocused ? 0.75 : 0.35)`). Supplementary raw literals L252 (`lineWidth: 1.5`), L255 (`intensity: 0.5`). All 12 em-dash hits are in code comments, zero in user-facing strings. iOS-26 APIs, raw fonts, raw SF Symbols, raw presentation, repeatForever: all clean.

## Priority Issues

- **[P1] Word tap targets are text-sized, not 44pt.** `wordButton` (L334-359) wraps a 13/15pt Text with `.fixedSize()` and no minHeight/contentShape. Direct HIG break for scattered targets a drained one-handed user must hit. The skip button (L101) already does `minHeight: 44` — the discipline exists in-file, just not here. Fix: `.padding(.vertical, .sm).contentShape(Rectangle())` inside each word's label.
- **[P1] Constellation collides under large Dynamic Type / small screens.** Absolute normalized positions in a fixed `screenWidth * 0.70` field (L174) with `.fixedSize()` words → adjacent words overlap at accessibility sizes. Fix: cap effective scaling or fall back to a wrapping flow-layout at `.accessibility1+`.
- **[P2] Save has no terminal confirmation (peak-end break).** `saveReflection()` sets `.done` and dismisses; no `.sensoryFeedback(.success)`, no held beat. The haptic scale reserves `.success` for exactly this terminal moment. Fix: fire success haptic + a brief "kept" acknowledgment before dismiss.
- **[P2] Silent data loss on skip.** Select words / type a note then skip → discarded, no prompt. Fix: auto-persist on skip (more on-brand than a dialog) when words/note are non-empty.
- **[P3] 0-cards / aborted-session headline.** "You went 0 cards deep tonight." is reachable when a session is safe-worded/abandoned immediately — a grim number on the hardest exit. Fix: low-count branch with gentler count-free copy.
- **[P3] Raw literals break zero-raw-values contract.** L200 / L253 opacity, L252 lineWidth, L255 intensity. Add opacity/hairline tokens.

## Persona Red Flags

- **Partner who wants OUT:** exit is `textTertiary` caption in the corner while the glowing bottom CTA funnels to "Reflect on tonight." In a `.vaylCover` with interactive-dismiss disabled, that gray word is the only door. Findability ≠ hittability. If their session aborted, hero greets them with "0 cards deep."
- **Emotionally raw first-timer:** lands on 13 scattered words with no instruction that selection is multi-select, optional, or private. No Save confirmation → may not trust anything was kept.
- **VoiceOver / Reduce-Motion:** Reduce Motion handled well (L349 crossfade). VoiceOver reading order follows source order, not visual scatter; no container/group label announcing "reflection words, N of 13 selected." Tap-target issue compounds for Switch Control.

## Emotional Journey (load-bearing lens for this screen)

The middle is beautifully handled — "breath as layout" (Spacer .xxl between copy and CTA, L136-138), word bank spanning warm→hard so honest feelings have a home, reflection never auto-shoved. The peak and the end are the weak points: (1) the end has no ending — Save vanishes with no success beat; (2) the exit is a whisper while the funnel is a shout; (3) the 0-cards leak stamps a number on the hardest exit. The screen doesn't know whether it's ending a glow or a wound, yet routes both to the same "afterglow" celebration frame.

## Minor Observations

- Reflection footer skip uses `.padding(.sm)` only (L269) — under 44pt, inconsistent with the landing skip.
- `timeContext` computed off `Date()` at render can flip "this morning"→"today" between landing and reflection header across a boundary.
- `id: \.element` on words (L323) is safe only while bank words stay unique.
- Verify `.vaylPressable` actually fires the select haptic on word toggle; if not, selection is silent.

## Questions to Consider

1. Should the hero lead with a number at all on a screen whose thesis is "not a dashboard"?
2. Is skip really the same as "done"? Silent-discard assumes the harsher reading of a user who marked words then skipped.
3. Who is the reflection for — and does the UI say so? Nothing tells the user the words are private-to-them, the unspoken question on a two-device couples app.
4. What does a hurting person deserve at the exit? Safe-worded-out routes to the same celebration frame as a great session.
