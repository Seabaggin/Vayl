//
//  DesireAnswerPill.swift
//  Vayl
//

import SwiftUI

/// Desire Map's answer-selection row — the "Card Weight" treatment approved 2026-07-04
/// (docs/prototypes/desire-map-final-mockup.html). Replaces `_RaterPill`.
///
/// Deliberately its own component, not a `SelectablePill` variant: SelectablePill is a
/// centered single-label capsule with no icon/hint slot and no per-instance accent color.
/// Retrofitting Option C onto it would mean rewriting internals three other screens
/// (onboarding, settings) already depend on.
///
/// The selected-state color is derived from `weight` itself, not passed in by the caller —
/// this is the fix for the shipped bug where every row tinted the same hardcoded
/// magenta/purple regardless of which answer was actually chosen.
struct DesireAnswerPill: View {
    let label: String
    let hint: String
    let weight: DesireRatingValue
    let isSelected: Bool
    let action: () -> Void

    /// "Not for me" always shows the private-answer lock, never the confirm checkmark —
    /// matches the existing app's `isBoundary` behavior (the reassuring checkmark never
    /// appears on the one answer whose whole point is that it stays private).
    private var isPrivateAnswer: Bool { weight == .notForMe }

    /// The row's own spectrum color. `.probablyNot` ("nervous") has no hue in the mockup —
    /// it's white-based, dimmed via opacity at each usage site below.
    private var accent: Color {
        switch weight {
        case .excitedAboutIt: return AppColors.spectrumCyan
        case .openToIt:       return AppColors.spectrumPurple
        case .probablyNot:    return .white
        case .notForMe:       return AppColors.spectrumMagenta
        }
    }

    /// Contrast color for text/icons drawn on top of a filled `accent` circle.
    private var onAccent: Color {
        weight == .probablyNot ? AppColors.void : .white
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .top) {
                // Top sheen — faint highlight cap, clipped to the row's rounded corners below.
                LinearGradient(colors: [.white.opacity(0.05), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 18)

                HStack(spacing: AppSpacing.md) {
                    orb
                    Text(label)
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(isSelected ? AppColors.textBright : AppColors.textSecondary)
                    Spacer(minLength: 0)
                    trailing
                }
                .padding(.horizontal, AppSpacing.md)
            }
            .frame(height: 62)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(accent.opacity(0.10)) : AnyShapeStyle(AppColors.whisperFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .stroke(isSelected ? accent.opacity(0.5) : AppColors.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
            .shadow(color: isSelected ? accent.opacity(0.35) : .clear, radius: 13, y: 10)
            .offset(y: isSelected ? -3 : 0)
            .animation(AppAnimation.spring, value: isSelected)
        }
        .buttonStyle(_AnswerPressStyle())
    }

    private var orb: some View {
        ZStack {
            Circle()
                .fill(accent)
                .frame(width: 17, height: 17)
                .blur(radius: 6)
                .opacity(0.7)
            Circle()
                .fill(.white)
                .frame(width: 7, height: 7)
        }
        .frame(width: 17, height: 17)
    }

    @ViewBuilder
    private var trailing: some View {
        if isPrivateAnswer {
            Image(systemName: "lock.fill")
                .font(AppFonts.meta)
                .foregroundStyle(AppColors.textTertiary.opacity(0.6))
        } else if isSelected {
            ZStack {
                Circle().fill(accent).frame(width: 23, height: 23)
                Image(systemName: "checkmark")
                    .font(AppFonts.meta)
                    .foregroundStyle(onAccent)
            }
            .transition(.scale.combined(with: .opacity))
        } else if !hint.isEmpty {
            Text(hint)
                .font(AppFonts.meta)
                .foregroundStyle(AppColors.textTertiary)
                .transition(.opacity)
        }
    }
}

// MARK: - Press style

private struct _AnswerPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(AppAnimation.fast, value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Answer pills — all four states") {
    VStack(spacing: AppSpacing.sm) {
        DesireAnswerPill(label: "Yes — that excites me", hint: "i want this", weight: .excitedAboutIt, isSelected: true) {}
        DesireAnswerPill(label: "I'm curious to try it", hint: "i'm curious", weight: .openToIt, isSelected: false) {}
        DesireAnswerPill(label: "I'm nervous about it", hint: "not right now", weight: .probablyNot, isSelected: false) {}
        DesireAnswerPill(label: "Not for me", hint: "", weight: .notForMe, isSelected: false) {}
    }
    .padding(AppSpacing.lg)
    .background(AppColors.void)
    .preferredColorScheme(.dark)
}
