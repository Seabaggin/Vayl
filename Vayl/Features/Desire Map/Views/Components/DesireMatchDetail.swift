//
//  DesireMatchDetail.swift
//  Vayl
//
//  The shared card body for a single desire match.
//  Used by DesireStarDetailSheet (screen 7) and DesireMapListSheet (screen 9).
//
//  Carries NO raw partner answers — the read path is alignment-only (RevealMatch).
//

import SwiftUI

struct DesireMatchDetail: View {

    let match: RevealMatch
    /// Called when the user taps "Talk about this". Stub — stub action in S1.3.
    var onTalkTapped: (() -> Void)? = nil
    /// Called when the user taps "Explore in Learn". Stub — stub action in S1.3.
    var onLearnTapped: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Category overline
            if let cat = match.itemCategory {
                Text(cat.uppercased())
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.textTertiary)
                    .tracking(1.0)
            }

            // Item name
            Text(match.itemName)
                .font(AppFonts.sectionHeading)
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // Alignment badge
            alignmentBadge
                .padding(.top, AppSpacing.xxs)

            // Couple-framed meaning line (falls back to the generic celebration line)
            Text(match.displayMeaning)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, AppSpacing.xxs)

            // Divider
            SpectrumHairline()
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xs)

            // CTAs — the mockup's d-talk is a filled gradient button, not a text row.
            VaylButton(
                label: "Talk about this →",
                style: .primary,
                size: .fullWidth,
                action: { onTalkTapped?() }
            )
            .frame(height: VaylButtonSize.fullWidth.height)

            // Learn link renders only when wired. Until Learn can deep-link to a desire
            // term, the reveal/list pass `onLearnTapped: nil`, so it stays hidden rather
            // than showing a dead "Explore X in Learn" control.
            if let onLearnTapped {
                Button {
                    onLearnTapped()
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        // Fix #6: interpolate the item name to match the mockup ("Explore "X" in Learn").
                        Text("Explore \u{201C}\(match.itemName)\u{201D} in Learn")
                            .font(AppFonts.bodyText)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(DetailPressStyle())
            }
        }
    }

    // MARK: - Badge

    private var alignmentBadge: some View {
        HStack(spacing: AppSpacing.xs) {
            Circle()
                .fill(badgeColor)
                .frame(width: 5, height: 5)
            Text(badgeText)
                .font(AppFonts.caption)
                .foregroundStyle(badgeColor)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs)
        .background(Capsule().fill(badgeColor.opacity(0.12)))
        .overlay(Capsule().stroke(badgeColor.opacity(0.30), lineWidth: 1))
    }

    private var badgeColor: Color {
        switch match.alignment {
        case .mutual:   return AppColors.spectrumMagenta
        case .adjacent: return AppColors.spectrumPurple
        case .none:     return AppColors.textTertiary
        }
    }

    private var badgeText: String {
        switch match.alignment {
        case .mutual:   return "You both want this"
        case .adjacent: return "Worth exploring"
        case .none:     return "Shared"
        }
    }
}

// MARK: - Press style (file-local)

struct DetailPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(AppAnimation.fast, value: configuration.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Mutual match") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        DesireMatchDetail(match: .sample("New Relationship Energy", .mutual))
            .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}

#Preview("Adjacent match") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        DesireMatchDetail(
            match: .sample("Overnight Stays With Others", .adjacent, category: "logistics")
        )
        .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
#endif
