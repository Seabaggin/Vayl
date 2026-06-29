// Features/Home/Components/HomePulseRail.swift
//
// Module 2 of the Home dashboard — the compact Pulse aura widget.
//
// Dormant (no today check-in): dim dashed orb + "How's your capacity?" invite.
// Active (today check-in exists): live PulseAura + Space name + sublabel + "Xh ago".
//
// No streak. No badge. No calendar gap. The orb IS the language.
//
// Visual reference: docs/prototypes/home-pulse-aura.html — dormant + active panels.

import SwiftUI

struct HomePulseRail: View {

    var onTap:          (() -> Void)? = nil
    var onCheckIn:      (() -> Void)? = nil
    var onInfo:         (() -> Void)? = nil
    // Kept for call-site compat; unused now that the aura widget is fixed-height.
    var expansion:      Double        = 1
    var maxGraphHeight: CGFloat       = 160

    @Environment(PulseStore.self) private var pulse
    @State private var breathe: Bool = false

    // MARK: - Body

    var body: some View {
        Group {
            if let entry = todayEntry {
                activeRow(entry: entry)
            } else {
                dormantRow
            }
        }
        .background(AppColors.glassSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
                .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
        )
        .onAppear { breathe = true }
    }

    // MARK: - Active row

    private func activeRow(entry: PulseEntry) -> some View {
        let quadrant = entry.resolvedPosition.quadrant
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap?()
        } label: {
            HStack(spacing: AppSpacing.sm) {
                PulseAura(quadrant: quadrant, size: 42)
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 2) {
                    Text("The Pulse")
                        .font(AppFonts.overline)
                        .foregroundStyle(AppColors.textTertiary)
                    Text(quadrant.spaceName)
                        .font(AppFonts.cardTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                    Text(quadrant.sublabel)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 3) {
                    Text("›")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppColors.textTertiary)
                    Text(relativeTime(entry.date))
                        .font(.system(size: 8.5, weight: .regular))
                        .foregroundStyle(AppColors.textTertiary)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Dormant row

    private var dormantRow: some View {
        HStack(spacing: AppSpacing.sm) {
            // Dashed, dim orb — breathes like an inactive shell.
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppColors.textTertiary.opacity(0.07), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 20
                        )
                    )
                Circle()
                    .strokeBorder(
                        AppColors.borderSubtle.opacity(0.55),
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                    )
            }
            .scaleEffect(breathe ? 1.06 : 0.94)
            .opacity(breathe ? 1.0 : 0.82)
            .ambientAnimation(AppAnimation.cardBreathe, value: breathe)
            .frame(width: 40, height: 40)
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 2) {
                Text("The Pulse")
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.textTertiary.opacity(0.7))
                Text("How's your capacity?")
                    .font(AppFonts.cardTitle)
                    .foregroundStyle(AppColors.textMuted)
                    .lineLimit(1)
                Text("A quick check-in")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onCheckIn?()
            } label: {
                Text("Check in")
                    .font(AppFonts.buttonLabelSmall)
                    .foregroundStyle(AppColors.spectrumCyan)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xxs)
                    .overlay(
                        Capsule()
                            .strokeBorder(AppColors.spectrumCyan.opacity(0.45), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - Helpers

    private var todayEntry: PulseEntry? {
        pulse.entries.last(where: { Calendar.current.isDateInToday($0.date) })
    }

    private func relativeTime(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60    { return "just now" }
        if seconds < 3600  { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "yesterday"
    }
}

// MARK: - PulseInfoSheet

struct PulseInfoSheet: View {
    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            Text("About the Pulse")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textMuted)
        }
    }
}

// MARK: - Preview

#Preview("Dormant") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        HomePulseRail(onCheckIn: {})
            .padding(AppSpacing.lg)
    }
    .environment(PulseStore())
    .preferredColorScheme(.dark)
}

#Preview("Active — Expansive") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        HomePulseRail(onTap: {})
            .padding(AppSpacing.lg)
    }
    .environment({
        let s = PulseStore()
        s.add(PulseEntry(
            date: Date(),
            capacityScore: 4.0,
            glowColor: .cyan,
            speed: "Expansive",
            nervousSystem: "Energized",
            focus: "Reaching Out",
            feeling: "Adventurous",
            position: PulsePosition(energy: 0.82, openness: 0.78)
        ))
        return s
    }())
    .preferredColorScheme(.dark)
}
