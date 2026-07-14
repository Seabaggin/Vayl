// Design/Components/Effects/MetalRing.swift

import SwiftUI

/// A rounded-rect / capsule ring stroked with the shared liquid-metal spectrum
/// (`AppColors.spectrumMetalAngular`, the native equivalent of the CSS
/// conic-gradient mockup — no Metal shader required).
///
/// STATIC "lit pose" at rest: fixed specular glints make it read as chrome
/// catching light rather than a frozen rainbow. A one-shot ~0.6s sweep fires
/// when the ring becomes active OR when `sweepToken` changes (e.g. a tab
/// switch): the metal's hues travel once while the fixed glint stays, then it
/// settles back to the pose. Nothing loops — no continuous cost on always-on
/// chrome. (The perpetual liquid-metal rotation is reserved for earned hero
/// moments, not persistent nav.)
///
/// Motion gating: the sweep is a reactive one-shot (user feedback), so it plays
/// under Low Power; Reduce Motion skips it and the ring just crossfades in.
struct MetalRing: View {

    var cornerRadius: CGFloat
    var lineWidth: CGFloat     = 1.25
    var glowOpacity: Double    = 0.3
    var glowLineWidth: CGFloat = 2.75
    var glowBlur: CGFloat      = 5
    var isActive: Bool

    /// Fire the sweep on first appearance (e.g. the initially-selected tab).
    var sweepOnAppear: Bool    = false
    /// Change this to fire a one-shot sweep WITHOUT toggling `isActive`
    /// (e.g. pass the selected tab index so a tab switch sweeps the ring).
    var sweepToken: Int        = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sweep: Angle = .degrees(0)

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        ZStack {
            // Soft outward halo — blurred once, cached (never rotates).
            Rectangle().fill(AppColors.spectrumMetalAngular)
                .mask(shape.stroke(lineWidth: glowLineWidth))
                .blur(radius: glowBlur)
                .opacity(isActive ? glowOpacity : 0)

            // Crisp metal ring at the current sweep angle (vector re-render;
            // static except during the brief one-shot sweep).
            Rectangle().fill(gradient(at: sweep.degrees))
                .mask(shape.stroke(lineWidth: lineWidth))
                .opacity(isActive ? 1 : 0)

            // Fixed specular glints — the "lit pose" that reads as metal at rest.
            specular
                .opacity(isActive ? 1 : 0)
        }
        // Static at rest, so compositingGroup composes once (only re-composites
        // during the ~0.6s sweep) — the .screen glint blends cleanly on the ring.
        .compositingGroup()
        .animation(AppAnimation.fast, value: isActive)
        .onChange(of: isActive) { _, active in fireSweep(active) }
        .onChange(of: sweepToken) { _, _ in fireSweep(isActive) }
        .onAppear { if sweepOnAppear { fireSweep(isActive) } }
    }

    /// Two fixed specular catches (primary top-left, secondary bottom-right),
    /// masked to the ring and screen-blended so the border reads as lit chrome.
    private var specular: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [.white.opacity(0.9), .clear],
                                         center: .center, startRadius: 0, endRadius: d * 0.55))
                    .frame(width: d * 1.1, height: d * 1.1)
                    .position(x: geo.size.width * 0.26, y: geo.size.height * 0.18)
                Circle()
                    .fill(RadialGradient(colors: [Color(uiColor: VaylPrimitives.metalHiMagenta).opacity(0.7), .clear],
                                         center: .center, startRadius: 0, endRadius: d * 0.5))
                    .frame(width: d, height: d)
                    .position(x: geo.size.width * 0.78, y: geo.size.height * 0.84)
            }
            .mask(shape.stroke(lineWidth: lineWidth + 0.5))
            .blendMode(.screen)
        }
    }

    private func gradient(at deg: Double) -> AngularGradient {
        AngularGradient(gradient: Gradient(stops: AppColors.spectrumMetalStops),
                        center: .center, startAngle: .degrees(deg), endAngle: .degrees(deg + 360))
    }

    /// Reactive one-shot sweep. Plays under Low Power (user feedback always
    /// plays); skipped under Reduce Motion (ring just crossfades in).
    private func fireSweep(_ active: Bool) {
        guard active, !reduceMotion else { return }
        sweep = .degrees(0)
        withAnimation(AppAnimation.metalSweep) {
            sweep = .degrees(360)
        }
    }
}

// MARK: - Preview

#Preview("MetalRing") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VStack(spacing: 28) {
            HStack(spacing: 24) {
                MetalRing(cornerRadius: 21, lineWidth: 2.0, isActive: true)
                    .frame(width: 58, height: 42)
                MetalRing(cornerRadius: 21, lineWidth: 2.0, isActive: false)
                    .frame(width: 58, height: 42)
            }
            MetalRing(cornerRadius: 28, lineWidth: 1.8, isActive: true)
                .frame(width: 300, height: 56)
                .overlay(Text("Begin").font(AppFonts.ctaLabel).foregroundStyle(.white))
        }
    }
    .preferredColorScheme(.dark)
}
