//
//  LivingText.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/16/26.
//
//  REVISED — v2.2  (two-surface palette system)
//
//  Change log
//  ──────────────────────────────────────────────────────────────────
//  LT-01  @Environment(\.colorScheme) added.
//
//  LT-02  @Environment(\.layoutDirection) added. RTL-aware gradients.
//
//  LT-03  Dark glow refactored from boolean @State + SwiftUI implicit
//         animation to ProgressAnimationClock + TimelineView at 30fps.
//
//  LT-04  AnimationMath.bloomIntensity(phase:) used — no inline sin().
//
//  LT-05  Glow mechanism: blurred-duplicate ZStack retained as the
//         standard LivingText treatment for ALL modes and surfaces.
//         Both light and dark run the animated path. This is the
//         established visual identity — not dark-only.
//
//  LT-06  Glow opacity envelope:
//           base 0.18 + intensity × 0.18 → range 0.18–0.36
//         Matches bloomAtmoOpacityBase (G-03).
//
//  LT-07  Glow radius envelope:
//           base 6.0 + intensity × 3.0 → range 6–9pt, hard cap 9pt.
//         Matches bloomAtmoBlurBase (G-04).
//
//  LT-08  shouldAnimate = !reduceMotion — light mode is NOT excluded.
//         Both surfaces animate. Drift only starts in dark mode.
//
//  LT-09  Cycle duration constant: 3.0s (G-01 / defaultShimmerCycle).
//         breatheDur retained for ABI compatibility — unused internally.
//         driftDur still drives gradient endpoint drift in dark mode.
//
//  LT-10  Light mode gradient resolved from palette.lightStops —
//         single source of truth per case, zero call-site decisions.
//         Dark surface: palette.stops (cyan/purple arc).
//         Light surface: palette.lightStops (magenta/gold arc).
//
//  LT-11  Reduce Motion: static gradient layer, no glow, no clock.
//
//  LT-12  Increase Contrast: glow opacity boosted via constants.
//           Dark:  0.50 static
//           Light: 0.28 static
//
//  LT-13  Clock lifecycle: onAppear/onDisappear + background/foreground
//         notifications. Identical to G-07 / ProgressBar pattern.
//
//  LT-14  Private enum LivingTextConstants — all magic numbers named.
//
//  LT-15  Previews updated: dark + light variant per palette.
//
//  LT-16  Palette.lightStops added — each case carries its own warm
//         arc mapping. lightGradient reads palette.lightStops directly
//         instead of a hardcoded switch. Call sites never change.
//  ──────────────────────────────────────────────────────────────────

import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Constants
// ─────────────────────────────────────────────────────────────────────────────

private enum LivingTextConstants {

    // ── Glow envelope (LT-06, LT-07) — both modes ────────────────────────
    /// Base glow opacity — matches bloomAtmoOpacityBase (G-03)
    static let glowOpacityBase:  Double  = 0.18
    /// Pulse delta — matches bloomAtmoOpacityPulse (G-03)
    static let glowOpacityPulse: Double  = 0.18
    /// Base blur radius — matches bloomAtmoBlurBase (G-04)
    static let glowRadiusBase:   CGFloat = 6.0
    /// Pulse delta — matches bloomAtmoBlurPulse (G-04)
    static let glowRadiusPulse:  CGFloat = 3.0
    /// Hard cap — above 9pt letterforms smear (G-04)
    static let glowRadiusCap:    CGFloat = 9.0

    // ── Cycle (LT-09) ─────────────────────────────────────────────────────
    /// 3.0s — matches ProgressBarConstants.defaultShimmerCycle (G-01)
    static let cycleDuration:    Double  = 3.0

    // ── Frame rate (LT-03) ────────────────────────────────────────────────
    /// 30fps cap — matches bloomFPS in ProgressBarConstants
    static let fps:              Double  = 30.0

    // ── Gradient drift (dark only) ─────────────────────────────────────────
    /// Maximum x-axis shift for the animated gradient endpoint
    static let driftMagnitude:   CGFloat = 0.5
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - LivingText
// ─────────────────────────────────────────────────────────────────────────────

struct LivingText: View {
    let text: String
    var font: Font = AppFonts.display(28, weight: .semibold)
    var palette: Palette = .cyanPurple

    // Retained for ABI compatibility — values respected by callers.
    // glowRadius / glowFloor / glowCeil superseded by LivingTextConstants
    // envelope in animated mode. breatheDur unused in v2.2 (clock governs).
    // driftDur still drives gradient drift in dark mode.
    var glowRadius: CGFloat = 8
    var glowFloor:  Double  = 0.15
    var glowCeil:   Double  = 0.35
    var breatheDur: Double  = 4.0   // ABI compat — unused internally
    var driftDur:   Double  = 10.0  // drives gradient drift in dark mode

    // ── Environment ───────────────────────────────────────────────────────
    @Environment(\.colorScheme)     private var colorScheme
    @Environment(\.layoutDirection) private var layoutDirection

    // ── Animation state ───────────────────────────────────────────────────
    /// Gradient endpoint drift — dark mode only
    @State private var shiftPhase: CGFloat = 0.0

    /// Clock for 30fps TimelineView — runs in both modes (LT-08)
    @State private var clock = ProgressAnimationClock()

    // ── Derived flags ─────────────────────────────────────────────────────
    private var isLight: Bool { colorScheme == .light }
    private var isRTL:   Bool { layoutDirection == .rightToLeft }

    private var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    // LT-08: animate in both modes — light is not excluded
    private var shouldAnimate: Bool { !reduceMotion }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Palette
    // ─────────────────────────────────────────────────────────────────────
    // LT-16: Every case carries stops (dark) and lightStops (light).
    // The view resolves the correct set from colorScheme automatically.
    // Call sites never specify surface — adding a new surface means
    // adding a new stops property here only, zero call-site changes.

    enum Palette {
        case cyanPurple       // trust / cool        — "acquainted."
        case purpleMagenta    // intimate warmth      — "exploring?"
        case cyanMagenta      // full spectrum        — "ready?"
        case magentaGold      // heat / confidence    — "connected."
        case cyanGold         // discovery / curiosity — "begin."

        // ── Dark surface: cyan / purple arc ───────────────────────────────
        var stops: [Gradient.Stop] {
            switch self {
            case .cyanPurple:
                return [
                    .init(color: AppColors.cyan,    location: 0.00),
                    .init(color: AppColors.purple,  location: 1.00),
                ]
            case .purpleMagenta:
                return [
                    .init(color: AppColors.purple,  location: 0.00),
                    .init(color: AppColors.magenta, location: 1.00),
                ]
            case .cyanMagenta:
                return [
                    .init(color: AppColors.cyan,    location: 0.00),
                    .init(color: AppColors.purple,  location: 0.45),
                    .init(color: AppColors.magenta, location: 1.00),
                ]
            case .magentaGold:
                return [
                    .init(color: AppColors.magenta, location: 0.00),
                    .init(color: AppColors.gold,    location: 1.00),
                ]
            case .cyanGold:
                return [
                    .init(color: AppColors.cyan,    location: 0.00),
                    .init(color: AppColors.gold,    location: 1.00),
                ]
            }
        }

        // ── Light surface: magenta / gold arc ─────────────────────────────
        // No cyan on cream — reads clinical.
        // No cool purple arc on cream — reads cold against aurora blobs.
        // Each case maps its emotional intent into the warm palette.
        var lightStops: [Gradient.Stop] {
            switch self {
            case .cyanPurple:
                // Trust/cool → warm confidence on cream. Clean two-stop arc.
                return [
                    .init(color: AppColors.magenta, location: 0.00),
                    .init(color: AppColors.gold,    location: 1.00),
                ]
            case .purpleMagenta:
                // Intimate warmth → softer gold terminus via goldLight.
                return [
                    .init(color: AppColors.magenta,   location: 0.00),
                    .init(color: AppColors.goldLight, location: 1.00),
                ]
            case .cyanMagenta:
                // Full spectrum → full warm arc. Three stops mirror the
                // dark three-stop structure — pink peaks in the middle.
                return [
                    .init(color: AppColors.magenta, location: 0.00),
                    .init(color: AppColors.pink,    location: 0.45),
                    .init(color: AppColors.gold,    location: 1.00),
                ]
            case .magentaGold:
                // Already the warm anchor — identical to dark stops.
                return [
                    .init(color: AppColors.magenta, location: 0.00),
                    .init(color: AppColors.gold,    location: 1.00),
                ]
            case .cyanGold:
                // Discovery/curiosity → softer magenta entry via
                // magentaLight so it doesn't hit as hard as full magenta.
                return [
                    .init(color: AppColors.magentaLight, location: 0.00),
                    .init(color: AppColors.gold,         location: 1.00),
                ]
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Gradients
    // ─────────────────────────────────────────────────────────────────────

    // ── Dark: palette.stops with animated endpoint drift ──────────────────
    private func darkGradient(shift: CGFloat) -> LinearGradient {
        if isRTL {
            return LinearGradient(
                stops:      palette.stops,
                startPoint: UnitPoint(x: 1.4 - shift, y: 1),
                endPoint:   UnitPoint(x: -shift,      y: 0)
            )
        } else {
            return LinearGradient(
                stops:      palette.stops,
                startPoint: UnitPoint(x: -shift,      y: 0),
                endPoint:   UnitPoint(x: 1.4 - shift, y: 1)
            )
        }
    }

    // ── Light: palette.lightStops — static, no drift (LT-16) ─────────────
    // Single source of truth per palette case.
    // lightGradient reads lightStops directly — no hardcoded switch here.
    // Callers set palette once; surface resolution is automatic.
    private var lightGradient: LinearGradient {
        LinearGradient(
            stops:      palette.lightStops,
            startPoint: isRTL ? .trailing : .leading,
            endPoint:   isRTL ? .leading  : .trailing
        )
    }

    // ── Surface resolver ──────────────────────────────────────────────────
    private func resolvedGradient(shift: CGFloat) -> LinearGradient {
        isLight ? lightGradient : darkGradient(shift: shift)
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Text layer builder
    // ─────────────────────────────────────────────────────────────────────

    private func baseText(gradient: LinearGradient) -> some View {
        Text(text)
            .font(font)
            .foregroundStyle(gradient)
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Animated layers
    // ─────────────────────────────────────────────────────────────────────
    // Standard LivingText treatment — both surfaces (LT-05).
    // ZStack: blurred duplicate (glow breath) + crisp fill on top.
    // Dark: drifting palette gradient.
    // Light: static lightGradient — gradient does the visual work.
    // Clock runs in both modes — glow breathes on cream too.

    @ViewBuilder
    private func animatedTextLayers(intensity: CGFloat) -> some View {
        let grad = resolvedGradient(shift: shiftPhase)

        let glowOpacity = LivingTextConstants.glowOpacityBase
                        + Double(intensity) * LivingTextConstants.glowOpacityPulse

        let radius = min(
            LivingTextConstants.glowRadiusBase
            + intensity * LivingTextConstants.glowRadiusPulse,
            LivingTextConstants.glowRadiusCap
        )

        ZStack {
            // Layer 1: Blurred duplicate — glow breath
            baseText(gradient: grad)
                .blur(radius: radius)
                .opacity(glowOpacity)
                .padding(-4)

            // Layer 2: Crisp gradient fill
            baseText(gradient: grad)
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Static layer (reduce motion)
    // ─────────────────────────────────────────────────────────────────────

    private var staticTextLayer: some View {
        baseText(gradient: resolvedGradient(shift: 0))
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Timeline schedule
    // ─────────────────────────────────────────────────────────────────────

    private var timelineSchedule: PeriodicTimelineSchedule {
        .periodic(from: .now, by: 1.0 / LivingTextConstants.fps)
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Body
    // ─────────────────────────────────────────────────────────────────────

    var body: some View {
        Group {
            if shouldAnimate {
                // ── Animated — dark AND light (LT-08) ────────────────────
                TimelineView(timelineSchedule) { tl in
                    let elapsed   = clock.elapsed(at: tl.date)
                    let phase     = AnimationMath.shimmerPhase(
                                        elapsed:       elapsed,
                                        cycleDuration: CGFloat(LivingTextConstants.cycleDuration)
                                    )
                    let intensity = AnimationMath.bloomIntensity(phase: phase)

                    animatedTextLayers(intensity: intensity)
                }
                .onAppear {
                    clock.activate()                         // LT-13
                    if !isLight { startDriftAnimation() }    // drift dark only
                }
                .onDisappear { clock.reset() }               // LT-13
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIApplication.didEnterBackgroundNotification
                    )
                ) { _ in clock.reset() }                     // LT-13
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIApplication.willEnterForegroundNotification
                    )
                ) { _ in clock.activate() }                  // LT-13

            } else {
                // ── Reduce Motion: crisp gradient, no glow (LT-11) ───────
                staticTextLayer
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Drift animation
    // ─────────────────────────────────────────────────────────────────────
    // Dark mode only — light gradient is intentionally static.
    // Runs as a separate SwiftUI animation independent of the clock
    // so the two phases naturally drift apart over time.

    private func startDriftAnimation() {
        withAnimation(
            .easeInOut(duration: driftDur)
            .repeatForever(autoreverses: true)
        ) {
            shiftPhase = LivingTextConstants.driftMagnitude
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Previews
// ─────────────────────────────────────────────────────────────────────────────

#Preview("cyanPurple — acquainted · dark") {
    VStack(alignment: .leading, spacing: 4) {
        Text("Let's get")
            .font(AppFonts.display(28, weight: .semibold))
            .foregroundColor(.white)
        LivingText(
            text:      "acquainted.",
            palette:   .cyanPurple,
            glowRadius: 6,
            glowFloor:  0.12,
            glowCeil:   0.28,
            breatheDur: 5.0,
            driftDur:   12.0
        )
    }
    .padding(28)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

#Preview("cyanPurple — acquainted · light") {
    VStack(alignment: .leading, spacing: 4) {
        Text("Let's get")
            .font(AppFonts.display(28, weight: .semibold))
            .foregroundColor(AppColors.lightTextPrimary)
        LivingText(
            text:      "acquainted.",
            palette:   .cyanPurple,
            glowRadius: 6,
            glowFloor:  0.12,
            glowCeil:   0.28,
            breatheDur: 5.0,
            driftDur:   12.0
        )
    }
    .padding(28)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(AppColors.lightPageBg)
    .preferredColorScheme(.light)
}

#Preview("purpleMagenta — exploring · dark") {
    VStack(alignment: .leading, spacing: 4) {
        Text("How are you")
            .font(AppFonts.display(28, weight: .semibold))
            .foregroundColor(.white)
        LivingText(
            text:      "exploring?",
            palette:   .purpleMagenta,
            glowRadius: 10,
            glowFloor:  0.18,
            glowCeil:   0.38,
            breatheDur: 4.0,
            driftDur:   10.0
        )
    }
    .padding(28)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

#Preview("purpleMagenta — exploring · light") {
    VStack(alignment: .leading, spacing: 4) {
        Text("How are you")
            .font(AppFonts.display(28, weight: .semibold))
            .foregroundColor(AppColors.lightTextPrimary)
        LivingText(
            text:      "exploring?",
            palette:   .purpleMagenta,
            glowRadius: 10,
            glowFloor:  0.18,
            glowCeil:   0.38,
            breatheDur: 4.0,
            driftDur:   10.0
        )
    }
    .padding(28)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(AppColors.lightPageBg)
    .preferredColorScheme(.light)
}

#Preview("cyanMagenta — ready · dark") {
    VStack(alignment: .leading, spacing: 4) {
        Text("Are you")
            .font(AppFonts.display(28, weight: .semibold))
            .foregroundColor(.white)
        LivingText(
            text:      "ready?",
            palette:   .cyanMagenta,
            glowRadius: 14,
            glowFloor:  0.22,
            glowCeil:   0.45,
            breatheDur: 3.0,
            driftDur:   8.0
        )
    }
    .padding(28)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

#Preview("cyanMagenta — ready · light") {
    VStack(alignment: .leading, spacing: 4) {
        Text("Are you")
            .font(AppFonts.display(28, weight: .semibold))
            .foregroundColor(AppColors.lightTextPrimary)
        LivingText(
            text:      "ready?",
            palette:   .cyanMagenta,
            glowRadius: 14,
            glowFloor:  0.22,
            glowCeil:   0.45,
            breatheDur: 3.0,
            driftDur:   8.0
        )
    }
    .padding(28)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(AppColors.lightPageBg)
    .preferredColorScheme(.light)
}

#Preview("magentaGold — connected · dark") {
    VStack(alignment: .leading, spacing: 4) {
        Text("Stay")
            .font(AppFonts.display(28, weight: .semibold))
            .foregroundColor(.white)
        LivingText(
            text:      "connected.",
            palette:   .magentaGold,
            glowRadius: 10,
            glowFloor:  0.15,
            glowCeil:   0.35,
            breatheDur: 4.0,
            driftDur:   10.0
        )
    }
    .padding(28)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

#Preview("magentaGold — connected · light") {
    VStack(alignment: .leading, spacing: 4) {
        Text("Stay")
            .font(AppFonts.display(28, weight: .semibold))
            .foregroundColor(AppColors.lightTextPrimary)
        LivingText(
            text:      "connected.",
            palette:   .magentaGold,
            glowRadius: 10,
            glowFloor:  0.15,
            glowCeil:   0.35,
            breatheDur: 4.0,
            driftDur:   10.0
        )
    }
    .padding(28)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(AppColors.lightPageBg)
    .preferredColorScheme(.light)
}

#Preview("cyanGold — begin · dark") {
    VStack(alignment: .leading, spacing: 4) {
        Text("Let's")
            .font(AppFonts.display(28, weight: .semibold))
            .foregroundColor(.white)
        LivingText(
            text:      "begin.",
            palette:   .cyanGold,
            glowRadius: 8,
            glowFloor:  0.15,
            glowCeil:   0.32,
            breatheDur: 4.5,
            driftDur:   11.0
        )
    }
    .padding(28)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

#Preview("cyanGold — begin · light") {
    VStack(alignment: .leading, spacing: 4) {
        Text("Let's")
            .font(AppFonts.display(28, weight: .semibold))
            .foregroundColor(AppColors.lightTextPrimary)
        LivingText(
            text:      "begin.",
            palette:   .cyanGold,
            glowRadius: 8,
            glowFloor:  0.15,
            glowCeil:   0.32,
            breatheDur: 4.5,
            driftDur:   11.0
        )
    }
    .padding(28)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(AppColors.lightPageBg)
    .preferredColorScheme(.light)
}
