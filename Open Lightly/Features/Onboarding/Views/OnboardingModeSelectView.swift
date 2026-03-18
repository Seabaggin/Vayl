// OnboardingModeSelectView.swift
// Open Lightly
//
// Screen 2: Mode Select — Solo vs. Partnered + NM experience level

import SwiftUI

struct OnboardingModeSelectView: View {
    @Binding var data: OnboardingData
    var onContinue: () -> Void
    var onBack: (() -> Void)?

    @State private var headerVisible     = false
    @State private var cardsVisible      = false
    @State private var experienceVisible = false
    @State private var ctaVisible        = false

    private var selectionMade: Bool {
        data.explorationMode != nil && data.nmStage != nil
    }

    /// Descriptor text that appears below pills on selection
    private var experienceDescriptor: String? {
        switch data.nmStage {
        case .curious:
            return "New to this — maybe I've read about it or know people who do it."
        case .exploring:
            return "I've dipped my toes in. A few real experiences."
        case .experienced:
            return "This has been part of my life for a while."
        case .none:
            return nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            // Nav
            OnboardingNavBar(currentStep: 2, totalSteps: 6, onBack: onBack)
                .padding(.top, 12)
                .padding(.bottom, 20)
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : -8)

            // Scrollable content
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    // Title + subtitle
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("How are you")
                                .font(AppFonts.heroTitle)
                                .foregroundStyle(AppColors.textPrimary)
                            Text("exploring?")
                                .font(AppFonts.heroTitle)
                                .foregroundStyle(LinearGradient(
                                    colors: [AppColors.purple, AppColors.cyan],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                        }
                        Text("There's no wrong way to start.")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .opacity(headerVisible ? 1 : 0)
                    .offset(y: headerVisible ? 0 : 12)

                    // Mode cards
                    VStack(spacing: 14) {
                        modeCard(
                            icon: "✦",
                            title: "On my own",
                            subtitle: "Figure out what you want first",
                            mode: .solo
                        )
                        modeCard(
                            icon: "✦",
                            title: "With a partner",
                            subtitle: "Start the conversation together",
                            mode: .couple
                        )
                    }
                    .opacity(cardsVisible ? 1 : 0)
                    .offset(y: cardsVisible ? 0 : 16)

                    // Experience level
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Your experience")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppColors.textSecondary)
                            Spacer()
                            Text("No judgment")
                                .font(.system(size: 11))
                                .foregroundColor(Color(red: 0.42, green: 0.42, blue: 0.50))
                        }

                        ZStack {
                            // Dark pocket behind pills
                            Capsule()
                                .fill(Color.black.opacity(0.45))
                                .frame(height: 80)
                                .blur(radius: 30)
                                .padding(.horizontal, -6)

                            HStack(spacing: 10) {
                                SelectablePill(
                                    label: "Curious",
                                    isSelected: data.nmStage == .curious,
                                    intensity: .dim,
                                    height: 42,
                                    fontSize: 14
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        data.nmStage = .curious
                                    }
                                }

                                SelectablePill(
                                    label: "Exploring",
                                    isSelected: data.nmStage == .exploring,
                                    intensity: .warm,
                                    height: 42,
                                    fontSize: 14
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        data.nmStage = .exploring
                                    }
                                }

                                SelectablePill(
                                    label: "Experienced",
                                    isSelected: data.nmStage == .experienced,
                                    intensity: .alive,
                                    height: 42,
                                    fontSize: 14
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        data.nmStage = .experienced
                                    }
                                }
                            }
                        }

                        // Descriptor — appears on selection
                        if let descriptor = experienceDescriptor {
                            Text(descriptor)
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                                .id(data.nmStage) // forces transition on change
                        }
                    }
                    .opacity(experienceVisible ? 1 : 0)
                    .offset(y: experienceVisible ? 0 : 16)

                    // Reassurance
                    Text("You can always change these later.")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .opacity(experienceVisible ? 1 : 0)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }

            Spacer(minLength: 0)

            // CTA + footer
            VStack(spacing: 0) {
                HoloCTAButton(title: "Let's go", isEnabled: selectionMade) {
                    onContinue()
                }
                OnboardingFooter(text: "Your data is encrypted and always stays yours.")
            }
            .padding(.horizontal, 24)
            .opacity(ctaVisible ? 1 : 0)
            .offset(y: ctaVisible ? 0 : 12)
        }
        .background {
            ZStack {
                AppColors.pageBg

                Ellipse()
                    .fill(RadialGradient(
                        colors: [AppColors.purple.opacity(0.3), AppColors.deepBlue.opacity(0.15), Color.clear],
                        center: .top, startRadius: 30, endRadius: 360
                    ))
                    .frame(width: 600, height: 500)
                    .offset(y: -80)
                    .blur(radius: 80)

                OnboardingGlowField()
            }
            .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        .onAppear { runEntranceAnimations() }
        .onAppear { runEntranceAnimations() }
        .onChange(of: data.explorationMode) { newValue in
            if newValue != nil && !experienceVisible {
                withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
                    experienceVisible = true
                }
            }
        }
    }

    // MARK: - Mode Card

    private func modeCard(icon: String, title: String, subtitle: String, mode: ExplorationMode) -> some View {
        let isSelected = data.explorationMode == mode

        return Button {
            withAnimation(.easeInOut(duration: 0.25)) { data.explorationMode = mode }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 14) {
                Text(icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? AppColors.cyan : AppColors.textTertiary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(subtitle)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(AppColors.cardBg))
            .overlay(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(LinearGradient(
                                colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                                startPoint: .leading, endPoint: .trailing
                            ), lineWidth: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppColors.border, lineWidth: 1.5)
                    }
                }
            )
            .compositingGroup()
            .shadow(color: isSelected ? AppColors.cyan.opacity(0.3) : .clear, radius: 8)
            .shadow(color: isSelected ? AppColors.magenta.opacity(0.2) : .clear, radius: 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Animations

    // MARK: - Animations

    private func runEntranceAnimations() {
        withAnimation(.easeOut(duration: 0.5).delay(0.15)) { headerVisible     = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.30)) { cardsVisible      = true }
        // REMOVED: experienceVisible no longer fires here
        withAnimation(.easeOut(duration: 0.5).delay(0.55)) { ctaVisible        = true }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var data = OnboardingData()

        var body: some View {
            OnboardingModeSelectView(
                data: $data,
                onContinue: { },
                onBack: { }
            )
        }
    }

    return PreviewWrapper()
}
