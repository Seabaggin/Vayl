# Card-look variability — design (2026-06-24)

Brainstormed with the human. Decision settled; this is the build spec. Visual reference:
`docs/prototypes/play-card-variability-options.html` (direction **B · Signature**).

## Problem
Every question card renders the identical `VaylCardFace`: fixed cyan/magenta/purple
atmosphere, no deck colour, no read of the card's intensity. Cards feel monotonous and
decks are visually indistinguishable.

## Decision
Two layers of variation, **both generated from data that already exists** (no model change):
- **Deck identity** — each deck's cards take the deck's colorway + a faint category-glyph
  watermark, so a Boundaries card differs from a Desire card (and matches its case).
- **Card weight** — a base-heat glow rises with the card's `intensity` (1→8), so a card
  visibly runs hotter; varies within one deck's session too.

Generated-only. **No authored override field** (deferred — add an optional accent/motif on
the deck later only if a deck needs hand-tuning).

## Model — unchanged
No new fields on `Deck` or `Card`. Derivations:
- `colorway` ← `category` via `DeckStyle.make` → `FoilColorway` (already on the deck case)
- glyph ← `category` via `DeckGlyphKind` (already exists)
- `heat` ← `card.intensity` normalised to 0…1
- (fast-follow) `highlightWords` lit in the colorway — already authored, currently ignored

## Rendering — extend `VaylCardFace` (shell untouched)
Add optional, backward-compatible inputs: `colorway: FoilColorway?`, `heat: Double = 0`,
`glyphPath: Path?`. nil / 0 → **today's exact look**, so Onboarding (which passes none) is
byte-identical. When provided:
- `FaceAtmosphere` recolors its blobs to the colorway (opacity scaled by heat)
- a faint glyph watermark (colorway-tinted) behind the text
- a bottom-up heat glow (colorway; height + opacity by heat)
- the protected **shell — frame, hairlines, border glow, `.drawingGroup()` — stays identical**

Decoupling: the face takes a `Path` (not Play's `DeckGlyphKind` enum) so Design stays
independent of Features/Play. `FoilColorway` is a Design type (FoilOpen), so no inverted
dependency.

## Plumbing
- `CardCarousel` gains optional `colorway: FoilColorway?` + `glyphPath: Path?`; passes
  per-card heat (from `cards[i].intensity`) + colorway + glyph to each `VaylCardFace`.
- `PlayHeroView` passes the featured deck's colorway + glyph.
- Home's carousel and the session pass nil for now (today's look).

## Segments (Vayl build protocol governs)
1. **This:** extend `VaylCardFace` + `CardCarousel` + hero. Device-verify: hero cards take
   the deck colour and warm with intensity; Onboarding unchanged.
2. Session (`SessionPlayerView`) colorway, so in-session cards vary too.
3. (optional) light `highlightWords` in the colorway.

## Out of scope
Authored override field; the bolder "C · Worlds" treatment; any change to the card shell.
