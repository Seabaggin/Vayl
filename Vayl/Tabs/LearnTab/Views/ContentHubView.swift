// Tabs/LearnTab/Views/ContentHubView.swift
//
// The screen behind Learn's content-hub door: books, watch, listen, voices.
//
// Learn's two bodies are the cited first-party reference (findings + glossary,
// which IS the tab) and this third-party media. Different provenance, different
// job, so the hub gets its own screen rather than competing for the tab's body.
//
// Chrome matches ResearchDatabaseView: a cover with a back affordance, dismissed
// via `\.vaylDismiss(confirm: false)` — leaving a browse screen has no consequence
// to confirm.

import SwiftUI

struct ContentHubView: View {
    let store: LearnStore

    @Environment(\.vaylDismiss) private var vaylDismiss

    var body: some View {
        ZStack {
            AppColors.pageBackground.ignoresSafeArea()
            OnboardingAtmosphere(config: .stat).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    backButton
                    header
                    ContentHubSection(store: store)
                }
                .padding(AppSpacing.lg)
            }
            .scrollTopEdgeFade()
        }
    }

    private var backButton: some View {
        Button { vaylDismiss(confirm: false) } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: AppIcons.chevronLeft)
                Text("Learn")
            }
            .font(AppFonts.buttonLabel)
            .foregroundStyle(AppColors.textSecondary)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableCardStyle())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("The content hub")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text("Books, shows, podcasts, and people worth following")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
    }
}

#Preview {
    ContentHubView(store: LearnStore())
}
