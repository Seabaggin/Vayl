// Features/Map/Components/MapPulseHero.swift
//
// The Me layer's Pulse section on the Map tab.
//
// Glance: aura hero (AppLayout.mapMeAuraSize) + Space name + sublabel + weather one-liner.
// Card pinned to AppLayout.mapPulseCardHeight — the shared Me/Us footprint (Map dashboard spec §1).
// "tap to map →" opens a sheet with the full 2D field at the user's current position.
//
// Visual reference: docs/prototypes/map-pulse-final.html — "Me · the glance" phone.

import SwiftUI

struct MapPulseHero: View {

    @Environment(PulseStore.self) private var pulse

    var onCheckIn:    () -> Void
    var onOpenHistory: () -> Void
    var isLinked: Bool = false

    @State private var showMap   = false
    @State private var isPressed = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader

            if hasHistory {
                // Aura — tapping it opens the field-map sheet.
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showMap = true
                } label: {
                    PulseAura(ramp: currentSpace.ramp(at: currentPosition), size: AppLayout.mapMeAuraSize)
                        .frame(maxWidth: .infinity)
                        .padding(.top, AppSpacing.lg)
                        .opacity(isStale ? PulseFieldEntry.staleOpacity : 1.0)
                }
                .buttonStyle(.plain)
                .scaleEffect(isPressed ? 0.96 : 1.0)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressed = true }
                        .onEnded   { _ in isPressed = false }
                )

                // Space name + sublabel
                VStack(spacing: AppSpacing.xxs) {
                    Text(currentSpace.displayName)
                        .font(AppFonts.screenTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(staleSublabel ?? currentSpace.descriptors(at: currentPosition))
                        .font(AppFonts.bodyText)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)

                    if let wl = pulse.weatherLine {
                        Text(wl)
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.spectrumCyan)
                            .padding(.top, AppSpacing.xxs)
                    }

                    if isLinked {
                        Text("Your read also appears in your shared orb")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textMuted)
                            .padding(.top, AppSpacing.xxs)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, AppSpacing.sm)

                if pulse.canCheckInToday {
                    checkInPill
                        .padding(.top, AppSpacing.md)
                }
            } else {
                emptyStateBlock
            }
        }
        // NOTE: kept as minHeight, not a hard height. The history grid that used to
        // live here (and justified the original minHeight) moved to PulseFullView,
        // but the check-in pill is conditional (pulse.canCheckInToday) and its
        // presence/absence still changes total content height enough that a hard
        // height risks clipping the pill on some content combinations. Revisit once
        // on-device sizing confirms a fixed height never clips.
        .frame(minHeight: AppLayout.mapPulseCardHeight, alignment: .top)
        .vaylCover(isPresented: $showMap, confirmOnExit: false) {
            MapFieldSheet(
                position:   currentPosition,
                space:      currentSpace,
                isStale:    isStale,
                staleSince: pulse.entries.last.map { pulse.relativeDay(for: $0.date) }
            )
        }
    }

    // MARK: - Section header

    private var sectionHeader: some View {
        HStack {
            Text("The Pulse")
                .font(AppFonts.overline)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(AppColors.textSectionLabel)
            Spacer()
            if hasHistory {
                HStack(spacing: AppSpacing.sm) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onOpenHistory()
                    } label: {
                        Text("History")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textMuted)
                    }
                    .buttonStyle(.plain)

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
        }
    }

    // MARK: - Empty state (never checked in) — reuses Home's exact dormant-state
    // copy/visual (PulseCyclingAura + "How's your capacity?") so the same underlying
    // condition reads consistently across Home and Map, instead of inventing a
    // second empty-state language for the same thing.

    private var emptyStateBlock: some View {
        VStack(spacing: 0) {
            PulseCyclingAura(size: AppLayout.mapMeAuraSize)
                .frame(maxWidth: .infinity)
                .padding(.top, AppSpacing.lg)

            VStack(spacing: AppSpacing.xxs) {
                Text("How's your capacity?")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)
                Text("A quick check-in")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.sm)

            checkInPill
                .padding(.top, AppSpacing.md)
        }
    }

    // MARK: - Check-in pill (fixes onCheckIn previously being wired by MapView but
    // never actually called anywhere in this view — Map's Me lens had no working
    // check-in entry point at all until now.)

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

    // MARK: - Derived state

    private var currentPosition: PulsePosition { pulse.currentPosition }

    /// The full six-space classification of the current (possibly stale) reading. Uncharted is
    /// recovered from the entry's stored answers; falls back to the position-only resolve.
    private var currentSpace: PulseSpace {
        pulse.entries.last?.space ?? PulseSpace.resolve(currentPosition)
    }

    /// False for a user who has never checked in — dead-center's tie-break rule
    /// resolves to .expansive, which would otherwise read as a real, live reading
    /// ("You're in an Expansive day") for someone who's logged nothing at all.
    private var hasHistory: Bool { !pulse.entries.isEmpty }

    /// True when the position shown is your last known one, not today's — Map
    /// (unlike Home) shows the last entry regardless of age, so the sublabel/orb
    /// need to say so rather than read like a live "today" status. Single source
    /// of truth lives on PulseStore now (was duplicated here).
    private var isStale: Bool { pulse.isPositionStale }

    private var staleSublabel: String? {
        guard isStale, let last = pulse.entries.last else { return nil }
        return "As of \(pulse.relativeDay(for: last.date))"
    }
}

// MARK: - Field map sheet

/// Full-screen cover: the circumplex field owns the screen, zone glows bleed into
/// the void atmosphere, copy reads below. Presented via .vaylCover so the system
/// knows this is an immersive experience, not a sheet.
private struct MapFieldSheet: View {
    let position:   PulsePosition
    let space:      PulseSpace
    let isStale:    Bool
    let staleSince: String?

    @Environment(\.vaylDismiss) private var dismiss

    var body: some View {
        GeometryReader { geo in
            let layout = AppLayout.from(geo)
            let w = geo.size.width

            ZStack(alignment: .top) {
                AppColors.void.ignoresSafeArea()
                OnboardingAtmosphere(config: .stat).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        PulseField(
                            entries: [PulseFieldEntry(
                                position: space == .uncharted ? PulsePosition(energy: 0.5, openness: 0.5) : position,
                                auraSize: 60,
                                opacity:  isStale ? PulseFieldEntry.staleOpacity : 1.0,
                                space:    space
                            )],
                            size: w,
                            showAxisLabels: true,
                            isUncharted: space == .uncharted
                        )
                        .padding(.top, layout.safeAreaInsets.top + AppSpacing.xl)

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
                }

                // Dismiss — top-leading, below Dynamic Island
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.textMuted)
                        .frame(width: 32, height: 32)
                        .background(AppColors.glassSurface)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(AppColors.borderSubtle, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.top, layout.safeAreaInsets.top + AppSpacing.sm)
                .padding(.leading, AppSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // A stale reading never claims "day" in the present tense — it names itself as
    // the last known Pulse instead. descCopy stays unchanged either way: it
    // describes the space's character, not a live status claim.
    private var readCopy: String {
        guard isStale, let staleSince else {
            switch space {
            case .expansive:  return "You're in an Expansive day"
            case .reactive:   return "A Reactive day"
            case .receptive:  return "A Receptive day"
            case .protective: return "A Protective day"
            case .neutral:    return "A Neutral day"
            case .uncharted:  return "An Uncharted day"
            default:          return space.displayName   // border state
            }
        }
        return "Your last Pulse: \(space.displayName) (\(staleSince))"
    }

    private var descCopy: String {
        switch space {
        case .expansive:  return "High energy and open. A good day to connect and explore."
        case .reactive:   return "High energy, turned inward. Things feel charged right now."
        case .receptive:  return "Grounded and open, moving at your own pace."
        case .protective: return "Low energy and guarded. You need space right now."
        case .neutral:    return "Balanced across both axes. Steady and calm right now."
        case .uncharted:  return "Your answers pull in different directions today. Fluid, still finding shape."
        default:          return space.descriptors(at: position)   // border state
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
