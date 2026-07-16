//
//  DeckWallView.swift
//  Vayl — Play
//
//  The deck library, split into two shelves: "Your decks" (owned — sealed OR
//  opened) and "Premium" (locked, behind Core). Each is a 2-column grid of deck
//  cells scrolling inline beneath the hero. The Premium shelf hides entirely once
//  Core is owned (every deck migrates up, as sealed). Tap a deck → its detail
//  carousel (sealed decks pass through the first-open ceremony on the way).
//  (Spec 2026-07-11 §1, §7.)
//

import SwiftUI

struct DeckWallView: View {
    let store: PlayStore

    /// Measured wall width → deterministic column width so each case can be pinned to
    /// an explicit 2:3 size (see DeckCellView). Read via a background preference so it
    /// never perturbs the ScrollView's vertical layout the way a GeometryReader would.
    @State private var wallWidth: CGFloat = 0

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.md),
        GridItem(.flexible(), spacing: AppSpacing.md)
    ]

    /// Two flexible columns, `md` between them, grid inset `lg` on each side.
    private var caseWidth: CGFloat {
        let content = wallWidth - AppSpacing.lg * 2 - AppSpacing.md
        return content > 0 ? content / 2 : 150
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            libraryHeader
            section(label: "Your decks", decks: store.unlockedSummaries)
            if !store.lockedSummaries.isEmpty {
                section(label: "Premium", decks: store.lockedSummaries)
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: WallWidthKey.self, value: geo.size.width)
            }
        )
        .onPreferenceChange(WallWidthKey.self) { wallWidth = $0 }
    }

    private var libraryHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Deck library")
                .font(AppFonts.sectionHeading)
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Text("\(store.summaries.count) decks")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    @ViewBuilder
    private func section(label: String, decks: [DeckSummary]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(label)
                .overlineTracked()
                .foregroundStyle(AppColors.textMuted)
                .padding(.horizontal, AppSpacing.lg)

            LazyVGrid(columns: columns, spacing: AppSpacing.lg) {
                ForEach(Array(decks.enumerated()), id: \.element.id) { index, summary in
                    DeckCellView(summary: summary,
                                 style: store.style(for: summary),
                                 store: store,
                                 index: index,
                                 caseWidth: caseWidth)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }
}

private struct WallWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#if DEBUG
#Preview("Deck library") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        ScrollView(showsIndicators: false) { DeckWallView(store: .preview) }
    }
    .preferredColorScheme(.dark)
}
#endif
