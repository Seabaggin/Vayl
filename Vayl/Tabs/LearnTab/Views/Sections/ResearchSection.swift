// Tabs/LearnTab/Views/Sections/ResearchSection.swift
//
// Section 1 — the Knowledge hub: research findings AND glossary terms, previewed
// in a swipeable paging carousel over a quiet "browse all" row into the database.
//
// (Filename still says Research; the section outgrew it when the glossary joined.
// Renaming the type is a mechanical follow-up, not worth the churn mid-sprint.)
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
                Text("Knowledge hub")
                    .font(AppFonts.sectionHeading)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textSectionLabel)
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

    /// A white pill. The chip names a category — it is content, not a control, and
    /// it was wearing the same purple as the links and the selected filter. Colour
    /// marks what you can act on; a label goes neutral.
    private func chip(icon: String, label: String) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
            Text(label)
                .textCase(.uppercase)
        }
        .font(AppFonts.label)
        .foregroundStyle(AppColors.textSecondary)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(Capsule().fill(AppColors.whisperFill))
        .overlay(Capsule().stroke(AppColors.borderSubtle, lineWidth: 1))
    }

    /// The finding IS the card. The standalone `scoreDisplay` stat is gone: it
    /// printed "1 in 5" in 32pt directly above a sentence that reads "Roughly 1 in
    /// 5 Americans…" — the same number twice, with the big one winning and the
    /// actual claim demoted to a caption.
    ///
    /// Now the number is highlighted inside the sentence via `HighlightText`, the
    /// same treatment OB card prompts use for their highlight words. Note its
    /// gradient is two-stop (cyan→purple), not the full cyan→purple→magenta, which
    /// is why it's legal below the Earned Spectrum Rule's 24pt bar.
    private func findingCard(_ f: ResearchFinding) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            typeChip(f)
            HighlightText.highlighted(
                f.finding,
                // The stat verbatim — it's already inside the sentence. A finding
                // with no number has nothing to highlight and reads plain, which is
                // honest: not every finding is a statistic.
                words: [f.stat].compactMap { $0 },
                baseFont: AppFonts.prompt,
                highlightFont: AppFonts.prompt,
                baseColor: AppColors.textBody
            )
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            // wraps: true is load-bearing. Citations are sentences, and LivingText
            // defaults to .fixedSize() for its hero-word callers — without this the
            // citation renders as one line wider than the screen and drags the whole
            // card with it, clipping the finding text above.
            LivingText(text: f.citation, font: AppFonts.caption, wraps: true)
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
