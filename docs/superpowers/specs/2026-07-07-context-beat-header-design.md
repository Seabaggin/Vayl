# Context Beat Header — Design Spec

**Date:** 2026-07-07
**Status:** Design approved, ready for implementation planning
**Mockups:** published artifacts during design session (kicker-line vs. detached-zone
comparison, then corrected no-chrome/centered-band version using real cards
`sex-and-pleasure/sp-01` and `the-opener/opener-01`)

## Problem

`Card.swift` already carries `contextBeatType` / `contextBeatCopy` / `backCopy`,
fully wired end to end: `ContentLoader` decodes them from deck JSON,
`CoupleSessionStore.activeContextBeat` arms them, and `ContextBeatOverlayView`
renders both the `banner` and `interstitial` cases as a transient overlay shown
**before** the card deals, then dismissed.

That transient-pill treatment is wrong for `banner`-length copy specifically.
Banner copy is a short, one-sentence framing line (e.g. "Jealousy has a memory.
It's older than the two of you.") that's load-bearing for how to answer the
question — a couple that dismisses the pill before reading it, or that reads it
5+ seconds before the card even appears, loses the context by the time the
question is in front of them. It needs to sit with the card, not precede and
then vanish from it.

Separately, the current session-card layout top-anchors the question directly
under the draw row, leaving a large dead zone below on short questions (see
reference screenshot). Adding a header above the question without addressing
this makes the imbalance worse, not better.

`interstitial`-length copy (2+ sentences, an actual definition/reframe, e.g. the
boundary-vs-rule card) is **not** part of this fix — its existing full-screen
"before this card" treatment already works and stays as-is.

## Non-goals

- **The five reveal-mechanic cards** (`whisper`, `unspoken`, `mirror`,
  `snapshot`, `whatIf` — routed through `RevealCardChrome` and its dedicated
  reveal views, gated by `card.isRevealMechanic`). These need their own
  explanation/teaching screens, to be designed separately. This spec's header
  never renders on them.
- **The content-authoring pass.** ~53 cards across the decks have context
  crammed directly into the raw `text` field instead of `context_beat_copy`
  (found during this design session, only partially bucketed into "rhythmic
  pacing / no fix needed," "split-role prompts — separate paired-card feature,"
  and "genuine crammed context — needs re-authoring"). Re-authoring those cards
  is out of scope here; this spec only changes how already-tagged
  `context_beat_copy` renders.
- **Paired `a`/`b` cards** for the split-role prompt pattern ("For him... then,
  for her..."). Flagged as its own future feature; not touched here.
- **`interstitial`-type context.** No changes to `ContextBeatOverlayView`'s
  `interstitial` case or its full-screen pre-card behavior.

## 1. Layout — centered band, no card chrome

`SessionPlayerView.screenLayer` (lines 170-188) currently stacks `drawerRow`
directly above `cardFace(card)` with no vertical centering, so short questions
float near the top with empty space below down to the controls. This changes
to:

- `drawerRow` (top) and the presence/intensity/deal controls (bottom) stay
  exactly where they are — fixed chrome, unaffected by card content length.
- The space between them becomes a `VStack` that **vertically centers** its
  content, rather than top-aligning it. This is centering within that bounded
  band, not the whole screen — short questions still keep a consistent margin
  from both the draw row and the controls, they just aren't glued to the top.
- No card border, background panel, or chrome is added. Text (kicker + question
  together, when a kicker is present) floats directly on the atmosphere,
  matching the real screen today — confirmed against the reference screenshot,
  which has no card box at all.

## 2. `ContextKickerView` — new component

New file, `Vayl/Features/Sessions/Components/ContextKickerView.swift`, matching
the one-component-per-file convention already used for
`ContextBeatOverlayView.swift` and `CardBackFlipView.swift`.

- Single input: the copy string.
- Renders as a small, muted, italic line with a left accent rule — the
  register established in the design-session mockups (13.5px/muted-violet-grey
  equivalent via `AppColors`/`AppFonts` tokens, not raw values — no new tokens
  needed, this reuses the existing caption/tertiary-text tokens).
- No dismiss affordance, no animation-in of its own — it appears and
  disappears with the rest of `screenLayer`'s existing fade (the same
  `holding`/`diving` opacity logic that already governs the whole layer),
  per the existing dealing-animation contract. It does not need independent
  wiring into that fade.

`SessionPlayerView` inserts `ContextKickerView` above `cardFace(card)` inside
the new centered band, conditioned on:

```
!card.isRevealMechanic && card.contextBeatType == .banner
```

## 3. Data flow — no state machine, read the current card directly

The header does not go through `activeContextBeat` / `dismissContextBeat()` /
`beatShownCardIds` — those exist to model "show once, then gone," which is the
wrong shape for something that should persist as long as its card is current.
Instead, `SessionPlayerView` reads `store.currentCard?.contextBeatCopy`
directly whenever the gating condition above is true. If the couple revisits a
card, the header reappears identically — there's no "already seen" suppression
for this treatment, unlike the old pill.

## 4. `CoupleSessionStore` changes

`cardDidChange()` (lines 499-512) currently arms `activeContextBeat` for any
card where `card.hasContextBeat` is true, regardless of `contextBeatType`. This
narrows to interstitial only:

```swift
if card.hasContextBeat, card.contextBeatType == .interstitial,
   !beatShownCardIds.contains(card.id) {
    activeContextBeat = (type: .interstitial, copy: card.contextBeatCopy!)
}
```

`banner`-type cards no longer touch `activeContextBeat` or
`beatShownCardIds` at all.

## 5. `ContextBeatOverlayView` changes

The `banner` case (lines 34-66) becomes unreachable once `CoupleSessionStore`
stops arming it for banner-type cards, and is deleted rather than left dead.
The `interstitial` case is untouched.

## 6. Testing / verification

- A new test case in `VaylTests/CoupleSessionPlaythroughTests.swift` (the
  existing home for `CoupleSessionStore` behavior tests) asserting
  `activeContextBeat` stays `nil` when the current card is `banner`-type, and
  still arms correctly for `interstitial`-type.
- `ContentLintTests.swift`'s existing lint on `contextBeatCopy` needs no
  change — it already covers this field regardless of type.
- Per how Bryan and Claude split verification: Claude build-verifies (compiles,
  tests pass) only. Bryan confirms the centering/motion feel on device — this
  spec does not claim the layout "feels right," only that it matches the
  agreed design.
