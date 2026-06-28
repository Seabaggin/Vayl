// Vayl/Features/Settings/SettingsNotificationsView.swift

import SwiftUI

struct SettingsNotificationsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("notificationsCheckInReminder") private var checkInReminder: Bool = true
    @AppStorage("notificationsPartnerActivity") private var partnerActivity: Bool = true
    @AppStorage("notificationsDiscreetMode")    private var discreetMode: Bool = false

    var body: some View {
        SettingsSubScreenShell(title: "Notifications", onBack: { dismiss() }) {
            SettingsSectionLabel(text: "Reminders")
            SettingsCard {
                VStack(spacing: 0) {
                    SettingsToggleRow(
                        icon: "bell.badge.fill",
                        label: "Check-in reminder",
                        subtitle: "Weekly nudge to log your Pulse.",
                        iconTint: AppColors.spectrumPurple,
                        iconBg: AppColors.spectrumPurple.opacity(0.10),
                        isOn: $checkInReminder
                    )

                    Divider().overlay(AppColors.borderSubtle)

                    SettingsToggleRow(
                        icon: "person.2.fill",
                        label: "Partner activity",
                        subtitle: "When your partner completes the Desire Map.",
                        iconTint: AppColors.spectrumCyan,
                        iconBg: AppColors.spectrumCyan.opacity(0.10),
                        isOn: $partnerActivity
                    )
                }
            }

            SettingsSectionLabel(text: "Privacy")
            SettingsCard {
                SettingsToggleRow(
                    icon: "eye.slash",
                    label: "Discreet mode",
                    subtitle: "Notification previews never mention Vayl by name.",
                    iconTint: AppColors.safetyAccent,
                    iconBg: AppColors.safetyAccent.opacity(0.10),
                    isOn: $discreetMode
                )
            }
        }
    }
}
