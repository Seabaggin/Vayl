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
        case playDeck

        var hook: String {
            switch self {
            case .reveal:   return "Reveal Your Map"        // after the reveal, and the Map-tab Desire Map door
            case .settings: return "Unlock Vayl"            // neutral, ownership — the Settings door
            case .playDeck: return "Unlock All Decks"       // one purchase unlocks every deck, not just this one
            }
        }
    }

    let entry: Entry
    /// Called when the purchase succeeds (Core unlocked).
    var onUnlocked: () -> Void = {}
    /// Called when the user declines ("Not now"). Each door passes the dismissal that
    /// returns the user to what they had: the reveal rewinds to the free map, the
    /// sheet doors close. When nil, no off-ramp control is shown.
    var onClose: (() -> Void)?
    /// Who owns the frame. `false` (default): the paywall self-frames + draws its own grab
    /// handle, for the bespoke reveal ceremony host that provides no chrome (matching its
    /// sibling sheets). `true`: the presenter (`.vaylSheet`, at the Map/Play doors) owns the
    /// frame + grabber + drag, so the paywall supplies content only — never double-framed.
    var hostProvidesChrome: Bool = false

    @Environment(EntitlementStore.self) private var entitlements

    @State private var showDetails = false
    @State private var purchasing  = false
    @State private var hapticTick  = 0
    @State private var restoring   = false
    /// Store-surfaced outcome of the last purchase attempt (EntitlementStore.loadError) —
    /// e.g. the Ask-to-Buy "pending approval" state (review addendum 2026-07-09). The store
    /// clears loadError at the start of each attempt, so this never shows a stale error.
    @State private var purchaseStatus: String?
    @State private var showRestoreFailedAlert = false
    @State private var legalDoc: LegalDoc?

    private let bullets = [
        "Understand what you each want",
        "Talk openly about sex, boundaries, and what-ifs",
        "Open up at a pace you both set",
        "Keep your agreements clear and honored"
    ]

    private let included = [
        "The full Desire Map",
        "Every conversation deck",
        "All games",
        "Pulse insights",
        "Agreements vault and your shared Roadmap",
        "Post-session reflections"
    ]

    /// StoreKit-localized price. Nil until the product loads (bootstrap runs at launch).
    /// Never assert a hardcoded number here — a stale literal could diverge from the live
    /// App Store price. When nil, the price shows "Loading price…" and the CTA is disabled.
    private var priceReady: Bool { entitlements.corePriceText != nil }

    // MARK: - Effect tuning (bloom + glow divider)
    //
    // Effect-rendering constants for the paywall-only spectrum halo behind the hook and the
    // glow under the divider. NOT design tokens; same convention as VaylSheetChrome's
    // purpleTint/darken. Tune on device; they never leave this file.
    private let bloomCoreSize: CGFloat = 300   // purple core diameter
    private let bloomFlankSize: CGFloat = 210   // cyan / magenta flank diameter
    private let bloomFlankDX: CGFloat = 72    // horizontal spread of the flanks
    private let bloomVOffset: CGFloat = -52   // halo tracks the hook up after the top tightened (was -20)
    private let bloomIntensity: Double  = 1.0   // overall opacity over GlowOrb's own falloff
    private let dividerGlowBlur: CGFloat = 6    // soft bloom under the crisp spectrum divider
    private let dividerGlowOpacity: Double = 0.9

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
            // System Safari sheet (same route as SettingsView/SignInView): the
            // paywall is itself `.vaylSheet` content, so a nested `.vaylSheet`
            // would anchor to the paywall's bounds, not the screen.
            .vaylSafariSheet(item: $legalDoc) { $0.url }
    }

    // Content-height when it fits; scrolls when it can't (large Dynamic Type / small screens).
    // ViewThatFits uses the .fixedSize (content-height) layout if it fits the proposed height,
    // else the scrollable fallback. vaylSheetChrome forces maxHeight:.infinity (shared, off-limits),
    // so the chrome wraps BOTH candidates: with .fixedSize it hugs content; inside the ScrollView
    // it fills the screen and the content scrolls (the CTA + footer stay reachable).
    @ViewBuilder private var sizedSheet: some View {
        if hostProvidesChrome {
            // The presenter (.vaylSheet) owns the frame + grabber + drag.
            // We supply content only; it scrolls inside the presenter's fixed height when tall.
            ScrollView(showsIndicators: false) { sheetStack }
        } else {
            // Bespoke reveal ceremony host provides no chrome — self-frame to content height,
            // matching the reveal's sibling sheets (star detail, full-map list). The chrome
            // carries the spectrum top border like every sheet.
            ViewThatFits(in: .vertical) {
                sheetStack
                    .vaylSheetChrome()
                    // .fixedSize(vertical) overrides the chrome's maxHeight:.infinity so the sheet
                    // hugs content; horizontal:false keeps full-bleed width (no width bug).
                    .fixedSize(horizontal: false, vertical: true)
                ScrollView(showsIndicators: false) { sheetStack }
                    .vaylSheetChrome()
            }
        }
    }

    // The sheet content, shared by both ViewThatFits candidates. The bloom lives here so it stays
    // with the hook whether the sheet hugs content or scrolls.
    private var sheetStack: some View {
        VStack(spacing: 0) {
            if !hostProvidesChrome { grabHandle }   // vaylSheet draws its own grabber at the Map/Play doors
            VStack(alignment: .leading, spacing: 0) {
                header                                          // hook + hero
                bulletList.padding(.top, AppSpacing.md)         // value list follows the hook directly (eyebrow removed)
                glowDivider.padding(.top, AppSpacing.md)        // the value / decision break
                priceRow.padding(.top, AppSpacing.md)           // price leads the decision zone
                cta.padding(.top, AppSpacing.md)                // price + CTA read as one unit
                coversBoth.padding(.top, AppSpacing.sm)         // badge hugs the button it reassures
                if let purchaseStatus {
                    purchaseStatusLine(purchaseStatus)
                        .padding(.top, AppSpacing.sm)
                }
                if onClose != nil {
                    notNow.padding(.top, AppSpacing.sm)   // an honest exit, as visible as the CTA
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.md)                       // tightened top (was xxl); bloom tracks via bloomVOffset

            footer
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.sm)                   // clear separation between decision zone and legal footer
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

            // Secondary tone so the supporting line recedes under the hero and reads
            // distinct from the bright (textPrimary) value bullets below — no white-on-white wall.
            Text("Made to take your curiosity somewhere deeper. Follow it together, and see where it leads.")
                .font(AppFonts.body(16, weight: .medium, relativeTo: .body))
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Header bloom (paywall-only spectrum halo behind the hook)
    //
    // Composed from the shared GlowOrb primitive: a purple core flanked by faint cyan/magenta,
    // so the hook sits in a halo that echoes the spectrum border, bullets, and divider. Lives
    // ONLY here, never in the shared vaylSheetChrome (FounderLetter/CredentialEditor reuse that).
    // Static (GlowOrb doesn't animate, so no Reduce Motion concern).
    private var headerBloom: some View {
        ZStack {
            GlowOrb(color: AppColors.spectrumCyan, size: bloomFlankSize)
                .offset(x: -bloomFlankDX, y: bloomVOffset)
            GlowOrb(color: AppColors.spectrumMagenta, size: bloomFlankSize)
                .offset(x: bloomFlankDX, y: bloomVOffset)
            GlowOrb(color: AppColors.spectrumPurple, size: bloomCoreSize)   // dominant: drawn last, on top
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
                                  font: AppFonts.body(16, weight: .medium, relativeTo: .body))
            }
        }
    }

    // MARK: - Glowing divider (premium accent — crisp spectrum line over a soft bloom)

    private var glowDivider: some View {
        ZStack {
            SpectrumHairline()
                .blur(radius: dividerGlowBlur)
                .opacity(dividerGlowOpacity)
            SpectrumHairline()
        }
    }

    // MARK: - Price + single info disclosure

    private var priceRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
            if priceReady {
                Text(entitlements.corePriceText ?? "")
                    .font(AppFonts.display(30, weight: .bold, relativeTo: .title))
                    .foregroundStyle(AppColors.textPrimary)
                Text("· one time · yours forever")
                    .font(AppFonts.body(15, weight: .regular, relativeTo: .subheadline))
                    .foregroundStyle(AppColors.textSecondary)
                    .accessibilityLabel("one time, yours forever")   // read clean; drop the · dividers
            } else {
                Text("Loading price…")
                    .font(AppFonts.body(17, weight: .medium, relativeTo: .body))
                    .foregroundStyle(AppColors.textSecondary)
            }
            Button {
                hapticTick += 1
                withAnimation(AppAnimation.standard) { showDetails = true }
            } label: {
                Image(systemName: AppIcons.infoCircle)
                    .font(AppFonts.body(19, weight: .regular, relativeTo: .body))
                    .foregroundStyle(AppColors.spectrumTextSafe)
                    .frame(minWidth: 44, minHeight: 44)   // 44pt hit area around the small glyph
                    .contentShape(Rectangle())
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
            AppColors.scrimHeavy
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

            Text("The Opener and The Check-In are always free.")
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
        VaylButton(label: "Unlock everything", isLoading: purchasing, isDisabled: !priceReady) {
            hapticTick += 1
            purchase()
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    /// Honest off-ramp. Declining returns the user to what they had (free reveal / prior
    /// screen), never loses anything. Kept visible and 44pt-tappable, one-handed reachable.
    private var notNow: some View {
        Button {
            hapticTick += 1
            onClose?()
        } label: {
            Text("Not now")
                .font(AppFonts.body(15, weight: .medium, relativeTo: .subheadline))
                .foregroundStyle(AppColors.textSecondary)
                .padding(.vertical, AppSpacing.sm)
                .padding(.horizontal, AppSpacing.lg)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityLabel("Not now")
        .accessibilityHint("Closes this without purchasing")
    }

    private var coversBoth: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: AppIcons.person2Fill)
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
        // Legal trio only (App Store requires Restore / Terms / Privacy). The decorative
        // "Grounded In Research" badge was removed to declutter the bottom; re-add if wanted.
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
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Restoring purchase")
            } else {
                footerLink("Restore purchase", hint: "Restores a purchase you already made", action: restorePurchases)
            }
            footerDot
            footerLink("Terms", hint: "Opens the Terms of Service", action: openTerms)
            footerDot
            footerLink("Privacy", hint: "Opens the Privacy Policy", action: openPrivacy)
        }
        .frame(maxWidth: .infinity)
    }

    /// One footnote-styled, tappable footer control (plain so it reads like text, not button chrome).
    private func footerLink(_ label: String, hint: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppFonts.body(14, weight: .regular, relativeTo: .footnote))
                .foregroundStyle(AppColors.textTertiary)
                .padding(.vertical, AppSpacing.xs)   // compact legal fine-print; tap area via contentShape
                .contentShape(Rectangle())
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
        purchaseStatus = nil
        Task {
            let ok = await entitlements.purchase()
            purchasing = false
            if ok {
                onUnlocked()
            } else {
                // Surface the store's outcome (pending-approval / verification / StoreKit
                // error). A user cancel leaves loadError nil, so nothing is shown for it.
                purchaseStatus = entitlements.loadError
            }
        }
    }

    /// Status line under the CTA for a purchase that ended without unlocking —
    /// most importantly the Ask-to-Buy `.pending` state (review addendum 2026-07-09).
    private func purchaseStatusLine(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.body(14, weight: .regular, relativeTo: .footnote))
            .foregroundStyle(AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityLabel(text)
    }

    // MARK: - Legal / restore actions

    private func restorePurchases() {
        guard !restoring, !purchasing else { return }   // ignore a tap while a purchase is in flight (avoids a false "nothing to restore")
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

#Preview("Settings door — in rail") {
    VaylSheetPreviewHost(heightFraction: 0.65) {
        PaywallSheet(entry: .settings, hostProvidesChrome: true)
    }
    .environment(EntitlementStore(modelContainer: .previewContainer, appState: AppState()))
    .preferredColorScheme(.dark)
}
