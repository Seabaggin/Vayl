# Pulse Field Zones Fix — 2026-06-28

## Problem

`PulseField` renders as a hard-edged rectangle in every context where it lives
on a dark background. The zone colors create a visible square boundary instead
of the atmospheric, edge-dissolving feel in the mockup.

Screenshot as of 2026-06-28: the circumplex field in the `MapFieldSheet` cover
appears as a flat coloured square sitting on the screen, especially visible at
the Friction (magenta) and Protective (rose) corners.

---

## Root Cause

### What the HTML does (correct)

Reference file: `docs/prototypes/map-pulse-us.html`

```css
/* Each zone is a CIRCLE, not a radial gradient fill */
.field { position: relative; width: 248px; height: 248px; }
.zone  { position: absolute; width: 74%; height: 74%;
         border-radius: 50%;          /* circle, not rectangle */
         filter: blur(26px);          /* heavy Gaussian smear */
         opacity: .16; }              /* very subtle */

/* Each circle is placed at -7% from its corner — overflows the field boundary */
.z-exp { top: -7%;    right:  -7%; background: radial-gradient(closest-side, var(--cyan),    transparent); }
.z-fri { top: -7%;    left:   -7%; background: radial-gradient(closest-side, var(--magenta), transparent); }
.z-pro { bottom: -7%; left:   -7%; background: radial-gradient(closest-side, var(--rose),    transparent); }
.z-sov { bottom: -7%; right:  -7%; background: radial-gradient(closest-side, var(--indigo),  transparent); }
```

Key properties:
- Zone is a **74% circle**, blurred, at 16% opacity.
- Positioned so **7% of the circle overflows** each near edge.
- The field div has **no background** — it's transparent. The circles overflow into
  the page background (dark void), blending invisibly.
- No `overflow: hidden` on `.field` — the overflow is intentional.

### What Swift does (wrong)

```swift
// PulseField.zones — current implementation
RadialGradient(colors: [AppColors.pulseTierExpansive.opacity(0.26), .clear],
               center: .topTrailing, startRadius: 0, endRadius: size * 0.92)
```

Problems:
1. `RadialGradient` fills the **entire ZStack frame** (a rectangle) — the gradient
   starts at a corner and paints opaque color all the way across to 92% of the field.
2. Opacity is 0.20–0.26 vs HTML's 0.16 — slightly more saturated.
3. No blur — sharp gradient edges.
4. No overflow — all color stays inside the `frame(width: size, height: size)`.

Result: four coloured triangles paint the corners of a rectangle. The rectangle
is the square the user sees.

---

## Fix

### File to change
`Vayl/Features/Pulse/Components/PulseField.swift` — the `zones` computed var only.

### Approach: replace RadialGradient fills with blurred circles

```swift
private var zones: some View {
    ZStack {
        // Each circle: 74% of field, blurred, positioned so center lands at
        // 30% or 70% of field width/height — matching HTML's -7% corner overflow.
        // No .clipped() on the parent ZStack so circles bleed beyond the field
        // boundary into the screen background (intentional, matches HTML).
        zoneBlob(AppColors.pulseTierExpansive,  cx: 0.70, cy: 0.30)
        zoneBlob(AppColors.pulseTierFriction,   cx: 0.30, cy: 0.30)
        zoneBlob(AppColors.pulseTierProtective, cx: 0.30, cy: 0.70)
        zoneBlob(AppColors.pulseTierSovereign,  cx: 0.70, cy: 0.70)
    }
}

private func zoneBlob(_ color: Color, cx: CGFloat, cy: CGFloat) -> some View {
    let d = size * 0.74
    return Circle()
        .fill(color.opacity(0.16))           // matches HTML opacity: .16
        .frame(width: d, height: d)
        .blur(radius: size * 0.105)          // blur(26px) on 248px field = 0.105× size
        .position(x: cx * size, y: cy * size)
}
```

### Why 0.30 / 0.70 for the center coords

HTML `.z-exp` (top-right): `top: -7%, right: -7%` on a 74%-wide element.
- Right edge of circle at 107% of field width (7% overflow).
- Left edge at 107% - 74% = 33% from left.
- **Center x = 33% + 37% = 70% from left = 0.70 × size.**
- **Center y = -7% + 37% = 30% from top = 0.30 × size.**

All four zones map symmetrically.

### What the overflow does

`position(x: 0.70 * size, y: 0.30 * size)` on a circle with diameter `0.74 * size`
puts the circle's outer edge at `0.70 + 0.37 = 1.07 × size` from the field origin.
On a 390pt full-screen field that's ~27pt of visual overflow. Since `PulseField`'s
ZStack has no `.clipped()` or `.clipShape()`, circles render beyond the `size × size`
layout frame. On the full-screen cover the overflow disappears into the void/atmosphere
background — the circle edge blends into the screen.

### Blur value

`filter: blur(26px)` in CSS on a 248px field = 26/248 ≈ 0.105. SwiftUI `.blur(radius:)`
uses the same Gaussian model. Proportional value: `size * 0.105`. On a 390pt phone this
gives ~41pt blur — heavy enough to prevent hard edges.

### Reduce Motion

No additional change needed — the zone circles are static (no animation). They respond
to Reduce Motion by not having any animation in the first place.

---

## Done condition

On device: the `MapFieldSheet` cover's circumplex field should read as atmospheric
colour wash filling the screen. No visible rectangular boundary. Expansive
(cyan, top-right) and Protective (rose, bottom-left) zones should dissolve into
the black void beyond the field edge. Compare directly with the HTML mockup open
in Safari side-by-side.

If blur feels too heavy/light on device, adjust `size * 0.105` — the FEEL value.
The opacity 0.16 is the mockup value; try 0.18 if the zones are too subtle.

---

## Files

| File | Change |
|---|---|
| `Vayl/Features/Pulse/Components/PulseField.swift` | Replace `zones` computed var (the `ZStack` of 4 `RadialGradient` views) with 4 `zoneBlob()` calls using `Circle + blur + position`. Add `zoneBlob(_:cx:cy:)` private helper. No other changes. |

Do NOT change `auraLayer`, `axisLabels`, `quadrantLabels`, the `body`, or any other
part of `PulseField`. This is a zones-only swap.
