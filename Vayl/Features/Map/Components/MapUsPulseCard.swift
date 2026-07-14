// Features/Map/Components/MapUsPulseCard.swift
//
// The Us Pulse hero — Map dashboard spec §3.2-3.3, restyled 2026-07-05 to match
// MapPulseHero's hero treatment instead of the original compact side-by-side
// card: a centered "split orb" (SplitOrbView, sized the same as the Me aura for
// visual parity) with the headline + names-read centered below it, same shape
// as MapPulseHero's aura → state-name → sublabel column. State is
// UsOrbState-driven — computed ONCE by the caller and threaded through, never
// re-derived here.
//
// Visual reference: MapPulseHero.swift (structure this mirrors); the original
// compact-card mockup in docs/superpowers/specs/2026-07-05-map-tab-dashboard-design.md
// §3.2-3.3 no longer applies to the composition, only to the state rules.

import SwiftUI

// MARK: - MapUsPulseCard

struct MapUsPulseCard: View {

    let state: UsOrbState
    let myAura: AuraColors
    let partnerAura: AuraColors
    /// Unused since the dated quiet call-out was removed (pre-TestFlight D6).
    /// Retained for call-site stability; MapUsLayer still passes both.
    let myLastEntry: PulseEntry?
    let partnerLastEntry: PulseEntry?
    let mySpaceName: String
    let partnerSpaceName: String
    let partnerName: String
    /// Both last positions, used only for the distance headline when
    /// `state.allowsLiveComparison` is true.
    let myPosition: PulsePosition?
    let partnerPosition: PulsePosition?
    /// Unused since the dated quiet call-out was removed (pre-TestFlight D6,
    /// humility: the ember dimming carries "quiet" visually). Retained for
    /// call-site stability; MapUsLayer still passes it.
    let relativeDay: (Date) -> String
    var onTap: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            orb
                .frame(maxWidth: .infinity)
                .padding(.top, AppSpacing.lg)

            content
                .frame(maxWidth: .infinity)
                .padding(.top, AppSpacing.sm)
        }
        // minHeight, not a hard height — matches MapPulseHero's own reasoning
        // (spec §1's shared footprint is the common case, not a hard guarantee).
        .frame(minHeight: AppLayout.mapPulseCardHeight, alignment: .top)
        .frame(maxWidth: .infinity, alignment: .leading)
        // NO card chrome — MapPulseHero (Me) has none either. This is a hero
        // sitting on the atmosphere, not a bordered card like the Vault door.
        // Shared tap contract: press-scale + haptic on touch-DOWN (was a manual
        // isPressed flipped on tap-UP with a timed reset — the scale lagged the touch).
        .vaylPressableTap { onTap?() }
    }

    // MARK: - Header (mirrors MapPulseHero.sectionHeader)

    private var header: some View {
        HStack {
            Text("THE PULSE · TOGETHER")
                .font(AppFonts.overline)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(AppColors.textSectionLabel)
            Spacer()
            Text("tap to open →")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textMuted)
        }
    }

    // MARK: - Orb (hero-sized — same AppLayout.mapMeAuraSize as the Me aura,
    // for visual parity between the two lenses, not the old smaller compact size)

    @ViewBuilder
    private var orb: some View {
        switch state {
        case .wholeUnwritten:
            // No ambient glow here — same reasoning as MapPulseHero's empty
            // state: a cycling ramp has no fixed colour for a static wash to
            // match, and the movement already reads as "not yet answered."
            PulseCyclingAura(size: AppLayout.mapMeAuraSize)
        case .split(let mine, let partner):
            SplitOrbView(
                mine: half(for: mine, aura: myAura),
                partner: half(for: partner, aura: partnerAura),
                size: AppLayout.mapMeAuraSize
            )
        }
    }

    private func half(for halfState: UsOrbState.HalfState, aura: AuraColors) -> SplitOrbView.Half {
        switch halfState {
        case .unwritten: return .cycling
        case .current:    return .solid(aura)
        case .quiet:      return .ember(aura)
        }
    }

    // MARK: - Content (mirrors MapPulseHero's centered state-name + sublabel column)

    @ViewBuilder
    private var content: some View {
        switch state {
        case .wholeUnwritten:
            VStack(spacing: AppSpacing.xxs) {
                Text("The Pulse starts with a check-in")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                Text("One check-in from either of you begins the shared read.")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

        case .split(let mine, let partner):
            VStack(spacing: AppSpacing.xxs) {
                Text(headline(mine: mine, partner: partner))
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                namesRead(mine: mine, partner: partner)
            }
        }
    }

    // MARK: - Headline (spec §3.3 headline guard)

    // Headline copy: kept intentionally simple; see UsOrbState.allowsLiveComparison
    // for the guard that decides whether a live distance read is shown at all.
    // FEEL: tune threshold on device.
    private func headline(mine: UsOrbState.HalfState, partner: UsOrbState.HalfState) -> String {
        if state.allowsLiveComparison,
           let my = myPosition, let their = partnerPosition {
            let distance = my.distance(to: their)
            return distance > 0.45 ? "A wide day between you" : "Close today"
        }
        if partner == .unwritten {
            // Orb-describing, never behavior-tracking (pre-TestFlight D6).
            return "The shared read is still forming"
        }
        return "Your last reads, side by side"
    }

    // MARK: - Names read

    @ViewBuilder
    private func namesRead(mine: UsOrbState.HalfState, partner: UsOrbState.HalfState) -> some View {
        VStack(spacing: AppSpacing.xxs) {
            if mine != .unwritten {
                Text("You in \(mySpaceName)")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.spectrumCyan)
                    .opacity(mine == .quiet ? PulseFieldEntry.staleOpacity : 1.0)
            }
            if partner != .unwritten {
                Text("\(displayName) in \(partnerSpaceName)")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .opacity(partner == .quiet ? PulseFieldEntry.staleOpacity : 1.0)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.top, AppSpacing.xxs)
    }

    private var displayName: String { partnerName.isEmpty ? "Your partner" : partnerName }
}

// MARK: - SplitOrbView

struct SplitOrbView: View {

    enum Half: Equatable {
        case cycling
        case solid(AuraColors)
        case ember(AuraColors)

        static func == (lhs: Half, rhs: Half) -> Bool {
            switch (lhs, rhs) {
            case (.cycling, .cycling): return true
            default: return false // AuraColors isn't Equatable; identity comparisons unneeded here.
            }
        }
    }

    let mine: Half
    let partner: Half
    var size: CGFloat = 98

    // FEEL: desaturation applied to an ember (quiet) half, on top of the shared
    // staleOpacity floor. 0.4 mutes without fully greying out the space colour.
    private let embersSaturation: Double = 0.4
    private let seamOpacity: Double = 0.22
    private let seamWidth: CGFloat = 1.2

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false

    var body: some View {
        ZStack {
            halfView(mine)
                .clipShape(HalfCircle(leading: true))
            halfView(partner)
                .clipShape(HalfCircle(leading: false))

            // Diagonal seam hairline.
            HalfCircle(leading: true)
                .stroke(AppColors.textBody.opacity(seamOpacity), lineWidth: seamWidth)

            // Rim.
            Circle()
                .strokeBorder(AppColors.textBody.opacity(0.14), lineWidth: 1)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        // Ambient wash — added AFTER the clip so it bleeds outside the orb's
        // circle instead of being cut off by it. A per-half glow would sit
        // INSIDE the clip above and get masked away by HalfCircle, so this is
        // one shared wash for the whole orb, blended from both people's
        // colours — only shown once both sides have a real reading (a
        // cycling half's colour keeps shifting, so it has no fixed colour to
        // glow with).
        .background {
            if let haloGlow {
                MapHeroAmbientGlow(color: haloGlow, orbSize: size)
            }
        }
        .scaleEffect(breathe ? 1.045 : 1.0)
        .ambientAnimation(
            .easeInOut(duration: AppAnimation.ambientPulse).repeatForever(autoreverses: true),
            value: breathe
        )
        .onAppear { startBreathe() }
    }

    /// Blended glow colour for the shared ambient halo — nil (no halo) while
    /// either half is still `.cycling`, since there's no fixed colour to
    /// glow with while it's actively shifting.
    private var haloGlow: Color? {
        func auraColors(_ half: Half) -> AuraColors? {
            switch half {
            case .solid(let a), .ember(let a): return a
            case .cycling: return nil
            }
        }
        guard let a = auraColors(mine), let b = auraColors(partner) else { return nil }
        return AuraColors.lerp(a, b, 0.5).glow
    }

    @ViewBuilder
    private func halfView(_ half: Half) -> some View {
        switch half {
        case .cycling:
            // Unwritten (this person has never checked in) — dimmed the same
            // as an ember, scoped to THIS half only (clipped by the caller's
            // HalfCircle). A vivid rotating ramp next to a real, current
            // reading drew the eye to the wrong side; "no answer yet" should
            // recede, not out-shine an actual answer.
            PulseCyclingAura(size: size)
                .saturation(embersSaturation)
                .opacity(PulseFieldEntry.staleOpacity)
        case .solid(let aura):
            PulseAura(ramp: aura, size: size)
        case .ember(let aura):
            PulseAura(ramp: aura, size: size)
                .saturation(embersSaturation)
                .opacity(PulseFieldEntry.staleOpacity)
        }
    }

    private func startBreathe() {
        guard !reduceMotion, !AppAnimation.lowPower else { return }
        breathe = true
    }
}

// MARK: - HalfCircle

/// Splits a circle along the 135° diagonal (top-left ↔ bottom-right) into two
/// triangle-ish halves that together tile the full circle.
struct HalfCircle: Shape {
    /// true = the leading (upper-left) half; false = the trailing (lower-right) half.
    let leading: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if leading {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        } else {
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }
}

// MARK: - Preview

#Preview("Whole unwritten") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        MapUsPulseCard(
            state: .wholeUnwritten,
            myAura: AuraColors(.cyan),
            partnerAura: AuraColors(.indigo),
            myLastEntry: nil,
            partnerLastEntry: nil,
            mySpaceName: "",
            partnerSpaceName: "",
            partnerName: "Alex",
            myPosition: nil,
            partnerPosition: nil,
            relativeDay: { _ in "3 days ago" }
        )
        .padding(.horizontal, AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}

// Preview-only sample data (PulseEntry.previews is always populated).
// swiftlint:disable force_unwrapping
#Preview("Split · current/current") {
    let mine    = PulseEntry.previews.last!
    let partner = PulseEntry.previews[PulseEntry.previews.count - 2]
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        MapUsPulseCard(
            state: .split(mine: .current, partner: .current),
            myAura: AuraColors.bilinear(energy: mine.resolvedPosition.energy, openness: mine.resolvedPosition.openness),
            partnerAura: AuraColors.bilinear(energy: partner.resolvedPosition.energy, openness: partner.resolvedPosition.openness),
            myLastEntry: mine,
            partnerLastEntry: partner,
            mySpaceName: mine.space.displayName,
            partnerSpaceName: partner.space.displayName,
            partnerName: "Alex",
            myPosition: mine.resolvedPosition,
            partnerPosition: partner.resolvedPosition,
            relativeDay: { _ in "today" }
        )
        .padding(.horizontal, AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}

#Preview("Split · current/quiet") {
    let mine    = PulseEntry.previews.last!
    let partner = PulseEntry.previews.first!
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        MapUsPulseCard(
            state: .split(mine: .current, partner: .quiet),
            myAura: AuraColors.bilinear(energy: mine.resolvedPosition.energy, openness: mine.resolvedPosition.openness),
            partnerAura: AuraColors.bilinear(energy: partner.resolvedPosition.energy, openness: partner.resolvedPosition.openness),
            myLastEntry: mine,
            partnerLastEntry: partner,
            mySpaceName: mine.space.displayName,
            partnerSpaceName: partner.space.displayName,
            partnerName: "Alex",
            myPosition: mine.resolvedPosition,
            partnerPosition: partner.resolvedPosition,
            relativeDay: { _ in "6 days ago" }
        )
        .padding(.horizontal, AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}

#Preview("Split · current/unwritten") {
    let mine = PulseEntry.previews.last!
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        MapUsPulseCard(
            state: .split(mine: .current, partner: .unwritten),
            myAura: AuraColors.bilinear(energy: mine.resolvedPosition.energy, openness: mine.resolvedPosition.openness),
            partnerAura: AuraColors.neutral,
            myLastEntry: mine,
            partnerLastEntry: nil,
            mySpaceName: mine.space.displayName,
            partnerSpaceName: "",
            partnerName: "Alex",
            myPosition: mine.resolvedPosition,
            partnerPosition: nil,
            relativeDay: { _ in "" }
        )
        .padding(.horizontal, AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
