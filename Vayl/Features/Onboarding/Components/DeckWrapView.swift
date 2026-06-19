//
//  DeckWrapView.swift
//  Vayl
//
//  BuildDeck "Forge" beat. Spectrum ribbons spiral AROUND the rising deck (a helix) —
//  the foil being woven onto it as it lifts off the felt. Front strands draw bright,
//  back strands dim (as if behind the deck), and the whole helix spins. Driven by a
//  TimelineView clock so it actually animates.
//

import SwiftUI
import Darwin

struct DeckWrapView: View {
    var center:    CGPoint   // the (rising) deck centre
    var deckSize:  CGSize
    var startDate: Date
    var intensity: Double    // 0 → 1 (fades in / tightens as the deck builds)

    private let palette: [Color] = [AppColors.spectrumCyan,
                                    AppColors.spectrumPurple,
                                    AppColors.spectrumMagenta]

    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSince(startDate)
            Canvas { ctx, _ in draw(&ctx, t: t) }
                .allowsHitTesting(false)
        }
    }

    private func draw(_ ctx: inout GraphicsContext, t: Double) {
        guard intensity > 0.001 else { return }
        let hw = deckSize.width  * 0.50          // wrap radius ≈ deck half-width (hugs the deck)
        let hh = deckSize.height * 0.52
        let turns = 1.1 + 0.4 * intensity        // a few loose ribbons, not a tight coil
        let rot = t * 1.0                         // the helix spins
        let steps = 80

        for r in 0..<palette.count {
            let phaseOff = Double(r) / Double(palette.count) * 2 * .pi
            let color = palette[r]
            var prev: CGPoint? = nil
            for s in 0...steps {
                let u = Double(s) / Double(steps)            // 0 = top, 1 = bottom
                let ang = u * turns * 2 * .pi + rot + phaseOff
                let pt = CGPoint(x: center.x + CGFloat(Darwin.cos(ang)) * hw,
                                 y: center.y - hh + CGFloat(u) * 2 * hh)
                let front = Darwin.sin(ang) > 0              // toward the viewer?
                if let p = prev {
                    var seg = Path(); seg.move(to: p); seg.addLine(to: pt)
                    let op = (front ? 0.85 : 0.22) * intensity
                    let lw: CGFloat = front ? 2.2 : 1.3
                    var glow = ctx
                    glow.addFilter(.blur(radius: front ? 4 : 2))
                    glow.stroke(seg, with: .color(color.opacity(op * 0.55)),
                                style: StrokeStyle(lineWidth: lw + 2, lineCap: .round))
                    ctx.stroke(seg, with: .color(color.opacity(op)),
                               style: StrokeStyle(lineWidth: lw, lineCap: .round))
                }
                prev = pt
            }
        }
    }
}
