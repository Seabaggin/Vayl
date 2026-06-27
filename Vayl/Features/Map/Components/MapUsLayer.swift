//
//  MapUsLayer.swift
//  Vayl
//
//  The Us layer: together stats, the couple crest card, a "where you align" preview
//  (mutual / adjacent revealed matches, with a locked-more row), and the Vault row.
//  All local data; the couple identity is generic in V1 (the partner's display name
//  is async-only, wired in a later pass). Empty state when not yet linked.
//

import SwiftUI

struct MapUsLayer: View {

    let stats: MapStore.UsStats
    let align: [MapStore.AlignItem]
    let lockedAlignCount: Int
    var onOpenVault: () -> Void

    var body: some View {
        if stats.isLinked {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                together
                whereYouAlign
                vaultRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            MapEmptyState(
                icon: "person.2",
                headline: "No partner linked yet",
                message: "Link with your partner and the couple layer fills in here: where you align, your agreements, and the Vault."
            )
            .vaylGlassCard()
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Together (stats + couple card)

    private var together: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            MapSectionHeader(title: "You two")

            HStack(alignment: .top, spacing: AppSpacing.sm) {
                stat(value: stats.tenureStage ?? "Linked", sub: stats.tenureTime ?? "together")
                divider
                stat(value: "\(stats.weeksOnVayl)", sub: stats.weeksOnVayl == 1 ? "week on Vayl" : "weeks on Vayl")
                divider
                stat(value: "\(stats.sessionCount)", sub: stats.sessionCount == 1 ? "session" : "sessions")
            }
            .padding(AppSpacing.md)
            .vaylGlassCard()

            coupleCard
        }
    }

    private func stat(value: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(AppFonts.display(15, weight: .bold, relativeTo: .subheadline))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text(sub)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var divider: some View {
        Rectangle().fill(AppColors.borderSubtle).frame(width: 1, height: 28)
    }

    private var coupleCard: some View {
        HStack(spacing: AppSpacing.md) {
            CoupleCrestPortrait(size: 52)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("YOUR COUPLE")
                    .font(AppFonts.overline).tracking(1.0)
                    .foregroundStyle(AppColors.textTertiary)
                Text("The two of you")
                    .font(AppFonts.display(17, weight: .bold, relativeTo: .title3))
                    .foregroundStyle(AppColors.textPrimary)
                Text("Primary · Linked")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .vaylGlassCard(accent: AppColors.accentTertiary)
    }

    // MARK: - Where you align

    private var whereYouAlign: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            MapSectionHeader(
                title: "Where you align",
                linkLabel: align.isEmpty ? nil : "in the Vault",
                onLink: align.isEmpty ? nil : onOpenVault
            )

            if align.isEmpty {
                MapEmptyState(
                    icon: "diamond",
                    headline: "No matches yet",
                    message: "Complete your Desire Maps and the overlap appears here, only ever the overlap, never the gaps."
                )
                .vaylGlassCard()
            } else {
                let shown = Array(align.prefix(3))
                VStack(spacing: 0) {
                    ForEach(Array(shown.enumerated()), id: \.element.id) { idx, item in
                        alignRow(item)
                        if idx < shown.count - 1 {
                            Rectangle().fill(AppColors.borderSubtle).frame(height: 1)
                        }
                    }
                    if lockedAlignCount > 0 {
                        lockedRow
                    }
                }
                .vaylGlassCard()
            }
        }
    }

    private func alignRow(_ item: MapStore.AlignItem) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "diamond")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppColors.spectrumBridge)
            Text(item.name)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textBody)
            Spacer()
            matchBadge(isMutual: item.isMutual)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 2)
    }

    private func matchBadge(isMutual: Bool) -> some View {
        let tint = isMutual ? AppColors.spectrumCyan : AppColors.spectrumBridge
        return Text(isMutual ? "Mutual" : "Adjacent")
            .font(AppFonts.overline)
            .tracking(0.4)
            .foregroundStyle(tint)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xxs + 1)
            .background(Capsule().fill(tint.opacity(0.12)))
            .overlay(Capsule().strokeBorder(tint.opacity(0.3), lineWidth: 1))
    }

    private var lockedRow: some View {
        Button(action: onOpenVault) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "lock")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppColors.textTertiary)
                Text("\(lockedAlignCount) more where you align")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Text("Unlock the full map")
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.accentPrimary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm + 2)
            .overlay(alignment: .top) {
                Rectangle().fill(AppColors.borderSubtle).frame(height: 1)
            }
        }
        .buttonStyle(PressableCardStyle())
    }

    // MARK: - Vault row

    private var vaultRow: some View {
        Button(action: onOpenVault) {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.accentSecondary.opacity(0.40), AppColors.accentTertiary.opacity(0.30)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    Image(systemName: "lock")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("The Vault")
                        .font(AppFonts.display(15, weight: .bold, relativeTo: .subheadline))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Desire Map · agreements · opened by consent")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(AppSpacing.md)
            .vaylGlassCard(accent: AppColors.accentSecondary)
        }
        .buttonStyle(PressableCardStyle())
    }
}
