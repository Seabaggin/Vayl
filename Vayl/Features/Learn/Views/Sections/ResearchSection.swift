// Features/Learn/Views/Sections/ResearchSection.swift
//
// Section 2 — research. STUB: featured finding card + a horizontal
// carousel of the next findings + a "browse all" row into the
// database. Purple hairline.

import SwiftUI

struct ResearchSection: View {
    let featured: ResearchFinding?
    let carousel: [ResearchFinding]
    let totalCount: Int
    var onOpenDatabase: () -> Void = {}
    var onOpenFinding: (ResearchFinding) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHairline(color: AppColors.spectrumPurple)
            Text("THE RESEARCH")
                .font(AppFonts.overline)
                .tracking(1.5)
                .foregroundStyle(AppColors.textSecondary)

            if let featured {
                Button { onOpenFinding(featured) } label: { featuredCard(featured) }
                    .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(carousel) { finding in
                        Button { onOpenFinding(finding) } label: { miniCard(finding) }
                            .buttonStyle(.plain)
                    }
                }
            }

            Button(action: onOpenDatabase) {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "square.stack.3d.up")
                        .foregroundStyle(AppColors.spectrumPurple)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Browse all research")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        Text("\(totalCount) findings · filter by topic, author, year")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .foregroundStyle(AppColors.spectrumPurple.opacity(0.7))
                }
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .fill(AppColors.spectrumPurple.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: AppRadius.lg)
                            .stroke(AppColors.spectrumPurple.opacity(0.2), lineWidth: 1))
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func typeChip(_ f: ResearchFinding) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: f.type.sfSymbol)
            Text(f.type.label.uppercased())
        }
        .font(AppFonts.label)
        .foregroundStyle(f.type.tint)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 4)
        .background(Capsule().fill(f.type.tint.opacity(0.1)))
    }

    private func featuredCard(_ f: ResearchFinding) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            typeChip(f)
            if let stat = f.stat {
                Text(stat)
                    .font(AppFonts.scoreDisplay)
                    .foregroundStyle(AppColors.spectrumPurple)
            }
            Text(f.finding)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
            Text(f.citation)
                .font(AppFonts.caption).italic()
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(RoundedRectangle(cornerRadius: AppRadius.xl).fill(AppColors.cardBackground))
    }

    private func miniCard(_ f: ResearchFinding) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            typeChip(f)
            Text(f.finding)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textBody)
                .lineLimit(4)
            Spacer(minLength: 0)
            Text("\(f.author) · \(String(f.year))")
                .font(AppFonts.meta).italic()
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(AppSpacing.md)
        .frame(width: 230, height: 150, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: AppRadius.lg).fill(AppColors.cardBackground))
    }
}

#Preview {
    let sample = ResearchFinding(id: "haupert", type: .prevalence, stat: "1 in 5", headline: "1 in 5", finding: "Roughly 1 in 5 Americans has engaged in CNM.", bullets: [], limitation: "", citation: "Haupert et al. (2017).", author: "Haupert et al.", year: 2017, topics: [], connected: [])
    return ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ResearchSection(featured: sample, carousel: [sample], totalCount: 32).padding()
    }
}
