//
//  BuildDeckPhase.swift
//  Vayl
//

import SwiftUI

/// OB Phase — Build Deck (renders OBPhase.buildDeck).
/// The forge ceremony, per the 2026-06-10 ceremony spec:
///   Beat 1 · the confirmed deck MELTS down through the felt (their truths go
///            under the table)
///   Beat 2 · the TABLE performs — spectrum pulses converge on the forge point
///   Beat 3 · the cased deck dissolves up LYING FLAT, rises to vertical, then
///            floats as the felt recedes (three calm impossibilities)
///   Beat 4 · stillness, dealer invitation
///   Beat 7 · founder letter sheet-peek exit (interim wiring — moves behind the
///            browse-or-idle trigger when the crack ceremony + reveal land)
///
/// Timing values below are raw on purpose — feel-tuning per the Build Protocol;
/// they become AppAnimation tokens once verified on device.
struct BuildDeckPhase: View {

    let director:   VaylDirector
    let screenSize: CGSize

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // sequence state
    @State private var started:    Bool = false
    @State private var deckShown:  Bool = true
    @State private var deckMelt:   Double = 0       // 0 intact → 1 fully under the felt
    @State private var meltDone:   Bool = false     // haptic trigger
    @State private var forgeStart: Date? = nil      // pulses run while non-nil
    @State private var caseShown:  Bool = false
    @State private var caseOpacity: Double = 0      // dissolve-up reveal
    @State private var caseRiseStart: Date? = nil   // flat→vertical pose driver
    @State private var caseFloat:  Bool = false     // felt → float position

    // founder letter sheet-peek (Beat 7)
    @State private var peekShown:     Bool = false
    @State private var sheetExpanded: Bool = false
    @State private var peekPressed:   Bool = false
    @State private var sheetDrag:     CGFloat = 0
    private let peekHeight: CGFloat = 76

    private var deckW:    CGFloat { AppLayout.obCardWidth(in: screenSize.width) }
    private var deckSize: CGSize  { CGSize(width: deckW, height: deckW * 1.5) }
    private var feltCenter:  CGPoint { CGPoint(x: screenSize.width / 2, y: AppLayout.obTableCardCenterY(in: screenSize.height)) }
    private var floatCenter: CGPoint { CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.42) }
    /// Where the deck enters the felt — its bottom edge on the table.
    private var forgePoint: CGPoint { CGPoint(x: feltCenter.x, y: feltCenter.y + deckSize.height / 2) }

    var body: some View {
        ZStack {
            // No background — the persistent canvas (void + atmosphere + FELT) shows through.

            // Beat 2 — the table performs around the forge point
            if let forgeStart {
                ForgePulses(center: forgePoint, startDate: forgeStart, reduceMotion: reduceMotion)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            // The slot in the felt — glows while anything passes through it
            SlotGlow(center: forgePoint, width: deckSize.width * 1.1)
                .opacity(slotGlowOpacity)

            // Beat 1 — the confirmed deck, melting down through the felt
            if deckShown {
                DeckStack(size: deckSize)
                    .modifier(MeltThroughFelt(progress: deckMelt, size: deckSize))
                    .position(feltCenter)
            }

            // Beat 3 — the cased deck: dissolves up flat, rises, floats
            if caseShown {
                MetallicCaseView(riseStart: caseRiseStart)
                    .frame(width: deckSize.width * 1.45, height: deckSize.height * 1.45)
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

    /// Slot glow tracks the ceremony: brightens as the deck melts through,
    /// breathes during the forge, flares again for the arrival, dies after.
    private var slotGlowOpacity: Double {
        if caseFloat { return 0 }
        if caseShown { return 0.85 }
        if forgeStart != nil { return 0.55 }
        return deckMelt * 0.8
    }

    // MARK: - Sequence (Beats 1–4 + interim peek)

    private func runSequence() {
        Task { @MainActor in
            // settle — the deck just arrived from confirmation; let it sit
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : 1.0))
            director.showDealerLine("From everything you've shown me…", hideAfter: 2.4)
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : 1.5))

            // Beat 1 — the deck melts down through the felt
            withAnimation(.easeIn(duration: 2.0).reduceMotionSafe) { deckMelt = 1 }
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : 2.0))
            meltDone = true
            deckShown = false

            // Beat 2 — the table works (pulses converge while the dealer speaks)
            withAnimation(AppAnimation.standard.reduceMotionSafe) { forgeStart = .now }
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.1 : 0.8))
            director.showDealerLine("…I'm building a deck that's yours alone.", hideAfter: 2.8)
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.3 : 3.2))

            // Beat 3a — the cased deck dissolves up, lying flat on the felt
            caseShown = true
            withAnimation(.easeOut(duration: 1.0).reduceMotionSafe) { caseOpacity = 1 }
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : 1.4))

            // Beat 3b — it rises from flat to vertical (pose driver in the case view)
            caseRiseStart = .now
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.1 : 1.6))

            // Beat 3c — it takes the air; the felt recedes beneath it
            withAnimation(.easeInOut(duration: 1.6).reduceMotionSafe) { caseFloat = true }
            director.recedeTableForForge()
            withAnimation(AppAnimation.exit.reduceMotionSafe) { forgeStart = nil }
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.3 : 2.2))

            // Beat 4 — stillness already passed; the invitation
            director.showDealerLine("This one's yours. Break it open.", hideAfter: 3.4)

            // Interim wiring: the peek arrives after a dwell. Moves behind the
            // browse-or-idle trigger once crack + reveal land (segments 5–7).
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.5 : 4.5))
            withAnimation(AppAnimation.enter.reduceMotionSafe) { peekShown = true }
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

// MARK: - The squared deck (real card backs — seam-matched to ConfirmationPhase's
// collapse, which ends face-down at this exact scale/point)

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

// MARK: - Beat 1: melt-through mask

/// The deck sinks straight down through a slot at its own bottom edge: the
/// visible region keeps its bottom pinned at the entry line while the top
/// descends — erased by the felt as it passes under.
private struct MeltThroughFelt: ViewModifier {
    var progress: Double   // 0 intact → 1 fully under
    var size: CGSize

    func body(content: Content) -> some View {
        content
            .offset(y: CGFloat(progress) * size.height)
            .mask(
                Rectangle()
                    .frame(height: max(0, size.height * (1 - progress)), alignment: .top)
                    .frame(maxHeight: .infinity, alignment: .top)
                    // counter the content offset so the mask stays pinned in
                    // screen space at the felt entry line
                    .offset(y: -CGFloat(progress) * size.height)
            )
    }
}

// MARK: - The felt slot (shared by melt + arrival)

/// A perspective-flattened seam of light on the felt where things pass through.
private struct SlotGlow: View {
    var center: CGPoint
    var width: CGFloat

    var body: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: AppColors.spectrumCyan.opacity(0.0),     location: 0.00),
                        .init(color: AppColors.spectrumPurple.opacity(0.55),  location: 0.50),
                        .init(color: AppColors.spectrumMagenta.opacity(0.0),  location: 1.00),
                    ],
                    startPoint: .leading,
                    endPoint:   .trailing
                )
            )
            .frame(width: width, height: 14)
            .blur(radius: 6)
            .position(center)
            .allowsHitTesting(false)
    }
}

// MARK: - Beat 2: the table performs

/// Spectrum pulse rings expanding on the felt plane around the forge point —
/// the table's own light, converging attention on where the work is happening.
/// Reduce Motion: a static soft under-glow, no rings.
private struct ForgePulses: View {
    var center: CGPoint
    var startDate: Date
    var reduceMotion: Bool

    var body: some View {
        if reduceMotion {
            staticGlow
        } else {
            TimelineView(.animation) { tl in
                Canvas { ctx, _ in
                    let t = tl.date.timeIntervalSince(startDate)
                    drawPulses(&ctx, t: t)
                }
            }
            .allowsHitTesting(false)
        }
    }

    private var staticGlow: some View {
        RadialGradient(
            colors: [AppColors.spectrumPurple.opacity(0.22), .clear],
            center: .center, startRadius: 0, endRadius: 120
        )
        .frame(width: 240, height: 120)
        .position(center)
        .allowsHitTesting(false)
    }

    private func drawPulses(_ ctx: inout GraphicsContext, t: Double) {
        // breathing under-glow — the work below the felt
        let breathe = 0.16 + 0.10 * (0.5 + 0.5 * sin(t * 2.1))
        let glowRect = CGRect(x: center.x - 130, y: center.y - 44, width: 260, height: 88)
        ctx.fill(
            Path(ellipseIn: glowRect),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: AppColors.spectrumPurple.opacity(breathe), location: 0),
                    .init(color: AppColors.spectrumPurple.opacity(0),       location: 1),
                ]),
                center: center, startRadius: 0, endRadius: 130
            )
        )

        // three staggered rings expanding outward on the felt plane,
        // escalating slightly with each cycle
        for i in 0..<3 {
            let raw = (t - Double(i) * 0.55) / 1.7
            guard raw > 0 else { continue }
            let p = raw.truncatingRemainder(dividingBy: 1)
            let r = 26 + p * 150
            let alpha = (1 - p) * 0.4
            let ring = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r * 0.30,
                                              width: r * 2, height: r * 0.60))
            ctx.stroke(
                ring,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: AppColors.spectrumCyan.opacity(alpha),    location: 0.0),
                        .init(color: AppColors.spectrumPurple.opacity(alpha),  location: 0.5),
                        .init(color: AppColors.spectrumMagenta.opacity(alpha), location: 1.0),
                    ]),
                    startPoint: CGPoint(x: center.x - r, y: center.y),
                    endPoint:   CGPoint(x: center.x + r, y: center.y)
                ),
                lineWidth: 1.2
            )
        }
    }
}
