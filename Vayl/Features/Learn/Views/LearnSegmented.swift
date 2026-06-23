// Features/Learn/Views/LearnSegmented.swift
//
// The Learn-tab segmented control (replaces native `.pickerStyle(.segmented)`,
// which doesn't match the void/spectrum aesthetic). A glass track holds equal
// segments; the active segment lifts on an accent-tinted pill. Supports an
// optional SF Symbol above the label (content-hub tabs) or label-only (the
// Voices Creators/Researchers filter). Mirrors `.hub-tabs` in the mockup.

import SwiftUI

struct LearnSegmented<Value: Hashable>: View {
    struct Item: Identifiable {
        var id: Value { value }   // identity is the value — stable across rebuilds
        let value: Value
        let label: String
        let icon: String?
        init(_ value: Value, _ label: String, icon: String? = nil) {
            self.value = value; self.label = label; self.icon = icon
        }
    }

    let items: [Item]
    @Binding var selection: Value
    var accent: Color = AppColors.spectrumMagenta

    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            ForEach(items) { item in
                let on = selection == item.value
                Button { withAnimation(AppAnimation.standard) { selection = item.value } } label: {
                    VStack(spacing: AppSpacing.xs) {
                        if let icon = item.icon {
                            Image(systemName: icon)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(on ? accent : AppColors.textSecondary)
                        }
                        Text(item.label)
                            .font(AppFonts.buttonLabelSmall)
                            .foregroundStyle(on ? AppColors.textPrimary : AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .fill(on ? accent.opacity(0.16) : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableCardStyle())
            }
        }
        .padding(AppSpacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .fill(Color.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(AppColors.borderSubtle, lineWidth: 1))
        )
    }
}
