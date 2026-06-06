// Features/Onboarding/Phases/GenderPhase.swift
//
// Near-pure renderer. Owns no animation state.
// All visual state lives on VaylDirector.
//
// View contract:
//   .onAppear  → director.startGenderSequence(screenSize:)
//   .onDisappear → director.cancelGenderSequence()
//
// Segment 1 — Card rises from table (crystallisation)
// Segment 2 — Dealer line + auto flip → RadioTunerCardFace revealed
// Segment 3 — Power-on beat → two drum pickers appear
// Segment 4 — User tunes left drum (gender) + right drum (pronouns)
//             Dials on card face track progress in real time.
//             When both settled: signal locks, "Found it." dealer line.
// Segment 5 — Swipe up to confirm → card pockets → .experienceLevel

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

    // Pronouns drum state (mirrors gender drum)
    @State private var pronounsBaseOffset:   CGFloat = 0
    @State private var pronounsDragOffset:   CGFloat = 0
    @State private var pronounsLastCentered: Int     = 0
    @State private var pronounsHapticGen:    UISelectionFeedbackGenerator = UISelectionFeedbackGenerator()

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

            // Picker — fades in after power-on beat, driven by genderPickerVisible
            pickerLayer
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .sensoryFeedback(.success, trigger: confirmedTrigger)
        .onAppear   { director.startGenderSequence(screenSize: screenSize, reduceMotion: reduceMotion) }
        .onDisappear { director.cancelGenderSequence() }
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
                VaylCardFace()
                    .overlay(
                        RadioTunerCardFace(
                            cardWidth:         cardWidth,
                            cardHeight:        cardHeight,
                            signalStrength:    director.genderSignalStrength,
                            scanPhase:         Double(drumBaseOffset + drumDragOffset
                                                    + pronounsBaseOffset + pronounsDragOffset),
                            leftDialProgress:  director.genderOptions.isEmpty ? 0 :
                                Double(director.genderSelectedIndex) / Double(max(1, director.genderOptions.count - 1)),
                            rightDialProgress: director.genderPronounsOptions.isEmpty ? 0 :
                                Double(director.genderPronounsSelectedIndex) / Double(max(1, director.genderPronounsOptions.count - 1))
                        )
                    )
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
                    guard director.genderBothSettled else { return }
                    director.endGenderSwipeHint()
                }
                .onEnded { value in
                    // Only active after both drums have settled.
                    guard director.genderBothSettled else { return }
                    // Require an upward swipe (negative height) with limited horizontal drift.
                    guard value.translation.height < -55  else { return }
                    guard abs(value.translation.width) < 80 else { return }
                    confirmedTrigger.toggle()   // triggers .sensoryFeedback(.success) in body
                    director.confirmGenderSelection(pronouns: nil)
                }
        )
        // Swipe-hint flick — pure upward translation that intermittently
        // throws the card up and springs it home, demonstrating the swipe gesture.
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

    private var pronounsInitialOffset: CGFloat {
        // Float division required — (n-1)/2.0 correctly centres item 0 for even-count lists.
        // Integer division (n-1)/2 is off by 0.5 slots for even n (6 pronouns → gap between items).
        CGFloat(director.genderPronounsOptions.count - 1) / 2.0 * drumItemH
    }

    private var pronounsScrollPosition: CGFloat {
        pronounsInitialOffset - pronounsBaseOffset - pronounsDragOffset
    }

    private var pronounsCurrentCenteredIndex: Int {
        let n = director.genderPronounsOptions.count
        guard n > 0 else { return 0 }
        let raw = (pronounsInitialOffset - pronounsBaseOffset - pronounsDragOffset) / drumItemH
        return max(0, min(n - 1, Int(raw.rounded())))
    }

    /// Y-offset from ZStack centre to the drum centre.
    /// Positions the drum in the open space between the card top and the screen top.
    private var pickerOffsetY: CGFloat {
        director.genderCardOffset.height - cardHeight / 2 - AppSpacing.xxl - drumWindowH / 2
    }

    // MARK: — Picker layer

    private var pickerLayer: some View {
        Group {
            if director.genderPickerVisible {
                HStack(spacing: AppSpacing.xl) {
                    drumPickerView(
                        options:        director.genderOptions,
                        baseOffset:     $drumBaseOffset,
                        dragOffset:     $drumDragOffset,
                        lastCentered:   $lastCenteredIndex,
                        hapticGen:      drumHapticGen,
                        initialOffset:  drumInitialOffset,
                        centeredIndex:  currentCenteredIndex,
                        onUpdate:       { director.updateGenderDrum(offset: $0) },
                        onSettle:       { director.settleGenderDrum(index: $0) }
                    )
                    drumPickerView(
                        options:        director.genderPronounsOptions,
                        baseOffset:     $pronounsBaseOffset,
                        dragOffset:     $pronounsDragOffset,
                        lastCentered:   $pronounsLastCentered,
                        hapticGen:      pronounsHapticGen,
                        initialOffset:  pronounsInitialOffset,
                        centeredIndex:  pronounsCurrentCenteredIndex,
                        onUpdate:       { director.updateGenderPronounsDrum(offset: $0) },
                        onSettle:       { director.settleGenderPronounsDrum(index: $0) }
                    )
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
        .allowsHitTesting(director.genderPickerVisible)
    }

    // MARK: — Drum

    /// Single scrollable drum. Called twice by pickerLayer — once for gender, once for pronouns.
    /// Gradient mask fades options that scroll toward the window edges.
    /// The gesture lives on the container so the full frame area receives touches —
    /// the inner strip VStack does not have a gesture to avoid any conflict.
    private func drumPickerView(
        options:       [String],
        baseOffset:    Binding<CGFloat>,
        dragOffset:    Binding<CGFloat>,
        lastCentered:  Binding<Int>,
        hapticGen:     UISelectionFeedbackGenerator,
        initialOffset: CGFloat,
        centeredIndex: Int,
        onUpdate:      @escaping (CGFloat) -> Void,
        onSettle:      @escaping (Int) -> Void
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
                        .init(color: .clear, location: 1.00),
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
                    director.endGenderSwipeHint()
                    dragOffset.wrappedValue = value.translation.height
                    let nowIdx = centeredIndex
                    if nowIdx != lastCentered.wrappedValue {
                        lastCentered.wrappedValue = nowIdx
                        hapticGen.selectionChanged()
                    }
                    onUpdate(initialOffset - currentBase - value.translation.height)
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

}
