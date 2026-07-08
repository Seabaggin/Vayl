//
//  RitualPills.swift
//  Vayl
//
//  Two optional centering rituals, offered before the lock-in — friction as
//  care, never required. Breathe together resets the body; one good thing
//  resets the mood. Tapping the active pill again clears the selection.
//

import SwiftUI

enum Ritual {
    case breathe
    case goodThing
}

struct RitualPills: View {

    @Binding var selected: Ritual?

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            pill(for: .breathe, label: "Breathe together") { breatheGlyph }
            pill(for: .goodThing, label: "One good thing") { goodThingGlyph }
        }
    }

    @ViewBuilder
    private func pill<Glyph: View>(
        for ritual: Ritual, label: String, @ViewBuilder glyph: () -> Glyph
    ) -> some View {
        let isOn = selected == ritual
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(AppAnimation.fast) {
                selected = isOn ? nil : ritual
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                glyph()
                    .frame(width: 18, height: 18)
                Text(label)
                    .font(AppFonts.caption)
                    .foregroundStyle(isOn ? AppColors.textPrimary : AppColors.textSecondary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(isOn ? AppColors.spectrumCyan.opacity(0.10) : AppColors.glassSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(isOn ? AppColors.spectrumCyan.opacity(0.4) : AppColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(PressableCardStyle())
    }

    private var breatheGlyph: some View {
        ZStack {
            Circle().stroke(AppColors.spectrumCyan.opacity(0.35), lineWidth: 1.2)
            Circle().stroke(AppColors.spectrumCyan.opacity(0.6), lineWidth: 1.2).scaleEffect(0.62)
            Circle().fill(AppColors.spectrumCyan).scaleEffect(0.24)
        }
    }

    private var goodThingGlyph: some View {
        ZStack {
            Image(systemName: "arrow.up")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(AppColors.spectrumMagenta)
                .offset(x: 4, y: -1)
            Text("1")
                .font(AppFonts.display(11, weight: .bold, relativeTo: .caption2))
                .foregroundStyle(AppColors.spectrumMagenta)
                .offset(x: -3, y: 2)
        }
    }
}

// MARK: - Preview

#Preview("Ritual Pills") {
    struct Wrapper: View {
        @State private var selected: Ritual? = nil
        var body: some View {
            ZStack {
                AppColors.void.ignoresSafeArea()
                RitualPills(selected: $selected).padding(AppSpacing.lg)
            }
        }
    }
    return Wrapper().preferredColorScheme(.dark)
}
