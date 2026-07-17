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

    /// 0.65s ease-out — StatPhase exit: the entire phase fades out after "Begin" is tapped.
    /// Long enough that the phase cross-fade (AppAnimation.slow) absorbs the remaining tail.
    /// Reduce motion: replace with AppAnimation.fast at call site.
    static let statExitFade: Animation = .easeOut(duration: 0.65)

    /// 0.32s ease-in-out — StatPhase citation panel toggle (open and close).
    /// Calm dim + fade — not snappy, not ceremonial. The panel is reference content.
    /// Reduce motion: replace with AppAnimation.fast at call site.
    static let statCitationToggle: Animation = .easeInOut(duration: 0.32)

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

    /// 0.2s ease-in, delayed 0.32s — Card alpha fading out at the END of a pocket flight.
    /// Companion to cardPocket: the card stays visible for ~90% of the travel and dissolves
    /// INTO the corner deck rather than fading at launch (fading across the whole flight made
    /// it vanish in ~0.15s, so the handoff never visibly arrived). Used at every pocket site —
    /// NamePhase, DemoPhase, GenderPhase, CuriosityPhase handoff, and ThreeCardFanController.
    /// Reduce motion: via .reduceMotionSafe → .easeOut(duration: 0.15); the delay is dropped.
    static let pocketAlphaFade: Animation = .easeIn(duration: 0.2).delay(0.32)

    /// Spring — the ContextPhase carousel assembling up off the receding felt. A touch of
    /// overshoot (lower damping than the general `spring` 0.5/0.85) so the cards ARRIVE
    /// rather than fade in. FEEL-GATE — tuned on device.
    /// Reduce motion: guarded at the call site (only fires on the non-RM entrance path).
    static let carouselAssemble: Animation = .spring(response: 0.6, dampingFraction: 0.74)

    /// Spring — ConfirmationPhase fan dealing out of the corner deck onto the felt.
    /// Applied per-card with a staggered .delay() at the call site (rightmost deals first).
    /// Reduce motion: call site returns AppAnimation.fast instead.
    static let confirmDeal: Animation = .spring(response: 0.46, dampingFraction: 0.84)   // FEEL-GATE: snappier, livelier deal (was 0.55 / 0.86)

    /// Spring — ConfirmationPhase fan GATHERING into the deck on confirm (the keystone
    /// "six credentials become THE deck" moment). 0.8 response so the collapse reads as a
    /// deliberate gather, not a snap. Applied per-card with a staggered .delay() at the call site.
    /// Reduce motion: call site returns AppAnimation.fast instead.
    static let confirmGather: Animation = .spring(response: 0.8, dampingFraction: 0.85)

    /// Spring — ConfirmationPhase cards turning face-down as they gather (their truths go
    /// private on the way to the deck). Applied per-card with a staggered .delay() at the call site.
    /// Reduce motion: call site returns AppAnimation.fast instead.
    static let confirmFlip: Animation = .spring(response: 0.5, dampingFraction: 0.9)

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

    /// 0.70s ease-out — The felt blooming UP onto the table (the inverse of tableRecede).
    /// One characteristic weight for every felt fade-IN after the first arrival, so the
    /// table reads as one physical surface: ModeSelect entry, Confirmation entry, and the
    /// Context felt re-emerging after the carousel. (The very first felt arrival in Demo
    /// stays on the heavier cinematicFade — the world's debut.) FEEL-GATE.
    /// Reduce motion: via .reduceMotionSafe → .easeOut(duration: 0.15) — felt appears.
    static let tableBloom: Animation = .easeOut(duration: 0.70)

    /// 1.0s ease-in-out — OB atmosphere crossfade between phases (OnboardingAtmosphere).
    /// Slow + geological so the background shifts beneath attention, never snappy. Single
    /// owner of the config crossfade — the canvas no longer double-animates it.
    /// Reduce motion: ambient background; acceptable as-is (opacity-only crossfade).
    static let atmosphereShift: Animation = .easeInOut(duration: 1.0)

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

    /// 0.42s per half — Demo card 3D flip. Same cubic as cardFlipHalf (0.4,0,0.6,1)
    /// but slower — DemoPhase is the user's first flip encounter; extra weight adds ceremony.
    /// Two halves compose a full 0.84s Demo flip. Not interchangeable with cardFlipHalf.
    /// Reduce motion: skip flip entirely — face swaps without rotation.
    static let demoFlipHalf: Animation = .timingCurve(0.4, 0, 0.6, 1, duration: 0.42)

    /// 0.52s cubic — 3D edge-turn on ExperienceLevelPhase card flip.
    /// timingCurve (0.45, 0.05, 0.55, 0.95): slight ease-in gathering momentum,
    /// then easing out as the card faces the user. Not a general flip token.
    /// Reduce motion: skip the turn — face swaps instantly.
    static let cardTurn3D: Animation = .timingCurve(0.45, 0.05, 0.55, 0.95, duration: 0.52)

    // MARK: — DemoPhase Sequence
    // Tokens for the Demo "I want ___" card: sentence melt → verb cycle → seal → dissolve.
    // These are ceremony-level animations that ONLY belong in DemoPhase — do not reuse.

    /// 1.05s ease-out — "I want" sentence dissolving / melting onto the card face.
    /// Deliberately slow — the melt is the first "magic" moment the user sees.
    /// Reduce motion: replace with AppAnimation.fast at call site.
    static let demoSentenceMelt: Animation = .easeOut(duration: 1.05)

    /// 0.24s ease-in-out — Verb slot-machine crossfade during the intro cycle.
    /// Short enough that the cycle feels quick and mechanical.
    /// Reduce motion: cycle is skipped entirely at call site.
    static let demoVerbCrossfade: Animation = .easeInOut(duration: 0.24)

    /// Spring — Demo card gliding to stage centre. response: 0.95, dampingFraction: 1.0 —
    /// critically damped (no oscillation), deliberately slower than cardCenter (0.72s).
    /// The demo card should feel weighty arriving at its presentation spot.
    /// Reduce motion: replace with AppAnimation.standard at call site.
    static let demoCenterDeliberate: Animation = .spring(response: 0.95, dampingFraction: 1.0)

    /// 0.35s ease-in-out — Sentence fusing into the seal line (chevron + prompt resolve).
    /// Runs before the dissolve — traces the line, THEN breaks it into motes.
    /// Reduce motion: replace with AppAnimation.fast at call site.
    static let sealTrace: Animation = .easeInOut(duration: 0.35)

    /// 1.0s ease-out — Card dissolving into spectrum motes after seal.
    /// Runs concurrently with the pocket animation — motes lift off before card flies.
    /// sealBloom (0.5s) uses AppAnimation.slow (exact match) — no separate token.
    /// Reduce motion: dissolve is skipped entirely at call site.
    static let sealDissolve: Animation = .easeOut(duration: 1.0)

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

    // MARK: — FounderLetterPhase
    /// 0.45s ease-in-out — The OB's final swipe-down descent ("curtain falls").
    /// Heavier than exit (0.2s easeIn) — the last gesture deserves weight.
    /// Half of the letter's own 0.4s arrival, so it mirrors rather than outdoes it.
    /// Apply .reduceMotionSafe at the call site.
    static let curtainFall: Animation = .easeInOut(duration: 0.45)

    // MARK: — Desire Map
    // Tokens for the ten-screen Desire Map flow (rater + reveal + paywall).
    // Two classes, same rules as the rest of this file:
    //   Reactive  — screen transitions, star ignitions, sheet rises, depth-push.
    //               Reduce motion fallback: .easeOut(duration: 0.15).
    //   Ambient   — sparkle cadence, hesitant line sketch, charted hold.
    //               Disable entirely under reduce motion — skip the .task / loop,
    //               hold the static state.
    //
    // Starting values tuned from the storyboard prototypes. Bryan dials final feel
    // on device — do not lock these before the device pass.

    // Reveal reactive
    /// 0.80s ease-out — Spectrum-bloom entrance wash as the rater opens.
    /// The one ceremonial entrance: the start screen recedes and Q1 emerges from depth.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let desireRevealBloom: Animation = .easeOut(duration: 0.80)

    /// 0.72s ease-out — Free star glow blooming in on reveal open.
    /// Fires on .onAppear of the free star; the star ignites to full then sparkles.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — star appears lit, no bloom.
    static let desireStarIgnite: Animation = .easeOut(duration: 0.72)

    /// 0.56s overshoot — a matched star blooming from two seeds into one bright star (the merge
    /// settle). The timingCurve's y2 > 1 produces a soft overshoot past full size before it settles.
    /// Feel reference: docs/prototypes/desire-map-match-ceremony.html
    /// Reduce motion: the two-seed entrance is skipped entirely; the star renders lit.
    static let desireStarMergeSettle: Animation = .timingCurve(0.34, 1.3, 0.5, 1, duration: 0.56)

    /// 0.56s — the two seeds (your purple, their magenta) drifting together as the star ignites.
    /// Slightly less overshoot than the bloom so the points arrive cleanly into one.
    /// Reduce motion: the entrance is skipped.
    static let desireStarSeedDrift: Animation = .timingCurve(0.34, 1.2, 0.5, 1, duration: 0.56)

    /// 0.18s — the bloom starts this long after the seeds begin converging, so the star brightens
    /// as the seeds arrive rather than before. Consumed as a `.delay`. Reduce motion: unused.
    static let desireStarMergeBloomDelay: Double = 0.18

    /// 0.76s ease-out — Constellation lines drawing on at the reveal.
    /// Applied to a trimFraction (0 → 1) on the confident-mode path in ConstellationField.
    /// Reduce motion: lines appear at full opacity, no draw-on travel.
    static let desireLineDraw: Animation = .easeOut(duration: 0.76)

    /// 0.50s ease-out — Detail / full-map / paywall sheet rising from the bottom.
    /// Applied to the .move(edge: .bottom) transition inside the cover's sheet host.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — sheet appears in place.
    static let desireSheetRise: Animation = .easeOut(duration: 0.50)

    // Rater depth-push reactive
    /// 0.20s ease-in — Current question receding on answer: scale .93 + translateY 7 + fade.
    /// Fast exit clears the stage for the incoming question without lingering.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — question disappears.
    static let desireDepthExit: Animation = .easeIn(duration: 0.20)

    /// 0.34s ease-out — Next question emerging from depth: scale 1.07 → 1 + fade-in.
    /// Slightly longer than exit — the arrival has more presence than the departure.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — question appears.
    static let desireDepthEnter: Animation = .easeOut(duration: 0.34)

    /// 0.56s ease-out — Answer star rising into the personal sky above.
    /// Synced to fire alongside desireDepthExit so the star lifts as the question recedes.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — star appears in sky position.
    static let desireStarRise: Animation = .easeOut(duration: 0.56)

    // Finish-beat reactive
    /// 0.35s ease-out — Last question and answer rows fading out at completion.
    /// Clears the stage for the finish-flair star rise.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let desireFinishFade: Animation = .easeOut(duration: 0.35)

    /// 0.80s ease-out — Last star rising with extra ignite + sparkle burst on completion.
    /// Brighter and slower than a normal desireStarRise — the climactic beat of rating.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — final star appears lit.
    static let desireFinishFlair: Animation = .easeOut(duration: 0.80)

    /// 0.60s ease-out — "Your map is charted." copy + hesitant constellation lines fading in.
    /// Fired after the finish-flair star settles, not immediately after the last rate().
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let desireChartedFadeIn: Animation = .easeOut(duration: 0.60)

    // Desire Map ambient (raw Double — not Animation instances)
    // All three: disable the .task / loop entirely when reduce motion is active.
    // The static state (a resting cross + glow, faint partial lines) must read without motion.

    /// 0.95s — Total duration of one sparkle keyframe (scale 0→1→0.55, opacity 0→1→0, slight rotation).
    /// Not an Animation — consumed by KeyframeAnimator total. Divide across CubicKeyframe tracks at the call site.
    /// Reduce motion: skip the .task trigger entirely; sparkle never fires.
    static let desireSparkleDuration: Double = 0.95

    /// 3.5s — Mean cadence for free/active star sparkle.
    /// Randomize ±55–160% at the call site (.task sleeps desireSparkleFreeRate * factor)
    /// so stars twinkle out of phase rather than in sync.
    /// Reduce motion: .task is never started.
    static let desireSparkleFreeRate: Double = 3.5

    /// 7.0s — Mean cadence for locked/dim star sparkle.
    /// Same randomize recipe as desireSparkleFreeRate; locked stars twinkle rarely.
    /// Reduce motion: .task is never started.
    static let desireSparkleLockedRate: Double = 7.0

    /// 2.0s — Hold at the charted screen before auto-advancing (tap-anywhere skips).
    /// Not an Animation — consumed by Task.sleep at the call site.
    /// Reduce motion: use as-is; the hold is timing, not motion.
    static let desireChartedHold: Double = 2.0

    /// 4.2s — One full pass of the hesitant constellation line sketch loop.
    /// Lines draw partway, pull back, fade, and restart — never locking.
    /// Not an Animation — consumed by a repeating loop at the call site.
    /// Reduce motion: loop never starts; lines hold at a faint partial-draw static state.
    static let desireHesitantSketch: Double = 4.2

    // Reveal 3-beat ceremony holds (raw Double — consumed by Task.sleep in DesireRevealStore).
    // Reduce motion: collapse both holds to ~0 so the reveal resolves instantly (no timed ceremony).

    /// 1.5s — Beat 1 → Beat 2: the free star settles before the locked gap appears.
    static let desireBeatHold1: Double = 1.5

    /// 1.2s — Beat 2 → Beat 3: the gap holds before the paywall rises.
    static let desireBeatHold2: Double = 1.2

    /// 0.08s — Per-locked-row stagger step (added per locked match before the Beat-2 hold begins).
    static let desireBeatStaggerStep: Double = 0.08

    /// 0.14s — Base offset before the locked-row stagger (the first row's lead-in).
    static let desireBeatStaggerBase: Double = 0.14

    /// 0.36s — A single locked teaser row fading/staggering into the gap (Beat 2).
    /// Reduce motion: falls back via `.reduceMotionSafe` to a fast opacity confirm.
    static let desireLockedRowEnter: Animation = .easeOut(duration: 0.36)

    // Reveal ceremony — the telegraphed constellation assembly (DesireConstellationView).
    // Stars light in the variant's order with a budgeted stagger; lines draw when both ends are
    // lit; a telegraph wind-up precedes. Reduce motion: skip to the static lit sky (no assembly).

    /// 1.4s — total budget to light all non-hero stars; per-star stagger = budget / count (clamped),
    /// so many stars do not drag.
    static let desireCeremonyBudget: Double = 1.4
    /// 0.5s — gap after the hero ignites before the rest begin (Gather).
    static let desireCeremonyHeroLead: Double = 0.5
    /// Per-star stagger clamps during the assembly.
    static let desireCeremonyStaggerMin: Double = 0.09
    static let desireCeremonyStaggerMax: Double = 0.30
    /// 1.7s — the Sweep band's full pass across the field; stars light as it reaches them.
    static let desireSweepDuration: Double = 1.7
    /// Linear sweep of the telegraph band across the field.
    static let desireSweepBand: Animation = .linear(duration: desireSweepDuration)
    /// 0.64s ease-in — the Gather telegraph contracting a point of light to center before the hero.
    static let desireGatherPulse: Animation = .easeIn(duration: 0.64)
    /// 0.5s — how long the Gather wind-up holds before the hero forms. Consumed by Task.sleep.
    static let desireGatherLead: Double = 0.5

    // Vayl mark ceremony — the one-shot "map charted" moment (MapChartedMoment).
    // Reduce motion: skip both; the mark is shown fully drawn and the copy is shown at once.

    /// 1.0s — The aperture draws/assembles on: rings trim in, glow blooms, core ignites.
    static let markDraw: Animation = .easeOut(duration: 1.0)

    /// 0.5s — The copy fades up after the mark has mostly assembled.
    static let markCopyRise: Animation = .easeOut(duration: 0.5)

    /// 0.9s — How long the copy waits for the mark to draw before rising (a `.delay`).
    static let markCopyDelay: Double = 0.9

    /// 2.8s — Hold after the copy resolves before the moment auto-advances back to Home.
    /// Reduce motion: measured from appear (no draw lead). Consumed by Task.sleep.
    static let markHold: Double = 2.8

    // MARK: — Pulse Aura
    // Ambient durations for PulseAura (raw Doubles — construct with .easeInOut at call site).
    // All three are ambient: guard with `!reduceMotion` in PulseAura; never fire under reduce motion.
    // FEEL: all values tuned on device against docs/prototypes/pulse-aura-glass.html.

    /// 5.4s — Aura body breathe (scale 1 ↔ 1.045, autoreverses). FEEL: tune on device.
    static let auraBreathe: Double = 5.4

    /// 7.0s — Caustic drift, one leg (offsets alternate, autoreverses). FEEL: tune on device.
    static let auraCausticDrift: Double = 7.0

    /// 8.5s — Glass sweep full non-reversing cycle. Mockup parity: the glint crosses the
    /// circle about every 8.5s (map-pulse-final.html @keyframes sweep / .od note).
    /// Was 17.0s; halved to match the mockup cadence. FEEL: confirm on device.
    static let auraGlassSweep: Double = 8.5

    /// The check-in ball's position-change shift (Q1-Q5 drift). Plain eased interpolation,
    /// NOT a spring — even a critically-damped spring still has a fast-snap-then-settle
    /// character; this reads as a smooth, even slide to the new point instead.
    /// 🎚️ FEEL: confirm on device.
    static let pulseBallDrift: Animation = .easeInOut(duration: 0.32)

    /// Uncharted resolution — the field (zone blobs, ghost labels, axis labels) fades to
    /// opacity 0 when the variance check fires after the final answer. 🎚️ FEEL: tune on device.
    static let pulseUnchartedFieldFade: Animation = .easeInOut(duration: 1.2)

    /// Uncharted resolution — the orb colour dissolves from its bilinear colour to Sage Deep,
    /// slightly slower than the field fade so colour lands last. 🎚️ FEEL: tune on device.
    static let pulseUnchartedColorDissolve: Animation = .easeInOut(duration: 1.5)

    /// Uncharted orb drift — slow, non-repeating-pattern wander around centre; replaces the
    /// bloom ring as the "landed" signal. Raw duration: construct .easeInOut(duration:).repeatForever
    /// at the call site. 🎚️ FEEL: amplitude + timing tuned on device.
    static let pulseUnchartedDrift: Double = 6.0

    /// History-grid border-state dots — one shared TimelineView drives all border dots'
    /// gentle two-colour LEAN at this cadence (per-dot phase offset by index). Slow on purpose:
    /// a border dot is a blend that drifts, never a flash. Raw seconds used in the sin() phase
    /// term, not an Animation. 🎚️ FEEL: tune on device.
    static let pulseHistoryBorderCadence: Double = 4.5

    // MARK: — Tab Navigation
    // Tokens for the tab bar orb snap-and-halo and tab content gravity drift.
    // Both are reactive (user-initiated tap). Reduce motion: easeOut(0.15), suppress offsets at call site.

    /// Spring — Tab bar orb snapping to new selection. response: 0.40, dampingFraction: 0.62
    /// overshoots ~15% past target then springs back, communicating physical momentum.
    /// Also drives the halo burst scale at the landing icon.
    /// Reduce motion: replace with AppAnimation.fast — orb jumps to position without travel.
    /// DEPRECATED by the motion system: `orbGlide` replaces this (the overshoot read as
    /// disconnected from the staple grammar — feel-rejected 2026-07-03). Delete this token
    /// when RacetrackTabBar migrates (motion spec §7 step 2); do not adopt in new code.
    static let orbSnap: Animation = .spring(response: 0.40, dampingFraction: 0.62)

    /// 0.25s ease-out — Tab content gravitational drift on tab switch.
    /// Incoming view drifts 14pt in from the direction of navigation, decelerating to rest.
    /// Outgoing view fades in place (no counter-drift — avoids direction-mismatch on removal).
    /// Reduce motion: call site should suppress the offset and cross-fade only.
    static let tabSwitch: Animation = .easeOut(duration: 0.25)

    // MARK: — Motion System (Staples & Registers)
    // The app-wide motion grammar. Spec: docs/superpowers/specs/2026-07-03-motion-system-design.md
    // Feel reference: docs/prototypes/motion-system-staples.html (all values tuned there;
    // device-feel-gated — starting points until Bryan's device pass confirms).
    //
    // Three staples × two registers:
    //   Staple 1 — Depth Handoff   (screen-level change: settle from depth, recede into it)
    //   Staple 2 — Weighted Arrival (objects entering: sheets, covers, cards)
    //   Staple 3 — Charged Tap      (input: the borderFill grammar — shared register, see
    //                                VaylBorderEffect; its tokens live in the Border Effect
    //                                section above)
    //   Loud  = OB + protected covers. Quiet = everything else.
    //
    // Appliers (transitions/modifiers with Reduce Motion built in) live in AppMotion.swift —
    // the AppGlows pattern: values here, thin stateless applications there.
    //
    // QUIET-TIER CEILINGS (hard caps, cite in review): scale delta ≤ quietMaxScaleDelta,
    // travel ≤ quietMaxTravel, duration ≤ 0.55s. Ceremony-class motion (multi-second builds,
    // dealer motifs) is BANNED outside the OB canvas and .vaylCover contents.

    /// 0.26s ease-out — Staple 1, Quiet register: main-app screen/content swaps.
    /// Incoming settles 1.01 → 1, outgoing recedes 1 → 0.985, opacity cross-fade. Never a slide.
    /// Reduce motion: AppMotion's applier collapses to pure opacity.
    static let depthQuiet: Animation = .easeOut(duration: 0.26)

    /// Staple 1 scale amplitudes. Quiet pair obeys quietMaxScaleDelta; Loud pair is the OB
    /// phaseHandoff (promoted from OnboardingCanvasView literals — same values, now tokens).
    /// Loud duration = AppAnimation.slow (the OB step-transition token), unchanged.
    static let depthQuietScaleIn:  CGFloat = 1.01
    static let depthQuietScaleOut: CGFloat = 0.985
    static let depthLoudScaleIn:   CGFloat = 1.02
    static let depthLoudScaleOut:  CGFloat = 0.97

    /// 0.50s ease-out — Staple 2, Quiet: a .vaylSheet rising, settling, and dismissing.
    /// One confident glide home, zero bounce. Device-feel-gated to easeOut/0.50 (Bryan's
    /// pass 2026-07-04, preferred over the earlier 0.42 deal-curve for the workhorse sheet);
    /// now wired into `.vaylSheet` (VaylPresentation). Shares its curve with desireSheetRise.
    /// Reduce motion: replace with .easeOut(duration: 0.15) on opacity — sheet appears in place.
    static let arrive: Animation = .easeOut(duration: 0.50)

    /// 0.55s deal-curve — Staple 2, Loud: a .vaylCover entering the table world. Same curve as
    /// `arrive`, heavier. The register shift IS the threshold cue into a protected mode.
    /// Reduce motion: replace with .easeOut(duration: 0.15) on opacity.
    static let arriveCover: Animation = .timingCurve(0, 0, 0.2, 1, duration: 0.55)

    /// 0.18s — Cover CONTENT settles from depth (Staple 1 nested in Staple 2) this long after
    /// the cover container starts rising. Consumed as a .delay on the content's settle.
    /// Reduce motion: unused — content appears with the cover.
    static let arriveCoverContentLag: Double = 0.18

    /// 0.38s glide — Tab bar orb drifting to the new selection: soft gather, long decelerating
    /// tail, ZERO overshoot — cubic (0.3, 0, 0.15, 1), the arrival-curve family, so the orb
    /// speaks the same physics as the sheets and the depth handoff. Replaces orbSnap (the
    /// spring overshoot was feel-rejected as disconnected). The halo burst re-times to this
    /// glide's landing, not a spring peak.
    /// Reduce motion: replace with AppAnimation.fast — orb jumps without travel.
    static let orbGlide: Animation = .timingCurve(0.3, 0, 0.15, 1, duration: 0.38)

    /// 0.52s long-tail drift — One row of a FIRST-ARRIVAL cascade: cubic (0.25, 0.1, 0.15, 1),
    /// soft start, slow bleed into rest. Rows overlap ~85% via cascadeStagger so the list reads
    /// as ONE wave travelling down, not per-row pops. Deliberately slower than `enter`: the
    /// cascade is the entrance for the whole list, not per-element decoration.
    /// LAW: only the first data arrival cascades — refreshes fade, never cascade.
    /// Reduce motion: all rows appear together with a single 0.2s fade (AppMotion applier).
    static let cascadeRow: Animation = .timingCurve(0.25, 0.1, 0.15, 1, duration: 0.52)

    /// 75ms — Per-row cascade stagger. The overlap ratio is what sells the wave: tighten the
    /// stagger for a quicker wave, lengthen cascadeRow for a dreamier one — duration alone
    /// does not fix abruptness.
    static let cascadeStagger: Double = 0.075

    /// 6 — Cascade row cap. Rows past the cap arrive together WITH the last capped row, so a
    /// long list never turns the entrance into a parade.
    static let cascadeCap: Int = 6

    /// 14pt — Cascade row rise distance (obeys quietMaxTravel).
    static let cascadeRise: CGFloat = 14

    /// 0.28s / ±3pt — Staple 3's "no": a refused (disabled/invalid) commit shivers laterally;
    /// the border arcs never fill. Pair with .sensoryFeedback(.impact(.medium)) at the call
    /// site — the haptic is half the refusal.
    /// Reduce motion: no shiver; the haptic still fires (haptics are not motion).
    static let refusalDuration:  Double  = 0.28
    static let refusalAmplitude: CGFloat = 3

    /// 0.10s — Commit dismissal: a task-completing sheet's exit launches this long after the
    /// commit glow's PEAK (glow peaks at borderGlowIn 0.12s → exit begins 0.22s after release,
    /// riding the glow's decay out). Cancels (grabber, scrim, Cancel) exit plain on `exit` —
    /// no charge ever built. Feel-locked at 100ms in the reference (60 buried the glow,
    /// 160 read as the app admiring its own button).
    static let commitDismissLag: Double = 0.10

    /// Quiet-register amplitude ceilings — hard caps, not guidelines. A quiet-tier animation
    /// scaling by more than this delta or travelling further than this is a violation; reach
    /// for a Loud token only inside the OB canvas or .vaylCover contents.
    static let quietMaxScaleDelta: Double  = 0.02
    static let quietMaxTravel:     CGFloat = 16

    // MARK: — OB Ceremony Tokens (tokenized from raw call-site values, 2026-07-03)
    // Values moved VERBATIM from OB files during the motion-token migration — the token
    // contract ("zero raw values") now holds inside the OB too. All are Loud-register,
    // OB-only. Do not re-tune here without a device feel pass; do not reuse in main-app code.

    /// Spring — the name-entry write line kicking down as a character lands (NamePhase).
    /// Softer than keystrokeBounce (600/12): the line reacts, the key does the snapping.
    /// Reduce motion: skip — no bounce fires under reduce motion.
    static let writeLineBounce: Animation = .interpolatingSpring(stiffness: 320, damping: 16)

    /// Spring — the Demo noun field pulsing back after input is cleaned/capped (DemoPhase).
    /// Reduce motion: acceptable as-is — a 6pt settle, confirmation not travel.
    static let demoFieldPulse: Animation = .interpolatingSpring(stiffness: 320, damping: 14)

    /// 0.7s ease-out — the Name card being SET DOWN by the dealer (fades in a hair high +
    /// large, settles to rest). Not a deal: no flight, no slide. FEEL-GATE origin value.
    /// Reduce motion: skipped at call site — card appears at rest.
    static let cardSetDown: Animation = .easeOut(duration: 0.7)

    /// 0.22s ease-in — the Curiosity DEMO card gliding partway off during the dealer's
    /// keep/pass demonstration (not the user's own throw — that's curiosityThrow).
    /// Reduce motion: the demo sequence is skipped entirely at the call site.
    static let curiosityDemoSwipe: Animation = .easeIn(duration: 0.22)

    /// 0.42s ease-out — the monte fan OPENING into a ribbon spread before the turnover
    /// (ExperienceLevelPhase). FEEL-GATE origin value.
    /// Reduce motion: the spread sequence never runs (reveal() path).
    static let fanSpreadOpen: Animation = .easeOut(duration: 0.42)

    /// 0.42s ease-in-out — the spread RE-COLLECTING to the resting fan after the turnover.
    /// Symmetric ease: the close mirrors the open. Reduce motion: never runs.
    static let fanRecollect: Animation = .easeInOut(duration: 0.42)

    /// 0.88s deal-curve — the ModeSelect mirror deal: both cards travelling simultaneously
    /// from opposite screen edges, weighted deceleration (cubic 0,0,0.2,1 — the arrival
    /// family at its heaviest travel).
    /// Reduce motion: call path is guarded upstream by the phase's RM branch.
    static let mirrorDealTravel: Animation = .timingCurve(0, 0, 0.2, 1, duration: 0.88)

    /// 0.22s per half — the REJECTED mirror card turning face-down on confirm. Same cubic
    /// as cardFlipHalf (0.4, 0, 0.6, 1) but faster (0.22 vs 0.29): the discard turn is an
    /// aside, not a reveal. Two halves compose the 0.44s reject flip.
    static let mirrorRejectFlipHalf: Animation = .timingCurve(0.4, 0, 0.6, 1, duration: 0.22)

    /// 0.42s — the rejected card sliding back toward its origin and fading. Same
    /// ease-into-motion-then-accelerate-away cubic as cardPocket (0.4, 0, 1, 1), shorter:
    /// the discard leaves, it is not filed.
    static let mirrorRejectExit: Animation = .timingCurve(0.4, 0, 1, 1, duration: 0.42)

    // — BuildDeck forge ceremony (Beats 1–7). All Loud-register, ceremony-class:
    //   these tokens must NEVER appear outside BuildDeckPhase / the OB canvas.

    /// Spring pair — the stage JOLT on a case strike: hard kick in (0.12/0.5), settle (0.32/0.7).
    static let strikeJolt:       Animation = .spring(response: 0.12, dampingFraction: 0.5)
    static let strikeJoltSettle: Animation = .spring(response: 0.32, dampingFraction: 0.7)

    /// Spring — the case yawing back to rest after a directional strike recoil.
    static let strikeRecoilReturn: Animation = .spring(response: 0.3, dampingFraction: 0.55)

    /// Spring — the case settling after an autonomous knock twitch (the deck wants out).
    /// Lower damping than strikeRecoilReturn: the knock wobbles, the strike is commanded.
    static let knockReturn: Animation = .spring(response: 0.35, dampingFraction: 0.5)

    /// Spring pair — the stage jolt on the SHATTER (third strike): heavier than a strike
    /// (0.18/0.6 in, 0.4/0.7 settle) — the climax lands harder than its wind-up.
    static let shatterJolt:       Animation = .spring(response: 0.18, dampingFraction: 0.6)
    static let shatterJoltSettle: Animation = .spring(response: 0.4, dampingFraction: 0.7)

    /// 0.5s ease-out — the white flash decaying after the case bursts.
    static let burstFlashDecay: Animation = .easeOut(duration: 0.5)

    /// 0.34s ease-in — the revealed deck (cards + title + CTA) sinking away on hand-off
    /// to the founder letter. FEEL-GATE origin value.
    static let deckExitSink: Animation = .easeIn(duration: 0.34)

    /// 0.5s ease-in-out — the founder letter sheet rising bottom → full. FEEL-GATE origin.
    static let letterRise: Animation = .easeInOut(duration: 0.5)

    /// 2.6s ease-in — the credential deck MELTING down through the felt (Beat 1).
    /// Ceremony-class duration: the forge's slowest, heaviest move.
    static let deckMeltDown: Animation = .easeIn(duration: 2.6)

    /// 1.0s ease-out — the forged case fading in on the felt (Beat 3a).
    static let caseFadeIn: Animation = .easeOut(duration: 1.0)

    /// 2.0s ease-in-out — the standing case taking the air and scaling up (Beat 3c dolly).
    static let caseFloatLift: Animation = .easeInOut(duration: 2.0)

    /// 1.4s ease-out — the table's rim + sway settling to rest as the felt lets the case go.
    static let forgeSettle: Animation = .easeOut(duration: 1.4)

    /// 1.2s ease-in-out — the case core lighting up once armed (contained energy).
    static let coreCharge: Animation = .easeInOut(duration: 1.2)

    /// 0.9s / 1.3s — one leg of the forge's rim-glow and topo-sway oscillations (Beat 1–2,
    /// "the table works"). Raw Doubles per the ambient-duration convention: build at the
    /// call site with .easeInOut(duration:) + .repeatForever(autoreverses: true).
    /// Reduce motion: the oscillation never starts (steady mid glow, still lines).
    static let forgeRimOscillation:  Double = 0.9
    static let forgeSwayOscillation: Double = 1.3

    // — Living Case tap ceremony (Beat 5 rework, 2026-07-04) + flower-peel reveal.
    //   The three taps are a negotiation: the case recognizes, resists, releases.
    //   Feel reference: the React "Living Case / Flower Peel" mockup (values verbatim).

    /// Damped-shake decay spans per strike (seconds) — consumed by the per-frame shake
    /// task in BuildDeckPhase: amplitude * exp(-p * 5) * sin(p * freq * 2π).
    /// Reduce motion: the shake task never starts.
    static let caseShake1: Double = 0.28
    static let caseShake2: Double = 0.42
    static let caseShake3: Double = 0.60

    /// A card back erupting through the lattice / the lattice resealing over it.
    /// The module's per-tap erupt/hold/seal spans (MetallicCaseView tunables) are
    /// timed against these two curves — re-tune both together.
    static let cardErupt:  Animation = .easeOut(duration: 0.32)
    static let cardReseal: Animation = .easeInOut(duration: 0.42)

    /// The flower peel — the case peeling away from the deck, centre cells first.
    static let flowerPeel: Animation = .easeInOut(duration: 1.35)
    /// Raw span of the peel — drives MetallicCaseView.peelSpan and the phase's
    /// shell-unmount sleep. Must match flowerPeel's duration.
    static let flowerPeelSpan: Double = 1.35

    /// The deck becoming visible / rising through the opening centre WHILE the peel
    /// runs (the case peels away FROM the deck — the deck never "appears after").
    static let peelDeckFade: Animation = .easeOut(duration: 0.54)
    static let peelDeckRise: Animation = .easeOut(duration: 0.81)

    /// Beat 6 reveal sequence — breath, name, fan, flip wave, CTA.
    /// The breath is the silence beat: the freed deck inhales/exhales once before
    /// any UI names it. Cutting it turns the ceremony into a UI transition.
    static let deckBreathIn:  Animation = .easeInOut(duration: 0.68)
    static let deckBreathOut: Animation = .easeInOut(duration: 0.52)
    static let deckNameRise:  Animation = .easeOut(duration: 0.58)
    static let deckFanBloom:  Animation = .easeOut(duration: 0.70)
    static let deckFlipWave:  Animation = .easeInOut(duration: 0.32)   // per card
    static let deckFlipStagger: Double  = 0.085                        // seconds between flips
    static let deckCtaFade:   Animation = .easeOut(duration: 0.36)
}

// MARK: — Ambient Motion Gate (Reduce Motion + Low Power Mode)

extension AppAnimation {

    /// True while the device is in Low Power Mode. Decorative ambient loops are exactly
    /// the discretionary GPU/CPU cost Low Power Mode exists to cut, so ambient motion
    /// treats it the same way it treats Reduce Motion: the loop is removed, the static
    /// state must read complete. Reactive animations are NOT gated on this — user
    /// feedback always plays.
    static var lowPower: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    /// The one question every ambient loop asks before starting: Reduce Motion
    /// (accessibility) OR Low Power Mode (battery). Read at body-evaluation time,
    /// same semantics as the Reduce Motion check — a mid-session toggle takes
    /// effect the next time the view re-evaluates or re-appears.
    /// Call sites that already hold `@Environment(\.accessibilityReduceMotion)`
    /// should guard with `reduceMotion || AppAnimation.lowPower` so the RM half
    /// keeps its live environment reactivity.
    static var ambientMotionDisabled: Bool {
        UIAccessibility.isReduceMotionEnabled || lowPower
    }
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
    /// Gated on `value` via the standard `.animation(_:value:)` modifier — this ONLY
    /// (re-)triggers when `value` itself changes (e.g. the one-time false→true flip an
    /// `.onAppear` typically does to kick off a `.repeatForever()` loop). Once running,
    /// an unrelated re-render elsewhere in the app does not restart it.
    ///
    /// The previous implementation used `.transaction { transaction.animation = animation }`,
    /// which is unconditional — it reapplies the ambient animation to EVERY transaction that
    /// flows through the view, for ANY reason, regardless of whether `value` changed. On a
    /// screen with frequent nearby `withAnimation(...)` calls (e.g. the Pulse check-in firing
    /// one on every pill tap), that repeatedly forced the aura's already-looping
    /// breathe/caustic/sweep layers to reset mid-cycle — visible as the orb "not staying
    /// static between answer selections" even when its position genuinely hadn't changed.
    ///
    /// Example:
    ///   myGlowView
    ///       .ambientAnimation(.easeInOut(duration: AppAnimation.ambientPulse).repeatForever(),
    ///                         value: isAnimating)
    func ambientAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        self.animation(AppAnimation.ambientMotionDisabled ? nil : animation, value: value)
    }
}
