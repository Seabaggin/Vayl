# LLM Audit Context — Vayl · Theme Files

> **Scope: All theme tokens, primitives, and modifiers.**
>
> Contents:
>   [1] Color, Font, Spacing, Layout, Grid, Radius, Elevation, SafeArea, Glows tokens
>       → AppColors / AppFonts / AppSpacing / AppLayout / AppGrid / AppRadius / AppElevation / AppSafeArea / AppGlows
>   [2] Animation + Theme entry point
>       → AppAnimation / AppTheme
>   [3] Theme manager + view modifiers
>       → ThemeManager / ThemeModifiers
>   [4] Root view + Vayl design primitives
>       → AppRootView / VaylPrimitives
>
> Generated: 2026-05-25 17:25:50 PDT

---

## Table of Contents

  1. [`Vayl/App/Theme/AppAnimation.swift`](#file-vayl-app-theme-appanimation-swift)
  2. [`Vayl/App/Theme/AppColors.swift`](#file-vayl-app-theme-appcolors-swift)
  3. [`Vayl/App/Theme/AppElevation.swift`](#file-vayl-app-theme-appelevation-swift)
  4. [`Vayl/App/Theme/AppFonts.swift`](#file-vayl-app-theme-appfonts-swift)
  5. [`Vayl/App/Theme/AppGlows.swift`](#file-vayl-app-theme-appglows-swift)
  6. [`Vayl/App/Theme/AppGrid.swift`](#file-vayl-app-theme-appgrid-swift)
  7. [`Vayl/App/Theme/AppLayout.swift`](#file-vayl-app-theme-applayout-swift)
  8. [`Vayl/App/Theme/AppRadius.swift`](#file-vayl-app-theme-appradius-swift)
  9. [`Vayl/App/Theme/AppRootView.swift`](#file-vayl-app-theme-approotview-swift)
  10. [`Vayl/App/Theme/AppSafeArea.swift`](#file-vayl-app-theme-appsafearea-swift)
  11. [`Vayl/App/Theme/AppSpacing.swift`](#file-vayl-app-theme-appspacing-swift)
  12. [`Vayl/App/Theme/AppTheme.swift`](#file-vayl-app-theme-apptheme-swift)
  13. [`Vayl/App/Theme/ThemeManager.swift`](#file-vayl-app-theme-thememanager-swift)
  14. [`Vayl/App/Theme/ThemeModifiers.swift`](#file-vayl-app-theme-thememodifiers-swift)
  15. [`Vayl/App/Theme/VaylPrimitives.swift`](#file-vayl-app-theme-vaylprimitives-swift)

---

## File: `Vayl/App/Theme/AppAnimation.swift` {#file-vayl-app-theme-appanimation-swift}

```swift
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

```

---

## File: `Vayl/App/Theme/AppColors.swift` {#file-vayl-app-theme-appcolors-swift}

```swift
// App/Theme/AppColors.swift

import SwiftUI

// ─────────────────────────────────────────────────────────────
// Tier 2 — Semantic color tokens.
//
// Rules:
//   • Every token has ONE name describing purpose, not appearance
//   • Every token resolves automatically for light and dark via
//     UIColor(dynamicProvider:) — no manual branching in views
//   • Every token maps exclusively to VaylPrimitives values
//   • Every token has a one-line use context comment
//   • VaylPrimitives is NEVER referenced outside this file
//
// Light = Dawn mode   (warm cream, refractive atmosphere)
// Dark  = Midnight mode (deep ink, emissive glows)
// ─────────────────────────────────────────────────────────────

struct AppColors {

    // ─────────────────────────────────────────────
    // MARK: Backgrounds — elevation hierarchy
    //
    // Page → Card → Modal. Never nest a higher
    // elevation color inside a lower one.
    // ─────────────────────────────────────────────

    /// Root view background. One per screen, never nested.
    static let pageBackground = Color.dynamic(
        light: VaylPrimitives.warmCream,
        dark:  VaylPrimitives.inkBase
    )

    /// Content containers that sit directly on pageBackground.
    static let cardBackground = Color.dynamic(
        light: VaylPrimitives.pureWhite,
        dark:  VaylPrimitives.inkCard
    )

    /// Second-tier elevated cards that sit on cardBackground.
    static let cardBackgroundRaised = Color.dynamic(
        light: VaylPrimitives.roseWhite,
        dark:  VaylPrimitives.inkCardRaised
    )

    /// Sheets, modals, overlays. Always sits above cardBackground.
    static let modalBackground = Color.dynamic(
        light: VaylPrimitives.pureWhite,
        dark:  VaylPrimitives.inkSurface
    )

    /// Holographic shimmer pill base. HolographicShimmer use only.
    static let shimmerBase    = Color(uiColor: VaylPrimitives.inkShimmerBase)
    /// Dark muted orb colours — not the vivid spectrum anchors. HolographicShimmer use only.
    static let shimmerViolet  = Color(uiColor: VaylPrimitives.inkShimmerViolet)
    static let shimmerCyan    = Color(uiColor: VaylPrimitives.inkShimmerCyan)
    static let shimmerPurple  = Color(uiColor: VaylPrimitives.inkShimmerPurple)
    static let shimmerMagenta = Color(uiColor: VaylPrimitives.inkShimmerMagenta)
    static let shimmerIndigo  = Color(uiColor: VaylPrimitives.inkShimmerIndigo)

    /// Input fields and inset wells. Recessed below pageBackground.
    static let inputBackground = Color.dynamic(
        light: VaylPrimitives.offWhite,
        dark:  VaylPrimitives.inkRaised
    )

    /// Home widget base layers only. Between page and card elevation.
    static let widgetBackground = Color.dynamic(
        light: VaylPrimitives.warmCream,
        dark:  VaylPrimitives.inkWidget
    )

    /// Constellation node core fill. Slightly lighter than pageBackground with a
    /// purple undertone. Distinct from cardBackground / modalBackground — not a
    /// general surface token; use only in ConstellationView node circles.
    static let constellationNodeCore = Color.dynamic(
        light: VaylPrimitives.pureWhite,
        dark:  VaylPrimitives.inkNodeCore
    )

    // ─────────────────────────────────────────────
    // MARK: OB StatPhase — ethos gradient
    //
    // Exclusive to EthosTextView in StatPhase.
    // Bakes the per-mode accent colors and their specific opacity values
    // into tokens so no numeric opacity literals appear in the View layer.
    // ─────────────────────────────────────────────

    /// Ethos gradient lead stop. accentPrimary at near-opaque presence.
    /// 10% transparency softens the hard start of the gradient sweep.
    static let ethosGradientLead = Color.dynamic(
        light: VaylPrimitives.magenta.withAlphaComponent(0.90),
        dark:  VaylPrimitives.cyan.withAlphaComponent(0.90)
    )

    /// Ethos gradient trail stop. accentSecondary at softened presence.
    /// 20% drop from lead produces a gentle luminosity fade across the short phrase.
    static let ethosGradientTrail = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.80),
        dark:  VaylPrimitives.purple.withAlphaComponent(0.80)
    )

    // ─────────────────────────────────────────────
    // MARK: OB Flourish — decorative component
    //
    // These tokens are exclusive to VaylFlourishView.
    // Sourced from the same hue palette as the "1 in 5" headline gradient
    // so the flourish reads as an extension of that typography.
    // ─────────────────────────────────────────────

    /// Flourish gradient left stop — purple end, mirrors accentSecondary palette.
    static let flourishLeft: Color = Color(uiColor: VaylPrimitives.purpleLight)

    /// Flourish gradient midpoint — lavender bridge between purple and coral.
    static let flourishMid: Color = Color(uiColor: VaylPrimitives.purpleBright)

    /// Flourish gradient right stop — coral/pink end, mirrors accentTertiary palette.
    static let flourishRight: Color = Color(uiColor: VaylPrimitives.magentaLight)

    /// Flourish Canvas layer base opacity. Renders as subtle texture, not decoration.
    static let flourishBaseOpacity: Double = 0.75

    // ─────────────────────────────────────────────
    // MARK: OB Canvas
    //
    // These tokens are exclusive to the Onboarding canvas.
    // They must never appear in main-app screens.
    //
    // Light-mode values are placeholders — they mirror the dark
    // values until OB Dawn mode is designed. Update both the
    // primitive and the light: stop here when that work begins.
    // Do not remove the light: parameter — it future-proofs the
    // token for adaptive resolution.
    // ─────────────────────────────────────────────

    /// Absolute floor of the OB canvas. The void the table sits in.
    /// Slightly warmer and more violet than inkBase — gives the table
    /// world its own atmospheric identity separate from the main app.
    /// Light: placeholder mirrors dark until OB Dawn is designed.
    static let void = Color.dynamic(
        light: VaylPrimitives.inkVoid,
        dark:  VaylPrimitives.inkVoid
    )

    /// OB card glass surface. Applied to VaylCardBack and VaylCardFace.
    /// Distinct from cardBackground (inkCard #12111A) — the OB card
    /// surface is #120f1a, a fraction warmer in the blue channel.
    /// Light: placeholder mirrors dark until OB Dawn is designed.
    static let cardBg = Color.dynamic(
        light: VaylPrimitives.inkCardOB,
        dark:  VaylPrimitives.inkCardOB
    )

    // ─────────────────────────────────────────────
    // MARK: OB Table Surface — rendering constants
    //
    // These tokens are exclusive to TableSurfaceView.
    // They simulate physical light on baize and an overhead
    // lamp — they are rendering constants, not brand colors.
    // They must never appear in any other view or component.
    //
    // Light-mode values mirror dark until OB Dawn is designed.
    // ─────────────────────────────────────────────

    /// Felt fill gradient — center stop. TableSurfaceView use only.
    static let tableFeltCore = Color.dynamic(
        light: VaylPrimitives.tableFeltCore,
        dark:  VaylPrimitives.tableFeltCore
    )

    /// Felt fill gradient — mid stop. TableSurfaceView use only.
    static let tableFeltMid = Color.dynamic(
        light: VaylPrimitives.tableFeltMid,
        dark:  VaylPrimitives.tableFeltMid
    )

    /// Felt fill gradient — outer stop. TableSurfaceView use only.
    static let tableFeltOuter = Color.dynamic(
        light: VaylPrimitives.tableFeltOuter,
        dark:  VaylPrimitives.tableFeltOuter
    )

    /// Felt fill gradient — trailing edge stop. TableSurfaceView use only.
    static let tableFeltEdge = Color.dynamic(
        light: VaylPrimitives.tableFeltEdge,
        dark:  VaylPrimitives.tableFeltEdge
    )

    /// Topo contour line stroke. TableSurfaceView use only.
    static let tableTopoLine = Color.dynamic(
        light: VaylPrimitives.tableTopoLine,
        dark:  VaylPrimitives.tableTopoLine
    )

    /// Compass star base color. TableSurfaceView use only.
    static let tableCompassStar = Color.dynamic(
        light: VaylPrimitives.tableCompassStar,
        dark:  VaylPrimitives.tableCompassStar
    )

    /// Amber overhead lamp pool center stop. TableSurfaceView use only.
    static let tableAmberPool = Color.dynamic(
        light: VaylPrimitives.tableAmberPool,
        dark:  VaylPrimitives.tableAmberPool
    )

    // ─────────────────────────────────────────────
    // MARK: Spectrum — fixed accent values
    //
    // These three tokens resolve the fixed spectrum anchor colors
    // used for hairlines, glows, and accents throughout the app.
    // They are NOT adaptive — the spectrum is the same in both modes.
    // Use these tokens wherever a single spectrum channel is needed.
    // For full spectrum gradients use spectrumBorder or spectrumText.
    // ─────────────────────────────────────────────

    /// Spectrum cyan anchor. #00C2FF. Hairlines, glows, accents.
    static let spectrumCyan    = Color(uiColor: VaylPrimitives.cyan)

    /// Spectrum purple anchor. #6C3AE0. Hairlines, glows, accents.
    static let spectrumPurple  = Color(uiColor: VaylPrimitives.purple)

    /// Spectrum magenta anchor. #FF006A. Hairlines, glows, accents.
    static let spectrumMagenta = Color(uiColor: VaylPrimitives.magenta)

    /// Mid-spectrum gradient bridge. Wordmark and spectrum sweep use only.
    /// Sits between cyan and magenta on the gradient arc — not a standalone accent.
    static let spectrumBridge  = Color(uiColor: VaylPrimitives.spectrumBridge)

    // ─────────────────────────────────────────────
    // MARK: Text — hierarchy
    //
    // Never use a lower-hierarchy token for primary content.
    // ─────────────────────────────────────────────

    /// Headings, screen titles, display text.
    static let textPrimary = Color.dynamic(
        light: VaylPrimitives.wineDeep,
        dark:  VaylPrimitives.inkText
    )

    /// Paragraph content, card text, descriptions.
    static let textBody = Color.dynamic(
        light: VaylPrimitives.wineMid,
        dark:  VaylPrimitives.pureWhite
    )

    /// Labels, descriptions, supporting copy. 60% hierarchy.
    static let textSecondary = Color.dynamic(
        light: VaylPrimitives.wineMid.withAlphaComponent(0.60),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.65)
    )

    /// Timestamps, metadata, counts. 38% hierarchy.
    /// Apply .italic() at usage site — italic is the semantic signal.
    static let textTertiary = Color.dynamic(
        light: VaylPrimitives.wineMid.withAlphaComponent(0.38),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.38)
    )

    /// Placeholder text, pronoun hints, inline helper copy.
    static let textHint = Color.dynamic(
        light: VaylPrimitives.magentaDark.withAlphaComponent(0.50),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.42)
    )

    /// Disabled states, ghost copy. Lowest visible hierarchy.
    static let textMuted = Color.dynamic(
        light: VaylPrimitives.wineMid.withAlphaComponent(0.22),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.20)
    )

    /// Overline labels and status counts. Must survive a tinted
    /// ambient background — device-absolute, never tinted.
    static let textBright = Color.dynamic(
        light: VaylPrimitives.wineDeep,
        dark:  UIColor(white: 0.90, alpha: 1)
    )

    /// Tappable links and accent body text.
    static let textAccent = Color.dynamic(
        light: VaylPrimitives.magentaDark,
        dark:  VaylPrimitives.cyan
    )

    /// Card overline and section labels with spectrum tint.
    static let textCardLabel = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.70),
        dark:  VaylPrimitives.cyan.withAlphaComponent(0.60)
    )

    // ─────────────────────────────────────────────
    // MARK: Accent — action and emphasis
    // ─────────────────────────────────────────────

    /// Primary interactive accent. CTAs, active states, focus rings.
    /// Midnight: cyan (emissive). Dawn: magenta (refractive).
    static let accentPrimary = Color.dynamic(
        light: VaylPrimitives.magenta,
        dark:  VaylPrimitives.cyan
    )

    /// Secondary accent. Decorative spectrum, orbit trails.
    static let accentSecondary = Color.dynamic(
        light: VaylPrimitives.purple,
        dark:  VaylPrimitives.purple
    )

    /// Tertiary accent. Badge fills, atmospheric tints.
    static let accentTertiary = Color.dynamic(
        light: VaylPrimitives.gold,
        dark:  VaylPrimitives.magenta
    )

    // ─────────────────────────────────────────────
    // MARK: Borders
    // ─────────────────────────────────────────────

    /// Default card and surface border. Barely visible structural edge.
    static let borderSubtle = Color.dynamic(
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.06),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.06)
    )

    /// Hover and focus border. Slightly more present than subtle.
    static let borderDefault = Color.dynamic(
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.10),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.10)
    )

    /// Active, selected, or structural border.
    static let borderActive = Color.dynamic(
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.15),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.15)
    )

    /// Accent-tinted border. Focus rings on accent inputs.
    static let borderAccent = Color.dynamic(
        light: VaylPrimitives.magenta.withAlphaComponent(0.22),
        dark:  VaylPrimitives.cyan.withAlphaComponent(0.20)
    )

    /// Purple-tinted structural border. Cards and fields in light mode.
    static let borderPurple = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.14),
        dark:  VaylPrimitives.purple.withAlphaComponent(0.14)
    )

    // ─────────────────────────────────────────────
    // MARK: Feedback states
    // ─────────────────────────────────────────────

    /// Destructive actions, error states, irreversible confirmations.
    static let destructive = Color.dynamic(
        light: VaylPrimitives.destructiveRed,
        dark:  VaylPrimitives.destructiveRed
    )

    /// Success confirmations, completed states.
    static let success = Color.dynamic(
        light: VaylPrimitives.successGreen,
        dark:  VaylPrimitives.successGreen
    )

    // ─────────────────────────────────────────────
    // MARK: Gold — safety signal
    //
    // At full or near-full opacity: safety signals only.
    // (safe word button, warnings, hard stop actions)
    // Aurora atmospheric use at ≤8% opacity is acceptable —
    // it cannot be read as a directional signal at that opacity.
    // If it is visible enough to be noticed as gold, it is
    // too opaque for non-safety use.
    // ─────────────────────────────────────────────

    /// Safety signal accent. Safe word, warnings, hard stops only.
    static let safetyAccent = Color.dynamic(
        light: VaylPrimitives.gold,
        dark:  VaylPrimitives.gold
    )

    /// Aurora atmospheric wash. ≤8% opacity enforced at call sites.
    static let safetyAtmosphere = Color.dynamic(
        light: VaylPrimitives.gold,
        dark:  VaylPrimitives.gold
    )

    // ─────────────────────────────────────────────
    // MARK: Shadows and glows
    // ─────────────────────────────────────────────

    /// Modal scrims and card drop shadows.
    static let shadowDeep = Color.dynamic(
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.12),
        dark:  VaylPrimitives.pureBlack.withAlphaComponent(0.50)
    )

    /// Dawn tinted shadow — magenta channel. Cards in light mode.
    static let shadowMagenta = Color.dynamic(
        light: VaylPrimitives.magenta.withAlphaComponent(0.18),
        dark:  VaylPrimitives.magenta.withAlphaComponent(0.10)
    )

    /// Dawn tinted shadow — purple channel. Cards in light mode.
    static let shadowPurple = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.12),
        dark:  VaylPrimitives.purple.withAlphaComponent(0.08)
    )

    /// Dawn tinted shadow — gold warmth layer. Lowest shadow channel.
    static let shadowGold = Color.dynamic(
        light: VaylPrimitives.gold.withAlphaComponent(0.07),
        dark:  VaylPrimitives.gold.withAlphaComponent(0.04)
    )

    // ─────────────────────────────────────────────
    // MARK: Aurora atmosphere
    //
    // Background blobs behind frosted surfaces.
    // Opacity intentionally low — felt, not seen.
    // ─────────────────────────────────────────────

    /// Aurora blob — top right corner.
    static let auroraBlob1 = Color.dynamic(
        light: VaylPrimitives.magenta.withAlphaComponent(0.09),
        dark:  VaylPrimitives.magenta.withAlphaComponent(0.09)
    )

    /// Aurora blob — bottom left corner.
    static let auroraBlob2 = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.08),
        dark:  VaylPrimitives.purple.withAlphaComponent(0.08)
    )

    // ─────────────────────────────────────────────
    // MARK: Glass fills
    //
    // Opaque values only. Semi-transparent fills multiply with
    // container opacity and vanish at disabled (0.45).
    // These hold shape identity at any opacity level.
    // ─────────────────────────────────────────────

    /// Frosted card fill. Warm near-white over aurora in Dawn.
    static let glassFrostCard = Color.dynamic(
        light: VaylPrimitives.frostCard,
        dark:  VaylPrimitives.inkCard
    )

    /// Unselected pill fill. Visible contrast against page background.
    static let glassFrostPill = Color.dynamic(
        light: VaylPrimitives.frostPill,
        dark:  VaylPrimitives.inkPill
    )

    /// Selected pill fill. Lifts visibly over unselected state.
    static let glassFrostPillSelected = Color.dynamic(
        light: VaylPrimitives.frostPillSelected,
        dark:  VaylPrimitives.inkSurface
    )

    /// CTA button fill. Warm rose on Dawn, ink surface on Midnight.
    static let glassFrostCTA = Color.dynamic(
        light: VaylPrimitives.frostCTA,
        dark:  VaylPrimitives.inkSurface
    )

    // ─────────────────────────────────────────────
    // MARK: Pill surface — Midnight mode
    //
    // ~15% brighter than cardBackground so pill labels have a
    // contrast floor against the purple ambient atmosphere.
    // ─────────────────────────────────────────────

    /// Unselected pill interior gradient — bottom stop.
    static let pillSurfaceBottom = Color.dynamic(
        light: VaylPrimitives.frostPillBottom,
        dark:  VaylPrimitives.inkPillBottom
    )

    /// Ambient lift shadow on every pill.
    static let pillGlow = Color.dynamic(
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.04),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.04)
    )

    // ─────────────────────────────────────────────
    // MARK: Input
    // ─────────────────────────────────────────────

    /// Floating label color when a text field is focused.
    static let inputLabelFocused = Color.dynamic(
        light: VaylPrimitives.magentaDark,
        dark:  VaylPrimitives.cyan
    )

    // ─────────────────────────────────────────────
    // MARK: Icon badge backgrounds
    // ─────────────────────────────────────────────

    /// Magenta-tinted icon badge background.
    static let iconBadgeMagenta = Color.dynamic(
        light: VaylPrimitives.magenta.withAlphaComponent(0.18),
        dark:  VaylPrimitives.magenta.withAlphaComponent(0.12)
    )

    /// Amber-tinted icon badge background.
    static let iconBadgeAmber = Color.dynamic(
        light: VaylPrimitives.orangeHot.withAlphaComponent(0.14),
        dark:  VaylPrimitives.orangeHot.withAlphaComponent(0.10)
    )

    /// Gold-tinted icon badge background.
    static let iconBadgeGold = Color.dynamic(
        light: VaylPrimitives.gold.withAlphaComponent(0.14),
        dark:  VaylPrimitives.gold.withAlphaComponent(0.10)
    )

    // ─────────────────────────────────────────────
    // MARK: Toggle
    // ─────────────────────────────────────────────

    /// Active toggle and switch fill.
    static let toggleActive = Color.dynamic(
        light: VaylPrimitives.magenta,
        dark:  VaylPrimitives.cyan
    )

    // ─────────────────────────────────────────────
    // MARK: Progress bar
    // ─────────────────────────────────────────────

    /// Leading stop of onboarding progress bar fill.
    static let progressBarLeading = Color.dynamic(
        light: VaylPrimitives.orangeHot,
        dark:  VaylPrimitives.cyan
    )

    /// Trailing stop of onboarding progress bar fill.
    static let progressBarTrailing = Color.dynamic(
        light: VaylPrimitives.orangeDeep,
        dark:  VaylPrimitives.purple
    )

    // ─────────────────────────────────────────────
    // MARK: App icon
    // ─────────────────────────────────────────────

    /// App icon launch background. Asset-matched fixed value.
    static let appIconBackground = Color(uiColor: VaylPrimitives.inkAppIcon)

    // ─────────────────────────────────────────────
    // MARK: Gradient stop tokens — structural only
    //
    // These are building blocks for gradients below.
    // Not for direct use in views — if you see gradientStop*
    // in a view file, that is a violation.
    //
    // Midnight: cyan  → purple → magenta   (emissive spectrum)
    // Dawn:     purple → magenta → gold    (refractive aurora)
    //
    // Cyan never appears in Dawn — it reads clinical on warm cream.
    // ─────────────────────────────────────────────

    private static let gradientStop1 = Color.dynamic(
        light: VaylPrimitives.purple,
        dark:  VaylPrimitives.cyan
    )
    private static let gradientStop2 = Color.dynamic(
        light: VaylPrimitives.magenta,
        dark:  VaylPrimitives.purple
    )
    private static let gradientStop3 = Color.dynamic(
        light: VaylPrimitives.gold,
        dark:  VaylPrimitives.magenta
    )

    // ─────────────────────────────────────────────
    // MARK: Gradients — public tokens
    // ─────────────────────────────────────────────

    /// Universal spectrum border.
    /// Midnight: cyan → purple → magenta
    /// Dawn:     purple → magenta → gold
    /// Applied to every prompt card and bordered surface.
    /// OB files reference this token as spectrumGradient — use this instead.
    static let spectrumBorder = LinearGradient(
        colors: [gradientStop1, gradientStop2, gradientStop3],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Universal spectrum text highlight.
    /// Same adaptive stops as spectrumBorder, horizontal direction.
    /// Use with .foregroundStyle() on keyword Text views.
    /// OB files reference this token as spectrumTextGradient — use this instead.
    static let spectrumText = LinearGradient(
        colors: [gradientStop1, gradientStop2, gradientStop3],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Light mode shimmer sweep. Used in LightModeShimmer.swift only.
    static let lightShimmerColors: [Color] = [
        Color(uiColor: VaylPrimitives.purple.withAlphaComponent(0.22)),
        Color(uiColor: VaylPrimitives.magenta.withAlphaComponent(0.20)),
        Color(uiColor: VaylPrimitives.gold.withAlphaComponent(0.18)),
        Color(uiColor: VaylPrimitives.magenta.withAlphaComponent(0.18)),
        Color(uiColor: VaylPrimitives.purple.withAlphaComponent(0.22)),
    ]

    // ─────────────────────────────────────────────
    // MARK: Card intensity — tinted backgrounds
    //
    // Used by CardIntensity extension only.
    // Not for general use in views or components.
    // ─────────────────────────────────────────────

    static let cardIntensityTintCyan       = Color(uiColor: VaylPrimitives.tintCyan)
    static let cardIntensityTintPurple     = Color(uiColor: VaylPrimitives.tintPurple)
    static let cardIntensityTintMagenta    = Color(uiColor: VaylPrimitives.tintMagenta)
    static let cardIntensityTintNavy       = Color(uiColor: VaylPrimitives.tintNavy)
    static let cardIntensityTintIndigo     = Color(uiColor: VaylPrimitives.tintIndigo)
    static let cardIntensityTintPlum       = Color(uiColor: VaylPrimitives.tintPlum)
    static let cardIntensityTintSupernovaA = Color(uiColor: VaylPrimitives.tintSupernovaA)
    static let cardIntensityTintSupernovaB = Color(uiColor: VaylPrimitives.tintSupernovaB)
    static let cardIntensityTintSupernovaC = Color(uiColor: VaylPrimitives.tintSupernovaC)
    static let cardIntensityTintSupernovaD = Color(uiColor: VaylPrimitives.tintSupernovaD)

    // ─────────────────────────────────────────────────────────────
    // MARK: Pulse tier — data visualization only
    //
    // These colors represent emotional capacity states on a scale.
    // Used exclusively in pulse graph and tier indicators.
    // Never used for UI interaction states or accents.
    //
    // Midnight: emissive spectrum — cyan down to soft magenta
    // Dawn:     refractive spectrum — magenta down to muted wine
    // ─────────────────────────────────────────────────────────────

    /// Pulse tier 1 — Expansive. Highest capacity. Connected, adventurous.
    static let pulseTierExpansive = Color.dynamic(
        light: VaylPrimitives.magenta,
        dark:  VaylPrimitives.cyan
    )

    /// Pulse tier 2 — Sovereign. Stable capacity. Grounded, secure.
    static let pulseTierSovereign = Color.dynamic(
        light: VaylPrimitives.purple,
        dark:  VaylPrimitives.purple
    )

    /// Pulse tier 3 — Friction. Reduced capacity. Anxious, defensive.
    static let pulseTierFriction = Color.dynamic(
        light: VaylPrimitives.magentaDark,
        dark:  VaylPrimitives.magenta
    )

    /// Pulse tier 4 — Protective. Lowest capacity. Overwhelmed, needs space.
    static let pulseTierProtective = Color.dynamic(
        light: VaylPrimitives.wineFaint,
        dark:  VaylPrimitives.magentaLight
    )
}


// MARK: - Color.dynamic

extension Color {
    /// Resolves automatically for light and dark via UIColor(dynamicProvider:).
    /// No @Environment(\.colorScheme) branching required in views.
    static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor(dynamicProvider: { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }))
    }
}

// MARK: - Color(hex:) — SwiftUI convenience

extension Color {
    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }
}

```

---

## File: `Vayl/App/Theme/AppElevation.swift` {#file-vayl-app-theme-appelevation-swift}

```swift
//
//  AppElevation.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//


// App/Theme/AppElevation.swift

import SwiftUI

/// Tier 2 — Semantic elevation tokens.
/// Every surface in the app belongs to exactly one elevation level.
/// Elevation communicates depth — which surface sits on top of which.
/// Shadows are never grey in either mode. Dawn and Midnight use tinted shadows only.
///
/// Elevation hierarchy (bottom to top):
///   Page → Card → Modal
///
/// Rules:
///   - A Page surface never has a shadow — it is the base layer.
///   - A Card surface always casts a shadow onto the Page below it.
///   - A Modal surface always casts a stronger shadow than a Card.
///   - Never nest a Page inside a Card, or a Card inside a Modal.
///   - Never apply a Card shadow to a Page surface or a Modal shadow to a Card surface.
internal enum AppElevation {

    // MARK: — Shadow Definition

    /// A fully specified shadow. Apply all four properties together — never mix
    /// the radius from one level with the offset from another.
    struct Shadow {
        /// The shadow color. Always a tinted AppColors token — never grey, never black.
        let color: Color
        /// The blur radius. Larger values produce softer, more diffuse shadows.
        let radius: CGFloat
        /// Horizontal offset. Positive moves the shadow right.
        let x: CGFloat
        /// Vertical offset. Positive moves the shadow down.
        let y: CGFloat
    }

    // MARK: — Page

    /// The base layer of every screen.
    /// Page surfaces sit directly on the display — they have no shadow.
    /// Background: AppColors.pageBackground
    /// Use: ScrollView backgrounds, full-screen view backgrounds, ZStack base layers.
    /// Never nest a Page surface inside any other surface.
    enum page {
        /// Page surfaces cast no shadow. This is a deliberate architectural constraint —
        /// if you feel a Page needs a shadow, the surface is at the wrong elevation level.
        static let shadow: Shadow? = nil
    }

    // MARK: — Card

    /// Content containers that sit on a Page surface.
    /// Card surfaces always cast a shadow downward onto the Page below them.
    /// Background: AppColors.cardBackground / AppColors.cardBackgroundRaised
    /// Use: Content cards, widget shells, pill containers, input field backgrounds.
    /// Never place a Card directly on a Modal surface.
    enum card {

        /// Midnight mode — deep cool shadow with a magenta warmth at the edge.
        /// Communicates the card sitting slightly above the dark page surface.
        static let midnightShadow = Shadow(
            color: AppColors.shadowDeep,
            radius: 16,
            x: 0,
            y: 8
        )

        /// Midnight mode — secondary magenta glow layer.
        /// Adds chromatic depth — the card feels lit from within, not just lifted.
        static let midnightGlow = Shadow(
            color: AppColors.shadowMagenta,
            radius: 24,
            x: 0,
            y: 4
        )

        /// Dawn mode — warm gold shadow.
        /// Grey shadows read as dirt on a warm background. Gold reads as sunlight.
        static let dawnShadow = Shadow(
            color: AppColors.shadowGold,
            radius: 12,
            x: 0,
            y: 6
        )

        /// Dawn mode — secondary purple warmth layer.
        /// Prevents the gold shadow from reading as a stain by adding spectral depth.
        static let dawnGlow = Shadow(
            color: AppColors.shadowPurple,
            radius: 20,
            x: 0,
            y: 3
        )
    }

    // MARK: — Modal

    /// Overlay surfaces that sit above Card surfaces.
    /// Modal surfaces always cast a stronger shadow than Cards — they are higher in the stack.
    /// Background: AppColors.modalBackground
    /// Use: Bottom sheets, full-screen overlays, contextual menus, confirmation dialogs.
    /// Never use a Modal surface for inline content — it must visually float above cards.
    enum modal {

        /// Midnight mode — deep shadow with increased radius and offset.
        /// The larger radius signals greater height above the page than a card.
        static let midnightShadow = Shadow(
            color: AppColors.shadowDeep,
            radius: 32,
            x: 0,
            y: 16
        )

        /// Midnight mode — strong magenta glow layer.
        /// More intense than the card glow to reinforce the greater elevation.
        static let midnightGlow = Shadow(
            color: AppColors.shadowMagenta,
            radius: 48,
            x: 0,
            y: 8
        )

        /// Dawn mode — deep gold shadow with stronger offset.
        /// The increased offset makes the modal read as clearly higher than any card.
        static let dawnShadow = Shadow(
            color: AppColors.shadowGold,
            radius: 24,
            x: 0,
            y: 12
        )

        /// Dawn mode — strong purple depth layer.
        /// Matches the increased intensity of the midnight modal glow in the warm palette.
        static let dawnGlow = Shadow(
            color: AppColors.shadowPurple,
            radius: 40,
            x: 0,
            y: 6
        )
    }

    // MARK: — Citation Panel
    // Exclusive to the expandable citation card in StatPhase.
    // Lighter radius than card elevation — the panel is a secondary
    // surface attached to inline copy, not a first-class card.

    enum citationPanel {

        /// Dawn mode — purple-tinted shadow matching the warm palette.
        static let dawnShadow = Shadow(
            color:  AppColors.shadowPurple,
            radius: 16,
            x:      0,
            y:      4
        )

        /// Midnight mode — deep shadow with slightly more spread.
        static let midnightShadow = Shadow(
            color:  AppColors.shadowDeep,
            radius: 20,
            x:      0,
            y:      6
        )
    }

    // MARK: — OB Card Physics Elevation
    // These tokens are exclusive to the Onboarding canvas.
    // They must never appear in main-app screens — the table metaphor
    // does not leave the OB boundary.
    //
    // OB cards exist on a continuous elevation range from 0.0 (flat on the table)
    // to 1.0 (fully lifted toward the user). The standard Page/Card/Modal tiers
    // do not apply here — card height is driven by physics state, not surface hierarchy.

    /// A shadow specification for a VaylCardModel at a given elevation.
    /// VaylDirector writes card.elevation. VaylCardRenderer calls this function.
    ///
    /// elevation 0.0 — card lying flat on the felt.
    ///   color: black at 50% opacity, radius 8pt, y offset 4pt.
    /// elevation 1.0 — card fully lifted toward the user.
    ///   color: black at 16% opacity, radius 32pt, y offset 20pt.
    ///
    /// The opacity inversion is intentional — a lifted card scatters its shadow
    /// across a larger area, so the color lightens as the radius grows.
    /// This matches the physical behaviour of an overhead point light source.
    ///
    /// - Parameter elevation: A Double in the range 0.0–1.0. Values outside
    ///   this range are not clamped — callers are responsible for correct input.
    struct CardShadow {
        let color:  Color
        let radius: CGFloat
        let y:      CGFloat
    }

    static func cardShadow(elevation: Double) -> CardShadow {
        CardShadow(
            color:  Color.black.opacity(lerp(0.50, 0.16, elevation)),
            radius: lerp(8,  32, elevation),
            y:      lerp(4,  20, elevation)
        )
    }

    // MARK: — Private Helpers

    /// Linear interpolation between two Double values.
    /// Used by cardShadow(elevation:) — not exported.
    /// a = value at t=0, b = value at t=1.
    private static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * t
    }
}

// MARK: — View Modifiers

private struct CardElevationModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let primary = colorScheme == .dark
            ? AppElevation.card.midnightShadow
            : AppElevation.card.dawnShadow

        let glow = colorScheme == .dark
            ? AppElevation.card.midnightGlow
            : AppElevation.card.dawnGlow

        return content
            .shadow(color: primary.color, radius: primary.radius, x: primary.x, y: primary.y)
            .shadow(color: glow.color, radius: glow.radius, x: glow.x, y: glow.y)
    }
}

private struct ModalElevationModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let primary = colorScheme == .dark
            ? AppElevation.modal.midnightShadow
            : AppElevation.modal.dawnShadow

        let glow = colorScheme == .dark
            ? AppElevation.modal.midnightGlow
            : AppElevation.modal.dawnGlow

        return content
            .shadow(color: primary.color, radius: primary.radius, x: primary.x, y: primary.y)
            .shadow(color: glow.color, radius: glow.radius, x: glow.x, y: glow.y)
    }
}

// MARK: — View Extension

extension View {

    /// Applies the correct Card elevation shadow for the current color scheme.
    /// Use on every surface at Card elevation. Never call this on Page or Modal surfaces.
    ///
    /// Example:
    ///   MyCardView()
    ///       .cardElevation()
    func cardElevation() -> some View {
        self.modifier(CardElevationModifier())
    }

    /// Applies the correct Modal elevation shadow for the current color scheme.
    /// Use on every surface at Modal elevation. Never call this on Page or Card surfaces.
    ///
    /// Example:
    ///   MySheetView()
    ///       .modalElevation()
    func modalElevation() -> some View {
        self.modifier(ModalElevationModifier())
    }
}

```

---

## File: `Vayl/App/Theme/AppFonts.swift` {#file-vayl-app-theme-appfonts-swift}

```swift
// App/Theme/AppFonts.swift

import SwiftUI

// ─────────────────────────────────────────────────────────────
// Typography scale.
//
// Rules:
//   • Every token uses Font.custom(_:size:relativeTo:) — no exceptions
//   • relativeTo: maps to the TextStyle closest to the token's
//     visual role — this is what Dynamic Type scales against
//   • Font.system(size:) is banned in this file
//   • assertionFailure fires on unsupported weights in debug
//     before the fallback path — surfaces programmer errors
//     without crashing in production
//   • Every token has a one-sentence use context comment
// ─────────────────────────────────────────────────────────────

struct AppFonts {

    // ─────────────────────────────────────────────
    // MARK: Typeface constructors
    //
    // Not for direct use in views.
    // Use the semantic tokens below.
    // ─────────────────────────────────────────────

    static func display(
        _ size: CGFloat,
        weight: Font.Weight = .bold,
        relativeTo textStyle: Font.TextStyle
    ) -> Font {
        switch weight {
        case .bold:
            return Font.custom("ClashDisplay-Bold",     size: size, relativeTo: textStyle)
        case .semibold:
            return Font.custom("ClashDisplay-Semibold", size: size, relativeTo: textStyle)
        case .medium:
            return Font.custom("ClashDisplay-Medium",   size: size, relativeTo: textStyle)
        default:
            assertionFailure(
                "AppFonts.display: unsupported weight \(weight). " +
                "Supported: .bold, .semibold, .medium"
            )
            return Font.custom("ClashDisplay-Bold", size: size, relativeTo: textStyle)
        }
    }

    static func body(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo textStyle: Font.TextStyle
    ) -> Font {
        switch weight {
        case .regular:
            return Font.custom("Switzer-Regular",  size: size, relativeTo: textStyle)
        case .medium:
            return Font.custom("Switzer-Medium",   size: size, relativeTo: textStyle)
        case .semibold:
            return Font.custom("Switzer-Semibold", size: size, relativeTo: textStyle)
        case .bold:
            return Font.custom("Switzer-Bold",     size: size, relativeTo: textStyle)
        default:
            assertionFailure(
                "AppFonts.body: unsupported weight \(weight). " +
                "Supported: .regular, .medium, .semibold, .bold"
            )
            return Font.custom("Switzer-Regular", size: size, relativeTo: textStyle)
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Display scale — ClashDisplay
    // ─────────────────────────────────────────────

    /// Full-screen hero text. Splash screens and empty state illustrations only.
    static var heroTitle: Font {
        display(42, weight: .bold, relativeTo: .largeTitle)
    }

    /// Oversized display numeral or word. One element per screen maximum.
    static var displayHero: Font {
        display(64, weight: .bold, relativeTo: .largeTitle)
    }

    /// Numeric data display — scores, counts, codes. Never prose.
    static var scoreDisplay: Font {
        display(32, weight: .bold, relativeTo: .title)
    }

    /// One per screen. Top of content area, primary screen identifier.
    static var screenTitle: Font {
        display(24, weight: .semibold, relativeTo: .title)
    }

    /// Onboarding phase headline. One per OB phase screen.
    /// Used for the cinematic opening statement on each onboarding phase —
    /// "Let's get acquainted.", "Good to meet you.", and equivalent lines
    /// on subsequent phases. Larger than screenTitle to anchor the emotional
    /// beat of each phase as a hero statement, not a navigation label.
    /// Never use outside the Onboarding canvas.
    /// relativeTo: .largeTitle — scales against the largest Dynamic Type style
    /// so the statement remains dominant at all accessibility sizes.
    static var obPhaseTitle: Font {
        display(32, weight: .semibold, relativeTo: .largeTitle)
    }

    /// Primary text inside a card surface. Never the screen title.
    static var cardTitle: Font {
        display(22, weight: .semibold, relativeTo: .title2)
    }

    /// Section labels inside a screen. Never the screen title.
    static var sectionHeading: Font {
        display(20, weight: .medium, relativeTo: .title3)
    }

    /// Category tags and grouped list headers.
    static var sectionLabelSmall: Font {
        display(13, weight: .medium, relativeTo: .subheadline)
    }

    /// The question or statement on a prompt card.
    static var prompt: Font {
        display(17, weight: .medium, relativeTo: .body)
    }

    /// Keyword emphasis within a prompt. Gradient foreground applied at usage site.
    static var promptHighlight: Font {
        display(17, weight: .semibold, relativeTo: .body)
    }

    // ─────────────────────────────────────────────
    // MARK: Body scale — Switzer
    // ─────────────────────────────────────────────

    /// Primary CTA button label. One per screen.
    static var ctaLabel: Font {
        body(17, weight: .semibold, relativeTo: .body)
    }

    /// Paragraph content. Never UI labels or navigation elements.
    static var bodyText: Font {
        body(16, weight: .regular, relativeTo: .body)
    }

    /// Emphasized body. Form labels, card subtitles, inline emphasis.
    static var bodyMedium: Font {
        body(15, weight: .medium, relativeTo: .body)
    }

    /// Secondary button and action label. Not the primary CTA.
    static var buttonLabel: Font {
        body(14, weight: .semibold, relativeTo: .callout)
    }

    /// Supporting information. Never primary content.
    static var caption: Font {
        body(13, weight: .regular, relativeTo: .caption)
    }

    /// Section dividers only. Always uppercase with tracking at usage site.
    static var overline: Font {
        body(11, weight: .semibold, relativeTo: .caption2)
    }

    /// Compact pill and chip labels only.
    static var buttonLabelSmall: Font {
        body(11, weight: .medium, relativeTo: .caption2)
    }

    /// Navigation labels at the bottom of the screen.
    static var tabLabel: Font {
        body(10, weight: .medium, relativeTo: .caption2)
    }

    /// Badges, counts, status indicators.
    static var label: Font {
        body(10, weight: .semibold, relativeTo: .caption2)
    }

    /// Notification and count badges only.
    static var badge: Font {
        body(10, weight: .medium, relativeTo: .caption2)
    }

    /// Timestamps, counts, secondary metadata. Never primary content.
    static var meta: Font {
        body(10, weight: .regular, relativeTo: .caption2)
    }

    // ─────────────────────────────────────────────
    // MARK: Debug
    // ─────────────────────────────────────────────

    static func debugFontList() {
        for family in UIFont.familyNames.sorted() {
            print("\n\(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  \(name)")
            }
        }
    }
}

```

---

## File: `Vayl/App/Theme/AppGlows.swift` {#file-vayl-app-theme-appglows-swift}

```swift
//
//  AppGlows.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/10/26.
//

// App/Theme/AppGlows.swift

import SwiftUI

// ─────────────────────────────────────────────────────────────
// Tier 2 — Semantic glow tokens.
//
// Rules:
//   • Every .shadow() call whose purpose is emissive glow
//     (not elevation depth) must reference a token from this file
//   • Elevation shadows live in AppElevation — never here
//   • Glow tokens describe energy emitted from a surface
//   • Elevation tokens describe height above a surface below
//   • If the shadow moves with the light source, it is elevation
//   • If the shadow pulses, reacts to input, or animates on its
//     own, it is a glow — it belongs here
//   • No raw CGFloat for radius or opacity anywhere in the app
//     that relates to a glow effect
//   • VaylPrimitives is never referenced in this file —
//     all colors come through AppColors tokens
// ─────────────────────────────────────────────────────────────

internal enum AppGlows {

    // ─────────────────────────────────────────────
    // MARK: Glow Layer Definition
    //
    // A GlowLayer is one pass of a .shadow() modifier.
    // Glows are always multi-layer — a tight inner core
    // for intensity, a broader outer halo for atmosphere.
    // Never apply a single .shadow() and call it a glow.
    // ─────────────────────────────────────────────

    struct GlowLayer {
        /// The color of this shadow pass.
        /// Always sourced from AppColors — never a raw color literal.
        let color: Color

        /// Blur radius. Larger = softer and more diffuse.
        /// Inner layers: tight (2–4pt). Outer layers: broad (8–16pt).
        let radius: CGFloat

        /// Always 0 for glow effects — glows radiate symmetrically.
        /// Non-zero x/y values produce directional shadows (elevation), not glows.
        let x: CGFloat
        let y: CGFloat

        init(color: Color, radius: CGFloat) {
            self.color  = color
            self.radius = radius
            self.x      = 0
            self.y      = 0
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Spectrum Border Glow
    //
    // The emissive glow applied to VaylButton's border arcs
    // when the press animation completes. Three chromatic
    // layers produce a concentrated inner edge with a
    // soft outer halo that reads as high-energy light.
    //
    // Applied to: VaylBorderEffect arc strokes
    // Trigger: glowIntensity > 0
    // Animation: AppAnimation.borderGlowIn / borderGlowOut
    // ─────────────────────────────────────────────

    enum spectrumBorder {

        /// Tight inner core — cyan channel.
        /// Highest opacity, smallest radius.
        /// Gives the border stroke a sharp luminous edge.
        static let inner = GlowLayer(
            color:  AppColors.spectrumCyan.opacity(0.90),
            radius: 3
        )

        /// Mid halo — purple channel.
        /// Bridges inner and outer — produces the chromatic
        /// spread that reads as refracted spectrum light.
        static let mid = GlowLayer(
            color:  AppColors.spectrumPurple.opacity(0.65),
            radius: 8
        )

        /// Broad outer atmosphere — magenta channel.
        /// The softest, most diffuse layer.
        /// Gives the button an ambient emissive presence
        /// that extends visibly beyond the border itself.
        static let outer = GlowLayer(
            color:  AppColors.spectrumMagenta.opacity(0.40),
            radius: 16
        )

        /// All three layers in application order (inner → outer).
        static let layers: [GlowLayer] = [inner, mid, outer]

        // ─── Stroke geometry ───────────────────────────────
        // Stroke weights are part of the glow specification.
        // All three states are defined here so they are never
        // changed independently and drift apart.
        //
        // These values are intentionally heavier than a typical
        // UI border — VaylButton's border is a design centrepiece,
        // not a structural edge. It needs presence.

        /// 1.2pt — Resting hairline in the inactive state.
        /// True hairline — present but quiet.
        static let strokeResting:  CGFloat = 1.2

        /// 1.8pt — Active fill stroke during arc draw-on.
        /// Marginally heavier than resting — the energy reads as
        /// luminosity from the glow, not physical stroke weight.
        static let strokeActive:   CGFloat = 2.2

        /// 2.0pt — Glowing stroke at full glow intensity.
        /// Minimal additional weight — the glow layer creates the
        /// perception of thickness. The stroke itself stays contained.
        static let strokeGlowing:  CGFloat = 2.8

        // ─── Hairline geometry ─────────────────────────────
        // The resting-state hairline is a separate visual element
        // from the arc strokes. It is a gradient strip, not a
        // Shape stroke, so its thickness is a frame height value
        // rather than a lineWidth.

        /// 1.8pt — Hairline strip height in the resting state.
        static let hairlineHeight: CGFloat = 1.8

        // ─── Hairline opacity ──────────────────────────────

        /// 1.0 — Hairline opacity in the resting state.
        static let hairlineOpacity: Double = 1.0
    }

    // ─────────────────────────────────────────────
    // MARK: Corner Deck Glow
    //
    // Pulsed by CornerDeckView when a card lands in
    // the corner deck. Migrated from AppElevation.
    //
    // Applied to: CornerDeckView
    // Trigger: card received event
    // Animation: AppAnimation.deckReceive, fades after 600ms
    // ─────────────────────────────────────────────

    enum cornerDeck {

        /// Spectrum purple at 30% — communicates receipt
        /// without competing with the mini-card content.
        static let color: Color = AppColors.spectrumPurple.opacity(0.30)

        /// 12pt — Tight radius so the glow reads as emanating
        /// from the mini-card stack, not the screen corner.
        static let radius: CGFloat = 12
    }

    // ─────────────────────────────────────────────
    // MARK: Card Breathe Glow
    //
    // The ambient emissive glow on a stationary OB card
    // while it awaits user input.
    //
    // Applied to: VaylCardRenderer in stationary states
    // Animation: AppAnimation.cardBreathe (ambient, repeat)
    // Reduce motion: remove entirely
    // ─────────────────────────────────────────────

    enum cardBreathe {

        static let color:  Color   = AppColors.spectrumPurple.opacity(0.22)
        static let radius: CGFloat = 18
    }

    // ─────────────────────────────────────────────
    // MARK: Accent Focus Glow
    //
    // Applied to focused input fields and selected states.
    //
    // Applied to: VaylTextField focus ring, selected pills
    // Trigger: focus / selection state
    // ─────────────────────────────────────────────

    enum accentFocus {

        static let inner = GlowLayer(
            color:  AppColors.accentPrimary.opacity(0.50),
            radius: 3
        )

        static let outer = GlowLayer(
            color:  AppColors.accentPrimary.opacity(0.18),
            radius: 10
        )

        static let layers: [GlowLayer] = [inner, outer]
    }

    // ─────────────────────────────────────────────
    // MARK: Lift Copy Glow
    //
    // Tight emissive glow on the gradient text that appears
    // above the table when a card is lifted in ModeSelectPhase.
    // Two layers — inner core hugs the letterforms,
    // outer is a soft falloff. Never a broad radial bloom.
    //
    // Applied to: ModeSelectPhase liftCopyLayer VStack
    // Trigger: card lift state
    // ─────────────────────────────────────────────

    enum liftCopy {

        /// Tight inner core — cyan channel.
        /// Hugs letterforms. Reads as text emitting light.
        static let inner = GlowLayer(
            color:  AppColors.spectrumCyan.opacity(0.18),
            radius: 2
        )

        /// Soft outer falloff — purple channel.
        /// Feathers the glow edge without creating a halo box.
        static let outer = GlowLayer(
            color:  AppColors.spectrumPurple.opacity(0.08),
            radius: 5
        )

        static let layers: [GlowLayer] = [inner, outer]
    }

    // ─────────────────────────────────────────────
    // MARK: Safety Glow
    //
    // Reserved exclusively for safe word and warning surfaces.
    // Same constraints as AppColors.safetyAccent — never
    // use for decorative or ambient purposes.
    //
    // Applied to: SafeWordButton, hard-stop confirmation UI
    // ─────────────────────────────────────────────

    enum safety {

        static let inner = GlowLayer(
            color:  AppColors.safetyAccent.opacity(0.45),
            radius: 4
        )

        static let outer = GlowLayer(
            color:  AppColors.safetyAccent.opacity(0.20),
            radius: 12
        )

        static let layers: [GlowLayer] = [inner, outer]
    }

    // ─────────────────────────────────────────────
    // MARK: Compass Star Glow
    //
    // Soft radial glow drawn behind the compass star
    // on the OB table surface. Simulates ambient light
    // scattering from an overhead point source onto the felt.
    //
    // Applied to: TableSurfaceView compass star layer
    // Not animated — static rendering constant
    // ─────────────────────────────────────────────

    enum compassStarGlow {
        /// Base color sourced from the compass star token.
        /// Opacity 0.14 — present as atmosphere, not as a visible halo.
        static let color: Color              = AppColors.tableCompassStar.opacity(0.14)
        /// Caller computes starSize × radiusMultiplier for the actual radius.
        static let radiusMultiplier: CGFloat = 2.2
    }

    // ─────────────────────────────────────────────
    // MARK: Table Rim Inner Glow
    //
    // Radial glow that sits behind the spectrum rim arc
    // on the OB table surface. Gives the rim the appearance
    // of an emissive light source rather than a painted line.
    //
    // Applied to: TableSurfaceView spectrum rim layer
    // inner radius: tableR - innerInset
    // outer radius: tableR + outerInset
    // peak stop position: peakPosition
    // ─────────────────────────────────────────────

    enum tableRimInnerGlow {
        /// Purple at 10% — suggests refracted light bleeding inward from the rim.
        static let color: Color          = AppColors.spectrumPurple.opacity(0.10)
        static let innerInset: CGFloat   = 28
        static let outerInset: CGFloat   = 6
        static let peakPosition: CGFloat = 0.55
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: View Extension — Glow Application
//
// Never call .shadow() directly for glow effects.
// Always use these modifiers so that glow tokens are
// the single point of change when values are updated.
// ─────────────────────────────────────────────────────────────

extension View {

    /// Applies a spectrum border glow using an opacity multiplier.
    ///
    /// Use a Double multiplier (0.0–1.0) rather than toggling
    /// between a color and .clear. Animating to/from .clear
    /// interpolates through a desaturated gray phase — the
    /// multiplier keeps all intermediate values fully chromatic.
    ///
    ///   arcView.spectrumBorderGlow(intensity: glowIntensity)
    ///
    ///   withAnimation(AppAnimation.borderGlowIn)  { glowIntensity = 1.0 }
    ///   withAnimation(AppAnimation.borderGlowOut) { glowIntensity = 0.0 }
    func spectrumBorderGlow(intensity: Double) -> some View {
        let layers = AppGlows.spectrumBorder.layers
        return self
            .shadow(
                color:  layers[0].color.opacity(intensity),
                radius: layers[0].radius,
                x:      layers[0].x,
                y:      layers[0].y
            )
            .shadow(
                color:  layers[1].color.opacity(intensity),
                radius: layers[1].radius,
                x:      layers[1].x,
                y:      layers[1].y
            )
            .shadow(
                color:  layers[2].color.opacity(intensity),
                radius: layers[2].radius,
                x:      layers[2].x,
                y:      layers[2].y
            )
    }

    /// Applies a corner deck receive glow.
    func cornerDeckGlow(visible: Bool) -> some View {
        self.shadow(
            color:  visible
                ? AppGlows.cornerDeck.color
                : .clear,
            radius: AppGlows.cornerDeck.radius,
            x: 0,
            y: 0
        )
    }

    /// Applies an accent focus glow for input fields and selected pills.
    func accentFocusGlow(visible: Bool) -> some View {
        let layers = AppGlows.accentFocus.layers
        return self
            .shadow(
                color:  visible ? layers[0].color : .clear,
                radius: layers[0].radius,
                x:      layers[0].x,
                y:      layers[0].y
            )
            .shadow(
                color:  visible ? layers[1].color : .clear,
                radius: layers[1].radius,
                x:      layers[1].x,
                y:      layers[1].y
            )
    }

    /// Applies a safety glow for safe word and warning surfaces.
    func safetyGlow(visible: Bool) -> some View {
        let layers = AppGlows.safety.layers
        return self
            .shadow(
                color:  visible ? layers[0].color : .clear,
                radius: layers[0].radius,
                x:      layers[0].x,
                y:      layers[0].y
            )
            .shadow(
                color:  visible ? layers[1].color : .clear,
                radius: layers[1].radius,
                x:      layers[1].x,
                y:      layers[1].y
            )
    }

    /// Applies the lift copy text glow.
    /// Use on the VStack in ModeSelectPhase.liftCopyLayer only.
    func liftCopyGlow() -> some View {
        let layers = AppGlows.liftCopy.layers
        return self
            .shadow(
                color:  layers[0].color,
                radius: layers[0].radius,
                x:      layers[0].x,
                y:      layers[0].y
            )
            .shadow(
                color:  layers[1].color,
                radius: layers[1].radius,
                x:      layers[1].x,
                y:      layers[1].y
            )
    }
}

```

---

## File: `Vayl/App/Theme/AppGrid.swift` {#file-vayl-app-theme-appgrid-swift}

```swift
//
//  AppGrid.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//


//
//  AppGrid.swift
//  Vayl
//
//  Design System — Phase 2.3
//
//  Grid constants for consistent content layout across the app.
//  All values derive from AppLayout and AppSpacing — nothing is hardcoded.
//
//  Rules:
//  - Never use a raw CGFloat for column count, gutter width, or content width.
//  - All width calculations go through AppLayout — never UIScreen.
//  - These constants describe layout geometry only. Component-level spacing
//    (internal padding, icon gaps, label offsets) still uses AppSpacing directly.
//
//  Usage:
//      GeometryReader { geo in
//          let layout = AppLayout.from(geo)
//          let grid   = AppGrid(layout: layout)
//          LazyVGrid(columns: grid.twoColumnGrid) { ... }
//      }

import SwiftUI

struct AppGrid {

    // MARK: - Init

    private let layout: AppLayout

    init(layout: AppLayout) {
        self.layout = layout
    }

    // MARK: - Gutter

    /// Standard gutter between columns and between a column and the screen edge.
    /// Always AppSpacing.md — 16pt.
    var gutter: CGFloat {
        AppSpacing.md
    }

    // MARK: - Column Widths

    /// Full single-column content width.
    /// Equal to AppLayout.cardWidth — screenWidth minus two AppSpacing.lg margins.
    /// Use for cards, form fields, and any full-width single-column content.
    var singleColumn: CGFloat {
        layout.cardWidth
    }

    /// Width of one column in a symmetric two-column layout.
    /// Derived from cardWidth minus one internal gutter, divided by two.
    /// Use for paired cards, category tiles, and two-up grids.
    var twoColumnItem: CGFloat {
        (layout.cardWidth - gutter) / 2
    }

    /// Width of one column in a symmetric three-column layout.
    /// Derived from cardWidth minus two internal gutters, divided by three.
    /// Use for icon grids, tag rows, and compact three-up layouts.
    var threeColumnItem: CGFloat {
        (layout.cardWidth - (gutter * 2)) / 3
    }

    // MARK: - SwiftUI GridItem Arrays

    /// Single adaptive column filling the full content width.
    /// Use with LazyVGrid for single-column scrolling lists.
    var singleColumnGrid: [GridItem] {
        [GridItem(.flexible(), spacing: 0)]
    }

    /// Two fixed-width columns with a standard gutter.
    /// Use for paired card layouts and two-up grids.
    var twoColumnGrid: [GridItem] {
        [
            GridItem(.fixed(twoColumnItem), spacing: gutter),
            GridItem(.fixed(twoColumnItem), spacing: 0)
        ]
    }

    /// Three fixed-width columns with standard gutters.
    /// Use for icon grids and compact three-up layouts.
    var threeColumnGrid: [GridItem] {
        [
            GridItem(.fixed(threeColumnItem), spacing: gutter),
            GridItem(.fixed(threeColumnItem), spacing: gutter),
            GridItem(.fixed(threeColumnItem), spacing: 0)
        ]
    }

    // MARK: - Vertical Section Spacing

    /// Standard vertical spacing between major content sections on a screen.
    /// Always AppSpacing.xl — 32pt.
    var sectionSpacing: CGFloat {
        AppSpacing.xl
    }

    /// Standard vertical spacing between items within a section.
    /// Always AppSpacing.md — 16pt.
    var itemSpacing: CGFloat {
        AppSpacing.md
    }

    /// Compact vertical spacing for dense lists and tight stacks.
    /// Always AppSpacing.sm — 8pt.
    var compactSpacing: CGFloat {
        AppSpacing.sm
    }
}
```

---

## File: `Vayl/App/Theme/AppLayout.swift` {#file-vayl-app-theme-applayout-swift}

```swift
//
//  AppLayout.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//


//
//  AppLayout.swift
//  Vayl
//
//  Design System — Phase 2.1
//
//  AppLayout resolves real screen geometry from a GeometryProxy and exposes
//  derived layout values used throughout the app. This is the single source
//  of truth for screen dimensions, device-class breakpoints, and safe area insets.
//
//  Usage — at the root of any screen-level view:
//
//      GeometryReader { geo in
//          let layout = AppLayout.from(geo)
//          YourView(layout: layout)
//      }
//
//  Rules:
//  - UIScreen.main.bounds is banned. Always use AppLayout.from(geometry).
//  - Never hardcode width, height, or safe-area offsets for layout purposes.
//  - Never hardcode .padding(.top, 60) or .padding(.bottom, 34) to clear
//    hardware elements — use layout.safeAreaInsets.top / .bottom instead.
//  - cardWidth, fullWidth, and contentMaxWidth are the only permitted width
//    values in layout code. Never derive your own from screenWidth directly.
//  - isSmallDevice and isLargeDevice drive conditional layout — never branch
//    on hardcoded point values in views.

import SwiftUI

struct AppLayout {

    // MARK: - Screen Dimensions

    /// Full screen width resolved from GeometryProxy. Never hardcode this value.
    let screenWidth: CGFloat

    /// Full screen height resolved from GeometryProxy. Never hardcode this value.
    let screenHeight: CGFloat

    // MARK: - Safe Area Insets

    /// Safe area insets resolved from GeometryProxy.
    /// Accounts for the Dynamic Island, notch, status bar, and home indicator
    /// on every device without hardcoding any pixel values.
    ///
    /// - `safeAreaInsets.top`    — clears the Dynamic Island, notch, or status bar.
    /// - `safeAreaInsets.bottom` — clears the home indicator on notchless devices.
    ///
    /// Use these wherever the violation catalogue shows .top, 60 or .bottom, 100
    /// or .bottom, 34 used as hardware-clearance proxies.
    let safeAreaInsets: EdgeInsets

    // MARK: - Device Class

    /// True for iPhone SE and iPhone mini form factors — screen width at or below 375pt.
    /// Use to apply compact layout adjustments, never to gate features.
    let isSmallDevice: Bool

    /// True for iPhone Pro Max and Plus form factors — screen width at or above 428pt.
    /// Use to apply expanded layout where additional breathing room is available.
    let isLargeDevice: Bool

    // MARK: - Derived Layout Values

    /// Standard content width with symmetric horizontal margins.
    /// Equal to screenWidth minus two AppSpacing.lg margins (24pt each side).
    /// Use for cards, form fields, and single-column content blocks.
    var cardWidth: CGFloat {
        screenWidth - (AppSpacing.lg * 2)
    }

    /// Full bleed width — equal to screenWidth.
    /// Use only for backgrounds, hero imagery, and tab bars that span edge to edge.
    /// All interactive content must remain within cardWidth or contentMaxWidth.
    var fullWidth: CGFloat {
        screenWidth
    }

    /// Maximum content width for readability on large screens.
    /// Clamps at 460pt so that text and form content never becomes uncomfortably
    /// wide on Pro Max devices. Use for body text containers and form layouts.
    var contentMaxWidth: CGFloat {
        min(screenWidth - (AppSpacing.lg * 2), 460)
    }

    // MARK: - Tab Bar

    /// Height of the visible UITabBar, read from the key window at call time.
    /// Returns 0 when no tab bar is present (onboarding, sheets, modals).
    /// Use with .bottomClearance(_:includesTabBar:) — do not read this value directly in views.
    var tabBarHeight: CGFloat {
        guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow })
        else { return 0 }
        return window.rootViewController?
            .view.subviews
            .first(where: { $0 is UITabBar })?
            .frame.height ?? 0
    }

    // MARK: - Factory

    /// Resolves an AppLayout from a GeometryProxy.
    /// Call this once at the root of a screen-level view and pass the result down.
    /// Never call UIScreen.main.bounds — this is the only permitted resolution path.
    static func from(_ geometry: GeometryProxy) -> AppLayout {
        let width = geometry.size.width
        return AppLayout(
            screenWidth:    width,
            screenHeight:   geometry.size.height,
            safeAreaInsets: geometry.safeAreaInsets,
            isSmallDevice:  width <= 375,
            isLargeDevice:  width >= 428
        )
    }

    // MARK: - Standard Screen Spacing
    // Referenced by the Screen Building Protocol and used across all main-app screens.
    // Do not override these values per-screen — if a screen needs more breathing room,
    // the layout design should be revisited, not the tokens.

    /// 18pt — Horizontal padding from screen edge to content.
    /// Applied to the outer ScrollView or VStack container of every screen.
    static let screenHPad: CGFloat = 18

    /// 24pt — Horizontal margin applied to the OB canvas content column.
    /// Wider than screenHPad (18pt) — the OB canvas uses a more spacious
    /// margin appropriate for cinematic phase layouts.
    static let screenMargin: CGFloat = 24

    /// 32pt — Horizontal inset for the primary CTA on OB screens.
    /// Intentionally wider than screenMargin so the CTA button sits visually
    /// inside the content column rather than spanning edge-to-edge.
    static let ctaHorizontalMargin: CGFloat = 32

    /// 20pt — Vertical padding at the top of every screen's scroll content.
    /// Provides breathing room below the header before the first card.
    static let screenVPad: CGFloat = 20

    /// 16pt — Horizontal padding inside a card, from card edge to card content.
    static let cardHPad: CGFloat = 16

    /// 14pt — Vertical padding inside a card, from card edge to card content.
    static let cardVPad: CGFloat = 14

    /// 10pt — Vertical gap between adjacent cards in a list or stack.
    static let cardGap: CGFloat = 10

    /// 24pt — Vertical gap between distinct sections on a screen.
    static let sectionGap: CGFloat = 24

    /// 13pt — Horizontal gap between an icon and its accompanying label in a row.
    static let rowGap: CGFloat = 13

    // MARK: - Standard Component Sizing

    /// 52pt — Height of a primary CTA button.
    static let ctaHeight: CGFloat = 52

    /// 32pt — Height of a filter pill or selection pill.
    static let pillHeight: CGFloat = 32

    /// 14pt — Horizontal padding inside a pill, from pill edge to label.
    static let pillHPad: CGFloat = 14

    /// 30pt — Tap area size for a ghost icon button (icon-only, no label).
    /// The visible icon may be smaller — this is the minimum hit target.
    static let iconBtnSize: CGFloat = 30

    /// 36pt — Width of the drag handle on a bottom sheet.
    static let dragHandleW: CGFloat = 36

    /// 4pt — Height of the drag handle on a bottom sheet.
    static let dragHandleH: CGFloat = 4

    /// 300pt — Maximum width of the expandable citation panel in StatPhase.
    /// Constrains the dense citation copy to a readable measure regardless of
    /// screen width. Matches the visual design at standard iPhone widths.
    static let citationPanelMaxWidth: CGFloat = 300

    // MARK: - OB Card Geometry
    // These values are exclusive to the Onboarding canvas.
    // They must never appear in main-app screens — the table metaphor
    // does not leave the OB boundary.
    //
    // All functions take screenWidth as a parameter because OB card geometry
    // is a function of screen width, not a fixed constant. Pass geo.size.width
    // from the GeometryReader in OnboardingCanvasView.

    /// Width of a full-size OB vertical card.
    /// Clamps at 320pt to preserve card proportions on Pro Max devices.
    /// Vertical cards are OB/personal only. Horizontal cards are session/shared.
    static func obCardWidth(in screenWidth: CGFloat) -> CGFloat {
        screenWidth * 1.14
    }

    /// Height of a full-size OB vertical card.
    /// Derived from obCardWidth at a fixed 3:2 portrait aspect ratio (×1.5).
    static func obCardHeight(in screenWidth: CGFloat) -> CGFloat {
        obCardWidth(in: screenWidth) * 1.5
    }
    /// Width of a card sitting on the OB table during the deal sequence.
    /// ~30% of screen width — small enough to read as a physical card on a surface.
    /// Distinct from obCardWidth (72%) which is used for the full-bleed expanded state.
    /// Never use obTableCardWidth for any state other than the on-table resting position.
    static func obTableCardWidth(in screenWidth: CGFloat) -> CGFloat {
        min(screenWidth * 0.30, 195)
    }

    /// Height of the on-table card. Derived from obTableCardWidth at 3:2 portrait ratio.
    static func obTableCardHeight(in screenWidth: CGFloat) -> CGFloat {
        obTableCardWidth(in: screenWidth) * 1.5
    }

    /// Cinematic zoom applied to the on-table card during the NamePhase deal sequence.
    /// Scales `obTableCardWidth` from 30% to ~45% of screen width, matching the HTML
    /// prototype's visual proportion (195px card in a 430px max-width container).
    /// Only NamePhase applies this. Do not use in other table card contexts.
    static let obTableCardCinematicScale: CGFloat = 1.5

    /// Width of a session card (horizontal orientation).
    /// Clamps at 480pt. Used in the main app session flow, never in OB.
    static func sessionCardWidth(in screenWidth: CGFloat) -> CGFloat {
        min(screenWidth * 0.88, 480)
    }

    /// Height of a session card (horizontal orientation).
    /// Derived from sessionCardWidth at a fixed aspect ratio (×0.708).
    static func sessionCardHeight(in screenWidth: CGFloat) -> CGFloat {
        sessionCardWidth(in: screenWidth) * 0.708
    }

    // MARK: - OB Corner Deck Geometry
    // The corner deck occupies the top-right corner of OnboardingCanvasView
    // from NamePhase onward. These constants define its frame and position.
    // The top-right ✦ mark is replaced by the corner deck — never overlap them.

    /// 48pt — Width of the corner deck mini-card stack.
    static let cornerDeckWidth:  CGFloat = 48

    /// 72pt — Height of the corner deck mini-card stack.
    static let cornerDeckHeight: CGFloat = 72

    /// 56pt — Distance from the top safe-area edge to the top of the corner deck.
    /// Sits just below the Dynamic Island with breathing room.
    /// Bump to 64 or 72 if it still reads too high on device.
    static let cornerDeckTop:    CGFloat = 56

    /// 24pt — Distance from the right screen edge to the right of the corner deck.
    static let cornerDeckRight:  CGFloat = 24

    // MARK: - OB Deal Point Geometry
    // The deal point is the origin from which all OB cards are launched.
    // Its position is derived from screen dimensions at render time —
    // these are the constants that define its appearance and vertical anchor.

    /// 22pt — Radius of the deal point glow ring.
    /// The center dot and outer haze scale from this value in DealPointView.
    static let dealPointRadius:  CGFloat = 22

    /// 0.32 — Vertical position of the deal point as a fraction of screen height.
    /// The deal point sits at the horizon where the felt meets the void.
    /// This fraction is shared with tableHorizonYFrac — they are the same anchor.
    static let dealPointYFrac:   CGFloat = 0.32

    // MARK: - OB Table Geometry

    /// 0.32 — Vertical position of the table horizon line as a fraction of screen height.
    /// The felt trapezoid's top edge, the deal point, and the projected text anchor
    /// all derive from this single fraction. Change this value to reposition the
    /// entire table world simultaneously.
    static let tableHorizonYFrac: CGFloat = 0.32

    /// 0.34 — Arc peak Y fraction for the circular table surface.
    /// Matches the HTML reference prototype where the table edge sits at H*0.34,
    /// giving the "zoomed in on the table" perspective the user wants.
    /// Distinct from tableHorizonYFrac (0.32) which is the trapezoid horizon.
    /// Used by TableSurfaceView arc geometry only.
    static let tableArcPeakYFrac: CGFloat = 0.34

    /// 1.05 — Table circle radius as a fraction of screen height.
    /// Large radius ensures only the top cap of the circle is visible.
    /// Used by TableSurfaceView arc geometry only.
    static let tableArcRadiusFrac: CGFloat = 1.05

    // MARK: - OB Card Landing Slots
    // Five predefined landing configurations for the OB deal sequence.
    // Cards pick from the available pool so no two cards in the same round
    // share a landing zone. Slots are defined in screen-fraction space so
    // they adapt to any device size.

    static let obCardLandingSlots: [CardLandingSlot] = [

        // Slot 0 — Center settle: classic deal, card rests just right of center
        CardLandingSlot(
            id: 0,
            xFrac: 0.50, yFrac: 0.535,
            angleDeg:  1.8,
            jitterX: 12, jitterY: 8, jitterAngle: 1.0
        ),

        // Slot 1 — Left lean: card drifts wide left, slight CCW tilt
        CardLandingSlot(
            id: 1,
            xFrac: 0.30, yFrac: 0.61,
            angleDeg: -6.0,
            jitterX: 12, jitterY: 8, jitterAngle: 1.5
        ),

        // Slot 2 — Deep slide: card overshoots toward the player, steep CW,
        // bottom third of card clips off-screen
        CardLandingSlot(
            id: 2,
            xFrac: 0.52, yFrac: 0.74,
            angleDeg:  13.0,
            jitterX: 14, jitterY: 10, jitterAngle: 2.0
        ),

        // Slot 3 — Hard right: card cuts right, steep CCW, right edge off-screen
        CardLandingSlot(
            id: 3,
            xFrac: 0.80, yFrac: 0.64,
            angleDeg: -19.0,
            jitterX: 12, jitterY: 8, jitterAngle: 2.0
        ),

        // Slot 4 — Bottom-left diagonal: card curves lower-left, partially off-screen
        CardLandingSlot(
            id: 4,
            xFrac: 0.24, yFrac: 0.70,
            angleDeg: -11.0,
            jitterX: 12, jitterY: 10, jitterAngle: 2.5
        ),
    ]

    /// Returns the Y coordinate of the optical center of the felt table surface.
    /// Derived from tableArcPeakYFrac — the fraction where the spectrum rim arc peaks.
    /// The table surface runs from that point to the bottom of the screen.
    /// Card center is the midpoint of that zone.
    /// Use this for every card resting position in the OB sequence.
    /// Never hardcode 0.55 or any raw Y fraction for card positioning.
    static func obTableCardCenterY(in screenHeight: CGFloat) -> CGFloat {
        let arcPeakY    = screenHeight * tableArcPeakYFrac
        let tableHeight = screenHeight - arcPeakY
        return arcPeakY + (tableHeight * 0.50)
    }

    // MARK: - OB NamePhase Layout Tokens
    // Exclusive to NamePhase. Never use in main-app screens.

    /// 80pt — Height of the swipe-to-submit zone above the name input field.
    static let swipeZoneHeight: CGFloat = 80

    /// 80pt — Translation threshold for a swipe-down to register as a submit gesture.
    static let swipeSubmitThreshold: CGFloat = 80

    /// 1.2 — Multiplier applied to screen height for the dragY exit translation on submit.
    /// Ensures the UI travels well past the screen bottom before disappearing.
    static let dragExitMultiplier: CGFloat = 1.2

    /// 30 — Maximum character count for a user-entered display name.
    static let maxNameLength: Int = 30

    /// 28pt — Blur radius applied to the card during the lift-toward-camera sequence.
    static let cardLiftBlurRadius: CGFloat = 28.0

    /// 4.5 — Scale multiplier for the card diving toward the camera during performLift.
    /// At 4.5× the card exceeds the screen width — the lens is inside the surface.
    static let cardLiftDiveMultiplier: CGFloat = 4.5

    /// 0.5pt — Letter-spacing applied to the user's name in the greeting display.
    static let nameLetterSpacing: CGFloat = 0.5

    // MARK: - OB Flourish Geometry
    // Exclusive to VaylFlourishView. Never use in main-app screens.

    /// 280pt — Width of the VaylFlourishView decorative component.
    static let flourishWidth: CGFloat = 280

    /// 72pt — Height of the VaylFlourishView decorative component.
    static let flourishHeight: CGFloat = 72

    /// 1.015 — Scale factor for the ambient breathing pulse on VaylFlourishView.
    static let flourishPulseScale: CGFloat = 1.015

    /// Visible position offset for the greeting row. Negative = moves up.
    /// Proportional to screen height for correct positioning across device sizes.
    static func greetingOffsetVisible(in screenHeight: CGFloat) -> CGFloat {
        -(screenHeight * 0.07)
    }

    /// Hidden/resting position offset for the greeting row.
    static func greetingOffsetHidden(in screenHeight: CGFloat) -> CGFloat {
        screenHeight * 0.017
    }
}

```

---

## File: `Vayl/App/Theme/AppRadius.swift` {#file-vayl-app-theme-appradius-swift}

```swift
//
//  AppRadius.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//


// App/Theme/AppRadius.swift

import CoreGraphics

/// Tier 2 — Semantic corner radius tokens.
/// Every `.cornerRadius()`, `.clipShape()`, or `RoundedRectangle(cornerRadius:)` call
/// in the codebase must reference one of these tokens.
/// Hardcoded numeric values in any corner radius context are a violation.
/// Nothing in this file may reference VaylPrimitives — radius has no primitive tier.
///
/// Grid note: Radius tokens use a 4pt grid. This is intentional and independent
/// of the 8pt spacing grid — radius granularity requirements are finer than spacing
/// requirements. The two grids do not need to be unified.
internal enum AppRadius {

    /// 2pt — Drag handle pills and fine decorative dividers.
    /// Use for drag handle capsules, hairline divider end-caps, and sub-pixel decorative rounding.
    /// Never use for interactive elements, cards, or any tappable surface.
    static let micro: CGFloat = 2

    /// 8pt — Small interactive chips, tags, and badge labels.
    /// Use for pills that display metadata (counts, status tags) and small category chips.
    /// Never use for primary buttons, cards, or any surface larger than a label container.
    static let sm: CGFloat = 8

    /// 12pt — Input fields and secondary buttons.
    /// Use for text input containers, secondary action buttons, and segmented control backgrounds.
    /// Never use for primary CTAs, cards, or modal surfaces.
    static let md: CGFloat = 12

    /// 16pt — Cards and primary action buttons.
    /// Use for all content cards regardless of elevation level, and for the HoloCTAButton.
    /// Never use for modals, sheets, or surfaces larger than a card.
    static let lg: CGFloat = 16

    /// 24pt — Modals, sheets, and large overlay surfaces.
    /// Use for bottom sheets, full-screen overlays presented over content, and large surface containers.
    /// Never use for cards or buttons — this radius is reserved for surfaces that sit above cards.
    static let xl: CGFloat = 24

    /// 20pt — Onboarding cards, home widgets, and pairing surfaces.
    /// Use for the dominant off-grid card radius seen across onboarding and home feature surfaces.
    /// Distinct from lg (16pt cards) and xl (24pt modals) — sits between them for hero containers.
    static let container: CGFloat = 20

    /// Infinity — Fully rounded capsule shape.
    /// Use for selectable pills, toggle tracks, and any element that must render as a perfect capsule.
    /// SwiftUI mathematically clamps .infinity to perfectly round the shortest edge.
    /// Never use for cards, buttons, inputs, or any rectangular surface.
    static let pill: CGFloat = .infinity

    // MARK: - OB Card Radii
    // These tokens are exclusive to the Onboarding canvas and its card components.
    // They must never appear in main-app screens — the table metaphor does not
    // leave the OB boundary.

    /// 14pt — Full-size OB vertical card.
    /// Applied to VaylCardBack, VaylCardFace, and VaylCardRenderer frame clips.
    /// Distinct from lg (16pt) — the slightly tighter radius reads as a playing card,
    /// not a UI card. Do not substitute lg here.
    /// Vertical cards are OB/personal only. This token never appears on session cards.
    static let obCard: CGFloat = 14

    /// 4pt — Corner deck mini-card stack.
    /// Applied to the scaled-down card representations in CornerDeckView.
    /// At the rendered scale of the corner deck (~22% of full card size), 4pt
    /// produces the correct visual proportion of the obCard radius.
    /// Never use for full-size cards.
    static let cornerCard: CGFloat = 4

    /// 16pt — Foil wrapper overlay in FoilPhase.
    /// Applied to FoilRenderer as it wraps the assembled deck.
    /// Matches lg intentionally — the foil sits over the deck surface and its
    /// edge radius must align with the card stack beneath it.
    static let foilEdge: CGFloat = 16
}

```

---

## File: `Vayl/App/Theme/AppRootView.swift` {#file-vayl-app-theme-approotview-swift}

```swift
import SwiftUI

#if DEBUG
/// Set to true to always route to OnboardingCanvasView on launch.
/// Flip to false to restore normal auth/onboarding routing.
private let forceOnboarding = true
#endif

// ─────────────────────────────────────────────────────────────
// AppRootView — top-level routing gate.
//
// Responsibilities:
//   1. Show SplashScreenView once per cold launch.
//      Suppressed on foreground resume from background —
//      scenePhase gate sets splashDone = true when the app
//      moves to background so the next foreground is treated
//      as a resume, not a cold launch.
//   2. After splash, route to auth or onboarding based on
//      persistent state read from UserDefaults / AuthService.
//
// Does NOT own app-level stores — those live in VaylApp and
// flow down via environment. This view only reads environment
// values it needs for routing decisions.
// ─────────────────────────────────────────────────────────────

struct AppRootView: View {

    // MARK: - Environment

    @Environment(AuthService.self) private var authService
    @Environment(\.scenePhase)     private var scenePhase

    // MARK: - State

    @State private var splashDone = false

    // MARK: - Routing

    @ViewBuilder
    private var postSplashDestination: some View {
        #if DEBUG
        if forceOnboarding {
            OnboardingCanvasWrapper()
                .themedRoot()
        } else {
            routedDestination
        }
        #else
        routedDestination
        #endif
    }

    @ViewBuilder
    private var routedDestination: some View {
        if authService.isAuthenticated {
            AppShell()
                .themedRoot()
        } else if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            SignInView(authService: authService)
                .themedRoot()
        } else {
            OnboardingCanvasWrapper()
                .themedRoot()
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if !splashDone {
                SplashScreenView(
                    onComplete:  { splashDone = true },
                    onTearBegan: {},
                    destination: AnyView(postSplashDestination)
                )
            } else {
                postSplashDestination
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // App moved to background — next foreground is a resume, not a cold
            // launch. Mark splash done so it does not replay on return.
            if newPhase == .background {
                splashDone = true
            }
        }
    }
}

```

---

## File: `Vayl/App/Theme/AppSafeArea.swift` {#file-vayl-app-theme-appsafearea-swift}

```swift
//  AppSafeArea.swift
//  Vayl
//
//  Design System — Phase 2.2
//
//  Safe area helpers built on top of AppLayout. These replace every hardcoded
//  top and bottom padding value that was being used as a hardware-clearance proxy.
//
//  The two patterns this file solves:
//
//  1. Sticky bottom CTAs — buttons that sit above the home indicator without
//     overlapping it. Always use .stickyBottomCTA() on the containing view,
//     never .padding(.bottom, 34) or .padding(.bottom, 100).
//
//  2. Content top clearance — clearing the Dynamic Island, notch, or status
//     bar when a view intentionally extends behind the system chrome.
//     Always use .topClearance(layout:) rather than .padding(.top, 60).
//
//  Rules:
//  - Never hardcode .padding(.top, 60), .padding(.top, 120), .padding(.bottom, 34),
//    or .padding(.bottom, 100) as hardware-clearance proxies anywhere in the app.
//  - .safeAreaInset(edge:) is the correct SwiftUI primitive — use it here and
//    nowhere else. Call sites use the named modifiers below, never the primitive.
//  - .bottomContentInset(_:) must never be used on a scroll view that also has
//    .stickyBottomCTA — .stickyBottomCTA automatically adjusts the scroll inset.
//    Double-applying will produce double bottom padding.
//  - AppLayout must be resolved at the screen root before any of these helpers
//    are called. Do not instantiate AppLayout inside a helper.

import SwiftUI

// MARK: - Sticky Bottom CTA

extension View {

    /// Attaches a sticky bottom CTA to the view, sitting flush above the home
    /// indicator or bottom of screen using real safe area geometry.
    ///
    /// This replaces every instance of .padding(.bottom, 100) and
    /// .padding(.bottom, 34) used as tab-bar or home-indicator proxies.
    ///
    /// Usage:
    ///     ScrollView {
    ///         content
    ///     }
    ///     .stickyBottomCTA {
    ///         VaylButton("Continue") { ... }
    ///     }
    ///
    /// The spacing between the CTA and the home indicator is AppSpacing.md (16pt).
    /// The CTA itself is not padded — callers control internal button padding.
    ///
    /// Do NOT combine with .bottomContentInset(_:) on the same scroll view.
    /// .safeAreaInset automatically adjusts the scroll view's content inset —
    /// adding .bottomContentInset on top will double-pad the bottom.
    func stickyBottomCTA<CTA: View>(@ViewBuilder cta: () -> CTA) -> some View {
        self.safeAreaInset(edge: .bottom, spacing: 0) {
            cta()
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
                // ignoresSafeAreaEdges: .bottom forces the material to bleed
                // to the physical bezel — without this the frosted glass clips
                // at the safe area boundary leaving a transparent gap.
                .background(.ultraThinMaterial, ignoresSafeAreaEdges: .bottom)
        }
    }

    /// Adds bottom padding equal to the real home indicator inset plus a
    /// standard content gap. Use on scroll content that must not be occluded
    /// by a tab bar or the home indicator.
    ///
    /// This replaces .padding(.bottom, 100) used as a tab-bar-height proxy
    /// in HomeDashboardView and HomeRouterView.
    ///
    /// ONLY use on scroll views that do NOT have .stickyBottomCTA attached.
    /// .stickyBottomCTA handles scroll inset automatically via .safeAreaInset.
    func bottomContentInset(_ layout: AppLayout) -> some View {
        self.padding(.bottom, layout.safeAreaInsets.bottom + AppSpacing.xl)
    }

    /// Bottom content inset including optional tab bar height.
    /// Use for floating elements and overlay content that must clear both the home
    /// indicator and, optionally, a visible tab bar.
    ///
    /// Usage:
    ///   .bottomClearance(layout)                          // home indicator + AppSpacing.xl
    ///   .bottomClearance(layout, includesTabBar: true)    // home indicator + tab bar + AppSpacing.xl
    ///
    /// Do NOT combine with .stickyBottomCTA or .bottomContentInset on the same scroll view.
    func bottomClearance(_ layout: AppLayout, includesTabBar: Bool = false) -> some View {
        let extra = includesTabBar ? layout.tabBarHeight : 0
        return self.padding(.bottom, layout.safeAreaInsets.bottom + AppSpacing.xl + extra)
    }

    /// Adds top padding equal to the real Dynamic Island or notch inset plus
    /// an optional additional padding value (defaults to AppSpacing.md).
    /// Use on content that sits directly below the system chrome without a navigation bar.
    ///
    /// Usage:
    ///   .topClearance(layout)                         // clearance + AppSpacing.md
    ///   .topClearance(layout, padding: AppSpacing.lg) // clearance + custom breathing room
    ///   .topClearance(layout, padding: 0)             // bare clearance only
    ///
    /// This replaces .padding(.top, 60) and .padding(.top, 120) used as
    /// safe-area proxies in HomeDashboardView, GravLiftView, PulseFullView,
    /// and RacetrackTabBar.
    func topClearance(_ layout: AppLayout, padding: CGFloat = AppSpacing.md) -> some View {
        self.padding(.top, layout.safeAreaInsets.top + padding)
    }
}

// MARK: - Safe Area Values

extension AppLayout {

    /// The minimum bottom padding required to clear the home indicator.
    /// Zero on devices without a home indicator (iPhone SE 1st gen, iPad with
    /// home button). Use this when you need the raw inset value rather than
    /// a view modifier.
    var homeIndicatorInset: CGFloat {
        safeAreaInsets.bottom
    }

    /// The minimum top padding required to clear the Dynamic Island, notch,
    /// or status bar. Use this when you need the raw inset value rather than
    /// a view modifier.
    var topHardwareInset: CGFloat {
        safeAreaInsets.top
    }

    /// True when the device has a home indicator rather than a home button —
    /// i.e. the bottom safe area inset is greater than zero.
    /// Use to conditionally apply extra bottom breathing room on notchless devices.
    var hasHomeIndicator: Bool {
        safeAreaInsets.bottom > 0
    }

    /// True when the device has a Dynamic Island or notch —
    /// i.e. the top safe area inset is greater than the status bar height.
    /// 20pt is the standard status bar height on non-notched devices.
    var hasNotchOrIsland: Bool {
        safeAreaInsets.top > 20
    }
}

// MARK: - Real Safe Area Environment Key
//
// Captures the real hardware safe area before it is consumed by .ignoresSafeArea()
// ancestor chains. Injected by OnboardingCanvasWrapper; read in all phase views
// via @Environment(\.realSafeArea).
//
// Default value is EdgeInsets() so standalone phase previews (which have no wrapper)
// receive zero insets — correct because those previews place the phase GR *inside*
// the safe area region, so no inset compensation is needed.

private struct RealSafeAreaKey: EnvironmentKey {
    static let defaultValue = EdgeInsets()
}

extension EnvironmentValues {
    var realSafeArea: EdgeInsets {
        get { self[RealSafeAreaKey.self] }
        set { self[RealSafeAreaKey.self] = newValue }
    }
}

```

---

## File: `Vayl/App/Theme/AppSpacing.swift` {#file-vayl-app-theme-appspacing-swift}

```swift
//
//  AppSpacing.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//


// App/Theme/AppSpacing.swift

import CoreGraphics

/// Tier 2 — Semantic spacing tokens.
/// Every padding, gap, and spacing value in the codebase must reference one of these.
/// Hardcoded numeric values in `.padding()`, `.spacing()`, or `.offset()` are a violation.
/// Nothing in this file may be referenced from VaylPrimitives — spacing has no primitive tier.
internal enum AppSpacing {

    /// 2pt — Micro-adjustments only.
    /// Use for drag handle gaps, dot separators, and sub-pixel optical corrections.
    /// Never use as a structural gap or content spacing value.
    static let xxs: CGFloat = 2

    /// 4pt — Tight internal gaps only.
    /// Use between an icon and its adjacent label, or between two tightly coupled inline elements.
    /// Never use as a structural margin or between independent content blocks.
    static let xs: CGFloat = 4

    /// 8pt — Compact vertical or horizontal gaps between related elements.
    /// Use between a title and its subtitle, between stacked labels in a card, or inside a pill's internal padding.
    /// Never use as a screen-edge margin or between independent sections.
    static let sm: CGFloat = 8

    /// 16pt — Default structural gap and card-edge padding.
    /// Use as the standard horizontal padding inside cards, the gap between form fields,
    /// and the vertical spacing between related content groups within a section.
    static let md: CGFloat = 16

    /// 24pt — Section separation and screen-edge horizontal margin.
    /// Use as the leading and trailing margin from screen edges to content,
    /// and as the vertical gap between independent sections on a screen.
    static let lg: CGFloat = 24

    /// 32pt — Bottom padding above sticky or bottom-anchored CTAs.
    /// Use to create breathing room between the last content element and a fixed bottom button.
    /// Also use as generous internal vertical padding on tall modal surfaces.
    static let xl: CGFloat = 32

    /// 48pt — Hero and top-of-screen breathing room.
    /// Use as the top padding above a screen's primary headline, and as the vertical gap
    /// between major structural breaks such as a hero block and the first content section.
    static let xxl: CGFloat = 48
}
```

---

## File: `Vayl/App/Theme/AppTheme.swift` {#file-vayl-app-theme-apptheme-swift}

```swift
//
//  AppTheme.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

// MARK: - Theme Mode

enum ThemeMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}

// MARK: - Color Palette

struct AppPalette {
    let bg: Color
    let bgElevated: Color
    let surface1: Color
    let surface2: Color
    let surface3: Color

    let border: Color
    let borderSubtle: Color

    let text: Color
    let textSecondary: Color
    let textMuted: Color

    let success: Color
    let successDim: Color
    let error: Color
    let errorDim: Color

    /// UI accent — links, active states, highlights
    let cyan: Color
    /// UI accent — CTAs, emphasis, warnings
    let magenta: Color
    /// Decorative only — spectrum bar, score ring, flag swatch
    let navy: Color
    let gold: Color

    let glowOpacity: Double
    let glowCyan: Color
    let glowMagenta: Color
    let glowGold: Color

    let isDark: Bool
}

// MARK: - Computed Gradients

extension AppPalette {
    /// Spectrum bar: cyan -> magenta -> navy (decorative)
    var spectrumGradient: LinearGradient {
        LinearGradient(
            colors: [cyan, magenta, navy],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Primary CTA: cyan -> magenta (no navy)
    var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [cyan, magenta],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Score ring: full 3-color polyam sweep (decorative)
    var ringGradient: AngularGradient {
        AngularGradient(
            colors: [cyan, magenta, navy, cyan],
            center: .center
        )
    }

    /// Card border — hairline white on dark, warm gray on light
    var cardBorder: Color {
        isDark ? .white.opacity(0.08) : border
    }
}

// MARK: - Light Palette

extension AppPalette {
    static let light = AppPalette(
        bg:            Color(hex: "F8F7F4"),
        bgElevated:    .white,
        surface1:      .white,
        surface2:      Color(hex: "F3F1ED"),
        surface3:      Color(hex: "E8E5DF"),
        border:        Color(hex: "E0DDD6"),
        borderSubtle:  Color(hex: "EAE7E1"),
        text:          Color(hex: "1A1918"),
        textSecondary: Color(hex: "5C5955"),
        textMuted:     Color(hex: "9E9A92"),
        success:       Color(hex: "14B866"),
        successDim:    Color(hex: "14B866").opacity(0.1),
        error:         Color(hex: "DC4444"),
        errorDim:      Color(hex: "DC4444").opacity(0.1),
        cyan:          Color(hex: "0891B2"),
        magenta:       Color(hex: "BE185D"),
        navy:          Color(hex: "1A3A8F"),
        gold:          Color(hex: "B8860B"),
        glowOpacity:   0.06,
        glowCyan:      Color(hex: "0891B2").opacity(0.10),
        glowMagenta:   Color(hex: "BE185D").opacity(0.08),
        glowGold:      Color(hex: "B8860B").opacity(0.08),
        isDark:        false
    )
}

// MARK: - Dark Palette

extension AppPalette {
    static let dark = AppPalette(
        bg:            .black,
        bgElevated:    .black,
        surface1:      Color(hex: "0A0A10"),
        surface2:      Color(hex: "101018"),
        surface3:      Color(hex: "18181F"),
        border:        .white.opacity(0.08),
        borderSubtle:  .white.opacity(0.05),
        text:          Color(hex: "F4F3F9"),
        textSecondary: Color(hex: "8A88A0"),
        textMuted:     Color(hex: "4A485C"),
        success:       Color(hex: "5CE0A0"),
        successDim:    Color(hex: "5CE0A0").opacity(0.10),
        error:         Color(hex: "EF6B6B"),
        errorDim:      Color(hex: "EF6B6B").opacity(0.20),
        cyan:          Color(hex: "5ED0EE"),
        magenta:       Color(hex: "F472AD"),
        navy:          Color(hex: "9494D0"),
        gold:          Color(hex: "FFD700"),
        glowOpacity:   0.18,
        glowCyan:      Color(hex: "5ED0EE").opacity(0.20),
        glowMagenta:   Color(hex: "F472AD").opacity(0.20),
        glowGold:      Color(hex: "FFD700").opacity(0.20),
        isDark:        true
    )
}

```

---

## File: `Vayl/App/Theme/ThemeManager.swift` {#file-vayl-app-theme-thememanager-swift}

```swift
//
//  ThemeManager.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

@Observable
class ThemeManager {

    var mode: ThemeMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "appThemeMode")
        }
    }

    init() {
        var saved = UserDefaults.standard.string(forKey: "appThemeMode") ?? "dark"

        // Migrate legacy "amoled" value → "dark"
        if saved == "amoled" {
            saved = "dark"
            UserDefaults.standard.set("dark", forKey: "appThemeMode")
        }

        // Migrate stale "light" value when onboarding is not yet complete.
        // Light mode is unavailable in Act 1 — if "light" is stored and the
        // user has not finished onboarding, it leaked from a dev/test session.
        // Reset to "dark" so cold launch always starts with the Midnight palette.
        if saved == "light" && !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            saved = "dark"
            UserDefaults.standard.set("dark", forKey: "appThemeMode")
        }

        self.mode = ThemeMode(rawValue: saved) ?? .dark
    }

    func palette(for systemScheme: ColorScheme) -> AppPalette {
        switch mode {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return systemScheme == .dark ? .dark : .light
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch mode {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

// MARK: - Environment Key

private struct PaletteKey: EnvironmentKey {
    // .dark — any view outside .themedRoot() gets Midnight, not Dawn.
    // Previously .light caused unthemed routes (SignIn, OB) to render
    // the warm palette even on dark-mode devices.
    static let defaultValue: AppPalette = .dark
}

extension EnvironmentValues {
    var theme: AppPalette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

```

---

## File: `Vayl/App/Theme/ThemeModifiers.swift` {#file-vayl-app-theme-thememodifiers-swift}

```swift
//
//  ThemeModifiers.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

// MARK: - Root Modifier

struct ThemedRootModifier: ViewModifier {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var systemScheme

    func body(content: Content) -> some View {
        let palette = themeManager.palette(for: systemScheme)
        content
            .environment(\.theme, palette)
            .preferredColorScheme(themeManager.preferredColorScheme)
    }
}

extension View {
    func themedRoot() -> some View {
        modifier(ThemedRootModifier())
    }
}

// MARK: - Card Modifier

struct ThemedCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var selected: Bool = false

    func body(content: Content) -> some View {
        content
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(
                        selected ? AppColors.accentPrimary : AppColors.borderSubtle,
                        lineWidth: selected ? 2 : 1.5
                    )
            )
            .shadow(
                color: selected && colorScheme == .dark
                    ? AppColors.accentPrimary.opacity(0.20)
                    : .clear,
                radius: selected ? 8 : 0
            )
    }
}

extension View {
    func themedCard(selected: Bool = false) -> some View {
        modifier(ThemedCardModifier(selected: selected))
    }
}

// MARK: - Conditional Modifier

extension View {
    @ViewBuilder
    func `if`<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}


```

---

## File: `Vayl/App/Theme/VaylPrimitives.swift` {#file-vayl-app-theme-vaylprimitives-swift}

```swift
//
//  VaylPrimitives.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//


// App/Theme/VaylPrimitives.swift

import SwiftUI

// ─────────────────────────────────────────────────────────────
// Tier 1 — Raw color values.
//
// Rules:
//   • internal — not accessible outside the module accidentally
//   • Named for appearance, never purpose
//   • Never referenced in any view, component, or feature file
//   • The ONLY permitted consumer is AppColors.swift
//
// If you are reading this in a view file, that is a violation.
// ─────────────────────────────────────────────────────────────

enum VaylPrimitives {

    // ── Spectrum anchors ──────────────────────────────────────
    static let cyan           = UIColor(hex: "#00C2FF")
    static let cyanLight      = UIColor(hex: "#4DD8FF")
    static let cyanDark       = UIColor(hex: "#0891B2")

    static let purple         = UIColor(hex: "#6C3AE0")
    static let purpleLight    = UIColor(hex: "#A78BFA")
    static let purpleBright   = UIColor(hex: "#C084FC")
    static let purpleVivid    = UIColor(hex: "#9333EA")
    static let electricViolet = UIColor(hex: "#8B5CF6")
    static let spectrumBridge = UIColor(hex: "#8B6FD4") // mid-spectrum gradient bridge — cyan to magenta wordmark sweep

    static let magenta        = UIColor(hex: "#FF006A")
    static let magentaLight   = UIColor(hex: "#FF4D94")
    static let magentaDark    = UIColor(hex: "#BE185D")
    static let pink           = UIColor(hex: "#FF2D8A")

    static let deepBlue       = UIColor(hex: "#0078FF")

    // ── Neutrals — dark side ──────────────────────────────────
    static let inkBase        = UIColor(hex: "#030305")  // page floor
    static let inkCard        = UIColor(hex: "#12111A")  // card interior
    static let inkSurface     = UIColor(hex: "#1A1825")  // elevated surface
    static let inkRaised      = UIColor(hex: "#0C0C10")  // input fields
    static let inkWidget      = UIColor(hex: "#08060A")  // widget dark floor
    static let inkShimmerBase    = UIColor(hex: "#0D0B1A")                                          // holographic shimmer pill base — HolographicShimmer use only
    static let inkShimmerViolet  = UIColor(red: 140/255, green:  0/255, blue: 255/255, alpha: 1)  // deep violet orb — HolographicShimmer use only
    static let inkShimmerCyan    = UIColor(red:   0/255, green: 90/255, blue: 160/255, alpha: 1)  // dark muted cyan orb — HolographicShimmer use only
    static let inkShimmerPurple  = UIColor(red:  55/255, green: 20/255, blue: 130/255, alpha: 1)  // dark muted purple orb — HolographicShimmer use only
    static let inkShimmerMagenta = UIColor(red: 130/255, green: 10/255, blue:  80/255, alpha: 1)  // dark muted magenta orb — HolographicShimmer use only
    static let inkShimmerIndigo  = UIColor(red:  20/255, green: 30/255, blue: 110/255, alpha: 1)  // dark muted indigo orb — HolographicShimmer use only
    static let inkNodeCore    = UIColor(hex: "#0A0814")  // constellation node core
    static let inkAppIcon     = UIColor(hex: "#090B17")

    // ── OB canvas darks ───────────────────────────────────────
    // Distinct from the main-app ink scale.
    // inkVoid is the absolute floor of the OB canvas — slightly warmer/cooler
    // than inkBase to give the table world its own atmospheric identity.
    // inkCardOB is the OB card glass surface — not interchangeable with inkCard.
    // Light-mode equivalents are placeholders until OB Dawn is designed.
    static let inkVoid        = UIColor(hex: "#0a0810")  // OB canvas void floor
    static let inkCardOB      = UIColor(hex: "#120f1a")  // OB card glass surface

    static let tableFeltCore    = UIColor(red: 22/255,  green: 17/255,  blue: 38/255,  alpha: 0.95) // felt fill center
    static let tableFeltMid     = UIColor(red: 18/255,  green: 14/255,  blue: 33/255,  alpha: 0.90) // felt fill mid
    static let tableFeltOuter   = UIColor(red: 14/255,  green: 11/255,  blue: 26/255,  alpha: 0.85) // felt fill outer
    static let tableFeltEdge    = UIColor(red: 10/255,  green:  8/255,  blue: 18/255,  alpha: 0.10) // felt fill trailing edge
    static let tableTopoLine    = UIColor(red: 150/255, green: 132/255, blue: 208/255, alpha: 1)    // topo contour stroke
    static let tableCompassStar = UIColor(red: 232/255, green: 228/255, blue: 222/255, alpha: 1)    // compass star
    static let tableAmberPool   = UIColor(red: 255/255, green: 235/255, blue: 180/255, alpha: 0.055) // amber pool center

    // ── Tinted card darks ─────────────────────────────────────
    static let tintCyan       = UIColor(hex: "#061018")
    static let tintPurple     = UIColor(hex: "#080614")
    static let tintMagenta    = UIColor(hex: "#120610")
    static let tintNavy       = UIColor(hex: "#0A1018")
    static let tintIndigo     = UIColor(hex: "#0A0820")
    static let tintPlum       = UIColor(hex: "#180818")

    static let tintSupernovaA = UIColor(hex: "#081420")
    static let tintSupernovaB = UIColor(hex: "#0C0624")
    static let tintSupernovaC = UIColor(hex: "#1A0620")
    static let tintSupernovaD = UIColor(hex: "#1C0818")

    // ── Neutrals — light side ─────────────────────────────────
    static let warmCream      = UIColor(hex: "#F8F6EE")  // page floor
    static let pureWhite      = UIColor(hex: "#FFFFFF")
    static let offWhite       = UIColor(hex: "#F2EFE6")  // inset fields

    // ── Wine scale — light mode text ──────────────────────────
    static let wineDeep       = UIColor(hex: "#3D1A26")                                   // headlines
    static let wineMid        = UIColor(red: 0.36,  green: 0.12,  blue: 0.21,  alpha: 1) // body
    static let wineLight      = UIColor(red: 0.478, green: 0.176, blue: 0.271, alpha: 1) // accent
    static let wineFaint      = UIColor(red: 0.44,  green: 0.07,  blue: 0.18,  alpha: 1) // pills/CTA
    static let nearBlack      = UIColor(hex: "#1A1A1E")

    // ── Gold / amber ──────────────────────────────────────────
    // Safety signal. Full usage rules in AppColors.swift.
    static let gold           = UIColor(hex: "#C8960A")
    static let goldLight      = UIColor(hex: "#E2B93B")
    static let goldDark       = UIColor(hex: "#8B6914")
    static let orangeHot      = UIColor(hex: "#E07020")
    static let orangeDeep     = UIColor(hex: "#C8710A")

    // ── Pure values ───────────────────────────────────────────
    static let pureBlack        = UIColor(hex: "#000000")

    // ── Text ──────────────────────────────────────────────────
    static let inkText          = UIColor(hex: "#E8E8F0")

    // ── Card surfaces ─────────────────────────────────────────
    static let roseWhite        = UIColor(red: 1.0,   green: 0.957, blue: 0.965, alpha: 1)
    static let inkCardRaised    = UIColor(red: 0.086, green: 0.078, blue: 0.141, alpha: 0.92)
    static let frostCard        = UIColor(red: 0.989, green: 0.985, blue: 0.972, alpha: 1)

    // ── Pill surfaces ─────────────────────────────────────────
    static let frostPill        = UIColor(red: 0.910, green: 0.875, blue: 0.945, alpha: 1)
    static let inkPill          = UIColor(red: 0.10,  green: 0.09,  blue: 0.16,  alpha: 1)
    static let frostPillSelected = UIColor(red: 0.958, green: 0.875, blue: 0.925, alpha: 1)
    static let frostPillBottom  = UIColor(red: 0.880, green: 0.845, blue: 0.920, alpha: 1)
    static let inkPillBottom    = UIColor(red: 0.08,  green: 0.07,  blue: 0.13,  alpha: 1)

    // ── CTA ───────────────────────────────────────────────────
    static let frostCTA         = UIColor(red: 0.98,  green: 0.91,  blue: 0.93,  alpha: 1)

    // ── Utility ───────────────────────────────────────────────
    static let destructiveRed = UIColor(hex: "#FF4444")
    static let successGreen   = UIColor(hex: "#00CC88")
}

// MARK: - UIColor hex initialiser (internal — primitives layer only)

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            alpha: Double(a) / 255
        )
    }
}

```

---

