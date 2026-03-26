//
//  HomeWaitingView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/23/26.
//


// HomeWaitingView.swift
// Open Lightly
//
// Home tab — Waiting state (S4)
// Shown when: user has completed their Desire Map, partner hasn't.
// Also shown when: user hasn't paired yet (isPaired: false).
//
// Primary goal: re-surface the invite mechanism without feeling pushy.
// Secondary: genuine value while they wait (education, preview).

import SwiftUI

struct HomeWaitingView: View {
    let isPaired: Bool
    let partnerName: String     // Empty string if unpaired
    let onInvite: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var headerVisible  = false
    @State private var statusVisible  = false
    @State private var ctaVisible     = false
    @State private var secondaryVisible = false
    @State private var hasAnimated    = false
    @State private var pulsing        = false

    private var displayPartnerName: String {
        partnerName.isEmpty ? "your partner" : partnerName
    }

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    contentBlock(h: h)
                }
                ctaBlock
                    .padding(.horizontal, 24)
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

    private func contentBlock(h: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: max(24.0, h * 0.036)) {

            // ── Overline ───────────────────────────────────────────
            Text("YOUR PART IS DONE")
                .font(AppFonts.overline)
                .tracking(2)
                .foregroundStyle(
                    colorScheme == .light
                        ? AnyShapeStyle(LinearGradient(
                            colors: [AppColors.magenta, AppColors.gold],
                            startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(AppColors.cyanLight)
                )
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : -8)

            // ── Headline ───────────────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                Text(isPaired
                     ? "Now we wait for"
                     : "Invite your partner")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)

                if isPaired {
                    Text(displayPartnerName + ".")
                        .font(AppFonts.heroTitle)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.cyan, AppColors.purple],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                }
            }
            .opacity(headerVisible ? 1 : 0)
            .offset(y: headerVisible ? 0 : 12)

            // ── Partner status indicator ───────────────────────────
            if isPaired {
                partnerStatusCard
                    .opacity(statusVisible ? 1 : 0)
                    .offset(y: statusVisible ? 0 : 12)
            }

            // ── Context copy ───────────────────────────────────────
            Text(isPaired
                 ? "Their answers are private too. When they're done, you'll see what you have in common."
                 : "They'll complete their own map privately. When you're both done, you'll see your first shared result.")
                .font(AppFonts.bodyText)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextSecondary
                    : AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(statusVisible ? 1 : 0)
                .offset(y: statusVisible ? 0 : 8)

            // ── While you wait ─────────────────────────────────────
            VStack(alignment: .leading, spacing: 12) {
                Text("While you wait")
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary)

                whileYouWaitRow(
                    icon: "books.vertical.fill",
                    text: "Browse the education library",
                    action: { /* route to Learn tab */ }
                )
                whileYouWaitRow(
                    icon: "eye.fill",
                    text: "Preview your first conversation deck",
                    action: { /* route to deck preview */ }
                )
            }
            .opacity(secondaryVisible ? 1 : 0)
            .offset(y: secondaryVisible ? 0 : 12)
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
        .padding(.bottom, 16)
    }

    // MARK: - Partner Status Card

    private var partnerStatusCard: some View {
        HStack(spacing: 14) {
            // Pulsing pending indicator
            ZStack {
                Circle()
                    .fill(AppColors.cyan.opacity(pulsing ? 0.15 : 0.06))
                    .frame(width: 36, height: 36)
                    .scaleEffect(pulsing ? 1.15 : 1.0)

                Circle()
                    .fill(AppColors.cyan.opacity(0.3))
                    .frame(width: 10, height: 10)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(displayPartnerName)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)
                Text("Map in progress...")
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
            }

            Spacer()

            Text("Waiting")
                .font(AppFonts.overline)
                .tracking(1)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background {
                    Capsule()
                        .fill(colorScheme == .light
                            ? AppColors.lightBorder
                            : Color.white.opacity(0.06))
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .light
                    ? AppColors.lightCardFill
                    : AppColors.cardBg)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(colorScheme == .light
                    ? AppColors.lightBorder
                    : AppColors.border,
                    lineWidth: 1)
        }
    }

    // MARK: - While You Wait Row

    private func whileYouWaitRow(
        icon: String,
        text: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.purple
                        : AppColors.cyanLight)
                    .frame(width: 20)

                Text(text)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .light
                        ? AppColors.lightFrostCard
                        : AppColors.cardBg)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorScheme == .light
                        ? AppColors.lightBorder
                        : AppColors.border,
                        lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - CTA Block

    private var ctaBlock: some View {
        VStack(spacing: 16) {
            HoloCTAButton(
                title: isPaired
                    ? "Remind \(displayPartnerName)"
                    : "Invite Your Partner",
                isEnabled: true
            ) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onInvite()
            }
            .fixedSize(horizontal: false, vertical: true)
            .opacity(ctaVisible ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.82), value: ctaVisible)

            OnboardingFooter(
                text: isPaired
                    ? "We won't tell them how you answered."
                    : "They'll set up their own account and complete the map privately."
            )
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
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.purple.opacity(0.20),
                            AppColors.deepBlue.opacity(0.10),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 30,
                        endRadius: 360
                    ))
                    .frame(width: w * 1.4, height: h * 0.50)
                    .offset(y: -h * 0.08)
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
        withAnimation(.easeOut(duration: 0.5).delay(0.15)) { headerVisible    = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.30)) { statusVisible    = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.50)) { secondaryVisible = true }
        withAnimation(.easeOut(duration: 0.4).delay(0.55)) { ctaVisible       = true }

        // Pulsing partner status loop
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulsing = true
            }
        }
    }
}

// MARK: - Previews

#Preview("Paired — Dark") {
    HomeWaitingView(isPaired: true, partnerName: "Alex", onInvite: {})
        .preferredColorScheme(.dark)
}

#Preview("Unpaired — Dark") {
    HomeWaitingView(isPaired: false, partnerName: "", onInvite: {})
        .preferredColorScheme(.dark)
}

#Preview("Paired — Light") {
    HomeWaitingView(isPaired: true, partnerName: "Alex", onInvite: {})
        .preferredColorScheme(.light)
}