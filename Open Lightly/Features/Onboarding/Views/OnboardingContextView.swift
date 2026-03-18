// Features/Onboarding/Views/OnboardingContextView.swift
//
// Screen 4: Relationship Context — branches on explorationMode
// Solo: 3 cards  |  Couple: 4 cards

import SwiftUI

struct OnboardingContextView: View {
    @Binding var data: OnboardingData
    var onContinue: (() -> Void)?
    var onBack: (() -> Void)?

    @State private var headerVisible      = false
    @State private var cardsVisible       = false
    @State private var reassuranceVisible = false

    @State private var selection: ContextOption? = nil
    @State private var autoAdvanceFired          = false

    // MARK: - Option Data

    private let soloOptions: [ContextOption] = [
        ContextOption(
            id: "single", context: .single, intensity: .ember,
            title: "I'm single",
            subtitle: "No partner in the picture",
            detail: "Your journey is yours alone — we'll tailor everything to individual exploration."
        ),
        ContextOption(
            id: "partnered_open", context: .partneredOpen, intensity: .spark,
            title: "I have a partner",
            subtitle: "They know I'm exploring",
            detail: "We'll include prompts that help you navigate with transparency."
        ),
        ContextOption(
            id: "partnered_hidden", context: .partneredHidden, intensity: .blaze,
            title: "It's complicated",
            subtitle: "I'm not sure how to bring it up",
            detail: "No pressure. We'll start with self-understanding before any conversations."
        ),
    ]

    private let coupleOptions: [ContextOption] = [
        ContextOption(
            id: "not_talked", context: .notTalked, intensity: .ember,
            title: "Haven't really talked about it",
            subtitle: "One or both of us is curious",
            detail: "We'll start with the basics — language, comfort levels, and small openings."
        ),
        ContextOption(
            id: "talking", context: .talking, intensity: .flame,
            title: "We've been talking",
            subtitle: "No experience yet, but we're on the same page",
            detail: "Great foundation. We'll build on your shared curiosity with structured prompts."
        ),
        ContextOption(
            id: "some_experience", context: .someExperience, intensity: .inferno,
            title: "We've tried some things",
            subtitle: "Real experiences — good, bad, or somewhere in between",
            detail: "We'll help you process what happened and decide what comes next."
        ),
        ContextOption(
            id: "needs_reset", context: .needsReset, intensity: .nova,
            title: "We need a reset",
            subtitle: "Something's off and we want to find our footing again",
            detail: "We'll focus on repair, reconnection, and rebuilding trust first."
        ),
    ]

    private var options: [ContextOption] {
        data.explorationMode == .couple ? coupleOptions : soloOptions
    }

    private var headlineText: String {
        data.explorationMode == .couple
            ? "You're exploring this together."
            : "You're exploring on your own."
    }

    private var subheadText: String {
        data.explorationMode == .couple
            ? "Where are you two at?"
            : "One thing that helps us personalize —"
    }

    private var reassuranceText: String {
        data.explorationMode == .couple
            ? "Every starting point is valid."
            : "No judgment on any answer."
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            OnboardingNavBar(currentStep: 3, totalSteps: 5, onBack: onBack)
                .padding(.top, 12)
                .padding(.bottom, 20)
                .padding(.horizontal, 24)
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : -8)

            VStack(alignment: .leading, spacing: 8) {
                Text(headlineText)
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subheadText)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .opacity(headerVisible ? 1 : 0)
            .offset(y: headerVisible ? 0 : 12)

            Spacer(minLength: 28)

            ContextCardStack(
                selection: $selection,
                options: options,
                onAdvance: handleAdvance
            )
            .opacity(cardsVisible ? 1 : 0)
            .offset(y: cardsVisible ? 0 : 16)

            Spacer(minLength: 28)

            Text(reassuranceText)
                .font(AppFonts.caption)
                .foregroundStyle(LinearGradient(
                    colors: [AppColors.cyan, AppColors.purple],
                    startPoint: .leading, endPoint: .trailing
                ))
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(reassuranceVisible ? 1 : 0)
                .offset(y: reassuranceVisible ? 0 : 8)

            OnboardingFooter(text: "Your data is encrypted and always stays yours.")
                .padding(.horizontal, 24)
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
    }

    // MARK: - Actions

    private func handleAdvance() {
        guard !autoAdvanceFired else { return }
        autoAdvanceFired = true
        data.relationshipContext = selection?.context
        onContinue?()
    }

    private func runEntranceAnimations() {
        withAnimation(.easeOut(duration: 0.5).delay(0.15)) { headerVisible      = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.30)) { cardsVisible       = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.55)) { reassuranceVisible = true }
    }
}

// MARK: - Preview

#Preview("Solo") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.explorationMode = .solo
        return d
    }()
    OnboardingContextView(data: $data, onContinue: {}, onBack: {})
}

#Preview("Couple") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.explorationMode = .couple
        return d
    }()
    OnboardingContextView(data: $data, onContinue: {}, onBack: {})
}
