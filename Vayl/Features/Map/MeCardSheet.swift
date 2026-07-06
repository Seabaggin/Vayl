//
//  MeCardSheet.swift
//  Vayl
//
//  The full Me Card + editor, presented as a .vaylSheet. Shows the large card,
//  then a Title chooser (the flavor's shortlist) and a Flavor chooser. Selecting
//  either persists via MapStore and re-renders the card. Portrait stays the lattice
//  sigil in V1 (opt-in photo deferred).
//

import SwiftUI

struct MeCardSheet: View {

    let card: MapStore.MeCard
    var onChooseTitle: (String) -> Void
    var onChooseFlavor: (Flavor) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                fullCard
                titleChooser
                flavorChooser
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - The full card

    private var fullCard: some View {
        VStack(spacing: AppSpacing.md) {
            FlavorPortrait(size: 92)

            VStack(spacing: AppSpacing.xxs) {
                Text(card.name)
                    .font(AppFonts.display(18, weight: .semibold, relativeTo: .title3))
                    .foregroundStyle(AppColors.textSecondary)
                Text(card.title)
                    .font(AppFonts.display(26, weight: .bold, relativeTo: .title))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, card.flavor.color],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: AppSpacing.sm) {
                FlavorChip(flavor: card.flavor)
                Text(card.flavor.essence)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            if !card.tags.isEmpty {
                FlowLayout(spacing: AppSpacing.xs) {
                    ForEach(card.tags) { tag in
                        DrawnTagChip(tag: tag, flavor: card.flavor)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity)
        .vaylGlassCard(accent: card.flavor.color, radius: AppRadius.xl)
    }

    // MARK: - Choosers

    private var titleChooser: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Choose your title")
                .font(AppFonts.overline)
                .tracking(1.0)
                .foregroundStyle(AppColors.textTertiary)
            FlowLayout(spacing: AppSpacing.xs) {
                ForEach(card.flavor.titles, id: \.self) { title in
                    choiceChip(label: title, selected: title == card.title, accent: card.flavor.color) {
                        onChooseTitle(title)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var flavorChooser: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Your flavor")
                .font(AppFonts.overline)
                .tracking(1.0)
                .foregroundStyle(AppColors.textTertiary)
            FlowLayout(spacing: AppSpacing.xs) {
                ForEach(Flavor.allCases) { flavor in
                    choiceChip(label: flavor.label, icon: flavor.icon,
                               selected: flavor == card.flavor, accent: flavor.color) {
                        onChooseFlavor(flavor)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func choiceChip(
        label: String,
        icon: String? = nil,
        selected: Bool,
        accent: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: AppSpacing.xs) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 11, weight: .semibold))
                }
                Text(label).font(AppFonts.caption)
            }
            .foregroundStyle(selected ? .white : AppColors.textSecondary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs + 1)
            .background(Capsule().fill(selected ? accent.opacity(0.20) : AppColors.glassSurface))
            .overlay(
                Capsule().strokeBorder(
                    selected ? accent.opacity(0.55) : AppColors.borderSubtle,
                    lineWidth: 1
                )
            )
        }
        .buttonStyle(PressableCardStyle())
    }
}
