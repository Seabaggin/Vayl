//
//  ConfirmationPhase.swift
//  Vayl
//

import SwiftUI

/// OB Phase — Confirmation (renders OBPhase.confirmation)
///
/// Entry: the felt settles + prompt breathes in → held beat → the six credential
/// cards deal out of the top-right corner deck onto the table along a bézier
/// corner-sweep (rightmost first, leftmost ends on top) → "This is me" CTA fades in.
/// Tapping a settled card opens its edit half-sheet (via `director.editingCredential`).
/// Confirming collapses the fan into a deck, then advances to `.buildDeck`.
///
/// This view renders its own `VaylCardFace` symbol cards and never writes
/// VaylCardModel physics — `tableFade` is raised by the director's `runConfirmationEntry`.
struct ConfirmationPhase: View {

    let director: VaylDirector

    @Environment(\.realSafeArea)               private var safeArea
    @Environment(\.accessibilityReduceMotion)  private var reduceMotion

    @State private var copyShown  = false
    @State private var dealt      = false
    @State private var ctaShown   = false
    @State private var pressedCTA = false
    @State private var exiting    = false

    private let credentials  = OBCredential.allCases   // name, gender, mode, experienceLevel, context, curiosity

    // Tuned reference values.
    private let fanSpread:    Double = 0.56
    private let dealStagger:  Double = 0.19
    private let dealArc:      Double = 13              // % of screen height — bézier sweep peak
    private let breatheHold:  Double = 1.4
    private let dealSpan:     Double = 1.3
    private let exitDuration: Double = 0.4

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                ForEach(Array(credentials.enumerated()), id: \.element) { index, credential in
                    cardView(index: index, credential: credential, size: size)
                }
                overlayCopy(size: size)
            }
            .frame(width: size.width, height: size.height)
            .task { await runEntry() }
        }
        .accessibilityLabel("Confirmation phase")
    }

    // MARK: - Card (extracted to keep the body type-checkable)

    @ViewBuilder
    private func cardView(index: Int, credential: OBCredential, size: CGSize) -> some View {
        let target = fanLayout(index: index, count: credentials.count, in: size)
        let shown  = dealt || reduceMotion
        let w      = cardWidth(in: size.width)
        let corner = cornerOrigin(in: size)
        let pos    = exiting ? exitDeckPoint(in: size) : target.position
        let ang    = exiting ? 0   : (shown ? target.angle : -18)
        // Exit scale targets the canonical OB deck size — both sides of the
        // confirmation→buildDeck boundary meet at face-down / obCard scale /
        // table center, so the phase swap is undetectable (ceremony spec, seam).
        let scl    = exiting ? AppLayout.obCardWidth(in: size.width) / w
                             : (shown ? 1 : 0.55)
        let opa    = shown ? 1.0 : 0.0
        // Flip container — CuriosityFlipCard idiom: two pre-rotated faces,
        // opacity crossfade, both driven by `exiting` through the exit animation.
        // The cards turn face-down as they collapse: their truths go private
        // as they're submitted to the table.
        ZStack {
            VaylCardFace(content: content(for: credential), onAction: tapHandler(for: credential))
                .rotation3DEffect(.degrees(exiting ? -180 : 0),
                                  axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                .opacity(exiting ? 0 : 1)
            VaylCardBack()
                .rotation3DEffect(.degrees(exiting ? 0 : 180),
                                  axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                .opacity(exiting ? 1 : 0)
        }
            .frame(width: w, height: w * 1.5)
            .rotationEffect(.degrees(ang))
            .scaleEffect(scl)
            .opacity(opa)
            .position(pos)
            .modifier(CornerSweep(progress: shown ? 1 : 0,
                                  corner:   corner,
                                  target:   target.position,
                                  control:  dealControl(corner: corner, target: target.position, size: size)))
            .zIndex(Double(credentials.count - index))   // index 0 (leftmost) on top
            .animation(dealAnimation(index: index, count: credentials.count), value: dealt)
            .animation(.easeIn(duration: exitDuration).reduceMotionSafe, value: exiting)
    }

    private func tapHandler(for credential: OBCredential) -> ((VaylCardAction) -> Void)? {
        guard dealt, !exiting else { return nil }   // inert while dealing / exiting
        return { action in
            if case .tapped = action { director.editingCredential = credential }
        }
    }

    // MARK: - Prompt + CTA

    @ViewBuilder
    private func overlayCopy(size: CGSize) -> some View {
        VStack(spacing: 0) {
            Text("Everything look right?")
                .font(AppFonts.prompt)
                .foregroundStyle(AppColors.textBody)
                .padding(.top, safeArea.top + AppSpacing.xl)
                .opacity(copyShown && !exiting ? 1 : 0)
                .animation(AppAnimation.slow.reduceMotionSafe, value: copyShown)
                .animation(AppAnimation.fast.reduceMotionSafe, value: exiting)

            Spacer()

            ctaButton
                .padding(.bottom, safeArea.bottom + AppSpacing.xl)
                .opacity(ctaShown && !exiting ? 1 : 0)
                .animation(AppAnimation.slow.reduceMotionSafe, value: ctaShown)
                .animation(AppAnimation.fast.reduceMotionSafe, value: exiting)
        }
    }

    private var ctaButton: some View {
        Text("This is me")
            .font(AppFonts.ctaLabel)
            .foregroundStyle(AppColors.textPrimary)
            .padding(.vertical, AppSpacing.md)
            .padding(.horizontal, AppSpacing.xl)
            .background(Capsule().strokeBorder(AppColors.spectrumBorder, lineWidth: 1.6))
            .scaleEffect(pressedCTA ? 0.96 : 1.0)
            .animation(AppAnimation.fast, value: pressedCTA)
            .sensoryFeedback(.impact(weight: .light), trigger: pressedCTA)
            .onTapGesture { startExit() }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressedCTA = true }
                    .onEnded   { _ in pressedCTA = false }
            )
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("This is me")
    }

    // MARK: - Sequences

    @MainActor
    private func runEntry() async {
        withAnimation(AppAnimation.slow.reduceMotionSafe) { copyShown = true }
        try? await Task.sleep(for: .seconds(reduceMotion ? 0.05 : breatheHold))
        dealt = true   // cards animate via their per-card dealAnimation
        try? await Task.sleep(for: .seconds(reduceMotion ? 0.05 : dealSpan))
        withAnimation(AppAnimation.slow.reduceMotionSafe) { ctaShown = true }
    }

    /// Confirm — collapse the fan into a deck, then hand off to buildDeck.
    private func startExit() {
        guard !exiting else { return }
        exiting = true   // cards collapse via the exit animation modifier
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.05 : exitDuration))
            director.advance(to: .buildDeck)
        }
    }

    // MARK: - Deal animation (rightmost card deals first)

    private func dealAnimation(index: Int, count: Int) -> Animation {
        if reduceMotion { return AppAnimation.fast }
        let delay = Double(count - 1 - index) * dealStagger
        return .spring(response: 0.55, dampingFraction: 0.86).delay(delay)
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
    let corner:  CGPoint
    let target:  CGPoint
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
