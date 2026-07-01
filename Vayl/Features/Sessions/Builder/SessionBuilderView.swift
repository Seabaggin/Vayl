//
//  SessionBuilderView.swift
//  Vayl
//
//  PLAN16-SECTION3 replaces this stub with the real builder (fast-path chips,
//  reorderable card list, timer chips, Start CTA). This placeholder keeps
//  Section 2's flow compilable and walkable: it confirms a full-deck plan in
//  authored order. Exact seam signature preserved:
//  SessionBuilderView(deck:onConfirm:onCancel:) with onConfirm: (SessionPlan) -> Void.
//

import SwiftUI

struct SessionBuilderView: View {

    let deck: Deck
    let onConfirm: (SessionPlan) -> Void
    let onCancel: () -> Void

    @State private var startPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Tonight's shape")
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textPrimary)
                Text("\(deck.orderedCards.count) \(deck.orderedCards.count == 1 ? "card" : "cards") · authored order")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.top, AppSpacing.sm)        // grabber (in .vaylSheet) supplies the top gap

            Spacer(minLength: 0)

            // PLAN16-SECTION3 replaces this stub body with the real builder UI.
            Text("The full builder arrives with the next pass. For now, tonight runs the whole deck.")
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onConfirm(SessionPlan(
                    deckId: deck.id,
                    cardIds: deck.orderedCards.map(\.id),
                    perCardTimerSeconds: nil,
                    globalTimerSeconds: nil,
                    deckVariant: nil
                ))
            } label: {
                Text("Start session")
                    .font(AppFonts.ctaLabel)
                    .foregroundStyle(AppColors.textBody)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            .strokeBorder(AppColors.spectrumBorder, lineWidth: 1.2)
                    )
            }
            .buttonStyle(.plain)
            .scaleEffect(startPressed ? 0.97 : 1.0)
            .sensoryFeedback(.impact(weight: .light), trigger: startPressed)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onCancel()
            } label: {
                Text("Not tonight")
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.xl)
    }
}
