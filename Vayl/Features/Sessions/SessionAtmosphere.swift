//
//  SessionAtmosphere.swift
//  Vayl
//
//  The void + breathing spectrum aurora behind the couple card session
//  (airlock → player → close). A session-scoped atmosphere, distinct from
//  the OB canvas: it uses the app-wide spectrum/void tokens only — never the
//  OB table tokens, which never leave the onboarding boundary.
//
//  An optional `turn` tint leans the room toward whoever is drawing —
//  cyan for the partner (A), magenta for you (B) — matching the in-session
//  ambient in docs/prototypes/couple-session-hero-v2.html.
//
//  Reduce Motion: the breath + drift are removed entirely; the static aurora
//  is visually complete on its own.
//

import SwiftUI

struct SessionAtmosphere: View {

    /// Who is drawing — leans the ambient tint. `.none` = even (airlock / close).
    enum Turn { case none, you, partner }

    var turn: Turn = .none

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = geo.size.height

            ZStack {
                AppColors.void.ignoresSafeArea()

                // ── Spectrum aurora — cyan high, purple mid, magenta low ──
                blob(
                    color: AppColors.spectrumCyan, base: 0.20, offset: 0.00,
                    size: CGSize(width: W * 1.15, height: H * 0.48),
                    at: CGPoint(x: W * 0.22, y: H * 0.34)
                )
                blob(
                    color: AppColors.spectrumPurple, base: 0.24, offset: 0.34,
                    size: CGSize(width: W * 1.25, height: H * 0.55),
                    at: CGPoint(x: W * 0.66, y: H * 0.60)
                )
                blob(
                    color: AppColors.spectrumMagenta, base: 0.24, offset: 0.66,
                    size: CGSize(width: W * 1.25, height: H * 0.50),
                    at: CGPoint(x: W * 0.46, y: H * 0.86)
                )

                // ── Turn tint — the room leans toward the drawer ──
                turnTint(W: W, H: H)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear(perform: startBreath)
    }

    // MARK: - Aurora blob

    private func blob(
        color: Color,
        base: Double,
        offset: CGFloat,
        size: CGSize,
        at: CGPoint
    ) -> some View {
        // One looping `phase` drives all three out of step via per-blob offsets,
        // so they breathe independently from a single animated value.
        let breath = reduceMotion ? 0.5 : (sin((phase + offset) * .pi * 2) * 0.5 + 0.5)
        let opacity = base * (0.62 + breath * 0.38)
        let scale = reduceMotion ? 1.0 : (0.97 + breath * 0.08)

        return Ellipse()
            .fill(color.opacity(opacity))
            .frame(width: size.width, height: size.height)
            .blur(radius: 70)
            .scaleEffect(scale)
            .position(at)
    }

    // MARK: - Turn tint

    @ViewBuilder
    private func turnTint(W: CGFloat, H: CGFloat) -> some View {
        let tint: Color? = {
            switch turn {
            case .none:    return nil
            case .partner: return AppColors.spectrumCyan
            case .you:     return AppColors.spectrumMagenta
            }
        }()

        Ellipse()
            .fill((tint ?? .clear).opacity(tint == nil ? 0 : 0.16))
            .frame(width: W * 1.0, height: H * 0.42)
            .blur(radius: 80)
            .position(x: W * 0.5, y: H * 0.52)
            .animation(.easeInOut(duration: 1.2), value: turn)
    }

    // MARK: - Breath cycle

    private func startBreath() {
        guard !reduceMotion else { return }
        withAnimation(.linear(duration: AppAnimation.ambientDrift * 2.5).repeatForever(autoreverses: false)) {
            phase = 1.0
        }
    }
}

// MARK: - Preview

#Preview("Session Atmosphere") {
    ZStack {
        SessionAtmosphere(turn: .partner)
    }
    .preferredColorScheme(.dark)
}
