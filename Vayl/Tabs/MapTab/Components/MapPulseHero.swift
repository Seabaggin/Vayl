// Features/Map/Components/MapPulseHero.swift
//
// The Me layer's Pulse section on the Map tab.
//
// Glance: aura hero (layout.mapHeroOrbSize) + Space name + sublabel + weather one-liner.
// Floats on the atmosphere with NO card chrome, at a screen-proportional size — the
// Void Rule, both clauses. No height floor: the hero sizes to its content.
//
// TWO tap targets, and only two (2026-07-17 rework, option A "spoken invite"):
//   1. The hero itself → check in. The whole block, not a pill.
//   2. ⓘ → PulseInfoSheet: what this is, what the spaces mean, and where you are.
// It previously carried FOUR (About / History / "tap to open →" / the orb / a pill),
// where the biggest, most obviously tappable element (the orb) opened the field map —
// the least important destination — and the primary action was a 10pt outlined pill.
// The field folded into ⓘ; history became an inline strip that expands in place; the
// pill is gone. See docs/mockups/map-pulse-hero-options.html.
//
// Visual reference: docs/mockups/map-pulse-hero-options.html — "A · spoken invite".

import SwiftUI

struct MapPulseHero: View {

    @Environment(PulseStore.self) private var pulse

    let layout: AppLayout
    var onCheckIn: () -> Void
    /// Presented by MapView, NOT here. `.vaylSheet` is an `.overlay` on the view it's
    /// attached to (VaylPresentation.swift:130) and sizes off that view's geometry, so
    /// attaching it to this hero produced a sheet 0.85 × THE HERO's height, anchored to
    /// the hero's bottom edge — a card floating mid-dashboard. It has to be attached at
    /// screen level, alongside MapView's other sheets.
    var onOpenInfo: () -> Void
    var isLinked: Bool = false

    @State private var isPressed = false
    @State private var infoPressed = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader

            // ONE target: the whole hero checks you in. The orb no longer owns a tap of
            // its own, so nothing is nested inside it.
            //
            // Gated on canCheckInToday (= todayEntry?.isEditable ?? true). A locked entry
            // used to simply hide the pill; now that the hero IS the button, the same
            // condition has to remove the tap and the invite, or the whole hero becomes a
            // dead target that silently does nothing.
            heroContent
                .contentShape(Rectangle())
                .scaleEffect(isPressed ? 0.96 : 1.0)
                .modifier(CheckInTap(
                    active: pulse.canCheckInToday,
                    isPressed: $isPressed,
                    hint: pulse.todayEntry == nil ? "Checks in" : "Edits today's check-in",
                    action: onCheckIn
                ))
                .accessibilityElement(children: .combine)
                .accessibilityLabel(heroAccessibilityLabel)

            // History — a sibling of the hero button, never a child of it. Nesting a tap
            // target inside a tap target is the gesture conflict this layout avoids.
            if hasHistory {
                PulseHistoryGrid(mode: .me(gridDays), collapsible: true)
                    .padding(.top, AppSpacing.lg)
            }

            if isLinked {
                // The worded-consent line (dashboard spec §3.4): the one place "Me = mine
                // alone" and the data model diverge. It was textMuted — 1.76:1, unreadable.
                // A privacy disclosure nobody can read is not a disclosure, so this is a
                // correctness fix, not a cosmetic one. textTertiary = 5.32:1.
                Text("Your read also appears in your shared orb")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, AppSpacing.md)
            }
        }
        // No minHeight floor. The old one (mapHeroSlotHeight, ≈221pt) was co-tuned to a
        // 135pt orb and stopped binding entirely at 184pt — see AppLayout's retirement
        // note. The hero sizes to its content, honestly.
    }

    // MARK: - Hero block (aura + the read + the invite)

    @ViewBuilder
    private var heroContent: some View {
        if hasHistory { heroBlock } else { emptyStateBlock }
    }

    private var heroBlock: some View {
        VStack(spacing: 0) {
            // .background, NOT a ZStack sibling — a ZStack sizes itself to
            // its largest child, and the glow's outer wash is ~2.6x the orb,
            // which was inflating this whole block's reported height and
            // pushing everything below it down. .background renders the
            // glow behind the aura without it participating in layout.
            // rampStatic, not ramp(at:): the hero shows a NAME with no field under it, so
            // the colour has to back the name up. Blended, a barely-Expansive reading
            // painted itself #7B6CC2 (43% cyan, the rest magenta/indigo/rose cancelling
            // toward grey) under the title "The Expansive Space" — while its own history
            // dot 40pt below, which never blended, showed true cyan.
            PulseAura(ramp: currentSpace.rampStatic, size: layout.mapHeroOrbSize)
                .background {
                    MapHeroAmbientGlow(
                        color: currentSpace.rampStatic.glow,
                        orbSize: layout.mapHeroOrbSize
                    )
                }
                .frame(maxWidth: .infinity)
                // xs, not lg: the header's 44pt ⓘ target already contributes ~14pt of
                // slack below the section label, so lg would double-count it and push the
                // orb down. 🎚️ FEEL: verify the label→orb gap on device.
                .padding(.top, AppSpacing.xs)
                .opacity(isQuiet ? PulseFieldEntry.staleOpacity : 1.0)

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

                inviteLine
            }
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.sm)
        }
    }

    /// The affordance the check-in pill used to carry. `textSecondary`, not `textAccent`:
    /// the orb owns colour on this screen, and on an Expansive day the ramp IS cyan, so a
    /// cyan invite would sit under a cyan orb and read as an accident. Secondary still
    /// outranks the timestamp below it, which is the hierarchy bug the pill left behind.
    /// 🎚️ FEEL: try `textAccent` on device before locking this.
    @ViewBuilder
    private var inviteLine: some View {
        if pulse.canCheckInToday {
            // "Edit", not "update": the app already says "Edit check-in" in HomePulseRail
            // and MapUsLayer. One term per concept.
            Text(pulse.todayEntry == nil ? "Tap to check in" : "Tap to edit today's check-in")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.top, AppSpacing.sm)
        }
    }

    // MARK: - Section header

    // ⓘ shows in BOTH states: a first-run user (empty state) needs a way to learn what
    // the Pulse is before checking in. It replaces three text links (About / History /
    // "tap to open →") — History moved inline, the field folded into ⓘ itself.
    private var sectionHeader: some View {
        HStack {
            Text("The Pulse")
                .font(AppFonts.overline)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(AppColors.textSectionLabel)
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onOpenInfo()
            } label: {
                Image(systemName: AppIcons.infoCircle)
                    .font(AppFonts.body(15, weight: .regular, relativeTo: .footnote))
                    // textTertiary (5.32:1 on void), NOT textMuted (1.76:1 — fails both
                    // WCAG AA text and the 3:1 non-text control floor). The three links
                    // this replaces were all textMuted, i.e. the whole header was near
                    // invisible; carrying that onto the ONE affordance that now explains
                    // the feature would be worse, not equal.
                    .foregroundStyle(AppColors.textTertiary)
                    // A 15pt glyph is not a 44pt target. The frame is the touch area;
                    // the glyph stays small (iOS HIG 44x44 minimum).
                    .frame(width: AppLayout.minTouchTarget, height: AppLayout.minTouchTarget, alignment: .trailing)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .scaleEffect(infoPressed ? 0.96 : 1.0)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in infoPressed = true }
                    .onEnded { _ in infoPressed = false }
            )
            .accessibilityLabel("About the Pulse")
            .accessibilityHint("Explains the check-in and the spaces, and shows where you are")
        }
        // The header owns the ⓘ's full 44pt height. Clamping it shorter (e.g. to
        // AppSpacing.lg) does NOT shrink the button's hit area — it just lets the target
        // overhang into the hero's tap zone below, where the two would fight over the
        // same points. The hero's top padding absorbs the extra height instead.
    }

    // MARK: - Empty state (never checked in) — reuses Home's exact dormant-state
    // copy/visual (PulseCyclingAura + "How's your capacity?") so the same underlying
    // condition reads consistently across Home and Map, instead of inventing a
    // second empty-state language for the same thing.

    private var emptyStateBlock: some View {
        VStack(spacing: 0) {
            // No ambient glow here: the cycling ramp's colour is always shifting,
            // and a static wash behind it would just look mismatched — the
            // moving colour already carries "not yet answered" on its own.
            PulseCyclingAura(size: layout.mapHeroOrbSize)
                .frame(maxWidth: .infinity)
                // Matches heroBlock's orb padding so the empty→filled transition doesn't shift.
                .padding(.top, AppSpacing.xs)

            VStack(spacing: AppSpacing.xxs) {
                Text("How's your capacity?")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)
                // Honest empty state: if hydrate failed, this isn't a first run,
                // it's an unreachable history, so say so instead of pretending.
                Text(pulse.lastHydrateFailed
                     ? "Couldn't reach your history right now. It'll restore when the connection is back."
                     : "A quick check-in")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.sm)

            // The empty state carries the invite too — a first-run user is exactly who
            // most needs to be told the orb is a door. (The pill this replaced was the
            // only working check-in entry point Map's Me lens had.)
            inviteLine
        }
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
    /// of truth lives on PulseStore now (was duplicated here). Governs COPY only
    /// ("As of 2 days ago") — see `isQuiet` for the separate opacity trigger.
    private var isStale: Bool { pulse.isPositionStale }

    /// True once the reading has gone quiet (4+ days) — the same threshold the
    /// Us orb dims on. Governs the aura's OPACITY, so a 1-3-day-old reading looks
    /// equally vivid in Me and Us instead of Me dimming a day sooner than Us does.
    private var isQuiet: Bool { pulse.isPositionQuiet }

    private var staleSublabel: String? {
        guard isStale, let last = pulse.entries.last else { return nil }
        return "As of \(pulse.relativeDay(for: last.date))"
    }

    /// The last 30 logged check-ins for the inline strip. Same helper the Pulse pillar
    /// uses, so the two surfaces can never disagree about what "your last 30" means.
    private var gridDays: [(date: Date, space: PulseSpace)] {
        PulseHistory.lastLoggedSpaces(pulse.entries)
    }

    /// One spoken label for the whole hero. `children: .combine` would otherwise read the
    /// orb, the name, the sublabel, the weather line and the invite as one run-on string.
    /// States WHAT THIS IS only; what a tap does is the hint's job (CheckInTap), and
    /// "button" plus "double tap to activate" is VoiceOver's own announcement to make.
    private var heroAccessibilityLabel: String {
        guard hasHistory else { return "How's your capacity? A quick check-in." }
        return "\(currentSpace.displayName). \(staleSublabel ?? currentSpace.descriptors(at: currentPosition))."
    }
}

// MARK: - Check-in tap

/// Makes the hero the check-in target, but only while a check-in is actually possible.
/// A concrete modifier rather than an inline `if` around the whole block: conditional
/// branches in a preview host are what trip DebugReplaceableView's SIGABRT, and this one
/// would wrap the aura (the most expensive thing on the screen to re-raster).
private struct CheckInTap: ViewModifier {
    let active: Bool
    @Binding var isPressed: Bool
    let hint: String
    let action: () -> Void

    func body(content: Content) -> some View {
        if active {
            content
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressed = true }
                        .onEnded { _ in isPressed = false }
                )
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    action()
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(hint)
        } else {
            // Not a button, so no trait and no hint: a locked entry must not announce
            // an action that will not happen.
            content
        }
    }
}

// MARK: - Preview

#Preview("Hero + sheet") {
    // GeometryReader, not a hand-built AppLayout: the preview resolves hero scale
    // the same way the device does (Void Rule clause 2).
    GeometryReader { geo in
        ZStack {
            AppColors.void.ignoresSafeArea()
            OnboardingAtmosphere(config: .stat).ignoresSafeArea()
            ScrollView {
                VStack {
                    MapPulseHero(layout: AppLayout.from(geo), onCheckIn: {}, onOpenInfo: {})
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.lg)
                }
            }
        }
    }
    .environment({
        let s = PulseStore()
        return s
    }())
    .preferredColorScheme(.dark)
}
