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

    var body: some View {
        GeometryReader { geo in
            FounderLetterSheet { letterBody }
                .frame(width: geo.size.width, height: geo.size.height)
                .offset(y: departing ? geo.size.height : max(0, dismissDrag))
                .gesture(dismissGesture)
                .sensoryFeedback(.impact(weight: .medium), trigger: departing)
                .accessibilityAction(named: "Finish") { finish() }
        }
        .ignoresSafeArea(edges: .bottom)
        .accessibilityLabel("Founder letter")
    }

    // MARK: - Letter

    private var letterBody: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Placeholder copy — the real letter + signature animation land in
            // the content/visual pass. The mechanics (detent, curtain, retry)
            // are final.
            Text("Welcome to Vayl.")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)

            Text("You just built something most couples never put into words. Whatever pace you take from here, the deck in your hands was made from your own answers — there is no one else's version of it.")
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)

            Text("— Bryan")
                .font(AppFonts.prompt)
                .foregroundStyle(AppColors.textSecondary)

            if director.commitFailed {
                Text("Couldn't save — pull down to retry.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.destructive)
            }

            Spacer(minLength: 0)

            Text("Pull down when you're ready.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textHint)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, AppSpacing.xxl)
        }
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

    private func finish() {
        director.finishOnboarding(using: onboardingStore)
        if director.commitFailed {
            // bounce back — retry surface is in letterBody, nothing lost
            withAnimation(AppAnimation.spring.reduceMotionSafe) { dismissDrag = 0 }
        } else {
            // the set changed behind the curtain — complete the descent
            withAnimation(AppAnimation.exit.reduceMotionSafe) {
                departing = true
                dismissDrag = 0
            }
        }
    }
}
