//
//  AirlockView.swift
//  Vayl
//
//  Screen 1 of the couple session cover: the airlock.
//  House rules fold into a 2x2, your bandwidth is a private segmented reading,
//  and the lock-in is the hold-and-release sync ring — both hold, the ring
//  fills, both release at close-enough points. Off → reset. In sync → the
//  phones-down transition, then the first card.
//
//  Faithful to docs/prototypes/couple-session-airlock.html. The both-release
//  tolerance is the friction that keeps it honest: forgiving for two people in
//  a room, not fakeable solo. Partner presence + the partner release point are
//  mocked in the store for now (no Realtime).
//

import SwiftUI

struct AirlockView: View {

    @Bindable var store: CoupleSessionStore

    @Environment(\.vaylDismiss) private var vaylDismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Ring rendering geometry (rendering constants, like ScoreRing).
    private let ringSize: CGFloat = 156
    private let ringRadius: CGFloat = 62
    private let fillSeconds: Double = 3.2
    private let tolerance: CGFloat = 0.13

    private enum SyncPhase { case waiting, ready, holding, synced, miss }
    @State private var syncPhase: SyncPhase = .waiting
    @State private var fill: CGFloat = 0
    @State private var holding = false
    @State private var youFraction: CGFloat = 0
    @State private var partnerFraction: CGFloat = 0
    @State private var ringAlive = false
    @State private var glowBreathe = false
    @State private var showSyncTutorial = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Text("Before we start")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.top, AppSpacing.md)

            rulesGrid
                .padding(.top, AppSpacing.md)

            syncArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.xxl)
        .padding(.bottom, AppSpacing.xl)
        .onAppear { store.armPresence() }
        .onChange(of: store.partnerPresent) { _, present in
            if present, syncPhase == .waiting {
                withAnimation(AppAnimation.slow) { syncPhase = .ready }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { vaylDismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(AppColors.cardBackground))
                    .overlay(Circle().strokeBorder(AppColors.borderDefault, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("The Opener · \(store.hand.count) \(store.hand.count == 1 ? "card" : "cards") · ~\(max(1, store.hand.count * 2)) min")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    // MARK: - 2x2 rules grid

    private var rulesGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: AppSpacing.sm),
            GridItem(.flexible(), spacing: AppSpacing.sm)
        ]
        return LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
            ruleBox(title: "Take your time",
                    sub: "Silence is fine. Both of you answer, every card.")
            ruleBox(title: "Listen first",
                    sub: "Say what you heard before it's your turn.")
            ruleBox(title: "No fixing",
                    sub: "Just get each other. Pass anytime. It stays here.")
            bandwidthBox
        }
    }

    private func ruleBox(title: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Circle()
                .fill(AppColors.spectrumBorder)
                .frame(width: 8, height: 8)
            Spacer(minLength: 0)
            Text(title)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textBody)
            Text(sub)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .padding(AppSpacing.md)
        .background(boxBackground)
    }

    private var bandwidthBox: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Your pulse")
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textBody)
            Text("how much you've got tonight · shared")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
            Spacer(minLength: 0)
            HStack(spacing: AppSpacing.xs) {
                ForEach(CoupleSessionStore.Bandwidth.allCases, id: \.self) { b in
                    bandwidthChip(b)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .padding(AppSpacing.md)
        .background(boxBackground)
    }

    private func bandwidthChip(_ b: CoupleSessionStore.Bandwidth) -> some View {
        let selected = store.bandwidth == b
        return Text(b.label)
            .font(AppFonts.buttonLabelSmall)
            .textCase(.uppercase)
            .foregroundStyle(selected ? AppColors.void : AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .fill(selected ? AnyShapeStyle(AppColors.spectrumBorder)
                                   : AnyShapeStyle(Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .strokeBorder(AppColors.borderDefault, lineWidth: selected ? 0 : 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                UISelectionFeedbackGenerator().selectionChanged()
                withAnimation(AppAnimation.fast) { store.setBandwidth(b) }
            }
    }

    private var boxBackground: some View {
        RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
            .fill(AppColors.cardBg)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
                    .strokeBorder(AppColors.spectrumBorder.opacity(0.4), lineWidth: 0.8)
            )
    }

    // MARK: - Sync ring

    private var syncArea: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                Spacer()
                Button { showSyncTutorial = true } label: {
                    Image(systemName: "info.circle")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("How syncing works")
            }

            Spacer(minLength: 0)

            ring
                .opacity(syncPhase == .waiting ? 0.32 : 1)
                .animation(AppAnimation.slow, value: syncPhase)

            Text(syncMessage)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
                .multilineTextAlignment(.center)
                .frame(minHeight: 22)

            presenceRow
        }
        .vaylSheet(isPresented: $showSyncTutorial, heightFraction: 0.55) { syncTutorialSheet }
    }

    // MARK: - Sync tutorial sheet

    private var syncTutorialSheet: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.xs) {
                Text("Syncing to begin")
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textPrimary)
                Text("A shared breath, on both phones at once.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            HStack(spacing: AppSpacing.md) {
                tutorialPhone
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundStyle(AppColors.textTertiary)
                tutorialPhone
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                tutorialStep(1, "Both of you press and hold. Each ring fills.")
                tutorialStep(2, "On a shared count, release at the same time.")
                tutorialStep(3, "Land close enough and you're in. Off, and it resets.")
            }

            Button { showSyncTutorial = false } label: {
                Text("Got it")
                    .font(AppFonts.ctaLabel)
                    .foregroundStyle(AppColors.textBody)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            .strokeBorder(AppColors.spectrumBorder.opacity(0.4), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.lg)
        .padding(.top, AppSpacing.sm)        // grabber (in .vaylSheet) supplies the top gap
    }

    private var tutorialPhone: some View {
        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
            .fill(AppColors.cardBg)
            .frame(width: 76, height: 138)
            .overlay(
                Circle()
                    .strokeBorder(AppColors.spectrumBorder, lineWidth: 3)
                    .frame(width: 44, height: 44)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(AppColors.borderDefault, lineWidth: 1)
            )
    }

    private func tutorialStep(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Text("\(n)")
                .font(AppFonts.buttonLabelSmall)
                .foregroundStyle(AppColors.textBody)
                .frame(width: 20, height: 20)
                .overlay(Circle().strokeBorder(AppColors.borderDefault, lineWidth: 1))
            Text(text)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
        }
    }

    private var ring: some View {
        ZStack {
            // Track
            Circle()
                .stroke(AppColors.textPrimary.opacity(0.10), lineWidth: 4)

            // Breathing glow when ready
            Circle()
                .stroke(AppColors.spectrumBorder, lineWidth: 13)
                .blur(radius: 7)
                .opacity(ringAlive && (syncPhase == .ready || syncPhase == .synced)
                         ? (glowBreathe ? 0.85 : 0.4) : 0)
                .ambientAnimation(
                    .easeInOut(duration: AppAnimation.ambientPulse * 1.5).repeatForever(autoreverses: true),
                    value: glowBreathe
                )

            // Progress arc
            Circle()
                .trim(from: 0, to: fill)
                .stroke(AppColors.spectrumBorder,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Release markers
            if syncPhase == .synced || syncPhase == .miss {
                marker(at: youFraction, color: AppColors.textBody)
                marker(at: partnerFraction, color: AppColors.spectrumMagenta)
            }

            Text(ringHint)
                .font(AppFonts.overline)
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(width: ringSize, height: ringSize)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in startHold() }
                .onEnded { _ in endHold() }
        )
        .onChange(of: syncPhase) { _, phase in
            ringAlive = (phase == .ready || phase == .synced)
            if ringAlive { glowBreathe = true }
        }
    }

    private func marker(at fraction: CGFloat, color: Color) -> some View {
        let angle = (-90 + Double(fraction) * 360) * .pi / 180
        let r = ringRadius
        let x = ringSize / 2 + r * CGFloat(cos(angle))
        let y = ringSize / 2 + r * CGFloat(sin(angle))
        return Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .position(x: x, y: y)
    }

    private var presenceRow: some View {
        HStack(spacing: AppSpacing.lg) {
            presenceChip(name: "You", detail: store.bandwidth.label, present: true, you: true)
            presenceChip(name: "Partner",
                         detail: store.partnerPresent ? store.partnerBandwidth.label : nil,
                         present: store.partnerPresent, you: false)
        }
    }

    private func presenceChip(name: String, detail: String?, present: Bool, you: Bool) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Circle()
                .fill(present
                      ? AnyShapeStyle(you
                            ? LinearGradient(colors: [AppColors.spectrumCyan, AppColors.accentSecondary],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [AppColors.spectrumMagenta, AppColors.accentSecondary],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                      : AnyShapeStyle(Color.clear))
                .frame(width: 8, height: 8)
                .overlay(Circle().strokeBorder(AppColors.textTertiary, lineWidth: present ? 0 : 1.3))
                .opacity(present ? 1 : (waitingPulse ? 1 : 0.35))
                .ambientAnimation(
                    .easeInOut(duration: AppAnimation.ambientPulse / 1.5).repeatForever(autoreverses: true),
                    value: waitingPulse
                )
            Text(detail != nil ? "\(name) · \(detail!)" : name)
                .font(AppFonts.caption)
                .foregroundStyle(present ? AppColors.textBody : AppColors.textSecondary)
        }
        .onAppear { waitingPulse = true }
    }

    @State private var waitingPulse = false

    // MARK: - Copy

    private var syncMessage: String {
        switch syncPhase {
        case .waiting: return "waiting for your partner to join…"
        case .ready:   return "hold, then release together"
        case .holding: return "hold…"
        case .synced:  return "you're in sync"
        case .miss:    return "release at the same time, try again"
        }
    }

    private var ringHint: String {
        switch syncPhase {
        case .waiting, .ready: return "hold"
        case .holding:         return "release"
        case .synced:          return "in sync"
        case .miss:            return "almost"
        }
    }

    // MARK: - Hold / release mechanic

    private func startHold() {
        guard syncPhase == .ready, !holding else { return }
        holding = true
        syncPhase = .holding
        fill = 0
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        let start = Date()
        Task { @MainActor in
            while holding {
                let elapsed = Date().timeIntervalSince(start)
                fill = min(1, CGFloat(elapsed / fillSeconds))
                if fill >= 1 {
                    holding = false
                    tooLong()
                    break
                }
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func endHold() {
        guard holding else { return }
        holding = false
        release(at: fill)
    }

    private func release(at fraction: CGFloat) {
        youFraction = fraction
        // Mock the partner's release point near yours (Realtime later).
        let offset = CGFloat.random(in: -0.10...0.10)
        partnerFraction = max(0.05, min(0.97, fraction + offset))

        if abs(youFraction - partnerFraction) <= tolerance {
            synced()
        } else {
            miss()
        }
    }

    private func synced() {
        syncPhase = .synced
        withAnimation(AppAnimation.standard) { fill = 1 }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.1))
            store.confirmSynced()
        }
    }

    private func miss() {
        syncPhase = .miss
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        resetRingAfterBeat()
    }

    private func tooLong() {
        syncPhase = .miss
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        resetRingAfterBeat()
    }

    private func resetRingAfterBeat() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(AppAnimation.standard) { fill = 0 }
            youFraction = 0
            partnerFraction = 0
            if store.partnerPresent { syncPhase = .ready }
        }
    }
}

// MARK: - Preview

#Preview("Airlock") {
    ZStack {
        SessionAtmosphere()
        AirlockView(store: CoupleSessionStore(
            hand: Array(Card.samples.prefix(8)),
            modelContainer: .previewContainer,
            appState: AppState()
        ))
    }
    .preferredColorScheme(.dark)
}
