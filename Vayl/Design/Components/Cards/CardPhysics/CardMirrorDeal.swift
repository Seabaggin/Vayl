//
//  CardMirrorDeal.swift
//  Vayl
//
//  Design/Components/CardPhysics/CardMirrorDeal.swift
//
//  Mirror deal physics for ModeSelectPhase.
//  Two cards travel from opposite sides simultaneously and land at the same moment.
//  One lifts on tap. Swipe up confirms. Unchosen card flips face-down and exits
//  back toward its origin.
//
//  Caller owns: card content, phase advancement, speech bubble.
//  This file owns: deal animation, lift, confirm, reject.
//

import SwiftUI

public enum MirrorDealState: Equatable {
    case idle
    case dealing
    case resting
    case faceUp
    case lifted(card: MirrorCard)
    case confirming(card: MirrorCard)
    case exiting(confirmed: MirrorCard)
    case done(selected: MirrorCard)
}

public enum MirrorCard: Equatable {
    case left   // Solo Discovery
    case right  // Together
}

@Observable
@MainActor
public final class CardMirrorDealController {

    // ── State ──────────────────────────────────────────────────────
    public var state: MirrorDealState = .idle

    // ── Card transforms ────────────────────────────────────────────
    public var leftOffset:  CGSize = .zero
    public var rightOffset: CGSize = .zero
    public var leftAngle:   Double = 0
    public var rightAngle:  Double = 0
    public var leftScale:   Double = 1.0
    public var rightScale:  Double = 1.0
    public var leftAlpha:   Double = 0
    public var rightAlpha:  Double = 0

    // ── Deal flip state ────────────────────────────────────────────
    public var leftFlipScaleX:  Double = 1.0
    public var rightFlipScaleX: Double = 1.0
    public var leftShowFace:    Bool   = false
    public var rightShowFace:   Bool   = false

    // ── Reject flip state ──────────────────────────────────────────
    public var rejectedFlipScaleX: Double = 1.0
    public var rejectedShowBack:   Bool   = false
    public var rejectedExitAlpha:  Double = 1.0

    // ── Haptic triggers — observed by ModeSelectPhase .sensoryFeedback ─
    public var confirmHapticTrigger: Bool = false

    // ── Resting geometry — stored in deal(), read in lift()/switchLift() ─
    private var restXL:          CGFloat = 0
    private var restXR:          CGFloat = 0
    private var restY:           CGFloat = 0
    private var cardWidth:       CGFloat = 0   // kept for legacy refs
    private var storedCardWidth: CGFloat = 0
    private var liftTargetY:     CGFloat = 0

    // ── Tasks ──────────────────────────────────────────────────────
    private var dealTask:    Task<Void, Never>? = nil
    private var confirmTask: Task<Void, Never>? = nil

    // MARK: — Deal

    /// Fire the mirror deal.
    /// Both cards travel simultaneously from opposite screen edges.
    /// Left card: from x = -(screenWidth * 0.65 + cardWidth / 2), angle -18°
    /// Right card: from x = +(screenWidth * 0.65 + cardWidth / 2), angle +18°
    /// Both animate to resting positions at the same time — no stagger.
    /// Landing haptics: left tap then right tap 80ms apart.
    public func deal(screenSize: CGSize, cardWidth: CGFloat,
                     onFaceUp: (() -> Void)? = nil) {
        guard state == .idle else { return }
        state = .dealing

        dealTask = Task { @MainActor in
            let tableY   = AppLayout.obTableCardCenterY(in: screenSize.height)
            let restY    = tableY - screenSize.height / 2
            let restXL   = -(cardWidth * 0.55)
            let restXR   =  (cardWidth * 0.55)
            self.restY          = restY
            self.restXL         = restXL
            self.restXR         = restXR
            self.cardWidth      = cardWidth
            self.storedCardWidth = cardWidth
            self.liftTargetY    = screenSize.height * 0.42 - screenSize.height / 2
            let originXL = -(screenSize.width * 0.65 + cardWidth / 2)
            let originXR =  (screenSize.width * 0.65 + cardWidth / 2)

            // Snap to start positions — both invisible off-screen
            leftOffset  = CGSize(width: originXL, height: restY)
            rightOffset = CGSize(width: originXR, height: restY)
            leftAngle   = -22
            rightAngle  =  22
            leftAlpha   = 1
            rightAlpha  = 1

            try? await Task.sleep(for: .milliseconds(16))
            guard !Task.isCancelled else { return }

            // Both cards travel simultaneously — weighted deceleration
            withAnimation(AppAnimation.mirrorDealTravel) {
                leftOffset  = CGSize(width: restXL, height: restY)
                rightOffset = CGSize(width: restXR, height: restY)
                leftAngle   = -14
                rightAngle  =  14
            }

            // Travel ends at 16+880ms — the tick must land WITH the visual
            // stop, not 100ms ahead of it (the hand felt it before the eye).
            try? await Task.sleep(for: .milliseconds(896))
            guard !Task.isCancelled else { return }

            // Landing haptics — both cards land at same moment, 80ms stagger
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            try? await Task.sleep(for: .milliseconds(80))
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            state = .resting

            // Settle after landing
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }

            // Left card flips face-up. The face swap waits the FULL half-flip
            // (290ms = cardFlipHalf) so it happens edge-on at scaleX = 0 —
            // swapping earlier popped the face in at ~25% width and retargeted
            // the in-flight first half.
            withAnimation(AppAnimation.cardFlipHalf) { leftFlipScaleX = 0.0 }
            try? await Task.sleep(for: .milliseconds(290))
            leftShowFace = true
            withAnimation(AppAnimation.cardFlipHalf) { leftFlipScaleX = 1.0 }

            // Right card flips 120ms after left
            try? await Task.sleep(for: .milliseconds(120))
            withAnimation(AppAnimation.cardFlipHalf) { rightFlipScaleX = 0.0 }
            try? await Task.sleep(for: .milliseconds(290))
            rightShowFace = true
            withAnimation(AppAnimation.cardFlipHalf) { rightFlipScaleX = 1.0 }

            try? await Task.sleep(for: .milliseconds(290))
            state = .faceUp
            onFaceUp?()
        }
    }

    // MARK: — Lift

    /// Lift a card.
    /// Animation is owned by the caller (ModeSelectPhase.handleAction) via
    /// withAnimation — keeping animation context at the View layer ensures
    /// @Observable property changes are correctly captured by SwiftUI.
    public func lift(card: MirrorCard) {
        guard state == .faceUp || state == .resting || {
            if case .lifted(_) = state { return true }
            return false
        }() else { return }

        state = .lifted(card: card)
        switch card {
        case .left:
            leftOffset.width   = 0
            leftOffset.height  = liftTargetY
            leftAngle          = 0
            leftScale          = 1.08
            leftAlpha          = 1.0
            rightOffset.width  = restXR + storedCardWidth * 0.10
            rightOffset.height = restY
            rightAngle         = 18
            rightScale         = 0.92
            rightAlpha         = 0.30
        case .right:
            rightOffset.width  = 0
            rightOffset.height = liftTargetY
            rightAngle         = 0
            rightScale         = 1.08
            rightAlpha         = 1.0
            leftOffset.width   = restXL - storedCardWidth * 0.10
            leftOffset.height  = restY
            leftAngle          = -18
            leftScale          = 0.92
            leftAlpha          = 0.30
        }
    }

    /// Switch lift to the other card without returning to resting.
    /// All positions are absolute — no accumulated deltas.
    /// Animation owned by caller (ModeSelectPhase) via withAnimation.
    public func switchLift(to card: MirrorCard) {
        state = .lifted(card: card)
        switch card {
        case .left:
            leftOffset.width   = 0
            leftOffset.height  = liftTargetY
            leftAngle          = 0
            leftScale          = 1.08
            leftAlpha          = 1.0
            rightOffset.width  = restXR + storedCardWidth * 0.10
            rightOffset.height = restY
            rightAngle         = 18
            rightScale         = 0.92
            rightAlpha         = 0.30
        case .right:
            rightOffset.width  = 0
            rightOffset.height = liftTargetY
            rightAngle         = 0
            rightScale         = 1.08
            rightAlpha         = 1.0
            leftOffset.width   = restXL - storedCardWidth * 0.10
            leftOffset.height  = restY
            leftAngle          = -18
            leftScale          = 0.92
            leftAlpha          = 0.30
        }
    }

    // MARK: — Confirm

    /// Swipe up confirmed on the lifted card.
    ///
    /// Sequence:
    ///   1. Border charges       — ~220ms
    ///   2. Confirmed card pockets to corner deck (cardPocket = 520ms), concurrent with:
    ///   3. Rejected card flips face-down (80+220+220ms)
    ///   4. `onLanded` fires at t≈740ms — confirmed card has visually arrived at corner
    ///   5. Rejected card slides back to origin (420ms)
    ///   6. `onConfirm` fires at t≈1160ms
    ///
    /// `onLanded` is the right place to update the corner deck model and pulse.
    /// `onConfirm` is the right place to advance the phase.
    public func confirm(
        card:       MirrorCard,
        screenSize: CGSize,
        cardWidth:  CGFloat,
        onLanded:   ((MirrorCard) -> Void)? = nil,
        onConfirm:  @escaping (MirrorCard) -> Void
    ) {
        guard case .lifted(let liftedCard) = state, liftedCard == card else { return }
        state = .confirming(card: card)

        confirmTask = Task { @MainActor in
            // Confirm responds AT release — the swipe's own momentum is the
            // anticipation. (A 220ms held-breath sleep lived here as residue of
            // the removed border-charge animation; it rendered as input lag.)
            // Downstream: onLanded fires at ~520ms, onConfirm at ~940ms.
            confirmHapticTrigger.toggle()
            state = .exiting(confirmed: card)

            // 2. Confirmed card pockets to corner deck — AppAnimation.cardPocket (520ms).
            // Corner deck lives at the top-right; we compute its centre in offset space
            // (offsets are relative to the view's own centre, not screen origin).
            let cornerX     = screenSize.width  - AppLayout.cornerDeckRight - AppLayout.cornerDeckWidth  / 2
            let cornerY     = AppLayout.cornerDeckTop + AppLayout.cornerDeckHeight / 2
            let pocketOffW  = cornerX - screenSize.width  / 2
            let pocketOffH  = cornerY - screenSize.height / 2
            // Scale the card down to corner-deck miniature size.
            let pocketScale = AppLayout.cornerDeckWidth / cardWidth

            withAnimation(AppAnimation.cardPocket) {
                switch card {
                case .left:
                    leftOffset = CGSize(width: pocketOffW, height: pocketOffH)
                    leftScale  = pocketScale
                    leftAlpha  = 0
                case .right:
                    rightOffset = CGSize(width: pocketOffW, height: pocketOffH)
                    rightScale  = pocketScale
                    rightAlpha  = 0
                }
            }

            // 3a. Rejected flip — first half: scaleX 1→0 (starts 80ms into confirmed flight)
            try? await Task.sleep(for: .milliseconds(80))
            guard !Task.isCancelled else { return }

            withAnimation(AppAnimation.mirrorRejectFlipHalf) {
                rejectedFlipScaleX = 0
            }

            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }

            // 3b. Show card back, complete flip: scaleX 0→1
            rejectedShowBack = true
            withAnimation(AppAnimation.mirrorRejectFlipHalf) {
                rejectedFlipScaleX = 1
            }

            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }

            // ── t ≈ 740ms ────────────────────────────────────────────────────────
            // cardPocket (520ms) started at t=220ms → confirmed card arrives at t=740ms.
            // Rejected flip also finishes here (80+220+220=520ms after flight start).
            // Fire onLanded so the caller can update the corner deck model now.
            onLanded?(card)

            // 3c. Slide rejected card back toward origin with fade (420ms)
            let originXL = -(screenSize.width * 0.65 + cardWidth / 2 + 40)
            let originXR =  (screenSize.width * 0.65 + cardWidth / 2 + 40)

            withAnimation(AppAnimation.mirrorRejectExit) {
                switch card {
                case .left:  // rejected is right
                    rightOffset.width = originXR
                    rightAngle        = 18
                    rejectedExitAlpha = 0
                case .right: // rejected is left
                    leftOffset.width  = originXL
                    leftAngle         = -18
                    rejectedExitAlpha = 0
                }
            }

            try? await Task.sleep(for: .milliseconds(420))
            guard !Task.isCancelled else { return }

            // ── t ≈ 1160ms ───────────────────────────────────────────────────────
            state = .done(selected: card)
            onConfirm(card)
        }
    }

    // MARK: — Cleanup

    public func cancel() {
        dealTask?.cancel()
        confirmTask?.cancel()
    }
}
