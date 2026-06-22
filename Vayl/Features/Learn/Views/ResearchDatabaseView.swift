// Features/Learn/Views/ResearchDatabaseView.swift
//
// The "browse all research" database. STUB: a scrollable list of
// findings (topic chips + filter sheet deferred). Tapping a row opens
// the finding detail.

import SwiftUI

struct ResearchDatabaseView: View {
    let store: LearnStore
    var onOpenFinding: (ResearchFinding) -> Void = { _ in }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(alignment: .firstTextBaseline) {
                    Text("The Research")
                        .font(AppFonts.screenTitle)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Text("\(store.findingCount) findings")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                ForEach(store.findings) { f in
                    Button { onOpenFinding(f) } label: { row(f) }
                        .buttonStyle(.plain)
                }
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColors.modalBackground)
    }

    private func row(_ f: ResearchFinding) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            if let stat = f.stat {
                Text(stat).font(AppFonts.cardTitle).foregroundStyle(AppColors.spectrumCyan)
                    .frame(width: 64, alignment: .leading)
            } else {
                Image(systemName: f.type.sfSymbol)
                    .font(.system(size: 20)).foregroundStyle(f.type.tint)
                    .frame(width: 48, height: 48)
                    .background(RoundedRectangle(cornerRadius: AppRadius.md).fill(f.type.tint.opacity(0.08)))
            }
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(f.finding).font(AppFonts.caption).foregroundStyle(AppColors.textBody)
                Text("\(f.type.label) · \(f.author) · \(String(f.year))")
                    .font(AppFonts.meta).foregroundStyle(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: AppRadius.lg).fill(AppColors.cardBackground))
    }
}

#Preview {
    ResearchDatabaseView(store: LearnStore())
}
