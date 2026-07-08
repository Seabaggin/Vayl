//
//  SignInView.swift
//  Vayl
//

import SwiftUI

struct SignInView: View {

    // MARK: - Dependencies

    var auth: AuthStore

    @State private var legalDoc: LegalDoc?

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let layout = AppLayout.from(geo)

            ZStack {
                // Background
                AppColors.pageBackground
                    .ignoresSafeArea()

                // Atmosphere
                atmosphereLayer

                VStack(spacing: 0) {

                    Spacer()

                    // ── Wordmark block ────────────────────────────────
                    VStack(spacing: AppSpacing.sm) {
                        Text("VAYL")
                            .font(AppFonts.display(
                                layout.isSmallDevice ? 38 : 44,
                                weight: .bold,
                                relativeTo: .largeTitle
                            ))
                            .tracking(4)
                            .foregroundStyle(AppColors.spectrumText)

                        Text("Explore intimacy at your own pace")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.xxl)
                    }

                    Spacer()
                    Spacer()

                    // ── CTA block ─────────────────────────────────────
                    VStack(spacing: AppSpacing.md) {

                        // Sign in with Apple
                        Button {
                            auth.signInWithApple()
                        } label: {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "applelogo")
                                    // SF Symbols render from their own glyph set regardless of font
                                    // family — only size/weight/relativeTo affect the symbol, so
                                    // reusing ctaLabel (same 17pt/semibold/.body as the adjacent
                                    // label) matches the prior raw `.body.weight(.semibold)` exactly.
                                    .font(AppFonts.ctaLabel)
                                Text("Sign in with Apple")
                                    .font(AppFonts.ctaLabel)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: AppLayout.ctaHeight)
                            .background(AppColors.textPrimary)
                            .foregroundStyle(AppColors.pageBackground)
                            .clipShape(
                                RoundedRectangle(cornerRadius: AppRadius.lg,
                                                 style: .continuous)
                            )
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .disabled(auth.isLoading)
                        .opacity(auth.isLoading ? 0.55 : 1)
                        .animation(AppAnimation.fast, value: auth.isLoading)

                        // Loading indicator
                        if auth.isLoading {
                            ProgressView()
                                .tint(AppColors.accentPrimary)
                                .transition(.opacity)
                        }

                        // Error state
                        if let error = auth.error {
                            Text(error)
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.destructive)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppSpacing.lg)
                                .transition(.opacity)
                        }

                        // Legal footnote — Terms / Privacy are tappable (open in-app Safari).
                        // Custom-scheme markdown links are intercepted below so they open the
                        // SafariView sheet instead of leaving the app.
                        Text("By continuing you agree to our [Terms](vayl-legal://terms) & [Privacy Policy](vayl-legal://privacy)")
                            .font(AppFonts.meta)
                            .tint(AppColors.textSecondary)
                            .foregroundStyle(AppColors.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.xxl)
                            .environment(\.openURL, OpenURLAction { url in
                                guard url.scheme == "vayl-legal" else { return .systemAction }
                                legalDoc = (url.host == "privacy") ? .privacy : .terms
                                return .handled
                            })
                    }
                    .animation(AppAnimation.standard, value: auth.isLoading)
                    .animation(AppAnimation.standard, value: auth.error)

                    Spacer()
                        .frame(height: AppSpacing.xl)
                }
                .bottomClearance(layout)
            }
        }
        .ignoresSafeArea()
        .vaylSafariSheet(item: $legalDoc) { $0.url }
    }

    // MARK: - Atmosphere

    private var atmosphereLayer: some View {
        ZStack {
            // Cyan — top-left
            RadialGradient(
                colors: [
                    AppColors.accentPrimary.opacity(0.14),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 200
            )
            .frame(width: 360, height: 360)
            .offset(x: -100, y: -220)

            // Purple — center
            RadialGradient(
                colors: [
                    AppColors.accentSecondary.opacity(0.12),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 180
            )
            .frame(width: 320, height: 320)
            .offset(x: 40, y: -40)

            // Magenta — bottom-left
            RadialGradient(
                colors: [
                    AppColors.accentTertiary.opacity(0.10),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 160
            )
            .frame(width: 280, height: 280)
            .offset(x: -80, y: 200)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview("Sign In — Dark") {
    SignInView(auth: AuthStore())
        .preferredColorScheme(.dark)
}
