//
//  MapChartedMoment.swift
//  Vayl
//
//  The one-shot "map charted" moment. When the first finisher completes their Desire Map,
//  the Vayl aperture draws itself on over an obscured Home, then the copy resolves. Plays
//  ONCE and dismisses, a brief beat, never a home state. The ongoing "waiting on your partner"
//  status lives quietly as an icon in the partner pill, not here.
//
//  The desire-map "world" is re-established over the obscured Home with a semi-transparent
//  atmosphere + a StarVeil, so the dimmed dashboard reads faintly through (almost home, but
//  still in the map's world). The presenter is responsible for the Home blur behind this.
//

import SwiftUI

/// How the copy enters after the mark has drawn. Tunable on device.
enum MomentCopyEntrance: String, CaseIterable {
    /// Blur → sharp: the words resolve into focus (clarity emerging, on-theme with the veil).
    case focusResolve
    /// The title fades in carrying a gentle spectrum glow that echoes the mark.
    case glowIgnite
    /// The copy springs up from beneath the mark, as if it surfaced from the aperture.
    case springRise
}

struct MapChartedMoment: View {
    let partnerName: String
    var copyEntrance: MomentCopyEntrance = .focusResolve
    var onDone: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draw: CGFloat = 0
    @State private var copyT: CGFloat = 0
    @State private var titleGlow: Double = 0

    var body: some View {
        ZStack {
            // Desire-map world over the obscured Home. Transparent enough that the dimmed
            // dashboard still reads faintly through (these opacities are the "how obscured" knobs).
            OnboardingAtmosphere(config: .cardReveal, opacity: 0.7)
                .ignoresSafeArea()
            StarVeil()
                .ignoresSafeArea()
                .opacity(0.6)
            AppColors.void.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                VaylMark(drawProgress: draw)
                    .frame(width: 116, height: 116)

                copyBlock
            }
            .padding(.horizontal, AppSpacing.xl)
        }
        .contentShape(Rectangle())
        .onTapGesture { onDone() }
        .onAppear(perform: animateIn)
    }

    private var copyBlock: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("That's yours now")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
                .modifier(TitleGlow(active: copyEntrance == .glowIgnite, intensity: titleGlow))

            Text("When \(partnerName) finishes theirs,\nyou'll see where you align.")
                .font(AppFonts.bodyText)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .modifier(CopyTransition(style: copyEntrance, t: copyT))
    }

    private func animateIn() {
        guard !reduceMotion else { draw = 1; copyT = 1; titleGlow = 0.5; return }

        withAnimation(AppAnimation.markDraw) { draw = 1 }

        let copyAnimation: Animation = copyEntrance == .springRise
            ? AppAnimation.spring
            : AppAnimation.markCopyRise
        withAnimation(copyAnimation.delay(AppAnimation.markCopyDelay)) { copyT = 1 }

        if copyEntrance == .glowIgnite {
            withAnimation(AppAnimation.markCopyRise.delay(AppAnimation.markCopyDelay)) { titleGlow = 0.55 }
        }
    }
}

// MARK: - Copy entrance modifiers

private struct CopyTransition: ViewModifier {
    let style: MomentCopyEntrance
    let t: CGFloat

    func body(content: Content) -> some View {
        switch style {
        case .focusResolve:
            content
                .opacity(Double(t))
                .blur(radius: (1 - t) * 6)
        case .glowIgnite:
            content
                .opacity(Double(t))
        case .springRise:
            content
                .opacity(Double(t))
                .scaleEffect(0.9 + 0.1 * t)
                .offset(y: (1 - t) * 20)
        }
    }
}

private struct TitleGlow: ViewModifier {
    let active: Bool
    let intensity: Double

    @ViewBuilder
    func body(content: Content) -> some View {
        if active {
            content.spectrumBorderGlow(intensity: intensity)
        } else {
            content
        }
    }
}

// MARK: - Previews

private func momentPreview(_ style: MomentCopyEntrance) -> some View {
    ZStack {
        // Mock obscured Home behind the moment (the presenter blurs the real dashboard).
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat)
            .ignoresSafeArea()
            .blur(radius: 8)
            .opacity(0.45)

        MapChartedMoment(partnerName: "Alex", copyEntrance: style)
    }
    .preferredColorScheme(.dark)
}

#Preview("1 · focus resolve") { momentPreview(.focusResolve) }
#Preview("2 · glow ignite")   { momentPreview(.glowIgnite) }
#Preview("3 · spring rise")   { momentPreview(.springRise) }
