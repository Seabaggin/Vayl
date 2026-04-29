//
//  PairingSettingsView.swift
//  Vayl
//

import SwiftUI
import SwiftData

struct PairingSettingsView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Navigation

    @State private var showInviteView: Bool = false
    @State private var showJoinView: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                (isLight ? AppColors.lightPageBg : AppColors.pageBg)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // ── Current link state ────────────────────────
                        linkStateSection

                        // ── Actions ───────────────────────────────────
                        if appState.linkState == .unlinked {
                            actionsSection
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Partner Linking")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showInviteView) {
                PairingInviteView(
                    store: PairingStore(
                        modelContainer: modelContext.container,
                        appState: appState
                    )
                )
                .environment(appState)
            }
            .sheet(isPresented: $showJoinView) {
                PairingJoinView(
                    store: PairingStore(
                        modelContainer: modelContext.container,
                        appState: appState
                    )
                )
                .environment(appState)
            }
        }
    }

    // MARK: - Link State Section

    @ViewBuilder
    private var linkStateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STATUS")
                .font(AppFonts.overline)
                .tracking(2)
                .foregroundStyle(isLight ? AppColors.lightTextSecondary : AppColors.textSecondary)

            HStack(spacing: 12) {
                Circle()
                    .fill(appState.linkState == .linked ? AppColors.cyan : AppColors.textTertiary)
                    .frame(width: 10, height: 10)

                Text(appState.linkState == .linked ? "Linked with partner" : "Not linked")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(isLight ? AppColors.lightTextPrimary : AppColors.textPrimary)

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isLight ? AppColors.lightCardFill : AppColors.surfaceBg)
            )

            if let coupleId = appState.coupleId {
                Text("Couple ID: \(coupleId.uuidString.prefix(8))...")
                    .font(AppFonts.caption)
                    .foregroundStyle(isLight ? AppColors.lightTextSecondary : AppColors.textTertiary)
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("LINK WITH PARTNER")
                .font(AppFonts.overline)
                .tracking(2)
                .foregroundStyle(isLight ? AppColors.lightTextSecondary : AppColors.textSecondary)

            // Invite — Person A
            actionCard(
                icon: "person.badge.plus",
                title: "Generate an invite code",
                subtitle: "Share a code with your partner so they can link their app to yours.",
                action: { showInviteView = true }
            )

            // Join — Person B
            actionCard(
                icon: "link",
                title: "Enter a partner's code",
                subtitle: "Your partner has a code — enter it here to link your accounts.",
                action: { showJoinView = true }
            )
        }
    }

    // MARK: - Action Card

    private func actionCard(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AppColors.cyan)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(isLight ? AppColors.lightTextPrimary : AppColors.textPrimary)

                    Text(subtitle)
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight ? AppColors.lightTextSecondary : AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isLight ? AppColors.lightTextSecondary : AppColors.textTertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isLight ? AppColors.lightCardFill : AppColors.surfaceBg)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Unlinked") {
    let state = AppState()
    state.linkState = .unlinked
    return PairingSettingsView()
        .environment(state)
        .preferredColorScheme(.dark)
}

#Preview("Linked") {
    let state = AppState()
    state.linkState = .linked
    state.coupleId = UUID()
    return PairingSettingsView()
        .environment(state)
        .preferredColorScheme(.dark)
}
