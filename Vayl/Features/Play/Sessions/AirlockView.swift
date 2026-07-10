//
//  AirlockView.swift
//  Vayl
//
//  The airlock — ONE merged "Before we start" screen (not two steps): a pure
//  capacity mirror, an optional centering ritual, and the lock-in ring. The
//  house rules are intentionally NOT here — six bullets took too much space
//  once capacity + ritual + ring shared the screen (Bryan's call).
//
//  The lock-in is the two-person SYNC round (spec 2026-07-08): both partners
//  press-and-hold to arm, a shared 3-2-1 fires, both rings sweep blind, and
//  both must let go within tolerance of each other. Driven by airlock.sync
//  (SyncLockInCoordinator) over the realtime channel. When the channel is down
//  (poll fallback) or in the DEBUG local path, the view falls back to the
//  per-device HoldToLockInRing — kept in the tree deliberately as the explicit
//  fallback if the two-device proof fails.
//
//  Driven by AirlockStore (real presence/consent). airlock == nil is the
//  DEBUG-only local path (mocked partner, unchanged store mock).
//

import SwiftUI

struct AirlockView: View {

    @Bindable var store: CoupleSessionStore
    let airlock: AirlockStore?

    @Environment(\.vaylDismiss) private var vaylDismiss
    @Environment(PulseStore.self) private var pulseStore

    @State private var lockedIn = false
    @State private var consentFailed = false
    @State private var waitingPulse = false
    @State private var selectedRitual: Ritual?
    @State private var capacityStore = CoupleCapacityStore()
    @State private var showHowItWorks = false

    private var yourTier: PulseCapacityColor {
        pulseStore.currentPosition.quadrant.capacityColor
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                eyebrowTitle

                CapacityMirror(
                    yourTier: yourTier,
                    partnerTier: capacityStore.partnerTier,
                    partnerNotCheckedIn: capacityStore.partnerNotCheckedIn,
                    partnerLabel: store.partnerLabel
                )
                .padding(.top, AppSpacing.lg)

                Text("take a moment to arrive · optional")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, AppSpacing.md)

                RitualPills(selected: $selectedRitual)
                    .padding(.top, AppSpacing.xs)

                ritualOrRing
                    .padding(.top, AppSpacing.xl)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.xxl)
            .padding(.bottom, AppSpacing.xl)
        }
        .onAppear {
            if airlock == nil { store.armPresence() }   // DEBUG local mock only
        }
        .task {
            await capacityStore.load()
        }
        .vaylSheet(isPresented: $showHowItWorks, heightFraction: 0.4) {
            howItWorksSheet
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { vaylDismiss() } label: {
                Image(systemName: AppIcons.chevronLeft)
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

    private var eyebrowTitle: some View {
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
        }
    }

    // MARK: - Ritual / Ring

    @ViewBuilder
    private var ritualOrRing: some View {
        switch selectedRitual {
        case .breathe:
            BreathGuide { selectedRitual = nil }
                .frame(maxWidth: .infinity)
                .transition(.opacity)

        case .goodThing:
            goodThingPrompt
                .transition(.opacity)

        case nil:
            lockInRing
                .transition(.opacity)
        }
    }

    private var goodThingPrompt: some View {
        VStack(spacing: AppSpacing.lg) {
            Text("✦")
                .font(AppFonts.displayHero)
                .foregroundStyle(AppColors.spectrumText)
            Text("One thing you're grateful for about them, right now.")
                .font(AppFonts.prompt)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            Text("Say it out loud. Take turns. No rush.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
            VaylButton(label: "we're ready", size: .compact) {
                selectedRitual = nil
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppSpacing.lg)
    }

    /// The production gesture is the two-person sync round (airlock.sync).
    /// HoldToLockInRing remains the explicit fallback: DEBUG local path
    /// (airlock == nil) and poll mode (sync == nil — no channel, no broadcasts).
    @ViewBuilder
    private var lockInRing: some View {
        if let airlock, let sync = airlock.sync {
            syncLockIn(sync: sync, airlock: airlock)
        } else {
            holdToLockIn
        }
    }

    // MARK: Sync lock-in (two-person round)

    private func syncLockIn(sync: SyncLockInCoordinator, airlock: AirlockStore) -> some View {
        VStack(spacing: AppSpacing.md) {
            SyncLockInRing(
                config: sync.config,
                phase: sync.phase,
                ringSize: 224,
                onArm: {
                    // Arming is only meaningful when the partner is here.
                    guard airlock.partnerPresent else { return }
                    sync.arm()
                },
                onRelease: { sync.release(fraction: $0) },
                onDisarm: { sync.disarm() }
            )
            .padding(.top, AppSpacing.md)

            if !airlock.partnerPresent {
                Text("Waiting for \(store.partnerLabel) to arrive…")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            presenceRow

            // The ultimate backstop — the gesture is never a wall. Shown on the
            // local miss grind OR asymmetric consent (partner already in). Each
            // device that taps consents itself; both consented + present → the
            // existing server-authoritative flip.
            if airlock.syncBackstopAvailable {
                Button {
                    Task { _ = await airlock.consent() }
                } label: {
                    Text("enter together anyway")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .underline()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Enter together anyway")
                .accessibilityHint("Skips the synchronized release and marks you ready to begin.")
                .padding(.top, AppSpacing.xs)
            }

            howItWorksButton
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Hold-to-lock-in (fallback)

    private var holdToLockIn: some View {
        VStack(spacing: AppSpacing.md) {
            HoldToLockInRing(locked: lockedIn, ringSize: 224, showsGlyph: false) {
                lockedIn = true
                consentFailed = false
                if let airlock {
                    Task { @MainActor in
                        // Un-latch on a failed commit so the ring drains and the
                        // user can hold again — never a full ring that never wrote.
                        if await !airlock.consent() {
                            lockedIn = false
                            consentFailed = true
                        }
                    }
                } else {
                    store.confirmSynced()   // DEBUG local path, mock unchanged
                }
            }
            .padding(.top, AppSpacing.md)

            VStack(spacing: AppSpacing.xxs) {
                Text(ringPrimaryLine)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                if !ringSecondaryLine.isEmpty {
                    Text(ringSecondaryLine)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            presenceRow

            howItWorksButton
        }
        .frame(maxWidth: .infinity)
    }

    private var howItWorksButton: some View {
        Button {
            showHowItWorks = true
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Text("how it works")
                Text("i")
                    .font(AppFonts.body(9, weight: .semibold, relativeTo: .caption2).italic())
                    .frame(width: 15, height: 15)
                    .overlay(Circle().strokeBorder(AppColors.textAccent, lineWidth: 1))
            }
            .font(AppFonts.caption)
            .foregroundStyle(AppColors.textAccent)
        }
        .buttonStyle(.plain)
        .padding(.top, AppSpacing.xs)
    }

    /// "You" reads ready once THIS device's commit landed: the hold path
    /// latches lockedIn; the sync path writes consent on a passed round.
    private var selfReady: Bool {
        if airlock?.sync != nil { return airlock?.selfConsented ?? false }
        return lockedIn
    }

    private var presenceRow: some View {
        HStack(spacing: AppSpacing.md) {
            presenceChip("You", ready: selfReady, you: true)
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
        return selfReady ? "waiting for \(store.partnerLabel)…" : ""
    }

    /// Real presence, distinct from consent — has the partner arrived at all.
    private var partnerHere: Bool { airlock?.partnerPresent ?? store.partnerPresent }
    private var partnerConsented: Bool { airlock?.partnerConsented ?? false }

    /// Terse primary line under the ring — mirrors the mockup's tiered copy
    /// (a short state message), rewritten honestly for the real mechanism:
    /// each partner independently holds, readiness crosses via consent.
    private var ringPrimaryLine: String {
        if consentFailed { return "That didn't reach the room. Hold again." }
        if partnerConsented && lockedIn { return "You're both in — here we go →" }
        if lockedIn { return "You're locked in." }
        if !partnerHere { return "Waiting for \(store.partnerLabel) to arrive…" }
        return "Press and hold your ring."
    }

    private var ringSecondaryLine: String {
        if partnerConsented && lockedIn { return "" }
        if lockedIn { return "Waiting for \(store.partnerLabel)…" }
        if !partnerHere { return "" }
        return "\(store.partnerLabel) holds theirs, on their phone."
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

    // MARK: - How it works

    private var howItWorksSheet: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("How it works")
                .font(AppFonts.sectionHeading)
                .foregroundStyle(AppColors.textPrimary)
            Text("Two phones, each holding their own ring.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)

            HStack(spacing: AppSpacing.xl) {
                MiniLockDemo(label: "you")
                Text("↔").font(AppFonts.body(20, relativeTo: .title3)).foregroundStyle(AppColors.textMuted)
                MiniLockDemo(label: store.partnerLabel.lowercased())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)

            Text("Press and hold together. When the count ends, let go at the **same moment**. Land close enough together and the deck opens.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.bottom, AppSpacing.md)

            Divider().overlay(AppColors.borderSubtle)

            Text("why it's here")
                .font(AppFonts.overline)
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textSectionLabel)

            Text("A session works best when you both actually arrive, present and choosing it on purpose. This can't be done alone, so it proves you're both here and ready before a single card turns.")
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
        }
        .padding(AppSpacing.lg)
    }
}

/// A small ambient demo ring for the "how it works" sheet — loops filling on
/// its own (not tied to real state) to show the shape of the gesture. Gated
/// on Reduce Motion / Low Power like every ambient loop in the app.
private struct MiniLockDemo: View {
    let label: String

    @State private var fill: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var spectrumArc: AngularGradient {
        AngularGradient(
            colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
            center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)
        )
    }

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            ZStack {
                Circle().stroke(AppColors.borderSubtle, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: fill)
                    .stroke(spectrumArc, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 64, height: 64)
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
        .onAppear {
            guard !reduceMotion, !AppAnimation.lowPower else { fill = 0.7; return }
            withAnimation(.easeInOut(duration: AppAnimation.ambientPulse).repeatForever(autoreverses: true)) {
                fill = 1
            }
        }
    }
}

// MARK: - Preview

#Preview("Airlock — local stub") {
    ZStack {
        OnboardingAtmosphere(config: .stat)
        AirlockView(store: CoupleSessionStore(
            hand: Array(Card.samples.prefix(8)),
            modelContainer: .previewContainer,
            appState: AppState()
        ), airlock: nil)
    }
    .environment(PulseStore())
    .preferredColorScheme(.dark)
}
