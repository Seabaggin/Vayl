// Features/Pulse/Components/PulseGraph.swift
// Open Lightly
//
// Drawing primitive for the Pulse capacity timeline.
// Straight lines between points — dots feel like natural vertices.
// NO fill underneath — EKG not stock chart.
// Line breathes continuously — smooth sine, no idle gap, no jitter.
// Tier guide lines — Treatment B: spectrum colored, fade at edges,
//   active tier brighter than inactive.
// Tier labels sit at right edge — line draws a gap around each label
//   so text is always legible regardless of data position.

import SwiftUI

// MARK: - GraphGlowButtonStyle

private struct GraphGlowButtonStyle: ButtonStyle {
    @Binding var touchGlow: Double

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, isPressed in
                // Conditional reactive animation — fast on press, enter on release.
                // Cannot be a single token — two different curves for two directions.
                withAnimation(isPressed ? AppAnimation.fast : AppAnimation.enter) {
                    touchGlow = isPressed ? 1.0 : 0.0
                }
            }
    }
}

// MARK: - PulseGraph

struct PulseGraph: View {

    let entries:     [PulseEntry]
    let graphWidth:  CGFloat
    let graphHeight: CGFloat

    var camScale:         CGFloat = 1.0
    var camTx:            CGFloat = 0.0
    var camTy:            CGFloat = 0.0
    var liveScore:        Double? = nil
    var drawProgress:     CGFloat = 0.0
    var onDotTapped:      ((PulseEntry, CGPoint) -> Void)? = nil
    var disableTouchGlow: Bool = false

    @State private var breathPhase:   Double  = 0
    @State private var demoProgress:  CGFloat = 0
    @State private var demoOpacity:   Double  = 1
    @State private var touchGlow:     Double  = 0
    @State private var showTierGuide: Bool    = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if disableTouchGlow {
                PulseGraphCanvas(
                    entries:           entries,
                    graphWidth:        graphWidth,
                    graphHeight:       graphHeight,
                    camScale:          camScale,
                    camTx:             camTx,
                    camTy:             camTy,
                    liveScore:         liveScore,
                    drawProgress:      drawProgress,
                    breathPhase:       breathPhase,
                    demoProgress:      demoProgress,
                    demoOpacity:       demoOpacity,
                    touchGlow:         touchGlow,
                    onDotTapped:       onDotTapped,
                    onTierBadgeTapped: { showTierGuide = true }
                )
            } else {
                Button(action: {}) {
                    PulseGraphCanvas(
                        entries:           entries,
                        graphWidth:        graphWidth,
                        graphHeight:       graphHeight,
                        camScale:          camScale,
                        camTx:             camTx,
                        camTy:             camTy,
                        liveScore:         liveScore,
                        drawProgress:      drawProgress,
                        breathPhase:       breathPhase,
                        demoProgress:      demoProgress,
                        demoOpacity:       demoOpacity,
                        touchGlow:         touchGlow,
                        onDotTapped:       onDotTapped,
                        onTierBadgeTapped: { showTierGuide = true }
                    )
                }
                .buttonStyle(GraphGlowButtonStyle(touchGlow: $touchGlow))
            }
        }
        // Demo loop — empty state
        // Note: reduce motion guard is missing from the demo loop.
        // TODO: Add reduceMotion check before demo withAnimation calls
        // to match the pattern used on the breath task below.
        .task(id: entries.isEmpty) {
            guard entries.isEmpty else { return }
            while !Task.isCancelled {
                withAnimation(AppAnimation.slow) { demoProgress = 1.0 }
                try? await Task.sleep(for: .seconds(5.0))
                guard !Task.isCancelled else { break }
                withAnimation(AppAnimation.slow) { demoOpacity = 0.0 }
                try? await Task.sleep(for: .seconds(0.9))
                guard !Task.isCancelled else { break }
                demoProgress = 0.0
                demoOpacity  = 0.0
                withAnimation(AppAnimation.slow) { demoOpacity = 1.0 }
                try? await Task.sleep(for: .seconds(1.0))
            }
        }
        // Breath — continuous sine, no idle gap, no jitter.
        // reduceMotion check is the guard — task exits early if enabled.
        // AppAnimation.ambientDrift duration (4.0s) matches original exactly.
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            try? await Task.sleep(for: .milliseconds(100))
            withAnimation(
                .easeInOut(duration: AppAnimation.ambientDrift)
                .repeatForever(autoreverses: true)
            ) {
                breathPhase = 1.0
            }
        }
        .sheet(isPresented: $showTierGuide) {
            TierGuideSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - PulseGraphCanvas

private struct PulseGraphCanvas: View, Animatable {

    let entries:     [PulseEntry]
    let graphWidth:  CGFloat
    let graphHeight: CGFloat

    var camScale:     CGFloat = 1.0
    var camTx:        CGFloat = 0.0
    var camTy:        CGFloat = 0.0
    var liveScore:    Double? = nil
    var drawProgress: CGFloat = 0.0

    var breathPhase:  Double  = 0
    var demoProgress: CGFloat = 0
    var demoOpacity:  Double  = 1
    var touchGlow:    Double  = 0

    var animatableData: CGFloat {
        get { drawProgress }
        set { drawProgress = newValue }
    }

    var onDotTapped:       ((PulseEntry, CGPoint) -> Void)? = nil
    var onTierBadgeTapped: (() -> Void)?                    = nil

    // MARK: - Constants

    private let padLeft:    CGFloat = 24
    private let padRight:   CGFloat = 32
    private let padTop:     CGFloat = 72
    private let padBot:     CGFloat = 8
    private let minSpacing: CGFloat = 44

    // MARK: - Dynamic Canvas Width

    private var canvasWidth: CGFloat {
        let slotCount = entries.count + (liveScore != nil ? 1 : 0)
        let computed  = padLeft + CGFloat(max(1, slotCount - 1)) * minSpacing + padRight
        return max(graphWidth, computed)
    }

    @Environment(\.colorScheme)               private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isLight: Bool { colorScheme == .light }

    // MARK: - Line Gradient

    private var lineColors: [Color] {
        isLight
            ? [AppColors.accentSecondary, AppColors.accentTertiary, AppColors.safetyAccent]
            : [AppColors.accentPrimary,   AppColors.accentSecondary,  AppColors.accentTertiary]
    }

    private var lineGradient: Gradient {
        Gradient(stops: [
            .init(color: lineColors[0], location: 0.00),
            .init(color: lineColors[1], location: 0.55),
            .init(color: lineColors[2], location: 1.00),
        ])
    }

    private var gradientStartUnit: UnitPoint {
        UnitPoint(x: padLeft / canvasWidth, y: 0.5)
    }
    private var gradientEndUnit: UnitPoint {
        UnitPoint(x: (canvasWidth - padRight) / canvasWidth, y: 0.5)
    }
    private var gradientStartPoint: CGPoint {
        CGPoint(x: padLeft, y: graphHeight / 2)
    }
    private var gradientEndPoint: CGPoint {
        CGPoint(x: canvasWidth - padRight, y: graphHeight / 2)
    }

    // MARK: - Breath Values

    private var breathLineWidth: CGFloat {
        let base:  CGFloat = isLight ? 2.0 : 1.8
        let swell: CGFloat = 0.4
        return base + CGFloat(breathPhase) * swell
    }

    private var breathGlowWidth: CGFloat {
        let base:  CGFloat = isLight ? 4.5 : 4.0
        let swell: CGFloat = 1.0
        return base + CGFloat(breathPhase) * swell
    }

    private var breathGlowOpacity: Double {
        0.20 + breathPhase * 0.12
    }

    // MARK: - Geometry

    var usableWidth:  CGFloat { canvasWidth  - padLeft - padRight }
    var usableHeight: CGFloat { graphHeight  - padTop  - padBot   }

    func xForIndex(_ index: Int) -> CGFloat {
        let totalSlots = entries.count + (liveScore != nil ? 1 : 0)
        guard totalSlots > 1 else { return padLeft + usableWidth / 2 }
        return padLeft + (CGFloat(index) / CGFloat(totalSlots - 1)) * usableWidth
    }

    func yForScore(_ score: Double) -> CGFloat {
        padTop + CGFloat((4.0 - score) / 3.0) * usableHeight
    }

    private func pointForIndex(_ index: Int) -> CGPoint {
        CGPoint(x: xForIndex(index), y: yForScore(entries[index].capacityScore))
    }

    private var liveDotPoint: CGPoint? {
        guard let score = liveScore else { return nil }
        return CGPoint(x: xForIndex(entries.count), y: yForScore(score))
    }

    // MARK: - Active Tier

    private var activeTierScore: Double {
        entries.last?.capacityScore ?? 2.5
    }

    private func isActiveTier(score: Double) -> Bool {
        switch score {
        case 4.0: return activeTierScore >= 3.5
        case 3.0: return activeTierScore >= 2.5 && activeTierScore < 3.5
        case 2.0: return activeTierScore >= 1.5 && activeTierScore < 2.5
        case 1.0: return activeTierScore  < 1.5
        default:  return false
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topLeading) {
            graphContent
        }
        .frame(width: canvasWidth, height: graphHeight)
        .scaleEffect(camScale, anchor: .topLeading)
        .offset(x: camTx, y: camTy)
    }

    // MARK: - Graph Content

    @ViewBuilder
    private var graphContent: some View {
        Canvas { context, size in
            switch entries.count {
            case 0:
                drawDemo(context: context, size: size)
            case 1:
                drawTierGuides(context: context, size: size)
                drawLiveDot(context: context)
            default:
                drawTierGuides(context: context, size: size)
                drawGlowLine(context: context, size: size)
                drawNewSegment(context: context)
                drawLiveDot(context: context)
            }
        }
        .frame(width: canvasWidth, height: graphHeight)

        tierLabelsOverlay
            .frame(width: canvasWidth, height: graphHeight)

        if entries.count >= 2 {
            crispLineLayer
                .frame(width: canvasWidth, height: graphHeight)
                .allowsHitTesting(false)
        }

        if entries.count >= 2 {
            dotsOverlay
                .frame(width: canvasWidth, height: graphHeight)
        }

        if entries.count == 1 {
            singleDotOverlay
                .frame(width: canvasWidth, height: graphHeight)
        }
    }

    // MARK: - Path Builder

    private func buildLinePath(points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count >= 2 else {
            if let p = points.first {
                path.move(to: CGPoint(x: 0, y: p.y))
                path.addLine(to: p)
            }
            return path
        }
        path.move(to: CGPoint(x: 0, y: points[0].y))
        path.addLine(to: points[0])
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        return path
    }

    // MARK: - Crisp Line Layer

    private var crispLineLayer: some View {
        let points   = entries.indices.map { pointForIndex($0) }
        let linePath = buildLinePath(points: points)

        return ZStack {
            LinearGradient(
                gradient:   lineGradient,
                startPoint: gradientStartUnit,
                endPoint:   gradientEndUnit
            )
            .mask(
                linePath.stroke(style: StrokeStyle(
                    lineWidth: breathGlowWidth,
                    lineCap:   .round,
                    lineJoin:  .round
                ))
            )
            .blur(radius: 2)
            .opacity(breathGlowOpacity)

            LinearGradient(
                gradient:   lineGradient,
                startPoint: gradientStartUnit,
                endPoint:   gradientEndUnit
            )
            .mask(
                linePath.stroke(style: StrokeStyle(
                    lineWidth: breathLineWidth,
                    lineCap:   .round,
                    lineJoin:  .round
                ))
            )
        }
    }

    // MARK: - Tier Labels Overlay

    private var tierLabelsOverlay: some View {
        let tiers: [(score: Double, letter: String, color: Color)] = [
            (4.0, "E", isLight ? AppColors.safetyAccent    : AppColors.accentTertiary),
            (3.0, "S", isLight ? AppColors.accentTertiary  : AppColors.accentSecondary),
            (2.0, "P", isLight ? AppColors.accentSecondary : AppColors.accentPrimary),
            (1.0, "C", isLight ? Color.black.opacity(0.70) : Color.white.opacity(0.70)),
        ]

        return ZStack(alignment: .topLeading) {
            ForEach(Array(tiers.enumerated()), id: \.offset) { _, tier in
                let y      = yForScore(tier.score)
                let active = isActiveTier(score: tier.score)

                ZStack {
                    // 44pt invisible tap target (HIG minimum)
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 44, height: 44)

                    // Visible badge
                    // TODO: Color(red: 8/255, green: 6/255, blue: 10/255) requires
                    // an AppColors token (e.g. AppColors.graphBadgeDark) before migration.
                    Circle()
                        .fill(
                            isLight
                                ? Color.white.opacity(active ? 0.90 : 0.65)
                                : Color(red: 8/255, green: 6/255, blue: 10/255).opacity(active ? 0.90 : 0.70)
                        )
                        .frame(width: 16, height: 16)
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    tier.color.opacity(active ? 0.80 : 0.45),
                                    lineWidth: 1
                                )
                        }

                    Text(tier.letter)
                        // Fixed 8pt monospaced — intentional exception.
                        // Badge circle is fixed at 16pt. Letter must fit within it.
                        // Dynamic Type scaling would overflow the badge geometry.
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(tier.color.opacity(active ? 1.0 : 0.65))
                }
                .contentShape(Circle().size(CGSize(width: 44, height: 44)))
                .highPriorityGesture(
                    TapGesture()
                        .onEnded { onTierBadgeTapped?() }
                )
                .position(x: padLeft - 2, y: y)
            }
        }
    }

    // MARK: - Canvas Drawing

    private func drawTierGuides(context: GraphicsContext, size: CGSize) {
        let tierDefs: [(score: Double, darkColor: Color, lightColor: Color)] = [
            (1.0, Color.white,              Color.black),
            (2.0, AppColors.accentPrimary,  AppColors.accentSecondary),
            (3.0, AppColors.accentSecondary, AppColors.accentTertiary),
            (4.0, AppColors.accentTertiary, AppColors.safetyAccent),
        ]

        for tier in tierDefs {
            let y      = yForScore(tier.score)
            let active = isActiveTier(score: tier.score)
            let color  = isLight ? tier.lightColor : tier.darkColor

            let glowOpacity: Double = active
                ? (isLight ? 0.50 : 0.55)
                : (isLight ? 0.28 : 0.35)

            let crispOpacity: Double = active
                ? (isLight ? 0.85 : 0.90)
                : (isLight ? 0.55 : 0.62)

            var glowCtx = context
            glowCtx.opacity = glowOpacity
            glowCtx.addFilter(.blur(radius: 2.5))

            var glowPath = Path()
            glowPath.move(to:    CGPoint(x: 0,           y: y))
            glowPath.addLine(to: CGPoint(x: canvasWidth, y: y))
            glowCtx.stroke(
                glowPath,
                with:  .color(color),
                style: StrokeStyle(lineWidth: active ? 3 : 1.5, lineCap: .round)
            )

            var crispCtx = context
            crispCtx.opacity = crispOpacity + touchGlow * 0.20

            var crispPath = Path()
            crispPath.move(to:    CGPoint(x: 0,           y: y))
            crispPath.addLine(to: CGPoint(x: canvasWidth, y: y))
            crispCtx.stroke(
                crispPath,
                with:  .color(color),
                style: StrokeStyle(lineWidth: active ? 1.4 : 1.0, lineCap: .round)
            )
        }
    }

    private func drawGlowLine(context: GraphicsContext, size: CGSize) {
        guard entries.count >= 2 else { return }
        let points   = entries.indices.map { pointForIndex($0) }
        let linePath = buildLinePath(points: points)

        let gradientStyle = GraphicsContext.Shading.linearGradient(
            lineGradient,
            startPoint: gradientStartPoint,
            endPoint:   gradientEndPoint
        )

        var coreBloom = context
        coreBloom.addFilter(.blur(radius: 1.5 + breathPhase * 0.5))
        coreBloom.stroke(
            linePath,
            with:  gradientStyle,
            style: StrokeStyle(lineWidth: 4.0, lineCap: .round, lineJoin: .round)
        )

        let lastIdx = entries.count - 1
        let lastPt  = pointForIndex(lastIdx)
        let prevPt  = pointForIndex(max(0, lastIdx - 1))

        var burnPath = Path()
        burnPath.move(to: prevPt)
        burnPath.addLine(to: lastPt)

        var outerBurn = context
        outerBurn.addFilter(.blur(radius: 4 + breathPhase * 2))
        outerBurn.opacity = 0.40 + breathPhase * 0.15
        outerBurn.stroke(
            burnPath,
            with:  .linearGradient(lineGradient, startPoint: gradientStartPoint, endPoint: gradientEndPoint),
            style: StrokeStyle(lineWidth: 5, lineCap: .round)
        )

        var innerBurn = context
        innerBurn.addFilter(.blur(radius: 1.0))
        innerBurn.opacity = 0.65 + breathPhase * 0.20
        innerBurn.stroke(
            burnPath,
            with:  .linearGradient(lineGradient, startPoint: gradientStartPoint, endPoint: gradientEndPoint),
            style: StrokeStyle(lineWidth: 1.8, lineCap: .round)
        )
    }

    private func drawNewSegment(context: GraphicsContext) {
        guard drawProgress > 0,
              let livePoint = liveDotPoint,
              let lastPoint = entries.indices.last.map({ pointForIndex($0) })
        else { return }

        let endX = lastPoint.x + (livePoint.x - lastPoint.x) * drawProgress
        let endY = lastPoint.y + (livePoint.y - lastPoint.y) * drawProgress
        let tip  = CGPoint(x: endX, y: endY)

        var segPath = Path()
        segPath.move(to: lastPoint)
        segPath.addLine(to: tip)

        var bloom = context
        bloom.addFilter(.blur(radius: 6))
        bloom.stroke(
            segPath,
            with:  .linearGradient(lineGradient, startPoint: gradientStartPoint, endPoint: gradientEndPoint),
            style: StrokeStyle(lineWidth: 8, lineCap: .round)
        )

        context.stroke(
            segPath,
            with:  .linearGradient(lineGradient, startPoint: gradientStartPoint, endPoint: gradientEndPoint),
            style: StrokeStyle(lineWidth: isLight ? 2.0 : 1.8, lineCap: .round)
        )

        drawWeldingSparks(context: context, tip: tip, progress: drawProgress)
    }

    private func drawLiveDot(context: GraphicsContext) {
        guard let point = liveDotPoint else { return }
        let color = isLight ? AppColors.accentSecondary : AppColors.accentPrimary

        context.fill(
            Path(ellipseIn: CGRect(x: point.x-14, y: point.y-14, width: 28, height: 28)),
            with: .color(color.opacity(0.15))
        )
        context.fill(
            Path(ellipseIn: CGRect(x: point.x-8, y: point.y-8, width: 16, height: 16)),
            with: .color(color.opacity(0.25))
        )
        context.fill(
            Path(ellipseIn: CGRect(x: point.x-5, y: point.y-5, width: 10, height: 10)),
            with: .color(color.opacity(0.4 + drawProgress * 0.6))
        )
    }

    // MARK: - Demo Drawing

    private func drawDemo(context: GraphicsContext, size: CGSize) {
        let demoScores: [Double] = [2.5, 3.0, 2.2, 3.2, 2.8, 3.5]
        let count = demoScores.count

        let demoPoints: [CGPoint] = demoScores.indices.map { i in
            CGPoint(
                x: padLeft + (CGFloat(i) / CGFloat(count - 1)) * usableWidth,
                y: yForScore(demoScores[i])
            )
        }

        let fullPath = buildLinePath(points: demoPoints)

        var trimmed = Path()
        fullPath.trimmedPath(from: 0, to: demoProgress).forEach { element in
            switch element {
            case .move(let p):                  trimmed.move(to: p)
            case .line(let p):                  trimmed.addLine(to: p)
            case .quadCurve(let p, let c):      trimmed.addQuadCurve(to: p, control: c)
            case .curve(let p, let c1, let c2): trimmed.addCurve(to: p, control1: c1, control2: c2)
            case .closeSubpath:                 trimmed.closeSubpath()
            }
        }

        var blurred = context
        blurred.addFilter(.blur(radius: 3))
        blurred.stroke(
            trimmed,
            with:  .color(Color.white.opacity(0.08 * demoOpacity)),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 6])
        )
        context.stroke(
            trimmed,
            with:  .color(Color.white.opacity(0.12 * demoOpacity)),
            style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 6])
        )
    }

    // MARK: - Dot Sampling

    private var pointSpacing: CGFloat {
        guard entries.count > 1 else { return usableWidth }
        return usableWidth / CGFloat(entries.count - 1)
    }

    private var sampledIndices: [Int] {
        let minTapSpacing: CGFloat = 22
        guard entries.count > 2 else { return Array(entries.indices) }
        if pointSpacing >= minTapSpacing { return Array(entries.indices) }
        let maxDots = Int(usableWidth / minTapSpacing)
        guard maxDots > 2 else { return [0, entries.count - 1] }
        let step = max(1, entries.count / maxDots)
        var indices = stride(from: 0, to: entries.count - 1, by: step).map { $0 }
        if !indices.contains(entries.count - 1) { indices.append(entries.count - 1) }
        return indices.sorted()
    }

    // MARK: - Dot Overlays

    private var dotsOverlay: some View {
        ZStack {
            ForEach(sampledIndices.dropLast(), id: \.self) { i in
                let point = pointForIndex(i)
                let entry = entries[i]
                Circle()
                    .fill(isLight
                        ? Color.black.opacity(0.22)
                        : Color.white.opacity(0.28))
                    .frame(width: 5, height: 5)
                    .position(point)
                    .onTapGesture { onDotTapped?(entry, point) }
                    .accessibilityLabel(dotAccessibilityLabel(for: entry))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint("Double tap to see full summary")
            }

            if let lastEntry = entries.last {
                let lastIndex = entries.count - 1
                let point     = pointForIndex(lastIndex)
                let color     = lineColors[2]

                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 20, height: 20)
                    .position(point)
                    .allowsHitTesting(false)

                Circle()
                    .fill(isLight ? AppColors.cardBackground : AppColors.cardBackground)
                    .overlay(Circle().stroke(color, lineWidth: 2))
                    .frame(width: 10, height: 10)
                    .position(point)
                    .onTapGesture { onDotTapped?(lastEntry, point) }
                    .accessibilityLabel(dotAccessibilityLabel(for: lastEntry))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint("Double tap to see full summary")
            }

            if liveScore == nil, let lastEntry = entries.last {
                let lastIndex = entries.count - 1
                let point     = pointForIndex(lastIndex)
                let color     = lineColors[2]

                ZStack {
                    Circle()
                        .fill(color.opacity(0.12 + breathPhase * 0.10))
                        .frame(
                            width:  28 + CGFloat(breathPhase) * 4,
                            height: 28 + CGFloat(breathPhase) * 4
                        )
                    Circle()
                        .fill(color.opacity(0.22 + breathPhase * 0.12))
                        .frame(width: 18, height: 18)
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                        .shadow(
                            color:  color.opacity(0.6 + breathPhase * 0.3),
                            radius: 6 + CGFloat(breathPhase) * 4
                        )
                }
                .position(point)
                .onTapGesture { onDotTapped?(lastEntry, point) }
                .accessibilityLabel(dotAccessibilityLabel(for: lastEntry))
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Double tap to see full summary")
            }
        }
    }

    // MARK: - Single Dot Overlay

    private var singleDotOverlay: some View {
        let entry = entries[0]
        let point = CGPoint(
            x: padLeft + usableWidth / 2,
            y: yForScore(entry.capacityScore)
        )
        let color = lineColors[2]

        return ZStack {
            Circle()
                .fill(color.opacity(0.12 + breathPhase * 0.10))
                .frame(
                    width:  28 + CGFloat(breathPhase) * 4,
                    height: 28 + CGFloat(breathPhase) * 4
                )
                .position(point)
                .allowsHitTesting(false)

            Circle()
                .fill(color.opacity(0.22 + breathPhase * 0.12))
                .frame(width: 18, height: 18)
                .position(point)
                .allowsHitTesting(false)

            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .shadow(
                    color:  color.opacity(0.6 + breathPhase * 0.3),
                    radius: 6 + CGFloat(breathPhase) * 4
                )
                .position(point)
                .onTapGesture { onDotTapped?(entry, point) }
                .accessibilityLabel(dotAccessibilityLabel(for: entry))
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Double tap to see full summary")
        }
    }

    // MARK: - Accessibility

    private func dotAccessibilityLabel(for entry: PulseEntry) -> String {
        "\(entry.date.formatted(.dateTime.month().day())). " +
        "\(entry.tier.label). " +
        "Nervous system: \(entry.nervousSystem). " +
        "Focus: \(entry.focus). " +
        "Feeling: \(entry.feeling). " +
        "Speed: \(entry.speed)."
    }

    // MARK: - Welding Sparks

    private func drawWeldingSparks(context: GraphicsContext, tip: CGPoint, progress: CGFloat) {
        guard progress > 0.02 && progress < 0.97 else { return }

        let edgeFade: CGFloat = {
            let fadeIn  = min(1.0, progress / 0.08)
            let fadeOut = min(1.0, (0.97 - progress) / 0.06)
            return fadeIn * fadeOut
        }()
        guard edgeFade > 0 else { return }

        let colorWhite = Color.white
        let colorHot   = lineColors[0]
        let colorMid   = lineColors[1]
        let colorOuter = lineColors[2]

        var ctx = context
        ctx.translateBy(x: tip.x, y: tip.y)

        var haloCtx = ctx
        haloCtx.addFilter(.blur(radius: 8))
        haloCtx.fill(
            Path(ellipseIn: CGRect(x: -18, y: -18, width: 36, height: 36)),
            with: .color(colorHot.opacity(0.36 * edgeFade))
        )
        haloCtx.fill(
            Path(ellipseIn: CGRect(x: -10, y: -10, width: 20, height: 20)),
            with: .color(colorMid.opacity(0.24 * edgeFade))
        )

        ctx.fill(
            Path(ellipseIn: CGRect(x: -3.2, y: -3.2, width: 6.4, height: 6.4)),
            with: .color(colorWhite.opacity(0.80 * edgeFade))
        )
        var coronaCtx = ctx
        coronaCtx.addFilter(.blur(radius: 3))
        coronaCtx.fill(
            Path(ellipseIn: CGRect(x: -5.6, y: -5.6, width: 11.2, height: 11.2)),
            with: .color(colorWhite.opacity(0.56 * edgeFade))
        )

        for i in 0..<14 {
            let fi = CGFloat(i)
            let t1 = progress * 4713.0 + fi * 137.508
            let t2 = progress * 3571.0 + fi * 89.442
            let t3 = progress * 2833.0 + fi * 61.803

            let r1 = abs(sin(t1) * cos(t2 * 0.7))
            let r2 = abs(cos(t2) * sin(t3 * 1.3))
            let r3 = abs(sin(t1 * 0.4 + t3 * 0.6))

            let baseAngle  = r1 * 360.0
            let upwardBias = -45.0 + r2 * 90.0
            let angle      = Angle(degrees: baseAngle * 0.6 + upwardBias * 0.4)
            let distance: CGFloat = r2 < 0.4 ? 3.0 + r1 * 12.0 : 14.0 + r3 * 22.0
            let tailLength: CGFloat = 3.0 + r3 * 14.0

            let sparkColor: Color = {
                if distance < 8  { return colorWhite }
                if distance < 18 { return colorHot   }
                if distance < 30 { return colorMid   }
                return colorOuter
            }()

            let flicker = abs(sin(t1 * 7.3 + t2 * 3.1))
            let opacity  = (0.25 + flicker * 0.60) * edgeFade
            guard opacity > 0.05 else { continue }

            let tailStart = CGPoint(x: distance, y: 0)
            let headEnd   = CGPoint(x: distance + tailLength, y: 0)

            var sparkPath = Path()
            sparkPath.move(to: tailStart)
            sparkPath.addLine(to: headEnd)

            var sparkCtx = ctx
            sparkCtx.rotate(by: angle)
            sparkCtx.stroke(
                sparkPath,
                with: .linearGradient(
                    Gradient(colors: [.clear, sparkColor.opacity(opacity * 0.6), colorWhite.opacity(opacity)]),
                    startPoint: tailStart,
                    endPoint:   headEnd
                ),
                style: StrokeStyle(lineWidth: 0.8, lineCap: .round)
            )

            var headCtx = sparkCtx
            headCtx.addFilter(.blur(radius: 1.5))
            headCtx.fill(
                Path(ellipseIn: CGRect(x: headEnd.x-2, y: headEnd.y-2, width: 4, height: 4)),
                with: .color(sparkColor.opacity(opacity * 0.5))
            )
        }

        for i in 0..<2 {
            let fi   = CGFloat(i)
            let t    = progress * 1847.0 + fi * 200.0
            let drip = abs(sin(t))
            let dripX: CGFloat = -8.0 + drip * 16.0
            let dripY: CGFloat =  4.0 + drip * 10.0
            let dripR: CGFloat =  1.5 + drip * 1.5

            var dripCtx = ctx
            dripCtx.addFilter(.blur(radius: 1.5))
            dripCtx.fill(
                Path(ellipseIn: CGRect(
                    x: dripX - dripR, y: dripY - dripR,
                    width: dripR * 2, height: dripR * 2
                )),
                with: .color(colorHot.opacity(0.44 * edgeFade))
            )
        }
    }
}



// MARK: - Previews

#Preview("Zero entries — dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        PulseGraph(entries: [], graphWidth: 320, graphHeight: 200)
            .padding(AppSpacing.md)
    }
    .preferredColorScheme(.dark)
}

#Preview("14 entries — dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        PulseGraph(entries: PulseEntry.previews, graphWidth: 320, graphHeight: 200)
            .padding(AppSpacing.md)
    }
    .preferredColorScheme(.dark)
}

#Preview("14 entries — light") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        PulseGraph(entries: PulseEntry.previews, graphWidth: 320, graphHeight: 200)
            .padding(AppSpacing.md)
    }
    .preferredColorScheme(.light)
}

#Preview("14 entries — with live dot") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        PulseGraph(
            entries:     PulseEntry.previews,
            graphWidth:  320,
            graphHeight: 200,
            liveScore:   2.5
        )
        .padding(AppSpacing.md)
    }
    .preferredColorScheme(.dark)
}
