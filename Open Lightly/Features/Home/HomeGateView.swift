//
//  HomeGateView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/23/26.
//


// HomeGateView.swift
// Open Lightly
//
// Home tab — Gate state (S1 / S3)
// Shown when: user has not completed their Desire Map.
// Whether paired or not, the primary CTA is the same: start the map.
// Learn tab escape hatch is a secondary link, never a consolation prize.

import SwiftUI

struct HomeGateView: View {
    let isPaired: Bool
    let onStartMap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var headerVisible     = false
    @State private var cardVisible       = false
    @State private var detailVisible     = false
    @State private var ctaVisible        = false
    @State private var hasAnimated       = false

    // Subtle breathing glow behind the CTA
    @State private var breathe: Bool = false

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width

            let topPad      = max(16.0, h * 0.04)
            let sectionGap  = max(20.0, h * 0.032)
            let cardPad     = max(16.0, h * 0.022)

            ViewThatFits(in: .vertical) {

                // Attempt 1 — preferred, no scroll
                VStack(spacing: 0) {
                    contentBlock(h: h, sectionGap: sectionGap,
                                 cardPad: cardPad, topPad: topPad)
                    Spacer(minLength: 0)
                    ctaBlock
                        .padding(.horizontal, 24)
                }

                // Attempt 2 — scroll fallback (SE + large text)
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        contentBlock(h: h, sectionGap: sectionGap,
                                     cardPad: cardPad, topPad: topPad)
                    }
                    ctaBlock
                        .padding(.horizontal, 24)
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

    // MARK: - Content Block

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
                        colors: [AppColors.magenta, AppColors.gold],
                        startPoint: .leading, endPoint: .trailing))
                    : AnyShapeStyle(AppColors.cyanLight))
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : -8)

            // ── Headline ───────────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                Text("Before you can see")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)

                Text("what you share —")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)

                // Gradient keyword line
                Text("know what YOU want.")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(
                        colorScheme == .light
                            ? AnyShapeStyle(LinearGradient(
                                colors: [AppColors.magenta, AppColors.gold],
                                startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(LinearGradient(
                                colors: [AppColors.cyan, AppColors.purple],
                                startPoint: .leading, endPoint: .trailing))
                    )
            }
            .opacity(headerVisible ? 1 : 0)
            .offset(y: headerVisible ? 0 : 12)

            // ── Info card ──────────────────────────────────────────
            VStack(alignment: .leading, spacing: 14) {
                infoRow(
                    icon: "lock.fill",
                    text: "17 questions. Your answers stay **completely private**."
                )
                infoRow(
                    icon: "clock.fill",
                    text: "About **5 minutes**. No wrong answers."
                )
                infoRow(
                    icon: "eye.slash.fill",
                    text: isPaired
                        ? "Your partner **never sees** your individual answers — only what you both agree on."
                        : "When your partner joins, they'll **never see** your individual answers."
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, cardPad)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .light
                        ? AppColors.lightCardFill
                        : AppColors.cardBg)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        colorScheme == .light
                            ? AppColors.lightBorder
                            : AppColors.border,
                        lineWidth: 1
                    )
            }
            .opacity(cardVisible ? 1 : 0)
            .offset(y: cardVisible ? 0 : 12)

            // ── Reassurance ────────────────────────────────────────
            Text("There are no right answers. Just yours.")
                .font(AppFonts.caption)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextSecondary
                    : AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(detailVisible ? 1 : 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, topPad)
        .padding(.bottom, 16)
    }

    // MARK: - Info Row

    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon badge
            ZStack {
                Circle()
                    .fill(colorScheme == .light
                        ? AppColors.magenta.opacity(0.08)
                        : AppColors.cyan.opacity(0.10))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.magenta
                        : AppColors.cyan)
            }
            .fixedSize()

            // Markdown-style bold text
            // Using AttributedString for inline bold
            Text(parseInlineBold(text))
                .font(AppFonts.bodyText)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextPrimary
                    : AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
    }

    // MARK: - CTA Block

    private var ctaBlock: some View {
        VStack(spacing: 16) {

            // Primary CTA
            HoloCTAButton(
                title: "Start Your Desire Map",
                isEnabled: true
            ) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onStartMap()
            }
            .fixedSize(horizontal: false, vertical: true)
            .opacity(ctaVisible ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.82), value: ctaVisible)

            // Education escape hatch
            Button {
                // Route to Learn tab
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 12, weight: .medium))
                    Text("Browse the education library while you wait")
                        .font(AppFonts.caption)
                }
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextSecondary
                    : AppColors.textSecondary)
            }
            .buttonStyle(.plain)
            .opacity(ctaVisible ? 1 : 0)
            .animation(
                .easeOut(duration: 0.4).delay(0.1),
                value: ctaVisible
            )

            // Footer
            OnboardingFooter(text: "Your answers are encrypted and never leave your device.")
        }
    }

    // MARK: - Background

    private func backgroundLayer(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            if colorScheme == .light {
                AppColors.lightPageBg
            } else {
                AppColors.pageBg
            }

            if colorScheme == .dark {
                // Atmospheric ellipse — purple top wash
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.purple.opacity(0.25),
                            AppColors.deepBlue.opacity(0.12),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 30,
                        endRadius: 360
                    ))
                    .frame(width: w * 1.4, height: h * 0.55)
                    .offset(y: -h * 0.1)
                    .blur(radius: 80)
            }

            if colorScheme == .light {
                AuroraGlowField()
            } else {
                OnboardingGlowField()
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Animations

    private func runEntranceAnimations() {
        withAnimation(.easeOut(duration: 0.5).delay(0.15)) { headerVisible = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.30)) { cardVisible   = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.50)) { detailVisible = true }
        withAnimation(.easeOut(duration: 0.4).delay(0.55)) { ctaVisible    = true }

        // Breathing glow loop — starts after entrance settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }

    // MARK: - Inline Bold Parser

    /// Converts **text** markers to AttributedString bold spans.
    /// Keeps font consistent — only weight changes.
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

// MARK: - Previews

#Preview("Dark — Unpaired") {
    HomeGateView(isPaired: false, onStartMap: {})
        .preferredColorScheme(.dark)
}

#Preview("Dark — Paired") {
    HomeGateView(isPaired: true, onStartMap: {})
        .preferredColorScheme(.dark)
}

#Preview("Light — Unpaired") {
    HomeGateView(isPaired: false, onStartMap: {})
        .preferredColorScheme(.light)
}

#Preview("SE — Dark") {
    HomeGateView(isPaired: true, onStartMap: {})
        .preferredColorScheme(.dark)
}