//
//  CapacityMirror.swift
//  Vayl
//
//  A pure mirror of where each partner is tonight — the shared Pulse capacity
//  tier, never the answers. It computes nothing and sets nothing: the couple
//  already picked the cards, so there is no determination for this to make.
//

import SwiftUI

struct CapacityMirror: View {

    let yourTier: PulseCapacityColor
    let partnerTier: PulseCapacityColor?
    let partnerNotCheckedIn: Bool
    let partnerLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("where you're each at")
                .font(AppFonts.overline)
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textSectionLabel)
                .padding(.bottom, AppSpacing.sm)

            HStack(spacing: AppSpacing.md) {
                tierItem(name: "You", tier: yourTier, notCheckedIn: false)
                connector
                tierItem(name: partnerLabel, tier: partnerTier, notCheckedIn: partnerNotCheckedIn)
            }
        }
        .padding(AppSpacing.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
        )
    }

    private var connector: some View {
        Capsule()
            .fill(AppColors.accentPrimary)
            .frame(width: AppSpacing.xl, height: 2)
            .opacity(0.6)
    }

    @ViewBuilder
    private func tierItem(name: String, tier: PulseCapacityColor?, notCheckedIn: Bool) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Group {
                if let tier {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [tier.auraLight, tier.auraCore, tier.auraDeep],
                                center: .center, startRadius: 0, endRadius: 10
                            )
                        )
                        .shadow(color: tier.auraGlow, radius: 6)
                } else {
                    Circle()
                        .strokeBorder(AppColors.borderDefault, style: StrokeStyle(lineWidth: 1.4, dash: [3, 3]))
                }
            }
            .frame(width: 16, height: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Text(notCheckedIn ? "not checked in" : (tier?.label ?? ""))
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(notCheckedIn ? AppColors.textTertiary : AppColors.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview("Capacity Mirror") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VStack(spacing: AppSpacing.lg) {
            CapacityMirror(yourTier: .cyan, partnerTier: .magenta, partnerNotCheckedIn: false, partnerLabel: "Alex")
            CapacityMirror(yourTier: .indigo, partnerTier: nil, partnerNotCheckedIn: true, partnerLabel: "Alex")
        }
        .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
