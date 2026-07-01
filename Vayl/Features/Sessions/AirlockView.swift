//
//  AirlockView.swift
//  Vayl
//
//  The airlock, two screens (cover-family 1A/1B):
//    1A house rules: six spectrum bullets, read aloud together, one tap on
//       "We're ready". Repeat sessions collapse to a one-line "settle in".
//    1B bandwidth + lock-in: private 3-detent slider, 3-second press-and-hold
//       lock-in, presence row. The gentler of the two readings becomes the
//       session's depth ceiling; the raw reading is never shown to the partner.
//
//  Driven by AirlockStore (real presence/consent). airlock == nil is the
//  DEBUG-only local path (mocked partner, unchanged store mock).
//

import SwiftUI

struct AirlockView: View {

    @Bindable var store: CoupleSessionStore
    let airlock: AirlockStore?

    @Environment(\.vaylDismiss) private var vaylDismiss

    private enum Step { case rules, bandwidth }
    @State private var step: Step = .rules
    @State private var lockedIn = false
    @State private var waitingPulse = false

    /// Repeat couples get the one-liner, not the six bullets (spec 4.5).
    private var isRepeatSession: Bool {
        UserDefaults.standard.bool(forKey: UserDefaultsKey.hasCompletedCoupleSession)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            switch step {
            case .rules:     rulesScreen
            case .bandwidth: bandwidthScreen
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.xxl)
        .padding(.bottom, AppSpacing.xl)
        .animation(AppAnimation.enter.reduceMotionSafe, value: step)
        .onAppear {
            if airlock == nil { store.armPresence() }   // DEBUG local mock only
        }
    }

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
            Text("\(store.deckTitle) · \(store.hand.count) \(store.hand.count == 1 ? "card" : "cards")")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    // MARK: - 1A · house rules

    private var rulesScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppSpacing.sm) {
                Text("✦").font(AppFonts.bodyMedium).foregroundStyle(AppColors.spectrumText)
                Text("settle in")
                    .font(AppFonts.overline).tracking(2).textCase(.uppercase)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.top, AppSpacing.lg)

            Text("Before we start")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.top, AppSpacing.sm)

            if isRepeatSession {
                Text("You know the room. Settle in, then say you're ready.")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.top, AppSpacing.md)
            } else {
                Text("Read these out loud, together.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.top, AppSpacing.xs)

                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    bulletRow("Take your time. Silence is fine.")
                    bulletRow("Both of you answer, every card.")
                    bulletRow("Listen first. Say what you heard before your turn.")
                    bulletRow("No fixing, no judging, just get each other.")
                    bulletRow("What's said here stays here.")
                    bulletRow("You can always pass.")
                }
                .padding(.top, AppSpacing.lg)
            }

            Spacer(minLength: 0)

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(AppAnimation.enter.reduceMotionSafe) { step = .bandwidth }
            } label: {
                Text("We're ready")
                    .font(AppFonts.ctaLabel)
                    .foregroundStyle(AppColors.textBody)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            .strokeBorder(AppColors.spectrumBorder, lineWidth: 1.2)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func bulletRow(_ text: String) -> some View {
        // SpectrumBulletRow (mockup): 7pt spectrum dot + one line.
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Circle()
                .fill(AppColors.spectrumBorder)
                .frame(width: 7, height: 7)
                .padding(.top, AppSpacing.xs + AppSpacing.xxs)
            Text(text)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 1B · bandwidth + lock-in

    private var bandwidthScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppSpacing.sm) {
                Text("✦").font(AppFonts.bodyMedium).foregroundStyle(AppColors.spectrumText)
                Text("lock in")
                    .font(AppFonts.overline).tracking(2).textCase(.uppercase)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.top, AppSpacing.lg)

            Text("How much have you\ngot for each other?")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.top, AppSpacing.sm)

            BandwidthSlider(selection: $store.bandwidth)
                .padding(.top, AppSpacing.xl)
                .disabled(lockedIn)
                .opacity(lockedIn ? 0.6 : 1)

            Spacer(minLength: 0)

            VStack(spacing: AppSpacing.md) {
                HoldToLockInRing(locked: lockedIn) {
                    lockedIn = true
                    if let airlock {
                        let fraction = store.bandwidth.fraction
                        Task { @MainActor in
                            await airlock.commitBandwidth(fraction)
                            await airlock.consent()
                        }
                    } else {
                        store.confirmSynced()   // DEBUG local path, mock unchanged
                    }
                }
                Text(lockedIn ? "you're locked in" : "press and hold to lock in")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                presenceRow
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var presenceRow: some View {
        HStack(spacing: AppSpacing.md) {
            presenceChip("You", ready: lockedIn, you: true)
            Text(partnerStatusLine)
                .font(AppFonts.overline)
                .foregroundStyle(AppColors.textTertiary)
                .frame(maxWidth: .infinity)
            presenceChip(store.partnerLabel,
                         ready: airlock?.partnerConsented ?? store.partnerPresent,
                         you: false)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + AppSpacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColors.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
                )
        )
    }

    private var partnerStatusLine: String {
        if airlock?.partnerConsented == true { return "both in" }
        return lockedIn ? "waiting for \(store.partnerLabel)…" : ""
    }

    private func presenceChip(_ name: String, ready: Bool, you: Bool) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Circle()
                .fill(ready
                      ? AnyShapeStyle(LinearGradient(
                            colors: you ? [AppColors.spectrumCyan, AppColors.accentSecondary]
                                        : [AppColors.spectrumMagenta, AppColors.accentSecondary],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                      : AnyShapeStyle(Color.clear))
                .frame(width: 9, height: 9)
                .overlay(Circle().strokeBorder(AppColors.textTertiary, lineWidth: ready ? 0 : 1.3))
                .opacity(ready ? 1 : (waitingPulse ? 1 : 0.35))
                .ambientAnimation(
                    .easeInOut(duration: AppAnimation.ambientPulse / 1.5).repeatForever(autoreverses: true),
                    value: waitingPulse
                )
            Text(name)
                .font(AppFonts.caption)
                .foregroundStyle(ready ? AppColors.textBody : AppColors.textSecondary)
        }
        .onAppear { waitingPulse = true }
    }
}

// MARK: - Preview

#Preview("Airlock — local stub") {
    ZStack {
        SessionAtmosphere()
        AirlockView(store: CoupleSessionStore(
            hand: Array(Card.samples.prefix(8)),
            modelContainer: .previewContainer,
            appState: AppState()
        ), airlock: nil)
    }
    .preferredColorScheme(.dark)
}
