import SwiftUI

/// Icon + label + Toggle row used in Settings sections.
/// Usage: `ToggleRow(icon: "waveform", iconColor: AppColors.magenta, label: "Haptic Feedback", isOn: $hapticFeedback)`
struct ToggleRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(iconColor)

            Text(label)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppColors.toggleActive)
        }
    }
}
