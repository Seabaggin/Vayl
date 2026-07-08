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
    /// Dismissal is scrim-tap (mockup screen 7 has no X). Kept for hosts that add
    /// their own affordance later (e.g. drag-to-dismiss).
    var onClose: () -> Void = {}
    var onTalkTapped: (() -> Void)?

    // Content-height when it fits; scrolls when it can't (large Dynamic Type).
    // vaylSheetChrome forces maxHeight:.infinity (shared, off-limits), so the chrome
    // wraps BOTH candidates and .fixedSize(vertical) makes the fitting one hug content
    // — same recipe as PaywallSheet.sizedSheet.
    var body: some View {
        ViewThatFits(in: .vertical) {
            sheetStack
                .vaylSheetChrome()
                .fixedSize(horizontal: false, vertical: true)
            ScrollView(showsIndicators: false) { sheetStack }
                .vaylSheetChrome()
        }
    }

    private var sheetStack: some View {
        VStack(alignment: .leading, spacing: 0) {
            grabHandle

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
        AppColors.shadowDeep.ignoresSafeArea()

        DesireStarDetailSheet(match: .sample("New Relationship Energy", .mutual))
    }
    .preferredColorScheme(.dark)
}

#Preview("Detail sheet — adjacent") {
    ZStack(alignment: .bottom) {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .cardReveal).ignoresSafeArea()
        AppColors.shadowDeep.ignoresSafeArea()

        DesireStarDetailSheet(match: .sample("Overnight Stays", .adjacent, category: "logistics"))
    }
    .preferredColorScheme(.dark)
}
#endif
