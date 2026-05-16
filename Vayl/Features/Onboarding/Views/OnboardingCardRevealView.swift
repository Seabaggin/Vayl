// Features/Onboarding/Views/OnboardingCardRevealView.swift
//
// Screen 7.5 — Card Reveal
//
// INTERACTION ARC
// ───────────────
//  t=0            Scene fades in. Card floats up spring(0.42, 0.78).
//                 AtmosphericGhostDeck drifts passively behind.
//  t=0.8s         Card breath begins — scale 1.000 ↔ 1.006, 3.0s sine.
//  t=tap          Flip fires. Ghost deck fades.
//                 3D flip: spring(0.58, 0.84), perspective 0.6.
//                 Front/back cross-fade over 12° window at 90°.
//  t=flip+~320ms  Back face visible. Heading enters, pills stagger up.
//  t=select       Three-beat post-selection sequence:
//                   Beat 1 (0ms):    Pill breathes — scale → 1.06.
//                   Beat 2 (+500ms): Border blooms — lineWidth → 3.0.
//                   Beat 3 (+900ms): Unselected pills sink and fade.
//  t=select+1.3s  Card exits upward, opacity 0, over 450ms.
//  t=select+1.65s Encouragement fades in from below.
//  t=select+1.83s Typewriter begins at 38 cps.
//                 Plain text in body color. Accent in static color.
//                 LivingText crossfades in once accent fully typed.
//                 Cursor blinks ×3 after last char, then fades.
//  t=typing+0.9s  Scene fades to pageBg over 500ms → onContinue().
//
// TRANSITION TO GROUNDRULES
// ──────────────────────────
//  This view owns its exit — sceneOpacity fades to 0, then onContinue()
//  fires. FlowView's spring transition cross-dissolves to GroundRulesView.
//  OnboardingAtmosphere persists in FlowView's ZStack, morphing from
//  .cardReveal to .groundRules config — no background flash.
//
// ANIMATION TIMING ARCHITECTURE
// ──────────────────────────────
//  This file contains a precisely timed cinematic sequence.
//  Many animation durations are intentional exceptions above the
//  AppAnimation token ceiling (0.5s). Do not migrate them to tokens.
//  Each exception is documented inline.
//  Items that are standard UI transitions use AppAnimation tokens.
//
// SKIP
// ────
//  "Continue when ready →" appears at 25s idle.
//  Stores data.nmCardResponse = nil and fades out.

import SwiftUI

// MARK: - Phase

private enum CardRevealPhase: Equatable {
    case idle
    case flipping
    case flipped
    case selected
    case encouragement
    case exiting
}

// MARK: - Main View

struct OnboardingCardRevealView: View {

    @Binding var data: OnboardingData
    var onContinue: (() -> Void)?

    @Environment(\.colorScheme)               private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var isLight: Bool { colorScheme == .light }

    // ── Phase ─────────────────────────────────────────────────────────
    @State private var phase:        CardRevealPhase = .idle
    @State private var selectedPill: CardRevealPill? = nil
    @State private var hasAdvanced = false

    // ── Entrance ───────────────────────────────────────────────────────
    @State private var hasAnimated       = false
    @State private var sceneOpacity:     Double  = 0
    @State private var cardOffsetY:      CGFloat = 40
    @State private var cardEntryOpacity: Double  = 0

    // ── Float ─────────────────────────────────────────────────────────
    @State private var isFloating:  Bool    = false
    @State private var floatOffset: CGFloat = 0

    // ── Glow pulse ────────────────────────────────────────────────────
    @State private var glowOpacity:  Double = 0.4
    @State private var hasBeenTapped: Bool  = false

    // ── Ghost deck ────────────────────────────────────────────────────
    @State private var ghostOpacity: Double = 0

    // ── Flip ──────────────────────────────────────────────────────────
    @State private var flipDegrees:  Double = 180
    @State private var backRevealed: Bool   = false

    // ── Post-selection beat ────────────────────────────────────────────
    @State private var selectedPillScale:      CGFloat = 1.0
    @State private var selectedBorderWidth:    CGFloat = 2.0
    @State private var unselectedPillsVisible: Bool    = true

    // ── Card exit ─────────────────────────────────────────────────────
    @State private var cardExiting: Bool = false

    // ── Encouragement ─────────────────────────────────────────────────
    @State private var encouragementVisible: Bool = false
    @State private var typingComplete:       Bool = false

    // ── Arrow ─────────────────────────────────────────────────────────
    @State private var arrowTriggered:      Bool = false
    @State private var sitWithThisVisible:  Bool = false
    @State private var tapHintVisible:      Bool = false

    // ── Fuse / flip hint ──────────────────────────────────────────────
    @State private var fuseVisible:      Bool   = false
    @State private var fuseCompleted:    Bool   = false
    @State private var flipHintActive:   Bool   = false
    @State private var flipHintDegrees:  Double = 0
    @State private var fuseBurnProgress: Double = 0
    @State private var fuseBurnStartDate: Date? = nil

    @State private var questionVisible: Bool = false
    @State private var pillsVisible:    Bool = false

    // ── Scene exit ────────────────────────────────────────────────────
    @State private var exitingToNext: Bool = false

    // MARK: - Constants

    private let cardSize         = CardLayout.size
    private let cardCornerRadius = CardLayout.cornerRadius
    private let fuseDuration:  TimeInterval = 15.0
    private let fuseDelay:     TimeInterval = 3.0
    private let fuseLineWidth: CGFloat      = 2.5

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            VStack {
                Spacer()
                ZStack {
                    cardStage

                    if encouragementVisible || typingComplete {
                        EncouragementView(
                            isLight:      isLight,
                            active:       encouragementVisible,
                            reduceMotion: reduceMotion,
                            selectedPill: selectedPill,
                            onComplete:   handleTypingComplete
                        )
                        .transition(
                            .opacity.combined(with: .offset(y: 16))
                        )
                    }
                }
                .frame(width: cardSize.width, height: cardSize.height)

                Text("sit with this")
                    .font(AppFonts.body(16, weight: .regular, relativeTo: .body))
                    .italic()
                    .foregroundStyle(Color.white)
                    .opacity(sitWithThisVisible && phase != .selected && phase != .encouragement && phase != .exiting ? 0.75 : 0)
                    .blur(radius: sitWithThisVisible ? 0 : 4)
                    .offset(y: sitWithThisVisible ? 0 : 6)
                    .padding(.top, AppSpacing.sm)

                Text("tap when ready")
                    .font(AppFonts.caption)
                    .foregroundStyle(Color.white.opacity(0.35))
                    .opacity(tapHintVisible && phase != .selected && phase != .encouragement && phase != .exiting ? 1 : 0)
                    .padding(.top, AppSpacing.xs)

                Color.clear.frame(height: 160)
            }
            .frame(maxWidth: .infinity)
        }
        .opacity(sceneOpacity)
        // Scene opacity animation — entrance uses easeOut, exit uses easeIn.
        // Two different curves on the same value — cannot be a single token.
        .animation(
            exitingToNext
                ? .easeIn(duration: 0.5)
                : .easeOut(duration: 0.45),
            value: exitingToNext
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            backRevealed
                ? "Something came up. What's it closest to? Choose from: \(CardRevealPill.allCases.map(\.rawValue).joined(separator: ", "))"
                : "What would you desire if nobody, not even you, would judge the answer? Tap to reflect."
        )
        .accessibilityAction(named: "Flip card") {
            if phase == .idle { handleCardTap() }
        }
        .accessibilityAction(named: "Skip") { handleSkip() }
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true
            startEntrance()
        }
    }

    // MARK: - Card Stage

    private var cardStage: some View {
        TimelineView(.animation(paused: !fuseVisible || fuseCompleted)) { timeline in
            ZStack {
                AtmosphericGhostDeck(
                    cardSize:     cardSize,
                    cornerRadius: cardCornerRadius
                )
                .opacity(ghostOpacity)
                .animation(AppAnimation.slow, value: ghostOpacity)

                ZStack {
                    flipContainer
                }
                .shadow(
                    color: phase == .idle && !hasBeenTapped
                        ? AppColors.accentPrimary.opacity(glowOpacity * 0.55)
                        : .clear,
                    radius: 28
                )
                .shadow(
                    color: phase == .idle && !hasBeenTapped
                        ? AppColors.accentTertiary.opacity(glowOpacity * 0.35)
                        : .clear,
                    radius: 40
                )
                // 2.8s glow pulse — intentional above ambientPulse (2.0s).
                // Slower breath gives the idle card a more contemplative feel.
                .animation(.easeInOut(duration: 2.8), value: glowOpacity)
                .offset(y: cardExiting ? -36 : cardOffsetY + floatOffset)
                .opacity(cardExiting ? 0 : cardEntryOpacity)
                .animation(
                    cardExiting
                        // Custom material motion curve — intentional, not AppAnimation.standard.
                        ? .timingCurve(0.4, 0, 0.6, 1, duration: 0.45)
                        // Slow entrance spring — intentional above AppAnimation.spring ceiling.
                        : .spring(response: 0.42, dampingFraction: 0.78),
                    value: cardExiting
                )
                .animation(AppAnimation.enter, value: cardEntryOpacity)
                .onTapGesture {
                    handleCardTap()
                }
            }
            .frame(width: cardSize.width, height: cardSize.height)
            .onChange(of: timeline.date) { _, date in
                updateFuseProgress(at: date)
            }
        }
    }

    // MARK: - Flip Container

    private var flipContainer: some View {
        let _phase = phase

        return ZStack {

            CardFrontView(
                cardSize:           cardSize,
                cornerRadius:       cardCornerRadius,
                isLight:            isLight,
                arrowTriggered:     arrowTriggered,
                sitWithThisVisible: sitWithThisVisible,
                onTap:              handleCardTap,
                fuseProgress:       fuseBurnProgress,
                questionVisible:    _phase == .flipped || _phase == .selected,
                pillsVisible:       pillsVisible,
                onPillSelected:     handlePillSelected
            )
            .opacity(frontFaceOpacity)
            .allowsHitTesting(true)

            CuriosityCardBack(isActive: _phase == .idle)
                .opacity(idleBackFaceOpacity)
                .rotation3DEffect(
                    Angle.degrees(180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .rotation3DEffect(
            Angle.degrees(flipDegrees + flipHintDegrees),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.6
        )
    }

    // MARK: - Cross-fade opacity

    private var frontFaceOpacity: Double {
        Double(max(0, min(1, (90.0 - flipDegrees) / 12.0)))
    }

    private var backFaceOpacity: Double {
        Double(max(0, min(1, (flipDegrees - 78.0) / 12.0)))
    }

    private var idleBackFaceOpacity: Double {
        Double(max(0, min(1, (flipDegrees - 78.0) / 12.0)))
    }

    // MARK: - Entrance

    private func startEntrance() {
        if reduceMotion {
            sceneOpacity     = 1
            cardOffsetY      = 0
            cardEntryOpacity = 1
            ghostOpacity     = 1
            arrowTriggered   = true
            return
        }

        // Scene fade — standard outer transition.
        withAnimation(AppAnimation.slow.delay(0.1)) {
            sceneOpacity = 1
        }

        // Card rises slowly — intentional slow entrance spring (response 1.4).
        // Gives user time to see the back face before auto-flip.
        // Above AppAnimation.spring ceiling intentionally.
        withAnimation(.spring(response: 1.4, dampingFraction: 0.78).delay(0.3)) {
            cardOffsetY = 0
        }
        withAnimation(AppAnimation.slow.delay(0.3)) {
            cardEntryOpacity = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            startFloat()
            startGlowPulse()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            guard self.phase == .idle else { return }
            self.performAutoFlip()
        }
    }

    // MARK: - Float

    private func startFloat() {
        guard !reduceMotion else { return }
        isFloating = true
        tickFloat()
    }

    private func tickFloat() {
        guard isFloating, phase == .idle else {
            withAnimation(AppAnimation.standard) { floatOffset = 0 }
            return
        }
        // 3.0s float tick — intentional above AppAnimation.slow ceiling.
        // Slow sine float is the card's ambient breathing while idle.
        withAnimation(.easeInOut(duration: 3.0)) {
            floatOffset = floatOffset < -2 ? 0 : -4
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { tickFloat() }
    }

    private func stopFloat() {
        isFloating = false
        withAnimation(AppAnimation.spring) {
            floatOffset = 0
        }
    }

    // MARK: - Glow Pulse

    private func startGlowPulse() {
        guard !reduceMotion else { return }
        tickGlowPulse()
    }

    private func tickGlowPulse() {
        guard phase == .idle, !hasBeenTapped else { return }
        // 2.8s glow tick — intentional above ambientPulse (2.0s).
        // Slower than standard ambient to match contemplative idle feel.
        withAnimation(.easeInOut(duration: 2.8)) {
            glowOpacity = glowOpacity < 0.7 ? 1.0 : 0.4
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            tickGlowPulse()
        }
    }

    // MARK: - Auto-flip

    private func performAutoFlip() {
        guard phase == .idle else { return }
        phase = .flipping
        stopFloat()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        withAnimation(AppAnimation.enter) {
            ghostOpacity = 0
        }

        // Cinematic flip spring — intentional custom values (0.58, 0.84).
        // Produces a physical card-flip feel distinct from AppAnimation.spring.
        withAnimation(.spring(response: 0.58, dampingFraction: 0.84)) {
            flipDegrees = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            backRevealed = true
            phase        = .flipped
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            withAnimation(AppAnimation.standard) {
                self.questionVisible = true
            }
            // 1.56s ghost rematerialise — intentional above ceiling.
            // Ghost deck reappears slowly to not compete with question text.
            withAnimation(.easeOut(duration: 1.56)) {
                self.ghostOpacity = 1
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            self.fuseBurnStartDate = Date()
            withAnimation(AppAnimation.enter) {
                self.fuseVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard self.phase == .flipped else { return }
            self.startShake()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            // 0.9s sit-with-this reveal — intentional above AppAnimation.slow.
            // Slow fade-up gives the instruction a meditative quality.
            withAnimation(.easeOut(duration: 0.9)) {
                self.sitWithThisVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            guard self.phase == .flipped, !self.pillsVisible else { return }
            withAnimation(AppAnimation.slow) {
                self.tapHintVisible = true
            }
        }
    }

    private func startShake() {
        guard !reduceMotion else { return }
        // Shake micro-timings — 0.55s per step is intentional.
        // These are physical simulation values, not UI response animations.
        // The asymmetric angles (8, -6, 4, -2, 0) decay the shake naturally.
        let sequence: [(Double, Double)] = [
            ( 8,  0.55),
            (-6,  0.55),
            ( 4,  0.55),
            (-2,  0.55),
            ( 0,  0.55),
        ]
        var delay = 0.0
        for (angle, duration) in sequence {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: duration)) {
                    flipHintDegrees = angle
                }
            }
            delay += duration
        }
    }

    // MARK: - Flip

    private func handleCardTap() {
        guard phase == .flipped, !pillsVisible else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(AppAnimation.enter) {
            pillsVisible   = true
            tapHintVisible = false
        }
    }

    // MARK: - Pill Selection

    private func handlePillSelected(_ pill: CardRevealPill) {
        guard phase == .flipped, selectedPill == nil else { return }
        selectedPill = pill
        phase        = .selected
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        ghostOpacity = 0

        // Beat 1 — gentle selection spring.
        // response: 0.6 / damping: 0.9 is intentionally softer than
        // AppAnimation.spring (0.5 / 0.85) — pill breath should feel unhurried.
        withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
            selectedPillScale = 1.06
        }

        // Beat 2 — border bloom
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(AppAnimation.standard) {
                selectedBorderWidth = 3.0
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        // Beat 3 — unselected pills sink
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(AppAnimation.standard) {
                unselectedPillsVisible = false
            }
        }

        // Card exits upward — custom material motion curve, intentional.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.timingCurve(0.4, 0, 0.6, 1, duration: 0.45)) {
                cardExiting = true
            }
        }

        // Encouragement rises
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.65) {
            phase = .encouragement
            withAnimation(AppAnimation.enter) {
                encouragementVisible = true
            }
        }
    }

    // MARK: - Typing complete → advance

    private func handleTypingComplete() {
        guard !hasAdvanced else { return }
        typingComplete = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            commitAndAdvance()
        }
    }

    private func commitAndAdvance() {
        guard !hasAdvanced else { return }
        hasAdvanced         = true
        data.nmCardResponse = selectedPill?.rawValue
        phase               = .exiting

        withAnimation(AppAnimation.slow) {
            exitingToNext = true
            sceneOpacity  = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onContinue?()
        }
    }

    // MARK: - Skip

    private func handleSkip() {
        fuseBurnProgress  = 0
        fuseBurnStartDate = nil
        fuseVisible       = false
        fuseCompleted     = true
        flipHintActive    = false
        flipHintDegrees   = 0
        tapHintVisible    = false
        guard phase == .idle, !hasAdvanced else { return }
        hasAdvanced         = true
        data.nmCardResponse = nil

        withAnimation(AppAnimation.slow) {
            exitingToNext = true
            sceneOpacity  = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onContinue?()
        }
    }

    private func handleFuseComplete() {
        guard phase == .flipped, !fuseCompleted else { return }
        fuseCompleted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.startFlipHint()
        }
    }

    private func startFlipHint() {
        guard phase == .flipped || phase == .idle else { return }
        flipHintActive = true
        pulseFlipHint()
    }

    private func pulseFlipHint() {
        guard flipHintActive, phase == .idle else {
            flipHintDegrees = 0
            return
        }
        // Intentional low-damping springs (0.6 / 0.7) — produce physical bounce.
        // AppAnimation.spring (0.85 damping) would be too stiff for a flip hint.
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            flipHintDegrees = 12
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                self.flipHintDegrees = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            self.pulseFlipHint()
        }
    }

    private func updateFuseProgress(at date: Date) {
        guard fuseVisible, !fuseCompleted,
              let start = fuseBurnStartDate else { return }
        let elapsed      = date.timeIntervalSince(start)
        fuseBurnProgress = min(elapsed / fuseDuration, 1.0)
        if fuseBurnProgress >= 1.0 { handleFuseComplete() }
    }
}

// MARK: - Card Views
// CardFrontView and CardBackView have been extracted to Design/Components/Cards/

// MARK: - Encouragement View
//
// Typewriter reveal at 38 cps using AttributedString — no Text + Text.
//
// Sequence:
//   1. Plain text types in body color
//   2. Accent types in a static single color (cyan dark / magenta light)
//   3. Once accent is fully typed, LivingText crossfades in
//   4. Cursor ("|") blinks × 3 then fades
//   5. onComplete() fires → parent waits 900ms → commitAndAdvance()
//
// TODO: typingTask DispatchWorkItem is never cancelled in onDisappear.
// If the view disappears mid-typing, the task continues firing state
// updates. Fix when EncouragementView gets a proper lifecycle owner.

private struct EncouragementView: View {

    let isLight:      Bool
    let active:       Bool
    let reduceMotion: Bool
    let selectedPill: CardRevealPill?
    let onComplete:   () -> Void

    private var plainText: String { selectionPhrase + " " }
    private let accentText = "You're in good company."
    private var fullText: String { plainText }

    // MARK: - Personalized Selection Phrase

    private var selectionPhrase: String {
        switch selectedPill {
        case .ready:      return "Knowing what you're ready for is rare."
        case .figuring:   return "Staying with the not-knowing takes courage."
        case .scared:     return "Naming what scares you is the harder move."
        case .almostSaid: return "Speaking what almost stayed silent matters."
        case .noApology:  return "That kind of honesty is what this is built for."
        case nil:         return "This journey asks a lot of the people it's meant for."
        }
    }

    private let charsPerSecond: Double = 18

    @State private var visibleCharCount:  Int    = 0
    @State private var cursorOn:          Bool   = true
    @State private var cursorDone:        Bool   = false
    @State private var accentFullyTyped:  Bool   = false
    @State private var livingTextOpacity: Double = 0
    @State private var livingTextOffsetY: CGFloat = 8
    @State private var typingTask: DispatchWorkItem? = nil

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            composedText
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
            Spacer()
        }
        .frame(width: 300, height: 400)
        .onAppear   { if active { beginTyping() } }
        .onChange(of: active) { _, isActive in
            if isActive { beginTyping() }
        }
    }

    @ViewBuilder
    private var composedText: some View {
        VStack(spacing: 0) {
            Text(buildAttributedString(
                plain:      String(plainText.prefix(visibleCharCount)),
                accent:     "",
                showCursor: !cursorDone && cursorOn
            ))
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.center)

            LivingText(
                text: accentText,
                font: AppFonts.body(20, weight: .bold, relativeTo: .title3)
            )
            .opacity(livingTextOpacity)
            .offset(y: livingTextOffsetY)
        }
    }

    private func buildAttributedString(
        plain:      String,
        accent:     String,
        showCursor: Bool
    ) -> AttributedString {
        var result = AttributedString(plain)
        result.font            = AppFonts.body(20, weight: .medium, relativeTo: .title3)
        result.foregroundColor = isLight ? AppColors.textPrimary : AppColors.textPrimary

        if !accent.isEmpty {
            var accentAttr = AttributedString(accent)
            accentAttr.font            = AppFonts.body(20, weight: .bold, relativeTo: .title3)
            accentAttr.foregroundColor = isLight ? AppColors.accentTertiary : AppColors.accentPrimary
            result.append(accentAttr)
        }

        if showCursor {
            var cursor = AttributedString("|")
            cursor.font            = AppFonts.body(20, weight: .thin, relativeTo: .title3)
            cursor.foregroundColor = isLight ? AppColors.accentTertiary : AppColors.accentPrimary
            result.append(cursor)
        }

        return result
    }

    // MARK: Typing sequence

    private func beginTyping() {
        guard visibleCharCount == 0 else { return }

        if reduceMotion {
            visibleCharCount  = fullText.count
            accentFullyTyped  = true
            cursorDone        = true
            livingTextOpacity = 1
            livingTextOffsetY = 0
            onComplete()
            return
        }

        typeNextChar()
    }

    private func typeNextChar() {
        guard visibleCharCount < fullText.count else {
            blinkCursor(count: 0)
            return
        }

        let item = DispatchWorkItem {
            visibleCharCount += 1

            if !accentFullyTyped && visibleCharCount == fullText.count {
                accentFullyTyped = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    cursorDone = true
                    // 1.0s LivingText fade-in — intentional above AppAnimation.slow ceiling.
                    // Slow arrival lets the glow "wake up" imperceptibly since both
                    // static accent and LivingText start at the same leading color.
                    withAnimation(.easeOut(duration: 1.0)) {
                        livingTextOpacity = 1
                        livingTextOffsetY = 0
                    }
                }
            }

            typeNextChar()
        }
        typingTask = item
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.0 / charsPerSecond,
            execute: item
        )
    }

    private func blinkCursor(count: Int) {
        guard count < 6 else {
            cursorOn   = false
            cursorDone = true
            // 1.0s cursor fade — intentional above ceiling, matches LivingText arrival timing.
            withAnimation(.easeOut(duration: 1.0)) {
                livingTextOpacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onComplete()
            }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            cursorOn = !cursorOn
            blinkCursor(count: count + 1)
        }
    }
}

// MARK: - Previews

#Preview("Dark") {
    @Previewable @State var data = OnboardingData()
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .cardReveal,
            sparkConfig: .curiosityPickerView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingCardRevealView(data: $data, onContinue: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    @Previewable @State var data = OnboardingData()
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .cardReveal,
            sparkConfig: .curiosityPickerView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingCardRevealView(data: $data, onContinue: {})
    }
    .preferredColorScheme(.light)
}
