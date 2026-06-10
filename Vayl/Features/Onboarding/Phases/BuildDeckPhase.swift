//
//  BuildDeckPhase.swift
//  Vayl
//

import SwiftUI

/// OB Phase — Build Deck (renders OBPhase.buildDeck).
/// The "forge" ceremony, ON the felt (the canvas table stays visible): the squared deck
/// LIFTS off the felt and rises into the air; spectrum ribbons weave around it as it builds;
/// the cased deck floats above. (WIP — tap→crack→disintegrate + reveal carousel are next.)
struct BuildDeckPhase: View {

    let director:   VaylDirector
    let screenSize: CGSize

    @State private var weaveStart: Date = .now
    @State private var lift:       Double = 0     // 0 = on the felt, 1 = floated up
    @State private var caseShown:  Bool = false
    @State private var started:    Bool = false

    // Founder letter sheet-peek (ceremony spec Beat 7): the letter itself is
    // the exit affordance. Expand FULLY first, advance second — the phase swap
    // happens behind the covered screen.
    @State private var peekShown:     Bool = false
    @State private var sheetExpanded: Bool = false
    @State private var peekPressed:   Bool = false
    @State private var sheetDrag:     CGFloat = 0
    private let peekHeight: CGFloat = 76

    private var deckW:    CGFloat { AppLayout.obCardWidth(in: screenSize.width) }
    private var deckSize: CGSize  { CGSize(width: deckW, height: deckW * 1.5) }
    private var feltCenter:  CGPoint { CGPoint(x: screenSize.width / 2, y: AppLayout.obTableCardCenterY(in: screenSize.height)) }
    private var floatCenter: CGPoint { CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.42) }
    private var deckPos: CGPoint {
        CGPoint(x: feltCenter.x, y: feltCenter.y + (floatCenter.y - feltCenter.y) * CGFloat(lift))
    }

    var body: some View {
        ZStack {
            // No background — the persistent canvas (void + atmosphere + FELT) shows through.

            if !caseShown {
                // the squared deck lifting off the felt …
                DeckStack(size: deckSize)
                    .position(deckPos)
                // … with spectrum ribbons weaving around it as it builds
                DeckWrapView(center: deckPos, deckSize: deckSize, startDate: weaveStart, intensity: lift)
                    .ignoresSafeArea()
            } else {
                // the cased deck, floating above the felt
                MetallicCaseView()
                    .frame(width: deckSize.width * 1.45, height: deckSize.height * 1.45)
                    .position(floatCenter)
                    .transition(.opacity)
            }

            // Founder letter peek — the exit affordance IS the destination.
            if peekShown {
                FounderLetterSheet { EmptyView() }
                    .frame(width: screenSize.width, height: screenSize.height)
                    .offset(y: sheetOffset)
                    .scaleEffect(peekPressed && !sheetExpanded ? 0.99 : 1.0)
                    .sensoryFeedback(.impact(weight: .light), trigger: sheetExpanded)
                    .onTapGesture { expandSheet() }
                    .gesture(peekDragGesture)
                    .transition(.move(edge: .bottom))
                    .accessibilityLabel("A note from the founder")
                    .accessibilityHint("Opens the founder letter")
                    .accessibilityAddTraits(.isButton)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Build deck phase")
        .onAppear {
            guard !started else { return }
            started = true
            weaveStart = .now
            runSequence()
        }
    }

    private func runSequence() {
        director.showDealerLine("From everything you've shown me…", hideAfter: 2.6)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            // the deck lifts off the felt while the ribbons wrap it
            withAnimation(.easeInOut(duration: 3.2)) { lift = 1 }

            try? await Task.sleep(for: .seconds(2.2))
            director.showDealerLine("…I'm building a deck that's yours alone.", hideAfter: 2.6)

            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.easeOut(duration: 0.8)) { caseShown = true }

            try? await Task.sleep(for: .milliseconds(900))
            director.showDealerLine("This one's yours. Break it open.", hideAfter: 3.4)

            // Interim wiring: the peek arrives after a dwell. Once the crack
            // ceremony + reveal land (segments 5–7), this moves behind the
            // browse-or-idle trigger per the ceremony spec.
            try? await Task.sleep(for: .seconds(4.0))
            withAnimation(AppAnimation.enter.reduceMotionSafe) { peekShown = true }
        }
    }

    // MARK: - Sheet peek mechanics

    /// Top of the sheet in screen space: peeking at the bottom edge → covering
    /// the screen. Drag adjusts from the resting detent; never above 0.
    private var sheetOffset: CGFloat {
        let resting = sheetExpanded ? 0 : screenSize.height - peekHeight
        return max(0, resting + sheetDrag)
    }

    private var peekDragGesture: some Gesture {
        DragGesture()
            .onChanged { v in
                peekPressed = true
                guard !sheetExpanded else { return }
                sheetDrag = v.translation.height   // negative = pulling up
            }
            .onEnded { v in
                peekPressed = false
                guard !sheetExpanded else { return }
                if v.translation.height < -60 {
                    expandSheet()
                } else {
                    withAnimation(AppAnimation.spring.reduceMotionSafe) { sheetDrag = 0 }
                }
            }
    }

    /// Expand FULLY, then advance — the swap to FounderLetterPhase happens
    /// while the sheet covers the screen (the curtain).
    private func expandSheet() {
        guard !sheetExpanded else { return }
        withAnimation(AppAnimation.enter.reduceMotionSafe) {
            sheetExpanded = true
            sheetDrag = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(550)) // expansion settle
            director.advance(to: .founderLetter)
        }
    }
}

// MARK: - The squared deck as it lifts (real card backs — seam-matched to
// ConfirmationPhase's collapse, which ends face-down at this exact scale/point)

private struct DeckStack: View {
    var size: CGSize
    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                VaylCardBack()
                    .frame(width: size.width, height: size.height)
                    .offset(x: CGFloat(4 - i) * 1.2, y: CGFloat(4 - i) * 1.6)
            }
        }
    }
}
