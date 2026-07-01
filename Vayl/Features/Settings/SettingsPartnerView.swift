// Vayl/Features/Settings/SettingsPartnerView.swift

import SwiftUI
import SwiftData

struct SettingsPartnerView: View {
    let store: SettingsStore
    var onClose: (() -> Void)? = nil

    @Environment(AppState.self)        private var appState
    @Environment(\.modelContext)       private var modelContext
    @Environment(\.dismiss)            private var dismiss

    @State private var showInvite:  Bool = false
    @State private var showJoin:    Bool = false
    @State private var showUnlink:  Bool = false

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
        .vaylSheet(isPresented: $showInvite, heightFraction: 0.92) {
            PairingInviteView(
                store: PairingStore(
                    modelContainer: modelContext.container,
                    appState: appState
                )
            )
            .environment(appState)
        }
        .vaylSheet(isPresented: $showJoin, heightFraction: 0.92) {
            PairingJoinView(
                store: PairingStore(
                    modelContainer: modelContext.container,
                    appState: appState
                )
            )
            .environment(appState)
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
            Text("You each keep your own answers, but shared things like your Desire Map matches are removed. You can pair again anytime.")
        }
    }

    // MARK: - Linked state

    private var linkedContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionLabel(text: "Connected")
            SettingsCard {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "person.2.fill")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.spectrumCyan)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.sm)
                                .fill(AppColors.spectrumCyan.opacity(0.10))
                        )
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text("Paired account")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        Text("Linked")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.success)
                        .accessibilityLabel("Linked")
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
                        showInvite = true
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
                        showJoin = true
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
