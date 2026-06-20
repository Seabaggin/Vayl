//
//  PaywallSheet.swift
//  Vayl
//
//  The reusable Vayl paywall — one Core-scoped sheet ($24.99 one-time; one buys, both unlock),
//  presented from three doors (reveal · Settings · Play locked-deck). The body is identical at
//  every door; only the hook header swaps by `entry`. Built from the OB sheet chrome + LivingText
//  + SpectrumBulletRow + VaylButton + tokens; purchase runs through EntitlementStore.
//  Spec: docs/superpowers/specs/2026-06-19-desire-reveal-paywall-design.md
//

import SwiftUI

struct PaywallSheet: View {

    /// Which door opened the sheet — swaps the hook header only. Body is identical.
    enum Entry: Equatable {
        case reveal
        case settings
        case playDeck(name: String)

        var hook: String {
            switch self {
            case .reveal:             return "Reveal your map"
            case .settings:           return "Yours, together"
            case .playDeck(let name): return "Unlock \(name)"
            }
        }
    }

    let entry: Entry
    /// Called when the purchase succeeds (Core unlocked).
    var onUnlocked: () -> Void = {}

    @Environment(EntitlementStore.self) private var entitlements

    @State private var showDetails = false
    @State private var purchasing  = false
    @State private var hapticTick  = 0

    private let bullets = [
        "Understand what you each want",
        "Talk openly about sex, boundaries, and what-ifs",
        "Open up at a pace you both set",
        "Keep your agreements clear and honored",
    ]

    private let included = [
        "The full Desire Map",
        "Every conversation deck",
        "All games",
        "Pulse insights",
        "Agreements vault and your shared Roadmap",
        "Post-session reflections",
    ]

    /// StoreKit-localized price when available; falls back to the catalog price.
    private var priceText: String { entitlements.corePriceText ?? "$24.99" }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            grabHandle
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    header
                    bulletList
                    glowDivider
                    priceRow
                    cta
                    coversBoth
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.xxl)
            }
            // Footer pinned to the bottom edge so there's no dead gap below the content.
            footer
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.md)
        }
        .frame(maxWidth: .infinity)
        .obSheetChrome()
        .overlay { if showDetails { detailsPopOut } }
        .screenshotProtected()
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTick)
    }

    // MARK: - Grab handle + Restore

    private var grabHandle: some View {
        ZStack(alignment: .top) {
            Capsule()
                .fill(AppColors.spectrumBorder)
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)

            HStack {
                Spacer()
                Button {
                    hapticTick += 1
                    // TODO(monetization): wire StoreKit restore-purchases here.
                } label: {
                    Text("Restore")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppSpacing.xl)
        }
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.sm)
    }

    // MARK: - Header (hook + hero + subheader)

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            LivingText(text: entry.hook,
                       font: AppFonts.display(34, weight: .bold, relativeTo: .largeTitle))
                .frame(maxWidth: .infinity, alignment: .center)

            Text("One payment, yours forever. Never a subscription. Opens everything you two explore.")
                .font(AppFonts.body(18, weight: .regular, relativeTo: .body))
                .foregroundStyle(AppColors.textBody)
                .fixedSize(horizontal: false, vertical: true)

            Text("Explore with less guesswork")
                .font(AppFonts.body(16, weight: .bold, relativeTo: .headline))
                .textCase(.uppercase)
                .foregroundStyle(AppColors.spectrumPurple)
                .padding(.top, AppSpacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Bullets (cascading shimmer down the list)

    private var bulletList: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            ForEach(Array(bullets.enumerated()), id: \.offset) { i, line in
                SpectrumBulletRow(text: line,
                                  phaseOffset: Double(i) * 0.22,
                                  font: AppFonts.body(20, weight: .medium, relativeTo: .body))
            }
        }
    }

    // MARK: - Glowing divider (premium accent — crisp spectrum line over a soft bloom)

    private var glowDivider: some View {
        ZStack {
            SpectrumHairline()
                .blur(radius: 6)
                .opacity(0.9)
            SpectrumHairline()
        }
    }

    // MARK: - Price + single info disclosure

    private var priceRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
            Text(priceText)
                .font(AppFonts.display(30, weight: .bold, relativeTo: .title))
                .foregroundStyle(AppColors.textPrimary)
            Text("· one time · yours forever")
                .font(AppFonts.body(15, weight: .regular, relativeTo: .subheadline))
                .foregroundStyle(AppColors.textSecondary)
            Button {
                hapticTick += 1
                withAnimation(AppAnimation.standard) { showDetails = true }
            } label: {
                Image(systemName: "info.circle")
                    .font(AppFonts.body(19, weight: .regular, relativeTo: .body))
                    .foregroundStyle(AppColors.spectrumText)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Details pop-out (StatPhase-style: dimmed scrim + centered spectrum card)

    private var detailsPopOut: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    hapticTick += 1
                    withAnimation(AppAnimation.standard) { showDetails = false }
                }
            detailsCard
                .padding(.horizontal, AppSpacing.xl)
        }
        .transition(.opacity)
        .zIndex(50)
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Everything included, forever")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                ForEach(included, id: \.self) { item in
                    detailRow(item)
                }
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("How access works")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                Text("One payment, you both unlock everything. If you ever unpair, it stays with whoever paid.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("The Opener and your solo decks are always free.")
                .font(AppFonts.meta)
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: AppLayout.citationPanelMaxWidth, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .fill(AppColors.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .stroke(AppColors.spectrumBorder, lineWidth: 1)
                )
        )
        .modalElevation()
    }

    private func detailRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Circle()
                .fill(AppColors.spectrumBorder)
                .frame(width: 5, height: 5)
                .padding(.top, AppSpacing.xs)
            Text(text)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - CTA + reassurance (badge UNDER the button)

    private var cta: some View {
        VaylButton(label: "Unlock everything", isLoading: purchasing) {
            hapticTick += 1
            purchase()
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, AppSpacing.sm)
    }

    private var coversBoth: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "person.2.fill")
                .font(AppFonts.body(15, weight: .regular, relativeTo: .subheadline))
                .foregroundStyle(AppColors.spectrumPurple)
            Text("covers both of you, your partner pays nothing")
                .font(AppFonts.body(15, weight: .regular, relativeTo: .subheadline))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("Restore purchase · Terms · Privacy")
                .font(AppFonts.body(14, weight: .regular, relativeTo: .footnote))
                .foregroundStyle(AppColors.textTertiary)
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "books.vertical")
                Text("grounded in research")
            }
            .font(AppFonts.body(13, weight: .regular, relativeTo: .caption))
            .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Purchase

    private func purchase() {
        guard !purchasing else { return }
        purchasing = true
        Task {
            let ok = await entitlements.purchase()
            purchasing = false
            if ok { onUnlocked() }
        }
    }
}

#if DEBUG
#Preview("Reveal door — content-height bottom sheet") {
    ZStack(alignment: .bottom) {
        AppColors.void.ignoresSafeArea()
        PaywallSheet(entry: .reveal)
            // Proportional height that scales with the screen, full-width (no GeometryReader —
            // that was insetting the width). Tune the fraction.
            .containerRelativeFrame(.vertical) { height, _ in height * 0.88 }
    }
    .environment(EntitlementStore(modelContainer: .previewContainer, appState: AppState()))
    .preferredColorScheme(.dark)
}
#endif
