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
//   (Pronouns removed — not needed for Vayl's use case.)
//
// Stub (not yet built):
//   ✓ Card swipe-right confirm + intermittent swipe-hint flick (starts after user settles drum)
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
    @State private var confirmedTrigger:      Bool                    = false
    @State private var hintOffset:            CGFloat                 = 0    // live y-offset for the swipe-hint flick (negative = upward)
    @State private var hintTask:              Task<Void, Never>?      = nil  // intermittent flick loop; cancelled on grab / re-scroll
    @State private var lastCenteredIndex:     Int                     = 0    // tracks previous item for selection haptic
    @State private var drumHapticGen:         UISelectionFeedbackGenerator = UISelectionFeedbackGenerator()

    // MARK: — Dimensions (derived, not stored)

    private var cardWidth: CGFloat {
        AppLayout.obTableCardWidth(in: screenSize.width) * AppLayout.obTableCardCinematicScale
    }
    private var cardHeight: CGFloat {
        AppLayout.obTableCardHeight(in: screenSize.width) * AppLayout.obTableCardCinematicScale
    }

    // Swipe-hint flick distance — proportional to card height so it scales across devices.
    // -0.10 ≈ a confident upward throw that clearly reads "swipe up," not a twitch.
    // Negative = upward in SwiftUI coordinate space.
    // Felt value — verify the travel on device.
    private var hintFlickY: CGFloat { -cardHeight * 0.10 }

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
        .sensoryFeedback(.success, trigger: confirmedTrigger)
        .onAppear   { director.startGenderSequence(screenSize: screenSize, reduceMotion: reduceMotion) }
        .onDisappear { director.cancelGenderSequence() }
        .onChange(of: director.genderPickerVisible) { _, visible in
            guard visible else { return }
            // Picker appeared — snap drum strip to index 0 (no autonomous spin to sync from).
            withAnimation(AppAnimation.spring.reduceMotionSafe) {
                drumBaseOffset = drumInitialOffset
                drumDragOffset = 0
            }
            lastCenteredIndex = 0
        }
        .onChange(of: director.genderShouldPocket) { _, pocket in
            // Director has animated card away (cardPocket ≈ 520ms).
            // Wait for the animation to complete then advance the phase.
            // 600ms = 520ms animation + 80ms buffer for frame jitter on slower devices.
            guard pocket else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(600))
                director.advance(to: .experienceLevel)
            }
        }
        .onChange(of: director.genderSwipeHintActive) { _, active in
            hintTask?.cancel()
            guard active, !reduceMotion else {
                // Stopped (user grabbed the card or re-scrolled the drum) — settle back to rest Y.
                withAnimation(AppAnimation.spring.reduceMotionSafe) { hintOffset = 0 }
                return
            }
            // Intermittent swipe demo: flick right → spring home → pause → repeat.
            // Cadence lives in Task.sleep (not animation tokens) per the codebase pattern.
            hintTask = Task { @MainActor in
                // Beat after the drum-settle haptics before the first flick.
                try? await Task.sleep(for: .milliseconds(600))
                while !Task.isCancelled {
                    withAnimation(AppAnimation.swipeHintFlick) { hintOffset = hintFlickY }
                    try? await Task.sleep(for: .milliseconds(380))   // 260ms flick + 120ms peak hold
                    guard !Task.isCancelled else { break }
                    withAnimation(AppAnimation.spring) { hintOffset = 0 }
                    try? await Task.sleep(for: .milliseconds(1900))  // ~500ms settle + ~1.4s rest
                    guard !Task.isCancelled else { break }
                }
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
                // Task 6 will overlay RadioTunerCardFace here.
                // Plain VaylCardFace shell compiles Task 5 cleanly.
                VaylCardFace()
                    .opacity(density * sharp)
            }
        }
        .blur(radius: blur)
        .frame(width: cardWidth, height: cardHeight)
        .scaleEffect(x: director.genderCardFlipScaleX, y: 1.0)
        .gesture(
            DragGesture(minimumDistance: 30)
                .onChanged { _ in
                    // User has grabbed the card — kill the swipe hint immediately.
                    guard director.genderPickerVisible else { return }
                    director.endGenderSwipeHint()
                }
                .onEnded { value in
                    // Only active after picker is visible (power-on beat complete).
                    guard director.genderPickerVisible else { return }
                    // Require an upward swipe (negative height) with limited horizontal drift.
                    guard value.translation.height < -55  else { return }
                    guard abs(value.translation.width) < 80 else { return }
                    confirmedTrigger.toggle()   // triggers .sensoryFeedback(.success) in body
                    director.confirmGenderSelection(pronouns: nil)
                }
        )
        // Swipe-hint flick — pure rightward translation (no tilt) that intermittently
        // throws the card right and springs it home, demonstrating the swipe gesture.
        // hintOffset is driven by the intermittent loop in .onChange(genderSwipeHintActive).
        .offset(director.genderCardOffset)
        .offset(y: hintOffset)
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
    /// Derived from drumBaseOffset + drumDragOffset (no autonomous spin to track).
    private var currentCenteredIndex: Int {
        let n = director.genderOptions.count
        guard n > 0 else { return 0 }
        let raw = (drumInitialOffset - drumBaseOffset - drumDragOffset) / drumItemH
        return max(0, min(n - 1, Int(raw.rounded())))
    }

    /// Y-offset from ZStack centre to the drum centre.
    /// Positions the drum in the open space between the card top and the screen top.
    private var pickerOffsetY: CGFloat {
        director.genderCardOffset.height - cardHeight / 2 - AppSpacing.xxl - drumWindowH / 2
    }

    /// Strip Y-offset — user/gesture-driven via drumBaseOffset + drumDragOffset.
    private var drumStripOffset: CGFloat {
        drumBaseOffset + drumDragOffset
    }

    // MARK: — Picker layer

    private var pickerLayer: some View {
        Group {
            if director.genderPickerVisible {
                drumPickerView
                    .onAppear {
                        drumBaseOffset = drumInitialOffset
                        // Pre-warm the Taptic Engine so first drum tick fires without latency.
                        drumHapticGen.prepare()
                    }
                    // Plain .opacity transition — the fade is driven solely by the
                    // withAnimation(.standard) that flips genderPickerVisible in the director.
                    // A transition-local .animation() here double-drives the insert and pops
                    // the picker to full opacity for one frame. Single animation source = no flash.
                    .transition(.opacity)
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
                        .font(idx == currentCenteredIndex
                            ? AppFonts.prompt.weight(.semibold)
                            : AppFonts.prompt)
                        .foregroundStyle(
                            idx == currentCenteredIndex
                                ? AppColors.textPrimary
                                : AppColors.textSecondary
                        )
                        .frame(height: drumItemH)
                        .animation(.none, value: currentCenteredIndex)
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
                // User is re-engaging the drum — pause the swipe hint until they settle again.
                director.endGenderSwipeHint()
                drumDragOffset = value.translation.height
                let nowIdx = currentCenteredIndex
                if nowIdx != lastCenteredIndex {
                    lastCenteredIndex = nowIdx
                    drumHapticGen.selectionChanged()
                }
                director.updateGenderDrum(offset: drumScrollPosition)
            }
            .onEnded { value in
                let n = director.genderOptions.count
                guard n > 0 else { return }
                // predictedEndTranslation extrapolates natural deceleration (iOS 16+).
                // Using it instead of raw translation gives the drum momentum when flicked.
                let raw      = (drumInitialOffset - drumBaseOffset - value.predictedEndTranslation.height) / drumItemH
                let snapped  = max(0, min(n - 1, Int(raw.rounded())))
                let newBase  = drumInitialOffset - CGFloat(snapped) * drumItemH

                withAnimation(AppAnimation.spring.reduceMotionSafe) {
                    drumBaseOffset = newBase
                    drumDragOffset = 0
                }
                lastCenteredIndex = snapped   // keep haptic tracking in sync after snap
                director.settleGenderDrum(index: snapped)
                // User has actively chosen a gender — they've earned the swipe prompt.
                director.beginGenderSwipeHint()
            }
    }

}
