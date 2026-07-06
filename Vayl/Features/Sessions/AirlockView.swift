//
//  AirlockView.swift
//  Vayl
//
//  The airlock — ONE merged "Before we start" screen (not two steps): rules
//  (first-timers only), a pure capacity mirror, an optional centering ritual,
//  and the lock-in ring. The ring's mechanism is the REAL production one —
//  each partner independently holds their own ring; readiness crosses devices
//  via AirlockStore.partnerConsented. There is no shared release-timing match
//  (that would need a realtime channel this app doesn't have yet); the copy
//  below is honest to what actually happens.
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
    @State private var waitingPulse = false
    @State private var selectedRitual: Ritual? = nil
    @State private var capacityStore = CoupleCapacityStore(service: SupabaseCoupleCapacityService())
    @State private var showHowItWorks = false

    /// Repeat couples get the one-liner, not the six bullets (spec 4.5).
    /// Store-owned: the view no longer reads persistence to make a flow decision.
    private var isRepeatSession: Bool { store.isRepeatSession }

    private var yourTier: PulseCapacityColor {
        pulseStore.currentPosition.quadrant.capacityColor
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                eyebrowTitle

                rules

                CapacityMirror(
                    yourTier: yourTier,
                    partnerTier: capacityStore.partnerTier,
                    partnerNotCheckedIn: capacityStore.partnerNotCheckedIn,
                    partnerLabel: store.partnerLabel
                )
                .padding(.top, AppSpacing.lg)

                RitualPills(selected: $selectedRitual)
                    .padding(.top, AppSpacing.md)

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

    // MARK: - Rules

    @ViewBuilder
    private var rules: some View {
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

    private var lockInRing: some View {
        VStack(spacing: AppSpacing.md) {
            HoldToLockInRing(locked: lockedIn, ringSize: 224, showsGlyph: false) {
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
            .padding(.top, AppSpacing.md)

            VStack(spacing: AppSpacing.xxs) {
                Text(lockedIn ? "you're locked in" : "Hold to lock in.")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                if !lockedIn {
                    Text("\(store.partnerLabel) locks in on their phone too — you'll both need to be ready.")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            presenceRow

            Button {
                showHowItWorks = true
            } label: {
                Text("how it works")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textAccent)
            }
            .buttonStyle(.plain)
            .padding(.top, AppSpacing.xs)
        }
        .frame(maxWidth: .infinity)
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

    // MARK: - How it works

    private var howItWorksSheet: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("How it works")
                .font(AppFonts.sectionHeading)
                .foregroundStyle(AppColors.textPrimary)

            Text("Hold your ring. \(store.partnerLabel) holds theirs, on their own phone. Once you're both locked in, the deck opens.")
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)

            Text("This is what proves you've both arrived, present and ready, before a single card turns.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(AppSpacing.lg)
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
    .environment(PulseStore())
    .preferredColorScheme(.dark)
}
