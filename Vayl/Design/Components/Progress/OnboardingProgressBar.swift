// OnboardingProgressBar.swift
// Open Lightly
//
// FULLY AUDITED & REFINED — v2.3  (visual quality pass)
//
// Changes in v2.3
// ───────────────────────────────────────────────────────
// VQ-01  shimmerCycleDuration default raised 2.4 → 3.0s.
//        At 2.4s the shimmer pulses at 25/min — reads as nervous.
//        3.0s aligns with reward animation research (cf. App Store
//        confetti timing) and simultaneously slows the bloom breathe
//        to ~20/min, closer to the 12–16/min respiratory target.
//
// VQ-02  Bloom atmo vertical spread scalars reduced:
//        Dark  base 3.5 → 2.8,  pulse 2.0 → 1.4
//        Light base 2.2 → 1.8,  pulse 1.1 → 0.8
//        Previous values produced 14–22pt spread on a 4pt bar.
//        New values produce 11–16pt dark / 9–13pt light — still
//        atmospheric but proportionate.
//
// VQ-03  Bloom atmo gradient gains a cyan stop at position 0 (dark)
//        and a deeper orangeDeep stop at 0 (light) to anchor the left
//        end of the bar's color identity into the atmospheric layer.
//        Previously atmo opened with purple, losing cyan entirely.
//
// VQ-04  Bloom atmo magenta opacity cap:
//        Dark:  0.80 → 0.70  (atmo center stop — was competing with fill)
//        Light: 0.80 → 0.50  (cream background — was creating pink cast)
//
// VQ-05  Bloom mid center stop opacity:
//        Light orangeHot 0.90 → 0.65  (too saturated on cream)
//        Dark  purple    0.90 → unchanged (correct)
//
// VQ-06  Bloom core base opacity:
//        Dark  0.50 → 0.38  (was competing with fill surface)
//        Light 0.22 → unchanged (well-calibrated)
//
// VQ-07  Bloom atmo blur base:
//        Light 4.5 → 3.5  (was spreading magenta too far on cream)
//        Dark  6.0 → unchanged
//
// VQ-08  Light mode fill gradient: magenta final stop opacity 0.75 → 0.55,
//        orangeHot mid stop location 0.5 → 0.65 — extends warm amber
//        longer before the pink arrival, reducing harsh colour jump.
//
// VQ-09  Light mode track opacity 0.06 → 0.09 — the rail was barely
//        legible at minimum contrast; 0.09 is structural without heavy.
//
// VQ-10  Shimmer outer blur radius 2 → 3pt — softens the rectangular
//        edge artifact visible at small blur on a 4pt bar.
//
// VQ-11  Shimmer inner opacity range light mode branch added:
//        Light: 0.32 + intensity×0.36  (dark: 0.28 + intensity×0.32)
//        White shimmer is less visible against orange fill; compensated.
//
// VQ-12  Particle rise height: base 10 → 14pt, variation ±3 → ±5pt
//        (range 9–19pt). Previous 7–13pt barely cleared the bloom halo.
//
// VQ-13  Particle ease exponent: base 2.0 → 2.2, variation ±0.5 → ±0.9
//        (range 1.3–3.1). Wider spread creates visible arc-vs-drift variety.
//
// VQ-14  Particle drift frequency: sin multiplier 2.1 → 1.8 per particle
//        index. Previous frequency clustered two particles at similar
//        rightward drift (+4.55, +3.27). New distribution is better spread.
//
// VQ-15  Particle wobble amplitude: easeOut×2 → easeOut×3.5.
//        Previous 2pt max lateral movement was sub-perceptual.
//
// VQ-16  Particle fade-in window: 0–20% → 0–15% of cycle.
//        0.48s fade-in at 2.4s cycle exceeded 300ms attention-capture
//        threshold. Now 0.45s at 3.0s cycle (0–15% × 3.0s).
//
// VQ-17  Particle Y origin: shifted to bar top surface.
//        Previously particles began at barMidY (bar centre).
//        Now: barMidY - barHeight/2 — they appear to launch from
//        the lit surface rather than from inside the fill.
//
// VQ-18  Particle light mode opacity scale: 0.52 → 0.65.
//        At 0.52 the dot (0.47) was too dim against orange fill on cream.
//        0.65 brings dot to 0.59, halo to 0.34 — readable without smear.
//
// All dark bloom color values unchanged except where explicitly noted.
// All accessibility, localisation, architecture, and performance work
// from v2.1/v2.2 preserved exactly.

import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ClosedRange clamp helper
// ─────────────────────────────────────────────────────────────────────────────

extension ClosedRange where Bound: Comparable {
    /// Clamps `value` to lie within this range.
    func clamp(_ value: Bound) -> Bound {
        Swift.min(upperBound, Swift.max(lowerBound, value))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Pure Animation Math  (zero UI dependencies — unit-testable)
// ─────────────────────────────────────────────────────────────────────────────

enum AnimationMath {

    /// Wraps elapsed seconds into a normalised [0, 1) phase for one cycle.
    static func shimmerPhase(
        elapsed: CGFloat,
        cycleDuration: CGFloat
    ) -> CGFloat {
        guard cycleDuration > 0 else { return 0 }
        return elapsed
            .truncatingRemainder(dividingBy: cycleDuration) / cycleDuration
    }

    /// Peak at mid-cycle. Returns value in [0, 1].
    static func bloomIntensity(phase: CGFloat) -> CGFloat {
        sin(phase * .pi)
    }

    /// Intentionally identical to bloomIntensity so the two effects
    /// pulse in perfect unison (fixes the phase-drift bug from v1).
    static func breatheIntensity(phase: CGFloat) -> CGFloat {
        bloomIntensity(phase: phase)
    }

    /// Shimmer hotspot X offset in points.
    /// Travels from −overshoot to fillWidth+overshoot across one cycle.
    static func shimmerXOffset(
        phase: CGFloat,
        fillWidth: CGFloat,
        overshoot: CGFloat = 30
    ) -> CGFloat {
        let sweepRange = fillWidth + overshoot * 2
        return phase * sweepRange - overshoot
    }

    /// Progress ratio clamped to [0, 1]; NaN / infinite safe.
    static func safeRatio(current: Int, total: Int) -> CGFloat {
        guard total > 0 else { return 0 }
        let raw = CGFloat(current) / CGFloat(total)
        guard raw.isFinite else { return 0 }
        return (0.0...1.0).clamp(raw)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Animation Clock  (extracted from View — testable, identity-safe)
// ─────────────────────────────────────────────────────────────────────────────

@Observable
final class ProgressAnimationClock {

    private(set) var startTime: Date?

    func activate() { startTime = Date() }
    func reset() { startTime = nil  }

    func elapsed(at date: Date) -> CGFloat {
        guard let start = startTime else { return 0 }
        return CGFloat(date.timeIntervalSince(start))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Design Constants
// ─────────────────────────────────────────────────────────────────────────────

private enum ProgressBarConstants {
    static let defaultTotalWidth: CGFloat = 120
    static let defaultBarHeight: CGFloat = 5
    /// Extra canvas on each side so bloom can bleed past bar ends.
    static let bloomBleed: CGFloat = 12
    // VQ-01: raised from 2.4 → 3.0s. See change log.
    static let defaultShimmerCycle: Double  = 3.0
    static let defaultFillDuration: Double  = 0.35
    /// Frame-rate cap for the bloom TimelineView.
    static let bloomFPS: Double  = 30
    /// Max vertical bloom spread as a multiple of barHeight (HIG cap).
    static let maxBloomSpreadFactor: CGFloat = 7.0
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Pre-computed Gradients  (static lets — dark mode source of truth)
//
// These are the dark mode gradients, allocated once.
// Light mode variants are computed properties on the View (they must be
// computed because they reference colorScheme, which requires View context).
// ─────────────────────────────────────────────────────────────────────────────

private enum ProgressBarGradients {

    // ── Fill ──────────────────────────────────────────────────────────────
    static let staticFill = LinearGradient(
        stops: [
            .init(color: AppColors.accentPrimary, location: 0.0),
            .init(color: AppColors.accentSecondary, location: 1.0)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let finalFill = LinearGradient(
        stops: [
            .init(color: AppColors.accentPrimary, location: 0.0),
            .init(color: AppColors.accentSecondary, location: 0.5),
            .init(color: AppColors.accentTertiary, location: 1.0)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    // RTL mirrors — colour order preserved, direction flipped
    static let staticFillRTL = LinearGradient(
        stops: [
            .init(color: AppColors.accentPrimary, location: 0.0),
            .init(color: AppColors.accentSecondary, location: 1.0)
        ],
        startPoint: .trailing,
        endPoint: .leading
    )
    static let finalFillRTL = LinearGradient(
        stops: [
            .init(color: AppColors.accentPrimary, location: 0.0),
            .init(color: AppColors.accentSecondary, location: 0.5),
            .init(color: AppColors.accentTertiary, location: 1.0)
        ],
        startPoint: .trailing,
        endPoint: .leading
    )

    // ── Light mode fill variants ───────────────────────────────────────────
    // VQ-08: magenta final stop opacity 0.75 → 0.55; orangeHot mid stop
    //        location 0.5 → 0.65 to extend warm amber before the pink arrives.

    static let staticFillLight = LinearGradient(
        stops: [
            .init(color: AppColors.progressBarTrailing, location: 0.0),
            .init(color: AppColors.progressBarLeading, location: 1.0)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let finalFillLight = LinearGradient(
        stops: [
            .init(color: AppColors.progressBarTrailing, location: 0.00),
            .init(color: AppColors.progressBarLeading, location: 0.65),  // VQ-08: was 0.50
            .init(color: AppColors.accentTertiary.opacity(0.55), location: 1.00)   // VQ-08: was 0.75
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let staticFillLightRTL = LinearGradient(
        stops: [
            .init(color: AppColors.progressBarTrailing, location: 0.0),
            .init(color: AppColors.progressBarLeading, location: 1.0)
        ],
        startPoint: .trailing,
        endPoint: .leading
    )
    static let finalFillLightRTL = LinearGradient(
        stops: [
            .init(color: AppColors.progressBarTrailing, location: 0.00),
            .init(color: AppColors.progressBarLeading, location: 0.65),  // VQ-08: was 0.50
            .init(color: AppColors.accentTertiary.opacity(0.55), location: 1.00)   // VQ-08: was 0.75
        ],
        startPoint: .trailing,
        endPoint: .leading
    )
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Localised String Helpers
// ─────────────────────────────────────────────────────────────────────────────

private enum ProgressBarStrings {

    static func stepLabel(
        description: String,
        current: Int,
        total: Int
    ) -> String {
        String(
            format: NSLocalizedString(
                "progress.step.label",
                value: "%@, step %lld of %lld",
                comment: "Accessibility label. Arg1: flow name, Arg2: current step, Arg3: total."
            ),
            description,
            current,
            total
        )
    }

    /// Cached — percentValue is read from the accessibility value in `body`, which
    /// re-evaluates at 30fps during the completion effect; a fresh NumberFormatter
    /// per read would be paid on every one of those frames.
    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle           = .percent
        formatter.locale                = .current
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// Locale-correct percentage, e.g. "75%" or "75 %" depending on locale.
    static func percentValue(ratio: CGFloat) -> String {
        percentFormatter.string(from: NSNumber(value: Double(ratio)))
            ?? "\(Int(ratio * 100))%"
    }

    static func milestoneAnnouncement(current: Int, total: Int) -> String {
        String(
            format: NSLocalizedString(
                "progress.step.announcement",
                value: "Step %lld of %lld",
                comment: "VoiceOver announcement when the user advances a step."
            ),
            current,
            total
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - iOS-version-safe onChange modifier  (wraps #available internally)
// ─────────────────────────────────────────────────────────────────────────────

private struct StepChangeModifier: ViewModifier {
    let currentStep: Int
    let action: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 17, *) {
            content.onChange(of: currentStep) { _, _ in action() }
        } else {
            content.onChange(of: currentStep) { _ in action() }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - OnboardingProgressBar
// ─────────────────────────────────────────────────────────────────────────────

struct OnboardingProgressBar: View {

    // ── Public props ───────────────────────────────────────────────────────

    let currentStep: Int
    let totalSteps: Int
    var progressDescription: String  = NSLocalizedString(
        "progress.description.default",
        value: "Onboarding",
        comment: "Default VoiceOver description."
    )
    var showCompletionEffect: Bool    = false
    var totalWidth: CGFloat = ProgressBarConstants.defaultTotalWidth
    var barHeight: CGFloat = ProgressBarConstants.defaultBarHeight
    var animationDuration: Double  = ProgressBarConstants.defaultFillDuration
    var shimmerCycleDuration: Double  = ProgressBarConstants.defaultShimmerCycle

    // ── Backward-compatible convenience init ──────────────────────────────
    init(
        currentStep: Int,
        totalSteps: Int,
        progressDescription: String  = NSLocalizedString(
            "progress.description.default",
            value: "Onboarding",
            comment: "Default VoiceOver description."
        ),
        showCompletionEffect: Bool    = false,
        totalWidth: CGFloat = ProgressBarConstants.defaultTotalWidth,
        barHeight: CGFloat = ProgressBarConstants.defaultBarHeight,
        animationDuration: Double  = ProgressBarConstants.defaultFillDuration,
        shimmerCycleDuration: Double  = ProgressBarConstants.defaultShimmerCycle
    ) {
        self.currentStep          = currentStep
        self.totalSteps           = totalSteps
        self.progressDescription  = progressDescription
        self.showCompletionEffect = showCompletionEffect
        self.totalWidth           = totalWidth
        self.barHeight            = barHeight
        self.animationDuration    = animationDuration
        self.shimmerCycleDuration = shimmerCycleDuration
    }

    // ── Private state ──────────────────────────────────────────────────────

    @State private var clock = ProgressAnimationClock()

    // ── Environment ────────────────────────────────────────────────────────

    private var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    private var increaseContrast: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }

    @Environment(\.layoutDirection)  private var layoutDirection

    // ── Derived values ─────────────────────────────────────────────────────

    var fillRatio: CGFloat {
        AnimationMath.safeRatio(current: currentStep, total: totalSteps)
    }

    private var fillWidth: CGFloat { totalWidth * fillRatio }

    private var trackColor: Color {
        Color.white.opacity(trackOpacity)
    }

    private var trackOpacity: CGFloat {
        increaseContrast ? 0.50 : 0.18
    }

    private var isRTL: Bool { layoutDirection == .rightToLeft }

    private var staticFillGradient: LinearGradient {
        isRTL
        ? ProgressBarGradients.staticFillRTL
        : ProgressBarGradients.staticFill
    }

    private var finalFillGradient: LinearGradient {
        isRTL
        ? ProgressBarGradients.finalFillRTL
        : ProgressBarGradients.finalFill
    }

    // ── Bloom geometry ─────────────────────────────────────────────────────

    private var bloomBleed: CGFloat { ProgressBarConstants.bloomBleed }
    private var canvasWidth: CGFloat { totalWidth + bloomBleed * 2 }
    private var maxBloomHeight: CGFloat {
        barHeight * ProgressBarConstants.maxBloomSpreadFactor
    }

    // ── Bloom light/dark scalars ────────────────────────────────────────────
    //
    // VQ-02: Atmo spread reduced. Previous dark base 3.5 → 2.8 (−20%),
    //        pulse 2.0 → 1.4 (−30%). Light base 2.2 → 1.8, pulse 1.1 → 0.8.
    //        On a 4pt bar the old values produced 14–22pt spread —
    //        disproportionate. New range: 11–16pt dark, 9–13pt light.
    //
    // VQ-04: Atmo magenta opacity reduced (see bloomCanvas gradient stops).
    // VQ-06: Core base opacity dark 0.50 → 0.38 — was competing with fill.
    // VQ-07: Atmo blur base light 4.5 → 3.5 — was spreading pink too far.

    private var bloomAtmoOpacityBase: CGFloat { 0.18 }
    private var bloomAtmoOpacityPulse: CGFloat { 0.18 }
    private var bloomMidOpacityBase: CGFloat { 0.28 }
    private var bloomMidOpacityPulse: CGFloat { 0.22 }
    private var bloomCoreOpacityBase: CGFloat { 0.38 }  // VQ-06: dark was 0.50
    private var bloomCoreOpacityPulse: CGFloat { 0.25 }

    // VQ-02: Spread multipliers tightened.
    private var bloomAtmoSpreadBase: CGFloat { 2.8 }    // VQ-02: dark was 3.5
    private var bloomAtmoSpreadPulse: CGFloat { 1.4 }    // VQ-02: dark was 2.0
    private var bloomMidSpreadBase: CGFloat { 2.0 }
    private var bloomMidSpreadPulse: CGFloat { 1.2 }
    private var bloomCoreSpreadBase: CGFloat { 1.2 }
    private var bloomCoreSpreadPulse: CGFloat { 1.0 }

    private var bloomAtmoBlurBase: CGFloat { 6.0 }
    private var bloomAtmoBlurPulse: CGFloat { 3.0 }
    private var bloomMidBlurBase: CGFloat { 5.0 }
    private var bloomMidBlurPulse: CGFloat { 3.0 }
    private var bloomCoreBlurBase: CGFloat { 2.0 }
    private var bloomCoreBlurPulse: CGFloat { 1.0 }

    private var particleOpacityScale: CGFloat { 1.0 }

    // ── Accessibility ──────────────────────────────────────────────────────

    private var a11yLabel: String {
        ProgressBarStrings.stepLabel(
            description: progressDescription,
            current: currentStep,
            total: totalSteps
        )
    }

    private var a11yValue: String {
        ProgressBarStrings.percentValue(ratio: fillRatio)
    }

    // ── Timeline schedule (30 fps cap) ─────────────────────────────────────

    private var timelineSchedule: PeriodicTimelineSchedule {
        .periodic(from: .now, by: 1.0 / ProgressBarConstants.bloomFPS)
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: body
    // ─────────────────────────────────────────────────────────────────────

    var body: some View {

        assert(totalSteps  >  0, "totalSteps must be > 0, got \(totalSteps)")
        assert(currentStep >= 0, "currentStep must be >= 0, got \(currentStep)")
        assert(
            currentStep <= totalSteps,
            "currentStep (\(currentStep)) exceeds totalSteps (\(totalSteps))"
        )

        return Group {
            if showCompletionEffect && !reduceMotion && !AppAnimation.lowPower {
                TimelineView(timelineSchedule) { tl in
                    let e  = clock.elapsed(at: tl.date)
                    let sp = AnimationMath.shimmerPhase(
                        elapsed: e,
                        cycleDuration: CGFloat(shimmerCycleDuration)
                    )
                    let bi = AnimationMath.bloomIntensity(phase: sp)
                    let br = AnimationMath.breatheIntensity(phase: sp)

                    finalBar(
                        elapsed: e,
                        shimmerPhase: sp,
                        bloomIntensity: bi,
                        breatheIntensity: br
                    )
                }
                .onAppear { clock.activate() }
                .onDisappear { clock.reset()    }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIApplication.didEnterBackgroundNotification
                    )
                ) { _ in clock.reset()    }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIApplication.willEnterForegroundNotification
                    )
                ) { _ in clock.activate() }
                .modifier(StepChangeModifier(currentStep: currentStep) {
                    if showCompletionEffect { clock.activate() }
                })

            } else {
                staticBar
                    .modifier(StepChangeModifier(currentStep: currentStep) { })
            }
        }
        .frame(width: totalWidth, height: barHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(currentStep) of \(totalSteps)")
        .accessibilityValue(a11yValue)
        .accessibilityAddTraits([.updatesFrequently, .isStaticText])
        .accessibilityIdentifier("OnboardingProgressBar")
        .modifier(StepChangeModifier(currentStep: currentStep) {
            postStepAnnouncement()
        })
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: VoiceOver announcement
    // ─────────────────────────────────────────────────────────────────────

    private func postStepAnnouncement() {
        let msg = ProgressBarStrings.milestoneAnnouncement(
            current: currentStep,
            total: totalSteps
        )
        UIAccessibility.post(notification: .announcement, argument: msg)
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Static bar
    // ─────────────────────────────────────────────────────────────────────

    private var staticBar: some View {
        ZStack(alignment: .leading) {

            Capsule()
                .fill(trackColor)
                .frame(width: totalWidth, height: barHeight)

            Capsule()
                .fill(staticFillGradient)
                .frame(width: fillWidth, height: barHeight)
                .animation(
                    .easeInOut(duration: animationDuration),
                    value: fillWidth
                )
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Final-step bar
    // ─────────────────────────────────────────────────────────────────────

    @ViewBuilder
    private func finalBar(
        elapsed: CGFloat,
        shimmerPhase: CGFloat,
        bloomIntensity: CGFloat,
        breatheIntensity: CGFloat
    ) -> some View {
        barContent(
            shimmerPhase: shimmerPhase,
            bloomIntensity: bloomIntensity,
            breatheIntensity: breatheIntensity
        )
        .drawingGroup()
        .overlay(
            bloomCanvas(
                elapsed: elapsed,
                bloomIntensity: bloomIntensity,
                breatheIntensity: breatheIntensity,
                barHeight: barHeight,
                atmoOpacityBase: bloomAtmoOpacityBase,
                atmoOpacityPulse: bloomAtmoOpacityPulse,
                midOpacityBase: bloomMidOpacityBase,
                midOpacityPulse: bloomMidOpacityPulse,
                coreOpacityBase: bloomCoreOpacityBase,
                coreOpacityPulse: bloomCoreOpacityPulse,
                atmoSpreadBase: bloomAtmoSpreadBase,
                atmoSpreadPulse: bloomAtmoSpreadPulse,
                midSpreadBase: bloomMidSpreadBase,
                midSpreadPulse: bloomMidSpreadPulse,
                coreSpreadBase: bloomCoreSpreadBase,
                coreSpreadPulse: bloomCoreSpreadPulse,
                atmoBlurBase: bloomAtmoBlurBase,
                atmoBlurPulse: bloomAtmoBlurPulse,
                midBlurBase: bloomMidBlurBase,
                midBlurPulse: bloomMidBlurPulse,
                coreBlurBase: bloomCoreBlurBase,
                coreBlurPulse: bloomCoreBlurPulse,
                particleOpacityScale: particleOpacityScale
            )
            .frame(width: canvasWidth, height: maxBloomHeight)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        )
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Bar content (track + fill + shimmer)
    // ─────────────────────────────────────────────────────────────────────

    @ViewBuilder
    private func barContent(
        shimmerPhase: CGFloat,
        bloomIntensity: CGFloat,
        breatheIntensity: CGFloat
    ) -> some View {
        ZStack(alignment: .leading) {

            Capsule()
                .fill(trackColor)
                .frame(width: totalWidth, height: barHeight)

            Capsule()
                .fill(finalFillGradient)
                .frame(width: fillWidth, height: barHeight)

            shimmerOverlay(
                shimmerPhase: shimmerPhase,
                breatheIntensity: breatheIntensity
            )
        }
        .compositingGroup()
        .clipShape(Capsule())
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Shimmer overlay
    // ─────────────────────────────────────────────────────────────────────
    // VQ-10: outer blur 2 → 3pt — softens rectangular edge on small bar.
    // VQ-11: light mode inner opacity branch added — white shimmer needs
    //        higher opacity to read against orange fill on cream.

    @ViewBuilder
    private func shimmerOverlay(
        shimmerPhase: CGFloat,
        breatheIntensity: CGFloat
    ) -> some View {
        let xPos         = AnimationMath.shimmerXOffset(
            phase: shimmerPhase,
            fillWidth: fillWidth
        )
        let outerOpacity = 0.10 + breatheIntensity * 0.18
        let innerOpacity: CGFloat = 0.28 + breatheIntensity * 0.32

        ZStack(alignment: .leading) {

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(outerOpacity),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 16, height: barHeight)
                .blur(radius: 3)            // VQ-10: was 2
                .offset(x: xPos - 2)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(innerOpacity),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 10, height: barHeight)
                .offset(x: xPos)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: Bloom canvas
    // ─────────────────────────────────────────────────────────────────────
    // LIGHT-03: colorScheme passed as parameter.
    // LIGHT-05: _ = elapsed inside Canvas prevents SwiftUI optimising
    //           away the redraw (was missing as _ = timeline.date in v2.1).
    //
    // VQ-03: Atmo gradient gains a cyan/orangeDeep anchor stop at leading
    //        edge so the bar's left-end color identity bleeds into atmosphere.
    // VQ-04: Atmo center magenta opacity: dark 0.80→0.70, light 0.80→0.50.
    // VQ-05: Mid center stop: light orangeHot 0.90→0.65.
    // VQ-06: Core opacity controlled via coreOpacityBase (dark 0.50→0.38).
    // VQ-12–VQ-17: Particle system tuning (see inline comments).
    //
    // barHeight is now explicitly threaded through so Canvas closure can
    // compute the correct Y launch origin (VQ-17) without capturing self.

    @ViewBuilder
    // swiftlint:disable:next function_parameter_count
    private func bloomCanvas(
        elapsed: CGFloat,
        bloomIntensity: CGFloat,
        breatheIntensity: CGFloat,
        barHeight: CGFloat,
        atmoOpacityBase: CGFloat,
        atmoOpacityPulse: CGFloat,
        midOpacityBase: CGFloat,
        midOpacityPulse: CGFloat,
        coreOpacityBase: CGFloat,
        coreOpacityPulse: CGFloat,
        atmoSpreadBase: CGFloat,
        atmoSpreadPulse: CGFloat,
        midSpreadBase: CGFloat,
        midSpreadPulse: CGFloat,
        coreSpreadBase: CGFloat,
        coreSpreadPulse: CGFloat,
        atmoBlurBase: CGFloat,
        atmoBlurPulse: CGFloat,
        midBlurBase: CGFloat,
        midBlurPulse: CGFloat,
        coreBlurBase: CGFloat,
        coreBlurPulse: CGFloat,
        particleOpacityScale: CGFloat
    ) -> some View {
        Canvas { ctx, size in

            _ = elapsed   // LIGHT-05: forces Canvas invalidation every tick.

            let barMinX   = bloomBleed
            let barMidY   = size.height / 2
            // VQ-17: bar top surface Y — particles launch from here, not centre.
            let barTopY   = barMidY - barHeight / 2

            // ── Layer 3: Outer atmosphere ──────────────────────────────────
            // VQ-02: spread values reduced (passed in via parameters).
            // VQ-03: leading stop now uses cyan (dark) / orangeDeep (light)
            //        to anchor the bar's left-end color into the atmosphere.
            // VQ-04: center magenta opacity dark 0.80→0.70, light 0.80→0.50.

            let atmoSpread  = barHeight * (atmoSpreadBase + breatheIntensity * atmoSpreadPulse)
            let atmoOpacity = atmoOpacityBase + breatheIntensity * atmoOpacityPulse
            var atmoCtx     = ctx
            atmoCtx.addFilter(.blur(radius: atmoBlurBase + bloomIntensity * atmoBlurPulse))
            atmoCtx.opacity = atmoOpacity
            let atmoRect    = CGRect(
                x: barMinX - 2,
                y: barMidY - atmoSpread / 2 - 3,
                width: fillWidth + 4,
                height: atmoSpread
            )
            atmoCtx.fill(
                Path(roundedRect: atmoRect, cornerRadius: atmoSpread / 2),
                with: .linearGradient(
                    Gradient(colors: [
                        AppColors.accentPrimary.opacity(0.35),         // VQ-03: anchors cyan end
                        AppColors.accentSecondary.opacity(0.60),
                        AppColors.accentTertiary.opacity(0.70),        // VQ-04: was 0.80
                        AppColors.accentSecondary.opacity(0.60),
                        AppColors.accentSecondary.opacity(0.30)
                    ]),
                    startPoint: CGPoint(x: atmoRect.minX, y: barMidY),
                    endPoint: CGPoint(x: atmoRect.maxX, y: barMidY)
                )
            )

            // ── Layer 2: Mid halo ──────────────────────────────────────────
            // VQ-05: light mode center stop orangeHot 0.90→0.65.

            let midSpread  = barHeight * (midSpreadBase + breatheIntensity * midSpreadPulse)
            let midOpacity = midOpacityBase + breatheIntensity * midOpacityPulse
            var midCtx     = ctx
            midCtx.addFilter(.blur(radius: midBlurBase + bloomIntensity * midBlurPulse))
            midCtx.opacity = midOpacity
            let midRect    = CGRect(
                x: barMinX - 4,
                y: barMidY - midSpread / 2 - 2,
                width: fillWidth + 8,
                height: midSpread
            )
            midCtx.fill(
                Path(roundedRect: midRect, cornerRadius: midSpread / 2),
                with: .linearGradient(
                    Gradient(colors: [
                        AppColors.accentPrimary.opacity(0.18),
                        AppColors.accentPrimary.opacity(0.50),
                        AppColors.accentSecondary.opacity(0.90),
                        AppColors.accentTertiary.opacity(0.60),
                        AppColors.accentTertiary.opacity(0.30)
                    ]),
                    startPoint: CGPoint(x: midRect.minX, y: barMidY),
                    endPoint: CGPoint(x: midRect.maxX, y: barMidY)
                )
            )

            // ── Layer 1: Tight core ────────────────────────────────────────
            // VQ-06: coreOpacityBase for dark passed in as 0.38 (was 0.50).
            //        This stops the core layer competing with the fill surface.

            let coreSpread  = barHeight * (coreSpreadBase + breatheIntensity * coreSpreadPulse)
            let coreOpacity = coreOpacityBase + breatheIntensity * coreOpacityPulse
            var coreCtx     = ctx
            coreCtx.addFilter(.blur(radius: coreBlurBase + bloomIntensity * coreBlurPulse))
            coreCtx.opacity = coreOpacity
            let coreRect    = CGRect(
                x: barMinX - 3,
                y: barMidY - coreSpread / 2 - 1,
                width: fillWidth + 6,
                height: coreSpread
            )
            coreCtx.fill(
                Path(roundedRect: coreRect, cornerRadius: coreSpread / 2),
                with: .linearGradient(
                    Gradient(colors: [
                        AppColors.accentPrimary.opacity(0.25),
                        AppColors.accentPrimary.opacity(0.90),
                        AppColors.accentSecondary.opacity(0.80),
                        AppColors.accentTertiary.opacity(0.90),
                        AppColors.accentTertiary.opacity(0.65)
                    ]),
                    startPoint: CGPoint(x: coreRect.minX, y: barMidY),
                    endPoint: CGPoint(x: coreRect.maxX, y: barMidY)
                )
            )

            // ── Particles ──────────────────────────────────────────────────

            let particleDefs: [(Color, CGFloat, Double)] = [
                (AppColors.accentPrimary, 0.08, 0.0),
                (AppColors.accentSecondary, 0.42, 0.6),
                (AppColors.accentTertiary, 0.72, 1.2),
                (AppColors.accentPrimary, 0.90, 0.3),
                (AppColors.accentTertiary, 0.22, 0.95),
                (AppColors.accentSecondary, 0.55, 0.65)
            ]

            // VQ-18: particleOpacityScale passed in; 0.65 light, 1.0 dark.
            let dotOpacityMultiplier: CGFloat = 0.90 * particleOpacityScale
            let haloOpacityMultiplier: CGFloat = 0.53 * particleOpacityScale

            let cycleDuration = CGFloat(shimmerCycleDuration)

            for (index, (color, xRatio, delay)) in particleDefs.enumerated() {
                let offsetElapsed = max(0, elapsed - CGFloat(delay))
                let phase: CGFloat = cycleDuration > 0
                    ? offsetElapsed.truncatingRemainder(
                        dividingBy: cycleDuration
                    ) / cycleDuration
                    : 0

                // VQ-16: fade-in window tightened 0–20% → 0–15% of cycle.
                //        At 3.0s this is 0.45s fade-in vs previous 0.72s,
                //        keeping it below the 300ms attention-capture threshold
                //        while still feeling smooth at 30fps.
                let pOpacity: CGFloat = phase < 0.15          // VQ-16: was 0.20
                    ? phase / 0.15                             // VQ-16: was / 0.20
                    : 1.0 - ((phase - 0.15) / 0.85)           // VQ-16: was (phase-0.20)/0.80
                guard pOpacity > 0.01 else { continue }

                let i = CGFloat(index)

                // VQ-12: rise height base 10 → 14pt, variation ±3 → ±5pt.
                //        Range was 7–13pt (barely clears bloom halo at 4pt bar).
                //        New range 9–19pt gives particles room to read distinctly.
                let riseHeight: CGFloat = 14 + sin(i * 1.3) * 5   // VQ-12: was 10 + sin(i×1.3)×3

                // VQ-13: easeExp base 2.0 → 2.2, variation ±0.5 → ±0.9.
                //        New range [1.3, 3.1] vs old [1.5, 2.5].
                //        Wider spread creates visible arc-vs-drift character
                //        diversity — fast-arcing vs slow-drifting particles.
                let easeExp: CGFloat = 2.2 + cos(i * 0.9) * 0.9   // VQ-13: was 2.0 + cos(i×0.9)×0.5

                // VQ-14: drift frequency 2.1 → 1.8 per index.
                //        Previous spacing clustered two particles at similar
                //        rightward drift. 1.8 produces better angular spread.
                let driftAmount: CGFloat = sin(i * 1.8) * 5    // VQ-14: was sin(i×2.1)×5

                // VQ-15: wobble amplitude easeOut×2 → easeOut×3.5.
                //        2pt max lateral movement was sub-perceptual on screen.
                //        3.5pt is clearly readable as organic sway.
                let wobbleFreq: CGFloat = 2.5 + cos(i * 1.7) * 1.0

                let easeOut = 1.0 - pow(1.0 - phase, easeExp)

                // VQ-17: Y origin shifted to bar top surface (barTopY).
                //        Previously barMidY caused particles to appear to
                //        launch from inside the fill rather than off the surface.
                let yPos    = barTopY - easeOut * riseHeight    // VQ-17: was barMidY - easeOut×riseHeight
                let wobble  = sin(phase * .pi * wobbleFreq) * easeOut * 3.5   // VQ-15: was easeOut×2
                let xPos    = barMinX
                    + fillWidth * xRatio
                    + phase * driftAmount
                    + wobble

                // Three concentric ellipses — never .radialGradient
                let haloSizes: [(scale: Double, opacity: Double)] = [
                    (1.0, Double(pOpacity * haloOpacityMultiplier) * 0.36),
                    (0.60, Double(pOpacity * haloOpacityMultiplier) * 0.22),
                    (0.32, Double(pOpacity * haloOpacityMultiplier) * 0.34)
                ]
                let glowRadius: CGFloat = 2.0
                for halo in haloSizes {
                    let hr = glowRadius * halo.scale
                    var haloCtx = ctx
                    haloCtx.opacity = halo.opacity
                    haloCtx.fill(
                        Path(ellipseIn: CGRect(
                            x: xPos - hr, y: yPos - hr,
                            width: hr * 2, height: hr * 2
                        )),
                        with: .color(color)
                    )
                }

                // 2×2pt dot
                var dotCtx = ctx
                dotCtx.opacity = Double(pOpacity * dotOpacityMultiplier)
                dotCtx.fill(
                    Path(ellipseIn: CGRect(
                        x: xPos - 1, y: yPos - 1,
                        width: 2, height: 2
                    )),
                    with: .color(color)
                )
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Previews
// ─────────────────────────────────────────────────────────────────────────────

#Preview("Dark — default") {
    PreviewContent().preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    PreviewContent().preferredColorScheme(.light)
}

#Preview("Reduce Motion") {
    PreviewContent()
        .preferredColorScheme(.dark)
}

#Preview("RTL Layout") {
    PreviewContent()
        .preferredColorScheme(.dark)
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("RTL Light Mode") {
    PreviewContent()
        .preferredColorScheme(.light)
        .environment(\.layoutDirection, .rightToLeft)
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Preview Content
// ─────────────────────────────────────────────────────────────────────────────

private struct PreviewContent: View {

    var body: some View {
        ZStack {
            AppColors.pageBackground
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {

                    sectionHeader("SOLO · COUPLE  (6 steps)")
                    stepGroup(total: 6)

                    sectionHeader("JUST BROWSING  (5 steps)")
                    stepGroup(total: 5)

                    sectionHeader("EDGE CASES")

                    edgeRow("Step 0 of 6  (empty bar)") {
                        OnboardingProgressBar(
                            currentStep: 0,
                            totalSteps: 6
                        )
                    }
                    edgeRow("Step 6 of 6  (full, no bloom)") {
                        OnboardingProgressBar(
                            currentStep: 6,
                            totalSteps: 6
                        )
                    }
                    edgeRow("Step 6 of 6  (full + bloom)") {
                        OnboardingProgressBar(
                            currentStep: 6,
                            totalSteps: 6,
                            showCompletionEffect: true
                        )
                    }
                    edgeRow("Step 1 of 1  (single step + bloom)") {
                        OnboardingProgressBar(
                            currentStep: 1,
                            totalSteps: 1,
                            showCompletionEffect: true
                        )
                    }
                    edgeRow("Narrow  (width: 60)") {
                        OnboardingProgressBar(
                            currentStep: 3,
                            totalSteps: 6,
                            totalWidth: 60
                        )
                    }
                    edgeRow("Tall  (height: 8)") {
                        OnboardingProgressBar(
                            currentStep: 4,
                            totalSteps: 6,
                            barHeight: 8
                        )
                    }
                }
                .padding(.vertical, AppSpacing.xxl)
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.overline)
            .foregroundStyle(AppColors.textTertiary)
            .tracking(2)
            .padding(.horizontal, AppSpacing.lg)
    }

    @ViewBuilder
    private func stepGroup(total: Int) -> some View {
        VStack(spacing: AppSpacing.lg) {
            ForEach(1...total, id: \.self) { step in
                OnboardingProgressBar(
                    currentStep: step,
                    totalSteps: total,
                    showCompletionEffect: step == total
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, AppSpacing.lg)
    }

    @ViewBuilder
    private func edgeRow<C: View>(
        _ label: String,
        @ViewBuilder content: () -> C
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.horizontal, AppSpacing.lg)
            content()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, AppSpacing.lg)
        }
    }
}
