// Tabs/LearnTab/Views/ResearchDatabaseView.swift
//
// The "browse all" database: research findings AND glossary terms in one body,
// filterable by kind and topic. Tapping a finding opens its detail.
//
// Fixed 2026-07-16 — what was broken:
//
// • The filters were decorative. `selectedTopic` was set by the topic chips but
//   never read: the list was a flat `ForEach(store.findings)`. The sort control
//   ("Newest ⌄") and the "Filters" pill had no action at all — chrome over a stub.
//   Both filter dimensions now actually filter, and the fake sort/Filters row is
//   gone rather than left as a promise the screen doesn't keep.
// • The glossary had no home. It lived in the store and rendered nowhere, so the
//   tab whose job is vocabulary never showed a word.
//
// Terms carry no topics, so the two filters interlock: choosing a topic implies
// findings, and choosing Terms clears the topic, rather than silently emptying
// the list.

import SwiftUI

struct ResearchDatabaseView: View {
    let store: LearnStore
    var onOpenFinding: (ResearchFinding) -> Void = { _ in }

    @Environment(\.vaylDismiss) private var vaylDismiss
    @State private var kind: ReferenceFilter = .all
    @State private var selectedTopic: String = Self.allTopics

    private static let allTopics = "All"

    private var topics: [String] {
        [Self.allTopics] + Array(Set(store.findings.flatMap(\.topics))).sorted()
    }

    /// Kind filter first, then topic. Terms have no topics, so any real topic
    /// selection narrows to findings by construction.
    private var items: [ReferenceItem] {
        let base = store.reference(kind)
        guard selectedTopic != Self.allTopics else { return base }
        return base.filter { $0.topics.contains(selectedTopic) }
    }

    var body: some View {
        ZStack {
            AppColors.pageBackground.ignoresSafeArea()
            OnboardingAtmosphere(config: .stat).ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppSpacing.md) {
                    backButton
                    header
                    kindChips
                    if topics.count > 1 { topicChips }
                    if items.isEmpty {
                        emptyState
                    } else {
                        ForEach(items) { item in
                            switch item {
                            case .finding(let f):
                                Button { onOpenFinding(f) } label: { findingRow(f) }
                                    .buttonStyle(PressableCardStyle())
                            case .term(let t):
                                termRow(t)
                            }
                        }
                    }
                }
                .padding(AppSpacing.lg)
            }
        }
    }

    private var backButton: some View {
        Button { vaylDismiss(confirm: false) } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: AppIcons.chevronLeft)
                Text("Learn")
            }
            .font(AppFonts.buttonLabel)
            .foregroundStyle(AppColors.textSecondary)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableCardStyle())
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Knowledge hub")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Text(countLabel)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var countLabel: String {
        let n = items.count
        switch kind {
        case .all:      return "\(n) entries"
        case .findings: return "\(n) findings"
        case .terms:    return "\(n) terms"
        }
    }

    // MARK: - Filters

    private var kindChips: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(ReferenceFilter.allCases) { option in
                chip(option.label, on: option == kind) {
                    kind = option
                    // Terms carry no topics; a stale topic would empty the list.
                    if option == .terms { selectedTopic = Self.allTopics }
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var topicChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(topics, id: \.self) { topic in
                    chip(topic.capitalized, on: topic == selectedTopic) {
                        selectedTopic = topic
                        // Only findings are topic-tagged, so a topic implies them.
                        if topic != Self.allTopics, kind == .terms { kind = .findings }
                    }
                }
            }
        }
    }

    private func chip(_ label: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(AppAnimation.standard) { action() }
        } label: {
            Text(label)
                .font(AppFonts.buttonLabelSmall)
                .foregroundStyle(on ? AppColors.textPrimary : AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .frame(minHeight: 44)
                .background(Capsule()
                    .fill(on ? AppColors.spectrumPurple.opacity(0.2) : AppColors.whisperFill)
                    .overlay(Capsule().stroke(on ? AppColors.spectrumPurple.opacity(0.45)
                                                 : AppColors.borderSubtle, lineWidth: 1)))
                .contentShape(Capsule())
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityAddTraits(on ? [.isSelected] : [])
    }

    private var emptyState: some View {
        VaylEmptyState(
            icon: AppIcons.textMagnifyingglass,
            headline: "Nothing matches that",
            message: "Try a different filter, or clear it to see everything.",
            cta: .init(label: "Clear filters") {
                withAnimation(AppAnimation.standard) {
                    kind = .all
                    selectedTopic = Self.allTopics
                }
            }
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxl)
    }

    // MARK: - Rows

    private func findingRow(_ f: ResearchFinding) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            if let stat = f.stat {
                // On a card fill, so the contrast-safe stops — `spectrumText`'s
                // darker stops only clear AA against the page floor.
                Text(stat).font(AppFonts.cardTitle)
                    .foregroundStyle(AppColors.spectrumTextSafe)
                    .frame(width: 64, alignment: .leading)
            } else {
                Image(systemName: f.type.sfSymbol)
                    .font(AppFonts.body(20, weight: .regular, relativeTo: .body))
                    .foregroundStyle(f.type.tint)
                    .frame(width: 48, height: 48)
                    .background(RoundedRectangle(cornerRadius: AppRadius.md).fill(f.type.tint.opacity(0.08)))
            }
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(f.finding).font(AppFonts.caption).foregroundStyle(AppColors.textBody)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                Text("\(f.type.label) · \(f.author) · \(String(f.year))")
                    .font(AppFonts.meta).foregroundStyle(AppColors.textTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .learnReadingCard(cornerRadius: AppRadius.lg)
    }

    /// Not a button — the definition is the entire content, so there is nothing
    /// deeper to open. No tap target without a destination.
    private func termRow(_ t: LexiconTerm) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            // Neutral: an icon tile marking a row's kind is content, not a control.
            // Purple in Learn means "you can act here" — links and selection.
            Image(systemName: AppIcons.textMagnifyingglass)
                .font(AppFonts.body(20, weight: .regular, relativeTo: .body))
                .foregroundStyle(AppColors.textTertiary)
                .frame(width: 48, height: 48)
                .background(RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(AppColors.whisperFill))
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(t.term).font(AppFonts.cardTitleCompact)
                    .foregroundStyle(AppColors.textPrimary)
                Text(t.definition).font(AppFonts.caption)
                    .foregroundStyle(AppColors.textBody)
                    .fixedSize(horizontal: false, vertical: true)
                if let example = t.example {
                    Text("\u{201C}\(example)\u{201D}")
                        .font(AppFonts.meta).italic()
                        .foregroundStyle(AppColors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .learnReadingCard(cornerRadius: AppRadius.lg)
    }
}

#Preview {
    ResearchDatabaseView(store: LearnStore())
}
