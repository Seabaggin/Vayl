// Features/Map/Components/MapUsPulseCard.swift
//
// The compact Us Pulse card — Map dashboard spec §3.2-3.3. Replaces the old inline
// full-width PulseField block with a fixed-height card: a two-half "split orb"
// (SplitOrbView) on the left, a headline + names-read on the right. State is
// UsOrbState-driven — computed ONCE by the caller and threaded through, never
// re-derived here.
//
// Visual reference: docs/superpowers/specs/2026-07-05-map-tab-dashboard-design.md §3.2-3.3.

import SwiftUI

// MARK: - MapUsPulseCard

struct MapUsPulseCard: View {

    let state:        UsOrbState
    let myAura:        AuraColors
    let partnerAura:    AuraColors
    let myLastEntry:    PulseEntry?
    let partnerLastEntry: PulseEntry?
    let mySpaceName:    String
    let partnerSpaceName: String
    let partnerName:    String
    /// Both last positions, used only for the distance headline when
    /// `state.allowsLiveComparison` is true.
    let myPosition:     PulsePosition?
    let partnerPosition: PulsePosition?
    let relativeDay:    (Date) -> String
    var onTap:          (() -> Void)? = nil

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            orb
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("THE PULSE · TOGETHER")
                    .font(AppFonts.overline)
                    .tracking(1.0)
                    .foregroundStyle(AppColors.spectrumMagenta)

                bodyContent
            }
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .frame(height: AppLayout.mapPulseCardHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .vaylGlassCard(accent: AppColors.spectrumMagenta, radius: AppRadius.container)
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .sensoryFeedback(.impact(weight: .light), trigger: isPressed) { _, now in now }
        .onTapGesture {
            isPressed = true
            onTap?()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isPressed = false }
        }
    }

    // MARK: - Orb

    @ViewBuilder
    private var orb: some View {
        switch state {
        case .wholeUnwritten:
            PulseCyclingAura(size: AppLayout.mapUsOrbSize)
        case .split(let mine, let partner):
            SplitOrbView(
                mine:    half(for: mine, aura: myAura),
                partner: half(for: partner, aura: partnerAura),
                size:    AppLayout.mapUsOrbSize
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

    // MARK: - Body content

    @ViewBuilder
    private var bodyContent: some View {
        switch state {
        case .wholeUnwritten:
            Text("The Pulse starts with a check-in")
                .font(AppFonts.display(15, weight: .semibold, relativeTo: .subheadline))
                .foregroundStyle(AppColors.textPrimary)
            Text("One check-in from either of you begins the shared read.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

        case .split(let mine, let partner):
            Text(headline(mine: mine, partner: partner))
                .font(AppFonts.display(15, weight: .semibold, relativeTo: .subheadline))
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            namesRead(mine: mine, partner: partner)

            if partner == .quiet, let last = partnerLastEntry {
                Text("\(displayName) hasn't checked in since \(relativeDay(last.date))")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .padding(.top, AppSpacing.xxs)
            }
        }
    }

    // MARK: - Headline (spec §3.3 headline guard)

    // "A wide day between you" vs "Close today" — same copy + threshold as MapUsLayer's
    // distance read (kept in sync deliberately; MapUsLayer's copy is the legacy source
    // until that duplicate is retired in a later task). FEEL: tune threshold on device.
    private func headline(mine: UsOrbState.HalfState, partner: UsOrbState.HalfState) -> String {
        if state.allowsLiveComparison,
           let my = myPosition, let their = partnerPosition {
            let distance = my.distance(to: their)
            return distance > 0.45 ? "A wide day between you" : "Close today"
        }
        if partner == .unwritten {
            return "\(displayName) hasn't checked in yet"
        }
        return "Your last reads, side by side"
    }

    // MARK: - Names read

    @ViewBuilder
    private func namesRead(mine: UsOrbState.HalfState, partner: UsOrbState.HalfState) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
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

    let mine:    Half
    let partner: Half
    var size:    CGFloat = 98

    // FEEL: desaturation applied to an ember (quiet) half, on top of the shared
    // staleOpacity floor. 0.4 mutes without fully greying out the space colour.
    private let embersSaturation: Double = 0.4
    private let seamOpacity:      Double = 0.22
    private let seamWidth:        CGFloat = 1.2

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
                .stroke(.white.opacity(seamOpacity), lineWidth: seamWidth)

            // Rim.
            Circle()
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .scaleEffect(breathe ? 1.045 : 1.0)
        .ambientAnimation(
            .easeInOut(duration: AppAnimation.ambientPulse).repeatForever(autoreverses: true),
            value: breathe
        )
        .onAppear { startBreathe() }
    }

    @ViewBuilder
    private func halfView(_ half: Half) -> some View {
        switch half {
        case .cycling:
            PulseCyclingAura(size: size)
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
