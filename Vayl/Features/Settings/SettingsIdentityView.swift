// Vayl/Features/Settings/SettingsIdentityView.swift

import SwiftUI
import SwiftData

struct SettingsIdentityView: View {
    @Environment(AppState.self)     private var appState
    @Environment(\.modelContext)    private var context
    @Environment(\.dismiss)         private var dismiss

    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }

    @State private var editField: IdentityField? = nil

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
        SettingsSubScreenShell(title: "You", onBack: { dismiss() }) {
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
        .sheet(item: $editField) { field in
            IdentityEditSheet(field: field, profile: profile, context: context) {
                if let name = profile?.displayName, !name.isEmpty {
                    appState.displayName = name
                }
            }
        }
    }
}

// MARK: - Edit sheet

private struct IdentityEditSheet: View {
    let field: SettingsIdentityView.IdentityField
    let profile: UserProfile?
    let context: ModelContext
    var onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var text: String = ""
    @State private var selectedStage: NMStage = .curious

    var body: some View {
        NavigationStack {
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
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .bottom) {
                HStack {
                    Button("Cancel") { dismiss() }
                        .font(AppFonts.buttonLabel)
                        .foregroundStyle(AppColors.textTertiary)
                        .buttonStyle(PressableCardStyle())
                    Spacer()
                    Button("Save") {
                        save()
                        onSave()
                        dismiss()
                    }
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(AppColors.accentPrimary)
                    .buttonStyle(PressableCardStyle())
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .presentationDetents([.medium])
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
                            Image(systemName: "checkmark.circle.fill")
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

    private func save() {
        guard let p = profile else { return }
        switch field {
        case .name:
            let trimmed = text.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty { p.displayName = trimmed }
        case .pronouns:
            let trimmed = text.trimmingCharacters(in: .whitespaces)
            p.pronouns = trimmed.isEmpty ? [] : trimmed
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        case .experience:
            p.nmStage = selectedStage
        }
        try? context.save()
        let capturedField = field
        let capturedStage = selectedStage
        Task {
            switch capturedField {
            case .name, .pronouns:
                await SyncManager.shared.pushDisplayIdentity(localProfile: p)
            case .experience:
                await SyncManager.shared.pushNMStage(capturedStage.rawValue)
            }
        }
    }
}
