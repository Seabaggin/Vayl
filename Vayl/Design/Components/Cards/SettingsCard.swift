import SwiftUI

/// Rounded card container used throughout Settings and any other list-style screen.
/// Usage: wrap any content in `SettingsCard { ... }`
struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(AppSpacing.md)
        .vaylGlassCard(radius: AppRadius.container)
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [
                    .clear,
                    AppColors.spectrumCyan.opacity(0.28),
                    AppColors.spectrumPurple.opacity(0.26),
                    AppColors.spectrumMagenta.opacity(0.28),
                    .clear
                ],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.container))
    }
}
