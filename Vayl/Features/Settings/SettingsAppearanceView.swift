// Vayl/Features/Settings/SettingsAppearanceView.swift

import SwiftUI

struct SettingsAppearanceView: View {
    var onClose: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @AppStorage("hapticFeedbackEnabled") private var hapticFeedback: Bool = true

    var body: some View {
        SettingsSubScreenShell(title: "Appearance", onBack: {
            if let onClose { onClose() } else { dismiss() }
        }) {
            SettingsSectionLabel(text: "Theme")
            SettingsCard {
                // Dark-only in Act 1: theme is fixed to Midnight.
                // When light/system mode ships, replace with a picker.
                HStack {
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .fill(AppColors.spectrumMagenta.opacity(0.10))
                        .overlay(
                            Image(systemName: "moon.fill")
                                .font(AppFonts.bodyMedium)
                                .foregroundStyle(AppColors.spectrumMagenta)
                                .accessibilityHidden(true)
                        )
                        .frame(width: 32, height: 32)
                    Text("Midnight")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Text("Dark only · Act 1")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textMuted)
                }
                .padding(.vertical, AppSpacing.sm)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Theme: Midnight, dark only")
            }

            SettingsSectionLabel(text: "Feel")
            SettingsCard {
                SettingsToggleRow(
                    icon: "waveform",
                    label: "Haptic feedback",
                    subtitle: "Feel interactions through vibration.",
                    iconTint: AppColors.accentSecondary,
                    iconBg: AppColors.accentSecondary.opacity(0.10),
                    isOn: $hapticFeedback
                )
            }
        }
    }
}
