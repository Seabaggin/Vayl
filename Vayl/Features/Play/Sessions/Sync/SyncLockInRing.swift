//
//  SyncLockInRing.swift
//  Vayl
//
//  The two-person airlock lock-in gesture (replaces HoldToLockInRing). Both
//  partners press-and-hold to arm; once both are armed a shared 3-2-1 fires and
//  each ring sweeps 0→360° at one rate. It is BLIND — this view renders only THIS
//  device's sweep, no partner ring, no degree readout, no floor/tick marks — so
//  the couple has to feel the moment together and release "at the same instant."
//
//  The view is dumb about networking: the coordinator (Segment 2) drives `phase`
//  and consumes `onArm` / `onRelease(fraction)` / `onDisarm`. `onRelease` carries
//  the elapsed FRACTION of the sweep (0…1+); SyncRound.classify turns it into a
//  release kind, so a fraction ≥ 1.0 is an overshoot.
//
//  Feel values live in SyncConfig (🎚️, confirmed on device). Reduce Motion / Low
//  Power only strips decorative breathing — the functional sweep always plays,
//  since it IS the mechanic.
//

import SwiftUI

/// Caller-driven render state for the ring. The coordinator owns transitions.
enum SyncRingPhase: Equatable {
    case idle                       // nothing armed
    case arming                     // this device armed, waiting for partner
    case countdown(Int)             // shared 3-2-1
    case sweeping(startedAt: Date)  // both rings sweeping from a shared start
    case result(SyncVerdict)        // judged outcome
}

struct SyncLockInRing: View {

    let config: SyncConfig
    let phase: SyncRingPhase
    var ringSize: CGFloat = 224
    let onArm: () -> Void
    let onRelease: (Double) -> Void   // elapsed fraction of the sweep
    let onDisarm: () -> Void          // let go before the sweep started

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var fill: CGFloat = 0
    @State private var pressing = false
    /// Guards against double-firing onRelease (auto-overshoot vs finger lift).
    @State private var didReport = false

    private var scale: CGFloat { ringSize / 224 }

    private var spectrumArc: AngularGradient {
        AngularGradient(
            colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
            center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)
        )
    }

    private var isSuccess: Bool {
        if case .result(.inSync) = phase { return true }
        return false
    }

    /// How full the ring reads for the current phase.
    private var displayFill: CGFloat {
        switch phase {
        case .sweeping: return fill
        case .result(.inSync): return 1
        default: return phase.isPreSweep ? 0 : fill
        }
    }

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            ring
            caption
        }
        .contentShape(Rectangle())
        .gesture(pressHold)
        .onChange(of: phase) { _, new in handlePhaseChange(new) }
        .sensoryFeedback(.impact(weight: .light), trigger: pressing)
        .sensoryFeedback(.success, trigger: isSuccess) { _, now in now }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lock in together")
        .accessibilityHint("You and your partner press and hold, then let go at the same moment.")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Ring

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(AppColors.borderSubtle, lineWidth: 3 * scale)

            // Glow pass ramps with the fill (two-pass house recipe).
            Circle()
                .trim(from: 0, to: displayFill)
                .stroke(spectrumArc, style: StrokeStyle(lineWidth: 8 * scale, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .blur(radius: 6)
                .opacity(0.2 + 0.5 * Double(displayFill))

            // Crisp pass.
            Circle()
                .trim(from: 0, to: displayFill)
                .stroke(spectrumArc, style: StrokeStyle(lineWidth: 3 * scale, lineCap: .round))
                .rotationEffect(.degrees(-90))

            centerContent
        }
        .frame(width: ringSize, height: ringSize)
        .scaleEffect(pressing ? 0.97 : (isSuccess ? 1.04 : 1.0))
        .animation(AppAnimation.spring, value: pressing)
        .animation(AppAnimation.standard, value: isSuccess)
    }

    @ViewBuilder
    private var centerContent: some View {
        switch phase {
        case .countdown(let n):
            Text("\(n)")
                .font(AppFonts.displayHero)
                .foregroundStyle(AppColors.spectrumText)
                .transition(.scale.combined(with: .opacity))
                .id(n)
        case .result(.inSync):
            Text("✦")
                .font(AppFonts.displayHero)
                .foregroundStyle(AppColors.spectrumText)
        default:
            // Blind: no readout during arming/sweeping/miss.
            EmptyView()
        }
    }

    // MARK: - Caption

    private var caption: some View {
        Text(captionText)
            .font(AppFonts.caption)
            .foregroundStyle(captionColor)
            .multilineTextAlignment(.center)
            .frame(maxWidth: ringSize * 1.3)
            .animation(AppAnimation.standard, value: captionText)
    }

    private var captionText: String {
        switch phase {
        case .idle:      return "Press and hold together."
        case .arming:    return "Holding. Waiting for your partner."
        case .countdown: return "Get ready."
        case .sweeping:  return "Let go together."
        case .result(let v): return Self.copy(for: v)
        }
    }

    private var captionColor: Color {
        if case .result(.inSync) = phase { return AppColors.textPrimary }
        return AppColors.textSecondary
    }

    /// Warm, one-person voice, no em dashes. Names what THIS partner can change.
    static func copy(for verdict: SyncVerdict) -> String {
        switch verdict {
        case .inSync:          return "In sync."
        case .soClose:         return "So close. Once more?"
        case .farApart:        return "Take a breath and count it out loud together."
        case .selfTooEarly:    return "Hold a beat longer before you let go."
        case .selfOvershoot:   return "You held past the top. Let go a little sooner."
        case .partnerTooEarly: return "They let go early. Once more, together."
        case .partnerOvershoot: return "They held past the top. Once more, together."
        }
    }

    // MARK: - Gesture

    private var pressHold: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in beginPress() }
            .onEnded { _ in endPress() }
    }

    private func beginPress() {
        guard !pressing else { return }
        pressing = true
        if case .idle = phase { onArm() }
    }

    private func endPress() {
        guard pressing else { return }
        pressing = false
        switch phase {
        case .sweeping(let startedAt):
            guard !didReport else { return }
            didReport = true
            onRelease(elapsedFraction(from: startedAt))
        case .arming, .countdown:
            onDisarm()
        default:
            break
        }
    }

    // MARK: - Sweep clock

    private func handlePhaseChange(_ new: SyncRingPhase) {
        switch new {
        case .sweeping(let startedAt):
            didReport = false
            fill = 0
            runSweep(from: startedAt)
        case .idle, .arming, .countdown:
            withAnimation(AppAnimation.standard) { fill = 0 }
        case .result(.inSync):
            withAnimation(AppAnimation.enter) { fill = 1 }
        case .result:
            // Miss: drain, no penalty.
            withAnimation(AppAnimation.standard) { fill = 0 }
        }
    }

    private func runSweep(from startedAt: Date) {
        Task { @MainActor in
            while case .sweeping = phase, !didReport {
                let f = elapsedFraction(from: startedAt)
                fill = CGFloat(min(1, f))
                if f >= 1 {
                    // Overshoot the instant the ring completes.
                    didReport = true
                    onRelease(1.0)
                    break
                }
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func elapsedFraction(from startedAt: Date) -> Double {
        max(0, Date().timeIntervalSince(startedAt) / config.sweepSeconds)
    }
}

private extension SyncRingPhase {
    /// Phases where the ring should read empty (pre-sweep).
    var isPreSweep: Bool {
        switch self {
        case .idle, .arming, .countdown: return true
        default: return false
        }
    }
}

// MARK: - Debug feel harness

#if DEBUG
private struct SyncLockInRingHarness: View {
    @State private var phase: SyncRingPhase = .idle
    private let config = SyncConfig.standard

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            VStack(spacing: AppSpacing.xl) {
                SyncLockInRing(
                    config: config,
                    phase: phase,
                    onArm: { runRound() },
                    onRelease: { fraction in resolve(fraction) },
                    onDisarm: { phase = .idle }
                )

                // Manual state cycler so each visual state can be felt solo.
                HStack {
                    ForEach(demoVerdicts, id: \.self) { v in
                        Button(Self.short(v)) { phase = .result(v) }
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
        }
    }

    private var demoVerdicts: [SyncVerdict] {
        [.inSync, .soClose(gapDegrees: 24), .farApart(gapDegrees: 120),
         .selfTooEarly, .selfOvershoot, .partnerOvershoot]
    }

    /// Simulate the shared start: countdown then sweep. A fixed simulated partner
    /// angle judges the result so every tier can be felt without a second device.
    private func runRound() {
        Task { @MainActor in
            for n in [3, 2, 1] {
                phase = .countdown(n)
                try? await Task.sleep(for: .seconds(0.6))
            }
            phase = .sweeping(startedAt: Date())
        }
    }

    private func resolve(_ fraction: Double) {
        let round = SyncRound(config: config, misses: 0)
        let mine = round.classify(elapsedFraction: fraction)
        // Simulated partner releases around 210° every round.
        let partner = SyncRelease.valid(angle: 210)
        phase = .result(round.judge(mine: mine, partner: partner))
    }

    static func short(_ v: SyncVerdict) -> String {
        switch v {
        case .inSync: return "sync"
        case .soClose: return "close"
        case .farApart: return "far"
        case .selfTooEarly: return "early"
        case .selfOvershoot: return "over"
        case .partnerTooEarly: return "p-early"
        case .partnerOvershoot: return "p-over"
        }
    }
}

#Preview("Sync lock-in ring") {
    SyncLockInRingHarness()
}
#endif
