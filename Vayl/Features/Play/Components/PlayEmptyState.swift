//
//  PlayEmptyState.swift
//  Vayl — Play
//
//  The data-screen empty/error state for the deck library: shown when the
//  catalog fails to load or decodes nothing, instead of a silently blank wall.
//  Icon + headline + sub-label + (on error) a Retry CTA, per the contract.
//

import SwiftUI

struct PlayEmptyState: View {
    /// A load-error message, or nil for a genuinely empty (but successful) catalog.
    var message: String?
    var onRetry: () -> Void

    @State private var pressed = false

    private var isError: Bool { message != nil }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: isError ? "exclamationmark.triangle" : "rectangle.stack")
                .resizable()
                .scaledToFit()
                .frame(width: AppSpacing.xxl, height: AppSpacing.xxl)
                .foregroundStyle(AppColors.textTertiary)

            Text(isError ? "Couldn't load decks" : "No decks yet")
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)

            Text(message ?? "Decks will appear here as they become available.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: AppSpacing.xxl * 6)

            if isError {
                Text("Try again")
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .background(Capsule().fill(AppColors.cardBackground))
                    .overlay(Capsule().strokeBorder(AppColors.borderSubtle, lineWidth: 1))
                    .scaleEffect(pressed ? 0.96 : 1)
                    .sensoryFeedback(.impact(weight: .light), trigger: pressed) { _, now in now }
                    .onTapGesture { onRetry() }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in pressed = true }
                            .onEnded { _ in pressed = false }
                    )
                    .padding(.top, AppSpacing.xs)
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview("Empty — error") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        PlayEmptyState(message: "Couldn't load decks.") {}
    }
    .preferredColorScheme(.dark)
}

#Preview("Empty — no decks") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        PlayEmptyState(message: nil) {}
    }
    .preferredColorScheme(.dark)
}
#endif
