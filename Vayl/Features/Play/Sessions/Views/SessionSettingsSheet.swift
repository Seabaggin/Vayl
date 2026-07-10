//
//  SessionSettingsSheet.swift
//  Vayl
//
//  The chest cog's two-knob sheet: who reads first, and length/pace.
//  Content-only — the presenting `.vaylSheet` supplies chrome + grabber.
//  Mirrors the SettingsIdentityView option-row pattern (tokens only).
//

import SwiftUI

struct SessionSettingsSheet: View {
    @Binding var reader: SessionSettings.Reader
    @Binding var length: SessionSettings.Length
    /// For the "Partner" reader label; falls back to "Partner" if empty.
    var partnerName: String
    var onDone: () -> Void

    private var partnerLabel: String {
        partnerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Partner"
            : partnerName
    }

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            OnboardingAtmosphere(config: .stat).ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.xl) {
                        header

                        readerGroup

                        lengthGroup
                    }
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xl)
                }

                VaylButton(label: "Done", size: .compact) { onDone() }
            }
            .padding(AppSpacing.lg)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Session settings")
                .font(AppFonts.cardTitleCompact)
                .foregroundStyle(AppColors.textPrimary)
            Text("Just the two knobs that matter tonight.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    // MARK: - Who reads first

    private var readerGroup: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            groupLabel("WHO READS FIRST")
            optionRow(title: "You", isSelected: reader == .you) { reader = .you }
            optionRow(title: partnerLabel, isSelected: reader == .partner) { reader = .partner }
            optionRow(title: "Let it decide", isSelected: reader == .either) { reader = .either }
        }
    }

    // MARK: - Length & pace

    private var lengthGroup: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            groupLabel("LENGTH & PACE")
            optionRow(title: "Short  ~10 min", isSelected: length == .short) { length = .short }
            optionRow(title: "Full  ~20 min", isSelected: length == .full) { length = .full }
            optionRow(title: "Unhurried  no cap", isSelected: length == .unhurried) { length = .unhurried }

            Text("Sets a gentle timer on the session, a soft nudge near the end, never a hard stop. Unhurried adds no timer.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
    }

    // MARK: - Building blocks

    private func groupLabel(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.overline)
            .tracking(2)
            .foregroundStyle(AppColors.textSectionLabel)
    }

    private func optionRow(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: AppIcons.checkmarkCircle)
                        .foregroundStyle(AppColors.spectrumCyan)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(isSelected
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

// MARK: - Preview

#Preview("Session Settings") {
    struct Wrapper: View {
        @State private var reader: SessionSettings.Reader = .you
        @State private var length: SessionSettings.Length = .full
        var body: some View {
            ZStack {
                AppColors.void.ignoresSafeArea()
                SessionSettingsSheet(
                    reader: $reader,
                    length: $length,
                    partnerName: "Alex",
                    onDone: {}
                )
            }
        }
    }
    return Wrapper().preferredColorScheme(.dark)
}
