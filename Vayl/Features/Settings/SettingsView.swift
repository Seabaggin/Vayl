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
    // TODO: migrate key to UserDefaultsKey.screenshotProtectionEnabled
    @State private var hapticFeedback: Bool = true
    @State private var navigateToThemePicker: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: AppSpacing.xl) {        // was 28 → xl (32), snap per handoff
                    header
                    NavigationLink(destination: PairingSettingsView()) {
                        HStack {
                            Image(AppIcons.heartCircleFill) // was "heart.circle.fill"
                                .foregroundStyle(.pink)
                            VStack(alignment: .leading, spacing: AppSpacing.xxs) { // was 2 → xxs, exact
                                Text("Pair with Partner")
                                    .font(AppFonts.bodyMedium)   // was .fontWeight(.medium) on system font
                                    .foregroundColor(AppColors.textPrimary)
                                Text("Connect your accounts to play together")
                                    .font(AppFonts.caption)      // was .font(.caption) system token
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(AppIcons.chevronRight)     // was "chevron.right"
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, AppSpacing.xs)  // was 4 → xs, exact
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
                .padding(.horizontal, AppSpacing.lg)    // was 20 → lg (24)
                .padding(.top, AppSpacing.md)           // was 16 → md, exact
                .padding(.bottom, AppSpacing.xxl)       // was 40 → xxl (48), snap per handoff
            }
            .background(AppColors.pageBackground.ignoresSafeArea())
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
            VStack(alignment: .leading, spacing: AppSpacing.md) { // was 14 → md (16), snap
                SectionHeader("PROFILE")
                InteractiveField(
                    placeholder: "Your name",
                    icon: "person.fill",            // raw string lives in InteractiveField — migrate there
                    text: $partnerName
                )
            }
        }
    }

    // MARK: - Partner Pairing

    private var partnerSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) { // was 14 → md (16), snap
                SectionHeader("PARTNER PAIRING")
                Text("Share this code with your partner so they can link their app to yours.")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
                HStack(spacing: AppSpacing.sm) {    // was 12 → sm (8), snap per handoff
                    Text(pairingCode)
                        .font(AppFonts.scoreDisplay)
                        .foregroundColor(AppColors.accentPrimary)
                        .kerning(2)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = pairingCode
                        withAnimation(AppAnimation.fast) { // was bare withAnimation
                            showPairingCopied = true
                        }
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            // TODO: replace try? with do/catch per Swift rules
                            withAnimation(AppAnimation.fast) { // was bare withAnimation
                                showPairingCopied = false
                            }
                        }
                    } label: {
                        Image(showPairingCopied ? AppIcons.checkmark : AppIcons.docOnDoc)
                        // was "checkmark" / "doc.on.doc"
                            .font(
                                Font.custom("Switzer-Medium", size: 16, relativeTo: .body)
                            )                       // was .system(size: 16, weight: .medium)
                            .foregroundColor(
                                showPairingCopied ? AppColors.success : AppColors.textSecondary
                            )
                            .frame(minWidth: 44, minHeight: 44) // A11y: min hit target
                    }
                    .accessibilityLabel(showPairingCopied ? "Copied" : "Copy pairing code")
                    .accessibilityAddTraits(.isButton)
                }
                .padding(AppSpacing.md)             // was 14 → md (16), snap
                .cardStyle(
                    background: AppColors.modalBackground,
                    cornerRadius: AppRadius.md      // was 10 → md (12), snap per handoff
                )
                InteractiveField(
                    placeholder: "Enter partner's code",
                    icon: "link",                   // raw string lives in InteractiveField — migrate there
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
            VStack(alignment: .leading, spacing: AppSpacing.md) { // was 14 → md (16), snap
                SectionHeader("APPEARANCE")
                Button {
                    navigateToThemePicker = true
                } label: {
                    HStack {
                        Image(AppIcons.paintpalette) // was "paintpalette.fill"
                            .font(
                                Font.custom("Switzer-Regular", size: 15, relativeTo: .body)
                            )                       // was .system(size: 15)
                            .foregroundColor(AppColors.accentSecondary)
                        Text("Theme")
                            .font(AppFonts.bodyMedium)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Text("Midnight")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textMuted)
                        Image(AppIcons.chevronRight) // was "chevron.right"
                            .font(
                                Font.custom("Switzer-Semibold", size: 12, relativeTo: .caption)
                            )                       // was .system(size: 12, weight: .semibold)
                            .foregroundColor(AppColors.textMuted)
                    }
                    .padding(.vertical, AppSpacing.xs) // was 4 → xs, exact
                }
                .accessibilityLabel("Theme — currently Midnight")
                .accessibilityAddTraits(.isButton)
                SpectrumBar()
                ToggleRow(
                    icon: "waveform",               // raw string lives in ToggleRow — migrate there
                    iconColor: AppColors.accentTertiary,
                    label: "Haptic Feedback",
                    isOn: $hapticFeedback
                )
            }
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) { // was 14 → md (16), snap
                SectionHeader("PRIVACY")
                ToggleRow(
                    icon: "eye.slash.fill",         // raw string lives in ToggleRow — migrate there
                    iconColor: AppColors.safetyAccent,
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
            VStack(alignment: .leading, spacing: AppSpacing.md) { // was 14 → md (16), snap
                SectionHeader("DATA")
                CriticalButton(title: "Export My Data", icon: "square.and.arrow.up", style: .neutral) {
                    // raw string lives in CriticalButton — migrate there
                    showExportSheet = true
                }
            }
        }
    }

    // MARK: - Danger Zone

    private var dangerZone: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) { // was 14 → md (16), snap
                SectionHeader("DANGER ZONE")
                CriticalButton(title: "Reset All Data", icon: "trash.fill", style: .neutral) {
                    // raw string lives in CriticalButton — migrate there
                    showResetConfirm = true
                }
            }
        }
    }

    // MARK: - App Info

    private var appInfo: some View {
        VStack(spacing: AppSpacing.sm) {            // was 6 → sm (8), snap per handoff
            Text("Vayl")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textMuted)
            Text("v0.1.0")
                .font(AppFonts.meta)
                .foregroundColor(AppColors.textMuted)
        }
        .padding(.top, AppSpacing.sm)              // was 8 → sm, exact
    }
}

// MARK: - Debug Logout

#if DEBUG
struct DebugLogoutView: View {
    @Environment(AuthService.self) private var authService
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    // TODO: migrate key to UserDefaultsKey.hasCompletedOnboarding

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
