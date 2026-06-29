// Features/Map/Components/MapUsLayer.swift
//
// The Us layer of the Map tab: two auras in a shared PulseField, enclosed by
// PulseCapsule, headline + copy derived from distance, and the 30-entry split grid.
//
// Visual reference: docs/prototypes/map-pulse-us.html — "A wide day" / "Same space".
//
// Layout contract (matches mockup proportions):
//   - The field fills the available content width (no hardcoded px).
//   - "You"/"Alex" tags are placed at 18% of fieldSize above/below the orb center.
//   - Copy is centered, 15pt Clash Display headline, 11pt body sublabel.
//   - VStack gaps are tight (xs) so the field dominates.

import SwiftUI

struct MapUsLayer: View {

    @Environment(PulseStore.self) private var pulse

    let stats:             MapStore.UsStats
    let align:             [MapStore.AlignItem]
    let lockedAlignCount:  Int
    var onOpenVault:       () -> Void
    var partnerPosition:   PulsePosition? = nil
    var partnerName:       String         = ""

    // MARK: - Derived state

    private var myPosition: PulsePosition {
        pulse.entries.last?.resolvedPosition ?? PulsePosition(energy: 0.5, openness: 0.5)
    }

    private var myQuadrant: PulseQuadrant { myPosition.quadrant }

    private var distance: Double {
        guard let partner = partnerPosition else { return 0 }
        return myPosition.distance(to: partner)
    }

    // "A wide day between you" vs "Close today" — FEEL: tune threshold on device.
    private var headline: String {
        guard partnerPosition != nil else { return "Pulse · together" }
        return distance > 0.45 ? "A wide day between you" : "Close today"
    }

    private var descCopy: String {
        guard let partner = partnerPosition else {
            return "Partner hasn't checked in yet today."
        }
        let pq = partner.quadrant
        let pName = partnerName.isEmpty ? "Your partner" : partnerName
        return "You're in the \(myQuadrant.spaceName); \(pName) is in the \(pq.spaceName)."
    }

    private var usGridPairs: [(mine: PulseQuadrant, partner: PulseQuadrant?)] {
        PulseHistory.pairedLastLogged(mine: pulse.entries, partner: [])
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .center, spacing: AppSpacing.xs) {
            fieldBlock
            copyBlock
            if !usGridPairs.isEmpty {
                PulseHistoryGrid(mode: .us(usGridPairs, partnerName: partnerName))
                    .padding(.top, AppSpacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Field block (fills available content width)

    private var fieldBlock: some View {
        // A clear square that fills the parent's width drives the field size.
        // GeometryReader reads the actual rendered width so PulseField + the
        // overlaid labels and capsule all share the same coordinate system.
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    let size = geo.size.width
                    ZStack {
                        PulseField(
                            entries: fieldEntries,
                            size: size,
                            showAxisLabels: true
                        )

                        if let partner = partnerPosition {
                            PulseCapsule(
                                myPosition:      myPosition,
                                partnerPosition: partner,
                                myColor:         myQuadrant.capacityColor.auraCore,
                                partnerColor:    partner.quadrant.capacityColor.auraCore,
                                fieldSize:       size
                            )
                            auraLabel("You",
                                      position: myPosition,
                                      color:    myQuadrant.capacityColor.auraCore,
                                      above:    true,
                                      fieldSize: size)
                            auraLabel(partnerName.isEmpty ? "Partner" : partnerName,
                                      position: partner,
                                      color:    partner.quadrant.capacityColor.auraCore,
                                      above:    false,
                                      fieldSize: size)
                        }
                    }
                    .frame(width: size, height: size)
                }
            }
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

    // Tag placed at 18% of fieldSize from the orb center — matches the mockup proportion.
    private func auraLabel(
        _ text:      String,
        position:    PulsePosition,
        color:       Color,
        above:       Bool,
        fieldSize:   CGFloat
    ) -> some View {
        let x  = position.openness * fieldSize
        let y  = (1 - position.energy) * fieldSize
        let dy = fieldSize * 0.18   // FEEL: tune vs the HTML mockup tag distance

        return Text(text)
            .font(.system(size: 9, weight: .bold))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(color)
            .position(x: x, y: y + (above ? -dy : dy))
    }

    // MARK: - Copy block

    private var copyBlock: some View {
        VStack(spacing: AppSpacing.xxs) {
            Text(headline)
                .font(AppFonts.display(15, weight: .semibold, relativeTo: .subheadline))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(descCopy)
                .font(AppFonts.body(11, weight: .regular, relativeTo: .footnote))
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
            .padding(.horizontal, AppSpacing.lg)
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
        ScrollView {
            MapUsLayer(
                stats: .init(),
                align: [],
                lockedAlignCount: 0,
                onOpenVault: {},
                partnerPosition: PulsePosition(energy: 0.78, openness: 0.72),
                partnerName: "Alex"
            )
            .padding(.horizontal, AppSpacing.lg)
        }
    }
    .environment({
        let s = PulseStore()
        return s
    }())
    .preferredColorScheme(.dark)
}
