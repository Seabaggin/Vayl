//
//  AppMotion.swift
//  Vayl
//

// App/Theme/AppMotion.swift

import SwiftUI

/// Tier 2 — Motion staple APPLIERS.
///
/// The AppGlows pattern: values live in AppAnimation's Motion System section; this file is
/// their thin, stateless application surface. Every applier bakes the Reduce Motion fallback
/// in, so a call site cannot forget it.
///
/// The system (spec: docs/superpowers/specs/2026-07-03-motion-system-design.md):
///   Staple 1 — Depth Handoff    → `AnyTransition.vaylDepth(_:)`
///   Staple 2 — Weighted Arrival → AppAnimation.arrive / arriveCover, adopted by VaylPresentation
///   Staple 3 — Charged Tap      → VaylBorderEffect (exists) + `.vaylRefusal(trigger:)`
///   Sequencing                  → `.vaylCascade(index:shown:)`
///
/// Choreographed machinery (presentation dismiss-guards, the press/charge/glow state machine)
/// stays in Design/Components and adopts these tokens — Theme hosts only what is thin and
/// stateless enough to read at a glance.

/// Which amplitude a Depth Handoff plays at.
///   .loud  — OB canvas + .vaylCover contents only (the ceremony ban's boundary).
///   .quiet — everything else. Obeys AppAnimation.quietMaxScaleDelta.
enum VaylMotionRegister {
    case loud
    case quiet
}

// MARK: — Staple 1: Depth Handoff

extension AnyTransition {

    /// Screen-level change: the incoming view settles forward from depth, the outgoing view
    /// recedes back into it. Screens never slide — Vayl is one continuous space with z-depth,
    /// not a page stack.
    ///
    /// Pair with the register's duration at the container:
    ///   .animation(AppAnimation.depthQuiet, value: selection)   // quiet
    ///   .animation(AppAnimation.slow.reduceMotionSafe, value: phase)  // loud (OB phaseHandoff)
    ///
    /// Reduce Motion: pure opacity cross-fade — scale is motion.
    static func vaylDepth(_ register: VaylMotionRegister) -> AnyTransition {
        guard !UIAccessibility.isReduceMotionEnabled else { return .opacity }
        let scaleIn: CGFloat
        let scaleOut: CGFloat
        switch register {
        case .loud:
            scaleIn  = AppAnimation.depthLoudScaleIn
            scaleOut = AppAnimation.depthLoudScaleOut
        case .quiet:
            scaleIn  = AppAnimation.depthQuietScaleIn
            scaleOut = AppAnimation.depthQuietScaleOut
        }
        return .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: scaleIn)),
            removal: .opacity.combined(with: .scale(scale: scaleOut))
        )
    }
}

// MARK: — Sequencing: First-Arrival Cascade

extension View {

    /// One row of a first-arrival cascade. Drive `shown` false → true when the screen's data
    /// FIRST lands; rows rise 14pt and fade in as one overlapping wave (75ms stagger against a
    /// 0.52s row — ~85% overlap is what makes it read as a single motion travelling down the
    /// list). Rows past AppAnimation.cascadeCap arrive together with the last capped row.
    ///
    /// LAW: only the first arrival cascades. Refreshes set `shown` without this modifier's
    /// stagger ever replaying (the value only flips once) — re-fetched content just fades.
    ///
    /// Reduce Motion: all rows appear together with a single fast fade, no travel.
    func vaylCascade(index: Int, shown: Bool) -> some View {
        modifier(VaylCascadeModifier(index: index, shown: shown))
    }

    /// Staple 3's "no". Bump `trigger` when the user commits an invalid or disabled action:
    /// the element shivers ±3pt laterally over 0.28s. The border arcs never fill on a refusal —
    /// this modifier is the visible half; pair `.sensoryFeedback(.impact(.medium), trigger:)`
    /// on the same trigger for the felt half.
    ///
    /// Reduce Motion: no shiver — the haptic alone carries the refusal.
    func vaylRefusal<T: Equatable>(trigger: T) -> some View {
        modifier(VaylRefusalModifier(trigger: trigger))
    }
}

private struct VaylCascadeModifier: ViewModifier {
    let index: Int
    let shown: Bool

    func body(content: Content) -> some View {
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        let cappedIndex  = min(index, AppAnimation.cascadeCap - 1)
        let delay        = reduceMotion ? 0 : Double(cappedIndex) * AppAnimation.cascadeStagger
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : AppAnimation.cascadeRise)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.2)
                    : AppAnimation.cascadeRow.delay(delay),
                value: shown
            )
    }
}

private struct VaylRefusalModifier<T: Equatable>: ViewModifier {
    let trigger: T
    @State private var shiverX: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: shiverX)
            .onChange(of: trigger) {
                guard !UIAccessibility.isReduceMotionEnabled else { return }
                Task { @MainActor in
                    // Four decaying legs across refusalDuration — a shiver, not a shake.
                    let leg = AppAnimation.refusalDuration / 4
                    let amp = AppAnimation.refusalAmplitude
                    for target in [-amp, amp, -amp * 0.66, 0] {
                        withAnimation(.easeOut(duration: leg)) { shiverX = target }
                        try? await Task.sleep(for: .seconds(leg))
                    }
                    shiverX = 0
                }
            }
    }
}
