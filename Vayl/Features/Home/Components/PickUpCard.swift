// Home/Components/PickUpCard.swift

import SwiftUI

struct PickUpCard: View {
    let items:      [PickUpItem]
    var onItemTap:  ((PickUpItem) -> Void)? = nil
    var onSeeAll:   (() -> Void)?           = nil

    @Environment(\.colorScheme) private var colorScheme

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        if items.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(items.prefix(2)) { item in
                    itemCard(item)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onItemTap?(item)
                        }
                }

                if items.count > 2 {
                    Button {
                        onSeeAll?()
                    } label: {
                        Text("See all in-progress →")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.accentTertiary
                                : AppColors.accentPrimary)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, AppSpacing.xs)
                }
            }
        }
    }

    private func itemCard(_ item: PickUpItem) -> some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.sm) {
                    Text(item.contentType.label)
                        .font(AppFonts.overline)
                        .tracking(1.0)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.accentTertiary
                            : AppColors.accentPrimary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background {
                            Capsule()
                                .fill(colorScheme == .light
                                    ? AppColors.accentTertiary.opacity(0.08)
                                    : AppColors.accentPrimary.opacity(0.12))
                        }
                        .overlay {
                            Capsule()
                                .stroke(colorScheme == .light
                                    ? AppColors.accentTertiary.opacity(0.20)
                                    : AppColors.accentPrimary.opacity(0.25),
                                    lineWidth: 1)
                        }

                    Spacer()

                    // Pulsing amber activity dot — 1.2s intentional.
                    // Faster than ambientPulse (2.0s) to signal urgency.
                    Circle()
                        .fill(Color(red: 1, green: 0.72, blue: 0))
                        .frame(width: 7, height: 7)
                        .scaleEffect(pulseScale)
                        .onAppear {
                            withAnimation(
                                .easeInOut(duration: AppAnimation.ambientShimmer)
                                .repeatForever(autoreverses: true)
                            ) {
                                pulseScale = 1.4
                            }
                        }
                }

                Text(item.contextLine)
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.textTertiary
                        : AppColors.textTertiary)

                Text(item.title)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.textSecondary
                        : AppColors.textSecondary)
                    .lineLimit(2)

                Text(item.actionLabel)
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.accentTertiary
                        : AppColors.accentPrimary)
            }
        }
        .padding(AppSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(colorScheme == .light
                    ? AppColors.glassFrostCard
                    : AppColors.cardBackground)
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.borderSubtle, lineWidth: 1)
        }
    }
}

private extension PickUpContentType {
    var label: String {
        switch self {
        case .timelineScenario: return "TIMELINE"
        case .article:          return "ARTICLE"
        case .judgmentCall:     return "JUDGMENT"
        case .autopsy:          return "AUTOPSY"
        }
    }
}
