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

    // AppRadius.pill replacescornerRadius: AppRadius.pill default.
    var cornerRadius: CGFloat = AppRadius.pill
    var height: CGFloat = 56
    var lightModeGradient: LinearGradient? = nil

    @Environment(\.colorScheme) private var colorScheme

    private let cyan    = AppColors.accentPrimary
    private let purple  = AppColors.accentSecondary
    private let magenta = AppColors.accentTertiary
    private let pink    = AppColors.accentTertiary
    private let ctaBG   = AppColors.cardBackground

    @State private var glowPulse: Bool = false

    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            action()
        }, label: {
            ZStack {

                // ── Behind-glow bloom — DARK ONLY ──────────────────
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
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(isLight ? AppColors.glassFrostCTA : ctaBG)

                    if isLight {
                        LightModeShimmer(duration: 8)
                    } else {
                        HolographicShimmer(duration: 6)
                            .opacity(0.50)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .if(isLight) { view in
                    view.warmAuroraBorder(cornerRadius: cornerRadius, lineWidth: 3.0, opacity: 0.90)
                }
                .if(!isLight) { view in
                    view.pillBorder(cornerRadius: cornerRadius)
                }

                // ── Ambient glow shadows ───────────────────────────
                if isLight {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.clear)
                        .frame(height: height)
                        .shadow(color: AppColors.accentTertiary.opacity(glowPulse ? 0.22 : 0.14), radius: 10, x: 0, y: 4)
                        .shadow(color: AppColors.accentSecondary.opacity(glowPulse ? 0.16 : 0.10), radius: 20, x: 0, y: 6)
                        .shadow(color: AppColors.safetyAccent.opacity(glowPulse ? 0.10 : 0.05),   radius: 8,  x: 0, y: 2)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.clear)
                        .frame(height: height)
                        .shadow(color: cyan.opacity(glowPulse ? 0.28 : 0.18),    radius: 10, x: 0, y: 0)
                        .shadow(color: purple.opacity(glowPulse ? 0.22 : 0.14),  radius: 18, x: 0, y: 0)
                        .shadow(color: magenta.opacity(glowPulse ? 0.16 : 0.10), radius: 28, x: 0, y: 0)
                }

                // ── Label ──────────────────────────────────────────
                Text(title)
                    .font(AppFonts.ctaLabel)
                    .foregroundStyle(
                        isLight && lightModeGradient != nil
                            ? AnyShapeStyle(lightModeGradient!)
                            : AnyShapeStyle(colorScheme == .light
                                ? AppColors.textSecondary
                                : Color.white)
                    )
            }
            .frame(height: height)
            .overlay {
                GeometryReader { geo in
                    OrbitSparkBorderView(
                        size:         geo.size,
                        // cornerRadius: AppRadius.xl — intentional fixed inner orbit radius.
                        // Deliberately inset from the button's pill shape regardless
                        // of the cornerRadius parameter. Not an AppRadius candidate.
                        cornerRadius: AppRadius.xl,
                        borderWidth:  3,
                        colorScheme:  colorScheme
                    )
                    .allowsHitTesting(false)
                    .opacity(isEnabled ? 1 : 0)
                    .animation(AppAnimation.enter, value: isEnabled)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
        })
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1.0 : 0.42)
        .scaleEffect(isEnabled ? 1.0 : 0.98)
        .animation(AppAnimation.spring, value: isEnabled)
        .allowsHitTesting(isEnabled)
        .onAppear {
            // Ambient glow pulse — 4.0s matches AppAnimation.ambientDrift exactly.
            // TODO: Add UIAccessibility.isReduceMotionEnabled guard here —
            // glow pulse currently runs under reduce motion.
            withAnimation(
                .easeInOut(duration: AppAnimation.ambientDrift)
                .repeatForever(autoreverses: true)
            ) {
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
        AppColors.pageBackground.ignoresSafeArea()
        HoloCTAButton(title: "Next", isEnabled: true, action: { })
            .padding(.horizontal, AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}

#Preview("HoloCTA Dark — disabled") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        HoloCTAButton(title: "Next", isEnabled: false, action: { })
            .padding(.horizontal, AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}

#Preview("HoloCTA Light — enabled") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        HoloCTAButton(title: "Next", isEnabled: true, action: { })
            .padding(.horizontal, AppSpacing.lg)
    }
    .preferredColorScheme(.light)
}

#Preview("HoloCTA Light — disabled") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        HoloCTAButton(title: "Next", isEnabled: false, action: { })
            .padding(.horizontal, AppSpacing.lg)
    }
    .preferredColorScheme(.light)
}
