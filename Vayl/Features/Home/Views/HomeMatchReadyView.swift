//
//  HomeMatchReadyView.swift
//  Open Lightly
//
//  Consolidated home state views — Gate, Waiting, and MatchReady.
//  Each struct represents a distinct navigation state in the HomeRouterView.
//

import SwiftUI



// MARK: - HomeMatchReadyView

struct HomeMatchReadyView: View {
    let onReveal: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var readyVisible    = false
    @State private var bodyVisible     = false
    @State private var ctaVisible      = false
    @State private var togetherVisible = false
    @State private var hasAnimated     = false
    @State private var bloom: Bool     = false

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width

            VStack(spacing: 0) {
                Spacer()

                // ── Core content — deliberately centered ──────────
                VStack(spacing: max(24.0, h * 0.034)) {

                    // Particle burst placeholder
                    // Replace with ParticleBurstView when built (Risk 3 in DESIGN_DOC)
                    HStack(spacing: AppSpacing.md) {
                        ForEach(0..<5) { i in
                            Circle()
                                .fill(
                                    [AppColors.accentPrimary, AppColors.accentSecondary,
                                     AppColors.accentTertiary, AppColors.accentPrimary,
                                     AppColors.accentSecondary][i]
                                    .opacity(bloom ? 0.9 : 0.4)
                                )
                                .frame(width: 6, height: 6)
                                .scaleEffect(bloom ? 1.2 : 0.8)
                                // Choreographed stagger — preserve per-element delay multiplier.
                                // ambientAnimation handles reduce motion removal.
                                .ambientAnimation(
                                    .easeInOut(duration: AppAnimation.ambientPulse)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.18),
                                    value: bloom
                                )
                        }
                    }
                    .opacity(readyVisible ? 1 : 0)

                    VStack(spacing: AppSpacing.sm) {
                        Text("You're both ready.")
                            .font(AppFonts.heroTitle)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: colorScheme == .light
                                        ? [AppColors.accentTertiary, AppColors.safetyAccent]
                                        : [AppColors.accentPrimary, AppColors.accentSecondary, AppColors.accentTertiary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                    }
                    .opacity(readyVisible ? 1 : 0)
                    .offset(y: readyVisible ? 0 : 16)

                    Text("One thing you agree on\nis waiting to be seen.")
                        .font(AppFonts.bodyText)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.textSecondary
                            : AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(bodyVisible ? 1 : 0)
                }
                .padding(.horizontal, AppSpacing.xl)

                Spacer()

                // ── CTA — pinned to bottom ─────────────────────────
                VStack(spacing: AppSpacing.md) {
                    VaylButton(
                        label: "See Your First Match"
                    ) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onReveal()
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(ctaVisible ? 1 : 0)
                    .animation(AppAnimation.spring, value: ctaVisible)

                    Text("Do this together.")
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.textTertiary
                            : AppColors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .opacity(togetherVisible ? 1 : 0)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
            .frame(width: w, height: h)
            .background { backgroundLayer(w: w, h: h) }
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                runEntranceAnimations()
            }
        }
    }

    private func backgroundLayer(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            AppColors.pageBackground

            if colorScheme == .dark {
                // Tri-color bloom — all three spectrum colors present.
                // ambientAnimation drives opacity changes and removes
                // the loop entirely under reduce motion.
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.accentPrimary.opacity(bloom ? 0.18 : 0.10),
                            AppColors.accentSecondary.opacity(bloom ? 0.14 : 0.08),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 20,
                        endRadius: 400
                    ))
                    .frame(width: w * 1.6, height: h * 0.6)
                    .offset(y: -h * 0.05)
                    .blur(radius: 90)
                    .ambientAnimation(
                        .easeInOut(duration: AppAnimation.ambientPulse)
                            .repeatForever(autoreverses: true),
                        value: bloom
                    )

                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.accentTertiary.opacity(bloom ? 0.12 : 0.06),
                            Color.clear
                        ],
                        center: .bottom,
                        startRadius: 10,
                        endRadius: 300
                    ))
                    .frame(width: w * 1.2, height: h * 0.4)
                    .offset(y: h * 0.15)
                    .blur(radius: 80)
                    .ambientAnimation(
                        .easeInOut(duration: AppAnimation.ambientPulse)
                            .repeatForever(autoreverses: true),
                        value: bloom
                    )
            }

            if colorScheme == .light {
                AuroraGlowField()
            } else {
                OnboardingAtmosphere()
            }
        }
        .ignoresSafeArea()
    }

    private func runEntranceAnimations() {
        // Choreographed entrance — deliberate slowness, this screen gets more ceremony.
        // Preserve all stagger delays. Base animations mapped to nearest tokens.
        withAnimation(AppAnimation.slow.delay(0.30))  { readyVisible    = true }
        withAnimation(AppAnimation.slow.delay(0.60))  { bodyVisible     = true }
        withAnimation(AppAnimation.enter.delay(0.90)) { ctaVisible      = true }
        withAnimation(AppAnimation.enter.delay(1.05)) { togetherVisible = true }

        // Ambient bloom — toggle boolean directly after delay.
        // The ambientAnimation modifiers on the background ellipses handle
        // the repeat loop and strip it under reduce motion.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            bloom = true
        }
    }
}
