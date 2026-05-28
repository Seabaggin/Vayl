// Features/Onboarding/Phases/GenderPhase.swift
//
// Near-pure renderer. Owns no animation state.
// All visual state lives on VaylDirector.
//
// View contract:
//   .onAppear  → director.startGenderSequence(screenSize:)
//   .onDisappear → director.cancelGenderSequence()
//   Gestures    → director methods only (Segments 3+)
//
// Segment 1 — Card rises from table    ✓
//   Card materializes at center screen, rises from felt, bloom at base.
//   No SpriteKit. No slot pool. No flight.
//
// Segment 2 — Dealer line + auto flip  ✓
//   Dealer line fades in above card (200ms after settled).
//   Card flips via two-half scaleX sequence to reveal SlotMachineCardFace.
//   All autonomous — no user input.
//
// Segment 4 — Autonomous handle pull   ✓
//   300ms after genderBeatComplete, handle pulls down over 500ms (ease-out cubic).
//   Reels start spinning 100ms into the pull.
//
// Segment 5 — Reel spin                ✓
//   Reels spin during handle pull; continuous 300ms coast after pull completes.
//   genderReelOffsets drives SlotMachineCardFace.reelOffsets via overlay.
//
// Segment 6 — Staggered reel settle    ✓
//   Reels settle 80ms apart (reel 0 → 1 → 2); unsettled reels stay live.
//   Medium haptic fires per reel via .sensoryFeedback on genderActiveReel.
//   Active reel glow holds 400ms then clears.
//
// Segment 7 — Picker + reel sync       ✓
//   Dealer line fades out, picker fades in (AppAnimation.standard).
//   3-item drum wheel; options sourced from director.genderOptions only.
//   Drum scroll calls director.updateGenderDrum — reels sync at 0.68× ratio.
//   Drum settle calls director.settleGenderDrum — winning glow + 3× haptic.
//   Pronouns TextField fades in on genderDrumSettled.
//   Swipe-right confirms: .success haptic + director.confirmGenderSelection.
//
// Stub (not yet built):
//   ✗ Drag cue / tug hint
//   ✗ User-drag → flip + reel spin

import SwiftUI

struct GenderPhase: View {

    let director:   VaylDirector
    let screenSize: CGSize
    @Binding var tableRimBurst: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: — Drum gesture state (view-local; synced to director via updateGenderDrum / settleGenderDrum)

    @State private var drumBaseOffset:   CGFloat = 0   // settled strip offset; resets on picker appear
    @State private var drumDragOffset:   CGFloat = 0   // live delta during current drag
    @State private var confirmedTrigger: Bool    = false

    // MARK: — Dimensions (derived, not stored)

    private var cardWidth: CGFloat {
        AppLayout.obTableCardWidth(in: screenSize.width) * AppLayout.obTableCardCinematicScale
    }
    private var cardHeight: CGFloat {
        AppLayout.obTableCardHeight(in: screenSize.width) * AppLayout.obTableCardCinematicScale
    }

    // MARK: — Body

    var body: some View {
        ZStack {
            // Bloom behind card — Canvas drawn, zero hit-testing
            bloomLayer

            // Dealer line + card — both gated on genderCardVisible.
            // .transition(.opacity) lets withAnimation(cardPocket) in confirmGenderSelection
            // animate the removal using the active animation context.
            if director.genderCardVisible {
                dealerLineLayer
                    .transition(.opacity)
                cardLayer
                    .transition(.opacity)
            }

            // Picker — fades in after reel settle, driven by genderPickerVisible
            pickerLayer
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .sensoryFeedback(.impact(weight: .medium), trigger: director.genderActiveReel) { _, new in
            new != nil
        }
        .sensoryFeedback(.success, trigger: confirmedTrigger)
        .onAppear   { director.startGenderSequence(screenSize: screenSize, reduceMotion: reduceMotion) }
        .onDisappear { director.cancelGenderSequence() }
        .onChange(of: director.genderReelsSpinning) { _, spinning in
            guard !spinning else { return }
            // Reels stopped — snap drum strip to the autonomously settled index.
            withAnimation(AppAnimation.spring.reduceMotionSafe) {
                drumBaseOffset = drumInitialOffset - CGFloat(director.genderSelectedIndex) * drumItemH
                drumDragOffset = 0
            }
        }
        .onChange(of: director.genderShouldPocket) { _, pocket in
            // Director has animated card away (cardPocket ≈ 520ms).
            // Wait for the animation to complete then advance the phase.
            guard pocket else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(550))
                director.advance(to: .experienceLevel)
            }
        }
    }

    // MARK: — Dealer Line

    /// Copy sourced from director.genderDealerLine — no raw strings in View.
    /// Positioned above the card top edge by AppSpacing.xl.
    /// Opacity is driven by director.genderDealerLineVisible via the director's
    /// withAnimation(AppAnimation.textProject) — no explicit animation modifier needed here.
    private var dealerLineLayer: some View {
        Text(director.genderDealerLine)
            .font(AppFonts.prompt)
            .foregroundStyle(AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppSpacing.xl)
            .opacity(director.genderDealerLineVisible ? 1.0 : 0.0)
            .offset(y: director.genderCardOffset.height - cardHeight / 2 - AppSpacing.xl)
            .allowsHitTesting(false)
    }

    // MARK: — Bloom

    /// Dimensional disturbance — radiates from card center as topo lines flow around it.
    /// Driven by director.dissolutionFlowOut — peaks as the card boundary becomes real.
    private var bloomLayer: some View {
        Canvas { context, size in
            let opacity = director.dissolutionFlowOut
            guard opacity > 0 else { return }

            let cardCenterY = size.height * AppLayout.obGenderCardRestYFrac
            let bloomR      = cardWidth  * 0.85
            let center      = CGPoint(x: size.width / 2, y: cardCenterY)

            context.fill(
                Path(ellipseIn: CGRect(
                    x: center.x - bloomR,
                    y: center.y - bloomR,
                    width:  bloomR * 2,
                    height: bloomR * 2
                )),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: AppColors.spectrumCyan.opacity(0.18 * opacity),   location: 0.0),
                        .init(color: AppColors.spectrumPurple.opacity(0.12 * opacity),  location: 0.45),
                        .init(color: .clear,                                             location: 1.0),
                    ]),
                    center:      center,
                    startRadius: 0,
                    endRadius:   bloomR
                )
            )
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    // MARK: — Card

    /// Crystallisation layer stack.
    ///
    /// Layer 1 (felt): visible only early — card is indistinguishable from the table.
    /// Layer 2 (void): card's own surface colour, emerges as sharpness rises.
    /// Layer 3 (back/face): full card content, fades in with density × sharp.
    ///
    /// Blur on the whole stack starts at 28 (felt-level) and clears as the card sharpens.
    /// No `.drawingGroup()` on the outer ZStack — VaylCardBack/Face each rasterise themselves.
    private var cardLayer: some View {
        let density = director.dissolutionDensity
        let sharp   = director.dissolutionSharp

        // 28 — Rendering constant. Felt-level blur at sharp=0; 0 when fully crystallised.
        let blur = CGFloat(28.0 * (1.0 - sharp))

        return ZStack {

            // ── Layer 1: felt-matched mass ──────────────────────────────────────
            // Opaque at density=1/sharp=0; invisible once sharp rises.
            // tableFeltCore is the TableSurfaceView gradient's centre stop —
            // visually identical to the felt at the card's screen position.
            RoundedRectangle(cornerRadius: AppRadius.obCard)
                .fill(AppColors.tableFeltCore)
                .opacity(density * (1 - sharp))

            // ── Layer 2: card void fill ─────────────────────────────────────────
            // The card's own background colour, rising as sharpness increases.
            RoundedRectangle(cornerRadius: AppRadius.obCard)
                .fill(AppColors.cardBg)
                .opacity(density * sharp)

            // ── Layer 3: card face / back ───────────────────────────────────────
            // Conditional flip handled here — flip logic driven by director.
            if !director.genderCardFaceUp {
                // hex and wordmark params wire into VaylCardBack — defaults preserve
                // existing behaviour at dissolution=1.0 (angle=8°, spacing=1.0, mark=1.0).
                VaylCardBack(
                    hexAngleOverride: CGFloat(director.dissolutionHexAngle),
                    hexSpacingMul:    CGFloat(director.dissolutionHexSpacing),
                    wordmarkOpacity:  director.dissolutionMark
                )
                .opacity(density * sharp)
            } else {
                // VaylCardFace() provides the card shell (cardBg, atmosphere, border,
                // hairlines). SlotMachineCardFace is overlaid with the animated
                // handleOffset so the director can drive it without touching VaylCardContent.
                VaylCardFace()
                    .overlay(
                        SlotMachineCardFace(
                            cardWidth:      cardWidth,
                            cardHeight:     cardHeight,
                            handleOffset:   director.genderHandleOffset,
                            reelOffsets:    director.genderReelOffsets,
                            settledSymbols: director.genderSettledSymbols,
                            activeReel:     director.genderActiveReel
                        )
                    )
                    .opacity(density * sharp)
            }
        }
        .blur(radius: blur)
        .frame(width: cardWidth, height: cardHeight)
        .scaleEffect(x: director.genderCardFlipScaleX, y: 1.0)
        .offset(director.genderCardOffset)
    }

    // MARK: — Picker

    // Drum slot height. 3-item window keeps the picker short so it clears the
    // card base (card ≈ 263pt tall, centred at 52% screen — leaves ~280pt below).
    private let drumItemH:   CGFloat = 48
    private var drumWindowH: CGFloat { drumItemH * 3 }

    /// Strip offset that centres item 0 in the 3-item window.
    /// Formula: (n-1)/2 items of padding above item 0 when n is odd.
    private var drumInitialOffset: CGFloat {
        CGFloat((director.genderOptions.count - 1) / 2) * drumItemH
    }

    /// Scroll position passed to the director (0 = first item, grows as user scrolls forward).
    private var drumScrollPosition: CGFloat {
        drumInitialOffset - drumBaseOffset - drumDragOffset
    }

    /// Index of the option currently closest to the selection band.
    /// During spin: derived from genderDrumOffset so highlight tracks reel motion.
    /// During drag / settled: derived from drumBaseOffset + drumDragOffset.
    private var currentCenteredIndex: Int {
        let n = director.genderOptions.count
        guard n > 0 else { return 0 }
        if director.genderReelsSpinning {
            let cycle = CGFloat(n) * drumItemH
            let norm  = director.genderDrumOffset.truncatingRemainder(dividingBy: cycle)
            return max(0, min(n - 1, Int(norm / drumItemH) % n))
        }
        let raw = (drumInitialOffset - drumBaseOffset - drumDragOffset) / drumItemH
        return max(0, min(n - 1, Int(raw.rounded())))
    }

    /// Y-offset from ZStack centre to the drum centre.
    /// Positions the drum in the open space between the card top and the screen top.
    private var pickerOffsetY: CGFloat {
        director.genderCardOffset.height - cardHeight / 2 - AppSpacing.xxl - drumWindowH / 2
    }

    /// Strip Y-offset — reel-driven during autonomous spin; user/gesture-driven after settle.
    ///
    /// During spin: wraps genderDrumOffset into [0, cycle) and inverts it so the strip
    /// scrolls in the same visual direction as the reel symbols.
    /// After settle or during user drag: standard drumBaseOffset + drumDragOffset.
    private var drumStripOffset: CGFloat {
        guard director.genderReelsSpinning else {
            return drumBaseOffset + drumDragOffset
        }
        let cycle = CGFloat(director.genderOptions.count) * drumItemH
        guard cycle > 0 else { return drumBaseOffset + drumDragOffset }
        let norm = director.genderDrumOffset.truncatingRemainder(dividingBy: cycle)
        return drumInitialOffset - norm
    }

    // MARK: — Picker layer

    private var pickerLayer: some View {
        Group {
            if director.genderPickerVisible {
                drumPickerView
                    .onAppear { drumBaseOffset = drumInitialOffset }
                    .transition(.opacity.animation(AppAnimation.standard.reduceMotionSafe))
            }
        }
        .offset(y: pickerOffsetY)
        .allowsHitTesting(director.genderPickerVisible)
    }

    // MARK: — Drum

    /// 3-item scrollable drum showing genderOptions from the director.
    /// Gradient mask fades options that scroll toward the window edges.
    /// drumGesture lives on the container so the full frame area receives touches —
    /// the inner strip VStack does not have a gesture to avoid any conflict.
    private var drumPickerView: some View {
        ZStack {
            // Full-frame touch target — transparent but receives all touches in the window
            Color.clear

            // Options strip — visual only, no gesture
            VStack(spacing: 0) {
                ForEach(Array(director.genderOptions.enumerated()), id: \.offset) { idx, option in
                    Text(option)
                        .font(AppFonts.prompt)
                        .foregroundStyle(
                            idx == currentCenteredIndex
                                ? AppColors.textPrimary
                                : AppColors.textSecondary
                        )
                        .frame(height: drumItemH)
                }
            }
            .offset(y: drumStripOffset)
            .allowsHitTesting(false)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.00),
                        .init(color: .black, location: 0.28),
                        .init(color: .black, location: 0.72),
                        .init(color: .clear, location: 1.00),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )

            // Selection band — two hairlines bounding the centre slot; outside mask
            VStack(spacing: drumItemH - 1) {
                Rectangle()
                    .fill(AppColors.spectrumBorder)
                    .frame(height: 0.5)
                Rectangle()
                    .fill(AppColors.spectrumBorder)
                    .frame(height: 0.5)
            }
            .frame(height: drumItemH)
            .allowsHitTesting(false)
        }
        .frame(width: screenSize.width * 0.62, height: drumWindowH)
        .contentShape(Rectangle())    // full frame receives touches (not just text bounds)
        .clipped()
        .gesture(drumGesture)         // on container, not strip — no gesture conflict
    }

    private var drumGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                drumDragOffset = value.translation.height
                director.updateGenderDrum(offset: drumScrollPosition)
            }
            .onEnded { value in
                let n = director.genderOptions.count
                guard n > 0 else { return }
                let raw      = (drumInitialOffset - drumBaseOffset - drumDragOffset) / drumItemH
                let snapped  = max(0, min(n - 1, Int(raw.rounded())))
                let newBase  = drumInitialOffset - CGFloat(snapped) * drumItemH

                withAnimation(AppAnimation.spring.reduceMotionSafe) {
                    drumBaseOffset = newBase
                    drumDragOffset = 0
                }
                director.settleGenderDrum(index: snapped)
            }
    }

}
