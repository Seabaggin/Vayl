import SwiftUI
import Combine

struct OnboardingBrandView: View {

    var onFinished: (() -> Void)? = nil

    // MARK: - Accessibility

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Screen geometry

    @State private var screenW: CGFloat = 393
    @State private var screenH: CGFloat = 852

    // MARK: - Canvas bloom state

    @State private var bl1Width: CGFloat = 6
    @State private var bl1Opacity: Double = 0.8
    @State private var hotWidth: CGFloat = 3
    @State private var hotOpacity: Double = 0.6
    @State private var thickWidth: CGFloat = 0
    @State private var thickOpacity: Double = 0
    @State private var centerGlowOpacity: Double = 0
    @State private var centerGlowScale: CGFloat = 1.0
    @State private var wisp1Opacity: Double = 0
    @State private var wisp2Opacity: Double = 0
    @State private var wisp3Opacity: Double = 0
    @State private var wisp1Offset: CGSize = .zero
    @State private var wisp1Scale: CGFloat = 1.0
    @State private var wisp2Offset: CGSize = .zero
    @State private var wisp2Scale: CGFloat = 1.0
    @State private var wisp3Offset: CGSize = .zero
    @State private var wisp3Scale: CGFloat = 1.0
    @State private var floorWidth: CGFloat = 0
    @State private var floorOpacity: Double = 0
    @State private var floorScaleX: CGFloat = 1.0

    // MARK: - Holo gradient sweep state

    @State private var holoPhase: CGFloat = 0
    @State private var holoPhaseB: CGFloat = 0

    // MARK: - Wordmark per-word state

    @State private var openOpacity: Double = 0
    @State private var openScale: CGFloat = 0.90
    @State private var openOffsetY: CGFloat = 12
    @State private var lightlyOpacity: Double = 0
    @State private var lightlyScale: CGFloat = 0.92
    @State private var lightlyOffsetY: CGFloat = 10
    @State private var wordmarkBreath: CGFloat = 1.0

    // MARK: - Tagline state
    //
    // taglineOpacity is EXIT-ONLY — starts at 1.0, only animated to 0 on exit.
    // No positional animation on the container — always at final position.
    //
    // Line 1 enters t=1950ms easeOut(0.22) → done t=2170ms
    // Line 2 enters t=2150ms easeOut(0.22) → done t=2370ms
    // Stagger gap (200ms) > duration × 0.7 (154ms) — reading beat honoured.
    // Exit does not begin until t=4500ms — 2130ms+ of settled dwell.

    @State private var taglineOpacity: Double = 1.0
    @State private var taglineBreath: Double = 0.55
    @State private var line1Opacity: Double = 0
    @State private var line2Opacity: Double = 0

    // MARK: - Global state

    @State private var autoAdvanceFired = false
    @State private var filamentStarted = false
    @State private var glowFieldOpacity: Double = 0
    @State private var sceneEntryOpacity: Double = 0
    @State private var ambientLoopsActive = false

    // NOTE: fadeOutOpacity REMOVED — coordinator owns the cover.

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let w = screenW
            let h = screenH

            ZStack {
                Color.clear.ignoresSafeArea()

                wisps(w: w, h: h)
                    .allowsHitTesting(false)

                centerGlow()
                    .allowsHitTesting(false)

                floorReflection(h: h)
                    .allowsHitTesting(false)

                if filamentStarted {
                    FilamentView(size: screenW, mode: .solo, speed: 1.0, showConnections: false)
                        .frame(width: screenW, height: screenW)
                        .position(x: w / 2, y: h * 0.46)
                        .allowsHitTesting(false)
                }

                wordmark
                    .scaleEffect(wordmarkBreath)
                    .position(x: w / 2 + 8, y: h * 0.46)
                    .accessibilityHidden(true)

                taglineView
                    .position(x: w / 2, y: h * 0.571)
                    .accessibilityHidden(true)

                // NOTE: No fadeOutOpacity cover layer here.
                // The coordinator's cover sits above this entire view.

                #if DEBUG
                VStack {
                    Spacer()
                Button("↺ Replay") { replay() }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.4))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .padding(.bottom, 48)
                }
                #endif

                // Accessibility: invisible, VoiceOver only.
                VStack(spacing: 4) {
                    Text("Open Lightly")
                    Text("Hard Conversations, Made Easier.")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Open Lightly. Hard Conversations, Made Easier.")
                .opacity(0)
                .allowsHitTesting(false)
            }
            .opacity(sceneEntryOpacity)
            .drawingGroup()
        }
        .ignoresSafeArea()
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { size in
            screenW = size.width
            screenH = size.height
        }
        .onAppear { startEverything() }
        .onDisappear {
            filamentStarted   = false
            ambientLoopsActive = false
            // autoAdvanceFired intentionally NOT reset here.
            // It is a one-way latch to prevent double-fire of the 5.20s handoff timer.
            // If the view reappears before the timer fires, the latch prevents
            // the timer from firing onFinished() twice. If the view cycles
            // (appear → disappear → reappear), startEverything() resets it explicitly
            // on the next onAppear, breaking the latch for a clean restart.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                wisp1Opacity      = 0
                wisp2Opacity      = 0
                wisp3Opacity      = 0
                centerGlowOpacity = 0
                floorOpacity      = 0
                glowFieldOpacity  = 0
                holoPhase         = 0
                holoPhaseB        = 0
                wordmarkBreath    = 1.0
                taglineBreath     = 0.55
            }
        }
    }

    // MARK: - Background layers

    private func bleedInit(h: CGFloat) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .clear,                          location: 0.02),
                        .init(color: AppColors.cyan.opacity(0.12),    location: 0.12),
                        .init(color: AppColors.purple.opacity(0.22),  location: 0.30),
                        .init(color: AppColors.magenta.opacity(0.20), location: 0.50),
                        .init(color: AppColors.purple.opacity(0.18),  location: 0.70),
                        .init(color: AppColors.pink.opacity(0.10),    location: 0.88),
                        .init(color: .clear,                          location: 0.98)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: bl1Width, height: h)
            .opacity(bl1Opacity)
    }

    private func bleedThick(h: CGFloat) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .clear,                           location: 0.05),
                        .init(color: AppColors.magenta.opacity(0.14),  location: 0.20),
                        .init(color: AppColors.purple.opacity(0.20),   location: 0.40),
                        .init(color: AppColors.cyan.opacity(0.12),     location: 0.60),
                        .init(color: AppColors.pink.opacity(0.14),     location: 0.80),
                        .init(color: .clear,                           location: 0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: thickWidth, height: h)
            .blur(radius: 40)
            .opacity(thickOpacity)
    }

    private func bleedHot(h: CGFloat) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.10),
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.10),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: hotWidth, height: h * 0.8)
            .opacity(hotOpacity)
    }

    private func centerGlow() -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    stops: [
                        .init(color: AppColors.purple.opacity(0.10),  location: 0),
                        .init(color: AppColors.magenta.opacity(0.06), location: 0.40),
                        .init(color: .clear,                          location: 0.70)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 150
                )
            )
            .frame(width: 250, height: 150)
            .scaleEffect(centerGlowScale)
            .blur(radius: 50)
            .opacity(centerGlowOpacity)
    }

    private func wisps(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(AppColors.cyan.opacity(0.06))
                .frame(width: 120, height: 80)
                .blur(radius: 35)
                .scaleEffect(wisp1Scale)
                .offset(wisp1Offset)
                .offset(x: -w * 0.15, y: -h * 0.12)
                .opacity(wisp1Opacity)

            Ellipse()
                .fill(AppColors.magenta.opacity(0.05))
                .frame(width: 80, height: 120)
                .blur(radius: 35)
                .scaleEffect(wisp2Scale)
                .offset(wisp2Offset)
                .offset(x: w * 0.18, y: h * 0.02)
                .opacity(wisp2Opacity)

            Ellipse()
                .fill(AppColors.purple.opacity(0.06))
                .frame(width: 100, height: 90)
                .blur(radius: 35)
                .scaleEffect(wisp3Scale)
                .offset(wisp3Offset)
                .offset(x: -w * 0.05, y: h * 0.18)
                .opacity(wisp3Opacity)
        }
    }

    private func floorReflection(h: CGFloat) -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    stops: [
                        .init(color: AppColors.magenta.opacity(0.10), location: 0),
                        .init(color: AppColors.purple.opacity(0.08),  location: 0.40),
                        .init(color: .clear,                          location: 0.70)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: floorWidth * 0.5
                )
            )
            .frame(width: floorWidth, height: 90)
            .scaleEffect(x: floorScaleX, y: 1.0)
            .blur(radius: 35)
            .opacity(floorOpacity)
            .offset(y: h * 0.36)
    }

    // MARK: - Wordmark

    private var wordmark: some View {
        VStack(spacing: screenH < 700 ? -10 : -16) {
            Text("Open")
                .font(.custom("Zodiak-Extrabold", size: 58))
                .tracking(-1.5)
                .italic()
                .foregroundStyle(
                    isLight
                        ? AnyShapeStyle(AppColors.purple)
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan, AppColors.cyan, AppColors.purple],
                            startPoint: UnitPoint(
                                x: -0.5 + holoPhase * 0.4,
                                y:  0.0 + holoPhase * 0.2
                            ),
                            endPoint: UnitPoint(
                                x:  1.5 + holoPhase * 0.4,
                                y:  1.0 + holoPhase * 0.2
                            )
                          ))
                )
                .opacity(openOpacity)
                .scaleEffect(openScale)
                .offset(y: openOffsetY)

            Text("Lightly")
                .font(.custom("Zodiak-Bold", size: 54))
                .tracking(2)
                .foregroundStyle(
                    isLight
                        ? AnyShapeStyle(AppColors.orangeHot)
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.magenta, AppColors.pink, AppColors.pink],
                            startPoint: UnitPoint(
                                x: -0.5 + holoPhaseB * 0.4,
                                y:  0.0 + holoPhaseB * 0.2
                            ),
                            endPoint: UnitPoint(
                                x:  1.5 + holoPhaseB * 0.4,
                                y:  1.0 + holoPhaseB * 0.2
                            )
                          ))
                )
                .opacity(lightlyOpacity)
                .scaleEffect(lightlyScale)
                .offset(y: lightlyOffsetY)
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Tagline

    private var taglineView: some View {
        VStack(spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("Hard")
                    .font(.custom("Switzer-Regular", size: 18))
                    .foregroundColor(
                        isLight
                            ? AppColors.wineDark
                            : Color.white
                    )
                Text("Conversations")
                    .font(.custom("Switzer-Light", size: 18))
                    .foregroundStyle(
                        isLight
                            ? AnyShapeStyle(LinearGradient(
                                stops: [
                                    .init(color: AppColors.magenta,   location: 0.00),
                                    .init(color: AppColors.orangeHot, location: 0.55),
                                    .init(color: AppColors.gold,      location: 1.00),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                            : AnyShapeStyle(LinearGradient(
                                colors: [
                                    AppColors.cyan,
                                    AppColors.purpleLight,
                                    AppColors.magenta,
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                    )
            }
            .opacity(line1Opacity)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("Made")
                    .font(.custom("Switzer-Regular", size: 18))
                    .foregroundColor(
                        isLight
                            ? AppColors.wineDark
                            : Color.white
                    )
                Text("Easier")
                    .font(.custom("Switzer-Light", size: 18))
                    .foregroundStyle(
                        isLight
                            ? AnyShapeStyle(LinearGradient(
                                stops: [
                                    .init(color: AppColors.magenta,   location: 0.00),
                                    .init(color: AppColors.orangeHot, location: 0.55),
                                    .init(color: AppColors.gold,      location: 1.00),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                            : AnyShapeStyle(LinearGradient(
                                colors: [
                                    AppColors.cyan,
                                    AppColors.purpleLight,
                                    AppColors.magenta,
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                    )
            }
            .opacity(line2Opacity)
        }
        .font(.custom("Switzer-Light", size: 18))
        .tracking(0.3)
        .multilineTextAlignment(.center)
        .opacity(taglineOpacity)
    }

    // MARK: - Replay (DEBUG only)

    private func replay() {
        #if DEBUG
        if autoAdvanceFired {
            print("[OnboardingBrandView] ⚠️ replay() called after " +
                  "ambient loops started — cancelling in-flight loops.")
        }
        #endif

        // Cancel any in-flight ambient loops before restarting
        withAnimation(.default) {
            ambientLoopsActive = false
        }

        bl1Width          = 6
        bl1Opacity        = 0.8
        hotWidth          = 3
        hotOpacity        = 0.6
        thickWidth        = 0
        thickOpacity      = 0
        centerGlowOpacity = 0
        centerGlowScale   = 1.0
        wisp1Opacity      = 0
        wisp2Opacity      = 0
        wisp3Opacity      = 0
        wisp1Offset       = .zero
        wisp2Offset       = .zero
        wisp3Offset       = .zero
        wisp1Scale        = 1.0
        wisp2Scale        = 1.0
        wisp3Scale        = 1.0
        floorWidth        = 0
        floorOpacity      = 0
        floorScaleX       = 1.0
        holoPhase         = 0
        holoPhaseB        = 0
        openOpacity       = 0
        openScale         = 0.90
        openOffsetY       = 12
        lightlyOpacity    = 0
        lightlyScale      = 0.92
        lightlyOffsetY    = 10
        wordmarkBreath    = 1.0
        taglineOpacity    = 1.0
        taglineBreath     = 0.55
        line1Opacity      = 0
        line2Opacity      = 0
        glowFieldOpacity  = 0
        sceneEntryOpacity = 0
        filamentStarted   = false
        autoAdvanceFired  = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            startEverything()
        }
    }

    // MARK: - Animation timeline
    //
    // FINAL TIMELINE (v7 — Layered Dissolve) total runtime ~5020ms to handoff:
    //
    //   t=0ms       Canvas bloom begins
    //   t=300ms     Filament starts (skipped if reduceMotion)
    //   t=600ms     "Open" lands
    //   t=900ms     "Lightly" lands
    //   t=1000ms    Glow field begins (dark: 2.5s creep / light: 0.6s)
    //   t=1800ms    Atmospheric loops begin (skipped if reduceMotion)
    //   t=2000ms    Wordmark gradient sweep begins
    //   t=2200ms    Wordmark breath begins
    //   t=1950ms    Line 1 fades in — easeOut(0.22) done t=2170ms
    //   t=2150ms    Line 2 fades in — easeOut(0.22) done t=2370ms
    //   t=2370ms–4500ms  Fully settled dwell (~2130ms)
    //   t=4500ms    Tagline exits     — easeIn(160ms)  done t=4660ms
    //   t=4700ms    Wordmark exits    — easeIn(280ms)  done t=4980ms
    //   t=4780ms    Atmosphere exits  — easeIn(400ms)  done t=5180ms
    //   t=5020ms    onFinished() fires — coordinator takes over
    //
    //   COORDINATOR then:
    //   +0ms    NextScreen renders under cover (already opaque)
    //   +50ms   Cover lifts — easeOut(320ms)
    //   +410ms  Cover gone, NextScreen fully visible
    //   +450ms  BrandView removed from hierarchy

    private func startEverything() {

        // ── Scene entry fade ──────────────────────
        withAnimation(.easeOut(duration: 0.4)) {
            sceneEntryOpacity = 1.0
        }

        // ── Phase 1: Canvas bloom (0ms) ──────────────────────────────────

        withAnimation(.easeOut(duration: 1.2)) {
            bl1Width   = 420
            bl1Opacity = 0.18
        }
        withAnimation(.easeOut(duration: 0.8)) {
            hotWidth   = 200
            hotOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(.easeOut(duration: 1.4)) {
                thickWidth   = 420
                thickOpacity = 0.22
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.8)) {
                wisp1Opacity      = 1.0
                wisp2Opacity      = 1.0
                wisp3Opacity      = 1.0
                centerGlowOpacity = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 1.0)) {
                floorWidth   = 360
                floorOpacity = 0.4
            }
        }

        // ── Glow field ────────────────────────────────────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 2.5)) {
                glowFieldOpacity = 1.0
            }
        }

        // ── Phase 2: "Open" lands (600ms) ────────────────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.60) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
                openOpacity = 1.0
                openScale   = 1.0
                openOffsetY = 0
            }
        }

        // ── Filament (300ms) ─────────────────────────────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            if !reduceMotion {
                filamentStarted = true
            }
        }

        // ── Phase 2b: "Lightly" lands (900ms) ────────────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.90) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
                lightlyOpacity = 1.0
                lightlyScale   = 1.0
                lightlyOffsetY = 0
            }
        }

        // ── Ambient loops — staggered ignition (v7) ───────────────────────
        //
        // Three separate dispatch times prevent the "loop bomb" where all
        // repeatForever transactions fire on the same RunLoop tick:
        //
        //   t=1800ms  Atmospheric layer (wisps, glow, floor)
        //   t=2000ms  Gradient sweep (holoPhase, holoPhaseB)
        //   t=2200ms  Wordmark breath (wordmarkBreath, taglineBreath)
        //
        // 200ms micro-stagger is sub-perceptual as a pause but spreads
        // GPU transaction load across frames.
        //
        // ambientLoopsActive gate prevents competing animations on view
        // recycle (appear → disappear → reappear). When disabled in
        // onDisappear, any in-flight repeatForever loops are cancelled.
        // replay() explicitly cancels ambientLoopsActive before replay.

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.80) {
            guard !reduceMotion else { return }
            withAnimation(
                ambientLoopsActive
                    ? .easeInOut(duration: 6).repeatForever(autoreverses: true)
                    : .default
            ) {
                ambientLoopsActive = true
                wisp1Offset     = CGSize(width: 20,  height: -15)
                wisp1Scale      = 1.10
                wisp2Offset     = CGSize(width: -18, height: 18)
                wisp2Scale      = 1.12
                wisp3Offset     = CGSize(width: 12,  height: 15)
                wisp3Scale      = 1.08
                centerGlowScale = 1.2
                floorScaleX     = 1.06
                floorOpacity    = 0.6
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.00) {
            guard !reduceMotion else { return }
            withAnimation(
                ambientLoopsActive
                    ? .easeInOut(duration: 5.2).repeatForever(autoreverses: true)
                    : .default
            ) {
                holoPhase  = 1.0
                holoPhaseB = 1.0
            }
            withAnimation(
                ambientLoopsActive
                    ? .easeInOut(duration: 5.5).repeatForever(autoreverses: true)
                    : .default
            ) {
                taglineBreath = 0.72
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.20) {
            guard !reduceMotion else { return }
            withAnimation(
                ambientLoopsActive
                    ? .easeInOut(duration: 5.0).repeatForever(autoreverses: true)
                    : .default
            ) {
                wordmarkBreath = 1.02
            }
        }

        // ── Tagline entrance ──────────────────────────────────────────────
        //
        // Stagger gap (200ms) > duration × 0.7 (154ms) — Line 1 fully
        // opaque before Line 2 starts. Reading beat is honoured.

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.95) {
            withAnimation(.easeOut(duration: 0.22)) {
                line1Opacity = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.15) {
            withAnimation(.easeOut(duration: 0.22)) {
                line2Opacity = 1.0
            }
        }

        // ── Settled dwell: t=2370ms → t=4500ms (~2130ms) ─────────────────

        // ── Phase 4: Exit sequence ────────────────────────────────────────
        //
        // Beat 1 — Tagline dissolves (t=4500ms, 160ms)
        // Beat 2 — Wordmark contracts+fades (t=4700ms, 280ms)
        //          Starts 40ms after tagline done (4660ms + 40ms buffer)
        // Beat 3 — Atmosphere fades (t=4780ms, 400ms)
        //          Overlaps wordmark tail — bg layer has lower priority
        // Handoff — onFinished() at t=5020ms
        //          40ms before atmosphere fully done (5180ms)
        //          Coordinator receives and starts cover lift

        // Beat 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.50) {
            withAnimation(.easeIn(duration: 0.16)) {
                taglineOpacity = 0
            }
        }

        // Beat 2
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.70) {
            withAnimation(.easeIn(duration: 0.28)) {
                openOpacity    = 0
                openScale      = 0.96
                lightlyOpacity = 0
                lightlyScale   = 0.96
            }
        }

        // Beat 3
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.78) {
            withAnimation(.easeIn(duration: 0.40)) {
                glowFieldOpacity  = 0
                centerGlowOpacity = 0
                wisp1Opacity      = 0
                wisp2Opacity      = 0
                wisp3Opacity      = 0
                floorOpacity      = 0
            }
        }

        // ── Handoff (5020ms) ─────────────────────────────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.85) {
            withAnimation(.easeIn(duration: 0.35)) {
                sceneEntryOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.20) {
            guard !autoAdvanceFired else { return }
            autoAdvanceFired = true
            #if DEBUG
            assert(
                onFinished != nil,
                "OnboardingBrandView: onFinished not injected — " +
                "wire this callback from the coordinator."
            )
            #endif
            onFinished?()
        }
    }
}

// MARK: - Previews

#Preview("Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .brand,
            sparkConfig: .statView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
        OnboardingBrandView(onFinished: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .brand,
            sparkConfig: .statView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
        OnboardingBrandView(onFinished: {})
    }
    .preferredColorScheme(.light)
}
 
