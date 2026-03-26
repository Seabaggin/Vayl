// Features/Onboarding/Views/OnboardingCardRevealView.swift
//
// Transition screen between BuildingPath and GroundRules.
// Shows the user a real prompt card before they agree to ground rules.
// Non-interactive except for a skip capsule — no data reads or writes.
//
// Animation phases:
//   Phase 1 (0.0–0.6s):  Two ghost cards fade in staggered
//   Phase 2 (0.6–1.6s):  Card flips via rotateY spring, edge light, glow sweep
//   Phase 3 (1.6s+):     Rest — breathing subtext, shimmer, skip capsule fade-in
//
// Color scheme: responds to system preference.
//   Dark  → deep space atmosphere (cyan / purple / magenta spectrum)
//   Light → warm cream aurora     (purple / magenta / gold, no cyan)
//
// A/B NOTE: swap cardText constant to test engagement variants.
// Do not seed from onboarding data — static card ensures clean
// single-variable testing.

import SwiftUI

struct OnboardingCardRevealView: View {
    var onContinue: (() -> Void)?

    // MARK: - Color Scheme
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Screen Size
    @State private var screenW: CGFloat = 393
    @State private var screenH: CGFloat = 852

    // MARK: - Animation State
    @State private var hasAnimated        = false
    @State private var didDisappear       = false

    @State private var ghostsVisible      = false
    @State private var flipDegrees        = -180.0   // starts at back side
    @State private var backFaceOpacity    = 1.0      // dark back, visible first
    @State private var cardLanded         = false
    @State private var landingGlowOpacity = 0.0      // 0 → 0.35 on land
    @State private var edgeLightScale     = 0.0      // scaleY 0 → 1
    @State private var edgeLightOpacity   = 0.0
    @State private var sweepOffset: CGFloat = -320   // glow sweep x position
    @State private var sweepOpacity       = 0.0
    @State private var subtextOpacity     = 0.0
    @State private var subtextPulse       = false
    @State private var skipVisible        = false
    @State private var shimmerActive      = false
    @State private var glowPeak           = false

    // iOS 26 — use UIAccessibility directly instead of
    // @Environment(\.accessibilityReduceMotion) which changed its
    // underlying type signature in iOS 26.
    private var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    // MARK: - Card Constants
    private let cardW: CGFloat = 300
    private let cardH: CGFloat = 400
    private let cardText     = "What's one thing about yourself you haven't said out loud yet?"
    private let cardCategory = "BEFORE WE BEGIN"
    private let cardSubtext  = "sit with this"

    // MARK: - Semantic Color Shorthands
    // Resolved per render — never stored, always fresh from environment.

    private var pageBg: Color {
        isLight ? AppColors.lightPageBg : AppColors.pageBg
    }

    private var cardBorder1: Color {
        isLight ? AppColors.purple.opacity(0.18) : AppColors.cyan
    }

    private var cardBorder2: Color {
        isLight ? AppColors.magenta.opacity(0.22) : AppColors.purple
    }

    private var cardBorder3: Color {
        isLight ? AppColors.gold.opacity(0.20) : AppColors.magenta
    }

    private var landingRingColors: [Color] {
        isLight
            ? [
                AppColors.purple.opacity(0.30),
                AppColors.magenta.opacity(0.25),
                AppColors.gold.opacity(0.20)
              ]
            : [
                AppColors.cyan.opacity(0.55),
                AppColors.purple.opacity(0.45),
                AppColors.magenta.opacity(0.35)
              ]
    }

    private var sweepColors: [Color] {
        isLight
            ? [
                Color.clear,
                AppColors.purple.opacity(0.20),
                AppColors.magenta.opacity(0.15),
                Color.clear
              ]
            : [
                Color.clear,
                AppColors.cyan.opacity(0.35),
                AppColors.purple.opacity(0.25),
                Color.clear
              ]
    }

    // MARK: - Body

    var body: some View {
        ZStack {

            // Size reader — invisible, just captures geo
            GeometryReader { geo in
                Color.clear.onAppear { cacheSize(geo.size) }
            }
            .ignoresSafeArea()

            // ── 1. Background ──────────────────────────────────────
            pageBg.ignoresSafeArea()

            // ── 2. Atmosphere ──────────────────────────────────────
            atmosphereLayer
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            // ── 3. Glow field (dark only) ──────────────────────────
            if !isLight {
                OnboardingGlowField()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }

            // ── 4. Card stack ──────────────────────────────────────
            ZStack {

                // Landing glow ring — behind everything
                RoundedRectangle(cornerRadius: 26)
                    .stroke(
                        LinearGradient(
                            colors: landingRingColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: cardW + 24, height: cardH + 24)
                    .blur(radius: isLight ? 8 : 12)
                    .opacity(landingGlowOpacity)
                    .allowsHitTesting(false)

                ghostDeck
                edgeLight

                darkBackFace
                    .opacity(backFaceOpacity)

                frontCard
                    .opacity(flipDegrees > -90 ? 1.0 : 0.0)

                // Sweep — shared geometry, scheme-aware colors
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: sweepColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 100, height: cardH)
                    .offset(x: sweepOffset)
                    .opacity(sweepOpacity)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .allowsHitTesting(false)
            }
            .rotation3DEffect(
                .degrees(flipDegrees),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.4
            )
            .accessibilityHidden(true)

            // ── 5. Subtext below card ──────────────────────────────
            VStack {
                Spacer()
                Text(cardSubtext)
                    .font(AppFonts.caption)
                    .italic()
                    .foregroundStyle(
                        isLight
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary
                    )
                    .opacity(subtextOpacity * (subtextPulse ? 0.80 : 0.45))
                    .animation(
                        .easeInOut(duration: 4.0).repeatForever(autoreverses: true),
                        value: subtextPulse
                    )
                    .padding(.bottom, screenH * 0.16)
            }
            .accessibilityHidden(true)

            // ── 6. Skip capsule ────────────────────────────────────
            VStack {
                HStack {
                    Spacer()
                    Button {
                        onContinue?()
                    } label: {
                        Text("skip")
                            .font(AppFonts.caption)
                            .foregroundStyle(
                                isLight
                                    ? AppColors.lightCardTitle.opacity(0.40)
                                    : AppColors.textTertiary
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(
                                        isLight
                                            ? Color.black.opacity(0.04)
                                            : Color.white.opacity(0.06)
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                isLight
                                                    ? Color.black.opacity(0.07)
                                                    : Color.white.opacity(0.08),
                                                lineWidth: 1
                                            )
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Skip")
                    .accessibilityHint("Skip to ground rules")
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                Spacer()
            }
            .opacity(skipVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.5), value: skipVisible)

            // ── 7. VoiceOver overlay ───────────────────────────────
            Color.clear
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Here's your first card. \(cardText). Take your time.")
                .accessibilityHint("Activate Skip to continue.")
                .accessibilityAction(named: "Skip") { onContinue?() }
        }
        .ignoresSafeArea()
        // No preferredColorScheme override — responds to system setting.
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true
            if reduceMotion {
                applyReducedMotion()
            } else {
                startAnimation()
            }
        }
        .onDisappear {
            didDisappear = true
        }
    }

    // MARK: - Ghost Deck

    private var ghostDeck: some View {
        ZStack {
            // Back ghost — furthest
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    isLight
                        ? Color.white.opacity(0.70)
                        : Color(red: 0.027, green: 0.027, blue: 0.063)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isLight
                                ? AppColors.lightBorder
                                : AppColors.border,
                            lineWidth: 1
                        )
                )
                .frame(width: cardW - 20, height: cardH - 12)
                .rotationEffect(.degrees(-5))
                .offset(x: -8, y: 12)
                .opacity(ghostsVisible ? (isLight ? 0.55 : 0.40) : 0)

            // Front ghost — closer
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    isLight
                        ? Color.white.opacity(0.80)
                        : Color(red: 0.027, green: 0.027, blue: 0.063)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isLight
                                ? AppColors.lightBorder
                                : AppColors.border,
                            lineWidth: 1
                        )
                )
                .frame(width: cardW - 10, height: cardH - 6)
                .rotationEffect(.degrees(4))
                .offset(x: 6, y: 8)
                .opacity(ghostsVisible ? (isLight ? 0.70 : 0.55) : 0)
        }
        .animation(.easeOut(duration: 0.45), value: ghostsVisible)
    }

    // MARK: - Dark Back Face
    // "Dark back face" in light mode becomes a warm-tinted cream reverse.

    private var darkBackFace: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: isLight
                            ? [
                                Color(red: 0.96, green: 0.93, blue: 0.96), // barely-plum cream
                                Color(red: 0.98, green: 0.96, blue: 0.99)
                              ]
                            : [
                                Color(red: 0.039, green: 0.000, blue: 0.063),
                                Color(red: 0.024, green: 0.000, blue: 0.031)
                              ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    isLight
                        ? AppColors.purple.opacity(0.15)
                        : AppColors.purple.opacity(0.25),
                    lineWidth: 1
                )

            Text("✦")
                .font(.system(size: 32))
                .foregroundStyle(
                    isLight
                        ? AppColors.purple.opacity(0.20)
                        : AppColors.purple.opacity(0.25)
                )
        }
        .frame(width: cardW, height: cardH)
        .shadow(
            color: isLight
                ? AppColors.purple.opacity(0.10)
                : AppColors.purple.opacity(0.20),
            radius: 20
        )
    }

    // MARK: - Front Card Face

    private var frontCard: some View {
        ZStack {

            // Base background
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: isLight
                            ? [
                                AppColors.lightCardBg,
                                Color(red: 0.99, green: 0.97, blue: 0.99) // barely-rose tint
                              ]
                            : [
                                Color(red: 0.027, green: 0.027, blue: 0.063),
                                Color(red: 0.020, green: 0.020, blue: 0.031)
                              ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Inner ambient wash
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    RadialGradient(
                        colors: isLight
                            ? [AppColors.magenta.opacity(0.05), Color.clear]
                            : [AppColors.purple.opacity(0.13), Color.clear],
                        center: UnitPoint(x: 0.3, y: 0.2),
                        startRadius: 0,
                        endRadius: cardW * 0.6
                    )
                )

            // Shimmer — Phase 3 only
            if shimmerActive {
                (isLight ? AppColors.purple.opacity(0.025) : AppColors.cyan.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 22))
            }

            // Spectrum border
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    LinearGradient(
                        colors: [cardBorder1, cardBorder2, cardBorder3],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isLight ? 1.0 : 1.5
                )

            // Card content
            VStack(alignment: .center, spacing: 0) {

                // Category overline
                Text(cardCategory)
                    .font(AppFonts.overline)
                    .foregroundStyle(
                        isLight
                            ? AppColors.lightCardTitle.opacity(0.40)
                            : AppColors.textTertiary
                    )
                    .tracking(2.0)
                    .padding(.top, 28)

                Spacer()

                // Prompt text
                VStack(spacing: 8) {
                    Text("What's one thing about")
                        .font(AppFonts.body(19, weight: .medium))
                        .foregroundStyle(
                            isLight
                                ? AppColors.lightCardTitle
                                : AppColors.textPrimary
                        )
                        .multilineTextAlignment(.center)

                    // "yourself" — gradient keyword
                    Text("yourself")
                        .font(AppFonts.body(22, weight: .semibold))
                        .foregroundStyle(
                            isLight
                                ? AppColors.warmAuroraText
                                : LinearGradient(
                                    colors: [
                                        AppColors.cyan,
                                        AppColors.purpleLight,
                                        AppColors.magenta
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )

                    Text("you haven't said\nout loud yet?")
                        .font(AppFonts.body(19, weight: .medium))
                        .foregroundStyle(
                            isLight
                                ? AppColors.lightCardTitle
                                : AppColors.textPrimary
                        )
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)

                Spacer()

                // Bottom mark
                Text("✦")
                    .font(AppFonts.overline)
                    .foregroundStyle(
                        isLight
                            ? AppColors.lightTextTertiary.opacity(0.5)
                            : AppColors.textTertiary.opacity(0.5)
                    )
                    .padding(.bottom, 24)
            }
        }
        .frame(width: cardW, height: cardH)
        // Light mode: aurora shadow stack — warm, not neon
        .shadow(
            color: isLight
                ? AppColors.purple.opacity(0.08)
                : AppColors.cyan.opacity(0.14),
            radius: 16
        )
        .shadow(
            color: isLight
                ? AppColors.magenta.opacity(0.12)
                : AppColors.purple.opacity(0.32),
            radius: 50
        )
        .shadow(
            color: isLight
                ? AppColors.gold.opacity(0.08)
                : AppColors.magenta.opacity(0.14),
            radius: 40,
            y: 8
        )
        .shadow(
            color: isLight
                ? Color.black.opacity(0.06)
                : Color.black.opacity(0.85),
            radius: 25,
            y: 25
        )
    }

    // MARK: - Edge Light

    private var edgeLight: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: isLight
                        ? [AppColors.purple, AppColors.magenta, AppColors.gold]
                        : [AppColors.cyan, AppColors.purple, AppColors.magenta],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 3, height: cardH)
            .scaleEffect(y: edgeLightScale, anchor: .top)
            .opacity(edgeLightOpacity)
            .blur(radius: 2)
            .shadow(
                color: isLight ? AppColors.purple : AppColors.cyan,
                radius: 8
            )
            .shadow(
                color: isLight ? AppColors.magenta : AppColors.purple,
                radius: 16
            )
            .offset(x: -(cardW / 2) - 2)
            .allowsHitTesting(false)
    }

    // MARK: - Atmosphere Layer
    // Dark: deep-space blooms (cyan / purple / magenta).
    // Light: warm aurora pools (magenta / purple / gold)
    //        — same positions, lower opacity, no cyan.

    private var atmosphereLayer: some View {
        ZStack {
            if isLight {
                lightAtmosphere
            } else {
                darkAtmosphere
            }
        }
    }

    // MARK: Dark Atmosphere (unchanged from original)

    private var darkAtmosphere: some View {
        ZStack {
            // Top bloom
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            AppColors.purple.opacity(0.40),
                            AppColors.cyan.opacity(0.20),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 30,
                        endRadius: 380
                    )
                )
                .frame(width: screenW * 1.4, height: screenH * 0.5)
                .offset(y: -screenH * 0.42)
                .blur(radius: 90)

            // Orb A — cyan, upper left
            Ellipse()
                .fill(AppColors.cyan.opacity(0.12))
                .frame(width: 180, height: 180)
                .blur(radius: 55)
                .offset(x: -screenW * 0.32, y: -screenH * 0.22)

            // Orb B — magenta, upper right
            Ellipse()
                .fill(AppColors.magenta.opacity(0.10))
                .frame(width: 140, height: 140)
                .blur(radius: 50)
                .offset(x: screenW * 0.32, y: -screenH * 0.26)

            // Orb C — purple, center
            Ellipse()
                .fill(AppColors.purple.opacity(0.14))
                .frame(width: 240, height: 240)
                .blur(radius: 80)

            // Orb D — cyan, lower left
            Ellipse()
                .fill(AppColors.cyan.opacity(0.08))
                .frame(width: 110, height: 110)
                .blur(radius: 42)
                .offset(x: -screenW * 0.38, y: screenH * 0.22)

            // Orb E — magenta, lower right
            Ellipse()
                .fill(AppColors.magenta.opacity(0.08))
                .frame(width: 150, height: 150)
                .blur(radius: 60)
                .offset(x: screenW * 0.38, y: screenH * 0.18)

            // Central glow burst
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            AppColors.purple.opacity(0.18),
                            AppColors.cyan.opacity(0.10),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .blur(radius: 70)
                .opacity(glowPeak ? 1.0 : 0)
                .animation(.easeInOut(duration: 2.0), value: glowPeak)

            // Spectrum vertical bleed
            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .clear,                          location: 0.03),
                            .init(color: AppColors.cyan.opacity(0.22),    location: 0.18),
                            .init(color: AppColors.purple.opacity(0.33),  location: 0.44),
                            .init(color: AppColors.magenta.opacity(0.28), location: 0.68),
                            .init(color: .clear,                          location: 0.92),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: glowPeak ? 4 : 1, height: screenH)
                .blur(radius: 3)
                .opacity(glowPeak ? 0.70 : 0.15)
                .animation(.easeInOut(duration: 2.0), value: glowPeak)

            // Bottom warmth
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.purple.opacity(0.10), Color.clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .opacity(glowPeak ? 1.0 : 0)
                .animation(.easeInOut(duration: 2.0), value: glowPeak)
        }
    }

    // MARK: Light Atmosphere — warm aurora pools

    private var lightAtmosphere: some View {
        ZStack {
            // Top bloom — magenta + purple, no cyan
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            AppColors.magenta.opacity(0.10),
                            AppColors.purple.opacity(0.07),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 30,
                        endRadius: 380
                    )
                )
                .frame(width: screenW * 1.4, height: screenH * 0.5)
                .offset(y: -screenH * 0.42)
                .blur(radius: 90)

            // Orb A — magenta, upper right (mirrors BuildingPath light)
            Ellipse()
                .fill(AppColors.auroraBlob1)          // magenta 0.09
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: screenW * 0.30, y: -screenH * 0.24)

            // Orb B — purple, upper left
            Ellipse()
                .fill(AppColors.purple.opacity(0.07))
                .frame(width: 160, height: 160)
                .blur(radius: 55)
                .offset(x: -screenW * 0.32, y: -screenH * 0.20)

            // Orb C — purple, center
            Ellipse()
                .fill(AppColors.auroraBlob2)          // purple 0.08
                .frame(width: 240, height: 240)
                .blur(radius: 80)

            // Orb D — gold, lower right
            Ellipse()
                .fill(AppColors.auroraBlob3)          // gold 0.07
                .frame(width: 150, height: 150)
                .blur(radius: 55)
                .offset(x: screenW * 0.36, y: screenH * 0.20)

            // Orb E — pink, mid left
            Ellipse()
                .fill(AppColors.auroraBlob4)          // pink 0.06
                .frame(width: 120, height: 120)
                .blur(radius: 45)
                .offset(x: -screenW * 0.36, y: screenH * 0.10)

            // Central glow burst — purple / magenta on cream
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            AppColors.purple.opacity(0.08),
                            AppColors.magenta.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .blur(radius: 70)
                .opacity(glowPeak ? 1.0 : 0)
                .animation(.easeInOut(duration: 2.0), value: glowPeak)

            // Warm vertical bleed — very subtle on cream
            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .clear,                          location: 0.03),
                            .init(color: AppColors.purple.opacity(0.06),  location: 0.18),
                            .init(color: AppColors.magenta.opacity(0.08), location: 0.44),
                            .init(color: AppColors.gold.opacity(0.06),    location: 0.68),
                            .init(color: .clear,                          location: 0.92),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: glowPeak ? 4 : 1, height: screenH)
                .blur(radius: 3)
                .opacity(glowPeak ? 0.40 : 0.08)
                .animation(.easeInOut(duration: 2.0), value: glowPeak)

            // Bottom gold warmth
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.gold.opacity(0.06), Color.clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .opacity(glowPeak ? 1.0 : 0)
                .animation(.easeInOut(duration: 2.0), value: glowPeak)
        }
    }

    // MARK: - Size Cache

    private func cacheSize(_ size: CGSize) {
        screenW = size.width
        screenH = size.height
    }

    // MARK: - Reduce Motion

    private func applyReducedMotion() {
        glowPeak           = true
        ghostsVisible      = true
        flipDegrees        = 0
        backFaceOpacity    = 0
        cardLanded         = true
        landingGlowOpacity = 0.35
        subtextOpacity     = 1.0
        subtextPulse       = true
        skipVisible        = true
        shimmerActive      = false
        edgeLightScale     = 0
        edgeLightOpacity   = 0
    }

    // MARK: - Animation Timeline

    private func startAnimation() {
        #if DEBUG
        assert(
            onContinue != nil,
            "OnboardingCardRevealView: onContinue not injected — wire from coordinator."
        )
        #endif

        glowPeak = true

        // ── Phase 1: Ghost deck ────────────────── 0.15s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            guard !didDisappear else { return }
            withAnimation(.easeOut(duration: 0.45)) {
                ghostsVisible = true
            }
        }

        // ── Phase 2: Edge light fires before flip ─ 0.55s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            guard !didDisappear else { return }
            withAnimation(.easeOut(duration: 0.40)) {
                edgeLightScale   = 1.0
                edgeLightOpacity = 1.0
            }
        }

        // ── Phase 2: Card flip starts ─────────── 0.65s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            guard !didDisappear else { return }
            withAnimation(.spring(response: 0.65, dampingFraction: 0.78)) {
                flipDegrees = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                guard !didDisappear else { return }
                withAnimation(.easeOut(duration: 0.15)) {
                    backFaceOpacity = 0
                }
            }
        }

        // ── Card lands ───────────────────────── 1.30s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.30) {
            guard !didDisappear else { return }
            cardLanded = true

            withAnimation(.easeOut(duration: 0.8)) {
                landingGlowOpacity = 0.35
            }
            withAnimation(.easeOut(duration: 0.5)) {
                edgeLightOpacity = 0
            }

            sweepOffset  = -(cardW / 2) - 60
            sweepOpacity = 0.9
            withAnimation(.easeOut(duration: 0.45)) {
                sweepOffset = (cardW / 2) + 60
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.30)) {
                sweepOpacity = 0
            }
        }

        // ── Phase 3: Subtext ─────────────────── 1.90s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.90) {
            guard !didDisappear else { return }
            withAnimation(.easeOut(duration: 0.6)) {
                subtextOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                guard !didDisappear else { return }
                subtextPulse = true
            }
        }

        // ── Phase 3: Shimmer ─────────────────── 2.20s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.20) {
            guard !didDisappear else { return }
            shimmerActive = true
        }

        // ── Phase 3: Skip capsule ────────────── 2.40s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.40) {
            guard !didDisappear else { return }
            withAnimation(.easeOut(duration: 0.5)) {
                skipVisible = true
            }
        }
    }
}

// MARK: - Previews

#Preview("Dark — Default") {
    OnboardingCardRevealView(onContinue: {})
        .preferredColorScheme(.dark)
}

#Preview("Light — Default") {
    OnboardingCardRevealView(onContinue: {})
        .preferredColorScheme(.light)
}

#Preview("Dark — Reduce Motion") {
    OnboardingCardRevealView(onContinue: {})
        .preferredColorScheme(.dark)
        // UIAccessibility.isReduceMotionEnabled cannot be forced in previews;
        // applyReducedMotion() fires automatically when the device flag is on.
}

#Preview("Light — Reduce Motion") {
    OnboardingCardRevealView(onContinue: {})
        .preferredColorScheme(.light)
}

#Preview("Light — SE 375pt") {
    OnboardingCardRevealView(onContinue: {})
        .preferredColorScheme(.light)
        .frame(width: 375, height: 667)
}

#Preview("Dark — SE 375pt") {
    OnboardingCardRevealView(onContinue: {})
        .preferredColorScheme(.dark)
        .frame(width: 375, height: 667)
}
