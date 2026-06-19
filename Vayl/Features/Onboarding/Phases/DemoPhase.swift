// Vayl/Features/Onboarding/Phases/DemoPhase.swift
//
// OB Phase — Demo · "The Snapshot Card" (renders OBPhase.demo)
//
// The user's FIRST card. Teaches the two core gestures (tap-to-lift,
// swipe-up-to-hand-back) AND runs a behavioral diagnostic disguised as a
// sentence completion: the user finishes "I [verb] [noun]." and the app
// triangulates verb × noun into an EmotionalRegister (DemoDictionary),
// reviving the cut CompassPhase Q3 signal.
//
// Scene:
//   arrival (table fade owned by director) → two intro lines → deal → flip →
//   "Pick it up." → TAP lifts (alive risen card, pulsing border) → compose
//   (verb drum + noun field, tone gradient shifts) → "Swipe up to seal it." →
//   SWIPE fuses + dissolves into spectrum particles + pockets (7th credential)
//   → commit register → name.
//
// Dealer copy uses the director's projected text (one voice, rendered by the
// canvas). The card mechanics adapt NamePhase's deal/flip/lift/pocket.

import SwiftUI

private enum DemoStage: Equatable {
    case intro, dealing, flipping, awaitingLift, composing, sealing, done
}

struct DemoPhase: View {

    let director:    VaylDirector
    let screenSize:  CGSize
    @Binding var tableRimBurst: Double

    // MARK: — Tasks
    @State private var sceneTask: Task<Void, Never>? = nil

    // MARK: — Card animation (mirrors NamePhase)
    @State private var stage:           DemoStage = .intro
    @State private var cardOffset:      CGSize    = .zero
    @State private var cardAngle:       Double    = 0
    @State private var cardAlpha:       Double    = 0
    @State private var flipScaleX:      Double    = 1.0
    @State private var showFace:        Bool      = false
    @State private var cardScale:       Double    = 1.0
    @State private var cardBlur:        Double    = 0

    // MARK: — Lift / compose
    @State private var cardLifted:      Bool      = false
    @State private var waitingForLift:  Bool      = false
    @State private var verb:            DemoVerb  = .want
    @State private var noun:            String    = ""
    @State private var nounPulse:       CGFloat   = 0
    @State private var borderPulse:     Bool      = false
    @State private var sentenceMelt:    Double    = 0   // 0 hidden → 1 "I want" settled onto the card

    // MARK: — Seal
    @State private var waitingForSeal:  Bool      = false
    @State private var sealProgress:    Double    = 0      // 0 composing → 1 fused
    @State private var dissolveProgress: Double   = 0      // 0 → 1 particle burst
    @State private var dissolveSeeds:   [DissolveSeed] = []
    @State private var sealBloom:       Double    = 0      // 0 → 1 spectrum bloom flash at seal

    // MARK: — Effects
    @State private var impactRingProgress: Double = 0
    @State private var flipBurstProgress:  Double = 0

    @FocusState private var nounFocused: Bool

    @State private var impactSoft   = UIImpactFeedbackGenerator(style: .soft)
    @State private var impactHeavy  = UIImpactFeedbackGenerator(style: .heavy)
    @State private var selectionGen = UISelectionFeedbackGenerator()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale)              private var displayScale

    private let maxNounLength = 14

    private var cardWidth: CGFloat {
        AppLayout.obTableCardWidth(in: screenSize.width) * AppLayout.obTableCardCinematicScale
    }
    private var cardHeight: CGFloat {
        AppLayout.obTableCardHeight(in: screenSize.width) * AppLayout.obTableCardCinematicScale
    }
    private var sentenceSize: CGFloat { min(cardWidth * 0.12, 30) }

    // Card centre in screen space — the sentence layer tracks this.
    private var cardCenter: CGPoint {
        CGPoint(x: screenSize.width  / 2 + cardOffset.width,
                y: screenSize.height / 2 + cardOffset.height)
    }

    // MARK: — Body

    var body: some View {
        ZStack {
            effectsLayer
            cardLayer
            if stage == .awaitingLift || stage == .composing || stage == .sealing {
                sentenceLayer
            }
        }
        .frame(width: screenSize.width, height: screenSize.height)
        // Make the whole frame hittable so the seal swipe registers anywhere on
        // the felt, not only on the card. Children (card tap, verb pill, noun
        // field) are hit-tested first, so this never steals their gestures.
        .contentShape(Rectangle())
        .gesture(
            // Empty onChanged is required to engage the recognizer (matches
            // NamePhase) — onEnded alone never fires.
            DragGesture()
                .onChanged { _ in }
                .onEnded { v in handleSwipe(v.translation) }
        )
        .onAppear { sceneTask = Task { await runScene() } }
        .onDisappear {
            sceneTask?.cancel(); sceneTask = nil
            waitingForLift = false; waitingForSeal = false
            director.hideDealerLine()
        }
    }

    // MARK: — Effects layer (impact ring + flip burst + dissolve burst)

    private var effectsLayer: some View {
        Canvas { context, size in
            let cx = cardCenter.x
            let cy = cardCenter.y

            if impactRingProgress > 0 {
                let ringW = cardWidth * 1.1 + (cardWidth * 2.2) * impactRingProgress
                let ringH = ringW * 0.23
                let a     = (1.0 - impactRingProgress) * 0.5
                if a > 0 {
                    var p = Path()
                    p.addEllipse(in: CGRect(x: cx - ringW/2, y: cy + cardHeight*0.48 - ringH/2,
                                            width: ringW, height: ringH))
                    context.stroke(p, with: .color(AppColors.spectrumPurple.opacity(a)), lineWidth: 1.0)
                }
            }

            if flipBurstProgress > 0 {
                let r = max(cardWidth, cardHeight) * 1.8 * flipBurstProgress
                let a = (1.0 - flipBurstProgress) * 0.45
                if a > 0 {
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .radialGradient(
                            Gradient(stops: [
                                .init(color: AppColors.spectrumPurple.opacity(a),       location: 0),
                                .init(color: AppColors.spectrumCyan.opacity(a * 0.45),  location: 0.45),
                                .init(color: AppColors.spectrumCyan.opacity(0),         location: 1),
                            ]),
                            center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: r
                        )
                    )
                }
            }

            // Seal bloom — a quick bright spectrum flash from the sentence as it
            // breaks apart. Blooms tight + bright, then widens + fades.
            if sealBloom > 0 {
                let r = max(cardWidth, cardHeight) * 1.7 * sealBloom
                let a = (1.0 - sealBloom) * 0.55
                if a > 0 {
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .radialGradient(
                            Gradient(stops: [
                                .init(color: Color.white.opacity(a * 0.5),               location: 0),
                                .init(color: AppColors.spectrumPurple.opacity(a),        location: 0.18),
                                .init(color: AppColors.spectrumMagenta.opacity(a * 0.5), location: 0.5),
                                .init(color: AppColors.spectrumCyan.opacity(0),          location: 1),
                            ]),
                            center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: r
                        )
                    )
                }
            }

            // Particle dissolve — motes break off the SENTENCE band (not the whole
            // card), drift up-and-toward-corner with a twinkle, and fade out.
            if dissolveProgress > 0 {
                let t = dissolveProgress
                for s in dissolveSeeds {
                    let tw  = 0.7 + 0.3 * sin(t * 9 + s.tw)          // size + alpha twinkle
                    let px  = cx + s.ox + s.vx * t
                    let py  = cy + s.oy + s.vy * t - Double(cardHeight) * 0.22 * (t * t)  // arc up
                    let a   = (1.0 - t) * s.opacity * tw
                    guard a > 0.01 else { continue }
                    let rad = max(0.2, s.size * (1.0 - t * 0.25) * tw)
                    let rect = CGRect(x: px - rad, y: py - rad, width: rad * 2, height: rad * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(s.color.opacity(a)))
                    // Hot core on the larger motes.
                    if s.size > 2.6 {
                        let cr = rad * 0.42
                        context.fill(
                            Path(ellipseIn: CGRect(x: px - cr, y: py - cr, width: cr * 2, height: cr * 2)),
                            with: .color(Color.white.opacity(a * 0.7))
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    // MARK: — Card layer

    private var cardLayer: some View {
        Group {
            if !showFace {
                VaylCardBack()
            } else {
                // Blank alive shell + tone wash. The sentence is a separate
                // unmirrored layer (the flip ends at scaleX −1; a child would mirror).
                VaylCardFace(content: .blank)
                    .overlay(toneWash)
            }
        }
        .drawingGroup()
        .frame(width: cardWidth, height: cardHeight)
        .overlay(aliveBorder)
        .overlay(LiftHalo(visible: cardLifted))
        .scaleEffect(x: flipScaleX, y: 1.0)
        .scaleEffect(cardScale)
        .rotationEffect(.degrees(cardAngle))
        .offset(cardOffset)
        .blur(radius: cardBlur)
        .opacity(cardAlpha * (1.0 - dissolveProgress))
    }

    private var toneWash: some View {
        RadialGradient(
            colors: [toneColor.opacity(0.18), .clear],
            center: .center, startRadius: 0, endRadius: cardWidth * 0.72
        )
        .animation(AppAnimation.standard, value: verb)
        .allowsHitTesting(false)
    }

    /// Slow intermittent spectrum pulse — gives the lifted card "life."
    private var aliveBorder: some View {
        RoundedRectangle(cornerRadius: AppRadius.obCard)
            .strokeBorder(AppColors.spectrumBorder, lineWidth: 1.4)
            .blur(radius: 2)
            .opacity(borderPulse ? 0.85 : 0.25)
            .ambientAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                              value: borderPulse)
            .opacity(cardLifted ? 1 : 0)
            .animation(AppAnimation.standard, value: cardLifted)
            .allowsHitTesting(false)
    }

    private var toneColor: Color {
        switch verb {
        case .need:   return AppColors.spectrumCyan
        case .want:   return AppColors.spectrumPurple
        case .desire: return AppColors.spectrumMagenta
        }
    }

    // MARK: — Sentence layer (interactive — separate so the flip never mirrors it)

    private var sentenceLayer: some View {
        VStack(spacing: cardHeight * 0.05) {
            // Line 1 — "I want". Melts onto the card before the tap: blur resolves,
            // it settles down and condenses as it "sets" on the surface.
            HStack(spacing: cardWidth * 0.03) {
                Text("I")
                    .font(AppFonts.display(sentenceSize, weight: .medium, relativeTo: .title))
                    .foregroundStyle(AppColors.textPrimary)
                verbView
            }
            .opacity(sentenceMelt)
            .blur(radius: (1 - sentenceMelt) * 9)
            .scaleEffect(0.92 + 0.08 * sentenceMelt)
            .offset(y: (1 - sentenceMelt) * -cardHeight * 0.03)

            // Line 2 — the live word (blinking cursor when empty). Always laid out
            // (reserves its line height); only interactive once the card is lifted.
            nounField
        }
        .frame(width: cardWidth * 0.86)
        .scaleEffect(cardScale)
        .position(cardCenter)
        .opacity(stage == .sealing ? (1.0 - dissolveProgress) : 1.0)
        // Display-only until composing — taps during await-lift fall through to
        // the card's lift gesture.
        .allowsHitTesting(stage == .composing)
    }

    /// Tappable verb — white, extra-bold. Cycles need → want → desire on tap; the
    /// word slides vertically (odometer) so the change is legible. A thin spectrum
    /// underline hints it's interactive; the intro cycle teaches that it changes.
    private var verbView: some View {
        ZStack {
            Text(verb.rawValue)
                .font(AppFonts.display(sentenceSize, weight: .bold, relativeTo: .title))
                .foregroundStyle(.white)
                .id(verb)
                .transition(.push(from: .bottom).combined(with: .opacity))
        }
        .frame(height: sentenceSize * 1.28)
        .fixedSize()
        .clipped()
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.spectrumBorder)
                .frame(height: 1.5)
                .opacity((1 - sealProgress) * 0.45)
        }
        .contentShape(Rectangle())
        .onTapGesture { cycleVerb() }
    }

    /// The one living element — the typed word, rendered as a spectrum LivingText.
    /// An invisible TextField beneath captures input and shows the blinking caret;
    /// LivingText overlays it with the breathing gradient (sized to the word, so it
    /// tracks length as you type). Empty + focused = just the caret.
    private var nounField: some View {
        TextField("", text: $noun)
            .font(AppFonts.display(sentenceSize, weight: .semibold, relativeTo: .title))
            .multilineTextAlignment(.center)
            .foregroundStyle(.clear)                 // invisible — LivingText draws the word
            .tint(AppColors.accentSecondary)         // visible caret
            .fixedSize()
            .frame(minWidth: cardWidth * 0.12)
            .focused($nounFocused)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(.done)
            .onSubmit { attemptSealFromKeyboard() }
            .overlay {
                if !noun.isEmpty {
                    LivingText(text: noun,
                               font: AppFonts.display(sentenceSize, weight: .semibold, relativeTo: .title))
                        .allowsHitTesting(false)
                }
            }
            .offset(x: nounPulse)
            .onChange(of: noun) { _, new in
                // Reject spaces (pulse), cap length.
                let filtered = String(new.filter { $0 != " " }.prefix(maxNounLength))
                if filtered != new {
                    noun = filtered
                    pulseNoun()
                }
                updateSealArming()
            }
    }

    // MARK: — Scene

    @MainActor
    private func runScene() async {
        // Felt fades in via director.runDemoEntry (≈1.4s). Hold for it.
        try? await Task.sleep(for: .milliseconds(800))
        guard !Task.isCancelled else { return }

        // ── Two intro lines (pulled from NamePhase) ───────────────
        let line1 = "The things worth learning about yourself rarely surface on their own."
        director.showDealerLineManual(line1)
        try? await Task.sleep(for: .milliseconds(AppDealerTyping.typeDuration(line1) + AppDealerTyping.hangLong))
        guard !Task.isCancelled else { return }
        director.hideDealerLine()
        try? await Task.sleep(for: .milliseconds(200))
        guard !Task.isCancelled else { return }

        let line2 = "Consider this your introduction."
        director.showDealerLineManual(line2)
        try? await Task.sleep(for: .milliseconds(AppDealerTyping.typeDuration(line2) + AppDealerTyping.hangShort))
        guard !Task.isCancelled else { return }

        // ── Deal + flip ───────────────────────────────────────────
        stage = .dealing
        await dealCard()
        guard !Task.isCancelled else { return }
        director.hideDealerLine()
        await centerCard()
        await performFlipWithBurst()
        guard !Task.isCancelled else { return }
        try? await Task.sleep(for: .milliseconds(220))

        // ── "I want" melts onto the card ──────────────────────────
        stage = .awaitingLift
        withAnimation(reduceMotion ? .easeOut(duration: 0.25) : .easeOut(duration: 1.05)) {
            sentenceMelt = 1.0
        }
        try? await Task.sleep(for: .milliseconds(400))
        guard !Task.isCancelled else { return }

        // ── Tease the verb cycling so the user knows the word changes ──
        await runVerbIntroCycle()
        guard !Task.isCancelled else { return }

        // ── Auto-lift into composing state ────────────────────────
        withAnimation(AppAnimation.cardLift.reduceMotionSafe) {
            cardLifted = true
            cardOffset = CGSize(width: 0, height: screenSize.height * 0.42 - screenSize.height / 2)
            cardScale  = 1.12
        }
        borderPulse = true   // alive pulse begins

        try? await Task.sleep(for: .milliseconds(360))
        guard !Task.isCancelled else { return }
        
        stage = .composing
        let composeLine = "Say what's true — one word."
        director.showDealerLineManual(composeLine, anchorYFrac: 0.15)
        
        // Focus the field only AFTER the dealer finishes asking. A flat 700ms
        // summoned the keyboard mid-sentence (this line types for ~1.5s) — the
        // instruction must lead the action, not race it.
        try? await Task.sleep(for: .milliseconds(AppDealerTyping.typeDuration(composeLine) + AppDealerTyping.hangShort))
        guard !Task.isCancelled else { return }
        nounFocused = true
    }

    /// One slot-machine pass through the verbs, landing back on `want`, so the
    /// user sees the word is changeable before they're asked to pick.
    @MainActor
    private func runVerbIntroCycle() async {
        guard !reduceMotion else { return }
        // want (current) → need → desire → want.
        for v in [DemoVerb.need, .desire, .want] {
            withAnimation(.easeInOut(duration: 0.24)) { verb = v }
            selectionGen.selectionChanged()
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
        }
        try? await Task.sleep(for: .milliseconds(160))
    }

    // MARK: — Deal / center / flip (adapted from NamePhase)

    @MainActor
    private func dealCard() async {
        if reduceMotion {
            cardAlpha = 1
            return
        }
        cardAlpha = 0
        guard let deal = await director.dealSingleCard(screenSize: screenSize, scale: displayScale) else {
            cardAlpha = 1; return
        }
        guard !Task.isCancelled else { return }
        cardOffset = deal.offset
        cardAngle  = deal.angle
        cardAlpha  = 1
        try? await Task.sleep(for: .milliseconds(32))
        director.cardFlightScene.clearCard(id: deal.flightID)
    }

    @MainActor
    private func centerCard() async {
        withAnimation(AppAnimation.cardCenter) {
            cardOffset = CGSize(width:  screenSize.width  * 0.50 - screenSize.width  / 2,
                                height: screenSize.height * 0.55 - screenSize.height / 2)
            cardAngle = 0
        }
        try? await Task.sleep(for: .milliseconds(420))
    }

    @MainActor
    private func performFlipWithBurst() async {
        stage = .flipping
        impactRingProgress = 0
        withAnimation(AppAnimation.impactRingDecay) { impactRingProgress = 1.0 }
        flipBurstProgress = 0
        withAnimation(AppAnimation.flipBurstDecay) { flipBurstProgress = 1.0 }
        tableRimBurst = 1.0
        withAnimation(AppAnimation.rimBurstDecay) { tableRimBurst = 0.0 }

        if reduceMotion { showFace = true; flipScaleX = -1.0; return }
        withAnimation(AppAnimation.cardFlipHalf) { flipScaleX = 0.0 }
        try? await Task.sleep(for: .milliseconds(290))
        showFace = true
        withAnimation(AppAnimation.cardFlipHalf) { flipScaleX = -1.0 }
        try? await Task.sleep(for: .milliseconds(290))
    }

    // MARK: — Compose helpers

    /// Tap cycles need → want → desire → need.
    private func cycleVerb() {
        guard stage == .composing else { return }
        let all = DemoVerb.allCases
        guard let i = all.firstIndex(of: verb) else { return }
        withAnimation(AppAnimation.fast) { verb = all[(i + 1) % all.count] }
        selectionGen.selectionChanged()
    }

    private func pulseNoun() {
        impactSoft.impactOccurred()
        // Single self-settling spring — the old asyncAfter(0.08) settle fired
        // uncancelled after teardown.
        nounPulse = -6
        withAnimation(.interpolatingSpring(stiffness: 320, damping: 14)) { nounPulse = 0 }
    }

    private func updateSealArming() {
        let armed = !noun.trimmingCharacters(in: .whitespaces).isEmpty
        guard armed != waitingForSeal else { return }
        waitingForSeal = armed
        // Since we removed the swipe-up lesson from DemoPhase, we don't ask them to swipe up.
        // We just remind them to hit 'return'/'done' on the keyboard if armed.
        director.showDealerLineManual(armed ? "Press return when you're ready." : "Say what's true — one word.",
                                      anchorYFrac: 0.15)
    }

    private func attemptSealFromKeyboard() {
        // Done key seals too (parity with swipe) once a word exists.
        guard waitingForSeal else { return }
        nounFocused = false
        Task { @MainActor in await performSeal() }
    }

    // MARK: — Swipe (teaches SWIPE / seals)

    @MainActor
    private func handleSwipe(_ translation: CGSize) {
        guard translation.height < -AppLayout.swipeSubmitThreshold else { return }
        guard stage == .composing, waitingForSeal else { return }
        nounFocused = false
        Task { @MainActor in await performSeal() }
    }

    // MARK: — Seal → dissolve → pocket → commit

    @MainActor
    private func performSeal() async {
        guard stage == .composing else { return }
        stage = .sealing
        waitingForSeal = false
        borderPulse = false
        impactHeavy.impactOccurred()
        director.hideDealerLine()

        // 1 — fuse the sentence (chevron + prompt resolve into a clean line).
        withAnimation(.easeInOut(duration: 0.35)) { sealProgress = 1.0 }
        try? await Task.sleep(for: .milliseconds(420))
        guard !Task.isCancelled else { return }

        // 2 — break the sentence into spectrum motes + a bloom flash while the
        //     card pockets.
        if !reduceMotion {
            dissolveSeeds = Self.makeSeeds(cardW: cardWidth, cardH: cardHeight)
            withAnimation(.easeOut(duration: 0.5)) { sealBloom = 1.0 }
            withAnimation(.easeOut(duration: 1.0)) { dissolveProgress = 1.0 }
            try? await Task.sleep(for: .milliseconds(120))   // let the motes lift off before the card flies
        }
        await pocketCard()

        // 3 — write data + credit the deck (director owns the data/routing).
        director.commitDemoSnapshot(verb: verb, noun: noun)

        // 4 — a breath on the cleared felt, then hand to name.
        stage = .done
        try? await Task.sleep(for: .milliseconds(reduceMotion ? 120 : 360))
        guard !Task.isCancelled else { return }
        director.advance(to: .name)
    }

    @MainActor
    private func pocketCard() async {
        let cornerX = screenSize.width  - AppLayout.cornerDeckRight - AppLayout.cornerDeckWidth  / 2
        let cornerY = AppLayout.cornerDeckTop + AppLayout.cornerDeckHeight / 2
        withAnimation(AppAnimation.cardPocket.reduceMotionSafe) {
            cardLifted = false
            cardOffset = CGSize(width:  cornerX - screenSize.width  / 2,
                                height: cornerY - screenSize.height / 2)
            cardScale  = AppLayout.cornerDeckWidth / cardWidth
        }
        withAnimation(.easeIn(duration: 0.2).delay(0.32)) { cardAlpha = 0 }
        try? await Task.sleep(for: .milliseconds(reduceMotion ? 80 : 480))
    }

    // MARK: — Dissolve seeds

    private struct DissolveSeed {
        let ox, oy:  Double    // spawn offset from card center — across the sentence band
        let vx, vy:  Double    // drift (rightward + upward bias, toward the corner deck)
        let size:    Double
        let opacity: Double
        let color:   Color
        let tw:      Double    // twinkle phase
    }

    private static func makeSeeds(cardW: CGFloat, cardH: CGFloat) -> [DissolveSeed] {
        let palette = [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta]
        let w = Double(cardW), h = Double(cardH)
        return (0..<48).map { _ in
            DissolveSeed(
                ox:      Double.random(in: -w * 0.36 ... w * 0.36),    // across the words
                oy:      Double.random(in: -h * 0.12 ... h * 0.12),
                vx:      Double.random(in: -w * 0.18 ... w * 0.55),    // rightward bias → corner deck
                vy:      Double.random(in: -h * 0.6  ... -h * 0.1),    // upward
                size:    Double.random(in: 1.2 ... 4.2),
                opacity: Double.random(in: 0.5 ... 0.95),
                color:   palette[Int.random(in: 0..<palette.count)],
                tw:      Double.random(in: 0 ..< (.pi * 2))
            )
        }
    }
}
