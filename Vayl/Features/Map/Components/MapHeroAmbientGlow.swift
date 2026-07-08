// Features/Map/Components/MapHeroAmbientGlow.swift
//
// A soft, screen-blended ambient wash placed behind the Map dashboard's Pulse
// hero orb (Me's aura, Us's split/whole orb). Deliberately NOT PulseAura's own
// `haloSpread` mechanism — that halo is a tight, single-layer, alpha-blended
// disc tuned for the small Home Pulse rail orb, and reused as-is here it read
// as "a circle glowing behind a ball" rather than ambient light already
// filling the room around the hero. This is a separate, bigger, softer wash:
// two layers (a broad soft outer + a tighter, slightly brighter inner, per
// AppGlows' own "never a single glow pass" philosophy), both screen-blended
// so the colour lightens the void instead of painting a shape over it.
//
// Implemented as gradients, not `.shadow()` — same reason PulseAura's own
// halo avoids a blur pass: a Gaussian blur is an offscreen re-rasterise, too
// costly to sit under an ambiently-animating (breathing) orb.

import SwiftUI

struct MapHeroAmbientGlow: View {

    let color: Color
    /// The wash's outer diameter, as a multiple of the orb it sits behind.
    /// Caller passes the orb's own size; this does the multiplying.
    let orbSize: CGFloat

    // FEEL: tune all four on device — this is the thing that didn't land on
    // the first pass, so treat these as a first guess, not a final answer.
    private let outerDiameterMultiple: CGFloat = 2.6
    private let innerDiameterMultiple: CGFloat = 1.35
    private let outerPeakOpacity: Double  = 0.22
    private let innerPeakOpacity: Double  = 0.30

    var body: some View {
        ZStack {
            wash(diameter: orbSize * outerDiameterMultiple, peak: outerPeakOpacity, coreStop: 0.12)
            wash(diameter: orbSize * innerDiameterMultiple, peak: innerPeakOpacity, coreStop: 0.05)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// One wash pass — a small, low-opacity solid core (`coreStop`) that
    /// fades out gradually, not the tight ~34%-solid disc PulseAura's own
    /// halo uses. A short solid stop + long fade reads as diffuse light;
    /// a long solid stop reads as a shape with a blurred edge.
    private func wash(diameter: CGFloat, peak: Double, coreStop: Double) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: color.opacity(peak), location: 0.0),
                        .init(color: color.opacity(peak * 0.6), location: coreStop),
                        .init(color: .clear, location: 1.0)
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: diameter / 2
                )
            )
            .frame(width: diameter, height: diameter)
            .blendMode(.screen)
    }
}
