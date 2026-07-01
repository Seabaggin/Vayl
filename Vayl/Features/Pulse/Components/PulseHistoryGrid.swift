// Features/Pulse/Components/PulseHistoryGrid.swift
//
// A 10-column grid of the user's last 30 check-ins — never "last 30 days."
//
// Each cell is a flat tinted-glass chip: a single tier colour (no 3D radial
// shading), a soft top sheen, and a bright-top / faint-bottom glass rim — the
// aura palette read as glass, cheap enough for 30 cells (no Canvas, no
// animation, no per-cell blur).
//
// Me mode — one glossy orb per cell in the quadrant's tier colour.
// Us mode — split bead: your colour fills the top-left half, partner's the
//           bottom-right, seamed on the diagonal. Solid when you shared a space.
//
// Visual reference: docs/prototypes/map-pulse-us.html — .grid / .sgd (upgraded).

import SwiftUI

struct PulseHistoryGrid: View {

    enum Mode {
        case me([PulseQuadrant])
        case us([(mine: PulseQuadrant, partner: PulseQuadrant?)], partnerName: String)
    }

    let mode: Mode

    // MARK: - Layout

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 10)

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label)
                .font(AppFonts.overline)
                .foregroundStyle(AppColors.textTertiary)

            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(cells.indices, id: \.self) { i in
                    AuraDot(tier: cells[i].mine, partner: cells[i].partner)
                }
            }
        }
    }

    // MARK: - Cell model

    /// Each cell: the user's tier colour, plus the partner's when they differ
    /// (nil = solid, i.e. same space or Me mode).
    private var cells: [(mine: PulseCapacityColor, partner: PulseCapacityColor?)] {
        switch mode {
        case .me(let quadrants):
            return quadrants.map { ($0.capacityColor, nil) }
        case .us(let pairs, _):
            return pairs.map { pair in
                guard let partner = pair.partner, partner != pair.mine else {
                    return (pair.mine.capacityColor, nil)
                }
                return (pair.mine.capacityColor, partner.capacityColor)
            }
        }
    }

    // MARK: - Label

    private var label: String {
        switch mode {
        case .me:
            return "Your last 30 check-ins"
        case .us(_, let name):
            let displayName = name.isEmpty ? "partner" : name
            return "Your last 30 check-ins · you / \(displayName)"
        }
    }
}

// MARK: - Aura dot (static glossy orb)

private struct AuraDot: View {

    let tier: PulseCapacityColor
    var partner: PulseCapacityColor? = nil

    var body: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height)
            orb(d)
                .frame(width: d, height: d)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func orb(_ d: CGFloat) -> some View {
        ZStack {
            // Flat tinted glass — one colour per half, no 3D radial shading.
            ZStack {
                if let partner {
                    Circle().fill(tier.auraCore)
                        .clipShape(DiagonalHalf(topLeading: true))
                    Circle().fill(partner.auraCore)
                        .clipShape(DiagonalHalf(topLeading: false))
                    SeamLine()
                        .stroke(AppColors.borderActive, lineWidth: max(0.5, d * 0.02))
                } else {
                    Circle().fill(tier.auraCore)
                }

                // Glass sheen — soft reflected light across the upper half.
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.24), .white.opacity(0.04), .clear],
                            startPoint: .top, endPoint: .center
                        )
                    )
            }
            .clipShape(Circle())

            // Glass edge — bright top rim fading to faint bottom.
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.45), .white.opacity(0.08)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: max(0.6, d * 0.035)
                )
        }
    }
}

// The you/partner split runs along the anti-diagonal (top-right → bottom-left),
// matching the mockup's `linear-gradient(135deg, a 0 50%, b 50% 100%)`.
private struct DiagonalHalf: Shape {
    let topLeading: Bool
    func path(in r: CGRect) -> Path {
        var p = Path()
        if topLeading {
            p.move(to: CGPoint(x: r.minX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        } else {
            p.move(to: CGPoint(x: r.maxX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        }
        p.closeSubpath()
        return p
    }
}

private struct SeamLine: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        return p
    }
}

// MARK: - Preview

#Preview("Me — glossy") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        PulseHistoryGrid(mode: .me(previewMeQuadrants))
            .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}

#Preview("Us — split") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        PulseHistoryGrid(mode: .us(previewUsPairs, partnerName: "Alex"))
            .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}

private let previewMeQuadrants: [PulseQuadrant] = [
    .expansive, .expansive, .sovereign, .expansive, .expansive,
    .sovereign, .expansive, .expansive, .friction,  .expansive,
    .sovereign, .expansive, .expansive, .sovereign, .expansive,
    .expansive, .sovereign, .expansive, .expansive, .expansive,
    .expansive, .sovereign, .expansive, .expansive, .sovereign,
    .expansive, .expansive, .protective,.expansive, .expansive,
]

private let previewUsPairs: [(mine: PulseQuadrant, partner: PulseQuadrant?)] = [
    (.expansive, .sovereign), (.expansive, .expansive), (.sovereign, .sovereign),
    (.expansive, .protective),(.expansive, .expansive), (.sovereign, .expansive),
    (.expansive, .expansive), (.expansive, .sovereign), (.friction,  .protective),
    (.expansive, .expansive), (.sovereign, .sovereign), (.expansive, .sovereign),
    (.expansive, .expansive), (.sovereign, .friction),  (.expansive, .expansive),
    (.expansive, .sovereign), (.sovereign, .sovereign), (.expansive, .expansive),
    (.expansive, .protective),(.expansive, .expansive), (.expansive, .expansive),
    (.sovereign, .expansive), (.expansive, .expansive), (.expansive, .sovereign),
    (.sovereign, .sovereign), (.expansive, .expansive), (.expansive, .protective),
    (.expansive, .expansive), (.expansive, .expansive), (.expansive, .expansive),
]
