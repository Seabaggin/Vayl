// Vayl/Features/Settings/SettingsComponents.swift

import SwiftUI

// MARK: - SettingsSectionLabel

struct SettingsSectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(AppFonts.overline)
            .tracking(2)
            .foregroundStyle(AppColors.textSectionLabel)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, AppSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - SettingsSubSectionLabel

/// Whisper-level label used inside a SettingsCard to separate sub-groups
/// (e.g. "About you", "Relationship" within a larger card).
struct SettingsSubSectionLabel: View {
    let text: String
    /// Use true when this label is the first item in a card — reduces top padding.
    var isFirst: Bool = false

    var body: some View {
        Text(text.uppercased())
            .font(AppFonts.overline)
            .tracking(1.5)
            .foregroundStyle(AppColors.textMuted)
            .padding(.top, isFirst ? AppSpacing.xxs : AppSpacing.sm + AppSpacing.xs)
            .padding(.bottom, AppSpacing.xxs)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - SettingsNavRow

/// A navigation row with icon badge, label (+ optional subtitle), optional trailing value, and chevron.
/// Wrap in a `Button` or `NavigationLink(value:)` — this view is layout only.
struct SettingsNavRow: View {
    let icon: String
    let label: String
    var subtitle: String? = nil
    var value: String? = nil
    var labelColor: Color = AppColors.textPrimary
    var iconTint: Color = AppColors.textSecondary
    var iconBg: Color = AppColors.glassSurface
    var showChevron: Bool = true

    var body: some View {
        HStack(spacing: AppSpacing.sm + AppSpacing.xs) {
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .fill(iconBg)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(iconTint)
                        .accessibilityHidden(true)
                )
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(label)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(labelColor)
                if let sub = subtitle {
                    Text(sub)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }

            Spacer()

            if let val = value {
                Text(val)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, AppSpacing.sm + AppSpacing.xs)
    }
}

// MARK: - SettingsToggleRow

struct SettingsToggleRow: View {
    let icon: String
    let label: String
    var subtitle: String? = nil
    var iconTint: Color = AppColors.textSecondary
    var iconBg: Color = AppColors.glassSurface
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: AppSpacing.sm + AppSpacing.xs) {
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .fill(iconBg)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(iconTint)
                        .accessibilityHidden(true)
                )
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(label)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                if let sub = subtitle {
                    Text(sub)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }

            Spacer()

            Toggle(label, isOn: $isOn)
                .labelsHidden()
                .tint(AppColors.accentPrimary)
        }
        .padding(.vertical, AppSpacing.sm + AppSpacing.xs)
    }
}
