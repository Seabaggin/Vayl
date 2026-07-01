//
//  DeckWallView.swift
//  Vayl — Play
//
//  The deck library: a full 2-column grid of every deck's case, scrolling inline
//  beneath the hero. Replaces the old docked-peek → pan/zoom canvas, which clipped
//  to one row (hiding most decks) and left a fade-to-void cutoff band. Now the page
//  simply scrolls and the whole library is visible. Tap a deck → its detail.
//

import SwiftUI

struct DeckWallView: View {
    let store: PlayStore
    let namespace: Namespace.ID

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            header
            grid
        }
    }

    private var header: some View {
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

    private var grid: some View {
        let cols = [GridItem(.flexible(), spacing: AppSpacing.md),
                    GridItem(.flexible(), spacing: AppSpacing.md)]
        return LazyVGrid(columns: cols, spacing: AppSpacing.lg) {
            ForEach(Array(store.summaries.enumerated()), id: \.element.id) { i, s in
                DeckCellView(summary: s, style: store.style(for: s),
                             locked: store.isLocked(s), index: i, namespace: namespace) {
                    store.openDetail(s.id)
                }
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }
}

#if DEBUG
#Preview("Deck library") {
    @Previewable @Namespace var ns
    ZStack {
        AppColors.void.ignoresSafeArea()
        ScrollView(showsIndicators: false) { DeckWallView(store: .preview, namespace: ns) }
    }
    .preferredColorScheme(.dark)
}
#endif
