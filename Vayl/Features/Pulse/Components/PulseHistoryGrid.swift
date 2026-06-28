// Features/Pulse/Components/PulseHistoryGrid.swift
//
// A 10-column grid of the user's last 30 check-ins — never "last 30 days."
//
// Me mode  — solid circles filled with the tier colour of each quadrant.
// Us mode  — split circles: top-left half = your colour, bottom-right half =
//            partner's colour. Solid when quadrants match or partner half is nil.
//
// Visual reference: docs/prototypes/map-pulse-us.html — .grid / .sgd

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
                    Circle()
                        .fill(cells[i])
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }

    // MARK: - Cell fill

    private func cellFill(mine: PulseQuadrant, partner: PulseQuadrant?) -> AnyShapeStyle {
        let myColor = mine.capacityColor.auraCore

        guard let partner, partner != mine else {
            return AnyShapeStyle(myColor)
        }

        // Diagonal split matching CSS `linear-gradient(135deg, --a 0 50%, --b 50% 100%)`:
        // colour A (you) occupies the top-left half, colour B (partner) the bottom-right.
        return AnyShapeStyle(
            LinearGradient(
                stops: [
                    .init(color: myColor,                    location: 0),
                    .init(color: myColor,                    location: 0.5),
                    .init(color: partner.capacityColor.auraCore, location: 0.5),
                    .init(color: partner.capacityColor.auraCore, location: 1),
                ],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing
            )
        )
    }

    private var cells: [AnyShapeStyle] {
        switch mode {
        case .me(let quadrants):
            return quadrants.map { cellFill(mine: $0, partner: nil) }
        case .us(let pairs, _):
            return pairs.map { cellFill(mine: $0.mine, partner: $0.partner) }
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

// MARK: - Preview

#Preview("Me — solid") {
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
