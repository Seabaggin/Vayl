// Features/Learn/Views/Sections/ContentHubSection.swift
//
// Section 3 — Content Hub. STUB: a segmented control (Books / Watch /
// Listen / Voices); Voices carries a Creators ⇄ Researchers filter.
// Magenta hairline.

import SwiftUI

struct ContentHubSection: View {
    let store: LearnStore

    @State private var tab: HubTab = .books
    @State private var voiceFilter: VoiceKind = .creator

    enum HubTab: String, CaseIterable, Identifiable {
        case books = "Books", watch = "Watch", listen = "Listen", voices = "Voices"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHairline(color: AppColors.spectrumMagenta)
            Text("CONTENT HUB")
                .font(AppFonts.overline)
                .tracking(1.5)
                .foregroundStyle(AppColors.textSecondary)

            Picker("", selection: $tab) {
                ForEach(HubTab.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            switch tab {
            case .books:  list(store.media(.book).map(\.title))
            case .watch:  list(store.media(.show).map(\.title))
            case .listen: list(store.media(.podcast).map(\.title))
            case .voices: voicesPanel
            }
        }
    }

    private var voicesPanel: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Picker("", selection: $voiceFilter) {
                Text("Creators").tag(VoiceKind.creator)
                Text("Researchers").tag(VoiceKind.researcher)
            }
            .pickerStyle(.segmented)
            list(store.voices(voiceFilter).map(\.name))
        }
    }

    private func list(_ titles: [String]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(titles, id: \.self) { title in
                HStack {
                    Text(title)
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(AppColors.textTertiary)
                }
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .fill(AppColors.cardBackground)
                        .overlay(RoundedRectangle(cornerRadius: AppRadius.lg)
                            .stroke(AppColors.spectrumMagenta.opacity(0.16), lineWidth: 1))
                )
            }
        }
    }
}

#Preview {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ContentHubSection(store: LearnStore()).padding()
    }
}
