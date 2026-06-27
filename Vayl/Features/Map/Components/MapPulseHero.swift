//
//  MapPulseHero.swift
//  Vayl
//
//  The Map's Pulse hero (Me layer). The full instrument, open on the atmosphere
//  with no card around it (the Pulse is light, not an object — same stance as
//  Home's rail), but distinct from Home's glance: it leads with the current Space
//  and a check-in pill, and taps through to the full history. Reuses PulseGraph for
//  the arc and the PulseTier tokens for the state. Under 7 check-ins it reads as
//  "your Pulse is forming" over the developing graph.
//
//  Data is read from the shared PulseStore (device cache); the screen (MapView)
//  owns the check-in cover + history sheet and passes the callbacks in.
//

import SwiftUI

struct MapPulseHero: View {

    @Environment(PulseStore.self) private var pulse

    var onCheckIn: () -> Void
    var onOpenHistory: () -> Void

    private var entries: [PulseEntry] { pulse.entries }
    private var recent: [PulseEntry] { Array(entries.suffix(7)) }
    private var isForming: Bool { entries.count < 7 }
    private var currentTier: PulseTier? { entries.last?.tier }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            header

            graph
                .contentShape(Rectangle())
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onOpenHistory()
                }

            if isForming {
                Text(formingHint)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Header (eyebrow + current Space + check-in pill)

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("The Pulse")
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.textTertiary)

                if let tier = currentTier {
                    LivingText(
                        text: tier.label,
                        font: AppFonts.display(26, weight: .bold, relativeTo: .title),
                        animated: false
                    )
                    Text(tier.sublabel)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                } else {
                    Text("Your Pulse is forming")
                        .font(AppFonts.display(22, weight: .semibold, relativeTo: .title2))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Comes alive at 7 days of check-ins")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            checkInPill
        }
    }

    private var checkInPill: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onCheckIn()
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                Text("Check in")
                    .font(AppFonts.buttonLabelSmall)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs + 2)
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: [AppColors.accentSecondary, AppColors.accentTertiary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            )
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityLabel("Check in")
    }

    // MARK: - Graph (the reused instrument; handles its own empty/building/settled states)

    private var graph: some View {
        GeometryReader { geo in
            PulseGraph(
                entries: recent,
                graphWidth: geo.size.width,
                graphHeight: geo.size.height,
                disableTouchGlow: true
            )
        }
        .frame(height: 150)
    }

    private var formingHint: String {
        let n = min(entries.count, 7)
        return "Check in daily and your spaces fill in. Day \(n) of 7."
    }
}

// MARK: - Preview

#Preview("Map Pulse hero") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        MapPulseHero(onCheckIn: {}, onOpenHistory: {})
            .padding(AppSpacing.lg)
    }
    .environment(PulseStore())
    .preferredColorScheme(.dark)
}
