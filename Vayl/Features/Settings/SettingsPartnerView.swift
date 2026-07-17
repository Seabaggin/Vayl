// Vayl/Features/Settings/SettingsPartnerView.swift

import SwiftUI
import SwiftData

struct SettingsPartnerView: View {
    let store: SettingsStore
    var onClose: (() -> Void)?

    @Environment(AppState.self)        private var appState
    @Environment(CoupleContext.self)   private var coupleContext
    @Environment(\.modelContext)       private var modelContext
    @Environment(\.dismiss)            private var dismiss

    /// Pairing sheets are presented by SettingsView (the screen root), NOT here.
    /// This view is itself `.vaylSheet` content, and a `.vaylSheet` anchors to
    /// the view it's attached to — presenting from here would size the pairing
    /// sheets to THIS sheet's bounds, not the screen.
    var onInvite: () -> Void = {}
    var onJoin: () -> Void = {}

    @State private var showUnlink: Bool = false

    var body: some View {
        SettingsSubScreenShell(title: "Partner", onBack: {
            if let onClose { onClose() } else { dismiss() }
        }) {
            if appState.linkState == .linked {
                linkedContent
            } else {
                soloContent
            }
        }
        .task {
            await coupleContext.refreshIfNeeded()
        }
        .confirmationDialog(
            "Unlink partner?",
            isPresented: $showUnlink,
            titleVisibility: .visible
        ) {
            Button("Unlink", role: .destructive) {
                Task { await store.unlink() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(store.unlinkWarning)
        }
    }

    // MARK: - Linked state

    private var partnerHeadline: String {
        guard let name = coupleContext.partnerName, !name.isEmpty else { return "Paired" }
        return "Paired with \(name)"
    }

    private var partnerInitial: String {
        guard let name = coupleContext.partnerName, let first = name.first else { return "•" }
        return String(first).uppercased()
    }

    private var linkedContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionLabel(text: "Connected")
            SettingsCard {
                HStack(spacing: AppSpacing.md) {
                    PartnerAvatarView(initial: partnerInitial, size: 32)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text(partnerHeadline)
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        Text(coupleContext.pairedSince.map { "Since \($0.formatted(date: .long, time: .omitted))" } ?? "Linked")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    Spacer()
                }
                .padding(.vertical, AppSpacing.sm)
            }

            SettingsSectionLabel(text: "Actions")
            SettingsCard {
                Button {
                    showUnlink = true
                } label: {
                    HStack {
                        Text("Unlink partner")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.destructive)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, AppSpacing.sm)
                }
                .buttonStyle(PressableCardStyle())
            }
        }
    }

    // MARK: - Solo state

    private var soloContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionLabel(text: "Pair with a partner")
            SettingsCard {
                VStack(spacing: 0) {
                    Button {
                        onInvite()
                    } label: {
                        SettingsNavRow(
                            icon: "envelope.fill",
                            label: "Invite my partner",
                            iconTint: AppColors.spectrumCyan,
                            iconBg: AppColors.spectrumCyan.opacity(0.10)
                        )
                    }
                    .buttonStyle(PressableCardStyle())

                    Divider().overlay(AppColors.borderSubtle)

                    Button {
                        onJoin()
                    } label: {
                        SettingsNavRow(
                            icon: "link.badge.plus",
                            label: "I have a partner code",
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
    let entitlements = EntitlementStore(modelContainer: .previewContainerWithProfile, appState: appState)
    VaylSheetPreviewHost(heightFraction: 0.92) {
        SettingsPartnerView(store: previewSettingsStore(appState))
    }
    .environment(appState)
    .environment(CoupleContext(appState: appState, entitlements: entitlements, modelContainer: .previewContainerWithProfile))
    .modelContainer(.previewContainerWithProfile)
}
#endif
