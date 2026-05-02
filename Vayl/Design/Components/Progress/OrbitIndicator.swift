// OrbitIndicator.swift
// Open Lightly
//
// Reusable orbit state indicator — extracted from OnboardingBuildingPathView.
// Used anywhere a three-state (pending → processing → complete) loading flow
// requires visual feedback with an animated comet tail orbit.
//
// USAGE
//
// Basic:
//   OrbitIndicator(state: .processing)
//   OrbitIndicator(state: .complete)
//   OrbitIndicator(state: .pending, size: 32)
//
// Driven by external state:
//   @State private var loadState: OrbitIndicatorState = .pending
//   OrbitIndicator(state: loadState)
//
// In a list row (matches OnboardingBuildingPathView pattern):
//   HStack(spacing: 14) {
//       OrbitIndicator(state: rowState)
//           .fixedSize()
//       VStack(alignment: .leading) { ... }
//   }
//
// Sizes:
//   22pt — default, matches onboarding build list
//   32pt — medium, standalone loading state
//   44pt — large, full-screen loading indicator
//
// Accessibility:
//   Wrap in an accessibilityElement with a dynamic label:
//   .accessibilityLabel(state == .complete ? "Complete" : "Loading")
//   .accessibilityAddTraits(state == .complete ? .isStaticText : [])
//
// ANIMATION NOTES
//
// BUG-3 FIX (OrbitIndicator): _OrbitCanvas previously used
// GraphicsContext.Shading.radialGradient for the spark head.
// That shading is silently discarded by the Xcode preview canvas
// renderer, making the spark invisible in previews. The spark now
// uses .color(opacity:) shading — identical to BPOrbitCanvas —
// which renders correctly in both the simulator and the preview canvas.

import SwiftUI

// MARK: - State Enum

/// Three-state indicator lifecycle.
public enum OrbitIndicatorState: Equatable {
    case pending      // static ring — zero GPU cost
    case processing   // animated comet orbit
    case complete     // gradient fill + glow, orbit dissolves
}

// MARK: - Public View

/// Reusable orbit state indicator for three-state async flows.
public struct OrbitIndicator: View {
    public let state: OrbitIndicatorState
    public var size: CGFloat = 22

    @State private var sheenOffset:    CGFloat = -1.5
    @State private var sheenAnimating: Bool    = false

    public init(state: OrbitIndicatorState, size: CGFloat = 22) {
        self.state = state
        self.size  = size
    }

    public var body: some View {
        ZStack {
            // LAYER 1 — Pending ring
            Circle()
                .strokeBorder(AppColors.borderSubtle, lineWidth: 1.5)
                .opacity(state == .pending ? 1 : 0)
                .animation(AppAnimation.standard, value: state == .pending)

            // LAYER 2 — Orbit canvas
            if state == .processing {
                _OrbitCanvas(size: size)
                    .transition(.opacity)
            }

            // LAYER 3 — Complete fill
            Circle()
                .fill(LinearGradient(
                    colors: [AppColors.accentPrimary, AppColors.accentSecondary, AppColors.accentTertiary],
                    startPoint: .topLeading,
                    endPoint:   .bottomTrailing
                ))
                .opacity(state == .complete ? 1 : 0)
                .animation(AppAnimation.spring, value: state == .complete)

            // LAYER 4 — Complete glow
            if state == .complete {
                Circle()
                    .fill(Color.clear)
                    .shadow(color: AppColors.accentPrimary,                 radius: 5,  x: 0, y: 0)
                    .shadow(color: AppColors.accentTertiary,                radius: 11, x: 0, y: 0)
                    .shadow(color: AppColors.accentSecondary.opacity(0.13), radius: 18, x: 0, y: 0)
                    .animation(AppAnimation.spring, value: state == .complete)
            }

            // LAYER 5 — Holographic sheen (complete state only)
            if state == .complete {
                Circle()
                    .fill(Color.clear)
                    .overlay {
                        LinearGradient(
                            stops: [
                                .init(color: .clear,                    location: 0.00),
                                .init(color: .clear,                    location: 0.25),
                                .init(color: Color.white.opacity(0.35), location: 0.38),
                                .init(color: Color.white.opacity(0.00), location: 0.45),
                                .init(color: .clear,                    location: 0.55),
                                .init(color: Color.white.opacity(0.20), location: 0.65),
                                .init(color: .clear,                    location: 0.72),
                                .init(color: .clear,                    location: 1.00),
                            ],
                            startPoint: UnitPoint(x: -0.1, y:  1.0),
                            endPoint:   UnitPoint(x:  1.1, y: -0.25)
                        )
                        .frame(width: size * 2.5)
                        .offset(x: sheenOffset * (size * 2.5))
                        .mask { Circle() }
                    }
                    .clipShape(Circle())
                    .allowsHitTesting(false)
                    .onAppear {
                        guard !sheenAnimating else { return }
                        sheenAnimating = true
                        // Sheen sweep — 4.0s matches AppAnimation.ambientDrift exactly.
                        withAnimation(
                            .easeInOut(duration: AppAnimation.ambientDrift)
                            .repeatForever(autoreverses: true)
                        ) {
                            sheenOffset = 1.5
                        }
                    }
                    .onDisappear {
                        sheenAnimating = false
                        sheenOffset    = -1.5
                    }
            }
        }
        .frame(width: size, height: size)
        .onChange(of: state) { _, newState in
            if newState != .complete {
                sheenAnimating = false
                sheenOffset    = -1.5
            }
        }
    }
}

// MARK: - Private Orbit Canvas

private struct _OrbitCanvas: View {
    let size: CGFloat

    private let revolutionDuration: TimeInterval = 1.4

    private var primaryRGB: (r: Double, g: Double, b: Double) {
        components(of: AppColors.accentPrimary)
    }
    private var secondaryRGB: (r: Double, g: Double, b: Double) {
        components(of: AppColors.accentSecondary)
    }
    private var tertiaryRGB: (r: Double, g: Double, b: Double) {
        components(of: AppColors.accentTertiary)
    }

    private let sparkOuter: Color = AppColors.accentTertiary
    private let sparkInner: Color = AppColors.accentPrimary

    var body: some View {
        let pRGB        = primaryRGB
        let sRGB        = secondaryRGB
        let tRGB        = tertiaryRGB
        let outer       = sparkOuter
        let inner       = sparkInner
        let borderColor: Color = AppColors.borderSubtle

        TimelineView(.animation) { timeline in
            Canvas { context, canvasSize in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: revolutionDuration)
                let progress = elapsed / revolutionDuration
                drawOrbit(
                    context:     context,
                    size:        canvasSize,
                    progress:    progress,
                    pRGB:        pRGB,
                    sRGB:        sRGB,
                    tRGB:        tRGB,
                    sparkOuter:  outer,
                    sparkInner:  inner,
                    borderColor: borderColor
                )
            }
            .frame(width: size, height: size)
        }
    }

    private func drawOrbit(
        context:     GraphicsContext,
        size:        CGSize,
        progress:    Double,
        pRGB:        (r: Double, g: Double, b: Double),
        sRGB:        (r: Double, g: Double, b: Double),
        tRGB:        (r: Double, g: Double, b: Double),
        sparkOuter:  Color,
        sparkInner:  Color,
        borderColor: Color
    ) {
        let cx     = size.width  / 2
        let cy     = size.height / 2
        let radius = size.width  / 2 - 2.0
        let steps  = 28

        let headAngle = progress * .pi * 2 - .pi / 2
        let tailArc   = Double.pi * 0.88

        var borderPath = Path()
        borderPath.addEllipse(in: CGRect(
            x: cx - radius, y: cy - radius,
            width: radius * 2, height: radius * 2
        ))
        context.stroke(borderPath, with: .color(borderColor), lineWidth: 1.5)

        for i in 0..<steps {
            let t         = Double(i) / Double(steps - 1)
            let dotAngle  = headAngle - tailArc * (1.0 - t)
            let x         = cx + cos(dotAngle) * radius
            let y         = cy + sin(dotAngle) * radius
            let alpha     = t * 0.58
            let dotRadius = 0.9 + t * 0.65

            let color: Color
            if t < 0.4 {
                let blend = t / 0.4
                color = Color(
                    red:   lerp(pRGB.r, sRGB.r, blend),
                    green: lerp(pRGB.g, sRGB.g, blend),
                    blue:  lerp(pRGB.b, sRGB.b, blend)
                )
            } else {
                let blend = (t - 0.4) / 0.6
                color = Color(
                    red:   lerp(sRGB.r, tRGB.r, blend),
                    green: lerp(sRGB.g, tRGB.g, blend),
                    blue:  lerp(sRGB.b, tRGB.b, blend)
                )
            }

            var dotPath = Path()
            dotPath.addEllipse(in: CGRect(
                x: x - dotRadius, y: y - dotRadius,
                width: dotRadius * 2, height: dotRadius * 2
            ))
            context.fill(dotPath, with: .color(color.opacity(alpha)))
        }

        let hx = cx + cos(headAngle) * radius
        let hy = cy + sin(headAngle) * radius

        var outerPath = Path()
        outerPath.addEllipse(in: CGRect(
            x: hx - 5.5, y: hy - 5.5, width: 11, height: 11
        ))
        context.fill(outerPath, with: .color(sparkOuter.opacity(0.45)))

        var innerPath = Path()
        innerPath.addEllipse(in: CGRect(
            x: hx - 3, y: hy - 3, width: 6, height: 6
        ))
        context.fill(innerPath, with: .color(sparkInner.opacity(0.55)))

        var corePath = Path()
        corePath.addEllipse(in: CGRect(
            x: hx - 1.8, y: hy - 1.8, width: 3.6, height: 3.6
        ))
        context.fill(corePath, with: .color(.white.opacity(0.96)))
    }

    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * t
    }

    private func components(of color: Color) -> (r: Double, g: Double, b: Double) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }
}

// MARK: - Previews

#Preview("Dark Mode — Static Grid") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ScrollView {
            VStack(spacing: AppSpacing.xxl) {
                Text("ORBIT INDICATOR")
                    .font(AppFonts.meta)
                    .kerning(2.2)
                    .foregroundStyle(AppColors.textTertiary)

                // ── Three states at default size (22pt) ──────────────
                VStack(spacing: AppSpacing.md) {
                    Text("22pt — default")
                        .font(AppFonts.meta)
                        .kerning(1.8)
                        .foregroundStyle(AppColors.textTertiary)
                    HStack(spacing: AppSpacing.xl) {
                        VStack(spacing: AppSpacing.sm) {
                            OrbitIndicator(state: .pending)
                            Text("pending")
                                .font(AppFonts.meta)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: AppSpacing.sm) {
                            OrbitIndicator(state: .processing)
                            Text("processing")
                                .font(AppFonts.meta)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: AppSpacing.sm) {
                            OrbitIndicator(state: .complete)
                            Text("complete")
                                .font(AppFonts.meta)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }

                // ── Three states at medium size (32pt) ───────────────
                VStack(spacing: AppSpacing.md) {
                    Text("32pt — medium")
                        .font(AppFonts.meta)
                        .kerning(1.8)
                        .foregroundStyle(AppColors.textTertiary)
                    HStack(spacing: AppSpacing.xl) {
                        VStack(spacing: AppSpacing.sm) {
                            OrbitIndicator(state: .pending,    size: 32)
                            Text("pending")
                                .font(AppFonts.meta)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: AppSpacing.sm) {
                            OrbitIndicator(state: .processing, size: 32)
                            Text("processing")
                                .font(AppFonts.meta)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: AppSpacing.sm) {
                            OrbitIndicator(state: .complete,   size: 32)
                            Text("complete")
                                .font(AppFonts.meta)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }

                // ── Three states at large size (44pt) ────────────────
                VStack(spacing: AppSpacing.md) {
                    Text("44pt — large")
                        .font(AppFonts.meta)
                        .kerning(1.8)
                        .foregroundStyle(AppColors.textTertiary)
                    HStack(spacing: AppSpacing.xl) {
                        VStack(spacing: AppSpacing.sm) {
                            OrbitIndicator(state: .pending,    size: 44)
                            Text("pending")
                                .font(AppFonts.meta)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: AppSpacing.sm) {
                            OrbitIndicator(state: .processing, size: 44)
                            Text("processing")
                                .font(AppFonts.meta)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: AppSpacing.sm) {
                            OrbitIndicator(state: .complete,   size: 44)
                            Text("complete")
                                .font(AppFonts.meta)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }

                // ── In-row context ────────────────────────────────────
                VStack(spacing: AppSpacing.md) {
                    Text("IN-ROW CONTEXT")
                        .font(AppFonts.meta)
                        .kerning(1.8)
                        .foregroundStyle(AppColors.textTertiary)
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        HStack(spacing: AppSpacing.md) {
                            OrbitIndicator(state: .complete).fixedSize()
                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                Text("STARTING POINT")
                                    .font(AppFonts.meta)
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.textTertiary)
                                Text("Beginning from curiosity")
                                    .font(AppFonts.body(14, weight: .medium, relativeTo: .callout))
                                    .foregroundStyle(AppColors.textPrimary)
                            }
                        }
                        HStack(spacing: AppSpacing.md) {
                            OrbitIndicator(state: .processing).fixedSize()
                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                Text("YOUR SITUATION")
                                    .font(AppFonts.meta)
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.textTertiary)
                                Text("Opening the conversation")
                                    .font(AppFonts.body(14, weight: .regular, relativeTo: .callout))
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                        HStack(spacing: AppSpacing.md) {
                            OrbitIndicator(state: .pending).fixedSize()
                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                Text("FIRST TO EXPLORE")
                                    .font(AppFonts.meta)
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.textTertiary)
                                Text("Communication & connection")
                                    .font(AppFonts.body(14, weight: .regular, relativeTo: .callout))
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                }
            }
            .padding(AppSpacing.xl)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Dark Mode — Live Cycle") {
    @Previewable @State var cycleState: OrbitIndicatorState = .pending
    @Previewable @State var sizeIndex: Int = 1
    let sizes: [CGFloat] = [22, 32, 44]
    let sizeLabels = ["22pt", "32pt", "44pt"]

    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        VStack(spacing: AppSpacing.xl) {
            Text("LIVE CYCLE")
                .font(AppFonts.meta)
                .kerning(2.2)
                .foregroundStyle(AppColors.textTertiary)

            OrbitIndicator(state: cycleState, size: sizes[sizeIndex])

            Text(cycleState == .pending    ? "pending"    :
                 cycleState == .processing ? "processing" : "complete")
                .font(AppFonts.overline)
                .kerning(1.6)
                .foregroundStyle(AppColors.textTertiary)
                .animation(.none, value: cycleState)

            HStack(spacing: 0) {
                ForEach(0..<3) { i in
                    Button(sizeLabels[i]) { sizeIndex = i }
                        .font(AppFonts.caption)
                        .foregroundStyle(sizeIndex == i
                            ? AppColors.accentPrimary
                            : AppColors.textTertiary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                }
            }
            .background(AppColors.cardBackground)
            .clipShape(Capsule())
        }
    }
    .preferredColorScheme(.dark)
    .task {
        while true {
            try? await Task.sleep(for: .seconds(1.0))
            withAnimation(AppAnimation.standard) { cycleState = .processing }
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(AppAnimation.spring)   { cycleState = .complete   }
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(AppAnimation.standard) { cycleState = .pending    }
        }
    }
}

#Preview("Light Mode — Static Grid") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ScrollView {
            VStack(spacing: AppSpacing.xxl) {
                Text("ORBIT INDICATOR")
                    .font(AppFonts.meta)
                    .kerning(2.2)
                    .foregroundStyle(AppColors.textTertiary)

                VStack(spacing: AppSpacing.md) {
                    Text("22pt — default")
                        .font(AppFonts.meta)
                        .kerning(1.8)
                        .foregroundStyle(AppColors.textTertiary)
                    HStack(spacing: AppSpacing.xl) {
                        VStack(spacing: AppSpacing.sm) {
                            OrbitIndicator(state: .pending)
                            Text("pending")
                                .font(AppFonts.meta)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: AppSpacing.sm) {
                            OrbitIndicator(state: .processing)
                            Text("processing")
                                .font(AppFonts.meta)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: AppSpacing.sm) {
                            OrbitIndicator(state: .complete)
                            Text("complete")
                                .font(AppFonts.meta)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }

                VStack(spacing: AppSpacing.md) {
                    Text("32pt — medium")
                        .font(AppFonts.meta)
                        .kerning(1.8)
                        .foregroundStyle(AppColors.textTertiary)
                    HStack(spacing: AppSpacing.xl) {
                        VStack(spacing: AppSpacing.sm) {
                            OrbitIndicator(state: .pending,    size: 32)
                            Text("pending")
                                .font(AppFonts.meta)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: AppSpacing.sm) {
                            OrbitIndicator(state: .processing, size: 32)
                            Text("processing")
                                .font(AppFonts.meta)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: AppSpacing.sm) {
                            OrbitIndicator(state: .complete,   size: 32)
                            Text("complete")
                                .font(AppFonts.meta)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }

                VStack(spacing: AppSpacing.md) {
                    Text("44pt — large")
                        .font(AppFonts.meta)
                        .kerning(1.8)
                        .foregroundStyle(AppColors.textTertiary)
                    HStack(spacing: AppSpacing.xl) {
                        VStack(spacing: AppSpacing.sm) {
                            OrbitIndicator(state: .pending,    size: 44)
                            Text("pending")
                                .font(AppFonts.meta)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: AppSpacing.sm) {
                            OrbitIndicator(state: .processing, size: 44)
                            Text("processing")
                                .font(AppFonts.meta)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: AppSpacing.sm) {
                            OrbitIndicator(state: .complete,   size: 44)
                            Text("complete")
                                .font(AppFonts.meta)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }

                VStack(spacing: AppSpacing.md) {
                    Text("IN-ROW CONTEXT")
                        .font(AppFonts.meta)
                        .kerning(1.8)
                        .foregroundStyle(AppColors.textTertiary)
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        HStack(spacing: AppSpacing.md) {
                            OrbitIndicator(state: .complete).fixedSize()
                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                Text("STARTING POINT")
                                    .font(AppFonts.meta)
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.textTertiary)
                                Text("Beginning from curiosity")
                                    .font(AppFonts.body(14, weight: .medium, relativeTo: .callout))
                                    .foregroundStyle(AppColors.textPrimary)
                            }
                        }
                        HStack(spacing: AppSpacing.md) {
                            OrbitIndicator(state: .processing).fixedSize()
                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                Text("YOUR SITUATION")
                                    .font(AppFonts.meta)
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.textTertiary)
                                Text("Opening the conversation")
                                    .font(AppFonts.body(14, weight: .regular, relativeTo: .callout))
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                        HStack(spacing: AppSpacing.md) {
                            OrbitIndicator(state: .pending).fixedSize()
                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                Text("FIRST TO EXPLORE")
                                    .font(AppFonts.meta)
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.textTertiary)
                                Text("Communication & connection")
                                    .font(AppFonts.body(14, weight: .regular, relativeTo: .callout))
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                }
            }
            .padding(AppSpacing.xl)
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Light Mode — Live Cycle") {
    @Previewable @State var cycleState: OrbitIndicatorState = .pending
    @Previewable @State var sizeIndex: Int = 1
    let sizes: [CGFloat] = [22, 32, 44]
    let sizeLabels = ["22pt", "32pt", "44pt"]

    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        VStack(spacing: AppSpacing.xl) {
            Text("LIVE CYCLE")
                .font(AppFonts.meta)
                .kerning(2.2)
                .foregroundStyle(AppColors.textTertiary)

            OrbitIndicator(state: cycleState, size: sizes[sizeIndex])

            Text(cycleState == .pending    ? "pending"    :
                 cycleState == .processing ? "processing" : "complete")
                .font(AppFonts.overline)
                .kerning(1.6)
                .foregroundStyle(AppColors.textTertiary)
                .animation(.none, value: cycleState)

            HStack(spacing: 0) {
                ForEach(0..<3) { i in
                    Button(sizeLabels[i]) { sizeIndex = i }
                        .font(AppFonts.caption)
                        .foregroundStyle(sizeIndex == i
                            ? AppColors.accentSecondary
                            : AppColors.textTertiary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                }
            }
            .background(AppColors.cardBackground)
            .clipShape(Capsule())
        }
    }
    .preferredColorScheme(.light)
    .task {
        while true {
            try? await Task.sleep(for: .seconds(1.0))
            withAnimation(AppAnimation.standard) { cycleState = .processing }
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(AppAnimation.spring)   { cycleState = .complete   }
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(AppAnimation.standard) { cycleState = .pending    }
        }
    }
}
