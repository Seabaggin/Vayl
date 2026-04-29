//
//  SettingsView.swift
//  Vayl
//

import SwiftUI

struct SettingsView: View {

    // MARK: - State

    @State private var partnerName: String = ""
    @State private var pairingCode: String = "AX7-QM2"
    @State private var showPairingCopied: Bool = false
    @State private var showResetConfirm: Bool = false
    @State private var showExportSheet: Bool = false
    @AppStorage("screenshotProtectionEnabled") private var screenshotProtection: Bool = true
    @State private var hapticFeedback: Bool = true
    @State private var navigateToThemePicker: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    header
                    NavigationLink(destination: PairingSettingsView()) {
                        HStack {
                            Image(systemName: "heart.circle.fill")
                                .foregroundStyle(.pink)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pair with Partner")
                                    .fontWeight(.medium)
                                Text("Connect your accounts to play together")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    profileSection
                    partnerSection
                    appearanceSection
                    privacySection
                    dataSection
                    dangerZone
                    appInfo
                    #if DEBUG
                    DebugLogoutView()
                    #endif
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .background(AppColors.pageBg.ignoresSafeArea())
            .if(screenshotProtection) { $0.screenshotProtected() }
            .alert("Reset All Data?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset Everything", role: .destructive) {
                    #if DEBUG
                    print("[Settings] Reset all data")
                    #endif
                }
            } message: {
                Text("This will permanently delete all sessions, ratings, and progress. This cannot be undone.")
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        Text("Settings")
            .font(AppFonts.screenTitle)
            .foregroundColor(AppColors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Profile

    private var profileSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader("PROFILE")
                InteractiveField(
                    placeholder: "Your name",
                    icon: "person.fill",
                    text: $partnerName
                )
            }
        }
    }

    // MARK: - Partner Pairing

    private var partnerSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader("PARTNER PAIRING")
                Text("Share this code with your partner so they can link their app to yours.")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
                HStack(spacing: 12) {
                    Text(pairingCode)
                        .font(AppFonts.scoreDisplay)
                        .foregroundColor(AppColors.cyan)
                        .kerning(2)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = pairingCode
                        withAnimation { showPairingCopied = true }
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            withAnimation { showPairingCopied = false }
                        }
                    } label: {
                        Image(systemName: showPairingCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(showPairingCopied ? AppColors.success : AppColors.textSecondary)
                    }
                }
                .padding(14)
                .cardStyle(background: AppColors.surfaceBg, cornerRadius: 10)
                InteractiveField(
                    placeholder: "Enter partner's code",
                    icon: "link",
                    text: .constant("")
                )
                GradientButton(title: "Link Partner") {
                    #if DEBUG
                    print("[Settings] Link partner tapped")
                    #endif
                }
            }
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader("APPEARANCE")
                Button {
                    navigateToThemePicker = true
                } label: {
                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.purple)
                        Text("Theme")
                            .font(AppFonts.bodyMedium)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Text("Midnight")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textMuted)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.textMuted)
                    }
                    .padding(.vertical, 4)
                }
                SpectrumBar()
                ToggleRow(
                    icon: "waveform",
                    iconColor: AppColors.magenta,
                    label: "Haptic Feedback",
                    isOn: $hapticFeedback
                )
            }
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader("PRIVACY")
                ToggleRow(
                    icon: "eye.slash.fill",
                    iconColor: AppColors.gold,
                    label: "Screenshot Protection",
                    isOn: $screenshotProtection
                )
                Text("When enabled, sensitive screens are hidden from screenshots and screen recordings.")
                    .font(AppFonts.meta)
                    .foregroundColor(AppColors.textMuted)
            }
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader("DATA")
                CriticalButton(title: "Export My Data", icon: "square.and.arrow.up", style: .neutral) {
                    showExportSheet = true
                }
            }
        }
    }

    // MARK: - Danger Zone

    private var dangerZone: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader("DANGER ZONE")
                CriticalButton(title: "Reset All Data", icon: "trash.fill", style: .neutral) {
                    showResetConfirm = true
                }
            }
        }
    }

    // MARK: - App Info

    private var appInfo: some View {
        VStack(spacing: 6) {
            Text("Vayl")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textMuted)
            Text("v0.1.0")
                .font(AppFonts.meta)
                .foregroundColor(AppColors.textMuted)
        }
        .padding(.top, 8)
    }
}

// MARK: - Debug Logout

#if DEBUG
struct DebugLogoutView: View {
    @Environment(AuthService.self) private var authService
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    var body: some View {
        Button("⚠️ DEV: Log Out & Reset Onboarding") {
            Task {
                await authService.signOut()
                hasCompletedOnboarding = false
            }
        }
        .foregroundColor(.red)
        .padding()
    }
}
#endif

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
        .environment(AuthService())
}
