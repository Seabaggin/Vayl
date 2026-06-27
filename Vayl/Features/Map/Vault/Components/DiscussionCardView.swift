//
//  DiscussionCardView.swift
//  Vayl
//
//  Renders a companion discussion card: the desire item name as context above,
//  then a ConversationCard showing the tier-appropriate prompt.
//  Hosted as a .vaylSheet from VaultSheet. Never forked -- reuses ConversationCard.
//

import SwiftUI

struct DiscussionCardView: View {

    let card: CompanionCard
    var onDismiss: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Context header
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("Talk about this")
                    .font(AppFonts.overline)
                    .tracking(1.0)
                    .foregroundStyle(AppColors.textTertiary)
                Text(card.title)
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)

            // Prompt card
            ConversationCard(
                content: .prompt(card.prompt),
                fuseConfig: .none,
                ghostDeckMode: .none,
                onContinue: onDismiss
            )
            .padding(.horizontal, AppSpacing.md)

            Spacer(minLength: AppSpacing.lg)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.void.ignoresSafeArea())
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Mutual prompt") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        DiscussionCardView(
            card: CompanionCard(
                id: "preview-mutual",
                desireItemId: "desire-001",
                title: "New Relationship Energy",
                prompt: "What part of this feels most exciting to you?",
                suggestedDeckId: nil
            )
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Consent opened prompt") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        DiscussionCardView(
            card: CompanionCard(
                id: "preview-consent",
                desireItemId: "desire-007",
                title: "Overnight Stays",
                prompt: "No rush here. Where would you want to start?",
                suggestedDeckId: nil
            )
        )
    }
    .preferredColorScheme(.dark)
}
#endif
