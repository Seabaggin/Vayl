import SwiftUI

// MARK: - Layout constants
private let kReferenceHeight: CGFloat = 844

// MARK: - Screen-Relative Spacing Helpers
// These are geometry-relative computed values — not AppSpacing token candidates.
// Fixed-step values (xs, sm, md, lg, hPad) have been migrated to AppSpacing tokens.
private enum Spacing {

    // Screen-relative top padding — keeps hero vertically centred on every device.
    //
    //  iPhone SE  (568pt) → ~10%  = 56pt  (feels tight, so floor at 8%)
    //  iPhone 14  (844pt) → 10%  = 84pt
    //  iPhone 14+ (926pt) → 10%  = 92pt
    //  iPhone 15 Pro Max  (932pt) → 10% = 93pt
    static func topPad(for h: CGFloat) -> CGFloat {
        let pct: CGFloat = h <= 700 ? 0.08 : 0.10
        return (h * pct).rounded()
    }

    // Space between stat and body copy — larger screens get more air.
    static func statToBody(scale: CGFloat) -> CGFloat {
        (24 * scale).rounded()
    }

    // Body copy → citation pill — tightly related, keep close.
    static func bodyToCite(scale: CGFloat) -> CGFloat {
        (16 * scale).rounded()
    }

    // Citation pill → ethos line — slightly more air, different semantic group.
    static func citeToEthos(scale: CGFloat) -> CGFloat {
        (28 * scale).rounded()
    }
}

// MARK: - Main Onboarding View

struct OnboardingStatView: View {

    var onContinue: (() -> Void)? = nil

    @State private var holoShiftPhase:  CGFloat = -0.35
    @State private var holoFlashOffset: CGFloat =  2.5
    @State private var glowPulseHigh  = false
    @State private var castPulseHigh  = false

    @State private var showStatLabel = false
    @State private var showCiteTap   = false
    @State private var showEthos     = false
    @State private var showCTA       = false

    @State private var citeOpen    = false
    @State private var hasAnimated = false
    @State private var hasAdvanced = false

    @Environment(\.colorScheme)               private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        GeometryReader { geo in
            let screenH       = geo.size.height
            let scale         = screenH / kReferenceHeight
            let screenW       = geo.size.width
            let statFontSize: CGFloat = screenH <= 700
                ? 100
                : (screenW > 390 ? 164 : 140)

            ZStack {
                Color.clear.ignoresSafeArea()

                if !isLight {
                    Ellipse()
                        .fill(RadialGradient(stops: [
                            .init(color: AppColors.accentSecondary.opacity(0.12), location: 0),
                            // TODO: verify token — original was AppColors.accentSecondary
                            .init(color: AppColors.accentSecondary.opacity(0.06), location: 0.5),
                            .init(color: .clear,                                  location: 1)
                        ], center: .center, startRadius: 0, endRadius: 240))
                        .frame(width: 380, height: 220)
                        .blur(radius: 90)
                        .offset(y: 260 * scale)
                        .allowsHitTesting(false)
                }

                VStack(spacing: 0) {

                    Spacer(minLength: Spacing.topPad(for: screenH))

                    VStack(spacing: 0) {

                        StatNumberView(
                            holoShiftPhase:  holoShiftPhase,
                            holoFlashOffset: holoFlashOffset,
                            glowPulseHigh:   glowPulseHigh,
                            castPulseHigh:   castPulseHigh,
                            fontSize:        statFontSize,
                            isLight:         isLight
                        )
                        .padding(.bottom, Spacing.statToBody(scale: scale))

                        Text("Americans have engaged in consensual non\u{2011}monogamy at some point in their lives.")
                            .font(AppFonts.body(18, weight: .regular, relativeTo: .body))
                            .lineSpacing(10.8)
                            .foregroundStyle(isLight
                                ? AppColors.textPrimary
                                : AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                            .opacity(showStatLabel ? 1 : 0)
                            .offset(y: showStatLabel ? 0 : 14)

                        CitationTapView(citeOpen: $citeOpen)
                            .padding(.top, Spacing.bodyToCite(scale: scale))
                            .opacity(showCiteTap ? 1 : 0)
                            .offset(y: showCiteTap ? 0 : 14)

                        EthosTextView()
                            .padding(.top, Spacing.citeToEthos(scale: scale))
                            .opacity(showEthos ? 1 : 0)
                            .offset(y: showEthos ? 0 : 8)
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    Spacer(minLength: AppSpacing.xl)

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
                        // AppRadius.pill replacescornerRadius: AppRadius.pill
                        cornerRadius: AppRadius.pill,
                        height: 56,
                        lightModeGradient: isLight ? LinearGradient(
                            stops: [
                                .init(color: AppColors.accentTertiary,    location: 0.0),
                                .init(color: AppColors.progressBarLeading, location: 0.55),
                                .init(color: AppColors.safetyAccent,       location: 1.0),
                            ],
                            startPoint: .leading,
                            endPoint:   .trailing
                        ) : nil
                    )
                    .padding(.horizontal, AppSpacing.lg)
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
            // One-way latch — prevents double-fire of onContinue.
        }
    }

    // MARK: - Animation Orchestration

    private func startAllAnimations() {

        if reduceMotion {
            holoShiftPhase  = 0.3
            holoFlashOffset = 0
            glowPulseHigh   = true
            castPulseHigh   = true
        } else {
            // Holographic sweep and glow pulses — procedural ambient loops.
            // reduceMotion guard above prevents these running under reduce motion.
            // ambientAnimation modifier pattern not applicable here — procedural Task context.
            //
            // 8.0s sweep — intentional above AppAnimation.ambientDrift (4.0s).
            // Slower sweep gives the holographic number a grander, unhurried feel.
            withAnimation(.easeInOut(duration: AppAnimation.ambientDrift).repeatForever(autoreverses: true)) {
                holoShiftPhase = 0.65
            }
            // 4.0s loops — matches AppAnimation.ambientDrift duration exactly.
            withAnimation(.easeInOut(duration: AppAnimation.ambientDrift).repeatForever(autoreverses: true)) {
                holoFlashOffset = -0.5
            }
            withAnimation(.easeInOut(duration: AppAnimation.ambientDrift).repeatForever(autoreverses: true)) {
                glowPulseHigh = true
            }
            withAnimation(.easeInOut(duration: AppAnimation.ambientDrift).repeatForever(autoreverses: true)) {
                castPulseHigh = true
            }
        }

        // Entrance sequence — stagger delays preserved exactly.
        withAnimation(AppAnimation.slow.delay(0.5))          { showStatLabel = true }
        withAnimation(AppAnimation.slow.delay(0.7))          { showCiteTap   = true }
        withAnimation(AppAnimation.slow.delay(1.0))          { showEthos     = true }
        withAnimation(AppAnimation.spring.delay(1.05))       { showCTA       = true }
    }

    // MARK: - Stat Number (Holographic "1 in 5")

    private struct StatNumberView: View {
        let holoShiftPhase:  CGFloat
        let holoFlashOffset: CGFloat
        let glowPulseHigh:   Bool
        let castPulseHigh:   Bool

        var fontSize: CGFloat = 140
        var isLight:  Bool    = false

        private let txt = "1 in 5"

        private var fnt: Font    { AppFonts.display(fontSize, weight: .bold, relativeTo: .largeTitle) }
        private var trk: CGFloat { -3.2 * (fontSize / 140) }

        private var castWidth:  CGFloat { 300 * (fontSize / 140) }
        private var castHeight: CGFloat { 55  * (fontSize / 140) }
        private var castOffset: CGFloat { 70  * (fontSize / 140) }

        private var holoStops: [Gradient.Stop] {
            [
                .init(color: AppColors.accentPrimary,   location: 0.00),
                .init(color: AppColors.accentSecondary, location: 0.25),
                .init(color: AppColors.accentTertiary,  location: 0.50),
                .init(color: AppColors.accentTertiary,  location: 0.65),
                .init(color: AppColors.accentSecondary, location: 0.80),
                .init(color: AppColors.accentPrimary,   location: 1.00),
            ]
        }

        private var warmStops: [Gradient.Stop] {
            [
                .init(color: AppColors.accentTertiary,    location: 0.00),
                .init(color: AppColors.progressBarLeading, location: 0.55),
                .init(color: AppColors.safetyAccent,       location: 1.00),
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
                              ? AppColors.accentTertiary.opacity(0.18)
                              : AppColors.accentSecondary.opacity(0.18), location: 0),
                        .init(color: isLight
                              ? AppColors.safetyAccent.opacity(0.10)
                              : AppColors.accentPrimary.opacity(0.10),   location: 0.4),
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
                                .init(color: .clear,                    location: 0.00),
                                .init(color: .clear,                    location: 0.30),
                                .init(color: Color.white.opacity(0.30), location: 0.38),
                                .init(color: Color.white.opacity(0.00), location: 0.42),
                                .init(color: .clear,                    location: 0.50),
                                .init(color: Color.white.opacity(0.18), location: 0.60),
                                .init(color: .clear,                    location: 0.65),
                                .init(color: .clear,                    location: 1.00),
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
            first.font = AppFonts.body(11.5, weight: .semibold, relativeTo: .caption2)
            result.append(first)

            var second = AttributedString(" of 8,718 single adults. Roughly 1 in 5 reported engaging in CNM \u{2014} consistent across age, income, religion, race, political affiliation, and region.")
            second.font = AppFonts.body(11.5, weight: .regular, relativeTo: .caption2)
            result.append(second)

            return result
        }

        var body: some View {
            VStack(spacing: 0) {
                Button {
                    // Custom cubic bezier — intentional material motion curve.
                    // Migrating to AppAnimation.standard would change the easing feel.
                    withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.35)) {
                        citeOpen.toggle()
                    }
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: AppIcons.infoCircle)
                            // .caption2 scales with Dynamic Type — correct for
                            // small inline info icons at this visual weight.
                            .font(.caption2)
                            .foregroundStyle(isLight
                                ? AppColors.accentTertiary
                                : AppColors.accentPrimary)
                        Text("About this research")
                            .font(AppFonts.body(11, weight: .medium, relativeTo: .caption2))
                            .foregroundStyle(isLight
                                ? AppColors.textPrimary
                                : AppColors.textPrimary)
                            .tracking(0.3)
                    }
                    .padding(.vertical, AppSpacing.xs)
                    .padding(.horizontal, AppSpacing.sm)
                    .background {
                        Capsule()
                            .fill(isLight
                                ? Color.white.opacity(0.08)
                                : Color.white.opacity(0.06))
                            .overlay {
                                Capsule()
                                    .stroke(
                                        isLight
                                            ? AppColors.borderSubtle
                                            : Color.white.opacity(0.12),
                                        lineWidth: 1
                                    )
                            }
                    }
                }
                .buttonStyle(.plain)

                if citeOpen {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(citationBody())
                            .foregroundColor(isLight
                                ? AppColors.textPrimary
                                : AppColors.textPrimary)
                            .lineSpacing(11.5 * 0.7)

                        Text("Haupert et al., 2017 · Journal of Sex Research")
                            .font(AppFonts.body(10, weight: .regular, relativeTo: .caption2).italic())
                            .foregroundColor(isLight
                                ? AppColors.textSecondary
                                : AppColors.textSecondary)
                            .padding(.top, AppSpacing.sm)
                    }
                    .frame(maxWidth: 300, alignment: .leading)
                    .padding(.vertical,   AppSpacing.md)
                    .padding(.horizontal, AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .fill(isLight
                                ? AppColors.cardBackground
                                : AppColors.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .stroke(isLight
                                        ? AppColors.borderSubtle
                                        : AppColors.borderActive,
                                        lineWidth: 1)
                            )
                    )
                    .shadow(
                        color: isLight
                            // TODO: verify token — original was AppColors.shadowPurple
                            ? AppColors.shadowPurple
                            : Color.black.opacity(0.5),
                        radius: isLight ? 16 : 20,
                        y:      isLight ?  4 :  6
                    )
                    .padding(.top, AppSpacing.md)
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
                        .font(AppFonts.body(14, weight: .semibold, relativeTo: .callout))
                        .foregroundStyle(LinearGradient(
                            stops: [
                                .init(color: AppColors.accentTertiary,    location: 0.00),
                                .init(color: AppColors.progressBarLeading, location: 0.55),
                                .init(color: AppColors.safetyAccent,       location: 1.00),
                            ],
                            startPoint: .leading,
                            endPoint:   .trailing
                        ))
                    Text(" And this isn't new.")
                        .font(AppFonts.body(14, weight: .medium, relativeTo: .callout))
                        .tracking(0.2)
                        .foregroundColor(AppColors.textPrimary)
                }
                .lineSpacing(14 * 0.6)
                .multilineTextAlignment(.center)
            } else {
                HStack(spacing: 0) {
                    Text("You're not alone.")
                        .font(AppFonts.body(14, weight: .semibold, relativeTo: .callout))
                        .foregroundStyle(LinearGradient(
                            colors: [
                                AppColors.accentPrimary.opacity(0.90),
                                AppColors.accentSecondary.opacity(0.80),
                            ],
                            startPoint: .topLeading,
                            endPoint:   .bottomTrailing
                        ))
                    Text(" And this isn't new.")
                        .font(AppFonts.body(14, weight: .medium, relativeTo: .callout))
                        .tracking(0.2)
                        .foregroundStyle(AppColors.textPrimary)
                }
                .lineSpacing(14 * 0.6)
                .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Previews

#Preview("Dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat, sparkConfig: .statView, opacity: 1.0)
            .ignoresSafeArea()
        OnboardingStatView(onContinue: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat, sparkConfig: .statView, opacity: 1.0)
            .ignoresSafeArea()
        OnboardingStatView(onContinue: {})
    }
    .preferredColorScheme(.light)
}
