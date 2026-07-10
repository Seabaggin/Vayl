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

    @State private var holoShiftPhase: CGFloat = -0.35
    @State private var holoFlashOffset: CGFloat =  2.5
    @State private var glowPulseHigh  = false

    // Arrival ignition — one-time light-catch fired as the numeral seats (~0.76s).
    @State private var igniteGlow: Double  = 0     // additive glow bloom, 0 at rest
    @State private var igniteSweepX: CGFloat = 2.5    // bright sweep parked off-screen right
    @State private var softHaptic = UIImpactFeedbackGenerator(style: .soft)

    // Ignition rendering constants — felt on device, not AppColors candidates.
    private let kGlowBloomBoost: Double  = 0.40   // additive peak → ~0.80 composite over resting 0.40
    private let kLandScaleFrom: CGFloat = 0.90   // hero scales up from 0.90 as it seats

    // Entrance cascade — fires in sequence via startAllAnimations()
    @State private var showStat      = false
    @State private var showStatLabel = false
    @State private var showEthos     = false
    @State private var showCTA       = false

    @State private var citeOpen    = false
    @State private var hasAnimated = false
    @State private var hasAdvanced = false
    @State private var statAlpha: Double = 1.0

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

            // Hero numeral size resolves from AppLayout (responsive by usable height +
            // width) and renders via AppFonts.statHero — no inline literals in the View.
            let statFontSize = AppLayout.statHeroSize(usableHeight: usableH, screenWidth: screenW)

            ZStack {
                // Phase inherits void and atmosphere from OnboardingCanvasView.
                Color.clear.ignoresSafeArea()

                // ── Ambient background ellipse — decorative only ───────────
                // Hidden from VoiceOver — purely atmospheric, no semantic content.
                Ellipse()
                    .fill(RadialGradient(stops: [
                        .init(color: AppColors.accentSecondary.opacity(kAtmosphereOuter), location: 0),
                        .init(color: AppColors.accentSecondary.opacity(kAtmosphereMid), location: 0.5),
                        .init(color: .clear, location: 1)
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
                                withAnimation(AppAnimation.statExitFade) { statAlpha = 0.0 }
                                Task { @MainActor in
                                    // Hold until the fade is ~88% done (easeOut) — the
                                    // 0.3s phase cross-fade absorbs the tail. Advancing
                                    // earlier unmounts the view and renders as a hard cut.
                                    try? await Task.sleep(for: .milliseconds(450))
                                    director.advance(to: .demo)
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

                // ── Citation pop-out — dims everything behind, tap to dismiss ──
                if citeOpen {
                    ZStack {
                        AppColors.scrimHeavy
                            .ignoresSafeArea()
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(AppAnimation.statCitationToggle) { citeOpen = false }
                            }
                        CitationCard()
                            .padding(.horizontal, AppLayout.screenMargin)
                    }
                    .transition(.opacity)
                    .zIndex(50)
                    .accessibilityAddTraits(.isModal)
                }
            }
        }
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true
            softHaptic.prepare()
            startAllAnimations()
            fireIgnitionOnLand()
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
        }
        .onDisappear {
            hasAnimated = false
            statAlpha   = 1.0
            // Reset ignition so a re-entry (e.g. dev phase-jump) lands clean.
            igniteGlow   = 0
            igniteSweepX = 2.5
            // hasAdvanced intentionally NOT reset.
            // One-way latch — prevents double-fire of director.advance.
        }
    }

    // MARK: - Content Group

    // Rendering constants for the OB atmospheric background ellipse.
    // The 0.08–0.12 range is the OB atmospheric opacity spec — felt, not seen.
    private let kAtmosphereOuter: CGFloat = 0.12
    private let kAtmosphereMid: CGFloat = 0.06

    @ViewBuilder
    private func contentGroup(statFontSize: CGFloat) -> some View {
        VStack(spacing: 0) {

            // ── Flourish — crowns the stat, not floats above void ─────────
            VaylFlourishView()
                .frame(width: AppLayout.flourishWidth, height: AppLayout.flourishHeight)
                .padding(.bottom, AppSpacing.md)

            // ── Stat hero — the primary communicative element ─────────────
            StatNumberView(
                holoShiftPhase: holoShiftPhase,
                holoFlashOffset: holoFlashOffset,
                glowPulseHigh: glowPulseHigh,
                igniteSweepX: igniteSweepX,
                igniteGlow: igniteGlow,
                fontSize: statFontSize
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
            .opacity(showStat ? 1 : 0)
            .scaleEffect(showStat ? 1.0 : kLandScaleFrom)
            .accessibilityLabel("1 in 5 Americans have engaged in consensual non-monogamy at some point in their lives.")
            .accessibilityAddTraits(.isStaticText)
            // Stat is a declaration, not a header — needs air below.
            .padding(.bottom, AppSpacing.xl)

            // ── Body copy + citation — tightly coupled semantic unit ──────
            // Claim with an inline source ⓘ (taps to reveal the citation), panel below.
            CitationTapView(citeOpen: $citeOpen)
                .opacity(showStatLabel ? 1 : 0)
                .offset(y: showStatLabel ? 0 : 14)
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
            Image(systemName: AppIcons.chartBarXaxis)
                .font(AppFonts.body(40, weight: .regular, relativeTo: .largeTitle)) // empty-state symbol — token pending AppLayout
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
            showStat        = true
            showStatLabel   = true
            showEthos       = true
            showCTA         = true
        } else {
            withAnimation(AppAnimation.cinematicFade) { showStat      = true }
            withAnimation(AppAnimation.slow.delay(0.5)) { showStatLabel = true }
            withAnimation(AppAnimation.slow.delay(1.0)) { showEthos     = true }
            withAnimation(AppAnimation.spring.delay(1.4)) { showCTA       = true }
        }
    }

    // MARK: - Arrival Ignition
    //
    // Fires once, ~0.76s into the stat's land, so the light catches the numeral as it
    // seats: a bright specular sweep crosses it, the glow blooms past its resting level
    // then settles, and a soft haptic lands. Reduce motion: the soft tap still fires
    // (haptics are not motion), but the sweep + bloom are skipped.

    private func fireIgnitionOnLand() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(AppAnimation.statIgnitionDelay))
            guard !hasAdvanced else { return }   // user already tapped Begin — don't ignite a leaving screen

            softHaptic.impactOccurred()          // soft land tap
            guard !reduceMotion else { return }  // skip the visual ignition under reduce motion

            withAnimation(AppAnimation.statIgnitionSweep) { igniteSweepX = -2.5 }
            withAnimation(AppAnimation.statGlowBloomIn) { igniteGlow   = kGlowBloomBoost }
            try? await Task.sleep(for: .seconds(AppAnimation.statGlowBloomHold))
            withAnimation(AppAnimation.statGlowBloomSettle) { igniteGlow = 0 }
        }
    }

    // MARK: - Stat Number (Holographic "1 in 5")

    private struct StatNumberView: View {
        let holoShiftPhase: CGFloat
        let holoFlashOffset: CGFloat
        let glowPulseHigh: Bool
        let igniteSweepX: CGFloat   // bright one-time sweep position (parked off-screen at rest)
        let igniteGlow: Double    // additive ignition bloom opacity (0 at rest)

        var fontSize: CGFloat = 140

        private let txt = "1 in 5"

        private var fnt: Font {
            AppFonts.statHero(fontSize)
        }

        // -3.2 × (fontSize / 140) — tracking scaled proportionally to font size.
        // -3.2 is the base tracking at 140pt. Geometry-relative constant, not
        // an AppSpacing candidate — letterform spacing, not UI element spacing.
        private var trk: CGFloat { -3.2 * (fontSize / 140) }

        var body: some View {
            // Single source of truth for the glass recipe (gradient + glow + specular).
            // StatPhase drives the animation values + arrival-ignition layers; the core
            // renders the pixels. Semantic label applied at the StatNumberView call site,
            // so internals stay accessibilityHidden inside the core.
            HolographicTextCore(
                text: txt,
                font: fnt,
                tracking: trk,
                shift: holoShiftPhase,
                flash: holoFlashOffset,
                glowHigh: glowPulseHigh,
                igniteGlow: igniteGlow,
                igniteSweepX: igniteSweepX,
                fixedSize: true
            )
        }
    }

    // MARK: - Citation Tap

    private struct CitationTapView: View {
        @Binding var citeOpen: Bool

        private struct CiteButtonStyle: ButtonStyle {
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
                    .offset(y: configuration.isPressed ? 1 : 0)
                    .animation(AppAnimation.fast, value: configuration.isPressed)
                    .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed)
            }
        }

        var body: some View {
            Button {
                withAnimation(AppAnimation.statCitationToggle) {   // FEEL-GATE: calm dim + fade
                    citeOpen.toggle()
                }
            } label: {
                // Hand-set to 3 lines so the gradient ⓘ can ride the last line as a real
                // Image (a glyph inside Text can't carry a gradient). The whole sentence
                // taps to reveal the citation; minimumScaleFactor holds 3 lines on narrow
                // widths. FEEL-GATE: the line breaks, and the ⓘ size (as big as fits).
                VStack(spacing: AppSpacing.xxs) {
                    Text("Americans have engaged in")
                    Text("consensual non\u{2011}monogamy at")
                    HStack(alignment: .center, spacing: AppSpacing.xs) {
                        Text("some point in their lives.")
                        Image(systemName: AppIcons.infoCircle)
                            .font(AppFonts.body(23.5, weight: .regular, relativeTo: .title3))   // FEEL-GATE
                            .foregroundStyle(AppColors.spectrumText)
                    }
                }
                .font(AppFonts.body(22, weight: .regular, relativeTo: .title3))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .contentShape(Rectangle())
                .accessibilityHidden(true)
            }
            .buttonStyle(CiteButtonStyle())
            .accessibilityLabel(citeOpen ? "Hide research citation" : "About this research")
            .accessibilityAddTraits(.isButton)
        }
    }

    // MARK: - Citation Card (pop-out)

    private struct CitationCard: View {
        private func citationBody() -> AttributedString {
            var result = AttributedString()
            var first = AttributedString("Two nationally representative studies")
            first.font = AppFonts.body(17, weight: .semibold, relativeTo: .body)   // FEEL-GATE: fills the box
            result.append(first)
            var second = AttributedString(" of 8,718 single adults. Roughly 1 in 5 reported engaging in CNM \u{2014} consistent across age, income, religion, race, political affiliation, and region.")
            second.font = AppFonts.body(17, weight: .regular, relativeTo: .body)
            result.append(second)
            return result
        }

        var body: some View {
            let shadow = AppElevation.citationPanel.midnightShadow
            VStack(alignment: .leading, spacing: 0) {
                // Small spectrum overline — structure + fills the top of the box.
                Text("The finding")
                    .font(AppFonts.body(13, weight: .bold, relativeTo: .footnote))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.spectrumText)
                    .padding(.bottom, AppSpacing.sm)
                Text(citationBody())
                    .foregroundColor(AppColors.textPrimary)
                    .lineSpacing(7)
                Text("Haupert et al., 2017 · Journal of Sex Research")
                    .font(AppFonts.body(12.5, weight: .regular, relativeTo: .caption).italic())
                    .foregroundStyle(AppColors.textTertiary)
                    .padding(.top, AppSpacing.sm)
            }
            // minHeight makes the card read squarer (≈ its width once padded); .leading
            // centers the copy vertically in the taller box. FEEL-GATE: minHeight.
            .frame(maxWidth: AppLayout.citationPanelMaxWidth, minHeight: 250, alignment: .leading)
            .padding(AppSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(AppColors.cardBg)   // app's purplish OB surface
                    .overlay(
                        // Spectrum gradient border — in line with the rest of the app.
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .strokeBorder(AppColors.spectrumText, lineWidth: 1.5)
                    )
            )
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: - Ethos Text

    private struct EthosTextView: View {

        var body: some View {
            // Two-line: white setup over the gradient punchline. (The longer, larger copy
            // can't sit on one line, and a two-color HStack can't wrap — so the wrap is
            // deliberate, and it gives the takeaway the presence it was missing.)
            VStack(spacing: AppSpacing.xs) {   // FEEL-GATE: inter-line gap
                Text("That's about as ordinary as")
                    .font(AppFonts.body(20, weight: .bold, relativeTo: .title3))
                    .tracking(0.2)
                    .foregroundStyle(AppColors.textPrimary)
                Text("owning a cat.")
                    .font(AppFonts.body(20, weight: .bold, relativeTo: .title3))
                    .foregroundStyle(LinearGradient(
                        colors: [
                            AppColors.ethosGradientLead,
                            AppColors.ethosGradientTrail
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }
            .multilineTextAlignment(.center)
            // Combine both Text nodes so VoiceOver reads the full
            // sentence as one unit rather than two fragments.
            .accessibilityElement(children: .combine)
            .accessibilityLabel("That's about as ordinary as owning a cat.")
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
        OnboardingAtmosphere(config: .stat, opacity: 1.0)
            .ignoresSafeArea()
        StatPhase(director: VaylDirector())
    }
    .preferredColorScheme(.light)
}
