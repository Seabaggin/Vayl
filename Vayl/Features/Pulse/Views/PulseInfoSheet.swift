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
//  Presented at SCREEN level by MapView, never attached to MapPulseHero —
//  `.vaylSheet` is an `.overlay` that sizes and anchors to its host view.
//  See the note on MapPulseHero.onOpenInfo.
//
//  2026-07-17 — DISTILLED, and deliberately stateless.
//
//  The circumplex field briefly folded in here (from MapPulseHero's deleted
//  MapFieldSheet) on the theory that ⓘ should both name the spaces and plot your
//  dot. Cut: the field teaches nothing to someone who has not checked in yet, and
//  someone who HAS meets it at the reveal (PulseCheckInView renders the real thing).
//  A map of one point is not a map. That also removed the last reason for this sheet
//  to read the Store, so it takes no inputs at all now.
//
//  Also cut: "your last check-in" read/descriptor copy. The hero it opens from is
//  already showing exactly that, two taps of nothing away.
//
//  The six spaces render as small, resting PulseAuras rather than flat 8pt dots —
//  the legend should look like the thing it names. `animates: false`: a legend orb
//  is a colour sample, not a live reading, and six breathing orbs is decoration.
//

import SwiftUI

struct PulseInfoSheet: View {

    /// The six spaces in reading order, each with a loose guide phrased in the axes'
    /// own vocabulary (charged/depleted, guarded/open) so the legend teaches the map
    /// rather than restating a name. Describes the SPACE, never the person: naming what
    /// a region of the map means is wayfinding, characterizing its occupant is assessment.
    private let spaces: [(space: PulseSpace, name: String, guide: String)] = [
        (.expansive,  "Expansive",  "Charged and open."),
        (.reactive,   "Reactive",   "Charged, but turned inward."),
        (.receptive,  "Receptive",  "Steady and open, at your own pace."),
        (.protective, "Protective", "Depleted and guarded."),
        (.neutral,    "Neutral",    "Balanced on both."),
        (.uncharted,  "Uncharted",  "Pulling in different directions.")
    ]

    /// 🎚️ FEEL: big enough to read as a small aura (gradient, rim, glow) rather than a
    /// dot, small enough that six of them stay a legend. Tune on device.
    private static let legendAuraSize: CGFloat = 34

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

                // Carried over from the first-run doorway (PulseFramingView), which is shown
                // once and then gone: this is the one idea there that lived nowhere else, and
                // it is the one that matters most — the anti-assessment line. Nothing should
                // be teachable only once.
                Text("There's no “correct” capacity. It's about showing up most authentically.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(AppSpacing.xs)
                    .fixedSize(horizontal: false, vertical: true)

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

    // MARK: - The two axes

    private var axesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // "how much energy is in your system" retired: "system" is the language of a
            // clinical instrument, which is the one thing Vayl promises not to be. The
            // pairing survives because it carries the actual idea — the first axis is how
            // much you have, the second is how much of THAT is available. The "it" is the
            // link; sub-lines that merely restate their label would add nothing.
            axisRow(name: "Charged / Depleted",
                    detail: "how much you have today.")
            axisRow(name: "Guarded / Open",
                    detail: "how much of it you want to share.")
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
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // The list below now names all six and says what each suggests, so the old
            // "…with Neutral and Uncharted for the days that sit between" was the legend
            // read aloud. Say it once.
            Text("Where your answers land gets a name.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: AppSpacing.md) {
                ForEach(spaces, id: \.name) { item in
                    HStack(alignment: .center, spacing: AppSpacing.md) {
                        PulseAura(
                            ramp: item.space.rampStatic,
                            size: Self.legendAuraSize,
                            animates: false
                        )
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text(item.name)
                                .font(AppFonts.bodyMedium)
                                .foregroundStyle(AppColors.textPrimary)
                            Text(item.guide)
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    // PulseAura is accessibilityHidden, so the row would otherwise read as
                    // two separate elements for one idea.
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(item.name). \(item.guide)")
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppColors.void.ignoresSafeArea()
        PulseInfoSheet()
    }
    .preferredColorScheme(.dark)
}

#Preview("In rail") {
    VaylSheetPreviewHost(heightFraction: 0.85) {
        PulseInfoSheet()
    }
    .environment(PulseStore())
}
