import SwiftUI

// MARK: - Palette (spectrum; sanctioned candle exception to outline-only OB rule)
enum CandlePalette {
    static let cyan    = Color(red: 0,     green: 0.761, blue: 1)
    static let purple  = Color(red: 0.424, green: 0.227, blue: 0.878)
    static let magenta = Color(red: 1,     green: 0,     blue: 0.416)
}

// MARK: - Noise (verbatim port of mockup smoothNoise/fbm)
enum CandleNoise {
    static func smooth(_ t: Double, seed: Double = 0) -> Double {
        let p = t + seed * 127.1
        let i = floor(p)
        let f = p - i
        let fc = f * f * (3 - 2 * f)
        let a = sin(i * 127.1 + 311.7) * 43758.5453
        let b = sin((i + 1) * 127.1 + 311.7) * 43758.5453
        return (a - floor(a)) * (1 - fc) + (b - floor(b)) * fc
    }
    static func fbm(_ t: Double, seed: Double = 0, octaves: Int = 4) -> Double {
        var v = 0.0, amp = 0.5, freq = 1.0, maxV = 0.0
        for o in 0..<octaves {
            v += smooth(t * freq, seed: seed + Double(o)) * amp
            maxV += amp; amp *= 0.5; freq *= 2.1
        }
        return v / maxV
    }
}

// MARK: - Geometry (verbatim port of getGeo)
struct CandleGeo {
    let bW, bH, cx, bY, bBY, bL, bR, wickH, wickBot, wickTip, wickTipX: CGFloat
    init(w: CGFloat, h: CGFloat) {
        let S = w / 160
        bW = w * 0.33
        bH = h * 0.46
        cx = w / 2
        bY = h * 0.28
        bBY = bY + bH
        bL = cx - bW / 2
        bR = cx + bW / 2
        wickH = bH * 0.072
        wickBot = bY + 4.0 * S
        wickTip = wickBot - wickH
        wickTipX = cx + 1.2 * S
    }
}

// MARK: - Tapered run (verbatim port of buildTaperedRun)
// Builds a closed Path from a quadratic spine with per-point width.
func candleTaperedRun(sx: CGFloat, sy: CGFloat, endX: CGFloat, endY: CGFloat,
                      cpx: CGFloat, cpy: CGFloat, wStart: CGFloat, wEnd: CGFloat,
                      steps: Int = 16) -> Path {
    var left: [CGPoint] = [], right: [CGPoint] = []
    for i in 0...steps {
        let u = CGFloat(i) / CGFloat(steps), mu = 1 - u
        let px = mu*mu*sx + 2*mu*u*cpx + u*u*endX
        let py = mu*mu*sy + 2*mu*u*cpy + u*u*endY
        let tx = 2*mu*(cpx - sx) + 2*u*(endX - cpx)
        let ty = 2*mu*(cpy - sy) + 2*u*(endY - cpy)
        let len = max(sqrt(tx*tx + ty*ty), 1)
        let w = wStart + (wEnd - wStart) * u
        let nx = -ty/len, ny = tx/len
        left.append(CGPoint(x: px + nx*w/2, y: py + ny*w/2))
        right.append(CGPoint(x: px - nx*w/2, y: py - ny*w/2))
    }
    var p = Path()
    p.move(to: left[0])
    left.forEach { p.addLine(to: $0) }
    right.reversed().forEach { p.addLine(to: $0) }
    p.closeSubpath()
    return p
}

// MARK: - The face
struct CandleCardFace: View {
    let intensity: CandleIntensity
    var time: Double = 0
    var reduceMotion: Bool = false

    var body: some View {
        Canvas { ctx, size in
            CandleRenderer.draw(into: &ctx, size: size,
                                intensity: intensity, time: time,
                                reduceMotion: reduceMotion)
        }
        .drawingGroup()   // CLAUDE.md: required on card faces — never remove
    }
}

enum CandleRenderer {

    static func spectrum(_ g: CandleGeo, topY: CGFloat, botY: CGFloat) -> GraphicsContext.Shading {
        .linearGradient(
            Gradient(stops: [
                .init(color: CandlePalette.cyan,    location: 0),
                .init(color: CandlePalette.purple,  location: 0.5),
                .init(color: CandlePalette.magenta, location: 1),
            ]),
            startPoint: CGPoint(x: g.cx, y: topY),
            endPoint:   CGPoint(x: g.cx, y: botY))
    }

    static func draw(into ctx: inout GraphicsContext, size: CGSize,
                     intensity: CandleIntensity, time t: Double, reduceMotion: Bool) {
        let w = size.width, h = size.height, S = w / 160
        let g = CandleGeo(w: w, h: h)
        let body = bodyPath(g, S: S, intensity: intensity)
        let bodyShade = spectrum(g, topY: g.bY, botY: g.bBY)

        // Crisp body stroke
        ctx.stroke(body, with: bodyShade,
                   style: StrokeStyle(lineWidth: 1.30 * S, lineCap: .square, lineJoin: .miter))

        // Crisp flame edges, static for now
        let flame = flameEdges(g, S: S, intensity: intensity, t: t)
        let flameShade = spectrum(g, topY: flame.tipY, botY: g.wickTip)
        ctx.stroke(flame.left,  with: flameShade,
                   style: StrokeStyle(lineWidth: 1.60 * S, lineCap: .round))
        ctx.stroke(flame.right, with: flameShade,
                   style: StrokeStyle(lineWidth: 1.60 * S, lineCap: .round))
    }

    // Curious/Exploring = bowed cylinder.
    static func bodyPath(_ g: CandleGeo, S: CGFloat, intensity: CandleIntensity) -> Path {
        var p = Path()
        let bow = g.bW * 0.04, midY = g.bY + g.bH * 0.5
        p.move(to: CGPoint(x: g.bL, y: g.bY))
        p.addCurve(to: CGPoint(x: g.bL, y: g.bBY),
                   control1: CGPoint(x: g.bL - bow, y: midY - g.bH*0.12),
                   control2: CGPoint(x: g.bL - bow, y: midY + g.bH*0.12))
        p.addLine(to: CGPoint(x: g.bR, y: g.bBY))
        p.addCurve(to: CGPoint(x: g.bR, y: g.bY),
                   control1: CGPoint(x: g.bR + bow, y: midY + g.bH*0.12),
                   control2: CGPoint(x: g.bR + bow, y: midY - g.bH*0.12))
        p.closeSubpath()
        return p
        // NOTE: experienced (notched/dripping) body added in a later task.
    }

    // Returns the two flame silhouette curves + the computed tip. Static (t=0).
    static func flameEdges(_ g: CandleGeo, S: CGFloat, intensity: CandleIntensity, t: Double)
        -> (left: Path, right: Path, tipY: CGFloat) {
        let cfg = FlameCfg.of(intensity)
        let flameH = g.bH * cfg.baseH
        let flameW = g.bW * cfg.baseW
        let fH = flameH
        let tipX = g.wickTipX
        let tipY = g.wickTip - fH
        let fWL = flameW, fWR = flameW * 0.72
        var lp = Path()
        lp.move(to: CGPoint(x: g.wickTipX, y: g.wickTip))
        lp.addCurve(to: CGPoint(x: tipX, y: tipY),
                    control1: CGPoint(x: g.wickTipX - fWL*1.08, y: g.wickTip - fH*0.32),
                    control2: CGPoint(x: g.wickTipX - fWL*0.52, y: tipY + fH*0.14))
        var rp = Path()
        rp.move(to: CGPoint(x: g.wickTipX, y: g.wickTip))
        rp.addCurve(to: CGPoint(x: tipX, y: tipY),
                    control1: CGPoint(x: g.wickTipX + fWR*1.02, y: g.wickTip - fH*0.28),
                    control2: CGPoint(x: tipX + fWR*0.42, y: tipY + fH*0.12))
        return (lp, rp, tipY)
    }
}

// Per-intensity flame config — verbatim port of FLAME_CFG.
struct FlameCfg {
    let baseH, baseW, crispAlpha, glowAlpha, swayAmp, swayFreq, flickerAmp, turbFreq, innerScale, innerAlpha: Double
    let dim: Bool
    let hasNotch: Bool
    static func of(_ i: CandleIntensity) -> FlameCfg {
        switch i {
        case .curious:     return .init(baseH:0.20, baseW:0.36, crispAlpha:0.38, glowAlpha:0.07, swayAmp:0.58, swayFreq:0.26, flickerAmp:0.55, turbFreq:1.8, innerScale:0.32, innerAlpha:0.42, dim:true,  hasNotch:false)
        case .exploring:   return .init(baseH:0.42, baseW:0.54, crispAlpha:0.94, glowAlpha:0.40, swayAmp:0.12, swayFreq:0.55, flickerAmp:0.07, turbFreq:2.1, innerScale:0.52, innerAlpha:0.80, dim:false, hasNotch:false)
        case .experienced: return .init(baseH:0.42, baseW:0.54, crispAlpha:0.94, glowAlpha:0.40, swayAmp:0.14, swayFreq:0.55, flickerAmp:0.09, turbFreq:2.4, innerScale:0.52, innerAlpha:0.80, dim:false, hasNotch:true)
        }
    }
}

#Preview("Candle — exploring @177pt") {
    ZStack {
        Color.black
        CandleCardFace(intensity: .exploring)
            .frame(width: 177, height: 177 * 1.5)
    }
    .ignoresSafeArea()
}
