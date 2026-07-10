//
//  DeckCellView.swift
//  Vayl — Play
//
//  A wall cell: the flat case + the deck's title/meta UNDERNEATH (shelf grammar).
//  Tap + press feedback come from a Button + PressableCardStyle (the Learn-tab pattern),
//  which is scroll-safe. A minimumDistance:0 DragGesture here used to grab every touch
//  and fight the library's scroll.
//

import SwiftUI

struct DeckCellView: View {
    let summary: DeckSummary
    let style: DeckStyle
    /// Live lock state from the wall's store (nil = frozen catalog flag).
    var locked: Bool?
    var index: Int = 0
    var namespace: Namespace.ID
    /// True while THIS deck's detail overlay is open. The cell yields matched-
    /// geometry sourcehood (and hides its case) so the detail's case is the one
    /// live source — two simultaneous sources degrade the zoom to a crossfade.
    var detailOpen: Bool = false
    var onTap: () -> Void

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                DeckCaseView(summary: summary, style: style, lockedOverride: locked)
                    .matchedGeometryEffect(id: summary.id, in: namespace, isSource: !detailOpen)
                    .opacity(detailOpen ? 0 : 1)
                VStack(alignment: .leading, spacing: 3) {
                    Text(summary.category.displayName)
                        .font(AppFonts.overline)
                        .foregroundStyle(AppColors.textHint)
                    Text(summary.title)
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        Circle().fill(style.accent).frame(width: 6, height: 6)
                        Text("\(summary.intensity.difficultyLabel) · \(summary.cardCount) cards")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableCardStyle())
        // C · ambient: each case settles in as it enters view (cascades by index).
        .scaleEffect(appeared ? 1 : 0.96)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            if reduceMotion { appeared = true } else { withAnimation(AppAnimation.enter.delay(Double(index % 6) * 0.04)) { appeared = true } }
        }
    }
}

#if DEBUG
#Preview("Cell — unlocked") {
    @Previewable @Namespace var ns
    let samples = (try? DeckCatalogService().loadSummaries()) ?? []
    return ZStack {
        AppColors.void.ignoresSafeArea()
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: AppSpacing.lg) {
            ForEach(Array(samples.prefix(2).enumerated()), id: \.element.id) { index, summary in
                DeckCellView(summary: summary,
                             style: DeckStyle.make(for: summary),
                             locked: false,
                             index: index,
                             namespace: ns) {}
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("Cell — locked") {
    @Previewable @Namespace var ns
    let samples = (try? DeckCatalogService().loadSummaries()) ?? []
    return ZStack {
        AppColors.void.ignoresSafeArea()
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: AppSpacing.lg) {
            ForEach(Array(samples.prefix(2).enumerated()), id: \.element.id) { index, summary in
                DeckCellView(summary: summary,
                             style: DeckStyle.make(for: summary),
                             locked: true,
                             index: index,
                             namespace: ns) {}
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
#endif
