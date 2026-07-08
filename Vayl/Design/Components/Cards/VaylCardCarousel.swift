// Design/Components/Cards/VaylCardCarousel.swift
//
// Generic, reusable browsable card carousel.
//
// Pairs with `CarouselPhysics` (the scalar browse engine) and renders any card
// content via a builder. This file owns the *visual layout* (the `.stacked`
// peek pile, tuned to "halfway between Strava-ish and Loose & glidey") and the
// gesture surface; the physics engine owns only the scroll math.
//
// Responsibilities (steady-state browse + selection — generic):
//   · horizontal drag → browse (drives CarouselPhysics)
//   · tap front card → onConfirm / onUnconfirm
//   · confirmed card breathes; browse drag locks while confirmed
//   · swipe-up while confirmed → onExit  (caller runs its own exit sequence)
//
// Phase-specific choreography (deal-in, vacuum exit) lives in the consumer.

import SwiftUI

struct VaylCardCarousel<Content: View>: View {

    // MARK: - Inputs

    let count: Int
    let cardSize: CGSize
    let physics: CarouselPhysics

    /// Logical index of the confirmed card, or nil. Owned by the consumer.
    var confirmedIndex: Int?

    /// Extra vertical offset applied to the confirmed card (negative = up). Lets the
    /// consumer drive a looping "swipe up" tug affordance after a card is confirmed.
    var confirmedCardYHint: CGFloat = 0

    /// When true, the confirmed card plays its exit: flies up and off + fades.
    /// Toggle inside `withAnimation` from the consumer.
    var exiting: Bool = false

    /// When true, the UNSELECTED cards drift out of focus (fade + shrink in place).
    /// Driven a beat after `exiting` so the chosen card leads and the rest follow —
    /// the asymmetric 2-step exit.
    var defocusUnselected: Bool = false

    /// Visual layout constants (peek geometry). Defaults = demo "halfway" feel.
    var layout: StackLayout = .standard

    @ViewBuilder var content: (_ index: Int, _ isFront: Bool) -> Content

    var onConfirm: (Int) -> Void = { _ in }
    var onUnconfirm: () -> Void    = {}
    var onExit: () -> Void    = {}

    // MARK: - Local state

    @State private var dragBegan  = false
    @State private var breathing  = false
    /// Trailing (timestamp, translation) samples for a stable release-velocity estimate.
    @State private var samples: [(t: TimeInterval, x: CGFloat)] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let tapThreshold: CGFloat = 10

    // MARK: - Body

    /// Slots on each side of center to render when wrapping. With opacityFalloff
    /// 0.5 (opacity 0 by delta 2), a window of ±3 recycles its far node at delta
    /// ~3.5 — safely invisible — while rendering far fewer cards.
    private var win: Int { 3 }
    /// Fixed node count for the wrapped window. Node id = slot mod nodeCount.
    private var nodeCount: Int { win * 2 + 1 }

    var body: some View {
        // Velocity-lean is gone with the manual integration loop; per-card
        // `rotationPerCard` tilt remains. Lean held at 0 for now.
        let lean: Double = 0
        let front = physics.currentIndex

        ZStack {
            if physics.wraps {
                // ── Infinite scroll ──────────────────────────────────────────
                // A recycled window of `nodeCount` slots around the scroll position.
                // Each render node is keyed by `slot mod nodeCount` — a STABLE id set
                // {0..<nodeCount} that never changes as you scroll. SwiftUI updates
                // nodes in place (no teardown), so a card's `.drawingGroup()` is
                // rasterized once; only the far-edge node (at ~0 opacity) ever swaps
                // content. Cards reappear from the opposite side → no reset point.
                let base = Int(physics.position.rounded())
                let slots = (base - win ... base + win).map {
                    WrapSlot(node: mod($0, nodeCount), slot: $0)
                }
                ForEach(slots, id: \.node) { entry in
                    card(slot: entry.slot,
                         logical: mod(entry.slot, count),
                         isFront: entry.slot == base,
                         lean: lean)
                }
            } else {
                // ── Finite list ──────────────────────────────────────────────
                // One persistent view per card (stable ids 0..<count), browses to ends.
                ForEach(0 ..< count, id: \.self) { i in
                    card(slot: i, logical: i, isFront: i == front, lean: lean)
                }
            }
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .contentShape(Rectangle())
        .gesture(browseGesture)
        // Accessibility: single element; adjustable action browses, "Select" confirms.
        .accessibilityElement(children: .ignore)
        .accessibilityAdjustableAction { direction in
            guard confirmedIndex == nil else { return }
            switch direction {
            case .increment: withAnimation(physics.settleAnimation) { physics.step(by: 1) }
            case .decrement: withAnimation(physics.settleAnimation) { physics.step(by: -1) }
            @unknown default: break
            }
        }
        .accessibilityAction(named: "Select") {
            if confirmedIndex == physics.currentIndex { onUnconfirm() } else { onConfirm(physics.currentIndex) }
        }
        .onChange(of: confirmedIndex) { _, newValue in
            if newValue != nil { startBreathing() } else { stopBreathing() }
        }
    }

    // MARK: - Card builder

    private struct WrapSlot { let node: Int; let slot: Int }

    private func mod(_ a: Int, _ n: Int) -> Int { ((a % n) + n) % n }

    /// Bright spectrum ring + glow on the confirmed card — the visible "selected"
    /// state. Generic affordance for any selectable carousel.
    @ViewBuilder
    private func confirmHighlight(visible: Bool) -> some View {
        let gradient = LinearGradient(
            colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.obCard)
                .stroke(gradient, lineWidth: AppGlows.spectrumBorder.strokeActive)
                .blur(radius: 7)
                .opacity(visible ? 0.55 : 0)
            RoundedRectangle(cornerRadius: AppRadius.obCard)
                .stroke(gradient, lineWidth: AppGlows.spectrumBorder.strokeGlowing)
                .opacity(visible ? 1 : 0)
                .spectrumBorderGlow(intensity: visible ? 0.8 : 0)
        }
        .animation(AppAnimation.standard, value: visible)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func card(slot: Int, logical: Int, isFront: Bool, lean: Double) -> some View {
        let t = transform(slot: slot, lean: lean)
        let isHero          = logical == confirmedIndex
        let confirmedActive = confirmedIndex != nil

        // ── Select state — mirrors ExperienceLevel.lift ─────────────────────────
        // Hero raises + scales up; the rest fade back. Only while confirmed & not exiting.
        let lifting   = confirmedActive && !exiting
        let liftY: CGFloat = (lifting && isHero)  ? -cardSize.height * 0.18 : 0
        let liftScale: CGFloat = (lifting && isHero)  ? 1.10 : 1.0
        let fadeBack: Double  = (lifting && !isHero) ? 0.45 : 1.0
        let fadeScale: CGFloat = (lifting && !isHero) ? 0.88 : 1.0

        // ── Exit state — asymmetric 2-step ──────────────────────────────────────
        // Hero flies up & off (keyed on `exiting`); the rest quietly drift out of
        // focus (keyed on `defocusUnselected`, fired a beat later).
        let heroExitY: CGFloat = (exiting && isHero) ? -cardSize.height * 1.4 : 0
        let heroExitScale: CGFloat = (exiting && isHero) ? 1.04 : 1.0
        let defocusScale: CGFloat = (defocusUnselected && !isHero) ? 0.80 : 1.0
        let exitOpacity: Double = {
            if exiting && isHero { return 0 }
            if defocusUnselected && !isHero { return 0 }
            return 1
        }()

        content(logical, isFront)
            .frame(width: cardSize.width, height: cardSize.height)
            .overlay(confirmHighlight(visible: isHero && lifting))
            .scaleEffect(t.scale * (isFront && breathing ? 1.02 : 1.0)
                         * liftScale * fadeScale * heroExitScale * defocusScale)
            .rotationEffect(.degrees(t.rotation))
            .blur(radius: reduceMotion ? 0 : t.blur)   // depth-of-field — the focal card stays crisp
            .offset(x: t.x,
                    y: t.y + (isHero ? confirmedCardYHint : 0) + liftY + heroExitY)
            .opacity(t.opacity * fadeBack * exitOpacity)
            .zIndex((isHero && (confirmedActive || exiting)) ? 999 : t.z)
    }

    // MARK: - Stacked layout math (demo, ground truth)

    private struct Transform { var x: CGFloat; var y: CGFloat; var scale: CGFloat; var rotation: Double; var opacity: Double; var z: Double; var blur: CGFloat }

    private func transform(slot: Int, lean: Double) -> Transform {
        // Continuous signed distance from the scroll position to this slot.
        // Absolute slots keep `delta` continuous through wrap (the window math
        // handles recycling), so there is no round()/branch pop.
        let delta = Double(slot) - physics.position
        let ad    = abs(delta)
        let sign: CGFloat = delta >= 0 ? 1 : -1

        // Peek spacing / lift scale with card width so the felt demo feel is
        // preserved across card sizes (fractions, not absolute px).
        let spacing = cardSize.width * layout.peekSpacingFraction
        let lift    = cardSize.width * layout.yLiftFraction

        let x: CGFloat = ad < 0.001
            ? 0
            : sign * (spacing * 0.55 + CGFloat(ad) * spacing * 0.55)
        let scale   = max(1 - CGFloat(ad) * layout.scaleFalloff, 0.7)
        let y       = CGFloat(ad) * lift
        let opacity = max(1 - ad * layout.opacityFalloff, 0)
        let rotation = delta * layout.rotationPerCard + lean   // no round() branch → no pop
        // Depth-of-field: off-center cards soften so the front reads as the focal plane
        // (Strava-style rack focus). Grows linearly with distance; ~0 on the centered card.
        let blur     = CGFloat(ad) * layout.blurPerCard

        return Transform(x: x, y: y, scale: scale, rotation: rotation, opacity: opacity, z: -ad, blur: blur)
    }

    // MARK: - Gesture

    private var browseGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard confirmedIndex == nil else { return }   // locked while confirmed
                if !dragBegan {
                    dragBegan = true
                    samples.removeAll()
                    physics.beginDrag()
                }
                physics.drag(translation: value.translation.width)
                // Record a trailing sample for the release-velocity estimate.
                samples.append((Date().timeIntervalSinceReferenceDate, value.translation.width))
                if samples.count > 6 { samples.removeFirst(samples.count - 6) }
            }
            .onEnded { value in
                defer { dragBegan = false; samples.removeAll() }
                let dx = value.translation.width
                let dy = value.translation.height

                // Tap — minimal movement.
                if max(abs(dx), abs(dy)) < tapThreshold {
                    if confirmedIndex == physics.currentIndex { onUnconfirm() } else { onConfirm(physics.currentIndex) }
                    return
                }

                // Confirmed → only swipe-up (exit) is meaningful; browse is locked.
                if confirmedIndex != nil {
                    if dy <= -(cardSize.height * 0.14) || value.velocity.height <= -400 {
                        onExit()
                    }
                    return
                }

                // Browsing — spring to the velocity-projected target. SwiftUI owns
                // the timing (render-server, vsync-locked) → no jank.
                withAnimation(physics.settleAnimation) {
                    physics.settle(predictedVelocity: trailingVelocity())
                }
            }
    }

    /// Stable release velocity (points/sec) from the trailing drag samples —
    /// avoids the jumpiness of `DragGesture.Value.velocity`.
    private func trailingVelocity() -> CGFloat {
        let now = Date().timeIntervalSinceReferenceDate
        let recent = samples.filter { now - $0.t < 0.09 }
        guard let a = recent.first, let b = recent.last, recent.count >= 2 else { return 0 }
        let dt = b.t - a.t
        guard dt > 0 else { return 0 }
        return (b.x - a.x) / CGFloat(dt)
    }

    // MARK: - Breathing

    private func startBreathing() {
        guard !reduceMotion, !AppAnimation.lowPower else { return }
        breathing = false
        withAnimation(.easeInOut(duration: AppAnimation.ambientPulse).repeatForever(autoreverses: true)) {
            breathing = true
        }
    }

    private func stopBreathing() {
        withAnimation(AppAnimation.fast.reduceMotionSafe) { breathing = false }
    }
}

// MARK: - StackLayout

/// Peek geometry for the `.stacked` carousel layout. Values are the felt
/// "halfway between Strava-ish and Loose & glidey" preset from the demo.
///
/// `peekSpacingFraction` / `yLiftFraction` are expressed as fractions of card
/// WIDTH so the feel survives any card size (demo values ÷ the ~230px demo card:
/// 75/230 ≈ 0.33, 16/230 ≈ 0.07). Unitless terms are size-independent.
struct StackLayout: Equatable {
    var peekSpacingFraction: CGFloat = 0.33
    var scaleFalloff: CGFloat = 0.11
    /// 0.5 ⇒ opacity reaches 0 by `delta == 2`, so only 3 cards are ever visible
    /// (front + one peek each side). Prevents a short, looping set from looking
    /// like it has more options than it does.
    var opacityFalloff: Double  = 0.5
    var yLiftFraction: CGFloat = 0.07
    var rotationPerCard: Double  = 2.5
    var leanPerCardPerVel: Double  = 1.3
    /// Depth-of-field: blur (points) added per card-distance from center. Off-center cards
    /// soften so the front reads as the focal plane (Strava-style rack focus). 0 disables.
    /// Kept small — only the immediate peek is visible (opacity hits 0 by delta 2). FEEL-GATE.
    var blurPerCard: CGFloat = 2.0

    static let standard = StackLayout()
}
