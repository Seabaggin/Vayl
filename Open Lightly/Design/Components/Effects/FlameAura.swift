// Design/Components/Effects/FlameAura.swift

import SwiftUI

struct FlameAura: View {
    let intensity: SelectablePill.Intensity

    // Warm flame palette — contrasts against cool purple bg
    private let flameOrange = Color(red: 1.0,  green: 0.55, blue: 0.15)
    private let flameGold   = Color(red: 1.0,  green: 0.75, blue: 0.25)
    private let flameWhite  = Color(red: 1.0,  green: 0.92, blue: 0.80)
    private let flamePink   = Color(red: 1.0,  green: 0.40, blue: 0.50)

    private var viewW: CGFloat { 160 }
    private var viewH: CGFloat { intensity == .alive ? 120 : 90 }
    private var cy: CGFloat { viewH - 23 }

    var body: some View {
        GeometryReader { geo in
            let fw = geo.size.width
            let fh = geo.size.height

            ZStack {
                ForEach(Array(flames.enumerated()), id: \.offset) { _, flame in
                    FlameWispView(
                        flame: flame,
                        viewW: viewW,
                        viewH: viewH,
                        frameW: fw,
                        frameH: fh
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var flames: [FlameData] {
        switch intensity {
        case .dim:   return []
        case .warm:  return warmFlames
        case .alive: return aliveFlames
        }
    }

    private var aliveFlames: [FlameData] {
        let c = cy
        return [
            // White-hot core wisps
            FlameData(
                points: [.M(60,c), .Q(55,c-30, 68,c-55), .Q(72,c-65, 70,c-75), .Q(76,c-55, 82,c-30), .Q(85,c-15, 80,c)],
                color: flameWhite, opacity: 0.18,
                blur: 7, duration: 5.0, delay: 0.0, anim: .slow1
            ),
            FlameData(
                points: [.M(75,c), .Q(70,c-25, 82,c-48), .Q(86,c-56, 84,c-65), .Q(90,c-45, 96,c-22), .Q(98,c-10, 94,c)],
                color: flameWhite, opacity: 0.14,
                blur: 8, duration: 5.5, delay: 0.5, anim: .slow2
            ),

            // Orange mid layer
            FlameData(
                points: [.M(30,c), .Q(28,c-35, 38,c-60), .Q(42,c-70, 40,c-85), .Q(44,c-65, 50,c-40), .Q(54,c-25, 48,c)],
                color: flameOrange, opacity: 0.28,
                blur: 9, duration: 4.5, delay: 0.0, anim: .slow1
            ),
            FlameData(
                points: [.M(70,c), .Q(65,c-40, 78,c-65), .Q(82,c-78, 80,c-95), .Q(86,c-70, 92,c-40), .Q(95,c-20, 88,c)],
                color: flameOrange, opacity: 0.24,
                blur: 10, duration: 5.8, delay: 0.3, anim: .slow3
            ),
            FlameData(
                points: [.M(110,c), .Q(108,c-28, 118,c-50), .Q(122,c-60, 120,c-72), .Q(126,c-48, 132,c-25), .Q(135,c-10, 128,c)],
                color: flameOrange, opacity: 0.22,
                blur: 10, duration: 5.5, delay: 0.6, anim: .slow2
            ),

            // Gold accent layer
            FlameData(
                points: [.M(45,c), .Q(40,c-30, 52,c-55), .Q(56,c-65, 54,c-80), .Q(60,c-55, 65,c-30), .Q(68,c-15, 62,c)],
                color: flameGold, opacity: 0.20,
                blur: 11, duration: 5.2, delay: 0.8, anim: .slow2
            ),
            FlameData(
                points: [.M(90,c), .Q(88,c-32, 98,c-52), .Q(102,c-62, 100,c-75), .Q(106,c-50, 112,c-28), .Q(115,c-12, 108,c)],
                color: flameGold, opacity: 0.18,
                blur: 12, duration: 6.0, delay: 1.2, anim: .slow1
            ),

            // Pink outer wisp
            FlameData(
                points: [.M(55,c), .Q(50,c-45, 65,c-75), .Q(70,c-88, 68,c-100), .Q(75,c-78, 82,c-50), .Q(86,c-30, 80,c)],
                color: flamePink, opacity: 0.14,
                blur: 13, duration: 6.5, delay: 1.0, anim: .slow3
            ),

            // Edge wisps
            FlameData(
                points: [.M(20,c), .Q(22,c-20, 18,c-40), .Q(16,c-50, 20,c-55), .Q(26,c-38, 32,c-18), .Q(35,c-8, 34,c)],
                color: flameOrange, opacity: 0.14,
                blur: 9, duration: 5.0, delay: 1.5, anim: .slow1
            ),
            FlameData(
                points: [.M(120,c), .Q(118,c-18, 125,c-35), .Q(128,c-45, 126,c-50), .Q(130,c-32, 138,c-15), .Q(140,c-5, 136,c)],
                color: flameGold, opacity: 0.12,
                blur: 9, duration: 4.8, delay: 0.4, anim: .slow2
            ),
        ]
    }

    private var warmFlames: [FlameData] {
        let c = cy
        return [
            FlameData(
                points: [.M(35,c), .Q(32,c-20, 44,c-36), .Q(48,c-42, 46,c-50), .Q(52,c-34, 58,c-18), .Q(60,c-8, 56,c)],
                color: flameOrange, opacity: 0.20,
                blur: 7, duration: 3.8, delay: 0.0, anim: .slow1
            ),
            FlameData(
                points: [.M(60,c), .Q(56,c-18, 68,c-34), .Q(72,c-40, 70,c-48), .Q(76,c-32, 82,c-16), .Q(84,c-6, 80,c)],
                color: flameGold, opacity: 0.18,
                blur: 8, duration: 4.2, delay: 0.5, anim: .slow2
            ),
            FlameData(
                points: [.M(90,c), .Q(86,c-16, 98,c-30), .Q(102,c-36, 100,c-42), .Q(106,c-28, 112,c-14), .Q(114,c-5, 110,c)],
                color: flameWhite, opacity: 0.12,
                blur: 7, duration: 4.5, delay: 0.2, anim: .slow3
            ),
            FlameData(
                points: [.M(72,c), .Q(68,c-22, 78,c-38), .Q(82,c-44, 80,c-52), .Q(86,c-36, 92,c-20), .Q(94,c-8, 90,c)],
                color: flamePink, opacity: 0.12,
                blur: 9, duration: 4.8, delay: 0.8, anim: .slow1
            ),
        ]
    }
}

// MARK: - Data Types

private enum AnimType {
    case slow1, slow2, slow3
}

private enum PathCommand {
    case M(CGFloat, CGFloat)
    case Q(CGFloat, CGFloat, CGFloat, CGFloat)
}

private struct FlameData {
    let points: [PathCommand]
    let color: Color
    let opacity: CGFloat
    let blur: CGFloat
    let duration: Double
    let delay: Double
    let anim: AnimType
}

// MARK: - Keyframes (exact CSS match)

private struct FlameKeyframe {
    let scaleY: CGFloat
    let translateY: CGFloat
    let skewX: CGFloat
    let opacity: CGFloat
}

private let slow1Keyframes: [(CGFloat, FlameKeyframe)] = [
    (0.00, FlameKeyframe(scaleY: 1.00, translateY: 0,  skewX: 0, opacity: 0.60)),
    (0.30, FlameKeyframe(scaleY: 1.06, translateY: -3, skewX: 0, opacity: 0.75)),
    (0.60, FlameKeyframe(scaleY: 0.97, translateY: -1, skewX: 0, opacity: 0.65)),
    (1.00, FlameKeyframe(scaleY: 1.04, translateY: -2, skewX: 0, opacity: 0.80)),
]

private let slow2Keyframes: [(CGFloat, FlameKeyframe)] = [
    (0.00, FlameKeyframe(scaleY: 1.00, translateY: 0,  skewX: 0.0,  opacity: 0.55)),
    (0.25, FlameKeyframe(scaleY: 1.05, translateY: -2, skewX: 1.5,  opacity: 0.70)),
    (0.50, FlameKeyframe(scaleY: 0.98, translateY: -1, skewX: -1.0, opacity: 0.60)),
    (0.75, FlameKeyframe(scaleY: 1.07, translateY: -4, skewX: 0.5,  opacity: 0.78)),
    (1.00, FlameKeyframe(scaleY: 1.02, translateY: -2, skewX: -0.5, opacity: 0.68)),
]

private let slow3Keyframes: [(CGFloat, FlameKeyframe)] = [
    (0.00, FlameKeyframe(scaleY: 1.00, translateY: 0,  skewX: 0.0,  opacity: 0.50)),
    (0.20, FlameKeyframe(scaleY: 1.04, translateY: -2, skewX: -1.0, opacity: 0.65)),
    (0.45, FlameKeyframe(scaleY: 1.08, translateY: -4, skewX: 1.0,  opacity: 0.75)),
    (0.70, FlameKeyframe(scaleY: 0.99, translateY: -1, skewX: 0.0,  opacity: 0.58)),
    (1.00, FlameKeyframe(scaleY: 1.03, translateY: -3, skewX: -0.5, opacity: 0.72)),
]

private func interpolateKeyframes(_ keyframes: [(CGFloat, FlameKeyframe)], at t: CGFloat) -> FlameKeyframe {
    guard keyframes.count >= 2 else {
        return keyframes.first?.1 ?? FlameKeyframe(scaleY: 1, translateY: 0, skewX: 0, opacity: 0.5)
    }
    for i in 0..<(keyframes.count - 1) {
        let (t0, kf0) = keyframes[i]
        let (t1, kf1) = keyframes[i + 1]
        if t >= t0 && t <= t1 {
            let local = (t - t0) / (t1 - t0)
            return FlameKeyframe(
                scaleY: kf0.scaleY + (kf1.scaleY - kf0.scaleY) * local,
                translateY: kf0.translateY + (kf1.translateY - kf0.translateY) * local,
                skewX: kf0.skewX + (kf1.skewX - kf0.skewX) * local,
                opacity: kf0.opacity + (kf1.opacity - kf0.opacity) * local
            )
        }
    }
    return keyframes.last!.1
}

private func keyframesFor(_ anim: AnimType) -> [(CGFloat, FlameKeyframe)] {
    switch anim {
    case .slow1: return slow1Keyframes
    case .slow2: return slow2Keyframes
    case .slow3: return slow3Keyframes
    }
}

// MARK: - Single Wisp (TimelineView)

private struct FlameWispView: View {
    let flame: FlameData
    let viewW: CGFloat
    let viewH: CGFloat
    let frameW: CGFloat
    let frameH: CGFloat

    @State private var startTime: Date?

    var body: some View {
        TimelineView(.animation) { context in
            let elapsed = startTime.map { context.date.timeIntervalSince($0) } ?? 0
            let delayed = max(0, elapsed - flame.delay)
            let cycle = delayed / flame.duration
            let fraction = cycle - floor(cycle)
            let isReversed = Int(cycle) % 2 == 1
            let t = CGFloat(isReversed ? 1 - fraction : fraction)
            let kf = interpolateKeyframes(keyframesFor(flame.anim), at: t)

            flamePath
                .fill(flame.color.opacity(flame.opacity))
                .blur(radius: flame.blur)
                .opacity(kf.opacity)
                .scaleEffect(x: 1.0, y: kf.scaleY, anchor: .bottom)
                .offset(y: kf.translateY)
                .transformEffect(CGAffineTransform(
                    a: 1, b: 0,
                    c: tan(kf.skewX * .pi / 180), d: 1,
                    tx: 0, ty: 0
                ))
        }
        .onAppear { startTime = Date() }
    }

    private var flamePath: Path {
        let sx = frameW / viewW
        let sy = frameH / viewH
        var path = Path()
        for cmd in flame.points {
            switch cmd {
            case .M(let x, let y):
                path.move(to: CGPoint(x: x * sx, y: y * sy))
            case .Q(let cx, let cy, let ex, let ey):
                path.addQuadCurve(
                    to: CGPoint(x: ex * sx, y: ey * sy),
                    control: CGPoint(x: cx * sx, y: cy * sy)
                )
            }
        }
        path.closeSubpath()
        return path
    }
}
