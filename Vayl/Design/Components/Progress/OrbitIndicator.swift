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
///
/// Animates smoothly between pending (static ring), processing (comet orbit),
/// and complete (gradient fill + glow). Uses the project's dark mode color spectrum
/// (cyan → purple → magenta) and follows PillBorder.swift's TimelineView + Canvas architecture.
/// All colors derived from AppColors tokens.
public struct OrbitIndicator: View {
    public let state: OrbitIndicatorState
    public var size: CGFloat = 22
    
    @State private var sheenOffset: CGFloat = -1.5
    @State private var sheenAnimating: Bool = false

    public init(
        state: OrbitIndicatorState,
        size: CGFloat = 22
    ) {
        self.state = state
        self.size = size
    }

    public var body: some View {
        ZStack {
            // LAYER 1 — Pending ring
            Circle()
                .strokeBorder(AppColors.border, lineWidth: 1.5)
                .opacity(state == .pending ? 1 : 0)
                .animation(.easeOut(duration: 0.3), value: state == .pending)

            // LAYER 2 — Orbit canvas
            //
            // Wrapped in withAnimation context at call sites so the
            // .transition(.opacity) fires correctly when state changes.
            if state == .processing {
                _OrbitCanvas(size: size)
                    .transition(.opacity)
            }

            // LAYER 3 — Complete fill
            // Dark mode spectrum: cyan → purple → magenta
            Circle()
                .fill(LinearGradient(
                    colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .opacity(state == .complete ? 1 : 0)
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.6),
                    value: state == .complete
                )

            // LAYER 4 — Complete glow
            if state == .complete {
                Circle()
                    .fill(Color.clear)
                    .shadow(
                        color: AppColors.cyan,
                        radius: 5,
                        x: 0, y: 0
                    )
                    .shadow(
                        color: AppColors.magenta,
                        radius: 11,
                        x: 0, y: 0
                    )
                    .shadow(
                        color: AppColors.purple.opacity(0.13),
                        radius: 18,
                        x: 0, y: 0
                    )
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.6),
                        value: state == .complete
                    )
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
                            startPoint: UnitPoint(x: -0.1, y: 1.0),
                            endPoint:   UnitPoint(x: 1.1,  y: -0.25)
                        )
                        // Scale the sweep to the circle diameter.
                        // StatView uses 320pt for a ~140pt text block (2.3× ratio).
                        // A 22pt circle uses 50pt sweep for the same visual ratio.
                        .frame(width: size * 2.5)
                        .offset(x: sheenOffset * (size * 2.5))
                        .mask { Circle() }
                    }
                    .clipShape(Circle())
                    .allowsHitTesting(false)
                    .onAppear {
                        guard !sheenAnimating else { return }
                        sheenAnimating = true
                        withAnimation(
                            .easeInOut(duration: 4)
                            .repeatForever(autoreverses: true)
                        ) {
                            sheenOffset = 1.5
                        }
                    }
                    .onDisappear {
                        sheenAnimating = false
                        sheenOffset = -1.5
                    }
            }
        }
        .frame(width: size, height: size)
        .onChange(of: state) { _, newState in
            if newState != .complete {
                sheenAnimating = false
                sheenOffset = -1.5
            }
        }
    }
}

// MARK: - Private Orbit Canvas

/// TimelineView + Canvas orbit renderer.
/// Draws a 28-dot comet tail orbiting the circle perimeter with a
/// spark head using flat-color opacity shading.
///
/// Architecture mirrors PillBorder.swift: conditional mounting,
/// TimelineView(.animation) for frame-perfect timing, Canvas for
/// direct GPU drawing.
///
/// BUG-3 FIX: spark head previously used radialGradient shading, which
/// the Xcode preview canvas renderer silently discards, making the spark
/// invisible in previews. Now uses .color(opacity:) — matching
/// BPOrbitCanvas — which renders correctly everywhere.
///
/// Color: Dark mode only — comet trail lerps cyan → purple → magenta.
/// RGB components resolved dynamically from AppColors tokens via UIColor.
private struct _OrbitCanvas: View {
    let size: CGFloat

    private let revolutionDuration: TimeInterval = 1.4

    // Pre-resolved RGB triples for the three anchor colors.
    // Dark mode: cyan → purple → magenta spectrum
    private var primaryRGB: (r: Double, g: Double, b: Double) {
        components(of: AppColors.cyan)
    }
    private var secondaryRGB: (r: Double, g: Double, b: Double) {
        components(of: AppColors.purple)
    }
    private var tertiaryRGB: (r: Double, g: Double, b: Double) {
        components(of: AppColors.magenta)
    }

    // Spark head colors — dark mode only
    // BUG-3 FIX: used as .color(opacity:) shading in Canvas,
    // NOT as radialGradient shading (which breaks in preview renderer).
    private let sparkOuter: Color = AppColors.magenta
    private let sparkInner: Color = AppColors.cyan

    var body: some View {
        // Capture resolved values before entering Canvas closure.
        // Canvas closures have no Environment access.
        let pRGB        = primaryRGB
        let sRGB        = secondaryRGB
        let tRGB        = tertiaryRGB
        let outer       = sparkOuter
        let inner       = sparkInner
        let borderColor: Color = AppColors.borderHover

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

        // Border ring
        var borderPath = Path()
        borderPath.addEllipse(in: CGRect(
            x: cx - radius, y: cy - radius,
            width: radius * 2, height: radius * 2
        ))
        context.stroke(borderPath, with: .color(borderColor), lineWidth: 1.5)

        // Trailing dot loop — lerps across three anchor colors
        for i in 0..<steps {
            let t         = Double(i) / Double(steps - 1)
            let dotAngle  = headAngle - tailArc * (1.0 - t)
            let x         = cx + cos(dotAngle) * radius
            let y         = cy + sin(dotAngle) * radius
            let alpha     = t * 0.58
            let dotRadius = 0.9 + t * 0.65

            // Lerp between the three anchor colors:
            //   t < 0.40 → primary → secondary
            //   t ≥ 0.40 → secondary → tertiary
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

        // Spark head — three flat-color opacity layers.
        //
        // BUG-3 FIX: previously used GraphicsContext.Shading.radialGradient,
        // which is silently discarded by the Xcode preview canvas renderer,
        // making the spark invisible in previews. Now uses .color(opacity:)
        // shading — identical to BPOrbitCanvas — which renders correctly in
        // both the simulator and the Xcode preview canvas.
        let hx = cx + cos(headAngle) * radius
        let hy = cy + sin(headAngle) * radius

        // Outer glow — tertiary accent, large halo
        var outerPath = Path()
        outerPath.addEllipse(in: CGRect(
            x: hx - 5.5, y: hy - 5.5,
            width: 11, height: 11
        ))
        context.fill(outerPath, with: .color(sparkOuter.opacity(0.45)))

        // Inner glow — primary accent, tighter focus
        var innerPath = Path()
        innerPath.addEllipse(in: CGRect(
            x: hx - 3, y: hy - 3,
            width: 6, height: 6
        ))
        context.fill(innerPath, with: .color(sparkInner.opacity(0.55)))

        // Core — white focal point
        var corePath = Path()
        corePath.addEllipse(in: CGRect(
            x: hx - 1.8, y: hy - 1.8,
            width: 3.6, height: 3.6
        ))
        context.fill(corePath, with: .color(.white.opacity(0.96)))
    }

    // MARK: - Helpers

    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * t
    }

    /// Resolve a SwiftUI Color to RGB components via UIColor.
    /// Bridges AppColors tokens into the Canvas rendering path.
    private func components(of color: Color) -> (r: Double, g: Double, b: Double) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }
}

// MARK: - Previews
//
// BUG-4 FIX: previews now include a live cycling variant that drives
// OrbitIndicator through all three states on a loop. A purely static
// preview that never invalidates can pause the TimelineView(.animation)
// scheduler. The cycling preview keeps the host view alive and redrawing,
// which ensures TimelineView fires continuously.
//
// The static grid previews are retained for quick visual inspection of
// all sizes and both color schemes.

#Preview("Dark Mode — Static Grid") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        ScrollView {
            VStack(spacing: 48) {
                Text("ORBIT INDICATOR")
                    .font(.system(size: 9, weight: .bold))
                    .kerning(2.2)
                    .foregroundStyle(AppColors.textTertiary)

                // ── Three states at default size (22pt) ──────────────
                VStack(spacing: 12) {
                    Text("22pt — default")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.textTertiary)
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .pending)
                            Text("pending")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .processing)
                            Text("processing")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .complete)
                            Text("complete")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }

                // ── Three states at medium size (32pt) ───────────────
                VStack(spacing: 12) {
                    Text("32pt — medium")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.textTertiary)
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .pending, size: 32)
                            Text("pending")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .processing, size: 32)
                            Text("processing")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .complete, size: 32)
                            Text("complete")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }

                // ── Three states at large size (44pt) ────────────────
                VStack(spacing: 12) {
                    Text("44pt — large")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.textTertiary)
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .pending, size: 44)
                            Text("pending")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .processing, size: 44)
                            Text("processing")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .complete, size: 44)
                            Text("complete")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }

                // ── In-row context ────────────────────────────────────
                VStack(spacing: 12) {
                    Text("IN-ROW CONTEXT")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.textTertiary)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 14) {
                            OrbitIndicator(state: .complete).fixedSize()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("STARTING POINT")
                                    .font(.system(size: 9, weight: .bold))
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.textTertiary)
                                Text("Beginning from curiosity")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(AppColors.textPrimary)
                            }
                        }
                        HStack(spacing: 14) {
                            OrbitIndicator(state: .processing).fixedSize()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("YOUR SITUATION")
                                    .font(.system(size: 9, weight: .bold))
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.textTertiary)
                                Text("Opening the conversation")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                        HStack(spacing: 14) {
                            OrbitIndicator(state: .pending).fixedSize()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("FIRST TO EXPLORE")
                                    .font(.system(size: 9, weight: .bold))
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.textTertiary)
                                Text("Communication & connection")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                    .padding(20)
                    .background(AppColors.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(32)
        }
    }
    .preferredColorScheme(.dark)
}

// BUG-4 FIX: Live cycling preview.
//
// Drives a single OrbitIndicator through pending → processing → complete
// on a repeating loop. This keeps the host view alive and continuously
// invalidating, which ensures TimelineView(.animation) fires every frame.
// Use this preview to verify the comet orbit and complete-fill transitions.
#Preview("Dark Mode — Live Cycle") {
    // State sequence: pending(1.0s) → processing(2.5s) → complete(1.5s) → repeat
    @Previewable @State var cycleState: OrbitIndicatorState = .pending
    @Previewable @State var sizeIndex: Int = 1   // 0=22pt, 1=32pt, 2=44pt
    let sizes: [CGFloat] = [22, 32, 44]
    let sizeLabels = ["22pt", "32pt", "44pt"]

    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        VStack(spacing: 32) {
            Text("LIVE CYCLE")
                .font(.system(size: 9, weight: .bold))
                .kerning(2.2)
                .foregroundStyle(AppColors.textTertiary)

            OrbitIndicator(state: cycleState, size: sizes[sizeIndex])

            Text(cycleState == .pending    ? "pending"    :
                 cycleState == .processing ? "processing" : "complete")
                .font(.system(size: 11, weight: .semibold))
                .kerning(1.6)
                .foregroundStyle(AppColors.textTertiary)
                .animation(.none, value: cycleState)

            // Size picker
            HStack(spacing: 0) {
                ForEach(0..<3) { i in
                    Button(sizeLabels[i]) { sizeIndex = i }
                        .font(.system(size: 12, weight: sizeIndex == i ? .bold : .regular))
                        .foregroundStyle(sizeIndex == i
                            ? AppColors.cyan
                            : AppColors.textTertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                }
            }
            .background(AppColors.cardBg)
            .clipShape(Capsule())
        }
    }
    .preferredColorScheme(.dark)
    .task {
        // Loop: pending → processing → complete → pending …
        while true {
            try? await Task.sleep(for: .seconds(1.0))
            withAnimation(.easeOut(duration: 0.3)) { cycleState = .processing }
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                cycleState = .complete
            }
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeOut(duration: 0.3)) { cycleState = .pending }
        }
    }
}

#Preview("Light Mode — Static Grid") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        ScrollView {
            VStack(spacing: 48) {
                Text("ORBIT INDICATOR")
                    .font(.system(size: 9, weight: .bold))
                    .kerning(2.2)
                    .foregroundStyle(AppColors.lightTextTertiary)

                VStack(spacing: 12) {
                    Text("22pt — default")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.lightTextTertiary)
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .pending)
                            Text("pending")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .processing)
                            Text("processing")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .complete)
                            Text("complete")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                    }
                }

                VStack(spacing: 12) {
                    Text("32pt — medium")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.lightTextTertiary)
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .pending, size: 32)
                            Text("pending")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .processing, size: 32)
                            Text("processing")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .complete, size: 32)
                            Text("complete")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                    }
                }

                VStack(spacing: 12) {
                    Text("44pt — large")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.lightTextTertiary)
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .pending, size: 44)
                            Text("pending")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .processing, size: 44)
                            Text("processing")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                        VStack(spacing: 8) {
                            OrbitIndicator(state: .complete, size: 44)
                            Text("complete")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.lightTextTertiary)
                        }
                    }
                }

                VStack(spacing: 12) {
                    Text("IN-ROW CONTEXT")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(AppColors.lightTextTertiary)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 14) {
                            OrbitIndicator(state: .complete).fixedSize()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("STARTING POINT")
                                    .font(.system(size: 9, weight: .bold))
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.lightTextTertiary)
                                Text("Beginning from curiosity")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(AppColors.lightTextPrimary)
                            }
                        }
                        HStack(spacing: 14) {
                            OrbitIndicator(state: .processing).fixedSize()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("YOUR SITUATION")
                                    .font(.system(size: 9, weight: .bold))
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.lightTextTertiary)
                                Text("Opening the conversation")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppColors.lightTextSecondary)
                            }
                        }
                        HStack(spacing: 14) {
                            OrbitIndicator(state: .pending).fixedSize()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("FIRST TO EXPLORE")
                                    .font(.system(size: 9, weight: .bold))
                                    .kerning(1.5)
                                    .foregroundStyle(AppColors.lightTextTertiary)
                                Text("Communication & connection")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppColors.lightTextSecondary)
                            }
                        }
                    }
                    .padding(20)
                    .background(AppColors.lightCardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(32)
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
        AppColors.lightPageBg.ignoresSafeArea()
        VStack(spacing: 32) {
            Text("LIVE CYCLE")
                .font(.system(size: 9, weight: .bold))
                .kerning(2.2)
                .foregroundStyle(AppColors.lightTextTertiary)

            OrbitIndicator(state: cycleState, size: sizes[sizeIndex])

            Text(cycleState == .pending    ? "pending"    :
                 cycleState == .processing ? "processing" : "complete")
                .font(.system(size: 11, weight: .semibold))
                .kerning(1.6)
                .foregroundStyle(AppColors.lightTextTertiary)
                .animation(.none, value: cycleState)

            HStack(spacing: 0) {
                ForEach(0..<3) { i in
                    Button(sizeLabels[i]) { sizeIndex = i }
                        .font(.system(size: 12, weight: sizeIndex == i ? .bold : .regular))
                        .foregroundStyle(sizeIndex == i
                            ? AppColors.purple
                            : AppColors.lightTextTertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                }
            }
            .background(AppColors.lightCardBg)
            .clipShape(Capsule())
        }
    }
    .preferredColorScheme(.light)
    .task {
        while true {
            try? await Task.sleep(for: .seconds(1.0))
            withAnimation(.easeOut(duration: 0.3)) { cycleState = .processing }
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                cycleState = .complete
            }
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeOut(duration: 0.3)) { cycleState = .pending }
        }
    }
}
