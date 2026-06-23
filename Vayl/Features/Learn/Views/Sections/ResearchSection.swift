// Features/Learn/Views/Sections/ResearchSection.swift
//
// Section 2 — research: an auto-advancing, infinite-loop paging carousel of
// findings (InfiniteCarousel) over a quiet "browse all" row into the
// filterable database. Purple section hairline.

import SwiftUI

struct ResearchSection: View {
    let findings: [ResearchFinding]
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

            InfiniteCarousel(items: findings, interval: 5.5, height: 212) { finding in
                Button { onOpenFinding(finding) } label: { findingCard(finding) }
                    .buttonStyle(PressableCardStyle())
            }

            browseRow
        }
    }

    // Quiet, lighter-weight than a filled card — stroke-only text row — so the
    // carousel stays the hero while still merchandising the filterable hub.
    private var browseRow: some View {
        Button(action: onOpenDatabase) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundStyle(AppColors.spectrumPurple.opacity(0.8))
                Text("Browse all \(totalCount) findings")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                Text("· filter by topic, author, year")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.vertical, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.md)
            .frame(maxWidth: .infinity)
            .learnCard(AppColors.spectrumPurple, cornerRadius: AppRadius.lg)
        }
        .buttonStyle(PressableCardStyle())
    }

    private func typeChip(_ f: ResearchFinding) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: f.type.sfSymbol)
            Text(f.type.label.uppercased())
        }
        .font(AppFonts.label)
        .foregroundStyle(f.type.tint)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(Capsule().fill(f.type.tint.opacity(0.1)))
    }

    private func findingCard(_ f: ResearchFinding) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            typeChip(f)
            if let stat = f.stat {
                Text(stat)
                    .font(AppFonts.scoreDisplay)
                    .foregroundStyle(AppColors.spectrumText)
            }
            Text(f.finding)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Text(f.citation)
                .font(AppFonts.caption).italic()
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(AppSpacing.lg)
        .learnCard(AppColors.spectrumPurple)
    }
}

#Preview {
    let a = ResearchFinding(id: "haupert", type: .prevalence, stat: "1 in 5", headline: "1 in 5", finding: "Roughly 1 in 5 Americans has engaged in CNM.", bullets: [], limitation: "", citation: "Haupert et al. (2017).", author: "Haupert et al.", year: 2017, topics: [], connected: [])
    let b = ResearchFinding(id: "conley", type: .myth, stat: nil, headline: "Monogamy myths", finding: "Monogamy isn't inherently safer for STI risk — CNM couples test and talk more.", bullets: [], limitation: "", citation: "Conley et al. (2013).", author: "Conley et al.", year: 2013, topics: [], connected: [])
    return ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ResearchSection(findings: [a, b], totalCount: 32).padding()
    }
}
