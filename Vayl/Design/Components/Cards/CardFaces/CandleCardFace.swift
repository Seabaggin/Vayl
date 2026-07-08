import SwiftUI

// MARK: - Palette (spectrum; sanctioned candle exception to outline-only OB rule)
// Verbatim-matches AppColors.spectrumCyan/Purple/Magenta (#00C2FF / #6C3AE0 / #FF006A) —
// aliased rather than duplicated as raw literals.
enum CandlePalette {
    static let cyan    = AppColors.spectrumCyan
    static let purple  = AppColors.spectrumPurple
    static let magenta = AppColors.spectrumMagenta
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

    /// Rest scale = the candle at full size; contracted scale = the bottom of an inhale.
    /// Kept small (~1.5%) so the breath reads as quiet life, not a pulse.
    private static let restScale: CGFloat = 1.0
    private static let contractedScale: CGFloat = 0.985

    @State private var contracted = false
    @State private var breatheTask: Task<Void, Never>?

    /// Subtle breathing scale applied to every candle (all three intensities) so the
    /// hand reads as one living set. Driven intermittently (see runBreathing).
    private var breatheScale: CGFloat {
        guard !reduceMotion else { return Self.restScale }
        return contracted ? Self.contractedScale : Self.restScale
    }

    var body: some View {
        Canvas { ctx, size in
            CandleRenderer.draw(into: &ctx, size: size,
                                intensity: intensity, time: time,
                                reduceMotion: reduceMotion)
        }
        .scaleEffect(breatheScale)
        .drawingGroup()   // CLAUDE.md: required on card faces — never remove
        .onAppear { runBreathing() }
        .onDisappear { breatheTask?.cancel() }
    }

    /// Intermittent breath loop: inhale → exhale → rest, repeat. Unlike a continuous
    /// repeatForever autoreverse, the rest between breaths makes the motion occasional
    /// and calm. A small random start offset keeps the three cards out of lockstep.
    /// Skipped entirely under Reduce Motion.
    private func runBreathing() {
        guard !reduceMotion else { return }
        breatheTask?.cancel()
        breatheTask = Task { @MainActor in
            // Desync the fan so the three candles don't breathe in unison.
            try? await Task.sleep(for: .seconds(Double.random(in: 0...AppAnimation.candleBreathHold)))
            let breath: Animation = .easeInOut(duration: AppAnimation.candleBreathDuration)
            while !Task.isCancelled {
                withAnimation(breath) { contracted = true }   // inhale
                try? await Task.sleep(for: .seconds(AppAnimation.candleBreathDuration))
                withAnimation(breath) { contracted = false }  // exhale
                try? await Task.sleep(for: .seconds(AppAnimation.candleBreathDuration))
                // Intermittent rest before the next breath.
                try? await Task.sleep(for: .seconds(AppAnimation.candleBreathHold))
            }
        }
    }
}

enum CandleRenderer {

    // MARK: - Shading helpers

    static func spectrum(_ g: CandleGeo, topY: CGFloat, botY: CGFloat) -> GraphicsContext.Shading {
        .linearGradient(
            Gradient(stops: [
                .init(color: CandlePalette.cyan, location: 0),
                .init(color: CandlePalette.purple, location: 0.5),
                .init(color: CandlePalette.magenta, location: 1)
            ]),
            startPoint: CGPoint(x: g.cx, y: topY),
            endPoint: CGPoint(x: g.cx, y: botY))
    }

    // MARK: - Body paths

    // Verbatim port of bodyPath() from mockup — both branches
    static func bodyPath(_ g: CandleGeo, S: CGFloat, intensity: CandleIntensity) -> Path {
        var p = Path()
        if intensity == .curious || intensity == .exploring {
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
        } else {
            // experienced: notched/dripping silhouette
            let l1Y = g.bY + g.bH * 0.20
            let l2Y = g.bY + g.bH * 0.50
            let l1X = g.bL - g.bW * 0.10
            let l2X = g.bL - g.bW * 0.07
            let r1Y = g.bY + g.bH * 0.36
            let r1X = g.bR + g.bW * 0.06
            p.move(to: CGPoint(x: g.bL + 2*S, y: g.bY))
            p.addCurve(to: CGPoint(x: l1X, y: l1Y),
                       control1: CGPoint(x: g.bL - g.bW*0.03, y: l1Y - g.bH*0.07),
                       control2: CGPoint(x: l1X + g.bW*0.04, y: l1Y - g.bH*0.03))
            p.addCurve(to: CGPoint(x: g.bL - g.bW*0.03, y: l2Y - g.bH*0.06),
                       control1: CGPoint(x: l1X - g.bW*0.01, y: l1Y + g.bH*0.05),
                       control2: CGPoint(x: g.bL - g.bW*0.015, y: l1Y + g.bH*0.10))
            p.addCurve(to: CGPoint(x: l2X, y: l2Y),
                       control1: CGPoint(x: l2X - g.bW*0.02, y: l2Y - g.bH*0.02),
                       control2: CGPoint(x: l2X, y: l2Y))
            p.addCurve(to: CGPoint(x: g.bL, y: g.bBY),
                       control1: CGPoint(x: l2X, y: l2Y + g.bH*0.04),
                       control2: CGPoint(x: g.bL - g.bW*0.01, y: l2Y + g.bH*0.10))
            p.addLine(to: CGPoint(x: g.bR, y: g.bBY))
            p.addCurve(to: CGPoint(x: r1X, y: r1Y),
                       control1: CGPoint(x: g.bR + g.bW*0.014, y: l2Y + g.bH*0.08),
                       control2: CGPoint(x: r1X - g.bW*0.02, y: r1Y + g.bH*0.04))
            p.addCurve(to: CGPoint(x: g.bR - 2*S, y: g.bY),
                       control1: CGPoint(x: r1X + g.bW*0.01, y: r1Y - g.bH*0.04),
                       control2: CGPoint(x: g.bR + g.bW*0.03, y: g.bY + g.bH*0.18))
            p.closeSubpath()
        }
        return p
    }

    // MARK: - Rim / pool paths

    // Verbatim port of topRim()
    static func topRim(_ g: CandleGeo, S: CGFloat, intensity: CandleIntensity) -> Path {
        var p = Path()
        switch intensity {
        case .curious:
            p.move(to: CGPoint(x: g.bL, y: g.bY))
            p.addLine(to: CGPoint(x: g.bR, y: g.bY))
        case .exploring:
            p.move(to: CGPoint(x: g.bL, y: g.bY))
            p.addCurve(to: CGPoint(x: g.cx, y: g.bY + 7.5*S),
                       control1: CGPoint(x: g.bL + g.bW*0.20, y: g.bY + 7.5*S),
                       control2: CGPoint(x: g.cx - g.bW*0.08, y: g.bY + 7.5*S))
            p.addCurve(to: CGPoint(x: g.bR, y: g.bY + 1.0*S),
                       control1: CGPoint(x: g.cx + g.bW*0.12, y: g.bY + 7.5*S),
                       control2: CGPoint(x: g.bR - g.bW*0.16, y: g.bY + 3.0*S))
        case .experienced:
            p.move(to: CGPoint(x: g.bL - g.bW*0.08, y: g.bY + 2*S))
            p.addCurve(to: CGPoint(x: g.cx, y: g.bY + 11.0*S),
                       control1: CGPoint(x: g.bL + g.bW*0.14, y: g.bY + 10.0*S),
                       control2: CGPoint(x: g.cx - g.bW*0.12, y: g.bY + 11.0*S))
            p.addCurve(to: CGPoint(x: g.bR + g.bW*0.04, y: g.bY + 2*S),
                       control1: CGPoint(x: g.cx + g.bW*0.10, y: g.bY + 11.0*S),
                       control2: CGPoint(x: g.bR - g.bW*0.10, y: g.bY + 5.5*S))
        }
        return p
    }

    // Verbatim port of waxPool()
    static func waxPool(_ g: CandleGeo, S: CGFloat, intensity: CandleIntensity) -> Path {
        switch intensity {
        case .exploring:
            return Path(ellipseIn: CGRect(x: g.cx - g.bW*0.44,
                                          y: g.bY + 7.5*S - 3.2*S,
                                          width: g.bW*0.44*2,
                                          height: 3.2*S*2))
        default: // experienced
            // ellipse(cx-bW*0.04, bY+10.8*S, bW*0.42, 4.2*S, -0.06, ...)
            // rotation -0.06 rad — apply via CGAffineTransform
            let cx = g.cx - g.bW*0.04
            let cy = g.bY + 10.8*S
            let rx = g.bW * 0.42
            let ry = 4.2 * S
            let ellipseRect = CGRect(x: cx - rx, y: cy - ry, width: rx*2, height: ry*2)
            let unrotated = Path(ellipseIn: ellipseRect)
            let transform = CGAffineTransform(translationX: cx, y: cy)
                .rotated(by: -0.06)
                .translatedBy(x: -cx, y: -cy)
            return unrotated.applying(transform)
        }
    }

    // MARK: - Flame edges (verbatim port of leftEdge/rightEdge)
    // Returns the two flame silhouette curves + the computed tip.
    static func flameEdges(_ g: CandleGeo, S: CGFloat, intensity: CandleIntensity, t: Double)
        // swiftlint:disable:next large_tuple
        -> (left: Path, right: Path, tipX: CGFloat, tipY: CGFloat,
            fH: CGFloat, fWL: CGFloat, fWR: CGFloat,
            slowSway: Double, midTurb: Double, fastFlick: Double) {
        let cfg = FlameCfg.of(intensity)
        let flameH = g.bH * CGFloat(cfg.baseH)
        let flameW = g.bW * CGFloat(cfg.baseW)
        // t-based noise (static at t=0; preserved for future animation)
        let slowSway = (CandleNoise.fbm(t * cfg.swayFreq, seed: 0) - 0.5) * 2
        let midTurb  = (CandleNoise.fbm(t * cfg.turbFreq, seed: 1) - 0.5) * 2
        let fastFlick = (CandleNoise.fbm(t * 9.2, seed: 2) - 0.5) * 2
        let sway = CGFloat(slowSway * cfg.swayAmp) * flameW
        let flicker = fastFlick * cfg.flickerAmp
        let heightMod = 1.0 - abs(flicker) * 0.22 + midTurb * 0.06
        let fH = flameH * CGFloat(heightMod)
        let tipX = g.wickTipX + sway
        let tipY = g.wickTip - fH
        let breathe = 1.0 + CGFloat(midTurb) * 0.06
        let fWL = flameW * breathe
        let fWR = flameW * breathe * 0.72

        var lp = Path()
        lp.move(to: CGPoint(x: g.wickTipX, y: g.wickTip))
        if cfg.hasNotch {
            let notchY = g.wickTip - fH * 0.58
            let notchIn = fWL * 0.10 * CGFloat(1 + midTurb * 0.3)
            lp.addCurve(to: CGPoint(x: g.wickTipX - fWL*0.50 + notchIn, y: notchY),
                        control1: CGPoint(x: g.wickTipX - fWL * CGFloat(1.05 + slowSway*0.12),
                                          y: g.wickTip - fH*0.28),
                        control2: CGPoint(x: g.wickTipX - fWL * CGFloat(0.82 + slowSway*0.08),
                                          y: notchY + fH*0.06))
            lp.addCurve(to: CGPoint(x: tipX, y: tipY),
                        control1: CGPoint(x: g.wickTipX - fWL*0.22, y: notchY - fH*0.08),
                        control2: CGPoint(x: tipX - fWL*0.12, y: tipY + fH*0.08))
        } else {
            let cm = CGFloat(slowSway * 0.15)
            lp.addCurve(to: CGPoint(x: tipX, y: tipY),
                        control1: CGPoint(x: g.wickTipX - fWL * (1.08 + cm),
                                          y: g.wickTip - fH*0.32),
                        control2: CGPoint(x: g.wickTipX - fWL * (0.52 + cm*0.5),
                                          y: tipY + fH*0.14))
        }

        var rp = Path()
        rp.move(to: CGPoint(x: g.wickTipX, y: g.wickTip))
        rp.addCurve(to: CGPoint(x: tipX, y: tipY),
                    control1: CGPoint(x: g.wickTipX + fWR * CGFloat(1.02 + slowSway*0.08),
                                      y: g.wickTip - fH*0.28),
                    control2: CGPoint(x: tipX + fWR*0.42, y: tipY + fH*0.12))

        return (lp, rp, tipX, tipY, fH, fWL, fWR, slowSway, midTurb, fastFlick)
    }

    // MARK: - Inner core (verbatim port of innerCore())
    static func innerCore(_ g: CandleGeo, S: CGFloat, cfg: FlameCfg,
                          fH: CGFloat, fWL: CGFloat, fWR: CGFloat,
                          sway: CGFloat, midTurb: Double,
                          wickTipX: CGFloat, wickTip: CGFloat) -> (left: Path, right: Path) {
        let darkZoneH = fH * 0.08
        let iS = CGFloat(cfg.innerScale)
        let iH = fH * 0.72
        let cBaseY = wickTip - darkZoneH
        let iTipY = wickTip - iH
        let iTipX = wickTipX + sway * 0.52

        var lI = Path()
        lI.move(to: CGPoint(x: wickTipX, y: cBaseY))
        lI.addCurve(to: CGPoint(x: iTipX, y: iTipY),
                    control1: CGPoint(x: wickTipX - fWL*iS*0.80, y: wickTip - iH*0.35),
                    control2: CGPoint(x: iTipX - fWL*iS*0.26, y: iTipY + iH*0.18))

        var rI = Path()
        rI.move(to: CGPoint(x: wickTipX, y: cBaseY))
        rI.addCurve(to: CGPoint(x: iTipX, y: iTipY),
                    control1: CGPoint(x: wickTipX + fWR*iS*0.78, y: wickTip - iH*0.30),
                    control2: CGPoint(x: iTipX + fWR*iS*0.24, y: iTipY + iH*0.15))

        return (lI, rI)
    }

    // MARK: - Drip builder (verbatim port of buildDrip)
    static func buildDrip(_ g: CandleGeo, S: CGFloat,
                          sx: CGFloat, sy: CGFloat,
                          length: CGFloat, lean: CGFloat,
                          sc: CGFloat = 1.0, tPulse: Double = 0)
        -> (shoulder: Path, run: Path, term: Path) {
        let sW = g.bW * 0.085 * sc
        let endX = sx + lean
        let endY = sy + length
        let cpx = sx + lean * 0.42
        let cpy = sy + length * 0.52

        var shoulder = Path()
        shoulder.move(to: CGPoint(x: sx, y: sy - sW*0.44))
        shoulder.addCurve(to: CGPoint(x: sx + lean*0.09, y: sy + sW*0.52),
                          control1: CGPoint(x: sx + sW*0.66, y: sy - sW*0.30),
                          control2: CGPoint(x: sx + sW*0.72, y: sy + sW*0.36))
        shoulder.addCurve(to: CGPoint(x: sx, y: sy - sW*0.44),
                          control1: CGPoint(x: sx - sW*0.10, y: sy + sW*0.66),
                          control2: CGPoint(x: sx - sW*0.68, y: sy + sW*0.24))
        shoulder.closeSubpath()

        let run = candleTaperedRun(sx: sx + lean*0.07, sy: sy + sW*0.38,
                                   endX: endX, endY: endY,
                                   cpx: cpx, cpy: cpy,
                                   wStart: 2.8 * sc * S, wEnd: 0.50 * S)

        let tR = g.bW * 0.048 * sc
        let pulse = CGFloat(1.0 + sin(tPulse) * 0.12)
        let pR = tR * pulse

        var term = Path()
        term.move(to: CGPoint(x: endX, y: endY - pR*0.30))
        term.addCurve(to: CGPoint(x: endX, y: endY + pR*1.50),
                      control1: CGPoint(x: endX + pR*0.90, y: endY),
                      control2: CGPoint(x: endX + pR*0.62, y: endY + pR*1.30))
        term.addCurve(to: CGPoint(x: endX, y: endY - pR*0.30),
                      control1: CGPoint(x: endX - pR*0.62, y: endY + pR*1.30),
                      control2: CGPoint(x: endX - pR*0.90, y: endY))
        term.closeSubpath()

        return (shoulder, run, term)
    }

    // MARK: - Shading builders
    // Extracted from `draw` so the main draw method stays under the type-check
    // limit — these multi-stop gradient literals are otherwise inline cost.

    /// Warm gold → magenta → purple → cyan, wick base to flame tip.
    static func flameWarmShading(g: CandleGeo, tipY: CGFloat) -> GraphicsContext.Shading {
        GraphicsContext.Shading.linearGradient(
            Gradient(stops: [
                .init(color: Color(red: 1, green: 0.843, blue: 0.314), location: 0.0),
                .init(color: CandlePalette.magenta, location: 0.3),
                .init(color: CandlePalette.purple, location: 0.7),
                .init(color: CandlePalette.cyan, location: 1.0)
            ]),
            startPoint: CGPoint(x: g.cx, y: g.wickTip),
            endPoint: CGPoint(x: g.cx, y: tipY))
    }

    /// Soft purple radial bloom behind the candle body (non-dim intensities).
    static func warmAmbientShading(g: CandleGeo, glowAlpha: Double) -> GraphicsContext.Shading {
        GraphicsContext.Shading.radialGradient(
            Gradient(stops: [
                .init(color: Color(red: 0.424, green: 0.227, blue: 0.878,
                                   opacity: glowAlpha * 0.22), location: 0.0),
                .init(color: Color(red: 0.424, green: 0.227, blue: 0.878,
                                   opacity: glowAlpha * 0.04), location: 0.6),
                .init(color: Color(red: 0.424, green: 0.227, blue: 0.878,
                                   opacity: 0), location: 1.0)
            ]),
            center: CGPoint(x: g.cx, y: g.bY),
            startRadius: 0,
            endRadius: g.bW * 2.8)
    }

    // MARK: - Main draw (full mockup draw order, line 76–95)
    static func draw(into ctx: inout GraphicsContext, size: CGSize,
                     intensity: CandleIntensity, time: Double, reduceMotion: Bool) {
        // Single chokepoint: all motion-driven math flows through `t`.
        // When Reduce Motion is on, t=0 yields a calm, static representative frame.
        let t = reduceMotion ? 0.0 : time
        let w = size.width, h = size.height, S = w / 160
        let g = CandleGeo(w: w, h: h)
        let cfg = FlameCfg.of(intensity)

        // Exploring/experienced carry tall flames that push their visual mass upward,
        // so the lit silhouette reads as sitting too high. Nudge the whole candle down
        // so the flame-to-body composition is vertically centered in the card. Curious
        // has only a tiny flame + smoke wisp, so it already reads centered (no nudge).
        if intensity != .curious {
            ctx.translateBy(x: 0, y: h * 0.06)
        }

        let bodyShade = spectrum(g, topY: g.bY, botY: g.bBY)
        let body = bodyPath(g, S: S, intensity: intensity)

        // Compute flame geometry (carries noise; static at t=0)
        let flame = flameEdges(g, S: S, intensity: intensity, t: t)
        let tipX  = flame.tipX, tipY = flame.tipY
        let fH = flame.fH, fWL = flame.fWL, fWR = flame.fWR
        let slowSway = flame.slowSway
        let midTurb  = flame.midTurb
        let fastFlick = flame.fastFlick
        let sway = CGFloat(slowSway * cfg.swayAmp) * g.bW * CGFloat(cfg.baseW)

        let baseAlpha = cfg.crispAlpha * (1.0 - abs(fastFlick) * cfg.flickerAmp * 1.3)
        let glowAlpha  = cfg.glowAlpha * (1.0 - abs(fastFlick) * cfg.flickerAmp * 1.1)

        // flameGrad: cyan → purple → magenta, tip to wick base
        let flameShade = spectrum(g, topY: tipY, botY: g.wickTip)
        // flameGradWarm: warm gold → magenta → purple → cyan (bottom to top, i.e. wick to tip)
        let flameWarmShade = flameWarmShading(g: g, tipY: tipY)

        // ------------------------------------------------------------------
        // PASS 1 — Ambient warm radial (non-dim intensities only) [line 76]
        // ------------------------------------------------------------------
        if !cfg.dim {
            let warmShade = warmAmbientShading(g: g, glowAlpha: glowAlpha)
            ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)), with: warmShade)
        }

        // ------------------------------------------------------------------
        // PASS 2 — Blurred flame glow [line 77]
        // ------------------------------------------------------------------
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: CGFloat(cfg.dim ? 6 : 12) * S))
            layer.opacity = glowAlpha * (1 + midTurb * 0.14)
            layer.stroke(flame.left, with: flameShade,
                         style: StrokeStyle(lineWidth: CGFloat(cfg.dim ? 5 : 12) * S,
                                            lineCap: .round))
            layer.stroke(flame.right, with: flameShade,
                         style: StrokeStyle(lineWidth: CGFloat(cfg.dim ? 5 : 12) * S,
                                            lineCap: .round))
        }

        // ------------------------------------------------------------------
        // PASS 3 — Blurred body glow [line 78]
        // ------------------------------------------------------------------
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 6 * S))
            layer.opacity = cfg.dim ? 0.13 : 0.28
            layer.stroke(body, with: bodyShade,
                         style: StrokeStyle(lineWidth: 10 * S))
        }

        // ------------------------------------------------------------------
        // PASS 4 — Experienced extra body glow [line 79]
        // ------------------------------------------------------------------
        if intensity == .experienced {
            ctx.drawLayer { layer in
                layer.addFilter(.blur(radius: 3.5 * S))
                layer.opacity = 0.15
                layer.stroke(body, with: bodyShade,
                             style: StrokeStyle(lineWidth: 5 * S))
            }
        }

        // ------------------------------------------------------------------
        // PASS 5 — Curious cylinder fill [line 80]
        // ------------------------------------------------------------------
        if intensity == .curious {
            ctx.drawLayer { layer in
                layer.clip(to: body)
                // base fill
                let baseFill = GraphicsContext.Shading.linearGradient(
                    Gradient(stops: [
                        .init(color: Color(red: 0, green: 0.235, blue: 0.314, opacity: 0.22), location: 0.0),
                        .init(color: Color(red: 0.118, green: 0, blue: 0.235, opacity: 0.28), location: 0.5),
                        .init(color: Color(red: 0.235, green: 0, blue: 0.118, opacity: 0.22), location: 1.0)
                    ]),
                    startPoint: CGPoint(x: g.cx, y: g.bY),
                    endPoint: CGPoint(x: g.cx, y: g.bBY))
                layer.fill(Path(CGRect(x: g.bL - 2*S, y: g.bY, width: g.bW + 4*S, height: g.bH)),
                           with: baseFill)
                // cylinder light (horizontal)
                let cylLight = GraphicsContext.Shading.linearGradient(
                    Gradient(stops: [
                        .init(color: Color(red: 0, green: 0, blue: 0, opacity: 0.15), location: 0.00),
                        .init(color: Color(red: 0.392, green: 0.627, blue: 0.784, opacity: 0.18), location: 0.22),
                        .init(color: Color(red: 0.235, green: 0.314, blue: 0.549, opacity: 0.10), location: 0.42),
                        .init(color: Color(red: 0.078, green: 0, blue: 0.157, opacity: 0.08), location: 0.70),
                        .init(color: Color(red: 0, green: 0, blue: 0, opacity: 0.28), location: 1.00)
                    ]),
                    startPoint: CGPoint(x: g.bL, y: g.bY),
                    endPoint: CGPoint(x: g.bR, y: g.bY))
                layer.fill(Path(CGRect(x: g.bL - 2*S, y: g.bY, width: g.bW + 4*S, height: g.bH)),
                           with: cylLight)
                // top-to-bottom gradient light
                let topLight = GraphicsContext.Shading.linearGradient(
                    Gradient(stops: [
                        .init(color: Color(red: 0.314, green: 0.471, blue: 0.627, opacity: 0.12), location: 0.00),
                        .init(color: Color(red: 0.157, green: 0.078, blue: 0.314, opacity: 0.06), location: 0.35),
                        .init(color: Color(red: 0, green: 0, blue: 0, opacity: 0.10), location: 1.00)
                    ]),
                    startPoint: CGPoint(x: g.cx, y: g.bY),
                    endPoint: CGPoint(x: g.cx, y: g.bBY))
                layer.fill(Path(CGRect(x: g.bL - 2*S, y: g.bY, width: g.bW + 4*S, height: g.bH)),
                           with: topLight)
            }
        }

        // ------------------------------------------------------------------
        // PASS 6 — Crisp body stroke [line 81]
        // ------------------------------------------------------------------
        ctx.drawLayer { layer in
            layer.opacity = intensity == .curious ? 0.82 : 0.88
            let lw = intensity == .experienced ? 1.50 * S : 1.30 * S
            layer.stroke(body, with: bodyShade,
                         style: StrokeStyle(lineWidth: lw, lineCap: .square, lineJoin: .miter))
        }

        // ------------------------------------------------------------------
        // PASS 7 — Top rim blurred glow (non-curious) [line 82]
        // ------------------------------------------------------------------
        let rim = topRim(g, S: S, intensity: intensity)
        if intensity != .curious {
            ctx.drawLayer { layer in
                layer.addFilter(.blur(radius: 3 * S))
                layer.opacity = intensity == .experienced ? 0.32 : 0.18
                let lw: CGFloat = intensity == .experienced ? 6 * S : 4 * S
                layer.stroke(rim, with: bodyShade,
                             style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))
            }
        }

        // ------------------------------------------------------------------
        // PASS 8 — Crisp top rim [line 83]
        // ------------------------------------------------------------------
        ctx.drawLayer { layer in
            switch intensity {
            case .curious:
                layer.opacity = 0.70
                layer.stroke(rim, with: bodyShade,
                             style: StrokeStyle(lineWidth: 1.30 * S, lineCap: .square, lineJoin: .round))
            case .exploring:
                layer.opacity = 0.84
                layer.stroke(rim, with: bodyShade,
                             style: StrokeStyle(lineWidth: 1.15 * S, lineCap: .round, lineJoin: .round))
            case .experienced:
                layer.opacity = 0.92
                layer.stroke(rim, with: bodyShade,
                             style: StrokeStyle(lineWidth: 1.50 * S, lineCap: .round, lineJoin: .round))
            }
        }

        // ------------------------------------------------------------------
        // PASS 9 — Wax pool glow + crisp stroke + experienced inner pool [line 84]
        // ------------------------------------------------------------------
        if intensity != .curious {
            let pool = waxPool(g, S: S, intensity: intensity)
            // blurred glow
            ctx.drawLayer { layer in
                layer.addFilter(.blur(radius: 3 * S))
                layer.opacity = 0.18
                layer.stroke(pool, with: bodyShade,
                             style: StrokeStyle(lineWidth: 4.5 * S))
            }
            // crisp
            ctx.drawLayer { layer in
                layer.opacity = intensity == .experienced ? 0.54 : 0.42
                let lw: CGFloat = intensity == .experienced ? 1.20 * S : 0.85 * S
                layer.stroke(pool, with: bodyShade,
                             style: StrokeStyle(lineWidth: lw))
            }
            // experienced inner pool highlight
            if intensity == .experienced {
                // inner pool ellipse (small, slightly rotated)
                let ipCX = g.cx - g.bW*0.04, ipCY = g.bY + 10.8*S
                let ipRX = g.bW*0.20, ipRY = 2.0*S
                let ipRect = CGRect(x: ipCX - ipRX, y: ipCY - ipRY, width: ipRX*2, height: ipRY*2)
                let ipRaw = Path(ellipseIn: ipRect)
                let ipTransform = CGAffineTransform(translationX: ipCX, y: ipCY)
                    .rotated(by: -0.06)
                    .translatedBy(x: -ipCX, y: -ipCY)
                let ip = ipRaw.applying(ipTransform)
                ctx.drawLayer { layer in
                    layer.opacity = 0.28
                    layer.stroke(ip, with: bodyShade,
                                 style: StrokeStyle(lineWidth: 0.70 * S))
                }
                // white specular highlight ellipse fill
                // ctx.beginPath(); ctx.ellipse(cx-bW*0.09,bY+8.0*S,bW*0.13,1.4*S,-0.12,...)
                let hlCX = g.cx - g.bW*0.09, hlCY = g.bY + 8.0*S
                let hlRX = g.bW*0.13, hlRY = 1.4*S
                let hlRect = CGRect(x: hlCX - hlRX, y: hlCY - hlRY, width: hlRX*2, height: hlRY*2)
                let hlRaw = Path(ellipseIn: hlRect)
                let hlTransform = CGAffineTransform(translationX: hlCX, y: hlCY)
                    .rotated(by: -0.12)
                    .translatedBy(x: -hlCX, y: -hlCY)
                let hl = hlRaw.applying(hlTransform)
                ctx.drawLayer { layer in
                    layer.opacity = 0.20
                    layer.fill(hl, with: .color(Color(red: 0.910, green: 0.894, blue: 0.871)))
                }
            }
        }

        // ------------------------------------------------------------------
        // PASS 10 — Texture lines [line 85]
        // ------------------------------------------------------------------
        if intensity != .curious {
            let texLines: [(x: CGFloat, y: CGFloat, w: CGFloat, op: CGFloat)]
            if intensity == .experienced {
                texLines = [
                    (g.bL + g.bW*0.08, g.bY + g.bH*0.18, g.bW*0.24, 0.26),
                    (g.bR - g.bW*0.32, g.bY + g.bH*0.32, g.bW*0.20, 0.20),
                    (g.bL + g.bW*0.06, g.bY + g.bH*0.50, g.bW*0.18, 0.18),
                    (g.bR - g.bW*0.28, g.bY + g.bH*0.66, g.bW*0.15, 0.14)
                ]
            } else {
                texLines = [
                    (g.bL + g.bW*0.10, g.bY + g.bH*0.28, g.bW*0.22, 0.14),
                    (g.bR - g.bW*0.30, g.bY + g.bH*0.48, g.bW*0.18, 0.12)
                ]
            }
            for tl in texLines {
                var tp = Path()
                tp.move(to: CGPoint(x: tl.x, y: tl.y))
                tp.addLine(to: CGPoint(x: tl.x + tl.w, y: tl.y + 0.7*S))
                ctx.drawLayer { layer in
                    layer.opacity = tl.op
                    layer.stroke(tp, with: bodyShade,
                                 style: StrokeStyle(lineWidth: 0.85 * S, lineCap: .round))
                }
            }
        }

        // ------------------------------------------------------------------
        // PASS 11 — Side runs (experienced) [line 86]
        // ------------------------------------------------------------------
        if intensity == .experienced {
            let sideRunDefs: [(x1: CGFloat, y1: CGFloat, cpx: CGFloat, cpy: CGFloat, x2: CGFloat, y2: CGFloat)] = [
                (g.bL - g.bW*0.035, g.bY + g.bH*0.10, g.bL - g.bW*0.06, g.bY + g.bH*0.36, g.bL - g.bW*0.018, g.bY + g.bH*0.62),
                (g.bR + g.bW*0.010, g.bY + g.bH*0.26, g.bR + g.bW*0.05, g.bY + g.bH*0.44, g.bR + g.bW*0.018, g.bY + g.bH*0.62)
            ]
            for sr in sideRunDefs {
                var rp = Path()
                rp.move(to: CGPoint(x: sr.x1, y: sr.y1))
                rp.addQuadCurve(to: CGPoint(x: sr.x2, y: sr.y2),
                                control: CGPoint(x: sr.cpx, y: sr.cpy))
                ctx.drawLayer { layer in
                    layer.opacity = 0.20
                    layer.stroke(rp, with: bodyShade,
                                 style: StrokeStyle(lineWidth: 2.8 * S, lineCap: .round))
                }
                ctx.drawLayer { layer in
                    layer.opacity = 0.38
                    layer.stroke(rp, with: bodyShade,
                                 style: StrokeStyle(lineWidth: 0.60 * S, lineCap: .round))
                }
            }
        }

        // ------------------------------------------------------------------
        // PASS 12 — Exploring rim drip [line 87]
        // ------------------------------------------------------------------
        if intensity == .exploring {
            let rx = g.bL - g.bW*0.015
            let ry0 = g.bY + 1*S
            let ry1 = g.bY + g.bH*0.15
            var rp = Path()
            rp.move(to: CGPoint(x: rx, y: ry0))
            rp.addQuadCurve(to: CGPoint(x: rx - g.bW*0.008, y: ry1),
                            control: CGPoint(x: rx - g.bW*0.025, y: ry0 + (ry1 - ry0)*0.5))
            ctx.drawLayer { layer in
                layer.opacity = 0.35
                layer.stroke(rp, with: bodyShade,
                             style: StrokeStyle(lineWidth: 0.85 * S, lineCap: .round))
            }
        }

        // ------------------------------------------------------------------
        // PASS 13 — Ember glow [line 89]
        // ------------------------------------------------------------------
        let emberScale = CGFloat(1.0 + sin(t * .pi) * 0.35)
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 2 * S))
            layer.opacity = cfg.dim ? 0.14 : 0.26
            let eg = GraphicsContext.Shading.radialGradient(
                Gradient(stops: [
                    .init(color: CandlePalette.magenta, location: 0),
                    .init(color: Color(red: 1, green: 0, blue: 0.416, opacity: 0), location: 1)
                ]),
                center: CGPoint(x: g.wickTipX, y: g.wickTip),
                startRadius: 0,
                endRadius: g.bW * 0.07 * emberScale)
            layer.fill(Path(CGRect(x: g.wickTipX - g.bW*0.12, y: g.wickTip - g.bW*0.12,
                                   width: g.bW*0.24, height: g.bW*0.24)), with: eg)
        }

        // ------------------------------------------------------------------
        // PASS 14 — Wick stroke + ember dot [line 90]
        // ------------------------------------------------------------------
        ctx.drawLayer { layer in
            layer.opacity = cfg.dim ? 0.55 : 0.68
            let wkG = GraphicsContext.Shading.linearGradient(
                Gradient(stops: [
                    .init(color: Color(red: 0.910, green: 0.894, blue: 0.871, opacity: 0.90), location: 0),
                    .init(color: Color(red: 0.910, green: 0.894, blue: 0.871, opacity: 0.24), location: 1)
                ]),
                startPoint: CGPoint(x: g.cx, y: g.wickBot),
                endPoint: CGPoint(x: g.wickTipX, y: g.wickTip))
            var wp = Path()
            wp.move(to: CGPoint(x: g.cx, y: g.wickBot))
            wp.addQuadCurve(to: CGPoint(x: g.wickTipX, y: g.wickTip),
                            control: CGPoint(x: g.cx + 1.0*S, y: g.wickBot - g.wickH*0.45))
            layer.stroke(wp, with: wkG,
                         style: StrokeStyle(lineWidth: CGFloat(cfg.dim ? 0.70 : 0.90) * S,
                                            lineCap: .round))
        }
        // ember dot
        ctx.drawLayer { layer in
            layer.opacity = cfg.dim ? 0.35 : 0.55
            let dotR = 1.0 * S * emberScale
            layer.fill(Path(ellipseIn: CGRect(x: g.wickTipX - dotR, y: g.wickTip - dotR,
                                              width: dotR*2, height: dotR*2)),
                       with: .color(Color(red: 0.910, green: 0.894, blue: 0.871, opacity: 0.92)))
        }

        // ------------------------------------------------------------------
        // PASS 15 — Crisp flame edges [line 91]
        // ------------------------------------------------------------------
        ctx.drawLayer { layer in
            layer.opacity = baseAlpha
            layer.stroke(flame.left, with: flameShade,
                         style: StrokeStyle(lineWidth: 1.60 * S, lineCap: .round))
            layer.stroke(flame.right, with: flameShade,
                         style: StrokeStyle(lineWidth: 1.60 * S, lineCap: .round))
        }

        // ------------------------------------------------------------------
        // PASS 16 — Inner core [line 92]
        // ------------------------------------------------------------------
        let core = innerCore(g, S: S, cfg: cfg,
                             fH: fH, fWL: fWL, fWR: fWR,
                             sway: sway, midTurb: midTurb,
                             wickTipX: g.wickTipX, wickTip: g.wickTip)
        ctx.drawLayer { layer in
            layer.opacity = baseAlpha * cfg.innerAlpha
            layer.stroke(core.left, with: flameWarmShade,
                         style: StrokeStyle(lineWidth: 1.05 * S, lineCap: .round))
            layer.stroke(core.right, with: flameWarmShade,
                         style: StrokeStyle(lineWidth: 1.05 * S, lineCap: .round))
        }

        // ------------------------------------------------------------------
        // PASS 17 — Tip glow (non-dim) [line 93]
        // ------------------------------------------------------------------
        if !cfg.dim {
            ctx.drawLayer { layer in
                layer.opacity = baseAlpha * 0.70
                let tg = GraphicsContext.Shading.radialGradient(
                    Gradient(stops: [
                        .init(color: Color(red: 0.765, green: 0.933, blue: 1.0, opacity: 0.95), location: 0),
                        .init(color: Color(red: 0, green: 0.761, blue: 1.0, opacity: 0), location: 1)
                    ]),
                    center: CGPoint(x: tipX, y: tipY),
                    startRadius: 0,
                    endRadius: g.bW * 0.16)
                layer.fill(Path(CGRect(x: tipX - g.bW*0.16, y: tipY - g.bW*0.16,
                                       width: g.bW*0.32, height: g.bW*0.32)), with: tg)
            }
        }

        // ------------------------------------------------------------------
        // PASS 18 — Curious smoke wisp [line 94]
        // ------------------------------------------------------------------
        if intensity == .curious {
            let smokeA = 0.09 + sin(t * 0.7) * 0.04
            var wispP = Path()
            wispP.move(to: CGPoint(x: tipX, y: tipY))
            wispP.addCurve(to: CGPoint(x: tipX + g.bW*0.06, y: tipY - g.bH*0.16),
                           control1: CGPoint(x: tipX + g.bW*0.18, y: tipY - g.bH*0.055),
                           control2: CGPoint(x: tipX - g.bW*0.14, y: tipY - g.bH*0.11))
            ctx.drawLayer { layer in
                layer.opacity = smokeA
                layer.stroke(wispP,
                             with: .color(Color(red: 0.784, green: 0.765, blue: 0.863)),
                             style: StrokeStyle(lineWidth: 0.40 * S, lineCap: .round))
            }
        }

        // ------------------------------------------------------------------
        // PASS 19 — Experienced wax drips [line 95]
        // ------------------------------------------------------------------
        if intensity == .experienced {
            let termPulse = t * (2 * .pi / 2.5)
            struct DripDef { var x, y, len, lean, sc: CGFloat; var pulse: Double }
            let dripDefs: [DripDef] = [
                DripDef(x: g.bL - g.bW*0.04, y: g.bY + 2*S, len: g.bH*0.62, lean: -g.bW*0.035, sc: 1.25, pulse: termPulse),
                DripDef(x: g.cx + g.bW*0.08, y: g.bY + 1*S, len: g.bH*0.40, lean: g.bW*0.040, sc: 1.06, pulse: 0),
                DripDef(x: g.bR + g.bW*0.01, y: g.bY + 3*S, len: g.bH*0.24, lean: g.bW*0.025, sc: 0.84, pulse: 0),
                DripDef(x: g.bL + g.bW*0.07, y: g.bY + 4*S, len: g.bH*0.15, lean: -g.bW*0.018, sc: 0.62, pulse: 0)
            ]
            for dd in dripDefs {
                let drip = buildDrip(g, S: S,
                                     sx: dd.x, sy: dd.y,
                                     length: dd.len, lean: dd.lean,
                                     sc: dd.sc, tPulse: dd.pulse)
                // blurred shoulder fill
                ctx.drawLayer { layer in
                    layer.addFilter(.blur(radius: 2.5 * S))
                    layer.opacity = 0.20
                    layer.fill(drip.shoulder, with: bodyShade)
                }
                // crisp shoulder
                ctx.drawLayer { layer in
                    layer.opacity = 0.72
                    layer.fill(drip.shoulder, with: bodyShade)
                }
                // run
                ctx.drawLayer { layer in
                    layer.opacity = 0.52
                    layer.fill(drip.run, with: bodyShade)
                }
                // terminal drop
                ctx.drawLayer { layer in
                    layer.opacity = 0.66
                    layer.fill(drip.term, with: bodyShade)
                }
            }
        }
    }
}

// Per-intensity flame config — verbatim port of FLAME_CFG.
struct FlameCfg {
    let baseH, baseW, crispAlpha, glowAlpha, swayAmp, swayFreq, flickerAmp, turbFreq, innerScale, innerAlpha: Double
    let dim: Bool
    let hasNotch: Bool
    static func of(_ i: CandleIntensity) -> FlameCfg {
        switch i {
        case .curious:     return .init(baseH: 0.20, baseW: 0.36, crispAlpha: 0.38, glowAlpha: 0.07, swayAmp: 0.58, swayFreq: 0.26, flickerAmp: 0.55, turbFreq: 1.8, innerScale: 0.32, innerAlpha: 0.42, dim: true, hasNotch: false)
        case .exploring:   return .init(baseH: 0.42, baseW: 0.54, crispAlpha: 0.94, glowAlpha: 0.40, swayAmp: 0.12, swayFreq: 0.55, flickerAmp: 0.07, turbFreq: 2.1, innerScale: 0.52, innerAlpha: 0.80, dim: false, hasNotch: false)
        case .experienced: return .init(baseH: 0.42, baseW: 0.54, crispAlpha: 0.94, glowAlpha: 0.40, swayAmp: 0.14, swayFreq: 0.55, flickerAmp: 0.09, turbFreq: 2.4, innerScale: 0.52, innerAlpha: 0.80, dim: false, hasNotch: true)
        }
    }
}

#Preview("Candles — animated") {
    TimelineView(.animation) { tl in
        let t = tl.date.timeIntervalSinceReferenceDate
        ZStack {
            Color.black
            HStack(spacing: AppSpacing.sm) {
                ForEach(CandleIntensity.ordered, id: \.self) { i in
                    CandleCardFace(intensity: i, time: t)
                        .frame(width: 118, height: 118 * 1.5)
                }
            }
        }.ignoresSafeArea()
    }
}

#Preview("Candles — reduce motion") {
    ZStack {
        Color.black
        HStack(spacing: AppSpacing.sm) {
            ForEach(CandleIntensity.ordered, id: \.self) { i in
                CandleCardFace(intensity: i, time: 5.0, reduceMotion: true)
                    .frame(width: 118, height: 118 * 1.5)
            }
        }
    }.ignoresSafeArea()
}
