import SwiftUI

// MARK: - Main View

struct OnboardingModeSelectView: View {
    @Binding var data: OnboardingData
    var onContinue: () -> Void
    var onBack: (() -> Void)?

    @State private var titleVisible  = false
    @State private var navVisible    = false
    @State private var cardsVisible  = false
    @State private var hasAnimated   = false

    // Breathing atmosphere — one phase per tile, offset so they never sync
    @State private var soloBreath:    CGFloat = 0
    @State private var coupleBreath:  CGFloat = 0
    @State private var browseBreath:  CGFloat = 0
    @State private var breathTask: Task<Void, Never>? = nil

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    private var selectionMade: Bool {
        guard let mode = data.explorationMode else {
            return false
        }
        if mode == .browsing { return true }
        return data.nmStage != nil
    }

    // COPYWRITING REVIEW: S5-E2
    // Current descriptors read as a progression (rungs on a ladder) rather than
    // three equally valid positions. "New to this" → "dipped my toes in" → "part of my life"
    // inadvertently implies a hierarchy. Consider reframing as parallel states:
    // "Still figuring out if this is for me." / "I've had experiences. Learning as I go." /
    // "I know this territory. Here to go deeper." This removes hierarchical language while
    // maintaining clarity. Also note: "No judgment" can paradoxically highlight judgment concerns.
    private var experienceDescriptor: String? {
        switch data.nmStage {
        case .curious:    return "New to this — maybe I've read about it or know people who do it."
        case .exploring:  return "I've dipped my toes in. A few real experiences."
        case .experienced:return "This has been part of my life for a while."
        case .none:       return nil
        }
    }

    private var atmosphereColors: (primary: Color, secondary: Color) {
        switch data.explorationMode {
        case .solo:     return (AppColors.cyan,    AppColors.deepBlue)
        case .couple:   return (AppColors.magenta, AppColors.purple)
        case .browsing: return (AppColors.gold,    AppColors.orangeHot)
        case .none:     return (AppColors.purple,  AppColors.deepBlue)
        }
    }

    private func handleSelection(_ mode: ExplorationMode) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            if data.explorationMode == mode {
                data.explorationMode = nil
                data.nmStage = nil
            } else {
                if data.explorationMode != nil {
                    data.nmStage = nil
                }
                data.explorationMode = mode
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
                    .strokeBorder(
                        isLight ? AppColors.warmAuroraBorder : AppColors.spectrumBorder,
                        lineWidth: 2
                    )
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        isLight ? AppColors.warmAuroraBorder : AppColors.spectrumBorder,
                        lineWidth: 3
                    )
                    .blur(radius: 4)
                    .opacity(0.25)
            }
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    isLight ? AppColors.lightBorder : AppColors.border,
                    lineWidth: 1.5
                )
        }
    }

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width

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
                        .animation(
                            .easeOut(duration: 0.45),
                            value: data.explorationMode?.rawValue ?? "none"
                        )
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }

                VStack(spacing: 0) {
                    OnboardingNavBar(
                        currentStep: 2,
                        totalSteps:  6,
                        onBack:      onBack
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, max(8.0, h * 0.014))
                    .opacity(navVisible ? 1.0 : 0.0)

                    ViewThatFits(in: .vertical) {
                        VStack(spacing: 0) {
                            contentBlock(sectionSpacing: sectionSpacing, geo: geo)
                            Spacer(minLength: 0)
                            ctaBlock.padding(.horizontal, 24)
                        }
                        VStack(spacing: 0) {
                            ScrollView(showsIndicators: false) {
                                contentBlock(sectionSpacing: sectionSpacing, geo: geo)
                            }
                            ctaBlock.padding(.horizontal, 24)
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
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
                withAnimation(.easeOut(duration: 0.3).delay(0.35)) { navVisible   = true }

                breathTask = Task {
                    // Solo — immediate
                    withAnimation(.easeInOut(duration: 4.0)
                        .repeatForever(autoreverses: true)) {
                        soloBreath = 1.0
                    }
                    // Couple — 0.8s delay
                    try? await Task.sleep(nanoseconds: 800_000_000)
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 5.0)
                        .repeatForever(autoreverses: true)) {
                        coupleBreath = 1.0
                    }
                    // Browsing — additional 0.8s
                    try? await Task.sleep(nanoseconds: 800_000_000)
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 6.0)
                        .repeatForever(autoreverses: true)) {
                        browseBreath = 1.0
                    }
                }
            }
            .onDisappear {
                breathTask?.cancel()
                breathTask = nil
                hasAnimated  = false
                soloBreath   = 0
                coupleBreath = 0
                browseBreath = 0
            }
        }
    }

    // MARK: - Content Block

    private func contentBlock(
        sectionSpacing: CGFloat,
        geo:            GeometryProxy
    ) -> some View {
        let h = geo.size.height
        let tileH: CGFloat = max(130, h * 0.195)
        
        return VStack(alignment: .leading, spacing: sectionSpacing) {
            
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("How are you")
                        .font(AppFonts.heroTitle)
                        .foregroundStyle(isLight
                                         ? AppColors.lightTextPrimary
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
                                 ? AppColors.lightTextSecondary
                                 : AppColors.textSecondary)
            }
            .opacity(titleVisible ? 1 : 0)
            .offset(y: titleVisible ? 0 : 12)
            
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    bentoCentered(mode: .solo,   tileH: tileH)
                    bentoCentered(mode: .couple, tileH: tileH)
                }
                bentoBar(mode: .browsing)
            }
            .opacity(cardsVisible ? 1 : 0)
            .offset(y: cardsVisible ? 0 : 16)
            
            if let mode = data.explorationMode {
                let teaserText: String = {
                    switch mode {
                    case .solo:     return "Starts with what you actually want."
                    case .couple:   return "Starts with the conversation you've been circling."
                    case .browsing: return "No commitment. Just curiosity."
                    }
                }()
                
                let operationalContext: String? = {
                    switch mode {
                    case .solo:     return "You can connect with a partner later."
                    case .couple:   return "Pairing happens after you both set up."
                    case .browsing: return nil
                    }
                }()
                
                LivingText(
                    text: teaserText,
                    font: AppFonts.body(17, weight: .semibold)
                )
                .id(mode)
                .transition(.opacity)
                .frame(maxWidth: .infinity)
                
                if let context = operationalContext {
                    Text(context)
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight
                                         ? AppColors.lightTextSecondary
                                         : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                }
            }
            
            let expVisible = data.explorationMode != nil
                && data.explorationMode != .browsing
            
            if expVisible {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Your experience")
                            .font(AppFonts.caption)
                            .foregroundStyle(isLight
                                             ? AppColors.lightTextSecondary
                                             : AppColors.textSecondary)
                        Spacer()
                        Text("No judgment")
                            .font(AppFonts.overline)
                            .foregroundStyle(isLight
                                             ? AppColors.lightTextTertiary
                                             : AppColors.textTertiary)
                    }
                    
                    HStack(spacing: 10) {
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
                                                 ? AppColors.lightTextSecondary
                                                 : AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                                .id(data.nmStage)
                                .accessibilityAddTraits(.updatesFrequently)
                        } else {
                            Color.clear.frame(height: 18)
                        }
                    }
                    .animation(.easeOut(duration: 0.25), value: data.nmStage?.rawValue ?? "")
                    
                    Text("You can always change these later.")
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight
                                         ? AppColors.lightTextTertiary
                                         : AppColors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .transition(.opacity.combined(with: .offset(y: 8)))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, sectionSpacing)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: data.explorationMode?.rawValue ?? "none")
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
        mode:  ExplorationMode,
        tileH: CGFloat
    ) -> some View {
        let isSelected    = data.explorationMode == mode
        let somethingElse = data.explorationMode != nil && !isSelected
        let filamentSize: CGFloat = min(tileH * 0.52, 88)

        // Per-tile color and breath values
        let tileColor: Color = {
            switch mode {
            case .solo:   return AppColors.cyan
            case .couple: return AppColors.magenta
            default:      return AppColors.purple
            }
        }()

        let breathValue: CGFloat = {
            switch mode {
            case .solo:   return soloBreath
            case .couple: return coupleBreath
            case .browsing: return browseBreath
            }
        }()

        // Glow opacity: low at rest, amplified on selection
        let glowOpacity: Double = isSelected
            ? 0.18 + Double(breathValue) * 0.10
            : 0.06 + Double(breathValue) * 0.04

        let headline: String = {
            switch mode {
            case .solo:   return "Solo Discovery"
            case .couple: return "Shared Journey"
            default:      return ""
            }
        }()

        let subtitle: String = {
            switch mode {
            case .solo:   return "I want clarity\nfor myself first."
            case .couple: return "Starting the conversation\ntogether."
            default:      return ""
            }
        }()

        Button {
            handleSelection(mode)
        } label: {
            VStack(spacing: 6) {
                Spacer(minLength: 0)

                // CHANGE: always active, speed idles at 0.28, accelerates on selection
                TileOrbitView(
                    orbitCount: mode == .solo ? 1 : 2,
                    isActive:   true,
                    speed:      isSelected ? 1.0 : 0.28,
                    size:       filamentSize
                )
                .frame(width: filamentSize, height: filamentSize)
                // CHANGE: always visible, dims when not selected
                .opacity(isSelected ? 1.0 : 0.35)
                .animation(.easeInOut(duration: 0.4), value: isSelected)

                Text(headline)
                    .font(AppFonts.display(17, weight: .semibold))
                    .foregroundStyle(isLight
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(AppFonts.caption)
                    .foregroundStyle(isLight
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .frame(height: tileH)
            .background(
                ZStack {
                    // Base fill — unchanged
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isLight
                            ? (isSelected ? AppColors.lightFrostCard : AppColors.lightFrostPill)
                            : AppColors.cardBg)

                    // CHANGE: breathing radial atmosphere — exists at rest, amplifies on selection
                    if !isLight {
                        RoundedRectangle(cornerRadius: 20)
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
                    selectedBorder(isSelected: isSelected, cornerRadius: 20)

                    // CHANGE: left-edge glow accent on selected tile
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
                                .padding(.vertical, 12)
                            Spacer()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .allowsHitTesting(false)
                    }
                }
            )
            .shadow(
                color: isSelected
                    ? (isLight
                        ? AppColors.lightShadowMagenta
                        : AppColors.purple.opacity(0.28))
                    : .clear,
                radius: 8
            )
            .shadow(
                color: isSelected
                    ? (isLight
                        ? AppColors.lightShadowPurple
                        : AppColors.cyan.opacity(0.18))
                    : .clear,
                radius: 16
            )
            .shadow(
                color: isSelected
                    ? AppColors.magenta.opacity(isLight ? 0.06 : 0.10)
                    : .clear,
                radius: 28
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : (somethingElse ? 0.965 : 1.0))
        .opacity(somethingElse ? 0.55 : 1.0)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.7),
            value: data.explorationMode?.rawValue ?? "none"
        )
        .accessibilityLabel(headline)
        .accessibilityHint(isSelected ? "Selected" : "Double-tap to select \(headline)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Bento Bar
    
    // COPYWRITING REVIEW: S5-E1
    // The "Safe Learning" label is aspirational but may not authentically represent
    // users who choose browsing to defer Solo/Couple selection (e.g., uncertain about
    // relationship status, not ready to answer honestly). Consider "Just Browsing" or
    // "Not Sure Yet" as alternatives. Update accessibilityLabel if changed.
    
    @ViewBuilder
    private func bentoBar(mode: ExplorationMode) -> some View {
        let isSelected    = data.explorationMode == mode
        let somethingElse = data.explorationMode != nil && !isSelected
        let filamentSize: CGFloat = 56

        let glowOpacity: Double = isSelected
            ? 0.18 + Double(browseBreath) * 0.08
            : 0.05 + Double(browseBreath) * 0.03

        Button {
            handleSelection(mode)
        } label: {
            HStack(spacing: 14) {
                // CHANGE: always active at idle speed
                TileOrbitView(
                    orbitCount: 3,
                    isActive:   true,
                    speed:      isSelected ? 1.0 : 0.22,
                    size:       filamentSize
                )
                .frame(width: filamentSize, height: filamentSize)
                // CHANGE: always visible, dims when not selected
                .opacity(isSelected ? 1.0 : 0.30)
                .animation(.easeInOut(duration: 0.4), value: isSelected)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Safe Learning")
                        .font(AppFonts.display(17, weight: .semibold))
                        .foregroundStyle(isLight
                            ? AppColors.lightTextPrimary
                            : AppColors.textPrimary)
                    Text("Just looking around for now.")
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight
                            ? AppColors.lightTextSecondary
                            : AppColors.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isLight
                            ? (isSelected ? AppColors.lightFrostCard : AppColors.lightFrostPill)
                            : AppColors.cardBg)

                    // CHANGE: breathing gold atmosphere on browsing bar
                    if !isLight {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        AppColors.gold.opacity(glowOpacity),
                                        AppColors.gold.opacity(glowOpacity * 0.25),
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
            .overlay(selectedBorder(isSelected: isSelected, cornerRadius: 20))
            .shadow(
                color: isSelected
                    ? AppColors.gold.opacity(isLight ? 0.20 : 0.28)
                    : .clear,
                radius: 8
            )
            .shadow(
                color: isSelected
                    ? AppColors.gold.opacity(isLight ? 0.12 : 0.18)
                    : .clear,
                radius: 16
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : (somethingElse ? 0.97 : 1.0))
        .opacity(somethingElse ? 0.55 : 1.0)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.7),
            value: data.explorationMode?.rawValue ?? "none"
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
        AppColors.pageBg.ignoresSafeArea()
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
        d.explorationMode = .solo
        d.nmStage         = .curious
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
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

#Preview("Dark — Couple selected") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.explorationMode = .couple
        d.nmStage         = .exploring
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
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
        d.explorationMode = .browsing
        d.nmStage         = .curious
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
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
        AppColors.lightPageBg.ignoresSafeArea()
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

#Preview("Light — Couple selected") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.explorationMode = .couple
        d.nmStage         = .exploring
        return d
    }()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    
}
