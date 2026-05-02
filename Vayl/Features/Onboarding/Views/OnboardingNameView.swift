

// OnboardingNameView.swift
// Open Lightly
//
// Screen 1: Name + Pronouns

import SwiftUI

// MARK: - Main View

struct OnboardingNameView: View {
    @Binding var data: OnboardingData
    var onContinue: (() -> Void)?
    var onBack:     (() -> Void)?

    // Form state
    @State private var displayName:       String         = ""
    @State private var selectedGender:    String? = nil
    @State private var customGenderText:  String = ""
    @State private var showCustomGenderField: Bool = false
    @FocusState private var nameFieldFocused: Bool

    // Atmosphere
    @State private var hasAnimated: Bool      = false

    // Entrance
    @State private var headerVisible = false
    @State private var cardVisible   = false
    @State private var ctaVisible    = false

    // Greeting response
    @State private var greetingVisible = false
    @State private var greetingOwnsName: Bool = false
    @State private var nameTextOpacity: Double = 1.0
    @State private var fieldCollapsed: Bool = false
    @State private var typingDebounce: DispatchWorkItem? = nil
    @State private var focusTask: Task<Void, Never>? = nil

    // Gender section
    @State private var genderSectionVisible = false

    // Validation Bloom
    @State private var isButtonGlowing: Bool = false

    // Pulse Animation
    @State private var glowPulse: Bool = false

    // Environment
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Surface tokens

    private var kFieldBG: Color {
        colorScheme == .light
            ? AppColors.modalBackground
            : Color.white.opacity(0.07)
    }

    private var kGlassBorder: Color {
        colorScheme == .light
            ? AppColors.borderSubtle
            : Color.white.opacity(0.09)
    }

    private var kFieldBorderActive: some ShapeStyle {
        if colorScheme == .light {
            return AnyShapeStyle(AppColors.spectrumBorder)
        } else {
            return AnyShapeStyle(AppColors.spectrumBorder)
        }
    }

    private var kFloatingLabelFocused: Color {
        colorScheme == .light
            ? AppColors.accentSecondary
            : AppColors.accentSecondary
    }

    private var kFloatingLabelUnfocused: Color {
        colorScheme == .light
            ? AppColors.textPrimary.opacity(0.40)
            : AppColors.textTertiary
    }

    private var kTextPrimary: Color {
        colorScheme == .light
            ? AppColors.textPrimary
            : .white
    }

    private var kPronounLabel: Color {
        colorScheme == .light
            ? AppColors.textPrimary.opacity(0.65)
            : .white.opacity(0.75)
    }

    private var kPronounHint: Color {
        colorScheme == .light
            ? AppColors.textHint
            : AppColors.textTertiary
    }

    private var kCustomPillFill: Color {
        colorScheme == .light
            ? AppColors.glassFrostPill
            : AppColors.modalBackground
    }

    private var kCustomPillBorder: Color {
        colorScheme == .light
            ? AppColors.borderSubtle
            : AppColors.borderDefault
    }

    private var isValid: Bool {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 1 && trimmed.count <= 30
              else { return false }
        guard let gender = selectedGender else { return false }
        if gender == "Something else" {
            return !customGenderText
                .trimmingCharacters(in: .whitespaces)
                .isEmpty
        }
        return true
    }

    // MARK: - Name Field

    @ViewBuilder
    private var nameField: some View {
        ZStack(alignment: .leading) {

            // Floating label
            Text("What should we call you?")
                .font(displayName.isEmpty && !nameFieldFocused
                      ? AppFonts.display(22, weight: .semibold, relativeTo: .title2)
                      : AppFonts.overline)
                .foregroundStyle(
                    displayName.isEmpty && !nameFieldFocused
                        ? (colorScheme == .light
                            ? AnyShapeStyle(AppColors.textSecondary)
                            : AnyShapeStyle(AppColors.textSecondary))
                        : (colorScheme == .light
                            ? AnyShapeStyle(AppColors.accentSecondary)
                            : AnyShapeStyle(AppColors.accentSecondary))
                )
                .offset(y: displayName.isEmpty && !nameFieldFocused ? 0 : -36)
                .animation(AppAnimation.standard, value: nameFieldFocused)
                .animation(AppAnimation.standard, value: displayName.isEmpty)
                .opacity(fieldCollapsed ? 0 : 1)
                .animation(AppAnimation.fast.delay(0.05), value: fieldCollapsed)
                .accessibilityHidden(true)

            TextField("", text: $displayName)
                .font(AppFonts.display(28, weight: .semibold, relativeTo: .title))
                .foregroundColor(
                    (colorScheme == .light
                        ? AppColors.textPrimary
                        : AppColors.textPrimary)
                    .opacity(nameTextOpacity)
                )
                .tint(colorScheme == .light
                    ? AppColors.accentSecondary
                    : AppColors.accentPrimary)
                .offset(y: 10)
                .focused($nameFieldFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit {
                    nameFieldFocused = false
                    triggerCollapse()
                }
                .opacity(fieldCollapsed ? 0 : 1)
                .animation(AppAnimation.standard, value: fieldCollapsed)
                .disabled(fieldCollapsed)
                .onChange(of: displayName) { _, newValue in
                    let trimmed = newValue
                        .trimmingCharacters(in: .whitespaces)
                    if trimmed.count > 30 {
                        displayName = String(trimmed.prefix(30))
                    }

                    let hasContent = !trimmed
                        .isEmpty

                    withAnimation(AppAnimation.spring) {
                        genderSectionVisible = hasContent
                    }

                    typingDebounce?.cancel()

                    guard !trimmed.isEmpty else {
                        withAnimation(AppAnimation.fast) {
                            greetingVisible = false
                            greetingOwnsName = false
                        }
                        withAnimation(AppAnimation.standard.delay(0.15)) {
                            fieldCollapsed = false
                            nameTextOpacity = 1.0
                        }
                        return
                    }

                    let work = DispatchWorkItem {
                        triggerCollapse()
                    }
                    typingDebounce = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
                }
                .onChange(of: nameFieldFocused) { _, isFocused in
                    if isFocused && greetingOwnsName {
                        withAnimation(AppAnimation.fast) {
                            greetingVisible = false
                            greetingOwnsName = false
                        }
                        withAnimation(AppAnimation.standard.delay(0.15)) {
                            fieldCollapsed = false
                            nameTextOpacity = 1.0
                        }
                    }
                }
                .accessibilityLabel("What should we call you?")
        }
        .frame(height: 72)
        .padding(.bottom, AppSpacing.xs)
        .overlay(alignment: .bottom) {
            ZStack {
                // Base line — always visible
                Rectangle()
                    .fill(
                        nameFieldFocused || !displayName.isEmpty
                            ? (colorScheme == .light
                                ? AnyShapeStyle(AppColors.spectrumBorder)
                                : AnyShapeStyle(AppColors.spectrumBorder))
                            : (colorScheme == .light
                                ? AnyShapeStyle(AppColors.borderSubtle)
                                : AnyShapeStyle(AppColors.borderSubtle))
                    )
                    .frame(height: nameFieldFocused ? 3 : 2)
                    .animation(AppAnimation.standard, value: nameFieldFocused)

                // Gradient glow line — appears when focused or has content
                if nameFieldFocused || !displayName.isEmpty {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .light
                                    ? [
                                        AppColors.accentTertiary.opacity(0.6),
                                        AppColors.accentTertiary.opacity(0.9),
                                        AppColors.accentSecondary.opacity(0.7),
                                        AppColors.accentTertiary.opacity(0.6)
                                      ]
                                    : [
                                        AppColors.accentPrimary.opacity(0.6),
                                        AppColors.accentSecondary.opacity(0.9),
                                        AppColors.accentTertiary.opacity(0.8),
                                        AppColors.accentPrimary.opacity(0.6)
                                      ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 3)
                        .blur(radius: 4)
                        .opacity(nameFieldFocused ? 1.0 : 0.5)
                        .animation(AppAnimation.standard, value: nameFieldFocused)

                    // Outer soft glow
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .light
                                    ? [
                                        AppColors.accentTertiary.opacity(0.2),
                                        AppColors.accentTertiary.opacity(0.35),
                                        AppColors.accentSecondary.opacity(0.25),
                                        AppColors.accentTertiary.opacity(0.2)
                                      ]
                                    : [
                                        AppColors.accentPrimary.opacity(0.2),
                                        AppColors.accentSecondary.opacity(0.35),
                                        AppColors.accentTertiary.opacity(0.3),
                                        AppColors.accentPrimary.opacity(0.2)
                                      ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 8)
                        .blur(radius: 6)
                        .opacity(nameFieldFocused ? 0.9 : 0.4)
                        .animation(AppAnimation.standard, value: nameFieldFocused)
                }
            }
            .opacity(fieldCollapsed ? 0 : 1)
            .animation(AppAnimation.standard, value: fieldCollapsed)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let layout = AppLayout.from(geo)
            let h = layout.screenHeight

            ZStack {
                // ── Background ───────────────────────────────────────────
                Color.clear.ignoresSafeArea()

                // ── Atmosphere ellipse ────────────────────────────────────
                if colorScheme == .dark {
                    Ellipse()
                        .fill(RadialGradient(stops: [
                            .init(color: Color.purple.opacity(0.22), location: 0),
                            .init(color: Color.blue.opacity(0.12),   location: 0.5),
                            .init(color: .clear,                     location: 1)
                        ], center: .center, startRadius: 0, endRadius: 240))
                        .frame(width: layout.screenWidth, height: h * 0.31)
                        .blur(radius: 80)
                        .offset(y: h * 0.30)
                        .allowsHitTesting(false)
                }

                // ── Content ───────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 0) {

                    OnboardingNavBar(currentStep: 1, totalSteps: 6, onBack: onBack)
                        .padding(.top, layout.safeAreaInsets.top > 50 ? 8 : 20)
                        .padding(.bottom, AppSpacing.xl)

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Let's get")
                            .font(AppFonts.display(28, weight: .semibold, relativeTo: .title))
                            .foregroundColor(kTextPrimary)
                        LivingText(text: "acquainted.")
                    }
                    .opacity(headerVisible ? 1 : 0)
                    .scaleEffect(headerVisible ? 1.0 : 0.95)
                    .padding(.bottom, AppSpacing.xl)

                    // ── Name field ────────────────────────────────────────
                    nameField
                        .padding(.bottom, AppSpacing.lg)
                        .opacity(cardVisible ? 1 : 0)
                        .scaleEffect(cardVisible ? 1.0 : 0.95)

                    // ── Greeting ──────────────────────────────────────────
                    // FIX: corrected brace structure
                    HStack(alignment: .firstTextBaseline, spacing: 7.5) { // intentional optical alignment — not a spacing token candidate
                        Spacer()

                        Text("Hi ")
                            .font(AppFonts.display(32, weight: .bold, relativeTo: .title))
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.textPrimary
                                : AppColors.textPrimary.opacity(0.94))

                        Text(displayName.trimmingCharacters(in: .whitespaces))
                            .font(AppFonts.display(32, weight: .bold, relativeTo: .title))
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.textPrimary
                                : AppColors.textPrimary)
                            .modifier(GlowUnderline(isLight: colorScheme == .light))

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(greetingVisible ? 1 : 0)
                    .offset(y: greetingVisible ? -65 : 16)
                    .animation(
                        .spring(response: 1.1, dampingFraction: 0.88),
                        value: greetingVisible
                    )
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.xl)
                    .onTapGesture {
                        withAnimation(AppAnimation.fast) {
                            greetingVisible = false
                            greetingOwnsName = false
                        }
                        withAnimation(AppAnimation.standard.delay(0.15)) {
                            fieldCollapsed = false
                            nameTextOpacity = 1.0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            nameFieldFocused = true
                        }
                    }
                    .accessibilityLabel("Edit name")
                    .accessibilityHint("Tap to change what we call you")
                    .accessibilityAddTraits(.isButton)

                    Text("tap to edit")
                        .font(AppFonts.caption)
                        .foregroundColor(colorScheme == .light
                            ? AppColors.textTertiary
                            : AppColors.textTertiary)
                        .padding(.top, AppSpacing.xs)
                        .opacity(greetingVisible ? 0.7 : 0)
                        .animation(AppAnimation.standard, value: greetingVisible)

                    Rectangle()
                        .fill(colorScheme == .light
                              ? AppColors.borderSubtle
                              : Color.white.opacity(0.05))
                        .frame(height: 1)
                        .padding(.bottom, AppSpacing.lg)
                        .opacity(cardVisible && !fieldCollapsed ? 1 : 0)
                        .scaleEffect(cardVisible ? 1.0 : 0.95)
                        .animation(AppAnimation.standard, value: fieldCollapsed)
                        .animation(
                            AppAnimation.spring.delay(0.23),
                            value: cardVisible
                        )

                    genderSection
                        .opacity(cardVisible && genderSectionVisible ? 1 : 0)
                        .scaleEffect(cardVisible && genderSectionVisible ? 1.0 : 0.95)

                    Spacer(minLength: OL.spacerMin(h))

                    // ── CTA ───────────────────────────────────────────────
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .fill(LinearGradient(
                                colors: [
                                    AppColors.accentTertiary.opacity(0.30),
                                    AppColors.accentSecondary.opacity(0.25),
                                    AppColors.accentTertiary.opacity(0.20)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .blur(radius: 36)
                            .opacity(isButtonGlowing ? 1.0 : 0.0)
                            .animation(
                                reduceMotion ? .none : .easeInOut(duration: 0.6),
                                value: isButtonGlowing
                            )
                            .allowsHitTesting(false)

                        HoloCTAButton(
                            title: "Next",
                            isEnabled: isValid
                        ) {
                            triggerHaptic(.medium)
#if DEBUG
                            assert(onContinue != nil,
                                   "OnboardingNameView: onContinue not injected — " +
                                   "wire this callback from the coordinator.")
#endif
                            commitData()
                            onContinue?()
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(
                            color: isButtonGlowing
                                ? AppColors.accentTertiary.opacity(
                                    reduceMotion ? 0.30 : (glowPulse ? 0.40 : 0.20)
                                )
                                : .clear,
                            radius: isButtonGlowing
                                ? (reduceMotion ? 12 : (glowPulse ? 18 : 8))
                                : 0,
                            x: 0, y: 0
                        )
                    }
                    .opacity(ctaVisible ? 1 : 0)
                    .scaleEffect(ctaVisible ? 1.0 : 0.95)

                    OnboardingFooter()
                        .opacity(ctaVisible ? 1 : 0)
                        .scaleEffect(ctaVisible ? 1.0 : 0.95)
                }
                .padding(.horizontal, AppSpacing.xl)
            }
            .frame(width: layout.screenWidth, alignment: .topLeading)
            .onAppear {
                restoreStateIfNeeded()

                if isValid {
                    isButtonGlowing = true
                    if !reduceMotion {
                        withAnimation(
                            .easeInOut(duration: AppAnimation.ambientPulse) // ambient loop
                            .repeatForever(autoreverses: true)
                            .delay(0.6)
                        ) { glowPulse = true }
                    }
                }

                guard !hasAnimated else { return }
                hasAnimated = true

                let entranceSpring = AppAnimation.spring

                if reduceMotion {
                    withAnimation(AppAnimation.standard) {
                        headerVisible = true
                        cardVisible   = true
                        ctaVisible    = true
                    }
                } else {
                    withAnimation(entranceSpring.delay(0.08)) { headerVisible = true }
                    withAnimation(entranceSpring.delay(0.23)) { cardVisible = true }
                    withAnimation(entranceSpring.delay(0.38)) { ctaVisible = true }
                }

                if !reduceMotion {
                    focusTask = Task {
                        try? await Task.sleep(nanoseconds: 750_000_000)
                        guard !Task.isCancelled else { return }
                        await MainActor.run {
                            withAnimation(AppAnimation.fast) {
                                nameFieldFocused = true
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onDisappear {
                typingDebounce?.cancel()
                typingDebounce = nil
                focusTask?.cancel()
                focusTask = nil
                hasAnimated      = false
                headerVisible    = false
                cardVisible      = false
                ctaVisible       = false
                isButtonGlowing  = false
                glowPulse        = false
                greetingOwnsName = false
                nameTextOpacity  = 1.0
                fieldCollapsed   = false
            }
            .onChange(of: isValid) { _, newValue in
                if newValue {
                    triggerHaptic(.medium)
                    if reduceMotion {
                        isButtonGlowing = true
                    } else {
                        withAnimation(AppAnimation.slow) {
                            isButtonGlowing = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            withAnimation(
                                .easeInOut(duration: AppAnimation.ambientPulse) // ambient loop
                                .repeatForever(autoreverses: true)
                            ) { glowPulse = true }
                        }
                    }
                } else {
                    withAnimation(AppAnimation.enter) {
                        isButtonGlowing = false
                    }
                    glowPulse = false
                }
            }
        }
    }

    // MARK: - Gender Section

    private var genderSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Gender identity")
                .font(AppFonts.body(13, weight: .medium, relativeTo: .caption))
                .foregroundColor(kPronounLabel)
            
            Text("Helps us personalise your prompts and tone")
                .font(AppFonts.caption)
                .foregroundColor(kPronounHint)
                .padding(.top, AppSpacing.xxs)
                .padding(.bottom, AppSpacing.sm)

            VStack(spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.sm) {
                    SelectablePill(
                        label: "Man",
                        isSelected: selectedGender == "Man",
                        showFlame: false
                    ) {
                        nameFieldFocused = false
                        withAnimation(AppAnimation.fast) {
                            selectedGender = selectedGender == "Man" ? nil : "Man"
                            showCustomGenderField = false
                            customGenderText = ""
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    SelectablePill(
                        label: "Woman",
                        isSelected: selectedGender == "Woman",
                        showFlame: false
                    ) {
                        nameFieldFocused = false
                        withAnimation(AppAnimation.fast) {
                            selectedGender = selectedGender == "Woman" ? nil : "Woman"
                            showCustomGenderField = false
                            customGenderText = ""
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                HStack(spacing: AppSpacing.sm) {
                    SelectablePill(
                        label: "Non-binary",
                        isSelected: selectedGender == "Non-binary",
                        showFlame: false
                    ) {
                        nameFieldFocused = false
                        withAnimation(AppAnimation.fast) {
                            selectedGender = selectedGender == "Non-binary" ? nil : "Non-binary"
                            showCustomGenderField = false
                            customGenderText = ""
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    SelectablePill(
                        label: "Something else",
                        isSelected: selectedGender == "Something else",
                        showFlame: false
                    ) {
                        nameFieldFocused = false
                        withAnimation(AppAnimation.fast) {
                            selectedGender = selectedGender == "Something else"
                                ? nil : "Something else"
                            showCustomGenderField = selectedGender == "Something else"
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }

                // Full-width and visually prominent by design.
                // Shame reduction architecture: the option to decline
                // should never feel hidden or harder to find than
                // providing the data. See PROJECT_SCOPE Section 6.
                SelectablePill(
                    label: "Prefer not to say",
                    isSelected: selectedGender == "Prefer not to say",
                    showFlame: false
                ) {
                    nameFieldFocused = false
                    withAnimation(AppAnimation.fast) {
                        selectedGender = selectedGender == "Prefer not to say"
                            ? nil : "Prefer not to say"
                        showCustomGenderField = false
                        customGenderText = ""
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                .frame(maxWidth: .infinity)

                if showCustomGenderField {
                    TextField("Describe your gender identity",
                              text: $customGenderText)
                        .font(AppFonts.body(16, weight: .regular, relativeTo: .body))
                        .foregroundColor(kTextPrimary)
                        .padding(.vertical, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .fill(kCustomPillFill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppRadius.md)
                                        .stroke(kCustomPillBorder,
                                                lineWidth: 1)
                                )
                        )
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(.top, AppSpacing.sm)
                        .transition(.opacity.combined(
                            with: .scale(scale: 0.97, anchor: .top)))
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Gender identity — optional")
    }

    // MARK: - Haptic

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    // MARK: - Helpers

    private func triggerCollapse() {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        typingDebounce?.cancel()
        withAnimation(AppAnimation.standard) {
            nameTextOpacity = 0
            fieldCollapsed = true
        }
        withAnimation(
            AppAnimation.spring
            .delay(0.28)
        ) {
            greetingVisible = true
            greetingOwnsName = true
        }
    }

    private func dismissCustomIfNeeded() {
        if showCustomGenderField {
            withAnimation(AppAnimation.standard) {
                showCustomGenderField = false
                customGenderText = ""
            }
        }
    }

    // MARK: - State Restoration

    private func restoreStateIfNeeded() {
        if !data.displayName.isEmpty {
            displayName = data.displayName
            genderSectionVisible = true
        }
        if let savedGender = data.genderIdentity {
            selectedGender = savedGender
            // If "Something else" was stored and it's a custom value,
            // we cannot reconstruct the custom field — leave as-is.
        }
    }

    // MARK: - Commit

    private func commitData() {
        data.displayName = displayName.trimmingCharacters(in: .whitespaces)
        if selectedGender == "Something else" {
            let custom = customGenderText
                .trimmingCharacters(in: .whitespaces)
            if !custom.isEmpty {
                data.genderIdentity = custom
            }
            // If somehow empty, do not write "Something else"
        } else if let selected = selectedGender,
                  selected != "Something else" {
            data.genderIdentity = selected
        }
    }
}

// MARK: - Previews

#Preview("Dark") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName = "Jordan"
        return d
    }()
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .name,
            sparkConfig: .nameView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingNameView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName = "Jordan"
        return d
    }()
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .name,
            sparkConfig: .nameView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingNameView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.light)
}

#Preview("Dark — empty state") {
    @Previewable @State var data = OnboardingData()
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .name,
            sparkConfig: .nameView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingNameView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — empty state") {
    @Previewable @State var data = OnboardingData()
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .name,
            sparkConfig: .nameView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingNameView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.light)
}
