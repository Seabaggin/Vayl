# Deck Punch-Out — interaction design

Date: 2026-06-22
Status: SUPERSEDED. The cover and the reinvented in-place overlay both read as a
drag-down. Final implementation reuses the existing **`CardCarousel`**
(`Vayl/Design/Components/Cards/CardCarousel.swift`), which already elevates UP in
place with a screen-wide background dim (no cover). Hand selection + "Settle in"
are wired in HomeDashboardView. The states/decisions below still hold; only the
mechanism changed.
Component: `Vayl/Design/Components/Cards/CardCarousel.swift` + `HomeDashboardView`

## Summary

Replace the deck's slide-up `fullScreenCover` "chest" with an **in-place punch-out
carousel**. Tapping the resting deck card makes it lift toward the user and the deck
fan into a browsable carousel **in place** (no panel sliding up). The container is
**clear** (no fill/color) with a **whisper spectrum rim** framing the carousel as a
faint stage. The rest of Home recedes (fades/blurs) behind. The hand-building chrome
(tonight's corner deck, count, "Settle in") is **revealed progressively** the moment
the user picks their first card. The session handoff is unchanged.

## States

1. **Rest** — the deck card levitates on its pedestal (unchanged).
2. **Browse (punch-out)** — tap the card → it lifts (z-pop, scale ~1.06, shadow
   deepens) and the deck **fans in behind it** (spring) into a swipeable carousel.
   Pulse + Lexicon + tab bar fade/blur back; the greeting name stays but dims. A
   whisper spectrum rim frames the carousel band. The centered card shows a quiet
   "tap to add" cue. Swipe left/right to browse.
3. **Building (first pick)** — tapping the centered card **adds** it; it flies to a
   "tonight" corner deck (top), and *that* is the moment the chrome materializes:
   the corner deck + count, and "Settle in →" at the bottom. Browsing continues;
   each add flies to the corner.
4. **Settle in** — "Settle in →" carries tonight's hand into the session (unchanged
   `onStartHand`).
5. **Dismiss** — tap the faded Home → the carousel collapses back into the card and
   the room un-fades. A back-step undoes the last add.

## Decisions (locked with Bryan)

- **Q1 = A:** tap-a-card = **add**; the first add summons the building chrome (earned).
- **Q2 = B:** clear container, **no fill**, with a **whisper spectrum rim** stage.
- **Q3:** **lift-then-fan** punch-out (card pulls the deck up with it).
- Sub-call 1: **cut the long-term progress bar**; keep the building state lean
  (corner deck + count + Settle in; at most a tiny deck-name label).
- Sub-call 2: **keep tonight's hand on dismiss** (reopening resumes).
- Sub-call 3: recede Pulse + Lexicon + tab bar; **keep the greeting name faintly**.

## Motion

- Punch-out: collapsed (matches the resting card) → expanded (centered card scale
  ~1.06 + lifted shadow, neighbors fanned at ±offset) via `AppAnimation.deckFan`.
- Add: card flies to the corner deck (existing fly-to-corner arc).
- Dismiss: reverse the punch-out, then close.
- Reduce Motion: no fan travel; cross-fade the state, hand still builds.

## Architecture (revised — the cover was abandoned)

- **NO presentation / cover.** A `fullScreenCover` always slides up (even with
  animations disabled), so it was abandoned entirely.
- `CardChestContainer` is split into two pieces, both rendered by HomeDashboardView
  and sharing a `@Namespace`:
  - **CardChestContainer** — the resting deck card.
  - **DeckCarousel** — a PERSISTENT, full-screen overlay in Home's root ZStack,
    invisible at rest (backdrop opacity 0, hit-testing off). On open it ENVELOPS
    the screen (backdrop → 0.5, the deck fans) with no slide.
- The card punches out via `matchedGeometryEffect(id:in:isSource:)` between the
  resting card (source when closed) and the carousel's centered card (source when
  open), so the card morphs between the two.
- The recede (Pulse + Lexicon blur) is driven by `deckOpen` in HomeDashboardView.
- The overlay covers the tab bar, so the tab bar fades without touching
  `RacetrackTabBar`.
- Session handoff (`onStartHand`) and the carousel/hand/add logic are preserved.

## Constraints (do not touch)

- `RacetrackTabBar`, `PulseWidget` / `PulseGraph`, `VaylCardFace` shell.
- The resting hero (`VaylCardFace` on the pedestal) and `onStartHand` contract stay.
