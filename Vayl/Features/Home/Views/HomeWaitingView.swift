//
//  HomeWaitingView.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/7/26.
//

import SwiftUI


// MARK: - HomeWaitingView

struct HomeWaitingView: View {
    let isPaired: Bool
    let partnerName: String
    let onInvite: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var headerVisible    = false
    @State private var statusVisible    = false
    @State private var ctaVisible       = false
    @State private var secondaryVisible = false
    @State private var hasAnimated      = false
    @State private var pulsing          = false

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
                    .padding(.horizontal, AppSpacing.lg)
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

    private func contentBlock(h: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: max(24.0, h * 0.036)) {

            // ── Overline ───────────────────────────────────────────
            Text("YOUR PART IS DONE")
                .font(AppFonts.overline)
                .tracking(2)
                .foregroundStyle(
                    colorScheme == .light
                        ? AnyShapeStyle(LinearGradient(
                            colors: [AppColors.accentTertiary, AppColors.safetyAccent],
                            startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(AppColors.accentPrimary)
                )
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : -8)

            // ── Headline ───────────────────────────────────────────
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(isPaired
                     ? "Now we wait for"
                     : "Invite your partner")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.textPrimary
                        : AppColors.textPrimary)

                if isPaired {
                    Text(displayPartnerName + ".")
                        .font(AppFonts.heroTitle)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.accentPrimary, AppColors.accentSecondary],
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
                    ? AppColors.textSecondary
                    : AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(statusVisible ? 1 : 0)
                .offset(y: statusVisible ? 0 : 8)

            // ── While you wait ─────────────────────────────────────
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("While you wait")
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.textSecondary
                        : AppColors.textSecondary)

                whileYouWaitRow(
                    icon: AppIcons.books,
                    text: "Browse the education library",
                    action: { /* route to Learn tab */ }
                )
                whileYouWaitRow(
                    icon: AppIcons.eye,
                    text: "Preview your first conversation deck",
                    action: { /* route to deck preview */ }
                )
            }
            .opacity(secondaryVisible ? 1 : 0)
            .offset(y: secondaryVisible ? 0 : 12)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.xl)
        .padding(.bottom, AppSpacing.md)
    }

    private var partnerStatusCard: some View {
        HStack(spacing: AppSpacing.md) {
            // Pulsing pending indicator — ambient loop driven by pulsing state.
            // ambientAnimation modifier on the views handles reduce motion.
            ZStack {
                Circle()
                    .fill(AppColors.accentPrimary.opacity(pulsing ? 0.15 : 0.06))
                    .frame(width: 36, height: 36)
                    .scaleEffect(pulsing ? 1.15 : 1.0)
                    .ambientAnimation(
                        .easeInOut(duration: AppAnimation.ambientPulse)
                            .repeatForever(autoreverses: true),
                        value: pulsing
                    )

                Circle()
                    .fill(AppColors.accentPrimary.opacity(0.3))
                    .frame(width: 10, height: 10)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(displayPartnerName)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.textPrimary
                        : AppColors.textPrimary)
                Text("Map in progress...")
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.textTertiary
                        : AppColors.textTertiary)
            }

            Spacer()

            Text("Waiting")
                .font(AppFonts.overline)
                .tracking(1)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background {
                    Capsule()
                        .fill(colorScheme == .light
                            ? AppColors.borderSubtle
                            : Color.white.opacity(0.06))
                }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(colorScheme == .light
                    ? AppColors.cardBackground
                    : AppColors.cardBackground)
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(colorScheme == .light
                    ? AppColors.borderSubtle
                    : AppColors.borderSubtle,
                    lineWidth: 1)
        }
    }

    private func whileYouWaitRow(
        icon: String,
        text: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    // .body scales with Dynamic Type — correct for
                    // row icons that accompany body-scale text.
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.accentSecondary
                        : AppColors.accentPrimary)
                    .frame(width: 20)

                Text(text)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.textPrimary
                        : AppColors.textPrimary)

                Spacer()

                Image(systemName: AppIcons.chevronRight)
                    // .caption scales with Dynamic Type — correct for
                    // trailing disclosure chevrons.
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.textTertiary
                        : AppColors.textTertiary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.md)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(colorScheme == .light
                        ? AppColors.glassFrostCard
                        : AppColors.cardBackground)
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(colorScheme == .light
                        ? AppColors.borderSubtle
                        : AppColors.borderSubtle,
                        lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var ctaBlock: some View {
        VStack(spacing: AppSpacing.md) {
            VaylButton(
                label: isPaired
                    ? "Remind \(displayPartnerName)"
                    : "Invite Your Partner"
            ) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onInvite()
            }
            .fixedSize(horizontal: false, vertical: true)
            .opacity(ctaVisible ? 1 : 0)
            .animation(AppAnimation.spring, value: ctaVisible)

            OnboardingFooter(
                text: isPaired
                    ? "We won't tell them how you answered."
                    : "They'll set up their own account and complete the map privately."
            )
        }
    }

    private func backgroundLayer(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            AppColors.pageBackground

            if colorScheme == .dark {
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.accentSecondary.opacity(0.20),
                            AppColors.accentSecondary.opacity(0.10),
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
                OnboardingAtmosphere()
            }
        }
        .ignoresSafeArea()
    }

    private func runEntranceAnimations() {
        // Choreographed entrance sequence — preserve all stagger delays.
        withAnimation(AppAnimation.slow.delay(0.15))  { headerVisible    = true }
        withAnimation(AppAnimation.slow.delay(0.30))  { statusVisible    = true }
        withAnimation(AppAnimation.slow.delay(0.50))  { secondaryVisible = true }
        withAnimation(AppAnimation.enter.delay(0.55)) { ctaVisible       = true }

        // Ambient pulsing — toggle boolean directly after delay.
        // The ambientAnimation modifier on the view handles the loop
        // and strips it under reduce motion. No withAnimation needed here.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            pulsing = true
        }
    }
}
