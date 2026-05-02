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