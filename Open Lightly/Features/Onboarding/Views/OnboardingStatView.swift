import SwiftUI

// MARK: - Layout constant
private let kReferenceHeight: CGFloat = 844

// MARK: - Main Onboarding View
struct OnboardingStatView: View {
    
    var onContinue: (() -> Void)? = nil
    
    @State private var blobVisible: [Bool] = Array(repeating: false, count: 8)
    @State private var blobPhase: [CGFloat] = Array(repeating: 0, count: 8)
    
    @State private var holoShiftPhase: CGFloat = -0.35
    @State private var holoFlashOffset: CGFloat = 2.5
    @State private var glowPulseHigh = false
    @State private var castPulseHigh = false
    
    @State private var showStatLabel = false
    @State private var showCiteTap   = false
    @State private var showEthos     = false
    @State private var showCTA       = false
    
    @State private var citeOpen = false
    
    var body: some View {
        GeometryReader { geo in
            let screenH = geo.size.height
            let scale = screenH / kReferenceHeight
            let statFontSize: CGFloat = screenH <= 700 ? 100 : 140
            
            ZStack {
                AppColors.pageBg.ignoresSafeArea()
                
                Ellipse()
                    .fill(RadialGradient(stops: [
                        .init(color: Color.purple.opacity(0.12), location: 0),
                        .init(color: Color.blue.opacity(0.06), location: 0.5),
                        .init(color: .clear, location: 1)
                    ], center: .center, startRadius: 0, endRadius: 240))
                    .frame(width: 380, height: 220)
                    .blur(radius: 90)
                    .offset(y: 260 * scale)
                    .allowsHitTesting(false)
                
                GlowFieldView(
                    blobVisible: blobVisible,
                    blobPhase: blobPhase
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
                
                VStack(spacing: 0) {
                    
                    Spacer(minLength: screenH * 0.08)
                    
                    VStack(spacing: 0) {
                        StatNumberView(
                            holoShiftPhase: holoShiftPhase,
                            holoFlashOffset: holoFlashOffset,
                            glowPulseHigh: glowPulseHigh,
                            castPulseHigh: castPulseHigh,
                            fontSize: statFontSize
                        )
                        .padding(.bottom, 20 * scale)
                        
                        Text("Americans have engaged in consensual non\u{2011}monogamy at some point in their lives.")
                            .font(AppFonts.body(18))
                            .lineSpacing(10.8)
                            .foregroundStyle(Color.white.opacity(0.60))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                            .opacity(showStatLabel ? 1 : 0)
                            .offset(y: showStatLabel ? 0 : 14)
                        
                        CitationTapView(citeOpen: $citeOpen)
                            .opacity(showCiteTap ? 1 : 0)
                            .offset(y: showCiteTap ? 0 : 14)
                        
                        EthosTextView()
                            .padding(.top, 28 * scale)
                            .opacity(showEthos ? 1 : 0)
                            .offset(y: showEthos ? 0 : 14)
                    }
                    .padding(.horizontal, 28)
                    
                    Spacer()
                    
                    // ✦ CHANGED — offset 14 → 10 (shorter travel = snappier)
                    HoloCTAButton(
                        title: "Explore",
                        isEnabled: true
                    ) {
                        onContinue?()
                    }
                    .padding(.horizontal, 28)
                    .opacity(showCTA ? 1 : 0)
                    .offset(y: showCTA ? 0 : 10)
                    
                    Spacer()
                        .frame(height: 12)
                    
                    HomeIndicatorBar()
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: startAllAnimations)
    }
    
    // MARK: - Animation Orchestration
    
    private func startAllAnimations() {
        
        let blobDelays:    [Double] = [0.2, 0.3, 0.5, 0.7, 0.5, 0.8, 1.0, 1.2]
        let blobDurations: [Double] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.2, 1.2, 1.4]
        
        for i in 0..<8 {
            withAnimation(.easeInOut(duration: blobDurations[i]).delay(blobDelays[i])) {
                blobVisible[i] = true
            }
        }
        
        let loopDur:   [Double] = [8, 10, 9, 11, 12, 14, 12, 0]
        let loopDelay: [Double] = [1.2, 1.3, 1.5, 1.7, 1.5, 2.0, 2.0, 0]
        
        for i in 0..<7 {
            DispatchQueue.main.asyncAfter(deadline: .now() + loopDelay[i]) {
                withAnimation(
                    .linear(duration: loopDur[i])
                    .repeatForever(autoreverses: false)
                ) {
                    blobPhase[i] = 1.0
                }
            }
        }
        
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            holoShiftPhase = 0.65
        }
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            holoFlashOffset = -0.5
        }
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            glowPulseHigh = true
        }
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            castPulseHigh = true
        }
        
        // ✦ CHANGED — tighter stagger (200ms), snappier durations
        // Time to interactive: 2.3s → 1.5s
        withAnimation(.easeOut(duration: 0.6).delay(0.5))  { showStatLabel = true }
        withAnimation(.easeOut(duration: 0.6).delay(0.7))  { showCiteTap   = true }
        withAnimation(.easeOut(duration: 0.6).delay(0.9))  { showEthos     = true }
        
        // ✦ CHANGED — CTA gets a spring for a decisive "tap me" arrival
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82).delay(1.05)) {
            showCTA = true
        }
    }
    
    // MARK: - Stat Number (Holographic "1 in 5")
    private struct StatNumberView: View {
        let holoShiftPhase: CGFloat
        let holoFlashOffset: CGFloat
        let glowPulseHigh: Bool
        let castPulseHigh: Bool
        
        var fontSize: CGFloat = 140
        
        private let txt  = "1 in 5"
        
        private var fnt: Font { AppFonts.display(fontSize, weight: .bold) }
        private var trk: CGFloat { -3.2 * (fontSize / 140) }
        
        private var castWidth: CGFloat { 300 * (fontSize / 140) }
        private var castHeight: CGFloat { 55 * (fontSize / 140) }
        private var castOffset: CGFloat { 70 * (fontSize / 140) }
        
        private var holoStops: [Gradient.Stop] {
            [
                .init(color: AppColors.cyan,    location: 0.00),
                .init(color: AppColors.purple,  location: 0.25),
                .init(color: AppColors.magenta, location: 0.50),
                .init(color: AppColors.pink,    location: 0.65),
                .init(color: AppColors.purple,  location: 0.80),
                .init(color: AppColors.cyan,    location: 1.00),
            ]
        }
        
        private var holoGradient: LinearGradient {
            LinearGradient(
                stops: holoStops,
                startPoint: UnitPoint(x: -holoShiftPhase, y: -0.2),
                endPoint:   UnitPoint(x: 2.0 - holoShiftPhase, y: 1.2)
            )
        }
        
        private var baseText: some View {
            Text(txt).font(fnt).tracking(trk)
        }
        
        var body: some View {
            ZStack {
                baseText
                    .foregroundStyle(.clear)
                    .overlay { holoGradient.mask { baseText } }
                    .blur(radius: 12)
                    .opacity(glowPulseHigh ? 0.40 : 0.25)
                    .padding(-6)
                
                Ellipse()
                    .fill(RadialGradient(stops: [.init(color: AppColors.purple.opacity(0.18), location: 0), .init(color: AppColors.cyan.opacity(0.10),  location: 0.4), .init(color: .clear, location: 0.7)], center: .center, startRadius: 0, endRadius: 150))
                    .frame(width: castWidth, height: castHeight)
                    .blur(radius: 20)
                    .scaleEffect(x: castPulseHigh ? 1.12 : 1.0, y: 1.0)
                    .opacity(castPulseHigh ? 1.0 : 0.7)
                    .offset(y: castOffset)
                
                baseText
                    .foregroundStyle(.clear)
                    .overlay { holoGradient.mask { baseText } }
                
                baseText
                    .foregroundStyle(.clear)
                    .overlay {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.00),
                                .init(color: .clear, location: 0.30),
                                .init(color: Color.white.opacity(0.30), location: 0.38),
                                .init(color: Color.white.opacity(0.00), location: 0.42),
                                .init(color: .clear, location: 0.50),
                                .init(color: Color.white.opacity(0.18), location: 0.60),
                                .init(color: .clear, location: 0.65),
                                .init(color: .clear, location: 1.00),
                            ],
                            startPoint: UnitPoint(x: -0.1, y: 1.0),
                            endPoint:   UnitPoint(x: 1.1,  y: -0.25)
                        )
                        .frame(width: 800)
                        .offset(x: holoFlashOffset * 320)
                        .mask { baseText }
                    }
                    .clipped()
            }
            .fixedSize()
        }
    }
    
    // MARK: - Citation Tap
    private struct CitationTapView: View {
        @Binding var citeOpen: Bool
        
        var body: some View {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.5)) {
                        citeOpen.toggle()
                    }
                } label: {
                    HStack(spacing: 5) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                .frame(width: 14, height: 14)
                            Text("i")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.35))
                        }
                        Text("About this research")
                            .font(AppFonts.body(11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.35))
                            .tracking(0.3)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .overlay(RoundedRectangle(cornerRadius: 100).stroke(Color.white.opacity(0.06), lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .padding(.top, 14)
                
                if citeOpen {
                    VStack(alignment: .leading, spacing: 0) {
                        (
                            Text("8,718 single adults")
                                .font(AppFonts.body(11.5, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.65))
                            +
                            Text(" across two nationally representative studies. Roughly 1 in 5 reported engaging in CNM \u{2014} consistent across age, income, religion, race, political affiliation, and region.")
                                .font(AppFonts.body(11.5))
                                .foregroundColor(Color.white.opacity(0.45))
                        )
                        .lineSpacing(11.5 * 0.7)
                        
                        Text("Haupert et al., 2017 · Journal of Sex Research")
                            .font(AppFonts.body(10).italic())
                            .foregroundStyle(Color.white.opacity(0.28))
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: 300, alignment: .leading)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.03))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1.5))
                    )
                    .padding(.top, 14)
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                }
            }
        }
    }
    
    // MARK: - Ethos Text
    private struct EthosTextView: View {
        var body: some View {
            (
                Text("You're not alone.")
                    .font(AppFonts.body(14, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [AppColors.cyan.opacity(0.90), AppColors.purple.opacity(0.80)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                +
                Text(" And this isn't new.")
                    .font(AppFonts.body(14, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.38))
            )
            .lineSpacing(14 * 0.6)
        }
    }
    
    // MARK: - Home Indicator Bar
    private struct HomeIndicatorBar: View {
        var body: some View {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.15))
                .frame(width: 134, height: 5)
                .frame(height: 24)
        }
    }
}

#Preview("Stat View") {
    OnboardingStatView(onContinue: {})
}
