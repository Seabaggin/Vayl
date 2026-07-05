// Vayl/Features/Settings/SettingsPartnerView.swift

import SwiftUI
import SwiftData

struct SettingsPartnerView: View {
    let store: SettingsStore
    var onClose: (() -> Void)? = nil

    @Environment(AppState.self)        private var appState
    @Environment(CoupleContext.self)   private var coupleContext
    @Environment(\.modelContext)       private var modelContext
    @Environment(\.dismiss)            private var dismiss

    @State private var showInvite:  Bool = false
    @State private var showJoin:    Bool = false
    @State private var showUnlink:  Bool = false
    @State private var partnerStore: SettingsPartnerStore? = nil

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
        .onAppear {
            if partnerStore == nil {
                partnerStore = SettingsPartnerStore(modelContainer: modelContext.container)
            }
            partnerStore?.loadPairedSince()
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
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.spectrumCyan,
                                        AppColors.spectrumPurple,
                                        AppColors.spectrumMagenta
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                        Text(partnerInitial)
                            .font(AppFonts.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text(partnerHeadline)
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        Text(partnerStore?.pairedSince.map { "Since \($0.formatted(date: .long, time: .omitted))" } ?? "Linked")
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
