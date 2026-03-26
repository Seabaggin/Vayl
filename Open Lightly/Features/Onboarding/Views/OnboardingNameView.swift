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
    @State private var selectedPronoun:   PronounOption?  = nil
    @State private var customPronounText: String          = ""
    @State private var showCustomField:   Bool           = false
    @FocusState private var nameFieldFocused: Bool

    // Atmosphere
    @State private var borderPhase: CGFloat   = 0
    @State private var hasAnimated: Bool      = false

    // Entrance
    @State private var headerVisible = false
    @State private var cardVisible   = false
    @State private var ctaVisible    = false

    // MARK: - TASK 1: Validation Bloom
    @State private var isButtonGlowing: Bool = false

    // MARK: - TASK 2: Pulse Animation
    @State private var glowPulse: Bool = false


    // Environment
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Surface tokens
    // Computed so they always read the current colorScheme.
    // Replaces the file-scope `private let` constants which
    // cannot capture colorScheme.

    private var kFieldBG: Color {
        colorScheme == .light
            ? AppColors.lightSurfaceBg          // #F2EFE6 — inset on cream
            : Color.white.opacity(0.07)
    }

    private var kGlassBorder: Color {
        colorScheme == .light
            ? AppColors.lightBorder             // black 6%
            : Color.white.opacity(0.09)
    }

    private var kFieldBorderActive: some ShapeStyle {
        if colorScheme == .light {
            // Light: warmAuroraBorder stroke — no cyan
            return AnyShapeStyle(AppColors.warmAuroraBorder)
        } else {
            return AnyShapeStyle(AppColors.spectrumBorder)
        }
    }

    private var kFloatingLabelFocused: Color {
        colorScheme == .light
            ? AppColors.lightLabelFocused       // #BE185D
            : AppColors.purpleLight
    }

    private var kFloatingLabelUnfocused: Color {
        colorScheme == .light
            ? AppColors.lightCardTitle.opacity(0.40)
            : AppColors.textTertiary
    }

    private var kTextPrimary: Color {
        colorScheme == .light
            ? AppColors.lightCardTitle
            : .white
    }

    private var kPronounLabel: Color {
        colorScheme == .light
            ? AppColors.lightCardTitle.opacity(0.65)
            : .white.opacity(0.75)   // D1-FIX: 0.55 fails WCAG AA at caption size — raised to 0.75
    }

    private var kPronounHint: Color {
        colorScheme == .light
            ? AppColors.lightHintText           // magentaDark 50%
            : AppColors.textQuaternary          // D2-FIX: use design token, not inline literal
    }

    private var kCustomPillFill: Color {
        colorScheme == .light
            ? AppColors.lightFrostPill
            : AppColors.surfaceBg
    }

    private var kCustomPillBorder: Color {
        colorScheme == .light
            ? AppColors.lightBorder
            : AppColors.borderHover
    }

    // Validation — name required, pronoun required for bloom trigger.
    // Both must be satisfied before the CTA enables.
    private var isValid: Bool {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 1 && trimmed.count <= 20 && selectedPronoun != nil
    }

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height

            ZStack {
                // ── Background ───────────────────────────────────────────
                if colorScheme == .light {
                    AppColors.lightPageBg.ignoresSafeArea()
                } else {
                    AppColors.pageBg.ignoresSafeArea()
                }

                // ── Glow field — layer 1 ─────────────────────────────────
                if colorScheme == .light {
                    AuroraGlowField(config: .nameView)
                        .ignoresSafeArea()
                } else {
                    OnboardingGlowField()
                        .ignoresSafeArea()
                }

                // ── SparkField — layer 2 (light only) ────────────────────
                if colorScheme == .light {
                    SparkField(config: .nameView)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                // ── Atmosphere ellipse ────────────────────────────────────
                // Dark: purple/blue glow in mid-screen
                // Light: omitted — AuroraGlowField handles atmosphere
                if colorScheme == .dark {
                    Ellipse()
                        .fill(RadialGradient(stops: [
                            .init(color: Color.purple.opacity(0.22), location: 0),
                            .init(color: Color.blue.opacity(0.12),   location: 0.5),
                            .init(color: .clear,                     location: 1)
                        ], center: .center, startRadius: 0, endRadius: 240))
                        .frame(width: geo.size.width, height: h * 0.31) // BUG1-FIX: capped to screen width
                        .blur(radius: 80)
                        .offset(y: h * 0.30)
                        .allowsHitTesting(false)
                }

                // ── Content ───────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 0) {

                    OnboardingNavBar(currentStep: 1, totalSteps: 6, onBack: onBack)
                        .padding(.top, geo.safeAreaInsets.top > 50 ? 8 : 20)
                        .padding(.bottom, 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Let's get")
                            .font(AppFonts.display(28, weight: .semibold))
                            .foregroundColor(kTextPrimary)
                        LivingText(
                            text: "acquainted.",
                            palette: .cyanPurple,
                            glowRadius: 6,
                            glowFloor: 0.12,
                            glowCeil: 0.28,
                            breatheDur: 5.0,
                            driftDur: 12.0
                        )
                    }
                    .opacity(headerVisible ? 1 : 0)
                    .scaleEffect(headerVisible ? 1 : 0.985, anchor: .leading)
                    .padding(.bottom, 28)

                    // ── Glass card ────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 0) {
                        nameField
                            .padding(.bottom, 20)

                        Rectangle()
                            .fill(colorScheme == .light
                                ? AppColors.lightBorder
                                : Color.white.opacity(0.05))
                            .frame(height: 1)
                            .padding(.bottom, 18)

                        pronounsSection
                    }
                    .padding(20)
                    .background(
                        Group {
                            if colorScheme == .light {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(AppColors.lightFrostCard)
                                    .background(
                                        .ultraThinMaterial,
                                        in: RoundedRectangle(cornerRadius: 20)
                                    )
                            } else {
                                // D5-FIX: material must BE the fill so blur renders;
                                // tint overlaid on top so it doesn't occlude the effect
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.white.opacity(0.05))
                                    )
                            }
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(kGlassBorder, lineWidth: 1.5)
                    )
                    .shadow(
                        color: colorScheme == .light
                            ? Color(red: 200/255, green: 100/255, blue: 40/255).opacity(0.05) // L2-FIX: valid SwiftUI initializer
                            : .clear,
                        radius: 24, y: 4
                    )
                    .shadow(
                        color: colorScheme == .light
                            ? Color.black.opacity(0.04)
                            : .clear,
                        radius: 4, y: 1
                    )
                    .opacity(cardVisible ? 1 : 0)
                    .offset(y: cardVisible ? 0 : 16)

                    Spacer(minLength: OL.spacerMin(h)) // LAYOUT-FIX: unbounded above, min prevents CTA crowding on SE

                    // ── CTA wrapper ───────────────────────────────────────
                    // MARK: - TASK 4: Aura Effect Behind Button
                    // ZStack layers: [aura] → [button] back to front.
                    // Aura fades in with the bloom; the pulsing shadow on
                    // the button itself provides the "alive" feeling.
                    ZStack {
                        RoundedRectangle(cornerRadius: 100)
                            .fill(LinearGradient(
                                colors: [
                                    AppColors.pink.opacity(0.30),
                                    AppColors.purple.opacity(0.25),
                                    AppColors.magenta.opacity(0.20)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .blur(radius: 36)
                            .opacity(isButtonGlowing ? 1.0 : 0.0)
                            .animation(
                                reduceMotion ? .none : .easeInOut(duration: 0.4),
                                value: isButtonGlowing
                            )
                            .allowsHitTesting(false)

                        HoloCTAButton(
                            title: "Next",
                            isEnabled: isValid
                        ) {
                            // MARK: - TASK 3: Haptic Feedback — CTA tap
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
                        // MARK: - TASK 2: Pulse Animation
                        // Shadow breathes between radius 8 and 18 once valid.
                        // reduceMotion: static radius 12 — no pulse, no spring.
                        .shadow(
                            color: isButtonGlowing
                                ? AppColors.pink.opacity(
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
                    .offset(y: ctaVisible ? 0 : 12)

                    OnboardingFooter()
                        .opacity(ctaVisible ? 1 : 0)
                        .offset(y: ctaVisible ? 0 : 12)
                }
                .padding(.horizontal, 28)

            }
            .frame(width: geo.size.width, alignment: .topLeading) // BUG1-FIX: anchor content to leading edge
            .onAppear {
                restoreStateIfNeeded()

                // If restoring a previously valid state (back-nav re-entry),
                // show bloom immediately without animation — no re-trigger needed.
                if isValid {
                    isButtonGlowing = true
                    if !reduceMotion {
                        withAnimation(
                            .easeInOut(duration: 2)
                            .repeatForever(autoreverses: true)
                            .delay(0.6)
                        ) { glowPulse = true }
                    }
                }

                guard !hasAnimated else { return }
                hasAnimated = true

                withAnimation(.easeOut(duration: 0.4))              { headerVisible = true }
                withAnimation(.easeOut(duration: 0.45).delay(0.15)) { cardVisible   = true }
                withAnimation(.easeOut(duration: 0.4).delay(0.30))  { ctaVisible    = true }

                // D4-FIX: borderPhase only used by dark mode custom pill border
                if colorScheme == .dark {
                    withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                        borderPhase = 1.0
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        nameFieldFocused = true
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        // REMOVED: .preferredColorScheme(.dark) — responds to system setting
        // TINT-FIX: broad .tint() removed — was overriding HoloCTAButton and
        // SelectablePill foreground colors across the entire view tree.
        // Cursor/selection tint is now scoped directly to each TextField.
        // M1-FIX: reset animation flags so entrance re-fires if view
        // is dismissed and re-presented (e.g. back-nav + re-entry)
        .onDisappear {
            hasAnimated    = false
            headerVisible  = false
            cardVisible    = false
            ctaVisible     = false
            isButtonGlowing = false
            glowPulse      = false
        }
        // MARK: - TASK 1: Validation Bloom — onChange driver
        // Fires whenever name or pronoun changes the validity state.
        // reduceMotion: instant opacity change only, no spring or pulse.
        .onChange(of: isValid) { _, newValue in
            if newValue {
                // MARK: - TASK 3: Haptic Feedback — form becomes valid
                triggerHaptic(.medium)
                if reduceMotion {
                    isButtonGlowing = true
                } else {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isButtonGlowing = true
                    }
                    // Pulse starts after bloom lands (0.4s delay)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(
                            .easeInOut(duration: 2)
                            .repeatForever(autoreverses: true)
                        ) { glowPulse = true }
                    }
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isButtonGlowing = false
                }
                glowPulse = false
            }
        }
    }

    // MARK: - Name Field

    private var nameField: some View {
        TextField("", text: $displayName)
            // TINT-FIX: tint scoped here for cursor + selection color only
            .tint(colorScheme == .light ? AppColors.lightLabelFocused : AppColors.cyan)
            .font(AppFonts.bodyText)
            .foregroundColor(kTextPrimary)
            .padding(.horizontal, 20)
            .padding(.top, 14)          // C1-FIX: push input text below floated label
            .frame(height: 58)
            .background(
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(kFieldBG)
                        .overlay {
                            if nameFieldFocused || !displayName.isEmpty {
                                // Active border
                                if colorScheme == .light {
                                    LightModeShimmer(duration: 9, usePillColors: true)
                                        .mask(
                                            RoundedRectangle(cornerRadius: 16)
                                                .strokeBorder(Color.black, lineWidth: 2)
                                        )
                                        .shadow(
                                            color: AppColors.lightShadowMagenta,
                                            radius: 8
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(kFieldBorderActive, lineWidth: 2)
                                        .shadow(
                                            color: AppColors.glowCyan,
                                            radius: 8
                                        )
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(kGlassBorder, lineWidth: 1.5)
                            }
                        }
                        .animation(.easeOut(duration: 0.2), value: nameFieldFocused)
                        .animation(.easeOut(duration: 0.2), value: displayName.isEmpty)

                    // Floating label
                    Text("First name")
                        .font(displayName.isEmpty && !nameFieldFocused
                            ? AppFonts.bodyMedium
                            : AppFonts.overline)
                        .foregroundStyle(
                            displayName.isEmpty && !nameFieldFocused
                                ? kFloatingLabelUnfocused
                                : kFloatingLabelFocused
                        )
                        .accessibilityHidden(true)
                        .offset(x: 20, y: displayName.isEmpty && !nameFieldFocused ? 0 : -14)
                        .animation(.easeOut(duration: 0.2), value: nameFieldFocused)
                        .animation(.easeOut(duration: 0.2), value: displayName)
                }
            )
            .focused($nameFieldFocused)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .onSubmit { nameFieldFocused = false }
            .onChange(of: displayName) { _, newValue in
                if newValue.count > 20 { displayName = String(newValue.prefix(20)) }
            }
            .accessibilityLabel("First name")
            .accessibilityHint("Required. 1 to 20 characters.")
    }

    // MARK: - Pronouns

    private var pronounsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Pronouns")
                    .font(AppFonts.caption)
                    .foregroundColor(kPronounLabel)
                Spacer()
                Text("so we get it right")
                    .font(AppFonts.overline)
                    .foregroundColor(kPronounHint)
            }
            .padding(.bottom, 12)

            // M2-FIX: static content — VStack/HStack has zero lazy overhead
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    SelectablePill(
                        label: "She/Her",
                        isSelected: selectedPronoun == .sheHer,
                        showFlame: false
                    ) {
                        selectPronoun(.sheHer)
                    }
                    // MARK: - TASK 5: Pronoun Chip Tap Feedback
                    
                    .opacity(pillOpacity(for: .sheHer))
                    .animation(.easeInOut(duration: 0.2), value: selectedPronoun)

                    SelectablePill(
                        label: "He/Him",
                        isSelected: selectedPronoun == .heHim,
                        showFlame: false
                    ) {
                        selectPronoun(.heHim)
                    }
                    // MARK: - TASK 5: Pronoun Chip Tap Feedback
                   
                    .opacity(pillOpacity(for: .heHim))
                    .animation(.easeInOut(duration: 0.2), value: selectedPronoun)
                }

                HStack(spacing: 10) {
                    SelectablePill(
                        label: "They/Them",
                        isSelected: selectedPronoun == .theyThem,
                        showFlame: false
                    ) {
                        selectPronoun(.theyThem)
                    }
                    // MARK: - TASK 5: Pronoun Chip Tap Feedback
                   
                    .opacity(pillOpacity(for: .theyThem))
                    .animation(.easeInOut(duration: 0.2), value: selectedPronoun)

                    if showCustomField {
                        TextField("", text: $customPronounText,
                                  prompt: Text("e.g. ze/zir")
                                      .foregroundColor(colorScheme == .light
                                          ? AppColors.lightTextTertiary
                                          : Color.white.opacity(0.35))) // D3-FIX: 0.20 is unreadable — raised to 0.35
                            // TINT-FIX: tint scoped here for cursor + selection color only
                            .tint(colorScheme == .light ? AppColors.lightLabelFocused : AppColors.cyan)
                            .font(AppFonts.bodyMedium)
                            .foregroundColor(kTextPrimary)
                            .padding(.horizontal, 20)
                            .frame(height: 46)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule()
                                    .fill(kFieldBG)
                                    .overlay(
                                        // Dark: animated spectrum border
                                        // Light: warmAuroraBorder — no animated cyan
                                        Group {
                                            if colorScheme == .light {
                                                Capsule()
                                                    .strokeBorder(
                                                        AppColors.warmAuroraBorder,
                                                        lineWidth: 2
                                                    )
                                            } else {
                                                Capsule()
                                                    .strokeBorder(
                                                        LinearGradient(colors: [
                                                            AppColors.cyan,
                                                            AppColors.purple,
                                                            AppColors.magenta
                                                            
                                                        ], startPoint: .leading, endPoint: .trailing),
                                                        lineWidth: 2
                                                    )
                                            }
                                        }
                                    )
                            )
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .transition(.opacity)
                            .accessibilityLabel("Custom pronouns")
                            .accessibilityHint("Enter your pronouns, for example ze slash zir")
                    } else {
                        Button {
                            withAnimation(.easeOut(duration: 0.25)) { showCustomField = true }
                        } label: {
                            Text("Custom")
                                .font(AppFonts.bodyMedium)
                                .foregroundColor(colorScheme == .light
                                    ? AppColors.wineDark
                                    : .white)
                                .frame(height: 46)
                                .frame(maxWidth: .infinity)
                                .background(
                                    Capsule()
                                        .fill(kCustomPillFill)
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(kCustomPillBorder, lineWidth: 1.5)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pronouns — optional")
    }

    // MARK: - TASK 3: Haptic Feedback
    // Centralized haptic helper — call at chip tap, validity change, and CTA tap.
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    // MARK: - TASK 5: Pronoun Selection + Scale Bounce
    // Handles toggle logic, spring bounce trigger, and custom field dismiss
    // in one place so each chip's action stays to a single call.
    private func selectPronoun(_ option: PronounOption) {
        // MARK: - TASK 3: Haptic Feedback — chip tap
        // SelectablePill fires its own .light haptic internally;
        // this helper adds the medium bounce on the validity transition
        // (handled in onChange(of: isValid)) not here — no double-fire.
       
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedPronoun = selectedPronoun == option ? nil : option
        }
        dismissCustomIfNeeded()
    }

    // Returns 1.0 for the selected chip (or when nothing is selected);
    // 0.5 for chips that are not currently selected.
    private func pillOpacity(for option: PronounOption) -> Double {
        guard let sel = selectedPronoun else { return 1.0 }
        return sel == option ? 1.0 : 0.5
    }

    // MARK: - Helpers

    private func dismissCustomIfNeeded() {
        if showCustomField {
            withAnimation(.easeOut(duration: 0.25)) {
                showCustomField   = false
                customPronounText = ""
            }
        }
    }

    // MARK: - State Restoration

    private func restoreStateIfNeeded() {
        if !data.displayName.isEmpty {
            displayName = data.displayName
        }
        if let firstPronoun = data.pronouns.first {
            selectedPronoun = firstPronoun
        }
        let savedCustom = data.customPronouns ?? ""
        if !savedCustom.isEmpty {
            customPronounText = savedCustom
            showCustomField   = true
        } else {
            // M3-FIX: explicitly clear so back-nav never shows an
            // open-but-empty custom field from a previous partial entry
            customPronounText = ""
            showCustomField   = false
        }
    }

    // MARK: - Commit

    private func commitData() {
        data.displayName = displayName.trimmingCharacters(in: .whitespaces)
        let custom = customPronounText.trimmingCharacters(in: .whitespaces)
        if !custom.isEmpty { data.customPronouns = custom }
        data.pronouns = selectedPronoun.map { [$0] } ?? []
    }
}

// MARK: - Previews

#Preview("Dark") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName = "Jordan"
        return d
    }()
    OnboardingNameView(data: $data, onContinue: {}, onBack: {})
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName = "Jordan"
        return d
    }()
    OnboardingNameView(data: $data, onContinue: {}, onBack: {})
        .preferredColorScheme(.light)
}
