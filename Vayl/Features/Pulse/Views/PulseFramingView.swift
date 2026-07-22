// Features/Pulse/Views/PulseFramingView.swift
//
// "Your First Pulse" — the one-time doorway shown ahead of a person's first check-in,
// from Home or from Map. Reference: docs/mockups/pulse-framing-entrance.html.
//
// WHY THIS EXISTS, and why it is only a doorway:
// Pulse is novel enough that "what am I answering, and what is it for" needs an answer —
// but front-loaded instruction does not stick. So this screen carries only what cannot be
// learned by doing (what Pulse is FOR, that it is not a test, what happens if you share it),
// and the check-in itself teaches the rest by being done. It is shown once and retires.
// The permanent home for "what is this" is the ⓘ → PulseInfoSheet, not a second copy here.
//
// THE ENTRANCE IS THE IDEA, not decoration: the aura the user tapped stays exactly where it
// is while the screen around it dissolves away, then drifts up and grows into its hero slot.
// Everything falls quiet and leaves your capacity sitting there. That continuity is why the
// orb is handed in from the caller as a source frame rather than being a new orb that appears.
//
// This view is PRESENTATION ONLY — it owns no gate and no persistence. PulseCheckInFlow
// decides whether it is shown at all and what "Begin" leads to.

import SwiftUI

struct PulseFramingView: View {

    /// Where the tapped aura sits on screen right now, in global coordinates. The orb starts
    /// life here so it is visually the SAME object the user touched. nil = the caller could not
    /// report one (an unusual layout, a preview): the orb simply fades up in its hero slot and
    /// the rest of the sequence is unchanged. Graceful, never broken.
    var sourceOrbFrame: CGRect?

    var onBegin: () -> Void
    var onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Choreography state
    //
    // One flag per beat rather than a phase enum: the beats overlap on purpose (a bullet's
    // 0.85s bloom outlasts the 0.60s gap to the next), which a single "current phase" cannot
    // express. Each flag is one-way — nothing here ever animates back out.

    @State private var dissolved   = false   // the originating screen has gone; void is ours
    @State private var orbLanded   = false   // aura has drifted + grown into the hero slot
    @State private var titleIn     = false
    @State private var ledeIn      = false
    @State private var beatsIn     = [false, false, false]
    @State private var ctaIn       = false

    /// The three doorway beats. Order is load-bearing: reassurance first (this is not a test),
    /// then what it unlocks with someone else, then permission to be irregular about it.
    private let beats: [(label: String, detail: String)] = [
        ("There is no “correct” capacity",
         "It’s about showing up most authentically."),
        ("Share your Pulse",
         "Help your partners better understand what space you’re in."),
        ("Check in when it feels good",
         "Every day, once a week — whatever makes sense for you.")
    ]

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let layout = AppLayout.from(geo)
            // The hero orb sizes off the screen, never a constant (Void Rule, clause 2).
            let heroSize = Self.heroOrbSize(screenWidth: layout.screenWidth)

            ZStack(alignment: .top) {
                // Faded IN rather than drawn opaque: the cover is presented over the still
                // visible originating screen (transparentBackground), so this is the dissolve.
                AppColors.void
                    .opacity(backdropOpacity)
                    .ignoresSafeArea()
                OnboardingAtmosphere(config: .stat, maskStart: Self.atmosphereMaskStart)
                    .opacity(backdropOpacity)
                    .ignoresSafeArea()

                content(layout: layout, heroSize: heroSize)

                travellingAura(geo: geo, heroSize: heroSize)
            }
            .onAppear { runEntrance() }
        }
    }

    // MARK: - Copy column

    private func content(layout: AppLayout, heroSize: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Reserves the aura's landing zone so no copy reflows when it arrives. The orb
            // itself is drawn in the overlay above, in screen space, because it starts its
            // life at a frame belonging to a completely different screen.
            Color.clear
                .frame(height: heroSize)
                .padding(.top, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xl)

            Text("Your First Pulse")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .cascadeIn(titleIn)

            Text("Pulse is your capacity map. Showing up in non-monogamy starts with knowing what you have the capacity for — this is how you gauge that.")
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, AppSpacing.sm)
                .cascadeIn(ledeIn)

            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                ForEach(Array(beats.enumerated()), id: \.offset) { index, beat in
                    SpectrumBulletRow(
                        text: beat.label,
                        detail: beat.detail,
                        phaseOffset: Double(index) * Self.bulletSweepStagger,
                        // Sized up via the component's own `font:` hook (the paywall does the
                        // same at 16): a doorway's beats are primary content, and at the
                        // default 15 they read as captions next to their own detail line.
                        font: AppFonts.body(17, weight: .medium, relativeTo: .body)
                    )
                    .cascadeIn(beatsIn[index])
                }
            }
            .padding(.top, AppSpacing.xl)

            Spacer(minLength: AppSpacing.xl)

            ctaBlock
                .cascadeIn(ctaIn, rises: false)
        }
        .padding(.horizontal, AppSpacing.lg)
        .topClearance(layout)
        .bottomClearance(layout)
    }

    // MARK: - CTAs

    private var ctaBlock: some View {
        VStack(spacing: AppSpacing.sm) {
            VaylButton(label: "Begin") { onBegin() }

            // A real off-ramp, deliberately quiet — a secondary VaylButton would make it a
            // second CTA and turn a doorway into a decision. Declining now is respected.
            // vaylPressableTap carries the whole tap contract (press scale + light haptic
            // on touch-down + action on release), so no hand-rolled press state here.
            Text("Maybe later")
                .font(AppFonts.buttonLabel)
                .foregroundStyle(AppColors.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md2)
                .vaylPressableTap { onDismiss() }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("Maybe later")
        }
    }

    // MARK: - The travelling aura

    /// Drawn in screen space, above the copy: it begins at the caller's orb frame (a rect from
    /// a different screen) and ends in the hero slot. Laying it out in the column instead would
    /// mean it could only ever start where the column put it — i.e. not where the user tapped.
    @ViewBuilder
    private func travellingAura(geo: GeometryProxy, heroSize: CGFloat) -> some View {
        let size   = orbLanded ? heroSize : (sourceOrbFrame?.width ?? heroSize)
        let centre = orbCentre(geo: geo, heroSize: heroSize)

        PulseCyclingAura(size: size)
            .position(x: centre.x, y: centre.y)
            // Position and scale on the ONE curve — an object approaching, not a move plus a
            // resize. `size` feeds a frame, so this animates layout, not a scaleEffect: the
            // aura's internal geometry is size-relative and must resolve at the real size.
            .animation(reduceMotion ? nil : AppAnimation.pulseFramingDrift, value: orbLanded)
            // Only when arriving from somewhere: the source orb is still on screen underneath
            // for the length of the dissolve, so the two cross-fade in place and a point or
            // two of misalignment is invisible. With no source frame there is nothing to
            // match and the orb simply belongs to this screen from the start.
            .opacity(sourceOrbFrame == nil ? 1 : (dissolved ? 1 : 0))
            .animation(reduceMotion ? nil : AppAnimation.pulseFramingDissolve, value: dissolved)
            .allowsHitTesting(false)
    }

    /// Screen-space centre for the aura: the caller's frame before the drift, the hero slot
    /// after. Converted out of global coordinates into this view's space.
    private func orbCentre(geo: GeometryProxy, heroSize: CGFloat) -> CGPoint {
        let heroCentre = CGPoint(
            x: geo.size.width / 2,
            y: geo.safeAreaInsets.top + AppSpacing.xl + heroSize / 2
        )
        guard !orbLanded, let source = sourceOrbFrame else { return heroCentre }

        let origin = geo.frame(in: .global).origin
        return CGPoint(x: source.midX - origin.x, y: source.midY - origin.y)
    }

    // MARK: - Entrance

    private var backdropOpacity: Double {
        // With no dissolve to run (Reduce Motion, or nothing beneath to dissolve away from)
        // the screen is simply itself from frame one.
        (dissolved || reduceMotion || sourceOrbFrame == nil) ? 1 : 0
    }

    /// Schedules the sequence. Absolute offsets from the tap, never derived from one another,
    /// so a change to one beat cannot silently shift the rest.
    private func runEntrance() {
        guard !reduceMotion else {
            // Reduce Motion: no dissolve, no drift, no cascade. The doorway is simply here,
            // fully composed, with the orb already home.
            dissolved = true; orbLanded = true
            titleIn = true; ledeIn = true; ctaIn = true
            beatsIn = [true, true, true]
            return
        }

        withAnimation(AppAnimation.pulseFramingDissolve) { dissolved = true }

        schedule(AppAnimation.pulseFramingDriftDelay, AppAnimation.pulseFramingDrift) { orbLanded = true }
        schedule(AppAnimation.pulseFramingTitleDelay, AppAnimation.pulseFramingCopy) { titleIn = true }
        schedule(AppAnimation.pulseFramingLedeDelay,  AppAnimation.pulseFramingCopy) { ledeIn = true }
        schedule(AppAnimation.pulseFramingBeat1Delay, AppAnimation.pulseFramingBeat) { beatsIn[0] = true }
        schedule(AppAnimation.pulseFramingBeat2Delay, AppAnimation.pulseFramingBeat) { beatsIn[1] = true }
        schedule(AppAnimation.pulseFramingBeat3Delay, AppAnimation.pulseFramingBeat) { beatsIn[2] = true }
        schedule(AppAnimation.pulseFramingCTADelay,   AppAnimation.pulseFramingCTA)  { ctaIn = true }
    }

    private func schedule(_ delay: Double, _ animation: Animation, _ step: @escaping () -> Void) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            withAnimation(animation) { step() }
        }
    }

    // MARK: - Geometry

    /// Hero aura diameter as a fraction of screen width — derived, never a constant, so it
    /// breathes across devices (Void Rule, clause 2). ~134pt on a 393pt screen.
    /// 🎚️ FEEL: tune the fraction on device, never by typing a literal size.
    static func heroOrbSize(screenWidth: CGFloat) -> CGFloat { screenWidth * 0.34 }

    /// Matches PulseCheckInView's own earlier trail-in, so the doorway and the check-in it
    /// opens sit on the same atmosphere rather than stepping between two backgrounds.
    private static let atmosphereMaskStart: CGFloat = 0.30

    /// Per-row delay on the bullets' specular sweep, so the light cascades down the list.
    /// Matches SpectrumBulletRow's own documented stagger.
    private static let bulletSweepStagger: Double = 0.22
}

// MARK: - Cascade

private extension View {
    /// The doorway's one entrance gesture: fade up, optionally rising a few points.
    ///
    /// `rises: false` is the CTA pair — the copy above travels because it is being read
    /// downward, the doors simply become available. Different motion, different kind of thing.
    @ViewBuilder
    func cascadeIn(_ shown: Bool, rises: Bool = true) -> some View {
        self
            .opacity(shown ? 1 : 0)
            .offset(y: shown || !rises ? 0 : AppSpacing.sm2)
    }
}

// MARK: - Preview

#Preview("Framing — full sequence") {
    PulseFramingView(sourceOrbFrame: nil, onBegin: {}, onDismiss: {})
        .background(AppColors.void)
        .preferredColorScheme(.dark)
}
