// Tabs/LearnTab/Views/LearnReferenceRow.swift
//
// The two row shapes of the reference: a research finding and a glossary term.
//
// They share a list but not a shape, because they aren't the same kind of thing.
// A finding is a claim someone measured, so it leads with the number and ends with
// the citation that makes it checkable. A term is a word, so it leads with the word
// and the definition IS the payload — there is nothing deeper to open, which is why
// term rows are not tappable. No chevron on a door that doesn't exist.
//
// Reference: docs/mockups/learn-tab-v2.html (direction D grammar), IA revised
// 2026-07-16: research + glossary are one body.

import SwiftUI

/// A research finding — tappable, opens the detail sheet.
struct LearnFindingRow: View {
    let finding: ResearchFinding
    var onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                leading
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(finding.finding)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textBody)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    Text("\(finding.type.label) · \(finding.author) · \(String(finding.year))")
                        .font(AppFonts.meta)
                        .foregroundStyle(AppColors.textTertiary)
                }
                Spacer(minLength: 0)
                Image(systemName: AppIcons.chevronRight)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .learnCard(cornerRadius: AppRadius.lg)
        }
        .buttonStyle(PressableCardStyle())
    }

    @ViewBuilder
    private var leading: some View {
        if let stat = finding.stat {
            // 22pt on a card fill: below the ≥24pt hero bar and not on the page
            // floor, so this takes the contrast-safe stops, not `spectrumText`.
            Text(stat)
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.spectrumTextSafe)
                .frame(width: 64, alignment: .leading)
        } else {
            Image(systemName: finding.type.sfSymbol)
                .font(AppFonts.body(20, weight: .regular, relativeTo: .body))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 48, height: 48)
                .background(RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(AppColors.whisperFill))
        }
    }
}

/// A glossary term — not tappable. The definition is the whole content.
///
/// Discovery, not assessment: the row names the word and hands over its meaning.
/// It never suggests the word describes the reader.
struct LearnTermRow: View {
    let term: LexiconTerm

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(term.term)
                .font(AppFonts.cardTitleCompact)
                .foregroundStyle(AppColors.textPrimary)
            Text(term.definition)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textBody)
                .fixedSize(horizontal: false, vertical: true)
            if let example = term.example {
                // .sentence kind — the usage quote is what teaches the word.
                Text("\u{201C}\(example)\u{201D}")
                    .font(AppFonts.caption).italic()
                    .foregroundStyle(AppColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, AppSpacing.xxs)
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .learnCard(cornerRadius: AppRadius.lg)
    }
}

#Preview {
    // Seed research data literal.
    // swiftlint:disable:next line_length
    let f = ResearchFinding(id: "haupert", type: .prevalence, stat: "1 in 5", headline: "1 in 5", finding: "Roughly 1 in 5 Americans has engaged in consensual non-monogamy at some point.", bullets: [], limitation: "", citation: "Haupert et al. (2017).", author: "Haupert et al.", year: 2017, topics: [], connected: [])
    let t = LexiconTerm(id: "compersion", kind: .term, term: "Compersion",
                        definition: "Joy felt when a partner experiences joy with someone else.",
                        example: nil)
    return ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        VStack(spacing: AppSpacing.md) {
            LearnFindingRow(finding: f, onOpen: {})
            LearnTermRow(term: t)
        }
        .padding()
    }
}
