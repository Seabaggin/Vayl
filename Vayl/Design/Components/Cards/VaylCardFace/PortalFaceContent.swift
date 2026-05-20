//
//  PortalFaceContent.swift
//  Vayl
//
//  Created by Claude Code Agent.
//
//  Design/Components/Cards/VaylCardFace/PortalFaceContent.swift
//
//  "The Deep" portal face content.
//  Bioluminescent center, tide rings, star field, elapsed-time driven via TimelineView.
//  Internal — only VaylCardFace.swift initialises this. Never reference directly from phases.
//  Replaces OBDeepCardFace.swift. Do not delete OBDeepCardFace.swift yet —
//  wait for device verification before removing.
//

import SwiftUI

// MARK: - PortalFaceContent

/// Canvas renderer for "The Deep" OB card face.
/// Revealed on flip during portal sequences.
/// Never used outside OB.
///
/// startDate: the moment this face became visible.
///            Used to derive elapsed time via TimelineView — this view never holds mutable time state.
internal struct PortalFaceContent: View {

    let startDate: Date

    // ── Seeded particle pool — generated once, stable across frames ────────────
    private let particles: [Particle] = Self.makeParticles()
    private let flecks:    [Fleck]    = Self.makeFlecks()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { tl in
            let deepT = tl.date.timeIntervalSince(startDate)
            contentLayer(deepT: max(0, deepT))
        }
    }

    private func contentLayer(deepT: Double) -> some View {
        GeometryReader { geo in
            let size = geo.size
            let R    = AppRadius.obCard

            Canvas { context, size in
                drawBase(context: context, size: size, R: R)
                drawSwirl(context: context, size: size, deepT: deepT)
                drawParticles(context: context, size: size, deepT: deepT)
                drawShimmer(context: context, size: size, deepT: deepT)
                drawDepthGlow(context: context, size: size, deepT: deepT)
            }
            .clipShape(RoundedRectangle(cornerRadius: R))
            .overlay { DeepCardShell(size: geo.size, R: R) }
        }
    }
}

// MARK: - Seeded data types

private extension PortalFaceContent {

    struct Particle {
        let x:        CGFloat
        let y:        CGFloat
        let driftA:   Double
        let driftSpd: Double
        let radius:   CGFloat
        let opacity:  Double
        let phase:    Double
    }

    struct Fleck {
        let x:      CGFloat
        let y:      CGFloat
        let period: Double
        let phase:  Double
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

private extension PortalFaceContent {

    func drawBase(context: GraphicsContext, size: CGSize, R: CGFloat) {
        let path = Path(roundedRect: CGRect(origin: .zero, size: size),
                        cornerRadius: R)
        context.fill(
            path,
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color(red: 0.031, green: 0.016, blue: 0.094), location: 0.00),
                    .init(color: Color(red: 0.051, green: 0.024, blue: 0.157), location: 0.45),
                    .init(color: Color(red: 0.016, green: 0.008, blue: 0.055), location: 1.00),
                ]),
                center:      CGPoint(x: size.width / 2, y: size.height / 2),
                startRadius: 0,
                endRadius:   max(size.width, size.height) * 0.72
            )
        )
    }
}

// MARK: - Layer 1: Swirl

private extension PortalFaceContent {

    func drawSwirl(context: GraphicsContext, size: CGSize, deepT: Double) {
        let W  = size.width
        let H  = size.height
        let cx = W / 2
        let cy = H / 2

        let angle1 = deepT * ((.pi * 2) / 10.0)
        let angle2 = deepT * ((.pi * 2) / 13.5) + .pi

        let orbitR: CGFloat = min(W, H) * 0.18

        let c1 = CGPoint(x: cx + cos(angle1) * orbitR, y: cy + sin(angle1) * orbitR * 0.55)
        let c2 = CGPoint(x: cx + cos(angle2) * orbitR, y: cy + sin(angle2) * orbitR * 0.55)

        let rect = Path(CGRect(origin: .zero, size: size))

        context.fill(rect, with: .radialGradient(
            Gradient(stops: [
                .init(color: Color(red: 0.102, green: 0.039, blue: 0.251).opacity(0.14), location: 0),
                .init(color: Color(red: 0.063, green: 0.016, blue: 0.188).opacity(0.06), location: 0.55),
                .init(color: .clear, location: 1),
            ]),
            center: c1, startRadius: 0, endRadius: min(W, H) * 0.55
        ))

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

private extension PortalFaceContent {

    func drawParticles(context: GraphicsContext, size: CGSize, deepT: Double) {
        let W = size.width
        let H = size.height
        let fadeIn = min(1.0, deepT / 1.50)
        guard fadeIn > 0 else { return }

        for p in particles {
            let driftX = (cos(p.driftA) * p.driftSpd * deepT).truncatingRemainder(dividingBy: 1.0)
            let driftY = (sin(p.driftA) * p.driftSpd * deepT).truncatingRemainder(dividingBy: 1.0)
            var nx = (p.x + driftX).truncatingRemainder(dividingBy: 1.0)
            var ny = (p.y + driftY).truncatingRemainder(dividingBy: 1.0)
            if nx < 0 { nx += 1 }
            if ny < 0 { ny += 1 }

            let px = nx * W
            let py = ny * H

            let tw = 0.65 + 0.35 * sin(deepT * 0.75 + p.phase)
            let a  = p.opacity * tw * fadeIn

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

private extension PortalFaceContent {

    func drawShimmer(context: GraphicsContext, size: CGSize, deepT: Double) {
        let W = size.width
        let H = size.height
        let fadeIn = min(1.0, deepT / 0.80)
        guard fadeIn > 0 else { return }

        for f in flecks {
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

private extension PortalFaceContent {

    func drawDepthGlow(context: GraphicsContext, size: CGSize, deepT: Double) {
        let cx = size.width  / 2
        let cy = size.height / 2

        let fadeIn  = min(1.0, deepT / 0.90)
        let breathe = 0.45 + 0.55 * pow(0.50 + 0.50 * sin(deepT * (.pi * 2 / 3.60)), 1.8)
        let gA      = fadeIn * breathe

        let r = min(size.width, size.height) / 2

        context.fill(
            Path(ellipseIn: CGRect(x: cx - r * 0.55, y: cy - r * 0.55,
                                   width: r * 1.10, height: r * 1.10)),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color(red: 0.227, green: 0.059, blue: 0.541).opacity(gA * 0.22), location: 0),
                    .init(color: Color(red: 0.424, green: 0.227, blue: 0.878).opacity(gA * 0.10), location: 0.5),
                    .init(color: .clear, location: 1),
                ]),
                center: CGPoint(x: cx, y: cy),
                startRadius: 0,
                endRadius: r * 0.55
            )
        )

        context.fill(
            Path(ellipseIn: CGRect(x: cx - r * 0.22, y: cy - r * 0.22,
                                   width: r * 0.44, height: r * 0.44)),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color(red: 0.424, green: 0.227, blue: 0.878).opacity(gA * 0.50), location: 0),
                    .init(color: Color(red: 0.424, green: 0.227, blue: 0.878).opacity(gA * 0.18), location: 0.5),
                    .init(color: .clear, location: 1),
                ]),
                center: CGPoint(x: cx, y: cy),
                startRadius: 0,
                endRadius: r * 0.22
            )
        )

        context.fill(
            Path(ellipseIn: CGRect(x: cx - r * 0.08, y: cy - r * 0.08,
                                   width: r * 0.16, height: r * 0.16)),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color(red: 0.753, green: 0.659, blue: 1.0).opacity(gA * 0.88), location: 0),
                    .init(color: Color(red: 0.424, green: 0.227, blue: 0.878).opacity(gA * 0.50), location: 0.5),
                    .init(color: .clear, location: 1),
                ]),
                center: CGPoint(x: cx, y: cy),
                startRadius: 0,
                endRadius: r * 0.08
            )
        )

        context.fill(
            Path(ellipseIn: CGRect(x: cx - 1.2, y: cy - 1.2, width: 2.4, height: 2.4)),
            with: .color(Color(red: 0.902, green: 0.863, blue: 1.0).opacity(gA * 0.70))
        )
    }
}

// MARK: - DeepCardShell

/// Spectrum shell overlay — same visual language as VaylCardFace.
private struct DeepCardShell: View {
    let size: CGSize
    let R:    CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: R)
                .stroke(AppColors.spectrumPurple.opacity(0.18), lineWidth: 1)
                .blur(radius: 20)

            RoundedRectangle(cornerRadius: R)
                .strokeBorder(AppColors.spectrumBorder, lineWidth: 1.1)
                .opacity(0.52)
                .padding(0.75)

            RoundedRectangle(cornerRadius: R - 4)
                .strokeBorder(AppColors.spectrumBorder, lineWidth: 0.55)
                .opacity(0.22)
                .padding(9)

            Path { p in
                p.move(to:    CGPoint(x: 14,              y: 0.75))
                p.addLine(to: CGPoint(x: size.width - 14, y: 0.75))
            }
            .stroke(AppColors.spectrumBorder.opacity(0.60), lineWidth: 1.2)
            .frame(width: size.width, height: size.height)

            Path { p in
                p.move(to:    CGPoint(x: 14,              y: size.height - 0.75))
                p.addLine(to: CGPoint(x: size.width - 14, y: size.height - 0.75))
            }
            .stroke(AppColors.spectrumBorder.opacity(0.60), lineWidth: 1.2)
            .frame(width: size.width, height: size.height)

            ZStack {
                ForEach([
                    CGPoint(x: 16,               y: 16),
                    CGPoint(x: size.width - 16,  y: 16),
                    CGPoint(x: 16,               y: size.height - 16),
                    CGPoint(x: size.width - 16,  y: size.height - 16),
                ], id: \.debugDescription) { pt in
                    Text("✦")
                        .font(AppFonts.label)
                        .foregroundStyle(Color.white.opacity(0.12))
                        .position(pt)
                }
            }
            .frame(width: size.width, height: size.height)
        }
    }
}

// MARK: - Preview

#Preview("Portal Face — resting") {
    ZStack {
        Color.black.ignoresSafeArea()
        PortalFaceContent(startDate: Date().addingTimeInterval(-2.0))
            .frame(width: 260, height: 385)
            .drawingGroup()
    }
    .preferredColorScheme(.dark)
}
