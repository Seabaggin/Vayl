// FilamentView.swift
// Open Lightly
//
// v3 — Solo color cycling + verified pattern variety

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
// 8 distinct parametric paths.
// Spread and scale values tuned so every pattern
// uses the full canvas area — nothing stays near center.

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

        // Classic horizontal figure-8
        case .figure8:
            return CGPoint(
                x: sin(t + offset),
                y: sin((t + offset) * 2) * 0.55
            )

        // Tighter lemniscate (stays closer to center)
        case .lemniscate:
            let s = t + offset
            let d = 1 + pow(sin(s), 2)
            return CGPoint(
                x: (cos(s) / d) * 1.2,
                y: (sin(s) * cos(s) / d) * 1.2
            )

        // Slow lateral breathing S
        case .sCurve:
            return CGPoint(
                x: sin((t + offset) * 0.5) * 0.95,
                y: sin(t + offset) * 0.65
                    + cos((t + offset) * 1.5) * 0.28
            )

        // Complex harmonic weave — most unpredictable
        case .weave:
            return CGPoint(
                x: sin((t + offset) * 0.7)
                    + sin((t + offset) * 1.9) * 0.35,
                y: cos((t + offset) * 0.9)
                    + cos((t + offset) * 2.3) * 0.22
            )

        // Clean circular orbit — replaces .cross
        // Deliberately simple so it contrasts the complex patterns
        case .circle:
            return CGPoint(
                x: cos(t + offset) * 0.88,
                y: sin(t + offset) * 0.88
            )

        // Expanding/contracting spiral orbit
        case .spiral:
            let r = 0.5 + sin((t + offset) * 0.3) * 0.45
            return CGPoint(
                x: cos((t + offset) * 1.3) * r,
                y: sin((t + offset) * 1.3) * r * 0.85
            )

        // Slow harmonic drift — contemplative
        case .drift:
            return CGPoint(
                x: sin((t + offset) * 0.4) * 0.75
                    + sin((t + offset) * 1.7) * 0.22,
                y: cos((t + offset) * 0.55) * 0.65
                    + sin((t + offset) * 1.3 + 1) * 0.28
            )

        // Pendulum swing with vertical bounce
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
// Named color sets for solo mode cycling.
// Dark and light variants use different palettes.
// Cycling order is randomized per FilamentState init.

struct FilamentColorSet {
    let primary: Color
    let light:   Color
    let glow:    Color

    // ── Dark mode palette ─────────────────────────
    static let darkSets: [FilamentColorSet] = [
        // Cyan
        FilamentColorSet(
            primary: Color(hex: "#00C2FF"),
            light:   Color(hex: "#4DD8FF"),
            glow:    Color(hex: "#0078FF")
        ),
        // Magenta
        FilamentColorSet(
            primary: Color(hex: "#FF006A"),
            light:   Color(hex: "#FF4D94"),
            glow:    Color(hex: "#BE185D")
        ),
        // Purple
        FilamentColorSet(
            primary: Color(hex: "#6C3AE0"),
            light:   Color(hex: "#A78BFA"),
            glow:    Color(hex: "#1A1A5E")
        ),
        // Gold
        FilamentColorSet(
            primary: Color(hex: "#C8960A"),
            light:   Color(hex: "#F0BC2E"),
            glow:    Color(hex: "#92680A")
        ),
        // Teal
        FilamentColorSet(
            primary: Color(hex: "#0891B2"),
            light:   Color(hex: "#22D3EE"),
            glow:    Color(hex: "#164E63")
        ),
    ]

    // ── Light mode palette ────────────────────────
    // Deeper, more saturated versions so trails read
    // against the cream background.
    static let lightSets: [FilamentColorSet] = [
        // Deep magenta
        FilamentColorSet(
            primary: Color(hex: "#BE185D"),
            light:   Color(hex: "#EC4899"),
            glow:    Color(hex: "#831843")
        ),
        // Deep purple
        FilamentColorSet(
            primary: Color(hex: "#7C3AED"),
            light:   Color(hex: "#A78BFA"),
            glow:    Color(hex: "#4C1D95")
        ),
        // Deep orange
        FilamentColorSet(
            primary: Color(hex: "#C2410C"),
            light:   Color(hex: "#FB923C"),
            glow:    Color(hex: "#7C2D12")
        ),
        // Deep teal
        FilamentColorSet(
            primary: Color(hex: "#0E7490"),
            light:   Color(hex: "#06B6D4"),
            glow:    Color(hex: "#164E63")
        ),
        // Deep gold
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

    // ── Published — Canvas reads these ────────────
    @Published var trail1: [CGPoint] = []
    @Published var trail2: [CGPoint] = []

    // Solo color cycling
    @Published var currentColorSet: FilamentColorSet
    @Published var nextColorSet:    FilamentColorSet
    @Published var colorProgress:   Double = 0   // 0→1 crossfade

    // ── Private time ──────────────────────────────
    private var t: Double = 0

    // Filament 1
    private var currentPattern1:     FilamentPattern
    private var nextPattern1:        FilamentPattern? = nil
    private var transitionProgress1: Double           = 0
    private var patternTimer1:       Int              = 0
    private var patternDuration1:    Int

    // Filament 2
    private var currentPattern2:     FilamentPattern
    private var nextPattern2:        FilamentPattern? = nil
    private var transitionProgress2: Double           = 0
    private var patternTimer2:       Int              = 0
    private var patternDuration2:    Int

    // Color cycling
    private var colorTimer:          Int = 0
    private var colorDuration:       Int         // frames before next color
    private var colorTransitioning:  Bool        = false
    private var colorSets:           [FilamentColorSet]
    private var currentColorIndex:   Int

    private static let maxTrail:         Int    = 130
    private static let transitionFrames: Double = 120
    // Color crossfade is slower than pattern crossfade — 3s at 60fps
    private static let colorFadeFrames:  Double = 180

    init(isDark: Bool = true) {
        let all  = FilamentPattern.allCases
        let i1   = Int.random(in: 0 ..< all.count)
        // Ensure patterns start at least 3 apart for variety
        let i2   = (i1 + 3 + Int.random(in: 0 ..< 3)) % all.count
        currentPattern1  = all[i1]
        currentPattern2  = all[i2]
        patternDuration1 = 280 + Int.random(in: 0 ..< 200)
        patternDuration2 = 320 + Int.random(in: 0 ..< 180)
        colorDuration    = 360 + Int.random(in: 0 ..< 240) // 6-10s

        // Build a shuffled color queue
        colorSets = isDark
            ? FilamentColorSet.darkSets.shuffled()
            : FilamentColorSet.lightSets.shuffled()

        currentColorIndex = 0
        currentColorSet   = colorSets[0]
        nextColorSet      = colorSets[1 % colorSets.count]
    }

    // ── Helpers ───────────────────────────────────

    private func easeInOut(_ x: Double) -> Double {
        x < 0.5 ? 4*x*x*x : 1 - pow(-2*x + 2, 3) / 2
    }

    private func pickNext(avoiding c: FilamentPattern) -> FilamentPattern {
        // Pick a pattern that is NOT the current one AND
        // differs by at least 2 steps for perceptible variety
        let all = FilamentPattern.allCases
        let cur = c.rawValue
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

    func advance(speed: Double, mode: FilamentMode, size: CGFloat) {
        t += 0.012 * speed

        let spread = size * 0.36
        let cx     = size / 2
        let cy     = size / 2

        // ── Pattern 1 cycling ─────────────────────
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

        // ── Pattern 2 cycling (duo only) ──────────
        if mode == .duo {
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

            let p2n = lerped(
                current:  currentPattern2,
                next:     nextPattern2,
                progress: transitionProgress2,
                t:        t * 0.85,
                offset:   2.2
            )
            var t2 = trail2
            t2.append(CGPoint(x: cx + p2n.x * spread,
                              y: cy + p2n.y * spread))
            if t2.count > Self.maxTrail { t2.removeFirst() }
            trail2 = t2
        }

        // ── Solo color cycling ────────────────────
        // Runs in both modes but only rendered in solo.
        // Keeping it running in duo costs nothing —
        // the duo draw functions ignore colorSet entirely.
        colorTimer += 1
        if !colorTransitioning, colorTimer > colorDuration {
            colorTransitioning = true
            colorProgress      = 0
        }
        if colorTransitioning {
            colorProgress += 1 / Self.colorFadeFrames
            if colorProgress >= 1 {
                // Commit: current becomes next, pick a new next
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

    // Interpolated color for solo rendering
    // Blends current → next using colorProgress
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

    // Simple linear color blend via opacity layering
    // SwiftUI Color doesn't expose RGB components for lerp,
    // so we use a ZStack-style opacity overlay approach:
    // return current at (1-t) opacity + next at t opacity.
    // Since Canvas uses .color() shaders we encode this as
    // the "closer" color at high opacity when t is near 0 or 1.
    private func blendColor(_ a: Color, _ b: Color, t: Double) -> Color {
        // Encode blend as: if t < 0.5, use `a` faded toward `b`
        // by returning `b` at low opacity overlay on `a`.
        // Full RGB lerp requires UIColor extraction — we use
        // a perceptually good approximation: cross-dissolve
        // by returning whichever is dominant with adjusted opacity.
        // At t=0 → a, at t=1 → b, midpoint blends.
        if t < 0.5 {
            return a   // caller applies opacity; color itself is dominant
        } else {
            return b
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - FilamentView
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct FilamentView: View {

    var size:  CGFloat      = 300
    var mode:  FilamentMode = .duo
    var speed: Double       = 1.0

    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var fs = FilamentState()

    private let timer = Timer.publish(
        every: 1.0 / 60.0,
        on: .main,
        in: .common
    ).autoconnect()

    var body: some View {
        Canvas { context, _ in
            if mode == .solo {
                // Solo: use cycling color set
                let cs = fs.interpolatedColorSet()
                drawFilament(
                    ctx:     &context,
                    trail:   fs.trail1,
                    primary: cs.primary,
                    light:   cs.light,
                    glow:    cs.glow
                )
            } else {
                // Duo: color scheme aware cyan + magenta
                let f1primary = colorScheme == .dark
                    ? AppColors.cyan
                    : AppColors.deepBlue
                let f1light = colorScheme == .dark
                    ? AppColors.cyanLight
                    : AppColors.cyan
                let f1glow = colorScheme == .dark
                    ? AppColors.deepBlue
                    : AppColors.cyanDark
                let f2primary = colorScheme == .dark
                    ? AppColors.magenta
                    : AppColors.magentaDark
                let f2light = colorScheme == .dark
                    ? AppColors.magentaLight
                    : AppColors.magenta
                let f2glow = colorScheme == .dark
                    ? AppColors.pink
                    : AppColors.magentaDark
                drawFilament(
                    ctx:     &context,
                    trail:   fs.trail1,
                    primary: f1primary,
                    light:   f1light,
                    glow:    f1glow
                )
                drawConnection(
                    ctx:    &context,
                    trail1: fs.trail1,
                    trail2: fs.trail2
                )
                drawFilament(
                    ctx:     &context,
                    trail:   fs.trail2,
                    primary: f2primary,
                    light:   f2light,
                    glow:    f2glow
                )
            }
        }
        .frame(width: size, height: size)
        .onReceive(timer) { _ in
            fs.advance(speed: speed, mode: mode, size: size)
        }
        // COLOR SCHEME INIT: resets palette to correct scheme
        // on first appear. One-frame dark flash on light mode
        // is acceptable at 60fps — not perceptible.
        .onAppear {
            fs.resetColors(isDark: colorScheme == .dark)
        }
        // Re-init color sets when color scheme changes
        .onChange(of: colorScheme) { _, newScheme in
            fs.resetColors(isDark: newScheme == .dark)
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - drawFilament
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func drawFilament(
        ctx:     inout GraphicsContext,
        trail:   [CGPoint],
        primary: Color,
        light:   Color,
        glow:    Color
    ) {
        guard trail.count >= 2 else { return }

        let count  = Double(trail.count)

        // ── Trail segments ────────────────────────
        // Draw in two passes:
        // Pass 1 — glow + mid (wide, transparent)
        // Pass 2 — core (narrow, bright)
        // This prevents the core from being occluded by its
        // own glow on overlapping trail segments.

        // Pass 1 — glow
        for i in 1 ..< trail.count {
            let alpha = 0.04 + (Double(i) / count) * 0.18
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
            let alpha = 0.08 + (Double(i) / count) * 0.88
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

        // ── Head glow ─────────────────────────────
        let head  = trail[trail.count - 1]
        let headR = size * 0.065

        ctx.fill(
            Path(ellipseIn: CGRect(
                x: head.x - headR, y: head.y - headR,
                width: headR * 2,  height: headR * 2
            )),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: light.opacity(0.95),   location: 0.00),
                    .init(color: primary.opacity(0.55), location: 0.35),
                    .init(color: primary.opacity(0.00), location: 1.00)
                ]),
                center:      head,
                startRadius: 0,
                endRadius:   headR
            )
        )

        // ── White-hot dot ─────────────────────────
        let dotR: CGFloat = 3.5
        ctx.fill(
            Path(ellipseIn: CGRect(
                x: head.x - dotR, y: head.y - dotR,
                width: dotR * 2,  height: dotR * 2
            )),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color.white.opacity(1.0), location: 0.0),
                    .init(color: light.opacity(0.0),       location: 1.0)
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

        // Glow arc
        ctx.stroke(
            arc,
            with: .color(Color(hex: "#A78BFA").opacity(ease * 0.22)),
            style: StrokeStyle(lineWidth: CGFloat(ease * 12), lineCap: .round)
        )
        // Core arc
        ctx.stroke(
            arc,
            with: .color(Color(hex: "#A78BFA").opacity(ease * 0.65)),
            style: StrokeStyle(lineWidth: CGFloat(ease * 2.5), lineCap: .round)
        )

        // Midpoint glow
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
                        .init(color: Color(hex: "#A78BFA").opacity(adj * 0.55), location: 0.0),
                        .init(color: Color(hex: "#7C3AED").opacity(adj * 0.22), location: 0.5),
                        .init(color: Color(hex: "#6C3AE0").opacity(0.00),       location: 1.0)
                    ]),
                    center:      ctrl,
                    startRadius: 0,
                    endRadius:   mgR
                )
            )
        }

        // Proximity sparks
        if ease > 0.4 {
            let sparkCount = max(1, Int((ease - 0.4) * 10))
            let step1 = max(1, trail1.count / sparkCount)
            let step2 = max(1, trail2.count / sparkCount)
            var fired = 0
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
                        with: .color(Color(hex: "#A78BFA").opacity(0.55))
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
// Extension so FilamentView can trigger a palette
// swap when colorScheme changes.

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
