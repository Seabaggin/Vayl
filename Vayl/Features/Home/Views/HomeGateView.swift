//
//  HomeGateView.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/7/26.
//

import SwiftUI

// MARK: - HomeGateView

struct HomeGateView: View {
    let isPaired: Bool
    let onStartMap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var headerVisible = false
    @State private var cardVisible   = false
    @State private var detailVisible = false
    @State private var ctaVisible    = false
    @State private var hasAnimated   = false
    @State private var breathe: Bool = false

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width

            // Geometry-relative layout values — intentional adaptive
            // calculations, not spacing token candidates.
            let topPad     = max(16.0, h * 0.04)
            let sectionGap = max(20.0, h * 0.032)
            let cardPad    = max(16.0, h * 0.022)

            ViewThatFits(in: .vertical) {

                // Attempt 1 — preferred, no scroll
                VStack(spacing: 0) {
                    contentBlock(h: h, sectionGap: sectionGap,
                                 cardPad: cardPad, topPad: topPad)
                    Spacer(minLength: 0)
                    ctaBlock
                        .padding(.horizontal, AppSpacing.lg)
                }

                // Attempt 2 — scroll fallback (SE + large text)
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        contentBlock(h: h, sectionGap: sectionGap,
                                     cardPad: cardPad, topPad: topPad)
                    }
                    ctaBlock
                        .padding(.horizontal, AppSpacing.lg)
                }
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

    private func contentBlock(
        h: CGFloat,
        sectionGap: CGFloat,
        cardPad: CGFloat,
        topPad: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: sectionGap) {

            // ── Overline ───────────────────────────────────────────
            Text("STEP 1 OF 2")
                .font(AppFonts.overline)
                .tracking(2)
                .foregroundStyle(colorScheme == .light
                    ? AnyShapeStyle(LinearGradient(
                        colors: [AppColors.accentTertiary, AppColors.safetyAccent],
                        startPoint: .leading, endPoint: .trailing))
                    : AnyShapeStyle(AppColors.accentPrimary))
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : -8)

            // ── Headline ───────────────────────────────────────────
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Before you can see")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.textPrimary
                        : AppColors.textPrimary)

                Text("what you share —")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.textPrimary
                        : AppColors.textPrimary)

                Text("know what YOU want.")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(
                        colorScheme == .light
                            ? AnyShapeStyle(LinearGradient(
                                colors: [AppColors.accentTertiary, AppColors.safetyAccent],
                                startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(LinearGradient(
                                colors: [AppColors.accentPrimary, AppColors.accentSecondary],
                                startPoint: .leading, endPoint: .trailing))
                    )
            }
            .opacity(headerVisible ? 1 : 0)
            .offset(y: headerVisible ? 0 : 12)

            // ── Info card ──────────────────────────────────────────
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                infoRow(
                    icon: AppIcons.lock,
                    text: "17 questions. Your answers stay **completely private**."
                )
                infoRow(
                    icon: AppIcons.clock,
                    text: "About **5 minutes**. No wrong answers."
                )
                infoRow(
                    icon: AppIcons.eyeSlash,
                    text: isPaired
                        ? "Your partner **never sees** your individual answers — only what you both agree on."
                        : "When your partner joins, they'll **never see** your individual answers."
                )
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, cardPad)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(colorScheme == .light
                        ? AppColors.cardBackground
                        : AppColors.cardBackground)
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(
                        colorScheme == .light
                            ? AppColors.borderSubtle
                            : AppColors.borderSubtle,
                        lineWidth: 1
                    )
            }
            .opacity(cardVisible ? 1 : 0)
            .offset(y: cardVisible ? 0 : 12)

            // ── Reassurance ────────────────────────────────────────
            Text("There are no right answers. Just yours.")
                .font(AppFonts.caption)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.textSecondary
                    : AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(detailVisible ? 1 : 0)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, topPad)
        .padding(.bottom, AppSpacing.md)
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(colorScheme == .light
                        ? AppColors.accentTertiary.opacity(0.08)
                        : AppColors.accentPrimary.opacity(0.10))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    // .caption scales with Dynamic Type — correct for
                    // icon badges that accompany body-scale text.
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.accentTertiary
                        : AppColors.accentPrimary)
            }
            .fixedSize()

            Text(parseInlineBold(text))
                .font(AppFonts.bodyText)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.textPrimary
                    : AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
    }

    private var ctaBlock: some View {
        VStack(spacing: AppSpacing.md) {

            VaylButton(
                label: "Start Your Desire Map"
            ) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onStartMap()
            }
            .fixedSize(horizontal: false, vertical: true)
            .opacity(ctaVisible ? 1 : 0)
            .animation(AppAnimation.spring, value: ctaVisible)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: AppIcons.books)
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("Browse the education library while you wait")
                        .font(AppFonts.caption)
                }
                .foregroundStyle(colorScheme == .light
                    ? AppColors.textSecondary
                    : AppColors.textSecondary)
            }
            .buttonStyle(.plain)
            .opacity(ctaVisible ? 1 : 0)
            .animation(AppAnimation.enter.delay(0.1), value: ctaVisible)

            OnboardingFooter(text: "Your answers are encrypted and never leave your device.")
        }
    }

    private func backgroundLayer(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            AppColors.pageBackground

            if colorScheme == .dark {
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.accentSecondary.opacity(0.25),
                            AppColors.accentSecondary.opacity(0.12),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 30,
                        endRadius: 360
                    ))
                    .frame(width: w * 1.4, height: h * 0.55)
                    .offset(y: -h * 0.1)
                    .blur(radius: 80)
                    // Ambient breathe — decorative glow pulse behind content.
                    // ambientAnimation removes this entirely under reduce motion.
                    .ambientAnimation(
                        .easeInOut(duration: AppAnimation.ambientPulse)
                            .repeatForever(autoreverses: true),
                        value: breathe
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
        // Choreographed entrance sequence — preserve all stagger delays.
        withAnimation(AppAnimation.slow.delay(0.15))  { headerVisible = true }
        withAnimation(AppAnimation.slow.delay(0.30))  { cardVisible   = true }
        withAnimation(AppAnimation.slow.delay(0.50))  { detailVisible = true }
        withAnimation(AppAnimation.enter.delay(0.55)) { ctaVisible    = true }

        // Ambient breathe — toggle boolean directly after delay.
        // The ambientAnimation modifier on the view handles the loop
        // and strips it under reduce motion. No withAnimation needed here.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            breathe = true
        }
    }

    private func parseInlineBold(_ raw: String) -> AttributedString {
        var result = AttributedString()
        let parts  = raw.components(separatedBy: "**")
        for (i, part) in parts.enumerated() {
            var segment = AttributedString(part)
            if i % 2 == 1 {
                segment.font = AppFonts.bodyMedium
            }
            result.append(segment)
        }
        return result
    }
}

