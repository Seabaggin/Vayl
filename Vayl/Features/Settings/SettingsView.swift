// Vayl/Features/Settings/SettingsView.swift

import SwiftUI
import SwiftData

// MARK: - Route enum

enum SettingsRoute: Hashable {
    case you
    case privacy
    case notifications
    case appearance
    case partner
}

// MARK: - Main view

struct SettingsView: View {
    @Environment(AppState.self)         private var appState
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(AuthService.self)      private var authService
    @Environment(\.dismiss)             private var dismiss

    @State private var showSignOutConfirm:  Bool = false
    @State private var showDeleteConfirm:   Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.void.ignoresSafeArea()
                OnboardingAtmosphere(config: .stat).ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        settingsHeader
                        membershipCard
                        partnerCard
                        SettingsSectionLabel(text: "Preferences")
                        preferencesCard
                        SettingsSectionLabel(text: "Account")
                        accountCard
                        footerLinks
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .you:           SettingsIdentityView()
                case .privacy:       SettingsPrivacyView()
                case .notifications: SettingsNotificationsView()
                case .appearance:    SettingsAppearanceView()
                case .partner:       SettingsPartnerView()
                }
            }
            .confirmationDialog("Sign out?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                Button("Sign out", role: .destructive) {
                    Task { await authService.signOut() }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Delete account?", isPresented: $showDeleteConfirm) {
                Button("Delete everything", role: .destructive) {
                    // Full deletion deferred to V1.1 — requires server-side cleanup
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your data and cannot be undone.")
            }
        }
    }

    // MARK: - Header

    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text("Settings")
                    .font(AppFonts.overline)
                    .tracking(2)
                    .foregroundStyle(AppColors.textSectionLabel)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(AppColors.glassSurface))
                }
                .buttonStyle(PressableCardStyle())
                .accessibilityLabel("Close settings")
            }
            .padding(.top, AppSpacing.md)

            Text(appState.displayName.isEmpty ? "You." : "\(appState.displayName).")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.top, AppSpacing.xs)
        }
    }

    // MARK: - Membership

    @ViewBuilder
    private var membershipCard: some View {
        if entitlements.isCore {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.spectrumCyan)
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Vayl Lifetime")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Full access, forever.")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                Spacer()
                Button("Restore") {
                    // Not wired in V1 — restore StoreKit purchase
                }
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.accentPrimary)
                    .buttonStyle(PressableCardStyle())
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(AppColors.spectrumCyan.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
            )
            .padding(.top, AppSpacing.md)
        } else {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.spectrumPurple)
                    Text("Vayl Lifetime")
                        .font(AppFonts.overline)
                        .tracking(1.5)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Text("$24.99 once")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                Text("Unlock every deck and the full Desire Map.")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                HStack {
                    Button("Restore purchase") {
                        // Not wired in V1 — restore StoreKit purchase
                    }
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .buttonStyle(PressableCardStyle())
                    Spacer()
                    Button("Upgrade") {
                        // Not wired in V1 — open paywall
                    }
                        .font(AppFonts.buttonLabel)
                        .foregroundStyle(AppColors.spectrumPurple)
                        .buttonStyle(PressableCardStyle())
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(LinearGradient(
                        colors: [
                            AppColors.spectrumCyan.opacity(0.07),
                            AppColors.spectrumPurple.opacity(0.10),
                            AppColors.spectrumMagenta.opacity(0.07)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
            )
            .padding(.top, AppSpacing.md)
        }
    }

    // MARK: - Partner card

    private var partnerCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionLabel(text: "Partner")
            SettingsCard {
                NavigationLink(value: SettingsRoute.partner) {
                    if appState.linkState == .linked {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(AppColors.spectrumCyan)
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: AppRadius.sm)
                                        .fill(AppColors.spectrumCyan.opacity(0.10))
                                )
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                Text("Linked")
                                    .font(AppFonts.bodyMedium)
                                    .foregroundStyle(AppColors.textPrimary)
                                Text("Paired account")
                                    .font(AppFonts.caption)
                                    .foregroundStyle(AppColors.textTertiary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(AppColors.textTertiary)
                                .accessibilityHidden(true)
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, AppSpacing.sm)
                    } else {
                        SettingsNavRow(
                            icon: "person.badge.plus",
                            label: "Invite a partner",
                            iconTint: AppColors.spectrumCyan,
                            iconBg: AppColors.spectrumCyan.opacity(0.10)
                        )
                    }
                }
                .buttonStyle(PressableCardStyle())
            }
        }
    }

    // MARK: - Preferences card (4 nav rows)

    private var preferencesCard: some View {
        SettingsCard {
            VStack(spacing: 0) {
                NavigationLink(value: SettingsRoute.you) {
                    SettingsNavRow(
                        icon: "person.circle",
                        label: "You",
                        value: appState.displayName.isEmpty ? nil : appState.displayName,
                        iconTint: AppColors.spectrumCyan,
                        iconBg: AppColors.spectrumCyan.opacity(0.10)
                    )
                }
                .buttonStyle(PressableCardStyle())

                Divider().overlay(AppColors.borderSubtle)

                NavigationLink(value: SettingsRoute.privacy) {
                    SettingsNavRow(
                        icon: "lock.fill",
                        label: "Privacy & safety",
                        iconTint: AppColors.safetyAccent,
                        iconBg: AppColors.safetyAccent.opacity(0.10)
                    )
                }
                .buttonStyle(PressableCardStyle())

                Divider().overlay(AppColors.borderSubtle)

                NavigationLink(value: SettingsRoute.notifications) {
                    SettingsNavRow(
                        icon: "bell.fill",
                        label: "Notifications",
                        iconTint: AppColors.spectrumPurple,
                        iconBg: AppColors.spectrumPurple.opacity(0.10)
                    )
                }
                .buttonStyle(PressableCardStyle())

                Divider().overlay(AppColors.borderSubtle)

                NavigationLink(value: SettingsRoute.appearance) {
                    SettingsNavRow(
                        icon: "paintpalette.fill",
                        label: "Appearance",
                        value: "Midnight",
                        iconTint: AppColors.spectrumMagenta,
                        iconBg: AppColors.spectrumMagenta.opacity(0.10)
                    )
                }
                .buttonStyle(PressableCardStyle())
            }
        }
    }

    // MARK: - Account card

    private var accountCard: some View {
        SettingsCard {
            VStack(spacing: 0) {
                Button {
                    showSignOutConfirm = true
                } label: {
                    HStack {
                        Text("Sign out")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, AppSpacing.sm)
                }
                .buttonStyle(PressableCardStyle())

                Divider().overlay(AppColors.borderSubtle)

                Button {
                    // Export data deferred to V1.1 — requires server-side data export pipeline
                } label: {
                    HStack {
                        Text("Export my data")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppColors.textTertiary)
                            .accessibilityHidden(true)
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, AppSpacing.sm)
                }
                .buttonStyle(PressableCardStyle())

                Divider().overlay(AppColors.borderSubtle)

                Button {
                    showDeleteConfirm = true
                } label: {
                    HStack {
                        Text("Delete account")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.destructive)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppColors.textTertiary)
                            .accessibilityHidden(true)
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, AppSpacing.sm)
                }
                .buttonStyle(PressableCardStyle())
            }
        }
    }

    // MARK: - Footer

    private var footerLinks: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xl) {
                Button("Privacy") {
                    // Not wired in V1 — open privacy URL
                }
                .buttonStyle(PressableCardStyle())
                Button("Terms") {
                    // Not wired in V1 — open terms URL
                }
                .buttonStyle(PressableCardStyle())
                Button("Support") {
                    // Not wired in V1 — open support URL
                }
                .buttonStyle(PressableCardStyle())
            }
            .font(AppFonts.caption)
            .foregroundStyle(AppColors.textTertiary)
            .padding(.top, AppSpacing.lg)

            Text("Vayl · v0.1.0")
                .font(AppFonts.overline)
                .tracking(1)
                .foregroundStyle(AppColors.textMuted)
                .padding(.top, AppSpacing.xs)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Shared sub-screen shell

struct SettingsSubScreenShell<Content: View>: View {
    let title: String
    var onBack: (() -> Void)? = nil
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            OnboardingAtmosphere(config: .stat).ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        onBack?()
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Settings")
                                .font(AppFonts.bodyMedium)
                        }
                        .foregroundStyle(AppColors.textSecondary)
                    }
                    .buttonStyle(PressableCardStyle())
                    .padding(.top, AppSpacing.md)

                    Text(title)
                        .font(AppFonts.screenTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.top, AppSpacing.sm)

                    content
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let state = AppState()
    SettingsView()
        .preferredColorScheme(.dark)
        .environment(state)
        .environment(EntitlementStore(modelContainer: .previewContainer, appState: state))
        .modelContainer(ModelContainer.previewContainer)
}
#endif
