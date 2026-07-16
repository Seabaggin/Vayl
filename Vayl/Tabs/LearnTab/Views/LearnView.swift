// Tabs/LearnTab/Views/LearnView.swift
//
// The Learn tab IS the reference: research findings and glossary terms in one
// browsable body, filterable by type, with one door out to the content hub.
//
// IA settled with Bryan 2026-07-16. Two things drove it:
//
// 1. Learn has no "today" and shouldn't. Home's Lexicon already serves a daily-5
//    from these exact corpora (research_findings / lexicon_terms / media_quotes)
//    with a day-seeded rotation. A daily hero here would be the same content, same
//    trick, second surface. Home is the daily surface; Learn is where you go
//    deliberately to look something up.
// 2. Learn used to be a content-hub template: three sections, each painted its own
//    spectrum accent, a segmented pill-group nested in a card in a tab, and an
//    auto-advancing carousel that moved for no reason. That's why it read as
//    derivative. The fix isn't a better feed — it's to stop being one. Learn is a
//    reference you consult, which is a job no other tab has.
//
// Research and glossary are one body because they're the same kind of thing: cited,
// first-party, "what we know" — the frame the subtitle promises. The content hub is
// third-party media ("where to go next"), so it's a door, not a section.
//
// No Router/Dashboard split: Learn has no routing state machine (unlike Home), so
// the extra layer would be ceremony without payoff.

import SwiftUI

struct LearnView: View {
    @State private var store = LearnStore()
    @State private var showHub = false
    @State private var showResources = false
    @State private var selectedFinding: ResearchFinding?
    @State private var filter: ReferenceFilter = .all

    /// The reference's one filter dimension. Unlike the old research database's
    /// topic chips — which set state that nothing ever read — this one filters.
    enum ReferenceFilter: String, CaseIterable, Identifiable {
        case all, findings, terms
        var id: String { rawValue }
        var label: String {
            switch self {
            case .all:      return "All"
            case .findings: return "Findings"
            case .terms:    return "Terms"
            }
        }
    }

    /// One list, two shapes. Findings lead; terms follow. Within the mixed view the
    /// order is stable and corpus-ordered, never shuffled — a reference you consult
    /// should be in the same place you left it.
    private var showFindings: Bool { filter != .terms }
    private var showTerms: Bool { filter != .findings }

    private var visibleFindings: [ResearchFinding] { showFindings ? store.findings : [] }
    private var visibleTerms: [LexiconTerm] { showTerms ? store.lexiconTerms : [] }
    private var isEmpty: Bool { visibleFindings.isEmpty && visibleTerms.isEmpty }

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.pageBackground.ignoresSafeArea()
            OnboardingAtmosphere(config: .stat).ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppSpacing.md) {
                    header
                    if store.loadError != nil { loadErrorNotice }
                    hubDoor
                    filterChips
                        .padding(.top, AppSpacing.xs)
                    if isEmpty {
                        emptyState
                    } else {
                        ForEach(visibleFindings) { f in
                            LearnFindingRow(finding: f, onOpen: { selectedFinding = f })
                        }
                        ForEach(visibleTerms) { t in
                            LearnTermRow(term: t)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.lg)   // breathing room only; tab-bar clearance is the shell's job
            }
            // Top scroll-edge: the masthead dissolves under the Dynamic Island as
            // it scrolls up, instead of hard-cutting at the safe-area line.
            .scrollTopEdgeFade()
        }
        .vaylCover(isPresented: $showHub, confirmOnExit: false) {
            ContentHubView(store: store)
        }
        .vaylSheet(isPresented: $showResources, heightFraction: 0.75) {
            ResourcesOverlayView(resources: store.supportResources)
        }
        .vaylSheet(isPresented: detailBinding, heightFraction: 0.85) {
            if let f = selectedFinding {
                FindingDetailView(finding: f, store: store, onOpenFinding: { selectedFinding = $0 })
            }
        }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Learn.")
                    .font(AppFonts.tabMasthead)
                    .vaylDisplayTracking(40)   // tabMasthead is display(40); tighten optically
                    .foregroundStyle(AppColors.spectrumText)
                Text("Build your frame before you need it")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            Spacer()
            // A 44pt glass circle, not a shimmer capsule: shimmer is a CTA material,
            // and Resources is quiet chrome that should never outrank the content.
            Button { showResources = true } label: {
                Image(systemName: AppIcons.lifepreserver)
                    .font(AppFonts.body(16, weight: .regular, relativeTo: .body))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(AppColors.whisperFill))
                    .overlay(Circle().stroke(AppColors.borderDefault, lineWidth: 1))
            }
            .buttonStyle(PressableCardStyle())
            .accessibilityLabel("Support resources")
        }
        .padding(.bottom, AppSpacing.sm)
    }

    /// The hub sits above the list, not below it: the reference runs to dozens of
    /// rows, and a door at the bottom of a long scroll is a door nobody opens.
    private var hubDoor: some View {
        Button { showHub = true } label: {
            HStack(spacing: AppSpacing.md2) {
                Image(systemName: AppIcons.books)
                    .font(AppFonts.body(18, weight: .regular, relativeTo: .body))
                    .foregroundStyle(AppColors.textAccent)
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("The content hub")
                        .font(AppFonts.cardTitleCompact)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(hubDetail)
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
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .learnCard()
        }
        .buttonStyle(PressableCardStyle())
    }

    private var hubDetail: String {
        let count = store.media.count + store.voices.count
        return count > 0
            ? "Books, shows, podcasts, voices · \(count)"
            : "Books, shows, podcasts, voices"
    }

    private var filterChips: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(ReferenceFilter.allCases) { option in
                let on = option == filter
                Button {
                    withAnimation(AppAnimation.standard) { filter = option }
                } label: {
                    Text(option.label)
                        .font(AppFonts.buttonLabelSmall)
                        .foregroundStyle(on ? AppColors.textPrimary : AppColors.textSecondary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .frame(minHeight: 44)
                        // Same selected fill SegmentedPillGroup uses, so the two
                        // selection affordances in Learn read as one vocabulary.
                        .background(Capsule().fill(on ? AppColors.glassFrostPillSelected : AppColors.whisperFill))
                        .overlay(Capsule().stroke(on ? AppColors.borderActive : AppColors.borderSubtle,
                                                  lineWidth: 1))
                        .contentShape(Capsule())
                }
                .buttonStyle(PressableCardStyle())
                .accessibilityAddTraits(on ? [.isSelected] : [])
            }
            Spacer(minLength: 0)
            Text(countLabel)
                .font(AppFonts.meta)
                .foregroundStyle(AppColors.textTertiary)
        }
    }

    private var countLabel: String {
        let n = visibleFindings.count + visibleTerms.count
        switch filter {
        case .all:      return "\(n) entries"
        case .findings: return "\(n) findings"
        case .terms:    return "\(n) terms"
        }
    }

    // MARK: - States

    private var emptyState: some View {
        VaylEmptyState(
            icon: AppIcons.textMagnifyingglass,
            headline: store.loadError == nil ? "Nothing here yet" : "Couldn't load the reference",
            message: store.loadError == nil
                ? "Research and vocabulary will show up here when they load."
                : "Check your connection. Nothing is lost, it just isn't loaded yet."
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxl)
    }

    private var loadErrorNotice: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: AppIcons.exclamationTriangle)
                .font(AppFonts.body(16, weight: .regular, relativeTo: .body))
                .foregroundStyle(AppColors.textTertiary)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("Some content didn't load")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Part of Learn couldn't be read. Anything below is what loaded.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .vaylGlassCard()
    }

    private var detailBinding: Binding<Bool> {
        Binding(get: { selectedFinding != nil },
                set: { if !$0 { selectedFinding = nil } })
    }
}

#Preview {
    LearnView()
}
