//
//  CompositionConfirmCard.swift
//  Vayl
//
//  Spec §9 one-tap confirm, shown on the pairing linked screen when a
//  composition proposal derives. Display only — PairingStore decides.
//  Copy is wayfinding (which card wordings the couple will see),
//  never a statement about either person.
//

import SwiftUI

struct CompositionConfirmCard: View {

    let proposal: GenderDynamic
    let showsError: Bool
    let onConfirm: () -> Void
    let onKeepFlexible: () -> Void

    @State private var flexiblePressed = false

    /// Wayfinding: which card wording the couple will see. Never a statement
    /// about either person.
    private var wordingLine: String {
        switch proposal {
        case .mf:       return "worded for a man and a woman"
        case .mm:       return "worded for two men"
        case .ff:       return "worded for two women"
        case .flexible: return "kept flexible"   // unreachable: flexible never proposes
        }
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            VStack(spacing: AppSpacing.sm) {
                Text("One thing about your cards")
                    .font(AppFonts.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Some session cards come in a few wordings. Based on what you each shared, yours can be \(wordingLine).")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VaylButton(label: "Use that wording") {
                onConfirm()
            }
            .frame(height: VaylButtonSize.fullWidth.height)

            if showsError {
                Text("That didn't save. Check your connection and tap again.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.destructive)
                    .multilineTextAlignment(.center)
            }

            Button {
                onKeepFlexible()
            } label: {
                Text("Keep it flexible")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .contentShape(Rectangle())
            }
            .scaleEffect(flexiblePressed ? 0.96 : 1.0)
            .sensoryFeedback(.impact(weight: .light), trigger: flexiblePressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in flexiblePressed = true }
                    .onEnded { _ in flexiblePressed = false }
            )

            Text("You can change this anytime in Settings.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.container)
                .fill(AppColors.whisperFill)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.container)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    // 0.4 matches the active-state stroke the sibling
                                    // pairing surfaces use (PairingJoinView codeInputField).
                                    AppColors.accentPrimary.opacity(0.4),
                                    AppColors.accentSecondary.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
    }
}

#if DEBUG
#Preview {
    ZStack {
        AppColors.void.ignoresSafeArea()
        CompositionConfirmCard(proposal: .mf, showsError: false, onConfirm: {}, onKeepFlexible: {})
            .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
#endif
