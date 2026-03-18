import SwiftUI

/// Single shared CTA button used across all onboarding screens.
struct HoloCTAButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var cornerRadius: CGFloat = 100
    var height: CGFloat = 56

    private let cyan    = AppColors.cyan
    private let purple  = AppColors.purple
    private let magenta = AppColors.magenta
    private let pink    = AppColors.pink
    private let ctaBG   = AppColors.cardBg

    @State private var shimmerPhase: CGFloat = 0
    @State private var glowPulse: Bool = false

    var body: some View {
        Button {
            guard isEnabled else { return }
            action()
        } label: {
            ZStack {
                // Behind-glow bloom
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LinearGradient(
                        colors: [cyan.opacity(0.22), purple.opacity(0.18), magenta.opacity(0.14)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(height: 34)
                    .blur(radius: 36)
                    .offset(y: 10)
                    .opacity(glowPulse ? 1.0 : 0.65)
                    .allowsHitTesting(false)

                // Pill face — dark base + shimmer, clipped precisely to pill shape
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(ctaBG)

                    ShimmerFill(
                        phase: shimmerPhase,
                        colors: [
                            cyan.opacity(0.50),
                            purple.opacity(0.44),
                            magenta.opacity(0.44),
                            pink.opacity(0.38),
                            cyan.opacity(0.38),
                        ]
                    )
                    .opacity(0.50)
                }
                .frame(maxWidth: .infinity)
                .frame(height: height)
                // Single clipShape clips BOTH the dark base and the shimmer cleanly
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                // Border + glow overlaid after clip so it sits on the edge
                .pillBorder(cornerRadius: cornerRadius)
                // Per-border ambient glow ring
                .shadow(color: cyan.opacity(glowPulse ? 0.28 : 0.18),    radius: 10, x: 0, y: 0)
                .shadow(color: purple.opacity(glowPulse ? 0.22 : 0.14),  radius: 18, x: 0, y: 0)
                .shadow(color: magenta.opacity(glowPulse ? 0.16 : 0.10), radius: 28, x: 0, y: 0)
                .overlay {
                    Text(title)
                        .font(AppFonts.ctaLabel)
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .allowsHitTesting(isEnabled)
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                shimmerPhase = 1
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

// MARK: - Shimmer Fill

private struct ShimmerFill: View {
    let phase: CGFloat
    let colors: [Color]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                .frame(width: w * 3, height: geo.size.height)
                .offset(x: phase * -w * 2)
        }
        .clipped()
    }
}
