// Design/Components/Navigation/VaylCloseButton.swift

import SwiftUI

/// The one close affordance. A 32pt glass circle with a subtle ring and a
/// tertiary xmark, tapped through `PressableCardStyle` (press-scale + light
/// haptic). Every sheet/cover dismiss chrome routes through this so the close
/// button looks, feels, and reads to VoiceOver the same everywhere.
///
/// The label defaults to "Close" and is overridable for the rare surface whose
/// dismiss means something more specific ("Close preview", "Dismiss").
struct VaylCloseButton: View {
    var accessibilityLabel: String = "Close"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppColors.glassSurface)
                    .overlay(
                        Circle()
                            .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
                    )
                Image(systemName: AppIcons.close)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .frame(width: 32, height: 32)
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview("VaylCloseButton") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VaylCloseButton {}
    }
    .preferredColorScheme(.dark)
}
