// Design/Components/Cards/CardPhysics/CarouselPhysics.swift
//
// Reusable, orientation-agnostic browse engine for card carousels.
//
// Owns ONLY the 1-D scroll math — a continuous `position` in card-index units.
// It knows nothing about layout, geometry, or card content: consuming views read
// `position` and map it to their own visual layout (stacked pile, horizontal row).
//
// MOTION MODEL — SwiftUI-native, display-synced.
// There is no manual integration loop. While dragging, the view sets `position`
// directly (1:1 finger). On release the view calls `settle(predictedVelocity:)`
// INSIDE `withAnimation(settleAnimation)`, so SwiftUI's render-server spring
// interpolates `position` to the projected target card — guaranteed smooth and
// vsync-locked. `settleAnimation` is parameterised with the same SwiftUI
// `response`/`dampingFraction` that were tuned in the interactive demo.

import SwiftUI

@Observable
@MainActor
final class CarouselPhysics {

    // MARK: - Config

    /// All tunable feel constants. Defaults are the demo's "halfway" preset.
    struct Config: Equatable, Sendable {
        /// Points of horizontal drag required to advance one full card.
        var dragSensitivity: CGFloat = 133
        /// Seconds of release velocity projected forward to choose the target card.
        var projection: Double = 0.16
        /// Maximum cards a single flick may travel.
        var maxFlick: Int = 5
        /// SwiftUI spring response (seconds) — lower is snappier.
        var response: Double = 0.35
        /// 0.70 gives a lively overshoot-and-settle without losing render-server smoothness.
        var dampingFraction: Double = 0.70

        nonisolated init(
            dragSensitivity: CGFloat = 133,
            projection: Double = 0.16,
            maxFlick: Int = 5,
            response: Double = 0.35,
            dampingFraction: Double = 0.70
        ) {
            self.dragSensitivity = dragSensitivity
            self.projection = projection
            self.maxFlick = maxFlick
            self.response = response
            self.dampingFraction = dampingFraction
        }

        nonisolated static let standard = Config()
    }

    var config: Config

    // MARK: - Topology

    /// Number of distinct cards. Content index is always `normalizedIndex`.
    private(set) var count: Int
    /// When true, browsing wraps infinitely (modulo). When false, clamps to ends.
    var wraps: Bool

    // MARK: - Live state (observed by views)

    /// Continuous scroll position in card-index units. The centered card is
    /// `normalizedIndex(Int(position.rounded()))`.
    private(set) var position: Double = 0
    /// Integer card last settled/targeted.
    private(set) var target: Int = 0
    /// True while a finger is actively dragging.
    private(set) var isDragging: Bool = false

    // MARK: - Private

    private var dragStartPosition: Double = 0

    // MARK: - Init

    init(count: Int, wraps: Bool = true, config: Config = .standard) {
        self.count  = max(count, 1)
        self.wraps  = wraps
        self.config = config
    }

    // MARK: - Derived

    /// The currently centered card index (normalized into `0..<count`).
    var currentIndex: Int { normalizedIndex(Int(position.rounded())) }

    /// Spring used by the view to animate `position` on release / programmatic moves.
    var settleAnimation: Animation {
        // TOKEN-EXEMPT: spring parameters come from the caller's CarouselConfig —
        // this is a parameterized engine, not a raw value.
        .spring(response: config.response, dampingFraction: config.dampingFraction)
    }

    /// Update card count (e.g. solo→together). Resets nothing else.
    func updateCount(_ newCount: Int) { count = max(newCount, 1) }

    // MARK: - Drag intents (called by the consuming view's gesture)

    func beginDrag() {
        isDragging = true
        dragStartPosition = position
    }

    /// `translation` = horizontal drag translation in points (+ = finger moved right).
    /// Dragging right reveals the previous card, so `position` decreases.
    /// Set WITHOUT animation by the caller — 1:1 finger tracking.
    func drag(translation: CGFloat) {
        guard isDragging else { return }
        var next = dragStartPosition - Double(translation / config.dragSensitivity)
        if !wraps { next = min(Double(count - 1), max(0, next)) }
        position = next
    }

    /// Project a target card from release velocity and snap `position` to it.
    /// `predictedVelocity` = horizontal release velocity in points/second
    /// (+ = finger moving right). MUST be called inside `withAnimation(settleAnimation)`
    /// so SwiftUI animates the resulting `position` change.
    func settle(predictedVelocity: CGFloat) {
        isDragging = false
        let v = -Double(predictedVelocity / config.dragSensitivity)   // index units / sec

        let here = Int(position.rounded())
        var snapped = Int((position + v * config.projection).rounded())
        snapped = min(here + config.maxFlick, max(here - config.maxFlick, snapped))
        if !wraps { snapped = min(count - 1, max(0, snapped)) }

        target = snapped
        position = Double(snapped)
    }

    /// Programmatic move (a11y adjustable action, buttons). Also must be called
    /// inside `withAnimation(settleAnimation)`.
    func step(by delta: Int) {
        var t = Int(position.rounded()) + delta
        if !wraps { t = min(count - 1, max(0, t)) }
        target = t
        position = Double(t)
    }

    // MARK: - Layout helper (read-only)

    /// Maps any (possibly out-of-range) slot index into `0..<count`.
    func normalizedIndex(_ raw: Int) -> Int {
        guard wraps else { return min(count - 1, max(0, raw)) }
        return ((raw % count) + count) % count
    }
}
