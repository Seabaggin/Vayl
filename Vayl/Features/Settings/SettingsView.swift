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
    @Environment(AppState.self)          private var appState
    @Environment(EntitlementStore.self)  private var entitlements
    @Environment(AuthService.self)       private var authService
    @Environment(\.dismiss)             private var dismiss
    @Environment(\.modelContext)         private var modelContext

    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }

    // Inline preference state
    @AppStorage("appLockEnabled")               private var appLock:            Bool = false
    @AppStorage("blurInSwitcherEnabled")         private var blurInSwitcher:      Bool = true
    @AppStorage("screenshotProtectionEnabled")   private var screenshotProtection: Bool = true
    @AppStorage("notificationsCheckInReminder")  private var checkInReminder:     Bool = true
    @AppStorage("notificationsPartnerActivity")  private var partnerNudges:       Bool = true
    @AppStorage("notificationsDiscreetMode")     private var discreetMode:        Bool = false
    @AppStorage("hapticFeedbackEnabled")         private var hapticFeedback:      Bool = true

    // Sheet / dialog state
    @State private var showInvite:          Bool = false
    @State private var showJoin:            Bool = false
    @State private var showUnlink:          Bool = false
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
                        youSection
                        partnerSection
                        appSection
                        accountSection
                        aboutSection
                        versionLabel
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
            .sheet(isPresented: $showInvite) {
                PairingInviteView(store: PairingStore(modelContainer: modelContext.container, appState: appState))
                    .environment(appState)
            }
            .sheet(isPresented: $showJoin) {
                PairingJoinView(store: PairingStore(modelContainer: modelContext.container, appState: appState))
                    .environment(appState)
            }
            .confirmationDialog("Unlink partner?", isPresented: $showUnlink, titleVisibility: .visible) {
                Button("Unlink", role: .destructive) {
                    // Unlink UX deferred to V1.1
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You and your partner will lose access to shared content.")
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
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.top, AppSpacing.xs)

            HStack(spacing: AppSpacing.xs) {
                if let stage = profile?.nmStage {
                    spectrumBadge(stage.displayName)
                }
                plainBadge(appState.linkState == .linked ? "Linked" : "Solo discovery")
            }
            .padding(.top, AppSpacing.xs)
        }
    }

    private func spectrumBadge(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.overline)
            .tracking(1.5)
            .foregroundStyle(
                LinearGradient(
                    colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(AppColors.spectrumPurple.opacity(0.10))
                    .overlay(Capsule().strokeBorder(AppColors.spectrumPurple.opacity(0.32), lineWidth: 1))
            )
    }

    private func plainBadge(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.overline)
            .tracking(1.5)
            .foregroundStyle(AppColors.textSecondary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(AppColors.glassSurface)
                    .overlay(Capsule().strokeBorder(AppColors.borderSubtle, lineWidth: 1))
            )
    }

    // MARK: - Membership

    @ViewBuilder
    private var membershipCard: some View {
        if entitlements.isCore {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.spectrumCyan)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(AppColors.spectrumCyan.opacity(0.12))
                            .overlay(RoundedRectangle(cornerRadius: AppRadius.sm)
                                .strokeBorder(AppColors.spectrumCyan.opacity(0.34), lineWidth: 1))
                    )
                    .accessibilityHidden(true)
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
                    // Not wired in V1
                }
                .font(AppFonts.caption.bold())
                .foregroundStyle(AppColors.spectrumCyan)
                .buttonStyle(PressableCardStyle())
            }
            .padding(AppSpacing.md)
            .vaylGlassCard(accent: AppColors.spectrumCyan, radius: AppRadius.container)
            .overlay(alignment: .top) { spectrumTopLine }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.container))
            .padding(.top, AppSpacing.md)
        } else {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.spectrumPurple)
                        .frame(width: 26, height: 26)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.sm)
                                .fill(AppColors.spectrumPurple.opacity(0.16))
                                .overlay(RoundedRectangle(cornerRadius: AppRadius.sm)
                                    .strokeBorder(AppColors.spectrumPurple.opacity(0.34), lineWidth: 1))
                        )
                        .accessibilityHidden(true)
                    Text("Vayl · Lifetime")
                        .font(AppFonts.overline)
                        .tracking(2)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Text("Unlock every deck and the full Desire Map.")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)

                HStack(alignment: .center) {
                    Group {
                        Text("$24.99")
                            .font(AppFonts.bodyMedium.bold())
                            .foregroundStyle(AppColors.textPrimary)
                        + Text("  once · yours to keep")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    Spacer()
                    Button {
                        // Not wired in V1 — open paywall
                    } label: {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: AppRadius.sm)
                                    .fill(LinearGradient(
                                        colors: [AppColors.spectrumPurple, AppColors.spectrumMagenta],
                                        startPoint: .leading, endPoint: .trailing
                                    ))
                            )
                    }
                    .buttonStyle(PressableCardStyle())
                    .accessibilityLabel("Upgrade to Lifetime")
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
                    .fill(LinearGradient(
                        colors: [
                            AppColors.spectrumCyan.opacity(0.09),
                            AppColors.spectrumPurple.opacity(0.12),
                            AppColors.spectrumMagenta.opacity(0.09)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .vaylGlassCard(radius: AppRadius.container)
            .overlay(alignment: .top) { spectrumTopLine }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.container))
            .padding(.top, AppSpacing.md)
        }
    }

    private var spectrumTopLine: some View {
        LinearGradient(
            colors: [
                .clear,
                AppColors.spectrumCyan.opacity(0.55),
                AppColors.spectrumPurple.opacity(0.5),
                AppColors.spectrumMagenta.opacity(0.55),
                .clear
            ],
            startPoint: .leading, endPoint: .trailing
        )
        .frame(height: 1)
    }

    // MARK: - You

    private var youSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionLabel(text: "You")
            SettingsCard {
                VStack(spacing: 0) {
                    NavigationLink(value: SettingsRoute.you) {
                        SettingsNavRow(
                            icon: "person.circle",
                            label: "Display name",
                            value: appState.displayName.isEmpty ? nil : appState.displayName,
                            iconTint: AppColors.spectrumCyan,
                            iconBg: AppColors.spectrumCyan.opacity(0.10)
                        )
                    }
                    .buttonStyle(PressableCardStyle())

                    Divider().overlay(AppColors.borderSubtle)

                    NavigationLink(value: SettingsRoute.you) {
                        SettingsNavRow(
                            icon: "quote.bubble",
                            label: "Pronouns",
                            value: profile?.pronouns.isEmpty == false
                                ? profile?.pronouns.joined(separator: " / ")
                                : nil,
                            iconTint: AppColors.spectrumPurple,
                            iconBg: AppColors.spectrumPurple.opacity(0.10)
                        )
                    }
                    .buttonStyle(PressableCardStyle())

                    Divider().overlay(AppColors.borderSubtle)

                    NavigationLink(value: SettingsRoute.you) {
                        SettingsNavRow(
                            icon: "stairs",
                            label: "Experience",
                            subtitle: "Shapes the deck and content shown to you",
                            value: profile?.nmStage.displayName,
                            iconTint: AppColors.spectrumMagenta,
                            iconBg: AppColors.spectrumMagenta.opacity(0.10)
                        )
                    }
                    .buttonStyle(PressableCardStyle())

                    SettingsSubSectionLabel(text: "About you")

                    NavigationLink(value: SettingsRoute.you) {
                        SettingsNavRow(
                            icon: "person.crop.rectangle",
                            label: "Age range",
                            iconTint: AppColors.spectrumCyan,
                            iconBg: AppColors.spectrumCyan.opacity(0.10)
                        )
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
        }
    }

    // MARK: - Partner

    private var partnerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionLabel(text: "Partner")
            SettingsCard {
                if appState.linkState == .linked {
                    VStack(spacing: 0) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(AppColors.spectrumCyan)
                                .frame(width: 34, height: 34)
                                .background(
                                    RoundedRectangle(cornerRadius: AppRadius.sm)
                                        .fill(AppColors.spectrumCyan.opacity(0.10))
                                        .overlay(RoundedRectangle(cornerRadius: AppRadius.sm)
                                            .strokeBorder(AppColors.borderSubtle, lineWidth: 1))
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
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColors.success)
                                .accessibilityLabel("Linked")
                        }
                        .padding(.vertical, AppSpacing.xs)

                        SettingsSubSectionLabel(text: "Relationship")

                        NavigationLink(value: SettingsRoute.partner) {
                            SettingsNavRow(
                                icon: "heart.fill",
                                label: "Relationship type",
                                subtitle: "Married, partnered, dating...",
                                iconTint: AppColors.spectrumMagenta,
                                iconBg: AppColors.spectrumMagenta.opacity(0.10)
                            )
                        }
                        .buttonStyle(PressableCardStyle())

                        Divider().overlay(AppColors.borderSubtle)

                        NavigationLink(value: SettingsRoute.partner) {
                            SettingsNavRow(
                                icon: "calendar",
                                label: "Together since",
                                iconTint: AppColors.spectrumPurple,
                                iconBg: AppColors.spectrumPurple.opacity(0.10)
                            )
                        }
                        .buttonStyle(PressableCardStyle())

                        Divider().overlay(AppColors.borderSubtle)

                        Button { showUnlink = true } label: {
                            SettingsNavRow(
                                icon: "link.badge.minus",
                                label: "Unlink partner",
                                labelColor: AppColors.destructive,
                                iconTint: AppColors.destructive,
                                iconBg: AppColors.destructive.opacity(0.09)
                            )
                        }
                        .buttonStyle(PressableCardStyle())
                    }
                } else {
                    VStack(spacing: 0) {
                        Button { showInvite = true } label: {
                            SettingsNavRow(
                                icon: "person.badge.plus",
                                label: "Invite a partner",
                                subtitle: "Share a code to link your apps",
                                iconTint: AppColors.spectrumCyan,
                                iconBg: AppColors.spectrumCyan.opacity(0.10)
                            )
                        }
                        .buttonStyle(PressableCardStyle())

                        Divider().overlay(AppColors.borderSubtle)

                        Button { showJoin = true } label: {
                            SettingsNavRow(
                                icon: "link.badge.plus",
                                label: "Enter a code",
                                iconTint: AppColors.spectrumPurple,
                                iconBg: AppColors.spectrumPurple.opacity(0.10)
                            )
                        }
                        .buttonStyle(PressableCardStyle())
                    }
                }
            }
        }
    }

    // MARK: - App (Privacy, Notifications, Appearance)

    private var appSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionLabel(text: "App")
            SettingsCard {
                VStack(spacing: 0) {

                    // Privacy & safety
                    SettingsSubSectionLabel(text: "Privacy & safety", isFirst: true)
                    SettingsToggleRow(
                        icon: "lock.fill",
                        label: "App lock",
                        subtitle: "Face ID · locks immediately",
                        iconTint: AppColors.safetyAccent,
                        iconBg: AppColors.safetyAccent.opacity(0.09),
                        isOn: $appLock
                    )
                    Divider().overlay(AppColors.borderSubtle)
                    SettingsToggleRow(
                        icon: "eye.slash.fill",
                        label: "Blur in app switcher",
                        iconTint: AppColors.textSecondary,
                        iconBg: AppColors.glassSurface,
                        isOn: $blurInSwitcher
                    )
                    Divider().overlay(AppColors.borderSubtle)
                    SettingsToggleRow(
                        icon: "camera.viewfinder",
                        label: "Screenshot protection",
                        iconTint: AppColors.textSecondary,
                        iconBg: AppColors.glassSurface,
                        isOn: $screenshotProtection
                    )
                    Divider().overlay(AppColors.borderSubtle)
                    Button {} label: {
                        SettingsNavRow(
                            icon: "checklist",
                            label: "Review ground rules",
                            iconTint: AppColors.textSecondary,
                            iconBg: AppColors.glassSurface
                        )
                    }
                    .buttonStyle(PressableCardStyle())

                    // Notifications
                    SettingsSubSectionLabel(text: "Notifications")
                    SettingsToggleRow(
                        icon: "bell.fill",
                        label: "Check-in reminder",
                        subtitle: "Weekly · Sunday evenings",
                        iconTint: AppColors.spectrumPurple,
                        iconBg: AppColors.spectrumPurple.opacity(0.10),
                        isOn: $checkInReminder
                    )
                    Divider().overlay(AppColors.borderSubtle)
                    SettingsToggleRow(
                        icon: "bell.badge.fill",
                        label: "Partner nudges",
                        iconTint: AppColors.spectrumPurple,
                        iconBg: AppColors.spectrumPurple.opacity(0.10),
                        isOn: $partnerNudges
                    )
                    Divider().overlay(AppColors.borderSubtle)
                    SettingsToggleRow(
                        icon: "eye.slash",
                        label: "Discreet mode",
                        subtitle: "Hide content in alerts",
                        iconTint: AppColors.textSecondary,
                        iconBg: AppColors.glassSurface,
                        isOn: $discreetMode
                    )

                    // Appearance
                    SettingsSubSectionLabel(text: "Appearance")
                    Button {} label: {
                        SettingsNavRow(
                            icon: "paintpalette.fill",
                            label: "Theme",
                            value: "Midnight",
                            iconTint: AppColors.spectrumMagenta,
                            iconBg: AppColors.spectrumMagenta.opacity(0.10)
                        )
                    }
                    .buttonStyle(PressableCardStyle())
                    LinearGradient(
                        colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(height: 5)
                    .clipShape(Capsule())
                    .opacity(0.85)
                    .padding(.vertical, AppSpacing.xs)
                    SettingsToggleRow(
                        icon: "waveform",
                        label: "Haptic feedback",
                        subtitle: "Feel interactions through vibration.",
                        iconTint: AppColors.textSecondary,
                        iconBg: AppColors.glassSurface,
                        isOn: $hapticFeedback
                    )
                }
            }
        }
    }

    // MARK: - Account & Data

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionLabel(text: "Account & data")
            SettingsCard {
                VStack(spacing: 0) {
                    Button { showSignOutConfirm = true } label: {
                        SettingsNavRow(
                            icon: "rectangle.portrait.and.arrow.right",
                            label: "Sign out",
                            iconTint: AppColors.textSecondary,
                            iconBg: AppColors.glassSurface
                        )
                    }
                    .buttonStyle(PressableCardStyle())

                    Divider().overlay(AppColors.borderSubtle)

                    Button {} label: {
                        SettingsNavRow(
                            icon: "square.and.arrow.down",
                            label: "Export my data",
                            iconTint: AppColors.textSecondary,
                            iconBg: AppColors.glassSurface
                        )
                    }
                    .buttonStyle(PressableCardStyle())

                    Divider().overlay(AppColors.borderSubtle)

                    Button { showDeleteConfirm = true } label: {
                        SettingsNavRow(
                            icon: "trash.fill",
                            label: "Delete account",
                            labelColor: AppColors.destructive,
                            iconTint: AppColors.destructive,
                            iconBg: AppColors.destructive.opacity(0.09)
                        )
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionLabel(text: "About")
            SettingsCard {
                VStack(spacing: 0) {
                    Button {} label: {
                        SettingsNavRow(
                            icon: "shield.fill",
                            label: "Privacy policy",
                            iconTint: AppColors.textSecondary,
                            iconBg: AppColors.glassSurface
                        )
                    }
                    .buttonStyle(PressableCardStyle())

                    Divider().overlay(AppColors.borderSubtle)

                    Button {} label: {
                        SettingsNavRow(
                            icon: "doc.text.fill",
                            label: "Terms of service",
                            iconTint: AppColors.textSecondary,
                            iconBg: AppColors.glassSurface
                        )
                    }
                    .buttonStyle(PressableCardStyle())

                    Divider().overlay(AppColors.borderSubtle)

                    Button {} label: {
                        SettingsNavRow(
                            icon: "questionmark.circle.fill",
                            label: "Support",
                            iconTint: AppColors.textSecondary,
                            iconBg: AppColors.glassSurface
                        )
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
        }
    }

    // MARK: - Version

    private var versionLabel: some View {
        Text("Vayl · v0.1.0")
            .font(AppFonts.overline)
            .tracking(1)
            .foregroundStyle(AppColors.textMuted)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, AppSpacing.lg)
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
    state.displayName = "Jordan"
    return SettingsView()
        .preferredColorScheme(.dark)
        .environment(state)
        .environment(EntitlementStore(modelContainer: .previewContainer, appState: state))
        .environment(AuthService())
        .modelContainer(ModelContainer.previewContainer)
}
#endif
