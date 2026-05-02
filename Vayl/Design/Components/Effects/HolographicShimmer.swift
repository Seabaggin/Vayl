import SwiftUI

/// Self-contained animated holographic shimmer fill.
/// Renders a 3× wide neon gradient that sweeps left→right continuously.
///
/// Use as a background layer clipped to any shape:
/// ```swift
/// Capsule()
///     .fill(AppColors.modalBackground)
///     .overlay { HolographicShimmer().clipShape(Capsule()) }
/// ```
struct HolographicShimmer: View {
    /// Animation duration in seconds. Defaults to 6 (gentle sweep).
    var duration: Double = 6

    @State private var phase: CGFloat = 0

    private let colors: [Color] = [
        AppColors.accentPrimary.opacity(0.50),
        AppColors.accentSecondary.opacity(0.45),
        AppColors.accentTertiary.opacity(0.45),
        AppColors.accentTertiary.opacity(0.40),
        AppColors.accentPrimary.opacity(0.40),
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                .frame(width: w * 3, height: geo.size.height)
                .offset(x: phase * -w * 2)
        }
        .clipped()
        .onAppear {
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }
}
