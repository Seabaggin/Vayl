// Vayl/Features/Onboarding/Phases/NamePhase.swift

import SwiftUI

private enum CardDealPhase: Equatable {
    case idle
    case swiping
    case resting
    case flipping
    case pausing
    case lifting
    case nameInput
    case collecting
}

struct NamePhase: View {

    let director:    VaylDirector
    let screenSize:  CGSize
    @Binding var tableRimBurst: Double

    @State private var dealTask:             Task<Void, Never>? = nil
    @State private var inputFocusTask:       Task<Void, Never>? = nil
    @State private var autoAdvanceTask:      Task<Void, Never>? = nil
    @State private var collapseEffectsTask:  Task<Void, Never>? = nil
    @State private var dealPhase:  CardDealPhase      = .idle
    @State private var cardOffset: CGSize             = .zero
    @State private var cardAngle:  Double             = 0
    @State private var cardAlpha:  Double             = 0

    @State private var flipScaleX:    Double = 1.0
    @State private var showFace:      Bool   = false
    @State private var faceStartDate: Date?  = nil

    @State private var cardScale:       Double = 1.0
    @State private var cardScreenAlpha: Double = 1.0
    @State private var cardBlur:        Double = 0

    @State private var impactRingProgress: Double = 0
    @State private var flipBurstProgress:  Double = 0

    @State private var name:           String  = ""
    @State private var uiAlpha:        Double  = 0
    @State private var dragY:          CGFloat = 0
    @State private var nudgeOffset:    CGFloat = 0
    @State private var hintArrowAlpha: Double  = 0

    @State private var fieldCollapsed:       Bool                    = false
    @State private var greetingVisible:      Bool                    = false
    @State private var greetingOwnsName:     Bool                    = false
    @State private var nameTextOpacity:      Double                  = 1.0
    @State private var typingDebounceTask:   Task<Void, Never>?      = nil
    @State private var lineBounceTask:       Task<Void, Never>?      = nil
    @FocusState private var nameFieldFocused: Bool

    @State private var headerText:  String  = "acquainted."
    @State private var headerFaded: Bool    = false

    @State private var glowPulseScale: CGFloat = 1.0

    @State private var lineRevealProgress: CGFloat = 0
    @State private var hasSweptLine:       Bool    = false
    @State private var lineBounce:         CGFloat = 0

    @State private var nameShimmerActive: Bool = false
    @State private var impactMedium = UIImpactFeedbackGenerator(style: .medium)
    @State private var impactHeavy  = UIImpactFeedbackGenerator(style: .heavy)

    @State private var coachMarkAlpha:    Double  = 0
    @State private var coachMarkOffset:   CGFloat = 0
    @State private var hasShownCoachMark: Bool    = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale) private var displayScale

    @State private var landingAngleDeg: Double  = 0
    @State private var landingOffset:   CGSize  = .zero
    @State private var seedGenerated:   Bool    = false

    private var cardWidth:  CGFloat {
        AppLayout.obTableCardWidth(in: screenSize.width) * AppLayout.obTableCardCinematicScale
    }
    private var cardHeight: CGFloat {
        AppLayout.obTableCardHeight(in: screenSize.width) * AppLayout.obTableCardCinematicScale
    }

    var body: some View {
        GeometryReader { geo in
            let safeAreaInsets = geo.safeAreaInsets
            ZStack {
                effectsLayer

                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { tl in
                    let t: Double = {
                        guard showFace, let start = faceStartDate else { return 0 }
                        return tl.date.timeIntervalSince(start)
                    }()
                    cardLayer(deepT: t)
                }

                if dealPhase == .nameInput || dealPhase == .collecting {
                    nameInputLayer(safeAreaInsets: safeAreaInsets)
                        .opacity(uiAlpha)
                }

            }
            .frame(width: screenSize.width, height: screenSize.height)
        .onAppear {
            dealTask = Task { await runDealSequence() }
        }
        .onDisappear {
            typingDebounceTask?.cancel()
            typingDebounceTask = nil
            lineBounceTask?.cancel()
            lineBounceTask = nil
            dealTask?.cancel()
            inputFocusTask?.cancel()
            inputFocusTask = nil
            autoAdvanceTask?.cancel()
            autoAdvanceTask = nil
            collapseEffectsTask?.cancel()
            collapseEffectsTask = nil
            seedGenerated = false
        }
        }
    }

    private var effectsLayer: some View {
        Canvas { context, size in
            let cx = size.width  / 2 + cardOffset.width
            let cy = size.height / 2 + cardOffset.height

            if impactRingProgress > 0 {
                let ringW     = cardWidth * 1.1 + (cardWidth * 2.2) * impactRingProgress
                let ringH     = ringW * 0.23
                let ringAlpha = (1.0 - impactRingProgress) * 0.55
                guard ringAlpha > 0 else { return }

                var ringPath = Path()
                ringPath.addEllipse(in: CGRect(
                    x: cx - ringW / 2,
                    y: cy + cardHeight * 0.48 - ringH / 2,
                    width:  ringW,
                    height: ringH
                ))
                context.stroke(
                    ringPath,
                    with: .color(AppColors.spectrumPurple.opacity(ringAlpha)),
                    lineWidth: 1.0
                )
            }

            if flipBurstProgress > 0 {
                let burstR     = max(cardWidth, cardHeight) * 1.8 * flipBurstProgress
                let burstAlpha = (1.0 - flipBurstProgress) * 0.45
                guard burstAlpha > 0 else { return }

                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: AppColors.spectrumPurple.opacity(burstAlpha),      location: 0),
                            .init(color: AppColors.spectrumCyan.opacity(burstAlpha * 0.45), location: 0.45),
                            .init(color: AppColors.spectrumCyan.opacity(0),                 location: 1),
                        ]),
                        center:      CGPoint(x: cx, y: cy),
                        startRadius: 0,
                        endRadius:   burstR
                    )
                )
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    // ARCH NOTE: This card lives entirely in phase state — not in director.tableCards.
    // It is rendered alongside the SpriteKit in-flight card during the deal handoff.
    // FIXME: SPEC GAP — OBDeepCardFace vs VaylCardFace unreconciled.
    // DO NOT SHIP until design+eng confirms which component is correct for this screen.
    // See audit finding F034. Assigned: Bryan, due before next TestFlight build.
    private func cardLayer(deepT: Double) -> some View {
        Group {
            if !showFace {
                VaylCardBack()
            } else {
                OBDeepCardFace(deepT: deepT)
            }
        }
        .drawingGroup() // rasterize cinematic card layers to Metal texture
        .frame(width: cardWidth, height: cardHeight)
        .scaleEffect(x: flipScaleX, y: 1.0)
        .scaleEffect(cardScale)
        .rotationEffect(.degrees(cardAngle))
        .offset(cardOffset)
        .blur(radius: cardBlur)
        .opacity(cardAlpha * cardScreenAlpha)
    }

    private func nameInputLayer(safeAreaInsets: EdgeInsets) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: safeAreaInsets.top + AppSpacing.lg) // AppSafeArea modifier — see TODO in audit F002

            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: AppLayout.swipeZoneHeight)
                .contentShape(Rectangle())
                .accessibilityLabel("Swipe down to confirm your name")
                .accessibilityHint("Confirms the name you entered and continues setup")
                .accessibilityAddTraits(.isButton)
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { v in
                            guard dealPhase == .nameInput else { return }
                            if v.translation.height > 0 { dragY = v.translation.height }
                        }
                        .onEnded { v in handleSwipeDown(v.translation.height) }
                )
                .overlay {
                    ZStack {
                        VStack(spacing: AppSpacing.xs) {
                            Image(systemName: "hand.point.down.fill")
                                .font(AppFonts.cardTitle) // light weight not in type scale, using cardTitle
                                .foregroundStyle(AppColors.textSecondary)

                            VStack(spacing: 3) { // 3pt glyph constant — below spacing grid, intentional
                                Circle().fill(AppColors.textHint).frame(width: 3, height: 3) // 3pt glyph constant — below spacing grid, intentional
                                Circle().fill(AppColors.textTertiary).frame(width: 3, height: 3)
                                Circle().fill(AppColors.textMuted).frame(width: 3, height: 3)
                            }
                        }
                        .offset(y: coachMarkOffset)
                        .opacity(coachMarkAlpha)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: AppLayout.swipeZoneHeight)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }

            VStack(alignment: .leading, spacing: 0) {
                if headerText == "Good to meet you." {
                    Text("Good to meet you.")
                        .font(AppFonts.obPhaseTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .opacity(headerFaded ? 0 : 1)
                        .animation(AppAnimation.headerFade, value: headerFaded)
                } else {
                    Text("Let's get")
                        .font(AppFonts.obPhaseTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .opacity(headerFaded ? 0 : 1)
                        .animation(AppAnimation.headerFade, value: headerFaded)
                    Text("acquainted.")
                        .font(AppFonts.obPhaseTitle)
                        .foregroundStyle(AppColors.spectrumText)
                        .opacity(headerFaded ? 0 : 1)
                        .animation(AppAnimation.headerFade, value: headerFaded)
                }
            }
            .padding(.bottom, AppSpacing.xl)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("What should we call you?")
                    .font(AppFonts.display(22, weight: .semibold, relativeTo: .title2))
                    .foregroundStyle(AppColors.textSecondary)
                    .opacity(fieldCollapsed ? 0 : 1)
                    .animation(AppAnimation.fast.delay(0.05), value: fieldCollapsed)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                TextField(
                    "",
                    text: $name,
                    prompt: Text("Enter name")
                        .font(AppFonts.display(28, weight: .semibold, relativeTo: .title))
                        .foregroundColor(AppColors.textPrimary.opacity(0.28))
                )
                    .font(AppFonts.display(28, weight: .semibold, relativeTo: .title))
                    .foregroundColor(AppColors.textPrimary.opacity(nameTextOpacity))
                    .tint(name.isEmpty ? .clear : AppColors.accentPrimary)
                    .focused($nameFieldFocused)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .accessibilityLabel("What should we call you?")
                    .onSubmit {
                        nameFieldFocused = false
                        triggerCollapse(keyboardSubmit: true)
                    }
                    .opacity(fieldCollapsed ? 0 : 1)
                    .animation(AppAnimation.standard, value: fieldCollapsed)
                    .disabled(fieldCollapsed)
                    .onChange(of: name) { _, newValue in
                        let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                        if trimmed.count > AppLayout.maxNameLength {
                            name = String(trimmed.prefix(AppLayout.maxNameLength))
                        }
                        typingDebounceTask?.cancel()
                        guard !trimmed.isEmpty else {
                            withAnimation(AppAnimation.fast) {
                                greetingVisible  = false
                                greetingOwnsName = false
                            }
                            withAnimation(AppAnimation.standard.delay(0.15)) {
                                fieldCollapsed  = false
                                nameTextOpacity = 1.0
                            }
                            return
                        }
                        if !reduceMotion {
                            withAnimation(AppAnimation.keystrokeBounce) { lineBounce = -1.5 }
                            lineBounceTask?.cancel()
                            lineBounceTask = Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(80))
                                guard !Task.isCancelled else { return }
                                withAnimation(AppAnimation.keystrokeBounceReturn) { lineBounce = 0 }
                            }
                        }
                        typingDebounceTask = Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(1500))
                            guard !Task.isCancelled else { return }
                            triggerCollapse()
                        }
                    }
                    .onChange(of: nameFieldFocused) { _, isFocused in
                        if isFocused && greetingOwnsName {
                            withAnimation(AppAnimation.fast) {
                                greetingVisible  = false
                                greetingOwnsName = false
                            }
                            withAnimation(AppAnimation.standard.delay(0.15)) {
                                fieldCollapsed  = false
                                nameTextOpacity = 1.0
                            }
                        }
                        if isFocused && !hasSweptLine {
                            hasSweptLine = true
                            withAnimation(AppAnimation.lineReveal) {
                                lineRevealProgress = 1.0
                            }
                        } else if isFocused {
                            lineRevealProgress = 1.0
                        }
                    }
                    .overlay(alignment: .bottom) {
                        ZStack {
                            Rectangle()
                                .fill(AnyShapeStyle(AppColors.spectrumBorder))
                                .frame(height: 1)

                            Rectangle()
                                .fill(LinearGradient(
                                    colors: [
                                        AppColors.accentPrimary.opacity(0.6),
                                        AppColors.accentSecondary.opacity(0.9),
                                        AppColors.accentTertiary.opacity(0.8),
                                        AppColors.accentPrimary.opacity(0.6)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(height: 3)
                                .blur(radius: 4)

                            Rectangle()
                                .fill(LinearGradient(
                                    colors: [
                                        AppColors.accentPrimary.opacity(0.2),
                                        AppColors.accentSecondary.opacity(0.35),
                                        AppColors.accentTertiary.opacity(0.3),
                                        AppColors.accentPrimary.opacity(0.2)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(height: 8)
                                .blur(radius: 6)
                        }
                        .scaleEffect(x: lineRevealProgress, anchor: .leading)
                        .offset(y: lineBounce)
                        .opacity(fieldCollapsed ? 0 : 1)
                        .animation(AppAnimation.standard, value: fieldCollapsed)
                    }
            }
            .padding(.bottom, AppSpacing.xs)

            // Greeting — springs in after 1.5s typing pause
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                Spacer()

                Text("Hi ")
                    // .regular weight not supported by ClashDisplay; .semibold used pending typeface audit
                    .font(AppFonts.display(28, weight: .semibold, relativeTo: .title))
                    .foregroundStyle(AppColors.textPrimary.opacity(0.94))

                Text(name.trimmingCharacters(in: .whitespaces))
                    .font(AppFonts.display(36, weight: .bold, relativeTo: .title))
                    .foregroundStyle(AppColors.textPrimary)
                    .modifier(GlowUnderline(isLight: false))
                    .tracking(AppLayout.nameLetterSpacing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .scaleEffect(x: glowPulseScale, y: 1.0, anchor: .center)
                    .overlay {
                        if nameShimmerActive {
                            HolographicShimmer()
                                .transition(.opacity)
                        }
                    }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .onChange(of: greetingVisible) { _, visible in
                guard visible else { return }
                let trimmed = name.trimmingCharacters(in: .whitespaces)
                UIAccessibility.post(notification: .announcement, argument: "Hi \(trimmed). Swipe down to continue.")
            }
            .opacity(greetingVisible ? 1 : 0)
            .offset(y: greetingVisible
                ? AppLayout.greetingOffsetVisible(in: screenSize.height)
                : AppLayout.greetingOffsetHidden(in: screenSize.height)
            )
            .animation(AppAnimation.greetingSettle, value: greetingVisible)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.xl)
            .onTapGesture {
                nudgeOffset    = 0
                hintArrowAlpha = 0
                coachMarkAlpha  = 0
                coachMarkOffset = 0
                headerText     = "acquainted."
                headerFaded    = false
                withAnimation(AppAnimation.fast) {
                    greetingVisible  = false
                    greetingOwnsName = false
                }
                withAnimation(AppAnimation.standard.delay(0.15)) {
                    fieldCollapsed  = false
                    nameTextOpacity = 1.0
                }
                inputFocusTask?.cancel()
                inputFocusTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(350))
                    guard !Task.isCancelled, dealPhase == .nameInput else { return }
                    nameFieldFocused = true
                }
            }

            Image(systemName: "chevron.down")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .opacity(hintArrowAlpha)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, AppSpacing.sm)
                .accessibilityHidden(true)

            Spacer().frame(height: safeAreaInsets.bottom + AppSpacing.lg)
        }
        .padding(.horizontal, AppSpacing.xl)
        .offset(y: dragY + nudgeOffset)
    }

    @MainActor
    private func snapshotCardBack(scale: CGFloat) -> UIImage? {
        let renderer = ImageRenderer(
            content: VaylCardBack()
                .frame(width: cardWidth, height: cardHeight)
        )
        renderer.scale = scale
        return renderer.uiImage
    }

    @MainActor
    private func runDealSequence() async {

        if !seedGenerated {
            landingAngleDeg = Double.random(in: -7...7)
            landingOffset   = CGSize(
                width:  CGFloat.random(in: -40...40),
                height: CGFloat.random(in: -40...40)
            )
            seedGenerated   = true
        }

        if reduceMotion {
            triggerNameInput()
            return
        }

        guard let cardImage = snapshotCardBack(scale: displayScale) else { return }

        // ── Claim a landing slot ──────────────────────────────────
        let slot          = director.claimLandingSlot(screenSize: screenSize)
        let flightID      = UUID().uuidString
        let startAngleDeg = Double.random(in: 11.0...16.0)

        // NOTE: Spec says origin y: -15% (off-screen top).
        // Current: y: 8% (visible but cardAlpha is 0).
        // Card is not physically off-screen — it is invisible at this position.
        // Visual result is equivalent; physical origin is a spec deviation.
        // Tracked for reconciliation.
        let origin = CGPoint(
            x: screenSize.width  * 1.05,
            y: screenSize.height * 0.08
        )
        let destination = slot.position

        // SpriteKit CCW-positive radians; negate for clockwise SwiftUI tilt.
        let skInitialAngle = CGFloat(-startAngleDeg * .pi / 180)
        let skFinalAngle   = CGFloat(-slot.angleDeg * .pi / 180)

        // ── Pre-deal: empty table + dealer copy ───────────────────
        // TODO: replace with final copy
        director.showDealerLineManual("The cards remember what you tell them.")

        try? await Task.sleep(for: .milliseconds(2600))
        guard !Task.isCancelled else { return }

        director.hideDealerLine()

        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }

        // ── SWIPE ─────────────────────────────────────────────────
        dealPhase = .swiping
        cardAlpha = 0

        let (restPos, restRot) = await director.sailCard(
            cardID:       flightID,
            image:        cardImage,
            from:         origin,
            to:           destination,
            sceneSize:    screenSize,
            duration:     0.92,
            initialAngle: skInitialAngle,
            finalAngle:   skFinalAngle
        )
        guard !Task.isCancelled else { return }

        // ── Handoff ───────────────────────────────────────────────
        // Atomic: sprite gone and SwiftUI card live in the same render pass.
        dealPhase = .resting
        cardOffset = CGSize(
            width:  restPos.x - screenSize.width  / 2,
            height: restPos.y - screenSize.height / 2
        )
        cardAngle = restRot
        director.cardFlightScene.clearCard(id: flightID)
        cardAlpha = 1

        try? await Task.sleep(for: .milliseconds(460))
        guard !Task.isCancelled else { return }

        fireImpactRing()
        tableRimBurst = 1.0
        withAnimation(AppAnimation.rimBurstDecay) {
            tableRimBurst = 0.0
        }

        // Pause for the landing to breathe, then the invisible hand centers the card.
        try? await Task.sleep(for: .milliseconds(520))
        guard !Task.isCancelled else { return }

        let tableCenter = CGPoint(
            x: screenSize.width  * 0.50,
            y: screenSize.height * 0.55
        )
        withAnimation(AppAnimation.cardCenter) {
            cardOffset = CGSize(
                width:  tableCenter.x - screenSize.width  / 2,
                height: tableCenter.y - screenSize.height / 2
            )
            cardAngle  = 0
        }

        try? await Task.sleep(for: .milliseconds(950))
        guard !Task.isCancelled else { return }

        dealPhase = .flipping
        await performFlip()
        guard !Task.isCancelled else { return }

        dealPhase = .pausing
        fireFlipBurst()

        // Pause to breathe after the flip.
        try? await Task.sleep(for: .milliseconds(900))
        guard !Task.isCancelled else { return }

        dealPhase = .lifting
        await performLift()
        guard !Task.isCancelled else { return }

        triggerNameInput()
    }

    @MainActor
    private func performFlip() async {
        withAnimation(AppAnimation.cardFlipHalf) {
            flipScaleX = 0.0
        }
        try? await Task.sleep(for: .milliseconds(290))
        guard !Task.isCancelled else { return }

        showFace      = true
        faceStartDate = Date()

        withAnimation(AppAnimation.cardFlipHalf) {
            flipScaleX = -1.0
        }
        try? await Task.sleep(for: .milliseconds(290))
    }

    @MainActor
    private func performFlipBack() async {
        if reduceMotion {
            showFace = false
            faceStartDate = nil
            flipScaleX = 1.0
            return
        }
        withAnimation(AppAnimation.cardFlipHalf) {
            flipScaleX = 0.0
        }
        try? await Task.sleep(for: .milliseconds(290))

        showFace   = false
        faceStartDate = nil

        withAnimation(AppAnimation.cardFlipHalf) {
            flipScaleX = 1.0
        }
        try? await Task.sleep(for: .milliseconds(290))
    }

    @MainActor
    private func performCardCollect() async {
        // Reveal the deck on the canvas just before the card flies in.
        // The next phase entry (runGenderEntry) will set it back to false.
        director.cornerDeckVisible = true

        let cornerX = screenSize.width  - AppLayout.cornerDeckRight - AppLayout.cornerDeckWidth  / 2
        let cornerY = AppLayout.cornerDeckTop + AppLayout.cornerDeckHeight / 2

        withAnimation(AppAnimation.cardPocket) {
            cardOffset = CGSize(
                width:  cornerX - screenSize.width  / 2,
                height: cornerY - screenSize.height / 2
            )
            cardScale  = AppLayout.cornerDeckWidth / cardWidth
            cardAlpha  = 0
        }

        try? await Task.sleep(for: .milliseconds(380))

        // Register in the corner deck so the counter appears.
        let collected = VaylCardModel()
        director.cornerDeckCards.append(collected)
        withAnimation(AppAnimation.deckReceive) {
            director.deckPulse = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            director.deckPulse = false
        }
    }

    @MainActor
    private func performLift() async {
        // Push the card past the camera plane — diveMultiplier× screen-widths deep.
        let diveScale = (screenSize.width * AppLayout.cardLiftDiveMultiplier) / cardWidth

        withAnimation(AppAnimation.tableFadeOut) {
            director.tableFade = 0.0
        }
        // Card rushes toward the camera — caustics fill the lens.
        withAnimation(AppAnimation.cardLift) {
            cardScale  = diveScale
            cardOffset = .zero
            cardAngle  = 0
        }

        // At ~300ms the card has grown past 1.5× screen width.
        // The lens is inside the water — blur ramps in hard.
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        withAnimation(AppAnimation.liftBlurRamp) {
            cardBlur = AppLayout.cardLiftBlurRadius
        }

        // 100ms later the user is submerged. Fade the card out.
        // The blur makes the fade imperceptible — reads as dissolving into the water.
        try? await Task.sleep(for: .milliseconds(100))
        guard !Task.isCancelled else { return }
        withAnimation(AppAnimation.liftCardFade) {
            cardScreenAlpha = 0.0
        }
    }

    @MainActor
    private func fireImpactRing() {
        impactRingProgress = 0
        withAnimation(AppAnimation.impactRingDecay) {
            impactRingProgress = 1.0
        }
    }

    @MainActor
    private func fireFlipBurst() {
        flipBurstProgress = 0
        withAnimation(AppAnimation.flipBurstDecay) {
            flipBurstProgress = 1.0
        }
    }

    @MainActor
    private func triggerNameInput() {
        dealPhase = .nameInput
        withAnimation(reduceMotion ? .linear(duration: 0.1) : AppAnimation.uiFadeIn) {
            uiAlpha = 1.0
        }
        impactHeavy.prepare()
        inputFocusTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(750))
            guard !Task.isCancelled else { return }
            nameFieldFocused = true
        }
    }

    @MainActor
    private func triggerCollapse(keyboardSubmit: Bool = false) {
        inputFocusTask?.cancel()
        inputFocusTask = nil
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        typingDebounceTask?.cancel()
        withAnimation(AppAnimation.standard) {
            nameTextOpacity = 0
            fieldCollapsed  = true
        }
        if reduceMotion {
            // Under reduce motion: show greeting with opacity only, skip spring offset.
            withAnimation(AppAnimation.standard) {
                greetingVisible  = true
                greetingOwnsName = true
            }
        } else {
            withAnimation(AppAnimation.spring.delay(0.28)) {
                greetingVisible  = true
                greetingOwnsName = true
            }
        }
        collapseEffectsTask?.cancel()
        collapseEffectsTask = Task { @MainActor in
            await withTaskGroup(of: Void.self) { group in

                // Nudge + hint arrow sequence (swipe-path only)
                if !keyboardSubmit {
                    group.addTask { @MainActor in
                        guard !reduceMotion else { return } // positional — skip entirely
                        try? await Task.sleep(for: .milliseconds(600))
                        guard !Task.isCancelled else { return }
                        withAnimation(AppAnimation.screenNudge) { nudgeOffset = 14 }
                        try? await Task.sleep(for: .milliseconds(220))
                        withAnimation(AppAnimation.screenNudgeReturn) { nudgeOffset = 0 }
                        try? await Task.sleep(for: .milliseconds(180))
                        withAnimation(AppAnimation.hintArrowIn) { hintArrowAlpha = 1.0 }
                        try? await Task.sleep(for: .milliseconds(900))
                        withAnimation(AppAnimation.hintArrowOut) { hintArrowAlpha = 0.0 }
                    }
                }

                // Header crossfade
                group.addTask { @MainActor in
                    try? await Task.sleep(for: .milliseconds(900))
                    guard !Task.isCancelled else { return }
                    withAnimation(AppAnimation.headerFade) { headerFaded = true }
                    try? await Task.sleep(for: .milliseconds(350))
                    headerText = "Good to meet you."
                    withAnimation(AppAnimation.headerFade) { headerFaded = false }
                }

                // Glow pulse
                group.addTask { @MainActor in
                    guard !reduceMotion else { return }
                    try? await Task.sleep(for: .milliseconds(1100))
                    guard !Task.isCancelled else { return }
                    withAnimation(AppAnimation.glowPulse) { glowPulseScale = 1.04 }
                    try? await Task.sleep(for: .milliseconds(550))
                    withAnimation(AppAnimation.glowPulse) { glowPulseScale = 1.0 }
                }

                // Coach mark sequence (swipe-path only, first time only)
                if !keyboardSubmit {
                    group.addTask { @MainActor in
                        guard !hasShownCoachMark, !reduceMotion else { return }
                        hasShownCoachMark = true
                        try? await Task.sleep(for: .milliseconds(1400))
                        guard !Task.isCancelled else { return }
                        coachMarkOffset = 0
                        withAnimation(AppAnimation.coachMarkIn) { coachMarkAlpha = 1.0 }
                        try? await Task.sleep(for: .milliseconds(300))
                        withAnimation(AppAnimation.coachMarkTravel) { coachMarkOffset = 38 }
                        try? await Task.sleep(for: .milliseconds(450))
                        withAnimation(AppAnimation.coachMarkOut) { coachMarkAlpha = 0.0 }
                        try? await Task.sleep(for: .milliseconds(400))
                        coachMarkOffset = 0
                    }
                }
            }
        }

        if keyboardSubmit {
            // Keyboard-submit path: greeting shows for ~1.5 s then card collects automatically.
            // The swipe gesture can cancel this and submit early.
            autoAdvanceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(1500))
                guard !Task.isCancelled else { return }
                submitName()
            }
        }
    }

    @MainActor
    private func handleSwipeDown(_ translationY: CGFloat) {
        guard dealPhase == .nameInput, translationY > AppLayout.swipeSubmitThreshold else {
            withAnimation(AppAnimation.spring) { dragY = 0 }
            return
        }
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            impactMedium.impactOccurred()
            withAnimation(AppAnimation.spring) { dragY = 0 }
            return
        }
        autoAdvanceTask?.cancel()
        autoAdvanceTask = nil
        submitName()
    }

    @MainActor
    private func submitName() {
        autoAdvanceTask?.cancel()
        autoAdvanceTask = nil
        guard dealPhase != .collecting else { return }
        typingDebounceTask?.cancel()
        typingDebounceTask = nil
        nameFieldFocused = false
        impactHeavy.impactOccurred()
        director.onboardingData.displayName = name.trimmingCharacters(in: .whitespaces)

        nameShimmerActive = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            nameShimmerActive = false
        }
        nudgeOffset    = 0
        hintArrowAlpha = 0
        coachMarkAlpha  = 0
        coachMarkOffset = 0
        headerText     = "acquainted."
        headerFaded    = false
        dealPhase = .collecting

        // UI slides off; card cross-fades back in at table size simultaneously.
        withAnimation(AppAnimation.exit)   { uiAlpha = 0 }
        withAnimation(AppAnimation.spring) { dragY = screenSize.height * AppLayout.dragExitMultiplier }
        // Scale and angle reset instantly — animating from diveScale would produce a zoom-in.
        cardScale = 1.0
        cardAngle = 0
        withAnimation(AppAnimation.cardRestore) {
            cardScreenAlpha = 1.0
            cardBlur        = 0
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(480))
            await performFlipBack()
            try? await Task.sleep(for: .milliseconds(160))
            await performCardCollect()
            try? await Task.sleep(for: .milliseconds(420))
            director.advance(to: .gender)
        }
    }
}
