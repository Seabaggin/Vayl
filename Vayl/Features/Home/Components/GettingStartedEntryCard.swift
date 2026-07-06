import SwiftUI

/// Compact "Your first steps" card on the dashboard. Tapping it opens the Path overlay.
/// Carries the matched-geometry source so the card morphs (expands out) into the overlay.
struct GettingStartedEntryCard: View {
    let gettingStarted: GettingStarted
    let namespace: Namespace.ID
    let isHidden: Bool          // true while the overlay is open (source handed to the overlay card)
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                ProgressRingView(progress: gettingStarted.progress, size: 38)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Your first steps")
                        .font(AppFonts.overline)
                        .foregroundColor(AppColors.textTertiary)
                    Text(gettingStarted.nextStep?.title ?? "All set")
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(AppColors.cardBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(AppColors.spectrumBorder, lineWidth: 1)
                    .opacity(0.45)
            )
            .matchedGeometryEffect(id: "gettingStartedPath", in: namespace, anchor: .center, isSource: !isHidden)
            .opacity(isHidden ? 0 : 1)   // hidden while the overlay owns the matched frame
        }
        .buttonStyle(PlainButtonStyle())
    }
}
