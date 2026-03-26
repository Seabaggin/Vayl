//
//  HomeMatchReadyView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/23/26.
//


// HomeMatchReadyView.swift
// Open Lightly
//
// Home tab — Match Ready state (S5)
// Shown when: both partners have completed the Desire Map, reveal not yet seen.
//
// This is the highest-tension screen in the entire app.
// Design intent: maximum restraint. One CTA. No clutter. No secondary actions.
// The pacing IS the experience — this screen should feel like the moment
// before opening something important.

import SwiftUI

struct HomeMatchReadyView: View {
    let onReveal: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var readyVisible   = false
    @State private var bodyVisible    = false
    @State private var ctaVisible     = false
    @State private var togetherVisible = false
    @State private var hasAnimated    = false

    // Spectrum bloom breathing — this screen's signature
    @State private var bloom: Bool = false

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
                    HStack(spacing: 12) {
                        ForEach(0..<5) { i in
                            Circle()
                                .fill(
                                    [AppColors.cyan, AppColors.purple,
                                     AppColors.magenta, AppColors.cyan,
                                     AppColors.purple][i]
                                    .opacity(bloom ? 0.9 : 0.4)
                                )
                                .frame(width: 6, height: 6)
                                .scaleEffect(bloom ? 1.2 : 0.8)
                                .animation(
                                    .easeInOut(duration: 1.4)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.18),
                                    value: bloom
                                )
                        }
                    }
                    .opacity(readyVisible ? 1 : 0)

                    // Headline
                    VStack(spacing: 6) {
                        Text("You're both ready.")
                            .font(AppFonts.heroTitle)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: colorScheme == .light
                                        ? [AppColors.magenta, AppColors.gold]
                                        : [AppColors.cyan, AppColors.purple, AppColors.magenta],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                    }
                    .opacity(readyVisible ? 1 : 0)
                    .offset(y: readyVisible ? 0 : 16)

                    // Body
                    Text("One thing you agree on\nis waiting to be seen.")
                        .font(AppFonts.bodyText)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextSecondary
                            : AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(bodyVisible ? 1 : 0)
                }
                .padding(.horizontal, 32)

                Spacer()

                // ── CTA — pinned to bottom ─────────────────────────
                VStack(spacing: 12) {
                    HoloCTAButton(
                        title: "See Your First Match",
                        isEnabled: true
                    ) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onReveal()
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(ctaVisible ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.82), value: ctaVisible)

                    // "Do this together" — only instruction on this screen
                    Text("Do this together.")
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .opacity(togetherVisible ? 1 : 0)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
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

    // MARK: - Background
    // Maximum atmospheric treatment — this screen earns full spectrum bloom.

    private func backgroundLayer(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            if colorScheme == .light {
                AppColors.lightPageBg
            } else {
                AppColors.pageBg
            }

            if colorScheme == .dark {
                // Tri-color bloom — all three spectrum colors present
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.cyan.opacity(bloom ? 0.18 : 0.10),
                            AppColors.purple.opacity(bloom ? 0.14 : 0.08),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 20,
                        endRadius: 400
                    ))
                    .frame(width: w * 1.6, height: h * 0.6)
                    .offset(y: -h * 0.05)
                    .blur(radius: 90)

                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.magenta.opacity(bloom ? 0.12 : 0.06),
                            Color.clear
                        ],
                        center: .bottom,
                        startRadius: 10,
                        endRadius: 300
                    ))
                    .frame(width: w * 1.2, height: h * 0.4)
                    .offset(y: h * 0.15)
                    .blur(radius: 80)
            }

            if colorScheme == .light {
                AuroraGlowField()
            } else {
                OnboardingGlowField()
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: bloom)
    }

    // MARK: - Animations

    private func runEntranceAnimations() {
        // Deliberate slowness — this screen gets more ceremony
        withAnimation(.easeOut(duration: 0.7).delay(0.30)) { readyVisible    = true }
        withAnimation(.easeOut(duration: 0.6).delay(0.60)) { bodyVisible     = true }
        withAnimation(.easeOut(duration: 0.4).delay(0.90)) { ctaVisible      = true }
        withAnimation(.easeOut(duration: 0.4).delay(1.05)) { togetherVisible = true }

        // Bloom breathing — starts after content settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                bloom = true
            }
        }
    }
}

// MARK: - Previews

#Preview("Dark") {
    HomeMatchReadyView(onReveal: {})
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    HomeMatchReadyView(onReveal: {})
        .preferredColorScheme(.light)
}