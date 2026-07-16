// Features/Home/Components/HomePulseRail.swift
//
// Module 2 of the Home dashboard — the compact Pulse aura widget (ambient hero).
//
// Dormant (no today check-in): cycling aura touring all 4 spaces + "How's your capacity?" invite.
// Active (today check-in exists): landed PulseAura + Space name + sublabel + "Xh ago".
//
// Layout — row-paired hero + orb (validated across 3 mockup rounds):
//   docs/prototypes/home-pulse-widget-shine.html → -alignment-options.html → -orb-size-options.html
//   • Eyebrow ("THE PULSE") on its own line.
//   • Hero line + orb share ONE row, .center aligned — so they stay vertically centered
//     against each other regardless of 1- vs 2-line hero copy. (Independent-block centering,
//     the prior approach, drifted ~14pt between dormant/active depending on line count.)
//   • The Check-in pill lives under the orb in BOTH states, so re-checking-in is one tap.
//   • Sub-label (+ relative time when active) sits below in normal flow.
//
// No streak. No badge. No calendar gap. The orb IS the language; its own glow washes the pane.
// Tapping the card opens the full Pulse on the Map; the pill (re-)runs a check-in.

import SwiftUI

struct HomePulseRail: View {

    var onTap: (() -> Void)?   // → Map Pulse
    var onCheckIn: (() -> Void)?   // → check-in

    /// Aura diameter. Matches Option A in the orb-size reference
    /// (docs/prototypes/home-pulse-widget-orb-size-options.html) — 84px orb in a ~320px card,
    /// present without going orb-dominant (Option B, rejected) or duplicating the 150pt
    /// Map-hero aura. FEEL: tune on device.
    private let orbSize: CGFloat = 84

    /// The orb's wide pane-wash glow — disc diameter as a multiple of orbSize. Matches
    /// shine.html's `box-shadow: 0 0 150px 60px` on a 66px orb: a ~186px (2.8×) solid-.32 disc
    /// feathered wide, washing the whole pane. Clipped to the card. FEEL: tune on device.
    private let orbHaloSpread: CGFloat = 2.8

    @Environment(PulseStore.self) private var pulse

    // Press states (tap contract: every tappable element carries press scale +
    // haptic + action): one for the card's tap surface, one for the pill.
    @State private var cardPressed = false
    @State private var pillPressed = false

    // MARK: - Body

    var body: some View {
        Group {
            if let entry = todayEntry {
                let position = entry.resolvedPosition
                let space    = entry.space
                card(
                    // Bilinear-coloured orb + six-space name, matching the check-in reveal and
                    // Map hero — a Neutral/Uncharted reading reads the same everywhere.
                    orb: PulseAura(ramp: space.ramp(at: position), size: orbSize, haloSpread: orbHaloSpread),
                    hero: space.displayName,
                    heroColor: AppColors.textPrimary,
                    sub: space.descriptors(at: position),
                    subColor: AppColors.textSecondary,
                    timestamp: trendAndTimestamp(entry.date)
                )
            } else {
                card(
                    orb: PulseCyclingAura(size: orbSize, haloSpread: orbHaloSpread),
                    hero: "How's your capacity?",
                    heroColor: AppColors.textPrimary,
                    sub: "A quick check-in",
                    subColor: AppColors.textTertiary,
                    timestamp: nil
                )
            }
        }
    }

    // MARK: - Card

    /// Shared ambient-hero layout. `Orb` is generic so each state passes its own aura view
    /// (landed vs cycling) with no AnyView boxing.
    private func card<Orb: View>(
        orb: Orb,
        hero: String,
        heroColor: Color,
        sub: String,
        subColor: Color,
        timestamp: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {

            // Eyebrow
            Text("The Pulse")
                .font(AppFonts.overline)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(AppColors.textSectionLabel)

            // Hero row — text leads, orb + pill on the right, centered against each other.
            HStack(alignment: .center, spacing: AppSpacing.md) {
                Text(hero)
                    .font(AppFonts.pulseWidgetTitle)
                    .foregroundStyle(heroColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: AppSpacing.sm) {
                    orb
                    if pulse.canCheckInToday {
                        checkInPill
                    }
                }
                .fixedSize()
            }

            // Sub-block
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(sub)
                    .font(AppFonts.caption)
                    .foregroundStyle(subColor)
                if let timestamp {
                    Text(timestamp)
                        .font(AppFonts.buttonLabelSmall)
                        .foregroundStyle(AppColors.textTertiary)
                        .monospacedDigit()
                }
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Opaque app-surface base (cardBackground) so the atmosphere does NOT bleed through —
        // the only colour on the pane is the orb's own shadow-glow, clipped to the card so it
        // washes from the orb's position and can't desync from the aura.
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
                .strokeBorder(AppColors.borderDefault, lineWidth: 1)
        )
        // Spectrum top hairline — the codebase card-chrome language (same cyan→purple→magenta
        // stops as VaylBorderEffect's HairlineView), tapered to nothing at the ends via the
        // clear stops. Inset horizontally so it lands on the straight top segment, clear of
        // the rounded corners.
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [
                    .clear,
                    AppColors.spectrumCyan.opacity(0.90),
                    AppColors.spectrumPurple,
                    AppColors.spectrumMagenta.opacity(0.90),
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
            .padding(.horizontal, AppSpacing.md)
        }
        .contentShape(RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous))
        .scaleEffect(cardPressed ? 0.96 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in cardPressed = true }
                .onEnded { _ in cardPressed = false }
        )
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap?()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("The Pulse. \(hero)")
        .accessibilityHint("Opens the Pulse on the Map")
    }

    // MARK: - Check-in pill (both states — hidden once today's entry has locked
    // past its 2-hour edit window; see PulseStore.canCheckInToday)

    private var checkInPill: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onCheckIn?()
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
        .scaleEffect(pillPressed ? 0.96 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pillPressed = true }
                .onEnded { _ in pillPressed = false }
        )
        .accessibilityLabel(pulse.todayEntry == nil ? "Check in" : "Edit today's check-in")
    }

    // MARK: - Helpers

    private var todayEntry: PulseEntry? { pulse.todayEntry }

    /// Combines the day-over-day trend (if available) with the relative timestamp
    /// on one line, matching home-pulse-widget-shine.html's "Brighter than
    /// yesterday · 2h ago" — the mockup's one remaining unbuilt detail (previously
    /// tracked as this file's own "D1.5" note, now built). Falls back to the plain
    /// timestamp on a first-ever entry (no yesterday to compare against).
    private func trendAndTimestamp(_ date: Date) -> String {
        guard let trend = pulse.weatherLine else { return relativeTime(date) }
        return "\(trend) · \(relativeTime(date))"
    }

    private func relativeTime(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        let days = seconds / 86400
        return "\(days) day\(days == 1 ? "" : "s") ago"
    }
}

// MARK: - Preview

#Preview("Dormant") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        HomePulseRail(onCheckIn: {})
            .padding(AppSpacing.lg)
    }
    .environment(PulseStore())
    .preferredColorScheme(.dark)
}

#Preview("Active — Expansive") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        HomePulseRail(onTap: {})
            .padding(AppSpacing.lg)
    }
    .environment({
        let s = PulseStore()
        s.add(PulseEntry(
            date: Date(),
            capacityScore: 4.0,
            glowColor: .cyan,
            speed: "Expansive",
            nervousSystem: "Energized",
            focus: "Reaching Out",
            feeling: "Adventurous",
            position: PulsePosition(energy: 0.82, openness: 0.78)
        ))
        return s
    }())
    .preferredColorScheme(.dark)
}

// A deliberately long state name to prove the hero wraps to 2 lines while staying
// centered against the orb (the alignment fix this rebuild exists for).
#Preview("Active — long hero (wrap test)") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        HomePulseRail(onTap: {})
            .padding(AppSpacing.lg)
    }
    .environment({
        let s = PulseStore()
        s.add(PulseEntry(
            date: Date(),
            capacityScore: 1.0,
            glowColor: .rose,
            speed: "Protective",
            nervousSystem: "Guarded",
            focus: "Turning Inward",
            feeling: "Need Space",
            position: PulsePosition(energy: 0.18, openness: 0.16)
        ))
        return s
    }())
    .preferredColorScheme(.dark)
}
