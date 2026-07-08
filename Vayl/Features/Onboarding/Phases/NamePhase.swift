// Vayl/Features/Onboarding/Phases/NamePhase.swift

import SwiftUI

/// Renderer for the Name phase. All orchestration (the dealer intro, card set-down /
/// flip / collect, name entry, greeting, and the tap-to-lift → swipe-to-hand-back lesson)
/// lives in `NameSequencer` (`director.name`), mirroring GenderPhase / GenderSequencer.
///
/// Three things stay here because they cannot live on an `@Observable`:
///   • `@FocusState` — relayed from `seq.nameFieldShouldFocus`.
///   • the `tableRimBurst` `@Binding` — pulsed from `seq.rimBurstTrigger`.
///   • `@Environment` (reduceMotion / displayScale) — handed to the sequencer at `start`.
struct NamePhase: View {

    let director: VaylDirector
    let screenSize: CGSize
    @Binding var tableRimBurst: Double

    @FocusState private var nameFieldFocused: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale)              private var displayScale

    /// All phase state + sequencing.
    private var seq: NameSequencer { director.name }

    private var cardWidth: CGFloat {
        AppLayout.obTableCardWidth(in: screenSize.width) * AppLayout.obTableCardCinematicScale
    }
    private var cardHeight: CGFloat {
        AppLayout.obTableCardHeight(in: screenSize.width) * AppLayout.obTableCardCinematicScale
    }

    // MARK: — Body

    var body: some View {
        ZStack {
            // Layer 1 — always present
            effectsLayer

            // Layer 2 — always present
            cardLayer()

            // Layer 3 — dealer copy, one line at a time via shuffle transitions.
            // Always mounted (empty Text renders nothing) — gating on dealerDisplayed
            // unmounted the view during shuffleEnterDealer, so the slide-in animated
            // nothing and lines popped in.
            dealerCopyView

            // Layer 4 — Beat 3 greeting (replaces dealer copy after submit)
            if seq.showGreeting {
                greetingView
            }

            // Layer 5 — name input, fades in after Beat 2 types
            if seq.dealPhase == .nameInput || seq.dealPhase == .collecting {
                dealerZone
                    .opacity(seq.uiAlpha)
            }

        }
        .frame(width: screenSize.width, height: screenSize.height)
        .gesture(
            DragGesture()
                .onChanged { v in
                    // Live hand-off: the lifted card tracks the finger as it's handed back.
                    guard seq.waitingForCardReturn, seq.cardLifted else { return }
                    seq.updateHandBack(v.translation)
                }
                .onEnded { v in
                    if seq.waitingForCardReturn, seq.cardLifted {
                        seq.endHandBack(v)
                    } else {
                        seq.handleSwipe(v.translation)   // name-submit path — unchanged
                    }
                }
        )
        // Sequencer → View relays (the three things @Observable can't hold)
        .onChange(of: seq.nameFieldShouldFocus) { _, shouldFocus in
            nameFieldFocused = shouldFocus
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

    // MARK: — Effects layer

    private var effectsLayer: some View {
        Canvas { context, size in
            let cx = size.width  / 2 + seq.cardOffset.width
            let cy = size.height / 2 + seq.cardOffset.height

            if seq.impactRingProgress > 0 {
                let ringW     = cardWidth * 1.1 + (cardWidth * 2.2) * seq.impactRingProgress
                let ringH     = ringW * 0.23
                let ringAlpha = (1.0 - seq.impactRingProgress) * 0.55
                guard ringAlpha > 0 else { return }

                var ringPath = Path()
                ringPath.addEllipse(in: CGRect(
                    x: cx - ringW / 2,
                    y: cy + cardHeight * 0.48 - ringH / 2,
                    width: ringW,
                    height: ringH
                ))
                context.stroke(
                    ringPath,
                    with: .color(AppColors.spectrumPurple.opacity(ringAlpha)),
                    lineWidth: 1.0
                )
            }

            if seq.flipBurstProgress > 0 {
                let burstR     = max(cardWidth, cardHeight) * 1.8 * seq.flipBurstProgress
                let burstAlpha = (1.0 - seq.flipBurstProgress) * 0.45
                guard burstAlpha > 0 else { return }

                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: AppColors.spectrumPurple.opacity(burstAlpha), location: 0),
                            .init(color: AppColors.spectrumCyan.opacity(burstAlpha * 0.45), location: 0.45),
                            .init(color: AppColors.spectrumCyan.opacity(0), location: 1)
                        ]),
                        center: CGPoint(x: cx, y: cy),
                        startRadius: 0,
                        endRadius: burstR
                    )
                )
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    // MARK: — Card layer

    private func cardLayer() -> some View {
        // Both faces stay mounted so the typewriter face's Canvas + drawingGroup warm
        // up BEFORE the flip — swapped by opacity at the edge-on midpoint instead of a
        // cold mount there, which made the turn jitter. (Same fix as DemoPhase.)
        ZStack {
            VaylCardBack()
                .opacity(seq.showFace ? 0 : 1)
            VaylCardFace(content: .typewriter(
                activeKey: seq.activeKeyIndex,
                carriageProgress: seq.carriageProgress
            ))
            .opacity(seq.showFace ? 1 : 0)
        }
        .drawingGroup()
        .frame(width: cardWidth, height: cardHeight)
        // Shared lift affordance — the exact spectrum ring the selection phases use,
        // so the gesture the dealer teaches here transfers to them by sight.
        .overlay(LiftHalo(visible: seq.cardLifted))
        .scaleEffect(x: seq.flipScaleX, y: 1.0)
        .scaleEffect(seq.cardScale)
        .rotationEffect(.degrees(seq.cardAngle + seq.handBackTilt))
        .offset(seq.cardOffset)
        // Return-demo drift — upward hint applied on top of positional offset
        .offset(y: seq.cardReturnHintOffset)
        // Live hand-off: the lifted card tracks the finger as it's handed back.
        .offset(seq.handBackDrag)
        .opacity(seq.cardAlpha * seq.cardScreenAlpha)
        // Tap the card to pick it up (only live during the guided lesson; a drag
        // still bubbles to the screen-level swipe handler).
        .onTapGesture { seq.handleLiftTap() }
    }

    // MARK: — Dealer zone (name input — no header)
    //
    // Beat 2 "And who am I dealing in?" remains visible in dealerCopyView while this
    // input zone is shown. dealerZone is positioned at 0.30 — below the Beat 2 copy at
    // 0.22, above the card center at 0.55. submitName() clears the copy instantly.

    private var dealerZone: some View {
        VStack(alignment: .center, spacing: AppSpacing.md) {
            TextField(
                "",
                text: Binding(get: { seq.name }, set: { seq.name = $0 }),
                prompt: Text("Enter name")
                    .font(AppFonts.display(28, weight: .semibold, relativeTo: .title))
                    .foregroundColor(AppColors.textTertiary)
            )
            .font(AppFonts.display(28, weight: .semibold, relativeTo: .title))
            .foregroundStyle(AppColors.textPrimary)
            .tint(seq.name.isEmpty ? .clear : AppColors.accentPrimary)
            .multilineTextAlignment(.center)
            .focused($nameFieldFocused)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .onSubmit {
                nameFieldFocused = false
                seq.submitName()
            }
            .onChange(of: seq.name) { _, newValue in
                seq.onNameChanged(newValue)
            }
            .onChange(of: nameFieldFocused) { _, isFocused in
                seq.onFocusChanged(isFocused)
            }
            .overlay(alignment: .bottom) {
                ZStack {
                    // Spectrum hairline — 1.5pt rule
                    Rectangle()
                        .fill(AnyShapeStyle(AppColors.spectrumBorder))
                        .frame(height: 1.5)

                    // Glow layer 1 — tight
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [
                                AppColors.accentPrimary.opacity(0.6),
                                AppColors.accentSecondary.opacity(0.9),
                                AppColors.accentTertiary.opacity(0.8),
                                AppColors.accentPrimary.opacity(0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: 3)
                        .blur(radius: 4)

                    // Glow layer 2 — wide soft bloom
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [
                                AppColors.accentPrimary.opacity(0.2),
                                AppColors.accentSecondary.opacity(0.35),
                                AppColors.accentTertiary.opacity(0.3),
                                AppColors.accentPrimary.opacity(0.2)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: 8)
                        .blur(radius: 6)
                }
                .frame(width: cardWidth)
                .scaleEffect(x: seq.lineRevealProgress, anchor: .leading)
                .offset(y: seq.lineBounce)
            }
        }
        .frame(width: cardWidth)
        .position(
            x: screenSize.width  / 2,
            y: screenSize.height * 0.30
        )
    }

    // MARK: — Dealer copy view

    /// Vertical anchor for the dealer copy. At rest it sits at 0.22; once the card is
    /// lifted (the swipe-up step) it rises to 0.21 — clears the hovered card and matches
    /// the selection phases' lift copy. Animates in sync with the lift because
    /// `cardLifted` flips inside the cardLift withAnimation.
    private var dealerCopyY: CGFloat {
        // FEEL-GATE: nudge up/down to taste.
        seq.cardLifted ? screenSize.height * 0.21 : screenSize.height * 0.22
    }

    private var dealerCopyView: some View {
        Text(seq.dealerDisplayed)
            .font(AppDealerTyping.font)
            .foregroundStyle(AppColors.textPrimary)
            .multilineTextAlignment(.center)
            .frame(width: screenSize.width * 0.82)
            .opacity(seq.dealerAlpha)
            .offset(y: seq.dealerOffsetY)
            .position(
                x: screenSize.width / 2,
                y: dealerCopyY
            )
    }

    // MARK: — Beat 3 greeting view
    //
    // Occupies the same Y anchor as dealerCopyView (0.22). Shown after submitName()
    // clears the dealer copy. "Welcome to the table," is a static line; the name line
    // fades in separately after a 200ms breath.

    private var greetingView: some View {
        VStack(spacing: AppSpacing.xs) {
            Text("Welcome to the table,")
                .font(AppDealerTyping.font)
                .foregroundStyle(AppColors.textPrimary)

            if seq.nameVisible {
                Text(seq.greetingName)
                    .font(AppFonts.display(28, weight: .bold, relativeTo: .title))
                    .foregroundStyle(AppColors.spectrumText)
                    .transition(.opacity)
            }
        }
        .opacity(seq.greetingAlpha)
        .position(
            x: screenSize.width / 2,
            y: screenSize.height * 0.22
        )
    }
}
