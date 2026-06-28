// Vayl/Features/Settings/SettingsPrivacyView.swift

import SwiftUI

struct SettingsPrivacyView: View {
    @Environment(\.dismiss)            private var dismiss

    @AppStorage("screenshotProtectionEnabled")
    private var screenshotProtection: Bool = true

    @State private var shareCapacity: Bool = true

    var body: some View {
        SettingsSubScreenShell(title: "Privacy & safety", onBack: { dismiss() }) {
            SettingsSectionLabel(text: "Screen protection")
            SettingsCard {
                SettingsToggleRow(
                    icon: "eye.slash.fill",
                    label: "Screenshot protection",
                    subtitle: "Hides sensitive screens from recordings.",
                    iconTint: AppColors.safetyAccent,
                    iconBg: AppColors.safetyAccent.opacity(0.10),
                    isOn: $screenshotProtection
                )
            }

            SettingsSectionLabel(text: "Sharing")
            SettingsCard {
                SettingsToggleRow(
                    icon: "waveform.path.ecg",
                    label: "Share capacity with partner",
                    subtitle: "Your partner sees your Pulse capacity, not your answers.",
                    iconTint: AppColors.accentPrimary,
                    iconBg: AppColors.accentPrimary.opacity(0.10),
                    isOn: Binding(
                        get: { shareCapacity },
                        set: { newVal in
                            shareCapacity = newVal
                            Task { await PulseSyncService.shared.setSharing(newVal) }
                        }
                    )
                )
            }
        }
        .task { shareCapacity = await PulseSyncService.shared.fetchSharing() }
    }
}
