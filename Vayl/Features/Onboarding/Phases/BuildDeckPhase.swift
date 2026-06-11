//
//  BuildDeckPhase.swift
//  Vayl
//

import SwiftUI

/// OB Phase — Build Deck (renders OBPhase.buildDeck).
/// The forge ceremony, per the 2026-06-10 ceremony spec:
///   Beat 1 · the confirmed deck MELTS down through the felt (their truths go
///            under the table)
///   Beat 2 · the TABLE performs — its spectrum rim oscillates while it works
///   Beat 3 · the cased deck lies FLAT and lifeless, lifts to vertical, the
///            camera dollies in, and the hex material wakes on arrival
///   Beat 4 · stillness, dealer invitation
///   Beat 7 · founder letter sheet-peek exit (interim wiring — moves behind the
///            browse-or-idle trigger when the crack ceremony + reveal land)
///
/// Timing values below are raw on purpose — feel-tuning per the Build Protocol;
/// they become AppAnimation tokens once verified on device.
struct BuildDeckPhase: View {

    let director:   VaylDirector
    let screenSize: CGSize
    /// The table's spectrum rim — phases drive it (NamePhase/GenderPhase
    /// pattern). During the forge it oscillates: the TABLE is the performer.
    @Binding var tableRimBurst: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // sequence state
    @State private var started:    Bool = false
    @State private var deckShown:  Bool = true
    @State private var deckMelt:   Double = 0       // 0 intact → 1 fully under the felt
    @State private var meltDone:   Bool = false     // haptic trigger
    @State private var caseShown:  Bool = false
    @State private var caseOpacity: Double = 0      // dissolve-up reveal
    // .distantFuture = mounted lying FLAT, lifeless — the lift is assigned later.
    // (nil would mean "full float pose" and causes the double-rise bug.)
    @State private var caseRiseStart: Date? = .distantFuture
    @State private var latticeWake: Date = .distantFuture  // hex wakes AFTER the zoom
    @State private var caseFloat:  Bool = false     // felt → float position

    // founder letter sheet-peek (Beat 7)
    @State private var peekShown:     Bool = false
    @State private var sheetExpanded: Bool = false
    @State private var peekPressed:   Bool = false
    @State private var sheetDrag:     CGFloat = 0
    private let peekHeight: CGFloat = 76

    // Mirrors ConfirmationPhase.cardWidth(in:) — the deck arrives at FAN-card
    // scale (the collapse never grows the cards). The size change to the hero
    // case happens as a camera zoom during the float, not object growth.
    private var deckW:    CGFloat { min(screenSize.width * 0.32, 230) }
    private var deckSize: CGSize  { CGSize(width: deckW, height: deckW * 1.5) }

    /// Camera dolly-in during Beat 3c: the case scales up WHILE the felt
    /// recedes beneath it — object-up + background-away reads as the camera
    /// moving closer, never as the object inflating. Feel-tunable.
    private let floatZoom: CGFloat = 2.0
    private var feltCenter:  CGPoint { CGPoint(x: screenSize.width / 2, y: AppLayout.obTableCardCenterY(in: screenSize.height)) }
    private var floatCenter: CGPoint { CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.42) }

    var body: some View {
        ZStack {
            // No background — the persistent canvas (void + atmosphere + FELT) shows through.

            // Beat 1 — the confirmed deck, melting down through the felt.
            // The table itself reacts (rim oscillation via tableRimBurst) —
            // no overlay props on the felt.
            if deckShown {
                DeckStack(size: deckSize)
                    .modifier(MeltThroughFelt(progress: deckMelt, size: deckSize))
                    .position(feltCenter)
            }

            // Beat 3 — the cased deck: lies flat and lifeless where the cards
            // went under, lifts to vertical, then the camera dollies in; the
            // hex material wakes only after the zoom lands.
            if caseShown {
                MetallicCaseView(riseStart: caseRiseStart, latticeWakeStart: latticeWake)
                    .frame(width: deckSize.width, height: deckSize.height)
                    .scaleEffect(caseFloat ? floatZoom : 1.0)
                    .position(caseFloat ? floatCenter : feltCenter)
                    .opacity(caseOpacity)
            }

            // Beat 7 — founder letter peek: the exit affordance IS the destination
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
        .sensoryFeedback(.impact(weight: .medium), trigger: meltDone)   // the deck goes under
        .sensoryFeedback(.impact(weight: .heavy),  trigger: caseFloat)  // the case takes the air
        .accessibilityLabel("Build deck phase")
        .onAppear {
            guard !started else { return }
            started = true
            runSequence()
        }
    }

    // MARK: - Sequence (Beats 1–4 + interim peek)

    private func runSequence() {
        Task { @MainActor in
            // settle — the deck just arrived from confirmation; let it sit
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : 1.5))
            director.showDealerLine("From everything you've shown me…", hideAfter: 2.6)
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : 2.0))

            // Beat 1 — the deck melts down through the felt; the table's rim
            // begins its working oscillation (the table is the performer)
            withAnimation(.easeIn(duration: 2.6).reduceMotionSafe) { deckMelt = 1 }
            startRimOscillation()
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : 2.6))
            meltDone = true
            deckShown = false

            // breath — the table works alone for a moment
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.1 : 1.2))

            // Beat 2 — the dealer speaks over the working table
            director.showDealerLine("…I'm building a deck that's yours alone.", hideAfter: 3.0)
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.3 : 4.0))

            // Beat 3a — the cased deck lies flat where the cards went under —
            // no animation, no life yet (rise pending, lattice asleep)
            caseShown = true
            withAnimation(.easeOut(duration: 1.0).reduceMotionSafe) { caseOpacity = 1 }
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : 1.7))

            // Beat 3b — the lift: flat → vertical (pose driver in the case view)
            caseRiseStart = .now
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.1 : 1.9))

            // Beat 3c — the camera dollies in: the case takes the air and scales
            // up WHILE the felt recedes beneath it (zoom, not growth); the rim
            // settles as the table lets it go
            withAnimation(.easeInOut(duration: 2.0).reduceMotionSafe) { caseFloat = true }
            director.recedeTableForForge()
            withAnimation(.easeOut(duration: 1.4).reduceMotionSafe) { tableRimBurst = 0 }
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.3 : 2.2))

            // …and the hex material wakes upon zoom-in
            latticeWake = .now
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.1 : 0.9))

            // Beat 4 — stillness already passed; the invitation
            director.showDealerLine("This one's yours. Break it open.", hideAfter: 3.4)

            // Interim wiring: the peek arrives after a dwell. Moves behind the
            // browse-or-idle trigger once crack + reveal land (segments 5–7).
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.5 : 5.0))
            withAnimation(AppAnimation.enter.reduceMotionSafe) { peekShown = true }
        }
    }

    /// The table's working glow: the spectrum rim oscillates while the forge
    /// is active. Reduce Motion: a steady mid glow instead of the oscillation.
    private func startRimOscillation() {
        if reduceMotion {
            tableRimBurst = 0.3
        } else {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                tableRimBurst = 0.55
            }
        }
    }

    // MARK: - Sheet peek mechanics (Beat 7)

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

// MARK: - The squared deck (real card backs — six layers whose offsets mirror
// ConfirmationPhase's exit positions card-for-card, so the phase swap
// exchanges identical pixels)

private struct DeckStack: View {
    var size: CGSize
    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                VaylCardBack()
                    .frame(width: size.width, height: size.height)
                    .offset(x: CGFloat(5 - i) * 1.2, y: CGFloat(5 - i) * 1.6)
            }
        }
    }
}

// MARK: - Beat 1: melt-through mask

/// The deck sinks straight down through the felt: a fixed clipping window
/// whose bottom edge IS the entry line — the deck genuinely translates
/// downward and is clipped as it passes under, with a soft absorption fade
/// over the last stretch so the edge melts rather than slices.
private struct MeltThroughFelt: ViewModifier {
    var progress: Double   // 0 intact → 1 fully under
    var size: CGSize

    func body(content: Content) -> some View {
        content
            .offset(y: CGFloat(progress) * size.height * 1.08)
            .frame(width: size.width + 10, height: size.height, alignment: .top)
            .clipped()
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0.00),
                        .init(color: .black, location: 0.85),
                        .init(color: .clear, location: 1.00),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )
    }
}
