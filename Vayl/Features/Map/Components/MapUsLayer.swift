// Features/Map/Components/MapUsLayer.swift
//
// The Us layer of the Map tab: two auras in a shared PulseField, enclosed by
// PulseCapsule, with a headline + descriptive copy derived from distance.
//
// `partnerPosition` is nil until Segment 7 wires PulseSyncService; the view
// shows a placeholder when unpaired or before sync arrives.
//
// Visual reference: docs/prototypes/map-pulse-us.html — "A wide day" / "Same space".

import SwiftUI

struct MapUsLayer: View {

    @Environment(PulseStore.self) private var pulse

    let stats:             MapStore.UsStats
    let align:             [MapStore.AlignItem]
    let lockedAlignCount:  Int
    var onOpenVault:       () -> Void
    var partnerPosition:   PulsePosition? = nil
    var partnerName:       String         = ""

    private let fieldSize: CGFloat = 240

    // MARK: - Derived state

    private var myPosition: PulsePosition {
        pulse.entries.last?.resolvedPosition ?? PulsePosition(energy: 0.5, openness: 0.5)
    }

    private var myQuadrant: PulseQuadrant { myPosition.quadrant }

    private var distance: Double {
        guard let partner = partnerPosition else { return 0 }
        return myPosition.distance(to: partner)
    }

    // "A wide day between you" (>0.45) vs "Close today" (≤0.45).
    // FEEL: tune threshold on device vs the mockup's two states.
    private var headline: String {
        guard partnerPosition != nil else { return "Pulse · together" }
        return distance > 0.45 ? "A wide day between you" : "Close today"
    }

    private var usGridPairs: [(mine: PulseQuadrant, partner: PulseQuadrant?)] {
        // Until Segment 7 wires PulseSyncService, partner entries are unavailable
        // and carry-forward yields all-nil partner halves (solid my-colour cells).
        PulseHistory.pairedLastLogged(mine: pulse.entries, partner: [])
    }

    private var descCopy: String {
        guard let partner = partnerPosition else {
            return "Partner hasn't checked in yet today."
        }
        let pq = partner.quadrant
        let myName = "You"
        let pName = partnerName.isEmpty ? "Your partner" : partnerName
        return "\(myName) are in the \(myQuadrant.spaceName); \(pName) is in the \(pq.spaceName)."
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            fieldBlock
            copyBlock
            if !usGridPairs.isEmpty {
                PulseHistoryGrid(mode: .us(usGridPairs, partnerName: partnerName))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Field block

    private var fieldBlock: some View {
        ZStack {
            PulseField(
                entries: fieldEntries,
                size: fieldSize,
                showAxisLabels: true
            )

            if let partner = partnerPosition {
                PulseCapsule(
                    myPosition: myPosition,
                    partnerPosition: partner,
                    myColor: myQuadrant.capacityColor.auraCore,
                    partnerColor: partner.quadrant.capacityColor.auraCore,
                    fieldSize: fieldSize
                )

                // "You" label
                auraLabel(
                    "You",
                    position: myPosition,
                    color: myQuadrant.capacityColor.auraCore,
                    above: true
                )
                // Partner label
                auraLabel(
                    partnerName.isEmpty ? "Partner" : partnerName,
                    position: partner,
                    color: partner.quadrant.capacityColor.auraCore,
                    above: false
                )
            }
        }
        .frame(width: fieldSize, height: fieldSize)
        .frame(maxWidth: .infinity)
    }

    private var fieldEntries: [PulseFieldEntry] {
        var entries: [PulseFieldEntry] = [
            PulseFieldEntry(id: "me", position: myPosition, auraSize: 44)
        ]
        if let partner = partnerPosition {
            entries.append(PulseFieldEntry(id: "partner", position: partner, auraSize: 44))
        }
        return entries
    }

    private func auraLabel(_ text: String, position: PulsePosition, color: Color, above: Bool) -> some View {
        let x = position.openness * fieldSize
        let y = (1 - position.energy) * fieldSize
        let labelOffsetY: CGFloat = above ? -35 : 35

        return Text(text)
            .font(.system(size: 9, weight: .bold))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(color)
            .position(x: x, y: y + labelOffsetY)
    }

    // MARK: - Copy block

    private var copyBlock: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(headline)
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(descCopy)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Wide day") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        ScrollView {
            MapUsLayer(
                stats: .init(),
                align: [],
                lockedAlignCount: 0,
                onOpenVault: {},
                partnerPosition: PulsePosition(energy: 0.18, openness: 0.22),
                partnerName: "Alex"
            )
            .padding(AppSpacing.lg)
        }
    }
    .environment({
        let s = PulseStore()
        return s
    }())
    .preferredColorScheme(.dark)
}

#Preview("Same space") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        MapUsLayer(
            stats: .init(),
            align: [],
            lockedAlignCount: 0,
            onOpenVault: {},
            partnerPosition: PulsePosition(energy: 0.78, openness: 0.72),
            partnerName: "Alex"
        )
        .padding(AppSpacing.lg)
    }
    .environment({
        let s = PulseStore()
        return s
    }())
    .preferredColorScheme(.dark)
}
