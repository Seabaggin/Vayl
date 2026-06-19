//
//  AppAnimation.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//

// App/Theme/AppAnimation.swift

import SwiftUI
import UIKit

/// Tier 2 — Semantic animation tokens.
/// Every animation in the codebase must reference one of these tokens.
/// Ad hoc values like .easeOut(duration: 0.3) anywhere outside this file are a violation.
///
/// Two animation classes exist and must never be confused:
///   Reactive  — responds directly to a user action (tap, swipe, drag release).
///               Always takes priority. Never cancel or defer a reactive animation.
///   Ambient   — runs continuously without user input (pulse, glow, orbit).
///               Always yields to reactive animations. Never block user feedback.
///
/// Reduce Motion rules:
///   Every token has a documented reduce-motion fallback.
///   Reactive animations: replace movement with an instant opacity cross-fade.
///   Ambient animations: disable entirely — remove the animation, not just slow it down.
///   Never use .default or .linear as a reduce-motion fallback — they still move.
///   The correct fallback for movement is no movement. Opacity change is permitted.
internal enum AppAnimation {

    // MARK: — Reactive Animations
    // These respond to user actions. They must feel immediate and confirm input.
    // Reduce motion fallback for all reactive tokens: .easeOut(duration: 0.15)
    // This preserves the state change confirmation while eliminating spatial movement.

    /// 0.15s ease-out — Immediate micro-responses to user input.
    /// Use for button press states, toggle flips, selection highlights, and icon state changes.
    /// The speed communicates that the app registered the tap instantly.
    /// Reduce motion: use as-is — at 0.15s this is already at the threshold of perception.
    static let fast: Animation = .easeOut(duration: 0.15)

    /// 0.3s ease-out — Standard state transitions driven by user action.
    /// Use for screen element rearrangement after a selection, card state changes,
    /// and any layout shift that results directly from a tap or swipe.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — confirm the change, skip the travel.
    static let standard: Animation = .easeOut(duration: 0.3)

    /// 0.5s ease-out — Deliberate, weighty transitions for significant state changes.
    /// Use for onboarding step transitions, modal presentations driven by user action,
    /// and reveal animations where the user has explicitly requested new content.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — the reveal happens, the travel does not.
    static let slow: Animation = .easeOut(duration: 0.5)

    // MARK: — Cinematic Duration
    // Not an Animation value — a raw duration for use with .easeOut(duration: AppAnimation.cinematic).
    // Reserved for screen-level content reveals requiring ceremony beyond slow (0.5s).
    // Ambient animations must be disabled entirely when reduce motion is active.

    /// 1.2s — Cinematic reveal duration.
    /// Use for name reveals, tagline entrances, and LivingText fade-in arrivals that
    /// require ceremony beyond slow (0.5s). Not an Animation instance — pass as a
    /// duration parameter: .easeOut(duration: AppAnimation.cinematic).
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    /// Do not use for UI response animations — those use slow or enter.
    static let cinematic: Double = 1.2

    /// Cinematic ease-out — TableSurfaceView fade in/out.
    /// Use this instead of constructing .easeOut(duration: AppAnimation.cinematic) inline.
    static let cinematicFade: Animation = .easeOut(duration: AppAnimation.cinematic)

    // MARK: — StatPhase Arrival Ignition
    // The "1 in 5" hero fires a one-time light-catch as it seats: a bright specular
    // sweep crosses the numeral, the glow blooms past its resting level then settles,
    // and a soft haptic lands. Tuned in docs/prototypes/statphase-arrival.html.
    // Reduce motion: skip the sweep + bloom entirely (visual only); the soft land
    // haptic still fires (haptics are not motion).

    /// 0.76s — Delay from the stat's cascade entrance to the ignition firing, so the
    /// light catches the numeral as it *seats* rather than on first appearance.
    static let statIgnitionDelay: Double = 0.76

    /// 0.68s ease-out — The one bright specular sweep travelling across the numeral on land.
    static let statIgnitionSweep: Animation = .easeOut(duration: 0.68)

    /// 0.14s ease-out — Glow blooming up to its ignition peak as the numeral seats.
    static let statGlowBloomIn: Animation = .easeOut(duration: 0.14)

    /// 0.16s — Hold at the bloom peak before it settles back to the resting glow.
    /// Must exceed statGlowBloomIn (0.14s) or the settle retargets the bloom mid-flight.
    static let statGlowBloomHold: Double = 0.16

    /// 0.46s settle — Glow easing back down from the ignition peak to its resting level.
    /// timingCurve (0.22, 1, 0.36, 1): snappy ease-out, no overshoot.
    static let statGlowBloomSettle: Animation = .timingCurve(0.22, 1, 0.36, 1, duration: 0.46)

    /// 0.35s material expand — Citation panel expand and collapse.
    /// timingCurve (0.4, 0, 0.2, 1): standard deceleration curve — element
    /// enters fast and eases into its resting position. Used for the expandable
    /// citation card in StatPhase. Not a general-purpose animation token — do
    /// not use outside StatPhase without deliberate intent.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let materialExpand: Animation = .timingCurve(0.4, 0, 0.2, 1, duration: 0.35)

    /// Spring — Physical, elastic responses to direct manipulation.
    /// Use for card lifts, pill selections, drag release snapping, and any interaction
    /// where the element should feel like it has mass and momentum.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — confirm without the bounce.
    static let spring: Animation = .spring(response: 0.5, dampingFraction: 0.85)

    // MARK: — Directional Transition Animations
    // Use for elements entering or leaving the screen as a result of navigation.
    // Reduce motion fallback: replace directional movement with opacity only.

    /// 0.4s ease-out — Elements entering the screen or becoming visible.
    /// Use for views sliding or fading into position after navigation, and for
    /// content appearing after an async load completes.
    /// Reduce motion: replace movement with .opacity animation at 0.2s duration.
    static let enter: Animation = .easeOut(duration: 0.4)

    /// 0.2s ease-in — Elements leaving the screen or becoming hidden.
    /// Use for views dismissing after navigation away, and for
    /// content disappearing before a state replacement.
    /// Ease-in for exit makes the departure feel intentional, not interrupted.
    /// Reduce motion: replace movement with .opacity animation at 0.15s duration.
    static let exit: Animation = .easeIn(duration: 0.2)

    // MARK: — Ambient Animation Durations
    // These are not Animation values — they are raw durations for use with
    // TimelineView, withAnimation loops, or RepeatForever animations.
    // Ambient animations must be disabled entirely when reduce motion is active.
    // Never use these durations inside a withAnimation block that responds to user input.

    /// 2.0s — Slow, continuous ambient pulse.
    /// Use for background glow breathe cycles, aura scale oscillation,
    /// and any effect that communicates the app is alive and listening.
    /// Reduce motion: remove the animation entirely. The static state must be visually complete.
    static let ambientPulse: Double = 2.0

    /// 4.0s — Very slow ambient drift.
    /// Use for aurora blob position shifts, background gradient rotation,
    /// and effects that should feel geological — barely perceptible movement.
    /// Reduce motion: remove the animation entirely. The static state must be visually complete.
    static let ambientDrift: Double = 4.0

    /// 1.2s — Medium ambient shimmer cycle.
    /// Use for specular highlight sweeps across card surfaces, shimmer loading states,
    /// and light-catch effects on premium surfaces.
    /// Reduce motion: remove the animation entirely — shimmer is purely decorative.
    static let ambientShimmer: Double = 1.2

    /// 2.2s — Duration of one direction of a candle's breath (in OR out). Build the
    /// animation at the call site with `.easeInOut(duration: AppAnimation.candleBreathDuration)`
    /// and sleep the same span between toggles so each inhale/exhale fully completes.
    /// The candle breathes in, then out, then RESTS (see candleBreathHold) rather than
    /// oscillating continuously — keeps the hand calm with occasional, subtle motion.
    /// Pair the amplitude small (~1.5–2%) so the breath reads as life, not a pulse.
    /// Reduce motion: no breathing; the candle holds its static frame.
    static let candleBreathDuration: Double = 2.2

    /// 3.0s — Intermittent rest between candle breaths. After a full in/out breath the
    /// candle holds still for this long before the next, so the motion is occasional.
    static let candleBreathHold: Double = 3.0

    // MARK: — Border Effect
        // Used by VaylBorderEffect. Applied to the spectrum stroke fill and glow pop
        // on VaylButton, SelectablePill, sheets, and any bordered surface.
        //
        // Spring timing note:
        // borderFill uses a spring, not a cubic-bezier. Spring animations do not
        // have a fixed wall-clock duration — response: 0.36 is the spring's natural
        // period, not its settle time. The actual visual settle is longer (~0.52s
        // at dampingFraction: 0.9). borderFillDuration accounts for this by using
        // the observed settle time rather than the spring response value.
        // If borderFill's spring parameters change, re-measure and update
        // borderFillDuration to match the new observed settle time.
        //
        // Reduce motion fallback: borderFill → instant state change, no animation.
        // Hairline tokens are opacity-only — safe under reduce motion as-is.

        /// Observed settle duration of borderFill — used in onPressUp() to calculate
        /// how long to wait before firing the glow so it lands exactly when the arcs meet.
        /// This is NOT the spring response value. It is the wall-clock time at which
        /// the spring animation is perceptually complete (within 1pt of target).
        /// Re-measure if borderFill spring parameters change.
        static let borderFillDuration: Double = 0.30

        /// Spring — Spectrum border filling around a pill on press.
        /// Two arcs sweep from top-center down to meet at bottom-center simultaneously.
        /// response: 0.36, dampingFraction: 0.9 — snappy initial velocity, no visible
        /// bounce. The circuit-completing feel comes from the arcs arriving with
        /// confidence rather than coasting in.
        /// Reduce motion: skip animation entirely — border jumps to filled state.
        static let borderFill: Animation = .spring(response: 0.36, dampingFraction: 0.9)

        /// 0.12s ease-out — Glow bursting on the moment arcs meet at bottom-center.
        /// Short and fast — this should feel like a flash of energy completing the
        /// circuit, not a bloom or fade-in. The intensity peak is immediate.
        /// Reduce motion: skip — no glow fires under reduce motion.
        static let borderGlowIn: Animation = .easeOut(duration: 0.12)

        /// 0.28s ease-in — Glow dissipating after the hold period.
        /// Ease-in communicates energy draining — the glow accelerates away from
        /// the peak rather than fading linearly. Faster than the previous 0.38s
        /// so the button feels resolved rather than lingering.
        /// Reduce motion: skip — no glow fires under reduce motion.
        static let borderGlowOut: Animation = .easeIn(duration: 0.28)

        /// How long the glow holds at full intensity before borderGlowOut begins.
        /// Not an Animation — a raw TimeInterval consumed by Task.sleep in VaylButton.
        /// 0.12s is short enough to clear before a rapid second tap, long enough
        /// to register as a deliberate energy burst rather than a flicker.
        /// Reduce motion: unused — glow sequence is skipped entirely.
        static let borderGlowHoldDuration: TimeInterval = 0.12

        /// 0.12s ease-in — Hairline retracting as border fill begins.
        /// Fast ease-in so the hairline clears before the arc strokes are visible.
        /// No visual overlap between hairline and arcs at any point in the transition.
        /// Reduce motion: use as-is — opacity only, no spatial movement.
        static let hairlineRetract: Animation = .easeIn(duration: 0.12)

        /// 0.35s ease-out — Hairline returning after border resets on cancel.
        /// Slower than retract — eases back in gently rather than snapping.
        /// Reduce motion: use as-is — opacity only, no spatial movement.
        static let hairlineReturn: Animation = .easeOut(duration: 0.35)

        /// 0.16s ease-in — Border retreating after a cancelled press.
        /// Ease-in signals a decisive abort — the border accelerates away from
        /// the pressed state rather than drifting back.
        /// Reduce motion: instant borderProgress = 0, no animation.
        static let borderRetract: Animation = .easeIn(duration: 0.16)
    // MARK: — Splash Screen
    // These tokens are exclusive to VaylSplashScreen.
    // They must never appear in any other screen — the cold launch ceremony
    // does not repeat as a UI pattern anywhere in the main app.
    //
    // Sequence timing (absolute offsets from cold launch):
    //   0.000s  void       — black screen, destination renders silently underneath
    //   0.250s  slit       — spectrum line aperture opens at constant velocity
    //   0.280s  bloom creep — line bloom builds from 0.35 → 0.58 over 300ms
    //   0.600s  ignition   — wordmark reveal begins, bloom spikes to 1.0
    //   0.640s  pulse      — linePulse fires 40ms after ignition (reveal leads)
    //   0.900s  hold       — bloom settles to 0.65, ambient oscillation begins
    //   1.660s  anticipate — zoom container micro-squeezes to 0.97× (40ms)
    //   1.700s  zoom       — camera crashes into line at 3.5×
    //   1.950s  tear       — panels snap apart, destination revealed
    //   2.200s  home fade  — destination opacity confirms (no animation — instant)
    //   2.400s  dismiss    — splash container removed from hierarchy
    //
    // Reduce motion fallback for all splash tokens:
    //   Skip the sequence entirely. Crossfade from void to destination at
    //   AppAnimation.standard duration. The destination must be visually
    //   complete at rest — no motion required to read it.

    /// 0.08s linear — Spectrum line aperture opening.
    /// Constant velocity communicates mechanical precision — an iris or shutter
    /// opening, not a fade. Linear is intentional and correct here.
    /// Reduce motion: skip — line appears instantly at full opacity.
    static let splashLineAppear: Animation = .linear(duration: 0.08)

    /// 0.58s easeOutExpo approximation — Wordmark reveal from light source.
    /// timingCurve (0.16, 1.0, 0.3, 1.0): high initial velocity decelerating
    /// sharply — communicates the letterforms arriving with mass from the energy
    /// of the line. Do NOT substitute .easeOut — it will feel lighter and faster.
    /// Reduce motion: skip — wordmark appears at full reveal instantly.
    static let splashReveal: Animation = .timingCurve(0.16, 1.0, 0.3, 1.0, duration: 0.58)

    /// 0.18s overshoot — Bloom energy spike at ignition.
    /// timingCurve (0.0, 0.8, 0.2, 1.2): y2 of 1.2 produces a genuine mathematical
    /// overshoot beyond the target bloom value before settling. This makes the
    /// ignition feel like a physical energy punch, not a fade-up.
    /// Reduce motion: skip — bloom appears at hold level instantly.
    static let splashBloomIgnite: Animation = .timingCurve(0.0, 0.8, 0.2, 1.2, duration: 0.18)

    /// 0.35s settle — Bloom returning to hold level after ignition overshoot.
    /// timingCurve (0.22, 1.0, 0.36, 1.0): snappy ease-out, no overshoot.
    /// Fired after splashBloomIgnite completes — bloom coasts down to resting glow.
    /// Reduce motion: not reached — reduce motion skips the ignition entirely.
    static let splashBloomSettle: Animation = .timingCurve(0.22, 1.0, 0.36, 1.0, duration: 0.35)

    /// 0.04s ease — Zoom container micro-squeeze anticipation.
    /// timingCurve (0.4, 0.0, 0.6, 1.0): scales the container to 0.97× in 40ms
    /// immediately before the zoom fires. The brief compression makes the zoom
    /// feel launched rather than switched on — physical cause before effect.
    /// Reduce motion: skip — zoom is suppressed entirely under reduce motion.
    static let splashZoomAnticipate: Animation = .timingCurve(0.4, 0.0, 0.6, 1.0, duration: 0.04)

    /// 0.38s crash — Camera zoom into the spectrum line.
    /// timingCurve (0.12, 0.9, 0.2, 1.0): acceleration-dominant curve that
    /// commits to the zoom early and arrives with confidence. The transform origin
    /// is locked to LINE_Y — the line stays fixed while everything else expands.
    /// Reduce motion: skip — zoom does not fire, sequence jumps straight to tear.
    static let splashZoom: Animation = .timingCurve(0.12, 0.9, 0.2, 1.0, duration: 0.38)

    /// 0.28s snap — Panels separating on tear.
    /// timingCurve (0.2, 0.9, 0.2, 1.0): near-instant initial velocity communicates
    /// a physical snap rather than a slide. The 20ms ramp at the start (x1=0.2)
    /// provides a one-frame buffer against dropped first frames on older hardware.
    /// Pairs with a keyframe overshoot: panels travel to H*0.74 then settle at H*0.70.
    /// Reduce motion: replace with .easeOut(duration: 0.15) on opacity only —
    /// panels do not move, destination crossfades in.
    static let splashTear: Animation = .timingCurve(0.2, 0.9, 0.2, 1.0, duration: 0.28)

    /// Tear overshoot distance as a ratio of panel travel distance.
    /// Panels snap to (tearDistance * splashTearOvershoot) then settle back to tearDistance.
    /// 1.056 = ~5.6% overshoot — enough to read as physical momentum, not noticeable as error.
    /// Used by the KeyframeAnimator driving panel translation. Not an Animation value.
    static let splashTearOvershoot: CGFloat = 1.056

    // MARK: — OB Card Physics
    // These tokens are exclusive to the Onboarding canvas. They must never appear
    // in main-app screens — the table metaphor does not leave the OB boundary.
    // Reduce motion fallback for all card physics tokens: .easeOut(duration: 0.15)
    // on opacity only. Card travel stops. State changes are still confirmed.

    /// 0.85s custom ease — Card travelling from deal point to table position.
    /// Cubic bezier (0, 0, 0.2, 1): accelerates instantly off the deal point,
    /// decelerates sharply into the landing position. Communicates weight and arrival.
    /// Reduce motion: replace with .easeOut(duration: 0.15) on opacity — card appears in place.
    static let cardSlide: Animation = .timingCurve(0, 0, 0.2, 1, duration: 0.85)

    /// Spring — Card settling after it lands on the table.
    /// High damping (0.92) gives a single, confident settle with no secondary bounce.
    /// Fired immediately after cardSlide completes at the destination.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — skip the physical settle.
    static let cardSettle: Animation = .spring(response: 0.55, dampingFraction: 0.92)

    /// Spring — Card sliding from table scatter position to center-screen.
    /// response: 0.72, dampingFraction: 1.0 — critically damped, zero wobble per spec.
    /// Communicates the card arriving with impossible smoothness — no physical bounce.
    /// Fired after the landing breath pause in NamePhase.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — centers without travel.
    // critically damped — zero wobble per spec. was response:0.6, dampingFraction:0.75
    static let cardCenter: Animation = .spring(response: 0.72, dampingFraction: 1.0)

    /// 0.52s custom ease — Card pocketing to the corner deck.
    /// Cubic bezier (0.4, 0, 1, 1): eases into motion then accelerates off-screen.
    /// The asymmetric exit communicates the card is being filed away, not dismissed.
    /// Reduce motion: replace with .easeOut(duration: 0.15) on opacity — card disappears in place.
    static let cardPocket: Animation = .timingCurve(0.4, 0, 1, 1, duration: 0.52)

    /// 0.36s custom ease — Curiosity sort card flung off-screen on a keep/pass commit.
    /// Cubic bezier (0.4, 0, 0.5, 1): eases off the release point then accelerates
    /// away — the card is thrown clear of the pile, not filed. Value is the locked
    /// feel reference (docs/prototypes/curiosity-swipe-prototype.html, --throw-ms).
    /// Reduce motion: replace with .easeOut(duration: 0.15) — card exits without travel.
    static let curiosityThrow: Animation = .timingCurve(0.4, 0, 0.5, 1, duration: 0.36)

    /// 0.22s custom ease — Next curiosity card rising into the top slot after a commit.
    /// Cubic bezier (0.2, 0.8, 0.2, 1): high initial velocity decelerating into place —
    /// the card snaps up crisply rather than settling with spring overshoot. Matches the
    /// locked feel reference (docs/prototypes/curiosity-swipe-prototype.html, commit()).
    /// Reduce motion: replace with .easeOut(duration: 0.15) — card appears in place.
    static let curiosityRise: Animation = .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.22)

    /// 0.58s custom ease — Card flipping face-up or face-down.
    /// Cubic bezier (0.4, 0, 0.6, 1): symmetric ease creates the sense of rotation
    /// through space. Applied to scaleX: 1 → 0 (first half) then -1 → 0 (second half).
    /// The renderer swaps VaylCardBack ↔ VaylCardFace at the scaleX = 0 moment.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — card face changes without rotating.
    static let cardFlip: Animation = .timingCurve(0.4, 0, 0.6, 1, duration: 0.58)

    /// 0.95s custom ease — Card lifting off the table toward the user.
    /// Cubic bezier (0.4, 0, 0.2, 1): gradual initial lift that carries through to the
    /// extended hold position. Elevation value drives shadow deepening simultaneously.
    /// Used for raise-and-confirm mechanic and full-bleed card expansion.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — card confirms raised state instantly.
    static let cardLift: Animation = .timingCurve(0.4, 0, 0.2, 1, duration: 0.95)

    /// Spring — Fan of cards spreading from a deck.
    /// Lower damping (0.88) than cardSettle allows a soft overshoot as cards fan apart,
    /// reinforcing the sense of physical playing cards spreading under slight tension.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — fan state appears without travel.
    static let deckFan: Animation = .spring(response: 0.70, dampingFraction: 0.88)

    /// 0.72s ease — Deck weave shuffle (interleaving two halves).
    /// Standard ease (0.25, 0.46, 0.45, 0.94) used here because the weave is a
    /// composed sequence — each card's motion looks hand-applied, not mechanical.
    /// Applied per-card with staggered delays, not to the deck as a whole.
    /// Reduce motion: skip the shuffle sequence entirely — deck goes directly to squared state.
    static let deckWeave: Animation = .timingCurve(0.25, 0.46, 0.45, 0.94, duration: 0.72)

    /// 0.65s ease-in — Foil surface dissolving after sufficient tears.
    /// Ease-in curve communicates the foil burning outward from tear edges —
    /// starts slow at the breach, accelerates as integrity collapses.
    /// Reduce motion: replace with .easeOut(duration: 0.15) on opacity — foil disappears instantly.
    static let foilDissolve: Animation = .easeIn(duration: 0.65)

    /// 0.70s custom ease — Table surface receding during hand-raise and full-bleed phases.
    /// Cubic bezier (0.4, 0, 0.6, 1): symmetric ease so the table feels like it is
    /// physically pulling back rather than fading. Applied to tableFade in VaylDirector.
    /// Reduce motion: replace with .easeOut(duration: 0.15) on opacity — table dims instantly.
    static let tableRecede: Animation = .timingCurve(0.4, 0, 0.6, 1, duration: 0.70)

    /// Spring — Corner deck receiving a newly pocketed card.
    /// Fast response (0.40) makes the receive feel reactive to the arriving card.
    /// The glow pulse uses this same token and fades after 600ms.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — card count increments without bounce.
    static let deckReceive: Animation = .spring(response: 0.40, dampingFraction: 0.85)

    /// 0.50s ease-out — Dealer line projecting onto the felt surface.
    /// Matched to the scaleY (0.94 → 1.0) and opacity entrance of ProjectedTextView.
    /// Text must be fully legible before the phase interaction begins — do not rush this token.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — text appears without scaling.
    static let textProject: Animation = .easeOut(duration: 0.50)

    /// 3.2s ease-in-out repeating — Subtle card surface breathe on the table.
    /// Applied to the elevation/glow of a stationary card while it awaits user input.
    /// Communicates that the card is alive and waiting, not frozen.
    /// This is an ambient animation — remove entirely under reduce motion.
    /// Use .ambientAnimation(AppAnimation.cardBreathe, value:) at every call site.
    static let cardBreathe: Animation = .easeInOut(duration: 3.2).repeatForever(autoreverses: true)

    /// 0.29s per half — One half of a card flip (scaleX 1→0 or 0→-1).
    /// Two halves compose the full 0.58s cardFlip total.
    /// Reduce motion: skip flip entirely — face swaps without rotation.
    static let cardFlipHalf: Animation = .timingCurve(0.4, 0, 0.6, 1, duration: 0.29)

    /// 0.60s custom ease — Table rim burst decaying after card lands.
    /// Cubic bezier (0.2, 0.8, 0.4, 1.0). was 0.50s — corrected to spec.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let rimBurstDecay: Animation = .timingCurve(0.2, 0.8, 0.4, 1.0, duration: 0.60)

    /// 0.55s ease-in — Blur ramping in as card lifts toward the camera.
    /// Also used for tableFade during the same lift sequence.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let liftBlurRamp: Animation = .easeIn(duration: 0.55)

    /// 0.40s ease-in — Card screen alpha fading out at peak of lift sequence.
    /// Ease-in communicates the card accelerating away from the user's plane.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let liftCardFade: Animation = .easeIn(duration: 0.40)

    /// 0.55s ease-in — Table surface fading during the lift sequence.
    static let tableFadeOut: Animation = .easeIn(duration: 0.55)

    /// 0.45s ease-out — Card surface properties restoring after name is submitted.
    /// Scale and angle are reset instantly before this fires — only opacity
    /// and blur animate, producing a cross-fade rather than a zoom-in.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let cardRestore: Animation = .easeOut(duration: 0.45)

    /// 0.52s ease-out — Name input UI fading in after card lift sequence.
    /// Reduce motion: replaced with .linear(duration: 0.1) at call site.
    static let uiFadeIn: Animation = .easeOut(duration: 0.52)

    /// Spring — Greeting "Hi [name]" row settling into view after typing pause.
    /// response: 1.1, dampingFraction: 0.88 — slow deliberate arrival with
    /// minimal overshoot. The greeting should feel earned, not snappy.
    /// Reduce motion: replace with AppAnimation.standard at call site.
    static let greetingSettle: Animation = .spring(response: 1.1, dampingFraction: 0.88)

    /// 0.35s ease-in-out — Header text fading out/in during the crossfade
    /// sequence after the name is confirmed. Applied per-line.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let headerFade: Animation = .easeInOut(duration: 0.35)

    /// Spring — Keystroke micro-bounce on underline. High stiffness, low damping —
    /// snappy downward kick that reads as the line reacting to each character arriving.
    /// Reduce motion: skip entirely — no bounce fires under reduce motion.
    static let keystrokeBounce: Animation = .interpolatingSpring(stiffness: 600, damping: 12)

    /// Spring — Underline returning to baseline after keystroke bounce.
    /// Lower stiffness than keystrokeBounce — the return is softer than the kick.
    /// Reduce motion: skip entirely — no bounce fires under reduce motion.
    static let keystrokeBounceReturn: Animation = .interpolatingSpring(stiffness: 400, damping: 18)

    /// 0.40s ease-out — Impact ring expanding outward after card lands on table.
    static let impactRingDecay: Animation = .easeOut(duration: 0.40)

    /// 0.35s ease-out — Radial burst fading after card flip completes.
    static let flipBurstDecay: Animation = .easeOut(duration: 0.35)

    /// 0.45s ease-out — Spectrum underline sweeping in on first field focus.
    static let lineReveal: Animation = .easeOut(duration: 0.45)

    /// 0.30s ease-in — Coach mark or hint element fading into view.
    static let coachMarkIn: Animation = .easeIn(duration: 0.30)

    /// 0.55s ease-in-out — Coach mark travelling downward during the hint sequence.
    static let coachMarkTravel: Animation = .easeInOut(duration: 0.55)

    /// 0.35s ease-out — Coach mark or hint element fading out of view.
    static let coachMarkOut: Animation = .easeOut(duration: 0.35)

    /// Spring — Screen nudging downward to hint at the swipe affordance.
    /// response: 0.45, dampingFraction: 0.62 — perceptible overshoot that
    /// communicates the screen is moveable.
    static let screenNudge: Animation = .spring(response: 0.45, dampingFraction: 0.62)

    /// Spring — Screen returning to baseline after the nudge hint.
    /// Higher damping than screenNudge — the return is settled, not bouncy.
    static let screenNudgeReturn: Animation = .spring(response: 0.55, dampingFraction: 0.78)

    /// 0.25s ease-in — Hint arrow chevron fading into view.
    static let hintArrowIn: Animation = .easeIn(duration: 0.25)

    /// 0.45s ease-out — Hint arrow chevron fading out of view.
    static let hintArrowOut: Animation = .easeOut(duration: 0.45)

    /// 0.55s ease-in-out — Name glow pulse expanding on the greeting.
    /// Applied in both directions: scale up and scale back to 1.0.
    static let glowPulse: Animation = .easeInOut(duration: 0.55)

    /// 4.0s ease-in-out — VaylFlourishView ambient breathing pulse.
    /// Apply .repeatForever(autoreverses: true) at the call site.
    /// This is an ambient animation — remove entirely under reduce motion.
    static let flourishBreath: Animation = .easeInOut(duration: 4.0)

    // MARK: — Gender Phase: Swipe Hint
    // An intermittent "swipe right" demo that runs only after the user has settled the
    // gender drum — i.e. has actively made a choice and earned the prompt. The card
    // flicks right then springs home, pauses, and repeats, modeled on how dating apps
    // demonstrate a right-swipe. No rotation: pure directional translation so it reads
    // as the swipe gesture itself, not a tilt. Stops the instant the user grabs the card
    // or re-scrolls the drum.
    // Ambient: suppressed entirely under reduce motion (guarded at the call site by
    // the View's accessibilityReduceMotion value). Settle to rest with the spring /
    // AppAnimation.standard when the hint stops.

    /// 0.26s ease-out — Card throwing right during one swipe-hint flick.
    /// Fast departure that reads as the start of a real right-swipe; paired with
    /// AppAnimation.spring for the settle back home, then a still pause before repeating.
    /// Reduce motion: never fires — the start branch is guarded by reduceMotion.
    static let swipeHintFlick: Animation = .easeOut(duration: 0.26)
}

// MARK: — Reduce Motion Helpers

extension Animation {

    /// Returns the reduce-motion safe version of a reactive animation.
    /// Replaces spatial movement with a fast opacity confirmation.
    /// Uses UIAccessibility directly — safe to call outside of a View context.
    /// Use at every call site where the animation drives positional change.
    ///
    /// Example:
    ///   withAnimation(.standard.reduceMotionSafe) { ... }
    var reduceMotionSafe: Animation {
        if UIAccessibility.isReduceMotionEnabled {
            return .easeOut(duration: 0.15)
        }
        return self
    }
}

extension View {

    /// Conditionally applies an ambient animation only when reduce motion is not active.
    /// Uses a Transaction to bind the animation to a specific value — avoids the deprecated
    /// unbound .animation() modifier which caused unpredictable propagation in iOS 15+.
    /// When reduce motion is active, the animation is stripped entirely from the transaction.
    /// The view renders in its static state — not slowed down, fully removed.
    ///
    /// Example:
    ///   myGlowView
    ///       .ambientAnimation(.easeInOut(duration: AppAnimation.ambientPulse).repeatForever(),
    ///                         value: isAnimating)
    func ambientAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        self.transaction { transaction in
            if UIAccessibility.isReduceMotionEnabled {
                transaction.animation = nil
            } else {
                transaction.animation = animation
            }
        }
    }
}
