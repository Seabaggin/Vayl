//
//  StatPhase.swift
//  Vayl
//

import SwiftUI

// MARK: - Layout constants
private let kReferenceHeight: CGFloat = 844

// MARK: - Screen-Relative Spacing Helpers
// These are geometry-relative computed values — not AppSpacing token candidates.
// Each function produces a value proportional to screen height, which cannot
// be expressed as a fixed token without breaking layout on small devices.
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

// MARK: - StatPhase

struct StatPhase: View {

    let director: VaylDirector

    @State private var holoShiftPhase:  CGFloat = -0.35
    @State private var holoFlashOffset: CGFloat =  2.5
    @State private var glowPulseHigh  = false
    @State private var castPulseHigh  = false

    // Entrance cascade — fires in sequence via startAllAnimations()
    @State private var showStat      = false
    @State private var showStatLabel = false
    @State private var showCiteTap   = false
    @State private var showEthos     = false
    @State private var showCTA       = false

    @State private var citeOpen    = false
    @State private var hasAnimated = false
    @State private var hasAdvanced = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let layout    = AppLayout.from(geo)
            let screenH   = layout.screenHeight
            let screenW   = layout.screenWidth
            let scale     = screenH / kReferenceHeight
            let statFontSize: CGFloat = screenH <= 700
                ? 100
                : (screenW > 390 ? 164 : 140)

            ZStack {
                // Phase inherits void and atmosphere from OnboardingCanvasView.
                // Color.clear preserves the canvas layers beneath this overlay.
                Color.clear.ignoresSafeArea()

                // ── Ambient background ellipse — decorative only ───
                // Hidden from VoiceOver — purely atmospheric, no semantic content.
                Ellipse()
                    .fill(RadialGradient(stops: [
                        .init(color: AppColors.accentSecondary.opacity(0.12), location: 0),   // Outer atmosphere stop — within the OB 0.08–0.12 atmospheric range. Felt, not seen.
                        .init(color: AppColors.accentSecondary.opacity(0.06), location: 0.5), // Mid atmosphere stop — half of outer, standard two-stop falloff.
                        .init(color: .clear,                                  location: 1)
                    ], center: .center, startRadius: 0, endRadius: 240))
                    .frame(width: 380, height: 220)
                    .blur(radius: 90)
                    .offset(y: 260 * scale)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                VStack(spacing: 0) {

                    Spacer(minLength: Spacing.topPad(for: screenH))

                    VStack(spacing: 0) {

                        // ── Stat number — hero entrance ───────────────
                        // VoiceOver reads the full stat sentence, not the
                        // graphic "1 in 5" treatment which has no semantic
                        // meaning in isolation.
                        StatNumberView(
                            holoShiftPhase:  holoShiftPhase,
                            holoFlashOffset: holoFlashOffset,
                            glowPulseHigh:   glowPulseHigh,
                            castPulseHigh:   castPulseHigh,
                            fontSize:        statFontSize
                        )
                        // FIX 7 — ambient animations applied as modifiers on the
                        // consuming view, not via withAnimation in startAllAnimations().
                        // .ambientAnimation() strips the animation entirely under reduce motion.
                        .ambientAnimation(
                            .easeInOut(duration: AppAnimation.ambientDrift).repeatForever(autoreverses: true),
                            value: holoShiftPhase
                        )
                        .ambientAnimation(
                            .easeInOut(duration: AppAnimation.ambientDrift).repeatForever(autoreverses: true),
                            value: holoFlashOffset
                        )
                        .ambientAnimation(
                            .easeInOut(duration: AppAnimation.ambientDrift).repeatForever(autoreverses: true),
                            value: glowPulseHigh
                        )
                        .ambientAnimation(
                            .easeInOut(duration: AppAnimation.ambientDrift).repeatForever(autoreverses: true),
                            value: castPulseHigh
                        )
                        // 0.94 — entrance scale origin. Subtle enough to feel
                        // like materialisation rather than a zoom. Not a token
                        // candidate — one-off physics constant for this hero entrance.
                        .opacity(showStat ? 1 : 0)
                        .scaleEffect(showStat ? 1.0 : 0.94)
                        .padding(.bottom, Spacing.statToBody(scale: scale))
                        .accessibilityLabel("1 in 5 Americans have engaged in consensual non-monogamy at some point in their lives.")
                        .accessibilityAddTraits(.isStaticText)

                        // ── Body copy ─────────────────────────────────
                        // Hidden from VoiceOver — content is covered by
                        // the accessibilityLabel on StatNumberView above.
                        Text("Americans have engaged in consensual non\u{2011}monogamy at some point in their lives.")
                            .font(AppFonts.body(18, weight: .regular, relativeTo: .body))
                            // 10.8 = 18pt × 0.6 — standard 60% line height ratio
                            // applied to this font size. Intentional typographic
                            // constant, not an AppSpacing candidate.
                            .lineSpacing(10.8)
                            .foregroundStyle(AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .opacity(showStatLabel ? 1 : 0)
                            .offset(y: showStatLabel ? 0 : 14)
                            .accessibilityHidden(true)

                        // ── Citation ──────────────────────────────────
                        CitationTapView(citeOpen: $citeOpen)
                            .padding(.top, Spacing.bodyToCite(scale: scale))
                            .opacity(showCiteTap ? 1 : 0)
                            .offset(y: showCiteTap ? 0 : 14)

                        // ── Ethos line ────────────────────────────────
                        EthosTextView()
                            .padding(.top, Spacing.citeToEthos(scale: scale))
                            .opacity(showEthos ? 1 : 0)
                            .offset(y: showEthos ? 0 : 8)
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    Spacer()

                    // ── CTA ───────────────────────────────────────────
                    // .padding(.bottom) uses real safe area geometry from AppLayout.
                    // Never use a fixed Spacer or hardcoded value for bottom clearance.
                    VaylButton(
                        label: "Ready to begin?",
                        action: {
                            guard !hasAdvanced else { return }
                            hasAdvanced = true
                            director.advance(to: .name)
                        }
                    )
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.bottom, layout.safeAreaInsets.bottom + AppSpacing.md)
                    .opacity(showCTA ? 1 : 0)
                    .offset(y: showCTA ? 0 : 10)
                    .accessibilityLabel("Ready to begin?")
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true
            startAllAnimations()
        }
        .task {
            // FIX 7 — ambient cycle trigger.
            // One runloop after onAppear so SwiftUI commits the initial @State
            // values first, then sees these as a distinct mutation to animate.
            // Without the yield, SwiftUI coalesces the reset + trigger into one
            // update and skips the animation — gradient freezes at position 0.65.
            try? await Task.sleep(for: .milliseconds(32))
            guard !reduceMotion else { return }
            holoShiftPhase  = 0.65
            holoFlashOffset = -0.5
            glowPulseHigh   = true
            castPulseHigh   = true
        }
        .onDisappear {
            hasAnimated = false
            // hasAdvanced intentionally NOT reset.
            // One-way latch — prevents double-fire of director.advance.
        }
    }

    // MARK: - Animation Orchestration
    //
    // Cascade order:
    //   0.00s  stat number   — hero arrives with weight (cinematic)
    //   0.50s  body copy     — follows with breathing room (slow)
    //   0.70s  citation pill — tightly related to body (slow)
    //   1.00s  ethos line    — different semantic group, more air (slow)
    //   1.05s  CTA           — springs up last (spring)

    private func startAllAnimations() {

        if reduceMotion {
            // Under reduce motion: all elements appear instantly.
            // No spatial movement — state changes only.
            holoShiftPhase  = 0.3
            holoFlashOffset = 0
            glowPulseHigh   = true
            castPulseHigh   = true
            showStat        = true
            showStatLabel   = true
            showCiteTap     = true
            showEthos       = true
            showCTA         = true
        } else {
            // FIX 7 — ambient withAnimation blocks removed.
            // Ambient loops are now driven by .ambientAnimation() modifiers
            // on StatNumberView in body, triggered by onAppear mutations.

            // Entrance cascade — stat number leads, everything follows
            withAnimation(.easeOut(duration: AppAnimation.cinematic))     { showStat      = true }
            withAnimation(AppAnimation.slow.delay(0.5))                    { showStatLabel = true }
            withAnimation(AppAnimation.slow.delay(0.7))                    { showCiteTap   = true }
            withAnimation(AppAnimation.slow.delay(1.0))                    { showEthos     = true }
            withAnimation(AppAnimation.spring.delay(1.05))                 { showCTA       = true }
        }
    }

    // MARK: - Stat Number (Holographic "1 in 5")

    private struct StatNumberView: View {
        let holoShiftPhase:  CGFloat
        let holoFlashOffset: CGFloat
        let glowPulseHigh:   Bool
        let castPulseHigh:   Bool

        var fontSize: CGFloat = 140

        private let txt = "1 in 5"

        private var fnt: Font {
            AppFonts.display(fontSize, weight: .bold, relativeTo: .largeTitle)
        }

        // -3.2 × (fontSize / 140) — tracking scaled proportionally to font size.
        // -3.2 is the base tracking at 140pt. Geometry-relative constant, not
        // an AppSpacing candidate — letterform spacing, not UI element spacing.
        private var trk: CGFloat { -3.2 * (fontSize / 140) }

        // Cast ellipse geometry — all proportional to fontSize.
        // Physics constants for the ground shadow beneath the numeral.
        private var castWidth:  CGFloat { 300 * (fontSize / 140) }
        private var castHeight: CGFloat { 55  * (fontSize / 140) }
        private var castOffset: CGFloat { 70  * (fontSize / 140) }

        // FIX 1 — named constant replaces raw negative padding value.
        // Negative padding prevents the blurred glow duplicate from hard-clipping
        // at the view boundary. Rendering artefact bleed offset — not a spacing token.
        private let kGlowBleedPad: CGFloat = -6

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

        private var activeGradient: LinearGradient {
            LinearGradient(
                stops:      holoStops,
                startPoint: UnitPoint(x: -holoShiftPhase, y: -0.2),
                endPoint:   UnitPoint(x:  2.0 - holoShiftPhase, y: 1.2)
            )
        }

        private var baseText: some View {
            Text(txt).font(fnt).tracking(trk)
        }

        var body: some View {
            ZStack {
                // Glow bloom — blurred duplicate beneath the numeral.
                // Decorative — hidden from VoiceOver at the StatNumberView call site.
                baseText
                    .foregroundStyle(.clear)
                    .overlay { activeGradient.mask { baseText } }
                    .blur(radius: 12)
                    .opacity(glowPulseHigh ? 0.40 : 0.25)
                    // 0.40 = breathe cycle high — glow peak without washing out the numeral.
                    // 0.25 = breathe cycle low  — minimum presence so the glow reads as alive at rest.
                    .padding(kGlowBleedPad)
                    .accessibilityHidden(true)

                // Ground cast shadow — ellipse beneath numeral.
                // Decorative atmospheric element.
                Ellipse()
                    .fill(RadialGradient(stops: [
                        .init(color: AppColors.accentSecondary.opacity(0.18), location: 0),   // 0.18 — cast shadow primary stop. Matches outer atmosphere ellipse for tonal unity.
                        .init(color: AppColors.accentPrimary.opacity(0.10),   location: 0.4), // 0.10 — cast shadow secondary stop. Half of primary, standard radial falloff.
                        .init(color: .clear, location: 0.7)
                    ], center: .center, startRadius: 0, endRadius: 150))
                    .frame(width: castWidth, height: castHeight)
                    .blur(radius: 20)
                    .scaleEffect(x: castPulseHigh ? 1.12 : 1.0, y: 1.0)
                    .opacity(castPulseHigh ? 1.0 : 0.7)
                    // 1.0 = pulse high — cast shadow at full presence when the numeral breathes up.
                    // 0.7 = pulse low  — 70% retains the shadow at rest without disappearing.
                    .offset(y: castOffset)
                    .accessibilityHidden(true)

                // Core gradient numeral — visual representation only.
                // Semantic label applied at StatNumberView call site.
                baseText
                    .foregroundStyle(.clear)
                    .overlay { activeGradient.mask { baseText } }
                    .accessibilityHidden(true)

                // Specular highlight sweep — holographic light catch.
                // white opacity values are specular physics constants:
                // 0.30 = primary highlight peak
                // 0.18 = secondary highlight
                // Not semantic color tokens — simulated light reflectance
                // on a holographic surface.
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
                    .accessibilityHidden(true)
            }
            .fixedSize()
        }
    }

    // MARK: - Citation Tap

    private struct CitationTapView: View {
        @Binding var citeOpen: Bool

        // FIX 6 — custom ButtonStyle provides press feedback.
        private struct CiteButtonStyle: ButtonStyle {
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
                    .offset(y: configuration.isPressed ? 1 : 0)
                    .animation(AppAnimation.fast, value: configuration.isPressed)
                    .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed)
            }
        }

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
                    // FIX 2 — AppAnimation.materialExpand replaces raw .timingCurve call.
                    withAnimation(AppAnimation.materialExpand) {
                        citeOpen.toggle()
                    }
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: AppIcons.infoCircle)
                            .font(AppFonts.body(15, weight: .regular, relativeTo: .caption2))
                            .foregroundStyle(AppColors.accentPrimary)
                            .accessibilityHidden(true)
                        Text("About this research")
                            .font(AppFonts.body(11, weight: .medium, relativeTo: .caption2))
                            .foregroundStyle(AppColors.textPrimary)
                            .tracking(0.3)
                    }
                    .frame(height: AppLayout.pillHeight)
                    .padding(.horizontal, AppLayout.pillHPad)
                    .background {
                        Capsule()
                            .fill(
                                // 0.06 — frosted glass surface. Translucent pill simulation.
                                // Not a token candidate — granularity below semantic system coverage.
                                Color.white.opacity(0.06)
                            )
                            .overlay {
                                Capsule()
                                    .stroke(
                                        // 0.12 — frosted glass border. Same rationale as fill above.
                                        Color.white.opacity(0.12),
                                        lineWidth: 1
                                    )
                            }
                    }
                    .contentShape(Capsule().inset(by: -8))
                }
                // FIX 6 — CiteButtonStyle replaces .buttonStyle(.plain).
                .buttonStyle(CiteButtonStyle())
                .accessibilityLabel(citeOpen ? "Hide research citation" : "About this research")
                .accessibilityAddTraits(.isButton)

                if citeOpen {
                    // FIX 3 — elevation tokens replace raw shadow values.
                    let citShadow = AppElevation.citationPanel.midnightShadow

                    VStack(alignment: .leading, spacing: 0) {
                        Text(citationBody())
                            .foregroundColor(AppColors.textPrimary)
                            // 11.5 × 0.7 — 70% line height ratio at 11.5pt.
                            // Tighter than the standard 0.6 ratio — citation copy
                            // is dense and benefits from slightly more leading.
                            // Intentional typographic constant.
                            .lineSpacing(11.5 * 0.7)

                        Text("Haupert et al., 2017 · Journal of Sex Research")
                            .font(AppFonts.body(10, weight: .regular, relativeTo: .caption2).italic())
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.top, AppSpacing.sm)
                    }
                    // FIX 4 — AppLayout token replaces raw maxWidth value.
                    .frame(maxWidth: AppLayout.citationPanelMaxWidth, alignment: .leading)
                    .padding(.vertical,   AppSpacing.md)
                    .padding(.horizontal, AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .fill(AppColors.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .stroke(AppColors.borderActive, lineWidth: 1)
                            )
                    )
                    .shadow(
                        color:  citShadow.color,
                        radius: citShadow.radius,
                        x:      citShadow.x,
                        y:      citShadow.y
                    )
                    .padding(.top, AppSpacing.md)
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    // MARK: - Ethos Text

    private struct EthosTextView: View {

        var body: some View {
            HStack(spacing: 0) {
                Text("You're not alone.")
                    .font(AppFonts.body(14, weight: .semibold, relativeTo: .callout))
                    .foregroundStyle(LinearGradient(
                        colors: [
                            AppColors.accentPrimary.opacity(0.90),   // 0.90 — near-opaque gradient lead. 10% transparency softens the hard start of the gradient sweep.
                            AppColors.accentSecondary.opacity(0.80), // 0.80 — gradient tail. 10pt drop from lead produces a gentle luminosity fade across the short phrase.
                        ],
                        startPoint: .topLeading,
                        endPoint:   .bottomTrailing
                    ))
                Text(" And this isn't new.")
                    .font(AppFonts.body(14, weight: .medium, relativeTo: .callout))
                    .tracking(0.2)
                    .foregroundStyle(AppColors.textPrimary)
            }
            // 14 × 0.6 — standard 60% line height ratio at 14pt.
            // Intentional typographic constant, not an AppSpacing candidate.
            .lineSpacing(14 * 0.6)
            .multilineTextAlignment(.center)
            // Combine both Text nodes so VoiceOver reads the full
            // sentence as one unit rather than two fragments.
            .accessibilityElement(children: .combine)
            .accessibilityLabel("You're not alone. And this isn't new.")
        }
    }
}

#Preview("Dark") {
    ZStack {
        OnboardingAtmosphere(config: .stat, opacity: 1.0)
            .ignoresSafeArea()
        StatPhase(director: VaylDirector())
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat, sparkConfig: .statView, opacity: 1.0)
            .ignoresSafeArea()
        StatPhase(director: VaylDirector())
    }
    .preferredColorScheme(.light)
}
