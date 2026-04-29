import SwiftUI

private let kRefW: CGFloat = 460

// MARK: - Volumetric Wave Shape (Organic Compound Sine)
struct VolumetricWave: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase:     CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.height * 0.30
        path.move(to: CGPoint(x: 0, y: midY + sin(phase) * amplitude))
        
        for x in stride(from: CGFloat(0), through: rect.width, by: 2) {
            let relX = x / rect.width
            // Layers a secondary, faster wave for organic turbulence
            let mainWave = sin(relX * .pi * frequency + phase)
            let microWave = sin(relX * .pi * (frequency * 2.5) + (phase * 1.5)) * 0.3
            
            let y = midY + (mainWave + microWave) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0,          y: rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - OnboardingBrandView
struct OnboardingBrandView: View {
    var onFinished: (() -> Void)? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var sceneOpacity:    Double  = 0
    @State private var lineOpacity:     Double  = 0
    @State private var lineBloom:       Double  = 0
    @State private var linePulseScale:  CGFloat = 1.0
    @State private var skyOpacity:      Double  = 0
    @State private var starsOpacity:    Double  = 0
    @State private var terrainOpacity:  Double  = 0

    // splitProgress 0→1: drives the expanding masks
    @State private var splitProgress:   Double  = 0
    @State private var aberration:      Double  = 0
    @State private var rippleOpacity:   Double  = 0
    @State private var rippleScaleX:    CGFloat = 1.0
    @State private var impactFlash:     Double  = 0
    @State private var flareOpacity:    Double  = 0
    @State private var wavePhase:       CGFloat = 0
    @State private var exitVignette:    Double  = 0
    @State private var exitLineOpacity: Double  = 1
    @State private var autoAdvanceFired = false
    @State private var started          = false

    // MARK: - Star data
    private let starData: [(CGFloat, CGFloat, Bool)] = {
        let raw: [(CGFloat, CGFloat)] = [
            (0.026,0.10),(0.061,0.06),(0.098,0.14),(0.135,0.05),(0.170,0.17),(0.205,0.08),
            (0.244,0.22),(0.283,0.04),(0.322,0.18),(0.361,0.11),(0.400,0.24),(0.439,0.07),
            (0.478,0.19),(0.517,0.13),(0.556,0.26),(0.595,0.09),(0.634,0.21),(0.673,0.15),
            (0.712,0.28),(0.751,0.06),(0.790,0.16),(0.829,0.23),(0.868,0.10),(0.907,0.20),
            (0.946,0.12),(0.985,0.25),(0.014,0.40),(0.052,0.45),(0.091,0.35),(0.130,0.50),
            (0.169,0.42),(0.208,0.47),(0.247,0.38),(0.286,0.52),(0.325,0.44),(0.364,0.49),
            (0.403,0.36),(0.442,0.54),(0.481,0.46),(0.520,0.41),(0.559,0.56),(0.598,0.43),
            (0.637,0.48),(0.676,0.37),(0.715,0.58),(0.754,0.39),(0.793,0.53),(0.832,0.45),
            (0.040,0.62),(0.079,0.67),(0.118,0.60),(0.157,0.69),(0.196,0.64),(0.235,0.71),
            (0.274,0.58),(0.313,0.73),(0.352,0.61),(0.391,0.68),(0.430,0.75),(0.469,0.63),
            (0.508,0.70),(0.547,0.57),(0.586,0.76),(0.625,0.66),(0.664,0.72),(0.703,0.55),
            (0.742,0.78),(0.781,0.59),(0.820,0.80),(0.859,0.60),(0.898,0.74),(0.937,0.56),
        ]
        let warmIndices: Set<Int> = [2, 14, 41]
        return raw.enumerated().compactMap { i, s in
            guard s.1 < 0.80 else { return nil }
            return (s.0, s.1, warmIndices.contains(i))
        }
    }()

    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            let w        = geo.size.width
            let h        = geo.size.height
            let scale    = w / kRefW
            let horizonY = h * 0.5
            let cx       = w * 0.5
            let fontSize: CGFloat = w * 0.235

            ZStack {
                Color.black.ignoresSafeArea()

                // ── APERTURE TOP (Sky & Top Text) ────────────────────────
                ZStack {
                    skyLayer(w: w, h: h)
                        .frame(width: w, height: horizonY)
                        .position(x: cx, y: horizonY / 2)
                        .opacity(skyOpacity)
                    
                    starsLayer(w: w, h: h)
                        .frame(width: w, height: horizonY)
                        .position(x: cx, y: horizonY / 2)
                        .opacity(starsOpacity)
                    
                    // The text is perfectly centered ON the horizon line
                    topHalfWord(fontSize: fontSize, scale: scale)
                        .position(x: cx, y: horizonY)
                }
                // MASK: Only reveals upwards from the horizon
                .mask {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        Rectangle()
                            .frame(width: w, height: horizonY * splitProgress)
                        Color.clear
                            .frame(width: w, height: h - horizonY)
                    }
                }

                // ── APERTURE BOTTOM (Terrain & Bottom Text) ──────────────
                ZStack {
                    terrainLayer(w: w, h: h, horizonY: horizonY, cx: cx, scale: scale)
                        .frame(width: w, height: h - horizonY)
                        .position(x: cx, y: horizonY + (h - horizonY) / 2)
                        .opacity(terrainOpacity)
                    
                    // The text is perfectly centered ON the horizon line
                    bottomHalfWord(fontSize: fontSize, scale: scale)
                        .position(x: cx, y: horizonY)
                }
                // MASK: Only reveals downwards from the horizon
                .mask {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(width: w, height: horizonY)
                        Rectangle()
                            .frame(width: w, height: (h - horizonY) * splitProgress)
                        Spacer(minLength: 0)
                    }
                }

                // ── EFFECTS (Line, Flare, Ripples) ────────────────────────
                lineLayer(w: w, h: h, horizonY: horizonY, scale: scale)
                atmosphereBounceLayer(w: w, horizonY: horizonY, scale: scale)
                lensFlareLayer(w: w, horizonY: horizonY, scale: scale)
                rippleLayer(w: w, horizonY: horizonY, scale: scale)

                vignetteLayer()

                Color.white
                    .ignoresSafeArea()
                    .opacity(impactFlash)
                    .blendMode(.screen)
                    .allowsHitTesting(false)

                if exitVignette > 0 {
                    exitLayer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(sceneOpacity)
            .overlay(alignment: .bottom) {
                #if DEBUG
                Button("↺ Replay") { replay() }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.40))
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(.white.opacity(0.10))
                    .clipShape(Capsule())
                    .padding(.bottom, 52)
                #endif
            }
            .onAppear {
                guard !started else { return }
                started = true
                startSequence()
            }
            .accessibilityElement()
            .accessibilityLabel("Vayl")
        }
        .ignoresSafeArea()
    }

    // MARK: - Vignette
    private func vignetteLayer() -> some View {
        RadialGradient(
            stops: [
                .init(color: .clear,                    location: 0.30),
                .init(color: Color.black.opacity(0.42), location: 0.70),
                .init(color: Color.black.opacity(0.78), location: 1.00),
            ],
            center: .center, startRadius: 0, endRadius: 700
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Exit layer
    private func exitLayer() -> some View {
        ZStack {
            RadialGradient(
                stops: [
                    .init(color: .clear,
                          location: max(0, 0.30 - exitVignette * 0.30)),
                    .init(color: Color.black.opacity(exitVignette),
                          location: max(0.01, 0.55 - exitVignette * 0.40)),
                    .init(color: Color.black.opacity(exitVignette),
                          location: 1.00),
                ],
                center: .center, startRadius: 0, endRadius: 700
            )
            .ignoresSafeArea()

            Color.black
                .ignoresSafeArea()
                .opacity(max(0, exitVignette - 0.3) / 0.7)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Atmosphere bounce
    private func atmosphereBounceLayer(w: CGFloat, horizonY: CGFloat, scale: CGFloat) -> some View {
        let bounceH: CGFloat = 90 * scale
        return Rectangle()
            .fill(LinearGradient(stops: [
                .init(color: .clear,                        location: 0.00),
                .init(color: AppColors.cyan.opacity(0.05),  location: 0.40),
                .init(color: AppColors.cyan.opacity(0.025), location: 0.75),
                .init(color: .clear,                        location: 1.00),
            ], startPoint: .bottom, endPoint: .top))
            .frame(width: w, height: bounceH)
            .position(x: w * 0.5, y: horizonY - bounceH * 0.5)
            .blendMode(.screen)
            .opacity(lineOpacity * lineBloom * 1.5)
            .allowsHitTesting(false)
    }

    // MARK: - Lens flare
    private func lensFlareLayer(w: CGFloat, horizonY: CGFloat, scale: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(stops: [
                    .init(color: .clear,                          location: 0.00),
                    .init(color: AppColors.cyan.opacity(0.09),    location: 0.28),
                    .init(color: Color.white.opacity(0.20),       location: 0.50),
                    .init(color: AppColors.magenta.opacity(0.09), location: 0.72),
                    .init(color: .clear,                          location: 1.00),
                ], startPoint: .leading, endPoint: .trailing))
                .frame(width: w * 0.88, height: max(1.5 * scale, 1.0))
                .blur(radius: 3 * scale)

            Rectangle()
                .fill(Color.white.opacity(0.60))
                .frame(width: w * 0.16, height: max(1.0 * scale, 0.8))
                .blur(radius: 0.5 * scale)
        }
        .position(x: w * 0.5, y: horizonY)
        .opacity(flareOpacity)
        .allowsHitTesting(false)
    }

    // MARK: - Sky
    private func skyLayer(w: CGFloat, h: CGFloat) -> some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0.000, green: 0.000, blue: 0.024), location: 0.00),
                .init(color: Color(red: 0.004, green: 0.008, blue: 0.063), location: 0.18),
                .init(color: Color(red: 0.008, green: 0.031, blue: 0.125), location: 0.40),
                .init(color: Color(red: 0.016, green: 0.082, blue: 0.188), location: 0.64),
                .init(color: Color(red: 0.027, green: 0.118, blue: 0.251), location: 0.84),
                .init(color: Color(red: 0.018, green: 0.085, blue: 0.200), location: 0.94),
                .init(color: Color(red: 0.010, green: 0.050, blue: 0.155), location: 1.00),
            ],
            startPoint: .top,
            endPoint:   .bottom
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }

    // MARK: - Stars
    private func starsLayer(w: CGFloat, h: CGFloat) -> some View {
        Canvas { ctx, size in
            for (i, s) in starData.enumerated() {
                let sx     = s.0 * size.width
                let sy     = s.1 * size.height * 0.80
                let isWarm = s.2
                let bright = i % 7 == 0
                let med    = i % 3 == 0
                let r:  CGFloat = bright ? 1.4  : med ? 0.90 : 0.55
                let op: Double  = bright ? 0.85 : med ? 0.50 : 0.16 + Double(i % 5) * 0.07
                
                let col: Color
                if isWarm {
                    col = Color(red: 1.000, green: 0.882, blue: 0.627).opacity(op * 0.90)
                } else if bright {
                    col = Color(red: 0.882, green: 0.933, blue: 1.000).opacity(op)
                } else if i % 6 == 0 {
                    col = Color(red: 0.706, green: 0.824, blue: 1.000).opacity(op)
                } else {
                    col = Color.white.opacity(op)
                }
                
                ctx.fill(
                    Path(ellipseIn: CGRect(x: sx-r, y: sy-r, width: r*2, height: r*2)),
                    with: .color(col)
                )
                if bright {
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: sx-r*3.5, y: sy-r*3.5, width: r*7, height: r*7)),
                        with: .color(col.opacity(0.10))
                    )
                }
            }
            
            // Nebula smears
            ctx.fill(
                Path(ellipseIn: CGRect(
                    x: size.width*0.62, y: size.height*0.04,
                    width: size.width*0.28, height: size.height*0.12
                )),
                with: .color(Color(red:0.424,green:0.227,blue:0.878).opacity(0.055))
            )
            ctx.fill(
                Path(ellipseIn: CGRect(
                    x: size.width*0.04, y: size.height*0.06,
                    width: size.width*0.22, height: size.height*0.10
                )),
                with: .color(Color(red:0.200,green:0.350,blue:0.900).opacity(0.040))
            )
            
            // Horizon haze
            let hazeY = size.height * 0.74
            let hazeH: CGFloat = 72
            ctx.fill(
                Path(CGRect(x: 0, y: hazeY, width: size.width, height: hazeH)),
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: Color(red:0.010,green:0.050,blue:0.155).opacity(0.65), location: 0.5),
                        .init(color: Color(red:0.010,green:0.050,blue:0.155).opacity(0.95), location: 1.0),
                    ]),
                    startPoint: CGPoint(x: 0, y: hazeY),
                    endPoint:   CGPoint(x: 0, y: hazeY + hazeH)
                )
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }

    // MARK: - Terrain
    private func terrainLayer(w: CGFloat, h: CGFloat, horizonY: CGFloat, cx: CGFloat, scale: CGFloat) -> some View {
        let terrainH:  CGFloat  = h - horizonY
        let fieldMidY: CGFloat  = terrainH * 0.22

        return ZStack {
            Canvas { ctx, size in
                let tw = size.width
                let th = size.height

                // Background
                ctx.fill(
                    Path(CGRect(x: 0, y: 0, width: tw, height: th)),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(red: 0.022, green: 0.028, blue: 0.140),
                            Color(red: 0.004, green: 0.004, blue: 0.031),
                        ]),
                        startPoint: .zero,
                        endPoint:   CGPoint(x: 0, y: th)
                    )
                )

                // Horizon bleed
                let horizGlowH = th * 0.30
                ctx.fill(
                    Path(CGRect(x: 0, y: 0, width: tw, height: horizGlowH)),
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: AppColors.purple.opacity(0.14), location: 0.0),
                            .init(color: AppColors.cyan.opacity(0.06),   location: 0.4),
                            .init(color: .clear,                         location: 1.0),
                        ]),
                        startPoint: CGPoint(x: tw*0.5, y: 0),
                        endPoint:   CGPoint(x: tw*0.5, y: horizGlowH)
                    )
                )
            }

            // ── Volumetric animated wave stack ────────────────────────────
            let waveFrameH = terrainH * 0.55
            ZStack {
                VolumetricWave(
                    amplitude: terrainH * 0.035,
                    frequency: 2.2,
                    phase:     wavePhase * 0.65
                )
                .fill(LinearGradient(stops: [
                    .init(color: AppColors.cyan.opacity(0.55), location: 0.00),
                    .init(color: AppColors.cyan.opacity(0.18), location: 0.35),
                    .init(color: .clear,                        location: 0.65),
                ], startPoint: .top, endPoint: .bottom))
                .opacity(0.20)
                .blendMode(.screen)

                VolumetricWave(
                    amplitude: terrainH * 0.060,
                    frequency: 1.75,
                    phase:     wavePhase * 0.85 + 0.9
                )
                .fill(LinearGradient(stops: [
                    .init(color: AppColors.purple.opacity(0.70), location: 0.00),
                    .init(color: AppColors.purple.opacity(0.22), location: 0.40),
                    .init(color: .clear,                          location: 0.70),
                ], startPoint: .top, endPoint: .bottom))
                .opacity(0.26)
                .blendMode(.screen)

                VolumetricWave(
                    amplitude: terrainH * 0.095,
                    frequency: 1.35,
                    phase:     wavePhase + 1.7
                )
                .fill(LinearGradient(stops: [
                    .init(color: AppColors.magenta.opacity(0.75), location: 0.00),
                    .init(color: Color(red:0.60,green:0.05,blue:0.25).opacity(0.40), location: 0.40),
                    .init(color: .clear, location: 0.72),
                ], startPoint: .top, endPoint: .bottom))
                .opacity(0.30)
                .blendMode(.screen)
            }
            .frame(width: w, height: waveFrameH)
            .position(x: w * 0.5, y: fieldMidY + waveFrameH * 0.5)
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }

    // MARK: - Horizon Line
    private func lineLayer(w: CGFloat, h: CGFloat, horizonY: CGFloat, scale: CGFloat) -> some View {
        let bloomWide: CGFloat = 52 * scale * linePulseScale
        let bloomMid:  CGFloat = 14 * scale * linePulseScale
        let coreH:     CGFloat = max(2.0 * scale, 1.5)
        let haloH:     CGFloat = max(1.2 * scale, 1.0)

        return ZStack {
            Rectangle()
                .fill(LinearGradient(stops: [
                    .init(color:.clear,                                       location:0.00),
                    .init(color:AppColors.cyan.opacity(0.20 * lineBloom),     location:0.14),
                    .init(color:AppColors.purple.opacity(0.38 * lineBloom),   location:0.42),
                    .init(color:AppColors.purple.opacity(0.44 * lineBloom),   location:0.50),
                    .init(color:AppColors.magenta.opacity(0.32 * lineBloom),  location:0.68),
                    .init(color:AppColors.magenta.opacity(0.18 * lineBloom),  location:0.86),
                    .init(color:.clear,                                       location:1.00),
                ], startPoint: .leading, endPoint: .trailing))
                .frame(width: w, height: bloomWide)
                .blur(radius: 20 * scale)
                .animation(.easeOut(duration: 0.22), value: linePulseScale)

            Rectangle()
                .fill(LinearGradient(stops: [
                    .init(color:.clear,                                       location:0.05),
                    .init(color:AppColors.cyan.opacity(0.60 * lineBloom),     location:0.20),
                    .init(color:AppColors.purple.opacity(0.88 * lineBloom),   location:0.47),
                    .init(color:AppColors.purple.opacity(0.94 * lineBloom),   location:0.50),
                    .init(color:AppColors.magenta.opacity(0.78 * lineBloom),  location:0.68),
                    .init(color:AppColors.magenta.opacity(0.42 * lineBloom),  location:0.83),
                    .init(color:.clear,                                       location:0.95),
                ], startPoint: .leading, endPoint: .trailing))
                .frame(width: w, height: bloomMid)
                .blur(radius: 5 * scale)
                .animation(.easeOut(duration: 0.22), value: linePulseScale)

            Rectangle()
                .fill(LinearGradient(stops: [
                    .init(color:.clear,            location:0.08),
                    .init(color:AppColors.cyan,    location:0.22),
                    .init(color:AppColors.purple,  location:0.50),
                    .init(color:AppColors.magenta, location:0.78),
                    .init(color:.clear,            location:0.92),
                ], startPoint: .leading, endPoint: .trailing))
                .frame(width: w, height: coreH)

            Rectangle()
                .fill(LinearGradient(stops: [
                    .init(color:.clear,               location:0.12),
                    .init(color:.white.opacity(0.55), location:0.25),
                    .init(color:.white.opacity(0.98), location:0.50),
                    .init(color:.white.opacity(0.55), location:0.75),
                    .init(color:.clear,               location:0.88),
                ], startPoint: .leading, endPoint: .trailing))
                .frame(width: w, height: haloH)
        }
        .frame(width: w, height: max(bloomWide, 52 * scale))
        .position(x: w * 0.5, y: horizonY)
        .opacity(lineOpacity * exitLineOpacity)
        .animation(.easeOut(duration: 0.30), value: lineOpacity)
        .allowsHitTesting(false)
    }

    // MARK: - Ripple
    private func rippleLayer(w: CGFloat, horizonY: CGFloat, scale: CGFloat) -> some View {
        Rectangle()
            .fill(LinearGradient(stops: [
                .init(color:.clear,                           location:0.00),
                .init(color:AppColors.cyan.opacity(0.55),     location:0.20),
                .init(color:AppColors.purple.opacity(0.75),   location:0.50),
                .init(color:AppColors.magenta.opacity(0.55),  location:0.80),
                .init(color:.clear,                           location:1.00),
            ], startPoint: .leading, endPoint: .trailing))
            .frame(width: w, height: max(4 * scale, 2.5))
            .blur(radius: 4 * scale)
            .scaleEffect(x: rippleScaleX, y: 1, anchor: .center)
            .opacity(rippleOpacity)
            .position(x: w * 0.5, y: horizonY)
            .allowsHitTesting(false)
    }

    // MARK: - Wordmark halves (Perfectly Centered)
    private func topHalfWord(fontSize: CGFloat, scale: CGFloat) -> some View {
        ZStack {
            wordLabel(fontSize: fontSize, color: AppColors.cyan.opacity(0.65 * aberration))
                .blur(radius: 0.8 * scale).offset(y: 1.5 * scale)
            wordLabel(fontSize: fontSize, color: AppColors.cyan.opacity(0.35 * aberration))
                .blur(radius: 2.0 * scale).offset(y: 4.0 * scale)
            wordLabel(fontSize: fontSize, color: AppColors.magenta.opacity(0.25 * aberration))
                .blur(radius: 3.0 * scale).offset(y: 7.0 * scale)

            wordLabel(fontSize: fontSize, color: Color(red: 0.863, green: 0.922, blue: 1.000).opacity(0.93))
                .shadow(color: AppColors.cyan.opacity(0.25), radius: 28 * scale)
                .shadow(color: AppColors.cyan.opacity(0.10), radius: 56 * scale)
        }
    }

    private func bottomHalfWord(fontSize: CGFloat, scale: CGFloat) -> some View {
        ZStack {
            wordLabel(fontSize: fontSize, color: AppColors.magenta.opacity(0.65 * aberration))
                .blur(radius: 0.8 * scale).offset(y: -1.5 * scale)
            wordLabel(fontSize: fontSize, color: AppColors.magenta.opacity(0.35 * aberration))
                .blur(radius: 2.0 * scale).offset(y: -4.0 * scale)
            wordLabel(fontSize: fontSize, color: AppColors.cyan.opacity(0.25 * aberration))
                .blur(radius: 3.0 * scale).offset(y: -7.0 * scale)

            Text("VAYL")
                .font(.custom("ClashDisplay-Bold", size: fontSize))
                .tracking(fontSize * 0.06)
                .lineLimit(1)
                .fixedSize()
                .foregroundStyle(LinearGradient(stops: [
                    .init(color:Color(red:0.200,green:0.550,blue:0.720).opacity(0.97), location:0.00),
                    .init(color:Color(red:0.380,green:0.220,blue:0.820).opacity(0.96), location:0.32),
                    .init(color:Color(red:0.580,green:0.160,blue:0.800).opacity(0.95), location:0.55),
                    .init(color:Color(red:0.820,green:0.140,blue:0.520).opacity(0.93), location:0.76),
                    .init(color:Color(red:0.740,green:0.090,blue:0.360).opacity(0.90), location:1.00),
                ], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: AppColors.purple.opacity(0.45),  radius: 14 * scale)
                .shadow(color: AppColors.magenta.opacity(0.20), radius: 30 * scale)
        }
    }

    private func wordLabel(fontSize: CGFloat, color: Color) -> some View {
        Text("VAYL")
            .font(.custom("ClashDisplay-Bold", size: fontSize))
            .tracking(fontSize * 0.06)
            .lineLimit(1)
            .fixedSize()
            .foregroundColor(color)
    }

    // MARK: - Sequence
    private func startSequence() {
        if reduceMotion {
            sceneOpacity   = 1; lineOpacity = 1; lineBloom = 0.65
            splitProgress  = 1; aberration  = 0.55
            terrainOpacity = 1; skyOpacity  = 1; starsOpacity = 1
            flareOpacity   = 0.22
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                wavePhase = .pi * 2
            }
            after(1.0) { beginExit() }
            return
        }

        withAnimation(.easeOut(duration: 0.40)) { sceneOpacity = 1 }

        after(0.300) {
            withAnimation(.easeOut(duration: 0.35)) { self.lineOpacity = 1 }
        }
        after(0.300) {
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                self.wavePhase = .pi * 2
            }
        }

        // ── PULSE 1 (t=0.40s) — darkness, just the line ──────────────────
        after(0.40) {
            withAnimation(.easeOut(duration: 0.18)) {
                self.linePulseScale = 1.42
                self.lineBloom      = 1.00
            }
        }
        after(0.40 + 0.22) {
            withAnimation(.easeOut(duration: 0.30)) {
                self.linePulseScale = 1.0
                self.lineBloom      = 0.28
            }
        }

        // ── PULSE 2 (t=1.10s) — still dark, line finding its brightness ──
        after(1.10) {
            withAnimation(.easeOut(duration: 0.18)) {
                self.linePulseScale = 1.34
                self.lineBloom      = 0.92
            }
        }
        after(1.10 + 0.25) {
            withAnimation(.easeOut(duration: 0.30)) {
                self.linePulseScale = 1.0
                self.lineBloom      = 0.34
            }
        }

        // ── SKY BLEEDS IN (t=1.60s) ──────────────────────────────────────
        // Stars appear in the dark — the tell that something is coming.
        after(1.60) {
            self.skyOpacity   = 1.0
            self.starsOpacity = 1.0
        }

        // ── PULSE 3 = IMPACT (t=1.80s) ───────────────────────────────────
        // The third heartbeat IS the event. Aperture, flash, ripple, and
        // aberration all fire on the same frame as the pulse attack.
        after(1.80) {
            // Line surges — bigger peak than the first two
            withAnimation(.easeOut(duration: 0.18)) {
                self.linePulseScale = 1.55
                self.lineBloom      = 1.00
            }

            // Aperture rips open on the beat
            withAnimation(.spring(response: 0.55, dampingFraction: 0.80)) {
                self.splitProgress = 1.0
            }
            withAnimation(.easeIn(duration: 0.35)) {
                self.terrainOpacity = 1.0
            }

            // Impact effects simultaneous with the pulse attack
            self.impactFlash = 0.06
            withAnimation(.easeOut(duration: 0.11)) { self.impactFlash = 0 }

            self.aberration = 1.0
            self.after(0.140) {
                withAnimation(.easeOut(duration: 0.20)) { self.aberration = 0.55 }
            }

            self.rippleOpacity = 1.0
            self.rippleScaleX  = 1.0
            withAnimation(.easeOut(duration: 0.40)) { self.rippleOpacity = 0 }
            withAnimation(.easeOut(duration: 0.70)) { self.rippleScaleX  = 2.5 }

            withAnimation(.easeOut(duration: 0.08)) { self.flareOpacity = 0.80 }
            self.after(0.30) {
                withAnimation(.easeOut(duration: 1.50)) { self.flareOpacity = 0.18 }
            }
        }

        // ── PULSE 3 DECAY (t=2.08s) ──────────────────────────────────────
        // Line settles to resting glow. World is open. Hold begins.
        after(1.80 + 0.28) {
            withAnimation(.easeOut(duration: 0.50)) {
                self.linePulseScale = 1.0
                self.lineBloom      = 0.65
            }
        }

        // ── HOLD THEN EXIT (t=3.80s) ─────────────────────────────────────
        // 2s hold — the world just opened, give the user a moment.
        after(3.80) { self.beginExit() }
    }

    // MARK: - Exit
    private func beginExit() {
        withAnimation(.easeIn(duration: 0.60)) { exitVignette = 1.0 }
        withAnimation(.easeIn(duration: 0.50)) {
            skyOpacity     = 0
            starsOpacity   = 0
            terrainOpacity = 0
            flareOpacity   = 0
            splitProgress  = 0
        }
        after(0.55) {
            withAnimation(.easeIn(duration: 0.25)) { exitLineOpacity = 0 }
        }
        after(0.82) { fireHandoff() }
    }

    // MARK: - Helpers
    private func after(_ s: Double, _ fn: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + s, execute: fn)
    }

    private func fireHandoff() {
        guard !autoAdvanceFired else { return }
        autoAdvanceFired = true
        onFinished?()
    }

    #if DEBUG
    private func replay() {
        autoAdvanceFired = false
        sceneOpacity     = 0
        lineOpacity      = 0; lineBloom = 0; linePulseScale = 1
        skyOpacity       = 0; starsOpacity = 0; terrainOpacity = 0
        splitProgress    = 0; aberration = 0
        rippleOpacity    = 0; rippleScaleX = 1
        impactFlash      = 0; flareOpacity = 0
        exitVignette     = 0; exitLineOpacity = 1
        wavePhase        = 0
        after(0.05) { startSequence() }
    }
    #endif
}

// MARK: - Previews
#Preview("390×844") {
    ZStack {
        Color.black.ignoresSafeArea()
        OnboardingBrandView(onFinished: {})
    }
    .preferredColorScheme(.dark)
}


