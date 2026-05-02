import SwiftUI

// ✅ Design system audit — verified March 9, 2026

// MARK: - ProgressRingView
// Reusable circular progress ring component
struct ProgressRingView: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let size: CGFloat
    @Environment(\.theme) private var t

    init(progress: Double, lineWidth: CGFloat = 6, size: CGFloat = 60) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .trim(from: 0, to: 1)
                .stroke(
                    t.isDark ? AppColors.borderSubtle : t.surface3,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
            // Progress arc
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    t.buttonGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(AppAnimation.slow, value: progress)
            // Center content
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.22, weight: .bold, design: .rounded)) // intentional — computed geometric badge font, size derived from ring diameter
                .foregroundStyle(t.text)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview
struct ProgressRingView_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: AppSpacing.lg) {
            ProgressRingView(progress: 0.0)
            ProgressRingView(progress: 0.33)
            ProgressRingView(progress: 0.67)
            ProgressRingView(progress: 1.0)
        }
        .padding()
        .background(AppColors.pageBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}
