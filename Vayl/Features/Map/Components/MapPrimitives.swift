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
    var linkLabel: String? = nil
    var onLink: (() -> Void)? = nil

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
// Icon + headline + sub-label per the CLAUDE.md empty-state spec. Every Map data
// block routes its empty/forming case through this, so they all read alike.

struct MapEmptyState: View {
    let icon: String
    let headline: String
    let message: String

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(AppFonts.body(26, weight: .regular, relativeTo: .title2))
                .fontWeight(.light)
                .foregroundStyle(AppColors.textTertiary)
            Text(headline)
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textSecondary)
            Text(message)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
        .padding(.horizontal, AppSpacing.lg)
    }
}

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
