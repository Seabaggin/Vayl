//
//  OnboardingModeSelectView.swift
//  Vayl
//

import SwiftUI

// MARK: - Main View

struct OnboardingModeSelectView: View {
    @Binding var data: OnboardingData
    var onContinue: () -> Void
    var onBack: (() -> Void)?

    @State private var titleVisible   = false
    @State private var navVisible     = false
    @State private var cardsVisible   = false
    @State private var hasAnimated    = false

    @State private var soloBreath:     CGFloat = 0
    @State private var togetherBreath: CGFloat = 0
    @State private var browseBreath:   CGFloat = 0
    @State private var breathTask: Task<Void, Never>? = nil

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    private var selectionMade: Bool {
        guard let mode = data.appMode else { return false }
        if mode == .browsing { return true }
        return data.nmStage != nil
    }

    private var experienceDescriptor: String? {
        switch data.nmStage {
        case .curious:     return "New to this — maybe I've read about it or know people who do it."
        case .exploring:   return "I've dipped my toes in. A few real experiences."
        case .experienced: return "This has been part of my life for a while."
        case .none:        return nil
        }
    }

    private var atmosphereColors: (primary: Color, secondary: Color) {
        switch data.appMode {
        // TODO: verify token — original was AppColors.accentSecondary
        case .solo:     return (AppColors.accentPrimary,   AppColors.accentSecondary)
        case .together: return (AppColors.accentTertiary,  AppColors.accentSecondary)
        case .browsing: return (AppColors.safetyAccent,    AppColors.progressBarLeading)
        // TODO: verify token — original was AppColors.accentSecondary
        case .none:     return (AppColors.accentSecondary, AppColors.accentSecondary)
        }
    }

    private func handleSelection(_ mode: AppMode) {
        withAnimation(AppAnimation.spring) {
            if data.appMode == mode {
                data.appMode = nil
                data.nmStage = nil
            } else {
                if data.appMode != nil {
                    data.nmStage = nil
                }
                data.appMode = mode
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @ViewBuilder
    private func selectedBorder(
        isSelected:   Bool,
        cornerRadius: CGFloat
    ) -> some View {
        if isSelected {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(AppColors.spectrumBorder, lineWidth: 2)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(AppColors.spectrumBorder, lineWidth: 3)
                    .blur(radius: 4)
                    .opacity(0.25)
            }
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(AppColors.borderSubtle, lineWidth: 1.5)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let layout = AppLayout.from(geo)
            let h = layout.screenHeight
            let w = layout.screenWidth

            // Geometry-relative section spacing — not token candidates.
            // max() floors ensure minimum usable spacing on very small devices.
            let sectionSpacing: CGFloat = h < 700
                ? max(8.0, h * 0.012)
                : max(12.0, h * 0.018)

            ZStack {
                Color.clear.ignoresSafeArea()

                if !isLight {
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [
                                atmosphereColors.primary.opacity(0.30),
                                atmosphereColors.secondary.opacity(0.15),
                                Color.clear,
                            ],
                            center: .top,
                            startRadius: 30,
                            endRadius: 360
                        ))
                        .frame(width: OL.atmosW(w), height: OL.atmosH(h))
                        .offset(y: -h * 0.09)
                        .blur(radius: 80)
                        .animation(AppAnimation.enter, value: data.appMode?.rawValue ?? "none")
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }

                VStack(spacing: 0) {
                    OnboardingNavBar(
                        currentStep: 2,
                        totalSteps:  6,
                        onBack:      onBack
                    )
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.sm)
                    // Geometry-relative bottom — max() floor, not a token candidate
                    .padding(.bottom, max(8.0, h * 0.014))
                    .opacity(navVisible ? 1.0 : 0.0)

                    ViewThatFits(in: .vertical) {
                        VStack(spacing: 0) {
                            contentBlock(sectionSpacing: sectionSpacing, layout: layout)
                            Spacer(minLength: 0)
                            ctaBlock.padding(.horizontal, AppSpacing.lg)
                        }
                        VStack(spacing: 0) {
                            ScrollView(showsIndicators: false) {
                                contentBlock(sectionSpacing: sectionSpacing, layout: layout)
                            }
                            ctaBlock.padding(.horizontal, AppSpacing.lg)
                        }
                    }
                }
                .frame(width: layout.screenWidth, height: layout.screenHeight)
            }
            .frame(width: layout.screenWidth, height: layout.screenHeight)
            .onAppear {
                guard !hasAnimated else {
                    titleVisible = true
                    cardsVisible = true
                    navVisible   = true
                    return
                }
                hasAnimated = true
                withAnimation(AppAnimation.enter.delay(0.15))   { titleVisible = true }
                withAnimation(AppAnimation.enter.delay(0.35))   { cardsVisible = true }
                withAnimation(AppAnimation.standard.delay(0.35)) { navVisible   = true }

                // Ambient breath loops — three tiles use different durations
                // intentionally so they never pulse in sync:
                //   solo:      4.0s (AppAnimation.ambientDrift)
                //   together:  5.0s (intentional above ambientDrift — documented)
                //   browse:    6.0s (intentional above ambientDrift — documented)
                // TODO: Add UIAccessibility.isReduceMotionEnabled guard before
                // each withAnimation call here to strip loops under reduce motion.
                breathTask = Task {
                    withAnimation(.easeInOut(duration: AppAnimation.ambientDrift)
                        .repeatForever(autoreverses: true)) {
                        soloBreath = 1.0
                    }
                    try? await Task.sleep(nanoseconds: 800_000_000)
                    guard !Task.isCancelled else { return }
                    // 5.0s — intentional above ambientDrift for per-card phase variance
                    withAnimation(.easeInOut(duration: 5.0)
                        .repeatForever(autoreverses: true)) {
                        togetherBreath = 1.0
                    }
                    try? await Task.sleep(nanoseconds: 800_000_000)
                    guard !Task.isCancelled else { return }
                    // 6.0s — intentional above ambientDrift for per-card phase variance
                    withAnimation(.easeInOut(duration: 6.0)
                        .repeatForever(autoreverses: true)) {
                        browseBreath = 1.0
                    }
                }
            }
            .onDisappear {
                breathTask?.cancel()
                breathTask     = nil
                hasAnimated    = false
                soloBreath     = 0
                togetherBreath = 0
                browseBreath   = 0
            }
        }
    }

    // MARK: - Content Block

    private func contentBlock(
        sectionSpacing: CGFloat,
        layout:         AppLayout
    ) -> some View {
        let h = layout.screenHeight
        let tileH: CGFloat = max(130, h * 0.195)

        return VStack(alignment: .leading, spacing: sectionSpacing) {

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("How are you")
                        .font(AppFonts.heroTitle)
                        .foregroundStyle(isLight
                            ? AppColors.textPrimary
                            : AppColors.textPrimary)
                    LivingText(text: "exploring?", font: AppFonts.heroTitle)
                }
                Text(data.displayName.trimmingCharacters(
                         in: .whitespaces).isEmpty
                    ? "There's no wrong way to start."
                    : "There's no wrong answer, \(data.displayName.trimmingCharacters(in: .whitespaces))."
                )
                .font(AppFonts.caption)
                .foregroundStyle(isLight
                    ? AppColors.textSecondary
                    : AppColors.textSecondary)
            }
            .opacity(titleVisible ? 1 : 0)
            .offset(y: titleVisible ? 0 : 12)

            VStack(spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.sm) {
                    bentoCentered(mode: .solo,     tileH: tileH)
                    bentoCentered(mode: .together, tileH: tileH)
                }
                bentoBar(mode: .browsing)
            }
            .opacity(cardsVisible ? 1 : 0)
            .offset(y: cardsVisible ? 0 : 16)

            if let mode = data.appMode {
                let teaserText: String = {
                    switch mode {
                    case .solo:     return "Starts with what you actually want."
                    case .together: return "Starts with the conversation you've been circling."
                    case .browsing: return "No commitment. Just curiosity."
                    }
                }()

                let operationalContext: String? = {
                    switch mode {
                    case .solo:     return "You can connect with a partner later."
                    case .together: return "Pairing happens after you both set up."
                    case .browsing: return nil
                    }
                }()

                LivingText(
                    text: teaserText,
                    font: AppFonts.body(17, weight: .semibold, relativeTo: .body)
                )
                .id(mode)
                .transition(.opacity)
                .frame(maxWidth: .infinity)

                if let context = operationalContext {
                    Text(context)
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight
                            ? AppColors.textSecondary
                            : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                }
            }

            let expVisible = data.appMode != nil && data.appMode != .browsing

            if expVisible {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack {
                        Text("Your experience")
                            .font(AppFonts.caption)
                            .foregroundStyle(isLight
                                ? AppColors.textSecondary
                                : AppColors.textSecondary)
                        Spacer()
                        Text("No judgment")
                            .font(AppFonts.overline)
                            .foregroundStyle(isLight
                                ? AppColors.textTertiary
                                : AppColors.textTertiary)
                    }

                    HStack(spacing: AppSpacing.sm) {
                        SelectablePill(
                            label:      "Curious",
                            isSelected: data.nmStage == .curious,
                            intensity:  .dim,
                            height:     44,
                            fontSize:   15
                        ) {
                            data.nmStage = .curious
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        SelectablePill(
                            label:      "Exploring",
                            isSelected: data.nmStage == .exploring,
                            intensity:  .warm,
                            height:     44,
                            fontSize:   15
                        ) {
                            data.nmStage = .exploring
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        SelectablePill(
                            label:      "Experienced",
                            isSelected: data.nmStage == .experienced,
                            intensity:  .alive,
                            height:     44,
                            fontSize:   15
                        ) {
                            data.nmStage = .experienced
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Group {
                        if let descriptor = experienceDescriptor {
                            Text(descriptor)
                                .font(AppFonts.caption)
                                .foregroundStyle(isLight
                                    ? AppColors.textSecondary
                                    : AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                                .id(data.nmStage)
                                .accessibilityAddTraits(.updatesFrequently)
                        } else {
                            Color.clear.frame(height: 18)
                        }
                    }
                    .animation(AppAnimation.fast, value: data.nmStage?.rawValue ?? "")

                    Text("You can always change these later.")
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight
                            ? AppColors.textTertiary
                            : AppColors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .transition(.opacity.combined(with: .offset(y: 8)))
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, sectionSpacing)
        .animation(AppAnimation.spring, value: data.appMode?.rawValue ?? "none")
    }

    // MARK: - CTA Block

    private var ctaBlock: some View {
        VStack(spacing: 0) {
            HoloCTAButton(title: "Next", isEnabled: selectionMade) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onContinue()
            }
            OnboardingFooter(text: "Your data is encrypted and always stays yours.")
        }
    }

    // MARK: - Bento Centered Tile

    @ViewBuilder
    private func bentoCentered(
        mode:  AppMode,
        tileH: CGFloat
    ) -> some View {
        let isSelected    = data.appMode == mode
        let somethingElse = data.appMode != nil && !isSelected
        let filamentSize: CGFloat = min(tileH * 0.52, 88)

        let tileColor: Color = {
            switch mode {
            case .solo:     return AppColors.accentPrimary
            case .together: return AppColors.accentTertiary
            case .browsing: return AppColors.accentSecondary
            }
        }()

        let breathValue: CGFloat = {
            switch mode {
            case .solo:     return soloBreath
            case .together: return togetherBreath
            case .browsing: return browseBreath
            }
        }()

        let glowOpacity: Double = isSelected
            ? 0.18 + Double(breathValue) * 0.10
            : 0.06 + Double(breathValue) * 0.04

        let headline: String = {
            switch mode {
            case .solo:     return "Solo Discovery"
            case .together: return "Shared Journey"
            case .browsing: return ""
            }
        }()

        let subtitle: String = {
            switch mode {
            case .solo:     return "I want clarity\nfor myself first."
            case .together: return "Starting the conversation\ntogether."
            case .browsing: return ""
            }
        }()

        Button {
            handleSelection(mode)
        } label: {
            VStack(spacing: AppSpacing.sm) {
                Spacer(minLength: 0)

                TileOrbitView(
                    orbitCount: mode == .solo ? 1 : 2,
                    isActive:   true,
                    speed:      isSelected ? 1.0 : 0.28,
                    size:       filamentSize
                )
                .frame(width: filamentSize, height: filamentSize)
                .opacity(isSelected ? 1.0 : 0.35)
                .animation(AppAnimation.enter, value: isSelected)

                Text(headline)
                    .font(AppFonts.display(17, weight: .semibold, relativeTo: .body))
                    .foregroundStyle(isLight
                        ? AppColors.textPrimary
                        : AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(AppFonts.caption)
                    .foregroundStyle(isLight
                        ? AppColors.textSecondary
                        : AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.md)
            .frame(maxWidth: .infinity)
            .frame(height: tileH)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.xl)
                        .fill(isLight
                            ? (isSelected ? AppColors.glassFrostCard : AppColors.glassFrostPill)
                            : AppColors.cardBackground)

                    if !isLight {
                        RoundedRectangle(cornerRadius: AppRadius.xl)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        tileColor.opacity(glowOpacity),
                                        tileColor.opacity(glowOpacity * 0.3),
                                        Color.clear,
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: tileH * 0.6
                                )
                            )
                            .blur(radius: 20)
                            .allowsHitTesting(false)
                    }
                }
            )
            .overlay(
                ZStack {
                    selectedBorder(isSelected: isSelected, cornerRadius: AppRadius.xl)

                    if isSelected && !isLight {
                        HStack {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.clear,
                                            tileColor.opacity(0.7),
                                            Color.clear,
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 2)
                                .padding(.vertical, AppSpacing.md)
                            Spacer()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
                        .allowsHitTesting(false)
                    }
                }
            )
            .shadow(
                color: isSelected
                    ? (isLight
                        ? AppColors.shadowMagenta
                        : AppColors.accentSecondary.opacity(0.28))
                    : .clear,
                radius: 8
            )
            .shadow(
                color: isSelected
                    ? (isLight
                        // TODO: verify token — original was AppColors.shadowPurple
                        ? AppColors.shadowPurple
                        : AppColors.accentPrimary.opacity(0.18))
                    : .clear,
                radius: 16
            )
            .shadow(
                color: isSelected
                    ? AppColors.accentTertiary.opacity(isLight ? 0.06 : 0.10)
                    : .clear,
                radius: 28
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : (somethingElse ? 0.965 : 1.0))
        .opacity(somethingElse ? 0.55 : 1.0)
        // Intentional lower damping (0.7 vs AppAnimation.spring 0.85) —
        // produces bouncier tile selection feel. Documented exception.
        .animation(
            AppAnimation.spring,
            value: data.appMode?.rawValue ?? "none"
        )
        .accessibilityLabel(headline)
        .accessibilityHint(isSelected ? "Selected" : "Double-tap to select \(headline)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Bento Bar

    @ViewBuilder
    private func bentoBar(mode: AppMode) -> some View {
        let isSelected    = data.appMode == mode
        let somethingElse = data.appMode != nil && !isSelected
        let filamentSize: CGFloat = 56

        let glowOpacity: Double = isSelected
            ? 0.18 + Double(browseBreath) * 0.08
            : 0.05 + Double(browseBreath) * 0.03

        Button {
            handleSelection(mode)
        } label: {
            HStack(spacing: AppSpacing.md) {
                TileOrbitView(
                    orbitCount: 3,
                    isActive:   true,
                    speed:      isSelected ? 1.0 : 0.22,
                    size:       filamentSize
                )
                .frame(width: filamentSize, height: filamentSize)
                .opacity(isSelected ? 1.0 : 0.30)
                .animation(AppAnimation.enter, value: isSelected)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Safe Learning")
                        .font(AppFonts.display(17, weight: .semibold, relativeTo: .body))
                        .foregroundStyle(isLight
                            ? AppColors.textPrimary
                            : AppColors.textPrimary)
                    Text("Just looking around for now.")
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight
                            ? AppColors.textSecondary
                            : AppColors.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.md)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.xl)
                        .fill(isLight
                            ? (isSelected ? AppColors.glassFrostCard : AppColors.glassFrostPill)
                            : AppColors.cardBackground)

                    if !isLight {
                        RoundedRectangle(cornerRadius: AppRadius.xl)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        AppColors.safetyAccent.opacity(glowOpacity),
                                        AppColors.safetyAccent.opacity(glowOpacity * 0.25),
                                        Color.clear,
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .blur(radius: 16)
                            .allowsHitTesting(false)
                    }
                }
            )
            .overlay(selectedBorder(isSelected: isSelected, cornerRadius: AppRadius.xl))
            .shadow(
                color: isSelected
                    ? AppColors.safetyAccent.opacity(isLight ? 0.20 : 0.28)
                    : .clear,
                radius: 8
            )
            .shadow(
                color: isSelected
                    ? AppColors.safetyAccent.opacity(isLight ? 0.12 : 0.18)
                    : .clear,
                radius: 16
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : (somethingElse ? 0.97 : 1.0))
        .opacity(somethingElse ? 0.55 : 1.0)
        // Intentional lower damping (0.7 vs AppAnimation.spring 0.85) —
        // matches bentoCentered tile selection feel.
        .animation(
            AppAnimation.spring,
            value: data.appMode?.rawValue ?? "none"
        )
        .accessibilityLabel("Safe Learning")
        .accessibilityHint(isSelected ? "Selected" : "Double-tap to select Safe Learning")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Previews

#Preview("Dark — no selection") {
    @Previewable @State var data = OnboardingData()
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Dark — Solo selected") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.appMode = .solo
        d.nmStage = .curious
        return d
    }()
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Dark — Together selected") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.appMode = .together
        return d
    }()
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Dark — Browsing selected") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.appMode = .browsing
        return d
    }()
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — no selection") {
    @Previewable @State var data = OnboardingData()
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.light)
}

#Preview("Light — Together selected") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.appMode = .together
        d.nmStage = .exploring
        return d
    }()
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
}
