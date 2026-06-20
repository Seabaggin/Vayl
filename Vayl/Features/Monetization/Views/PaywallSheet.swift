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
            case .reveal:             return "Reveal Your Map"
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
    @State private var restoring   = false
    @State private var showRestoreFailedAlert = false
    @State private var legalDoc: LegalDoc?

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

    // MARK: - Header bloom tuning
    //
    // Bloom-rendering constants (size / offset / intensity) for the paywall-only spectrum halo
    // behind the hook. NOT design tokens; same convention as OBSheetChrome's purpleTint/darken.
    // Tune on device; they never leave this file.
    private let bloomCoreSize:  CGFloat = 300   // purple core diameter
    private let bloomFlankSize: CGFloat = 210   // cyan / magenta flank diameter
    private let bloomFlankDX:   CGFloat = 72    // horizontal spread of the flanks
    private let bloomVOffset:   CGFloat = -52   // halo tracks the hook up after the top tightened (was -20)
    private let bloomIntensity: Double  = 1.0   // overall opacity over GlowOrb's own falloff

    // MARK: - Body

    var body: some View {
        sizedSheet
            .ignoresSafeArea(.container, edges: .bottom)
            .overlay { if showDetails { detailsPopOut } }
            .screenshotProtected()
            .sensoryFeedback(.impact(weight: .light), trigger: hapticTick)
            .alert("Nothing to restore", isPresented: $showRestoreFailedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("We couldn't find a purchase to restore on this Apple ID. If you've bought Vayl, make sure you're signed in with the same Apple ID you used to purchase.")
            }
            .sheet(item: $legalDoc) { doc in
                SafariView(url: doc.url)
            }
    }

    // Content-height when it fits; scrolls when it can't (large Dynamic Type / small screens).
    // ViewThatFits uses the .fixedSize (content-height) layout if it fits the proposed height,
    // else the scrollable fallback. obSheetChrome forces maxHeight:.infinity (shared, off-limits),
    // so the chrome wraps BOTH candidates: with .fixedSize it hugs content; inside the ScrollView
    // it fills the screen and the content scrolls (the CTA + footer stay reachable).
    @ViewBuilder private var sizedSheet: some View {
        ViewThatFits(in: .vertical) {
            sheetStack
                .obSheetChrome()
                // .fixedSize(vertical) overrides the chrome's maxHeight:.infinity so the sheet hugs
                // content; horizontal:false keeps full-bleed width (no GeometryReader, no width bug).
                .fixedSize(horizontal: false, vertical: true)
            ScrollView(showsIndicators: false) { sheetStack }
                .obSheetChrome()
        }
    }

    // The sheet content, shared by both ViewThatFits candidates. The bloom lives here so it stays
    // with the hook whether the sheet hugs content or scrolls.
    private var sheetStack: some View {
        VStack(spacing: 0) {
            grabHandle
            VStack(alignment: .leading, spacing: 0) {
                header                                          // hook + hero
                sectionHeading.padding(.top, AppSpacing.lg)     // air between value prop and label — premium apps breathe here
                bulletList.padding(.top, AppSpacing.sm)         // small breathe between label and list
                glowDivider.padding(.top, AppSpacing.lg)        // the value / decision break
                priceRow.padding(.top, AppSpacing.lg)           // price leads the decision zone — more air = more weight
                cta.padding(.top, AppSpacing.md)                // price + CTA read as one unit
                coversBoth.padding(.top, AppSpacing.sm)         // badge hugs the button it reassures
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.md)                       // tightened top (was xxl); bloom tracks via bloomVOffset

            footer
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.lg)                   // clear separation between decision zone and legal footer
                .padding(.bottom, AppSpacing.sm)                // minimal clearance above home indicator
        }
        .frame(maxWidth: .infinity)
        .background(alignment: .top) { headerBloom }
    }

    // MARK: - Grab handle + Restore

    private var grabHandle: some View {
        Capsule()
            .fill(AppColors.spectrumBorder)
            .frame(width: 40, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.sm)
            .accessibilityHidden(true)
    }

    // MARK: - Header (hook + hero + subheader)

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            LivingText(text: entry.hook,
                       font: AppFonts.display(38, weight: .bold, relativeTo: .largeTitle))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, -AppSpacing.md)   // widen past the body inset so 38pt stays one line

            Text("Made to take your curiosity somewhere deeper. Follow it together, and see where it leads.")
                .font(AppFonts.body(20, weight: .medium, relativeTo: .body))
                .foregroundStyle(AppColors.textBody)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Section heading (introduces the bullets)

    private var sectionHeading: some View {
        Text("Explore with less guesswork")
            .font(AppFonts.body(18, weight: .bold, relativeTo: .headline))
            .textCase(.uppercase)
            .foregroundStyle(AppColors.spectrumPurple)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Header bloom (paywall-only spectrum halo behind the hook)
    //
    // Composed from the shared GlowOrb primitive: a purple core flanked by faint cyan/magenta,
    // so the hook sits in a halo that echoes the spectrum border, bullets, and divider. Lives
    // ONLY here, never in the shared obSheetChrome (FounderLetter/CredentialEditor reuse that).
    // Static (GlowOrb doesn't animate, so no Reduce Motion concern).
    private var headerBloom: some View {
        ZStack {
            GlowOrb(color: AppColors.spectrumCyan,    size: bloomFlankSize)
                .offset(x: -bloomFlankDX, y: bloomVOffset)
            GlowOrb(color: AppColors.spectrumMagenta, size: bloomFlankSize)
                .offset(x:  bloomFlankDX, y: bloomVOffset)
            GlowOrb(color: AppColors.spectrumPurple,  size: bloomCoreSize)   // dominant: drawn last, on top
                .offset(y: bloomVOffset)
        }
        .opacity(bloomIntensity)
        .allowsHitTesting(false)
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
                .accessibilityLabel("one time, yours forever")   // read clean; drop the · dividers
            Button {
                hapticTick += 1
                withAnimation(AppAnimation.standard) { showDetails = true }
            } label: {
                Image(systemName: "info.circle")
                    .font(AppFonts.body(19, weight: .regular, relativeTo: .body))
                    .foregroundStyle(AppColors.spectrumText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("What's included")
            .accessibilityHint("Shows everything the purchase unlocks and how access works")
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Covers both of you. Your partner pays nothing.")
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: AppSpacing.sm) {
            // Legal trio — wired controls: Restore runs EntitlementStore.restore() (spinner while
            // in flight); Terms/Privacy open the in-app Safari sheet. App Store requires all three.
            HStack(spacing: AppSpacing.xs) {
                if restoring {
                    HStack(spacing: AppSpacing.xxs) {
                        ProgressView()
                            .controlSize(.mini)
                            .tint(AppColors.textTertiary)
                        Text("Restoring…")
                            .font(AppFonts.body(14, weight: .regular, relativeTo: .footnote))
                            .foregroundStyle(AppColors.textTertiary)
                    }
                } else {
                    footerLink("Restore purchase", hint: "Restores a purchase you already made", action: restorePurchases)
                }
                footerDot
                footerLink("Terms", hint: "Opens the Terms of Service", action: openTerms)
                footerDot
                footerLink("Privacy", hint: "Opens the Privacy Policy", action: openPrivacy)
            }
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "books.vertical")
                Text("Grounded In Research")
            }
            .font(AppFonts.body(13, weight: .regular, relativeTo: .caption))
            .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    /// One footnote-styled, tappable footer control (plain so it reads like text, not button chrome).
    private func footerLink(_ label: String, hint: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppFonts.body(14, weight: .regular, relativeTo: .footnote))
                .foregroundStyle(AppColors.textTertiary)
        }
        .buttonStyle(.plain)
        .accessibilityHint(hint)
    }

    /// Decorative "·" divider between footer links (hidden from VoiceOver).
    private var footerDot: some View {
        Text("·")
            .font(AppFonts.body(14, weight: .regular, relativeTo: .footnote))
            .foregroundStyle(AppColors.textTertiary)
            .accessibilityHidden(true)
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

    // MARK: - Legal / restore actions

    private func restorePurchases() {
        guard !restoring else { return }
        hapticTick += 1
        restoring = true
        Task {
            let unlocked = await entitlements.restore()   // AppStore.sync() → couple re-grant → refresh
            restoring = false
            if unlocked {
                onUnlocked()                              // gate opens = the confirmation
            } else {
                showRestoreFailedAlert = true             // nothing owned / couldn't restore
            }
        }
    }

    private func openTerms() {
        hapticTick += 1
        legalDoc = .terms
    }

    private func openPrivacy() {
        hapticTick += 1
        legalDoc = .privacy
    }
}

#if DEBUG
#Preview("Reveal door — content-height bottom sheet") {
    ZStack(alignment: .bottom) {
        AppColors.void.ignoresSafeArea()
        // Content-height: the sheet hugs its content (see .fixedSize in the body), so the host
        // no longer forces a height fraction. Bottom-anchored bottom sheet.
        PaywallSheet(entry: .reveal)
    }
    .environment(EntitlementStore(modelContainer: .previewContainer, appState: AppState()))
    .preferredColorScheme(.dark)
}

#Preview("Reveal door — AX5 Dynamic Type (scroll backstop)") {
    // Forces the largest accessibility text size so the content overflows the screen: ViewThatFits
    // drops to the ScrollView fallback, and the CTA + footer stay reachable by scrolling instead
    // of clipping. Flip between this and the content-height preview to confirm both behaviours.
    ZStack(alignment: .bottom) {
        AppColors.void.ignoresSafeArea()
        PaywallSheet(entry: .reveal)
    }
    .environment(EntitlementStore(modelContainer: .previewContainer, appState: AppState()))
    .environment(\.dynamicTypeSize, .accessibility5)
    .preferredColorScheme(.dark)
}
#endif
