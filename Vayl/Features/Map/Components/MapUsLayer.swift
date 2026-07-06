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
    var onCheckIn:         () -> Void
    var partnerPosition:   PulsePosition?  = nil
    var partnerEntries:    [PulseEntry]    = []
    var partnerName:       String          = ""

    // MARK: - Derived state

    private var myPosition: PulsePosition { pulse.currentPosition }

    /// Full six-space classification. Uncharted is recovered from stored answers where an
    /// entry exists, else resolved from the position alone (the partner-position-only case).
    private var mySpace: PulseSpace { pulse.entries.last?.space ?? PulseSpace.resolve(myPosition) }

    private func partnerSpace(_ pos: PulsePosition) -> PulseSpace {
        partnerLastEntry?.space ?? PulseSpace.resolve(pos)
    }

    private var distance: Double {
        guard let partner = partnerPosition else { return 0 }
        return myPosition.distance(to: partner)
    }

    // "A wide day between you" vs "Close today" — FEEL: tune threshold on device.
    // Neither reading is claimed to be "today" unless both actually are.
    private var headline: String {
        guard partnerPosition != nil else {
            return partnerName.isEmpty ? "Pulse · together" : "\(partnerName) hasn't checked in"
        }
        guard !myStale, !partnerStale else { return "Comparing your last Pulses" }
        return distance > 0.45 ? "A wide day between you" : "Close today"
    }

    // Each person's freshness is named independently — a fresh reading gets present
    // tense, a stale one gets "was last in … (N days ago)", so the comparison never
    // implies both are today's unless both actually are.
    private var descCopy: String {
        guard let partner = partnerPosition else {
            return partnerName.isEmpty
                ? "Check in to see how you and your partner compare."
                : "Their space fills in the moment they take a reading."
        }
        let pName = partnerName.isEmpty ? "Your partner" : partnerName

        let myPhrase: String = {
            guard myStale, let mine = pulse.entries.last else {
                return "You're in the \(mySpace.displayName)"
            }
            return "You were last in the \(mySpace.displayName) (\(pulse.relativeDay(for: mine.date)))"
        }()

        let partnerPhrase: String = {
            guard partnerStale, let last = partnerLastEntry else {
                return "\(pName) is in the \(partnerSpace(partner).displayName)"
            }
            return "\(pName) was last in the \(partnerSpace(partner).displayName) (\(pulse.relativeDay(for: last.date)))"
        }()

        return "\(myPhrase); \(partnerPhrase)."
    }

    private var usGridPairs: [(date: Date, mine: PulseSpace, partner: PulseSpace?)] {
        PulseHistory.pairedLastLoggedSpaces(mine: pulse.entries, partner: partnerEntries)
    }

    /// False for a user who has never checked in at all — distinct from "no partner
    /// data yet." Without this, `myPosition` falls back to dead-center, which resolves
    /// to .expansive (the tie-break rule), fabricating a real-looking reading for
    /// someone who's never logged anything.
    private var hasHistory: Bool { !pulse.entries.isEmpty }

    /// Mirrors PulseStore.isPositionStale but scoped to this layer's own copy.
    private var myStale: Bool { pulse.isPositionStale }

    private var partnerLastEntry: PulseEntry? { partnerEntries.last }

    /// True when the partner has logged before, but not today. Independent of
    /// `myStale` — the two people's freshness can differ.
    private var partnerStale: Bool {
        guard let last = partnerLastEntry else { return false }
        return !Calendar.current.isDateInToday(last.date)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .center, spacing: AppSpacing.xs) {
            if hasHistory {
                fieldBlock
                copyBlock
            } else {
                emptyStateBlock
            }
            if pulse.canCheckInToday {
                checkInPill
                    .padding(.top, AppSpacing.xxs)
            }
            if !usGridPairs.isEmpty {
                PulseHistoryGrid(mode: .us(usGridPairs, partnerName: partnerName))
                    .padding(.top, AppSpacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty state (never checked in)

    private var emptyStateBlock: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 28))
                .foregroundStyle(AppColors.textTertiary)
            Text("No Pulse yet")
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text("Check in to see how you and \(partnerName.isEmpty ? "your partner" : partnerName) compare.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
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
                    // Aura diameter as a ratio of the field, not a fixed pt — matches the
                    // mockup's 44/248 ≈ 0.177 so orbs (and the capsule derived from them)
                    // scale with the full-width field instead of reading small.
                    let auraSize = size * 0.177
                    ZStack {
                        PulseField(
                            entries: fieldEntries(auraSize: auraSize),
                            size: size,
                            showAxisLabels: true
                        )

                        if let partner = partnerPosition {
                            PulseCapsule(
                                myPosition:      myPosition,
                                partnerPosition: partner,
                                myColor:         mySpace.dotCoreStatic,
                                partnerColor:    partnerSpace(partner).dotCoreStatic,
                                fieldSize:       size,
                                auraSize:        auraSize
                            )
                            auraLabel("You",
                                      position: myPosition,
                                      color:    mySpace.dotCoreStatic,
                                      above:    true,
                                      fieldSize: size)
                            auraLabel(partnerName.isEmpty ? "Partner" : partnerName,
                                      position: partner,
                                      color:    partnerSpace(partner).dotCoreStatic,
                                      above:    false,
                                      fieldSize: size)
                        } else if !partnerName.isEmpty {
                            // Partner is paired but hasn't logged yet — echo the same cycling
                            // four-space aura Home/Map-Me use for "no reading yet," tagged with
                            // their name, so their half of the field reads as waiting, not broken.
                            // Matches map-pulse-coldstart.html's "Us, partner not yet" card
                            // (including its illustrative placement — there's no real reading to
                            // place, this position is fixed, not derived from any data).
                            let waitingPos = PulsePosition(energy: 0.30, openness: 0.30)
                            let waitingPt  = CGPoint(x: waitingPos.openness * size, y: (1 - waitingPos.energy) * size)
                            PulseCyclingAura(size: auraSize)
                                .position(x: waitingPt.x, y: waitingPt.y)
                            auraLabel("\(partnerName) · not yet",
                                      position: waitingPos,
                                      color:    AppColors.textTertiary,
                                      above:    false,
                                      fieldSize: size)
                        }
                    }
                    .frame(width: size, height: size)
                }
            }
    }

    private func fieldEntries(auraSize: CGFloat) -> [PulseFieldEntry] {
        var entries: [PulseFieldEntry] = [
            PulseFieldEntry(
                id:       "me",
                position: myPosition,
                auraSize: auraSize,
                opacity:  myStale ? PulseFieldEntry.staleOpacity : 1.0,
                space:    mySpace
            )
        ]
        if let partner = partnerPosition {
            entries.append(PulseFieldEntry(
                id:       "partner",
                position: partner,
                auraSize: auraSize,
                opacity:  partnerStale ? PulseFieldEntry.staleOpacity : 1.0,
                space:    partnerSpace(partner)
            ))
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
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        ScrollView {
            MapUsLayer(
                stats: .init(),
                align: [],
                lockedAlignCount: 0,
                onOpenVault: {},
                onCheckIn:   {},
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
                onCheckIn:   {},
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
