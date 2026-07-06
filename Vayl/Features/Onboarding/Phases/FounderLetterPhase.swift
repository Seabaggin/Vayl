//
//  FounderLetterPhase.swift
//  Vayl
//

import SwiftUI

/// OB Phase — Founder Letter (renders OBPhase.founderLetter).
///
/// Mounts with the shared FounderLetterSheet already covering the screen —
/// BuildDeckPhase expanded it fully before advancing, so the phase swap
/// happened invisibly behind the sheet (ceremony spec, Beat 7).
///
/// Dismissal contract (Beat 8, "the curtain"):
///   · single full detent — no medium stop, upward drag rubber-bands
///   · pull-down is the COMPLETION gesture, not a cancel: past the threshold
///     it commits via director.finishOnboarding(using:)
///   · success → the sheet completes its descent; the stage behind already
///     changed (finishOnboarding fades the table; reactive routing carries the
///     user home) — the set changed behind the curtain
///   · failure → the sheet settles back up with a quiet retry line
///     (director.commitFailed); nothing is lost
///   · never hostage: dismissal is available from the first frame; letter copy
///     is a placeholder pending the content pass
struct FounderLetterPhase: View {

    let director: VaylDirector
    @Environment(OnboardingStore.self) private var onboardingStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var dismissDrag: CGFloat = 0
    @State private var departing   = false

    /// Pull-down distance that commits. Feel-tunable.
    private let dismissThreshold: CGFloat = 140

    /// The sheet rests inset from the top — a card sheet, not an edge-to-edge
    /// fill — so the void/table shows in the strip above (One Year grammar).
    /// Fraction of screen height; MUST equal BuildDeckPhase.expandedTopInsetFrac
    /// so the peek→full phase swap stays pixel-identical.
    private let topInsetFrac: CGFloat = 0.15

    var body: some View {
        GeometryReader { geo in
            let topInset = geo.size.height * topInsetFrac
            FounderLetterSheet { letterBody(height: geo.size.height) }
                // maxWidth: .infinity (NOT geo.size.width) — the nested geo can
                // report the safe width, which inset the sheet and left side
                // gaps. Filling the parent guarantees true edge-to-edge.
                .frame(maxWidth: .infinity)
                .frame(height: geo.size.height - topInset)
                .offset(y: departing ? geo.size.height : topInset + max(0, dismissDrag))
                .gesture(dismissGesture)
                .sensoryFeedback(.impact(weight: .medium), trigger: departing)
                .accessibilityAction(named: "Finish") { finish() }
        }
        .ignoresSafeArea()
        .accessibilityLabel("Founder letter")
    }

    // MARK: - Letter

    private func letterFont(for height: CGFloat) -> Font {
        switch height {
        case ..<700: return AppFonts.founderLetter(13)
        case ..<900: return AppFonts.founderLetter(15)
        default:     return AppFonts.founderLetter(16)
        }
    }

    @ViewBuilder
    private func letterBody(height: CGFloat) -> some View {
        let font = letterFont(for: height)
        VStack(spacing: AppSpacing.md) {

            VaylGradientWordmark()

            // Paragraphs — kept tight so the sign-off + signature stay on-page
            VStack(spacing: AppSpacing.md) {
                Text("Non-monogamy is my life. For the past three years, everything I've built has been in service to my community.")
                    .font(font)
                    .foregroundStyle(AppColors.textBody)

                Text("I'm of the mind that most relationship conflicts boil down to information asymmetry, and unlike monogamy, NM can be far more consequential when that asymmetry goes unaddressed.")
                    .font(font)
                    .foregroundStyle(AppColors.textBody)

                Text("Vayl is what I wish I had at the beginning of my journey: a way to explore myself, uncover hidden truths, and do it alongside my partner.")
                    .font(font)
                    .foregroundStyle(AppColors.textBody)

                Text("Before your journey begins, whether it takes you further than you ever imagined or you realize where you've been is where you were always meant to be, thank you for following your curiosity here.")
                    .font(font)
                    .foregroundStyle(AppColors.textBody)
            }
            .fixedSize(horizontal: false, vertical: true)

            // Sign-off
            VStack(spacing: AppSpacing.xs) {
                Text("Forever Grateful,")
                    .font(AppFonts.founderLetterBold(14))
                    .foregroundStyle(AppColors.textPrimary)

                // Signature — Native SwiftUI animated draw-on, plays once.
                // Fits its own bounds, so the frame sets the rendered size.
                AnimatedSignature()
                    .frame(width: 280, height: 110)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.md)
            }

            if director.commitFailed {
                Text("Couldn't save — pull down to retry.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.destructive)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.xl)
    }

    // MARK: - Dismissal (the curtain)

    private var dismissGesture: some Gesture {
        DragGesture()
            .onChanged { v in
                guard !departing else { return }
                // single full detent: downward follows the finger, upward rubber-bands
                dismissDrag = v.translation.height > 0
                    ? v.translation.height
                    : v.translation.height / 6
            }
            .onEnded { v in
                guard !departing else { return }
                if v.translation.height > dismissThreshold {
                    finish()
                } else {
                    withAnimation(AppAnimation.spring.reduceMotionSafe) { dismissDrag = 0 }
                }
            }
    }

    // MARK: - Gradient wordmark

    fileprivate struct VaylGradientWordmark: View {
        var body: some View {
            VStack(spacing: AppSpacing.xs) {
                Text("Welcome To")
                    .font(AppFonts.display(24, weight: .bold, relativeTo: .title2))
                    .foregroundStyle(AppColors.textPrimary)

                LivingText(
                    text: "VAYL",
                    font: AppFonts.display(48, weight: .bold, relativeTo: .largeTitle)
                )

                SpectrumHairline()
                    .padding(.horizontal, AppSpacing.lg)
            }
        }
    }

    private func finish() {
        director.finishOnboarding(using: onboardingStore)
        if director.commitFailed {
            // bounce back — retry surface is in letterBody, nothing lost
            withAnimation(AppAnimation.spring.reduceMotionSafe) { dismissDrag = 0 }
        } else {
            // the set changed behind the curtain — complete the descent.
            withAnimation(AppAnimation.curtainFall.reduceMotionSafe) {
                departing = true
                dismissDrag = 0
            }
        }
    }
}
