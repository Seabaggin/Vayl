// Vayl/Features/Settings/SettingsCompositionView.swift
//
// Spec §9: the couple can change their card wording anytime. Four options,
// one checkmark, writes through SettingsStore → PairingService RPC.
// Copy is wayfinding (how cards are phrased), never a label on either person.

import SwiftUI

struct SettingsCompositionView: View {

    let store: SettingsStore
    var onClose: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SettingsSubScreenShell(title: "Card wording", onBack: {
            if let onClose { onClose() } else { dismiss() }
        }) {
            Text("Some session cards come in a few phrasings. Pick the one that fits how you two want your cards to read.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.sm)

            SettingsCard {
                VStack(spacing: 0) {
                    ForEach(GenderDynamic.allCases, id: \.self) { option in
                        Button {
                            Task { await store.setComposition(option) }
                        } label: {
                            HStack(spacing: AppSpacing.sm + AppSpacing.xs) {
                                Text(option.settingsLabel)
                                    .font(AppFonts.bodyMedium)
                                    .foregroundStyle(AppColors.textPrimary)
                                Spacer()
                                if store.composition == option {
                                    Image(systemName: AppIcons.checkmark)
                                        .font(AppFonts.bodyMedium)
                                        .foregroundStyle(AppColors.accentPrimary)
                                        .accessibilityHidden(true)
                                }
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical, AppSpacing.sm + AppSpacing.xs)
                        }
                        .buttonStyle(PressableCardStyle())
                        .sensoryFeedback(.impact(weight: .light), trigger: store.composition)
                        .accessibilityAddTraits(store.composition == option ? .isSelected : [])

                        if option != GenderDynamic.allCases.last {
                            Divider().overlay(AppColors.borderSubtle)
                        }
                    }
                }
            }

            Text("This only changes how those cards are phrased. It is not a label on either of you.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.top, AppSpacing.sm)
        }
        .task { await store.loadComposition() }
    }
}

// MARK: - Human labels (D5 wording — settings-facing, distinct from the
// terser GenderDynamic.displayName used elsewhere)

extension GenderDynamic {
    var settingsLabel: String {
        switch self {
        case .mf:       return "Man and woman"
        case .mm:       return "Two men"
        case .ff:       return "Two women"
        case .flexible: return "Flexible, experience based"
        }
    }
}

#if DEBUG
#Preview {
    let state = AppState()
    return SettingsCompositionView(
        store: SettingsStore(
            modelContainer: .previewContainer,
            appState: state,
            authService: AuthService(),
            entitlements: EntitlementStore(modelContainer: .previewContainer, appState: state)
        )
    )
    .preferredColorScheme(.dark)
}
#endif
