//
//  PulseInfoSheet.swift
//  Vayl
//
//  "About the Pulse" — a short, calm explainer presented as a .vaylSheet
//  (pre-TestFlight review D11). Content-only: the presenting `.vaylSheet`
//  supplies chrome + grabber (same discipline as SessionSettingsSheet).
//  Descriptive, never assessive: it explains the map and the
//  privacy promise, and says nothing about the person reading it.
//

import SwiftUI

struct PulseInfoSheet: View {

    /// The four named quadrant spaces, in reading order, with their static
    /// aura-core dot colours (the same colour the history grid uses).
    private let spaces: [(name: String, space: PulseSpace)] = [
        ("Expansive", .expansive),
        ("Reactive", .reactive),
        ("Receptive", .receptive),
        ("Protective", .protective)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("About the Pulse")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)

                Text("A quick daily check-in. Five questions, answered by feel, place you somewhere on a small map of energy and openness. There's no score and no right answer, just where you are today.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(AppSpacing.xs)
                    .fixedSize(horizontal: false, vertical: true)

                axesSection

                spacesSection

                Text("Your Pulse is yours. If you share it, your partner sees your capacity, not your answers.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(AppSpacing.xs)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Check in when you feel like it. There's no streak to keep.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - The two axes

    private var axesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            axisRow(name: "Charged / Depleted",
                    detail: "how much energy is in your system.")
            axisRow(name: "Guarded / Open",
                    detail: "how much of it is available for connection.")
        }
    }

    private func axisRow(name: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(name)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textPrimary)
            Text(detail)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - The spaces

    private var spacesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Where your answers land gets a name: Expansive, Reactive, Receptive, or Protective, with Neutral and Uncharted for the days that sit between.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineSpacing(AppSpacing.xs)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                ForEach(spaces, id: \.name) { item in
                    HStack(spacing: AppSpacing.sm) {
                        Circle()
                            .fill(item.space.dotCoreStatic)
                            .frame(width: AppSpacing.sm, height: AppSpacing.sm)
                        Text(item.name)
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppColors.void.ignoresSafeArea()
        PulseInfoSheet()
    }
    .preferredColorScheme(.dark)
}
