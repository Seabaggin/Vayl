// Features/Onboarding/Phases/SingleGreetingSheet.swift
//
// The couples-first "honest moment" shown when a user confirms "I'm single" in ContextPhase.
// Hosted OUTSIDE the canvas (the canvas forbids .sheet) — same pattern as CredentialEditorOverlay,
// driven by director.showSingleGreeting. "Got it" commits the pending context conclusion
// (director.continueFromSingleGreeting) and advances.

import SwiftUI

struct SingleGreetingOverlay: View {
    @Bindable var director: VaylDirector
    @State private var pressed = false

    var body: some View {
        ZStack {
            // Scrim — focus the moment. No tap-to-dismiss: this is acknowledged via "Got it".
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .transition(.opacity)

            card
                .padding(.horizontal, AppSpacing.xl)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .ignoresSafeArea()
    }

    private var card: some View {
        VStack(spacing: AppSpacing.lg) {
            Text("AN HONEST MOMENT")
                .font(AppFonts.overline)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textAccent)
                .tracking(2)

            Text("Vayl gets the most out of two people right now — more for solo journeys is on the way.")
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("But you're not locked out — these are yours today:")
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: AppSpacing.md) {
                SpectrumBulletRow(text: "Your Desire Map", phaseOffset: 0.00)
                SpectrumBulletRow(text: "A solo deck", phaseOffset: 0.22)
                SpectrumBulletRow(text: "The Learn library", phaseOffset: 0.44)
            }
            .padding(.top, AppSpacing.xs)

            continueButton
                .padding(.top, AppSpacing.xs)
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: 360)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .fill(AppColors.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .strokeBorder(AppColors.spectrumBorder, lineWidth: 1)
                        .opacity(0.5)
                )
        )
    }

    private var continueButton: some View {
        Text("Got it")
            .font(AppFonts.buttonLabel)
            .foregroundStyle(AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.pill)
                    .strokeBorder(AppColors.spectrumBorder, lineWidth: 1.2)
            )
            .scaleEffect(pressed ? 0.96 : 1.0)
            .animation(AppAnimation.fast.reduceMotionSafe, value: pressed)
            .sensoryFeedback(.impact(weight: .light), trigger: pressed)
            .contentShape(Rectangle())
            .onTapGesture { director.continueFromSingleGreeting() }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressed = true }
                    .onEnded { _ in pressed = false }
            )
    }
}

#if DEBUG
#Preview("Single greeting") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        SingleGreetingOverlay(director: VaylDirector())
    }
    .preferredColorScheme(.dark)
}
#endif
