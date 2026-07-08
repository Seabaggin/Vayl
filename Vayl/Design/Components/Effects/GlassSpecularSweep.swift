// Design/Components/Effects/GlassSpecularSweep.swift
// Shared glass specular sweep — the diagonal light streak that crosses a glass surface.
//
// Used by PulseAura (circle orb) and HolographicTextCore (text glyphs).
// The gradient recipe is canonicalized on the StatPhase "1 in 5" look (StatPhase is king).
//
// Two entry points:
//   LinearGradient.glassSpecular(...)      — gradient factory; caller owns strip geometry
//   View.glassSpecularSweep(size:)         — self-animating overlay; for orb/circle consumers

import SwiftUI

// MARK: - Gradient factory

extension LinearGradient {

    /// Two-band glass specular: a primary bright streak + a softer secondary rim catch.
    /// Stop positions canonicalized on HolographicTextCore's StatPhase recipe.
    /// Uses `white.opacity(0)` for the transition stop after the primary band to avoid
    /// the black-fringe artifact that `.clear` (rgba 0,0,0,0) produces in gradient interpolation.
    static func glassSpecular(
        primary: CGFloat    = 0.30,   // HolographicTextCore.specPrimary
        secondary: CGFloat    = 0.18,   // HolographicTextCore.specSecondary
        startPoint: UnitPoint  = .leading,
        endPoint: UnitPoint  = .trailing
    ) -> LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.30),
                .init(color: .white.opacity(primary), location: 0.38),
                .init(color: .white.opacity(0), location: 0.42),
                .init(color: .clear, location: 0.50),
                .init(color: .white.opacity(secondary), location: 0.60),
                .init(color: .clear, location: 0.65)
            ],
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}

// MARK: - Self-animating modifier (orb / circle consumers)

private struct GlassSpecularSweepModifier: ViewModifier {

    let size: CGFloat
    var primary: CGFloat = 0.30
    var secondary: CGFloat = 0.18
    var duration: Double  = AppAnimation.auraGlassSweep

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var active = false

    func body(content: Content) -> some View {
        content.overlay {
            if !reduceMotion && !AppAnimation.lowPower {
                // Strip is 2.8× wide so edges stay off-screen throughout the sweep.
                // Geometry matches the HTML prototype (width:280%, height:124%).
                let offsetX = active ? size * 0.9 : -size * 0.892
                Rectangle()
                    .fill(LinearGradient.glassSpecular(primary: primary, secondary: secondary))
                    .frame(width: size * 2.8, height: size * 1.24)
                    .offset(x: offsetX)
                    .ambientAnimation(
                        .easeInOut(duration: duration).repeatForever(autoreverses: false),
                        value: active
                    )
            }
        }
        .onAppear { active = true }
    }
}

extension View {
    func glassSpecularSweep(
        size: CGFloat,
        primary: CGFloat = 0.30,
        secondary: CGFloat = 0.18,
        duration: Double  = AppAnimation.auraGlassSweep
    ) -> some View {
        modifier(GlassSpecularSweepModifier(
            size: size, primary: primary, secondary: secondary, duration: duration
        ))
    }
}
