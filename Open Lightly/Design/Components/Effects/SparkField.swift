// SparkField.swift
// Open Lightly
//
// Campfire ember particle system for light mode screens.
// Standalone Canvas-based component — place alongside AuroraGlowField
// in the screen background stack.
//
// Palette: warm ember colors — deep magenta, hot pink, gold, amber,
//          rose, warm gold, deep rose, orange-amber.
//          Matches the StatView HTML mockup exactly.
//
// Usage:
//   ZStack {
//       AppColors.lightPageBg.ignoresSafeArea()
//       AuroraGlowField().ignoresSafeArea()
//       SparkField(config: .statView).ignoresSafeArea()
//       // content
//   }
//
// Screen configs:
//   .statView            — Screen 1, free travel, no fade
//   .nameView            — Screen 3, fades before glass card
//   .modeSelectView      — Screen 4, stays in lower third
//   .contextView         — Screen 5, very subtle, early fade
//   .curiosityPickerView — Screen 6, minimal, bottom only
//   .groundRulesView     — Screen 8, confined to bottom quarter
//
// BrandView (Screen 2) and BuildingPathView (Screen 7)
// are permanently dark — never use SparkField on those screens.
//
// Always: .allowsHitTesting(false)
// Always: placed in background, never over content
// Light mode only — never use on dark screens
//
// Architecture notes:
//   - SparkSystem is @StateObject — each SparkField instance owns its
//     own isolated particle state. No singleton. Safe for overlapping
//     views, navigation transitions, and sheet presentations.
//   - plusLighter blend is applied INSIDE the Canvas GraphicsContext only.
//     Sparks glow additively against each other within the offscreen texture.
//     The texture itself composites normally (.normal) against the scene,
//     preserving ember colors against the cream background.
//   - .compositingGroup() on the view seals the layer so sparks physically
//     sit below all ZStack siblings placed after SparkField.

import Combine
import SwiftUI

// ─────────────────────────────────────────────
// MARK: SparkConfiguration
// One config per screen. Defined once, used everywhere.
// Tune numbers here — never inside Particle or SparkSystem.
// ─────────────────────────────────────────────

struct SparkConfiguration {

    // Number of simultaneous sparks
    var count: Int

    // Rise speed — base + variance
    // vy = -(baseSpeed + random * speedVariance)
    var baseSpeed: Double
    var speedVariance: Double

    // Dot size
    var radiusMin: Double
    var radiusMax: Double

    // Glow halo multiplier applied to radius
    var glowMultiplierMin: Double
    var glowMultiplierMax: Double

    // Opacity ceiling — how bright sparks get at peak
    // Tuned per screen: brighter on open screens, dimmer under content
    var opacityCeilMin: Double
    var opacityCeilMax: Double

    // Spawn X range (normalised 0–1)
    var spawnXMin: Double
    var spawnXMax: Double

    // Spawn Y on respawn (normalised 0–1, 1 = bottom)
    // Particles born here when they respawn after lifespan ends
    var respawnYMin: Double

    // Spatial fade zone (normalised 0–1, y decreases as particle rises)
    // nil = no fade — particle travels until lifecycle ends naturally
    // fadeStartY: fade begins (full opacity below this)
    // fadeEndY:   fully transparent (above this y, particle invisible)
    // fadeStartY must be > fadeEndY (y decreases as particle rises)
    var fadeStartY: Double?
    var fadeEndY: Double?

    // Palette override — nil uses the default warm ember palette
    // Provide a custom palette to shift color character per screen
    var palette: [(r: Double, g: Double, b: Double)]?
}

// ─────────────────────────────────────────────
// MARK: Per-screen configurations
// ─────────────────────────────────────────────

extension SparkConfiguration {

    // Default warm ember palette — shared across all screens.
    // Matches the StatView HTML mockup warmPalette exactly.
    static let defaultPalette: [(r: Double, g: Double, b: Double)] = [
        (r: 220/255, g:  30/255, b:  90/255),  // deep magenta   — boosted red channel
        (r: 255/255, g:   0/255, b: 106/255),  // hot pink       — unchanged #FF006A
        (r: 215/255, g: 110/255, b:   0/255),  // amber-gold     — green reduced, warmer
        (r: 240/255, g:  70/255, b:  10/255),  // hot amber      — red pushed, green dropped
        (r: 210/255, g:  10/255, b:  80/255),  // rose           — more saturated
        (r: 255/255, g: 130/255, b:   0/255),  // pure warm gold — green floor raised
        (r: 200/255, g:  20/255, b:  70/255),  // deep rose      — direction unchanged
        (r: 250/255, g:  90/255, b:  20/255),  // hot orange     — red channel maximised
    ]

    // ── Screen 1: StatView ────────────────────
    // No cards. Full vertical travel. No spatial fade.
    // Most expressive — stat number is the hero, sparks
    // surround it freely across the full screen height.
    // Matches HTML StatView mockup: count 28, speed 0.27–0.45.
    static let statView = SparkConfiguration(
        count:             28,
        baseSpeed:         0.27,
        speedVariance:     0.18,
        radiusMin:         0.65,
        radiusMax:         2.00,
        glowMultiplierMin: 4.0,
        glowMultiplierMax: 6.2,
        opacityCeilMin:    0.48,
        opacityCeilMax:    0.75,
        spawnXMin:         0.10,
        spawnXMax:         0.90,
        respawnYMin:       0.55,
        fadeStartY:        nil,   // full travel — no fade
        fadeEndY:          nil,
        palette:           nil    // default warm ember
    )

    // ── Screen 3: NameView ────────────────────
    // Glass card: y ~0.28–0.72.
    // Sparks spawn below, dissolve before card edge.
    // Form screen — quieter than StatView.
    static let nameView = SparkConfiguration(
        count:             22,
        baseSpeed:         0.27,
        speedVariance:     0.18,
        radiusMin:         0.65,
        radiusMax:         2.00,
        glowMultiplierMin: 4.0,
        glowMultiplierMax: 6.2,
        opacityCeilMin:    0.42,
        opacityCeilMax:    0.65,
        spawnXMin:         0.12,
        spawnXMax:         0.88,
        respawnYMin:       0.55,
        fadeStartY:        0.58, // dissolve begins here
        fadeEndY:          0.44, // fully gone — well below card edge
        palette:           nil
    )

    // ── Screen 4: ModeSelectView ──────────────
    // Three mode cards start ~y 0.35, experience pills below.
    // Sparks confined to lower half. Quieter density.
    // ScrollView content means particles should not rise
    // high enough to be visible behind text.
    static let modeSelectView = SparkConfiguration(
        count:             18,
        baseSpeed:         0.22,
        speedVariance:     0.14,
        radiusMin:         0.55,
        radiusMax:         1.70,
        glowMultiplierMin: 3.5,
        glowMultiplierMax: 5.5,
        opacityCeilMin:    0.33,
        opacityCeilMax:    0.54,
        spawnXMin:         0.12,
        spawnXMax:         0.88,
        respawnYMin:       0.62,  // born lower than other screens
        fadeStartY:        0.55,
        fadeEndY:          0.40,
        palette:           nil
    )

    // ── Screen 5: ContextView ─────────────────
    // Gesture-driven card stack takes most of the screen.
    // Sparks must not compete with the drag interaction.
    // Very subtle — almost subliminal presence only.
    static let contextView = SparkConfiguration(
        count:             14,
        baseSpeed:         0.20,
        speedVariance:     0.12,
        radiusMin:         0.50,
        radiusMax:         1.50,
        glowMultiplierMin: 3.0,
        glowMultiplierMax: 5.0,
        opacityCeilMin:    0.27,
        opacityCeilMax:    0.45,
        spawnXMin:         0.10,
        spawnXMax:         0.90,
        respawnYMin:       0.65,
        fadeStartY:        0.60,  // early fade — cards occupy mid-screen
        fadeEndY:          0.48,
        palette:           nil
    )

    // ── Screen 6: CuriosityPickerView ─────────
    // Dense ScrollView fills most of the screen from top.
    // Sparks barely there — content is the entire focus.
    // Lowest density and opacity in the flow.
    static let curiosityPickerView = SparkConfiguration(
        count:             12,
        baseSpeed:         0.18,
        speedVariance:     0.10,
        radiusMin:         0.45,
        radiusMax:         1.30,
        glowMultiplierMin: 3.0,
        glowMultiplierMax: 4.5,
        opacityCeilMin:    0.22,
        opacityCeilMax:    0.36,
        spawnXMin:         0.10,
        spawnXMax:         0.90,
        respawnYMin:       0.70,  // born in bottom 30% only
        fadeStartY:        0.65,  // dissolve almost immediately after spawning
        fadeEndY:          0.52,
        palette:           nil
    )

    // ── Screen 8: GroundRulesView ─────────────
    // ScrollView with promise cards + italic line + pinned CTA.
    // Sparks confined to bottom quarter. Very dim.
    // Must not distract from the must-read content.
    static let groundRulesView = SparkConfiguration(
        count:             14,
        baseSpeed:         0.18,
        speedVariance:     0.10,
        radiusMin:         0.45,
        radiusMax:         1.30,
        glowMultiplierMin: 3.0,
        glowMultiplierMax: 4.5,
        opacityCeilMin:    0.24,
        opacityCeilMax:    0.40,
        spawnXMin:         0.10,
        spawnXMax:         0.90,
        respawnYMin:       0.72,  // bottom quarter only
        fadeStartY:        0.68,
        fadeEndY:          0.56,
        palette:           nil
    )
}

// ─────────────────────────────────────────────
// MARK: SparkField View
// ─────────────────────────────────────────────

struct SparkField: View {

    var config: SparkConfiguration = .statView

    // Each SparkField instance owns its own isolated particle system.
    // @StateObject persists across parent re-renders (e.g. keyboard
    // appearing, @State changes on the parent view) so particles are
    // never accidentally reset mid-animation.
    @StateObject private var system = SparkSystem()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30, paused: false)) { timeline in
            Canvas { context, size in
                // Reference timeline.date — required so SwiftUI
                // invalidates the Canvas on every tick.
                _ = timeline.date
                system.update(size: size)
                system.drawAll(context: context, size: size)
            }
        }
        // .compositingGroup() flattens this entire Canvas into one
        // offscreen Metal texture before it is composited into the
        // parent ZStack. This means every ZStack sibling placed AFTER
        // SparkField sits in a completely separate layer — sparks are
        // physically underneath buttons, cards, and text.
        //
        // NO .blendMode() here — normal alpha compositing against the
        // scene preserves ember colors on the cream background.
        // plusLighter lives only INSIDE the Canvas (see SparkSystem.drawAll)
        // where it blends sparks against each other, not against the bg.
        .compositingGroup()
        .allowsHitTesting(false)
        .onAppear {
            system.configure(config)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: SparkSystem
// Owns all particle state. ObservableObject so @StateObject
// in SparkField holds a stable reference across re-renders.
// No singleton — each SparkField gets its own instance.
// Safe for overlapping views, navigation transitions, sheets.
// ─────────────────────────────────────────────

final class SparkSystem: ObservableObject {

    // Explicit publisher satisfies ObservableObject without @Published.
    // SparkSystem never needs to push UI updates through Combine —
    // the Canvas refreshes via TimelineView, not objectWillChange.
    // Declared explicitly because the compiler cannot synthesise
    // conformance when no @Published properties are present.
    let objectWillChange = ObservableObjectPublisher()

    private var particles: [Particle] = []
    private var activeConfig: SparkConfiguration = .statView

    func configure(_ config: SparkConfiguration) {
        // Always fully reconfigure — no one-time flag.
        // .onAppear is naturally scoped to the view lifetime,
        // so this is only called when the view actually appears.
        activeConfig = config
        let palette = config.palette ?? SparkConfiguration.defaultPalette
        particles = (0..<config.count).map { _ in
            Particle(config: config, palette: palette, initial: true)
        }
    }

    func update(size: CGSize) {
        let palette = activeConfig.palette ?? SparkConfiguration.defaultPalette
        for i in particles.indices {
            particles[i].update(bounds: size, config: activeConfig, palette: palette)
        }
    }

    func drawAll(context: GraphicsContext, size: CGSize) {
        // plusLighter INSIDE the Canvas only.
        // Sparks that overlap each other add light together — correct
        // ember glow behaviour. The offscreen texture produced by
        // .compositingGroup() then composites normally against the scene,
        // so the cream background is never additively blown out to white.
        var blendedContext = context
        blendedContext.blendMode = .plusLighter

        for particle in particles {
            let px = particle.x * size.width
            let py = particle.y * size.height
            particle.drawAt(context: blendedContext, px: px, py: py)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: Particle
// Value type — one ember spark.
// x and y are stored normalised (0–1).
// Converted to pixels in SparkSystem.drawAll().
// All physics values read from SparkConfiguration —
// nothing hardcoded here.
// ─────────────────────────────────────────────

private struct Particle {

    var x: Double
    var y: Double
    var vy: Double
    var vx: Double
    var driftAmp:    Double
    var driftFreq:   Double
    var driftPhase:  Double
    var radius:      Double
    var glowRadius:  Double
    var frame:       Double
    var totalFrames: Double
    var opacityCeil: Double
    var fadeStartY:  Double?
    var fadeEndY:    Double?
    var r: Double
    var g: Double
    var b: Double

    // ── Init ──────────────────────────────────────

    init(
        config: SparkConfiguration,
        palette: [(r: Double, g: Double, b: Double)],
        initial: Bool
    ) {
        let c = palette[Int.random(in: 0..<palette.count)]
        r = c.r; g = c.g; b = c.b

        x = config.spawnXMin + Double.random(in: 0..<(config.spawnXMax - config.spawnXMin))

        // Initial spread: y 0.15–1.0 so all vertical zones populated on first appear
        // Respawn: born near bottom per config.respawnYMin
        y = initial
            ? (0.15 + Double.random(in: 0..<0.85))
            : (config.respawnYMin + Double.random(in: 0..<(1.0 - config.respawnYMin)))

        radius = config.radiusMin + Double.random(in: 0..<(config.radiusMax - config.radiusMin))

        let spd = config.baseSpeed
        let variance = config.speedVariance
        vy = -(spd + Double.random(in: 0..<variance))
        vx = (Double.random(in: 0..<1.0) - 0.5) * 0.20

        driftAmp   = 0.5 + Double.random(in: 0..<0.9)
        driftFreq  = 0.007 + Double.random(in: 0..<0.011)
        driftPhase = Double.random(in: 0..<(.pi * 2))

        totalFrames = 180 + Double.random(in: 0..<240)
        frame       = initial ? Double.random(in: 0..<totalFrames) : 0

        let glowMult = config.glowMultiplierMin
            + Double.random(in: 0..<(config.glowMultiplierMax - config.glowMultiplierMin))
        glowRadius = radius * glowMult

        opacityCeil = config.opacityCeilMin
            + Double.random(in: 0..<(config.opacityCeilMax - config.opacityCeilMin))

        // Store fade zone per particle so update() can read it without config reference
        fadeStartY = config.fadeStartY
        fadeEndY   = config.fadeEndY
    }

    // ── Opacity curve ─────────────────────────────
    // Lifecycle: ease in (0→0.15), hold (0.15→0.66), ease out (0.66→1.0)
    // Spatial:   dissolve as particle rises into content zone.
    //            nil fadeStartY = no spatial fade.

    var opacity: Double {
        let t = frame / totalFrames

        // Lifecycle curve
        let lifeCurve: Double
        if t < 0.14      { lifeCurve = (t / 0.14) * opacityCeil }
        else if t < 0.66 { lifeCurve = opacityCeil }
        else             { lifeCurve = ((1.0 - t) / 0.34) * opacityCeil }

        // Spatial fade — only applied when config provides fade zone
        guard let startY = fadeStartY, let endY = fadeEndY else {
            return lifeCurve   // no fade — full travel
        }
        let spatialFade: Double
        if y > startY {
            spatialFade = 1.0
        } else if y < endY {
            spatialFade = 0.0
        } else {
            spatialFade = (y - endY) / (startY - endY)
        }
        return lifeCurve * spatialFade
    }

    // ── Update ────────────────────────────────────

    mutating func update(
        bounds: CGSize,
        config: SparkConfiguration,
        palette: [(r: Double, g: Double, b: Double)]
    ) {
        frame += 1

        let pixelY = y * bounds.height
        if frame >= totalFrames || pixelY < -20 {
            self = Particle(config: config, palette: palette, initial: false)
            return
        }

        let sine = sin(frame * driftFreq + driftPhase)
        x += (vx + sine * driftAmp * 0.032) / bounds.width
        y += vy / bounds.height
        vy *= 1.0012
    }

    // ── Draw ──────────────────────────────────────
    // Three layers: smooth radial gradient halo → crisp dot → hot white core.

    func drawAt(context: GraphicsContext, px: Double, py: Double) {
        let op = opacity
        guard op > 0.01 else { return }

        let baseColor = Color(red: r, green: g, blue: b)

        // Layer 1: Smooth Radial Gradient Halo
        let haloGradient = Gradient(stops: [
            .init(color: baseColor.opacity(op * 0.72), location: 0.0),
            .init(color: baseColor.opacity(op * 0.32), location: 0.40),
            .init(color: baseColor.opacity(op * 0.08), location: 0.75),
            .init(color: baseColor.opacity(0.0),       location: 1.0)
        ])

        let haloRect = CGRect(
            x: px - glowRadius, y: py - glowRadius,
            width: glowRadius * 2, height: glowRadius * 2
        )
        context.fill(
            Path(ellipseIn: haloRect),
            with: .radialGradient(
                haloGradient,
                center: CGPoint(x: px, y: py),
                startRadius: 0,
                endRadius: glowRadius
            )
        )

        // Layer 2: Crisp dot
        let dotRect = CGRect(
            x: px - radius, y: py - radius,
            width: radius * 2, height: radius * 2
        )
        context.fill(Path(ellipseIn: dotRect), with: .color(baseColor.opacity(op * 1.0)))

        // Layer 3: Hot white core for larger sparks
        if radius > 0.7 {
            let coreR = radius * 0.40
            let coreRect = CGRect(
                x: px - coreR, y: py - coreR,
                width: coreR * 2, height: coreR * 2
            )
            context.fill(
                Path(ellipseIn: coreRect),
                with: .color(Color.white.opacity(op * 0.65))
            )
        }
    }
}

// ─────────────────────────────────────────────
// MARK: Previews
// ─────────────────────────────────────────────

#Preview("StatView — full travel") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField().ignoresSafeArea()
        SparkField(config: .statView).ignoresSafeArea()
        VStack {
            Spacer()
            Text("1 in 5")
                .font(.system(size: 120, weight: .bold))
                .foregroundStyle(Color.orange)
            Spacer()
        }
    }
    .preferredColorScheme(.light)
}

#Preview("NameView — fades before card") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField().ignoresSafeArea()
        SparkField(config: .nameView).ignoresSafeArea()
        VStack {
            Spacer().frame(height: 200)
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .frame(height: 340)
                .padding(.horizontal, 28)
            Spacer()
        }
    }
    .preferredColorScheme(.light)
}

#Preview("ModeSelectView — lower third") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField().ignoresSafeArea()
        SparkField(config: .modeSelectView).ignoresSafeArea()
    }
    .preferredColorScheme(.light)
}

#Preview("ContextView — very subtle") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField().ignoresSafeArea()
        SparkField(config: .contextView).ignoresSafeArea()
    }
    .preferredColorScheme(.light)
}

#Preview("CuriosityPickerView — minimal") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField().ignoresSafeArea()
        SparkField(config: .curiosityPickerView).ignoresSafeArea()
    }
    .preferredColorScheme(.light)
}

#Preview("GroundRulesView — bottom quarter") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField().ignoresSafeArea()
        SparkField(config: .groundRulesView).ignoresSafeArea()
        VStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .frame(height: 500)
                .padding(.horizontal, 24)
                .padding(.top, 80)
            Spacer()
        }
    }
    .preferredColorScheme(.light)
}
