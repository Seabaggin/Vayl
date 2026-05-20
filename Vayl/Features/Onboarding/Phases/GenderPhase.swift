//
//  GenderPhase.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/10/26.
//

import SwiftUI

// MARK: - GenderDealPhase

private enum GenderDealPhase: Equatable {
    case idle
    case resting         // card on table, waiting for interaction
    case tugging         // the single downward tug hint
    case dragging        // user has their finger on the card
    case drifting        // auto-drift active after 5s timeout
    case lifting         // portal sequence firing
    case pickerVisible   // drum picker is shown
    case collecting      // card pocketing to CornerDeck
}

// MARK: - GenderPhase

struct GenderPhase: View {

    let director:   VaylDirector
    let screenSize: CGSize

    // TODO: Bryan supplies final copy for GenderPhase
    private let copyLineOne = "One thing helps me read the table right."
    private let copyLineTwo = "How do you identify?"

    private let identities: [String] = [
        "Man", "Woman", "Non-binary", "Transgender", "Genderfluid",
        "Agender", "Bigender", "Genderqueer", "Intersex", "Questioning"
    ]

    // ── Phase state ────────────────────────────────────────────────────────────
    @State private var dealPhase:  GenderDealPhase = .idle
    @State private var copyAlpha:  Double = 0

    // ── Card state ─────────────────────────────────────────────────────────────
    @State private var cardAlpha:       Double = 0
    @State private var cardScale:       Double = 1.0
    @State private var cardScreenAlpha: Double = 1.0
    @State private var flipScaleX:      Double = 1.0
    @State private var showFace:        Bool   = false
    @State private var faceStartDate:   Date?  = nil

    // ── Tug state ──────────────────────────────────────────────────────────────
    @State private var tugOffset:  CGFloat = 0
    @State private var hasTugged:  Bool    = false
    @State private var tugTask:    Task<Void, Never>? = nil

    // ── Drag / drift state ─────────────────────────────────────────────────────
    @State private var dragOffset: CGFloat = 0
    @State private var liftFired:  Bool    = false
    @State private var driftTask:  Task<Void, Never>? = nil

    // ── Picker state ───────────────────────────────────────────────────────────
    @State private var pickerAlpha:      Double = 0
    @State private var selectedIdentity: String = "Non-binary"
    @State private var isScrolling:      Bool   = false
    @State private var confirmAlpha:     Double = 0
    @State private var confirmTask:      Task<Void, Never>? = nil

    // ── Card geometry ──────────────────────────────────────────────────────────
    private var cardWidth:  CGFloat { AppLayout.obCardWidth(in: screenSize.width) }
    private var cardHeight: CGFloat { AppLayout.obCardHeight(in: screenSize.width) }

    // Card resting offset — positions the card at the table surface midpoint.
    // All drag and tug offsets are added on top of this.
    private var cardRestingOffset: CGSize {
        CGSize(
            width:  0,
            height: AppLayout.obTableCardCenterY(in: screenSize.height) - screenSize.height / 2
        )
    }

    // Threshold distance that triggers the portal.
    private var liftThreshold: CGFloat { screenSize.height * 0.18 }

    // ── Safe area helpers ──────────────────────────────────────────────────────
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

    // MARK: - Body

    var body: some View {
        ZStack {
            // Card layer
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { tl in
                let t: Double = {
                    guard showFace, let start = faceStartDate else { return 0 }
                    return tl.date.timeIntervalSince(start)
                }()
                cardLayer(deepT: t)
            }

            // Copy lines — fade in while resting
            if dealPhase == .resting || dealPhase == .tugging {
                copyLayer
                    .opacity(copyAlpha)
            }

            // Picker layer — appears after portal dissolve
            if dealPhase == .pickerVisible {
                pickerLayer
                    .opacity(pickerAlpha)
            }
        }
        .onAppear { start() }
        .onDisappear { cancelAllTasks() }
    }

    // MARK: - Card Layer

    private func cardLayer(deepT: Double) -> some View {
        Group {
            if !showFace {
                VaylCardBack()
            } else {
                PortalFaceContent(startDate: faceStartDate ?? Date())
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .scaleEffect(x: flipScaleX, y: 1.0)
        .scaleEffect(cardScale)
        .offset(
            x: cardRestingOffset.width,
            y: cardRestingOffset.height + tugOffset + dragOffset
        )
        .opacity(cardAlpha * cardScreenAlpha)
        .drawingGroup()
        .gesture(dragGesture)
    }

    // MARK: - Copy Layer

    private var copyLayer: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(copyLineOne)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textBody)
                .tracking(0.4)
                .multilineTextAlignment(.center)

            Text(copyLineTwo)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, AppSpacing.xl)
        .offset(y: cardRestingOffset.height - cardHeight / 2 - AppSpacing.lg)
    }

    // MARK: - Picker Layer

    private var pickerLayer: some View {
        VStack(spacing: 0) {
            Spacer()

            // Drum picker
            Picker("Identity", selection: $selectedIdentity) {
                ForEach(identities, id: \.self) { identity in
                    Text(identity)
                        .font(AppFonts.screenTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .tag(identity)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 200)
            .clipped()
            .onChange(of: selectedIdentity) {
                isScrolling = true
                confirmTask?.cancel()
                withAnimation(AppAnimation.fast) { confirmAlpha = 0 }
                // "That's me" appears 300ms after picker settles
                confirmTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(600))
                    guard !Task.isCancelled else { return }
                    isScrolling = false
                    withAnimation(AppAnimation.standard) { confirmAlpha = 1 }
                }
            }

            // "That's me" button
            Button {
                confirmSelection()
            } label: {
                Text("That's me")
                    .font(AppFonts.ctaLabel)
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppLayout.ctaHeight)
                    .background(identityGradient(for: selectedIdentity))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            }
            .opacity(confirmAlpha)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)

            Spacer().frame(height: safeBottom + AppSpacing.lg)
        }
    }

    // MARK: - Identity Gradient

    private func identityGradient(for identity: String) -> LinearGradient {
        let colors: (Color, Color) = {
            switch identity {
            case "Man":          return (Color(red: 0.24, green: 0.51, blue: 0.95), Color(red: 0.13, green: 0.36, blue: 0.78))
            case "Woman":        return (Color(red: 0.90, green: 0.35, blue: 0.65), Color(red: 0.70, green: 0.20, blue: 0.50))
            case "Non-binary":   return (Color(red: 0.97, green: 0.84, blue: 0.20), Color(red: 0.60, green: 0.22, blue: 0.80))
            case "Transgender":  return (Color(red: 0.36, green: 0.78, blue: 0.95), Color(red: 0.90, green: 0.50, blue: 0.65))
            case "Genderfluid":  return (Color(red: 0.60, green: 0.22, blue: 0.80), Color(red: 0.24, green: 0.51, blue: 0.95))
            case "Agender":      return (Color(red: 0.45, green: 0.45, blue: 0.45), Color(red: 0.20, green: 0.20, blue: 0.20))
            case "Bigender":     return (Color(red: 0.90, green: 0.35, blue: 0.65), Color(red: 0.24, green: 0.51, blue: 0.95))
            case "Genderqueer":  return (Color(red: 0.60, green: 0.22, blue: 0.80), Color(red: 0.13, green: 0.55, blue: 0.13))
            case "Intersex":     return (Color(red: 0.97, green: 0.78, blue: 0.10), Color(red: 0.55, green: 0.15, blue: 0.75))
            case "Questioning":  return (Color(red: 0.24, green: 0.51, blue: 0.95), Color(red: 0.60, green: 0.22, blue: 0.80))
            default:             return (AppColors.spectrumPurple, AppColors.spectrumCyan)
            }
        }()
        return LinearGradient(
            colors: [colors.0, colors.1],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Cancel tug and drift the instant drag begins
                tugTask?.cancel()
                driftTask?.cancel()
                guard !liftFired else { return }
                dealPhase = .dragging
                // Clamp to downward only — ignore upward motion
                let clampedTranslation = max(0, value.translation.height)
                dragOffset = clampedTranslation * 0.85  // resistance factor
            }
            .onEnded { value in
                guard !liftFired else { return }
                let distance = value.translation.height
                let velocity = value.predictedEndLocation.y - value.location.y
                if distance >= liftThreshold || velocity >= 400 {
                    performPortalLift()
                } else {
                    dealPhase = .resting
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.80)) {
                        dragOffset = 0
                    }
                    scheduleDrift()
                }
            }
    }

    // MARK: - Start

    @MainActor
    private func start() {
        // Card appears at resting position (placed by NamePhase conceptually)
        cardAlpha = 1.0
        dealPhase = .resting

        // Fade in copy lines
        withAnimation(.easeOut(duration: 0.52)) {
            copyAlpha = 1.0
        }

        // Schedule tug after 2 seconds
        scheduleTug()

        // Schedule drift after 5 seconds
        scheduleDrift()
    }

    // MARK: - Tug

    private func scheduleTug() {
        guard !hasTugged else { return }
        tugTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled, !hasTugged, dealPhase == .resting else { return }
            await performTug()
        }
    }

    @MainActor
    private func performTug() async {
        hasTugged = true
        dealPhase = .tugging
        // Down
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            tugOffset = 7
        }
        try? await Task.sleep(for: .milliseconds(400))
        guard !Task.isCancelled else { return }
        // Return
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            tugOffset = 0
        }
        try? await Task.sleep(for: .milliseconds(700))
        guard !Task.isCancelled else { return }
        dealPhase = .resting
    }

    // MARK: - Auto-Drift

    private func scheduleDrift() {
        driftTask?.cancel()
        driftTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled, dealPhase == .resting || dealPhase == .tugging else { return }
            guard !liftFired else { return }
            await performAutoDrift()
        }
    }

    @MainActor
    private func performAutoDrift() async {
        dealPhase = .drifting
        withAnimation(.spring(response: 1.2, dampingFraction: 0.9)) {
            dragOffset = liftThreshold
        }
        // Brief pause for animation to near-complete, then fire portal
        try? await Task.sleep(for: .milliseconds(900))
        guard !Task.isCancelled else { return }
        performPortalLift()
    }

    // MARK: - Portal Lift Sequence

    @MainActor
    private func performPortalLift() {
        guard !liftFired else { return }
        liftFired   = true
        dealPhase   = .lifting
        tugTask?.cancel()
        driftTask?.cancel()

        Task { @MainActor in
            // Fade copy
            withAnimation(.easeOut(duration: 0.20)) { copyAlpha = 0 }

            await triggerFlip()
        }
    }

    @MainActor
    private func triggerFlip() async {
        // First half — collapse to scaleX == 0
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            flipScaleX = 0.0
        }
        try? await Task.sleep(for: .milliseconds(190))

        // Swap to portal face at the invisible midpoint
        showFace      = true
        faceStartDate = Date()

        // Second half — expand mirrored (negative = face-up)
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            flipScaleX = -1.0
        }
        try? await Task.sleep(for: .milliseconds(660))

        await triggerExpand()
    }

    @MainActor
    private func triggerExpand() async {
        let scaleX = screenSize.width  / cardWidth
        let scaleY = screenSize.height / cardHeight
        let target = max(scaleX, scaleY) * 1.04  // 4% overshoot for full bleed

        withAnimation(.easeIn(duration: 0.55)) {
            director.tableFade = 0.0
        }
        withAnimation(.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 1.05)) {
            cardScale = target
        }
        try? await Task.sleep(for: .milliseconds(550))

        withAnimation(.easeIn(duration: 0.35)) {
            cardScreenAlpha = 0.0
        }
        try? await Task.sleep(for: .milliseconds(380))

        showPicker()
    }

    @MainActor
    private func showPicker() {
        dealPhase = .pickerVisible
        withAnimation(.easeOut(duration: 0.52)) {
            pickerAlpha = 1.0
        }
        // Show confirm button after initial settle (no prior scroll event)
        confirmTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            guard !Task.isCancelled else { return }
            withAnimation(AppAnimation.standard) { confirmAlpha = 1 }
        }
    }

    // MARK: - Confirm Selection

    @MainActor
    private func confirmSelection() {
        director.onboardingData.genderIdentity = selectedIdentity

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        withAnimation(AppAnimation.fast) { pickerAlpha = 0 }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            performCardCollect()
        }
    }

    // MARK: - Card Collect

    @MainActor
    private func performCardCollect() {
        dealPhase = .collecting

        let cornerTarget = CGPoint(
            x: screenSize.width  - AppLayout.cornerDeckRight - AppLayout.cornerDeckWidth  / 2,
            y: AppLayout.cornerDeckTop + AppLayout.cornerDeckHeight / 2
        )
        let cornerOffset = CGSize(
            width:  cornerTarget.x - screenSize.width  / 2,
            height: cornerTarget.y - screenSize.height / 2
        )

        // Reset card state for collect animation
        withAnimation(AppAnimation.standard) {
            cardScreenAlpha = 1.0
            cardScale       = 1.0
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))

            withAnimation(AppAnimation.cardPocket) {
                dragOffset      = cornerOffset.height - cardRestingOffset.height
                cardScale       = 0.22
                cardAlpha       = 0
            }
            try? await Task.sleep(for: .milliseconds(600))

            let corner = VaylCardModel()
            corner.credential = .gender
            director.cornerDeckCards.append(corner)

            director.advance(to: .modeSelect)
        }
    }

    // MARK: - Cleanup

    private func cancelAllTasks() {
        tugTask?.cancel()
        driftTask?.cancel()
        confirmTask?.cancel()
        liftFired = false
    }
}
