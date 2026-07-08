// Features/Learn/Views/ResearchDatabaseView.swift
//
// The "browse all research" database: search + topic chips + sort/Filters
// affordances over the finding list. The chips/sort/filter are VISUAL for now
// — the actual filtering engine is the deeper pass (chips derive from corpus
// `topics` tags). Tapping a row opens the finding detail.

import SwiftUI

struct ResearchDatabaseView: View {
    let store: LearnStore
    var onOpenFinding: (ResearchFinding) -> Void = { _ in }

    @Environment(\.vaylDismiss) private var vaylDismiss
    @State private var selectedTopic: String = "All"

    private var topics: [String] {
        ["All"] + Array(Set(store.findings.flatMap(\.topics))).sorted()
    }

    var body: some View {
        ZStack {
            AppColors.pageBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    backButton
                    header
                    searchField
                    topicChips
                    controlRow
                    ForEach(store.findings) { f in
                        Button { onOpenFinding(f) } label: { row(f) }
                            .buttonStyle(PressableCardStyle())
                    }
                }
                .padding(AppSpacing.lg)
            }
        }
    }

    private var backButton: some View {
        Button { vaylDismiss(confirm: false) } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "chevron.left")
                Text("Learn")
            }
            .font(AppFonts.buttonLabel)
            .foregroundStyle(AppColors.textSecondary)
        }
        .buttonStyle(PressableCardStyle())
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("The Research")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.spectrumPurple)
            Spacer()
            Text("\(store.findingCount) findings")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var searchField: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass").foregroundStyle(AppColors.textSecondary)
            Text("Search findings, authors…")
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textTertiary)
            Spacer(minLength: 0)
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.md)
        .background(RoundedRectangle(cornerRadius: AppRadius.md)
            .fill(AppColors.whisperFill)
            .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(AppColors.borderSubtle, lineWidth: 1)))
    }

    private var topicChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(topics, id: \.self) { topic in
                    let on = topic == selectedTopic
                    Button { withAnimation(AppAnimation.standard) { selectedTopic = topic } } label: {
                        Text(topic.capitalized)
                            .font(AppFonts.buttonLabelSmall)
                            .foregroundStyle(on ? AppColors.textPrimary : AppColors.textSecondary)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(Capsule()
                                .fill(on ? AppColors.spectrumPurple.opacity(0.2) : AppColors.whisperFill)
                                .overlay(Capsule().stroke(on ? AppColors.spectrumPurple.opacity(0.45) : AppColors.borderSubtle, lineWidth: 1)))
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
        }
    }

    private var controlRow: some View {
        HStack {
            HStack(spacing: AppSpacing.xs) {
                Text("Newest").font(AppFonts.bodyMedium).foregroundStyle(AppColors.textBody)
                Image(systemName: "chevron.down").font(AppFonts.caption).foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "line.3.horizontal.decrease")
                Text("Filters")
            }
            .font(AppFonts.buttonLabel)
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(Capsule()
                .fill(AppColors.spectrumPurple.opacity(0.14))
                .overlay(Capsule().stroke(AppColors.spectrumPurple.opacity(0.3), lineWidth: 1)))
        }
    }

    private func row(_ f: ResearchFinding) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            if let stat = f.stat {
                Text(stat).font(AppFonts.cardTitle).foregroundStyle(AppColors.spectrumText)
                    .frame(width: 64, alignment: .leading)
            } else {
                Image(systemName: f.type.sfSymbol)
                    .font(AppFonts.body(20, weight: .regular, relativeTo: .body)).foregroundStyle(f.type.tint)
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
        .learnCard(AppColors.spectrumPurple, cornerRadius: AppRadius.lg)
    }
}

#Preview {
    ResearchDatabaseView(store: LearnStore())
}
