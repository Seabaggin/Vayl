// Features/Onboarding/Phases/GenderPhase.swift
//
// Near-pure renderer. Owns no animation state.
// All visual state lives on VaylDirector.
//
// View contract:
//   .onAppear  → director.gender.startSequence(screenSize:)
//   .onDisappear → director.gender.cancelSequence()
//
// Segment 1 — Card crystallises out of the felt; dealer line types DURING
//             formation (canvas-projected — one dealer voice for all phases)
// Segment 2 — Auto flip → RadioTunerCardFace revealed → drum pickers appear
// Segment 3 — User tunes left drum (gender) + right drum (pronouns).
//             Dials on card face track progress in real time. Defaults are a
//             valid selection — nothing is gated on drum interaction.
//             Both drums settled on a choice: signal locks + "lined up" thud.
// Segment 4 — Tap card to lift (LiftHalo, drums fade) → swipe up to confirm →
//             card flies to the corner deck → .experienceLevel.
//             Tap the lifted card again to set it down and keep tuning.

import SwiftUI

struct GenderPhase: View {

    let director: VaylDirector
    let screenSize: CGSize
    @Binding var tableRimBurst: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: — Drum gesture state (view-local; synced to director via updateGenderDrum / settleGenderDrum)

    @State private var drumBaseOffset: CGFloat = 0   // settled strip offset; resets on picker appear
    @State private var drumDragOffset: CGFloat = 0   // live delta during current drag
    @State private var confirmedTrigger: Bool                    = false
    @State private var liftHaptic: Bool                    = false  // .selection on lift/lower, sibling parity
    @State private var hintOffset: CGFloat                 = 0    // live y-offset for the swipe-hint flick (negative = upward)
    @State private var hintTask: Task<Void, Never>?  // intermittent flick loop; cancelled on grab / re-scroll
    @State private var declinePressed: Bool                    = false  // press-scale for the shared decline bar
    @State private var lastCenteredIndex: Int                     = 0    // tracks previous item for selection haptic
    @State private var drumHapticGen: UISelectionFeedbackGenerator = UISelectionFeedbackGenerator()

    // Pronouns drum state (mirrors gender drum)
    @State private var pronounsBaseOffset: CGFloat = 0
    @State private var pronounsDragOffset: CGFloat = 0
    @State private var pronounsLastCentered: Int     = 0
    @State private var pronounsHapticGen: UISelectionFeedbackGenerator = UISelectionFeedbackGenerator()

    // Live hand-off follow (Phase 4): the lifted card tracks the finger as it's handed up
    // (shared HandBackFollow — weighty, banded, can't fly off). View-local; the sequencer
    // owns cardOffset, so this resolves to .zero inside the pocket flight on confirm.
    @State private var handBackDrag: CGSize = .zero
    @State private var handBackArmed: Bool   = false   // past the commit threshold → selection tick

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

            // Card — gated on genderCardVisible. The dealer line is canvas-projected
            // (ProjectedTextView via the stage) — no phase-local dealer text.
            if director.gender.cardVisible {
                cardLayer
                    .transition(.opacity)
            }

            // Picker — fades in after power-on beat, driven by genderPickerVisible
            pickerLayer
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .sensoryFeedback(.success, trigger: confirmedTrigger)
        .sensoryFeedback(.selection, trigger: liftHaptic)
        .sensoryFeedback(.impact(weight: .medium), trigger: director.gender.lockThudTrigger)
        .onAppear { director.gender.startSequence(screenSize: screenSize, reduceMotion: reduceMotion) }
        .onDisappear { director.gender.cancelSequence() }
        .onChange(of: director.gender.shouldPocket) { _, pocket in
            // Card is flying to the corner deck (cardPocket ≈ 520ms). Credit the
            // deck as it lands — the pulse is the arrival, not a forecast of it.
            guard pocket else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(480))
                director.receiveCredential(.gender)
                try? await Task.sleep(for: .milliseconds(270))
                // Heal the felt — the card has landed in the deck, so the
                // dissolution flow-around must stop deflecting the topo lines
                // before the table carries into ExperienceLevel. (Reset under the
                // advance cross-fade; if it reads abrupt on device, tick it down.)
                director.gender.resetDissolution()
                director.advance(to: .experienceLevel)
            }
        }
        .onChange(of: director.gender.swipeHintActive) { _, active in
            hintTask?.cancel()
            guard active, !reduceMotion else {
                // Stopped (user grabbed the card or re-scrolled the drum) — settle back to rest Y.
                withAnimation(AppAnimation.spring.reduceMotionSafe) { hintOffset = 0 }
                return
            }
            // Intermittent swipe demo: flick up → spring home → pause → repeat.
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

    // MARK: — Bloom

    /// Dimensional disturbance — radiates from card center as topo lines flow around it.
    /// Driven by director.gender.dissolutionFlowOut — peaks as the card boundary becomes real.
    private var bloomLayer: some View {
        Canvas { context, size in
            let opacity = director.gender.dissolutionFlowOut
            guard opacity > 0 else { return }

            let cardCenterY = size.height * AppLayout.obGenderCardRestYFrac
            let bloomR      = cardWidth  * 0.85
            let center      = CGPoint(x: size.width / 2, y: cardCenterY)

            context.fill(
                Path(ellipseIn: CGRect(
                    x: center.x - bloomR,
                    y: center.y - bloomR,
                    width: bloomR * 2,
                    height: bloomR * 2
                )),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: AppColors.spectrumCyan.opacity(0.18 * opacity), location: 0.0),
                        .init(color: AppColors.spectrumPurple.opacity(0.12 * opacity), location: 0.45),
                        .init(color: .clear, location: 1.0)
                    ]),
                    center: center,
                    startRadius: 0,
                    endRadius: bloomR
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
        let density = director.gender.dissolutionDensity
        let sharp   = director.gender.dissolutionSharp

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
            // Both faces stay mounted (pre-warm) so RadioTunerCardFace doesn't cold-render
            // at the flip pivot — swapped by the dissolution opacity × a face-up factor.
            // hex/wordmark params preserve existing back behaviour at dissolution=1.0.
            VaylCardBack(
                hexAngleOverride: CGFloat(director.gender.dissolutionHexAngle),
                hexSpacingMul: CGFloat(director.gender.dissolutionHexSpacing),
                wordmarkOpacity: director.gender.dissolutionMark
            )
            .opacity(density * sharp * (director.gender.cardFaceUp ? 0 : 1))
            VaylCardFace()
                .overlay(
                    RadioTunerCardFace(
                        cardWidth: cardWidth,
                        cardHeight: cardHeight,
                        signalStrength: director.gender.signalStrength,
                        scanPhase: Double(drumBaseOffset + drumDragOffset
                                                + pronounsBaseOffset + pronounsDragOffset),
                        leftDialProgress: director.gender.drumSettled
                            ? Double(director.gender.selectedIndex) / Double(max(1, director.gender.options.count - 1))
                            : 0,
                        rightDialProgress: director.gender.pronounsDrumSettled
                            ? Double(director.gender.pronounsSelectedIndex) / Double(max(1, director.gender.pronounsOptions.count - 1))
                            : 0
                    )
                )
                .opacity(density * sharp * (director.gender.cardFaceUp ? 1 : 0))
        }
        .blur(radius: blur)
        .frame(width: cardWidth, height: cardHeight)
        // Lift affordance — the same ring taught in NamePhase. Scales with the card. It
        // also appears on the RESTING card the moment both dials are armed (tuned or
        // declined), so the "pick me up" cue can't fire until the user has tuned themselves
        // in — then it always does. (Bryan: the card needs a clearer pickup cue.)
        .overlay(LiftHalo(visible: director.gender.cardLifted
                                   || (director.gender.armedToLift
                                       && director.gender.pickerVisible
                                       && !director.gender.cardLifted)))
        .scaleEffect(x: director.gender.cardFlipScaleX, y: 1.0)
        .scaleEffect(director.gender.cardScale)
        // Tilt as the card is handed up (shared HandBackFollow) — a held card leaning.
        .rotationEffect(.degrees(HandBackFollow.tilt(for: handBackDrag.width, screenWidth: screenSize.width)))
        .opacity(director.gender.cardAlpha)
        // Tap-to-lift → swipe-up — the grammar taught in NamePhase. Tap again
        // while lifted to set the card down and keep tuning the drums.
        .onTapGesture {
            if director.gender.cardLifted {
                liftHaptic.toggle()
                withAnimation(AppAnimation.cardLift.reduceMotionSafe) {
                    director.gender.lowerCard(screenSize: screenSize)
                }
            } else if director.gender.pickerVisible {
                liftHaptic.toggle()
                withAnimation(AppAnimation.cardLift.reduceMotionSafe) {
                    director.gender.liftCard(screenSize: screenSize)
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 30)
                .onChanged { value in
                    // Grab the lifted card — kill the hint and follow the finger (weighty, banded).
                    guard director.gender.cardLifted else { return }
                    director.gender.endSwipeHint()
                    handBackDrag = HandBackFollow.offset(for: value.translation,
                                                         cardWidth: cardWidth, cardHeight: cardHeight)
                    let crossed = value.translation.height < -cardHeight * 0.14
                    if crossed != handBackArmed { handBackArmed = crossed; drumHapticGen.selectionChanged() }
                }
                .onEnded { value in
                    // Swipe-up confirms only while lifted (sibling-phase gate:
                    // distance OR a committed flick, limited horizontal drift).
                    guard director.gender.cardLifted else { return }
                    handBackArmed = false
                    let dy  = value.translation.height
                    let pdy = value.predictedEndTranslation.height
                    if dy < -cardHeight * 0.14 || pdy < -cardHeight * 0.5, abs(value.translation.width) < 80 {
                        confirmedTrigger.toggle()   // triggers .sensoryFeedback(.success) in body
                        // Drift + tilt resolve INTO the pocket flight — no snap at the handoff.
                        withAnimation(AppAnimation.cardPocket.reduceMotionSafe) { handBackDrag = .zero }
                        director.gender.confirmSelection(screenSize: screenSize, cardWidth: cardWidth)
                    } else {
                        // Short of the threshold — settle the card back to the lift anchor.
                        withAnimation(AppAnimation.cardSettle.reduceMotionSafe) { handBackDrag = .zero }
                    }
                }
        )
        // Swipe-hint flick — pure upward translation that intermittently
        // throws the lifted card up and springs it home, cueing the confirm swipe.
        // hintOffset is driven by the intermittent loop in .onChange(genderSwipeHintActive).
        .offset(director.gender.cardOffset)
        .offset(y: hintOffset)
        .offset(handBackDrag)   // live hand-off follow (resolves into the pocket flight)
    }

    // MARK: — Picker

    // Drum slot height. 3-item window keeps the picker short so it clears the
    // card base (card ≈ 263pt tall, centred at 52% screen — leaves ~280pt below).
    private let drumItemH: CGFloat = 48
    private var drumWindowH: CGFloat { drumItemH * 3 }

    /// Height of the shared decline bar beneath the dials. FEEL-GATE.
    private let declineBarHeight: CGFloat = 40

    // Display strips prepend a "—" placeholder so each dial opens BLANK — the user must
    // tune to a real option (or tap the decline bar). Display index 0 = placeholder;
    // display index i maps to the canonical option i-1 (settle subtracts 1).
    private var genderDisplay: [String] { ["—"] + director.gender.options }
    private var pronounsDisplay: [String] { ["—"] + director.gender.pronounsOptions }

    /// Strip offset that centres item 0 in the 3-item window.
    /// Formula: (n-1)/2 items of padding above item 0 when n is odd.
    private var drumInitialOffset: CGFloat {
        // Centres display index 0 (the "—" placeholder) in the window — the blank start.
        // Float division keeps even counts centred (see pronounsInitialOffset).
        CGFloat(genderDisplay.count - 1) / 2.0 * drumItemH
    }

    /// Scroll position passed to the director (0 = first item, grows as user scrolls forward).
    private var drumScrollPosition: CGFloat {
        drumInitialOffset - drumBaseOffset - drumDragOffset
    }

    /// Index of the option currently closest to the selection band.
    /// Derived from drumBaseOffset + drumDragOffset (no autonomous spin to track).
    private var currentCenteredIndex: Int {
        let n = genderDisplay.count
        guard n > 0 else { return 0 }
        let raw = (drumInitialOffset - drumBaseOffset - drumDragOffset) / drumItemH
        return max(0, min(n - 1, Int(raw.rounded())))
    }

    private var pronounsInitialOffset: CGFloat {
        // Centres the "—" placeholder (display index 0). Float division keeps even counts centred.
        CGFloat(pronounsDisplay.count - 1) / 2.0 * drumItemH
    }

    private var pronounsScrollPosition: CGFloat {
        pronounsInitialOffset - pronounsBaseOffset - pronounsDragOffset
    }

    private var pronounsCurrentCenteredIndex: Int {
        let n = pronounsDisplay.count
        guard n > 0 else { return 0 }
        let raw = (pronounsInitialOffset - pronounsBaseOffset - pronounsDragOffset) / drumItemH
        return max(0, min(n - 1, Int(raw.rounded())))
    }

    /// Y-offset from ZStack centre to the drum centre.
    /// Positions the drum in the open space between the card top and the screen top.
    private var pickerOffsetY: CGFloat {
        // Push the dials up to clear room for the decline bar beneath them ("push up the
        // dial options"). The extra lift ≈ half the bar region. FEEL-GATE.
        director.gender.cardOffset.height - cardHeight / 2 - AppSpacing.xxl - drumWindowH / 2
            - (declineBarHeight + AppSpacing.lg) / 2
    }

    // MARK: — Picker layer

    private var pickerLayer: some View {
        Group {
            if director.gender.pickerVisible {
                VStack(spacing: AppSpacing.lg) {
                    HStack(spacing: AppSpacing.xl) {
                        drumPickerView(
                            options: genderDisplay,
                            baseOffset: $drumBaseOffset,
                            dragOffset: $drumDragOffset,
                            lastCentered: $lastCenteredIndex,
                            hapticGen: drumHapticGen,
                            initialOffset: drumInitialOffset,
                            centeredIndex: currentCenteredIndex,
                            onUpdate: { director.gender.updateDrum(offset: $0) },
                            onSettle: { director.gender.settleDrum(index: $0 - 1) }   // display → canonical
                        )
                        drumPickerView(
                            options: pronounsDisplay,
                            baseOffset: $pronounsBaseOffset,
                            dragOffset: $pronounsDragOffset,
                            lastCentered: $pronounsLastCentered,
                            hapticGen: pronounsHapticGen,
                            initialOffset: pronounsInitialOffset,
                            centeredIndex: pronounsCurrentCenteredIndex,
                            onUpdate: { director.gender.updatePronounsDrum(offset: $0) },
                            onSettle: { director.gender.settlePronounsDrum(index: $0 - 1) }
                        )
                    }
                    declineBar
                }
                .onAppear {
                    drumBaseOffset     = drumInitialOffset
                    pronounsBaseOffset = pronounsInitialOffset
                    drumHapticGen.prepare()
                    pronounsHapticGen.prepare()
                }
                // Plain .opacity transition — the fade is driven solely by the
                // withAnimation(.standard) that flips genderPickerVisible in the director.
                // A transition-local .animation() here double-drives the insert and pops
                // the picker to full opacity for one frame. Single animation source = no flash.
                .transition(.opacity)
            }
        }
        .offset(y: pickerOffsetY)
        // Drums fade while the card is lifted — the selection is "in hand."
        // Opacity only (never unmount): pickerLayer.onAppear resets the drum
        // base offsets, so unmounting on lift would wipe the user's selection
        // position when the card is set back down.
        .opacity(director.gender.cardLifted ? 0.0 : 1.0)
        .animation(AppAnimation.standard.reduceMotionSafe, value: director.gender.cardLifted)
        .allowsHitTesting(director.gender.pickerVisible && !director.gender.cardLifted)
    }

    // MARK: — Drum

    /// Single scrollable drum. Called twice by pickerLayer — once for gender, once for pronouns.
    /// Gradient mask fades options that scroll toward the window edges.
    /// The gesture lives on the container so the full frame area receives touches —
    /// the inner strip VStack does not have a gesture to avoid any conflict.
    private func drumPickerView(
        options: [String],
        baseOffset: Binding<CGFloat>,
        dragOffset: Binding<CGFloat>,
        lastCentered: Binding<Int>,
        hapticGen: UISelectionFeedbackGenerator,
        initialOffset: CGFloat,
        centeredIndex: Int,
        onUpdate: @escaping (CGFloat) -> Void,
        onSettle: @escaping (Int) -> Void
    ) -> some View {
        let currentBase = baseOffset.wrappedValue
        let currentDrag = dragOffset.wrappedValue
        let stripOffset = currentBase + currentDrag

        return ZStack {
            // Full-frame touch target — transparent but receives all touches in the window
            Color.clear

            // Options strip — visual only, no gesture
            VStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.offset) { idx, option in
                    Text(option)
                        .font(idx == centeredIndex
                            ? AppFonts.prompt.weight(.semibold)
                            : AppFonts.prompt)
                        .foregroundStyle(
                            idx == centeredIndex
                                ? AppColors.textPrimary
                                : AppColors.textSecondary
                        )
                        .frame(height: drumItemH)
                        .animation(.none, value: centeredIndex)
                }
            }
            .offset(y: stripOffset)
            .allowsHitTesting(false)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.00),
                        .init(color: .black, location: 0.28),
                        .init(color: .black, location: 0.72),
                        .init(color: .clear, location: 1.00)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )

            // Selection band — two hairlines bounding the centre slot; outside mask
            VStack(spacing: drumItemH - 1) {
                Rectangle().fill(AppColors.spectrumBorder).frame(height: 0.5)
                Rectangle().fill(AppColors.spectrumBorder).frame(height: 0.5)
            }
            .frame(height: drumItemH)
            .allowsHitTesting(false)
        }
        .frame(width: screenSize.width * 0.28, height: drumWindowH)
        .contentShape(Rectangle())
        .clipped()
        .gesture(
            DragGesture()
                .onChanged { value in
                    director.gender.endSwipeHint()
                    // Rubber-band past the first/last option instead of tracking the
                    // finger 1:1 off the ends — the drum resists, it never runs free
                    // into empty space. `t0`/`tN` are the translations that centre
                    // index 0 and index n-1; beyond them the excess is damped.
                    let n = options.count
                    var t = value.translation.height
                    if n > 0 {
                        let t0 = initialOffset - currentBase                                   // index 0
                        let tN = initialOffset - currentBase - CGFloat(n - 1) * drumItemH      // index n-1
                        if t > t0 {
                            t = t0 + VaylRubberBand.damp(t - t0, dimension: drumItemH)
                        } else if t < tN {
                            t = tN - VaylRubberBand.damp(tN - t, dimension: drumItemH)
                        }
                    }
                    dragOffset.wrappedValue = t
                    let nowIdx = centeredIndex
                    if nowIdx != lastCentered.wrappedValue {
                        lastCentered.wrappedValue = nowIdx
                        hapticGen.selectionChanged()
                    }
                    onUpdate(initialOffset - currentBase - t)
                }
                .onEnded { value in
                    let n = options.count
                    guard n > 0 else { return }
                    let raw     = (initialOffset - currentBase - value.predictedEndTranslation.height) / drumItemH
                    let snapped = max(0, min(n - 1, Int(raw.rounded())))
                    let newBase = initialOffset - CGFloat(snapped) * drumItemH
                    withAnimation(AppAnimation.spring.reduceMotionSafe) {
                        baseOffset.wrappedValue = newBase
                        dragOffset.wrappedValue = 0
                    }
                    lastCentered.wrappedValue = snapped
                    onSettle(snapped)
                }
        )
    }

    // MARK: — Decline bar (shared "prefer not to say")

    /// Understated strip beneath the dials — not a CTA. Tap declines the whole identity
    /// card (clears both dials back to "—") and arms the lift. Active styling while
    /// declined; tuning either dial clears it (the sequencer flips `declined` to false).
    private var declineBar: some View {
        let active = director.gender.declined
        return Text("Prefer not to say")
            .font(AppFonts.caption)
            .foregroundStyle(active ? AppColors.textPrimary : AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: declineBarHeight)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .stroke(AppColors.spectrumBorder, lineWidth: active ? 1.0 : 0.5)
                    .opacity(active ? 1.0 : 0.4)
            )
            .frame(width: screenSize.width * 0.6)
            .contentShape(Rectangle())
            .scaleEffect(declinePressed ? 0.97 : 1.0)
            .animation(AppAnimation.fast.reduceMotionSafe, value: declinePressed)
            .sensoryFeedback(.impact(weight: .light), trigger: declinePressed)
            .onTapGesture { tapDecline() }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in declinePressed = true }
                    .onEnded { _ in declinePressed = false }
            )
            .allowsHitTesting(!director.gender.cardLifted)
    }

    /// Reset both drum strips to the placeholder, then commit the shared decline.
    private func tapDecline() {
        withAnimation(AppAnimation.spring.reduceMotionSafe) {
            drumBaseOffset     = drumInitialOffset
            drumDragOffset     = 0
            pronounsBaseOffset = pronounsInitialOffset
            pronounsDragOffset = 0
        }
        lastCenteredIndex    = 0
        pronounsLastCentered = 0
        director.gender.declineIdentity()
    }

}
