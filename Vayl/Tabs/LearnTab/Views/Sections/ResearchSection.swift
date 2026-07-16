// Tabs/LearnTab/Views/Sections/ResearchSection.swift
//
// Section 1 — the reference: research findings AND glossary terms, previewed in a
// swipeable paging carousel over a quiet "browse all" row into the database.
//
// Two changes, 2026-07-16:
//
// 1. The glossary joined the research. They're the same kind of thing (cited,
//    first-party) and the vocabulary previously had no front door at all — it was
//    reachable only by filtering inside the research database.
// 2. The carousel no longer auto-advances. Drifting every 12s was decorative
//    motion: it conveyed no state and made the section read as a feed. It now
//    moves only when the user swipes.
//
// Deliberately NOT here: a finding-of-the-day. Home's Lexicon already serves a
// daily-5 from these exact corpora with a day-seeded rotation; a daily hero here
// would be the same content, same trick, second surface.

import SwiftUI

struct ResearchSection: View {
    let items: [ReferenceItem]
    var onOpenDatabase: () -> Void = {}
    var onOpenFinding: (ResearchFinding) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Research & vocabulary")
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Button { onOpenDatabase() } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: AppIcons.rectangleStack)
                            .foregroundStyle(AppColors.spectrumPurple)   // purple symbol (section is purple-only)
                        Text("Browse")
                            .font(AppFonts.buttonLabel)
                            .foregroundStyle(AppColors.textBody)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(HolographicShimmer().opacity(0.7))        // same shimmer as the Resources pill
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(AppColors.borderSubtle, lineWidth: 1))
                }
                .buttonStyle(PressableCardStyle())
            }

            InfiniteCarousel(items: items, autoAdvances: false, height: 212) { item in
                switch item {
                case .finding(let f):
                    Button { onOpenFinding(f) } label: { findingCard(f) }
                        .buttonStyle(PressableCardStyle())
                case .term(let t):
                    // Not a button: the definition is the whole payload, so there's
                    // nothing deeper to open. No tap target without a destination.
                    termCard(t)
                }
            } emptyContent: {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: AppIcons.textMagnifyingglass)
                .font(AppFonts.body(26, weight: .regular, relativeTo: .title2))
                .foregroundStyle(AppColors.textTertiary)
            Text("Nothing to show yet")
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textSecondary)
            Text("Research and vocabulary will show up here when they load.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
    }

    private func typeChip(_ f: ResearchFinding) -> some View {
        chip(icon: f.type.sfSymbol, label: f.type.label)
    }

    private func chip(icon: String, label: String) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
            Text(label.uppercased())
        }
        .font(AppFonts.label)
        .foregroundStyle(AppColors.spectrumPurple)   // section is purple-only; the icon conveys type
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(Capsule().fill(AppColors.spectrumPurple.opacity(0.1)))
    }

    private func findingCard(_ f: ResearchFinding) -> some View {
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
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Text(f.citation)
                .font(AppFonts.caption).italic()
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(AppSpacing.lg)
        .learnCard()
    }

    private func termCard(_ t: LexiconTerm) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            chip(icon: AppIcons.textMagnifyingglass, label: "Term")
            Text(t.term)
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text(t.definition)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if let example = t.example {
                Text("\u{201C}\(example)\u{201D}")
                    .font(AppFonts.caption).italic()
                    .foregroundStyle(AppColors.textTertiary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(AppSpacing.lg)
        .learnCard()
    }
}

#Preview {
    // Seed research data literal.
    // swiftlint:disable:next line_length
    let a = ResearchFinding(id: "haupert", type: .prevalence, stat: "1 in 5", headline: "1 in 5", finding: "Roughly 1 in 5 Americans has engaged in CNM.", bullets: [], limitation: "", citation: "Haupert et al. (2017).", author: "Haupert et al.", year: 2017, topics: [], connected: [])
    // Seed research data literal.
    // swiftlint:disable:next line_length
    let b = ResearchFinding(id: "conley", type: .myth, stat: nil, headline: "Monogamy myths", finding: "Monogamy isn't inherently safer for STI risk — CNM couples test and talk more.", bullets: [], limitation: "", citation: "Conley et al. (2013).", author: "Conley et al.", year: 2013, topics: [], connected: [])
    let t = LexiconTerm(id: "compersion", kind: .term, term: "Compersion",
                        definition: "Joy felt when a partner experiences joy with someone else.",
                        example: nil)
    return ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ResearchSection(items: [.finding(a), .finding(b), .term(t)]).padding()
    }
}
