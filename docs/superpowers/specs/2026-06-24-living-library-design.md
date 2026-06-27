# The Living Library — Play deck grid (2026-06-24)

Brainstormed with the human. Motion reference (the three families, interactive):
`docs/prototypes/play-grid-motion-options.html`.

## Goal
Make the Play deck library feel **alive** — the whole library moves as a group — without
re-introducing the failures of the old docked-peek/pan-zoom canvas (hidden decks, a
fade-cutoff band, sparse screen). The human is drawn to all three motion families; the
spine is **whole-library group motion**, with tap-to-detail and ambient life layered on.

## The one rule we do not break again
**The resting state must reveal that a library exists, and every deck stays reachable by
scrolling.** No state where most decks are hidden behind a gesture. Aliveness is added
*on top of* a plain, complete, scrollable grid — never by hiding it.

## Theme: a scroll-reactive hero (consistent with Home)
**Hero-collapse is the screen's signature motion**, chosen to rhyme with Home. Home already
treats the hero zone as a scroll-reactive surface: its Pulse graph is collapsed at rest and
**expands 1:1 with scroll** over a ~320pt range (via `.onScrollGeometryChange`, with a runway
that bounds the scroll to exactly the transform distance). Play mirrors the **mechanism and
motion character** — the same scroll-linked, bounded, 1:1 transform and the same easing — but
in service of this tab's purpose: where Home **blooms toward** the pulse you came for, Play
**yields** the featured deck to the library you came to browse. The consistency is the feel and
the mechanism, not a literal direction (Home expands a secondary module; Play collapses the
primary hero). Matching Home's curve + range is what makes the two tabs feel like one app.

## The system (rest → engage → open)
- **Rest:** hero (featured deck) prominent; the library header + the first row of cases
  *peek* below it, signalling "there's a library, scroll."
- **Engage (scroll):** the hero recedes/collapses and the cases **spread up and settle**
  into the full grid (Hero-collapse + Spread fused into one scroll-driven motion).
- **Open (tap):** a case **grows in place into its detail** (native zoom), tap back shrinks
  it home.
- **Ambient:** staggered entrance + subtle parallax so even the resting grid breathes.

## Segments (each independently shippable + device-verified)

**Build order: B first** — it's the theme, and it matches Home's already-working
scroll-linked mechanism, so we're copying a proven pattern rather than inventing one (which
de-risks the delicate one). Then A, then C.

### A · Expand-in-place  (lowest risk)
Tap a case → it zooms into the detail; tap back → shrinks home.
- **Mechanism:** `matchedGeometryEffect` (iOS 16+) on a shared `@Namespace` declared in
  `PlayView`, with the grid's `DeckCaseView` as source and the detail's case as
  destination, keyed by `deckId`.
- **Decision:** the detail shows the **enlarged static `DeckCaseView`** (a perfect
  static→static matched zoom), not the 3D `MetallicCaseView`. The animated 3D case is
  reserved for the **Begin ceremony** (its existing home), so the zoom stays seamless and
  the 3D drama is the payoff, not the preview. `DeckDetailView` drops its `MetallicCaseView`.
- **Files:** `PlayView` (namespace + pass down), `DeckCellView`/`DeckCaseView`
  (matched source), `DeckDetailView` (matched dest, use `DeckCaseView`).
- **Reduce Motion:** cross-dissolve instead of the zoom.
- **Done (device):** tapping a case grows it into the detail and back, continuous; RM fades.

### B · Hero-collapse + spread entrance  (the theme — build first)
Scroll drives the hero receding and the cases spreading into the grid.
- **Mechanism:** match Home exactly — `.onScrollGeometryChange` reads scrollY → a bounded
  `0…1` collapse progress over a ~300pt range, with a shrinking runway that bounds the
  scroll to the collapse distance (the `HomeDashboardView` pattern, same easing/curve). Hero
  scales + fades by the progress and collapses toward a slim featured bar; grid cases get a
  staggered entrance (scale/translate from slightly-collapsed → settled) as they enter view.
- **Consistency:** reuse Home's range + easing so Play's collapse and Home's expand read as
  one motion language. This is the screen's theme.
- **Files:** `PlayView` (scroll offset + hero collapse wiring), `PlayHeroView`
  (collapsible), `DeckWallView`/`DeckCellView` (entrance spread).
- **Guardrails:** all decks reachable by continued scroll; no clip/fade cutoff; the
  collapsed hero stays useful (slim featured bar), never vanishes; performance holds
  (cases are `.drawingGroup()`-rasterized).
- **Reduce Motion:** plain scroll, hero pinned, no spread (snap to final state).
- **Done (device):** scrolling collapses the hero + spreads the grid in; smooth; all decks
  reachable; RM = plain scroll.

### C · Ambient  (polish)
- Staggered first-appearance of cases (cascade), a subtle scroll parallax, optional gentle
  hero float. All via `.ambientAnimation(...)` (RM-safe, contract-required on loops).
- **Files:** `DeckCellView` (entrance), `PlayHeroView` (float).
- **Done (device):** the grid breathes; RM disables all of it.

## Constraints (contract)
- Tokens only; **`VaylCardFace` shell untouched**; reuse `CardCarousel` / `DeckCaseView` /
  `MetallicCaseView`; modals via `.vaylSheet` / `.vaylCover`.
- **Reduce Motion fallback on every motion** (hard requirement).
- The dead `ZoomablePanView` + `PlayStore.canvasExpanded` / `expandCanvas` /
  `collapseCanvas` are removed as part of this work (the living library replaces that idea).

## Out of scope
The bolder "C · Worlds" card-art treatment; authored per-deck visual overrides; deck
search/filter; any change to the masthead or the hero carousel's internal physics.

## Verification
Compile (`xcodebuild … build`) + the human runs each segment on device and confirms the
**feel** before the next segment begins. Build-succeeds is not done; feel-is-correct is done.
