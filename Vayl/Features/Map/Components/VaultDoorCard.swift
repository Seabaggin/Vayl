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
    private let spinDegrees:     Double = 60
    // FEEL: tune on device.
    private let spinToOpenDelay: Double = 0.28

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            guard !reduceMotion else {
                onOpen()
                return
            }
            withAnimation(AppAnimation.spring) { spinning = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + spinToOpenDelay) {
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

/// Six-spoke lattice emblem, ported from the mockup's vault-door SVG
/// (docs/prototypes/map-dashboard-final.html, Us/magenta gradient variant).
/// All geometry is proportional within a self-contained 100×100 coordinate
/// space; the caller's `.frame(width:height:)` scales it — no fixed pixels.
private struct VaultEmblem: View {

    private let spokeCount   = 6
    private let ringInset:   CGFloat = 6     // in the 100x100 space
    private let coreRadius:  CGFloat = 12    // in the 100x100 space

    private var spectrumGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 100
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let ringRadius = (50 - ringInset) * scale

            // Pass 1: glow (blurred, low opacity).
            drawLattice(into: &context, center: center, ringRadius: ringRadius, scale: scale, glow: true)
            // Pass 2: crisp (full opacity).
            drawLattice(into: &context, center: center, ringRadius: ringRadius, scale: scale, glow: false)
        }
    }

    private func drawLattice(
        into context: inout GraphicsContext,
        center: CGPoint,
        ringRadius: CGFloat,
        scale: CGFloat,
        glow: Bool
    ) {
        var layer = context

        if glow {
            layer.addFilter(.blur(radius: 3 * scale))
            layer.opacity = 0.35
        } else {
            layer.opacity = 1.0
        }

        // Outer ring.
        var ring = Path()
        ring.addEllipse(in: CGRect(
            x: center.x - ringRadius, y: center.y - ringRadius,
            width: ringRadius * 2, height: ringRadius * 2
        ))
        layer.stroke(ring, with: .color(AppColors.spectrumPurple), lineWidth: (glow ? 3 : 1.4) * scale)

        // Six spokes at 60° increments, from the core edge to the ring.
        for i in 0..<spokeCount {
            let angle = Angle(degrees: Double(i) * 360.0 / Double(spokeCount) - 90)
            let inner = CGPoint(
                x: center.x + cos(angle.radians) * coreRadius * scale,
                y: center.y + sin(angle.radians) * coreRadius * scale
            )
            let outer = CGPoint(
                x: center.x + cos(angle.radians) * ringRadius,
                y: center.y + sin(angle.radians) * ringRadius
            )
            var spoke = Path()
            spoke.move(to: inner)
            spoke.addLine(to: outer)
            layer.stroke(spoke, with: .color(AppColors.spectrumCyan), lineWidth: (glow ? 2.5 : 1 ) * scale)
        }

        // Rotated-square core with a bright highlight.
        let coreRect = CGRect(
            x: center.x - coreRadius * scale, y: center.y - coreRadius * scale,
            width: coreRadius * 2 * scale, height: coreRadius * 2 * scale
        )
        var core = Path()
        core.addRect(coreRect)
        let rotatedCore = core.applying(
            CGAffineTransform(translationX: center.x, y: center.y)
                .rotated(by: .pi / 4)
                .translatedBy(x: -center.x, y: -center.y)
        )
        layer.fill(rotatedCore, with: .color(AppColors.spectrumMagenta.opacity(glow ? 0.4 : 0.85)))

        if !glow {
            var highlight = Path()
            let hl = coreRadius * 0.4 * scale
            highlight.addEllipse(in: CGRect(
                x: center.x - hl, y: center.y - hl, width: hl * 2, height: hl * 2
            ))
            layer.fill(highlight, with: .color(.white.opacity(0.8)))
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
