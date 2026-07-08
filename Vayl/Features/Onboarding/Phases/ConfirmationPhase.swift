//
//  ConfirmationPhase.swift
//  Vayl
//

import SwiftUI

/// OB Phase — Confirmation (renders OBPhase.confirmation)
///
/// Entry: the felt settles + prompt breathes in → held beat → the six credential
/// cards deal out of the top-right corner deck onto the table along a bézier
/// corner-sweep (rightmost first, leftmost ends on top).
/// Tapping a settled card opens its edit half-sheet (via `director.editingCredential`).
/// Confirming is a SWIPE RIGHT on the fan — the keep gesture from CuriosityPhase,
/// asked of the whole hand ("does this feel true?"). Commit collapses the fan
/// into a deck, then advances to `.buildDeck`. No CTA chrome on the felt.
///
/// This view renders its own `VaylCardFace` symbol cards and never writes
/// VaylCardModel physics — `tableFade` is raised by the director's `runConfirmationEntry`.
struct ConfirmationPhase: View {

    let director: VaylDirector

    @Environment(\.realSafeArea)               private var safeArea
    @Environment(\.accessibilityReduceMotion)  private var reduceMotion

    @State private var dealt      = false
    @State private var exiting    = false

    // ── Swipe-right confirm (the CuriosityPhase keep gesture, fan-wide) ──
    @State private var armed            = false           // fan settled — swipe live
    @State private var fanDragX: CGFloat = 0       // damped follow during the drag
    @State private var thresholdCrossed = false           // → .selection tick (both ways)
    @State private var commitThunk      = false           // → .impact(.medium) on commit
    @State private var nudgeX: CGFloat = 0       // idle rightward cue
    @State private var nudgeTask: Task<Void, Never>?
    @State private var dealTickTask: Task<Void, Never>?   // landing-haptic loop
    @State private var exitTask: Task<Void, Never>?   // collapse → advance

    private let credentials  = OBCredential.allCases   // name, gender, mode, experienceLevel, context, curiosity

    // Tuned reference values.
    private let fanSpread: Double = 0.56
    private let dealStagger: Double = 0.10            // FEEL-GATE: snappier deal (was 0.19)
    private let dealArc: Double = 13              // % of screen height — bézier sweep peak
    private let dealLeadIn: Double = 0.5             // FEEL-GATE: covers only the cross-fade, then deal (was breatheHold 1.4 of empty felt)
    private let dealSpan: Double = 1.2             // FEEL-GATE: stagger tail + spring settle (was 1.9)
    private let exitStagger: Double = 0.12   // per-card delay, leftmost first — the gather reads card by card
    private let exitSpan: Double = 2.0    // FEEL-GATE: stagger tail (0.6) + FULL confirmGather settle (resp 0.8) before the swap — was 1.6, which advanced ~0.3s while the last card was still springing, popping the otherwise-identical deck handoff
    /// Same commit physics as CuriosityPhase — distance, or a committed flick.
    private let commitThreshold: CGFloat = 95

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                // The fan moves as one hand: damped drag-follow + idle nudge.
                ZStack {
                    ForEach(Array(credentials.enumerated()), id: \.element) { index, credential in
                        cardView(index: index, credential: credential, size: size)
                    }
                }
                .offset(x: fanDragX + nudgeX)
                // simultaneousGesture — VaylCardFace owns its own tap/drag, so a
                // plain .gesture here would lose drags that start on a card
                // (which is most of them). Card taps still edit; card-level
                // swipe events are ignored by tapHandler.
                .simultaneousGesture(fanSwipe(size: size))

            }
            .frame(width: size.width, height: size.height)
            .sensoryFeedback(.selection, trigger: thresholdCrossed)
            .sensoryFeedback(.impact(weight: .medium), trigger: commitThunk)
            .task { await runEntry(size: size) }
        }
        .onDisappear {
            nudgeTask?.cancel()
            dealTickTask?.cancel()
            exitTask?.cancel()
        }
        .accessibilityLabel("Confirmation phase")
        .accessibilityAction(named: "Confirm — this is me") { startExit() }
    }

    // MARK: - Fan swipe (the keep gesture, asked of the whole hand)

    private func fanSwipe(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 25)
            .onChanged { value in
                guard armed, !exiting, director.editingCredential == nil else { return }
                nudgeTask?.cancel()
                withAnimation(AppAnimation.spring.reduceMotionSafe) { nudgeX = 0 }
                let x = value.translation.width
                // Rightward follows damped; leftward rubber-bands hard — there
                // is no "pass" on yourself here, only the keep direction.
                fanDragX = x > 0 ? min(x * 0.5, size.width * 0.35) : x * 0.15
                let crossed = x >= commitThreshold
                if crossed != thresholdCrossed { thresholdCrossed = crossed }
            }
            .onEnded { value in
                thresholdCrossed = false
                guard armed, !exiting, director.editingCredential == nil else {
                    withAnimation(AppAnimation.cardSettle.reduceMotionSafe) { fanDragX = 0 }
                    return
                }
                let travelled = value.translation.width
                let projected = value.predictedEndTranslation.width
                if travelled >= commitThreshold || projected >= commitThreshold * 1.6 {
                    commitThunk.toggle()
                    startExit()
                } else {
                    withAnimation(AppAnimation.cardSettle.reduceMotionSafe) { fanDragX = 0 }
                }
            }
    }

    // MARK: - Card (extracted to keep the body type-checkable)

    @ViewBuilder
    private func cardView(index: Int, credential: OBCredential, size: CGSize) -> some View {
        let target = fanLayout(index: index, count: credentials.count, in: size)
        let shown  = dealt || reduceMotion
        let w      = cardWidth(in: size.width)
        let corner = cornerOrigin(in: size)
        // Each card lands on ITS OWN layer of the deck stack — offsets mirror
        // BuildDeckPhase.DeckStack exactly (top card index 0 at zero offset),
        // so the phase swap exchanges identical pixels, no visible object change.
        let pos    = exiting
            ? { let b = exitDeckPoint(in: size)
                return CGPoint(x: b.x + CGFloat(index) * 1.2,
                               y: b.y + CGFloat(index) * 1.6) }()
            : target.position
        let ang    = exiting ? 0   : (shown ? target.angle : -18)
        // Exit keeps the cards at their fan size — they sweep and flip into a
        // deck WITHOUT growing (growth reads as inflation, not gathering).
        // BuildDeckPhase opens its deck at this same fan-card scale; the later
        // size change is a camera zoom during the float, never object growth
        // (ceremony spec, seam).
        let scl    = exiting ? 1.0 : (shown ? 1 : 0.55)
        let opa    = shown ? 1.0 : 0.0
        // Flip container — CuriosityFlipCard idiom: two pre-rotated faces,
        // opacity crossfade, both driven by `exiting` through the exit animation.
        // The cards turn face-down as they collapse: their truths go private
        // as they're submitted to the table.
        ZStack {
            // +180 — the card turns over its RIGHT edge, the way a card flips
            // when pushed rightward; the commit gesture is a swipe right.
            VaylCardFace(content: content(for: credential), onAction: tapHandler(for: credential))
                .rotation3DEffect(.degrees(exiting ? 180 : 0),
                                  axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                .opacity(exiting ? 0 : 1)
            VaylCardBack()
                .rotation3DEffect(.degrees(exiting ? 0 : -180),
                                  axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                .opacity(exiting ? 1 : 0)
        }
            // flip is scoped tighter + faster than the sweep — cards arrive at
            // the deck already face-down, not flipping at the last instant
            .animation(exitFlipAnimation(index: index, count: credentials.count), value: exiting)
            .frame(width: w, height: w * 1.5)
            .rotationEffect(.degrees(ang))
            .scaleEffect(scl)
            .opacity(opa)
            .position(pos)
            .modifier(CornerSweep(progress: shown ? 1 : 0,
                                  corner: corner,
                                  target: target.position,
                                  control: dealControl(corner: corner, target: target.position, size: size)))
            .zIndex(Double(credentials.count - index))   // index 0 (leftmost) on top
            .animation(dealAnimation(index: index, count: credentials.count), value: dealt)
            .animation(exitMoveAnimation(index: index, count: credentials.count), value: exiting)
    }

    private func tapHandler(for credential: OBCredential) -> ((VaylCardAction) -> Void)? {
        guard dealt, !exiting else { return nil }   // inert while dealing / exiting
        return { action in
            if case .tapped = action { director.editingCredential = credential }
        }
    }

    // MARK: - Sequences

    @MainActor
    private func runEntry(size: CGSize) async {
        // The prompt is DEALER copy — typed Menlo via the canvas projection,
        // never a phase-local Text in a display face (one dealer, one voice).
        if reduceMotion {
            // Cards are visible from the first frame under RM — no beats to wait out.
            dealt = true
            armed = true
            director.projector.showDealerLineManual("Everything look right?")
        } else {
            // Lead-in covers only the phase cross-fade, then the six cards deal out
            // of the corner immediately (no empty-felt breathe), continuous with the
            // deck the user just pocketed. The question types WITH the deal, landing
            // as the fan settles, never asked of a blank table. One line, no lull.
            try? await Task.sleep(for: .seconds(dealLeadIn))
            dealt = true   // cards animate via their per-card dealAnimation
            director.projector.showDealerLineManual("Everything look right?")

            // One light tick per landing, riding the deal stagger.
            dealTickTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.35))
                let tick = UIImpactFeedbackGenerator(style: .light)
                tick.prepare()
                for _ in credentials.indices {
                    guard !exiting else { break }
                    tick.impactOccurred()
                    try? await Task.sleep(for: .seconds(dealStagger))
                }
            }

            try? await Task.sleep(for: .seconds(dealSpan))
            armed = true   // fan settled — the swipe is live
        }

        // Idle cue — if the user hasn't engaged after a beat, the dealer names
        // the gesture once and the fan nudges rightward on a sparse cadence.
        try? await Task.sleep(for: .seconds(reduceMotion ? 0.5 : 2.5))
        guard !exiting, director.editingCredential == nil else { return }
        director.projector.hideDealerLine()
        try? await Task.sleep(for: .milliseconds(300))
        guard !exiting, director.editingCredential == nil else { return }
        // Persistent (manual) — the directional cue stays coupled to the nudge
        // instead of auto-hiding while the fan keeps twitching silently. This is
        // the only swipe-RIGHT in the OB (every prior confirm was swipe-up), so
        // its worded cue must not time out. Hidden on commit (startExit).
        director.projector.showDealerLineManual("If that's you — swipe right.")
        startNudge(amplitude: size.width * 0.055)
    }

    /// Sparse rightward nudge on the whole fan — the curiosity keep direction.
    private func startNudge(amplitude: CGFloat) {
        nudgeTask?.cancel()
        guard !reduceMotion else { return }
        nudgeTask = Task { @MainActor in
            while !Task.isCancelled {
                withAnimation(AppAnimation.swipeHintFlick.reduceMotionSafe) { nudgeX = amplitude }
                try? await Task.sleep(for: .milliseconds(380))
                guard !Task.isCancelled else { break }
                withAnimation(AppAnimation.spring.reduceMotionSafe) { nudgeX = 0 }
                try? await Task.sleep(for: .milliseconds(6000))
                guard !Task.isCancelled else { break }
            }
        }
    }

    /// Confirm — collapse the fan into a deck, then hand off to buildDeck.
    private func startExit() {
        guard !exiting else { return }
        exiting = true   // cards collapse via the exit animation modifiers
        nudgeTask?.cancel()
        director.projector.hideDealerLine()
        // The committed drag offset bleeds out on a slow ease UNDER the gather —
        // a spring snap-back here moved the whole fan leftward, against the
        // swipe that just committed. The deck still lands at the seam point.
        // TOKEN-EXEMPT: exitSpan is computed from the per-card stagger so the fade
        // spans the whole gather — duration is derived, not a constant.
        withAnimation(.easeOut(duration: exitSpan).reduceMotionSafe) {
            fanDragX = 0
            nudgeX   = 0
        }
        exitTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.05 : exitSpan))
            director.advance(to: .buildDeck)
        }
    }

    // MARK: - Deal animation (rightmost card deals first)

    private func dealAnimation(index: Int, count: Int) -> Animation {
        if reduceMotion { return AppAnimation.fast }
        let delay = Double(count - 1 - index) * dealStagger
        return AppAnimation.confirmDeal.delay(delay)
    }

    // MARK: - Exit animation (rightmost card leaves first — the deal grammar, reversed home)

    /// Sweep into the deck: per-card staggered spring so the fan GATHERS card by
    /// card and each one decelerates INTO the stack. LEFTMOST first — the commit
    /// is a swipe right, so the closing wave travels left→right WITH the gesture
    /// (the swipe shoves the hand shut from its left edge).
    private func exitMoveAnimation(index: Int, count: Int) -> Animation {
        if reduceMotion { return AppAnimation.fast }
        let delay = Double(index) * exitStagger
        // 0.8 response — this is the keystone object moment (six credentials
        // become THE deck); at 0.5 the whole collapse read in ~0.35s, a snap.
        return AppAnimation.confirmGather.delay(delay)
    }

    /// The face-down flip rides the same stagger but resolves ~60% through the
    /// sweep — their truths go private on the way to the deck, not at arrival.
    private func exitFlipAnimation(index: Int, count: Int) -> Animation {
        if reduceMotion { return AppAnimation.fast }
        let delay = Double(index) * exitStagger
        return AppAnimation.confirmFlip.delay(delay)
    }

    // MARK: - Geometry

    /// 0.32 of screen width — trimmed so all six cards fit without clipping the edges.
    private func cardWidth(in screenWidth: CGFloat) -> CGFloat {
        min(screenWidth * 0.32, 230)
    }

    private func cornerOrigin(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width - AppLayout.cornerDeckRight - AppLayout.cornerDeckWidth / 2,
                y: AppLayout.cornerDeckTop + AppLayout.cornerDeckHeight / 2)
    }

    private func exitDeckPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width / 2, y: AppLayout.obTableCardCenterY(in: size.height))
    }

    /// Bézier control point for the corner sweep: pulled up-and-over toward center-top.
    private func dealControl(corner: CGPoint, target: CGPoint, size: CGSize) -> CGPoint {
        let midX = (corner.x + target.x) / 2
        let p1x  = midX + (size.width * 0.42 - midX) * 0.45
        let p1y  = min(corner.y, target.y) - size.height * (dealArc / 100)
        return CGPoint(x: p1x, y: p1y)
    }

    private func fanLayout(index: Int, count: Int, in size: CGSize) -> (position: CGPoint, angle: Double) {
        let h        = cardWidth(in: size.width) * 1.5
        let centerX  = size.width / 2
        let baseY    = AppLayout.obTableCardCenterY(in: size.height)   // on the felt
        let frac     = count <= 1 ? 0 : Double(index) / Double(count - 1) - 0.5   // −0.5 … 0.5
        let totalDeg = 10 + fanSpread * 42
        let ang      = frac * totalDeg
        let r        = h * (1.5 + fanSpread * 1.6)
        let radians  = ang * .pi / 180
        let x        = centerX + CGFloat(sin(radians)) * r
        let y        = baseY - CGFloat(cos(radians)) * r + r * 0.97
        return (CGPoint(x: x, y: y), ang)
    }

    // MARK: - Credential → phase symbol content

    private func content(for credential: OBCredential) -> VaylCardContent {
        let data = director.onboardingData
        switch credential {
        case .snapshot:
            // The one credential that IS the user's own words — show the sealed
            // sentence back, not an abstract symbol.
            let verb = DemoVerb(rawValue: data.demoVerb ?? "") ?? .want
            return .snapshot(verb: verb, noun: data.demoNoun ?? "",
                             toneProgress: verb.toneProgress, sealProgress: 1.0)

        case .name:
            return .typewriter(activeKey: -1, carriageProgress: 1.0)

        case .gender:
            return .radioTuner(signalStrength: 1.0, scanPhase: 0,
                               leftDialProgress: 0.5, rightDialProgress: 0.5)

        case .mode:
            return data.appMode == .together
                ? .dualController(activeButtonsFront: [], activeButtonsBack: [])
                : .controller(activeButtons: [])

        case .experienceLevel:
            let intensity: CandleIntensity
            switch data.nmStage {
            case .curious:     intensity = .curious
            case .exploring:   intensity = .exploring
            case .experienced: intensity = .experienced
            }
            return .candle(intensity: intensity, time: 0)

        case .context:
            return .context(number: "", title: "", subtitle: "", detail: "")

        case .curiosity:
            return .curiosity(category: "")
        }
    }
}

// MARK: - CornerSweep

/// Animatable geometry effect that moves a view (laid out at `target`) along a
/// quadratic bézier from `corner` → `control` → `target` as `progress` goes 0→1.
/// Driven by the per-card deal spring so the cards sweep up-and-over out of the
/// corner deck instead of travelling in a straight line.
private struct CornerSweep: GeometryEffect {
    var progress: Double
    let corner: CGPoint
    let target: CGPoint
    let control: CGPoint

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let t  = progress
        let mt = 1 - t
        let x  = mt * mt * corner.x + 2 * mt * t * control.x + t * t * target.x
        let y  = mt * mt * corner.y + 2 * mt * t * control.y + t * t * target.y
        return ProjectionTransform(CGAffineTransform(translationX: x - target.x, y: y - target.y))
    }
}
