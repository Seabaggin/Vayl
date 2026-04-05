// HoloCTAButton.swift
// Open Lightly
//
// Single shared CTA button used across all onboarding screens.
// Supports dark mode (spectrum glow) and light mode (warm aurora).
//
// Dark:  cardBg fill + HolographicShimmer + pillBorder + bloom glow
// Light: lightFrostCTA fill + LightModeShimmer + warmAuroraBorder
//        + shadow spread (shadow IS the glow on cream)
//        + no behind-bloom (invisible on light surfaces)

import SwiftUI

struct HoloCTAButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    
    var cornerRadius: CGFloat = 100
    var height: CGFloat = 56
    var lightModeGradient: LinearGradient? = nil

    @Environment(\.colorScheme) private var colorScheme

    // Dark mode color locals — unchanged
    private let cyan    = AppColors.cyan
    private let purple  = AppColors.purple
    private let magenta = AppColors.magenta
    private let pink    = AppColors.pink
    private let ctaBG   = AppColors.cardBg

    @State private var glowPulse:  Bool   = false

    // Convenience
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            action()
        }, label: {
            ZStack {

                // ── Behind-glow bloom — DARK ONLY ──────────────────
                // Invisible on cream — skipped entirely in light mode.
                if !isLight {
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
                }

                // ── Pill face ───────────────────────────────────────
                ZStack {
                    // Base fill
                    // FILL-FIX: lightFrostCTA was near-white — at 0.45 disabled
                    // opacity the shimmer's pink washed out entirely.
                    // lightCTAFill is opaque rose so the button reads correctly
                    // at both 1.0 (enabled) and 0.45 (disabled) opacity.
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(isLight ? AppColors.lightCTAFill : ctaBG)

                    // Shimmer — warm aurora on light, spectrum on dark
                    if isLight {
                        LightModeShimmer(duration: 8)
                    } else {
                        HolographicShimmer(duration: 6)
                            .opacity(0.50)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: height)
                // Single clipShape clips base + shimmer cleanly
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

                // ── Border ─────────────────────────────────────────
                // Dark:  .pillBorder()         — cyan → purple → magenta + glow blur
                // Light: .warmAuroraBorder()   — purple → magenta → gold + shadow spread
                // Both called AFTER clipShape so border sits on the edge, not inside
                .if(isLight) { view in
                    view.warmAuroraBorder(cornerRadius: cornerRadius, lineWidth: 3.0, opacity: 0.90)
                }
                .if(!isLight) { view in
                    view.pillBorder(cornerRadius: cornerRadius)
                }
                // Structural visuals always render at full intensity.
                // Disabled dimming handled by outermost container opacity.

                // ── Ambient glow shadows ───────────────────────────
                // Dark:  cyan/purple/magenta glow ring, pulses with glowPulse
                // Light: shadow spread is already handled inside warmAuroraBorder.
                //        These additional shadows deepen the lift on cream.
                if isLight {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.clear)
                        .frame(height: height)
                        .shadow(color: AppColors.magenta.opacity(glowPulse ? 0.22 : 0.14), radius: 10, x: 0, y: 4)
                        .shadow(color: AppColors.purple.opacity(glowPulse ? 0.16 : 0.10),  radius: 20, x: 0, y: 6)
                        .shadow(color: AppColors.gold.opacity(glowPulse ? 0.10 : 0.05),    radius: 8,  x: 0, y: 2)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.clear)
                        .frame(height: height)
                        .shadow(color: cyan.opacity(glowPulse ? 0.28 : 0.18),    radius: 10, x: 0, y: 0)
                        .shadow(color: purple.opacity(glowPulse ? 0.22 : 0.14),  radius: 18, x: 0, y: 0)
                        .shadow(color: magenta.opacity(glowPulse ? 0.16 : 0.10), radius: 28, x: 0, y: 0)
                }

                // ── Label ──────────────────────────────────────────
                // Dark:  white
                // Light: lightTextPrimary (#1A1A1E) — white on cream is invisible
                //        Or custom gradient if lightModeGradient is provided
                Text(title)
                    .font(AppFonts.ctaLabel)
                    .foregroundStyle(
                        isLight && lightModeGradient != nil
                            ? AnyShapeStyle(lightModeGradient!)
                            : AnyShapeStyle(colorScheme == .light
                                ? AppColors.wineDark
                                : Color.white)
                    )
            }
            .frame(height: height)
            .overlay {
                GeometryReader { geo in
                    OrbitSparkBorderView(
                        size:         geo.size,
                        cornerRadius: 28,
                        borderWidth:  3,
                        colorScheme:  colorScheme
                    )
                    .allowsHitTesting(false)
                    .opacity(isEnabled ? 1 : 0)
                    .animation(.easeIn(duration: 0.4), value: isEnabled)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
        })
        .buttonStyle(.plain)
        // CONTRAST-FIX: scale + spring makes enabled state snap.
        // 0.98 shrink on disabled reads as "not ready" instantly.
        // Spring on enable feels like the button inflates to life.
        .opacity(isEnabled ? 1.0 : 0.42)
        .scaleEffect(isEnabled ? 1.0 : 0.98)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.75),
            value: isEnabled
        )
        .allowsHitTesting(isEnabled)
        .onAppear {
            // Glow pulse — shadow breathing for both modes
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

private struct CTABorderModifier: ViewModifier {
    let isLight: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if isLight {
            content.warmAuroraBorder(cornerRadius: cornerRadius, lineWidth: 3.0, opacity: 0.90)
        } else {
            content.pillBorder(cornerRadius: cornerRadius)
        }
    }
}

// MARK: - Previews

#Preview("HoloCTA Dark — enabled") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        HoloCTAButton(title: "Next", isEnabled: true, action: { })
            .padding(.horizontal, 24)
    }
    .preferredColorScheme(.dark)
}

#Preview("HoloCTA Dark — disabled") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        HoloCTAButton(title: "Next", isEnabled: false, action: { })
            .padding(.horizontal, 24)
    }
    .preferredColorScheme(.dark)
}

#Preview("HoloCTA Light — enabled") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        HoloCTAButton(title: "Next", isEnabled: true, action: { })
            .padding(.horizontal, 24)
    }
    .preferredColorScheme(.light)
}

#Preview("HoloCTA Light — disabled") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        HoloCTAButton(title: "Next", isEnabled: false, action: { })
            .padding(.horizontal, 24)
    }
    .preferredColorScheme(.light)
}
