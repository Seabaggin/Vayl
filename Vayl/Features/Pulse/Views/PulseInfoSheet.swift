//
//  PulseInfoSheet.swift
//  Vayl
//
//  "About the Pulse" — a short, calm explainer presented as a .vaylSheet
//  (pre-TestFlight review D11). Content-only: the presenting `.vaylSheet`
//  supplies chrome + grabber (same discipline as SessionSettingsSheet).
//  Descriptive, never assessive: it explains the map and the
//  privacy promise, and says nothing about the person reading it.
//
//  2026-07-17 — the circumplex field folded in here from MapPulseHero's private
//  MapFieldSheet, which is now deleted. The field was its own `.vaylCover`
//  destination reachable only by tapping the hero orb, which cost the hero its tap
//  and taught nobody: you had to already know what the axes meant to read it. Folded
//  in, one ⓘ both names the spaces AND shows which one you're in, and the hero's tap
//  is freed for check-in. Reference: docs/mockups/map-pulse-hero-options.html.
//
//  `reading` is optional: a user who has never checked in still needs the explainer,
//  they just have no dot to plot.
//

import SwiftUI

struct PulseInfoSheet: View {

    @Environment(PulseStore.self) private var pulse

    /// The user's current reading, plotted on the field. Nil for a user with no history —
    /// the explainer still stands, there's just nothing to place on it yet.
    struct Reading {
        let position: PulsePosition
        let space: PulseSpace
        /// Governs the aura's opacity — the same 4-day threshold the Us orb dims on.
        let isQuiet: Bool
        /// "4 days ago" when the reading isn't today's; nil when it is.
        let staleSince: String?
    }

    /// Derived from the store rather than passed in. The sheet is presented from MapView
    /// (screen level — see MapPulseHero.onOpenInfo), which would otherwise have to
    /// re-derive the hero's stale/quiet logic just to hand it back down. Reading from the
    /// Store is the layer's own rule; threading it through a tab view is not.
    private var reading: Reading? {
        guard let last = pulse.entries.last else { return nil }
        return Reading(
            position: pulse.currentPosition,
            space: last.space,
            isQuiet: pulse.isPositionQuiet,
            staleSince: pulse.isPositionStale ? pulse.relativeDay(for: last.date) : nil
        )
    }

    /// The four named quadrant spaces, in reading order, with their static
    /// aura-core dot colours (the same colour the history grid uses).
    private let spaces: [(name: String, space: PulseSpace)] = [
        ("Expansive", .expansive),
        ("Reactive", .reactive),
        ("Receptive", .receptive),
        ("Protective", .protective)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("About the Pulse")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)

                Text("A quick daily check-in. Five questions, answered by feel, place you somewhere on a small map of energy and openness. There's no score and no right answer, just where you are today.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(AppSpacing.xs)
                    .fixedSize(horizontal: false, vertical: true)

                axesSection

                spacesSection

                fieldSection

                Text("Your Pulse is yours. If you share it, your partner sees your capacity, not your answers.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(AppSpacing.xs)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Check in when you feel like it. There's no streak to keep.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - The field (with the reader's own dot on it)

    @ViewBuilder
    private var fieldSection: some View {
        if let reading {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Here's the map, with your last check-in on it.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                GeometryReader { geo in
                    PulseField(
                        entries: [PulseFieldEntry(
                            position: reading.space == .uncharted
                                ? PulsePosition(energy: 0.5, openness: 0.5)
                                : reading.position,
                            auraSize: geo.size.width * Self.fieldDotFraction,
                            opacity: reading.isQuiet ? PulseFieldEntry.staleOpacity : 1.0,
                            space: reading.space
                        )],
                        size: geo.size.width,
                        showAxisLabels: true,
                        isUncharted: reading.space == .uncharted
                    )
                }
                // The field is square by construction, so its height IS its width. Reserving
                // it here keeps the GeometryReader (which reports zero intrinsic height)
                // from collapsing inside the ScrollView's VStack.
                .aspectRatio(1, contentMode: .fit)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(readCopy)
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(descCopy)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// The dot's share of the field's width. 🎚️ FEEL: 0.14 reads as "a place on the map"
    /// rather than a blob covering its own quadrant; tune on device.
    private static let fieldDotFraction: CGFloat = 0.14

    // A stale reading never claims "day" in the present tense — it names itself as the last
    // known Pulse instead. descCopy stays unchanged either way: it describes the space's
    // character, not a live status claim. (Migrated verbatim from MapFieldSheet.)
    private var readCopy: String {
        guard let reading else { return "" }
        guard let staleSince = reading.staleSince else {
            switch reading.space {
            case .expansive:  return "You're in an Expansive day"
            case .reactive:   return "A Reactive day"
            case .receptive:  return "A Receptive day"
            case .protective: return "A Protective day"
            case .neutral:    return "A Neutral day"
            case .uncharted:  return "An Uncharted day"
            default:          return reading.space.displayName   // border state
            }
        }
        return "Your last Pulse: \(reading.space.displayName) (\(staleSince))"
    }

    private var descCopy: String {
        guard let reading else { return "" }
        switch reading.space {
        case .expansive:  return "High energy and open. A good day to connect and explore."
        case .reactive:   return "High energy, turned inward. Things feel charged right now."
        case .receptive:  return "Grounded and open, moving at your own pace."
        case .protective: return "Low energy and guarded. Be kind to yourself today."
        case .neutral:    return "Balanced across both axes. Steady and calm right now."
        case .uncharted:  return "Your answers pull in different directions today. Fluid, still finding shape."
        default:          return reading.space.descriptors(at: reading.position)   // border state
        }
    }

    // MARK: - The two axes

    private var axesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            axisRow(name: "Charged / Depleted",
                    detail: "how much energy is in your system.")
            axisRow(name: "Guarded / Open",
                    detail: "how much of it is available for connection.")
        }
    }

    private func axisRow(name: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(name)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textPrimary)
            Text(detail)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - The spaces

    private var spacesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Where your answers land gets a name: Expansive, Reactive, Receptive, or Protective, with Neutral and Uncharted for the days that sit between.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineSpacing(AppSpacing.xs)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                ForEach(spaces, id: \.name) { item in
                    HStack(spacing: AppSpacing.sm) {
                        Circle()
                            .fill(item.space.dotCoreStatic)
                            .frame(width: AppSpacing.sm, height: AppSpacing.sm)
                        Text(item.name)
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

// PulseStore's init seeds preview entries under XCODE_RUNNING_FOR_PREVIEWS, so this
// always renders WITH a reading (field + dot). The no-history branch — explainer only,
// no field — has no preview: `entries` is private(set) and the seed is unconditional in
// previews, so there is no honest way to stage an empty store from here. It's covered by
// the `reading == nil` guard in fieldSection.
#Preview {
    ZStack {
        AppColors.void.ignoresSafeArea()
        PulseInfoSheet()
    }
    .environment(PulseStore())
    .preferredColorScheme(.dark)
}
