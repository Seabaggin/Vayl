// Features/Onboarding/Phases/CuriosityPhase.swift

import SwiftUI

/// OB Phase — CuriosityPhase (two-round card sort).
///
/// Renders a pile of sort cards dealt from the dealer (bottom origin).
/// The user sweeps left (discard) or right (keep) until the pile is empty.
/// Round 1 → Round 2 → auto-advance on Round 2 exhaustion.
///
/// Architecture contract:
///   • View renders pixels and forwards gestures only.
///   • All state lives on VaylDirector.
///   • director.advance() is called by the director — never from here.
///   • The pile is one identity-stable stack (ForEach keyed by card id) so the next
///     card rises into place on a swipe instead of a recycled view swapping content.
///   • Top card + immediate-next card carry content; deeper cards are shells (perf).
///   • The departing card is rendered as a separate overlay so it leaves as itself.
struct CuriosityPhase: View {

    let director:   VaylDirector
    let screenSize: CGSize

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Drives the staggered deal animation. Flips true to animate cards in,
    /// resets to false before each new deal so cards return off-screen first.
    @State private var allCardsDealt:       Bool = false
    /// Toggled on commit so .sensoryFeedback can fire .impact on each card exit.
    @State private var commitHapticTrigger: Bool = false
    /// Torque factor from where the finger grabbed the card: +1 top edge,
    /// −1 bottom edge, 0 dead center (card slides without tilting). Makes the
    /// card pivot under the fingertip like a held physical card. Defaults to 1
    /// so the director's demo swipes (no gesture) tilt with the classic curve.
    @State private var grabPivot: CGFloat = 1.0

    // ── Forged-deck handoff hint ─────────────────────────────────────
    // While the deck sits presented in the user's hand, it tugs upward on the
    // taught cadence — same cue as every lifted card in the OB.
    @State private var summaryHintOffset: CGFloat            = 0
    @State private var summaryHintTask:   Task<Void, Never>? = nil

    // MARK: - Layout

    /// Horizontal drag distance that commits a swipe. Also normalizes the drag
    /// into the compass needle deflection (−1…1), so the needle hits full tilt
    /// exactly at the commit point.
    private let commitThreshold: CGFloat = 95

    private var cardWidth:  CGFloat { AppLayout.obTableCardWidth(in: screenSize.width) * AppLayout.obTableCardCinematicScale }
    private var cardHeight: CGFloat { AppLayout.obTableCardHeight(in: screenSize.width) * AppLayout.obTableCardCinematicScale }

    // MARK: - Layout (continued)

    /// Y origin for off-screen cards waiting to deal in.
    /// Negative = above the table so cards slide down onto the surface,
    /// matching the dealer-is-above visual language used across OB phases.
    private var offScreenY: CGFloat { -(screenSize.height * 0.5 + cardHeight) }

    // MARK: - Body

    var body: some View {
        ZStack {

            // ── Card pile ─────────────────────────────────────────────
            // (No round label — one deck, one sort; the mid-deck question
            // swap is the only punctuation.)
            pileView

        }
        // Trigger deal whenever the director toggles the deal flag
        // (fires on entry for Round 1 and again on Round 2 transition).
        .onChange(of: director.curiosityDealTrigger) { _, _ in
            dealCards()
        }
        // Threshold crossing → selection haptic (fires both ways: in and out of threshold)
        .sensoryFeedback(.selection, trigger: director.curiosityThresholdCrossed)
        // Commit → medium impact haptic (toggled by the view before calling director)
        .sensoryFeedback(.impact(weight: .medium), trigger: commitHapticTrigger)
        // Demo commits carry the same thunk — the gesture is taught WITH its
        // physical signature (the director toggles this only on demo swipes).
        .sensoryFeedback(.impact(weight: .medium), trigger: director.curiosityDemoCommitTrigger)
        .onAppear {
            director.beginCuriosityDemo(screenWidth: screenSize.width)
        }
        .onDisappear {
            director.curiositySequenceTask?.cancel()
            summaryHintTask?.cancel()
        }
        // Tug loop on the presented deck — flick up, spring home, rest.
        .onChange(of: director.curiositySummaryPresented) { _, presented in
            summaryHintTask?.cancel()
            guard presented, !reduceMotion else {
                withAnimation(AppAnimation.spring.reduceMotionSafe) { summaryHintOffset = 0 }
                return
            }
            summaryHintTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(600))
                while !Task.isCancelled {
                    withAnimation(AppAnimation.swipeHintFlick.reduceMotionSafe) { summaryHintOffset = -cardHeight * 0.10 }
                    try? await Task.sleep(for: .milliseconds(380))
                    guard !Task.isCancelled else { break }
                    withAnimation(AppAnimation.spring.reduceMotionSafe) { summaryHintOffset = 0 }
                    try? await Task.sleep(for: .milliseconds(1900))
                    guard !Task.isCancelled else { break }
                }
            }
        }
    }

    // MARK: - Pile View

    /// The pile is one identity-stable stack: every card is a persistent view keyed
    /// by its id, so committing the top card lets the next card (already content-bearing
    /// underneath) *rise* into place instead of a recycled view swapping content. The
    /// departing card is rendered separately by `flyingCardView` so it leaves as itself.
    private var pileView: some View {
        let pile = director.curiosityPile

        return ZStack {

            // ── Pile (back → front) ───────────────────────────────────
            // Rendered highest-depth first so index 0 (top) draws last / frontmost.
            ZStack {
                ForEach(Array(pile.enumerated().reversed()), id: \.element.id) { index, card in
                    pileCard(card: card, depth: index, pileCount: pile.count)
                }
            }
            // pile.count changing (a card committed) drives the rise: each remaining
            // card animates from its old depth to its new one — crisp, no spring overshoot.
            .animation(
                reduceMotion ? .easeOut(duration: 0.15) : AppAnimation.curiosityRise,
                value: pile.count
            )

            // ── Departing card ────────────────────────────────────────
            // Its own identity, flying clear of the pile. Director owns the throw
            // timing (curiosityThrow), so no .animation modifier is applied here.
            flyingCardView

            // ── Forged deck, presented in-hand ────────────────────────
            // "Your yeses built a deck" — the squared deck (same object the
            // forge melts in BuildDeck) materialises at the lift anchor with
            // the taught halo. The USER hands it over: swipe-up → handoff.
            // Director owns the materialise + flight animation.
            if director.curiositySummaryVisible {
                VaylDeckStack(size: CGSize(width: cardWidth, height: cardHeight))
                    .overlay(LiftHalo(visible: director.curiositySummaryPresented))
                    .scaleEffect(director.curiositySummaryScale)
                    .opacity(director.curiositySummaryAlpha)
                    .offset(director.curiositySummaryOffset)
                    .offset(y: summaryHintOffset)
                    .contentShape(Rectangle())
                    .gesture(summaryHandoffDrag)
                    .allowsHitTesting(director.curiositySummaryPresented)
            }
        }
    }

    /// One card in the pile. Structure is identical at every depth — only modifier
    /// *values* change with depth — so a card keeps its identity (and animates smoothly)
    /// as it rises from beneath to top. Only the top card carries the live drag + gesture.
    @ViewBuilder
    private func pileCard(card: CuriositySortCard, depth: Int, pileCount: Int) -> some View {
        let isTop = depth == 0
        let drag  = director.curiosityDragOffset

        // Resting stagger gives the pile physical thickness; the top card rests centered.
        // Direction alternates so the pile tilts irregularly rather than fanning.
        let sign:        CGFloat = depth % 2 == 0 ? 1 : -1
        let staggerX:    CGFloat = CGFloat(depth) * 1.5 * sign
        let staggerY:    CGFloat = CGFloat(depth) * 4.0
        let restRotate:  Double  = Double(depth) * 1.2 * Double(sign)
        let cardOpacity: Double  = max(0, 1.0 - Double(depth) * 0.05)
        // Bottom cards arrive first so they end up under the later arrivals.
        let dealDelay:   Double  = Double(pileCount - 1 - depth) * 0.06

        // Top card follows the finger; beneath cards hold their stagger.
        let offsetX:  CGFloat = isTop ? drag.width : staggerX
        let offsetY:  CGFloat = allCardsDealt ? (isTop ? drag.height : staggerY) : offScreenY
        let rotation: Double  = isTop
            ? Double(drag.width) / Double(screenSize.width) * 18.0 * Double(grabPivot)
            : restRotate

        // Only the top card's compass needle follows the finger; the next card
        // rests at zero so it rises into place with a level needle.
        let deflection: Double = isTop ? Double(drag.width / commitThreshold) : 0

        // Content on the top card and the immediate next card only; deeper cards are
        // shells (mostly occluded) to keep the frame rate solid during a drag.
        VaylCardFace(content: depth <= 1 ? .curiosity(category: card.text, deflection: deflection) : nil)
            .frame(width: cardWidth, height: cardHeight)
            .overlay { swipeStamps(for: isTop ? drag : .zero) }
            .opacity(cardOpacity)
            .rotationEffect(.degrees(rotation))
            // Deal flight (y from off-screen) — only this is driven by allCardsDealt,
            // so a live drag on the top card is never animated by the deal curve.
            .animation(
                reduceMotion ? .easeOut(duration: 0.15)
                             : AppAnimation.cardSlide.delay(dealDelay),
                value: allCardsDealt
            )
            .offset(x: offsetX, y: offsetY)
            // Only the top card receives touches; the gesture is attached to every card
            // (constant structure) but gated off beneath, off during the demo, and
            // off during the mid-deck pause while the second question types.
            .allowsHitTesting(isTop
                              && !director.curiosityDemoActive
                              && !director.curiosityRoundTransitioning)
            .gesture(curiosityDrag)
    }

    /// The just-committed card flying clear of the pile. Appears at the release position
    /// and is animated off-screen by the director, so it reads as the same card leaving —
    /// not a card vanishing while a new one pops in.
    @ViewBuilder
    private var flyingCardView: some View {
        if let flying = director.curiosityFlyingCard {
            let off = director.curiosityFlyingOffset
            // Needle pinned at full tilt in the throw direction — the card leaves
            // showing the verdict it was committed with.
            VaylCardFace(content: .curiosity(
                category:   flying.text,
                deflection: off.width >= 0 ? 1.0 : -1.0
            ))
                .frame(width: cardWidth, height: cardHeight)
                .overlay { swipeStamps(for: off) }
                .rotationEffect(.degrees(Double(off.width) / Double(screenSize.width) * 18.0))
                .offset(off)
                .allowsHitTesting(false)
        }
    }

    /// KEEP / PASS directional stamps, driven by a card's current offset. Lives on the
    /// card face so the stamps rotate with the drag arc. Inert to gestures.
    @ViewBuilder
    private func swipeStamps(for offset: CGSize) -> some View {
        let x           = Double(offset.width)
        let keepOpacity = x > 0 ? min(1.0, x / 95.0) : 0
        let passOpacity = x < 0 ? min(1.0, -x / 95.0) : 0

        ZStack {
            // KEEP stamp — right edge, spectrum cyan
            Text("KEEP")
                .font(AppFonts.overline)
                .foregroundStyle(AppColors.spectrumCyan)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .stroke(AppColors.spectrumCyan, lineWidth: 1.5)
                )
                .rotationEffect(.degrees(-12))
                .opacity(keepOpacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(AppSpacing.md)

            // PASS stamp — left edge, spectrum magenta
            Text("PASS")
                .font(AppFonts.overline)
                .foregroundStyle(AppColors.spectrumMagenta)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .stroke(AppColors.spectrumMagenta, lineWidth: 1.5)
                )
                .rotationEffect(.degrees(12))
                .opacity(passOpacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(AppSpacing.md)
        }
        .allowsHitTesting(false)
    }

    /// Drag gesture for the top card. Attached to every card for structural stability;
    /// only the top card has hit-testing enabled, so only it ever fires.
    private var curiosityDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                // startLocation is in the card's local space and constant for the
                // gesture, so this resolves to the same pivot every change.
                let half = cardHeight / 2.0
                grabPivot = min(max((half - value.startLocation.y) / half, -1.0), 1.0)
                director.onCuriosityDrag(offset: value.translation)
            }
            .onEnded { value in
                // Commit on distance crossed, OR on a confident flick whose
                // projected travel (position + velocity) clears the threshold
                // with margin — so a short fast throw isn't ignored, but drift
                // never commits on momentum alone.
                let travelled = value.translation.width
                let projected = value.predictedEndTranslation.width
                if abs(travelled) >= commitThreshold || abs(projected) >= commitThreshold * 1.6 {
                    // Toggle before calling director so the haptic fires on this frame.
                    commitHapticTrigger.toggle()
                    director.commitCuriositySwipe(screenSize: screenSize)
                } else {
                    director.snapBackCuriosityCard()
                }
            }
    }

    /// Swipe-up on the presented deck — the handoff. Sibling-phase gate:
    /// distance OR a committed flick, the gesture taught in Name.
    private var summaryHandoffDrag: some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { _ in
                summaryHintTask?.cancel()
                withAnimation(AppAnimation.spring.reduceMotionSafe) { summaryHintOffset = 0 }
            }
            .onEnded { value in
                let dy  = value.translation.height
                let pdy = value.predictedEndTranslation.height
                guard dy < -cardHeight * 0.14 || pdy < -cardHeight * 0.5 else { return }
                commitHapticTrigger.toggle()
                director.handoffCuriosityDeck(screenSize: screenSize)
            }
    }

    // MARK: - Deal Animation

    /// Resets cards to off-screen then triggers the staggered deal.
    /// `.animation(.delay(), value: allCardsDealt)` on each card handles
    /// the per-card timing — no manual Task loop needed.
    private func dealCards() {
        if reduceMotion {
            allCardsDealt = true
            return
        }
        // Snap off-screen without animation first.
        withAnimation(nil) { allCardsDealt = false }

        // Brief gap so SwiftUI commits the off-screen state before
        // flipping true and starting the staggered flights.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            allCardsDealt = true
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Curiosity Pile — Round 1") {
    // Director lives inside a wrapper view so @State drives the lifecycle correctly.
    // Setting curiosityDealTrigger before the view appears doesn't fire onChange
    // (onChange only triggers on changes, not initial values), so we toggle it
    // via onAppear instead.
    struct PreviewWrapper: View {
        @State private var director: VaylDirector = {
            let d = VaylDirector()
            d.curiosityPile = [
                CuriositySortCard(id: "p0", text: "I don't know what I actually want",  round: 1),
                CuriositySortCard(id: "p1", text: "We want different things",             round: 1),
                CuriositySortCard(id: "p2", text: "I wouldn't know how to ask for it",   round: 1),
                CuriositySortCard(id: "p3", text: "Jealousy comes up and gets stuck",    round: 1),
                CuriositySortCard(id: "p4", text: "We've lost some of our connection",   round: 1),
                CuriositySortCard(id: "p5", text: "I keep ending up in the same place",  round: 1),
                CuriositySortCard(id: "p6", text: "My reactions in intimacy surprise me",round: 1),
            ]
            return d
        }()

        var body: some View {
            GeometryReader { geo in
                ZStack {
                    AppColors.void.ignoresSafeArea()
                    CuriosityPhase(director: director, screenSize: geo.size)
                }
                .ignoresSafeArea()
            }
            .onAppear {
                // Toggle triggers onChange → dealCards() → staggered deal animation.
                director.curiosityDealTrigger.toggle()
            }
        }
    }

    return PreviewWrapper()
        .preferredColorScheme(.dark)
}
#endif
