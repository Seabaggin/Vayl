# Deck Case Foil — Debossed Hex Foil Design

**Date:** 2026-06-09
**Status:** Approved direction, pending spec review
**Module:** FoilOpen (`Vayl/Design/Components/Effects/FoilOpen/`) — reusable, content-agnostic

## Context

The sealed deck case is the reward object of the OB BuildDeck phase — and a reusable
ceremony (materialize → tap-to-crack → shatter → reveal) for every future deck in the
app. Two prior surface iterations failed in opposite directions:

1. **Plasma holo** — full-field fbm noise. Energetic but off-brand: scrambled the
   ordered cyan→purple→magenta spectrum, produced crimson (outside the Vayl palette),
   drowned the 3D face shading, and the screen-space noise flowed continuously across
   the box fold (read as a projected image, not a wrapped material).
2. **Dark anodized sweep** — ordered spectrum, hue-preserving deepen, single highlight
   band. On-brand but **bland**: user diagnosis was specifically *missing material
   richness* — no micro-structure, no relief, no tactility. (Not motion, not
   brightness, not story.)

**Design principle:** real materials read rich because light interacts with structure
at multiple scales. Don't paint color onto the surface — carve geometry into it and
let light find the carving.

**Real-world anchors:** letterpress deboss on black foil stock (luxury packaging),
credit-card security holograms (geometric micro-pattern that flashes in sequence as
light crosses), brushed metal anisotropic specular.

## Design

### 1 · Material — debossed hex lattice in anodized metal

- Base: near-void anodized metal box. The existing `MetallicCaseView` Canvas
  projection stays: 8-corner box, painter-sorted faces, per-face brightness from a
  single light (`metalShading`) — this is what makes the box read as a volume.
- Front face carries the **hex lattice from `VaylCardBack` pressed in as relief**:
  procedural hex-grid distance field in the shader; distance-to-nearest-edge → V-groove
  profile; each groove gets a **lit flank and a shadow flank** keyed to the sweep-light
  position.
- Between grooves: flat metal, dim anodized base only. **Light lives in the
  structure, never in the field.**
- Spectrum: keep the Segment-1 foundation — one ordered cyan→purple→magenta sweep,
  position-keyed across the face, hue-preserving deepen (no channel squaring), no
  wrap seam, no time term on the ramp. Color shows only where a groove flank catches
  the band.

### 2 · Light — one anisotropic band, float-driven

- A single brushed-metal light band (long blade of specular) travels with the float
  tilt — the box's existing slow drift is the sole animation driver.
- **No noise-driven animation.** Aliveness = cell-by-cell glints as the band crosses
  lattice edges (sequential sparkle, light over cut glass).
- Reduce Motion: static ¾ view, band parked at a flattering angle, grooves still lit —
  the relief reads even frozen.

### 3 · Face-space UVs — the fold fix

- Pass the front face's four projected quad corners into the shader as uniforms;
  compute face-local UV via inverse bilinear mapping.
- The lattice lives in **face space**: grooves foreshorten with tilt and terminate at
  the box fold. Side/top faces get no lattice — darker plain anodized metal, exactly
  how stamped foil looks from the side.
- This solves the projected-image problem at the root (previously patched with
  luminance gating).

### 4 · Deck identity — the reuse contract

One house material for every deck box. Identity enters only through a small theme:

```swift
struct FoilDeckTheme {              // Model layer — pure struct, no logic
    var colorway: FoilColorway      // category color coding (legend TBD)
    var deckName: String            // embossed text on the front face
}
```

- `colorway` — drives groove flash, sweep tint, and (later) crack light-bleed.
  Solo decks = app spectrum (cyan→purple→magenta). Other categories (sex, jealousy,
  …) get their own ramps via a legend defined later. `FoilColorway` is a named ramp
  (ordered color stops), not raw colors at call sites — tokens stay in the theme
  layer.
- `deckName` — embossed on the front face in ClashDisplay (`AppFonts.display`),
  using the same emboss shadow/highlight pass technique as the `VaylCardBack`
  wordmark. Rendered as Canvas passes positioned on the projected front-face quad
  (not in the shader). The serif system-font placeholder and concentric-circle
  emblem are removed.
- A hairline inset frame (spectrum/colorway gradient) is embossed on the front face,
  echoing the card back's inset frame.
- `MetallicCaseView(theme:)` — the parameter is defaulted to the solo theme, so
  existing call sites (BuildDeckPhase) compile unchanged; future consumers pass
  their own.

### 5 · Ceremony hooks (forward-looking, separate build phase)

- Cracks propagate **along hex groove edges** — the crack engine's branches snap to
  lattice paths; shatter plates become hex clusters. The deboss is the fracture map,
  visible from the first frame.
- Crack light-bleed uses the deck's colorway: the contents glow, the case barely
  holds the light in.
- The existing tap-crack ceremony keeps working on the new surface in the interim;
  lattice-snapped cracks are a follow-up phase, not part of the surface build.

## Constraints

- Files: `MetallicCaseView.swift`, `HolographicShimmer.metal` (a NEW stitchable
  `hexFoilSurface` function replaces the `holoFoilSurface` usage —
  `holoFoilSurface` itself and `holoColor`, `causticLayer`, `htmlCaustics`,
  `holoSpecular` are untouched), plus a new `FoilDeckTheme` model file. No card files, no director,
  no phase files (BuildDeckPhase only changes if the `MetallicCaseView` initializer
  signature changes).
- Design tokens only — colorway ramps resolve from `AppColors` spectrum tokens for
  the default; no raw color literals in views.
- All geometry proportional to face size — no fixed pixels.
- Reduce Motion fallback mandatory (static band, no float).
- Shader time uniforms must stay wrapped/elapsed (float32 precision — never absolute
  timestamps).
- Metal gotcha: clean build after every `.metal` edit (incremental builds serve stale
  shaders).

## Verification

- Judging harness: the **"Case vs card back"** side-by-side `#Preview` in
  `MetallicCaseView.swift` (already added). Material richness, spectrum order, and
  kinship are judged there and on device per the Build Protocol — built segments are
  done only when the user confirms feel on device.
- Theme reuse: a second preview with a non-default colorway + deck name verifies the
  contract renders correctly without code changes.
- Fold check: watch the lattice terminate at the front/side fold during float.

## Out of scope

- Colorway legend (category → ramp mapping) — later.
- Lattice-snapped crack propagation + hex shatter plates — follow-up phase after the
  surface feels right.
- Wiring the foil-tear engine into the director / BuildDeck flow completion.
