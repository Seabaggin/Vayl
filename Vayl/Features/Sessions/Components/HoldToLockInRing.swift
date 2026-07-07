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
    /// Ring diameter. Defaults to the original 168pt; the merged Before-we-start
    /// screen passes a larger size so the ring reads as the dominant element.
    var ringSize: CGFloat = 168
    /// Whether to show the center "✦" glyph. The merged screen wants an empty
    /// center (the ring itself is the whole commit, no separate glyph needed).
    var showsGlyph: Bool = true
    let onLockIn: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let holdSeconds: Double = 3.0     // 🎚️ feel value

    @State private var fill: CGFloat = 0
    @State private var holding = false

    private var spectrumArc: AngularGradient {
        AngularGradient(
            colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
            center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)
        )
    }

    /// Stroke weights scale with ringSize (proportional to the original 168pt
    /// baseline) so a larger ring reads as thicker, not just wider.
    private var scale: CGFloat { ringSize / 168 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.borderSubtle, lineWidth: 3 * scale)

            // Glow pass ramps with the fill (two-pass stroke, house recipe).
            Circle()
                .trim(from: 0, to: locked ? 1 : fill)
                .stroke(spectrumArc, style: StrokeStyle(lineWidth: 8 * scale, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .blur(radius: 6)
                .opacity(0.2 + 0.5 * Double(locked ? 1 : fill))

            // Crisp pass.
            Circle()
                .trim(from: 0, to: locked ? 1 : fill)
                .stroke(spectrumArc, style: StrokeStyle(lineWidth: 3 * scale, lineCap: .round))
                .rotationEffect(.degrees(-90))

            if showsGlyph {
                Text("✦")
                    .font(AppFonts.displayHero)
                    .foregroundStyle(AppColors.spectrumText)
                    .scaleEffect(locked ? 1.0 : 0.85 + 0.15 * fill)
            }
        }
        .frame(width: ringSize, height: ringSize)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in startHold() }
                .onEnded { _ in endHold() }
        )
        // The host un-latches on a failed commit (network) — drain the ring so
        // the user can hold again, not stare at a full ring that never landed.
        .onChange(of: locked) { _, isLocked in
            if !isLocked { withAnimation(AppAnimation.standard) { fill = 0 } }
        }
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
