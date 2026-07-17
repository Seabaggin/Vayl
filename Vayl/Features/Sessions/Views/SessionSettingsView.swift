//
//  SessionSettingsView.swift
//  Vayl
//
//  The session pre-roll room: the merged "connect + settings" screen that
//  replaced the old SessionLobbyView. Presence frames the screen (the partner
//  arriving is the emotional beat); the two knobs — who reads first, and
//  length/pace — sit under it as the thing you set while you wait.
//
//  Auto-advance is owned by the container: the instant AirlockStore reports
//  bothPresent, CoupleSessionFlow swaps this for AirlockView (consent + deck
//  edit + sync ring). So there is no "Start" here — presence advances, and the
//  only manual affordance is a quiet cancel. Cover-family chrome (the container
//  supplies the void + atmosphere).
//
//  Two modes, by entry:
//   • initiator — "Waiting for <partner>" + the two knob groups + Cancel.
//   • joiner    — a light "You're in the room" beat (settings are the
//                 initiator's; the joiner edits the deck later, in the airlock).
//

import SwiftUI

struct SessionSettingsView: View {

    @Bindable var store: CoupleSessionStore
    let airlock: AirlockStore

    @Environment(\.vaylDismiss) private var vaylDismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var waitingPulse = false

    private var isInitiator: Bool { store.entry == .initiator }
    private var cardCount: Int { store.hand.count }

    // MARK: - Settings bindings (write straight through to the session store)

    private var readerBinding: Binding<SessionSettings.Reader> {
        Binding(get: { store.sessionSettings.reader }, set: { store.setReader($0) })
    }
    private var lengthBinding: Binding<SessionSettings.Length> {
        Binding(get: { store.sessionSettings.length }, set: { store.setLength($0) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            frame

            if isInitiator {
                waitRule
                    .padding(.top, AppSpacing.lg)

                readerGroup
                    .padding(.top, AppSpacing.lg)

                lengthGroup
                    .padding(.top, AppSpacing.lg)
            }

            Spacer(minLength: AppSpacing.lg)

            cancelButton
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.xxl)
        .padding(.bottom, AppSpacing.xl)
        .onAppear { waitingPulse = true }
    }

    // MARK: - Frame (presence is the hero)

    private var frame: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppSpacing.sm) {
                Text("✦")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.spectrumText)
                Text("session lobby")
                    .font(AppFonts.overline)
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.bottom, AppSpacing.lg)

            HStack(spacing: AppSpacing.sm) {
                presenceDot
                Text(isInitiator ? "Waiting for \(store.partnerLabel)" : "You're in the room")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)
            }

            if case .failed(let reason) = airlock.state {
                Text(reason)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.top, AppSpacing.sm)
            }
        }
    }

    /// The live presence pulse, sitting inline with the hero. The hero copy
    /// already says "Waiting for <partner>", so the old caption that repeated it
    /// is gone — the breathing dot carries the liveness, the hero the words.
    private var presenceDot: some View {
        Circle()
            .fill(airlock.partnerPresent ? AppColors.spectrumMagenta : AppColors.accentPrimary)
            .frame(width: 9, height: 9)
            .opacity(airlock.partnerPresent ? 1 : (waitingPulse ? 0.75 : 0.4))
            .background(
                // Present-state halo — a blurred circle, not a `.shadow()` (glow rule).
                Circle()
                    .fill(AppColors.spectrumMagenta)
                    .frame(width: 9, height: 9)
                    .blur(radius: 6)
                    .opacity(airlock.partnerPresent ? 0.6 : 0)
            )
            .ambientAnimation(
                .easeInOut(duration: AppAnimation.ambientPulse).repeatForever(autoreverses: true),
                value: waitingPulse
            )
    }

    // MARK: - "While you wait" divider

    private var waitRule: some View {
        HStack(spacing: AppSpacing.md) {
            line
            Text("while you wait")
                .font(AppFonts.overline)
                .tracking(1.5)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textTertiary)
                .fixedSize()
            line
        }
    }

    private var line: some View {
        Rectangle()
            .fill(AppColors.borderSubtle)
            .frame(height: 1)
    }

    // MARK: - Who reads first

    private var readerGroup: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            groupLabel("WHO READS FIRST")
            SegmentedPillGroup(
                options: [
                    .init(.you,
                          label: SessionSettings.Reader.you.displayLabel(partnerName: store.partnerLabel),
                          accent: AppColors.spectrumCyan),
                    .init(.partner,
                          label: SessionSettings.Reader.partner.displayLabel(partnerName: store.partnerLabel),
                          accent: AppColors.spectrumPurple),
                    .init(.either,
                          label: SessionSettings.Reader.either.displayLabel(partnerName: store.partnerLabel),
                          accent: AppColors.spectrumMagenta)
                ],
                selection: readerBinding
            )
        }
    }

    // MARK: - Length & pace (scales to the selected hand)

    private var lengthGroup: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            groupLabel("LENGTH & PACE")
            SegmentedPillGroup(
                options: [
                    .init(.short,
                          label: SessionSettings.Length.short.displayLabel,
                          sublabel: paceEstimate(.short),
                          accent: AppColors.spectrumCyan),
                    .init(.full,
                          label: SessionSettings.Length.full.displayLabel,
                          sublabel: paceEstimate(.full),
                          accent: AppColors.spectrumPurple),
                    .init(.unhurried,
                          label: SessionSettings.Length.unhurried.displayLabel,
                          sublabel: paceEstimate(.unhurried),
                          accent: AppColors.spectrumMagenta)
                ],
                selection: lengthBinding
            )

            Text("Full gives both of you room to answer and follow up; Short keeps it lighter. A soft nudge near the end, never a hard stop.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
    }

    private func paceEstimate(_ length: SessionSettings.Length) -> String {
        if let minutes = length.estimatedMinutes(cardCount: cardCount) {
            "~\(minutes) min"
        } else {
            "no cap"
        }
    }

    // MARK: - Cancel

    private var cancelButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            store.abandonRemoteSession()
            airlock.leave()
            vaylDismiss(confirm: false)
        } label: {
            Text(isInitiator ? "Cancel session" : "Not now")
                .font(AppFonts.buttonLabel)
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .strokeBorder(AppColors.borderDefault, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Building blocks

    private func groupLabel(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.overline)
            .tracking(2)
            .foregroundStyle(AppColors.textSectionLabel)
    }
}

// MARK: - Preview

#Preview("Pre-roll — initiator, configuring") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat)
        SessionSettingsView(
            store: CoupleSessionStore(
                launch: SessionLaunch(
                    hand: Array(Card.samples.prefix(4)),
                    entry: .initiator,
                    role: .a,
                    session: nil
                ),
                modelContainer: .previewContainer,
                appState: AppState()
            ),
            airlock: AirlockStore(coupleId: UUID(), myProfileId: UUID(), role: .a)
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Pre-roll — joiner, in the room") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat)
        SessionSettingsView(
            store: CoupleSessionStore(
                launch: SessionLaunch(
                    hand: Array(Card.samples.prefix(4)),
                    entry: .joiner,
                    role: .b,
                    session: nil
                ),
                modelContainer: .previewContainer,
                appState: AppState()
            ),
            airlock: AirlockStore(coupleId: UUID(), myProfileId: UUID(), role: .b)
        )
    }
    .preferredColorScheme(.dark)
}
