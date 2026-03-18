import SwiftUI

struct OnboardingBrandView: View {

    var onFinished: (() -> Void)? = nil

    @State private var screenW: CGFloat = 393
    @State private var screenH: CGFloat = 852

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

    @State private var holoPhase: CGFloat = 0
    @State private var holoPhaseB: CGFloat = 0

    // ✦ NEW — per-word wordmark states (replaces wordmarkOpacity / wordmarkScale)
    @State private var openOpacity: Double = 0
    @State private var openScale: CGFloat = 0.90
    @State private var openOffsetY: CGFloat = 12
    @State private var lightlyOpacity: Double = 0
    @State private var lightlyScale: CGFloat = 0.92
    @State private var lightlyOffsetY: CGFloat = 10

    @State private var wordmarkBreath: CGFloat = 1.0
    @State private var taglineOpacity: Double = 0
    @State private var taglineOffset: CGFloat = 8
    @State private var taglineBreath: Double = 0.28

    // ✦ REMOVED — barVisible, barProgress (progress bar cut)

    @State private var autoAdvanceFired = false
    @State private var fadeOutOpacity: Double = 0

    var body: some View {
        GeometryReader { geo in
            let _ = cacheSize(geo.size)
            let w = screenW
            let h = screenH

            ZStack {
                AppColors.pageBg.ignoresSafeArea()

                wisps(w: w, h: h)
                    .allowsHitTesting(false)

                centerGlow()
                    .allowsHitTesting(false)

                floorReflection(h: h)
                    .allowsHitTesting(false)

                bleedThick(h: h)
                    .allowsHitTesting(false)

                bleedInit(h: h)
                    .allowsHitTesting(false)

                bleedHot(h: h)
                    .allowsHitTesting(false)

                // ✦ CHANGED — wordmark now uses per-word opacity,
                // breath still on the VStack wrapper
                wordmark
                    .scaleEffect(wordmarkBreath)
                    .position(x: w / 2 + 8, y: h * 0.46)

                taglineView
                    .position(x: w / 2, y: h * 0.64)

                // ✦ REMOVED — progressBar

                // ✦ CHANGED — fadeOut goes to 1.0 now (full cover)
                AppColors.pageBg
                    .opacity(fadeOutOpacity)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
            .drawingGroup()
        }
        .ignoresSafeArea()
        .onAppear { startEverything() }
    }

    // MARK: - Helpers (unchanged)

    private func cacheSize(_ size: CGSize) {
        if screenW != size.width || screenH != size.height {
            DispatchQueue.main.async {
                screenW = size.width
                screenH = size.height
            }
        }
    }

    private func bleedInit(h: CGFloat) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.02),
                        .init(color: AppColors.cyan.opacity(0.12), location: 0.12),
                        .init(color: AppColors.purple.opacity(0.22), location: 0.30),
                        .init(color: AppColors.magenta.opacity(0.20), location: 0.50),
                        .init(color: AppColors.purple.opacity(0.18), location: 0.70),
                        .init(color: AppColors.pink.opacity(0.10), location: 0.88),
                        .init(color: .clear, location: 0.98)
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
                        .init(color: .clear, location: 0.05),
                        .init(color: AppColors.magenta.opacity(0.14), location: 0.20),
                        .init(color: AppColors.purple.opacity(0.20), location: 0.40),
                        .init(color: AppColors.cyan.opacity(0.12), location: 0.60),
                        .init(color: AppColors.pink.opacity(0.14), location: 0.80),
                        .init(color: .clear, location: 0.95)
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
                        .init(color: AppColors.purple.opacity(0.10), location: 0),
                        .init(color: AppColors.magenta.opacity(0.06), location: 0.40),
                        .init(color: .clear, location: 0.70)
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
                        .init(color: AppColors.purple.opacity(0.08), location: 0.40),
                        .init(color: .clear, location: 0.70)
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

    // ✦ CHANGED — each word has its own opacity/scale/offset
    private var wordmark: some View {
        VStack(spacing: -16) {
            Text("Open")
                .font(.custom("Zodiak-Extrabold", size: 58))
                .tracking(-1.5)
                .italic()
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.cyan, AppColors.cyan, AppColors.purple],
                        startPoint: UnitPoint(
                            x: -0.5 + holoPhase * 0.4,
                            y: 0.0 + holoPhase * 0.2
                        ),
                        endPoint: UnitPoint(
                            x: 1.5 + holoPhase * 0.4,
                            y: 1.0 + holoPhase * 0.2
                        )
                    )
                )
                .opacity(openOpacity)
                .scaleEffect(openScale)
                .offset(y: openOffsetY)

            Text("Lightly")
                .font(.custom("Zodiak-Bold", size: 54))
                .tracking(2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.magenta, AppColors.pink, AppColors.pink],
                        startPoint: UnitPoint(
                            x: -0.5 + holoPhaseB * 0.4,
                            y: 0.0 + holoPhaseB * 0.2
                        ),
                        endPoint: UnitPoint(
                            x: 1.5 + holoPhaseB * 0.4,
                            y: 1.0 + holoPhaseB * 0.2
                        )
                    )
                )
                .opacity(lightlyOpacity)
                .scaleEffect(lightlyScale)
                .offset(y: lightlyOffsetY)
        }
        .multilineTextAlignment(.center)
    }

    private var taglineView: some View {
        Text("Explore what\u{2019}s possible.")
            .font(.custom("GeneralSans-Regular", size: 15))
            .foregroundColor(.white.opacity(taglineBreath))
            .tracking(0.3)
            .opacity(taglineOpacity)
            .offset(y: taglineOffset)
    }

    // ✦ REMOVED — progressBar computed property

    // MARK: - Replay

    func replay() {
        bl1Width = 6
        bl1Opacity = 0.8
        hotWidth = 3
        hotOpacity = 0.6
        thickWidth = 0
        thickOpacity = 0
        centerGlowOpacity = 0
        centerGlowScale = 1.0
        wisp1Opacity = 0
        wisp2Opacity = 0
        wisp3Opacity = 0
        wisp1Offset = .zero
        wisp2Offset = .zero
        wisp3Offset = .zero
        wisp1Scale = 1.0
        wisp2Scale = 1.0
        wisp3Scale = 1.0
        floorWidth = 0
        floorOpacity = 0
        floorScaleX = 1.0
        holoPhase = 0
        holoPhaseB = 0

        // ✦ CHANGED — reset per-word states
        openOpacity = 0
        openScale = 0.90
        openOffsetY = 12
        lightlyOpacity = 0
        lightlyScale = 0.92
        lightlyOffsetY = 10

        wordmarkBreath = 1.0
        taglineOpacity = 0
        taglineOffset = 8
        taglineBreath = 0.28
        fadeOutOpacity = 0
        autoAdvanceFired = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            startEverything()
        }
    }

    // MARK: - ✦ CHANGED — Entire animation timeline

    private func startEverything() {

        // ── Phase 1: Canvas bloom (0ms) ──────────────────────
        // All ambient layers launch together so the canvas is
        // warm by the time the wordmark drops at 500ms.

        withAnimation(.easeOut(duration: 1.2)) {
            bl1Width = 420
            bl1Opacity = 0.18
        }

        withAnimation(.easeOut(duration: 0.8)) {
            hotWidth = 200
            hotOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 1.4)) {
                thickWidth = 420
                thickOpacity = 0.22
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.8)) {
                wisp1Opacity = 1.0
                wisp2Opacity = 1.0
                wisp3Opacity = 1.0
                centerGlowOpacity = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 1.0)) {
                floorWidth = 360
                floorOpacity = 0.4
            }
        }

        // ── Phase 2: "Open" lands (500ms) ───────────────────
        // Spring with slight overshoot — brand arrives with
        // confidence. 12pt upward travel gives direction.

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
                openOpacity = 1.0
                openScale = 1.0
                openOffsetY = 0
            }
        }

        // ── Phase 2b: "Lightly" lands (680ms) ──────────────
        // 180ms stagger creates "Open... Lightly" micro-narrative

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.68) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
                lightlyOpacity = 1.0
                lightlyScale = 1.0
                lightlyOffsetY = 0
            }
        }

        // ── Phase 3: Tagline (1100ms) ───────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeOut(duration: 0.5)) {
                taglineOpacity = 1.0
                taglineOffset = 0
            }
        }

        // ── Ambient loops (after wordmark settles, ~1000ms) ─
        // Consolidated: fewer dispatch calls, same organic feel.
        // Different durations (5, 5.5, 6s) create phase-shifting.

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(
                .easeInOut(duration: 6)
                    .repeatForever(autoreverses: true)
            ) {
                wisp1Offset = CGSize(width: 20, height: -15)
                wisp1Scale = 1.10
                wisp2Offset = CGSize(width: -18, height: 18)
                wisp2Scale = 1.12
                wisp3Offset = CGSize(width: 12, height: 15)
                wisp3Scale = 1.08
                centerGlowScale = 1.2
                floorScaleX = 1.06
                floorOpacity = 0.6
            }

            withAnimation(
                .easeInOut(duration: 5)
                    .repeatForever(autoreverses: true)
            ) {
                holoPhase = 1.0
                wordmarkBreath = 1.02
            }

            withAnimation(
                .easeInOut(duration: 5.5)
                    .repeatForever(autoreverses: true)
            ) {
                holoPhaseB = 1.0
                taglineBreath = 0.38
            }
        }

        // ── Phase 4: Wordmark retreats (2800ms) ────────────
        // Words fade + scale up slightly (rising away).
        // easeIn for exits — accelerates out of view.

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeIn(duration: 0.4)) {
                openOpacity = 0
                openScale = 1.04
                lightlyOpacity = 0
                lightlyScale = 1.04
            }
        }

        // ── Tagline lingers 200ms longer, then fades ────────
        // Last thing user reads: "Explore what's possible."
        // → immediately answered by "1 in 5" on next screen.

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeIn(duration: 0.3)) {
                taglineOpacity = 0
            }
        }

        // ── Phase 5: Full screen fade (3200ms) ─────────────
        // easeIn (not easeOut) — exits accelerate.
        // 1.0 opacity (not 0.85) — clean seam, no ghost frame.

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation(.easeIn(duration: 0.3)) {
                fadeOutOpacity = 1.0
            }
        }

        // ── Handoff (3500ms) ────────────────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            guard !autoAdvanceFired else { return }
            autoAdvanceFired = true
            onFinished?()
        }
    }
}

#Preview {
    OnboardingBrandView()
        .preferredColorScheme(.dark)
}
