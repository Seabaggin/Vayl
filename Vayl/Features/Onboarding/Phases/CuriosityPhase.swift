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
///   • Only the top card (pile[0]) carries animated content.
///     Beneath cards are shell-only for performance.
struct CuriosityPhase: View {

    let director:   VaylDirector
    let screenSize: CGSize

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Drives the staggered deal animation. Flips true to animate cards in,
    /// resets to false before each new deal so cards return off-screen first.
    @State private var allCardsDealt:       Bool = false
    /// Toggled on commit so .sensoryFeedback can fire .impact on each card exit.
    @State private var commitHapticTrigger: Bool = false

    // MARK: - Layout

    private var cardWidth:  CGFloat { AppLayout.obTableCardWidth(in: screenSize.width) * AppLayout.obTableCardCinematicScale }
    private var cardHeight: CGFloat { AppLayout.obTableCardHeight(in: screenSize.width) * AppLayout.obTableCardCinematicScale }

    // MARK: - Swipe Direction Indicators

    /// 0 → 1 as the top card moves right, peaks at the 95pt commit threshold.
    private var keepOpacity: Double {
        let x = Double(director.curiosityDragOffset.width)
        return x > 0 ? min(1.0, x / 95.0) : 0
    }

    /// 0 → 1 as the top card moves left, peaks at the 95pt commit threshold.
    private var passOpacity: Double {
        let x = Double(director.curiosityDragOffset.width)
        return x < 0 ? min(1.0, -x / 95.0) : 0
    }

    /// Y origin for off-screen cards waiting to deal in.
    /// Negative = above the table so cards slide down onto the surface,
    /// matching the dealer-is-above visual language used across OB phases.
    private var offScreenY: CGFloat { -(screenSize.height * 0.5 + cardHeight) }

    // MARK: - Body

    var body: some View {
        ZStack {

            // ── Round label ───────────────────────────────────────────
            roundLabel
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, screenSize.height * 0.10)

            // ── Card pile ─────────────────────────────────────────────
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
        .onAppear {
            director.beginCuriosityDemo(screenWidth: screenSize.width)
        }
        .onDisappear {
            director.curiositySequenceTask?.cancel()
        }
    }

    // MARK: - Round Label

    private var roundLabel: some View {
        Text(director.curiosityRoundIndex == 0 ? "Round 1 of 2" : "Round 2 of 2")
            .font(AppFonts.caption)
            .foregroundStyle(AppColors.textTertiary)
            // Hidden during the tutorial demo — there is no "round" yet.
            .opacity(director.curiosityDemoActive ? 0 : 0.50)
            .animation(AppAnimation.fast, value: director.curiosityRoundIndex)
            .animation(AppAnimation.fast, value: director.curiosityDemoActive)
    }

    // MARK: - Pile View

    private var pileView: some View {
        let pile = director.curiosityPile

        return ZStack {

            // ── Beneath cards (shell only, back → front) ──────────────
            // Rendered from highest index first so they stack correctly.
            // No topic text or ? animation — keeps frame rate solid
            // while the user is actively swiping the top card.
            if pile.count > 1 {
                ForEach(Array(pile.dropFirst().enumerated().reversed()), id: \.element.id) { i, _ in
                    shellCard(atDepth: i + 1, pileCount: pile.count)
                }
            }

            // ── Top card — full content + drag gesture ────────────────
            if let topCard = pile.first {
                VaylCardFace(content: .curiosity(category: topCard.text))
                    .frame(width: cardWidth, height: cardHeight)
                    // ── Directional indicators ────────────────────────────
                    // Stamp overlays live on the card face so they rotate
                    // with it during the drag arc. .allowsHitTesting(false)
                    // keeps them transparent to gesture recognition.
                    .overlay {
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
                                .frame(maxWidth: .infinity, maxHeight: .infinity,
                                       alignment: .topTrailing)
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
                                .frame(maxWidth: .infinity, maxHeight: .infinity,
                                       alignment: .topLeading)
                                .padding(AppSpacing.md)
                        }
                        .allowsHitTesting(false)
                    }
                    // Deal animation: y only, driven by allCardsDealt.
                    .offset(y: allCardsDealt ? 0 : offScreenY)
                    .animation(
                        reduceMotion
                            ? .easeOut(duration: 0.15)
                            : AppAnimation.cardSlide.delay(Double(pile.count - 1) * 0.06),
                        value: allCardsDealt
                    )
                    // Drag offset: director animates x+y explicitly (fling / snap-back).
                    .offset(director.curiosityDragOffset)
                    // Rotation proportional to drag — spec: never a fixed angle.
                    // ÷ screenWidth normalises across devices; × 18 caps the arc.
                    .rotationEffect(.degrees(
                        Double(director.curiosityDragOffset.width) / Double(screenSize.width) * 18.0
                    ))
                    // Disable user gesture while the director's demo sequence is running.
                    .allowsHitTesting(!director.curiosityDemoActive)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                director.onCuriosityDrag(offset: value.translation)
                            }
                            .onEnded { value in
                                if abs(value.translation.width) >= 95 {
                                    // Toggle before calling director so the haptic fires
                                    // on this frame, not after the async pop.
                                    commitHapticTrigger.toggle()
                                    director.commitCuriositySwipe(screenSize: screenSize)
                                } else {
                                    director.snapBackCuriosityCard()
                                }
                            }
                    )
            }
        }
        // Beneath cards settle into new stagger positions after each swipe.
        .animation(AppAnimation.cardSettle, value: pile.count)
    }

    /// One shell card at `depth` positions below the top card.
    /// Slight stagger offset + rotation gives the pile physical thickness.
    private func shellCard(atDepth depth: Int, pileCount: Int) -> some View {
        // Direction alternates so the pile tilts irregularly rather than fanning.
        let sign:     CGFloat = depth % 2 == 0 ? 1 : -1
        // Fixed pt-per-depth so pile thickness scales with card count:
        // a 7-card pile looks clearly deeper than a 3-card pile.
        let staggerX: CGFloat = CGFloat(depth) * 1.5 * sign
        let staggerY: CGFloat = CGFloat(depth) * 4.0
        let rotation: Double  = Double(depth) * 1.2 * Double(sign)
        let opacity:  Double  = max(0, 1.0 - Double(depth) * 0.05)

        // Bottom cards arrive first so they end up under the later arrivals.
        let dealDelay = Double(pileCount - 1 - depth) * 0.06

        return VaylCardFace()
            .frame(width: cardWidth, height: cardHeight)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .offset(x: staggerX, y: allCardsDealt ? staggerY : offScreenY)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.15)
                    : AppAnimation.cardSlide.delay(dealDelay),
                value: allCardsDealt
            )
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
