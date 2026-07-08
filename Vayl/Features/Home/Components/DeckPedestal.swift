// Features/Home/Components/DeckPedestal.swift
// Vayl
//
// The "pedestal of light" the Deck levitates on — faithful port of
// docs/prototypes/home-final.html `.pedestal`:
//   • pBloom — a purple radial bloom that breathes (opacity 0.85→0.55,
//     scaleX 1→0.9 over 4s) and glows up behind the card's lower edge
//   • pStrip — a thin spectrum light-strip (cyan→lilac→magenta) with a soft
//     purple/cyan glow; widens from 238 → 320 when the deck is taken in hand
//
// Rendering constants are intentional (an effect surface, same convention as
// the other Effects/* files); colors resolve through the spectrum tokens.

import SwiftUI

struct DeckPedestal: View {

    /// Resting = narrow strip. Widened = deck-in-hand (carousel) state.
    var widened: Bool = false

    /// When false, only the light-strip renders (no radial bloom) — for hosts
    /// that already provide their own bloom behind the card (e.g. CardCarousel).
    var showBloom: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false

    private var stripWidth: CGFloat { widened ? 320 : 238 }

    // mockup `#7a5cff` — the lilac mid-stop between cyan and magenta on the strip.
    private let stripLilac = AppColors.spectrumLilac

    var body: some View {
        ZStack {
            // ── Bloom — rises behind the card's lower edge ──
            if showBloom {
                Ellipse()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: AppColors.spectrumPurple.opacity(0.50), location: 0.0),
                                .init(color: AppColors.spectrumPurple.opacity(0.12), location: 0.62),
                                .init(color: .clear,                                 location: 1.0),
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 109
                        )
                    )
                    .frame(width: 218, height: 86)
                    .blur(radius: 22)
                    .scaleEffect(x: breathe ? 0.9 : 1.0, anchor: .center)
                    .opacity(breathe ? 0.55 : 0.85)
                    .offset(y: -16)
            }

            // ── Strip — the line of light the card rests on ──
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .clear,                            location: 0.00),
                            .init(color: AppColors.spectrumCyan,            location: 0.18),
                            .init(color: stripLilac,                        location: 0.50),
                            .init(color: AppColors.spectrumMagenta,         location: 0.82),
                            .init(color: .clear,                            location: 1.00),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: stripWidth, height: 2)
                .shadow(color: AppColors.spectrumPurple.opacity(0.85), radius: 7)
                .shadow(color: AppColors.spectrumCyan.opacity(0.60),   radius: 2)
                .animation(AppAnimation.spring, value: widened)
        }
        .frame(height: 86)
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion, !AppAnimation.lowPower else { return }
            withAnimation(
                .easeInOut(duration: AppAnimation.ambientDrift)
                .repeatForever(autoreverses: true)
            ) {
                breathe = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Deck Pedestal") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VStack(spacing: 40) {
            DeckPedestal(widened: false)
            DeckPedestal(widened: true)
        }
    }
    .preferredColorScheme(.dark)
}
