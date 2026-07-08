//
//  MeCardCompact.swift
//  Vayl
//
//  The title-led Me Card as it sits on the Me layer: flavor-tinted glass surface,
//  lattice portrait, name + chosen Title, flavor chip + essence, and the derived
//  "Drawn to" tags (shared ones glow). Tapping opens the full card + editor sheet.
//  Display-only; MapStore owns the data.
//

import SwiftUI

struct MeCardCompact: View {

    let card: MapStore.MeCard
    var onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("\(card.flavor.label) Type".uppercased())
                    .font(AppFonts.overline)
                    .tracking(1.0)
                    .foregroundStyle(AppColors.textTertiary)
                Spacer()
                Text("Edit")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }

            HStack(spacing: AppSpacing.md) {
                FlavorPortrait(size: 56)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(card.name)
                        .font(AppFonts.display(15, weight: .semibold, relativeTo: .subheadline))
                        .foregroundStyle(AppColors.textSecondary)
                    Text(card.title)
                        .font(AppFonts.display(20, weight: .bold, relativeTo: .title3))
                        .foregroundStyle(titleGradient)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    HStack(spacing: AppSpacing.sm) {
                        FlavorChip(flavor: card.flavor)
                        Text(card.flavor.essence)
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: AppIcons.chevronRight)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
            }

            if !card.tags.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Drawn to".uppercased())
                        .font(AppFonts.overline)
                        .tracking(1.0)
                        .foregroundStyle(AppColors.textTertiary)
                    FlowLayout(spacing: AppSpacing.xs) {
                        ForEach(card.tags) { tag in
                            DrawnTagChip(tag: tag, flavor: card.flavor)
                        }
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .vaylGlassCard(accent: card.flavor.color)
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }
    }

    private var titleGradient: LinearGradient {
        LinearGradient(
            colors: [.white, card.flavor.color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
