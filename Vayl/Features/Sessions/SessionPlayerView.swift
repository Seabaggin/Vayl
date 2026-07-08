//
//  SessionPlayerView.swift
//  Vayl
//
//  Screen 3 of the couple session cover: the in-session player (the heart).
//  Faithful to docs/prototypes/couple-session-hero-v2.html.
//
//  Zones, top to bottom: the fanned deck (remaining cards, the deal source) →
//  the drawer ceremony + hero prompt → intentional aurora ground → controls on
//  a shared bottom baseline (care icon left — pause/hug/skip/end well, all in
//  one sheet — hold-to-deal right).
//
//  Hold the proceed control and the next card pulls down out of the fan in
//  proportion to the hold; release early to cancel; hold to commit and it dives
//  away, revealing the next prompt. Background is the canonical
//  OnboardingAtmosphere, shared with the rest of the cover.
//
//  Hold/dive durations are ported from the prototype as feel-gated starting
//  values — tune on device, not blind.
//

import SwiftUI

struct SessionPlayerView: View {

    @Bindable var store: CoupleSessionStore

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Feel-gated timings (ported from the prototype --hold / --expand).
    private let holdSeconds: Double = 0.85
    private let diveSeconds: Double = 0.82

    @State private var fill: CGFloat = 0          // hold progress 0…1
    @State private var holding = false
    @State private var diving = false
    @State private var pendingPrompt: String = ""
    @State private var showCare = false
    @State private var dimmed = false
    @State private var idleTask: Task<Void, Never>?
    @State private var warpProgress: CGFloat = 0

    var body: some View {
        ZStack {
            fanDeck

            screenLayer
                .if(store.currentCard?.isSensitive == true) { $0.screenshotProtected() }
                .opacity(holding ? Double(1 - fill) : 1)
                .animation(reduceMotion ? AppAnimation.fast : AppAnimation.standard, value: holding)

            if diving || holding {
                dealingCard
            }

            if diving && !reduceMotion {
                warpFlash
            }

            controls

            // Idle dim — alive, recedes when the room is set down.
            Rectangle()
                .fill(AppColors.void)
                .opacity(dimmed ? 0.52 : 0)
                .animation(.easeInOut(duration: dimmed ? 1.7 : 0.4), value: dimmed)
                .allowsHitTesting(false)
                .ignoresSafeArea()

            // Pause / partner-away — a held room, above the idle dim.
            if store.isPaused {
                ZStack {
                    Rectangle().fill(AppColors.void).opacity(0.72).ignoresSafeArea()
                    VStack(spacing: AppSpacing.md) {
                        Text(store.partnerAway
                             ? "waiting for \(store.partnerLabel)…"
                             : "paused")
                            .font(AppFonts.sectionHeading)
                            .foregroundStyle(AppColors.textPrimary)
                        if !store.partnerAway {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                store.togglePause()
                            } label: {
                                Text("resume")
                                    .font(AppFonts.buttonLabel)
                                    .foregroundStyle(AppColors.spectrumText)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .transition(.opacity)
            }

            // Pre-card context beat (Section 3, narrowed 2026-07-07) — the only
            // remaining case is interstitial; it holds until "got it". Banner
            // now renders as a persistent ContextKickerView on the card itself
            // (see screenLayer).
            if let beat = store.activeContextBeat {
                ContextBeatOverlayView(
                    copy: beat.copy,
                    onDismiss: { store.dismissContextBeat() }
                )
                .zIndex(10)
            }
        }
        .animation(reduceMotion ? AppAnimation.fast : AppAnimation.standard, value: store.isPaused)
        .contentShape(Rectangle())
        .onTapGesture { wake() }
        .onAppear {
            scheduleIdle()
            UIApplication.shared.isIdleTimerDisabled = true   // keep-awake mid-session
        }
        .onDisappear {
            idleTask?.cancel()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .vaylSheet(isPresented: $showCare, heightFraction: 0.5) { careSheet }
    }

    // MARK: - Fanned deck

    private var fanDeck: some View {
        let show = min(5, store.upcomingCount)
        return VStack(spacing: AppSpacing.sm) {
            ZStack {
                fanGlow
                ForEach(0..<show, id: \.self) { i in
                    let t = CGFloat(i) - CGFloat(show - 1) / 2   // -2…2
                    fanCard
                        .rotationEffect(.degrees(Double(t) * 9))
                        .offset(x: t * 32, y: abs(t) * 6)
                        .zIndex(Double(20 - Int(abs(t))))
                }
            }
            .frame(height: 80)

            Text(store.upcomingCount > 0
                 ? "\(store.upcomingCount) \(store.upcomingCount == 1 ? "card" : "cards") left"
                 : "last card")
                .font(AppFonts.overline)
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textTertiary)

            SessionTimerBar(store: store)
                .padding(.top, AppSpacing.sm)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, AppSpacing.xl)
    }

    /// A soft glow sized and centered to the fan's own footprint — not a
    /// stray circle placed nearby. Keeps the deck grounded against the
    /// atmosphere's void zone instead of floating in true black.
    private var fanGlow: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        AppColors.spectrumPurple.opacity(0.65),  // core — pushed well past VaylCardBack's atmosphere ceiling, this needs to actually read against void
                        AppColors.spectrumCyan.opacity(0.40),
                        .clear,
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 150   // rendering constant — half the glow's own width, not a token
                )
            )
            .frame(width: 300, height: 160)   // rendering constant — hugs the 5-card fan's rotated bounding box
            .blur(radius: 24)
            .allowsHitTesting(false)
    }

    private var fanCard: some View {
        // VaylCardBack's geometry (hex cell size, corner radius, border width)
        // is fixed-point, tuned for its real session-card size — squeezing it
        // straight into this small a frame distorts all of that (oversized
        // corners, thick-looking border). Render it at true size, then scale
        // the whole rendered card down uniformly so every proportion holds.
        let nativeWidth = AppLayout.sessionCardWidth(in: 390)
        let nativeHeight = AppLayout.sessionCardHeight(in: 390)
        let fanWidth: CGFloat = 96
        let scale = fanWidth / nativeWidth
        return VaylCardBack()
            .frame(width: nativeWidth, height: nativeHeight)
            .scaleEffect(scale)
            .frame(width: fanWidth, height: nativeHeight * scale)
            .shadow(color: AppColors.shadowDeep, radius: 12, y: 6)
    }

    // MARK: - Drawer ceremony + hero prompt

    private var screenLayer: some View {
        Group {
            if let card = store.currentCard {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    if card.hasContextKicker {
                        ContextKickerView(copy: card.contextBeatCopy ?? "")
                    }
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        cardFace(card)
                        if card.hasBackCopy, !card.isRevealMechanic {
                            CardBackFlipView(
                                backCopy: card.backCopy ?? "",
                                showingBack: store.showingCardBack,
                                onFlip: { store.flipCardBack() }
                            )
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.xl)
        .padding(.bottom, 150)
        .frame(maxHeight: .infinity, alignment: .center)
    }

    /// Face router (Section 3): reveal mechanics get their reveal surface,
    /// local living cards get their typed face, discussion cards keep the
    /// hero prompt.
    @ViewBuilder
    private func cardFace(_ card: Card) -> some View {
        switch card.type {
        case .whisper:
            WhisperRevealView(store: store, isWhatIf: false,
                              recomposing: store.revealRecomposing)
        case .whatIf:
            WhisperRevealView(store: store, isWhatIf: true,
                              recomposing: store.revealRecomposing)
        case .unspoken:
            UnspokenSliderView(store: store, recomposing: store.revealRecomposing)
        case .mirror:
            MirrorRevealView(store: store, recomposing: store.revealRecomposing)
        case .snapshot:
            SnapshotRevealView(store: store, recomposing: store.revealRecomposing)
        case .prompt, .reflect:
            highlightedPrompt(card)
                .font(AppFonts.display(26, weight: .medium, relativeTo: .title))
                .foregroundStyle(AppColors.textPrimary)
                .lineSpacing(AppSpacing.xs)
                .fixedSize(horizontal: false, vertical: true)
        default:
            LocalCardFaceView(card: card)               // the nine local living cards
        }
    }

    // MARK: - Dealing card (pulls from fan, dives on commit)

    private var dealingCard: some View {
        // During hold: y interpolates from the fan (up) to center as fill grows,
        // scale 0.42 → 1, and the card flips from its face-down back (180°) to the
        // prompt face (0°). On dive: scale blooms past 1 and fades.
        let pulledScale = 0.42 + 0.58 * fill
        let pulledY = -300 * (1 - fill)
        let flipAngle = Angle(degrees: 180 * Double(1 - fill))   // 180 = back, 0 = front
        let showFront = fill >= 0.5

        return ZStack {
            // Each face carries a compensating 180° pre-rotation for the side
            // that's visible when the outer wrapper (below) is near that same
            // angle — without it, whichever face is on screen renders mirrored.
            cardBackFace
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(showFront ? 0 : 1)
            cardFrontFace
                .opacity(showFront ? 1 : 0)
        }
        .frame(width: 300, height: 212)
        .rotation3DEffect(flipAngle, axis: (x: 0, y: 1, z: 0), perspective: 0.4)
        .shadow(color: AppColors.shadowDeep, radius: 24, y: 12)
        .scaleEffect(diving ? 3.4 : pulledScale)
        .opacity(diving ? 0 : 1)
        .blur(radius: diving ? 6 : 0)
        .offset(y: diving ? -20 : pulledY)
        .allowsHitTesting(false)
    }

    private var cardFrontFace: some View {
        VaylCardFace(question: pendingPrompt)
    }

    private var cardBackFace: some View {
        VaylCardBack()
    }

    private var warpFlash: some View {
        // A single spectrum rush on the dive: bright + small → faded + expanded.
        RadialGradient(
            colors: [AppColors.spectrumPurple.opacity(0.28),
                     AppColors.spectrumMagenta.opacity(0.08),
                     .clear],
            center: .center, startRadius: 0, endRadius: 320
        )
        .scaleEffect(0.4 + warpProgress * 1.8)
        .opacity(0.35 * Double(1 - warpProgress))
        .blendMode(.screen)
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    /// Colors `card.highlightWords` in HighlightText's solid word color — the
    /// word carries the accent, not a gradient on text (AttributedString runs
    /// can't hold a moving/multi-stop gradient without breaking line flow).
    private func highlightedPrompt(_ card: Card) -> Text {
        guard !card.highlightWords.isEmpty else { return Text(card.text) }
        var attributed = AttributedString(card.text)
        for word in card.highlightWords {
            var cursor = attributed.startIndex
            while let range = attributed[cursor...].range(of: word) {
                attributed[range].foregroundColor = HighlightText.wordColor
                cursor = range.upperBound
            }
        }
        return Text(attributed)
    }

    // MARK: - Controls (shared bottom baseline)

    private var controls: some View {
        VStack {
            Spacer()
            HStack(alignment: .bottom) {
                leftStack
                Spacer()
                // Reveal cards must reveal before advancing (the ceremony is
                // the card). Only the proceed control is gated — the care mark
                // and the safe word stay reachable, always.
                proceedButton
                    .allowsHitTesting(store.revealSatisfied)
                    .opacity(store.revealSatisfied ? 1 : 0.35)
                    .animation(AppAnimation.standard, value: store.revealSatisfied)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.xl)
    }

    private var leftStack: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Care lives behind this one icon — the care sheet below is
            // "everything in one place" (pause/hug/skip/end well).
            Button {
                wake()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showCare = true
            } label: {
                Image(systemName: "heart.circle")
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 54, height: 54)
                    .background(Circle().fill(AppColors.cardBackground))
                    .overlay(Circle().strokeBorder(AppColors.borderDefault, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Take a beat — pause, care options, or end the session")

            turnAndPresencePill
        }
    }

    /// Replaces the old top-of-screen drawer row — whose draw it is and
    /// whether the partner's device is connected, merged into one pill down
    /// with the rest of the session chrome instead of floating alone up top.
    private var turnAndPresencePill: some View {
        let isYou = store.currentDrawer == .you
        return HStack(spacing: AppSpacing.sm) {
            Text(store.drawingRoleLabel)
                .font(AppFonts.display(11, weight: .semibold, relativeTo: .caption2))
                .foregroundStyle(AppColors.void)
                .frame(width: 20, height: 20)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: isYou
                                ? [AppColors.spectrumMagenta, AppColors.accentSecondary]
                                : [AppColors.spectrumCyan, AppColors.accentSecondary],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                )
            Text(isYou ? "your draw" : "partner's draw")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
            Circle()
                .fill(store.partnerConnected ? AppColors.spectrumCyan : AppColors.textTertiary)
                .frame(width: 6, height: 6)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(
            Capsule().fill(AppColors.cardBackground.opacity(0.6))
                .overlay(Capsule().strokeBorder(AppColors.borderSubtle, lineWidth: 1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(isYou ? "Your draw" : "Partner's draw"). Partner is "
            + (store.partnerConnected ? "connected." : "not connected.")
        )
    }

    private var proceedButton: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(AppColors.spectrumBorder.opacity(0.32))
                .frame(width: max(0, proceedWidth * fill))
            HStack(spacing: AppSpacing.sm) {
                Text(holding ? "keep holding…" : (store.isLastCard ? "hold to finish" : "hold to deal next"))
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(AppColors.textBody)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
        .frame(height: 44)
        .background(
            Capsule().fill(AppColors.cardBackground.opacity(0.6))
        )
        .overlay(Capsule().strokeBorder(AppColors.borderDefault, lineWidth: 1))
        .clipShape(Capsule())
        .contentShape(Capsule())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in startHold() }
                .onEnded { _ in endHold() }
        )
    }

    private let proceedWidth: CGFloat = 176

    // MARK: - Care sheet (.vaylSheet)

    private var careSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("if you need a beat")
                .font(AppFonts.overline)
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)        // grabber (in .vaylSheet) supplies the top gap
                .padding(.bottom, AppSpacing.sm)

            careOption("❚❚", "Pause", sub: "hold the room") {
                showCare = false
                store.togglePause()
            }
            careOption("🤍", "A 6-second hug") { showCare = false }
            careOption("✦", "Say one thing you love") { showCare = false }
            careOption("◦", "Just sit a minute") { showCare = false }

            Divider().background(AppColors.borderSubtle)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)

            careOption("⤼", "Skip this card") {
                showCare = false
                store.pass()
            }
            careOption("✓", "End well", sub: "save a clean close", heavy: true) {
                showCare = false
                store.endEarly()
            }

            Spacer(minLength: AppSpacing.lg)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func careOption(
        _ glyph: String, _ title: String, sub: String? = nil,
        heavy: Bool = false, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Text(glyph)
                    .font(AppFonts.bodyText)
                    .frame(width: 22)
                Text(title)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(heavy ? AppColors.spectrumMagenta : AppColors.textBody)
                Spacer()
                if let sub {
                    Text(sub)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Hold-to-deal mechanic

    private func startHold() {
        guard !holding, !diving, !store.isPaused, store.currentCard != nil,
              store.revealSatisfied else { return }
        wake()
        holding = true
        fill = 0
        pendingPrompt = nextPromptText()
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        let start = Date()
        Task { @MainActor in
            while holding {
                let elapsed = Date().timeIntervalSince(start)
                fill = min(1, CGFloat(elapsed / holdSeconds))
                if fill >= 1 {
                    holding = false
                    commitDeal()
                    break
                }
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func endHold() {
        guard holding else { return }
        holding = false
        withAnimation(AppAnimation.standard) { fill = 0 }   // card returns to fan
    }

    private func commitDeal() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        // The dealingCard reads `diving` for its scale/opacity/offset — animate it.
        withAnimation((reduceMotion ? AppAnimation.fast : .easeIn(duration: diveSeconds))) {
            diving = true
        }
        if !reduceMotion {
            warpProgress = 0
            withAnimation(.easeOut(duration: diveSeconds)) { warpProgress = 1 }
        }
        // Advance the model midway so the new prompt is ready as the card clears.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(diveSeconds * 0.45))
            store.dealNext()
            try? await Task.sleep(for: .seconds(diveSeconds * 0.55))
            diving = false
            fill = 0
            wake()
        }
    }

    private func nextPromptText() -> String {
        let next = store.index + 1
        guard store.hand.indices.contains(next) else {
            return store.currentCard?.text ?? ""
        }
        return store.hand[next].text
    }

    // MARK: - Idle dim

    private func scheduleIdle() {
        idleTask?.cancel()
        idleTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3.6))
            if !Task.isCancelled, !holding, !diving, !showCare {
                dimmed = true
            }
        }
    }

    private func wake() {
        dimmed = false
        scheduleIdle()
    }
}

// MARK: - Preview

#Preview("Session Player") {
    ZStack {
        OnboardingAtmosphere(config: .stat)
        SessionPlayerView(store: CoupleSessionStore(
            hand: Array(Card.samples.prefix(8)),
            modelContainer: .previewContainer,
            appState: AppState()
        ))
    }
    .preferredColorScheme(.dark)
}
