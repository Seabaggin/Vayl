//
//  DeckCellView.swift
//  Vayl — Play
//
//  A wall cell: the flat case (title now lives INSIDE the case) + a compact
//  metadata SHELF underneath (shelf grammar). Shelf v2 (spec 2026-07-11 §7):
//  category → "N cards" + partner-saved dot → progress bar / "✓ Completed" /
//  nothing. No difficulty label anywhere. Tap routes through the store, which
//  decides paywall / first-open ceremony / detail from the deck's state.
//
//  Tap + press feedback come from a Button + PressableCardStyle (the Learn-tab
//  pattern), which is scroll-safe. A minimumDistance:0 DragGesture here used to
//  grab every touch and fight the library's scroll. The wall→detail open is a
//  fade now (matchedGeometry lives only in the first-open ceremony), so the cell
//  no longer sources a matchedGeometryEffect.
//

import SwiftUI

struct DeckCellView: View {
    let summary: DeckSummary
    let style: DeckStyle
    /// The wall's store — the cell reads deck state / progress / partner-star
    /// through it and routes taps through `tapDeck`. Never touches SwiftData or
    /// the catalog service directly (spec §2).
    let store: PlayStore
    var index: Int = 0
    /// The measured grid-column width (from `DeckWallView`). The case is pinned to
    /// `caseWidth × 1.5` so it can NEVER stretch to fill leftover row height — the bug
    /// that made rowmate cases render at different heights. `.aspectRatio` alone does
    /// not hold inside a LazyVGrid row; an explicit height does.
    var caseWidth: CGFloat = 150

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            store.tapDeck(summary.id)
        } label: {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                DeckCaseView(summary: summary, style: style, state: store.deckState(summary), width: caseWidth)
                shelf
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableCardStyle())
        // C · ambient: each case settles in as it enters view (cascades by index).
        .scaleEffect(appeared ? 1 : 0.96)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(AppAnimation.enter.delay(Double(index % 6) * 0.04)) { appeared = true }
            }
        }
    }

    // MARK: - Shelf v2

    private var shelf: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(summary.category.displayName)
                .font(AppFonts.overline)
                .foregroundStyle(AppColors.textHint)

            HStack(spacing: AppSpacing.xs) {
                Text("\(summary.cardCount) cards")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                // Partner-saved affordance. Invisible in V1 (isStarredByPartner
                // returns false until partner-star sync lands) — kept on purpose,
                // never faked.
                if store.isStarredByPartner(summary) {
                    Circle()
                        .fill(AppColors.spectrumMagenta)
                        .frame(width: AppSpacing.xs, height: AppSpacing.xs)
                }
            }

            statusLine
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// One of: in-progress bar + "N% in" · "✓ Completed" · nothing (fresh).
    /// `progressFraction` is nil when fresh OR completed, so the completed branch
    /// only shows for genuinely finished decks.
    @ViewBuilder
    private var statusLine: some View {
        if let fraction = store.progressFraction(summary) {
            HStack(spacing: AppSpacing.sm) {
                ProgressBar(value: fraction, max: 1)
                Text("\(Int((fraction * 100).rounded()))% in")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .fixedSize()
            }
        } else if store.isCompleted(summary) {
            Text("✓ Completed")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
    }
}

#if DEBUG
#Preview("Cells — shelf v2") {
    let store = PlayStore.preview
    let samples = (try? DeckCatalogService().loadSummaries()) ?? []
    return ZStack {
        AppColors.void.ignoresSafeArea()
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: AppSpacing.lg) {
            ForEach(Array(samples.prefix(4).enumerated()), id: \.element.id) { index, summary in
                DeckCellView(summary: summary,
                             style: store.style(for: summary),
                             store: store,
                             index: index)
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
#endif
