//
//  TierGuideSheet.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//


// Design/Components/Pulse/TierGuideSheet.swift
// Open Lightly
//
// Sheet presented when user taps any tier badge on PulseGraph.
// Explains the four capacity tiers — Expansive, Sovereign, Protective, Contracted.
// Presented via .sheet(isPresented:) in PulseGraph.
// Extracted from PulseGraph.swift — rendering math stays there, structural UI lives here.

import SwiftUI

// MARK: - TierGuideSheet

struct TierGuideSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    private let tiers: [(letter: String, name: String, sublabel: String, color: Color, description: String)] = [
        ("E", "Expansive",  "Connected · Adventurous", AppColors.accentTertiary,
         "You have full capacity. Energy is available. A good day to show up fully and go deep."),
        ("S", "Sovereign",  "Grounded · Secure",       AppColors.accentSecondary,
         "Stable ground. You're present and able. Presence without performance is enough."),
        ("P", "Protective", "Anxious · Defensive",     AppColors.accentPrimary,
         "Something's rubbing. That's not wrong — it's information. Protect your energy first."),
        ("C", "Contracted", "Overwhelmed · Closed",    AppColors.textTertiary,
         "Low capacity is valid data. You're not available right now and that's honest."),
    ]

    var body: some View {
        ZStack {
            AppColors.pageBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: AppSpacing.xs) {
                    Text("CAPACITY TIERS")
                        .font(AppFonts.overline)
                        .tracking(2.5)
                        .foregroundStyle(AppColors.textTertiary)
                        .padding(.top, AppSpacing.lg)
                    Text("Your daily state has four zones.")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.bottom, AppSpacing.lg)
                }

                Divider()
                    .background(isLight
                        ? Color.black.opacity(0.07)
                        : Color.white.opacity(0.07))

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(tiers.enumerated()), id: \.offset) { i, tier in
                            HStack(alignment: .top, spacing: AppSpacing.md) {
                                // Letter badge — fixed 32pt circle.
                                // Font fixed at 13pt monospaced — intentional exception.
                                // Dynamic Type would overflow the badge geometry.
                                ZStack {
                                    Circle()
                                        .fill(tier.color.opacity(0.12))
                                        .frame(width: 32, height: 32)
                                        .overlay {
                                            Circle()
                                                .strokeBorder(tier.color.opacity(0.35), lineWidth: 1)
                                        }
                                    Text(tier.letter)
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundStyle(tier.color)
                                }
                                .padding(.top, AppSpacing.xs)

                                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                    Text(tier.name)
                                        .font(AppFonts.bodyMedium)
                                        .foregroundStyle(tier.color)
                                    Text(tier.sublabel)
                                        .font(AppFonts.overline)
                                        .tracking(1.5)
                                        .foregroundStyle(AppColors.textTertiary)
                                    Text(tier.description)
                                        .font(AppFonts.caption)
                                        .foregroundStyle(AppColors.textSecondary)
                                        .lineSpacing(3)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.top, AppSpacing.xs)
                                }

                                Spacer()
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.md)

                            if i < tiers.count - 1 {
                                Divider()
                                    .background(isLight
                                        ? Color.black.opacity(0.05)
                                        : Color.white.opacity(0.05))
                                    .padding(.horizontal, AppSpacing.md)
                            }
                        }
                    }
                    .padding(.bottom, AppSpacing.xl)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Tier Guide — dark") {
    TierGuideSheet()
        .preferredColorScheme(.dark)
}

#Preview("Tier Guide — light") {
    TierGuideSheet()
        .preferredColorScheme(.light)
}