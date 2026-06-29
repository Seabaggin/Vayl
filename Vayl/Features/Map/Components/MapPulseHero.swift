// Features/Map/Components/MapPulseHero.swift
//
// The Me layer's Pulse section on the Map tab.
//
// Glance: aura hero (148pt) + Space name + sublabel + weather one-liner.
// "tap to map →" opens a sheet with the full 2D field at the user's current position.
//
// Visual reference: docs/prototypes/map-pulse-final.html — "Me · the glance" phone.

import SwiftUI

struct MapPulseHero: View {

    @Environment(PulseStore.self) private var pulse

    var onCheckIn:    () -> Void
    var onOpenHistory: () -> Void

    @State private var showMap = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader

            // Aura — tapping it opens the field-map sheet.
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showMap = true
            } label: {
                PulseAura(quadrant: currentQuadrant, size: 148)
                    .frame(maxWidth: .infinity)
                    .padding(.top, AppSpacing.lg)
            }
            .buttonStyle(.plain)
            .scaleEffect(1.0)   // placeholder for press state — wire if adding isPressed

            // Space name + sublabel
            VStack(spacing: AppSpacing.xxs) {
                Text(currentQuadrant.spaceName)
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(currentQuadrant.sublabel)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                if let wl = weatherLine {
                    Text(wl)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.spectrumCyan)
                        .padding(.top, AppSpacing.xxs)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.sm)

            // History grid — last 30 logged check-ins, never "last 30 days".
            if !meGridQuadrants.isEmpty {
                PulseHistoryGrid(mode: .me(meGridQuadrants))
                    .padding(.top, AppSpacing.lg)
            }
        }
        .vaylSheet(isPresented: $showMap, heightFraction: 0.88) {
            MapFieldSheet(position: currentPosition, quadrant: currentQuadrant)
        }
    }

    // MARK: - Section header

    private var sectionHeader: some View {
        HStack {
            Text("The Pulse")
                .font(AppFonts.overline)
                .foregroundStyle(AppColors.textTertiary)
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showMap = true
            } label: {
                Text("tap to map →")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Derived state

    private var currentPosition: PulsePosition {
        pulse.entries.last?.resolvedPosition ?? PulsePosition(energy: 0.5, openness: 0.5)
    }

    private var currentQuadrant: PulseQuadrant { currentPosition.quadrant }

    private var meGridQuadrants: [PulseQuadrant] {
        PulseHistory.lastLogged(pulse.entries).map { $0.resolvedPosition.quadrant }
    }

    private var weatherLine: String? {
        let entries = pulse.entries
        guard
            let today = entries.last(where: { Calendar.current.isDateInToday($0.date) }),
            let yesterday = entries.last(where: { Calendar.current.isDateInYesterday($0.date) })
        else { return nil }

        let delta = today.resolvedPosition.energy - yesterday.resolvedPosition.energy
        if abs(delta) < 0.05 { return "About the same as yesterday" }
        return delta > 0 ? "Brighter than yesterday" : "A bit quieter today"
    }
}

// MARK: - Field map sheet

/// The "your map" panel — the PulseField fills the full sheet width so the zone
/// glows are one with the sheet surface. GeometryReader at the root gives a stable
/// width measurement without feedback loops.
private struct MapFieldSheet: View {
    let position: PulsePosition
    let quadrant: PulseQuadrant

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            // AppColors.void here is load-bearing: PulseField zone gradients fade to
            // .clear, which otherwise shows the semi-transparent modalBackground and
            // lets the Map tab content bleed through. Void blocks it and makes the
            // zone glows feel one with the surface.
            ZStack(alignment: .top) {
                AppColors.void
                ScrollView {
                    VStack(spacing: 0) {
                        PulseField(
                            entries: [PulseFieldEntry(position: position, auraSize: 60)],
                            size: w,
                            showAxisLabels: true
                        )
                        .padding(.top, AppSpacing.xs)

                        VStack(spacing: AppSpacing.xxs) {
                            Text(readCopy)
                                .font(AppFonts.display(15, weight: .semibold, relativeTo: .subheadline))
                                .foregroundStyle(AppColors.textPrimary)
                                .multilineTextAlignment(.center)
                            Text(descCopy)
                                .font(AppFonts.body(11, weight: .regular, relativeTo: .footnote))
                                .foregroundStyle(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.md)

                        Spacer(minLength: AppSpacing.xl)
                    }
                    .frame(minHeight: geo.size.height)
                }
            }
        }
    }

    private var readCopy: String {
        switch quadrant {
        case .expansive:  return "You're in an Expansive day"
        case .friction:   return "A Friction day"
        case .sovereign:  return "A Sovereign day"
        case .protective: return "A Protective day"
        }
    }

    private var descCopy: String {
        switch quadrant {
        case .expansive:  return "High energy and open. A good day to connect and explore."
        case .friction:   return "High energy, turned inward. Things feel charged right now."
        case .sovereign:  return "Grounded and open, moving at your own pace."
        case .protective: return "Low energy and guarded. You need space right now."
        }
    }
}

// MARK: - Preview

#Preview("Hero + sheet") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        ScrollView {
            VStack {
                MapPulseHero(onCheckIn: {}, onOpenHistory: {})
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.lg)
            }
        }
    }
    .environment({
        let s = PulseStore()
        return s
    }())
    .preferredColorScheme(.dark)
}
