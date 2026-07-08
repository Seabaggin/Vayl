// Features/Pulse/PulseFullView.swift
//
// The full-screen Pulse pillar, opened from MapPulseHero's "History" affordance.
// History and detail live here, never inline on the dashboard (Map dashboard
// spec §1: "History and detail stay hidden until you open the pillar.").
//
// Carries the same interior lens toggle grammar as MapView's masthead (smaller
// size), writing back to the SAME MapStore.layer — single source of truth. Me
// shows the last-30-logged grid; Us restores the pre-Task-5 field+capsule block
// (resurrected from git history, see MapUsLayer.swift blame around "demolish
// inline field") alongside the paired grid.

import SwiftUI

struct PulseFullView: View {

    @Bindable var mapStore: MapStore
    @Environment(PulseStore.self) private var pulse

    var myEntries: [PulseEntry] = PulseEntry.previews
    var partnerEntries: [PulseEntry] = []
    var partnerName: String       = ""
    var onDismiss: (() -> Void)?

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            OnboardingAtmosphere(config: .stat).ignoresSafeArea()

            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                interiorHeader

                ScrollView {
                    Group {
                        switch mapStore.layer {
                        case .me:
                            meBody
                        case .us:
                            if mapStore.hasUs { usBody } else { meBody }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
            }
            .padding(AppSpacing.lg)
        }
        .screenshotProtected()
    }

    // MARK: - Interior header (close + smaller interior lens toggle)

    private var interiorHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                interiorNameToggle
                if mapStore.hasUs {
                    Text(mapStore.layer == .us ? "Shared · you both see this" : "Only you")
                        .font(AppFonts.caption)
                        .foregroundStyle(mapStore.layer == .us
                            ? AppColors.spectrumMagenta.opacity(0.8)
                            : AppColors.spectrumCyan.opacity(0.8))
                        .transition(.opacity)
                        .accessibilityLabel(mapStore.layer == .us
                            ? "Shared lens: your partner sees this too"
                            : "Private lens: only you see this")
                }
            }
            Spacer()
            closeButton
        }
    }

    // Same grammar as MapView.nameToggle (your name always lit, partner's name
    // dims in Me / lights in Us, tapping either writes mapStore.layer), just at a
    // smaller interior size and without the trailing "gear" affordance.
    private var interiorNameToggle: some View {
        let name = mapStore.displayName
        let partner = mapStore.partnerName
        let isUs = mapStore.layer == .us
        return HStack(spacing: 0) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(AppAnimation.spring) { mapStore.layer = .me }
            } label: {
                Text(isUs ? name : "\(name).")
                    .foregroundStyle(AppColors.spectrumText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Show just you")
            .accessibilityAddTraits(isUs ? .isButton : [.isButton, .isSelected])

            if mapStore.hasUs && !partner.isEmpty {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(AppAnimation.spring) { mapStore.layer = .us }
                } label: {
                    Text(isUs ? " & \(partner)." : " & \(partner)")
                        .foregroundStyle(isUs
                            ? AnyShapeStyle(AppColors.spectrumText)
                            : AnyShapeStyle(AppColors.textTertiary))
                        .opacity(isUs ? 1.0 : 0.45)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
                .accessibilityLabel("Show you and \(partner) together")
                .accessibilityAddTraits(isUs ? [.isButton, .isSelected] : .isButton)
            }
        }
        .font(AppFonts.display(22, weight: .bold, relativeTo: .title2))
        .animation(AppAnimation.slow, value: mapStore.partnerName)
    }

    private var closeButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onDismiss?()
        } label: {
            Image(systemName: AppIcons.close)
                .font(AppFonts.body(13, weight: .medium, relativeTo: .footnote))
                .foregroundStyle(AppColors.textMuted)
                .frame(width: 32, height: 32)
                .background(AppColors.glassSurface)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(AppColors.borderSubtle, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }

    // MARK: - Me body

    private var meGridDays: [(date: Date, space: PulseSpace)] {
        PulseHistory.lastLoggedSpaces(myEntries)
    }

    private var meBody: some View {
        VStack(alignment: .center, spacing: AppSpacing.lg) {
            if meGridDays.isEmpty {
                emptyMeState
            } else {
                PulseHistoryGrid(mode: .me(meGridDays))
            }
        }
        .padding(.top, AppSpacing.md)
    }

    private var emptyMeState: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: AppIcons.waveformPathEcg)
                .font(AppFonts.body(28, weight: .regular, relativeTo: .title2))
                .foregroundStyle(AppColors.textTertiary)
            Text("No Pulse yet")
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text("Check in to start building your history.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
    }

    // MARK: - Us body (resurrected pre-Task-5 field+capsule block, relocated here
    // per the spec — this is exactly the content that used to render inline on
    // MapUsLayer before Task 5 cut it, moved into the full pillar view instead.)

    private var myPosition: PulsePosition { pulse.currentPosition }

    private var mySpace: PulseSpace { myEntries.last?.space ?? PulseSpace.resolve(myPosition) }

    private func partnerSpace(_ pos: PulsePosition) -> PulseSpace {
        partnerLastEntry?.space ?? PulseSpace.resolve(pos)
    }

    private var partnerLastEntry: PulseEntry? { partnerEntries.last }

    private var partnerPosition: PulsePosition? {
        partnerLastEntry?.position
    }

    private var hasHistory: Bool { !myEntries.isEmpty }

    /// The UsOrbState computed ONCE per body render and threaded through to the
    /// field entries and copy below — never re-derived (same idiom as
    /// MapUsLayer.usOrbState / MapUsPulseCard, review note from Task 1).
    private var usOrbState: UsOrbState {
        UsOrbState.resolve(mine: myEntries, partner: partnerEntries)
    }

    private var myHalfState: UsOrbState.HalfState {
        if case .split(let mine, _) = usOrbState { return mine }
        return .unwritten
    }

    private var partnerHalfState: UsOrbState.HalfState {
        if case .split(_, let partner) = usOrbState { return partner }
        return .unwritten
    }

    private var myStale: Bool { myHalfState == .quiet }

    private var partnerStale: Bool { partnerHalfState == .quiet }

    private var distance: Double {
        guard let partner = partnerPosition else { return 0 }
        return myPosition.distance(to: partner)
    }

    // Headline copy/thresholds mirror MapUsPulseCard.headline(mine:partner:) —
    // both route through the SAME UsOrbState.allowsLiveComparison guard so the
    // compact card and this detail view never disagree on staleness.
    private var headline: String {
        guard partnerPosition != nil else {
            if mapStore.partnerPulseFetchFailed { return "Couldn't reach their Pulse" }
            return partnerName.isEmpty ? "Pulse · together" : "\(partnerName) hasn't checked in"
        }
        guard usOrbState.allowsLiveComparison else { return "Comparing your last Pulses" }
        return distance > 0.45 ? "A wide day between you" : "Close today"
    }

    private var descCopy: String {
        guard let partner = partnerPosition else {
            if mapStore.partnerPulseFetchFailed {
                return "Couldn't reach your partner's data right now. It'll refresh when the connection is back."
            }
            return partnerName.isEmpty
                ? "Check in to see how you and your partner compare."
                : "Their space fills in the moment they take a reading."
        }
        let pName = partnerName.isEmpty ? "Your partner" : partnerName

        let myPhrase: String = {
            guard myStale, let mine = myEntries.last else {
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
        PulseHistory.pairedLastLoggedSpaces(mine: myEntries, partner: partnerEntries)
    }

    private var usBody: some View {
        VStack(alignment: .center, spacing: AppSpacing.xs) {
            if hasHistory {
                fieldBlock
                copyBlock
            } else {
                emptyUsState
            }
            if !usGridPairs.isEmpty {
                PulseHistoryGrid(mode: .us(usGridPairs, partnerName: partnerName))
                    .padding(.top, AppSpacing.lg)
            }
        }
        .padding(.top, AppSpacing.md)
    }

    private var emptyUsState: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: AppIcons.waveformPathEcg)
                .font(AppFonts.body(28, weight: .regular, relativeTo: .title2))
                .foregroundStyle(AppColors.textTertiary)
            Text(mapStore.partnerPulseFetchFailed ? "Couldn't reach their Pulse" : "No Pulse yet")
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text(mapStore.partnerPulseFetchFailed
                ? "Couldn't reach your partner's data right now. It'll refresh when the connection is back."
                : "Check in to see how you and \(partnerName.isEmpty ? "your partner" : partnerName) compare.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
    }

    private var fieldBlock: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    let size = geo.size.width
                    let auraSize = size * 0.177
                    ZStack {
                        PulseField(
                            entries: fieldEntries(auraSize: auraSize),
                            size: size,
                            showAxisLabels: true
                        )

                        if let partner = partnerPosition {
                            PulseCapsule(
                                myPosition: myPosition,
                                partnerPosition: partner,
                                myColor: mySpace.dotCoreStatic,
                                partnerColor: partnerSpace(partner).dotCoreStatic,
                                fieldSize: size,
                                auraSize: auraSize
                            )
                            auraLabel("You",
                                      position: myPosition,
                                      color: mySpace.dotCoreStatic,
                                      above: true,
                                      fieldSize: size)
                            auraLabel(partnerName.isEmpty ? "Partner" : partnerName,
                                      position: partner,
                                      color: partnerSpace(partner).dotCoreStatic,
                                      above: false,
                                      fieldSize: size)
                        } else if !partnerName.isEmpty {
                            let waitingPos = PulsePosition(energy: 0.30, openness: 0.30)
                            let waitingPt  = CGPoint(x: waitingPos.openness * size, y: (1 - waitingPos.energy) * size)
                            PulseCyclingAura(size: auraSize)
                                .position(x: waitingPt.x, y: waitingPt.y)
                            auraLabel("\(partnerName) · not yet",
                                      position: waitingPos,
                                      color: AppColors.textTertiary,
                                      above: false,
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
                id: "me",
                position: myPosition,
                auraSize: auraSize,
                opacity: myStale ? PulseFieldEntry.staleOpacity : 1.0,
                space: mySpace
            )
        ]
        if let partner = partnerPosition {
            entries.append(PulseFieldEntry(
                id: "partner",
                position: partner,
                auraSize: auraSize,
                opacity: partnerStale ? PulseFieldEntry.staleOpacity : 1.0,
                space: partnerSpace(partner)
            ))
        }
        return entries
    }

    private func auraLabel(
        _ text: String,
        position: PulsePosition,
        color: Color,
        above: Bool,
        fieldSize: CGFloat
    ) -> some View {
        let x  = position.openness * fieldSize
        let y  = (1 - position.energy) * fieldSize
        let dy = fieldSize * 0.18

        return Text(text)
            .font(AppFonts.microBadge)
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(color)
            .position(x: x, y: y + (above ? -dy : dy))
    }

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

#Preview("Me") {
    let store = MapStore()
    return PulseFullView(mapStore: store, myEntries: PulseEntry.previews)
        .environment(PulseStore())
        .preferredColorScheme(.dark)
}

#Preview("Us") {
    let store = MapStore()
    store.layer = .us
    return PulseFullView(
        mapStore: store,
        myEntries: PulseEntry.previews,
        partnerEntries: PulseEntry.previews,
        partnerName: "Alex"
    )
    .environment(PulseStore())
    .preferredColorScheme(.dark)
}
