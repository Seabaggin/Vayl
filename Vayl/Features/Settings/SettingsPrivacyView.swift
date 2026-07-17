// Vayl/Features/Settings/SettingsPrivacyView.swift

import SwiftUI
import SwiftData

struct SettingsPrivacyView: View {
    let store: SettingsStore
    var onClose: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @AppStorage("screenshotProtectionEnabled")
    private var screenshotProtection: Bool = true

    @AppStorage("shareCapacityWithPartner")
    private var shareCapacity: Bool = true

    var body: some View {
        SettingsSubScreenShell(title: "Privacy & safety", onBack: {
            if let onClose { onClose() } else { dismiss() }
        }) {
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
                    isOn: $shareCapacity
                )
            }
        }
        .onChange(of: shareCapacity) { _, newValue in
            store.setShareCapacity(newValue)
        }
    }
}

#if DEBUG
@MainActor
private func previewSettingsStore(_ appState: AppState) -> SettingsStore {
    SettingsStore(
        modelContainer: .previewContainerWithProfile,
        appState: appState,
        authService: AuthService(),
        entitlements: EntitlementStore(modelContainer: .previewContainerWithProfile, appState: appState)
    )
}

#Preview("In rail") {
    let appState = AppState()
    VaylSheetPreviewHost(heightFraction: 0.92) {
        SettingsPrivacyView(store: previewSettingsStore(appState))
    }
    .environment(appState)
    .modelContainer(.previewContainerWithProfile)
}
#endif
