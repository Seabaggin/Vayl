//
//  ConstellationField.swift
//  Vayl
//
//  Lays out DesireStarView atoms at deterministic phyllotaxis positions and
//  draws constellation lines between proximate nodes.
//
//  1 node  → single hero star centred, no lines.
//  2+ nodes → golden-angle spread without crowding; lines connect proximate pairs.
//
//  Line modes:
//    .hidden    — no lines drawn
//    .hesitant  — thin white lines that draw partway and pull back on a loop,
//                 never fully connecting (used on the rater's charted finish beat)
//    .confident — lines draw on once and hold (used on the reveal)
//
//  Reduce Motion:
//    .hesitant  → static faint partial draw (no loop)
//    .confident → lines appear at full opacity with a fast cross-fade (no draw-on)
//

import SwiftUI

// MARK: - Line mode

enum ConstellationLineMode {
    case hidden
    case hesitant
    case confident
}

// MARK: - Node data

struct ConstellationNodeData: Identifiable {
    let id: String
    var size: CGFloat = 14
    var state: DesireStarView.StarState = .lit
    var label: String? = nil
    var cadence: DesireStarView.Cadence = .free
}

// MARK: - ConstellationField

struct ConstellationField: View {

    var nodes: [ConstellationNodeData]
    var lineMode: ConstellationLineMode = .hidden
    /// Called with the node's `id` string when the user taps a star.
    var onNodeTapped: ((String) -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hesitantTrim: Double = 0.0
    @State private var confidentTrim: Double = 0.0
    /// Drives the looping hesitant sketch through .ambientAnimation (the canonical
    /// Reduce-Motion gate), toggled on appear instead of a bare repeatForever.
    @State private var hesitantAnimating = false

    var body: some View {
        GeometryReader { geo in
            let fieldSize = geo.size
            let positions = nodePositions(count: nodes.count, in: fieldSize)
            let connections = proximateConnections(positions: positions, in: fieldSize)

            ZStack {
                // ── Lines ──────────────────────────────────
                // Path + .trim() participates in SwiftUI's animation interpolation;
                // Canvas does not — keep lines as view-layer Paths.
                if lineMode != .hidden, nodes.count > 1 {
                    if lineMode == .hesitant {
                        // Looping sketch goes through .ambientAnimation (the canonical
                        // Reduce-Motion gate). Scoped to .hesitant so it never clobbers
                        // the .confident draw-on, which owns its own withAnimation.
                        lineLayer(connections: connections, positions: positions)
                            .ambientAnimation(
                                .easeInOut(duration: AppAnimation.desireHesitantSketch / 2)
                                    .repeatForever(autoreverses: true),
                                value: hesitantAnimating
                            )
                    } else {
                        lineLayer(connections: connections, positions: positions)
                    }
                }

                // ── Stars ──────────────────────────────────
                ForEach(Array(nodes.enumerated()), id: \.element.id) { i, node in
                    DesireStarView(
                        size: node.size,
                        state: node.state,
                        label: node.label,
                        cadence: node.cadence
                    )
                    .position(positions[i])
                    .onTapGesture { onNodeTapped?(node.id) }
                }
            }
        }
        .onAppear { startLineAnimation() }
    }

    // MARK: - Line layer

    @ViewBuilder
    private func lineLayer(connections: [(Int, Int)], positions: [CGPoint]) -> some View {
        let trim = lineMode == .hesitant ? hesitantTrim : confidentTrim
        let lineOpacity = lineMode == .hesitant ? 0.18 : 0.34

        ZStack {
            ForEach(Array(connections.enumerated()), id: \.offset) { _, conn in
                Path { path in
                    path.move(to: positions[conn.0])
                    path.addLine(to: positions[conn.1])
                }
                .trim(from: 0, to: trim)
                .stroke(
                    Color.white.opacity(lineOpacity),
                    style: StrokeStyle(lineWidth: 0.7, lineCap: .round)
                )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Layout

    // Vogel phyllotaxis (sunflower) — positions are a pure function of index and count.
    // Golden angle ≈ 137.508° ensures no two stars share the same radial spoke.
    // maxRadius uses 40% of the shorter dimension, leaving a margin for the star halos.
    private func nodePositions(count: Int, in size: CGSize) -> [CGPoint] {
        guard count > 0, size.width > 0, size.height > 0 else { return [] }
        guard count > 1 else {
            return [CGPoint(x: size.width / 2, y: size.height / 2)]
        }

        let goldenAngle: CGFloat = 2.399963229728653 // 137.508° in radians
        let maxRadius = min(size.width, size.height) * 0.40
        let cx = size.width / 2
        let cy = size.height / 2

        return (0..<count).map { i in
            // (i + 0.5) / count: no star at exact centre, even spread from ring 0 out.
            let r = maxRadius * sqrt((CGFloat(i) + 0.5) / CGFloat(count))
            let theta = CGFloat(i) * goldenAngle
            return CGPoint(
                x: cx + r * cos(theta),
                y: cy + r * sin(theta)
            )
        }
    }

    // Connect any two stars closer than 45% of the shorter canvas dimension.
    // This produces 2–6 connections for typical node counts (3–10) without
    // creating a fully-connected graph.
    private func proximateConnections(positions: [CGPoint], in size: CGSize) -> [(Int, Int)] {
        guard positions.count > 1, size.width > 0 else { return [] }
        let threshold = min(size.width, size.height) * 0.45
        var result: [(Int, Int)] = []
        for i in 0..<positions.count {
            for j in (i + 1)..<positions.count {
                let dx = positions[i].x - positions[j].x
                let dy = positions[i].y - positions[j].y
                if sqrt(dx * dx + dy * dy) < threshold {
                    result.append((i, j))
                }
            }
        }
        return result
    }

    // MARK: - Animation

    private func startLineAnimation() {
        switch lineMode {
        case .hidden:
            break

        case .hesitant:
            if reduceMotion {
                // Static faint partial — suggests lines without completing them.
                hesitantTrim = 0.42
            } else {
                // Draws toward 0.65, reverses, never fully connects. The looping
                // animation lives on the line layer via .ambientAnimation (which
                // carries the Reduce-Motion gate); toggling hesitantAnimating starts it.
                hesitantTrim = 0.65
                hesitantAnimating = true
            }

        case .confident:
            withAnimation(reduceMotion
                ? .easeOut(duration: 0.15)
                : AppAnimation.desireLineDraw
            ) {
                confidentTrim = 1.0
            }
        }
    }
}

// MARK: - Previews

private func sampleNodes(_ count: Int, allLit: Bool = true) -> [ConstellationNodeData] {
    let labels = ["Shared space", "Deep talk", "New together", "Our ritual",
                  "Adventure", "Quiet time", "Openness", "Play", "Growth"]
    return (0..<count).map { i in
        ConstellationNodeData(
            id: "n\(i)",
            size: 14,
            state: allLit ? .lit : (i == 0 ? .lit : .dim),
            label: count > 2 ? labels[i % labels.count] : nil,
            cadence: i == 0 ? .free : .locked
        )
    }
}

#Preview("1 node — hero") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        ConstellationField(nodes: sampleNodes(1), lineMode: .hidden)
            .frame(width: 300, height: 280)
    }
}

#Preview("3 nodes — hesitant") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        ConstellationField(nodes: sampleNodes(3), lineMode: .hesitant)
            .frame(width: 300, height: 280)
    }
}

#Preview("3 nodes — confident") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        ConstellationField(nodes: sampleNodes(3), lineMode: .confident)
            .frame(width: 300, height: 280)
    }
}

#Preview("5 nodes — hesitant") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        ConstellationField(nodes: sampleNodes(5), lineMode: .hesitant)
            .frame(width: 300, height: 280)
    }
}

#Preview("5 nodes — confident") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        ConstellationField(nodes: sampleNodes(5), lineMode: .confident)
            .frame(width: 300, height: 280)
    }
}

#Preview("5 nodes — lit + dim mix") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        ConstellationField(nodes: sampleNodes(5, allLit: false), lineMode: .confident)
            .frame(width: 300, height: 280)
    }
}
