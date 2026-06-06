//
//  StatPhase.swift
//  Vayl
//

import SwiftUI

// MARK: - Layout constants

// Reference height used to derive the scale factor for the decorative
// atmosphere ellipse. This is a screen-calibration constant, not a
// spacing token — changing it repositions the ellipse on all devices.
private let kReferenceHeight: CGFloat = 844

// Vertical offset of the decorative background ellipse at reference height.
// Scales proportionally with usableH via `scale`. Rendering constant only.
private let kAtmosphereEllipseOffset: CGFloat = 260

// MARK: - StatPhase

struct StatPhase: View {

    let director: VaylDirector

    // Stat content. Making these explicit properties (rather than inline literals)
    // lets hasContent guard against future CMS gaps without touching rendering code.
    private let statText: String = "1 in 5"
    private let bodyText: String = "Americans have engaged in consensual non\u{2011}monogamy at some point in their lives."

    private var hasContent: Bool {
        !statText.isEmpty && !bodyText.isEmpty
    }

    // Real device safe area, injected by OnboardingCanvasWrapper before the
    // canvas's .ignoresSafeArea() chain consumes it. Defaults to EdgeInsets()
    // in standalone previews — correct because those GRs are already inside the
    // safe area region and need no additional offset compensation.
    @Environment(\.realSafeArea) private var safeAreaInsets

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
    @State private var statAlpha:  Double = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let layout  = AppLayout.from(geo)
            let screenW = layout.screenWidth

            // ── Safe-area — read from environment ─────────────────────────
            // safeAreaInsets is captured by OnboardingCanvasWrapper before the
            // canvas's .ignoresSafeArea() chain consumes it. It is (0, 0) in
            // standalone previews where the GR is already inside the safe area.
            //
            // usableH: geo.size.height minus the safe area the GR spans.
            //   Canvas  → geo.size = 852, safeArea = (59, 34) → usableH = 759
            //   Preview → geo.size = 759, safeArea = (0,  0)  → usableH = 759
            // Both contexts produce the same usableH, so spacing is identical.
            let safeArea = safeAreaInsets
            let usableH  = geo.size.height - safeArea.top - safeArea.bottom
            let scale    = usableH / kReferenceHeight

            // TODO: 100/140/164pt outside AppFonts type scale.
            // AppFonts.heroTitle (42pt) and displayHero (64pt) are the largest tokens.
            // A dedicated AppFonts.statHero token is required. Tracked as spec gap.
            let statFontSize: CGFloat = usableH <= 700
                ? 100
                : (screenW > 390 ? 164 : 140)

            ZStack {
                // Phase inherits void and atmosphere from OnboardingCanvasView.
                Color.clear.ignoresSafeArea()

                // ── Ambient background ellipse — decorative only ───────────
                // Hidden from VoiceOver — purely atmospheric, no semantic content.
                Ellipse()
                    .fill(RadialGradient(stops: [
                        .init(color: AppColors.accentSecondary.opacity(kAtmosphereOuter), location: 0),
                        .init(color: AppColors.accentSecondary.opacity(kAtmosphereMid),   location: 0.5),
                        .init(color: .clear,                                              location: 1)
                    ], center: .center, startRadius: 0, endRadius: 240))
                    .frame(width: 380, height: 220) // decorative atmosphere constants — token pending AppLayout
                    .blur(radius: 90)
                    .offset(y: kAtmosphereEllipseOffset * scale)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                // ── Content — three explicit zones, proportional to usableH ──
                VStack(spacing: 0) {
                    // Zone 1 — Top breathing room: status bar + intentional air.
                    // Pushes content down from the Dynamic Island with purpose.
                    Color.clear.frame(height: safeArea.top + (usableH * 0.06))

                    // Zone 2 — Flourish + Stat hero: owns the top-center of the screen.
                    if hasContent {
                        contentGroup(statFontSize: statFontSize)
                            .padding(.horizontal, AppLayout.screenMargin)
                    } else {
                        emptyStateView
                    }

                    // Zone 3 — Bottom buffer: flexible space above CTA.
                    // minLength prevents collapse on iPhone SE.
                    Spacer(minLength: AppSpacing.xl)
                }
                .opacity(statAlpha)

                // ── CTA — pinned to real safe-area bottom ──────────────────
                // Separate ZStack layer so content Spacers cannot push the button
                // lower as available height grows.
                if hasContent {
                    VStack(spacing: 0) {
                        Spacer()
                        VaylButton(
                            label: "Begin",
                            action: {
                                guard !hasAdvanced else { return }
                                hasAdvanced = true
                                withAnimation(.easeOut(duration: 0.65)) { statAlpha = 0.0 }
                                Task { @MainActor in
                                    // Brief beat — just enough for the fade to land, not a hitch
                                    try? await Task.sleep(for: .milliseconds(150))
                                    director.advance(to: .name)
                                }
                            }
                        )
                        .padding(.horizontal, AppLayout.ctaHorizontalMargin)
                        .padding(.bottom, safeArea.bottom + AppSpacing.lg)
                        .opacity(showCTA ? 1 : 0)
                        .offset(y: showCTA ? 0 : 10)
                        .accessibilityLabel("Begin")
                        .accessibilityAddTraits(.isButton)

                    }
                    .opacity(statAlpha)
                }
            }
        }
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true
            startAllAnimations()
        }
        .task {
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
            statAlpha   = 1.0
            // hasAdvanced intentionally NOT reset.
            // One-way latch — prevents double-fire of director.advance.
        }
    }

    // MARK: - Content Group

    // Rendering constants for the OB atmospheric background ellipse.
    // The 0.08–0.12 range is the OB atmospheric opacity spec — felt, not seen.
    private let kAtmosphereOuter: CGFloat = 0.12
    private let kAtmosphereMid:   CGFloat = 0.06

    @ViewBuilder
    private func contentGroup(statFontSize: CGFloat) -> some View {
        VStack(spacing: 0) {

            // ── Flourish — crowns the stat, not floats above void ─────────
            VaylFlourishView()
                .frame(width: AppLayout.flourishWidth, height: AppLayout.flourishHeight)
                .padding(.bottom, AppSpacing.md)

            // ── Stat hero — the primary communicative element ─────────────
            StatNumberView(
                holoShiftPhase:  holoShiftPhase,
                holoFlashOffset: holoFlashOffset,
                glowPulseHigh:   glowPulseHigh,
                castPulseHigh:   castPulseHigh,
                fontSize:        statFontSize
            )
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
            .opacity(showStat ? 1 : 0)
            .scaleEffect(showStat ? 1.0 : 0.94)
            .accessibilityLabel("1 in 5 Americans have engaged in consensual non-monogamy at some point in their lives.")
            .accessibilityAddTraits(.isStaticText)
            // Stat is a declaration, not a header — needs air below.
            .padding(.bottom, AppSpacing.xl)

            // ── Body copy + citation — tightly coupled semantic unit ──────
            VStack(spacing: AppSpacing.lg) {
                Text(bodyText)
                    .font(AppFonts.body(18, weight: .regular, relativeTo: .body))
                    .lineSpacing(10.8)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(showStatLabel ? 1 : 0)
                    .offset(y: showStatLabel ? 0 : 14)
                    .accessibilityHidden(true)

                CitationTapView(citeOpen: $citeOpen)
                    .opacity(showCiteTap ? 1 : 0)
                    .offset(y: showCiteTap ? 0 : 14)
            }
            // Different semantic register — needs clear separation from stat block.
            .padding(.bottom, AppSpacing.xxl)

            // ── Ethos line — emotional punctuation, own semantic zone ─────
            EthosTextView()
                .opacity(showEthos ? 1 : 0)
                .offset(y: showEthos ? 0 : 8)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40)) // empty-state symbol — token pending AppLayout
                .foregroundStyle(AppColors.textSecondary)
            Text("Stat unavailable")
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.animation(AppAnimation.standard))
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
            withAnimation(AppAnimation.cinematicFade)      { showStat      = true }
            withAnimation(AppAnimation.slow.delay(0.5))    { showStatLabel = true }
            withAnimation(AppAnimation.slow.delay(0.7))    { showCiteTap   = true }
            withAnimation(AppAnimation.slow.delay(1.0))    { showEthos     = true }
            withAnimation(AppAnimation.spring.delay(1.4))  { showCTA       = true }
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

        // Glow breathe cycle opacity. Rendering constants for ambient pulse.
        // Not AppColors candidates — these are View opacity levels, not colors.
        private let kGlowPulseHigh: CGFloat = 0.40  // breathe peak — glow without washing out numeral
        private let kGlowPulseLow:  CGFloat = 0.25  // breathe floor — minimum presence at rest

        // Cast shadow pulse opacity. Same rationale as glow breathe constants.
        private let kCastPulseHigh: CGFloat = 1.00  // shadow at full presence when numeral breathes up
        private let kCastPulseLow:  CGFloat = 0.70  // 70% retains shadow at rest without disappearing

        // Specular highlight physics constants. Simulate light reflectance on a
        // holographic surface — not semantic tokens, not design decisions.
        private let kSpecularPrimary:   CGFloat = 0.30  // primary highlight peak
        private let kSpecularSecondary: CGFloat = 0.18  // secondary highlight

        // Cast shadow radial gradient opacity stops. Atmospheric rendering constants.
        private let kCastShadowPrimary:   CGFloat = 0.18  // cast shadow primary stop
        private let kCastShadowSecondary: CGFloat = 0.10  // cast shadow secondary stop

        private var fnt: Font {
            AppFonts.display(fontSize, weight: .bold, relativeTo: .largeTitle)
        }

        // -3.2 × (fontSize / 140) — tracking scaled proportionally to font size.
        // -3.2 is the base tracking at 140pt. Geometry-relative constant, not
        // an AppSpacing candidate — letterform spacing, not UI element spacing.
        private var trk: CGFloat { -3.2 * (fontSize / 140) }

        // Cast ellipse geometry — all proportional to fontSize.
        private var castWidth:  CGFloat { 300 * (fontSize / 140) }
        private var castHeight: CGFloat { 55  * (fontSize / 140) }
        private var castOffset: CGFloat { 70  * (fontSize / 140) }

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
                    .opacity(glowPulseHigh ? kGlowPulseHigh : kGlowPulseLow)
                    .padding(kGlowBleedPad)
                    .accessibilityHidden(true)

                // Ground cast shadow — ellipse beneath numeral.
                Ellipse()
                    .fill(RadialGradient(stops: [
                        .init(color: AppColors.accentSecondary.opacity(kCastShadowPrimary),   location: 0),
                        .init(color: AppColors.accentPrimary.opacity(kCastShadowSecondary),   location: 0.4),
                        .init(color: .clear, location: 0.7)
                    ], center: .center, startRadius: 0, endRadius: 150))
                    .frame(width: castWidth, height: castHeight)
                    .blur(radius: 20)
                    .scaleEffect(x: castPulseHigh ? 1.12 : 1.0, y: 1.0)
                    .opacity(castPulseHigh ? kCastPulseHigh : kCastPulseLow)
                    .offset(y: castOffset)
                    .accessibilityHidden(true)

                // Core gradient numeral — visual representation only.
                // Semantic label applied at StatNumberView call site.
                baseText
                    .foregroundStyle(.clear)
                    .overlay { activeGradient.mask { baseText } }
                    .accessibilityHidden(true)

                // Specular highlight sweep — holographic light catch.
                baseText
                    .foregroundStyle(.clear)
                    .overlay {
                        LinearGradient(
                            stops: [
                                .init(color: .clear,                                location: 0.00),
                                .init(color: .clear,                                location: 0.30),
                                .init(color: Color.white.opacity(kSpecularPrimary), location: 0.38),
                                .init(color: Color.white.opacity(0),                location: 0.42),
                                .init(color: .clear,                                location: 0.50),
                                .init(color: Color.white.opacity(kSpecularSecondary), location: 0.60),
                                .init(color: .clear,                                location: 0.65),
                                .init(color: .clear,                                location: 1.00),
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

        // Frosted glass surface opacity constants — translucent pill simulation.
        // Granularity is below the semantic AppColors system coverage.
        // Rendering constants only — not candidates for AppColors tokens.
        private let kGlassFill:   CGFloat = 0.06
        private let kGlassBorder: CGFloat = 0.12

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
                            .fill(Color.white.opacity(kGlassFill))
                            .overlay {
                                Capsule()
                                    .stroke(Color.white.opacity(kGlassBorder), lineWidth: 1)
                            }
                    }
                    .contentShape(Capsule().inset(by: -8))
                }
                .buttonStyle(CiteButtonStyle())
                .accessibilityLabel(citeOpen ? "Hide research citation" : "About this research")
                .accessibilityAddTraits(.isButton)

                if citeOpen {
                    let citShadow = AppElevation.citationPanel.midnightShadow

                    VStack(alignment: .leading, spacing: 0) {
                        Text(citationBody())
                            .foregroundColor(AppColors.textPrimary)
                            // 11.5 × 0.7 — 70% line height ratio at 11.5pt.
                            // Tighter than the standard 0.6 ratio — citation copy
                            // is dense and benefits from slightly more leading.
                            .lineSpacing(11.5 * 0.7)

                        Text("Haupert et al., 2017 · Journal of Sex Research")
                            .font(AppFonts.caption.italic())
                            .foregroundStyle(AppColors.textTertiary)
                            .padding(.top, AppSpacing.sm)
                    }
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
                    .font(AppFonts.body(15, weight: .semibold, relativeTo: .callout))
                    .foregroundStyle(LinearGradient(
                        colors: [
                            AppColors.ethosGradientLead,
                            AppColors.ethosGradientTrail,
                        ],
                        startPoint: .topLeading,
                        endPoint:   .bottomTrailing
                    ))
                Text(" And this isn't new.")
                    .font(AppFonts.body(15, weight: .medium, relativeTo: .callout))
                    .tracking(0.2)
                    .foregroundStyle(AppColors.textPrimary)
                
            }
            // 14 × 0.6 — standard 60% line height ratio at 14pt.
            // Intentional typographic constant, not an AppSpacing candidate.
            .lineSpacing(15 * 0.6)
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
