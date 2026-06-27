//
//  RotaryDial.swift
//  Vayl — Play
//
//  The arcade mode dial. INVISIBLE rotary: glyph(s) hang from a hub and sway.
//  With one enabled mode it's a single Cards glyph (ambient sway only). The swap
//  ENGINE is generic over `enabledModes`; flip PlayFeatureFlags.simulatorEnabled
//  to reveal the 2nd detent — zero rework.
//

import SwiftUI

enum RotaryMath {
    /// Angle (deg) for the active index given the per-detent step.
    static func angle(forIndex i: Int, step: Double) -> Double { -Double(i) * step }

    /// Snap a live drag angle to the nearest detent index in 0..<count.
    static func nearestIndex(angleDeg a: Double, step: Double, count: Int) -> Int {
        guard count > 1, step != 0 else { return 0 }
        let raw = (-a / step).rounded()
        return min(max(Int(raw), 0), count - 1)
    }
}

struct RotaryDial: View {
    let store: PlayStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var sway: Double = 0
    @State private var dragDeg: Double = 0
    @State private var dragging = false

    private let step: Double = 52        // degrees between detents
    // Pendulum geometry — the glyph hangs `armLen` below a hub pinned just under
    // the top edge, so it reads as docked beneath the status bar / island (mockup
    // glyph centre ≈ y86 from phone top). Tune hubInset / armLen to taste.
    private let hubInset: CGFloat = 6    // hub distance below the dial's top edge
    private let armLen: CGFloat = 50     // hub → glyph centre
    private let glyphW: CGFloat = 40
    private let glyphH: CGFloat = 36

    private var modes: [PlayMode] { store.enabledModes }
    private var activeIndex: Int { modes.firstIndex(of: store.activeMode) ?? 0 }

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            wheel
            labels
        }
        .contentShape(Rectangle())
        .gesture(swapDrag)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3.6).repeatForever(autoreverses: true)) { sway = 5 }
        }
    }

    private var wheel: some View {
        let wheelDeg = dragging ? dragDeg : RotaryMath.angle(forIndex: activeIndex, step: step)
        return ZStack(alignment: .top) {
            // active-slot glow, centred on the hanging glyph
            Circle()
                .fill(RadialGradient(colors: [glowColor.opacity(0.5), .clear],
                                     center: .center, startRadius: 0, endRadius: 60))
                .frame(width: 120, height: 90)
                .offset(y: hubInset + armLen + glyphH / 2 - 45)
                .blur(radius: 16)

            // the invisible wheel: each glyph rides an arm whose TOP is the shared
            // hub, so rotation (sway + detent) truly pivots from the hub.
            ZStack(alignment: .top) {
                ForEach(Array(modes.enumerated()), id: \.element.id) { idx, mode in
                    arm(idx, mode)
                }
            }
            .rotationEffect(.degrees(wheelDeg + sway), anchor: .top)
            .offset(y: hubInset)
        }
        .frame(maxWidth: .infinity)
        .frame(height: hubInset + armLen + glyphH)
    }

    /// One glyph hanging from the hub on an `armLen` arm. The arm pivots from its
    /// top (the hub); the glyph counter-rotates to stay upright.
    private func arm(_ idx: Int, _ mode: PlayMode) -> some View {
        let active = idx == activeIndex
        return VStack(spacing: 0) {
            Spacer(minLength: 0).frame(height: armLen)
            glyph(mode)
                .frame(width: glyphW, height: glyphH)
                .rotationEffect(.degrees(-Double(idx) * step))
                .opacity(active ? 1 : 0.4)
                .scaleEffect(active ? 1 : 0.7)
        }
        .rotationEffect(.degrees(Double(idx) * step), anchor: .top)
    }

    @ViewBuilder
    private func glyph(_ m: PlayMode) -> some View {
        switch m {
        case .cards:     DeckGlyph(kind: .cards)
        case .simulator: DeckGlyph(kind: .network)
        }
    }

    private var labels: some View {
        HStack(spacing: 10) {
            ForEach(Array(modes.enumerated()), id: \.element.id) { i, m in
                if i > 0 {
                    Circle().fill(AppColors.textMuted).frame(width: 3, height: 3)
                }
                HStack(spacing: 3) {
                    Text(m.title.uppercased())
                    if m == .simulator { Image(systemName: "lock.fill").font(.system(size: 8)) }
                }
                .font(AppFonts.overline)
                .foregroundStyle(m == store.activeMode ? AnyShapeStyle(spectrum) : AnyShapeStyle(AppColors.textMuted))
                .onTapGesture { snap(to: m) }
            }
        }
    }

    private var swapDrag: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { v in
                guard modes.count > 1 else { return }
                dragging = true
                let base = RotaryMath.angle(forIndex: activeIndex, step: step)
                dragDeg = max(-step * Double(modes.count - 1),
                              min(0, base + Double(v.translation.width) * (step / 130)))
                let live = RotaryMath.nearestIndex(angleDeg: dragDeg, step: step, count: modes.count)
                if modes[live] != store.activeMode {
                    store.activeMode = modes[live]
                    UISelectionFeedbackGenerator().selectionChanged()
                }
            }
            .onEnded { _ in
                guard modes.count > 1 else { return }
                dragging = false
                let i = RotaryMath.nearestIndex(angleDeg: dragDeg, step: step, count: modes.count)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { store.activeMode = modes[i] }
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
    }

    private func snap(to m: PlayMode) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { store.setMode(m) }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private var spectrum: LinearGradient {
        .init(colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
              startPoint: .leading, endPoint: .trailing)
    }
    private var glowColor: Color { store.activeMode == .simulator ? AppColors.spectrumMagenta : AppColors.spectrumCyan }
}

#if DEBUG
#Preview("Rotary dial") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        RotaryDial(store: .preview).frame(height: 150)
    }
    .preferredColorScheme(.dark)
}
#endif
