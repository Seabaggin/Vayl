// OnboardingNameView.swift
// Open Lightly
//
// Screen 1: Name + Pronouns

import SwiftUI

// MARK: - Local shorthands (all backed by AppColors — single source of truth)

private let kFieldBG     = Color.white.opacity(0.07)
private let kGlassBorder = Color.white.opacity(0.09)

// MARK: - Main View

struct OnboardingNameView: View {
    @Binding var data: OnboardingData
    var onContinue: (() -> Void)?
    var onBack:     (() -> Void)?

    // Form state
    @State private var displayName:       String         = ""
    @State private var selectedPronoun:   PronounOption?  = nil
    @State private var customPronounText: String         = ""
    @State private var showCustomField:   Bool           = false
    @FocusState private var nameFieldFocused: Bool

    // Atmosphere
    @State private var borderPhase: CGFloat   = 0
    @State private var hasAnimated: Bool      = false

    // Entrance
    @State private var headerVisible = false
    @State private var cardVisible   = false
    @State private var ctaVisible    = false

    // Validation — name required, pronouns optional
    private var isValid: Bool {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 1 && displayName.count <= 20
    }

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height

            ZStack {
                AppColors.pageBg.ignoresSafeArea()

                Ellipse()
                    .fill(RadialGradient(stops: [
                        .init(color: Color.purple.opacity(0.22), location: 0),
                        .init(color: Color.blue.opacity(0.12),   location: 0.5),
                        .init(color: .clear,                     location: 1)
                    ], center: .center, startRadius: 0, endRadius: 240))
                    .frame(width: 420, height: 260)
                    .blur(radius: 80)
                    .offset(y: h * 0.30)
                    .allowsHitTesting(false)

                OnboardingGlowField()
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {

                    OnboardingNavBar(currentStep: 1, totalSteps: 6, onBack: onBack)
                        .padding(.top, geo.safeAreaInsets.top > 50 ? 8 : 20)
                        .padding(.bottom, 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Let's get")
                            .font(AppFonts.display(28, weight: .semibold))
                            .foregroundColor(.white)
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

                    VStack(alignment: .leading, spacing: 0) {
                        nameField
                            .padding(.bottom, 20)

                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 1)
                            .padding(.bottom, 18)

                        pronounsSection
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(kGlassBorder, lineWidth: 1.5)
                    )
                    .opacity(cardVisible ? 1 : 0)
                    .offset(y: cardVisible ? 0 : 16)

                    Spacer()

                    HoloCTAButton(
                        title: "Next",
                        isEnabled: isValid
                    ) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        commitData()
                        onContinue?()
                    }
                    .opacity(ctaVisible ? 1 : 0)
                    .offset(y: ctaVisible ? 0 : 12)

                    if ctaVisible {
                        OnboardingFooter()
                    }
                }
                .padding(.horizontal, 28)
            }
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true

                withAnimation(.easeOut(duration: 0.4))              { headerVisible = true }
                withAnimation(.easeOut(duration: 0.45).delay(0.15)) { cardVisible   = true }
                withAnimation(.easeOut(duration: 0.4).delay(0.30))  { ctaVisible    = true }

                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    borderPhase = 1.0
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .preferredColorScheme(.dark)
        .tint(AppColors.cyan)
    }

    // MARK: - Name Field

    private var nameField: some View {
        TextField("", text: $displayName)
            .font(.system(size: 16))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .frame(height: 58)
            .background(
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(kFieldBG)
                        .pillBorder(cornerRadius: 16, lineWidth: 2, glowRadius: 8)

                    Text("First name")
                        .font(.system(
                            size: displayName.isEmpty && !nameFieldFocused ? 15 : 11,
                            weight: displayName.isEmpty && !nameFieldFocused ? .regular : .semibold
                        ))
                        .foregroundColor(
                            displayName.isEmpty && !nameFieldFocused
                                ? Color(red: 107/255, green: 107/255, blue: 128/255)
                                : Color(red: 123/255, green: 97/255,  blue: 255/255)
                        )
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
    }

    // MARK: - Pronouns

    private var pronounsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Pronouns")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))
                Spacer()
                Text("so we get it right")
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.42, green: 0.42, blue: 0.50))
            }
            .padding(.bottom, 12)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {

                SelectablePill(
                    label: "She/Her",
                    isSelected: selectedPronoun == .sheHer
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPronoun = selectedPronoun == .sheHer ? nil : .sheHer
                    }
                    dismissCustomIfNeeded()
                }

                SelectablePill(
                    label: "He/Him",
                    isSelected: selectedPronoun == .heHim
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPronoun = selectedPronoun == .heHim ? nil : .heHim
                    }
                    dismissCustomIfNeeded()
                }

                SelectablePill(
                    label: "They/Them",
                    isSelected: selectedPronoun == .theyThem
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPronoun = selectedPronoun == .theyThem ? nil : .theyThem
                    }
                    dismissCustomIfNeeded()
                }

                if showCustomField {
                    TextField("", text: $customPronounText,
                              prompt: Text("e.g. ze/zir")
                                  .foregroundColor(Color.white.opacity(0.20)))
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .frame(height: 46)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule().fill(kFieldBG)
                                .overlay(Capsule().strokeBorder(
                                    LinearGradient(colors: [
                                        AppColors.magenta.opacity(0.15 + 0.25 * Double(1 - borderPhase)),
                                        AppColors.purple.opacity(0.20),
                                        AppColors.cyan.opacity(0.15 + 0.25 * Double(borderPhase))
                                    ], startPoint: .leading, endPoint: .trailing),
                                    lineWidth: 2))
                        )
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .transition(.opacity)
                } else {
                    Button {
                        withAnimation(.easeOut(duration: 0.25)) { showCustomField = true }
                    } label: {
                        Text("Custom")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.55))
                            .frame(height: 46)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule().fill(AppColors.surfaceBg)
                                    .overlay(Capsule().strokeBorder(AppColors.borderHover, lineWidth: 1.5))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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

    // MARK: - Commit

    private func commitData() {
        data.displayName = displayName.trimmingCharacters(in: .whitespaces)
        let custom = customPronounText.trimmingCharacters(in: .whitespaces)
        if !custom.isEmpty { data.customPronouns = custom }
        data.pronouns = selectedPronoun.map { [$0] } ?? []
    }
}

// MARK: - Preview

#Preview {
    OnboardingNameView(
        data: .constant(OnboardingData()),
        onContinue: { },
        onBack: { }
    )
}
