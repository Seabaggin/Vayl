// Vayl/Features/Onboarding/Phases/DemoPhase.swift
//
// OB Phase — Demo · "The Snapshot Card" (renders OBPhase.demo)
//
// The user's FIRST card. Teaches the two core gestures (tap-to-lift,
// swipe-up-to-hand-back) AND runs a behavioral diagnostic disguised as a sentence
// completion: the user finishes "I [verb] [noun]." and the app triangulates verb × noun
// into an EmotionalRegister (DemoDictionary).
//
// Renderer only. All orchestration (intro lines, deal/flip, compose, seal → dissolve →
// pocket → commit) lives in `DemoSequencer` (`director.demo`), mirroring NameSequencer.
// `@FocusState` (noun field) and the `tableRimBurst` `@Binding` stay here and are relayed
// from the sequencer's `nounShouldFocus` / `rimBurstTrigger`.

import SwiftUI

struct DemoPhase: View {

    let director: VaylDirector
    let screenSize: CGSize
    @Binding var tableRimBurst: Double

    @FocusState private var nounFocused: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale)              private var displayScale

    /// All phase state + sequencing.
    private var seq: DemoSequencer { director.demo }

    private var cardWidth: CGFloat {
        AppLayout.obTableCardWidth(in: screenSize.width) * AppLayout.obTableCardCinematicScale
    }
    private var cardHeight: CGFloat {
        AppLayout.obTableCardHeight(in: screenSize.width) * AppLayout.obTableCardCinematicScale
    }
    private var sentenceSize: CGFloat { min(cardWidth * 0.12, 30) }

    /// Noun font eases down with length: short words stay a decent size; longer phrases
    /// ease smaller. A hard fit-cap guarantees it never overflows. Applied to BOTH the
    /// invisible TextField and the LivingText overlay so the caret stays aligned.
    private var nounSize: CGFloat {
        guard !seq.noun.isEmpty else { return sentenceSize }
        let n = CGFloat(seq.noun.count)
        let gentle = sentenceSize * max(0.62, 1 - 0.010 * max(0, n - 5))
        let avail  = cardWidth * 0.80
        let estW   = sentenceSize * n * 0.60
        let fit    = estW <= avail ? sentenceSize : sentenceSize * (avail / estW)
        return min(gentle, fit)
    }

    // Card centre in screen space — the sentence layer tracks this.
    private var cardCenter: CGPoint {
        CGPoint(x: screenSize.width  / 2 + seq.cardOffset.width,
                y: screenSize.height / 2 + seq.cardOffset.height)
    }

    // MARK: — Body

    var body: some View {
        ZStack {
            effectsLayer
            cardLayer
            if seq.stage == .awaitingLift || seq.stage == .composing || seq.stage == .sealing {
                sentenceLayer
            }
        }
        .frame(width: screenSize.width, height: screenSize.height)
        // Make the whole frame hittable so the seal swipe registers anywhere on the felt,
        // not only on the card. Children (card tap, verb pill, noun field) are hit-tested
        // first, so this never steals their gestures.
        .contentShape(Rectangle())
        .gesture(
            // Empty onChanged is required to engage the recognizer — onEnded alone never fires.
            DragGesture()
                .onChanged { _ in }
                .onEnded { v in seq.handleSwipe(v.translation) }
        )
        // Sequencer → View relays (the two things @Observable can't hold)
        .onChange(of: seq.nounShouldFocus) { _, shouldFocus in
            nounFocused = shouldFocus
        }
        .onChange(of: seq.rimBurstTrigger) { _, _ in
            tableRimBurst = 1.0
            withAnimation(AppAnimation.rimBurstDecay) { tableRimBurst = 0.0 }
        }
        .onAppear {
            seq.start(screenSize: screenSize, reduceMotion: reduceMotion, displayScale: displayScale)
        }
        .onDisappear {
            seq.stop()
        }
    }

    // MARK: — Effects layer (impact ring + flip burst + dissolve burst)

    private var effectsLayer: some View {
        Canvas { context, size in
            let cx = cardCenter.x
            let cy = cardCenter.y

            if seq.impactRingProgress > 0 {
                let ringW = cardWidth * 1.1 + (cardWidth * 2.2) * seq.impactRingProgress
                let ringH = ringW * 0.23
                let a     = (1.0 - seq.impactRingProgress) * 0.5
                if a > 0 {
                    var p = Path()
                    p.addEllipse(in: CGRect(x: cx - ringW/2, y: cy + cardHeight*0.48 - ringH/2,
                                            width: ringW, height: ringH))
                    context.stroke(p, with: .color(AppColors.spectrumPurple.opacity(a)), lineWidth: 1.0)
                }
            }

            if seq.flipBurstProgress > 0 {
                let r = max(cardWidth, cardHeight) * 1.8 * seq.flipBurstProgress
                let a = (1.0 - seq.flipBurstProgress) * 0.45
                if a > 0 {
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .radialGradient(
                            Gradient(stops: [
                                .init(color: AppColors.spectrumPurple.opacity(a), location: 0),
                                .init(color: AppColors.spectrumCyan.opacity(a * 0.45), location: 0.45),
                                .init(color: AppColors.spectrumCyan.opacity(0), location: 1)
                            ]),
                            center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: r
                        )
                    )
                }
            }

            // Seal bloom — a quick bright spectrum flash from the sentence as it breaks
            // apart. Blooms tight + bright, then widens + fades.
            if seq.sealBloom > 0 {
                let r = max(cardWidth, cardHeight) * 1.7 * seq.sealBloom
                let a = (1.0 - seq.sealBloom) * 0.55
                if a > 0 {
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .radialGradient(
                            Gradient(stops: [
                                .init(color: Color.white.opacity(a * 0.5), location: 0),
                                .init(color: AppColors.spectrumPurple.opacity(a), location: 0.18),
                                .init(color: AppColors.spectrumMagenta.opacity(a * 0.5), location: 0.5),
                                .init(color: AppColors.spectrumCyan.opacity(0), location: 1)
                            ]),
                            center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: r
                        )
                    )
                }
            }

            // Particle dissolve — motes break off the SENTENCE band, drift up-and-toward-
            // corner with a twinkle, and fade out.
            if seq.dissolveProgress > 0 {
                let t = seq.dissolveProgress
                for s in seq.dissolveSeeds {
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
        // Both faces stay mounted so the blank face's Canvas + drawingGroup warm up BEFORE
        // the flip — swapped by opacity at the edge-on midpoint instead of a cold mount.
        ZStack {
            VaylCardBack()
                .opacity(seq.showFace ? 0 : 1)
            // Blank alive shell + tone wash. The sentence is a separate unmirrored layer
            // (the flip ends at scaleX −1; a child here would mirror).
            VaylCardFace(content: .blank)
                .overlay(toneWash)
                .opacity(seq.showFace ? 1 : 0)
        }
        .drawingGroup()
        .frame(width: cardWidth, height: cardHeight)
        .overlay(aliveBorder)
        .overlay(LiftHalo(visible: seq.cardLifted))
        .scaleEffect(x: seq.flipScaleX, y: 1.0)
        .scaleEffect(seq.cardScale)
        .rotationEffect(.degrees(seq.cardAngle))
        .offset(seq.cardOffset)
        .blur(radius: seq.cardBlur)
        .opacity(seq.cardAlpha * (1.0 - seq.dissolveProgress))
    }

    private var toneWash: some View {
        RadialGradient(
            colors: [toneColor.opacity(0.18), .clear],
            center: .center, startRadius: 0, endRadius: cardWidth * 0.72
        )
        .animation(AppAnimation.standard, value: seq.verb)
        .allowsHitTesting(false)
    }

    /// Slow intermittent spectrum pulse — gives the lifted card "life."
    private var aliveBorder: some View {
        RoundedRectangle(cornerRadius: AppRadius.obCard)
            .strokeBorder(AppColors.spectrumBorder, lineWidth: 1.4)
            .blur(radius: 2)
            .opacity(seq.borderPulse ? 0.85 : 0.25)
            .ambientAnimation(.easeInOut(duration: AppAnimation.ambientPulse).repeatForever(autoreverses: true),
                              value: seq.borderPulse)
            .opacity(seq.cardLifted ? 1 : 0)
            .animation(AppAnimation.standard, value: seq.cardLifted)
            .allowsHitTesting(false)
    }

    private var toneColor: Color {
        switch seq.verb {
        case .need:   return AppColors.spectrumCyan
        case .want:   return AppColors.spectrumPurple
        case .desire: return AppColors.spectrumMagenta
        }
    }

    // MARK: — Sentence layer (interactive — separate so the flip never mirrors it)

    private var sentenceLayer: some View {
        VStack(spacing: cardHeight * 0.05) {
            // Line 1 — "I want". Melts onto the card before the tap.
            HStack(spacing: cardWidth * 0.03) {
                Text("I")
                    .font(AppFonts.display(sentenceSize, weight: .medium, relativeTo: .title))
                    .foregroundStyle(AppColors.textPrimary)
                verbView
            }
            .opacity(seq.sentenceMelt)
            .blur(radius: (1 - seq.sentenceMelt) * 9)
            .scaleEffect(0.92 + 0.08 * seq.sentenceMelt)
            .offset(y: (1 - seq.sentenceMelt) * -cardHeight * 0.03)

            // Line 2 — the live word (blinking cursor when empty).
            nounField
        }
        .frame(width: cardWidth * 0.86)
        .scaleEffect(seq.cardScale)
        .position(cardCenter)
        .opacity(seq.stage == .sealing ? (1.0 - seq.dissolveProgress) : 1.0)
        // Display-only until composing — taps during await-lift fall through.
        .allowsHitTesting(seq.stage == .composing)
    }

    /// Tappable verb — cycles need → want → desire on tap; the word slides vertically
    /// (odometer) so the change is legible.
    private var verbView: some View {
        ZStack {
            Text(seq.verb.rawValue)
                .font(AppFonts.display(sentenceSize, weight: .bold, relativeTo: .title))
                .foregroundStyle(AppColors.textBody)
                .id(seq.verb)
                .transition(.push(from: .bottom).combined(with: .opacity))
        }
        .frame(height: sentenceSize * 1.28)
        .fixedSize()
        .clipped()
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.spectrumBorder)
                .frame(height: 1.5)
                .opacity((1 - seq.sealProgress) * 0.45)
        }
        .contentShape(Rectangle())
        .onTapGesture { seq.cycleVerb() }
    }

    /// The one living element — the typed word, rendered as a spectrum LivingText. An
    /// invisible TextField beneath captures input and shows the blinking caret.
    private var nounField: some View {
        TextField("", text: Binding(get: { seq.noun }, set: { seq.noun = $0 }))
            .font(AppFonts.display(nounSize, weight: .semibold, relativeTo: .title))
            .multilineTextAlignment(.center)
            .foregroundStyle(.clear)                 // invisible — LivingText draws the word
            .tint(AppColors.accentSecondary)         // visible caret
            .fixedSize()
            .frame(minWidth: cardWidth * 0.12)
            .focused($nounFocused)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(.done)
            .onSubmit {
                nounFocused = false
                seq.attemptSealFromKeyboard()
            }
            .overlay {
                if !seq.noun.isEmpty {
                    LivingText(text: seq.noun,
                               font: AppFonts.display(nounSize, weight: .semibold, relativeTo: .title))
                        .allowsHitTesting(false)
                }
            }
            .offset(x: seq.nounPulse)
            .onChange(of: seq.noun) { _, new in
                seq.onNounChanged(new)
            }
    }
}
