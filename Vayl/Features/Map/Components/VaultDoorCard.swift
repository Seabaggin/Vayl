// Features/Map/Components/VaultDoorCard.swift
//
// The Vault door card — Map dashboard spec §4 (vault spin-open). Interim per
// spec §1: Us lens only. Tapping spins the six-spoke lattice emblem briefly,
// then opens the existing VaultSheet via `onOpen` (MapView's onOpenVault
// closure, previously wired but never called — see MapUsLayer).
//
// Visual reference: docs/prototypes/map-dashboard-final.html (vault door,
// magenta/Us gradient variant).

import SwiftUI

struct VaultDoorCard: View {

    let summary:   String
    let statLine:  String
    var onOpen:    () -> Void

    @State private var spinning = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // FEEL: tune on device — total spin+delay must stay under 0.5s (spec §4).
    private let spinDegrees:      Double = 60
    // FEEL: tied to AppAnimation.spring's response (0.5s) — sheet arrives once
    // the spin visually settles, not mid-flight.
    private let spinSettleDelay:  Double = 0.5

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            guard !reduceMotion else {
                onOpen()
                return
            }
            withAnimation(AppAnimation.spring) { spinning = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + spinSettleDelay) {
                onOpen()
                spinning = false
            }
        } label: {
            VStack(spacing: AppSpacing.sm) {
                VaultEmblem()
                    .frame(width: 74, height: 74)
                    .rotationEffect(.degrees(spinning ? spinDegrees : 0))

                Text("Our Vault")
                    .font(AppFonts.display(15, weight: .semibold, relativeTo: .headline))
                    .foregroundStyle(AppColors.textPrimary)

                Text(summary)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                Text(statLine)
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.textTertiary)

                Text("Open ›")
                    .font(AppFonts.caption.bold())
                    .foregroundStyle(AppColors.spectrumMagenta)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressableCardStyle())
        .vaylGlassCard(accent: AppColors.spectrumMagenta, radius: AppRadius.container)
        .accessibilityLabel("Our Vault")
        .accessibilityHint("Opens the shared vault")
    }
}

// MARK: - VaultEmblem

/// The vault-door lattice, ported LITERALLY (same coordinates, same element
/// order, same gradients) from the mockup's SVG — Us/magenta variant, in
/// docs/prototypes/map-dashboard-final.html (`#dvu`/`#dau`/`#dgu`/`#dbu`).
/// Every coordinate below is copied straight from that SVG's 0–100 viewBox;
/// `scale` is the only thing that adapts it to the caller's frame, so nothing
/// here should be "improved" without also updating the mockup — this is meant
/// to read as the same emblem, not a reinterpretation of it.
private struct VaultEmblem: View {

    /// The six spoke/bead terminal points, radius 45 from centre, 60° apart —
    /// copied verbatim from the SVG's six `<line>`/`<circle>` endpoints rather
    /// than re-derived from trig, so the geometry can't drift from the source.
    private let spokeEnds: [CGPoint] = [
        CGPoint(x: 95,   y: 50),
        CGPoint(x: 72.5, y: 88.97),
        CGPoint(x: 27.5, y: 88.97),
        CGPoint(x: 5,    y: 50),
        CGPoint(x: 27.5, y: 11.03),
        CGPoint(x: 72.5, y: 11.03),
    ]

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 100
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * scale, y: y * scale) }
            func circle(_ c: CGPoint, _ r: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
            }

            let center = p(50, 50)
            // linearGradient#dvu: x1/y1=8,8 → x2/y2=92,92 — one diagonal spectrum
            // stroke shared by the ring, spokes, beads, and core stroke.
            let spectrum = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta]),
                startPoint: p(8, 8), endPoint: p(92, 92)
            )

            // radialGradient#dau — the centre aura glow.
            context.fill(circle(center, 15 * scale), with: .radialGradient(
                Gradient(stops: [
                    .init(color: AppColors.vaultRoseHighlight.opacity(0.7), location: 0),
                    .init(color: AppColors.spectrumMagenta.opacity(0.24), location: 0.6),
                    .init(color: .clear, location: 1),
                ]),
                center: center, startRadius: 0, endRadius: 15 * scale
            ))

            // Ring (r=32): blurred glow pass (width 5, opacity .45, filter#dbu
            // stdDeviation 2.4) THEN a crisp pass (width 2) — only the ring gets
            // this two-pass treatment in the mockup, nothing else does.
            let ring = circle(center, 32 * scale)
            var glowLayer = context
            glowLayer.opacity = 0.45
            glowLayer.addFilter(.blur(radius: 2.4 * scale))
            glowLayer.stroke(ring, with: spectrum, lineWidth: 5 * scale)
            context.stroke(ring, with: spectrum, lineWidth: 2 * scale)

            // Six spokes, centre → each terminal point, round caps.
            for end in spokeEnds {
                var spoke = Path()
                spoke.move(to: center)
                spoke.addLine(to: p(end.x, end.y))
                context.stroke(spoke, with: spectrum, style: StrokeStyle(lineWidth: 2.6 * scale, lineCap: .round))
            }

            // Terminal beads (r=3.4) at each spoke's outer end.
            for end in spokeEnds {
                context.fill(circle(p(end.x, end.y), 3.4 * scale), with: spectrum)
            }

            // Rotated core — rect(39,39,22,22) rx=3, rotated 45° about its own
            // centre (50,50). radialGradient#dgu (cx 38%/cy 32% of the core box,
            // r 80%) gives the glossy off-centre highlight; stroked with the
            // same spectrum gradient, width 2.4.
            var core = Path(roundedRect: CGRect(x: 39 * scale, y: 39 * scale, width: 22 * scale, height: 22 * scale),
                             cornerRadius: 3 * scale)
            core = core.applying(
                CGAffineTransform(translationX: center.x, y: center.y)
                    .rotated(by: .pi / 4)
                    .translatedBy(x: -center.x, y: -center.y)
            )
            context.fill(core, with: .radialGradient(
                Gradient(stops: [
                    .init(color: .white.opacity(0.95), location: 0),
                    .init(color: AppColors.vaultRoseCore.opacity(0.85), location: 0.28),
                    .init(color: AppColors.spectrumMagenta.opacity(0.55), location: 0.7),
                    .init(color: AppColors.vaultRoseDeep.opacity(0.92), location: 1),
                ]),
                // r="80%" on the core's own 22×22 bounding box (SVG objectBoundingBox
                // default) resolves to 0.8 × 22 = 17.6 viewBox units, not a guessed value.
                center: p(47.36, 46.04), startRadius: 0, endRadius: 17.6 * scale
            ))
            context.stroke(core, with: spectrum, lineWidth: 2.4 * scale)

            // Diamond facet highlight (M50,40 L60,50 L50,60 L40,50 Z).
            var facet = Path()
            facet.move(to: p(50, 40))
            facet.addLine(to: p(60, 50))
            facet.addLine(to: p(50, 60))
            facet.addLine(to: p(40, 50))
            facet.closeSubpath()
            context.fill(facet, with: .color(.white.opacity(0.12)))

            // Sparkle dot.
            context.fill(circle(p(45.5, 45.5), 1.6 * scale), with: .color(.white))
        }
    }
}

// MARK: - Preview

#Preview("Vault door") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        VaultDoorCard(
            summary: "Where you meet · Agreements · The record",
            statLine: "7 shared · 12 sessions",
            onOpen: {}
        )
        .padding(.horizontal, AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
