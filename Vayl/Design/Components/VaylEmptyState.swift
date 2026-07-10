// Design/Components/VaylEmptyState.swift
//
// The one empty / forming state. Icon + headline + sub-label per the CLAUDE.md
// empty-state spec, with an optional CTA. Extracted verbatim from the Map tab's
// `MapEmptyState` (which is now a typealias of this) so every data screen —
// Map, Vault, Desire Reveal, Session builder, Pulse — routes its empty case
// through one component and they all read alike.

import SwiftUI

struct VaylEmptyState: View {
    let icon: String
    let headline: String
    let message: String
    var cta: CTA?

    /// Optional call-to-action beneath the sub-label.
    struct CTA {
        let label: String
        let action: () -> Void
    }

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(AppFonts.body(26, weight: .regular, relativeTo: .title2))
                .fontWeight(.light)
                .foregroundStyle(AppColors.textTertiary)
            Text(headline)
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textSecondary)
            Text(message)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let cta {
                Button(action: cta.action) {
                    Text(cta.label)
                        .font(AppFonts.buttonLabel)
                        .foregroundStyle(AppColors.textAccent)
                }
                .buttonStyle(PressableCardStyle())
                .padding(.top, AppSpacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
        .padding(.horizontal, AppSpacing.lg)
    }
}

#Preview("VaylEmptyState") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VaylEmptyState(
            icon: "sparkles",
            headline: "Nothing here yet",
            message: "This is where your record will take shape.",
            cta: .init(label: "Get started", action: {})
        )
    }
    .preferredColorScheme(.dark)
}
