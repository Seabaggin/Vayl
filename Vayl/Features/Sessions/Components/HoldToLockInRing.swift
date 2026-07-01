//
//  HoldToLockInRing.swift
//  Vayl
//
//  The 3-second press-and-hold lock-in (cover-family 1B). A sustained gesture
//  you can't do absentmindedly: the spectrum arc draws on over the hold and the
//  glow ramps with it. Release early and it drains back. 🎚️ holdSeconds = 3.0,
//  Bryan dials the ramp feel on device (Swift-over-HTML rule).
//

import SwiftUI

struct HoldToLockInRing: View {

    let locked: Bool
    let onLockIn: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Rendering constants (geometry, like ScoreRing / the old sync ring).
    private let ringSize: CGFloat = 168
    private let holdSeconds: Double = 3.0     // 🎚️ feel value

    @State private var fill: CGFloat = 0
    @State private var holding = false

    private var spectrumArc: AngularGradient {
        AngularGradient(
            colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
            center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)
        )
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.borderSubtle, lineWidth: 3)

            // Glow pass ramps with the fill (two-pass stroke, house recipe).
            Circle()
                .trim(from: 0, to: locked ? 1 : fill)
                .stroke(spectrumArc, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .blur(radius: 6)
                .opacity(0.2 + 0.5 * Double(locked ? 1 : fill))

            // Crisp pass.
            Circle()
                .trim(from: 0, to: locked ? 1 : fill)
                .stroke(spectrumArc, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("✦")
                .font(AppFonts.displayHero)
                .foregroundStyle(AppColors.spectrumText)
                .scaleEffect(locked ? 1.0 : 0.85 + 0.15 * fill)
        }
        .frame(width: ringSize, height: ringSize)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in startHold() }
                .onEnded { _ in endHold() }
        )
        .accessibilityLabel(locked ? "Locked in" : "Press and hold to lock in")
    }

    private func startHold() {
        guard !locked, !holding else { return }
        holding = true
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        if reduceMotion {
            // Reduce Motion: no ramp animation; a plain timed hold with a final snap.
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(holdSeconds))
                if holding { holding = false; complete() }
            }
            return
        }
        let start = Date()
        Task { @MainActor in
            while holding {
                fill = min(1, CGFloat(Date().timeIntervalSince(start) / holdSeconds))
                if fill >= 1 { holding = false; complete(); break }
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func endHold() {
        guard holding else { return }
        holding = false
        withAnimation(AppAnimation.standard) { fill = 0 }   // drains back, no penalty
    }

    private func complete() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(AppAnimation.standard) { fill = 1 }
        onLockIn()
    }
}
