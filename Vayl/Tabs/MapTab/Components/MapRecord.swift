//
//  MapRecord.swift
//  Vayl
//
//  The Record (Me layer): a slim category-distribution bar over the recent-sessions
//  list, both derived from the couple's CardSession history (resolved to deck titles
//  + categories via the deck catalog). Empty state when there are no sessions yet.
//  Display-only; MapStore owns the data.
//

import SwiftUI

struct MapRecord: View {

    let sessions: [MapStore.RecordSession]
    let shares: [MapStore.CategoryShare]

    private var totalCount: Int { shares.reduce(0) { $0 + $1.count } }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            MapSectionHeader(title: "The Record")

            if sessions.isEmpty {
                MapEmptyState(
                    icon: "rectangle.stack",
                    headline: "No sessions yet",
                    message: "When you play a deck together, it lands here, and the Map begins to learn the shape of your conversations."
                )
                .vaylGlassCard()
            } else {
                let shown = Array(sessions.prefix(5))
                VStack(spacing: 0) {
                    distribution
                    ForEach(Array(shown.enumerated()), id: \.element.id) { idx, session in
                        row(session)
                        if idx < shown.count - 1 {
                            Rectangle()
                                .fill(AppColors.borderSubtle)
                                .frame(height: 1)
                        }
                    }
                }
                .vaylGlassCard()
            }
        }
    }

    // MARK: - Distribution bar

    private var distribution: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(shares) { share in
                        share.category.mapColor
                            .frame(width: max(2, geo.size.width * fraction(share.count)))
                    }
                }
            }
            .frame(height: 7)
            .clipShape(Capsule())

            Text(distributionCaption)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.md)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppColors.borderSubtle).frame(height: 1)
        }
    }

    private func fraction(_ count: Int) -> CGFloat {
        totalCount > 0 ? CGFloat(count) / CGFloat(totalCount) : 0
    }

    private var distributionCaption: String {
        let top = shares.prefix(2).map { $0.category.displayName }
        switch top.count {
        case 2...:  return "Where your conversations have gone · most in \(top[0]), then \(top[1])"
        case 1:     return "Where your conversations have gone · all in \(top[0])"
        default:    return "Where your conversations have gone"
        }
    }

    // MARK: - Session row

    private func row(_ s: MapStore.RecordSession) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Circle()
                .fill(s.category.mapColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(s.deckName)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textBody)
                HStack(spacing: AppSpacing.xs) {
                    Text(s.date, format: .relative(presentation: .named))
                    Text("·")
                    Text(s.category.displayName)
                }
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
            }

            Spacer()

            HStack(spacing: 3) {
                Text("\(s.cardCount)")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                Text("cards")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 2)
    }
}
