// Features/Home/Components/CardCarousel.swift
// Open Lightly

import SwiftUI

// MARK: - Supporting Types

enum CarouselPhase: Equatable {
    case floating
    case spread
    case gathering
    case lifted
    case carousel
}

enum CarouselDirection {
    case next
    case prev
}

enum CardAction {
    case startSession
    case navigateToPlay
    case share
    case redo(Card)
}

// MARK: - Layout Constants

private let cardW: CGFloat = 300
private let cardH: CGFloat = 190

// 6-Card Converging Fan — hand-tuned offsets, not AppSpacing candidates.
// These define the physical spread geometry of the fan animation.
private let spreadOffsets: [CGFloat] = [-180, 180, -120, 120, -60, 60 ]
private let spreadRotations: [Double]  = [ -18, 18, -12, 12, -6, 6 ]
private let spreadYOffsets: [CGFloat] = [  24, 24, 16, 16, 8, 8 ]
private let spreadScales: [CGFloat] = [0.78, 0.78, 0.84, 0.84, 0.90, 0.90]
private let spreadOpacities: [Double]  = [0.25, 0.25, 0.50, 0.50, 0.75, 0.75]

// 6-Card Gathered State
private let gatheredYOffsets: [CGFloat] = [15, 12, 9, 6, 4, 2  ]
private let gatheredOpacities: [Double]  = [0.30, 0.45, 0.60, 0.75, 0.85, 0.95]
private let gatheredScales: [CGFloat] = [0.91, 0.93, 0.95, 0.96, 0.97, 0.98]

// MARK: - CardCarousel

struct CardCarousel: View {

    var cards: [Card]
    var onCardAction: ((Card, CardAction) -> Void)?
    var onNavigateToPlay: (() -> Void)?
    var onPhaseChange: ((CarouselPhase) -> Void)?

    // Hand-selection mode — when `selecting`, tapping the active card toggles it
    // into tonight's hand (via onToggleSelect) instead of starting a session.
    // `selectedIDs` marks which cards are already in the hand.
    var selecting: Bool = false
    var selectedIDs: Set<String> = []
    var onToggleSelect: ((Card) -> Void)?

    /// Backdrop dim opacity when engaged. nil keeps the default (light 0.35 / dark
    /// 0.75) — pass a softer value (e.g. Home) to fade the room rather than black it out.
    var dimOpacity: Double?

    /// Deck identity for Play / session cards — tints each face and adds the glyph
    /// watermark; per-card heat comes from the card's intensity. nil (Home's hand-builder,
    /// OB) keeps the canonical look.
    var colorway: FoilColorway?
    var glyphPath: Path?

    @State private var phase: CarouselPhase = .floating
    @State private var activeIndex: Int     = 0
    @State private var dragOffset: CGFloat = 0
    @State private var verticalDragOffset: CGFloat = 0
    @State private var isDragging: Bool    = false
    @State private var dragVelocity: CGFloat = 0
    @State private var previousDragOffset: CGFloat = 0
    @State private var specularPhase: CGFloat = 0
    @State private var specularActive: Bool    = false
    @State private var borderRotation: Double  = 0.0
    @State private var floatOffset: CGFloat = 0
    @State private var bloomOpacity: Double  = 0.5
    @State private var flyGhostActive: Bool    = false
    @State private var flyProgress: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var activeCard: Card? {
        guard cards.indices.contains(activeIndex) else { return nil }
        return cards[activeIndex]
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            cardStack
        }
        .onChange(of: phase) { _, newPhase in
            onPhaseChange?(newPhase)
        }
        .onAppear {
            onPhaseChange?(.floating)

            // Ambient idle loops — disabled entirely under Reduce Motion / Low Power
            // Mode (the static resting state must read without motion). The phase
            // callback above always fires.
            guard !reduceMotion, !AppAnimation.lowPower else { return }

            // Border rotation — ambient loop, 4.0s matches AppAnimation.ambientDrift.
            withAnimation(.linear(duration: AppAnimation.ambientDrift).repeatForever(autoreverses: false)) {
                borderRotation = 360.0
            }

            DispatchQueue.main.async {
                // Float loop — 3.2s intentional, slightly below ambientDrift (4.0s).
                // Gives card a faster, more responsive idle breath.
                withAnimation(AppAnimation.cardBreathe) {
                    floatOffset = -6
                }
            }

            // Bloom pulse — 4.0s matches AppAnimation.ambientDrift.
            withAnimation(.easeInOut(duration: AppAnimation.ambientDrift).repeatForever(autoreverses: true)) {
                bloomOpacity = 0.75
            }
        }
    }

    // MARK: - Card Stack

    private var cardStack: some View {
        ZStack(alignment: .top) {
            auroraBloom
            backingCards
            carouselCards
            flyGhostView
        }
        .frame(maxWidth: .infinity)
        // Height gives clearance above and below for lifted/carousel state.
        // Cards lift -40pt and have 8pt top padding — 300pt is sufficient.
        .frame(height: cardH + 120)
        // No .clipped() — cards must overflow upward during lifted/carousel phases.
        .animation(AppAnimation.spring, value: phase)
        .background { dimmingBackdrop }
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.height > 80 && phase == .carousel {
                        handleDismissQuickview()
                    }
                }
        )
        .overlay { glassTrackpad }
        .scaleEffect(phase == .spread ? 0.75 : 1.0)
        .offset(y: cardStackOffsetY)
        // Phase-driven negative bottom padding — intentional carousel layout mechanics.
        // Each value controls how much the card container bleeds into content below
        // for that phase. These are not AppSpacing candidates.
        .padding(.bottom, cardStackBottomPadding)
        .animation(cardStackPhaseAnimation, value: phase)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cardStackA11yLabel)
        .accessibilityHint(cardStackA11yHint)
        .accessibilityAdjustableAction { direction in
            guard phase == .carousel else { return }
            switch direction {
            case .increment: navigateCarousel(direction: .next)
            case .decrement: navigateCarousel(direction: .prev)
            @unknown default: break
            }
        }
    }

    // Phase-driven layout values hoisted out of the `cardStack` modifier chain so
    // each nested ternary is type-checked in isolation (chain was 600ms inline).

    private var dimmingBackdrop: some View {
        Rectangle()
            .fill(dimOpacity.map { Color.black.opacity($0) } ?? AppColors.scrimHeavy)
            .frame(width: 3000, height: 3000)
            .opacity((phase == .floating || phase == .spread) ? 0 : 1)
            .allowsHitTesting(phase != .floating && phase != .spread)
            .onTapGesture { handleDismissQuickview() }
    }

    private var cardStackOffsetY: CGFloat {
        phase == .spread ? 0 : (phase == .floating ? 0 : -20)
    }

    private var cardStackBottomPadding: CGFloat {
        switch phase {
        case .carousel: return -40
        case .spread:   return -60
        case .floating: return -100
        default:        return -20
        }
    }

    private var cardStackPhaseAnimation: Animation {
        // Slow phase spring — intentional above AppAnimation.spring ceiling.
        // response: 0.95 gives the card stack deliberate weight during transitions.
        reduceMotion
            ? AppAnimation.standard
            : .spring(response: 0.95, dampingFraction: 0.85)
    }

    private var cardStackA11yLabel: String {
        phase == .carousel
            ? "Card \(activeIndex + 1) of \(cards.count). \(activeCard?.text ?? "")"
            : "Card deck. Tap to begin."
    }

    private var cardStackA11yHint: String {
        phase == .carousel
            ? "Swipe left or right to navigate cards"
            : "Double tap to open"
    }

    // MARK: - Glass Trackpad

    private var glassTrackpad: some View {
        Color.white.opacity(0.001)
            .onTapGesture {
                if phase == .floating {
                    handleFloatingTap()
                } else if phase == .lifted {
                    handleDismissQuickview()
                } else if phase == .carousel {
                    // This overlay sits ABOVE the cards, so the active card's own
                    // tap can't fire — handle the carousel tap here. In selecting
                    // mode tapping the centered card adds it to tonight's hand (it
                    // flies to the corner deck → "Settle in →"); otherwise it starts.
                    handleCarouselTap()
                }
            }
            .highPriorityGesture(
                (phase == .carousel || phase == .lifted) && phase != .floating
                    ? DragGesture(minimumDistance: 5)
                        .onChanged { handleDragChanged($0) }
                        .onEnded { handleDragEnded($0) }
                    : nil
            )
    }

    private func handleDragChanged(_ value: DragGesture.Value) {
        if phase == .lifted {
            withAnimation(AppAnimation.spring) {
                phase = .carousel
            }
        }
        if dragOffset == 0 {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        isDragging    = true
        dragVelocity  = value.translation.width - previousDragOffset

        let currentProgress  = abs(value.translation.width / (cardW + 16))
        let previousProgress = abs(previousDragOffset / (cardW + 16))
        if (currentProgress >= 0.5 && previousProgress < 0.5) ||
           (currentProgress < 0.5  && previousProgress >= 0.5) {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.8)
        }
        previousDragOffset = value.translation.width
        dragOffset         = value.translation.width

        // Rubber-band downward drag — sqrt damping gives physical resistance feel.
        // verticalDragOffset is a layout mechanic, not a spacing token.
        let verticalTranslation = value.translation.height
        if verticalTranslation > 0 {
            verticalDragOffset = sqrt(verticalTranslation) * 2.5
        } else {
            verticalDragOffset = 0
        }
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        if value.translation.height > 80 {
            withAnimation(AppAnimation.spring) {
                verticalDragOffset = 0
            }
            handleDismissQuickview()
            return
        }

        withAnimation(AppAnimation.spring) {
            verticalDragOffset = 0
        }

        // A near-stationary touch is a TAP, not a swipe. The high-priority drag
        // (minimumDistance 5) otherwise swallows taps on device — finger jitter
        // turns them into micro-drags — so the active card never gets selected.
        // Detect it here and route to the mockup's tap-to-add.
        if abs(value.translation.width) < 10, abs(value.translation.height) < 10 {
            handleCarouselTap()
            return
        }

        let predicted  = value.predictedEndTranslation.width
        let threshold: CGFloat = 50
        var newIndex   = activeIndex

        if dragOffset < -threshold || predicted < -200 {
            newIndex = (activeIndex + 1) % cards.count
        } else if dragOffset > threshold || predicted > 200 {
            newIndex = (activeIndex - 1 + cards.count) % cards.count
        }

        if newIndex != activeIndex {
            let shift: CGFloat = newIndex > activeIndex ? (cardW + 16) : -(cardW + 16)
            dragOffset += shift
            activeIndex = newIndex
            UISelectionFeedbackGenerator().selectionChanged()
            if !reduceMotion { triggerSpecularGlint() }
        }

        DispatchQueue.main.async {
            withAnimation(AppAnimation.spring) {
                isDragging = false
                dragOffset = 0
            }
        }
        dragVelocity       = 0
        previousDragOffset = 0
    }

    // MARK: - Aurora Bloom

    @ViewBuilder
    private var auroraBloom: some View {
        if let _ = activeCard {
            Ellipse()
                .fill(RadialGradient(
                    colors: [
                        AppColors.accentSecondary
                            .opacity(phase == .spread ? 0.14 : 0.28),
                        AppColors.accentSecondary.opacity(0.08),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 180
                ))
                .frame(width: 380, height: 260)
                .blur(radius: 60)
                .scaleEffect(isDragging ? 1.15 : 1.0)
                .opacity(phase == .floating ? bloomOpacity : (isDragging ? 1.0 : 0.6))
                // FEEL CHANGE (2026-07-08 audit fix): was .spring(response: 0.4, dampingFraction: 0.6),
                // which violated the dampingFraction >= 0.75 hard rule outside the OB canvas.
                // Swapped to AppAnimation.spring (0.5 / 0.85), the documented tap-release staple.
                // This changes the aurora swell's bounce character (less overshoot, slightly
                // slower settle) - needs a device feel-confirmation pass.
                .animation(AppAnimation.spring, value: isDragging)
                .allowsHitTesting(false)
                .animation(AppAnimation.slow, value: activeIndex)

            if phase == .carousel && !reduceMotion {
                let bleed = min(abs(dragOffset) / 320, 1.0)
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.accentSecondary
                                .opacity(bleed * 0.22),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 160
                    ))
                    .frame(width: 380, height: 260)
                    .offset(x: dragOffset < 0 ? 50 : -50)
                    .blur(radius: 65)
                    .allowsHitTesting(false)
                    .animation(
                        isDragging ? .none : AppAnimation.enter,
                        value: dragOffset
                    )
            }
        }
    }

    // MARK: - Backing Cards

    private var backingCards: some View {
        ForEach(0..<6, id: \.self) { i in
            let isSpread = phase == .spread
            CardBackView(
                offsetX: isSpread ? spreadOffsets[i]   : 0,
                offsetY: isSpread ? spreadYOffsets[i]  : gatheredYOffsets[i],
                rotation: isSpread ? spreadRotations[i] : 0,
                scale: isSpread ? spreadScales[i]    : gatheredScales[i],
                opacity: (phase == .floating || phase == .carousel) ? 0
                    : isSpread ? spreadOpacities[i]
                    : gatheredOpacities[i],
                isLight: false   // V1 is dark-only (no colorScheme reads in Views)
            )
            .zIndex(Double(i))
            .offset(y: (phase == .lifted || phase == .carousel) ? -15 : 0)
            .animation(
                reduceMotion
                    ? AppAnimation.standard
                    // Backing card spring — intentional above AppAnimation.spring ceiling.
                    // response: 0.85 makes backing cards feel heavier than the active card.
                    : .spring(response: 0.85, dampingFraction: 0.80),
                value: phase
            )
        }
    }

    // MARK: - Carousel Cards

    @ViewBuilder
    private var carouselCards: some View {
        if cards.isEmpty {
            EmptyView()
        } else {
            let prevIdx = (activeIndex - 1 + cards.count) % cards.count
            let nextIdx = (activeIndex + 1) % cards.count
            let visibleSlots: [(index: Int, relative: Int)] = [
                (prevIdx, -1),
                (activeIndex, 0),
                (nextIdx, 1)
            ]

            ForEach(visibleSlots, id: \.index) { entry in
                carouselCard(index: entry.index, relativeIndex: entry.relative)
            }
        }
    }

    // MARK: - Carousel Card Helper

    @ViewBuilder
    private func carouselCard(index i: Int, relativeIndex: Int) -> some View {
        let baseOffset      = CGFloat(relativeIndex) * (cardW + 16)
        let rawX            = phase == .carousel ? (baseOffset + dragOffset) : 0
        let progress        = rawX / (cardW + 16)
        let clampedProgress = min(max(progress, -1.0), 1.0)
        let visualX         = clampedProgress * (cardW * 0.78)
        let isActive        = i == activeIndex

        ZStack {
            // Real card face — restored. The front cards had been stubbed to a flat
            // page-coloured rect with plain text; VaylCardFace brings back the
            // spectrum frame, hairlines, and atmosphere. Landscape frame (cardW × cardH).
            VaylCardFace(
                question: cards[i].text,
                colorway: colorway,
                heat: Double(cards[i].intensity.rawValue - 1) / 7.0,
                glyphPath: glyphPath
            )
                .frame(width: cardW, height: cardH)

            LinearGradient(
                colors: [.clear, .white.opacity(0.12), .clear],
                startPoint: .init(x: 0.2 - (progress * 1.5), y: 0),
                endPoint: .init(x: 0.8 - (progress * 1.5), y: 1)
            )
            .blendMode(.screen)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.obCard, style: .continuous))
            .allowsHitTesting(false)
            .opacity(phase == .carousel ? 1 : 0)

            let specularOpacity: Double = (isActive && specularActive && phase != .carousel) ? 1 : 0
            RoundedRectangle(cornerRadius: AppRadius.obCard)
                .fill(LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .white.opacity(0.08), location: 0.35),
                        .init(color: .white.opacity(0.20), location: 0.50),
                        .init(color: .white.opacity(0.08), location: 0.65),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .init(x: specularPhase * 1.4 - 0.4, y: 0),
                    endPoint: .init(x: specularPhase * 1.4 - 0.1, y: 1)
                ))
                .blendMode(.screen)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.obCard))
                .opacity(specularOpacity)
        }
        .frame(width: cardW, height: cardH)
        .overlay(alignment: .topTrailing) {
            // Selected for tonight's hand — spectrum check badge.
            if selecting && selectedIDs.contains(cards[i].id) {
                Image(systemName: "checkmark")
                    .font(AppFonts.body(11, weight: .bold, relativeTo: .caption2))
                    .foregroundStyle(AppColors.void)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(AppColors.spectrumBorder))
                    .shadow(color: AppColors.accentSecondary.opacity(0.5), radius: 6)
                    .padding(10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottom) {
            if selecting && isActive && phase == .carousel {
                selectHint(added: selectedIDs.contains(cards[i].id))
                    .offset(y: 30)   // sit BELOW the card, not on it
            }
        }
        .overlay(alignment: .topLeading) {
            // Depth band, top-left — the mockup's per-card .vdepth.
            if phase == .carousel {
                Text(depthLabel(forIndex: i))
                    .font(AppFonts.label)
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.spectrumText)
                    .padding(.top, AppSpacing.md)
                    .padding(.leading, AppSpacing.lg)
            }
        }
        .padding(.top, AppSpacing.sm)
        // .padding(.bottom, -8) — intentional negative bleed offset.
        // Keeps the card visually anchored without a gap below. Not an AppSpacing candidate.
        .padding(.bottom, -8)
        .offset(
            x: phase == .carousel ? visualX : 0,
            y: phaseOffsetY(isActive: isActive) + (isActive ? verticalDragOffset : 0)
        )
        .scaleEffect(
            phase == .carousel
                ? max(0.75, 1.0 - abs(clampedProgress) * 0.25)
                : (phase == .lifted ? 1.04 : 1.0)
        )
        .blur(radius: phase == .carousel ? abs(clampedProgress) * 2.5 : 0)
        .rotation3DEffect(
            rotationAngle(clampedProgress: clampedProgress),
            axis: (x: 0.3, y: 1, z: 0),
            perspective: 0.25
        )
        .zIndex(isActive ? 200.0 : 100.0 - Double(abs(progress) * 10))
        .allowsHitTesting(phase == .carousel && isActive)
        .onTapGesture {
            if phase == .carousel && isActive {
                handleCarouselTap()
            }
        }
        .shadow(
            color: shadowColor(isActive: isActive, clampedProgress: clampedProgress),
            radius: phase == .carousel ? 36 + (abs(clampedProgress) * 45) : 36,
            y: 18
        )
        .opacity(phase == .carousel ? (isActive ? 1.0 : 0.75) : (isActive ? 1.0 : 0.0))
        .animation(AppAnimation.spring, value: phase)
    }

    private func phaseOffsetY(isActive: Bool) -> CGFloat {
        switch phase {
        case .lifted, .carousel: return -40
        case .floating:          return isActive ? floatOffset : 0
        default:                 return 0
        }
    }

    private func rotationAngle(clampedProgress: CGFloat) -> Angle {
        if phase == .lifted && !reduceMotion { return .degrees(-4) }
        if phase == .carousel && !reduceMotion { return .degrees(Double(clampedProgress * -25.0)) }
        return .degrees(0.001)
    }

    private func shadowColor(isActive: Bool, clampedProgress: CGFloat) -> Color {
        if phase == .lifted || phase == .carousel {
            return AppColors.accentSecondary.opacity((isActive ? 0.35 : 0.0) + abs(clampedProgress) * 0.45)
        }
        return AppColors.accentSecondary.opacity(0.001)
    }

    // MARK: - Hand Selection Affordances

    /// The active card's add hint — hidden once picked (the check badge takes
    /// over), matching the mockup's .vadd. Uses the same lavender-purple as
    /// other section headers/eyebrows, not the cyan accent (Bryan's call).
    @ViewBuilder
    private func selectHint(added: Bool) -> some View {
        if !added {
            Text("tap to add")
                .font(AppFonts.buttonLabelSmall)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textSectionLabel)
        }
    }

    /// Depth band for a card by its position in the deck — warming up → deepening
    /// → opening up → deep — matching the mockup's per-card progression.
    private func depthLabel(forIndex i: Int) -> String {
        guard cards.count > 1 else { return "warming up" }
        switch Double(i) / Double(cards.count - 1) {
        case ..<0.25: return "warming up"
        case ..<0.5:  return "deepening"
        case ..<0.75: return "opening up"
        default:      return "deep"
        }
    }

    /// Transient ghost that flies toward the corner deck on add — the arc feedback
    /// from the prototype, without changing the toggle-in-place selection model.
    /// `flyProgress` 0 → 1: full-size at the card → shrunk + up-right + gone.
    @ViewBuilder
    private var flyGhostView: some View {
        if flyGhostActive {
            RoundedRectangle(cornerRadius: AppRadius.obCard, style: .continuous)
                .fill(AppColors.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.obCard, style: .continuous)
                        .strokeBorder(AppColors.spectrumBorder, lineWidth: 1)
                )
                .frame(width: cardW, height: cardH)
                .scaleEffect(1.0 - flyProgress * 0.84)
                .offset(x: flyProgress * 130, y: -40 + flyProgress * -150)
                .opacity(Double(1 - flyProgress))
                .allowsHitTesting(false)
        }
    }

    private func triggerFlyGhost() {
        flyGhostActive = true
        flyProgress = 0
        withAnimation(AppAnimation.cardPocket) { flyProgress = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            flyGhostActive = false
            flyProgress = 0
        }
    }

    /// Tap on the centered card in carousel phase (routed from glassTrackpad, which
    /// otherwise swallows it). Selecting mode → add/remove from tonight's hand;
    /// non-selecting → start the session for that card.
    private func handleCarouselTap() {
        guard cards.indices.contains(activeIndex) else { return }
        let card = cards[activeIndex]
        if selecting {
            let isAdd = !selectedIDs.contains(card.id)
            onToggleSelect?(card)
            UISelectionFeedbackGenerator().selectionChanged()
            if isAdd {
                // Adding deals the card away — auto-advance so the next card slides
                // in on its own, rather than making the user swipe after every pick.
                if !reduceMotion { triggerFlyGhost() }
                advanceToNextCard()
            }
        } else {
            onCardAction?(card, .startSession)
        }
    }

    /// Slide the next card into the center — same mechanic as a swipe-end advance,
    /// but triggered by an add so selecting deals the card away hands-free. Stays put
    /// on the last card (nothing to advance to) so the final pick doesn't wrap around.
    private func advanceToNextCard() {
        guard cards.count > 1, activeIndex < cards.count - 1 else { return }
        activeIndex += 1
        // Offset the incoming card to where the old one sat, then settle it to center —
        // cancels the instant re-slot the activeIndex bump would otherwise cause.
        dragOffset += (cardW + 16)
        DispatchQueue.main.async {
            withAnimation(AppAnimation.spring) {
                dragOffset = 0
            }
        }
    }

    // MARK: - Specular Glint

    func triggerSpecularGlint() {
        guard !reduceMotion else { return }
        specularPhase  = 0
        specularActive = true
        // Custom material motion curve — intentional, not AppAnimation.standard.
        // Produces a precise specular sweep feel distinct from easeOut.
        withAnimation(.timingCurve(0.4, 0, 0.6, 1, duration: 0.75)) {
            specularPhase = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            specularActive = false
            specularPhase  = 0
        }
    }

    // MARK: - Phase Transitions
    //
    // ANIMATION ARCHITECTURE — read before modifying:
    //
    // Each spring in this section is tuned for a specific physical feel:
    //   Fan spread:    response 0.6 / damping 0.7  — bouncy, like cards fanning
    //   Card lift:     response 0.85 / damping 0.82 — heavy, deliberate raise
    //   Dismiss:       response 0.6 / damping 0.8  — settle back with weight
    //   Backing cards: response 0.85 / damping 0.80 — lags behind active card
    //   Phase stack:   response 0.95 / damping 0.85 — slowest, gives stack weight
    //
    // These are all above AppAnimation.spring (0.5 / 0.85) intentionally.
    // They work together as a layered physics system. Do not normalise them.

    func handleFloatingTap() {
        guard phase == .floating else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(AppAnimation.fast) { floatOffset = 0 }
        let fanAnim: Animation = reduceMotion
            ? AppAnimation.fast
            // Fan spread spring — intentional bouncy feel.
            : .spring(response: 0.6, dampingFraction: 0.7)
        withAnimation(fanAnim) { phase = .spread }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            // Card lift spring — intentional heavy raise.
            withAnimation(.spring(response: 0.85, dampingFraction: 0.82)) {
                phase = .lifted
            }
            if !reduceMotion { triggerSpecularGlint() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(AppAnimation.spring) {
                    phase = .carousel
                }
            }
        }
    }

    func handleBrowseDeck() {
        let anim: Animation = reduceMotion
            ? AppAnimation.fast
            : AppAnimation.spring
        withAnimation(anim) { phase = .carousel }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func handleDismissQuickview() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(reduceMotion
            ? AppAnimation.fast
            : AppAnimation.spring
        ) {
            phase              = .spread
            verticalDragOffset = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(reduceMotion
                ? AppAnimation.fast
                // Dismiss return spring — intentional deliberate settle.
                : .spring(response: 0.6, dampingFraction: 0.8)
            ) {
                phase       = .floating
                activeIndex = 0
                dragOffset  = 0
                floatOffset = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            // Float loop restart — same 3.2s as onAppear, intentional.
            // Gated like the onAppear loops: under RM / Low Power the idle
            // float never ran, so don't restart it here either.
            guard !reduceMotion, !AppAnimation.lowPower else { return }
            withAnimation(AppAnimation.cardBreathe) {
                floatOffset = -6
            }
        }
    }

    func handleBackToDeck() {
        let anim: Animation = reduceMotion
            ? AppAnimation.fast
            : AppAnimation.spring
        withAnimation(anim) {
            phase       = .lifted
            activeIndex = 0
            dragOffset  = 0
        }
    }

    // MARK: - Carousel Navigation

    func navigateCarousel(direction: CarouselDirection) {
        let next = direction == .next
            ? (activeIndex + 1) % cards.count
            : (activeIndex - 1 + cards.count) % cards.count
        guard next != activeIndex else {
            withAnimation(AppAnimation.spring) {
                dragOffset = 0
            }
            return
        }
        let shift: CGFloat = next > activeIndex ? (cardW + 16) : -(cardW + 16)
        dragOffset += shift
        activeIndex = next
        UISelectionFeedbackGenerator().selectionChanged()
        if !reduceMotion { triggerSpecularGlint() }
        withAnimation(AppAnimation.spring) {
            dragOffset = 0
        }
    }
}

// MARK: - Previews

#Preview("Spread — dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        CardCarousel(cards: Card.samples)
    }
    .preferredColorScheme(.dark)
}
