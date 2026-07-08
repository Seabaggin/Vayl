// Vayl/Features/Settings/SettingsIdentityView.swift

import SwiftUI
import SwiftData

struct SettingsIdentityView: View {
    let store: SettingsStore
    var onClose: (() -> Void)?

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss)     private var dismiss

    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }

    @State private var editField: IdentityField?

    enum IdentityField: Hashable, Identifiable {
        case name, pronouns, experience
        var id: Self { self }
    }

    // Pronouns are stored as [String] on UserProfile — join for display.
    private var pronounsDisplay: String {
        guard let p = profile else { return "Not set" }
        let joined = p.pronouns.joined(separator: ", ")
        return joined.isEmpty ? "Not set" : joined
    }

    var body: some View {
        SettingsSubScreenShell(title: "You", onBack: {
            if let onClose { onClose() } else { dismiss() }
        }) {
            SettingsSectionLabel(text: "Identity")
            SettingsCard {
                VStack(spacing: 0) {
                    Button {
                        editField = .name
                    } label: {
                        SettingsNavRow(
                            icon: "person.fill",
                            label: "Name",
                            value: profile?.displayName.isEmpty == false
                                ? profile?.displayName
                                : (appState.displayName.isEmpty ? nil : appState.displayName)
                        )
                    }
                    .buttonStyle(PressableCardStyle())

                    Divider().overlay(AppColors.borderSubtle)

                    Button {
                        editField = .pronouns
                    } label: {
                        SettingsNavRow(
                            icon: "quote.bubble",
                            label: "Pronouns",
                            value: pronounsDisplay == "Not set" ? nil : pronounsDisplay
                        )
                    }
                    .buttonStyle(PressableCardStyle())

                    Divider().overlay(AppColors.borderSubtle)

                    Button {
                        editField = .experience
                    } label: {
                        SettingsNavRow(
                            icon: "sparkles",
                            label: "Experience",
                            value: profile?.nmStage.displayName ?? NMStage.curious.displayName
                        )
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
        }
        .vaylSheet(
            isPresented: Binding(
                get: { editField != nil },
                set: { if !$0 { editField = nil } }
            ),
            heightFraction: 0.5
        ) {
            if let field = editField {
                IdentityEditSheet(field: field, profile: profile, store: store) {
                    editField = nil
                }
            }
        }
    }
}

// MARK: - Edit sheet

private struct IdentityEditSheet: View {
    let field: SettingsIdentityView.IdentityField
    let profile: UserProfile?
    let store: SettingsStore
    /// Closes the presenting `.vaylSheet` (a custom overlay — `dismiss()` has no
    /// presentation to act on here, so the owner collapses `editField` instead).
    var onDone: () -> Void

    @State private var text: String = ""
    @State private var selectedStage: NMStage = .curious

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            OnboardingAtmosphere(config: .stat).ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                switch field {
                case .name:
                    editTextField(label: "Display name", placeholder: "Your name")
                case .pronouns:
                    editTextField(label: "Pronouns", placeholder: "e.g. she/her, they/them")
                case .experience:
                    experiencePicker
                }
                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)
        }
        .overlay(alignment: .bottom) {
            HStack {
                Button("Cancel") { onDone() }
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(AppColors.textTertiary)
                    .buttonStyle(PressableCardStyle())
                Spacer()
                Button("Save") { commit() }
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(AppColors.accentPrimary)
                    .buttonStyle(PressableCardStyle())
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .onAppear { loadCurrentValue() }
    }

    private func editTextField(label: String, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(label)
                .font(AppFonts.overline)
                .tracking(2)
                .foregroundStyle(AppColors.textSectionLabel)
            TextField(placeholder, text: $text)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textPrimary)
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .fill(AppColors.glassSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
                )
        }
    }

    private var experiencePicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Experience")
                .font(AppFonts.overline)
                .tracking(2)
                .foregroundStyle(AppColors.textSectionLabel)
            ForEach(NMStage.allCases, id: \.self) { stage in
                Button {
                    selectedStage = stage
                } label: {
                    HStack {
                        Text(stage.displayName)
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        if selectedStage == stage {
                            Image(systemName: AppIcons.checkmarkCircle)
                                .foregroundStyle(AppColors.spectrumCyan)
                                .accessibilityHidden(true)
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .fill(selectedStage == stage
                                  ? AppColors.spectrumCyan.opacity(0.10)
                                  : AppColors.glassSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
                    )
                }
                .buttonStyle(PressableCardStyle())
            }
        }
    }

    private func loadCurrentValue() {
        switch field {
        case .name:
            text = profile?.displayName ?? ""
        case .pronouns:
            // Pronouns stored as [String] — present as comma-space joined for editing.
            text = profile?.pronouns.joined(separator: ", ") ?? ""
        case .experience:
            selectedStage = profile?.nmStage ?? .curious
        }
    }

    private func commit() {
        let storeField: SettingsStore.IdentityField
        switch field {
        case .name:       storeField = .name
        case .pronouns:   storeField = .pronouns
        case .experience: storeField = .experience
        }
        store.saveIdentity(field: storeField, rawText: text, stage: selectedStage)
        onDone()
    }
}
