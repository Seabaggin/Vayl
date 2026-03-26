// Home/Components/PickUpCard.swift

import SwiftUI

struct PickUpCard: View {
    let items: [PickUpItem]
    var onItemTap: ((PickUpItem) -> Void)? = nil
    var onSeeAll: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        if items.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(items.prefix(2)) { item in
                    itemCard(item)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light)
                                .impactOccurred()
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
                                ? AppColors.magenta
                                : AppColors.cyanLight)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 4)
                }
            }
        }
    }

    private func itemCard(_ item: PickUpItem) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(item.contentType.label)
                        .font(AppFonts.overline)
                        .tracking(1.0)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.magenta
                            : AppColors.cyanLight)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background {
                            Capsule()
                                .fill(colorScheme == .light
                                    ? AppColors.magenta.opacity(0.08)
                                    : AppColors.cyan.opacity(0.12))
                        }
                        .overlay {
                            Capsule()
                                .stroke(colorScheme == .light
                                    ? AppColors.magenta.opacity(0.20)
                                    : AppColors.cyan.opacity(0.25),
                                    lineWidth: 1)
                        }

                    Spacer()

                    // Pulsing amber dot
                    Circle()
                        .fill(Color(red: 1, green: 0.72, blue: 0))
                        .frame(width: 7, height: 7)
                        .scaleEffect(pulseScale)
                        .onAppear {
                            withAnimation(
                                .easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true)
                            ) {
                                pulseScale = 1.4
                            }
                        }
                }

                Text(item.contextLine)
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)

                Text(item.title)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary)
                    .lineLimit(2)

                Text(item.actionLabel)
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.magenta
                        : AppColors.cyanLight)
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .light
                    ? AppColors.lightFrostCard
                    : AppColors.cardBg)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(colorScheme == .light
                    ? AppColors.lightBorder
                    : AppColors.border,
                    lineWidth: 1)
        }
    }
}

private extension PickUpContentType {
    var label: String {
        switch self {
        case .timelineScenario: return "TIMELINE"
        case .article:          return "ARTICLE"
        case .judgmentCall:      return "JUDGMENT"
        case .autopsy:          return "AUTOPSY"
        }
    }
}
