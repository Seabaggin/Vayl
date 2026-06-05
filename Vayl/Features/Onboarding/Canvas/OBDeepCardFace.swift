// Vayl/Features/Onboarding/Canvas/OBDeepCardFace.swift



import SwiftUI



// MARK: - OBDeepCardFace



/// Canvas renderer for "The Deep" OB card face.

/// Revealed on flip during the NamePhase card deal sequence.

/// Never used outside OB.

///

/// deepT: elapsed seconds since face became visible.

///        Drives swirl drift, particle movement, shimmer cycles, glow breathe.

///        Caller increments via TimelineView — this view never holds time state.

struct OBDeepCardFace: View {



    let deepT: Double



    // ── Seeded particle pool — generated once, stable across frames ────────────

    private let particles: [Particle] = Self.makeParticles()

    private let flecks:    [Fleck]    = Self.makeFlecks()



    var body: some View {

        GeometryReader { geo in

            let size = geo.size

            let R    = AppRadius.obCard



            ZStack {

                Canvas { ctx, canvasSize in

                    drawBase(context: ctx, size: canvasSize, R: R)

                    drawSwirl(context: ctx, size: canvasSize, deepT: deepT)


                    drawShimmer(context: ctx, size: canvasSize, deepT: deepT)

                    drawDepthGlow(context: ctx, size: canvasSize, deepT: deepT)

                }



                // Caustic + ripple layer — screen-blended over Canvas.

                // Ripples are a UV displacement field: no circles drawn.

                // Rings appear as the caustic pattern bunching and spreading.

                Rectangle()
                    .colorEffect(ShaderLibrary.htmlCaustics(
                        .float2(size),
                        .float(Float(deepT)),
                        .float(0.0115), // scale     — zoomed in, reduces overall wave count
                        .float(0.81)    // threshold — culls fainter secondary lines
                    ))
                    .blendMode(.screen)

            }

            .drawingGroup()

            .clipShape(RoundedRectangle(cornerRadius: R))

            .overlay { DeepCardShell(size: size, R: R) }

        }

    }

}



// MARK: - Seeded data types



private extension OBDeepCardFace {



    struct Particle {

        let x:       CGFloat   // normalised 0..1 of card width

        let y:       CGFloat   // normalised 0..1 of card height

        let driftA:  Double    // drift direction (radians)

        let driftSpd: Double   // drift speed (normalised units/s)

        let radius:  CGFloat   // base radius (pt)

        let opacity: Double    // max opacity

        let phase:   Double    // twinkle phase offset

    }



    struct Fleck {

        let x:      CGFloat

        let y:      CGFloat

        let period: Double    // full cycle duration (seconds)

        let phase:  Double    // start offset within cycle

        let radius: CGFloat

    }



    private static func rng(_ seed: Double) -> Double {

        var x = sin(seed) * 43758.5453

        x -= floor(x)

        return x

    }



    static func makeParticles() -> [Particle] {

        return (0 ..< 48).map { i in

            let fi = Double(i)

            return Particle(

                x:        CGFloat(rng(fi * 1.30)),

                y:        CGFloat(rng(fi * 2.71)),

                driftA:   rng(fi * 3.94) * .pi * 2,

                driftSpd: 0.006 + rng(fi * 5.13) * 0.012,

                radius:   CGFloat(1.5 + rng(fi * 6.37) * 2.0),

                opacity:  0.10 + rng(fi * 7.58) * 0.20,

                phase:    rng(fi * 8.81) * .pi * 2

            )

        }

    }



    static func makeFlecks() -> [Fleck] {

        return (0 ..< 4).map { i in

            let fi = Double(i)

            return Fleck(

                x:      CGFloat(0.12 + rng(fi * 11.3) * 0.76),

                y:      CGFloat(0.12 + rng(fi * 12.7) * 0.76),

                period: 2.2 + rng(fi * 13.9) * 1.6,

                phase:  rng(fi * 15.1) * 2.2,

                radius: CGFloat(0.8 + rng(fi * 16.3) * 0.8)

            )

        }

    }

}



// MARK: - Layer 0: Base



private extension OBDeepCardFace {



    func drawBase(context: GraphicsContext, size: CGSize, R: CGFloat) {

        let path = Path(roundedRect: CGRect(origin: .zero, size: size),

                        cornerRadius: R)

        context.fill(

            path,

            with: .radialGradient(

                Gradient(stops: [

                    .init(color: .black,                                               location: 0.00),
                    .init(color: Color(red: 0.02, green: 0.01, blue: 0.06),           location: 0.40),
                    .init(color: Color(red: 0.04, green: 0.015, blue: 0.12),          location: 0.80),
                    .init(color: .black,                                               location: 1.00),

                ]),

                center:      CGPoint(x: size.width / 2, y: size.height / 2),

                startRadius: 0,

                endRadius:   max(size.width, size.height) * 0.72

            )

        )

    }

}



// MARK: - Layer 1: Swirl



private extension OBDeepCardFace {



    // Two overlapping radial layers whose centres drift slowly in opposite

    // circular arcs. Creates organic undulation without per-pixel computation.

    func drawSwirl(context: GraphicsContext, size: CGSize, deepT: Double) {

        let W  = size.width

        let H  = size.height

        let cx = W / 2

        let cy = H / 2



        // Slow drift — period ≈ 10s per orbit

        let angle1 = deepT * ((.pi * 2) / 10.0)

        let angle2 = deepT * ((.pi * 2) / 13.5) + .pi  // opposite phase



        let orbitR: CGFloat = min(W, H) * 0.18



        let c1 = CGPoint(x: cx + cos(angle1) * orbitR, y: cy + sin(angle1) * orbitR * 0.55)

        let c2 = CGPoint(x: cx + cos(angle2) * orbitR, y: cy + sin(angle2) * orbitR * 0.55)



        let rect = Path(CGRect(origin: .zero, size: size))



        // Layer A — deep indigo

        context.fill(rect, with: .radialGradient(

            Gradient(stops: [

                .init(color: Color(red: 0.102, green: 0.039, blue: 0.251).opacity(0.14), location: 0),

                .init(color: Color(red: 0.063, green: 0.016, blue: 0.188).opacity(0.06), location: 0.55),

                .init(color: .clear, location: 1),

            ]),

            center: c1, startRadius: 0, endRadius: min(W, H) * 0.55

        ))



        // Layer B — purple

        context.fill(rect, with: .radialGradient(

            Gradient(stops: [

                .init(color: Color(red: 0.165, green: 0.063, blue: 0.376).opacity(0.11), location: 0),

                .init(color: Color(red: 0.102, green: 0.039, blue: 0.251).opacity(0.05), location: 0.50),

                .init(color: .clear, location: 1),

            ]),

            center: c2, startRadius: 0, endRadius: min(W, H) * 0.48

        ))

    }

}



// MARK: - Layer 2: Particles



private extension OBDeepCardFace {



    func drawParticles(context: GraphicsContext, size: CGSize, deepT: Double) {

        let W = size.width

        let H = size.height

        // Fade in over first 1.5s

        let fadeIn = min(1.0, deepT / 1.50)

        guard fadeIn > 0 else { return }



        for p in particles {

            // Drift position — wraps at edges (toroidal)

            let driftX = (cos(p.driftA) * p.driftSpd * deepT).truncatingRemainder(dividingBy: 1.0)

            let driftY = (sin(p.driftA) * p.driftSpd * deepT).truncatingRemainder(dividingBy: 1.0)

            var nx = (p.x + driftX).truncatingRemainder(dividingBy: 1.0)

            var ny = (p.y + driftY).truncatingRemainder(dividingBy: 1.0)

            if nx < 0 { nx += 1 }

            if ny < 0 { ny += 1 }



            let px = nx * W

            let py = ny * H



            // Twinkle

            let tw = 0.65 + 0.35 * sin(deepT * 0.75 + p.phase)

            let a  = p.opacity * tw * fadeIn



            // Soft halo — 3× radius, low opacity

            let haloR = p.radius * 3.0

            context.fill(

                Path(ellipseIn: CGRect(x: px - haloR, y: py - haloR,

                                       width: haloR * 2, height: haloR * 2)),

                with: .radialGradient(

                    Gradient(colors: [

                        Color(red: 0.784, green: 0.722, blue: 1.0).opacity(a * 0.35),

                        .clear,

                    ]),

                    center: CGPoint(x: px, y: py),

                    startRadius: 0,

                    endRadius: haloR

                )

            )



            // Core — silver-lavender

            let coreR = p.radius

            context.fill(

                Path(ellipseIn: CGRect(x: px - coreR, y: py - coreR,

                                       width: coreR * 2, height: coreR * 2)),

                with: .color(Color(red: 0.784, green: 0.722, blue: 1.0).opacity(a))

            )

        }

    }

}



// MARK: - Layer 3: Surface Shimmer



private extension OBDeepCardFace {



    func drawShimmer(context: GraphicsContext, size: CGSize, deepT: Double) {

        let W = size.width

        let H = size.height

        let fadeIn = min(1.0, deepT / 0.80)

        guard fadeIn > 0 else { return }



        for f in flecks {

            // Cycle position in [0, 1) — sharp sin² peak

            let cyclePos = (deepT + f.phase).truncatingRemainder(dividingBy: f.period) / f.period

            let rawAlpha = pow(max(0.0, sin(cyclePos * .pi)), 2.0)

            let a = rawAlpha * 0.28 * fadeIn

            guard a > 0.002 else { continue }



            let px = f.x * W

            let py = f.y * H

            let haloR = f.radius * 9.0



            context.fill(

                Path(ellipseIn: CGRect(x: px - haloR, y: py - haloR,

                                       width: haloR * 2, height: haloR * 2)),

                with: .radialGradient(

                    Gradient(colors: [

                        Color(red: 0.824, green: 0.784, blue: 1.0).opacity(a),

                        .clear,

                    ]),

                    center: CGPoint(x: px, y: py),

                    startRadius: 0,

                    endRadius: haloR

                )

            )

        }

    }

}



// MARK: - Layer 4: Depth Glow



private extension OBDeepCardFace {



    // Wide, ambient breathing source deep in the liquid.
    // Removed the concentrated core to preserve the "abyss" depth illusion.

    func drawDepthGlow(context: GraphicsContext, size: CGSize, deepT: Double) {

        let cx = size.width  / 2

        let cy = size.height / 2

        let fadeIn  = min(1.0, deepT / 0.90)
        let breathe = 0.45 + 0.55 * pow(0.50 + 0.50 * sin(deepT * (.pi * 2 / 3.60)), 1.8)
        let gA      = fadeIn * breathe

        let r = min(size.width, size.height) / 2

        // Outer — wide ambient deep-sea scatter
        context.fill(
            Path(ellipseIn: CGRect(x: cx - r * 0.85, y: cy - r * 0.85,
                                   width: r * 1.70, height: r * 1.70)),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color(red: 0.227, green: 0.059, blue: 0.541).opacity(gA * 0.15), location: 0),
                    .init(color: Color(red: 0.150, green: 0.030, blue: 0.350).opacity(gA * 0.05), location: 0.6),
                    .init(color: .clear, location: 1),
                ]),
                center: CGPoint(x: cx, y: cy),
                startRadius: 0,
                endRadius: r * 0.85
            )
        )

        // Mid — soft diffuse centre glow, no sharp pinpoint
        context.fill(
            Path(ellipseIn: CGRect(x: cx - r * 0.40, y: cy - r * 0.40,
                                   width: r * 0.80, height: r * 0.80)),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color(red: 0.424, green: 0.227, blue: 0.878).opacity(gA * 0.25), location: 0),
                    .init(color: Color(red: 0.227, green: 0.059, blue: 0.541).opacity(gA * 0.08), location: 0.7),
                    .init(color: .clear, location: 1),
                ]),
                center: CGPoint(x: cx, y: cy),
                startRadius: 0,
                endRadius: r * 0.40
            )
        )
    }
}



// MARK: - DeepCardShell



/// Spectrum shell overlay — same visual language as VaylCardFace.

/// Drawn as SwiftUI views over the Canvas so they sit above the clip boundary.

private struct DeepCardShell: View {

    let size: CGSize

    let R:    CGFloat



    var body: some View {

        ZStack {

            // Border glow

            RoundedRectangle(cornerRadius: R)

                .stroke(AppColors.spectrumPurple.opacity(0.18), lineWidth: 1)

                .blur(radius: 20)



            // Outer spectrum hairline

            RoundedRectangle(cornerRadius: R)

                .strokeBorder(AppColors.spectrumBorder, lineWidth: 1.1)

                .opacity(0.52)

                .padding(0.75)



            // Inset frame

            RoundedRectangle(cornerRadius: R - 4)

                .strokeBorder(AppColors.spectrumBorder, lineWidth: 0.55)

                .opacity(0.22)

                .padding(9)



            // Top hairline

            Path { p in

                p.move(to:    CGPoint(x: 14,              y: 0.75))

                p.addLine(to: CGPoint(x: size.width - 14, y: 0.75))

            }

            .stroke(AppColors.spectrumBorder.opacity(0.60), lineWidth: 1.2)

            .frame(width: size.width, height: size.height)



            // Bottom hairline

            Path { p in

                p.move(to:    CGPoint(x: 14,              y: size.height - 0.75))

                p.addLine(to: CGPoint(x: size.width - 14, y: size.height - 0.75))

            }

            .stroke(AppColors.spectrumBorder.opacity(0.60), lineWidth: 1.2)

            .frame(width: size.width, height: size.height)



        }

    }

}



// MARK: - Preview



#Preview("The Deep — resting (deepT = 2.0)") {

    ZStack {

        Color.black.ignoresSafeArea()

        OBDeepCardFace(deepT: 2.0)

            .frame(width: 260, height: 385)

            .drawingGroup()

    }

    .preferredColorScheme(.dark)

}



#Preview("The Deep — just flipped (deepT = 0.1)") {

    ZStack {

        Color.black.ignoresSafeArea()

        OBDeepCardFace(deepT: 0.1)

            .frame(width: 260, height: 385)

            .drawingGroup()

    }

    .preferredColorScheme(.dark)

}



private struct DeepCardLivePreview: View {

    @State private var startDate = Date()

    var body: some View {

        ZStack {

            Color.black.ignoresSafeArea()

            TimelineView(.animation) { tl in

                OBDeepCardFace(deepT: tl.date.timeIntervalSince(startDate))

                    .frame(width: 260, height: 385)

                    .drawingGroup()

            }

        }

        .preferredColorScheme(.dark)

    }

}



#Preview("The Deep — live") {

    DeepCardLivePreview()

}
