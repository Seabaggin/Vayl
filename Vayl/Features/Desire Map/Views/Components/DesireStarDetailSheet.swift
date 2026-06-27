//
//  DesireStarDetailSheet.swift
//  Vayl
//
//  Screen 7 — star detail sheet. Hosted INSIDE the reveal cover as a custom
//  bottom sheet (ZStack + .move(edge:.bottom) transition in DesireRevealView).
//  Never presented via .vaylSheet or .sheet — those break width on iOS 26.
//
//  Pattern mirrors CredentialEditorOverlay: grab handle, content, vaylSheetChrome.
//

import SwiftUI

struct DesireStarDetailSheet: View {

    let match: RevealMatch
    var onClose: () -> Void = {}
    var onTalkTapped: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            grabHandle

            // Close row
            HStack {
                Spacer()
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(AppColors.cardBg.opacity(0.55)))
                        .overlay(Circle().stroke(AppColors.borderSubtle, lineWidth: 1))
                }
                .buttonStyle(_DetailPressStyle())
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.sm)

            // Detail body
            DesireMatchDetail(
                match: match,
                onTalkTapped: onTalkTapped,
                onLearnTapped: nil   // stub — S1.3; Learn nav wired later
            )
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xxl)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .vaylSheetChrome()
    }

    private var grabHandle: some View {
        Capsule()
            .fill(AppColors.spectrumBorder)
            .frame(width: 40, height: 4)
            .opacity(0.55)
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.md)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Detail sheet — mutual") {
    ZStack(alignment: .bottom) {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .cardReveal).ignoresSafeArea()
        Color.black.opacity(0.5).ignoresSafeArea()

        DesireStarDetailSheet(match: .sample("New Relationship Energy", .mutual))
    }
    .preferredColorScheme(.dark)
}

#Preview("Detail sheet — adjacent") {
    ZStack(alignment: .bottom) {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .cardReveal).ignoresSafeArea()
        Color.black.opacity(0.5).ignoresSafeArea()

        DesireStarDetailSheet(match: .sample("Overnight Stays", .adjacent, category: "logistics"))
    }
    .preferredColorScheme(.dark)
}
#endif
