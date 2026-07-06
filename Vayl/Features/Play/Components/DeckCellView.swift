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
    var locked: Bool? = nil
    var index: Int = 0
    var namespace: Namespace.ID
    var onTap: () -> Void

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                DeckCaseView(summary: summary, style: style, lockedOverride: locked)
                    .matchedGeometryEffect(id: summary.id, in: namespace, isSource: true)
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
            if reduceMotion { appeared = true }
            else { withAnimation(AppAnimation.enter.delay(Double(index % 6) * 0.04)) { appeared = true } }
        }
    }
}
