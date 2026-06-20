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
                    SpectrumHairline()
                        .padding(.vertical, AppSpacing.xs)
                    priceRow
                    if showDetails { detailsPanel }
                    cta
                    coversBoth
                    footer
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .frame(maxWidth: .infinity)
        .obSheetChrome()
        .screenshotProtected()
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTick)
        .animation(AppAnimation.standard, value: showDetails)
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
        .padding(.bottom, AppSpacing.md)
    }

    // MARK: - Header (hook + hero + subheader)

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            LivingText(text: entry.hook)

            Text("One payment, yours forever. Never a subscription. Opens everything you two explore.")
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
                .fixedSize(horizontal: false, vertical: true)

            Text("Explore with less guesswork")
                .font(AppFonts.overline)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.top, AppSpacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Bullets (cascading shimmer down the list)

    private var bulletList: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            ForEach(Array(bullets.enumerated()), id: \.offset) { i, line in
                SpectrumBulletRow(text: line, phaseOffset: Double(i) * 0.22)
            }
        }
    }

    // MARK: - Price + single info disclosure

    private var priceRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
            Text(priceText)
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text("· one time · yours forever")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
            Button {
                hapticTick += 1
                showDetails.toggle()
            } label: {
                Image(systemName: showDetails ? "info.circle.fill" : "info.circle")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.spectrumPurple)
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Details panel (receipt + how access works) — behind the info button

    private var detailsPanel: some View {
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
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(AppColors.borderSubtle, lineWidth: 1)
                )
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
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
        VaylButton(label: "Unlock everything · \(priceText)", isLoading: purchasing) {
            hapticTick += 1
            purchase()
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, AppSpacing.sm)
    }

    private var coversBoth: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "person.2.fill")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.spectrumPurple)
            Text("covers both of you, your partner pays nothing")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("Restore purchase · Terms · Privacy")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
            HStack(spacing: AppSpacing.xxs) {
                Image(systemName: "books.vertical")
                Text("grounded in real research")
            }
            .font(AppFonts.meta)
            .foregroundStyle(AppColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.sm)
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
#Preview("Reveal door") {
    ZStack(alignment: .bottom) {
        AppColors.void.ignoresSafeArea()
        PaywallSheet(entry: .reveal)
    }
    .environment(EntitlementStore(modelContainer: .previewContainer, appState: AppState()))
    .preferredColorScheme(.dark)
}
#endif
