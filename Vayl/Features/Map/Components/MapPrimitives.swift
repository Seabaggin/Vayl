//
//  MapPrimitives.swift
//  Vayl
//
//  Small shared building blocks for the Map tab: the section eyebrow, the empty /
//  forming state (cohesion rule #7), and the Record's category colour mapping.
//  Kept in one place so every Map surface speaks the same visual language.
//

import SwiftUI

// MARK: - Section header (eyebrow + optional trailing link)

struct MapSectionHeader: View {
    let title: String
    var linkLabel: String?
    var onLink: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(AppFonts.overline)
                .tracking(1.2)
                .foregroundStyle(AppColors.textTertiary)
            Spacer()
            if let linkLabel, let onLink {
                Button(action: onLink) {
                    Text(linkLabel)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.accentSecondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Empty / forming state
//
// Now the shared `VaylEmptyState` (Design/Components/VaylEmptyState.swift). The
// Map alias is kept so every Map data block's existing `MapEmptyState(...)` call
// site stays put while the component lives app-wide.

typealias MapEmptyState = VaylEmptyState

// MARK: - Deck category colour (Map-local)
//
// No canonical per-category colour exists in the system, so this is a Map-local
// spectrum mapping for the Record's distribution bar + row dots. Tokens only.

extension DeckCategory {
    var mapColor: Color {
        switch self {
        case .foundationEntry:     return AppColors.spectrumCyan
        case .relationshipCore:    return AppColors.accentPrimary
        case .nmSpecific:          return AppColors.spectrumMagenta
        case .styleSpecific:       return AppColors.spectrumPurple
        case .experienceArc:       return AppColors.accentSecondary
        case .identityDynamics:    return AppColors.pulseTierSovereign
        case .advancedExperienced: return AppColors.pulseTierFriction
        case .soloPrep:            return AppColors.pulseTierProtective
        case .wildcard:            return AppColors.accentTertiary
        case .multiPerson:         return AppColors.pulseTierExpansive
        }
    }
}

// MARK: - Flow layout (wrapping chip cloud)
//
// A minimal wrapping layout for the Me Card's Drawn-to tags + the Title / Flavor
// choosers. Lays subviews left to right, wrapping to a new row when the proposed
// width runs out.

struct FlowLayout: Layout {
    var spacing: CGFloat = AppSpacing.xs

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        let width = maxWidth == .infinity ? x : maxWidth
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
