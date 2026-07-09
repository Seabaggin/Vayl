//
//  SyncConfig.swift
//  Vayl
//
//  Tunable feel values for the airlock sync lock-in. All 🎚️ values are
//  confirmed on device (Swift-over-HTML rule); the HTML rig only seeds them.
//

import Foundation

struct SyncConfig: Equatable {
    var floorDegrees: Double = 120        // 🎚️ release below this = too early
    var toleranceDegrees: Double = 18     // 🎚️ max circular gap to pass (≈±175ms @3.5s)
    var sweepSeconds: Double = 3.5        // 🎚️ time for a full 0→360° sweep
    var easingStepDegrees: Double = 6     // 🎚️ tolerance added per consecutive miss
    var easingCapDegrees: Double = 48     // 🎚️ silent-easing ceiling
    var backstopAfterMisses: Int = 4      // 🎚️ misses before "enter together anyway"

    static let standard = SyncConfig()

    /// Accessibility base: wider tolerance + longer sweep from attempt one.
    static let reducedPrecision = SyncConfig(toleranceDegrees: 30, sweepSeconds: 4.5)

    /// Silently-eased tolerance after `misses` consecutive misses, capped.
    func tolerance(afterMisses misses: Int) -> Double {
        min(easingCapDegrees, toleranceDegrees + easingStepDegrees * Double(max(0, misses)))
    }
}
