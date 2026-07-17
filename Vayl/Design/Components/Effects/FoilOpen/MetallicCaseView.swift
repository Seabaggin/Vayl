//
//  MetallicCaseView.swift
//  Vayl
//
//  FoilOpen module — Layer 1 (reusable, content-agnostic).
//
//  The sealed deck's 3D tuck-box: near-void anodized metal with the card back's
//  hex lattice DEBOSSED into the front face. A `Canvas` projects the box (front +
//  visible side + top faces, painter-sorted, per-face brightness = the 3D read);
//  the `hexFoilSurface` shader maps pixels into face-local UV over the projected
//  front quad and lights the groove flanks with one tilt-driven anisotropic band
//  in the deck's colorway (`FoilDeckTheme`). Light lives in the carved structure —
//  flats stay dark. The deck name is embossed low on the face in ClashDisplay,
//  same emboss recipe as the VaylCardBack wordmark.
//
//  Drawing the box in a Canvas (rather than nested rotation3DEffect, which SwiftUI
//  can't composite into a shared 3D scene) means the later crack/disintegrate pass
//  draws in the SAME projected face-space → cracks stay ISOLATED on the deck.
//
//  Everything tunable lives as a stored property below — tinker on device.
//

import SwiftUI
import UIKit
import Darwin

/// A crack in the sealed case, anchored in FACE-LOCAL UV (0…1 across the front
/// face) so it sticks to the case through float and tilt. The FoilOpen module's
/// own currency — consumers map their tear records into this.
struct CaseTear: Identifiable, Equatable {
    let id: UUID
    let faceUV: CGPoint
    let seed: UInt64
    /// When the strike landed — the crack propagates outward from this moment.
    let struck: Date
    /// Dominant orientation of the main fracture (degrees; 0 = horizontal).
    let angleDeg: Double
}

struct MetallicCaseView: View {

    // MARK: - Tunables

    var depthFrac:      CGFloat = 0.30   // box depth as a fraction of face width (full-deck heft; ~0.26 thinner)
    var tiltAmplitude:  Double  = 6      // float tilt amplitude (deg) — subtle
    var floatSpeed:     Double  = 0.7
    var perspective:    Double  = 600    // smaller = more convergence/foreshortening (photographic; 820 = flat/CAD)
    var saturation:     Double  = 0.95   // richer base (the holo iridescence adds the electric pop)
    var metalDarkness:  Double  = 0.52   // how dark the metal base sits (solid deep colour, not black)
    var ambient:        Double  = 0.28   // floor brightness on faces away from light (low = box reads in 3D)
    var frontLightAnchor: Double = 1.0   // hold the FRONT face's VALUE steady as the box tips flat→¾.
                                         // The hue is already anchored (caseGeometry.hueDeg) so the metal
                                         // never recolours on the rise — but its brightness wasn't, so the
                                         // hero face darkened 0.72→~0.41 and the eye read that as a hue
                                         // shift. 1 = fully steady · 0 = pure normal lighting (old behaviour).
    var hueOffset:      Double  = 90     // pick the single metal colour (deg) — ≈ deep purple
    var hueShift:       Double  = 1.4    // how much that one colour shifts as it tilts
    var boxScale:       CGFloat = 0.70   // box size as fraction of the fitting square

    // Foil surface — debossed hex lattice (hexFoilSurface). Light lives in the
    // carved structure: groove flanks ignite in the deck colorway as one
    // tilt-driven band sweeps the face. No noise, no time-driven animation.
    var cornerSoftness: Double  = 0.06   // rounding of the box SILHOUETTE — low = crisp/boxy deck case,
                                         // high = pillowy. ~0.04 very boxy · ~0.10 soft tuck-box (was 0.14, too round)
    var flatScale:      CGFloat = 1.0    // footprint while FLAT on the felt — fills the frame, matching the deck that melted
    var latticeColumns: Double = 13      // hex columns across the face width
    var grooveWidth:    Double = 0.10    // groove half-width in cell units
    var bandSharpness:  Double = 10      // band specular exponent
    var bandGain:       Double = 0.9     // band strength
    var glintGain:      Double = 0.5     // per-cell glint strength
    var bandTravel:     Double = 0.35    // band phase per degree of Y tilt
    var grainGain:      Double = 0.15    // anodized micro-grain amplitude on the flats (0 = flat mockup)
    var grainScale:     Double = 200     // grain frequency across the face width (higher = finer)
    var fresnelGain:    Double = 0.12    // #2 grazing-edge rim brightening (panel border catches the room)
    var envGain:        Double = 0.30    // #3 two-tone vertical environment the metal reflects (cool top → deep bottom)
    var edgeCatchGain:  Double = 0.55    // #1 edge catch-light intensity on the silhouette + front panel (0 = off)
    var edgeCatchTint:  Double = 0.25    // 0 = full cool blue-purple (colorway) · 1 = white. Hue of the catch-light.
    var frameOpacity:   Double = 0.6     // spectrum-border colorway opacity (was 0.27 — muted by the metal effects)
    var frameWidth:     Double = 1.3     // spectrum-border crisp line width
    var frameGlow:      Double = 0.7     // spectrum-border glow-pass strength (0 = crisp line only)
    var frameGlowRadius: Double = 4      // spectrum-border glow blur radius
    var theme: FoilDeckTheme   = .vayl

    // Arrival pose (ceremony spec Beat 3): nil = full float pose (default for
    // previews and any consumer that doesn't choreograph an arrival). Set to a
    // Date to drive the rise from that moment: FACE-ON flat on the felt (the
    // table's card grammar — matching the deck that melted) tipping back into
    // the floating ¾ box. Material stays asleep until latticeWakeStart.
    var riseStart:    Date?  = nil
    var riseDuration: Double = 1.4

    /// When the hex lattice + band WAKE (ceremony: "start the hex animation
    /// upon zoom-in"). `.distantPast` (default) = awake from the first frame;
    /// `.distantFuture` = asleep (plain anodized metal) until the caller
    /// assigns a real date, after which the material fades in over ~1.2s.
    var latticeWakeStart: Date = .distantPast

    /// Cracks on the sealed case (Beat 5 ceremony) — rendered in face space
    /// with colorway light-bleed that escalates per tear.
    var tears: [CaseTear] = []

    /// When the shatter begins (third crack): `.distantFuture` = sealed.
    /// Assigning a real date runs OVERLOAD then the UN-KNIT — the shell
    /// disassembles cell by cell along its own hex lattice, uncovering whatever
    /// the consumer mounted behind the view (formation-in-reverse, not confetti).
    var dissolveStart: Date = .distantFuture

    // Un-knit timeline + wave shape (module tunables — tinker on device).
    var overloadSpan: Double = 0.45   // held breath: cracks flare, nothing moves
    var unknitSpan:   Double = 1.25   // the wave front crossing the whole shell
    var unknitBand:   Double = 3.2    // wave front thickness (lattice units) — cells actively departing

    // — Living Case ceremony (Beat 5 rework) —

    /// Flower-peel exit mode: when true, `dissolveStart` runs the FLOWER PEEL
    /// (the lattice peels away from the centre outward like petals opening —
    /// the case CHOOSES to open) instead of the formation-in-reverse un-knit.
    /// The peel starts immediately at `dissolveStart` — the held breath is the
    /// consumer's beat (it decides when to assign the date), not an overload span.
    var peelMode: Bool = false
    var peelSpan: Double = AppAnimation.flowerPeelSpan   // the peel wave crossing the shell

    /// A card back tearing UP through the centre of the lattice (the deck inside
    /// straining against the shell). Each new date plays one eruption; the module
    /// derives rise / hold / reseal from its own frame clock. `.distantFuture` = none.
    var eruptStart: Date = .distantFuture
    /// Which strike this eruption belongs to (0, 1, 2) — escalates rise height,
    /// adds the second card on 1+, and suppresses the reseal on 2 (the case
    /// cannot close anymore).
    var eruptTapIndex: Int = 0
    // per-tap eruption spans (seconds) — rise, hold-at-peak, reseal
    var eruptRiseSpans: [Double] = [0.30, 0.36, 0.42]
    var eruptHoldSpans: [Double] = [0.22, 0.30, 0]
    var eruptSealSpans: [Double] = [0.40, 0.50, 0]

    /// Seam-stress target (0…1): lattice cells bow outward from centre, most at
    /// the middle, as the deck pushes from within. Ramps in with the eruption and
    /// unwinds with its reseal (held when the reseal is suppressed on tap 3).
    var seamStress: Double = 0

    /// Wake rings (0…3): each strike permanently lights another ring of lattice
    /// cells from the centre out (inner 0.28 · middle 0.62 · full). Spectrum
    /// colour is keyed per cell (radial + angular hue) so the lattice shimmers.
    var wakeRings: Int = 0

    /// Tap-to-crack: when set, taps landing on (or near) the FRONT FACE are
    /// converted to face-local UV at tap time — the inverse-bilinear of the
    /// projected quad — and forwarded. The consumer routes them to its store;
    /// the module never owns crack state.
    var onFaceTap: ((CGPoint) -> Void)? = nil

    /// The KNOCK FROM INSIDE (pre-strike anticipation): each new date plays a
    /// brief seam glimmer — light trying a few hex grooves from within. The
    /// consumer pairs it with a physical twitch + soft haptic.
    var knockStart: Date = .distantFuture
    var knockSeed:  UInt64 = 0

    /// CORE GLOW from within (Segment 2): the contained energy leaking through the
    /// hex groove network. 0 = sealed/dark; climbs as the deck strains toward the
    /// break. Lights the lattice SEAMS in the colorway — light from the case's own
    /// structure, not a backdrop. Generic intensity (module stays content-agnostic).
    var coreGlow: Double = 0

    /// FLAT static mode (grids / thumbnails): locks the rise pose to 0 (face-on,
    /// full footprint) and renders ONCE — no TimelineView — so many instances on
    /// screen stay cheap. The full animated 3D case is the default (flat == false).
    var flat: Bool = false

    init(theme: FoilDeckTheme = .vayl,
         flat: Bool = false,
         riseStart: Date? = nil,
         riseDuration: Double = 1.4,
         latticeWakeStart: Date = .distantPast,
         tears: [CaseTear] = [],
         dissolveStart: Date = .distantFuture,
         onFaceTap: ((CGPoint) -> Void)? = nil,
         knockStart: Date = .distantFuture,
         knockSeed: UInt64 = 0,
         coreGlow: Double = 0,
         peelMode: Bool = false,
         eruptStart: Date = .distantFuture,
         eruptTapIndex: Int = 0,
         seamStress: Double = 0,
         wakeRings: Int = 0) {
        self.theme = theme
        self.flat = flat
        self.riseStart = riseStart
        self.riseDuration = riseDuration
        self.latticeWakeStart = latticeWakeStart
        self.tears = tears
        self.dissolveStart = dissolveStart
        self.onFaceTap = onFaceTap
        self.knockStart = knockStart
        self.knockSeed = knockSeed
        self.coreGlow = coreGlow
        self.peelMode = peelMode
        self.eruptStart = eruptStart
        self.eruptTapIndex = eruptTapIndex
        self.seamStress = seamStress
        self.wakeRings = wakeRings
    }


    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Per-frame geometry

    /// Everything the Canvas closure AND the foil shader need each frame.
    /// Computed once per frame in `foilLayer` so the shader's front-quad
    /// uniforms always match the Canvas-drawn box exactly.
    private struct CaseGeometry {
        let rx: Double           // X tilt (radians)
        let ry: Double           // Y tilt (radians)
        let ryDeg: Double        // Y tilt (degrees) — drives the band phase
        let hueDeg: Double       // hue driver — anchored at the float's resting yaw
                                 // through flat + rise so the metal NEVER changes
                                 // colour as it stands; only the float drift shifts it
        let boxFit: Double       // face width after the pose-mixed scale — one source for draw + culling
        let proj: [CGPoint]      // 8 projected corners
        let frontQuad: [CGPoint] // front face TL, TR, BR, BL (proj[0...3])
    }

    /// 0 = lying flat on the felt · 1 = full float pose. Smoothstep-eased from
    /// `riseStart`; Reduce Motion (motion == false) snaps to the final pose.
    /// A caller that wants the case to MOUNT flat passes `.distantFuture` and
    /// later assigns the real lift moment.
    private func risePose(t: Double, motion: Bool) -> Double {
        if flat { return 0 }                  // grid/thumbnail: lock face-on flat
        guard let riseStart else { return 1 }
        guard motion else { return 1 }
        let elapsed = t - riseStart.timeIntervalSinceReferenceDate
        let p = min(1, max(0, elapsed / riseDuration))
        return p * p * (3 - 2 * p)
    }

    /// 0 = lattice asleep (plain anodized metal) · 1 = fully awake.
    /// Reduce Motion: snaps to the terminal state (awake unless still pending).
    private func latticeWake(t: Double, motion: Bool) -> Double {
        if latticeWakeStart == .distantFuture { return 0 }
        guard motion else { return 1 }
        let e = (t - latticeWakeStart.timeIntervalSinceReferenceDate) / 1.2
        let p = min(1, max(0, e))
        return p * p * (3 - 2 * p)
    }

    private func caseGeometry(size: CGSize, t: Double, motion: Bool, pose: Double,
                              calm: Double = 0) -> CaseGeometry {
        // float — biased to a clear 3/4 view (static angle shows the 3D), with only a
        // gentle drift on top so it reads as floating without "moving too much".
        // `pose` mixes from the flat-on-the-felt arrival to the floating ¾ view.
        // FLAT follows the table's card grammar: a card lying on the felt is a
        // FACE-ON flat graphic (rx = ry = 0, full footprint) — exactly how the
        // melted deck looked — never a real-3D edge-on sliver. The rise tips it
        // back into the ¾ view: the flat printed thing stands up into a 3D box.
        let osc = (motion ? 1.0 : 0.0) * pose * (1.0 - calm)
        let restYawDeg = 21.0                // the float's resting ¾ yaw
        let ryDeg = restYawDeg * pose
                  + osc * tiltAmplitude        * dsin(t * 0.42 * floatSpeed)
        let rxDeg = -16.0 * pose
                  + osc * tiltAmplitude * 0.4 * dcos(t * 0.31 * floatSpeed)
        let rx = rxDeg * .pi / 180, ry = ryDeg * .pi / 180
        // Hue rides the RESTING yaw, not the rise sweep — the flat case is the
        // same purple it will float at; standing up never reads as a recolour.
        let hueDeg = ryDeg + restYawDeg * (1.0 - pose)

        // box dimensions — flat fills the frame (the deck's footprint), the
        // floating pose settles to boxScale so the tilt has margin to swing in
        let scaleMix = Double(flatScale) + (Double(boxScale) - Double(flatScale)) * pose
        let fit = Double(min(size.width, size.height / 1.5)) * scaleMix
        let w = fit, h = fit * 1.5, d = fit * Double(depthFrac)
        let hx = w / 2, hy = h / 2, hz = d / 2
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        let corners3D: [SIMD3<Double>] = [
            SIMD3(-hx, -hy,  hz), SIMD3( hx, -hy,  hz), SIMD3( hx,  hy,  hz), SIMD3(-hx,  hy,  hz),
            SIMD3(-hx, -hy, -hz), SIMD3( hx, -hy, -hz), SIMD3( hx,  hy, -hz), SIMD3(-hx,  hy, -hz),
        ]
        let proj = corners3D.map { project(rotate($0, rx: rx, ry: ry), center: center) }
        return CaseGeometry(rx: rx, ry: ry, ryDeg: ryDeg, hueDeg: hueDeg, boxFit: fit,
                            proj: proj, frontQuad: Array(proj[0...3]))
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            Group {
                if reduceMotion || flat || AppAnimation.lowPower {
                    foilLayer(size: size, t: 0, motion: false)
                } else {
                    TimelineView(.animation) { tl in
                        foilLayer(size: size, t: tl.date.timeIntervalSinceReferenceDate, motion: true)
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture().onEnded { value in
                    handleTap(value.location, size: size)
                },
                including: onFaceTap == nil ? .none : .all
            )
        }
    }

    /// The shatter timeline, two acts from `dissolveStart`:
    ///   OVERLOAD (0…overloadSpan) — every crack flares white-hot, the light
    ///   inside maxes out, nothing moves: the held breath before the shell gives.
    ///   UN-KNIT (overloadSpan…+unknitSpan) — the shell disassembles cell by
    ///   cell along its hex lattice; `flood` 0→1 is the wave's progress.
    /// Reduce Motion snaps both to done (the shell is simply gone — the content
    /// behind stands revealed with no motion).
    private func dissolvePhases(t: Double, motion: Bool) -> (overload: Double, flood: Double) {
        if dissolveStart == .distantFuture { return (0, 0) }
        guard motion else { return (1, 1) }
        let e = t - dissolveStart.timeIntervalSinceReferenceDate
        if peelMode {
            // The peel starts immediately — the held breath is the consumer's beat.
            let f = min(1, max(0, e / peelSpan))
            return (1, f * f * (3 - 2 * f))
        }
        let overload = min(1, max(0, e / overloadSpan))
        let f = min(1, max(0, (e - overloadSpan) / unknitSpan))
        return (overload, f * f * (3 - 2 * f))
    }

    /// Convert a tap in view space to face-local UV via the inverse-bilinear of
    /// the CURRENT projected front quad (same geometry path the renderer uses),
    /// then forward it. Taps near the face edge are clamped in — during the
    /// ceremony "the case" is the target, not a precise quad.
    private func handleTap(_ point: CGPoint, size: CGSize) {
        guard let onFaceTap else { return }
        let motion = !reduceMotion
        let t = motion ? Date.now.timeIntervalSinceReferenceDate : 0
        let pose = risePose(t: t, motion: motion)
        let geo = caseGeometry(size: size, t: t, motion: motion, pose: pose)
        guard let uv = invBilinear(point, quad: geo.frontQuad),
              (-0.18...1.18).contains(uv.x), (-0.18...1.18).contains(uv.y) else { return }
        onFaceTap(CGPoint(x: min(max(uv.x, 0.04), 0.96),
                          y: min(max(uv.y, 0.04), 0.96)))
    }

    @ViewBuilder
    private func foilLayer(size: CGSize, t: Double, motion: Bool) -> some View {
        let pose = risePose(t: t, motion: motion)
        let wake = latticeWake(t: t, motion: motion)
        let (overload, flood) = dissolvePhases(t: t, motion: motion)
        // the world holds its breath: the float drift damps to stillness
        // through the overload — nothing sways while the cracks scream
        let geo = caseGeometry(size: size, t: t, motion: motion, pose: pose, calm: overload)
        ZStack {
        // BEHIND the shell: the glowing interior, revealed through erased wounds.
        // Carries the through-cracks (Segment 5) and drains as the un-knit
        // sweeps, handing the reveal to whatever the consumer mounted behind.
        if !tears.isEmpty {
            Canvas { ctx, _ in
                drawInterior(&ctx, geo: geo, t: t, motion: motion, flood: flood)
            }
        }
        Canvas { ctx, _ in
            drawCase(&ctx, size: size, geo: geo)
            drawKnock(&ctx, geo: geo, t: t, motion: motion)
            drawTears(&ctx, geo: geo, overload: overload, t: t, motion: motion)
            if peelMode { erasePeel(&ctx, geo: geo, flood: flood) }
            else        { eraseUnknit(&ctx, geo: geo, flood: flood) }
        }
            // Debossed hex foil — the band phase is driven by the FLOAT TILT, not
            // time, so the light only moves because the box moves (and Reduce
            // Motion freezes both together). No absolute timestamps reach the GPU.
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
                .float(Float(glintGain)),
                .float(Float(wake)),
                .float(Float(grainGain)),
                .float(Float(grainScale)),
                .float(Float(fresnelGain)),
                .float(Float(envGain)),
                .float(Float(coreGlow))
            ))
            // The shell is REMOVED cell by cell by eraseUnknit — no whole-object
            // fade. A final sliver fade cleans up the fold strips the lattice
            // wrap can't reach (wrapPoint dies past 90% of the depth).
            .opacity(flood > 0.92 ? max(0, (1 - flood) / 0.08) : 1)

            // Living Case overlay — seam stress + wake rings + card eruptions,
            // drawn in a plain Canvas (no foil shader) ABOVE the shell so the
            // spectrum strokes stay vivid. Stress/rings retire once the peel
            // begins consuming the lattice; the eruption fades over its start.
            if wakeRings > 0 || eruptStart != .distantFuture {
                Canvas { ctx, _ in
                    if flood < 0.001 {
                        drawLatticeStress(&ctx, geo: geo, t: t, motion: motion)
                    }
                    drawEruption(&ctx, geo: geo, t: t, motion: motion, flood: flood)
                }
            }

            // Exit pieces: the departing cells, drawn in a plain Canvas (no foil
            // shader). Un-knit = solid metal lifting clear at the wave front;
            // flower peel = three-pass spectrum petals (shadow, face, tear-edge).
            if flood > 0.001, flood < 0.999 {
                Canvas { ctx, _ in
                    if peelMode { drawFlowerPeel(&ctx, geo: geo, flood: flood) }
                    else        { drawUnknitPieces(&ctx, geo: geo, flood: flood) }
                }
            }
        }
    }

    // MARK: - Draw

    private func drawCase(_ ctx: inout GraphicsContext, size: CGSize, geo: CaseGeometry) {
        let rx = geo.rx, ry = geo.ry

        // ONE metal colour for the whole case (shifts slowly as it tilts — anodized).
        let caseHue = hueOffset + geo.hueDeg * hueShift
        // single light, mostly FRONTAL (high +z) so the front + top read bright and the side
        // panels go genuinely darker — that contrast is what makes the 3D box legible as it moves.
        let light = SIMD3(-0.20, -0.62, 0.72)

        // box dimensions — needed locally for face culling (rotated corner depth);
        // geo.boxFit carries the pose-mixed scale so culling matches the projection
        let fit = geo.boxFit
        let w = fit, h = fit * 1.5, d = fit * Double(depthFrac)
        let hx = w / 2, hy = h / 2, hz = d / 2

        // 8 corners (front face = +z)
        let corners3D: [SIMD3<Double>] = [
            SIMD3(-hx, -hy,  hz), SIMD3( hx, -hy,  hz), SIMD3( hx,  hy,  hz), SIMD3(-hx,  hy,  hz),
            SIMD3(-hx, -hy, -hz), SIMD3( hx, -hy, -hz), SIMD3( hx,  hy, -hz), SIMD3(-hx,  hy, -hz),
        ]

        let proj = geo.proj

        // faces: corner indices, outward normal (one colour for all — they differ by lighting)
        struct Face { let idx: [Int]; let n: SIMD3<Double>; let isFront: Bool }
        let faces: [Face] = [
            Face(idx: [0,1,2,3], n: SIMD3(0,0, 1), isFront: true),   // front
            Face(idx: [1,5,6,2], n: SIMD3( 1,0,0), isFront: false),  // right
            Face(idx: [4,0,3,7], n: SIMD3(-1,0,0), isFront: false),  // left
            Face(idx: [4,5,1,0], n: SIMD3(0,-1,0), isFront: false),  // top
            Face(idx: [3,2,6,7], n: SIMD3(0, 1,0), isFront: false),  // bottom
            Face(idx: [5,4,7,6], n: SIMD3(0,0,-1), isFront: false),  // back
        ]

        // visible faces (rotated normal toward camera), painter-sorted back→front
        let visible = faces
            .map { face -> (f: Face, rn: SIMD3<Double>, cz: Double) in
                let rn = rotate(face.n, rx: rx, ry: ry)
                let cz = face.idx.reduce(0.0) { acc, i in acc + rotate(corners3D[i], rx: rx, ry: ry).z } / 4
                return (face, rn, cz)
            }
            .filter { $0.rn.z > 0.001 }
            .sorted { $0.cz < $1.cz }

        // soft tuck-box silhouette: gently round the convex hull of the projected corners and
        // clip to it → soft outer corners with NO gaps; the panel folds inside stay crisp.
        ctx.clip(to: roundedFacePath(convexHull(proj), softness: cornerSoftness))

        for v in visible {
            let pts = v.f.idx.map { proj[$0] }
            var face = Path()
            face.move(to: pts[0])
            for p in pts.dropFirst() { face.addLine(to: p) }
            face.closeSubpath()

            // per-face brightness from a single light → top bright, front mid, side dark = 3D
            var brightness = max(ambient, (v.rn * light).sum())
            // Anchor the FRONT face's value across the rise (the twin of the hue
            // anchor): without this the hero face darkens as its normal tips off
            // the frontal light and reads as a recolour. Side/top faces stay
            // normal-lit — they carry the 3D.
            if v.f.isFront {
                let faceOn = max(ambient, light.z)   // front normal (0,0,1) · light
                brightness += (faceOn - brightness) * frontLightAnchor
            }
            let shading = metalShading(caseHue: caseHue, brightness: brightness,
                                       a: pts[0], c: pts[2])
            ctx.fill(face, with: shading)
        }

        // Edge catch-light (#1): a bright, top-lit rim on the silhouette and the
        // front panel edge — the chamfer catching the overhead key. The single
        // strongest "solid metal object" cue vs a flat fill. Brightest up top
        // (the light sits high), fading down. Additive (plusLighter) so it reads
        // as a highlight, not paint.
        if edgeCatchGain > 0 {
            let ys = proj.map(\.y)
            let top = ys.min() ?? 0, bot = ys.max() ?? 0
            let cx = size.width / 2
            // Catch-light hue: a cool blue-purple from the colorway's cool end, not
            // pure white — white reads as plastic / pasted-on against the saturated
            // metal. This reflects the cool "sky" of the two-tone, so the edge
            // belongs to the scene. edgeCatchTint lifts it toward white for pop.
            let coolStop = mix(Self.components(theme.colorway.c0),
                               Self.components(theme.colorway.c1), 0.5)
            let rimColor = color(mix(coolStop, SIMD3(1, 1, 1), edgeCatchTint))
            let rimShade = GraphicsContext.Shading.linearGradient(
                Gradient(stops: [
                    .init(color: rimColor.opacity(edgeCatchGain), location: 0.0),
                    .init(color: .clear,                          location: 1.0),
                ]),
                startPoint: CGPoint(x: cx, y: top),
                endPoint:   CGPoint(x: cx, y: top + (bot - top) * 0.5))
            var rim = ctx
            rim.blendMode = .plusLighter
            rim.stroke(roundedFacePath(convexHull(proj), softness: cornerSoftness),
                       with: rimShade, lineWidth: 1.6)
            var frontPath = Path()
            let fq = geo.frontQuad
            frontPath.move(to: fq[0])
            for p in fq.dropFirst() { frontPath.addLine(to: p) }
            frontPath.closeSubpath()
            rim.stroke(frontPath, with: rimShade, lineWidth: 1.1)
        }

        // embossed brand layer (deck name + hairline frame) on the front face
        if let front = visible.first(where: { $0.f.isFront }) {
            drawBrand(&ctx, quad: front.f.idx.map { proj[$0] })
        }
    }

    /// Convex hull (monotone chain) of the projected box corners → the outer silhouette.
    private func convexHull(_ input: [CGPoint]) -> [CGPoint] {
        let pts = input.sorted { $0.x != $1.x ? $0.x < $1.x : $0.y < $1.y }
        guard pts.count >= 3 else { return pts }
        func cross(_ o: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
            (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
        }
        var lower: [CGPoint] = []
        for p in pts {
            while lower.count >= 2, cross(lower[lower.count - 2], lower[lower.count - 1], p) <= 0 { lower.removeLast() }
            lower.append(p)
        }
        var upper: [CGPoint] = []
        for p in pts.reversed() {
            while upper.count >= 2, cross(upper[upper.count - 2], upper[upper.count - 1], p) <= 0 { upper.removeLast() }
            upper.append(p)
        }
        lower.removeLast(); upper.removeLast()
        return lower + upper
    }

    // MARK: - Metallic shading

    /// Flat anodized faces — per-face brightness carries the 3D, the hex foil
    /// shader owns ALL the light play (band, glints, grooves). The old white
    /// specular streak predated the lattice and is gone for good.
    private func metalShading(caseHue: Double, brightness b: Double,
                              a: CGPoint, c: CGPoint) -> GraphicsContext.Shading {
        let core  = Self.metalHue(caseHue / 360)               // the single metal hue
        let grey  = (core.x + core.y + core.z) / 3
        let desat = mix(core, SIMD3(grey, grey, grey), 1 - saturation)
        let metal = mix(desat, Self.anchorDark, metalDarkness)
        let lit   = metal * b                                  // face brightness = the 3D read
        let lo    = lit * 0.88                                  // gentle edge falloff (no dark corners)
        return .linearGradient(
            Gradient(stops: [
                .init(color: color(lo),  location: 0.0),
                .init(color: color(lit), location: 0.5),
                .init(color: color(lo),  location: 1.0),
            ]),
            startPoint: a, endPoint: c)
    }

    // MARK: - Brand layer (embossed deck name + hairline frame)

    private func drawBrand(_ ctx: inout GraphicsContext, quad: [CGPoint]) {
        guard quad.count == 4 else { return }
        let edgeW = hypot(quad[1].x - quad[0].x, quad[1].y - quad[0].y)
        guard edgeW > 1 else { return }

        // — hairline inset frame, colorway gradient, PERSPECTIVE-CORRECT —
        // Built in unit-face space, then every point mapped through the TRUE
        // projected quad (bilerp) instead of an affine parallelogram. The affine
        // map ignored the BR corner, so the bottom edge SAGGED under the tilt.
        let inset = 9.0 / edgeW                   // matches the card back's 9pt inset
        let x0 = inset, x1 = 1 - inset
        let y0 = inset * (2.0 / 3.0), y1 = 1 - inset * (2.0 / 3.0)
        let rx = 0.03, ry = 0.02                  // corner radius (u, v) — small, like the card back
        var unit: [CGPoint] = []
        let seg = 5
        func corner(_ cx: Double, _ cy: Double, _ from: Double, _ to: Double) {
            for k in 0...seg {
                let a = from + (to - from) * Double(k) / Double(seg)
                unit.append(CGPoint(x: cx + rx * dcos(a), y: cy + ry * dsin(a)))
            }
        }
        corner(x0 + rx, y0 + ry, .pi,       1.5 * .pi)   // TL
        corner(x1 - rx, y0 + ry, 1.5 * .pi, 2.0 * .pi)   // TR
        corner(x1 - rx, y1 - ry, 0.0,       0.5 * .pi)   // BR
        corner(x0 + rx, y1 - ry, 0.5 * .pi, .pi)         // BL
        var frame = Path()
        let mapped = unit.map { bilerp(quad, Double($0.x), Double($0.y)) }
        frame.move(to: mapped[0])
        for p in mapped.dropFirst() { frame.addLine(to: p) }
        frame.closeSubpath()
        // Two-pass spectrum border (glow + crisp), OB card-face grammar — the
        // single thin stroke got muted once the grain / env / fresnel enriched the
        // metal. The blurred additive glow lifts the colorway back off the surface.
        let frameShade = GraphicsContext.Shading.linearGradient(
            Gradient(stops: [
                .init(color: theme.colorway.c0.opacity(frameOpacity), location: 0.0),
                .init(color: theme.colorway.c1.opacity(frameOpacity), location: 0.5),
                .init(color: theme.colorway.c2.opacity(frameOpacity), location: 1.0),
            ]),
            startPoint: bilerp(quad, x0, 0.5),
            endPoint:   bilerp(quad, x1, 0.5))
        if frameGlow > 0 {
            var glow = ctx
            glow.blendMode = .plusLighter
            glow.opacity = frameGlow
            glow.addFilter(.blur(radius: frameGlowRadius))
            glow.stroke(frame, with: frameShade, lineWidth: frameWidth * 2.2)
        }
        ctx.stroke(frame, with: frameShade, lineWidth: frameWidth)

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

    // MARK: - Crack ceremony (tears + bloom-flood)

    /// The knock from inside: a 0.7s seam glimmer — light tries a few hex
    /// grooves from within, somewhere mid-face. Plays once per `knockStart`
    /// date; deterministic per `knockSeed`. Reduce Motion: none.
    private func drawKnock(_ ctx: inout GraphicsContext, geo: CaseGeometry,
                           t: Double, motion: Bool) {
        guard motion, knockStart != .distantFuture else { return }
        let age = t - knockStart.timeIntervalSinceReferenceDate
        guard age >= 0, age < 0.7 else { return }
        let bell = dsin(min(age / 0.7, 1) * .pi)

        var rng = SplitMix64(seed: knockSeed)
        let u = Double.random(in: 0.30...0.70, using: &rng)
        let v = Double.random(in: 0.25...0.75, using: &rng)
        var current = nearestHexVertex(SIMD2(u * latticeColumns, v * 1.5 * latticeColumns))
        var previous = current
        var path = Path()
        if let start = wrapPoint(current, geo: geo) { path.move(to: start) }
        for _ in 0..<3 {
            let options = hexNeighbors(of: current).filter { dist2($0, previous) > 0.01 }
            guard let next = options.shuffled(using: &rng).first,
                  let pt = wrapPoint(next, geo: geo) else { break }
            path.addLine(to: pt)
            previous = current
            current = next
        }

        let spectrum = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [theme.colorway.c0, theme.colorway.c1, theme.colorway.c2]),
            startPoint: geo.frontQuad[0], endPoint: geo.frontQuad[2])
        var glow = ctx
        glow.opacity = 0.40 * bell
        glow.addFilter(.blur(radius: 5))
        glow.stroke(path, with: spectrum, lineWidth: 3.5)
        var crisp = ctx
        crisp.opacity = 0.5 * bell
        crisp.stroke(path, with: spectrum, lineWidth: 1.0)
    }

    /// Cracks rendered in face space: each tear's branch polylines live in UV,
    /// mapped through the CURRENT projected quad every frame — the crack rides
    /// the case through float and tilt. The strike is an EVENT, not a decal:
    /// branches PROPAGATE outward from the finger (~0.22s), flash white-hot on
    /// impact with an expanding shock ring, and taper from a wide wound at the
    /// strike to hairline tips. Light-bleed escalates per tear and floods
    /// during the shatter.
    /// One strike's authored fracture set — the SAME geometry consumed by the
    /// shell pass (drawTears) and the interior card pass (drawInterior), so the
    /// wound reads as going all the way through (Segment 5). Fully deterministic
    /// (seeded), so both passes computing it independently stay aligned.
    private struct TearNetwork {
        let k: Int
        let tear: CaseTear
        let lines: [[CGPoint]]
        let ripAngle: Double
    }

    /// Build every tear's crack network for the current frame geometry.
    /// CHOREO — the cracks + rip aim toward the CENTRE: corner strikes spray a
    /// DIRECTED fan toward the middle (the composition converges there); the
    /// central kill radiates full. This is what makes the 1-2-3 read as one
    /// composed failure instead of three scattered hits. The central kill also
    /// reaches cracks to BOTH previous strikes (connecting the whole network
    /// before the shatter); corner strikes don't link — their directed fan
    /// already converges on the centre.
    private func tearNetworks(geo: CaseGeometry) -> [TearNetwork] {
        var occupied = Set<Int64>()
        var nets: [TearNetwork] = []
        for (k, tear) in tears.enumerated() {
            let toC = SIMD2(0.5 - Double(tear.faceUV.x), 0.5 - Double(tear.faceUV.y))
            let centered = (toC.x * toC.x + toC.y * toC.y).squareRoot() < 0.12
            let anchorAngle = centered ? tear.angleDeg * .pi / 180 : atan2(toC.y, toC.x)
            let spread = centered ? 2 * Double.pi : 1.8   // tighter = cracks aim AT centre, not the borders
            let ripAngle = centered ? tear.angleDeg : anchorAngle * 180 / .pi
            let links: [CGPoint] = centered ? Array(tears.prefix(k)).map { $0.faceUV } : []
            // count + reach AUTHORED by severity (the designed 1-2-3 escalation)
            let cracks = radiatingCracks(tear, geo: geo, count: 4 + k,
                                         reach: 18 + 5 * k, links: links,
                                         anchorAngle: anchorAngle, spread: spread,
                                         occupied: &occupied)
            nets.append(TearNetwork(k: k, tear: tear, lines: cracks, ripAngle: ripAngle))
        }
        return nets
    }

    private func drawTears(_ ctx: inout GraphicsContext, geo: CaseGeometry,
                           overload: Double, t: Double, motion: Bool) {
        guard !tears.isEmpty else { return }
        let quad = geo.frontQuad
        let spectrum = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [theme.colorway.c0, theme.colorway.c1, theme.colorway.c2]),
            startPoint: quad[0], endPoint: quad[2])
        // sizing is relative to the FACE WIDTH so the damage uses the case's real
        // estate (Opal-scale), not a few fixed pixels.
        let faceW = hypot(quad[1].x - quad[0].x, quad[1].y - quad[0].y)

        for net in tearNetworks(geo: geo) {
            let k = net.k, tear = net.tear
            // DESIGNED 1-2-3 sequence: severity is AUTHORED by strike index, not
            // random — each strike is a heavier impact than the last.
            let sev   = k + 1                                  // 1, 2, 3
            let age   = motion ? max(0, t - tear.struck.timeIntervalSinceReferenceDate) : 10
            let grow  = min(1.0, age / 0.30)
            let growE = 1 - (1 - grow) * (1 - grow)
            let flash = max(0.0, 1.0 - age / 0.28)
            let phase = Double(tear.seed % 628) / 100.0
            let pulse = motion ? 0.5 + 0.5 * dsin(t * (2 * .pi / 1.6) + phase) : 1.0
            let bleed = min(1.7, (0.5 + 0.22 * Double(k)) * (0.7 + 0.5 * pulse) + 1.0 * overload)
            let widen = 1.0 + 0.25 * Double(k) + 0.5 * overload
            let ripAngle = net.ripAngle

            for line in net.lines {
                drawCrackLine(&ctx, line, growE: growE, widen: widen, bleed: bleed,
                              flash: flash, overload: overload, t: t, motion: motion,
                              spectrum: spectrum)
            }

            // THE WOUND — a big tear at the composed strike point, its rip pointing
            // toward centre; sized off the face (Opal-scale), bigger each strike.
            let woundR = faceW * (0.135 + 0.04 * Double(sev)) * growE * (0.9 + 0.25 * coreGlow)
            drawWound(&ctx, at: tear.faceUV, geo: geo, radius: woundR, angleDeg: ripAngle,
                      seed: tear.seed, bleed: bleed, flash: flash, overload: overload,
                      spectrum: spectrum)

            // shock ring — expands from the impact, dies as the crack lands
            if flash > 0, motion {
                let origin = bilerp(quad, Double(tear.faceUV.x), Double(tear.faceUV.y))
                let ringP = min(1.0, age / 0.35)
                let radius = 5 + 26 * (1 - (1 - ringP) * (1 - ringP))
                var ring = ctx
                ring.opacity = (1 - ringP) * 0.5
                ring.stroke(Path(ellipseIn: CGRect(x: origin.x - radius, y: origin.y - radius,
                                                   width: radius * 2, height: radius * 2)),
                            with: spectrum, lineWidth: 1.5)
            }
        }
    }

    /// One radiating crack line — reveal-animated from the impact, soft glow + a
    /// crisp tapered core, then LIVELY accents (the released energy alive in the
    /// fracture): flickering glints crackling along it + a bright pulse coursing out.
    private func drawCrackLine(_ ctx: inout GraphicsContext, _ branch: [CGPoint],
                               growE: Double, widen: Double, bleed: Double,
                               flash: Double, overload: Double, t: Double, motion: Bool,
                               spectrum: GraphicsContext.Shading) {
        let n = branch.count - 1
        guard n > 0 else { return }
        let reveal = growE * Double(n)
        var revealed = Path()
        revealed.move(to: branch[0])
        var revealedPts: [CGPoint] = [branch[0]]
        var segments: [(Path, Double)] = []
        for i in 0..<n {
            let segP = min(max(reveal - Double(i), 0), 1)
            guard segP > 0 else { break }
            let a = branch[i], b = branch[i + 1]
            let end = segP >= 1 ? b
                : CGPoint(x: a.x + (b.x - a.x) * segP, y: a.y + (b.y - a.y) * segP)
            revealed.addLine(to: end)
            revealedPts.append(end)
            var seg = Path(); seg.move(to: a); seg.addLine(to: end)
            let width = 2.2 - 1.7 * Double(i) / Double(max(n - 1, 1))
            segments.append((seg, width))
        }
        var glow = ctx
        glow.opacity = min(1.0, 0.45 * bleed)
        glow.addFilter(.blur(radius: 4.0))
        glow.stroke(revealed, with: spectrum, lineWidth: 4.0 * widen)
        for (seg, width) in segments {
            var crisp = ctx
            crisp.opacity = min(1.0, 0.6 + 0.4 * bleed)
            crisp.stroke(seg, with: spectrum, lineWidth: width * widen)
            var core = ctx
            core.opacity = min(1.0, 0.30 * bleed + 0.6 * flash + overload)
            core.stroke(seg, with: .color(.white), lineWidth: width * widen * 0.45)
        }

        // LIVELY accents — per-crack phase so they don't pulse in lockstep
        guard motion, revealedPts.count > 1 else { return }
        let ph = Double(branch[0].x) * 0.013 + Double(branch[0].y) * 0.017
        // flickering glints crackling along the crack's length (electric/alive)
        for (j, vp) in revealedPts.enumerated() {
            let tw = dsin(t * 6 + ph + Double(j) * 1.9)
            guard tw > 0.74 else { continue }
            var gl = ctx
            gl.opacity = (tw - 0.74) / 0.26 * 0.45
            gl.addFilter(.blur(radius: 1.2))
            gl.fill(Path(ellipseIn: CGRect(x: vp.x - 1.4, y: vp.y - 1.4, width: 2.8, height: 2.8)),
                    with: .color(.white))
        }
        // a bright energy pulse coursing OUTWARD along the crack, fading at the tip
        let pf = CGFloat(((t * 0.8 + ph).truncatingRemainder(dividingBy: 1.0) + 1)
                            .truncatingRemainder(dividingBy: 1.0))
        let pp = pointAlong(revealedPts, pf)
        var pulse = ctx
        pulse.opacity = 0.5 * (1 - Double(pf)) * min(1, 0.4 + 0.6 * bleed)
        pulse.addFilter(.blur(radius: 3))
        pulse.fill(Path(ellipseIn: CGRect(x: pp.x - 3, y: pp.y - 3, width: 6, height: 6)),
                   with: .color(.white))
    }

    /// Point at arc-length fraction `f` (0…1) along a polyline.
    private func pointAlong(_ pts: [CGPoint], _ f: CGFloat) -> CGPoint {
        guard pts.count > 1 else { return pts.first ?? .zero }
        var lens: [CGFloat] = [], total: CGFloat = 0
        for i in 0..<pts.count - 1 {
            let d = hypot(pts[i + 1].x - pts[i].x, pts[i + 1].y - pts[i].y)
            lens.append(d); total += d
        }
        guard total > 0 else { return pts[0] }
        var target = max(0, min(1, f)) * total
        for i in 0..<lens.count {
            if target <= lens[i] {
                let u = lens[i] > 0 ? target / lens[i] : 0
                return CGPoint(x: pts[i].x + (pts[i + 1].x - pts[i].x) * u,
                               y: pts[i].y + (pts[i + 1].y - pts[i].y) * u)
            }
            target -= lens[i]
        }
        return pts[pts.count - 1]
    }

    /// The WOUND at an impact — an elongated jagged RIP centred on the strike and
    /// oriented along the crack axis (a torn slit, not a round splat). Dark gap
    /// (depth) + glowing card-light inset behind a shadow rim + bright jagged lip.
    /// Screen-space (small enough that tilt foreshortening doesn't matter).
    private func drawWound(_ ctx: inout GraphicsContext, at uv: CGPoint, geo: CaseGeometry,
                           radius: Double, angleDeg: Double, seed: UInt64,
                           bleed: Double, flash: Double, overload: Double,
                           spectrum: GraphicsContext.Shading) {
        guard radius > 0.6 else { return }
        let center = bilerp(geo.frontQuad, Double(uv.x), Double(uv.y))
        let ang = angleDeg * .pi / 180, ca = dcos(ang), sa = dsin(ang)
        let L = radius * 2.7, W = radius * 0.95          // elongated along the crack axis
        var rng = SplitMix64(seed: seed ^ 0x770F)
        let steps = 7
        let topJit = (0...steps).map { _ in 0.65 + 0.6 * Double.random(in: 0...1, using: &rng) }
        let botJit = (0...steps).map { _ in 0.65 + 0.6 * Double.random(in: 0...1, using: &rng) }
        // a jagged lens (pointed ends, bulged middle) rotated to the crack axis — a rip
        func lens(_ scale: Double) -> Path {
            var p = Path()
            let hl = L * 0.5 * scale, hw = W * 0.5 * scale
            func map(_ x: Double, _ y: Double) -> CGPoint {
                CGPoint(x: center.x + x * ca - y * sa, y: center.y + x * sa + y * ca)
            }
            for i in 0...steps {                          // top edge: left → right, bulging up
                let s = Double(i) / Double(steps)
                let pt = map(-hl + 2 * hl * s, -hw * dsin(.pi * s) * topJit[i])
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            for i in 0...steps {                          // bottom edge: right → left, bulging down
                let s = Double(i) / Double(steps)
                p.addLine(to: map(hl - 2 * hl * s, hw * dsin(.pi * s) * botJit[steps - i]))
            }
            p.closeSubpath(); return p
        }
        let outer = lens(1.0)

        // 1. PUNCH THROUGH — erase the shell so the glowing interior (drawn BEHIND
        //    in the ZStack) shows as true NEGATIVE SPACE. The hex shader passes
        //    transparent pixels straight through (`if a < 0.01 return currentColor`),
        //    so no grooves fill the hole.
        var cut = ctx
        cut.blendMode = .destinationOut
        cut.fill(outer, with: .color(.black))

        // 2. THICKNESS — a dark inner WALL just inside the broken edge (the case's
        //    depth in shadow), so the hole reads as an extrusion, not a flat cut.
        var wall = ctx
        wall.opacity = min(1.0, 0.55 + 0.2 * flash)
        wall.stroke(lens(0.82), with: .color(AppColors.void), lineWidth: max(2, radius * 0.2))

        // 3. DIRECTIONAL RIM — bright broken metal ONLY on the light-facing edge,
        //    fading to nothing on the shadow side (never a 360° neon outline).
        let lightTL = CGPoint(x: center.x - L, y: center.y - L)
        let lightBR = CGPoint(x: center.x + L, y: center.y + L)
        var rim = ctx
        rim.opacity = min(1.0, 0.8 + 0.4 * flash)
        rim.stroke(outer, with: .linearGradient(
            Gradient(stops: [
                .init(color: .white,                         location: 0.0),
                .init(color: theme.colorway.c1.opacity(0.6), location: 0.4),
                .init(color: .clear,                         location: 0.62),
            ]),
            startPoint: lightTL, endPoint: lightBR), lineWidth: 2.0)
    }

    /// smoothstep — 0 below `a`, 1 above `b`, eased between.
    private func sstep(_ x: Double, _ a: Double, _ b: Double) -> Double {
        let u = min(1, max(0, (x - a) / (b - a)))
        return u * u * (3 - 2 * u)
    }

    /// The glowing INTERIOR revealed through the erased wounds — a generic lit panel
    /// (spectrum, brightest at centre) clipped to the case silhouette so it only
    /// shows through real negative space. Lives BEHIND the shell Canvas in the
    /// ZStack. Kept generic so the module stays content-agnostic.
    ///
    /// Segment 5 — the wound goes ALL THE WAY THROUGH: the same fracture network
    /// as the shell (identical seeds → identical geometry via tearNetworks) is
    /// rendered on this card body as a dark fissure with a hot edge, so a wound
    /// shows the crack continuing beneath the shell. TRANSIENT by design: the
    /// fissures cool and seal as the energy drains through the un-knit — the
    /// actual reveal content the consumer mounts behind is never touched.
    ///
    /// During the un-knit the whole layer DRAINS (the escaping essence), handing
    /// the uncovered holes to the consumer's content behind the module.
    private func drawInterior(_ ctx: inout GraphicsContext, geo: CaseGeometry,
                              t: Double, motion: Bool, flood: Double) {
        let drain = sstep(flood, 0.10, 0.75)
        guard drain < 0.999 else { return }
        let hull = roundedFacePath(convexHull(geo.proj), softness: cornerSoftness)
        let q = geo.frontQuad
        let center = CGPoint(x: (q[0].x + q[2].x) / 2, y: (q[0].y + q[2].y) / 2)
        let r = hypot(q[2].x - q[0].x, q[2].y - q[0].y) * 0.62
        var g = ctx
        g.clip(to: hull)
        g.opacity = 1 - drain
        g.fill(hull, with: .radialGradient(
            Gradient(stops: [
                .init(color: .white.opacity(0.92),            location: 0.0),
                .init(color: theme.colorway.c1.opacity(0.85), location: 0.4),
                .init(color: theme.colorway.c2.opacity(0.7),  location: 0.8),
                .init(color: theme.colorway.c0.opacity(0.6),  location: 1.0),
            ]),
            center: center, startRadius: 0, endRadius: r))

        // the through-cracks — grow in sync with the shell's (same 0.30s reveal),
        // cool + seal as the un-knit settles (a slightly earlier fade than the
        // glow, so the damage heals before the light finishes leaving)
        let cool = 1 - sstep(flood, 0.20, 0.70)
        guard cool > 0.01 else { return }
        for net in tearNetworks(geo: geo) {
            let age   = motion ? max(0, t - net.tear.struck.timeIntervalSinceReferenceDate) : 10
            let grow  = min(1.0, age / 0.30)
            let growE = 1 - (1 - grow) * (1 - grow)
            guard growE > 0.01 else { continue }
            for line in net.lines {
                let path = revealedPath(line, growE: growE)
                // hot edge first (the card's energy pressed into the fissure)…
                var hot = g
                hot.blendMode = .plusLighter
                hot.opacity = 0.35 * growE * cool
                hot.addFilter(.blur(radius: 2.0))
                hot.stroke(path, with: .color(theme.colorway.c2), lineWidth: 3.2)
                // …then the dark split itself — damage on a glowing body
                var fissure = g
                fissure.opacity = 0.6 * growE * cool
                fissure.stroke(path, with: .color(AppColors.void), lineWidth: 1.8)
            }
        }
    }

    /// The revealed prefix of a crack polyline at growth `growE` (0…1) — the
    /// propagation animation as a single Path. Shared by the shell's crack pass
    /// (per-segment styling lives in drawCrackLine) and the interior card pass,
    /// so the two stay frame-locked.
    private func revealedPath(_ branch: [CGPoint], growE: Double) -> Path {
        var path = Path()
        let n = branch.count - 1
        guard n > 0 else { return path }
        let reveal = growE * Double(n)
        path.move(to: branch[0])
        for i in 0..<n {
            let segP = min(max(reveal - Double(i), 0), 1)
            guard segP > 0 else { break }
            let a = branch[i], b = branch[i + 1]
            path.addLine(to: segP >= 1 ? b
                : CGPoint(x: a.x + (b.x - a.x) * segP, y: a.y + (b.y - a.y) * segP))
        }
        return path
    }

    // MARK: - Un-knit (Segment 3): the shell disassembles along its own lattice

    /// One honeycomb cell of the shell during the un-knit wave.
    ///   lead < 0  — still knitted, but the wave front is near (seam pre-glow)
    ///   0…1       — departing: erased from the shell, drawn as a freed piece
    ///   ≥ 1       — gone
    private struct UnknitCell {
        let center: SIMD2<Double>   // lattice space
        let lead: Double
        let jitter: Double          // per-cell 0…1 (seeded) — organic front + flight variance
        var q: Double { min(1, max(0, lead)) }
    }

    /// Enumerate the honeycomb cell centers covering the face + fold overhang
    /// (the same two offset grids as hexFoilSurface / nearestHexVertex) and
    /// compute each cell's departure under the wave. The wave radiates from the
    /// KILL strike (dead centre in the Pincer); a small seeded jitter keeps the
    /// front organic without breaking the formation-in-reverse read.
    /// Only cells the front has reached (or is about to) are returned.
    private func unknitCells(flood: Double) -> [UnknitCell] {
        guard flood > 0.001 else { return [] }
        let r3 = 1.7320508
        let cols = latticeColumns
        let over = Double(depthFrac) * cols               // fold overhang, lattice units
        let xLo = -over, xHi = cols + over
        let yLo = -over, yHi = 1.5 * cols + over
        // wave origin = the kill strike
        let o = tears.last.map {
            SIMD2(Double($0.faceUV.x) * cols, Double($0.faceUV.y) * 1.5 * cols)
        } ?? SIMD2(0.5 * cols, 0.75 * cols)
        // the wave must reach the farthest corner
        let maxD = [SIMD2(xLo, yLo), SIMD2(xHi, yLo), SIMD2(xLo, yHi), SIMD2(xHi, yHi)]
            .map { c -> Double in
                let v = c - o
                return (v.x * v.x + v.y * v.y).squareRoot()
            }
            .max() ?? 1
        let waveD = flood * (maxD + unknitBand)
        let waveSeed = tears.last?.seed ?? 0x0BAD_CE11

        var cells: [UnknitCell] = []
        func visit(_ c: SIMD2<Double>) {
            let v = c - o
            let d = (v.x * v.x + v.y * v.y).squareRoot()
            var rng = SplitMix64(seed: UInt64(bitPattern: vertexKey(c)) ^ waveSeed)
            let jitter = Double.random(in: 0...1, using: &rng)
            let lead = (waveD - (d + (jitter - 0.5) * 1.6)) / unknitBand
            guard lead > -0.5 else { return }
            cells.append(UnknitCell(center: c, lead: lead, jitter: jitter))
        }
        let jLo = Int((yLo / r3).rounded(.down)), jHi = Int((yHi / r3).rounded(.up))
        let iLo = Int(xLo.rounded(.down)), iHi = Int(xHi.rounded(.up))
        for j in jLo...jHi {
            let rowY = Double(j) * r3
            for i in iLo...iHi {
                visit(SIMD2(Double(i), rowY))                       // grid A
                visit(SIMD2(Double(i) + 0.5, rowY + r3 * 0.5))      // grid B
            }
        }
        return cells
    }

    /// A cell's hexagon in screen space, corners scaled about the center
    /// (`scale` > 1 swallows the groove seam). Nil if any corner falls past a
    /// fold the camera can't see — that cell has no drawable piece.
    private func hexCellPath(center: SIMD2<Double>, geo: CaseGeometry,
                             scale: Double) -> Path? {
        let R = Self.hexR
        let offs: [SIMD2<Double>] = [
            SIMD2(0,  R), SIMD2(0.5,  R / 2), SIMD2(0.5, -R / 2),
            SIMD2(0, -R), SIMD2(-0.5, -R / 2), SIMD2(-0.5, R / 2),
        ]
        var pts: [CGPoint] = []
        for off in offs {
            guard let p = wrapPoint(center + off * scale, geo: geo) else { return nil }
            pts.append(p)
        }
        var path = Path()
        path.move(to: pts[0])
        for p in pts.dropFirst() { path.addLine(to: p) }
        path.closeSubpath()
        return path
    }

    /// Erase departed cells from the shell — the un-knit's NEGATIVE SPACE. Runs
    /// inside the shell Canvas (destinationOut) so the hex shader passes the
    /// holes straight through: whatever the consumer mounted behind the module
    /// is genuinely UNCOVERED, never cross-faded to. The 1.18 inflation swallows
    /// the groove seams — the lattice's joints give way with the cell.
    private func eraseUnknit(_ ctx: inout GraphicsContext, geo: CaseGeometry, flood: Double) {
        guard flood > 0.001 else { return }
        var cut = ctx
        cut.blendMode = .destinationOut
        for cell in unknitCells(flood: flood) where cell.lead > 0 {
            guard let hex = hexCellPath(center: cell.center, geo: geo, scale: 1.18) else { continue }
            cut.fill(hex, with: .color(.black))
        }
    }

    /// The wave front, drawn OVER the shell in a plain (un-shadered) Canvas:
    ///   · seam pre-glow — cells the front is about to take flare along their
    ///     hex outline (the lattice visibly giving way ahead of the wave)
    ///   · freed pieces — each departing cell lifts a short way OUTWARD from the
    ///     wave origin, tips slightly, cools and fades. Formation-in-reverse:
    ///     ordered, light, no gravity, no tumble. (Segment 6 holds heavier
    ///     per-cell flight physics in reserve pending the device feel pass.)
    private func drawUnknitPieces(_ ctx: inout GraphicsContext, geo: CaseGeometry, flood: Double) {
        let cells = unknitCells(flood: flood)
        guard !cells.isEmpty else { return }
        let quad = geo.frontQuad
        let spectrum = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [theme.colorway.c0, theme.colorway.c1, theme.colorway.c2]),
            startPoint: quad[0], endPoint: quad[2])
        let originUV = tears.last?.faceUV ?? CGPoint(x: 0.5, y: 0.5)
        let origin = bilerp(quad, Double(originUV.x), Double(originUV.y))
        let metal = color(mix(Self.components(theme.colorway.c1), SIMD3(0, 0, 0), 0.5))
        let backMetal = color(mix(Self.components(theme.colorway.c1), SIMD3(0, 0, 0), 0.78))

        for cell in cells {
            // seam pre-glow just ahead of the front
            if cell.lead <= 0 {
                guard let hex = hexCellPath(center: cell.center, geo: geo, scale: 1.0) else { continue }
                var pre = ctx
                pre.blendMode = .plusLighter
                pre.opacity = (0.5 + cell.lead) / 0.5 * 0.35
                pre.addFilter(.blur(radius: 1.5))
                pre.stroke(hex, with: spectrum, lineWidth: 1.2)
                continue
            }
            let q = cell.q
            guard q < 1,
                  let pc = wrapPoint(cell.center, geo: geo),
                  let hex = hexCellPath(center: cell.center, geo: geo, scale: 1.0)
            else { continue }

            // freed piece: short outward lift, slight tip, cool + fade
            let dx = pc.x - origin.x, dy = pc.y - origin.y
            let len = max(1, hypot(dx, dy))
            let qe = 1 - (1 - q) * (1 - q)                     // easeOut departure
            let travel = (10 + 14 * cell.jitter) * qe
            let ox = dx / len * travel, oy = dy / len * travel
            let ang = (cell.jitter - 0.5) * 0.8 * q
            let ca = dcos(ang), sa = dsin(ang)
            let sc = 1 - 0.30 * q
            var piece = Path()
            hex.forEach { el in
                func moved(_ p: CGPoint) -> CGPoint {
                    let rx = (p.x - pc.x) * sc, ry = (p.y - pc.y) * sc
                    return CGPoint(x: pc.x + (rx * ca - ry * sa) + ox,
                                   y: pc.y + (rx * sa + ry * ca) + oy)
                }
                switch el {
                case .move(let p):        piece.move(to: moved(p))
                case .line(let p):        piece.addLine(to: moved(p))
                case .closeSubpath:       piece.closeSubpath()
                default:                  break
                }
            }
            let alpha = 1 - q
            // thin dark back-offset → the piece reads as solid metal, not paper
            var back = ctx
            back.opacity = alpha
            back.fill(piece.applying(CGAffineTransform(translationX: 1.5 * sc, y: 1.5 * sc)),
                      with: .color(backMetal))
            var front = ctx
            front.opacity = alpha
            front.fill(piece, with: .color(metal))
            front.stroke(piece, with: spectrum, lineWidth: 0.8)
            // detach flare — the seam light releasing as the cell lets go
            if q < 0.35 {
                var flare = ctx
                flare.blendMode = .plusLighter
                flare.opacity = (0.35 - q) / 0.35 * 0.8
                flare.addFilter(.blur(radius: 2))
                flare.stroke(piece, with: spectrum, lineWidth: 1.4)
            }
        }
    }

    // MARK: - Living Case ceremony (Beat 5 rework): stress, rings, eruption, flower peel

    /// The theme colorway as a clamped spectrum ramp (c0 → c1 → c2), resolved to
    /// RGB once per draw pass — never white-primary: the lattice shimmers across
    /// the colorway, white only ever mixes IN at a lift peak.
    private struct ColorwayRamp {
        let c0: SIMD3<Double>, c1: SIMD3<Double>, c2: SIMD3<Double>
        func at(_ t: Double) -> SIMD3<Double> {
            let u = min(1, max(0, t))
            return u < 0.5 ? c0 + (c1 - c0) * (u * 2)
                           : c1 + (c2 - c1) * ((u - 0.5) * 2)
        }
    }
    private func colorwayRamp() -> ColorwayRamp {
        ColorwayRamp(c0: Self.components(theme.colorway.c0),
                     c1: Self.components(theme.colorway.c1),
                     c2: Self.components(theme.colorway.c2))
    }

    /// Per-cell spectrum position: radial (70%) + angular (30%) so adjacent cells
    /// at the same radius still differ slightly — shimmer, not colour rings.
    private func cellHueT(dx: Double, dy: Double, dist: Double, maxD: Double) -> Double {
        (dist / maxD) * 0.7 + (Darwin.atan2(dy, dx) / (2 * .pi) + 0.5) * 0.3
    }

    /// The eruption's pose on the module's frame clock: rise (0…1, eased), seal
    /// (0…1, eased; suppressed on the third tap), and visibility.
    private struct EruptPose {
        let rise: Double        // net rise after any reseal pull-back
        let seal: Double
        let visible: Double
        static let none = EruptPose(rise: 0, seal: 0, visible: 0)
    }
    private func eruptPose(t: Double, motion: Bool) -> EruptPose {
        guard motion, eruptStart != .distantFuture else { return .none }
        let e = t - eruptStart.timeIntervalSinceReferenceDate
        guard e >= 0 else { return .none }
        let k = min(max(eruptTapIndex, 0), 2)
        let riseDur = eruptRiseSpans[k]
        let riseIn = min(1, e / riseDur)
        let riseP = 1 - (1 - riseIn) * (1 - riseIn) * (1 - riseIn)   // easeOut
        var sealP = 0.0
        if k < 2 {
            let sealAt = riseDur + eruptHoldSpans[k]
            if e > sealAt {
                let s = min(1, (e - sealAt) / max(0.01, eruptSealSpans[k]))
                sealP = s * s * (3 - 2 * s)
            }
        }
        let visible = min(1, riseP * 4) * (1 - sealP * sealP)
        guard visible > 0.001 else { return .none }
        return EruptPose(rise: riseP * (1 - sealP), seal: sealP, visible: visible)
    }

    /// Live seam stress: the target bows in with the eruption's rise and unwinds
    /// with its reseal — held open when the reseal is suppressed (tap 3).
    private func netSeamStress(t: Double, motion: Bool) -> Double {
        guard seamStress > 0.001, motion, eruptStart != .distantFuture else { return 0 }
        let e = t - eruptStart.timeIntervalSinceReferenceDate
        guard e >= 0 else { return 0 }
        let pose = eruptPose(t: t, motion: motion)
        let ramp = min(1, e / 0.30)
        return seamStress * ramp * (1 - pose.seal)
    }

    /// One lattice cell with its radial coordinates from the FACE CENTRE (the
    /// peel + stress + rings all radiate from the middle, not a strike point).
    private struct RadialCell {
        let center: SIMD2<Double>   // lattice space
        let dist: Double            // lattice units from face centre
        let dx: Double, dy: Double
    }

    /// Enumerate honeycomb cell centres radially from the face centre. Overhang
    /// includes the fold wrap (peel consumes the whole shell); without it the
    /// enumeration stays on the front face (stress/ring overlay).
    private func radialCells(overhang: Bool) -> (cells: [RadialCell], maxD: Double) {
        let r3 = 1.7320508
        let cols = latticeColumns
        let over = overhang ? Double(depthFrac) * cols : 0
        let xLo = -over, xHi = cols + over
        let yLo = -over, yHi = 1.5 * cols + over
        let o = SIMD2(0.5 * cols, 0.75 * cols)
        let maxD = [SIMD2(xLo, yLo), SIMD2(xHi, yLo), SIMD2(xLo, yHi), SIMD2(xHi, yHi)]
            .map { c -> Double in
                let v = c - o
                return (v.x * v.x + v.y * v.y).squareRoot()
            }
            .max() ?? 1
        var cells: [RadialCell] = []
        func visit(_ c: SIMD2<Double>) {
            guard c.x >= xLo, c.x <= xHi, c.y >= yLo, c.y <= yHi else { return }
            let v = c - o
            cells.append(RadialCell(center: c,
                                    dist: (v.x * v.x + v.y * v.y).squareRoot(),
                                    dx: v.x, dy: v.y))
        }
        let jLo = Int((yLo / r3).rounded(.down)), jHi = Int((yHi / r3).rounded(.up))
        let iLo = Int(xLo.rounded(.down)), iHi = Int(xHi.rounded(.up))
        for j in jLo...jHi {
            let rowY = Double(j) * r3
            for i in iLo...iHi {
                visit(SIMD2(Double(i), rowY))                       // grid A
                visit(SIMD2(Double(i) + 0.5, rowY + r3 * 0.5))      // grid B
            }
        }
        return (cells, maxD)
    }

    /// Peel stagger: centre cells depart first — a centre cell starts at
    /// exitProgress ≈ 0, an edge cell not until ≈ 0.44; each takes 0.56 of the
    /// normalized timeline to complete its arc.
    private func peelLocalP(dist: Double, maxD: Double, flood: Double) -> Double {
        let delay = (dist / (maxD * 1.03)) * 0.44
        return min(1, max(0, (flood - delay) / 0.56))
    }

    /// Erase peeled cells from the shell — same destinationOut mechanism as the
    /// un-knit, but centre-out on the peel stagger: the deck behind is genuinely
    /// UNCOVERED through the opening middle while the edges still hold.
    private func erasePeel(_ ctx: inout GraphicsContext, geo: CaseGeometry, flood: Double) {
        guard flood > 0.001 else { return }
        let (cells, maxD) = radialCells(overhang: true)
        var cut = ctx
        cut.blendMode = .destinationOut
        for cell in cells where peelLocalP(dist: cell.dist, maxD: maxD, flood: flood) > 0 {
            guard let hex = hexCellPath(center: cell.center, geo: geo, scale: 1.18) else { continue }
            cut.fill(hex, with: .color(.black))
        }
    }

    /// The FLOWER PEEL — each departing cell is a petal opening toward the
    /// camera: drifts outward along its radial, scales up (perspective of the
    /// lift), brightens toward white at the arc's midpoint, fades as it
    /// completes. Three passes per cell:
    ///   1 shadow underside (darker, offset further outward — the petal's back)
    ///   2 face (spectrum colour, white-mixed at peak lift)
    ///   3 tear-edge highlight (bright stroke, 88% scale, pulled back toward
    ///     centre — the seam catching light as it breaks; the pass that makes
    ///     the peel read as material separating, not cells fading out)
    private func drawFlowerPeel(_ ctx: inout GraphicsContext, geo: CaseGeometry, flood: Double) {
        let (cells, maxD) = radialCells(overhang: true)
        guard !cells.isEmpty else { return }
        let quad = geo.frontQuad
        let sc = bilerp(quad, 0.5, 0.5)   // screen-space face centre
        let faceW = hypot(quad[1].x - quad[0].x, quad[1].y - quad[0].y)
        guard faceW > 1 else { return }
        let ramp = colorwayRamp()
        let white = SIMD3(1.0, 1.0, 1.0)
        let black = SIMD3(0.0, 0.0, 0.0)

        for cell in cells {
            let p = peelLocalP(dist: cell.dist, maxD: maxD, flood: flood)
            guard p > 0 else { continue }
            let fadeP = p * p * p                                  // easeIn3
            guard fadeP < 0.99 else { continue }
            let ep = 1 - (1 - p) * (1 - p) * (1 - p) * (1 - p)     // easeOut4
            guard let pc = wrapPoint(cell.center, geo: geo),
                  let hex = hexCellPath(center: cell.center, geo: geo, scale: 1.0)
            else { continue }

            // radial flight direction in SCREEN space
            let ddx = pc.x - sc.x, ddy = pc.y - sc.y
            let len = max(1, hypot(ddx, ddy))
            let nx = ddx / len, ny = ddy / len

            // centre cells travel farther (they carry more energy) + lift steeper
            let radial = 1 - cell.dist / maxD
            let travelScale = 0.6 + radial * 0.4
            let travel = ep * faceW * 0.20 * travelScale
            let liftAngle = radial * 0.5 + 0.2
            let scaleX = 1 + ep * dcos(liftAngle) * 0.5
            let scaleY = 1 + ep * 0.35

            let hueT = cellHueT(dx: cell.dx, dy: cell.dy, dist: cell.dist, maxD: maxD)
            let liftColor = ramp.at(hueT + ep * 0.15)
            let peakMix = max(0, dsin(p * .pi))                    // bell over the arc
            let faceColor = mix(liftColor, white, peakMix * 0.55)
            let alpha = 1 - fadeP

            // transform a hex path about its own centre: scale then translate
            func transformed(_ scale: Double, tx: CGFloat, ty: CGFloat) -> Path {
                var out = Path()
                hex.forEach { el in
                    func moved(_ pt: CGPoint) -> CGPoint {
                        CGPoint(x: pc.x + (pt.x - pc.x) * scaleX * scale + tx,
                                y: pc.y + (pt.y - pc.y) * scaleY * scale + ty)
                    }
                    switch el {
                    case .move(let pt):  out.move(to: moved(pt))
                    case .line(let pt):  out.addLine(to: moved(pt))
                    case .closeSubpath:  out.closeSubpath()
                    default:             break
                    }
                }
                return out
            }
            let tx = nx * travel, ty = ny * travel

            // 1 — shadow underside, offset further outward
            let shadowDepth = ep * faceW * 0.028 * travelScale
            var shadow = ctx
            shadow.opacity = alpha * 0.6
            shadow.fill(transformed(1.0, tx: tx + nx * shadowDepth, ty: ty + ny * shadowDepth),
                        with: .color(color(mix(liftColor, black, 0.75))))

            // 2 — face: spectrum colour brightening toward white at peak lift
            let facePath = transformed(1.0, tx: tx, ty: ty)
            var face = ctx
            face.opacity = alpha * (0.85 + peakMix * 0.15)
            face.fill(facePath, with: .color(color(faceColor).opacity(0.18 + peakMix * 0.35)))
            face.stroke(facePath, with: .color(color(faceColor)),
                        lineWidth: 1.2 + peakMix * 0.8)

            // 3 — tear-edge highlight: bright inner stroke, pulled back toward centre
            let tearOp = peakMix * 0.9 * alpha
            if tearOp > 0.02 {
                let back = faceW * 0.008
                var tear = ctx
                tear.opacity = tearOp
                tear.stroke(transformed(0.88, tx: tx - nx * back, ty: ty - ny * back),
                            with: .color(color(mix(liftColor, white, 0.7))),
                            lineWidth: 2.2)
            }
        }
    }

    /// Seam stress + wake rings on the intact shell: each strike permanently
    /// lights another ring of cells in per-cell spectrum colour; live stress
    /// bows cells outward from centre (most in the middle) — the lattice being
    /// pulled apart from within, without redrawing the shader's grooves.
    private func drawLatticeStress(_ ctx: inout GraphicsContext, geo: CaseGeometry,
                                   t: Double, motion: Bool) {
        let stress = netSeamStress(t: t, motion: motion)
        guard wakeRings > 0 || stress > 0.01 else { return }
        let (cells, maxD) = radialCells(overhang: false)
        let quad = geo.frontQuad
        let faceW = hypot(quad[1].x - quad[0].x, quad[1].y - quad[0].y)
        guard faceW > 1 else { return }
        let ringFrac = [0.0, 0.28, 0.62, 1.0][min(max(wakeRings, 0), 3)]
        let ringRadius = ringFrac * maxD
        let ramp = colorwayRamp()

        for cell in cells {
            let lit = cell.dist <= ringRadius
            let localStress = stress * max(0, 1 - cell.dist / maxD) * 1.3
            guard lit || localStress > 0.05 else { continue }
            guard var hex = hexCellPath(center: cell.center, geo: geo, scale: 1.0) else { continue }

            // stress displacement: bow outward from centre, screen-radial
            if localStress > 0.01, let pc = wrapPoint(cell.center, geo: geo) {
                let sc = bilerp(quad, 0.5, 0.5)
                let ddx = pc.x - sc.x, ddy = pc.y - sc.y
                let len = max(1, hypot(ddx, ddy))
                let push = localStress * faceW * 0.02
                hex = hex.applying(CGAffineTransform(translationX: ddx / len * push,
                                                     y: ddy / len * push))
            }

            let cw = color(ramp.at(cellHueT(dx: cell.dx, dy: cell.dy,
                                            dist: cell.dist, maxD: maxD)))
            let op = min(1, (lit ? 0.55 + 0.25 * coreGlow : 0) + localStress * 0.25)
            // soft glow (wide, additive) + crisp seam — two passes, no per-cell blur
            var glow = ctx
            glow.blendMode = .plusLighter
            glow.opacity = op * 0.35
            glow.stroke(hex, with: .color(cw), lineWidth: 3.0)
            var crisp = ctx
            crisp.opacity = op
            crisp.stroke(hex, with: .color(cw), lineWidth: 1.0 + localStress * 0.8)
            if lit {
                var fill = ctx
                fill.opacity = 0.08 + coreGlow * 0.12
                fill.fill(hex, with: .color(cw))
            }
        }
    }

    /// A card back tearing UP through the centre of the lattice — drawn in
    /// face-UV space through the projected quad and CLIPPED to the upper half
    /// of the front face, so it reads as pushing through from inside (without
    /// the clip it floats on top and reads as UI). Second card on tap 2+.
    private func drawEruption(_ ctx: inout GraphicsContext, geo: CaseGeometry,
                              t: Double, motion: Bool, flood: Double) {
        let pose = eruptPose(t: t, motion: motion)
        // the eruption hands off to the peel — fade over the peel's first act
        let visible = pose.visible * (1 - sstep(flood, 0.0, 0.35))
        guard visible > 0.01 else { return }
        let quad = geo.frontQuad
        let faceW = hypot(quad[1].x - quad[0].x, quad[1].y - quad[0].y)
        guard faceW > 1 else { return }
        let k = min(max(eruptTapIndex, 0), 2)
        let ramp = colorwayRamp()

        // card metrics in face-UV (card ≈ 29% of the face each way, mockup-scale)
        let wU = 0.30, hV = 0.29
        let maxRiseFrac = [0.55, 0.72, 0.85][k]
        let riseV = pose.rise * maxRiseFrac * hV

        // clip: the upper half of the front face — the card pushes through the midline
        var upper = Path()
        upper.move(to: quad[0])
        upper.addLine(to: quad[1])
        upper.addLine(to: bilerp(quad, 1, 0.5))
        upper.addLine(to: bilerp(quad, 0, 0.5))
        upper.closeSubpath()

        func drawCard(cxU: Double, rise: Double, opacity: Double, glowTint: Color) {
            let bottomV = 0.5 - rise
            let card = mappedRoundedRect(u0: cxU - wU / 2, v0: bottomV - hV,
                                         u1: cxU + wU / 2, v1: bottomV,
                                         rU: 0.045, geo: geo)
            var g = ctx
            g.clip(to: upper)
            g.opacity = opacity
            // body — near-void card back, colorway-tinted
            g.fill(card, with: .color(color(mix(ramp.at(0.5), SIMD3(0, 0, 0), 0.8))))
            // border glow (wide, soft) + crisp spectrum edge
            var glow = g
            glow.blendMode = .plusLighter
            glow.opacity = opacity * 0.35
            glow.stroke(card, with: .color(glowTint), lineWidth: 2.5)
            g.stroke(card, with: .linearGradient(
                Gradient(colors: [theme.colorway.c0, theme.colorway.c1, theme.colorway.c2]),
                startPoint: bilerp(quad, cxU - wU / 2, bottomV - hV),
                endPoint:   bilerp(quad, cxU + wU / 2, bottomV)),
                lineWidth: 1.2)
        }

        // second card first (behind): offset left, lower, dimmer — tap 2+
        if k >= 1 {
            drawCard(cxU: 0.5 - wU - 0.045, rise: riseV * 0.8,
                     opacity: visible * 0.85 * 0.75, glowTint: theme.colorway.c0)
        }
        drawCard(cxU: 0.5, rise: riseV, opacity: visible, glowTint: theme.colorway.c1)

        // the breach — glow at the tear point + spectrum lines radiating 6 ways
        let breach = bilerp(quad, 0.5, 0.5)
        var bg = ctx
        bg.blendMode = .plusLighter
        bg.opacity = visible * 0.5
        let bw = faceW * 0.36, bh = faceW * 0.06
        bg.fill(Path(ellipseIn: CGRect(x: breach.x - bw / 2, y: breach.y - bh / 2,
                                       width: bw, height: bh)),
                with: .color(theme.colorway.c1))
        let tearLen = faceW * (0.10 + 0.08 * visible)
        for i in 0..<6 {
            let a = Double(i) / 6 * 2 * .pi
            var line = Path()
            line.move(to: breach)
            line.addLine(to: CGPoint(x: breach.x + dcos(a) * tearLen,
                                     y: breach.y + dsin(a) * tearLen))
            var lg = ctx
            lg.blendMode = .plusLighter
            lg.opacity = visible * 0.6
            lg.stroke(line, with: .color(color(ramp.at(Double(i) / 6))), lineWidth: 0.8)
        }
    }

    /// A rounded rect authored in face-UV, every point mapped through the TRUE
    /// projected quad (bilerp) — same perspective-correct technique as the brand
    /// frame, so the erupting card sits ON the face, not on the screen.
    private func mappedRoundedRect(u0: Double, v0: Double, u1: Double, v1: Double,
                                   rU: Double, geo: CaseGeometry) -> Path {
        let rV = rU / 1.5   // face is w × 1.5w — equal corner radius in both axes
        var unit: [CGPoint] = []
        let seg = 4
        func corner(_ cx: Double, _ cy: Double, _ from: Double, _ to: Double) {
            for s in 0...seg {
                let a = from + (to - from) * Double(s) / Double(seg)
                unit.append(CGPoint(x: cx + rU * dcos(a), y: cy + rV * dsin(a)))
            }
        }
        corner(u0 + rU, v0 + rV, .pi,       1.5 * .pi)   // TL
        corner(u1 - rU, v0 + rV, 1.5 * .pi, 2.0 * .pi)   // TR
        corner(u1 - rU, v1 - rV, 0.0,       0.5 * .pi)   // BR
        corner(u0 + rU, v1 - rV, 0.5 * .pi, .pi)         // BL
        var path = Path()
        let mapped = unit.map { bilerp(geo.frontQuad, Double($0.x), Double($0.y)) }
        path.move(to: mapped[0])
        for p in mapped.dropFirst() { path.addLine(to: p) }
        path.closeSubpath()
        return path
    }

    /// Cracks RADIATE from the impact — `count` clean lines fanning out in evenly
    /// spread directions (a stone-through-glass impact), each propagating `reach`
    /// hex steps along the lattice (the seams give way) with the occasional straight
    /// chord across a cell for natural long runs. count/reach are AUTHORED by the
    /// caller per strike severity (the designed 1-2-3 escalation), so the only
    /// randomness is natural direction jitter. Deterministic per tear (seeded).
    /// `occupied` blocks cracks from crossing/merging across strikes.
    private func radiatingCracks(_ tear: CaseTear, geo: CaseGeometry,
                                 count: Int, reach: Int, links: [CGPoint],
                                 anchorAngle: Double, spread: Double,
                                 occupied: inout Set<Int64>) -> [[CGPoint]] {
        var rng = SplitMix64(seed: tear.seed)
        let strike = nearestHexVertex(SIMD2(Double(tear.faceUV.x) * latticeColumns,
                                            Double(tear.faceUV.y) * 1.5 * latticeColumns))
        occupied.insert(vertexKey(strike))

        // directions toward each LINKED (previous) strike — these cracks reach for
        // them so the central kill connects the whole network (they stop at the
        // earlier cracks they run into, reading as a join).
        let linkDirs: [SIMD2<Double>] = links.compactMap { l in
            let target = SIMD2(Double(l.x) * latticeColumns, Double(l.y) * 1.5 * latticeColumns)
            let d = target - strike
            let len = (d.x * d.x + d.y * d.y).squareRoot()
            return len > 0.01 ? SIMD2(d.x / len, d.y / len) : nil
        }
        let total = max(count, linkDirs.count)
        let fanCount = max(1, total - linkDirs.count)

        var lines: [[CGPoint]] = []
        for i in 0..<total {
            // the first cracks reach the linked strikes; the rest fan within `spread`
            // (toward centre for corner strikes, full circle for the central kill)
            let isLink = i < linkDirs.count
            let dir: SIMD2<Double>
            if isLink {
                dir = linkDirs[i]
            } else {
                let fi = i - linkDirs.count
                let ang = fanCount > 1
                    ? anchorAngle + spread * (Double(fi) / Double(fanCount - 1) - 0.5)
                        + Double.random(in: -0.2...0.2, using: &rng)
                    : anchorAngle
                dir = SIMD2(dcos(ang), dsin(ang))
            }
            let armReach = isLink ? reach + 10 : reach   // link spans toward the corner
            let (mainScreen, mainLat) = walkFracture(from: strike, dir: dir, reach: armReach,
                                                     geo: geo, occupied: &occupied, rng: &rng)
            if mainScreen.count > 1 { lines.append(mainScreen) }

            // OFFSHOOTS — short sub-cracks forking off the main run, so the fracture
            // SPREADS and covers area (a tree, not a single scratch).
            guard mainLat.count > 4 else { continue }
            for _ in 0..<2 {
                let idx = Int.random(in: 2..<mainLat.count, using: &rng)
                let side: Double = Bool.random(using: &rng) ? 1 : -1
                let offAng = atan2(dir.y, dir.x) + side * Double.random(in: 0.6...1.1, using: &rng)
                let offDir = SIMD2(dcos(offAng), dsin(offAng))
                let (offScreen, _) = walkFracture(from: mainLat[idx], dir: offDir,
                                                  reach: max(3, armReach / 2),
                                                  geo: geo, occupied: &occupied, rng: &rng)
                if offScreen.count > 1 { lines.append(offScreen) }
            }
        }
        return lines
    }

    /// Walk one fracture run along the hex lattice from `start` heading `dir`, up to
    /// `reach` steps (with the occasional straight chord across a cell). Returns the
    /// screen polyline + the lattice vertices visited (so offshoots can fork off it).
    private func walkFracture(from start: SIMD2<Double>, dir: SIMD2<Double>, reach: Int,
                              geo: CaseGeometry, occupied: inout Set<Int64>,
                              rng: inout SplitMix64) -> ([CGPoint], [SIMD2<Double>]) {
        let openings = hexNeighbors(of: start).filter { !occupied.contains(vertexKey($0)) }
        guard let first = openings.max(by: { align($0 - start, dir) < align($1 - start, dir) }),
              let p0 = wrapPoint(start, geo: geo),
              let p1 = wrapPoint(first, geo: geo) else { return ([], []) }
        occupied.insert(vertexKey(first))
        var screen = [p0, p1]
        var lat = [start, first]
        var previous = start, current = first
        for _ in 0..<reach {
            let options = hexNeighbors(of: current).filter {
                dist2($0, previous) > 0.01 && !occupied.contains(vertexKey($0))
            }
            guard !options.isEmpty else { break }
            var next = options.max(by: {
                align($0 - current, dir) + Double.random(in: 0...0.3, using: &rng)
              < align($1 - current, dir) + Double.random(in: 0...0.3, using: &rng)
            })!
            if Double.random(in: 0...1, using: &rng) < 0.3 {
                let heading = next - current
                let beyond = hexNeighbors(of: next).filter {
                    dist2($0, current) > 0.01 && !occupied.contains(vertexKey($0))
                }
                if let through = beyond.max(by: {
                    align($0 - next, heading) < align($1 - next, heading)
                }) { next = through }
            }
            previous = current; current = next
            guard let pt = wrapPoint(current, geo: geo) else { break }
            occupied.insert(vertexKey(current))
            screen.append(pt); lat.append(current)
        }
        return (screen, lat)
    }

    /// Normalized alignment of a step with a direction (−1…1).
    private func align(_ step: SIMD2<Double>, _ dir: SIMD2<Double>) -> Double {
        let len = (step.x * step.x + step.y * step.y).squareRoot()
        guard len > 1e-9 else { return -1 }
        return (step.x * dir.x + step.y * dir.y) / len
    }

    /// Quantized lattice-vertex key: x lives on multiples of 0.5, y on
    /// multiples of 1/(2√3) — exact integer grid once scaled.
    private func vertexKey(_ v: SIMD2<Double>) -> Int64 {
        let xi = Int64((v.x * 2).rounded())
        let yi = Int64((v.y * 2 * 1.7320508).rounded())
        return (xi << 32) ^ (yi & 0xFFFF_FFFF)
    }

    // MARK: Lattice-space helpers — these mirror hexFoilSurface's grid EXACTLY
    // (pointy-top hexes tiled on r = (1, √3), centers on two offset grids).
    // If the shader's layout changes, these must change with it.

    /// Hex circumradius for apothem 0.5 — also the honeycomb edge length.
    private static let hexR = 1.0 / 1.7320508

    private func uvFromLattice(_ p: SIMD2<Double>) -> CGPoint {
        CGPoint(x: p.x / latticeColumns, y: p.y / (1.5 * latticeColumns))
    }

    /// Face UV → screen, WRAPPING OVER THE BOX FOLDS: u/v beyond [0,1] continue
    /// onto the side/top/bottom faces (the shell fails all around, not just the
    /// front plate). Overhang is mapped across the box depth toward the back
    /// edge; returns nil past the fold of a face the camera can't see, or past
    /// 90% of the depth — the branch dies there.
    private func wrapPoint(_ p: SIMD2<Double>, geo: CaseGeometry) -> CGPoint? {
        let uv = uvFromLattice(p)
        let u = Double(uv.x), v = Double(uv.y)
        let depthU = Double(depthFrac)            // side-face depth in u units
        let depthV = Double(depthFrac) / 1.5      // top/bottom depth in v units
        let proj = geo.proj
        func mixP(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
            CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
        }
        func facing(_ n: SIMD3<Double>) -> Bool {
            rotate(n, rx: geo.rx, ry: geo.ry).z > 0.04
        }
        switch ((0.0...1.0).contains(u), (0.0...1.0).contains(v)) {
        case (true, true):
            return bilerp(geo.frontQuad, u, v)
        case (false, true):                       // left / right face
            let left = u < 0
            let s = (left ? -u : u - 1) / depthU
            guard s <= 0.9, facing(SIMD3(left ? -1 : 1, 0, 0)) else { return nil }
            return left
                ? mixP(mixP(proj[0], proj[4], s), mixP(proj[3], proj[7], s), v)
                : mixP(mixP(proj[1], proj[5], s), mixP(proj[2], proj[6], s), v)
        case (true, false):                       // top / bottom face
            let top = v < 0
            let s = (top ? -v : v - 1) / depthV
            guard s <= 0.9, facing(SIMD3(0, top ? -1 : 1, 0)) else { return nil }
            return top
                ? mixP(mixP(proj[0], proj[4], s), mixP(proj[1], proj[5], s), u)
                : mixP(mixP(proj[3], proj[7], s), mixP(proj[2], proj[6], s), u)
        default:                                  // past a box corner — stop
            return nil
        }
    }

    private func dist2(_ a: SIMD2<Double>, _ b: SIMD2<Double>) -> Double {
        let d = a - b
        return d.x * d.x + d.y * d.y
    }

    /// Nearest honeycomb VERTEX (cell corner) to a lattice-space point.
    private func nearestHexVertex(_ p: SIMD2<Double>) -> SIMD2<Double> {
        let r = SIMD2(1.0, 1.7320508)
        func wrap(_ x: SIMD2<Double>) -> SIMD2<Double> {
            SIMD2(x.x - r.x * (x.x / r.x).rounded(.down),
                  x.y - r.y * (x.y / r.y).rounded(.down)) - r * 0.5
        }
        let ga = wrap(p)
        let gb = wrap(p - r * 0.5)
        let gv = (ga.x * ga.x + ga.y * ga.y) < (gb.x * gb.x + gb.y * gb.y) ? ga : gb
        let center = p - gv                      // owning cell center
        let R = Self.hexR
        let corners: [SIMD2<Double>] = [
            SIMD2(0,  R), SIMD2(0.5,  R / 2), SIMD2(0.5, -R / 2),
            SIMD2(0, -R), SIMD2(-0.5, -R / 2), SIMD2(-0.5, R / 2),
        ]
        return corners
            .map { center + $0 }
            .min(by: { dist2($0, p) < dist2($1, p) })!
    }

    /// A honeycomb vertex's 3 neighbors: probe all 6 edge directions and keep
    /// the ones that land on a real vertex — no parity bookkeeping to drift.
    private func hexNeighbors(of v: SIMD2<Double>) -> [SIMD2<Double>] {
        let R = Self.hexR
        let dirs: [SIMD2<Double>] = [
            SIMD2(0,  R), SIMD2(0, -R),
            SIMD2( 0.5,  R / 2), SIMD2( 0.5, -R / 2),
            SIMD2(-0.5,  R / 2), SIMD2(-0.5, -R / 2),
        ]
        return dirs.compactMap { d in
            let candidate = v + d
            let snapped = nearestHexVertex(candidate)
            return dist2(snapped, candidate) < (R * 0.05) * (R * 0.05) ? snapped : nil
        }
    }

    /// UV → screen through the projected front quad (TL, TR, BR, BL).
    private func bilerp(_ q: [CGPoint], _ u: Double, _ v: Double) -> CGPoint {
        let top = CGPoint(x: q[0].x + (q[1].x - q[0].x) * u, y: q[0].y + (q[1].y - q[0].y) * u)
        let bot = CGPoint(x: q[3].x + (q[2].x - q[3].x) * u, y: q[3].y + (q[2].y - q[3].y) * u)
        return CGPoint(x: top.x + (bot.x - top.x) * v, y: top.y + (bot.y - top.y) * v)
    }

    /// Screen → UV: analytic inverse-bilinear over the projected front quad
    /// (TL, TR, BR, BL) — the same machinery the foil shader uses, so a tap
    /// lands exactly where the crack will render.
    private func invBilinear(_ p: CGPoint, quad q: [CGPoint]) -> CGPoint? {
        guard q.count == 4 else { return nil }
        let a = SIMD2(Double(q[0].x), Double(q[0].y))
        let b = SIMD2(Double(q[1].x), Double(q[1].y))
        let c = SIMD2(Double(q[2].x), Double(q[2].y))
        let d = SIMD2(Double(q[3].x), Double(q[3].y))
        let pt = SIMD2(Double(p.x), Double(p.y))

        let e = b - a, f = d - a, g = a - b + c - d, h = pt - a
        func cross2(_ x: SIMD2<Double>, _ y: SIMD2<Double>) -> Double { x.x * y.y - x.y * y.x }
        let k2 = cross2(g, f)
        let k1 = cross2(e, f) + cross2(h, g)
        let k0 = cross2(h, e)

        var v: Double
        if abs(k2) < 1e-7 {
            guard abs(k1) > 1e-9 else { return nil }
            v = -k0 / k1
        } else {
            let disc = k1 * k1 - 4 * k2 * k0
            guard disc >= 0 else { return nil }
            let sq = disc.squareRoot()
            let v1 = (-k1 + sq) / (2 * k2)
            let v2 = (-k1 - sq) / (2 * k2)
            // the quad is convex — pick the root nearest the unit interval
            func unitDistance(_ x: Double) -> Double { x < 0 ? -x : (x > 1 ? x - 1 : 0) }
            v = unitDistance(v1) <= unitDistance(v2) ? v1 : v2
        }
        let denX = e.x + g.x * v
        let denY = e.y + g.y * v
        guard max(abs(denX), abs(denY)) > 1e-9 else { return nil }
        let u = abs(denX) > abs(denY) ? (h.x - f.x * v) / denX
                                      : (h.y - f.y * v) / denY
        return CGPoint(x: u, y: v)
    }

    /// Seeded deterministic RNG for crack geometry — same pattern every frame.
    private struct SplitMix64: RandomNumberGenerator {
        var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
    }

    // MARK: - 3D math

    private func rotate(_ p: SIMD3<Double>, rx: Double, ry: Double) -> SIMD3<Double> {
        // rotate around X then Y
        let y1 = p.y * dcos(rx) - p.z * dsin(rx)
        let z1 = p.y * dsin(rx) + p.z * dcos(rx)
        let x2 = p.x * dcos(ry) + z1 * dsin(ry)
        let z2 = -p.x * dsin(ry) + z1 * dcos(ry)
        return SIMD3(x2, y1, z2)
    }

    private func project(_ p: SIMD3<Double>, center: CGPoint) -> CGPoint {
        let s = perspective / (perspective - p.z)
        return CGPoint(x: center.x + CGFloat(p.x * s), y: center.y + CGFloat(p.y * s))
    }

    // Disambiguate cos/sin: CoreGraphics' cos(CGFloat) + implicit CGFloat↔Double
    // conversion makes the bare calls ambiguous. Darwin has only the Double overload.
    private func dcos(_ x: Double) -> Double { Darwin.cos(x) }
    private func dsin(_ x: Double) -> Double { Darwin.sin(x) }

    // MARK: - Surface (foil)

    /// A face path with rounded corners — softens the machined-plate read toward foil.
    private func roundedFacePath(_ pts: [CGPoint], softness: Double) -> Path {
        var path = Path()
        guard pts.count >= 3 else { return path }
        if softness <= 0 {
            path.move(to: pts[0]); for p in pts.dropFirst() { path.addLine(to: p) }
            path.closeSubpath(); return path
        }
        let n = pts.count
        // UNIFORM corner radius: base it on the silhouette's overall size, not on
        // each corner's adjacent edge lengths. With the old per-edge radius, a
        // corner between two LONG edges (the perspective-compressed bottom, where
        // the long side edges converge) got a far bigger round than the rest and
        // read as a melted/warped corner — which ALSO clipped the brand frame
        // there (the frame is drawn inside this same clip), so both symptoms shared
        // one cause. Cap per-corner so a short edge still can't be over-rounded.
        let xs = pts.map(\.x), ys = pts.map(\.y)
        let span = min((xs.max() ?? 0) - (xs.min() ?? 0), (ys.max() ?? 0) - (ys.min() ?? 0))
        let maxR = CGFloat(softness) * 0.5 * span
        for i in 0..<n {
            let cur = pts[i], prev = pts[(i + n - 1) % n], next = pts[(i + 1) % n]
            let r = min(maxR, 0.5 * min(dist(cur, prev), dist(cur, next)))
            let a = lerpPoint(cur, prev, r)
            let b = lerpPoint(cur, next, r)
            if i == 0 { path.move(to: a) } else { path.addLine(to: a) }
            path.addQuadCurve(to: b, control: cur)
        }
        path.closeSubpath()
        return path
    }

    private func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(b.x - a.x, b.y - a.y) }
    private func lerpPoint(_ from: CGPoint, _ to: CGPoint, _ d: CGFloat) -> CGPoint {
        let len = max(0.0001, dist(from, to))
        let f = min(1, d / len)
        return CGPoint(x: from.x + (to.x - from.x) * f, y: from.y + (to.y - from.y) * f)
    }

    // MARK: - Colour helpers

    private func mix(_ a: SIMD3<Double>, _ b: SIMD3<Double>, _ t: Double) -> SIMD3<Double> {
        a + (b - a) * t
    }
    private func color(_ v: SIMD3<Double>) -> Color {
        Color(red: min(1, max(0, v.x)), green: min(1, max(0, v.y)), blue: min(1, max(0, v.z)))
    }

    /// Cyclic interpolation cyan → purple → magenta → cyan, p in 0...1.
    private static func metalHue(_ p: Double) -> SIMD3<Double> {
        let x = ((p.truncatingRemainder(dividingBy: 1)) + 1).truncatingRemainder(dividingBy: 1)
        let anchors = [anchorCyan, anchorPurple, anchorMagenta, anchorCyan]
        let seg = min(2, Int(x * 3))
        let lt = x * 3 - Double(seg)
        return anchors[seg] + (anchors[seg + 1] - anchors[seg]) * lt
    }

    // spectrum tokens resolved to RGB once, for the metallic math (no raw colour literals)
    private static func components(_ c: Color) -> SIMD3<Double> {
        let ui = UIColor(c)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        _ = ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return SIMD3(Double(r), Double(g), Double(b))
    }
    private static let anchorCyan    = components(AppColors.spectrumCyan)
    private static let anchorPurple  = components(AppColors.spectrumPurple)
    private static let anchorMagenta = components(AppColors.spectrumMagenta)
    private static let anchorDark    = components(AppColors.void)
}

// MARK: - Preview

#Preview("Metallic case") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        MetallicCaseView()
    }
    .preferredColorScheme(.dark)
}

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

// Temporary verification harness — judge every foil segment against the card
// back it must complement. Same footprint for both so value range, spectrum
// order, and texture family compare directly.
#Preview("Case vs card back") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        HStack(spacing: AppSpacing.md) {
            let cardW = AppLayout.obCardWidth(in: 240)
            let cardH = AppLayout.obCardHeight(in: 240)
            MetallicCaseView()
                .frame(width: cardW, height: cardH)
            VaylCardBack()
                .frame(width: cardW, height: cardH)
        }
    }
    .preferredColorScheme(.dark)
}
