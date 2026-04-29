import SwiftUI

// MARK: - Layout constants
private let kReferenceHeight: CGFloat = 844

// MARK: - Spacing Scale (8pt grid)
private enum Spacing {
    // Base unit
    static let unit: CGFloat = 8

    // Fixed steps
    static let xs:  CGFloat = 8   // 1×
    static let sm:  CGFloat = 16  // 2×
    static let md:  CGFloat = 24  // 3×
    static let lg:  CGFloat = 32  // 4×
    static let xl:  CGFloat = 48  // 6×

    // Screen-relative top padding
    // Keeps hero vertically centred on every device
    //
    //  iPhone SE  (568pt) → ~10%  = 56pt  (feels tight, so floor at 8%)
    //  iPhone 14  (844pt) → 10%  = 84pt
    //  iPhone 14+ (926pt) → 10%  = 92pt
    //  iPhone 15 Pro Max (932pt) → 10% = 93pt
    static func topPad(for h: CGFloat) -> CGFloat {
        let pct: CGFloat = h <= 700 ? 0.08 : 0.10
        return (h * pct).rounded()
    }

    // Space between stat and body copy
    // Larger screens get more air; SE gets minimum viable
    static func statToBody(scale: CGFloat) -> CGFloat {
        (24 * scale).rounded()   // 24pt @ 844  →  ~16pt @ SE
    }

    // Body copy → citation pill
    // These are *related* items so keep them close (sm)
    static func bodyToCite(scale: CGFloat) -> CGFloat {
        (16 * scale).rounded()
    }

    // Citation pill → ethos line
    // Slightly more air — different semantic group
    static func citeToEthos(scale: CGFloat) -> CGFloat {
        (28 * scale).rounded()
    }

    // Bottom safe area under home bar
    static let homeBarBottom: CGFloat = 8

    // Horizontal page margin — matches HIG (16pt min, 20pt comfortable)
    static let hPad: CGFloat = 24
}

// MARK: - Main Onboarding View
struct OnboardingStatView: View {
    
    var onContinue: (() -> Void)? = nil
    
    @State private var holoShiftPhase: CGFloat = -0.35
    @State private var holoFlashOffset: CGFloat = 2.5
    @State private var glowPulseHigh = false
    @State private var castPulseHigh = false
    
    @State private var showStatLabel = false
    @State private var showCiteTap   = false
    @State private var showEthos     = false
    @State private var showCTA       = false
    
    @State private var citeOpen = false
    @State private var hasAnimated = false
    @State private var hasAdvanced = false
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var isLight: Bool { colorScheme == .light }
    
    var body: some View {
        GeometryReader { geo in
            let screenH = geo.size.height
            let scale   = screenH / kReferenceHeight
            let screenW = geo.size.width
            let statFontSize: CGFloat = screenH <= 700
            ? 100
            : (screenW > 390 ? 164 : 140)
            
            ZStack {
                Color.clear.ignoresSafeArea()
                
                if !isLight {
                    Ellipse()
                        .fill(RadialGradient(stops: [
                            .init(color: AppColors.purple.opacity(0.12), location: 0),
                            .init(color: AppColors.deepBlue.opacity(0.06),   location: 0.5),
                            .init(color: .clear,                     location: 1)
                        ], center: .center, startRadius: 0, endRadius: 240))
                        .frame(width: 380, height: 220)
                        .blur(radius: 90)
                    // ✦ SPACING — keep cast glow anchored below stat block
                        .offset(y: 260 * scale)
                        .allowsHitTesting(false)
                }
                
                VStack(spacing: 0) {
                    
                    // ──────────────────────────────────────────
                    // TOP PADDING
                    // Screen-relative so hero sits at ~golden
                    // ratio on every device size.
                    // ──────────────────────────────────────────
                    Spacer(minLength: Spacing.topPad(for: screenH))
                    
                    // ──────────────────────────────────────────
                    // HERO BLOCK
                    // All content items are *related*, so they
                    // share a single VStack with explicit,
                    // intentional gaps rather than Spacers.
                    // ──────────────────────────────────────────
                    VStack(spacing: 0) {
                        
                        StatNumberView(
                            holoShiftPhase:  holoShiftPhase,
                            holoFlashOffset: holoFlashOffset,
                            glowPulseHigh:   glowPulseHigh,
                            castPulseHigh:   castPulseHigh,
                            fontSize:        statFontSize,
                            isLight:         isLight
                        )
                        // ✦ stat → body: 24pt scaled (related, but different type)
                        .padding(.bottom, Spacing.statToBody(scale: scale))
                        
                        Text("Americans have engaged in consensual non\u{2011}monogamy at some point in their lives.")
                            .font(AppFonts.body(18))
                            .lineSpacing(10.8)
                            .foregroundStyle(isLight
                                             ? AppColors.lightCardTitle
                                             : AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                            .opacity(showStatLabel ? 1 : 0)
                            .offset(y: showStatLabel ? 0 : 14)
                        
                        // ✦ body → citation pill: 16pt scaled (tightly related)
                        CitationTapView(citeOpen: $citeOpen)
                            .padding(.top, Spacing.bodyToCite(scale: scale))
                            .opacity(showCiteTap ? 1 : 0)
                            .offset(y: showCiteTap ? 0 : 14)
                        
                        // ✦ citation → ethos: 28pt scaled (new semantic group)
                        EthosTextView()
                            .padding(.top, Spacing.citeToEthos(scale: scale))
                            .opacity(showEthos ? 1 : 0)
                            .offset(y: showEthos ? 0 : 8)
                    }
                    .padding(.horizontal, Spacing.hPad)
                    
                    // ──────────────────────────────────────────
                    // FLEXIBLE SPACE
                    // Single Spacer between content and CTA so
                    // the button is always visually anchored to
                    // the bottom on every screen height.
                    // ──────────────────────────────────────────
                    Spacer(minLength: Spacing.lg)
                    
                    // ──────────────────────────────────────────
                    // CTA — anchored to bottom
                    // ──────────────────────────────────────────
                    HoloCTAButton(
                        title: "Explore",
                        isEnabled: true,
                        action: {
                            guard !hasAdvanced else { return }
                            hasAdvanced = true
#if DEBUG
                            assert(onContinue != nil,
                                   "OnboardingStatView: onContinue not injected — wire from coordinator.")
#endif
                            onContinue?()
                        },
                        cornerRadius: 100,
                        height: 56,
                        lightModeGradient: isLight ? LinearGradient(
                            stops: [
                                .init(color: AppColors.magenta,   location: 0.0),
                                .init(color: AppColors.orangeHot, location: 0.55),
                                .init(color: AppColors.gold,      location: 1.0),
                            ],
                            startPoint: .leading,
                            endPoint:   .trailing
                        ) : nil
                    )
                    .padding(.horizontal, Spacing.hPad)
                    .opacity(showCTA ? 1 : 0)
                    .offset(y: showCTA ? 0 : 10)
                    
                  
                    
                    
                }
            }
        }
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true
            startAllAnimations()
        }
        .onDisappear {
            hasAnimated = false
            // hasAdvanced intentionally NOT reset.
            // It is a one-way latch to prevent double-fire of onContinue.
            // If the view reappears before the coordinator has advanced,
            // the latch prevents firing onContinue() again.
        }
    }
    
    // MARK: - Animation Orchestration
    private func startAllAnimations() {
        
        // Reduce Motion: set static values, no repeatForever loops
        if reduceMotion {
            holoShiftPhase  = 0.3          // static midpoint, no sweep
            holoFlashOffset = 0            // no flash
            glowPulseHigh   = true         // glow at full opacity, static
            castPulseHigh   = true         // cast at full opacity, static
        } else {
            // Full motion: holographic sweep and glow pulses
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
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.5))  { showStatLabel = true }
        withAnimation(.easeOut(duration: 0.6).delay(0.7))  { showCiteTap   = true }
        withAnimation(.easeOut(duration: 0.5).delay(1.0))  { showEthos     = true }
        
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
        var isLight: Bool = false
        
        private let txt = "1 in 5"
        
        private var fnt:  Font    { AppFonts.display(fontSize, weight: .bold) }
        private var trk:  CGFloat { -3.2 * (fontSize / 140) }
        
        private var castWidth:  CGFloat { 300 * (fontSize / 140) }
        private var castHeight: CGFloat { 55  * (fontSize / 140) }
        private var castOffset: CGFloat { 70  * (fontSize / 140) }
        
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
        
        private var warmStops: [Gradient.Stop] {
            [
                .init(color: AppColors.magenta,   location: 0.00),
                .init(color: AppColors.orangeHot, location: 0.55),
                .init(color: AppColors.gold,      location: 1.00),
            ]
        }
        
        private var holoGradient: LinearGradient {
            LinearGradient(
                stops:      holoStops,
                startPoint: UnitPoint(x: -holoShiftPhase, y: -0.2),
                endPoint:   UnitPoint(x:  2.0 - holoShiftPhase, y: 1.2)
            )
        }
        
        private var warmGradient: LinearGradient {
            LinearGradient(
                stops:      warmStops,
                startPoint: UnitPoint(x: -holoShiftPhase, y: -0.2),
                endPoint:   UnitPoint(x:  2.0 - holoShiftPhase, y: 1.2)
            )
        }
        
        private var activeGradient: LinearGradient {
            isLight ? warmGradient : holoGradient
        }
        
        private var baseText: some View {
            Text(txt).font(fnt).tracking(trk)
        }
        
        var body: some View {
            ZStack {
                baseText
                    .foregroundStyle(.clear)
                    .overlay { activeGradient.mask { baseText } }
                    .blur(radius: 12)
                    .opacity(glowPulseHigh ? 0.40 : 0.25)
                    .padding(-6)
                
                Ellipse()
                    .fill(RadialGradient(stops: [
                        .init(color: isLight
                              ? AppColors.magenta.opacity(0.18)
                              : AppColors.purple.opacity(0.18), location: 0),
                        .init(color: isLight
                              ? AppColors.gold.opacity(0.10)
                              : AppColors.cyan.opacity(0.10),   location: 0.4),
                        .init(color: .clear, location: 0.7)
                    ], center: .center, startRadius: 0, endRadius: 150))
                    .frame(width: castWidth, height: castHeight)
                    .blur(radius: 20)
                    .scaleEffect(x: castPulseHigh ? 1.12 : 1.0, y: 1.0)
                    .opacity(castPulseHigh ? 1.0 : 0.7)
                    .offset(y: castOffset)
                
                baseText
                    .foregroundStyle(.clear)
                    .overlay { activeGradient.mask { baseText } }
                
                baseText
                    .foregroundStyle(.clear)
                    .overlay {
                        LinearGradient(
                            stops: [
                                .init(color: .clear,                     location: 0.00),
                                .init(color: .clear,                     location: 0.30),
                                .init(color: Color.white.opacity(0.30),  location: 0.38),
                                .init(color: Color.white.opacity(0.00),  location: 0.42),
                                .init(color: .clear,                     location: 0.50),
                                .init(color: Color.white.opacity(0.18),  location: 0.60),
                                .init(color: .clear,                     location: 0.65),
                                .init(color: .clear,                     location: 1.00),
                            ],
                            startPoint: UnitPoint(x: -0.1, y:  1.0),
                            endPoint:   UnitPoint(x:  1.1, y: -0.25)
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
        
        @Environment(\.colorScheme) private var colorScheme
        private var isLight: Bool { colorScheme == .light }
        
        private func citationBody() -> AttributedString {
            var result = AttributedString()
            
            var first = AttributedString("Two nationally representative studies")
            first.font = AppFonts.body(11.5, weight: .semibold)
            result.append(first)
            
            var second = AttributedString(" of 8,718 single adults. Roughly 1 in 5 reported engaging in CNM \u{2014} consistent across age, income, religion, race, political affiliation, and region.")
            second.font = AppFonts.body(11.5, weight: .regular)
            result.append(second)
            
            return result
        }
        
        var body: some View {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.35)) {
                        citeOpen.toggle()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(isLight
                                             ? AppColors.magenta
                                             : AppColors.cyanLight)
                        Text("About this research")
                            .font(AppFonts.body(11, weight: .medium))
                            .foregroundStyle(isLight
                                             ? AppColors.lightCardTitle
                                             : AppColors.textPrimary)
                            .tracking(0.3)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background {
                        Capsule()
                            .fill(isLight
                                  ? Color.white.opacity(0.08)
                                  : Color.white.opacity(0.06))
                            .overlay {
                                Capsule()
                                    .stroke(
                                        isLight
                                        ? AppColors.lightBorder
                                        : Color.white.opacity(0.12),
                                        lineWidth: 1
                                    )
                            }
                    }
                }
                .buttonStyle(.plain)
                // ✦ NO top padding here — parent VStack owns the gap above
                
                if citeOpen {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(citationBody())
                            .foregroundColor(isLight
                                             ? AppColors.lightTextPrimary
                                             : AppColors.textPrimary)
                            .lineSpacing(11.5 * 0.7)
                        
                        Text("Haupert et al., 2017 · Journal of Sex Research")
                            .font(AppFonts.body(10).italic())
                            .foregroundColor(isLight
                                             ? AppColors.lightTextSecondary
                                             : AppColors.textSecondary)
                            .padding(.top, Spacing.xs)   // 8pt — tight, same group
                    }
                    .frame(maxWidth: 300, alignment: .leading)
                    .padding(.vertical,   Spacing.sm)    // 16pt
                    .padding(.horizontal, Spacing.sm)    // 16pt
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isLight
                                  ? AppColors.lightCardFill
                                  : AppColors.cardBg)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(isLight
                                        ? AppColors.lightBorder
                                        : AppColors.borderActive,
                                        lineWidth: 1))
                    )
                    .shadow(color: isLight
                            ? AppColors.lightShadowPurple
                            : Color.black.opacity(0.5),
                            radius: isLight ? 16 : 20,
                            y:      isLight ?  4 :  6)
                    .padding(.top, Spacing.sm)           // 16pt — card floats below pill
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                }
            }
        }
    }
    
    // MARK: - Ethos Text
    private struct EthosTextView: View {
        @Environment(\.colorScheme) private var colorScheme
        private var isLight: Bool { colorScheme == .light }
        
        var body: some View {
            if isLight {
                HStack(spacing: 0) {
                    Text("You're not alone.")
                        .font(AppFonts.body(14, weight: .semibold))
                        .foregroundStyle(LinearGradient(
                            stops: [
                                .init(color: AppColors.magenta,   location: 0.00),
                                .init(color: AppColors.orangeHot, location: 0.55),
                                .init(color: AppColors.gold,      location: 1.00),
                            ],
                            startPoint: .leading,
                            endPoint:   .trailing
                        ))
                    Text(" And this isn't new.")
                        .font(AppFonts.body(14, weight: .medium))
                        .tracking(0.2)
                        .foregroundColor(AppColors.lightCardTitle)
                }
                .lineSpacing(14 * 0.6)
                .multilineTextAlignment(.center)
            } else {
                HStack(spacing: 0) {
                    Text("You're not alone.")
                        .font(AppFonts.body(14, weight: .semibold))
                        .foregroundStyle(LinearGradient(
                            colors: [
                                AppColors.cyan.opacity(0.90),
                                AppColors.purple.opacity(0.80),
                            ],
                            startPoint: .topLeading,
                            endPoint:   .bottomTrailing
                        ))
                    Text(" And this isn't new.")
                        .font(AppFonts.body(14, weight: .medium))
                        .tracking(0.2)
                        .foregroundStyle(AppColors.textPrimary)
                }
                .lineSpacing(14 * 0.6)
                .multilineTextAlignment(.center)
            }
        }
    }
    
}
#Preview("Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat, sparkConfig: .statView, opacity: 1.0)
            .ignoresSafeArea()
        OnboardingStatView(onContinue: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat, sparkConfig: .statView, opacity: 1.0)
            .ignoresSafeArea()
        OnboardingStatView(onContinue: {})
    }
    .preferredColorScheme(.light)
}
