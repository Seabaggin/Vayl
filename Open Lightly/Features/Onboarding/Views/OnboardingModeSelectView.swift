// OnboardingModeSelectView.swift
// Open Lightly
//
// Screen 2: Mode Select — Solo vs. Partnered + NM experience level
// ✅ Adaptive layout — ViewThatFits prevents scroll on all devices where content fits

import SwiftUI

struct OnboardingModeSelectView: View {
    @Binding var data: OnboardingData
    var onContinue: () -> Void
    var onBack: (() -> Void)?

    @State private var titleVisible  = false
    @State private var navVisible    = false
    @State private var cardsVisible  = false
    @State private var hasAnimated   = false

    @Environment(\.colorScheme) private var colorScheme

    private var selectionMade: Bool {
        data.explorationMode != nil && data.nmStage != nil
    }

    private var experienceDescriptor: String? {
        switch data.nmStage {
        case .curious:     return "New to this — maybe I've read about it or know people who do it."
        case .exploring:   return "I've dipped my toes in. A few real experiences."
        case .experienced: return "This has been part of my life for a while."
        case .none:        return nil
        }
    }

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width

            let sectionSpacing: CGFloat = h < 700
                ? max(8.0, h * 0.012)
                : max(12.0, h * 0.018)

            let cardPadding: CGFloat = h < 700
                ? max(8.0, h * 0.013)
                : max(10.0, h * 0.016)

            let cardSpacing = max(8.0, h * 0.012)

            let navBottomPad: CGFloat = h < 700
                ? max(12.0, h * 0.018)
                : max(24.0, h * 0.038)

            ZStack {
                // ── Background — layer 0 ──────────────────────────────────
                if colorScheme == .light {
                    AppColors.lightPageBg.ignoresSafeArea()
                } else {
                    AppColors.pageBg.ignoresSafeArea()
                }

                // ── Glow field — layer 1 ──────────────────────────────────
                if colorScheme == .light {
                    AuroraGlowField(config: .modeSelectView)
                        .ignoresSafeArea()
                } else {
                    OnboardingGlowField()
                        .ignoresSafeArea()
                }

                // ── SparkField — layer 2 (light only) ────────────────────
                if colorScheme == .light {
                    SparkField(config: .modeSelectView)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                // ── Content layers above ──────────────────────────────────
                VStack(spacing: 0) {

                    HStack {
                        OnboardingNavArrow(direction: .back, size: CGSize(width: 56, height: 48), action: {
                            onBack?()
                        })

                        Spacer()

                        OnboardingProgressBar(currentStep: 2, totalSteps: 6)

                        Spacer()

                        Color.clear
                            .frame(width: 56, height: 48)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, navBottomPad)
                    .opacity(navVisible ? 1.0 : 0.18)

                    // ── ViewThatFits: no-scroll preferred, scroll fallback ──
                    // Attempt 1: plain VStack + Spacer — CTA pins to bottom.
                    // SwiftUI uses this if ALL content fits without clipping.
                    // Attempt 2: ScrollView fallback — only activates on SE
                    // when experience section is fully expanded (State 3B).
                    ViewThatFits(in: .vertical) {

                        // Attempt 1 — preferred, no scroll
                        VStack(spacing: 0) {
                            contentBlock(
                                sectionSpacing: sectionSpacing,
                                cardPadding: cardPadding,
                                cardSpacing: cardSpacing
                            )
                            Spacer()
                                .frame(minHeight: 32, maxHeight: 44)
                                .fixedSize(horizontal: false, vertical: true)
                            ctaBlock
                                .padding(.horizontal, 24)
                        }

                        // Attempt 2 — scroll fallback
                        VStack(spacing: 0) {
                            ScrollView(showsIndicators: false) {
                                contentBlock(
                                    sectionSpacing: sectionSpacing,
                                    cardPadding: cardPadding,
                                    cardSpacing: cardSpacing
                                )
                            }
                            ctaBlock
                                .padding(.horizontal, 24)
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)

                // ── Dark atmosphere ellipse ───────────────────────────────
                if colorScheme == .dark {
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [
                                AppColors.purple.opacity(0.3),
                                AppColors.deepBlue.opacity(0.15),
                                Color.clear
                            ],
                            center: .top,
                            startRadius: 30,
                            endRadius: 360
                        ))
                        .frame(width: OL.atmosW(w), height: OL.atmosH(h))
                        .offset(y: -h * 0.09)
                        .blur(radius: 80)
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                guard !hasAnimated else {
                    titleVisible = true
                    cardsVisible = true
                    navVisible   = true
                    return
                }
                hasAnimated = true
                withAnimation(.easeOut(duration: 0.4).delay(0.15)) { titleVisible = true }
                withAnimation(.easeOut(duration: 0.4).delay(0.35)) { cardsVisible = true }
                withAnimation(.easeOut(duration: 0.3).delay(1.50)) { navVisible   = true }
            }
        }
    }

    // MARK: - Content Block
    // Extracted so ViewThatFits can use it in both layout attempts
    // without duplicating markup.

    private func contentBlock(
        sectionSpacing: CGFloat,
        cardPadding: CGFloat,
        cardSpacing: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {

            // ── Title ──────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                Text("How are you")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightCardTitle
                        : AppColors.textPrimary)

                Text("exploring?")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(colorScheme == .light
                        ? AnyShapeStyle(LinearGradient(
                            colors: [AppColors.magenta, AppColors.gold],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.purple, AppColors.cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )))
            }
            .padding(.bottom, 4)
            .opacity(titleVisible ? 1 : 0)
            .offset(y: titleVisible ? 0 : 12)

            // ── Mode cards ─────────────────────────────────────────
            VStack(spacing: cardSpacing) {
                modeCard(
                    icon: "✦",
                    title: "On my own",
                    subtitle: "Figure out what you want first",
                    mode: .solo,
                    cardPadding: cardPadding
                )
                modeCard(
                    icon: "✦",
                    title: "With a partner",
                    subtitle: "Start the conversation together",
                    mode: .couple,
                    cardPadding: cardPadding
                )
                modeCard(
                    icon: "✦",
                    title: "Just browsing",
                    subtitle: "Explore the app before deciding",
                    mode: .browsing,
                    cardPadding: cardPadding
                )
            }
            .opacity(cardsVisible ? 1 : 0)
            .offset(y: cardsVisible ? 0 : 16)

            // ── Experience level ───────────────────────────────────
            if data.explorationMode != nil {
                VStack(spacing: 0) {
                    Spacer().frame(height: 36)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your experience")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightCardTitle.opacity(0.65)
                                : AppColors.textSecondary)

                        // MARK: Intensity graduation: dim → warm → alive
                        // These intensities affect the UNSELECTED appearance of each pill.
                        // The progression is intentional — it communicates that the options
                        // exist on a spectrum of experience.
                        // Known tradeoff: .dim on "Curious" may feel lower-status for new users.
                        // The descriptor text on selection is the primary shame-reduction
                        // mechanism here, not pill styling.
                        // Change only after user testing confirms the gradient reads as
                        // hierarchical rather than descriptive.
                        HStack(spacing: 10) {
                            SelectablePill(
                                label: "Curious",
                                isSelected: data.nmStage == .curious,
                                intensity: .dim,
                                height: 42,
                                fontSize: 14
                            ) {
                                data.nmStage = .curious
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            SelectablePill(
                                label: "Exploring",
                                isSelected: data.nmStage == .exploring,
                                intensity: .warm,
                                height: 42,
                                fontSize: 14
                            ) {
                                data.nmStage = .exploring
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            SelectablePill(
                                label: "Experienced",
                                isSelected: data.nmStage == .experienced,
                                intensity: .alive,
                                height: 42,
                                fontSize: 14
                            ) {
                                data.nmStage = .experienced
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if colorScheme == .dark {
                                Capsule()
                                    .fill(Color.black.opacity(0.45))
                                    .blur(radius: 30)
                                    .padding(.horizontal, -6)
                            }
                        }

                        if let descriptor = experienceDescriptor {
                            Text(descriptor)
                                .font(AppFonts.caption)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.lightCardTitle.opacity(0.65)
                                    : AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.88)
                                .id(data.nmStage)
                                .accessibilityAddTraits(.updatesFrequently)
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Your NM experience level")
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }

    // MARK: - CTA Block
    // Extracted so both ViewThatFits branches share identical CTA.

    private var ctaBlock: some View {
        VStack(spacing: 0) {
            HoloCTAButton(title: "Next", isEnabled: selectionMade) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onContinue()
            }
            OnboardingFooter(text: "Your data is encrypted and always stays yours.")
        }
    }

    // MARK: - Mode Card

    private func modeCard(
        icon: String,
        title: String,
        subtitle: String,
        mode: ExplorationMode,
        cardPadding: CGFloat
    ) -> some View {
        let isSelected = data.explorationMode == mode

        return Button {
            data.explorationMode = mode
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 14) {
                Text(icon)
                    .font(AppFonts.body(18))
                    .foregroundStyle(
                        isSelected
                            ? (colorScheme == .light ? AppColors.purple : AppColors.cyan)
                            : (colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)
                    )
                    .frame(width: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightCardTitle
                            : AppColors.textPrimary)
                    Text(subtitle)
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightCardTitle.opacity(0.65)
                            : AppColors.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .light
                        ? (isSelected ? AppColors.lightFrostCard : AppColors.lightFrostPill)
                        : AppColors.cardBg)
            )
            .overlay(
                Group {
                    if isSelected {
                        if colorScheme == .light {
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(AppColors.warmAuroraBorder, lineWidth: 2)
                        } else {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            AppColors.cyan,
                                            AppColors.purple,
                                            AppColors.magenta
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 2
                                )
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                colorScheme == .light
                                    ? AppColors.lightBorder
                                    : AppColors.border,
                                lineWidth: 1.5
                            )
                    }
                }
            )
            .compositingGroup()
            .shadow(
                color: isSelected
                    ? (colorScheme == .light
                        ? AppColors.lightShadowMagenta
                        : AppColors.cyan.opacity(0.3))
                    : .clear,
                radius: 8
            )
            .shadow(
                color: isSelected
                    ? (colorScheme == .light
                        ? AppColors.lightShadowPurple
                        : AppColors.magenta.opacity(0.2))
                    : .clear,
                radius: 12
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint(isSelected ? "Selected" : "Double-tap to select \(title)")
    }
}

// MARK: - Previews

#Preview("Dark") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .solo
        d.nmStage         = .exploring
        return d
    }()
    OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .solo
        d.nmStage         = .exploring
        return d
    }()
    OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
        .preferredColorScheme(.light)
}

// MARK: - Changes applied
// LIGHT-01 through LIGHT-21 — preserved, see prior change log
// FIX-16   GeometryReader wraps outer VStack for spacing values only
// FIX-17   REMOVED .frame(maxHeight: .infinity) from ScrollView
// FIX-18   All withAnimation() removed from binding writes
// FIX-19   Proportional spacing via GeometryReader h value
// FIX-20   ViewThatFits replaces ScrollView-as-spacer pattern.
//          Attempt 1: plain VStack + Spacer(minLength:0) — CTA pins to bottom.
//          Attempt 2: ScrollView fallback — only activates when content
//          genuinely overflows (SE + full selection + 2-line descriptor).
//          This eliminates the dead space between cards and CTA on all
//          devices where content fits without scrolling.
// FIX-21   contentBlock() and ctaBlock extracted to eliminate markup
//          duplication across the two ViewThatFits branches.
// FIX-22   Five visual hierarchy fixes: removed "No judgment" label,
//          removed reassurance line, increased nav-to-hero gap,
//          enforced 40pt min spacer above CTA, capped descriptor
//          at 2 lines with 0.88 scale factor.
// FIX-23   Fresh audit fixes: removed subtitle text, reduced title
//          bottom pad to 4pt, tightened CTA spacer to 32–44pt with
//          fixedSize, increased navBottomPad floor to 24pt / 0.038
//          on non-SE devices, increased card-to-experience gap to
//          36pt, fixed contentBlock bottom padding to 8pt flat.
