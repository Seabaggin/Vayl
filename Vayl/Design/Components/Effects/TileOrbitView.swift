//
//  TileOrbitView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/29/26.
//


// Design/Components/Effects/TileOrbitView.swift
// Open Lightly
//
// Purpose-built comet orbit animation for small tile contexts (44–88pt).
// Drives the mode selection visual in OnboardingModeSelectView.
//
// API:
//   TileOrbitView(orbitCount: 1, isActive: false)  — resting arc
//   TileOrbitView(orbitCount: 2, isActive: true)   — animated comet orbits
//
// Resting state: static arc indicators per orbit count.
//   1 orbit → single 120° arc
//   2 orbits → two offset arcs
//   3 orbits → three full dim rings
//
// Active state: TimelineView-driven comet orbits.
//   Each orbit has a phase offset, radius differential, and speed
//   differential so they never stack. All orbits cycle through
//   cyan → magenta → purple, each offset by one color step so
//   no two orbits share a color at any given frame.
//
// Color cycling:
//   Three AppColors tokens used as cycle anchors:
//     AppColors.accentPrimary    (#00C2FF)
//     AppColors.accentTertiary (#FF006A)
//     AppColors.accentSecondary  (#6C3AE0)
//   Light mode uses the warm aurora equivalents:
//     AppColors.accentTertiary → AppColors.progressBarLeading → AppColors.accentSecondary
//
// Performance:
//   No state objects. No trail history. No pattern cycling.
//   TimelineView capped at 60fps via .animation schedule.
//   Canvas drawing only — no SwiftUI view tree overhead.
//   Zero GPU cost in resting state (no TimelineView mounted).

import SwiftUI

// MARK: - TileOrbitView

struct TileOrbitView: View {

    var orbitCount: Int     = 1      // 1, 2, or 3
    var isActive:   Bool    = false  // resting arc vs. animated comet
    var speed:      Double  = 1.0    // global speed multiplier
    var size:       CGFloat = 72     // canvas dimension in points
    var glowScale:  Double  = 1.0    // reduce for tight contexts like card backs

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Color cycle anchors

    // Dark:  cyan → magenta → purple
    // Light: magenta → orangeHot → purple
    private var cycleColors: [Color] {
        isLight
            ? [AppColors.accentTertiary, AppColors.progressBarLeading, AppColors.accentSecondary]
            : [AppColors.accentPrimary,  AppColors.accentTertiary,     AppColors.accentSecondary]
    }

    // MARK: - Orbit geometry constants

    // Radii as fractions of baseR — outer to inner
    private let radiiFactors: [Double] = [1.00, 0.65, 0.32]

    // Fixed phase offsets guarantee heads never meet.
    // 2 orbits: π apart — always opposite sides of the ring.
    // 3 orbits: 2π/3 apart — always 120° apart.
    private let phaseOffsets: [Double] = [0, .pi, .pi * 4 / 3]
    
    private let speedMultipliers: [Double] = [1.00, 1.00, 1.00]

    // Color index offset per orbit — never same color simultaneously
    private let colorOffsets: [Int] = [0, 1, 2]

    // MARK: - Body

    var body: some View {
        if isActive {
            TimelineView(.animation) { tl in
                Canvas { context, canvasSize in
                    let elapsed = tl.date.timeIntervalSinceReferenceDate
                    drawActive(
                        context:   &context,
                        size:      canvasSize,
                        elapsed:   elapsed
                    )
                }
                .frame(width: size, height: size)
            }
        } else {
            Canvas { context, canvasSize in
                drawResting(context: &context, size: canvasSize)
            }
            .frame(width: size, height: size)
        }
    }

    // MARK: - Resting Draw

    private func drawResting(
        context: inout GraphicsContext,
        size:    CGSize
    ) {
        let cx     = size.width  / 2
        let cy     = size.height / 2
        let baseR  = Double(size.width) * 0.36
        let stroke = StrokeStyle(lineWidth: 1.0, lineCap: .round)
        let color = isLight
            ? AppColors.borderSubtle.opacity(0.28)
            : AppColors.borderSubtle.opacity(0.28)

        switch orbitCount {

        case 1:
            // Single 120° arc — top of circle
            var arc = Path()
            arc.addArc(
                center:     CGPoint(x: cx, y: cy),
                radius:     baseR,
                startAngle: .degrees(-150),
                endAngle:   .degrees(-30),
                clockwise:  false
            )
            context.stroke(arc, with: .color(color), style: stroke)

        case 2:
            // Two offset arcs at different radii
            var arc1 = Path()
            arc1.addArc(
                center:     CGPoint(x: cx, y: cy),
                radius:     baseR * radiiFactors[0],
                startAngle: .degrees(-140),
                endAngle:   .degrees(20),
                clockwise:  false
            )
            context.stroke(arc1, with: .color(color), style: stroke)

            var arc2 = Path()
            arc2.addArc(
                center:     CGPoint(x: cx, y: cy),
                radius:     baseR * radiiFactors[1],
                startAngle: .degrees(-40),
                endAngle:   .degrees(120),
                clockwise:  false
            )
            context.stroke(arc2, with: .color(color), style: stroke)

        default:
            // Three full dim rings at decreasing radii
            for i in 0 ..< 3 {
                var ring = Path()
                ring.addEllipse(in: CGRect(
                    x: cx - baseR * radiiFactors[i],
                    y: cy - baseR * radiiFactors[i],
                    width:  baseR * radiiFactors[i] * 2,
                    height: baseR * radiiFactors[i] * 2
                ))
                context.stroke(
                    ring,
                    with: .color(isLight
                        ? AppColors.borderSubtle.opacity(0.18)
                        : AppColors.borderSubtle.opacity(0.18)),
                    style: stroke
                )
            }
        }
    }

    // MARK: - Active Draw

    private func drawActive(
        context: inout GraphicsContext,
        size:    CGSize,
        elapsed: Double
    ) {
        let cx    = size.width  / 2
        let cy    = size.height / 2
        let baseR = Double(size.width) * 0.36

        // Global angle — advances with time and speed multiplier
        let angle = elapsed * 2.6 * speed

        // Color cycle — full rotation over ~6 seconds
        let cyclePeriod: Double = 6.0
        let cycleRaw    = elapsed.truncatingRemainder(dividingBy: cyclePeriod)
        let cyclePhase  = cycleRaw / cyclePeriod   // 0.0 → 1.0
        let colorCount  = Double(cycleColors.count)
        let colorPos   = cyclePhase * colorCount
        let colorIndex = Int(colorPos) % cycleColors.count
        let colorFrac  = colorPos - Double(Int(colorPos))

        // Lerp the entire orbit color as a single unit.
        // All parts of the orbit — ring, tail, head — use this one value.
        func orbitColor(forIndex i: Int) -> Color {
            let base = cycleColors[(colorIndex + colorOffsets[i]) % cycleColors.count]
            let next = cycleColors[(colorIndex + colorOffsets[i] + 1) % cycleColors.count]
            // Simple crossfade — colorFrac drives the whole orbit simultaneously
            return colorFrac < 0.5 ? base : next
        }

        for i in 0 ..< orbitCount {
            let orbitR   = baseR * radiiFactors[i]
            let orbSpeed = speedMultipliers[i]
            let phaseOff = phaseOffsets[i]
            let headAngle = angle * orbSpeed + phaseOff

            // Dim full ring
            var ring = Path()
            ring.addEllipse(in: CGRect(
                x: cx - orbitR, y: cy - orbitR,
                width: orbitR * 2, height: orbitR * 2
            ))
            context.stroke(
                ring,
                with: .color(orbitColor(forIndex: i).opacity(0.07)),
                style: StrokeStyle(lineWidth: 1.0)
            )

            // Comet tail — segment-by-segment for opacity gradient
                let tailArc:   Double = .pi * 1.4
                let tailSteps: Int    = 80

            for s in 0 ..< tailSteps {
                let t      = Double(s) / Double(tailSteps)
                let segA   = headAngle - tailArc * (1.0 - t)
                let alpha  = t * 0.52
                let width  = 0.5 + t * 0.9

                let x1 = cx + cos(segA - 0.015) * orbitR
                let y1 = cy + sin(segA - 0.015) * orbitR
                let x2 = cx + cos(segA) * orbitR
                let y2 = cy + sin(segA) * orbitR

                var seg = Path()
                seg.move(to:    CGPoint(x: x1, y: y1))
                seg.addLine(to: CGPoint(x: x2, y: y2))

                context.stroke(
                    seg,
                    with: .color(orbitColor(forIndex: i).opacity(alpha)),
                    style: StrokeStyle(lineWidth: width, lineCap: .round)
                )
            }

            // Head glow — radial, accent color
            let hx   = cx + cos(headAngle) * orbitR
            let hy   = cy + sin(headAngle) * orbitR
            let glowR = Double(size.width) * 0.09 * glowScale

            let headGlow = Path(ellipseIn: CGRect(
                x: hx - glowR, y: hy - glowR,
                width: glowR * 2, height: glowR * 2
            ))
            context.fill(
                headGlow,
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: .white.opacity(0.90),                    location: 0.00),
                        .init(color: orbitColor(forIndex: i).opacity(0.70),   location: 0.28),
                        .init(color: orbitColor(forIndex: i).opacity(0.00),   location: 1.00),
                    ]),
                    center:      CGPoint(x: hx, y: hy),
                    startRadius: 0,
                    endRadius:   glowR
                )
            )

            // White-hot dot
            let dotR = 1.8
            context.fill(
                Path(ellipseIn: CGRect(
                    x: hx - dotR, y: hy - dotR,
                    width: dotR * 2, height: dotR * 2
                )),
                with: .color(.white.opacity(0.95))
            )
        }
    }
}

// MARK: - Previews

#Preview("Dark — all counts, resting") {
    HStack(spacing: AppSpacing.lg) {
        ForEach([1, 2, 3], id: \.self) { count in
            VStack(spacing: AppSpacing.sm) {
                TileOrbitView(orbitCount: count, isActive: false, size: 72)
                Text("\(count)")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }
    .padding(AppSpacing.xxl)
    .background(AppColors.pageBackground)
    .preferredColorScheme(.dark)
}

#Preview("Dark — all counts, active") {
    HStack(spacing: AppSpacing.lg) {
        ForEach([1, 2, 3], id: \.self) { count in
            VStack(spacing: AppSpacing.sm) {
                TileOrbitView(orbitCount: count, isActive: true, size: 72)
                Text("\(count)")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }
    .padding(AppSpacing.xxl)
    .background(AppColors.pageBackground)
    .preferredColorScheme(.dark)
}

#Preview("Light — all counts, active") {
    HStack(spacing: AppSpacing.lg) {
        ForEach([1, 2, 3], id: \.self) { count in
            VStack(spacing: AppSpacing.sm) {
                TileOrbitView(orbitCount: count, isActive: true, size: 72)
                Text("\(count)")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }
    .padding(AppSpacing.xxl)
    .background(AppColors.pageBackground)
    .preferredColorScheme(.light)
}

#Preview("Tap to activate") {
    @Previewable @State var active = false
    VStack(spacing: AppSpacing.lg) {
        TileOrbitView(orbitCount: 2, isActive: active, size: 88)
        Button(active ? "Deactivate" : "Activate") {
            withAnimation(AppAnimation.standard) { active.toggle() }
        }
        .font(AppFonts.caption)
        .foregroundStyle(AppColors.textSecondary)
    }
    .padding(AppSpacing.xxl)
    .background(AppColors.pageBackground)
    .preferredColorScheme(.dark)
}
