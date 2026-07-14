//
//  SessionDealIntroView.swift
//  Vayl
//
//  Segment 1 of the session-entry-flow redesign (Seg 1 — standalone, unwired).
//  Spec: docs/superpowers/specs/2026-07-11-session-entry-flow-redesign.md
//  Feel reference: docs/mockups/pre-session-deal.html (timings ported verbatim).
//
//  The "you're in it now" pre-session beat: a dealer-copy line fades in and
//  out, cards bloom from center into a portrait reservoir, a short settle,
//  then the first card auto-deals — a portrait back pulls out of the
//  reservoir and turns (edge-on, so the VAYL wordmark is never caught
//  sideways) into the landscape prompt card SessionPlayerView deals — before
//  diving into bare reading text exactly like SessionPlayerView.commitDeal.
//
//  This view owns no store and no network. It is driven purely by the
//  injected copy + prompt and calls `onComplete` once the reading text has
//  resolved. NOT yet wired into CardSessionContainerView — that is Seg 2.
//

import SwiftUI

struct SessionDealIntroView: View {

    let dealerCopy: String
    let firstPrompt: String
    var onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var motionDisabled: Bool { reduceMotion || AppAnimation.lowPower }

    // Decorative reservoir size — not tied to the couple's real hand size;
    // this beat only stages the FIRST card, the rest are atmosphere. Matches
    // the mockup's N=5, which is also what the locked ~4.9s total assumes
    // (bloom stagger × 4 gaps + bloom duration).
    private let reservoirCount = 5

    // MARK: - Timing (local copies of the AppAnimation tokens above, so the
    // sequencer's arithmetic never multiplies/divides an `AppAnimation.` token
    // directly — mirrors SessionPlayerView's own holdSeconds/diveSeconds pattern).
    private let copyHoldSeconds = AppAnimation.sessionIntroCopyHold
    private let bloomDurationSeconds = AppAnimation.sessionIntroBloomDuration
    private let bloomStaggerSeconds = AppAnimation.sessionIntroBloomStagger
    private let settleSeconds = AppAnimation.sessionIntroSettle
    private let pullSeconds = AppAnimation.sessionIntroPullDuration
    private let flipStartRatio = AppAnimation.sessionIntroFlipStartRatio
    private let flipFrontDelay = AppAnimation.sessionIntroFlipFrontDelay
    private let flipFrontOpenSeconds = 0.32   // matches sessionIntroFlipFrontOpen's duration
    private let diveSeconds = AppAnimation.sessionIntroDiveSeconds
    private let textHandoffRatio = AppAnimation.sessionIntroTextHandoffRatio

    // MARK: - State

    @State private var sequenceStarted = false

    @State private var copyOpacity: Double = 0
    @State private var reservoirVisible: [Bool] = Array(repeating: false, count: 5)

    @State private var dealing = false        // pull/flip/dealt-card phase active
    @State private var backPulled = false     // portrait back: reservoir slot → center
    @State private var backTurned = false     // portrait back turning edge-on
    @State private var frontOpened = false    // landscape front opening from edge-on

    @State private var diving = false         // card→text dive (matches SessionPlayerView.diving)
    @State private var warpProgress: CGFloat = 0
    @State private var textResolved = false

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let layout = AppLayout.from(geo)
            ZStack {
                if !motionDisabled {
                    reservoirView(layout: layout)
                }

                if dealing {
                    dealtBackCard(layout: layout)
                    dealtFrontCard(layout: layout)
                }

                if diving && !motionDisabled {
                    warpFlashView
                }

                dealerCopyView

                readingTextView
            }
            .frame(width: layout.screenWidth, height: layout.screenHeight)
            .onAppear {
                guard !sequenceStarted else { return }
                sequenceStarted = true
                Task { await runSequence() }
            }
        }
        .allowsHitTesting(false)   // Seg 1: no interaction, the beat plays itself out
    }

    // MARK: - Dealer copy

    private var dealerCopyView: some View {
        VStack(spacing: AppSpacing.md) {
            Text("tonight")
                .font(AppFonts.overline)
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textTertiary)
            Text(dealerCopy)
                .font(AppFonts.display(24, weight: .medium, relativeTo: .title2))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(AppSpacing.xs)
        }
        .padding(.horizontal, AppSpacing.xl)
        .opacity(copyOpacity)
    }

    // MARK: - Reservoir (portrait VaylCardBack fan)

    /// Reservoir cards render at native OB card geometry, then scale down
    /// uniformly — same technique as SessionPlayerView.fanCard, so hex-cell
    /// size, corner radius, and border width all hold their real proportions
    /// instead of distorting at a tiny frame.
    private func reservoirView(layout: AppLayout) -> some View {
        let nativeW = AppLayout.obCardWidth(in: layout.screenWidth)
        let nativeH = AppLayout.obCardHeight(in: layout.screenWidth)
        let displayW: CGFloat = 72   // rendering constant — reservoir footprint
        let scale = displayW / nativeW
        let displayH = nativeH * scale

        return ZStack {
            ForEach(0..<reservoirCount, id: \.self) { index in
                // The rightmost slot is the card being dealt — once dealing
                // starts it's replaced by dealtBackCard/dealtFrontCard, so it
                // drops out of the reservoir instead of doubling up.
                if !(dealing && index == reservoirCount - 1) {
                    let bloomed = reservoirVisible[index]
                    VaylCardBack()
                        .frame(width: nativeW, height: nativeH)
                        .scaleEffect(scale)
                        .frame(width: displayW, height: displayH)
                        .shadow(color: AppColors.shadowDeep, radius: 10, y: 5)
                        .scaleEffect(bloomed ? 1 : 0.18)
                        .rotationEffect(.degrees(bloomed ? reservoirSlotRotation(index) : 0))
                        .opacity(bloomed ? 1 : 0)
                        .offset(
                            x: bloomed ? reservoirSlotX(index) : 0,
                            y: bloomed ? reservoirSlotY(index, layout: layout) : reservoirBaseY(layout)
                        )
                        .zIndex(Double(index))   // right-most on top, per spec
                }
            }
        }
    }

    // Reservoir geometry — shared between the resting fan and the dealt
    // card's pull-origin, so the two never drift out of sync. Coefficients
    // (34 / 7 / 8) are rendering constants ported from the mockup's slot math,
    // scaled by the sessionIntroReservoirSpread token.
    private func reservoirBaseY(_ layout: AppLayout) -> CGFloat {
        // Matches SessionPlayerView.fanDeck's top-anchored position exactly
        // (padding.top xl, cards centered in an 80pt-tall row) so the
        // reservoir rests where the fan deck will be — the .transition →
        // .session swap hands off the same silhouette instead of popping it.
        let fanRowCenterFromTop = layout.safeAreaInsets.top + AppSpacing.xl + 40
        return fanRowCenterFromTop - layout.screenHeight / 2
    }

    private func reservoirSlotOffset(_ index: Int) -> CGFloat {
        CGFloat(index) - CGFloat(reservoirCount - 1) / 2
    }

    private func reservoirSlotX(_ index: Int) -> CGFloat {
        reservoirSlotOffset(index) * 34 * AppAnimation.sessionIntroReservoirSpread
    }

    private func reservoirSlotY(_ index: Int, layout: AppLayout) -> CGFloat {
        reservoirBaseY(layout) + abs(reservoirSlotOffset(index)) * 7 * AppAnimation.sessionIntroReservoirSpread
    }

    private func reservoirSlotRotation(_ index: Int) -> Double {
        Double(reservoirSlotOffset(index)) * 8 * AppAnimation.sessionIntroReservoirSpread
    }

    // MARK: - Dealt card (pull + flip: portrait back → landscape front)

    /// The portrait back — pulls from the last reservoir slot to center
    /// (translate + scale, VAYL always upright, never in-plane rotated), then
    /// turns edge-on. Split from the front into its own element (mirroring
    /// the mockup) so the flip can overlap the pull's tail instead of both
    /// legs fighting over one rotating view.
    private func dealtBackCard(layout: AppLayout) -> some View {
        let nativeW = AppLayout.obCardWidth(in: layout.screenWidth)
        let nativeH = AppLayout.obCardHeight(in: layout.screenWidth)
        let displayW: CGFloat = 72
        let scale = displayW / nativeW
        let originIndex = reservoirCount - 1

        return VaylCardBack()
            .frame(width: nativeW, height: nativeH)
            .scaleEffect(backPulled ? 1 : scale)
            .rotation3DEffect(.degrees(backTurned ? 90 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
            .opacity(backTurned || diving ? 0 : 1)
            .offset(
                x: backPulled ? 0 : reservoirSlotX(originIndex),
                y: backPulled ? 0 : reservoirSlotY(originIndex, layout: layout)
            )
            .allowsHitTesting(false)
    }

    /// The landscape front — VaylCardFace with the first prompt, opening from
    /// edge-on into view, then diving into bare reading text exactly like
    /// SessionPlayerView.dealingCard/commitDeal (scale 1→3.4, opacity→0,
    /// blur→6, offset y→-20).
    private func dealtFrontCard(layout: AppLayout) -> some View {
        let w = AppLayout.sessionCardWidth(in: layout.screenWidth)
        let h = AppLayout.sessionCardHeight(in: layout.screenWidth)

        return VaylCardFace(question: firstPrompt)
            .frame(width: w, height: h)
            .rotation3DEffect(.degrees(frontOpened ? 0 : -90), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
            .shadow(color: AppColors.shadowDeep, radius: 24, y: 12)
            .scaleEffect(diving ? (motionDisabled ? 1 : 3.4) : 1)
            .opacity(diving ? 0 : 1)
            .blur(radius: diving && !motionDisabled ? 6 : 0)
            .offset(y: diving && !motionDisabled ? -20 : 0)
            .allowsHitTesting(false)
    }

    /// Copies SessionPlayerView.warpFlash exactly — a single spectrum rush on
    /// the dive, driven by the same warpProgress 0…1 shape.
    private var warpFlashView: some View {
        RadialGradient(
            colors: [AppColors.spectrumPurple.opacity(0.28),
                     AppColors.spectrumMagenta.opacity(0.08),
                     .clear],
            center: .center, startRadius: 0, endRadius: 320
        )
        .scaleEffect(0.4 + warpProgress * 1.8)
        .opacity(0.35 * Double(1 - warpProgress))
        .blendMode(.screen)
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    // MARK: - Reading text (bare styled text, not a card — matches SessionPlayerView.highlightedPrompt)

    private var readingTextView: some View {
        Text(firstPrompt)
            .font(AppFonts.display(26, weight: .medium, relativeTo: .title))
            .foregroundStyle(AppColors.textPrimary)
            .lineSpacing(AppSpacing.xs)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .opacity(textResolved ? 1 : 0)
            // Matches SessionPlayerView.screenLayer's block exactly (leading,
            // full-width, same bottom-biased centering) so the reading text
            // doesn't shift when the phase swaps to SessionPlayerView.
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.xl)
            // swiftlint:disable:next no_hardcoded_padding
            .padding(.bottom, 150)
            .frame(maxHeight: .infinity, alignment: .center)
    }

    // MARK: - Sequence

    @MainActor
    private func runSequence() async {
        let rm = motionDisabled

        // 1 — dealer copy: fade in, hold, fade out.
        withAnimation(rm ? AppAnimation.fast : AppAnimation.sessionIntroCopyFadeIn) { copyOpacity = 1 }
        try? await Task.sleep(for: .seconds(rm ? 0.45 : copyHoldSeconds))
        withAnimation(rm ? AppAnimation.fast : AppAnimation.sessionIntroCopyFadeOut) { copyOpacity = 0 }

        // 2 — bloom the reservoir, staggered per card. Skipped under reduce
        // motion / low power — the beat collapses straight to the deal.
        if !rm {
            for index in 0..<reservoirCount {
                let delay = Double(index) * bloomStaggerSeconds
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(delay))
                    withAnimation(AppAnimation.sessionIntroBloom) { reservoirVisible[index] = true }
                }
            }
            let bloomSpan = bloomStaggerSeconds * Double(reservoirCount - 1) + bloomDurationSeconds
            try? await Task.sleep(for: .seconds(bloomSpan))
            try? await Task.sleep(for: .seconds(settleSeconds))
        }

        // 3 — auto-deal: portrait back pulls to center and turns; the
        // landscape front opens into view. Under reduce motion / low power
        // the card lands instantly — motion stripped, mechanic kept.
        dealing = true
        if rm {
            backPulled = true
            backTurned = true
            frontOpened = true
        } else {
            withAnimation(AppAnimation.sessionIntroPull) { backPulled = true }
            try? await Task.sleep(for: .seconds(pullSeconds * flipStartRatio))
            withAnimation(AppAnimation.sessionIntroFlipBackTurn) { backTurned = true }
            try? await Task.sleep(for: .seconds(flipFrontDelay))
            withAnimation(AppAnimation.sessionIntroFlipFrontOpen) { frontOpened = true }
            try? await Task.sleep(for: .seconds(flipFrontOpenSeconds))
        }

        // 4 — card→text dive, matching SessionPlayerView.commitDeal exactly:
        // the card dives (sessionDiveIn), the warp blooms (sessionDiveOut),
        // and the reading text resolves underneath at 45% of the dive.
        withAnimation(rm ? AppAnimation.fast : AppAnimation.sessionDiveIn) { diving = true }
        if !rm {
            warpProgress = 0
            withAnimation(AppAnimation.sessionDiveOut) { warpProgress = 1 }
        }
        try? await Task.sleep(for: .seconds(rm ? 0.05 : diveSeconds * textHandoffRatio))
        withAnimation(rm ? AppAnimation.fast : AppAnimation.standard) { textResolved = true }
        try? await Task.sleep(for: .seconds(rm ? 0.15 : diveSeconds * (1 - textHandoffRatio)))

        onComplete()
    }
}

// MARK: - Preview

#Preview("Session Deal Intro") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat)
        SessionDealIntroView(
            dealerCopy: "the two of you open up about what pulled you together.",
            firstPrompt: "What are the anchors that have kept you two tethered to each other through everything so far?",
            onComplete: {}
        )
    }
    .preferredColorScheme(.dark)
}
