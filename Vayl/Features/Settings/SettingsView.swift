// Vayl/Features/Settings/SettingsView.swift

import SwiftUI
import SwiftData

// MARK: - Main view

struct SettingsView: View {

    @Environment(AppState.self)          private var appState
    @Environment(EntitlementStore.self)  private var entitlements
    @Environment(AuthStore.self)         private var auth
    @Environment(\.dismiss)             private var dismiss
    @Environment(\.modelContext)         private var modelContext

    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }

    /// Built in .onAppear — the Store needs the environment container + appState +
    /// authService, which aren't available in a property initializer.
    @State private var store: SettingsStore?

    // Sub-screen navigation
    @State private var showYou: Bool = false
    @State private var showPrivacy: Bool = false
    @State private var showNotifications: Bool = false
    @State private var showAppearance: Bool = false
    @State private var showPartner: Bool = false
    @State private var showComposition: Bool = false

    // Sheet / dialog state
    @State private var showUnlink: Bool = false
    @State private var showSignOutConfirm: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var legalDoc: LegalDoc?

    var body: some View {
        GeometryReader { geo in
            let layout = AppLayout.from(geo)
            ZStack {
                AppColors.void.ignoresSafeArea()
                OnboardingAtmosphere(config: .stat).ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        settingsHeader
                        youSection
                        partnerSection
                        appSection
                        accountSection
                        aboutSection
                        membershipCard
                        versionLabel
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .frame(width: layout.screenWidth)
            .onAppear {
                if store == nil {
                    // Store composition — the service crosses from AuthStore into
                    // SettingsStore's initializer here; the view itself never calls it.
                    store = SettingsStore(
                        modelContainer: modelContext.container,
                        appState: appState,
                        authService: auth.service,
                        entitlements: entitlements
                    )
                }
                Task { await store?.loadComposition() }
            }
            .onChange(of: store?.didLeaveAccount ?? false) { _, left in
                // Close the cover; the root re-routes reactively underneath.
                if left { dismiss() }
            }
            .vaylSheet(isPresented: $showYou, heightFraction: 0.92, screenHeight: layout.screenHeight) {
                if let store {
                    SettingsIdentityView(store: store, onClose: { showYou = false })
                }
            }
            .vaylSheet(isPresented: $showPrivacy, heightFraction: 0.92, screenHeight: layout.screenHeight) {
                if let store {
                    SettingsPrivacyView(store: store, onClose: { showPrivacy = false })
                }
            }
            .vaylSheet(isPresented: $showNotifications, heightFraction: 0.92, screenHeight: layout.screenHeight) {
                if let store {
                    SettingsNotificationsView(store: store, onClose: { showNotifications = false })
                }
            }
            .vaylSheet(isPresented: $showAppearance, heightFraction: 0.92, screenHeight: layout.screenHeight) {
                SettingsAppearanceView(onClose: { showAppearance = false })
            }
            .vaylSheet(isPresented: $showPartner, heightFraction: 0.92, screenHeight: layout.screenHeight) {
                if let store {
                    SettingsPartnerView(store: store, onClose: { showPartner = false })
                }
            }
            .vaylSheet(isPresented: $showComposition, heightFraction: 0.5, screenHeight: layout.screenHeight) {
                if let store {
                    SettingsCompositionView(store: store, onClose: { showComposition = false })
                }
            }
            .confirmationDialog("Unlink partner?", isPresented: $showUnlink, titleVisibility: .visible) {
                Button("Unlink", role: .destructive) {
                    Task { await store?.unlink() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(store?.unlinkWarning ?? "")
            }
            .confirmationDialog("Sign out?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                Button("Sign out", role: .destructive) {
                    Task { await store?.signOut() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You can sign back in anytime with the same Apple ID.")
            }
            .alert("Delete your account?", isPresented: $showDeleteConfirm) {
                Button("Delete account", role: .destructive) {
                    Task { await store?.deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your profile, your Desire Map answers, and your sessions. If you have a partner, they keep their own data and return to being unpaired. This cannot be undone.")
            }
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { if case .error = store?.accountPhase { return true } else { return false } },
                    set: { _ in store?.clearError() }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                if case .error(let message) = store?.accountPhase { Text(message) }
            }
            .vaylSafariSheet(item: $legalDoc) { $0.url }
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
                    Image(systemName: AppIcons.close)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(AppColors.glassSurface))
                }
                .buttonStyle(PressableCardStyle())
                .accessibilityLabel("Close settings")
            }
            .padding(.top, AppSpacing.md)

            Text(appState.displayName.isEmpty ? "Settings." : "\(appState.displayName).")
                .font(AppFonts.screenTitle)
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.top, AppSpacing.xs)
                .padding(.bottom, AppSpacing.sm)
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
            .padding(.vertical, AppSpacing.xxs + 3)
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
            .padding(.vertical, AppSpacing.xxs + 3)
            .background(
                Capsule()
                    .fill(AppColors.glassSurface)
                    .overlay(Capsule().strokeBorder(AppColors.borderSubtle, lineWidth: 1))
            )
    }

    // MARK: - Membership

    @ViewBuilder
    private var membershipCard: some View {
        SettingsSectionLabel(text: "Membership")
        if entitlements.isCore {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: AppIcons.checkmarkCircle)
                    .font(AppFonts.bodyMedium)
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
        } else {
            Button {
                // Not wired in V1 — open paywall
            } label: {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: AppIcons.sparkles)
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.spectrumPurple)
                            .accessibilityHidden(true)
                        Text("Vayl · Lifetime")
                            .font(AppFonts.overline)
                            .tracking(2)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Text("Unlock every deck and the full Desire Map.")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)

                    Text("\(Text("$24.99").font(AppFonts.bodyMedium.bold()).foregroundStyle(AppColors.textPrimary))\(Text("  once · yours to keep").font(AppFonts.caption).foregroundStyle(AppColors.textTertiary))")
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PressableCardStyle())
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
            .overlay(alignment: .top) { premiumHairline }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.container))
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

    private var premiumHairline: some View {
        let gradient = LinearGradient(
            colors: [.clear, AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta, .clear],
            startPoint: .leading, endPoint: .trailing
        )
        return ZStack(alignment: .top) {
            gradient.frame(height: 8).blur(radius: 5).opacity(0.55)
            gradient.frame(height: 1)
        }
    }

    // MARK: - You

    private var youSection: some View {
        Button { showYou = true } label: {
            HStack(spacing: AppSpacing.md) {
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(AppColors.glassSurface)
                    .overlay(
                        Image(systemName: AppIcons.personFill)
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textSecondary)
                            .accessibilityHidden(true)
                    )
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Profile")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)

                    let sub = [
                        profile?.pronouns.isEmpty == false ? profile?.pronouns.joined(separator: "/") : nil
                    ].compactMap { $0 }.joined(separator: " · ")
                    if !sub.isEmpty {
                        Text(sub)
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    } else {
                        Text("Tap to complete your profile")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textMuted)
                    }
                }

                Spacer()

                Image(systemName: AppIcons.chevronRight)
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(AppSpacing.md)
        }
        .buttonStyle(PressableCardStyle())
        .vaylGlassCard(radius: AppRadius.container)
        .overlay(alignment: .top) { spectrumTopLine }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.container))
    }

    // MARK: - Partner

    private var partnerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionLabel(text: "Partner")
            SettingsCard {
                if appState.linkState == .linked {
                    VStack(spacing: 0) {
                        Button { showPartner = true } label: {
                            SettingsNavRow(
                                icon: "person.2.fill",
                                label: "Linked",
                                subtitle: "Add relationship details"
                            )
                        }
                        .buttonStyle(PressableCardStyle())

                        Divider().overlay(AppColors.borderSubtle)

                        Button { showComposition = true } label: {
                            SettingsNavRow(
                                icon: "text.bubble",
                                label: "Card wording",
                                subtitle: "How some session cards are phrased",
                                value: (store?.composition ?? .flexible).settingsLabel
                            )
                        }
                        .buttonStyle(PressableCardStyle())

                        Divider().overlay(AppColors.borderSubtle)

                        Button { showUnlink = true } label: {
                            SettingsNavRow(
                                icon: "person.badge.minus",
                                label: "Unlink partner",
                                labelColor: AppColors.destructive,
                                iconTint: AppColors.destructive,
                                iconBg: AppColors.destructive.opacity(0.09)
                            )
                        }
                        .buttonStyle(PressableCardStyle())
                    }
                } else {
                    Button { showPartner = true } label: {
                        SettingsNavRow(
                            icon: "person.badge.plus",
                            label: "Invite a partner",
                            subtitle: "Share a code or enter one to link your apps"
                        )
                    }
                    .buttonStyle(PressableCardStyle())
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
                    Button { showPrivacy = true } label: {
                        SettingsNavRow(icon: "lock.fill", label: "Privacy & safety")
                    }
                    .buttonStyle(PressableCardStyle())

                    Divider().overlay(AppColors.borderSubtle)

                    Button { showNotifications = true } label: {
                        SettingsNavRow(icon: "bell.fill", label: "Notifications")
                    }
                    .buttonStyle(PressableCardStyle())

                    Divider().overlay(AppColors.borderSubtle)

                    Button { showAppearance = true } label: {
                        SettingsNavRow(icon: "paintpalette.fill", label: "Appearance")
                    }
                    .buttonStyle(PressableCardStyle())
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
                        SettingsNavRow(icon: "rectangle.portrait.and.arrow.right", label: "Sign out")
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
                    Button { legalDoc = .privacy } label: {
                        SettingsNavRow(icon: "hand.raised.fill", label: "Privacy policy")
                    }
                    .buttonStyle(PressableCardStyle())

                    Divider().overlay(AppColors.borderSubtle)

                    Button { legalDoc = .terms } label: {
                        SettingsNavRow(icon: "doc.text.fill", label: "Terms of service")
                    }
                    .buttonStyle(PressableCardStyle())

                    Divider().overlay(AppColors.borderSubtle)

                    Button {} label: {
                        SettingsNavRow(icon: "questionmark.circle.fill", label: "Support")
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
    var onBack: (() -> Void)?
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
                            Image(systemName: AppIcons.chevronLeft)
                                .font(AppFonts.caption)
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
        .environment(AuthStore())
        .modelContainer(ModelContainer.previewContainer)
}
#endif
