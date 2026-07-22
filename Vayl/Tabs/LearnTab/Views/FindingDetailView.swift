// Features/Learn/Views/FindingDetailView.swift
//
// A single finding presented as research: stat / finding / bullets /
// honest limitation / citation / connected research. STUB layout.

import SwiftUI

struct FindingDetailView: View {
    let finding: ResearchFinding
    let store: LearnStore
    var onOpenFinding: (ResearchFinding) -> Void = { _ in }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: finding.type.sfSymbol)
                    Text(finding.type.label)
                        .textCase(.uppercase)
                }
                .font(AppFonts.label)
                .foregroundStyle(finding.type.tint)

                if let stat = finding.stat {
                    // On the modal fill, so the contrast-safe stops; `spectrumText`'s
                    // darker stops only clear AA against the page floor.
                    Text(stat).font(AppFonts.displayHero)
                        .foregroundStyle(AppColors.spectrumTextSafe)
                }
                Text(finding.finding)
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textPrimary)

                ForEach(finding.bullets, id: \.self) { b in
                    Label(b, systemImage: "circle.fill")
                        .font(AppFonts.bodyText)
                        .foregroundStyle(AppColors.textBody)
                        .labelStyle(BulletStyle())
                }

                Text("One honest limitation")
                    .font(AppFonts.overline).foregroundStyle(AppColors.textSecondary)
                Text(finding.limitation)
                    .font(AppFonts.caption).foregroundStyle(AppColors.textBody)

                Text(finding.citation)
                    .font(AppFonts.caption).italic()
                    .foregroundStyle(AppColors.textTertiary)

                if !finding.connected.isEmpty {
                    Text("Connected research")
                        .overlineTracked()
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.top, AppSpacing.sm)
                    ForEach(finding.connected, id: \.self) { id in
                        if let c = store.finding(id: id) {
                            Button { onOpenFinding(c) } label: { connectedRow(c) }
                                .buttonStyle(PressableCardStyle())
                        }
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
    }

    private func connectedRow(_ c: ResearchFinding) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: c.type.sfSymbol).foregroundStyle(c.type.tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(c.type.label).font(AppFonts.label).foregroundStyle(AppColors.textSecondary)
                Text(c.headline).font(AppFonts.bodyMedium).foregroundStyle(AppColors.textPrimary)
            }
            Spacer()
            Image(systemName: AppIcons.chevronRight).foregroundStyle(AppColors.textTertiary)
        }
        .padding(AppSpacing.md)
        .background(RoundedRectangle(cornerRadius: AppRadius.lg).fill(AppColors.cardBackground))
    }
}

private struct BulletStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            // 7pt optically centers the bullet dot against the first text line; not a spacing token.
            // swiftlint:disable:next no_hardcoded_padding
            Image(systemName: AppIcons.circleFill).font(AppFonts.body(4, weight: .regular, relativeTo: .caption2)).padding(.top, 7)
            configuration.title
        }
    }
}

#Preview {
    // Seed research data literal.
    // swiftlint:disable:next line_length
    let f = ResearchFinding(id: "haupert", type: .prevalence, stat: "1 in 5", headline: "1 in 5", finding: "Roughly 1 in 5 Americans has engaged in CNM.", bullets: ["Evenly distributed.", "Consistent across studies."], limitation: "Lifetime counts only.", citation: "Haupert et al. (2017).", author: "Haupert et al.", year: 2017, topics: [], connected: [])
    return FindingDetailView(finding: f, store: LearnStore())
}

#Preview("In rail") {
    // swiftlint:disable:next line_length
    let f = ResearchFinding(id: "haupert", type: .prevalence, stat: "1 in 5", headline: "1 in 5", finding: "Roughly 1 in 5 Americans has engaged in CNM.", bullets: ["Evenly distributed.", "Consistent across studies."], limitation: "Lifetime counts only.", citation: "Haupert et al. (2017).", author: "Haupert et al.", year: 2017, topics: [], connected: [])
    VaylSheetPreviewHost(heightFraction: 0.85) {
        FindingDetailView(finding: f, store: LearnStore())
    }
}
