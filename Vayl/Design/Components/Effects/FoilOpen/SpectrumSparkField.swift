//
//  SpectrumSparkField.swift
//  Vayl
//
//  FoilOpen module — spectrum motes knocked loose by a strike on the case.
//  They pop outward fast, then hang and drift upward like embers, twinkling
//  out. Pure function of time (TimelineView + seeded params): no particle
//  state, fully deterministic per burst, nothing to clean up mid-flight.
//

import SwiftUI
import Darwin

/// One strike's worth of sparks. Created at the strike, pruned by the consumer
/// once it has aged out (`lifespan`).
struct SparkBurst: Identifiable {
    /// strike = damage physics (pop + hang). burst = celebration physics:
    /// ejected far and fast, then a slow rain as gravity takes the motes.
    enum Style { case strike, burst }

    let id = UUID()
    /// Spawn point in the spark field's coordinate space.
    let origin: CGPoint
    let started: Date = .now
    let seed: UInt64 = .random(in: .min ... .max)
    var count: Int = 14
    var style: Style = .strike

    /// Longest possible particle life — safe pruning horizon.
    static let lifespan: Double = 3.2
}

struct SpectrumSparkField: View {

    var bursts: [SparkBurst]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Reduce Motion: no airborne particles — the crack itself is the feedback.
        if !reduceMotion {
            TimelineView(.animation) { tl in
                let now = tl.date.timeIntervalSinceReferenceDate
                Canvas { ctx, _ in
                    for burst in bursts { draw(burst, at: now, in: &ctx) }
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func draw(_ burst: SparkBurst, at now: Double, in ctx: inout GraphicsContext) {
        let age = now - burst.started.timeIntervalSinceReferenceDate
        guard age >= 0, age < SparkBurst.lifespan else { return }

        var rng = SparkRandom(seed: burst.seed)
        let colorway = [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta]

        let celebratory = burst.style == .burst
        for _ in 0..<burst.count {
            // params are drawn unconditionally so the stream stays aligned
            // across frames regardless of which particles are still alive
            let angle   = Double.random(in: 0...(2 * .pi), using: &rng)
            let lift    = Double.random(in: 0.25...1.0, using: &rng)
            let speed   = celebratory
                ? Double.random(in: 90...200, using: &rng)
                : Double.random(in: 26...80, using: &rng)
            let life    = celebratory
                ? Double.random(in: 1.4...3.0, using: &rng)
                : Double.random(in: 0.9...2.2, using: &rng)
            let size    = celebratory
                ? Double.random(in: 1.4...3.2, using: &rng)
                : Double.random(in: 1.2...2.6, using: &rng)
            let swayAmp = Double.random(in: 2...7, using: &rng)
            let swayHz  = Double.random(in: 0.6...1.4, using: &rng)
            let phase   = Double.random(in: 0...(2 * .pi), using: &rng)
            let color   = colorway[Int.random(in: 0..<3, using: &rng)]
            guard age < life else { continue }

            let p = age / life
            // fast pop that arrests quickly, then the mote HANGS (ember physics)
            let tau  = celebratory ? 0.30 : 0.22
            let dist = speed * tau * (1 - exp(-age / tau))
            // celebration: gravity takes the motes in their second act — rain
            let rain = celebratory ? 24 * pow(max(0, age - life * 0.4), 2) : 0
            let x = burst.origin.x + cos(angle) * dist
                  + sin(age * 2 * .pi * swayHz + phase) * swayAmp * p
            let y = burst.origin.y + sin(angle) * dist * 0.7
                  - lift * 18 * age                          // gentle float upward
                  + rain

            let twinkle = 0.65 + 0.35 * sin(age * 9 + phase)
            let alpha   = (1 - p) * twinkle
            let dot = CGRect(x: x - size / 2, y: y - size / 2, width: size, height: size)

            var glow = ctx
            glow.opacity = alpha * 0.5
            glow.addFilter(.blur(radius: 2.2))
            glow.fill(Path(ellipseIn: dot.insetBy(dx: -size * 0.7, dy: -size * 0.7)),
                      with: .color(color))

            var core = ctx
            core.opacity = alpha
            core.fill(Path(ellipseIn: dot), with: .color(color))
        }
    }

    /// Seeded deterministic RNG — same particle params every frame.
    private struct SparkRandom: RandomNumberGenerator {
        var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
    }
}
