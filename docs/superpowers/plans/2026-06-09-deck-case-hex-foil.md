# Debossed Hex Foil Deck Case Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the deck case's flat anodized surface with a materially rich debossed hex lattice — light lives in the carved structure, deck identity enters via a `FoilDeckTheme` (colorway + embossed deck name).

**Architecture:** The existing `MetallicCaseView` Canvas box projection stays. Per-frame geometry (tilt angles + projected corners) is extracted so both the Canvas and a new `hexFoilSurface` Metal shader receive it. The shader maps screen pixels into face-local UV via inverse bilinear over the front quad, carves a procedural hex-groove field there, and lights groove flanks with one tilt-driven anisotropic band in the deck's colorway. The brand layer (deck name + hairline frame) is embossed Canvas passes, not shader work.

**Tech Stack:** SwiftUI Canvas + `colorEffect` (SwiftUI ShaderLibrary), Metal stitchable functions, Swift 6, iOS 16+ baseline.

**Spec:** `docs/superpowers/specs/2026-06-09-deck-case-foil-design.md`

**Verification model:** This is a shader/visual feature — there is no meaningful unit test for pixels. Per the project Build Protocol (CLAUDE.md), each task's gate is: build succeeds **and** the change is observed in the Xcode "Case vs card back" preview / simulator; the final gate is the user confirming feel on device. Build with a **pinned DerivedData path** (this session previously installed a stale binary from the wrong DerivedData folder — do not repeat that).

**Build command (use everywhere):**
```bash
cd /Users/bryanjorden/Documents/School/Code/Vayl
xcodebuild -project Vayl.xcodeproj -scheme Vayl \
  -destination 'platform=iOS Simulator,id=1A610585-FBCA-47EC-8519-C0F1C5426D56' \
  -derivedDataPath /tmp/vayl-foil-dd build -quiet
```
Expected: exit code 0. **After any `.metal` edit, insert `clean` before `build`** (incremental builds serve stale shaders — project memory).

**Install + launch (for device checks):**
```bash
xcrun simctl install 1A610585-FBCA-47EC-8519-C0F1C5426D56 \
  /tmp/vayl-foil-dd/Build/Products/Debug-iphonesimulator/Vayl.app
xcrun simctl launch 1A610585-FBCA-47EC-8519-C0F1C5426D56 com.bryanjorden.Vayl
```

**File map:**
- Create: `Vayl/Design/Components/Effects/FoilOpen/FoilDeckTheme.swift` — pure model (colorway + deck name). Project uses filesystem-synchronized groups: new files under `Vayl/` are picked up automatically.
- Modify: `Vayl/Design/Components/Effects/HolographicShimmer.metal` — append `hexFoilSurface` + helpers at end of file. Do NOT touch `holoColor`, `causticLayer`, `htmlCaustics`, `holoSpecular`, `holoFoilSurface`.
- Modify: `Vayl/Design/Components/Effects/FoilOpen/MetallicCaseView.swift` — geometry extraction, shader swap, brand layer, theme parameter, previews.

---

### Task 1: FoilDeckTheme model

**Files:**
- Create: `Vayl/Design/Components/Effects/FoilOpen/FoilDeckTheme.swift`

- [ ] **Step 1: Write the model file**

```swift
//
//  FoilDeckTheme.swift
//  Vayl
//
//  FoilOpen module — deck identity for the sealed case.
//  The case material (debossed hex lattice in anodized metal) is house language,
//  identical for every deck. Identity enters ONLY through this theme:
//  a category colorway and the deck name embossed on the front face.
//

import SwiftUI

/// Ordered three-stop ramp — the color identity of a deck category.
/// Solo decks use the app spectrum; other categories (sex, jealousy, …)
/// get their own ramps via a legend defined later.
struct FoilColorway: Equatable {
    var c0: Color
    var c1: Color
    var c2: Color

    /// App-centric colorway — solo decks and the OB starter deck.
    static let solo = FoilColorway(
        c0: AppColors.spectrumCyan,
        c1: AppColors.spectrumPurple,
        c2: AppColors.spectrumMagenta
    )
}

/// Pure data — no logic, no dependencies beyond color tokens.
struct FoilDeckTheme: Equatable {
    var colorway: FoilColorway
    var deckName: String

    /// The OB starter deck.
    static let vayl = FoilDeckTheme(colorway: .solo, deckName: "VAYL")
}
```

- [ ] **Step 2: Build to verify it compiles**

Run the pinned build command. Expected: exit 0.

- [ ] **Step 3: Commit**

```bash
git add Vayl/Design/Components/Effects/FoilOpen/FoilDeckTheme.swift
git commit -m "feat(foil): add FoilDeckTheme — colorway + deck name reuse contract"
```

---

### Task 2: Extract per-frame case geometry

**Files:**
- Modify: `Vayl/Design/Components/Effects/FoilOpen/MetallicCaseView.swift`

Why: the shader needs the projected front-quad corners and the tilt angle every frame; today they're computed inside `drawCase`. Extract them so `foilLayer` computes geometry ONCE and feeds both the Canvas closure and the shader uniforms. **Pure refactor — rendered output must be pixel-identical.**

- [ ] **Step 1: Add the geometry struct and builder**

Add inside `MetallicCaseView` (below the tunables):

```swift
// MARK: - Per-frame geometry

/// Everything the Canvas closure AND the foil shader need each frame.
private struct CaseGeometry {
    let rx: Double          // X tilt (radians)
    let ry: Double          // Y tilt (radians)
    let ryDeg: Double       // Y tilt (degrees) — drives metal hue + band phase
    let proj: [CGPoint]     // 8 projected corners
    let frontQuad: [CGPoint] // front face TL, TR, BR, BL (proj[0...3])
}

private func caseGeometry(size: CGSize, t: Double, motion: Bool) -> CaseGeometry {
    let osc = motion ? 1.0 : 0.0
    let ryDeg = 21.0 + osc * tiltAmplitude        * dsin(t * 0.42 * floatSpeed)
    let rxDeg = -16.0 + osc * tiltAmplitude * 0.4 * dcos(t * 0.31 * floatSpeed)
    let rx = rxDeg * .pi / 180, ry = ryDeg * .pi / 180

    let fit = Double(min(size.width, size.height / 1.5)) * Double(boxScale)
    let w = fit, h = fit * 1.5, d = fit * Double(depthFrac)
    let hx = w / 2, hy = h / 2, hz = d / 2
    let center = CGPoint(x: size.width / 2, y: size.height / 2)

    let corners3D: [SIMD3<Double>] = [
        SIMD3(-hx, -hy,  hz), SIMD3( hx, -hy,  hz), SIMD3( hx,  hy,  hz), SIMD3(-hx,  hy,  hz),
        SIMD3(-hx, -hy, -hz), SIMD3( hx, -hy, -hz), SIMD3( hx,  hy, -hz), SIMD3(-hx,  hy, -hz),
    ]
    let proj = corners3D.map { project(rotate($0, rx: rx, ry: ry), center: center) }
    return CaseGeometry(rx: rx, ry: ry, ryDeg: ryDeg,
                        proj: proj, frontQuad: Array(proj[0...3]))
}
```

- [ ] **Step 2: Rewire drawCase to consume the geometry**

Change the signature and delete the duplicated math at the top of `drawCase` (the `osc/ryDeg/rxDeg/rx/ry` block, the box-dimension block, `corners3D`, and the `proj` map). The `corners3D` array must stay (face culling sums rotated corner z) — keep it as a local rebuilt from the same dimensions, or simpler: keep the dimension math for `corners3D` only. Resulting head of `drawCase`:

```swift
private func drawCase(_ ctx: inout GraphicsContext, size: CGSize, geo: CaseGeometry) {
    let rx = geo.rx, ry = geo.ry
    let caseHue = hueOffset + geo.ryDeg * hueShift
    let light = SIMD3(-0.20, -0.62, 0.72)

    // box dimensions — needed for face culling (rotated corner depth)
    let fit = Double(min(size.width, size.height / 1.5)) * Double(boxScale)
    let w = fit, h = fit * 1.5, d = fit * Double(depthFrac)
    let hx = w / 2, hy = h / 2, hz = d / 2
    let corners3D: [SIMD3<Double>] = [
        SIMD3(-hx, -hy,  hz), SIMD3( hx, -hy,  hz), SIMD3( hx,  hy,  hz), SIMD3(-hx,  hy,  hz),
        SIMD3(-hx, -hy, -hz), SIMD3( hx, -hy, -hz), SIMD3( hx,  hy, -hz), SIMD3(-hx,  hy, -hz),
    ]
    let proj = geo.proj
    // … the rest of drawCase (faces, culling, fills) is unchanged from here
```

- [ ] **Step 3: Rewire foilLayer**

```swift
@ViewBuilder
private func foilLayer(size: CGSize, t: Double, motion: Bool) -> some View {
    let geo = caseGeometry(size: size, t: t, motion: motion)
    Canvas { ctx, _ in drawCase(&ctx, size: size, geo: geo) }
        .colorEffect(ShaderLibrary.holoFoilSurface(
            .float2(size),
            .float(Float((t * holoSpeed).truncatingRemainder(dividingBy: 600))),
            .float(Float(holoIntensity)),
            .float(Float(holoScale)),
            .float(Float(holoSharpness)),
            .float(Float(holoShine)),
            .float(Float(pattern))
        ))
}
```

(The old shader stays wired for this task — it's replaced in Task 3.)

- [ ] **Step 4: Build + eyeball the preview for identical output**

Run the pinned build. Expected: exit 0. Open the "Metallic case" preview in Xcode — the box must float exactly as before (same angles, same shading).

- [ ] **Step 5: Commit**

```bash
git add Vayl/Design/Components/Effects/FoilOpen/MetallicCaseView.swift
git commit -m "refactor(foil): extract per-frame CaseGeometry for shader uniforms"
```

---

### Task 3: hexFoilSurface shader — face-space UV + ordered band (no lattice yet)

**Files:**
- Modify: `Vayl/Design/Components/Effects/HolographicShimmer.metal` (append at end)
- Modify: `Vayl/Design/Components/Effects/FoilOpen/MetallicCaseView.swift` (swap colorEffect)

The shader lands in two stages so face-space mapping is verified before the lattice goes in. This stage: inverse bilinear front-quad UV; one tilt-driven band tinted by the colorway; side faces untouched.

- [ ] **Step 1: Append helpers + stitchable to HolographicShimmer.metal**

```metal
// MARK: - Debossed hex foil (MetallicCaseView)
// Face-space material: screen pixels map into the front face's local UV via
// inverse bilinear over the projected quad, so the lattice foreshortens with
// tilt and TERMINATES at the box fold. Side faces pass through untouched —
// stamped foil only fronts the box. One anisotropic band, phase-driven by the
// float tilt (NOT time): the float is the sole animation driver.

static float foilModf(float x, float y) { return x - y * floor(x / y); }
static float2 foilMod2(float2 x, float2 y) {
    return float2(foilModf(x.x, y.x), foilModf(x.y, y.y));
}
static float foilCross2(float2 a, float2 b) { return a.x * b.y - a.y * b.x; }

// Inverse bilinear (iq): point p in quad (a,b,c,d = TL,TR,BR,BL) → UV in [0,1]².
// Returns (-1,-1) when p has no valid mapping.
static float2 invBilinear(float2 p, float2 a, float2 b, float2 c, float2 d) {
    float2 e = b - a, f = d - a, g = a - b + c - d, h = p - a;
    float k2 = foilCross2(g, f);
    float k1 = foilCross2(e, f) + foilCross2(h, g);
    float k0 = foilCross2(h, e);
    float u, v;
    if (abs(k2) < 1e-4) {                       // parallelogram fast path
        if (abs(k1) < 1e-6) return float2(-1.0);
        v = -k0 / k1;
        u = (h.x - f.x * v) / (e.x + g.x * v);
    } else {
        float w = k1 * k1 - 4.0 * k0 * k2;
        if (w < 0.0) return float2(-1.0);
        w = sqrt(w);
        float v1 = (-k1 - w) / (2.0 * k2);
        v = (v1 >= 0.0 && v1 <= 1.0) ? v1 : (-k1 + w) / (2.0 * k2);
        u = (h.x - f.x * v) / (e.x + g.x * v);
    }
    return float2(u, v);
}

// 3-stop ordered ramp c0→c1→c2, NON-cyclic — same shape as the card hairline
// gradient (.leading → .trailing stops at 0 / 0.5 / 1). No wrap seam.
static float3 ramp3(float t, float3 c0, float3 c1, float3 c2) {
    t = clamp(t, 0.0, 1.0);
    return t < 0.5 ? mix(c0, c1, t * 2.0) : mix(c1, c2, (t - 0.5) * 2.0);
}

[[stitchable]]
half4 hexFoilSurface(float2 position,
                     half4  currentColor,
                     float2 qa, float2 qb,    // front quad TL, TR (view points)
                     float2 qc, float2 qd,    // front quad BR, BL
                     half4  rampA,            // colorway stop 0
                     half4  rampB,            // colorway stop 1
                     half4  rampC,            // colorway stop 2
                     float  phase,            // band phase — from float tilt, NOT time
                     float  lattice,          // hex columns across face width (~13)
                     float  grooveW,          // groove half-width, cell units (~0.10)
                     float  bandSharp,        // band specular exponent (~10)
                     float  bandGain,         // band strength (~0.9)
                     float  glintGain)        // per-cell glint strength (~0.5)
{
    half a = currentColor.a;
    if (a < 0.01h) return currentColor;                  // leave the void alone

    float2 uvq = invBilinear(position, qa, qb, qc, qd);
    // Outside the front face (side/top faces, silhouette margins): plain metal.
    if (uvq.x < 0.0 || uvq.x > 1.0 || uvq.y < 0.0 || uvq.y > 1.0) return currentColor;

    float3 base = float3(currentColor.rgb) / max(float(a), 0.001);

    // one anisotropic band — tilt-phase, ordered colorway along the sweep axis
    float2 dir  = normalize(float2(0.5, 1.0));
    float  cpn  = dot(uvq, dir) / 1.3416;                // 0…1 across the face
    float  lum  = 0.5 + 0.5 * sin(cpn * 2.6 + phase);
    float  band = pow(lum, bandSharp);

    float3 ink = ramp3(cpn, float3(rampA.rgb), float3(rampB.rgb), float3(rampC.rgb));

    float3 col = base + ink * band * (0.30 * bandGain);  // flat-metal sheen only (lattice comes next task)
    col = clamp(col, 0.0, 1.0);
    return half4(half3(col * float(a)), a);
}
```

(`lattice`, `grooveW`, `glintGain` are wired but unused this task — they keep the Swift call site stable when Task 4 fills them in.)

- [ ] **Step 2: Swap the colorEffect in MetallicCaseView**

Replace the tunables block additions and `foilLayer` shader call. Add new tunables (delete none yet):

```swift
// Debossed hex foil surface
var latticeColumns: Double = 13     // hex columns across the face width
var grooveWidth:    Double = 0.10   // groove half-width in cell units
var bandSharpness:  Double = 10     // band specular exponent
var bandGain:       Double = 0.9    // band strength
var glintGain:      Double = 0.5    // per-cell glint strength
var bandTravel:     Double = 0.35   // band phase per degree of Y tilt
var theme: FoilDeckTheme = .vayl
```

New `foilLayer` body:

```swift
@ViewBuilder
private func foilLayer(size: CGSize, t: Double, motion: Bool) -> some View {
    let geo = caseGeometry(size: size, t: t, motion: motion)
    Canvas { ctx, _ in drawCase(&ctx, size: size, geo: geo) }
        .colorEffect(ShaderLibrary.hexFoilSurface(
            .float2(geo.frontQuad[0]),
            .float2(geo.frontQuad[1]),
            .float2(geo.frontQuad[2]),
            .float2(geo.frontQuad[3]),
            .color(theme.colorway.c0),
            .color(theme.colorway.c1),
            .color(theme.colorway.c2),
            .float(Float(geo.ryDeg * bandTravel)),
            .float(Float(latticeColumns)),
            .float(Float(grooveWidth)),
            .float(Float(bandSharpness)),
            .float(Float(bandGain)),
            .float(Float(glintGain))
        ))
}
```

- [ ] **Step 3: CLEAN build (metal changed) + verify in preview**

Run the pinned build **with `clean build`**. Expected: exit 0. In the "Case vs card back" preview: a single ordered colorway band sweeps the FRONT face as the box floats; the band's color order matches the card back hairline (cyan top-left → magenta bottom-right); side/top faces show plain dark metal with **no band crossing the fold**.

- [ ] **Step 4: Commit**

```bash
git add Vayl/Design/Components/Effects/HolographicShimmer.metal \
        Vayl/Design/Components/Effects/FoilOpen/MetallicCaseView.swift
git commit -m "feat(foil): hexFoilSurface stage 1 — face-space UV + tilt-driven ordered band"
```

---

### Task 4: Hex lattice grooves + flank lighting + glints

**Files:**
- Modify: `Vayl/Design/Components/Effects/HolographicShimmer.metal` (extend `hexFoilSurface`)

- [ ] **Step 1: Add the hex edge helper above `hexFoilSurface`**

```metal
// Nearest hex edge for a point in cell-local coords. Returns
// (distance-to-edge, outward edge normal xy). Grid: pointy-top hexes tiled
// on r = (1, √3); cell centers at distance 0.5 from each edge.
static float3 hexEdge(float2 gv) {
    float2 p  = abs(gv);
    float2 n1 = normalize(float2(1.0, 1.7320508));
    float  c  = dot(p, n1);
    float  d  = 0.5 - max(c, p.x);
    float2 n  = (p.x > c) ? float2(1.0, 0.0) : n1;
    n = float2(gv.x < 0.0 ? -n.x : n.x,
               gv.y < 0.0 ? -n.y : n.y);
    return float3(d, n.x, n.y);
}
```

- [ ] **Step 2: Replace the band-only color block in `hexFoilSurface`**

Replace from `float3 col = base + ink * band * (0.30 * bandGain);` to the `clamp` line with:

```metal
    // ---- debossed hex lattice in face space (v spans 1.5× the face width) ----
    const float2 r   = float2(1.0, 1.7320508);
    float2 huv = float2(uvq.x, uvq.y * 1.5) * lattice;
    float2 ga  = foilMod2(huv, r) - r * 0.5;
    float2 gb  = foilMod2(huv - r * 0.5, r) - r * 0.5;
    float2 gv  = dot(ga, ga) < dot(gb, gb) ? ga : gb;
    float2 id  = huv - gv;                       // cell id — per-cell variation
    float3 e   = hexEdge(gv);                    // x: dist to edge · yz: outward normal

    // V-groove: 1 at the edge line, 0 on the flats
    float groove = 1.0 - smoothstep(0.0, grooveW, e.x);

    // emboss flanks: lit toward the sweep axis, shadowed away — the relief read
    float facing = dot(float2(e.y, e.z), dir);

    // per-cell shimmer: deterministic offset so cells ignite in sequence, not in unison
    float2 cell  = cellHash(id);
    float  twink = 0.75 + 0.25 * sin(cell.x * 6.2832 + phase * (1.0 + cell.y));

    float lit    = groove * max(0.0,  facing) * (0.16 + band * bandGain) * twink;
    float shadow = groove * max(0.0, -facing) * 0.55;
    float glint  = groove * band * smoothstep(0.60, 0.95, twink) * glintGain;

    float3 col = base
        + ink * lit                              // lit flank ignites in the colorway
        - base * shadow                          // shadow flank carves below base
        + mix(ink, float3(1.0), 0.5) * glint     // hot glints where band crosses cells
        + ink * band * 0.05;                     // faint sheen on flats — band stays legible
    col = clamp(col, 0.0, 1.0);
```

- [ ] **Step 3: CLEAN build + judge in the side-by-side preview**

Expected: exit 0. In "Case vs card back": the front face reads as black foil stock with the hex lattice pressed in — lit flanks in ordered colorway, dark flanks carving deeper than the base; glints travel cell-by-cell as the band sweeps; flats stay near-void; lattice visibly foreshortens with tilt and stops at the fold. No red anywhere.

- [ ] **Step 4: Install on simulator for a feel pass, tune tunables if needed**

Install + launch (commands at top). Tunables to nudge on device if the read is off: `latticeColumns` (cell size), `grooveWidth` (relief weight), `bandSharp`/`bandGain` (drama), `glintGain` (sparkle). Iterate in Swift on device — do not prototype this in HTML (project memory).

- [ ] **Step 5: Commit**

```bash
git add Vayl/Design/Components/Effects/HolographicShimmer.metal \
        Vayl/Design/Components/Effects/FoilOpen/MetallicCaseView.swift
git commit -m "feat(foil): debossed hex lattice — groove flanks, sequential glints"
```

---

### Task 5: Embossed brand layer — deck name + hairline frame

**Files:**
- Modify: `Vayl/Design/Components/Effects/FoilOpen/MetallicCaseView.swift`

Replaces `drawEmblem` (serif system font + concentric circles — both off-brand).

- [ ] **Step 1: Delete `drawEmblem` and its call site**

Remove the whole `// MARK: - Emblem` section and the `if let front = visible.first(where: { $0.f.isFront }) { drawEmblem(...) }` block in `drawCase`. Remove the `emblemOpacity` tunable.

- [ ] **Step 2: Add the brand layer**

```swift
// MARK: - Brand layer (embossed deck name + hairline frame)

/// Affine map of the unit square onto the projected front quad (TL,TR,BR,BL).
/// Drops perspective — acceptable at this float's low tilt, same approximation
/// the old emblem used.
private func frontFaceTransform(_ q: [CGPoint]) -> CGAffineTransform {
    let o = q[0], bx = q[1], by = q[3]
    return CGAffineTransform(a: bx.x - o.x, b: bx.y - o.y,
                             c: by.x - o.x, d: by.y - o.y,
                             tx: o.x, ty: o.y)
}

private func drawBrand(_ ctx: inout GraphicsContext, quad: [CGPoint]) {
    guard quad.count == 4 else { return }
    let edgeW = hypot(quad[1].x - quad[0].x, quad[1].y - quad[0].y)
    guard edgeW > 1 else { return }

    // — hairline inset frame, colorway gradient, drawn in unit-face space —
    var fc = ctx
    fc.concatenate(frontFaceTransform(quad))
    let inset = 9.0 / edgeW                       // matches the card back's 9pt inset
    let frame = Path(roundedRect: CGRect(x: inset, y: inset * (2.0/3.0),
                                         width: 1 - inset * 2,
                                         height: 1 - inset * (4.0/3.0)),
                     cornerRadius: 0.03)
    fc.stroke(
        frame,
        with: .linearGradient(
            Gradient(stops: [
                .init(color: theme.colorway.c0.opacity(0.27), location: 0.0),
                .init(color: theme.colorway.c1.opacity(0.27), location: 0.5),
                .init(color: theme.colorway.c2.opacity(0.27), location: 1.0),
            ]),
            startPoint: CGPoint(x: inset, y: 0.5),
            endPoint:   CGPoint(x: 1 - inset, y: 0.5)
        ),
        lineWidth: 0.6 / edgeW
    )

    // — embossed deck name, screen space at the projected anchor (low-center) —
    let cx = (quad[0].x + quad[1].x + quad[2].x + quad[3].x) / 4
    let cy = (quad[0].y + quad[1].y + quad[2].y + quad[3].y) / 4
    let anchor   = CGPoint(x: cx, y: cy + edgeW * 0.52)
    let fontSize = edgeW * 0.085

    func nameText(_ fs: CGFloat) -> Text {
        Text(theme.deckName)
            .font(AppFonts.display(fs, weight: .medium, relativeTo: .title))
            .tracking(fontSize * 0.45)
    }

    // emboss passes — same recipe as the VaylCardBack wordmark
    var shadowPass = ctx
    shadowPass.addFilter(.blur(radius: 0.8))
    shadowPass.draw(nameText(fontSize).foregroundStyle(Color.black.opacity(0.55)),
                    at: CGPoint(x: anchor.x + 0.8, y: anchor.y + 0.9), anchor: .center)

    var highlightPass = ctx
    highlightPass.addFilter(.blur(radius: 0.6))
    highlightPass.draw(nameText(fontSize).foregroundStyle(Color.white.opacity(0.45)),
                       at: CGPoint(x: anchor.x - 0.7, y: anchor.y - 0.8), anchor: .center)

    var corePass = ctx
    corePass.clipToLayer(opacity: 0.90) { clip in
        clip.draw(nameText(fontSize).foregroundStyle(Color.white),
                  at: anchor, anchor: .center)
    }
    let bounds = CGRect(x: anchor.x - fontSize * 4, y: anchor.y - fontSize,
                        width: fontSize * 8, height: fontSize * 2)
    corePass.fill(
        Path(bounds),
        with: .linearGradient(
            Gradient(stops: [
                .init(color: theme.colorway.c0, location: 0.0),
                .init(color: theme.colorway.c1, location: 0.4),
                .init(color: theme.colorway.c2, location: 1.0),
            ]),
            startPoint: CGPoint(x: bounds.minX, y: anchor.y),
            endPoint:   CGPoint(x: bounds.maxX, y: anchor.y)
        )
    )
}
```

Call it where `drawEmblem` was called in `drawCase`:

```swift
if let front = visible.first(where: { $0.f.isFront }) {
    drawBrand(&ctx, quad: front.f.idx.map { proj[$0] })
}
```

- [ ] **Step 3: Build (no metal change — incremental fine) + judge**

Expected: exit 0. Preview check: "VAYL" embossed low on the front face in ClashDisplay with the colorway core + emboss relief, visually kin to the card back wordmark; hairline frame inset on the face, tracking the quad as the box floats. The shader's groove glints catching around the embossed text is expected and good.

- [ ] **Step 4: Commit**

```bash
git add Vayl/Design/Components/Effects/FoilOpen/MetallicCaseView.swift
git commit -m "feat(foil): embossed deck-name brand layer + hairline frame, kill serif emblem"
```

---

### Task 6: Theme parameter surface + alt-theme preview

**Files:**
- Modify: `Vayl/Design/Components/Effects/FoilOpen/MetallicCaseView.swift`

`theme` is already a stored property (Task 3), so `MetallicCaseView(theme:)` already compiles with a default. This task proves the contract.

- [ ] **Step 1: Add the alt-theme preview**

```swift
// Reuse-contract proof: a different colorway + deck name with ZERO code changes.
// Ramp deliberately reuses existing tokens in a different order — the real
// category legend (sex, jealousy, …) is defined later.
#Preview("Alt deck theme") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        MetallicCaseView(theme: FoilDeckTheme(
            colorway: FoilColorway(
                c0: AppColors.spectrumMagenta,
                c1: AppColors.spectrumPurple,
                c2: AppColors.spectrumCyan
            ),
            deckName: "JEALOUSY"
        ))
    }
    .preferredColorScheme(.dark)
}
```

Note: `MetallicCaseView` declares its tunables as `var`s, so the memberwise init exposes them all. If the call above fails to compile because Swift requires every parameter, add an explicit `init(theme: FoilDeckTheme = .vayl)` that sets only the theme and leaves other tunables at their defaults:

```swift
init(theme: FoilDeckTheme = .vayl) {
    self.theme = theme
}
```

- [ ] **Step 2: Build + verify both previews**

Expected: exit 0. "Alt deck theme" preview: same material, magenta→cyan groove flash, "JEALOUSY" embossed. "Case vs card back": unchanged solo look (default theme path intact).

- [ ] **Step 3: Commit**

```bash
git add Vayl/Design/Components/Effects/FoilOpen/MetallicCaseView.swift
git commit -m "feat(foil): theme parameter + alt-colorway reuse proof preview"
```

---

### Task 7: Dead tunable cleanup + final device gate

**Files:**
- Modify: `Vayl/Design/Components/Effects/FoilOpen/MetallicCaseView.swift`

- [ ] **Step 1: Remove dead holo tunables**

Delete `holoScale`, `holoIntensity`, `holoSharpness`, `holoSpeed`, `holoShine`, `pattern` — they fed `holoFoilSurface`, which `MetallicCaseView` no longer calls. (`holoFoilSurface` itself stays in the .metal file untouched.) Keep `cornerSoftness` (still clips the silhouette) and all metal/box/float tunables.

- [ ] **Step 2: Grep for stragglers**

```bash
grep -n "holoScale\|holoIntensity\|holoSharpness\|holoSpeed\|holoShine\|pattern" \
  Vayl/Design/Components/Effects/FoilOpen/MetallicCaseView.swift
```
Expected: no matches (or only the foil-surface comment block — update it to describe the hex foil).

- [ ] **Step 3: Final CLEAN build, install, launch**

Run pinned `clean build`, install, launch (commands at top). Expected: exit 0, app launches.

- [ ] **Step 4: USER FEEL GATE (Build Protocol — blocking)**

The user judges on device/simulator, in the side-by-side preview AND in BuildDeckPhase if reachable:
- Material richness: relief reads tactile, glints sequential, flats near-void
- Kinship: hex pattern + emboss + ordered colorway match the card back
- 3D: lattice folds at the box edge; side faces plain dark metal
- Reduce Motion: enable in Settings → case static at ¾ view, relief still legible

Done ONLY when the user confirms the feel. Do not self-certify.

- [ ] **Step 5: Commit**

```bash
git add Vayl/Design/Components/Effects/FoilOpen/MetallicCaseView.swift
git commit -m "chore(foil): drop dead holo tunables after hex foil migration"
```

---

## Out of scope (per spec)

- Colorway legend (category → ramp mapping)
- Lattice-snapped crack propagation + hex shatter plates (follow-up phase; existing tap-crack keeps working on this surface)
- Director/BuildDeck flow wiring
