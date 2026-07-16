//
//  AirlockView.swift
//  Vayl
//
//  The airlock — the "Let's Lock In" screen: a quick two-person capacity glance
//  that yields to the lock-in ring as the focal action. The centering rituals
//  (breathe / one good thing) were pulled out (2026-07-11) — the stabilizers now
//  live in the in-session pause, where a couple actually needs to reset, rather
//  than as friction before the deck opens. The house rules stay out too.
//
//  The lock-in is the two-person SYNC round (spec 2026-07-08): both partners
//  press-and-hold to arm, a shared 3-2-1 fires, both rings sweep blind, and both
//  must let go within tolerance of each other. Driven by airlock.sync
//  (SyncLockInCoordinator) over the realtime channel.
//
//  ONE ring for every path (2026-07-12): SyncLockInRing. When there's no live
//  partner on the channel — the DEBUG-local path (airlock == nil) or a genuine
//  channel-down / poll session (airlock.sync == nil) — a SOLO coordinator drives
//  the same ring against a phantom partner (a valid press-hold-release passes).
//  HoldToLockInRing was retired.
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var capacityStore = CoupleCapacityStore()
    @State private var showHowItWorks = false
    /// Solo coordinator for the no-live-partner paths (DEBUG-local / channel-down);
    /// nil when the real `airlock.sync` drives the ring.
    @State private var soloSync: SyncLockInCoordinator?

    /// The entrance choreography: a two-person capacity glance (`.glance`) that
    /// yields to the focal lock-in ring (`.focal`). `chromeRevealed` fades the
    /// ring's copy/presence in a beat after the ring lands. Under Reduce Motion /
    /// Low Power the screen mounts straight to `.focal` with chrome shown.
    private enum EntrancePhase { case glance, focal }
    @State private var phase: EntrancePhase = .glance
    /// The glance clears first: the orbs collapse into the ring centre when this
    /// flips, and airlockGlanceLead later the ring rises to fill the vacated space.
    @State private var glanceCollapsing = false
    @State private var chromeRevealed = false
    @State private var showGlance = true
    @State private var entranceTask: Task<Void, Never>?

    private var yourTier: PulseCapacityColor {
        pulseStore.currentPosition.quadrant.capacityColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            titleView

            Spacer(minLength: AppSpacing.md)

            // The convergence: the glance sits above the ring during `.glance`.
            // At the hold mark the glance CLEARS FIRST (shrink + fade into the ring
            // centre), then the ring rises + grows to focal to fill the vacated space.
            // FEEL-GATE (tune on device): the glance offset (-140), the ring's
            // latent offset (75) / scale (0.60) / opacity (0.55), and the title
            // recede (opacity 0.8). Timings live in AppAnimation.airlock*.
            ZStack {
                if let sync = activeSync {
                    SyncLockInSection(
                        sync: sync,
                        isFocal: phase == .focal,
                        chromeRevealed: chromeRevealed,
                        partnerLabel: store.partnerLabel,
                        showWaiting: showWaiting,
                        onArm: { armIfAllowed(sync) },
                        onRelease: { sync.release(fraction: $0) },
                        onDisarm: { sync.disarm() },
                        onBackstop: { Task { _ = await commitConsent() } },
                        onHowItWorks: { showHowItWorks = true }
                    )
                    .scaleEffect(phase == .focal ? 0.95 : 0.60)   // FEEL-GATE: ~1.58× grow (ref)
                    .offset(y: phase == .focal ? 0 : 75)          // FEEL-GATE: rise (ref translateY 75→0)
                    .opacity(phase == .focal ? 1.0 : 0.55)        // FEEL-GATE: latent opacity (ref 0.55)
                    .allowsHitTesting(phase == .focal)
                    .animation(AppAnimation.airlockConverge.reduceMotionSafe, value: phase)
                }

                // The glance holds, then clears FIRST — the orbs collapse INTO the
                // ring centre (down to a point, fading) as the two of you become the
                // Us, and the ring rises to fill behind them. Driven by
                // glanceCollapsing, which flips airlockGlanceLead BEFORE the ring
                // goes focal. Dropped once faded (showGlance).
                if showGlance {
                    CapacityGlance(
                        yourTier: yourTier,
                        partnerTier: capacityStore.partnerTier,
                        partnerNotCheckedIn: capacityStore.partnerNotCheckedIn,
                        partnerLabel: store.partnerLabel
                    )
                    .scaleEffect(glanceCollapsing ? 0.08 : 1.0)   // FEEL-GATE: collapse to a point
                    .offset(y: glanceCollapsing ? 0 : -140)       // FEEL-GATE: top → ring centre
                    .opacity(glanceCollapsing ? 0 : 1.0)
                    .allowsHitTesting(false)
                    .animation(AppAnimation.airlockGlanceOut.reduceMotionSafe, value: glanceCollapsing)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: AppSpacing.md)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.xxl)
        .padding(.bottom, AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(atmosphere)
        .onAppear {
            if airlock == nil { store.armPresence() }   // DEBUG local mock only
            if airlock?.sync == nil, soloSync == nil {
                soloSync = makeSoloSync()   // no live partner → solo-drive the ring
            }
            startEntrance()
        }
        .onDisappear { entranceTask?.cancel() }
        .task {
            await capacityStore.load()
        }
        .vaylSheet(isPresented: $showHowItWorks, heightFraction: 0.4) {
            howItWorksSheet
        }
    }

    /// Drives the entrance. Reduce Motion skips the whole glance choreography and
    /// mounts straight to the focal ring with chrome shown. The entrance is a
    /// one-shot (not an ambient loop), so it is NOT Low-Power-gated — it plays
    /// under LPM; only the aura/glow loops inside it are LPM-gated, internally.
    private func startEntrance() {
        guard !reduceMotion else {
            phase = .focal
            glanceCollapsing = true
            chromeRevealed = true
            showGlance = false
            return
        }
        entranceTask = Task { @MainActor in
            // 1. Glance holds, then CLEARS FIRST — the orbs fly into the ring centre.
            try? await Task.sleep(for: .seconds(AppAnimation.airlockGlanceHold))
            guard !Task.isCancelled else { return }
            withAnimation(AppAnimation.airlockGlanceOut) { glanceCollapsing = true }

            // 2. A beat later (RISE_LAG) the ring rises + grows to fill the space.
            try? await Task.sleep(for: .seconds(AppAnimation.airlockGlanceLead))
            guard !Task.isCancelled else { return }
            withAnimation(AppAnimation.airlockConverge) { phase = .focal }

            // 3. A beat after the glance clears, the copy fades in.
            try? await Task.sleep(for: .seconds(AppAnimation.airlockChromeDelay))
            guard !Task.isCancelled else { return }
            withAnimation(AppAnimation.airlockChromeReveal) { chromeRevealed = true }
            showGlance = false   // glance has long since collapsed; drop it from the tree
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

    /// Soft spectrum atmosphere behind the content, echoing the design reference:
    /// a cyan/purple wash in the upper-left, a magenta wash lower-right. Adds depth
    /// to the void without competing with the ring. Static (no loop) — decorative.
    private var atmosphere: some View {
        ZStack {
            RadialGradient(
                colors: [AppColors.spectrumPurple.opacity(0.10), .clear],
                center: .topLeading, startRadius: 0, endRadius: 300)
            RadialGradient(
                colors: [AppColors.spectrumMagenta.opacity(0.07), .clear],
                center: .bottomTrailing, startRadius: 0, endRadius: 300)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    /// Full-size throughout; only steps back in emphasis (dim) once the ring is
    /// focal, so it stays a readable header rather than shrinking away.
    private var titleView: some View {
        Text("Let's Lock In.")
            .font(AppFonts.lockInTitle)
            .foregroundStyle(AppColors.textPrimary)
            .minimumScaleFactor(0.8)
            .lineLimit(2)
            .opacity(phase == .focal ? 0.8 : 1.0)
            .animation(AppAnimation.airlockTitleRecede.reduceMotionSafe, value: phase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, AppSpacing.lg)
    }

    // MARK: - Ring

    /// One ring for every path (2026-07-12): the two-person `SyncLockInRing`. When
    /// no live partner is on the channel — the DEBUG-local path (airlock == nil) or
    /// a genuine channel-down / poll session (airlock.sync == nil) — a solo
    /// `SyncLockInCoordinator` drives it against a phantom partner, so a valid
    /// press-hold-release passes. `HoldToLockInRing` was retired.
    private var activeSync: SyncLockInCoordinator? { airlock?.sync ?? soloSync }

    /// True only on the live two-device path while the partner has not yet
    /// arrived on the channel. The solo / DEBUG-local path never waits.
    private var showWaiting: Bool {
        guard let airlock, airlock.sync != nil else { return false }
        return !airlock.partnerPresent
    }

    /// The two-device path arms only when the partner is here; the solo bypass
    /// (no live partner) has no one to wait on.
    private func armIfAllowed(_ sync: SyncLockInCoordinator) {
        if let airlock, airlock.sync != nil {
            guard airlock.partnerPresent else { return }
        }
        sync.arm()
    }

    /// The commit for a passed round / backstop: the real path writes server
    /// consent; the solo / DEBUG-local path flips the local session.
    private func commitConsent() async -> Bool {
        if let airlock { return await airlock.consent() }
        store.confirmSynced()
        return true
    }

    /// The solo coordinator that drives the ring when there's no live partner
    /// (DEBUG-local or channel-down). The phantom partner mirrors this device, so
    /// a valid release passes. Built once, on appear, when `airlock.sync == nil`.
    private func makeSoloSync() -> SyncLockInCoordinator {
        let store = self.store
        let airlock = self.airlock
        return SyncLockInCoordinator(
            role: .a,
            solo: true,
            send: { _ in },
            requestConsent: {
                if let airlock { return await airlock.consent() }
                store.confirmSynced()
                return true
            },
            isSessionActive: { store.phase != .airlock }
        )
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

// MARK: - Sync lock-in section

/// The focal ring block: the two-person `SyncLockInRing` (with its resting
/// `LockInRingBloom` behind it) plus the chrome that fades in below once the ring
/// lands focal. Extracted into a concrete `View` (rather than an inline
/// `@ViewBuilder` helper on `AirlockView`) so Xcode Previews' `DebugReplaceableView`
/// instrumentation has a stable typed unit — nested conditional `@ViewBuilder`
/// helpers with optional children were crashing the preview graph. Dumb about
/// networking: the parent bakes the arm guard / consent into the closures.
private struct SyncLockInSection: View {

    let sync: SyncLockInCoordinator
    let isFocal: Bool
    let chromeRevealed: Bool
    let partnerLabel: String
    let showWaiting: Bool
    let onArm: () -> Void
    let onRelease: (Double) -> Void
    let onDisarm: () -> Void
    let onBackstop: () -> Void
    let onHowItWorks: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            SyncLockInRing(
                config: sync.config,
                phase: sync.phase,
                ringSize: AppLayout.lockInRingSize,
                onArm: onArm,
                onRelease: onRelease,
                onDisarm: onDisarm
            )
            // The vivid resting ring lives behind the functional ring, aligned to
            // its top (SyncLockInRing's own caption sits below the ring in its VStack).
            .background(alignment: .top) {
                LockInRingBloom(bloomed: isFocal, ringSize: AppLayout.lockInRingSize)
            }
            .padding(.top, AppSpacing.md)

            chrome
                .opacity(chromeRevealed ? 1 : 0)
                .animation(AppAnimation.airlockChromeReveal.reduceMotionSafe, value: chromeRevealed)
        }
        .frame(maxWidth: .infinity)
    }

    /// Copy + backstop + how-it-works. Fades in a beat after the ring lands focal.
    private var chrome: some View {
        VStack(spacing: AppSpacing.md) {
            // Persistent partner sub-line (the mock's "Alex holds theirs, on their
            // phone."): the two-device framing, always present under the ring copy.
            Text("\(partnerLabel) holds theirs, on their phone.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            if showWaiting {
                Text("Waiting for \(partnerLabel) to arrive…")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // The ultimate backstop — the gesture is never a wall. Shown after the
            // miss grind; each device that taps consents itself.
            if sync.backstopAvailable {
                Button(action: onBackstop) {
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

            Button(action: onHowItWorks) {
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
            .accessibilityLabel("How it works")
            .accessibilityHint("Explains the two-phone lock-in.")
        }
    }
}

// MARK: - Capacity glance

/// The two-person capacity glance at the top of the airlock entrance: each
/// partner's live Pulse aura side by side, a quick "where you're each at" read
/// before the ring takes over. Both partners are present at this screen (the
/// bothPresent gate upstream), so both tiers resolve; the partner shows
/// "not checked in" only if they skipped Pulse. Uses the real PulseAura, not a
/// flat dot, so it reads as the same orb as the rest of the app.
private struct CapacityGlance: View {

    let yourTier: PulseCapacityColor
    let partnerTier: PulseCapacityColor?
    let partnerNotCheckedIn: Bool
    let partnerLabel: String

    private let orbSize: CGFloat = 60

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.xl) {
            cell(name: "You", tier: yourTier, notCheckedIn: false)
            connector
            cell(name: partnerLabel, tier: partnerTier, notCheckedIn: partnerNotCheckedIn)
        }
    }

    /// The comparison thread between the two orbs, aligned to their centre.
    private var connector: some View {
        Capsule()
            .fill(LinearGradient(
                colors: [AppColors.spectrumCyan, AppColors.spectrumPurple],
                startPoint: .leading, endPoint: .trailing))
            .frame(width: AppSpacing.lg, height: 1.5)
            .opacity(0.45)
            .padding(.top, orbSize / 2)
    }

    @ViewBuilder
    private func cell(name: String, tier: PulseCapacityColor?, notCheckedIn: Bool) -> some View {
        VStack(spacing: AppSpacing.sm) {
            Group {
                if let tier {
                    PulseAura(ramp: AuraColors(tier), size: orbSize)
                } else {
                    Circle()
                        .strokeBorder(AppColors.borderDefault,
                                      style: StrokeStyle(lineWidth: 1.4, dash: [3, 3]))
                        .frame(width: orbSize, height: orbSize)
                }
            }
            VStack(spacing: 1) {
                Text(name)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Text(notCheckedIn ? "not checked in" : (tier?.label ?? ""))
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(notCheckedIn ? AppColors.textTertiary : AppColors.textPrimary)
            }
        }
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
