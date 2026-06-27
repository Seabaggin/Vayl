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

    // Live hand-off follow (Phase 4): the presented deck tracks the finger as it's handed up
    // (shared HandBackFollow). View-local; the director owns curiositySummaryOffset, so this
    // resolves to .zero inside the pocket flight on handoff.
    @State private var summaryDrag:         CGSize = .zero
    @State private var summaryArmed:        Bool   = false
    @State private var summarySelectionGen = UISelectionFeedbackGenerator()

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

    // MARK: - Squared-deck stack & deal tuning  (FEEL-GATE — tune on device)
    // The resting pile is a tight, single-direction squared deck (mirrors
    // VaylDeckStack — the same look the kept cards forge into at the phase end),
    // dealt in one confident cascade from a single origin above the table.
    // Promote to AppLayout/AppAnimation tokens once the feel is locked.

    /// Visible thickness cap. Cards deeper than this share the deepest layer's
    /// offset, so a 10-card pile reads as a ~4-thick deck, never a sprawl.
    private static let stackDepthCap:    Int     = 4
    /// Per-layer lateral step (one direction) — the deck's side bevel.
    private static let stackStepX:       CGFloat = 1.2
    /// Per-layer vertical step (one direction) — the deck's bottom bevel.
    private static let stackStepY:       CGFloat = 2.0
    /// Per-layer opacity falloff for the beneath cards, floored so the bevel
    /// reads as depth without turning murky.
    private static let stackOpacityStep: Double  = 0.045
    private static let stackMinOpacity:  Double  = 0.85
    /// Resting tilt of the squared deck. 0 = machine-flat; a whisper (≈0.4)
    /// reads as a hand-squared deck. Start flat.
    private static let stackRestTilt:    Double  = 0.0
    /// Inter-card deal delay — a confident cascade, not a lazy rain (was 0.06).
    private static let dealStagger:      Double  = 0.045
    /// Incoming tilt as each card flies off the dealer's deck; settles to the
    /// resting tilt on landing. 0 = straight drop.
    private static let dealIncomingTilt: Double  = -7.0

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
        .onChange(of: director.curiosity.dealTrigger) { _, _ in
            dealCards()
        }
        // Threshold crossing → selection haptic (fires both ways: in and out of threshold)
        .sensoryFeedback(.selection, trigger: director.curiosity.thresholdCrossed)
        // Commit → medium impact haptic (toggled by the view before calling director)
        .sensoryFeedback(.impact(weight: .medium), trigger: commitHapticTrigger)
        // Demo commits carry the same thunk — the gesture is taught WITH its
        // physical signature (the director toggles this only on demo swipes).
        .sensoryFeedback(.impact(weight: .medium), trigger: director.curiosity.demoCommitTrigger)
        .onAppear {
            director.curiosity.beginCuriosityDemo(screenWidth: screenSize.width)
        }
        .onDisappear {
            director.curiosity.sequenceTask?.cancel()
            summaryHintTask?.cancel()
        }
        // Tug loop on the presented deck — flick up, spring home, rest.
        .onChange(of: director.curiosity.summaryPresented) { _, presented in
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
        let pile = director.curiosity.pile

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
            if director.curiosity.summaryVisible {
                VaylDeckStack(size: CGSize(width: cardWidth, height: cardHeight), count: 4, bleedUp: true)   // FEEL-GATE: slim, recedes up so the halo sits flush on the bottom
                    .overlay(LiftHalo(visible: director.curiosity.summaryPresented))
                    .scaleEffect(director.curiosity.summaryScale)
                    // Tilt as the deck is handed up (shared HandBackFollow).
                    .rotationEffect(.degrees(HandBackFollow.tilt(for: summaryDrag.width, screenWidth: screenSize.width)))
                    .opacity(director.curiosity.summaryAlpha)
                    .offset(director.curiosity.summaryOffset)
                    .offset(y: summaryHintOffset)
                    .offset(summaryDrag)   // live hand-off follow (resolves into the pocket flight)
                    .contentShape(Rectangle())
                    .gesture(summaryHandoffDrag)
                    .allowsHitTesting(director.curiosity.summaryPresented)
            }
        }
    }

    /// One card in the pile. Structure is identical at every depth — only modifier
    /// *values* change with depth — so a card keeps its identity (and animates smoothly)
    /// as it rises from beneath to top. Only the top card carries the live drag + gesture.
    @ViewBuilder
    private func pileCard(card: CuriositySortCard, depth: Int, pileCount: Int) -> some View {
        let isTop = depth == 0
        let drag  = director.curiosity.dragOffset

        // Resting squared deck: every card offset the SAME direction by a small
        // step, capped after `stackDepthCap` layers so a 10-card pile reads as a
        // tight ~4-thick deck (top card centered), not a sprawling alternating pile.
        let layer:       CGFloat = CGFloat(min(depth, Self.stackDepthCap))
        let restX:       CGFloat = layer * Self.stackStepX
        let restY:       CGFloat = layer * Self.stackStepY
        let restRotate:  Double  = Self.stackRestTilt
        let cardOpacity: Double  = max(Self.stackMinOpacity, 1.0 - Double(layer) * Self.stackOpacityStep)
        // Bottom cards arrive first so they end up under the later arrivals.
        let dealDelay:   Double  = Double(pileCount - 1 - depth) * Self.dealStagger

        // Single confident deal: before landing, every card sits at ONE origin
        // (centered, above the table) and converges into the squared deck — a
        // dealt cascade, not 10 columns of rain. After landing, the top card
        // follows the finger; beneath cards hold the squared rest.
        let offsetX:  CGFloat = allCardsDealt ? (isTop ? drag.width  : restX) : 0
        let offsetY:  CGFloat = allCardsDealt ? (isTop ? drag.height : restY) : offScreenY
        // Incoming tilt settles to the resting tilt as the card lands (cards
        // flicked off the dealer's deck), then the top card tilts with the drag.
        let rotation: Double  = allCardsDealt
            ? (isTop ? Double(drag.width) / Double(screenSize.width) * 18.0 * Double(grabPivot)
                     : restRotate)
            : Self.dealIncomingTilt

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
            // Deal flight (x converges + y drops + tilt settles) — all driven by
            // allCardsDealt, so a live drag on the top card is never animated by
            // the deal curve (drag changes don't re-trigger this value).
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
                              && !director.curiosity.demoActive
                              && !director.curiosity.roundTransitioning)
            .gesture(curiosityDrag)
    }

    /// The just-committed card flying clear of the pile. Appears at the release position
    /// and is animated off-screen by the director, so it reads as the same card leaving —
    /// not a card vanishing while a new one pops in.
    @ViewBuilder
    private var flyingCardView: some View {
        if let flying = director.curiosity.flyingCard {
            let off = director.curiosity.flyingOffset
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
                director.curiosity.onCuriosityDrag(offset: value.translation)
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
                    director.curiosity.commitCuriositySwipe(screenSize: screenSize)
                } else {
                    director.curiosity.snapBackCuriosityCard()
                }
            }
    }

    /// Swipe-up on the presented deck — the handoff. Sibling-phase gate:
    /// distance OR a committed flick, the gesture taught in Name.
    private var summaryHandoffDrag: some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { value in
                summaryHintTask?.cancel()
                withAnimation(AppAnimation.spring.reduceMotionSafe) { summaryHintOffset = 0 }
                // Follow the finger as the forged deck is handed up (weighty, banded).
                summaryDrag = HandBackFollow.offset(for: value.translation,
                                                    cardWidth: cardWidth, cardHeight: cardHeight)
                let crossed = value.translation.height < -cardHeight * 0.14
                if crossed != summaryArmed { summaryArmed = crossed; summarySelectionGen.selectionChanged() }
            }
            .onEnded { value in
                summaryArmed = false
                let dy  = value.translation.height
                let pdy = value.predictedEndTranslation.height
                if dy < -cardHeight * 0.14 || pdy < -cardHeight * 0.5 {
                    commitHapticTrigger.toggle()
                    // Drift + tilt resolve INTO the pocket flight — no snap at the handoff.
                    withAnimation(AppAnimation.cardPocket.reduceMotionSafe) { summaryDrag = .zero }
                    director.curiosity.handoffCuriosityDeck(screenSize: screenSize)
                } else {
                    // Short of the threshold — settle the deck back to the presented anchor.
                    withAnimation(AppAnimation.cardSettle.reduceMotionSafe) { summaryDrag = .zero }
                }
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
#Preview("Curiosity Pile — full deal (10)") {
    // Director lives inside a wrapper view so @State drives the lifecycle correctly.
    // Setting curiosityDealTrigger before the view appears doesn't fire onChange
    // (onChange only triggers on changes, not initial values), so we toggle it
    // via onAppear instead. Loads the real 5+5 deck so the squared deck + cascade
    // read at the true depth.
    struct PreviewWrapper: View {
        @State private var director: VaylDirector = {
            let d = VaylDirector()
            d.curiosity.pile = d.curiosity.buildCuriosityPile(round: 1, onboardingData: d.onboardingData) + d.curiosity.buildCuriosityPile(round: 2, onboardingData: d.onboardingData)
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
                director.curiosity.dealTrigger.toggle()
            }
        }
    }

    return PreviewWrapper()
        .preferredColorScheme(.dark)
}
#endif
