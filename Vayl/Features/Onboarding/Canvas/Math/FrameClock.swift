//
//  FrameClock.swift
//  Vayl
//

// Features/Onboarding/Canvas/Math/FrameClock.swift

import QuartzCore

/// Display-refresh-aligned async frames for hand-driven animation loops.
///
/// A `Task.sleep(for: .milliseconds(14))` drive loop is NOT frame-aligned: its
/// wake-ups beat against the display cadence (16.7ms at 60Hz, 8.3ms at 120Hz),
/// so some frames get two value writes and some get none — visible as judder on
/// anything the loop drives. This wraps a CADisplayLink so each iteration lands
/// exactly once per rendered frame, at whatever rate the display is running.
///
/// Usage:
///     for await _ in FrameClock.frames() {
///         guard !Task.isCancelled else { break }
///         // one write per display frame
///     }
///
/// The stream ends (and the display link is invalidated) when the consuming
/// task cancels or breaks out of the loop.
@MainActor
enum FrameClock {

    /// One element per display frame; the value is the link's `targetTimestamp`.
    /// Buffering keeps only the newest tick — a slow consumer skips frames
    /// rather than replaying a stale backlog.
    static func frames() -> AsyncStream<TimeInterval> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let driver = Driver { continuation.yield($0) }
            continuation.onTermination = { _ in
                Task { @MainActor in driver.stop() }
            }
            driver.start()
        }
    }

    /// CADisplayLink target. The link retains its target, so the driver stays
    /// alive exactly as long as the link runs; `stop()` breaks the cycle.
    private final class Driver: NSObject {
        private var link: CADisplayLink?
        private let tick: (TimeInterval) -> Void

        init(tick: @escaping (TimeInterval) -> Void) {
            self.tick = tick
        }

        func start() {
            let link = CADisplayLink(target: self, selector: #selector(step(_:)))
            // Track the display's full range — 120 on ProMotion (enabled by
            // CADisableMinimumFrameDurationOnPhone in Vayl.plist), 60 elsewhere.
            link.preferredFrameRateRange = CAFrameRateRange(
                minimum: 60, maximum: 120, preferred: 120
            )
            link.add(to: .main, forMode: .common)
            self.link = link
        }

        func stop() {
            link?.invalidate()
            link = nil
        }

        @objc private func step(_ link: CADisplayLink) {
            tick(link.targetTimestamp)
        }
    }
}
