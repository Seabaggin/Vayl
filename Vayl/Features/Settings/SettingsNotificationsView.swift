// Vayl/Features/Settings/SettingsNotificationsView.swift

import SwiftUI
import UserNotifications

struct SettingsNotificationsView: View {
    var onClose: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @AppStorage("notificationsCheckInReminder") private var checkInReminder: Bool = false
    @AppStorage("notificationsPartnerActivity") private var partnerActivity: Bool = false
    @AppStorage("notificationsDiscreetMode")    private var discreetMode: Bool = false

    @State private var showPermissionDeniedAlert = false

    var body: some View {
        SettingsSubScreenShell(title: "Notifications", onBack: {
            if let onClose { onClose() } else { dismiss() }
        }) {
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
        .onChange(of: checkInReminder) { _, enabled in
            if enabled { requestPermission(onDenied: { checkInReminder = false }) }
        }
        .onChange(of: partnerActivity) { _, enabled in
            if enabled { requestPermission(onDenied: { partnerActivity = false }) }
        }
        .alert("Notifications are off", isPresented: $showPermissionDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Allow notifications for Vayl in System Settings to enable this.")
        }
    }

    private func requestPermission(onDenied: @escaping () -> Void) {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                break
            case .denied:
                await MainActor.run {
                    onDenied()
                    showPermissionDeniedAlert = true
                }
            case .notDetermined:
                // iOS 26: `.alert` authorization option is banned — request sound + badge
                // only and set the banner presentation style in the notification delegate
                // (same posture as PushService.requestAuthorizationAndRegister).
                let granted = (try? await center.requestAuthorization(options: [.sound, .badge])) ?? false
                if !granted {
                    await MainActor.run {
                        onDenied()
                        showPermissionDeniedAlert = true
                    }
                }
            @unknown default:
                break
            }
        }
    }
}
