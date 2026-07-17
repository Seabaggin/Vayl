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

    let layout: AppLayout
    let stats: MapStore.UsStats
    let align: [MapStore.AlignItem]
    let lockedAlignCount: Int
    /// The couple's active-agreement count, for the vault door's stat line
    /// ("‹shared› shared · ‹agreements› agreements · ‹sessions› sessions" —
    /// the mockup's door shows all three; this was the missing one).
    var agreementsCount: Int = 0
    var onOpenVault: () -> Void
    var onCheckIn: () -> Void
    var onOpenPulse: (() -> Void)?
    var partnerPosition: PulsePosition?
    var partnerEntries: [PulseEntry]    = []
    var partnerName: String          = ""

    // MARK: - Derived state

    private var myPosition: PulsePosition { pulse.currentPosition }

    /// Full six-space classification. Uncharted is recovered from stored answers where an
    /// entry exists, else resolved from the position alone (the partner-position-only case).
    private var mySpace: PulseSpace { pulse.entries.last?.space ?? PulseSpace.resolve(myPosition) }

    private func partnerSpace(_ pos: PulsePosition) -> PulseSpace {
        partnerLastEntry?.space ?? PulseSpace.resolve(pos)
    }

    /// The UsOrbState computed ONCE per body render and threaded through to the
    /// card and its helpers — never re-derived (review note from Task 1).
    private var usOrbState: UsOrbState {
        UsOrbState.resolve(mine: pulse.entries, partner: partnerEntries)
    }

    /// False for a user who has never checked in at all — distinct from "no partner
    /// data yet." Without this, `myPosition` falls back to dead-center, which resolves
    /// to .expansive (the tie-break rule), fabricating a real-looking reading for
    /// someone who's never logged anything.
    private var hasHistory: Bool { !pulse.entries.isEmpty }

    private var partnerLastEntry: PulseEntry? { partnerEntries.last }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .center, spacing: AppSpacing.xs) {
            usPulseCard
            if pulse.canCheckInToday {
                checkInPill
                    .padding(.top, AppSpacing.xxs)
            }
            // Lens symmetry (2026-07-17): Me's hero grew an inline collapsed history
            // strip, so Us grows the same one in its own mode (split you/partner beads).
            // Me-only would have broken the dashboard spec's governing rule — "Me is
            // never a smaller copy of Us" — by giving the two lenses different heights
            // and different content shapes. Same component, one mode apart.
            if !usGridPairs.isEmpty {
                PulseHistoryGrid(
                    mode: .us(usGridPairs, partnerName: partnerName),
                    collapsible: true
                )
                .padding(.top, AppSpacing.lg)
            }
            vaultDoorCard
                .padding(.top, AppSpacing.sm)
        }
        .frame(maxWidth: .infinity)
    }

    /// The paired last-30 for the inline strip. Same helper `PulseFullView` uses, so the
    /// dashboard strip and the pillar's grid can never disagree.
    private var usGridPairs: [(date: Date, mine: PulseSpace, partner: PulseSpace?)] {
        PulseHistory.pairedLastLoggedSpaces(mine: pulse.entries, partner: partnerEntries)
    }

    // MARK: - Vault door

    private var vaultDoorCard: some View {
        VaultDoorCard(
            summary: "Where you meet · Agreements · The record",
            statLine: "\(align.filter(\.isMutual).count) shared · \(agreementsCount) agreement\(agreementsCount == 1 ? "" : "s") · \(stats.sessionCount) session\(stats.sessionCount == 1 ? "" : "s")",
            onOpen: onOpenVault
        )
    }

    // MARK: - Us Pulse card

    private var usPulseCard: some View {
        let state = usOrbState
        return MapUsPulseCard(
            layout: layout,
            state: state,
            // rampStatic, not ramp(at:) — the Us orb names two spaces with no field under
            // it, so each half's colour must back its name up (rule: colour blends only
            // where position is visible; see PulseSpace.ramp(at:)). It matters more here
            // than anywhere: the whole card is a COMPARISON, and two blended halves drift
            // toward the same grey-lavender, which reads as "you're aligned" when the
            // headline says a step apart.
            myAura: mySpace.rampStatic,
            partnerAura: partnerPosition.map { partnerSpace($0).rampStatic } ?? .neutral,
            myLastEntry: pulse.entries.last,
            partnerLastEntry: partnerLastEntry,
            mySpaceName: mySpace.displayName,
            partnerSpaceName: partnerPosition.map { partnerSpace($0).displayName } ?? "",
            partnerName: partnerName,
            myPosition: hasHistory ? myPosition : nil,
            partnerPosition: partnerPosition,
            relativeDay: pulse.relativeDay(for:),
            onTap: onOpenPulse
        )
    }

    // MARK: - Check-in (the Us lens previously had no way to check in at all —
    // you had to switch to Me first). Same plain capsule treatment as Home's and
    // Map-Me's check-in pill, just reachable from here too. Hidden entirely once
    // today's entry has locked (see PulseStore.canCheckInToday) — a completed
    // check-in is a sealed snapshot, not something to keep revising.
    private var checkInPill: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onCheckIn()
        } label: {
            Text(pulse.todayEntry == nil ? "Check in" : "Edit check-in")
                .font(AppFonts.buttonLabelSmall)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xxs)
                .overlay(
                    Capsule().strokeBorder(AppColors.borderDefault, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(pulse.todayEntry == nil ? "Check in" : "Edit today's check-in")
    }
}

// MARK: - Preview

#Preview("Wide day") {
    // GeometryReader, not a hand-built AppLayout: the preview resolves hero scale
    // the same way the device does (Void Rule clause 2).
    GeometryReader { geo in
        ZStack {
            AppColors.void.ignoresSafeArea()
            OnboardingAtmosphere(config: .stat).ignoresSafeArea()
            ScrollView {
                MapUsLayer(
                    layout: AppLayout.from(geo),
                    stats: .init(),
                    align: [],
                    lockedAlignCount: 0,
                    onOpenVault: {},
                    onCheckIn: {},
                    partnerPosition: PulsePosition(energy: 0.18, openness: 0.22),
                    partnerName: "Alex"
                )
                .padding(.horizontal, AppSpacing.lg)
            }
        }
    }
    .environment({
        let s = PulseStore()
        return s
    }())
    .preferredColorScheme(.dark)
}

#Preview("Same space") {
    GeometryReader { geo in
        ZStack {
            AppColors.void.ignoresSafeArea()
            OnboardingAtmosphere(config: .stat).ignoresSafeArea()
            ScrollView {
                MapUsLayer(
                    layout: AppLayout.from(geo),
                    stats: .init(),
                    align: [],
                    lockedAlignCount: 0,
                    onOpenVault: {},
                    onCheckIn: {},
                    partnerPosition: PulsePosition(energy: 0.78, openness: 0.72),
                    partnerName: "Alex"
                )
                .padding(.horizontal, AppSpacing.lg)
            }
        }
    }
    .environment({
        let s = PulseStore()
        return s
    }())
    .preferredColorScheme(.dark)
}
