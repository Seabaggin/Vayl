// FilamentView.swift
// Open Lightly
//
// v4 — exitProgress parameter for orbit contraction transition

import SwiftUI
import Combine

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - FilamentMode
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum FilamentMode {
    case solo
    case duo
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - FilamentPattern
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum FilamentPattern: Int, CaseIterable {
    case figure8
    case lemniscate
    case sCurve
    case weave
    case circle
    case spiral
    case drift
    case pendulum

    func position(t: Double, offset: Double) -> CGPoint {
        switch self {

        case .figure8:
            return CGPoint(
                x: sin(t + offset),
                y: sin((t + offset) * 2) * 0.55
            )

        case .lemniscate:
            let s = t + offset
            let d = 1 + pow(sin(s), 2)
            return CGPoint(
                x: (cos(s) / d) * 1.2,
                y: (sin(s) * cos(s) / d) * 1.2
            )

        case .sCurve:
            return CGPoint(
                x: sin((t + offset) * 0.5) * 0.95,
                y: sin(t + offset) * 0.65
                    + cos((t + offset) * 1.5) * 0.28
            )

        case .weave:
            return CGPoint(
                x: sin((t + offset) * 0.7)
                    + sin((t + offset) * 1.9) * 0.35,
                y: cos((t + offset) * 0.9)
                    + cos((t + offset) * 2.3) * 0.22
            )

        case .circle:
            return CGPoint(
                x: cos(t + offset) * 0.88,
                y: sin(t + offset) * 0.88
            )

        case .spiral:
            let r = 0.5 + sin((t + offset) * 0.3) * 0.45
            return CGPoint(
                x: cos((t + offset) * 1.3) * r,
                y: sin((t + offset) * 1.3) * r * 0.85
            )

        case .drift:
            return CGPoint(
                x: sin((t + offset) * 0.4) * 0.75
                    + sin((t + offset) * 1.7) * 0.22,
                y: cos((t + offset) * 0.55) * 0.65
                    + sin((t + offset) * 1.3 + 1) * 0.28
            )

        case .pendulum:
            let swing = sin((t + offset) * 0.6) * 0.92
            return CGPoint(
                x: swing,
                y: -abs(cos((t + offset) * 0.6)) * 0.48
                    + sin((t + offset) * 2.4) * 0.28 + 0.18
            )
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - FilamentColorSet
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct FilamentColorSet {
    let primary: Color
    let light:   Color
    let glow:    Color

    static let darkSets: [FilamentColorSet] = [
        FilamentColorSet(
            primary: AppColors.cyan,
            light:   AppColors.cyanLight,
            glow:    AppColors.deepBlue
        ),
        FilamentColorSet(
            primary: AppColors.magenta,
            light:   AppColors.magentaLight,
            glow:    AppColors.magentaDark
        ),
        FilamentColorSet(
            primary: AppColors.purple,
            light:   AppColors.purpleLight,
            glow:    AppColors.purpleDark
        ),
        FilamentColorSet(
            primary: AppColors.gold,
            light:   Color(hex: "#F0BC2E"),
            glow:    Color(hex: "#92680A")
        ),
        FilamentColorSet(
            primary: AppColors.cyanDark,
            light:   Color(hex: "#22D3EE"),
            glow:    Color(hex: "#164E63")
        ),
    ]

    static let lightSets: [FilamentColorSet] = [
        FilamentColorSet(
            primary: AppColors.magentaDark,
            light:   Color(hex: "#EC4899"),
            glow:    Color(hex: "#831843")
        ),
        FilamentColorSet(
            primary: AppColors.electricViolet,
            light:   AppColors.purpleLight,
            glow:    Color(hex: "#4C1D95")
        ),
        FilamentColorSet(
            primary: Color(hex: "#C2410C"),
            light:   Color(hex: "#FB923C"),
            glow:    Color(hex: "#7C2D12")
        ),
        FilamentColorSet(
            primary: Color(hex: "#0E7490"),
            light:   Color(hex: "#06B6D4"),
            glow:    Color(hex: "#164E63")
        ),
        FilamentColorSet(
            primary: Color(hex: "#B45309"),
            light:   Color(hex: "#F59E0B"),
            glow:    Color(hex: "#78350F")
        ),
    ]
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - FilamentState
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final class FilamentState: ObservableObject {

    @Published var trail1: [CGPoint] = []
    @Published var trail2: [CGPoint] = []
    @Published var trail3: [CGPoint] = []

    @Published var currentColorSet: FilamentColorSet
    @Published var nextColorSet:    FilamentColorSet
    @Published var colorProgress:   Double = 0

    private var t: Double = 0

    private var currentPattern1:     FilamentPattern
    private var nextPattern1:        FilamentPattern? = nil
    private var transitionProgress1: Double           = 0
    private var patternTimer1:       Int              = 0
    private var patternDuration1:    Int

    private var currentPattern2:     FilamentPattern
    private var nextPattern2:        FilamentPattern? = nil
    private var transitionProgress2: Double           = 0
    private var patternTimer2:       Int              = 0
    private var patternDuration2:    Int

    private var currentPattern3:     FilamentPattern
    private var nextPattern3:        FilamentPattern? = nil
    private var transitionProgress3: Double           = 0
    private var patternTimer3:       Int              = 0
    private var patternDuration3:    Int

    private var colorTimer:         Int  = 0
    private var colorDuration:      Int
    private var colorTransitioning: Bool = false
    private var colorSets:          [FilamentColorSet]
    private var currentColorIndex:  Int

    private static let maxTrail:         Int    = 130
    private static let transitionFrames: Double = 120
    private static let colorFadeFrames:  Double = 180

    init(isDark: Bool = true) {
        let all = FilamentPattern.allCases
        let i1  = Int.random(in: 0 ..< all.count)
        let i2  = (i1 + 3 + Int.random(in: 0 ..< 3)) % all.count
        let i3  = (i2 + 2 + Int.random(in: 0 ..< 2)) % all.count
        currentPattern1  = all[i1]
        currentPattern2  = all[i2]
        currentPattern3  = all[i3]
        patternDuration1 = 280 + Int.random(in: 0 ..< 200)
        patternDuration2 = 320 + Int.random(in: 0 ..< 180)
        patternDuration3 = 300 + Int.random(in: 0 ..< 160)
        colorDuration    = 360 + Int.random(in: 0 ..< 240)

        colorSets         = isDark
            ? FilamentColorSet.darkSets.shuffled()
            : FilamentColorSet.lightSets.shuffled()
        currentColorIndex = 0
        currentColorSet   = colorSets[0]
        nextColorSet      = colorSets[1 % colorSets.count]
    }

    private func easeInOut(_ x: Double) -> Double {
        x < 0.5 ? 4*x*x*x : 1 - pow(-2*x + 2, 3) / 2
    }

    private func pickNext(avoiding c: FilamentPattern) -> FilamentPattern {
        let all        = FilamentPattern.allCases
        let cur        = c.rawValue
        let candidates = all.filter { abs($0.rawValue - cur) >= 2 }
        return (candidates.isEmpty
            ? all.filter { $0 != c }
            : candidates
        ).randomElement()!
    }

    private func lerped(
        current:  FilamentPattern,
        next:     FilamentPattern?,
        progress: Double,
        t:        Double,
        offset:   Double
    ) -> CGPoint {
        let base = current.position(t: t, offset: offset)
        guard let next, progress > 0 else { return base }
        let tgt = next.position(t: t, offset: offset)
        let e   = easeInOut(progress)
        return CGPoint(
            x: base.x * (1 - e) + tgt.x * e,
            y: base.y * (1 - e) + tgt.y * e
        )
    }

    // ── Advance ───────────────────────────────────
    //
    // exitProgress: nil = normal orbiting.
    // 0.0→1.0 = spiral contraction toward center.
    //
    // Two effects of exitProgress:
    //
    // 1. SPREAD REDUCTION
    //    spread is multiplied by (1 - exitProgress).
    //    At exitProgress=1.0, spread=0 — all particles
    //    converge to canvas center point.
    //
    // 2. SPIRAL ACCELERATION
    //    t advances faster as exitProgress increases.
    //    speedMultiplier = 1.0 + exitProgress * 4.0
    //    At exitProgress=0.5, particles orbit ~3x faster.
    //    At exitProgress=1.0, ~5x faster.
    //    This creates the visual spiral-inward effect —
    //    particles are still orbiting their patterns but
    //    the radius is shrinking, producing a spiral.
    //
    // Trail history is preserved during contraction so
    // the trail "chases" the contracting head — giving
    // the spiral a comet-tail appearance rather than
    // the entire trail collapsing at once.

    func advance(speed: Double, mode: FilamentMode, size: CGFloat,
                 exitProgress: CGFloat = 0) {

        // Speed multiplier — orbits accelerate as they contract.
        // easeInOut applied so acceleration starts gently.
        let ep             = Double(max(0, min(1, exitProgress)))
        let easedEP        = easeInOut(ep)
        let speedMultiplier = 1.0 + easedEP * 4.0
        t += 0.012 * speed * speedMultiplier

        // Spread shrinks toward zero as exitProgress reaches 1.
        // Particles converge on canvas center (cx, cy).
        let fullSpread = size * 0.36
        let spread     = fullSpread * CGFloat(1.0 - easedEP)
        let cx         = size / 2
        let cy         = size / 2

        // ── Pattern 1 cycling ─────────────────────
        // Pattern cycling is FROZEN during exit contraction.
        // exitProgress > 0 means the orbits are being wound down —
        // triggering a new pattern mid-contraction would cause a
        // jarring direction change at the worst moment.
        if ep == 0 {
            patternTimer1 += 1
            if nextPattern1 == nil, patternTimer1 > patternDuration1 {
                nextPattern1        = pickNext(avoiding: currentPattern1)
                transitionProgress1 = 0
            }
            if nextPattern1 != nil {
                transitionProgress1 += 1 / Self.transitionFrames
                if transitionProgress1 >= 1 {
                    currentPattern1     = nextPattern1!
                    nextPattern1        = nil
                    transitionProgress1 = 0
                    patternTimer1       = 0
                    patternDuration1    = 250 + Int.random(in: 0 ..< 250)
                }
            }
        }

        let p1n = lerped(
            current:  currentPattern1,
            next:     nextPattern1,
            progress: transitionProgress1,
            t:        t,
            offset:   0
        )
        var t1 = trail1
        t1.append(CGPoint(x: cx + p1n.x * spread,
                          y: cy + p1n.y * spread))
        if t1.count > Self.maxTrail { t1.removeFirst() }
        trail1 = t1

        // ── Pattern 2 cycling ─────────────────────

        if ep == 0 {
            patternTimer2 += 1
            if nextPattern2 == nil, patternTimer2 > patternDuration2 {
                nextPattern2        = pickNext(avoiding: currentPattern2)
                transitionProgress2 = 0
            }
            if nextPattern2 != nil {
                transitionProgress2 += 1 / Self.transitionFrames
                if transitionProgress2 >= 1 {
                    currentPattern2     = nextPattern2!
                    nextPattern2        = nil
                    transitionProgress2 = 0
                    patternTimer2       = 0
                    patternDuration2    = 280 + Int.random(in: 0 ..< 220)
                }
            }
        }

        let trail2T      = mode == .solo ? t * 0.82 : t * 0.85
        let trail2Offset = mode == .solo ? Double.pi  : 2.2

        let p2n = lerped(
            current:  currentPattern2,
            next:     nextPattern2,
            progress: transitionProgress2,
            t:        trail2T,
            offset:   trail2Offset
        )
        var t2 = trail2
        t2.append(CGPoint(x: cx + p2n.x * spread,
                          y: cy + p2n.y * spread))
        if t2.count > Self.maxTrail { t2.removeFirst() }
        trail2 = t2

        // ── Pattern 3 cycling ─────────────────────

        if ep == 0 {
            patternTimer3 += 1
            if nextPattern3 == nil, patternTimer3 > patternDuration3 {
                nextPattern3        = pickNext(avoiding: currentPattern3)
                transitionProgress3 = 0
            }
            if nextPattern3 != nil {
                transitionProgress3 += 1 / Self.transitionFrames
                if transitionProgress3 >= 1 {
                    currentPattern3     = nextPattern3!
                    nextPattern3        = nil
                    transitionProgress3 = 0
                    patternTimer3       = 0
                    patternDuration3    = 300 + Int.random(in: 0 ..< 160)
                }
            }
        }

        let p3n = lerped(
            current:  currentPattern3,
            next:     nextPattern3,
            progress: transitionProgress3,
            t:        t * 0.91,
            offset:   4.2
        )
        var t3 = trail3
        t3.append(CGPoint(x: cx + p3n.x * spread,
                          y: cy + p3n.y * spread))
        if t3.count > Self.maxTrail { t3.removeFirst() }
        trail3 = t3

        // ── Solo color cycling ────────────────────
        // Frozen during exit — no point cycling colors
        // during a 600ms contraction window.
        guard ep == 0 else { return }

        colorTimer += 1
        if !colorTransitioning, colorTimer > colorDuration {
            colorTransitioning = true
            colorProgress      = 0
        }
        if colorTransitioning {
            colorProgress += 1 / Self.colorFadeFrames
            if colorProgress >= 1 {
                currentColorIndex  = (currentColorIndex + 1) % colorSets.count
                currentColorSet    = colorSets[currentColorIndex]
                let nextIdx        = (currentColorIndex + 1) % colorSets.count
                nextColorSet       = colorSets[nextIdx]
                colorProgress      = 0
                colorTransitioning = false
                colorTimer         = 0
                colorDuration      = 360 + Int.random(in: 0 ..< 240)
            }
        }
    }

    func interpolatedColorSet() -> FilamentColorSet {
        guard colorProgress > 0 else { return currentColorSet }
        let e = easeInOut(colorProgress)
        return FilamentColorSet(
            primary: blendColor(currentColorSet.primary,
                                nextColorSet.primary, t: e),
            light:   blendColor(currentColorSet.light,
                                nextColorSet.light,   t: e),
            glow:    blendColor(currentColorSet.glow,
                                nextColorSet.glow,    t: e)
        )
    }

    private func blendColor(_ a: Color, _ b: Color, t: Double) -> Color {
        t < 0.5 ? a : b
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - FilamentView
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct FilamentView: View {

    var size:  CGFloat      = 300
    var mode:  FilamentMode = .duo
    var speed: Double       = 1.0

    // EXIT CONTRACTION
    // ─────────────────
    // nil  = normal orbiting — no contraction (default).
    //        All existing call sites pass no value and are unaffected.
    // 0.0  = contraction begins, full orbit radius, normal speed.
    // 1.0  = fully contracted, all particles at canvas center.
    //
    // Animate from nil→0→1 using withAnimation(.easeInOut(duration: 0.60))
    // in OnboardingBrandView at t=4700ms.
    //
    // Internal behaviour:
    //   — spread multiplied by (1 - easeInOut(exitProgress))
    //   — t advance speed multiplied by (1 + easeInOut(exitProgress) * 4)
    //   — pattern cycling frozen (no jarring direction changes mid-spiral)
    //   — color cycling frozen
    var exitProgress: CGFloat? = nil

    // 1, 2, or 3. Default 3 — all existing call sites unaffected.
    var orbitCount: Int = 3

    // false suppresses connection arcs between trail heads.
    // Use false in small tiles where arcs read as noise.
    // Default true — all existing call sites unaffected.
    var showConnections: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var fs = FilamentState()

    private let timer = Timer.publish(
        every: 1.0 / 60.0,
        on: .main,
        in: .common
    ).autoconnect()

    var body: some View {
        Canvas { context, _ in
            let f1primary = colorScheme == .dark ? AppColors.cyan        : AppColors.magenta
            let f1light   = colorScheme == .dark ? AppColors.cyanLight   : AppColors.magentaLight
            let f1glow    = colorScheme == .dark ? AppColors.deepBlue    : AppColors.magentaDark

            let f2primary = colorScheme == .dark ? AppColors.magenta     : AppColors.orangeHot
            let f2light   = colorScheme == .dark ? AppColors.magentaLight: AppColors.gold
            let f2glow    = colorScheme == .dark ? AppColors.pink        : AppColors.goldDark

            let f3primary = colorScheme == .dark ? AppColors.purple      : AppColors.purple
            let f3light   = colorScheme == .dark ? AppColors.purpleLight : AppColors.purpleLight
            let f3glow    = colorScheme == .dark ? AppColors.purpleDark  : AppColors.purpleDark

            // Orbit 1 — always drawn
            drawFilament(ctx: &context, trail: fs.trail1,
                         primary: f1primary, light: f1light, glow: f1glow)

            // Orbit 2 — drawn when orbitCount >= 2
            if orbitCount >= 2 {
                if showConnections {
                    drawConnection(ctx: &context,
                                   trail1: fs.trail1, trail2: fs.trail3)
                }
                drawFilament(ctx: &context, trail: fs.trail3,
                             primary: f3primary, light: f3light, glow: f3glow)
            }

            // Orbit 3 — drawn when orbitCount >= 3
            if orbitCount >= 3 {
                if showConnections {
                    drawConnection(ctx: &context,
                                   trail1: fs.trail3, trail2: fs.trail2)
                }
                drawFilament(ctx: &context, trail: fs.trail2,
                             primary: f2primary, light: f2light, glow: f2glow)
            }

            // NOTE: FilamentState always advances all three trails regardless
            // of orbitCount. Unused trails compute but don't render — this
            // keeps trail2/trail3 warm so switching orbitCount mid-session
            // produces no cold-start visual gap.
        }
        .frame(width: size, height: size)
        .onReceive(timer) { _ in
            fs.advance(
                speed:        speed,
                mode:         mode,
                size:         size,
                exitProgress: exitProgress ?? 0
            )
        }
        .onAppear {
            fs.resetColors(isDark: colorScheme == .dark)
        }
        .onChange(of: colorScheme) { _, newScheme in
            fs.resetColors(isDark: newScheme == .dark)
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - drawFilament
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func drawFilament(
        ctx:       inout GraphicsContext,
        trail:     [CGPoint],
        primary:   Color,
        light:     Color,
        glow:      Color,
        dimFactor: Double = 1.0
    ) {
        guard trail.count >= 2 else { return }

        let count = Double(trail.count)

        // Pass 1 — glow
        for i in 1 ..< trail.count {
            let alpha = (0.04 + (Double(i) / count) * 0.18) * dimFactor
            let width = CGFloat(1.0 + (Double(i) / count) * 5.0)

            var seg = Path()
            seg.move(to: trail[i - 1])
            seg.addLine(to: trail[i])

            ctx.stroke(
                seg,
                with: .color(glow.opacity(alpha)),
                style: StrokeStyle(lineWidth: width + 8, lineCap: .round)
            )
        }

        // Pass 2 — mid + core
        for i in 1 ..< trail.count {
            let alpha = (0.08 + (Double(i) / count) * 0.88) * dimFactor
            let width = CGFloat(0.5 + (Double(i) / count) * 3.5)

            var seg = Path()
            seg.move(to: trail[i - 1])
            seg.addLine(to: trail[i])

            ctx.stroke(
                seg,
                with: .color(primary.opacity(alpha * 0.60)),
                style: StrokeStyle(lineWidth: width + 3, lineCap: .round)
            )
            ctx.stroke(
                seg,
                with: .color(light.opacity(alpha * 0.95)),
                style: StrokeStyle(lineWidth: width, lineCap: .round)
            )
        }

        // Head glow
        let head  = trail[trail.count - 1]
        let headR = size * 0.065 * CGFloat(dimFactor < 1.0 ? 0.80 : 1.0)

        ctx.fill(
            Path(ellipseIn: CGRect(
                x: head.x - headR, y: head.y - headR,
                width: headR * 2,  height: headR * 2
            )),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: light.opacity(0.95 * dimFactor),   location: 0.00),
                    .init(color: primary.opacity(0.55 * dimFactor), location: 0.35),
                    .init(color: primary.opacity(0.00),             location: 1.00)
                ]),
                center:      head,
                startRadius: 0,
                endRadius:   headR
            )
        )

        // White-hot dot
        let dotR: CGFloat = dimFactor < 1.0 ? 2.5 : 3.5
        ctx.fill(
            Path(ellipseIn: CGRect(
                x: head.x - dotR, y: head.y - dotR,
                width: dotR * 2,  height: dotR * 2
            )),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color.white.opacity(dimFactor), location: 0.0),
                    .init(color: light.opacity(0.0),             location: 1.0)
                ]),
                center:      head,
                startRadius: 0,
                endRadius:   dotR
            )
        )
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - drawConnection
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func drawConnection(
        ctx:    inout GraphicsContext,
        trail1: [CGPoint],
        trail2: [CGPoint]
    ) {
        guard let p1 = trail1.last,
              let p2 = trail2.last else { return }

        let dist    = hypot(p2.x - p1.x, p2.y - p1.y)
        let maxDist = size * 0.50
        guard dist < maxDist else { return }

        let closeness = 1.0 - dist / maxDist
        let ease      = closeness * closeness

        let mx    = (p1.x + p2.x) / 2
        let my    = (p1.y + p2.y) / 2
        let perpX = -(p2.y - p1.y) * 0.2 * ease
        let perpY =  (p2.x - p1.x) * 0.2 * ease
        let ctrl  = CGPoint(x: mx + perpX, y: my + perpY)

        var arc = Path()
        arc.move(to: p1)
        arc.addQuadCurve(to: p2, control: ctrl)

        ctx.stroke(
            arc,
            with: .color(AppColors.purpleLight.opacity(ease * 0.22)),
            style: StrokeStyle(lineWidth: CGFloat(ease * 12), lineCap: .round)
        )
        ctx.stroke(
            arc,
            with: .color(AppColors.purpleLight.opacity(ease * 0.65)),
            style: StrokeStyle(lineWidth: CGFloat(ease * 2.5), lineCap: .round)
        )

        if ease > 0.3 {
            let mgR = size * 0.07
            let adj = ease - 0.3
            ctx.fill(
                Path(ellipseIn: CGRect(
                    x: ctrl.x - mgR, y: ctrl.y - mgR,
                    width: mgR * 2,  height: mgR * 2
                )),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: AppColors.purpleLight.opacity(adj * 0.55), location: 0.0),
                        .init(color: AppColors.electricViolet.opacity(adj * 0.22), location: 0.5),
                        .init(color: AppColors.purple.opacity(0.00),       location: 1.0)
                    ]),
                    center:      ctrl,
                    startRadius: 0,
                    endRadius:   mgR
                )
            )
        }

        if ease > 0.4 {
            let sparkCount = max(1, Int((ease - 0.4) * 10))
            let step1      = max(1, trail1.count / sparkCount)
            let step2      = max(1, trail2.count / sparkCount)
            var fired      = 0
            outer: for i in stride(from: 0, to: trail1.count, by: step1) {
                for j in stride(from: 0, to: trail2.count, by: step2) {
                    let tp1 = trail1[i], tp2 = trail2[j]
                    guard hypot(tp2.x - tp1.x, tp2.y - tp1.y) < size * 0.09
                    else { continue }
                    ctx.fill(
                        Path(ellipseIn: CGRect(
                            x: (tp1.x + tp2.x) / 2 - 1.5,
                            y: (tp1.y + tp2.y) / 2 - 1.5,
                            width: 3, height: 3
                        )),
                        with: .color(AppColors.purpleLight.opacity(0.55))
                    )
                    fired += 1
                    if fired >= sparkCount { break outer }
                }
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - FilamentState color reset
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension FilamentState {
    func resetColors(isDark: Bool) {
        let sets           = isDark
            ? FilamentColorSet.darkSets.shuffled()
            : FilamentColorSet.lightSets.shuffled()
        currentColorIndex  = 0
        currentColorSet    = sets[0]
        nextColorSet       = sets[1 % sets.count]
        colorProgress      = 0
        colorTransitioning = false
        colorTimer         = 0
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Previews
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#Preview("Dark — Solo (color cycling)") {
    ZStack {
        Color(hex: "#030305").ignoresSafeArea()
        VStack(spacing: 20) {
            Text("Solo · dark · color cycling")
                .font(.caption)
                .foregroundStyle(Color(hex: "#666680"))
            FilamentView(size: 300, mode: .solo, speed: 1.0)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Dark — Solo — Exit contraction") {
    // Preview the exitProgress contraction at 50% and 100%
    ZStack {
        Color(hex: "#030305").ignoresSafeArea()
        VStack(spacing: 32) {
            Text("exitProgress: 0.5")
                .font(.caption)
                .foregroundStyle(Color(hex: "#666680"))
            FilamentView(size: 260, mode: .solo, speed: 1.0, exitProgress: 0.5)

            Text("exitProgress: 0.9")
                .font(.caption)
                .foregroundStyle(Color(hex: "#666680"))
            FilamentView(size: 260, mode: .solo, speed: 1.0, exitProgress: 0.9)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Dark — Duo") {
    ZStack {
        Color(hex: "#030305").ignoresSafeArea()
        VStack(spacing: 20) {
            Text("Duo · dark · cyan + magenta")
                .font(.caption)
                .foregroundStyle(Color(hex: "#666680"))
            FilamentView(size: 300, mode: .duo, speed: 1.0)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — Solo (color cycling)") {
    ZStack {
        Color(hex: "#F5F0E8").ignoresSafeArea()
        VStack(spacing: 20) {
            Text("Solo · light · color cycling")
                .font(.caption)
                .foregroundStyle(Color(hex: "#888880"))
            FilamentView(size: 300, mode: .solo, speed: 1.0)
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Light — Duo") {
    ZStack {
        Color(hex: "#F5F0E8").ignoresSafeArea()
        VStack(spacing: 20) {
            Text("Duo · light · cyan + magenta")
                .font(.caption)
                .foregroundStyle(Color(hex: "#888880"))
            FilamentView(size: 300, mode: .duo, speed: 1.0)
        }
    }
    .preferredColorScheme(.light)
}

#Preview("orbitCount 1 / 2 / 3 — no connections") {
    ZStack {
        Color(hex: "#030305").ignoresSafeArea()
        HStack(spacing: 20) {
            VStack(spacing: 6) {
                FilamentView(
                    size:            52,
                    mode:           .solo,
                    speed:           1.0,
                    orbitCount:      1,
                    showConnections: false
                )
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                Text("1")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#666680"))
            }
            VStack(spacing: 6) {
                FilamentView(
                    size:            52,
                    mode:           .duo,
                    speed:           1.0,
                    orbitCount:      2,
                    showConnections: false
                )
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                Text("2")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#666680"))
            }
            VStack(spacing: 6) {
                FilamentView(
                    size:            52,
                    mode:           .duo,
                    speed:           1.0,
                    orbitCount:      3,
                    showConnections: false
                )
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                Text("3")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#666680"))
            }
        }
    }
    .preferredColorScheme(.dark)
}
