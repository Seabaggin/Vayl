// Vayl/Features/Onboarding/Phases/NamePhase.swift

import SwiftUI

// MARK: - CardDealPhase

/// Sub-phase state machine local to NamePhase.
/// VaylDirector stays at macro level (.nameInput).
/// This enum drives the card deal animation sequence.
private enum CardDealPhase {
    case idle
    case dealing       // card in flight from top-right
    case landing       // card hits table — rimBurst fires
    case organizing    // eerie auto-drift to center
    case settled       // copy beats, 1.2s timer
    case flipping      // back → Deep face, automatic
    case expanding     // card scales to fill screen
    case nameInput     // UI active, swipe-down to submit
}

// MARK: - NamePhase

struct NamePhase: View {

    let director:   VaylDirector
    let screenSize: CGSize

    // ── Deal state ─────────────────────────────────────────────────────────────
    @State private var dealTask:     Task<Void, Never>? = nil
    @State private var dealPhase:    CardDealPhase = .idle
    @State private var cardOffset:   CGSize        = .zero
    @State private var cardAngle:    Double        = 0
    @State private var cardAlpha:    Double        = 0
    @State private var rimBurst:     Double        = 0

    // Landing seed — generated once, stable across replays in session
    @State private var landingAngle:  Double = 0
    @State private var landingOffset: CGSize = .zero

    // ── Flip state ─────────────────────────────────────────────────────────────
    @State private var flipScaleX: Double = 1.0
    @State private var showFace:   Bool   = false
    @State private var faceStartDate: Date? = nil

    // ── Expand state ───────────────────────────────────────────────────────────
    @State private var cardScale:  Double = 1.0
    @State private var tableFade:  Double = 1.0
    @State private var cardScreenAlpha: Double = 1.0

    // ── Name input state ───────────────────────────────────────────────────────
    @State private var name:      String  = ""
    @State private var uiAlpha:   Double  = 0
    @State private var dragY:     CGFloat = 0
    @State private var isCharging: Bool   = false

    // ── Card geometry ──────────────────────────────────────────────────────────
    // AppLayout.obCardWidth(in:) and obCardHeight(in:) take screenWidth: CGFloat
    private var cardWidth:  CGFloat { AppLayout.obCardWidth(in: screenSize.width) }
    private var cardHeight: CGFloat { AppLayout.obCardHeight(in: screenSize.width) }

    // Starting position — off-screen top-right
    private var dealOrigin: CGSize {
        CGSize(
            width:  screenSize.width  * 0.60,
            height: -screenSize.height * 0.58
        )
    }

    // Safe area helpers — resolved from UIWindowScene at render time
    private var safeTop: CGFloat {
        guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow })
        else { return 44 }
        return window.safeAreaInsets.top
    }

    private var safeBottom: CGFloat {
        guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow })
        else { return 34 }
        return window.safeAreaInsets.bottom
    }

    var body: some View {
        ZStack {
            // Table surface — fades out during expand
            TableSurfaceView(fade: tableFade, rimBurst: rimBurst)

            // Card layer
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { tl in
                let t: Double = {
                    guard showFace, let start = faceStartDate else { return 0 }
                    return tl.date.timeIntervalSince(start)
                }()
                cardLayerWithTime(t)
            }

            // Name input UI — appears after expand
            if dealPhase == .nameInput {
                nameInputLayer
                    .opacity(uiAlpha)
            }
        }
        .onAppear {
            seedLanding()
            dealTask = Task { @MainActor in startDeal() }
        }
        .onDisappear { dealTask?.cancel() }
    }

    // MARK: - Card Layer

    private func cardLayerWithTime(_ deepT: Double) -> some View {
        Group {
            if !showFace {
                VaylCardBack()
            } else {
                OBDeepCardFace(deepT: deepT)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .scaleEffect(x: flipScaleX, y: 1.0)
        .scaleEffect(cardScale)
        .offset(cardOffset)
        .rotationEffect(.degrees(cardAngle))
        .opacity(cardAlpha * cardScreenAlpha)
        .drawingGroup()
    }

    // MARK: - Name Input Layer

    private var nameInputLayer: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: safeTop + 58)

            // Back button
            Circle()
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                .frame(width: 30, height: 30)
                .overlay {
                    Text("←")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.25))
                }
                .padding(.bottom, 32)

            // Header
            VStack(alignment: .leading, spacing: 0) {
                Text("Let's get")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)
                Text("acquainted.")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.spectrumBorder)
            }
            .padding(.bottom, 32)

            // Name field
            VStack(alignment: .leading, spacing: 5) {
                Text("WHAT DO I CALL YOU?")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.spectrumPurple.opacity(0.78))
                    .tracking(2.5)

                TextField("", text: $name)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .tint(AppColors.spectrumCyan)

                // Write line
                Rectangle()
                    .fill(AppColors.spectrumBorder.opacity(0.60))
                    .frame(height: 2)

                // Glow under write line
                Rectangle()
                    .fill(AppColors.spectrumBorder.opacity(0.15))
                    .frame(height: 8)
                    .blur(radius: 4)
                    .padding(.top, -6)
            }

            Divider()
                .background(AppColors.spectrumPurple.opacity(0.12))
                .padding(.vertical, 24)

            Spacer()

            Text("terms · privacy")
                .font(AppFonts.caption)
                .foregroundStyle(Color.white.opacity(0.09))
                .tracking(2)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer().frame(height: safeBottom + 42)
        }
        .padding(.horizontal, 32)
        .gesture(
            DragGesture()
                .onChanged { v in dragY = v.translation.height }
                .onEnded   { v in handleSwipeDown(v.translation.height) }
        )
    }

    // MARK: - Deal sequence

    @MainActor
    private func seedLanding() {
        landingAngle  = Double.random(in: -7...7)
        landingOffset = CGSize(
            width:  CGFloat.random(in: -38...38),
            height: CGFloat.random(in: -28...28)
        )
    }

    @MainActor
    private func startDeal() {
        // Place card at origin (invisible)
        cardOffset = dealOrigin
        cardAngle  = -14
        cardAlpha  = 0
        dealPhase  = .dealing

        // Fade in card as it enters
        withAnimation(.linear(duration: 0.14)) {
            cardAlpha = 1
        }

        // Deal flight — rotation and offset use slightly different springs
        // so they don't arrive simultaneously, producing natural tilt in flight
        withAnimation(
            .interpolatingSpring(mass: 1.1, stiffness: 160, damping: 18, initialVelocity: 6)
        ) {
            cardOffset = landingOffset
            cardAngle  = landingAngle
        }

        // Offset arrives first (~920ms), then trigger landing
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(940))
            triggerLanding()
        }
    }

    @MainActor
    private func triggerLanding() {
        dealPhase = .landing

        // rimBurst spike with long decay
        rimBurst = 1.0
        withAnimation(.timingCurve(0.2, 0.8, 0.4, 1.0, duration: 0.6)) {
            rimBurst = 0.0
        }

        // Short beat then organize
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            triggerOrganize()
        }
    }

    @MainActor
    private func triggerOrganize() {
        dealPhase = .organizing

        // Critically damped — zero overshoot. Eerie precision.
        withAnimation(.spring(response: 0.72, dampingFraction: 1.0)) {
            cardOffset = .zero
            cardAngle  = 0
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(780))
            dealPhase = .settled
            // 1.2s settled beat, then flip
            try? await Task.sleep(for: .milliseconds(1200))
            triggerFlip()
        }
    }

    // MARK: - Forward stubs (Task 4 + 5 will replace these)

    @MainActor private func triggerFlip()                  { /* Task 4 */ }
    @MainActor private func triggerExpand()                { /* Task 4 */ }
    @MainActor private func triggerNameInput()             { /* Task 4 */ }
    @MainActor private func submitName()                   { /* Task 5 */ }
    @MainActor private func handleSwipeDown(_ y: CGFloat)  { /* Task 5 */ }
}
