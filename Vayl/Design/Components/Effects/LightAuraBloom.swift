//
//  LightAuraBloom.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/26/26.
//


// Design/Components/Effects/LightAuraBloom.swift
// Open Lightly
//
// Light-mode analogue of FlameAura.
// Renders layered, animated warm blobs that rise above
// a selected pill on a cream/white background.
// Uses rose / peach / gold / lavender — all visible on light surfaces.

import SwiftUI
import Combine

struct LightAuraBloom: View {

    let intensity: SelectablePill.Intensity

    // ── tuneable per-intensity values ──────────────────────────────
    private var blobOpacity: Double {
        switch intensity {
        case .dim:   return 0.30
        case .warm:  return 0.48
        case .alive: return 0.62
        }
    }

    private var bloomHeight: CGFloat {
        switch intensity {
        case .dim:   return 0          // .dim never shows flame/bloom
        case .warm:  return 70
        case .alive: return 100
        }
    }

    // ── animation state ───────────────────────────────────────────
    // Phase anchor: the timeline clock is measured from mount so the sway
    // starts at t = 0 (same start pose the old Timer-driven phase gave).
    @State private var mountDate = Date()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder
    var body: some View {
        if bloomHeight <= 0 {
            EmptyView()
        } else if reduceMotion || AppAnimation.lowPower {
            // Ambient gate — Reduce Motion / Low Power Mode render ONE static
            // bloom frame: no TimelineView tick, no phase advance.
            Canvas { ctx, size in
                drawBloom(ctx: &ctx, size: size, t: 0)
            }
            .allowsHitTesting(false)
        } else {
            // One clock: the timeline drives t directly (the old code ran an
            // uncapped TimelineView AND a 60Hz Timer mutating @State — two
            // competing per-frame invalidation sources for one Canvas).
            // 0.72/s matches the old advance rate (0.012 per 1/60s tick);
            // sway frequencies are 1.2–2.0 rad/s, so a 30fps cap is invisible.
            TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                Canvas { ctx, size in
                    let t = timeline.date.timeIntervalSince(mountDate) * 0.72
                    drawBloom(ctx: &ctx, size: size, t: t)
                }
            }
            .allowsHitTesting(false)
            .onAppear { mountDate = Date() }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Drawing
    // ─────────────────────────────────────────────────────────────

    private func drawBloom(ctx: inout GraphicsContext, size: CGSize, t: Double) {
        let blobs: [(offsetX: Double, color: Color, scale: Double, phaseShift: Double)] = [
            // rose centre
            (offsetX:  0.00, color: Color(red: 1.00, green: 0.40, blue: 0.60),
             scale: 1.00, phaseShift: 0.00),
            // peach left
            (offsetX: -0.18, color: Color(red: 1.00, green: 0.65, blue: 0.45),
             scale: 0.78, phaseShift: 0.90),
            // gold right
            (offsetX:  0.20, color: Color(red: 1.00, green: 0.80, blue: 0.30),
             scale: 0.70, phaseShift: 1.60),
            // lavender far-left
            (offsetX: -0.30, color: Color(red: 0.78, green: 0.60, blue: 1.00),
             scale: 0.60, phaseShift: 2.40),
            // blush far-right
            (offsetX:  0.32, color: Color(red: 1.00, green: 0.55, blue: 0.75),
             scale: 0.55, phaseShift: 3.10),
        ]

        for blob in blobs {
            let waver   = sin(t * 1.8 + blob.phaseShift) * 0.06    // gentle horizontal sway
            let rise    = cos(t * 1.2 + blob.phaseShift) * 0.08    // breathing rise/fall
            let pulse   = 0.88 + sin(t * 2.0 + blob.phaseShift) * 0.12 // opacity pulse

            let cx = size.width  * (0.50 + blob.offsetX + waver)
            // blobs sit just above bottom edge and drift upward
            let cy = size.height * (0.75 + rise)

            let blobW = size.width  * blob.scale * 0.55
            let blobH = size.height * blob.scale * 0.60

            let rect = CGRect(
                x: cx - blobW / 2,
                y: cy - blobH / 2,
                width: blobW,
                height: blobH
            )

            // soft radial gradient per blob
            let gradient = Gradient(stops: [
                .init(color: blob.color.opacity(blobOpacity * pulse), location: 0.0),
                .init(color: blob.color.opacity(0),                   location: 1.0),
            ])

            ctx.drawLayer { inner in
                inner.addFilter(.blur(radius: 18 * blob.scale))
                inner.fill(
                    Path(ellipseIn: rect),
                    with: .radialGradient(
                        gradient,
                        center: CGPoint(x: cx, y: cy),
                        startRadius: 0,
                        endRadius: max(blobW, blobH) / 2
                    )
                )
            }
        }
    }
}
