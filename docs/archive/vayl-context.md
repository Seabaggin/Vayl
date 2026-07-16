# Vayl — LLM Context Dump

> Generated: 2026-06-28 18:51:09 PDT
>
> **Active segment:** D4 — Desire Reveal (request affordance + bridge-card nav)
>
> **What this covers:**
>   D4    — DesireRevealView, DesireRevealStore, constellation, sheets, companion card
>   Core  — AppState, DesireSyncService, EntitlementService, models, enums
>   M2    — EntitlementStore, EntitlementRecord, PaywallSheet
>   T1    — HomeRouterView, HomeStore
>   T3    — MapView, MapStore, MeCardSheet, all Map components + Vault
>   S     — AirlockView
>   Theme — AppColors, AppFonts, AppSpacing, AppRadius, AppAnimation
>   Settings — SettingsView
>
> Files marked MISSING = wrong path or stub to create.

---

## Table of Contents

  1. [`Vayl/Features/Desire Map/Views/DesireRevealView.swift`](#file-vayl-features-desire-map-views-desirerevealview-swift)
  2. [`Vayl/Features/Desire Map/Store/DesireRevealStore.swift`](#file-vayl-features-desire-map-store-desirerevealstore-swift)
  3. [`Vayl/Features/Desire Map/Views/Components/DesireConstellationView.swift`](#file-vayl-features-desire-map-views-components-desireconstellationview-swift)
  4. [`Vayl/Features/Desire Map/Views/Components/DesireStarDetailSheet.swift`](#file-vayl-features-desire-map-views-components-desirestardetailsheet-swift)
  5. [`Vayl/Features/Desire Map/Views/Components/DesireMapListSheet.swift`](#file-vayl-features-desire-map-views-components-desiremaplistsheet-swift)
  6. [`Vayl/Features/Desire Map/Views/Components/DesireMatchDetail.swift`](#file-vayl-features-desire-map-views-components-desirematchdetail-swift)
  7. [`Vayl/Features/Desire Map/Views/Components/DesireStarView.swift`](#file-vayl-features-desire-map-views-components-desirestarview-swift)
  8. [`Vayl/Features/Desire Map/Views/Components/ConstellationField.swift`](#file-vayl-features-desire-map-views-components-constellationfield-swift)
  9. [`Vayl/Features/Desire Map/CeremonyVariant.swift`](#file-vayl-features-desire-map-ceremonyvariant-swift)
  10. [`Vayl/Features/Desire Map/ConstellationLayout.swift`](#file-vayl-features-desire-map-constellationlayout-swift)
  11. [`Vayl/Core/Models/CompanionCard.swift`](#file-vayl-core-models-companioncard-swift)
  12. [`Vayl/Features/Desire Map/Store/CompanionCardStore.swift`](#file-vayl-features-desire-map-store-companioncardstore-swift)
  13. [`Vayl/Features/Desire Map/Store/DesireMapStore.swift`](#file-vayl-features-desire-map-store-desiremapstore-swift)
  14. [`Vayl/Features/Desire Map/Views/DesireMapView.swift`](#file-vayl-features-desire-map-views-desiremapview-swift)
  15. [`Vayl/Core/Models/DesireMatch.swift`](#file-vayl-core-models-desirematch-swift)
  16. [`Vayl/Core/Models/DesireItem.swift`](#file-vayl-core-models-desireitem-swift)
  17. [`Vayl/Core/Models/DesireRating.swift`](#file-vayl-core-models-desirerating-swift)
  18. [`Vayl/Core/Models/Enums/AppDesireEnums.swift`](#file-vayl-core-models-enums-appdesireenums-swift)
  19. [`Vayl/Core/Services/AppState.swift`](#file-vayl-core-services-appstate-swift)
  20. [`Vayl/Core/Services/DesireSyncService.swift`](#file-vayl-core-services-desiresyncservice-swift)
  21. [`Vayl/Core/Services/EntitlementService.swift`](#file-vayl-core-services-entitlementservice-swift)
  22. [`Vayl/Features/Monetization/Store/EntitlementStore.swift`](#file-vayl-features-monetization-store-entitlementstore-swift)
  23. [`Vayl/Features/Monetization/Views/PaywallSheet.swift`](#file-vayl-features-monetization-views-paywallsheet-swift)
  24. [`Vayl/Core/Models/EntitlementRecord.swift`](#file-vayl-core-models-entitlementrecord-swift)
  25. [`Vayl/Features/Home/Views/HomeRouterView.swift`](#file-vayl-features-home-views-homerouterview-swift)
  26. [`Vayl/Features/Home/Store/HomeStore.swift`](#file-vayl-features-home-store-homestore-swift)
  27. [`Vayl/Features/Home/Components/DesireMapIndicator.swift`](#file-vayl-features-home-components-desiremapindicator-swift)
  28. [`Vayl/Features/Home/Views/MapChartedMoment.swift`](#file-vayl-features-home-views-mapchartedmoment-swift)
  29. [`Vayl/Features/Map/MapView.swift`](#file-vayl-features-map-mapview-swift)
  30. [`Vayl/Features/Map/MapStore.swift`](#file-vayl-features-map-mapstore-swift)
  31. [`Vayl/Features/Map/MeCardSheet.swift`](#file-vayl-features-map-mecardsheet-swift)
  32. [`Vayl/Features/Map/PrismView.swift`](#file-vayl-features-map-prismview-swift)
  33. [`Vayl/Features/Map/Components/FlavorVisuals.swift`](#file-vayl-features-map-components-flavorvisuals-swift)
  34. [`Vayl/Features/Map/Components/MapPrimitives.swift`](#file-vayl-features-map-components-mapprimitives-swift)
  35. [`Vayl/Features/Map/Components/MapPulseHero.swift`](#file-vayl-features-map-components-mappulsehero-swift)
  36. [`Vayl/Features/Map/Components/MapRecord.swift`](#file-vayl-features-map-components-maprecord-swift)
  37. [`Vayl/Features/Map/Components/MapUsLayer.swift`](#file-vayl-features-map-components-mapuslayer-swift)
  38. [`Vayl/Features/Map/Components/MeCardCompact.swift`](#file-vayl-features-map-components-mecardcompact-swift)
  39. [`Vayl/Features/Map/Vault/VaultSheet.swift`](#file-vayl-features-map-vault-vaultsheet-swift)
  40. [`Vayl/Features/Map/Vault/VaultStore.swift`](#file-vayl-features-map-vault-vaultstore-swift)
  41. [`Vayl/Features/Map/Vault/EventEntryEditor.swift`](#file-vayl-features-map-vault-evententryeditor-swift)
  42. [`Vayl/Features/Map/Vault/Components/VaultDesireSection.swift`](#file-vayl-features-map-vault-components-vaultdesiresection-swift)
  43. [`Vayl/Features/Map/Vault/Components/VaultAgreementsSection.swift`](#file-vayl-features-map-vault-components-vaultagreementssection-swift)
  44. [`Vayl/Features/Map/Vault/Components/VaultLogSection.swift`](#file-vayl-features-map-vault-components-vaultlogsection-swift)
  45. [`Vayl/Features/Map/Vault/Components/DiscussionCardView.swift`](#file-vayl-features-map-vault-components-discussioncardview-swift)
  46. [`Vayl/Features/Sessions/AirlockView.swift`](#file-vayl-features-sessions-airlockview-swift)
  47. [`Vayl/App/Theme/AppColors.swift`](#file-vayl-app-theme-appcolors-swift)
  48. [`Vayl/App/Theme/AppFonts.swift`](#file-vayl-app-theme-appfonts-swift)
  49. [`Vayl/App/Theme/AppSpacing.swift`](#file-vayl-app-theme-appspacing-swift)
  50. [`Vayl/App/Theme/AppRadius.swift`](#file-vayl-app-theme-appradius-swift)
  51. [`Vayl/App/Theme/AppAnimation.swift`](#file-vayl-app-theme-appanimation-swift)
  52. [`Vayl/Features/Settings/SettingsView.swift`](#file-vayl-features-settings-settingsview-swift)

---

## File: `Vayl/Features/Desire Map/Views/DesireRevealView.swift` {#file-vayl-features-desire-map-views-desirerevealview-swift}

```swift
//
//  DesireRevealView.swift
//  Vayl
//
//  D4 — the Desire-Map reveal. Reads DesireRevealStore; forwards taps; no DB/Service.
//  The whole reveal is ONE .vaylCover (wired in HomeRouterView S1.6). Inner sheets
//  (detail · full-map · paywall) are hosted directly inside this view as a custom
//  bottom sheet layer — never via .vaylSheet or .sheet.
//
//  Screens 6–10 of the ten-screen Desire Map flow:
//    6  Reveal      — free star lit + locked stars dim (ConstellationField)
//    7  Star detail — DesireStarDetailSheet (S1.3)
//    8  Paywall     — PaywallSheet host (S1.4)
//    9  Full map    — DesireMapListSheet (S1.5)
//   10  Unlocked    — whole sky lit, confident lines, caption updates in place
//

import SwiftUI

struct DesireRevealView: View {

    let store: DesireRevealStore

    // vaylDismiss is injected by .vaylCover (wired in S1.6).
    // Until S1.6, X is a no-op — swipe-dismiss the fullScreenCover to close during testing.
    @Environment(\.vaylDismiss) private var vaylDismiss
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hapticTick: Int = 0

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Background ──────────────────────────────
            AppColors.void.ignoresSafeArea()
            OnboardingAtmosphere(config: .cardReveal).ignoresSafeArea()

            // ── Content ─────────────────────────────────
            VStack(spacing: 0) {
                topBar
                mainContent
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            // ── Sheet host (S1.3/S1.4/S1.5 fill the sheets) ──
            if hasActiveSheet {
                sheetHostLayer
                    .transition(.opacity)
            }
        }
        .screenshotProtected()
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTick)
        .animation(AppAnimation.desireSheetRise, value: hasActiveSheet)
        .task { if case .loading = store.phase { await store.load() } }
        .onAppear { triggerBeatSequence() }
        .onChange(of: store.phase) { _, _ in triggerBeatSequence() }
    }

    private var hasActiveSheet: Bool {
        store.selectedMatch != nil || store.showFullMap || store.showPaywall
    }

    private func triggerBeatSequence() {
        guard case .ready = store.phase, store.beatPhase == .idle else { return }
        store.startBeatSequence()
    }

    // MARK: - Phase routing

    @ViewBuilder
    private var mainContent: some View {
        switch store.phase {
        case .loading:
            loadingView
        case .failed(let msg):
            emptyState(
                icon: "exclamationmark.triangle",
                title: "Couldn't load your matches",
                message: msg
            )
        case .empty:
            emptyState(
                icon: "sparkles",
                title: "No shared matches yet",
                message: "When you and your partner both finish your maps, what you share appears here."
            )
        case .ready:
            beatReveal
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button {
                hapticTick += 1
                vaylDismiss(confirm: false)
            } label: {
                Image(systemName: "xmark")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(AppColors.cardBg.opacity(0.55)))
                    .overlay(Circle().stroke(AppColors.borderSubtle, lineWidth: 1))
            }
            .buttonStyle(_PressScaleStyle())

            Spacer()

            if store.totalCount > 1 {
                Button {
                    hapticTick += 1
                    store.openFullMap()
                } label: {
                    Text("Full map")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(Capsule().fill(AppColors.cardBg.opacity(0.55)))
                        .overlay(Capsule().stroke(AppColors.borderSubtle, lineWidth: 1))
                }
                .buttonStyle(_PressScaleStyle())
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.xs)
    }

    // MARK: - Beat-driven reveal (3-beat ceremony + unlock-in-place)
    //
    // beat1:    free match entrance — constellation shows only unlocked nodes
    // beat2:    locked teasers stagger in below; count + spectrum hairline fade in
    // beat3:    PaywallSheet auto-rises (hosted in sheetHostLayer)
    // revealed: all matches lit, confident lines — post-unlock celebration

    private var beatReveal: some View {
        ZStack {
            // Tap-anywhere-to-advance background (nodes' own tap gestures take priority)
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    hapticTick += 1
                    store.advanceBeat()
                }

            VStack(spacing: 0) {
                // Beat progress dots (hidden when idle or fully revealed)
                if store.beatPhase != .idle && store.beatPhase != .revealed {
                    beatDots
                        .padding(.top, AppSpacing.xs)
                }

                // Overline
                Text(store.beatPhase == .revealed ? "Your shared sky" : "Where you meet")
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.textTertiary)
                    .tracking(1.5)
                    .padding(.top, AppSpacing.md)
                    .opacity(store.beatPhase != .idle ? 1 : 0)
                    .animation(AppAnimation.desireStarIgnite.delay(0.10).reduceMotionSafe, value: store.beatPhase)

                // Constellation
                DesireConstellationView(
                    stars: placedStars,
                    edges: layout.edges,
                    variant: ceremonyVariant,
                    mode: constellationMode,
                    onTap: { id in
                        hapticTick += 1
                        if let match = store.matches.first(where: { $0.id.uuidString == id }) {
                            store.selectStar(match)
                        }
                    }
                )
                .frame(maxWidth: .infinity)
                .frame(height: (store.beatPhase == .beat2 || store.beatPhase == .beat3) ? 220 : 300)
                .padding(.vertical, AppSpacing.lg)
                .opacity(store.beatPhase != .idle ? 1 : 0)
                // Fix #3b: opacity reveal gated behind reduceMotionSafe; the per-star ignite + line
                // draw live inside DesireConstellationView (also Reduce-Motion aware).
                .animation(AppAnimation.desireStarIgnite.reduceMotionSafe, value: store.beatPhase)

                // Bottom section: caption at beat1/revealed, locked rows at beat2/beat3
                bottomSection
                    .animation(AppAnimation.enter.reduceMotionSafe, value: store.beatPhase)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var bottomSection: some View {
        switch store.beatPhase {
        case .idle:
            EmptyView()

        case .beat1:
            // Caption for the free match
            VStack(spacing: AppSpacing.xs) {
                Text("You both marked this")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                if store.lockedCount > 0 {
                    Text("tap to read · or open the full map")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, AppSpacing.xxl)
            .padding(.bottom, AppSpacing.xxl)
            .transition(.opacity)

        case .beat2, .beat3:
            // Locked teasers + count
            _LockedSection(
                matches: store.lockedMatches,
                isVisible: store.beatPhase.rawValue >= 2
            )
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xxl)
            .transition(.opacity)

        case .revealed:
            // Post-unlock caption
            VStack(spacing: AppSpacing.xs) {
                let n = store.totalCount
                Text("\(n) desire\(n == 1 ? "" : "s") you share")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                Text("tap any star to talk about it")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
                Rectangle()
                    .fill(LinearGradient(
                        colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: 56, height: 1)
                    .opacity(0.5)
                    .padding(.top, AppSpacing.xs)
            }
            .padding(.horizontal, AppSpacing.xxl)
            .padding(.bottom, AppSpacing.xxl)
            .transition(.opacity)
        }
    }

    // MARK: - Beat dots (spectrum pill for active, dim dot for inactive)

    private var beatDots: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(1...3, id: \.self) { i in
                let isActive = store.beatPhase.rawValue == i
                Capsule()
                    .fill(isActive
                        ? AnyShapeStyle(LinearGradient(
                            colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                            startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(Color.white.opacity(0.12)))
                    .frame(width: isActive ? 20 : 6, height: 6)
                    .shadow(color: isActive ? AppColors.spectrumPurple.opacity(0.45) : .clear, radius: 4)
                    .animation(AppAnimation.fast, value: store.beatPhase)
            }
        }
    }

    // MARK: - Constellation data (generated layout + ceremony)

    /// The telegraphed ceremony variant for this couple (seeded by coupleId).
    private var ceremonyVariant: CeremonyVariant {
        #if DEBUG
        if let override = store.debugVariantOverride { return override }
        #endif
        return CeremonyVariant.resolve(coupleId: appState.coupleId)
    }

    /// The generated constellation (positions + MST edges) for the full match set, seeded by the
    /// couple so the sky is theirs and stable across beats. Deterministic — recomputing is cheap.
    private var layout: ConstellationLayout.Result {
        let seed = appState.coupleId.map { ConstellationLayout.seed(for: $0) } ?? 0
        return ConstellationLayout.generate(count: store.matches.count, seed: seed)
    }

    /// What the constellation does at the current beat.
    private var constellationMode: DesireConstellationView.Mode {
        switch store.beatPhase {
        case .idle, .beat1:   return .intro
        case .beat2, .beat3:  return .teasers
        case .revealed:       return reduceMotion ? .resolved : .assemble
        }
    }

    /// Matches placed onto the generated layout: the free-reveal (or first mutual) star takes the
    /// central hero slot; the rest fill the remaining positions in order. Sizes scale with count
    /// so many stars do not crowd. Indices align with `layout.points` / `layout.edges`.
    private var placedStars: [DesireConstellationView.Star] {
        let result = layout
        guard !result.points.isEmpty, !store.matches.isEmpty else { return [] }

        let hero = store.matches.first(where: { $0.isFreeReveal })
            ?? store.matches.first(where: { $0.alignment == .mutual })
            ?? store.matches.first
        let others = store.matches.filter { $0.id != hero?.id }

        var placed = [RevealMatch?](repeating: nil, count: result.points.count)
        if result.heroIndex < placed.count { placed[result.heroIndex] = hero }
        var oi = 0
        for i in placed.indices where i != result.heroIndex {
            if oi < others.count { placed[i] = others[oi]; oi += 1 }
        }

        let n = max(store.matches.count, 1)
        let base = max(9.0, min(16.0, 16.0 * (4.0 / Double(n)).squareRoot()))
        let heroSize = CGFloat(min(24.0, base * 1.5))

        return placed.enumerated().compactMap { index, match in
            guard let match else { return nil }
            let isHero = index == result.heroIndex
            return DesireConstellationView.Star(
                id: match.id.uuidString,
                point: result.points[index],
                size: isHero ? heroSize : CGFloat(base),
                label: match.itemName,
                isHero: isHero,
                isLocked: match.isLocked,
                cadence: match.isLocked ? .locked : .free
            )
        }
    }

    // MARK: - Sheet host layer

    // Scrim + sheet slot. Sheets are pinned to bottom and transition .move(edge:.bottom).
    // S1.4 adds PaywallSheet; S1.5 adds DesireMapListSheet.
    private var sheetHostLayer: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    hapticTick += 1
                    if store.showPaywall {
                        store.closePaywall()
                    } else {
                        store.dismissSheets()
                    }
                }

            // S1.3 — star detail sheet
            if let match = store.selectedMatch {
                DesireStarDetailSheet(
                    match: match,
                    onClose: { store.dismissSheets() },
                    onTalkTapped: routeToVault
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(AppAnimation.desireSheetRise, value: store.selectedMatch?.id)
            }

            // S1.5 — full-map list sheet
            if store.showFullMap {
                DesireMapListSheet(
                    matches: store.matches,
                    priceText: entitlements.corePriceText,
                    onUnlockTapped: {
                        store.dismissSheets()
                        store.showPaywall = true
                    },
                    onClose: { store.dismissSheets() },
                    onTalk: { _ in routeToVault() }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(AppAnimation.desireSheetRise, value: store.showFullMap)
            }

            // S1.4 — paywall
            if store.showPaywall {
                PaywallSheet(entry: .reveal, onUnlocked: {
                    store.handleUnlockSuccess()
                })
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(AppAnimation.desireSheetRise, value: store.showPaywall)
            }
        }
    }

    // MARK: - Talk routing

    /// Talk-about-this: leave the reveal and open the Vault (Map tab), where the
    /// conversation / consent flow lives. Shared by the star-detail sheet and the
    /// full-map list rows so both routes behave identically.
    private func routeToVault() {
        store.dismissSheets()
        vaylDismiss(confirm: false)
        appState.selectedTab = .map
        appState.vaultOpenPending = true
    }

    // MARK: - Loading state

    private var loadingView: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .tint(AppColors.textTertiary)
            Text("Finding where you align…")
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty / error state

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textTertiary)
            Text(title)
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.md)
            Button {
                hapticTick += 1
                vaylDismiss(confirm: false)
            } label: {
                Text("Close")
                    .font(AppFonts.ctaLabel)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .buttonStyle(_PressScaleStyle())
            .padding(.top, AppSpacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.xl)
    }
}

// MARK: - Locked teasers section (beat2 + beat3)
// Blurred item names + lock glyphs, staggered in at 80ms each, matching desire-reveal.html.

private struct _LockedSection: View {
    let matches: [RevealMatch]
    let isVisible: Bool

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            ForEach(Array(matches.prefix(4).enumerated()), id: \.element.id) { i, match in
                HStack(spacing: AppSpacing.md) {
                    Text(match.itemName)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(Color.white.opacity(0.30))
                        .blur(radius: 5)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "lock.fill")
                        .font(AppFonts.caption)
                        .foregroundStyle(Color.white.opacity(0.30))
                }
                .padding(.horizontal, AppSpacing.md)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(Color.white.opacity(0.02))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 22)
                // Fix #5: tokenized locked-row stagger (was .easeOut 0.36 / 0.08 step),
                // reduceMotionSafe so it collapses to a fast opacity confirm.
                .animation(
                    AppAnimation.desireLockedRowEnter
                        .delay(Double(i) * AppAnimation.desireBeatStaggerStep)
                        .reduceMotionSafe,
                    value: isVisible
                )
            }

            // Count + spectrum hairline; delayed until all rows finish staggering in
            VStack(spacing: AppSpacing.xs) {
                Text("\(matches.count) more aligned desire\(matches.count == 1 ? "" : "s")")
                    .font(AppFonts.caption)
                    .foregroundStyle(Color.white.opacity(0.18))
                Rectangle()
                    .fill(LinearGradient(
                        colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: 60, height: 1)
                    .opacity(0.4)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.sm)
            .opacity(isVisible ? 1 : 0)
            // Fix #5: tokenized count + hairline fade (was .easeOut 0.4 / 0.08 step / 0.14 base),
            // reduceMotionSafe so it collapses to a fast opacity confirm.
            .animation(
                AppAnimation.enter
                    .delay(Double(min(matches.count, 4)) * AppAnimation.desireBeatStaggerStep + AppAnimation.desireBeatStaggerBase)
                    .reduceMotionSafe,
                value: isVisible
            )
        }
    }
}

// MARK: - Press-scale button style (local)

private struct _PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(AppAnimation.fast, value: configuration.isPressed)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Free reveal — 1 lit + 3 locked") {
    let appState = AppState()
    DesireRevealView(store: .previewStore(matches: [
        .sample("New Relationship Energy", .mutual),
        .sample("Overnight Stays With Others", .adjacent, locked: true),
        .sample("Meeting Your Partner's Other Connections", .mutual, locked: true),
        .sample("Time and Attention", .adjacent, locked: true),
    ]))
    .environment(appState)
    .environment(EntitlementStore(modelContainer: .previewContainer, appState: appState))
    .preferredColorScheme(.dark)
}

#Preview("Fully unlocked — 5 stars") {
    let appState = AppState()
    DesireRevealView(store: .previewStore(matches: [
        .sample("New Relationship Energy", .mutual, free: true),
        .sample("Overnight Stays", .adjacent),
        .sample("Meeting Partners", .mutual),
        .sample("Shared Space", .mutual),
        .sample("Deep Conversations", .adjacent),
    ]))
    .environment(appState)
    .environment(EntitlementStore(modelContainer: .previewContainer, appState: appState))
    .preferredColorScheme(.dark)
}

#Preview("Empty") {
    let appState = AppState()
    DesireRevealView(store: .previewStore(matches: [], phase: .empty))
        .environment(appState)
        .environment(EntitlementStore(modelContainer: .previewContainer, appState: appState))
        .preferredColorScheme(.dark)
}

#Preview("Loading") {
    let appState = AppState()
    DesireRevealView(store: .previewStore(matches: [], phase: .loading))
        .environment(appState)
        .environment(EntitlementStore(modelContainer: .previewContainer, appState: appState))
        .preferredColorScheme(.dark)
}
#endif

```

---

## File: `Vayl/Features/Desire Map/Store/DesireRevealStore.swift` {#file-vayl-features-desire-map-store-desirerevealstore-swift}

```swift
//
//  DesireRevealStore.swift
//  Vayl
//
//  Store for D4 — the Desire-Map reveal (the "magic moment"). Reads the couple's computed
//  matches (alignment only — NEVER raw partner answers) and resolves the free/locked split.
//
//  4-Layer arch: View → Store → Service. Reads `DesireSyncService.fetchMatches` (client-safe:
//  id, item, alignment, is_free_reveal — no partner values/gap). The free/locked gate is the
//  conversion mechanic (D4 shows it; M5 wires the actual purchase).
//
//  STUB STATUS (2026-06-17): structure + data wiring complete; FEEL/styling is Bryan's pass.
//  The "request a hidden conversation" idea moved to the Vault consent flow
//  (VaultStore.askToOpen + VaultDesireSection), so it no longer lives here.
//

import Foundation
import SwiftData
import SwiftUI   // AppAnimation tokens + UIAccessibility (Reduce Motion checks in the beat ceremony)

@Observable
@MainActor
final class DesireRevealStore: Identifiable {

    /// Identity for `.fullScreenCover(item:)` presentation (mirrors DesireMapStore).
    let id = UUID()

    // MARK: - Phase

    enum Phase: Equatable {
        case loading
        case ready
        case empty            // both complete but no positive matches — graceful, not an error
        case failed(String)
    }

    // MARK: - Beat phase (3-beat reveal ceremony)
    //
    // idle    → (load completes) → beat1: free match entrance; auto-advances after kHold12
    // beat1   → (hold) → beat2: locked teasers stagger in; auto-advances after kHold23
    // beat2   → (hold) → beat3: paywall auto-rises
    // beat3   → (purchase) → revealed: all matches lit, confident lines
    //
    // Already-Core couples skip beats 2-3 and land directly in revealed.
    // Tap-to-advance (advanceBeat) skips the current hold immediately.

    enum BeatPhase: Int, Equatable {
        case idle     = 0
        case beat1    = 1   // free match visible only
        case beat2    = 2   // locked teasers stagger in
        case beat3    = 3   // paywall open
        case revealed = 4   // post-unlock: all matches lit
    }

    // MARK: - Published state

    private(set) var phase: Phase = .loading

    /// All matches, each resolved to a display name + alignment + locked flag.
    /// Free couple: the one `is_free_reveal` is unlocked, the rest locked. Core: all unlocked.
    private(set) var matches: [RevealMatch] = []

    /// Drives the 3-beat ceremony. View observes this to choreograph the visual sequence.
    private(set) var beatPhase: BeatPhase = .idle

    /// The pending auto-advance timer (held weakly inside; tracked here so a new sequence
    /// or an unlock can cancel a stale one). Never strongly retains the store.
    @ObservationIgnored private var autoAdvanceTask: Task<Void, Never>?

    // MARK: - Interaction state (sheet hosts live inside the reveal cover)

    /// Set when the user taps a star — drives the detail sheet.
    var selectedMatch: RevealMatch? = nil
    /// True while the full-map list sheet is open.
    var showFullMap: Bool = false
    /// True while the paywall sheet is open (tapped a locked star or the upgrade CTA).
    var showPaywall: Bool = false

    #if DEBUG
    /// Debug-only: force a specific ceremony variant. Production picks it by coupleId.
    var debugVariantOverride: CeremonyVariant? = nil
    #endif

    // MARK: - Derived

    var unlockedMatches: [RevealMatch] { matches.filter { !$0.isLocked } }
    var lockedMatches:   [RevealMatch] { matches.filter { $0.isLocked } }
    var lockedCount: Int { lockedMatches.count }
    var totalCount:  Int { matches.count }

    /// True once the couple is `core` — every match is shown, no unlock CTA.
    var isFullyUnlocked: Bool { entitlements.isCore }

    // MARK: - Dependencies

    private let appState: AppState
    private let entitlements: EntitlementStore
    private let service: DesireSyncService

    init(
        appState: AppState,
        entitlements: EntitlementStore,
        service: DesireSyncService? = nil
    ) {
        self.appState = appState
        self.entitlements = entitlements
        // Resolve the main-actor singleton in the @MainActor init body, not as a nonisolated default arg.
        self.service = service ?? .shared
    }

    // MARK: - Beat sequence

    /// Kick off the reveal ceremony. No-op if a sequence is already running.
    /// Already-Core couples skip straight to .revealed (no conversion moment needed).
    ///
    /// Edge case (fix #2): a free couple whose ONLY match is the free one (lockedCount == 0)
    /// has nothing to gate. Auto-advancing them to beat3 would float a paywall over an empty
    /// locked section. Treat them like already-Core: land on the lit end-state, no ask, no gap.
    /// (matches / lockedCount are populated by load() before .ready, which gates this call.)
    func startBeatSequence() {
        guard beatPhase == .idle else { return }
        if isFullyUnlocked || lockedCount == 0 {
            beatPhase = .revealed
            // Landing straight on the lit sky (already-Core, or a lone free match) is a full
            // viewing, so stamp full-seen: full_reveal_seen_at should reflect reality, mirroring
            // the post-purchase path (handleUnlockSuccess). load() already stamped free-seen.
            if let coupleId = appState.coupleId {
                Task { try? await service.markRevealSeen(coupleId: coupleId, full: true) }
            }
        } else {
            beatPhase = .beat1
            scheduleAutoAdvance()
        }
    }

    /// Tap-to-advance: skip the current hold immediately. Idempotent — safe to call at any beat.
    /// Animations are driven by the View observing beatPhase changes.
    ///
    /// Fix #1: a beat1 tap lands on beat2, but the beat2 → beat3 leg must still auto-arm so the
    /// paywall eventually rises on its own. Both the auto path (scheduleAutoAdvance) and a tap
    /// route the second leg through scheduleBeat2ToBeat3() so neither strands the ceremony.
    func advanceBeat() {
        autoAdvanceTask?.cancel()   // a tap supersedes the current auto-timer; the user drives from here
        switch beatPhase {
        case .beat1:
            beatPhase = .beat2
            scheduleBeat2ToBeat3()   // re-arm the second leg so the paywall still auto-rises
        case .beat2: beatPhase = .beat3; showPaywall = true
        case .beat3: showPaywall = true  // re-open paywall if the user dismissed it without purchasing
        default: break
        }
    }

    /// First leg of the ceremony: beat1 hold, then beat1 → beat2, then chains the second leg.
    /// [weak self]: a fire-and-forget timer must NOT keep the store alive past the reveal.
    /// A strong capture would release the store on a background executor when the Task ends
    /// (after the cover dismissed / in tests, after the case returned), routing the
    /// @MainActor isolated deinit through the wrong executor.
    private func scheduleAutoAdvance() {
        // Fix #3a: with Reduce Motion on, collapse the hold to 0 so there is no timed ceremony.
        let hold: Double = UIAccessibility.isReduceMotionEnabled ? 0 : AppAnimation.desireBeatHold1
        autoAdvanceTask?.cancel()
        autoAdvanceTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(hold))
            guard let self, beatPhase == .beat1 else { return }
            beatPhase = .beat2
            scheduleBeat2ToBeat3()
        }
    }

    /// Second leg: wait for the locked rows to stagger in plus the beat-2 hold, then beat2 → beat3
    /// and raise the paywall. Reusable so both the auto path and a beat1 tap reach beat3.
    private func scheduleBeat2ToBeat3() {
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        // Fix #4: tokenized holds + stagger (was kHold23 1.2 / 0.08 step / 0.14 base).
        let stagger = Double(lockedCount) * AppAnimation.desireBeatStaggerStep + AppAnimation.desireBeatStaggerBase
        // Fix #3a: Reduce Motion collapses the hold so beat3 lands immediately (no timed ceremony).
        let wait: Double = reduceMotion ? 0 : (stagger + AppAnimation.desireBeatHold2)
        autoAdvanceTask?.cancel()
        autoAdvanceTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(wait))
            guard let self, beatPhase == .beat2 else { return }
            beatPhase = .beat3
            showPaywall = true
        }
    }

    // MARK: - Load

    /// Fetch the couple's matches and resolve the free/locked split. No-op (empty) when unpaired.
    func load() async {
        guard let coupleId = appState.coupleId else { phase = .empty; return }
        phase = .loading
        do {
            let names = try itemNameMap()
            let categories = try itemCategoryMap()
            let rows = try await service.fetchMatches(coupleId: coupleId)
            let core = entitlements.isCore
            matches = rows.map { row in
                RevealMatch(
                    id: row.id,
                    itemName: names[row.desireItemId] ?? row.desireItemId,
                    itemCategory: categories[row.desireItemId],
                    alignment: row.matchType,                       // mutual / adjacent
                    isLocked: !core && !row.isFreeReveal,           // free couple locks all but the free one
                    bridgeCardId: row.bridgeCardId,
                    isFreeReveal: row.isFreeReveal                  // the server-set hero star
                )
            }
            phase = matches.isEmpty ? .empty : .ready
            if !matches.isEmpty {
                // Always stamp free-seen. This closes the latent edge where a Core couple
                // opening the reveal stamped only full: true, leaving free_reveal_seen_at null
                // and HomeStore.revealDone (= hasSeenFree) permanently false.
                Task { try? await service.markRevealSeen(coupleId: coupleId, full: false) }
            }
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    private func itemNameMap() throws -> [String: String] {
        try ContentLoader.loadDesireItems().reduce(into: [:]) { $0[$1.id] = $1.name }
    }

    private func itemCategoryMap() throws -> [String: String] {
        try ContentLoader.loadDesireItems().reduce(into: [:]) { $0[$1.id] = $1.category }
    }

    // MARK: - Actions (stubbed — see file header)

    /// Unlock all matches for BOTH partners — runs the Core purchase (M2). On success the
    /// entitlement resolves Core (server + local StoreKit), so re-loading flips the locked teasers
    /// open. M5 (the dedicated paywall surface) can replace this entry with a richer sheet.
    func unlockAll() {
        Task {
            guard await entitlements.purchase() else { return }
            #if DEBUG
            if appState.coupleId == nil {
                matches = matches.map { RevealMatch(id: $0.id, itemName: $0.itemName, itemCategory: $0.itemCategory, alignment: $0.alignment, isLocked: false, bridgeCardId: $0.bridgeCardId, isFreeReveal: $0.isFreeReveal) }
                beatPhase = .revealed
                return
            }
            #endif
            await load()
            guard let coupleId = appState.coupleId else { return }
            Task { try? await service.markRevealSeen(coupleId: coupleId, full: true) }
        }
    }

    // MARK: - Sheet interaction

    /// Tap a star: unlocked → open detail sheet; locked → open paywall.
    func selectStar(_ match: RevealMatch) {
        if match.isLocked {
            showPaywall = true
        } else {
            selectedMatch = match
        }
    }

    /// Open the full-map list sheet from the top-right pill.
    func openFullMap() {
        showFullMap = true
    }

    /// Dismiss the detail sheet or the full-map sheet (not the paywall).
    func dismissSheets() {
        selectedMatch = nil
        showFullMap = false
    }

    /// Dismiss the paywall sheet only.
    func closePaywall() {
        showPaywall = false
    }

    /// Called by `PaywallSheet.onUnlocked` after the purchase has already succeeded.
    /// Closes the paywall, transitions to .revealed, and reloads — at this point
    /// `entitlements.isCore` is already true, so `load()` resolves all matches as unlocked,
    /// lighting the constellation in place. Also stamps `full: true` seen.
    func handleUnlockSuccess() {
        autoAdvanceTask?.cancel()
        showPaywall = false
        beatPhase = .revealed
        Task {
            #if DEBUG
            if appState.coupleId == nil {
                matches = matches.map { RevealMatch(id: $0.id, itemName: $0.itemName, itemCategory: $0.itemCategory, alignment: $0.alignment, isLocked: false, bridgeCardId: $0.bridgeCardId, isFreeReveal: $0.isFreeReveal) }
                return
            }
            #endif
            await load()
            guard let coupleId = appState.coupleId else { return }
            Task { try? await service.markRevealSeen(coupleId: coupleId, full: true) }
        }
    }

    // MARK: - Preview seam

    #if DEBUG
    static func previewStore(matches: [RevealMatch], phase: Phase = .ready, entitlements: EntitlementStore? = nil) -> DesireRevealStore {
        let store = DesireRevealStore(
            appState: AppState(),
            entitlements: entitlements ?? EntitlementStore(modelContainer: .previewContainer, appState: AppState())
        )
        store.matches = matches
        store.phase = phase
        return store
    }
    #endif
}

// MARK: - RevealMatch (view model)

/// One match as the reveal renders it — display name + alignment + locked flag.
/// Carries NO raw answers or gap (the read path never has them).
struct RevealMatch: Identifiable, Equatable {
    let id: UUID
    let itemName: String
    let itemCategory: String?           // e.g. "emotional", "sexual", "communication"
    let alignment: DesireMatchType?     // mutual ("Mutual") / adjacent ("Worth Exploring")
    let isLocked: Bool
    let bridgeCardId: String?
    /// The one server-set free reveal (the emotional-peak star). Drives the hero on the unlocked sky.
    var isFreeReveal: Bool = false

    /// Celebratory subtitle by alignment (mutual = wholehearted; adjacent = mostly aligned).
    var celebration: String {
        switch alignment {
        case .mutual:   return "You're both excited about this."
        case .adjacent: return "You're mostly aligned here."
        case .none:     return "You share this."
        }
    }

    #if DEBUG
    static func sample(_ name: String, _ alignment: DesireMatchType, locked: Bool = false, free: Bool = false, category: String? = "emotional") -> RevealMatch {
        RevealMatch(id: UUID(), itemName: name, itemCategory: category, alignment: alignment, isLocked: locked, bridgeCardId: nil, isFreeReveal: free)
    }
    #endif
}

```

---

## File: `Vayl/Features/Desire Map/Views/Components/DesireConstellationView.swift` {#file-vayl-features-desire-map-views-components-desireconstellationview-swift}

```swift
//
//  DesireConstellationView.swift
//  Vayl
//
//  The Desire Map reveal constellation with the telegraphed two-seed assembly ceremony.
//  Renders generated star positions + MST edges and, in `.assemble`, lights the stars in the
//  variant's order (each via DesireStarView's two-seed ignite) while the lines draw and a
//  telegraph plays. Reduce Motion lands on the static lit sky.
//
//  Replaces the reveal's use of ConstellationField. Positions/edges come from ConstellationLayout
//  (stable per couple); the variant comes from CeremonyVariant.
//
//  Feel reference: docs/prototypes/desire-map-ceremony-variants.html
//  Spec: docs/superpowers/specs/2026-06-27-desire-map-reveal-ceremony-design.md
//

import SwiftUI

struct DesireConstellationView: View {

    struct Star: Identifiable {
        let id: String
        let point: CGPoint        // normalized 0...1
        let size: CGFloat
        let label: String?
        let isHero: Bool
        let isLocked: Bool
        let cadence: DesireStarView.Cadence
    }

    enum Mode: Equatable {
        case intro      // beat 1: only the hero free star, igniting
        case teasers    // beat 2/3: all shown, hero lit, locked dim, no lines
        case assemble   // revealed (motion): the telegraphed variant ceremony
        case resolved   // revealed (reduce motion / static): all lit, lines drawn, no motion
    }

    let stars: [Star]
    let edges: [ConstellationLayout.Edge]
    let variant: CeremonyVariant
    let mode: Mode
    var onTap: ((String) -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed: Set<Int> = []
    @State private var gatherContracted = false
    @State private var sweepProgress: CGFloat = 0
    @State private var sweepVisible = false

    private var heroIndex: Int { stars.firstIndex(where: \.isHero) ?? 0 }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if mode == .assemble && !reduceMotion {
                    telegraph(in: geo.size)
                }

                ForEach(Array(edges.enumerated()), id: \.offset) { _, edge in
                    line(edge, in: geo.size)
                }

                ForEach(Array(stars.enumerated()), id: \.element.id) { index, star in
                    if revealed.contains(index) {
                        DesireStarView(
                            size: star.size,
                            state: starState(index, star),
                            label: showsLabel(star) ? star.label : nil,
                            cadence: star.cadence,
                            ignites: ignites
                        )
                        .position(x: star.point.x * geo.size.width,
                                  y: star.point.y * geo.size.height)
                        .onTapGesture { onTap?(star.id) }
                    }
                }
            }
        }
        .task(id: mode) { await applyMode() }
    }

    // MARK: - Per-star rendering

    /// New stars ignite (two-seed merge) during the intro hero beat and the full assembly only.
    private var ignites: Bool { mode == .intro || mode == .assemble }

    private func starState(_ index: Int, _ star: Star) -> DesireStarView.StarState {
        (mode == .teasers && star.isLocked) ? .dim : .lit
    }

    private func showsLabel(_ star: Star) -> Bool {
        guard star.label != nil, !star.isLocked else { return false }
        return star.isHero || stars.count <= 6
    }

    // MARK: - Lines

    @ViewBuilder
    private func line(_ edge: ConstellationLayout.Edge, in size: CGSize) -> some View {
        let drawn = lineDrawn(edge)
        Path { path in
            path.move(to: scaled(stars[edge.a].point, size))
            path.addLine(to: scaled(stars[edge.b].point, size))
        }
        .trim(from: 0, to: drawn ? 1 : 0)
        .stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
        .animation(AppAnimation.desireLineDraw.reduceMotionSafe, value: drawn)
    }

    private func lineDrawn(_ edge: ConstellationLayout.Edge) -> Bool {
        switch mode {
        case .resolved:        return true
        case .assemble:        return revealed.contains(edge.a) && revealed.contains(edge.b)
        case .intro, .teasers: return false
        }
    }

    // MARK: - Telegraph

    @ViewBuilder
    private func telegraph(in size: CGSize) -> some View {
        switch variant.telegraph {
        case .gather:
            Circle()
                .fill(RadialGradient(
                    colors: [Color.white.opacity(0.22), AppColors.spectrumMagenta.opacity(0.12), .clear],
                    center: .center, startRadius: 0, endRadius: size.width * 0.24))
                .frame(width: size.width * 0.48, height: size.width * 0.48)
                .scaleEffect(gatherContracted ? 0.2 : 1.7)
                .opacity(gatherContracted ? 0 : 0.5)
                .blur(radius: 6)
                .position(x: size.width / 2, y: size.height * 0.46)
                .allowsHitTesting(false)
        case .sweep:
            Rectangle()
                .fill(LinearGradient(
                    colors: [.clear, Color.white.opacity(0.16), .clear],
                    startPoint: .leading, endPoint: .trailing))
                .frame(width: 60, height: size.height * 1.4)
                .blur(radius: 8)
                .rotationEffect(.degrees(-12))
                .position(x: (sweepProgress * 1.4 - 0.2) * size.width, y: size.height / 2)
                .opacity(sweepVisible ? 0.85 : 0)
                .allowsHitTesting(false)
        case .none:
            EmptyView()
        }
    }

    private func scaled(_ point: CGPoint, _ size: CGSize) -> CGPoint {
        CGPoint(x: point.x * size.width, y: point.y * size.height)
    }

    // MARK: - Assembly timeline

    private func applyMode() async {
        sweepVisible = false
        gatherContracted = false
        sweepProgress = 0
        switch mode {
        case .intro:
            revealed = stars.isEmpty ? [] : [heroIndex]
        case .teasers, .resolved:
            revealed = Set(stars.indices)
        case .assemble:
            revealed = []
            await runAssembly()
        }
    }

    private func runAssembly() async {
        guard !stars.isEmpty else { return }

        switch variant.telegraph {
        case .gather:
            withAnimation(AppAnimation.desireGatherPulse) { gatherContracted = true }
            try? await Task.sleep(for: .seconds(AppAnimation.desireGatherLead))
        case .sweep:
            sweepVisible = true
            withAnimation(AppAnimation.desireSweepBand) { sweepProgress = 1 }
        case .none:
            break
        }
        if Task.isCancelled { return }

        let schedule = variant.schedule(points: stars.map(\.point), heroIndex: heroIndex)
            .sorted { $0.delay < $1.delay }
        var elapsed = 0.0
        for step in schedule {
            let wait = step.delay - elapsed
            if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
            if Task.isCancelled { return }
            elapsed = step.delay
            revealed.insert(step.index)
        }
        sweepVisible = false
    }
}

```

---

## File: `Vayl/Features/Desire Map/Views/Components/DesireStarDetailSheet.swift` {#file-vayl-features-desire-map-views-components-desirestardetailsheet-swift}

```swift
//
//  DesireStarDetailSheet.swift
//  Vayl
//
//  Screen 7 — star detail sheet. Hosted INSIDE the reveal cover as a custom
//  bottom sheet (ZStack + .move(edge:.bottom) transition in DesireRevealView).
//  Never presented via .vaylSheet or .sheet — those break width on iOS 26.
//
//  Pattern mirrors CredentialEditorOverlay: grab handle, content, vaylSheetChrome.
//

import SwiftUI

struct DesireStarDetailSheet: View {

    let match: RevealMatch
    var onClose: () -> Void = {}
    var onTalkTapped: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            grabHandle

            // Close row
            HStack {
                Spacer()
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(AppColors.cardBg.opacity(0.55)))
                        .overlay(Circle().stroke(AppColors.borderSubtle, lineWidth: 1))
                }
                .buttonStyle(_DetailPressStyle())
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.sm)

            // Detail body
            DesireMatchDetail(
                match: match,
                onTalkTapped: onTalkTapped,
                onLearnTapped: nil   // stub — S1.3; Learn nav wired later
            )
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xxl)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .vaylSheetChrome()
    }

    private var grabHandle: some View {
        Capsule()
            .fill(AppColors.spectrumBorder)
            .frame(width: 40, height: 4)
            .opacity(0.55)
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.md)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Detail sheet — mutual") {
    ZStack(alignment: .bottom) {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .cardReveal).ignoresSafeArea()
        Color.black.opacity(0.5).ignoresSafeArea()

        DesireStarDetailSheet(match: .sample("New Relationship Energy", .mutual))
    }
    .preferredColorScheme(.dark)
}

#Preview("Detail sheet — adjacent") {
    ZStack(alignment: .bottom) {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .cardReveal).ignoresSafeArea()
        Color.black.opacity(0.5).ignoresSafeArea()

        DesireStarDetailSheet(match: .sample("Overnight Stays", .adjacent, category: "logistics"))
    }
    .preferredColorScheme(.dark)
}
#endif

```

---

## File: `Vayl/Features/Desire Map/Views/Components/DesireMapListSheet.swift` {#file-vayl-features-desire-map-views-components-desiremaplistsheet-swift}

```swift
//
//  DesireMapListSheet.swift
//  Vayl
//
//  Screen 9 — "Where you meet" full-map list, hosted as a bottom sheet inside the
//  reveal cover. Two surfaces:
//
//  • DesireMapListView   — pure content (header + match rows + CTA). Reused by
//                          VaultDesireSection in Phase 3 — keep inputs generic.
//  • DesireMapListSheet  — sheet chrome wrapper (grab handle, close, vaylSheetChrome).
//
//  Pattern mirrors DesireStarDetailSheet: no .vaylSheet or .sheet — custom ZStack
//  bottom-sheet inside the cover, transition .move(edge:.bottom).
//

import SwiftUI

// MARK: - Sheet wrapper

struct DesireMapListSheet: View {

    let matches: [RevealMatch]
    let priceText: String?
    var onUnlockTapped: () -> Void = {}
    var onClose: () -> Void = {}
    /// Tapped "Talk about this" inside an expanded row — routes to the Vault (wired by the host).
    var onTalk: (RevealMatch) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            grabHandle

            // Close row
            HStack {
                Spacer()
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(AppColors.cardBg.opacity(0.55)))
                        .overlay(Circle().stroke(AppColors.borderSubtle, lineWidth: 1))
                }
                .buttonStyle(_DetailPressStyle())
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.sm)

            // Content — hugs its height when it fits; scrolls on small screens / long lists
            ViewThatFits(in: .vertical) {
                DesireMapListView(
                    matches: matches,
                    priceText: priceText,
                    onUnlockTapped: onUnlockTapped,
                    onTalk: onTalk
                )
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)

                ScrollView(showsIndicators: false) {
                    DesireMapListView(
                        matches: matches,
                        priceText: priceText,
                        onUnlockTapped: onUnlockTapped,
                        onTalk: onTalk
                    )
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .vaylSheetChrome()
    }

    private var grabHandle: some View {
        Capsule()
            .fill(AppColors.spectrumBorder)
            .frame(width: 40, height: 4)
            .opacity(0.55)
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.md)
    }
}

// MARK: - List content (reusable in Phase 3 Vault)

/// Pure content: header + match rows + optional unlock CTA.
/// Input is `[RevealMatch]` — Phase 3 maps `MapStore.AlignItem` to this shape before calling.
struct DesireMapListView: View {

    let matches: [RevealMatch]
    let priceText: String?
    var onUnlockTapped: () -> Void = {}
    var onTalk: (RevealMatch) -> Void = { _ in }

    @State private var expandedId: String? = nil

    private var unlockedMatches: [RevealMatch] { matches.filter { !$0.isLocked } }
    private var lockedCount: Int  { matches.filter { $0.isLocked }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            listHeader
            matchRows
            if lockedCount > 0 {
                unlockCTA
            }
        }
    }

    // MARK: - Header

    private var listHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Where you meet")
                .font(AppFonts.sectionHeading)
                .foregroundStyle(AppColors.textPrimary)

            Text(subCaption)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
    }

    private var subCaption: String {
        if lockedCount == 0 {
            let n = matches.count
            return "\(n) desire\(n == 1 ? "" : "s") you share"
        }
        let revealed = unlockedMatches.count
        return "\(revealed) revealed · \(lockedCount) more you share"
    }

    // MARK: - Match rows

    @ViewBuilder
    private var matchRows: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(matches) { match in
                if match.isLocked {
                    _LockedMatchRow(match: match, onTap: onUnlockTapped)
                } else {
                    _ExpandableMatchRow(
                        match: match,
                        isExpanded: Binding(
                            get: { expandedId == match.id.uuidString },
                            set: { expanded in
                                withAnimation(AppAnimation.standard.reduceMotionSafe) {
                                    expandedId = expanded ? match.id.uuidString : nil
                                }
                            }
                        ),
                        onTalk: { onTalk(match) }
                    )
                }
            }
        }
    }

    // MARK: - Unlock CTA

    private var unlockCTA: some View {
        VStack(spacing: AppSpacing.sm) {
            SpectrumHairline()

            VaylButton(
                label: "Unlock the full map · \(priceText ?? "$24.99")",
                style: .gold,
                size: .fullWidth,
                action: onUnlockTapped
            )
            .frame(height: VaylButtonSize.fullWidth.height)

            Text("One purchase unlocks for both of you.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppSpacing.xs)
    }
}

// MARK: - Expandable row (unlocked match)

private struct _ExpandableMatchRow: View {

    let match: RevealMatch
    @Binding var isExpanded: Bool
    var onTalk: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Collapsed header — always visible
            Button {
                isExpanded.toggle()
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    alignmentDot
                    Text(match.itemName)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .contentShape(Rectangle())
                .padding(.vertical, AppSpacing.sm)
            }
            .buttonStyle(_DetailPressStyle())

            // Expanded body
            if isExpanded {
                DesireMatchDetail(match: match, onTalkTapped: onTalk)
                    .padding(.top, AppSpacing.sm)
                    .padding(.leading, AppSpacing.md)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColors.cardBg.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(AppColors.borderSubtle.opacity(isExpanded ? 0.5 : 0.25), lineWidth: 1)
        )
    }

    private var alignmentDot: some View {
        Circle()
            .fill(dotColor)
            .frame(width: 6, height: 6)
    }

    private var dotColor: Color {
        switch match.alignment {
        case .mutual:   return AppColors.spectrumMagenta
        case .adjacent: return AppColors.spectrumPurple
        case .none:     return AppColors.textTertiary
        }
    }
}

// MARK: - Locked row

private struct _LockedMatchRow: View {

    let match: RevealMatch
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "lock.fill")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary.opacity(0.6))

                // Fix #6: render the REAL item name, blurred + dimmed, so it reads as a
                // blurred real label (mockup) rather than placeholder dots.
                Text(match.itemName)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textTertiary)
                    .blur(radius: 5)
                    .lineLimit(1)
                    .opacity(0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary.opacity(0.4))
            }
            .contentShape(Rectangle())
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(_DetailPressStyle())
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColors.cardBg.opacity(0.20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(AppColors.borderSubtle.opacity(0.15), lineWidth: 1)
        )
        .opacity(0.65)
    }
}

// MARK: - Preview

#if DEBUG
private let _previewMatches: [RevealMatch] = [
    .sample("New Relationship Energy", .mutual),
    .sample("Overnight Stays", .adjacent),
    .sample("Meeting Partners", .mutual, locked: true),
    .sample("Shared Space Agreements", .adjacent, locked: true),
    .sample("Time and Attention", .mutual, locked: true),
]

#Preview("Partial reveal — sheet") {
    ZStack(alignment: .bottom) {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .cardReveal).ignoresSafeArea()
        Color.black.opacity(0.5).ignoresSafeArea()

        DesireMapListSheet(
            matches: _previewMatches,
            priceText: "$24.99"
        )
    }
    .environment(EntitlementStore(modelContainer: .previewContainer, appState: AppState()))
    .preferredColorScheme(.dark)
}

#Preview("Fully unlocked — list content") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        DesireMapListView(
            matches: _previewMatches.map {
                RevealMatch(id: $0.id, itemName: $0.itemName, itemCategory: $0.itemCategory,
                            alignment: $0.alignment, isLocked: false, bridgeCardId: nil)
            },
            priceText: nil
        )
        .padding(AppSpacing.lg)
    }
    .environment(EntitlementStore(modelContainer: .previewContainer, appState: AppState()))
    .preferredColorScheme(.dark)
}
#endif

```

---

## File: `Vayl/Features/Desire Map/Views/Components/DesireMatchDetail.swift` {#file-vayl-features-desire-map-views-components-desirematchdetail-swift}

```swift
//
//  DesireMatchDetail.swift
//  Vayl
//
//  The shared card body for a single desire match.
//  Used by DesireStarDetailSheet (screen 7) and DesireMapListSheet (screen 9).
//
//  Carries NO raw partner answers — the read path is alignment-only (RevealMatch).
//

import SwiftUI

struct DesireMatchDetail: View {

    let match: RevealMatch
    /// Called when the user taps "Talk about this". Stub — stub action in S1.3.
    var onTalkTapped: (() -> Void)? = nil
    /// Called when the user taps "Explore in Learn". Stub — stub action in S1.3.
    var onLearnTapped: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Category overline
            if let cat = match.itemCategory {
                Text(cat.uppercased())
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.textTertiary)
                    .tracking(1.0)
            }

            // Item name
            Text(match.itemName)
                .font(AppFonts.sectionHeading)
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // Alignment badge
            alignmentBadge
                .padding(.top, AppSpacing.xxs)

            // Celebration line
            Text(match.celebration)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, AppSpacing.xxs)

            // Divider
            SpectrumHairline()
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xs)

            // CTAs
            Button {
                onTalkTapped?()
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Text("Talk about this")
                        .font(AppFonts.ctaLabel)
                        .foregroundStyle(badgeColor)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(AppFonts.caption)
                        .foregroundStyle(badgeColor.opacity(0.7))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(_DetailPressStyle())

            // Learn link renders only when wired. Until Learn can deep-link to a desire
            // term, the reveal/list pass `onLearnTapped: nil`, so it stays hidden rather
            // than showing a dead "Explore X in Learn" control.
            if let onLearnTapped {
                Button {
                    onLearnTapped()
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        // Fix #6: interpolate the item name to match the mockup ("Explore "X" in Learn").
                        Text("Explore \u{201C}\(match.itemName)\u{201D} in Learn")
                            .font(AppFonts.bodyText)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(_DetailPressStyle())
            }
        }
    }

    // MARK: - Badge

    private var alignmentBadge: some View {
        HStack(spacing: AppSpacing.xs) {
            Circle()
                .fill(badgeColor)
                .frame(width: 5, height: 5)
            Text(badgeText)
                .font(AppFonts.caption)
                .foregroundStyle(badgeColor)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs)
        .background(Capsule().fill(badgeColor.opacity(0.12)))
        .overlay(Capsule().stroke(badgeColor.opacity(0.30), lineWidth: 1))
    }

    private var badgeColor: Color {
        switch match.alignment {
        case .mutual:   return AppColors.spectrumMagenta
        case .adjacent: return AppColors.spectrumPurple
        case .none:     return AppColors.textTertiary
        }
    }

    private var badgeText: String {
        switch match.alignment {
        case .mutual:   return "You both want this"
        case .adjacent: return "Worth exploring"
        case .none:     return "Shared"
        }
    }
}

// MARK: - Press style (file-local)

struct _DetailPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(AppAnimation.fast, value: configuration.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Mutual match") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        DesireMatchDetail(match: .sample("New Relationship Energy", .mutual))
            .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}

#Preview("Adjacent match") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        DesireMatchDetail(
            match: .sample("Overnight Stays With Others", .adjacent, category: "logistics")
        )
        .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
#endif

```

---

## File: `Vayl/Features/Desire Map/Views/Components/DesireStarView.swift` {#file-vayl-features-desire-map-views-components-desirestarview-swift}

```swift
//
//  DesireStarView.swift
//  Vayl
//
//  Reusable warm star atom for the Desire Map rater sky and reveal constellation.
//  Mirrors the ConstellationNode recipe from Learn but uses the warm magenta-led
//  desire colorway (magenta → purple, never cyan).
//
//  Do NOT wrap in .drawingGroup() — the sparkle keyframeAnimator must re-render
//  only its own layer, and the resting cross + core are cheap enough to skip rasterizing.
//

import SwiftUI

// MARK: - Supporting types

extension DesireStarView {
    enum StarState { case dim, lit }
    enum Cadence { case free, locked }
}

private struct SparkleValues {
    var scale: CGFloat = 0.0
    var opacity: Double = 0.0
    var rotation: Double = 0.0
}

// MARK: - DesireStarView

/// A single warm desire star.
///
/// `size` is the core circle diameter — all other dimensions derive from it.
/// Typical ranges: 10–18pt for rater sky accumulation; 28–40pt for reveal hero.
struct DesireStarView: View {

    var size: CGFloat
    var state: StarState = .lit
    var label: String? = nil
    var cadence: Cadence = .free
    /// When true, the star plays the two-seed ignite entrance once on appear (your purple + their
    /// magenta converging into one bright star). Default false — renders lit immediately.
    var ignites: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sparkleTrigger: Int = 0
    /// Entrance state. Initialized from `ignites` so non-igniting stars render at rest with no
    /// first-frame flash; igniting stars start collapsed and bloom in `startEntrance()`.
    @State private var bloomed: Bool
    @State private var seedsMerged: Bool

    init(size: CGFloat, state: StarState = .lit, label: String? = nil, cadence: Cadence = .free, ignites: Bool = false) {
        self.size = size
        self.state = state
        self.label = label
        self.cadence = cadence
        self.ignites = ignites
        _bloomed = State(initialValue: !ignites)
        _seedsMerged = State(initialValue: !ignites)
    }

    // MARK: Derived geometry (all proportional to size)

    private var haloSize: CGFloat  { size * 6.0  }
    private var glowSize: CGFloat  { size * 3.2  }
    private var coreSize: CGFloat  { size        }
    private var crossLen: CGFloat  { size * 3.5  }
    private var crossW: CGFloat    { max(0.8, size * 0.075) }
    private var sparkleSize: CGFloat { size * 2.2 }

    private var glowOpacity: Double   { state == .lit ? 1.0 : 0.18 }
    private var coreOpacity: Double   { state == .lit ? 1.0 : 0.28 }
    private var crossOpacity: Double  { state == .lit ? 0.38 : 0.20 }

    // MARK: Body

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            ZStack {
                // Two-seed entrance — a cool (you) and warm (them) point converging as the star
                // ignites. Present only while the entrance plays; otherwise no seeds, instant bloom.
                if playsEntrance {
                    seedView(color: AppColors.spectrumPurple,  dx: -seedOffset)
                    seedView(color: AppColors.spectrumMagenta, dx:  seedOffset)
                }

                ZStack {
                    haloLayer
                    glowLayer
                    coreLayer
                    crossLayer
                    if state == .lit {
                        sparkleLayer
                    }
                }
                .scaleEffect(bloomed ? 1 : entranceStartScale)
                .opacity(bloomed ? 1 : 0)
            }
            .frame(width: haloSize, height: haloSize)

            if let label {
                Text(label)
                    .font(AppFonts.body(10, weight: .semibold, relativeTo: .caption2))
                    .foregroundStyle(Color.white)
                    .shadow(color: Color.black.opacity(0.85), radius: 2)
                    .shadow(color: AppColors.spectrumMagenta.opacity(0.55), radius: 5)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: haloSize)
                    .opacity(bloomed ? 1 : 0)
            }
        }
        .onAppear { startEntrance() }
        .task(id: "\(state == .lit)-\(!reduceMotion)") {
            guard !reduceMotion, state == .lit else { return }
            await sparkleLoop()
        }
    }

    // MARK: Entrance (two-seed ignite)

    private var playsEntrance: Bool { ignites && state == .lit && !reduceMotion }

    private var seedDiameter: CGFloat { glowSize * 0.5 }
    private var seedOffset: CGFloat   { glowSize * 0.45 }
    private var entranceStartScale: CGFloat { 0.2 }
    private var seedRestOpacity: Double { 0.6 }

    /// A faint pre-merge seed point (cool = you, warm = them). Drifts to center and fades as the
    /// star blooms. Geometry is proportional to `size`.
    private func seedView(color: Color, dx: CGFloat) -> some View {
        Circle()
            .fill(RadialGradient(
                colors: [color.opacity(0.95), color.opacity(0.22), .clear],
                center: .center, startRadius: 0, endRadius: seedDiameter / 2))
            .frame(width: seedDiameter, height: seedDiameter)
            .blur(radius: 5)
            .scaleEffect(seedsMerged ? 0.35 : 1)
            .offset(x: seedsMerged ? 0 : dx, y: seedsMerged ? 0 : dx * 0.35)
            .opacity(seedsMerged ? 0 : seedRestOpacity)
    }

    /// Drives the entrance on appear. Igniting stars converge two seeds and bloom; everything
    /// else (no ignite, or Reduce Motion) lands at rest instantly.
    private func startEntrance() {
        guard ignites else { return }              // already at rest (bloomed initialized true)
        guard playsEntrance else {                 // Reduce Motion / not lit: skip the ceremony
            bloomed = true
            seedsMerged = true
            return
        }
        withAnimation(AppAnimation.desireStarSeedDrift) { seedsMerged = true }
        withAnimation(AppAnimation.desireStarMergeSettle.delay(AppAnimation.desireStarMergeBloomDelay)) { bloomed = true }
        Task {
            try? await Task.sleep(for: .seconds(AppAnimation.desireStarMergeBloomDelay * 2))
            sparkleTrigger += 1
        }
    }

    // MARK: Layers

    private var haloLayer: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        AppColors.spectrumMagenta.opacity(0.16),
                        AppColors.spectrumPurple.opacity(0.08),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: haloSize / 2
                )
            )
            .frame(width: haloSize, height: haloSize)
            .blur(radius: 17)
    }

    private var glowLayer: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.85),
                        AppColors.spectrumMagenta.opacity(0.42),
                        AppColors.spectrumPurple.opacity(0.13),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: glowSize / 2
                )
            )
            .frame(width: glowSize, height: glowSize)
            .blur(radius: 5)
            .opacity(glowOpacity)
    }

    private var coreLayer: some View {
        Circle()
            .fill(Color.white)
            .frame(width: coreSize, height: coreSize)
            .shadow(color: Color.white,                                   radius: 3)
            .shadow(color: AppColors.spectrumMagenta.opacity(0.82),       radius: 7)
            .shadow(color: AppColors.spectrumPurple.opacity(0.42),        radius: 15)
            .opacity(coreOpacity)
    }

    // Two thin rectangles (H + V) with a white gradient that fades at both ends.
    // This is the star's permanent character — present even at rest.
    private var crossLayer: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.white, Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: crossLen, height: crossW)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.white, Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: crossW, height: crossLen)
        }
        .opacity(crossOpacity)
    }

    private var sparkleLayer: some View {
        SparkleStar()
            .fill(
                RadialGradient(
                    colors: [Color.white.opacity(0.95), Color.white.opacity(0.0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: sparkleSize / 2
                )
            )
            .frame(width: sparkleSize, height: sparkleSize)
            .keyframeAnimator(
                initialValue: SparkleValues(),
                trigger: sparkleTrigger
            ) { content, values in
                content
                    .scaleEffect(values.scale)
                    .opacity(values.opacity)
                    .rotationEffect(.degrees(values.rotation))
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    CubicKeyframe(0.0, duration: 0.0)
                    CubicKeyframe(1.0, duration: AppAnimation.desireSparkleDuration * 0.45)
                    CubicKeyframe(0.55, duration: AppAnimation.desireSparkleDuration * 0.55)
                }
                KeyframeTrack(\.opacity) {
                    CubicKeyframe(0.0, duration: 0.0)
                    CubicKeyframe(1.0, duration: AppAnimation.desireSparkleDuration * 0.35)
                    CubicKeyframe(0.0, duration: AppAnimation.desireSparkleDuration * 0.65)
                }
                KeyframeTrack(\.rotation) {
                    CubicKeyframe(0.0, duration: 0.0)
                    CubicKeyframe(12.0, duration: AppAnimation.desireSparkleDuration)
                }
            }
    }

    // MARK: Sparkle loop

    private func sparkleLoop() async {
        let baseRate = cadence == .free
            ? AppAnimation.desireSparkleFreeRate
            : AppAnimation.desireSparkleLockedRate
        while !Task.isCancelled {
            let factor = Double.random(in: 0.55...1.6)
            let wait = baseRate * factor
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled else { return }
            sparkleTrigger += 1
        }
    }
}

// MARK: - Previews

#Preview("Lit — free cadence") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VStack(spacing: AppSpacing.xxl) {
            DesireStarView(size: 20, state: .lit, label: "Shared space", cadence: .free)
            DesireStarView(size: 14, state: .lit, cadence: .free)
            DesireStarView(size: 10, state: .dim, cadence: .locked)
        }
    }
}

#Preview("Sizes — lit vs dim") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        HStack(spacing: AppSpacing.xl) {
            VStack(spacing: AppSpacing.lg) {
                Text("Lit").font(AppFonts.caption).foregroundStyle(AppColors.textTertiary)
                DesireStarView(size: 32, state: .lit, cadence: .free)
                DesireStarView(size: 18, state: .lit, cadence: .free)
                DesireStarView(size: 12, state: .lit, cadence: .free)
            }
            VStack(spacing: AppSpacing.lg) {
                Text("Dim").font(AppFonts.caption).foregroundStyle(AppColors.textTertiary)
                DesireStarView(size: 32, state: .dim, cadence: .locked)
                DesireStarView(size: 18, state: .dim, cadence: .locked)
                DesireStarView(size: 12, state: .dim, cadence: .locked)
            }
        }
    }
}

#Preview("Locked cadence") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        DesireStarView(size: 24, state: .lit, label: "Rare spark", cadence: .locked)
    }
}

#Preview("Two-seed ignite") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        HStack(spacing: AppSpacing.xl) {
            DesireStarView(size: 22, state: .lit, label: "Opening Up", cadence: .free, ignites: true)
            DesireStarView(size: 15, state: .lit, label: "Shared", cadence: .free, ignites: true)
        }
    }
    .preferredColorScheme(.dark)
}

```

---

## File: `Vayl/Features/Desire Map/Views/Components/ConstellationField.swift` {#file-vayl-features-desire-map-views-components-constellationfield-swift}

```swift
//
//  ConstellationField.swift
//  Vayl
//
//  Lays out DesireStarView atoms at deterministic phyllotaxis positions and
//  draws constellation lines between proximate nodes.
//
//  1 node  → single hero star centred, no lines.
//  2+ nodes → golden-angle spread without crowding; lines connect proximate pairs.
//
//  Line modes:
//    .hidden    — no lines drawn
//    .hesitant  — thin white lines that draw partway and pull back on a loop,
//                 never fully connecting (used on the rater's charted finish beat)
//    .confident — lines draw on once and hold (used on the reveal)
//
//  Reduce Motion:
//    .hesitant  → static faint partial draw (no loop)
//    .confident → lines appear at full opacity with a fast cross-fade (no draw-on)
//

import SwiftUI

// MARK: - Line mode

enum ConstellationLineMode {
    case hidden
    case hesitant
    case confident
}

// MARK: - Node data

struct ConstellationNodeData: Identifiable {
    let id: String
    var size: CGFloat = 14
    var state: DesireStarView.StarState = .lit
    var label: String? = nil
    var cadence: DesireStarView.Cadence = .free
}

// MARK: - ConstellationField

struct ConstellationField: View {

    var nodes: [ConstellationNodeData]
    var lineMode: ConstellationLineMode = .hidden
    /// Called with the node's `id` string when the user taps a star.
    var onNodeTapped: ((String) -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hesitantTrim: Double = 0.0
    @State private var confidentTrim: Double = 0.0
    /// Drives the looping hesitant sketch through .ambientAnimation (the canonical
    /// Reduce-Motion gate), toggled on appear instead of a bare repeatForever.
    @State private var hesitantAnimating = false

    var body: some View {
        GeometryReader { geo in
            let fieldSize = geo.size
            let positions = nodePositions(count: nodes.count, in: fieldSize)
            let connections = proximateConnections(positions: positions, in: fieldSize)

            ZStack {
                // ── Lines ──────────────────────────────────
                // Path + .trim() participates in SwiftUI's animation interpolation;
                // Canvas does not — keep lines as view-layer Paths.
                if lineMode != .hidden, nodes.count > 1 {
                    if lineMode == .hesitant {
                        // Looping sketch goes through .ambientAnimation (the canonical
                        // Reduce-Motion gate). Scoped to .hesitant so it never clobbers
                        // the .confident draw-on, which owns its own withAnimation.
                        lineLayer(connections: connections, positions: positions)
                            .ambientAnimation(
                                .easeInOut(duration: AppAnimation.desireHesitantSketch / 2)
                                    .repeatForever(autoreverses: true),
                                value: hesitantAnimating
                            )
                    } else {
                        lineLayer(connections: connections, positions: positions)
                    }
                }

                // ── Stars ──────────────────────────────────
                ForEach(Array(nodes.enumerated()), id: \.element.id) { i, node in
                    DesireStarView(
                        size: node.size,
                        state: node.state,
                        label: node.label,
                        cadence: node.cadence
                    )
                    .position(positions[i])
                    .onTapGesture { onNodeTapped?(node.id) }
                }
            }
        }
        .onAppear { startLineAnimation() }
    }

    // MARK: - Line layer

    @ViewBuilder
    private func lineLayer(connections: [(Int, Int)], positions: [CGPoint]) -> some View {
        let trim = lineMode == .hesitant ? hesitantTrim : confidentTrim
        let lineOpacity = lineMode == .hesitant ? 0.18 : 0.34

        ZStack {
            ForEach(Array(connections.enumerated()), id: \.offset) { _, conn in
                Path { path in
                    path.move(to: positions[conn.0])
                    path.addLine(to: positions[conn.1])
                }
                .trim(from: 0, to: trim)
                .stroke(
                    Color.white.opacity(lineOpacity),
                    style: StrokeStyle(lineWidth: 0.7, lineCap: .round)
                )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Layout

    // Vogel phyllotaxis (sunflower) — positions are a pure function of index and count.
    // Golden angle ≈ 137.508° ensures no two stars share the same radial spoke.
    // maxRadius uses 40% of the shorter dimension, leaving a margin for the star halos.
    private func nodePositions(count: Int, in size: CGSize) -> [CGPoint] {
        guard count > 0, size.width > 0, size.height > 0 else { return [] }
        guard count > 1 else {
            return [CGPoint(x: size.width / 2, y: size.height / 2)]
        }

        let goldenAngle: CGFloat = 2.399963229728653 // 137.508° in radians
        let maxRadius = min(size.width, size.height) * 0.40
        let cx = size.width / 2
        let cy = size.height / 2

        return (0..<count).map { i in
            // (i + 0.5) / count: no star at exact centre, even spread from ring 0 out.
            let r = maxRadius * sqrt((CGFloat(i) + 0.5) / CGFloat(count))
            let theta = CGFloat(i) * goldenAngle
            return CGPoint(
                x: cx + r * cos(theta),
                y: cy + r * sin(theta)
            )
        }
    }

    // Connect any two stars closer than 45% of the shorter canvas dimension.
    // This produces 2–6 connections for typical node counts (3–10) without
    // creating a fully-connected graph.
    private func proximateConnections(positions: [CGPoint], in size: CGSize) -> [(Int, Int)] {
        guard positions.count > 1, size.width > 0 else { return [] }
        let threshold = min(size.width, size.height) * 0.45
        var result: [(Int, Int)] = []
        for i in 0..<positions.count {
            for j in (i + 1)..<positions.count {
                let dx = positions[i].x - positions[j].x
                let dy = positions[i].y - positions[j].y
                if sqrt(dx * dx + dy * dy) < threshold {
                    result.append((i, j))
                }
            }
        }
        return result
    }

    // MARK: - Animation

    private func startLineAnimation() {
        switch lineMode {
        case .hidden:
            break

        case .hesitant:
            if reduceMotion {
                // Static faint partial — suggests lines without completing them.
                hesitantTrim = 0.42
            } else {
                // Draws toward 0.65, reverses, never fully connects. The looping
                // animation lives on the line layer via .ambientAnimation (which
                // carries the Reduce-Motion gate); toggling hesitantAnimating starts it.
                hesitantTrim = 0.65
                hesitantAnimating = true
            }

        case .confident:
            withAnimation(reduceMotion
                ? .easeOut(duration: 0.15)
                : AppAnimation.desireLineDraw
            ) {
                confidentTrim = 1.0
            }
        }
    }
}

// MARK: - Previews

private func sampleNodes(_ count: Int, allLit: Bool = true) -> [ConstellationNodeData] {
    let labels = ["Shared space", "Deep talk", "New together", "Our ritual",
                  "Adventure", "Quiet time", "Openness", "Play", "Growth"]
    return (0..<count).map { i in
        ConstellationNodeData(
            id: "n\(i)",
            size: 14,
            state: allLit ? .lit : (i == 0 ? .lit : .dim),
            label: count > 2 ? labels[i % labels.count] : nil,
            cadence: i == 0 ? .free : .locked
        )
    }
}

#Preview("1 node — hero") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        ConstellationField(nodes: sampleNodes(1), lineMode: .hidden)
            .frame(width: 300, height: 280)
    }
}

#Preview("3 nodes — hesitant") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        ConstellationField(nodes: sampleNodes(3), lineMode: .hesitant)
            .frame(width: 300, height: 280)
    }
}

#Preview("3 nodes — confident") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        ConstellationField(nodes: sampleNodes(3), lineMode: .confident)
            .frame(width: 300, height: 280)
    }
}

#Preview("5 nodes — hesitant") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        ConstellationField(nodes: sampleNodes(5), lineMode: .hesitant)
            .frame(width: 300, height: 280)
    }
}

#Preview("5 nodes — confident") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        ConstellationField(nodes: sampleNodes(5), lineMode: .confident)
            .frame(width: 300, height: 280)
    }
}

#Preview("5 nodes — lit + dim mix") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        ConstellationField(nodes: sampleNodes(5, allLit: false), lineMode: .confident)
            .frame(width: 300, height: 280)
    }
}

```

---

## File: `Vayl/Features/Desire Map/CeremonyVariant.swift` {#file-vayl-features-desire-map-ceremonyvariant-swift}

```swift
//
//  CeremonyVariant.swift
//  Vayl
//
//  The three telegraphed Desire Map reveal ceremonies, picked deterministically by the couple
//  (so a new partner or a watched friend gets a different one). The variant only sets the
//  telegraph and the lighting order of the assembly — it composes with any match count and any
//  layout seed. Pure logic, no SwiftUI.
//
//  Feel reference: docs/prototypes/desire-map-ceremony-variants.html
//  Spec: docs/superpowers/specs/2026-06-27-desire-map-reveal-ceremony-design.md
//

import CoreGraphics
import Foundation

enum CeremonyVariant: Int, CaseIterable {
    case gather        // stills, pulls light to center, hero forms, the rest radiate outward
    case sweep         // a band passes; pairs snap together in its wake, in spatial order
    case constellate   // all at once — every star merges simultaneously

    /// Deterministic per couple. Same `coupleId` always resolves the same variant (FNV-1a seed,
    /// not `hashValue`, so it survives relaunches). Unpaired falls back to `.gather`.
    static func resolve(coupleId: UUID?) -> CeremonyVariant {
        guard let coupleId else { return .gather }
        let seed = ConstellationLayout.seed(for: coupleId)
        let index = Int(seed % UInt64(CeremonyVariant.allCases.count))
        return CeremonyVariant(rawValue: index) ?? .gather
    }

    enum Telegraph: Equatable { case gather, sweep, none }

    var telegraph: Telegraph {
        switch self {
        case .gather:      return .gather
        case .sweep:       return .sweep
        case .constellate: return .none
        }
    }

    /// Each star index paired with its delay (seconds) from assembly start. The constellation
    /// lights stars in this order; a line draws once both its endpoints have lit.
    func schedule(points: [CGPoint], heroIndex: Int) -> [(index: Int, delay: Double)] {
        let count = points.count
        guard count > 0 else { return [] }

        switch self {
        case .gather:
            // Hero first, then the rest from the center outward.
            let centroid = centroid(of: points)
            let others = (0..<count)
                .filter { $0 != heroIndex }
                .sorted { distance(points[$0], centroid) < distance(points[$1], centroid) }
            let per = stagger(for: count)
            var result: [(index: Int, delay: Double)] = [(heroIndex, 0)]
            for (k, i) in others.enumerated() {
                result.append((i, AppAnimation.desireCeremonyHeroLead + Double(k) * per))
            }
            return result

        case .sweep:
            // Stars light in spatial order along the sweep, timed to the band's pass.
            let xs = points.map { Double($0.x) }
            let minX = xs.min() ?? 0
            let maxX = xs.max() ?? 1
            let span = max(0.0001, maxX - minX)
            return (0..<count)
                .sorted { points[$0].x < points[$1].x }
                .map { i in
                    let fraction = (Double(points[i].x) - minX) / span
                    return (index: i, delay: fraction * AppAnimation.desireSweepDuration)
                }

        case .constellate:
            // Simultaneous — every star merges at once.
            return (0..<count).map { (index: $0, delay: 0) }
        }
    }

    // MARK: - Helpers

    private func stagger(for count: Int) -> Double {
        let raw = AppAnimation.desireCeremonyBudget / Double(max(count, 1))
        return min(AppAnimation.desireCeremonyStaggerMax,
                   max(AppAnimation.desireCeremonyStaggerMin, raw))
    }

    private func centroid(of points: [CGPoint]) -> CGPoint {
        let n = Double(max(points.count, 1))
        let cx = points.reduce(0.0) { $0 + Double($1.x) } / n
        let cy = points.reduce(0.0) { $0 + Double($1.y) } / n
        return CGPoint(x: cx, y: cy)
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
        hypot(Double(a.x - b.x), Double(a.y - b.y))
    }
}

```

---

## File: `Vayl/Features/Desire Map/ConstellationLayout.swift` {#file-vayl-features-desire-map-constellationlayout-swift}

```swift
//
//  ConstellationLayout.swift
//  Vayl
//
//  Pure, deterministic constellation generator for the Desire Map reveal (Model/util layer —
//  no SwiftUI, no state). Maps a match count + a per-couple seed to star positions, connecting
//  edges, and a hero index. Same (count, seed) always yields the same constellation, so a
//  couple's sky is stable, varies across couples, and is unit-testable.
//
//  Positions: a seeded golden-angle (phyllotaxis) spiral, perturbed by the seed (rotation +
//  jitter + slight aspect squash) — even spread, no crowding, any count from 1 to 17.
//  Edges: a minimum spanning tree (always one connected figure, never a web) plus up to two
//  short extra links for richness.
//
//  Feel reference: docs/prototypes/desire-map-constellation-engine.html
//  Spec: docs/superpowers/specs/2026-06-27-desire-map-reveal-ceremony-design.md
//

import SwiftUI

enum ConstellationLayout {

    struct Edge: Equatable {
        let a: Int
        let b: Int
    }

    struct Result: Equatable {
        /// Normalized 0...1 positions inside the field.
        let points: [CGPoint]
        /// Index pairs to connect with a line. Empty when count < 2.
        let edges: [Edge]
        /// Index of the central hero star (the free-reveal star sits here). 0 when count <= 1.
        let heroIndex: Int
    }

    /// Golden angle (137.5°) in radians — the phyllotaxis spoke separation.
    private static let goldenAngle: Double = 2.399963229728653

    // MARK: - Generate

    static func generate(count: Int, seed: UInt64) -> Result {
        guard count > 0 else { return Result(points: [], edges: [], heroIndex: 0) }

        var rng = SeededRNG(seed: seed)
        let rotation = rng.nextUnit() * 2 * .pi
        let squash = 0.84 + rng.nextUnit() * 0.26   // slight aspect variation per seed

        var points: [CGPoint] = []
        points.reserveCapacity(count)
        for i in 0..<count {
            let r = sqrt((Double(i) + 0.5) / Double(count)) * 0.40
            let theta = Double(i) * goldenAngle + rotation
            let jx = (rng.nextUnit() - 0.5) * 0.05
            let jy = (rng.nextUnit() - 0.5) * 0.05
            let x = 0.5 + r * cos(theta) + jx
            let y = 0.47 + r * sin(theta) * squash + jy
            points.append(CGPoint(
                x: CGFloat(min(0.87, max(0.13, x))),
                y: CGFloat(min(0.86, max(0.12, y)))
            ))
        }

        let heroIndex = nearestToCentroidIndex(points)
        let edges = count > 1 ? buildEdges(points: points, hero: heroIndex, rng: &rng) : []
        return Result(points: points, edges: edges, heroIndex: heroIndex)
    }

    /// Stable per-couple seed from the couple's UUID bytes (FNV-1a). NOT `hashValue` — Swift's
    /// hashing is randomized per process, which would reshuffle the sky every launch.
    static func seed(for coupleId: UUID) -> UInt64 {
        let b = coupleId.uuid
        let bytes: [UInt8] = [b.0, b.1, b.2, b.3, b.4, b.5, b.6, b.7,
                              b.8, b.9, b.10, b.11, b.12, b.13, b.14, b.15]
        var h: UInt64 = 0xcbf29ce484222325            // FNV-1a 64-bit offset basis
        for byte in bytes { h = (h ^ UInt64(byte)) &* 0x100000001b3 }
        return h
    }

    // MARK: - Edges (MST + short extras)

    private static func buildEdges(points: [CGPoint], hero: Int, rng: inout SeededRNG) -> [Edge] {
        let n = points.count
        var inTree: Set<Int> = [hero]
        var rest = Set(0..<n)
        rest.remove(hero)
        var edges: [Edge] = []

        // Prim's minimum spanning tree — guarantees one connected figure with n-1 edges.
        while !rest.isEmpty {
            var best = Double.greatestFiniteMagnitude
            var bi = hero
            var bj = -1
            for i in inTree {
                for j in rest {
                    let d = dist(points[i], points[j])
                    if d < best { best = d; bi = i; bj = j }
                }
            }
            guard bj >= 0 else { break }
            edges.append(Edge(a: bi, b: bj))
            inTree.insert(bj)
            rest.remove(bj)
        }

        // A couple of short extra links for richness (seeded), never long enough to read as clutter.
        let mean = edges.reduce(0.0) { $0 + dist(points[$1.a], points[$1.b]) } / Double(max(edges.count, 1))
        var have = Set<String>()
        for e in edges { have.insert(key(e.a, e.b)) }
        var candidates: [(d: Double, a: Int, b: Int)] = []
        for i in 0..<n {
            for j in (i + 1)..<n where !have.contains(key(i, j)) {
                let d = dist(points[i], points[j])
                if d < mean * 1.35 { candidates.append((d, i, j)) }
            }
        }
        candidates.sort { $0.d < $1.d }
        let extraCount = n >= 5 ? 1 + Int(rng.nextUnit() * 2) : (n >= 4 ? 1 : 0)
        for c in candidates.prefix(extraCount) { edges.append(Edge(a: c.a, b: c.b)) }
        return edges
    }

    // MARK: - Helpers

    private static func nearestToCentroidIndex(_ pts: [CGPoint]) -> Int {
        guard pts.count > 1 else { return 0 }
        let cx = pts.reduce(0.0) { $0 + Double($1.x) } / Double(pts.count)
        let cy = pts.reduce(0.0) { $0 + Double($1.y) } / Double(pts.count)
        let centroid = CGPoint(x: CGFloat(cx), y: CGFloat(cy))
        var best = Double.greatestFiniteMagnitude
        var idx = 0
        for (i, p) in pts.enumerated() {
            let d = dist(p, centroid)
            if d < best { best = d; idx = i }
        }
        return idx
    }

    private static func dist(_ a: CGPoint, _ b: CGPoint) -> Double {
        hypot(Double(a.x - b.x), Double(a.y - b.y))
    }

    private static func key(_ i: Int, _ j: Int) -> String {
        "\(min(i, j))-\(max(i, j))"
    }
}

// MARK: - Seeded RNG

/// Tiny deterministic seeded PRNG (SplitMix64). Fast, well-distributed, and reproducible across
/// launches — the property `hashValue` does not give us. File-private to avoid clashing with the
/// identically-named generator in StarVeil.
private struct SeededRNG {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Next value in [0, 1) using a 53-bit mantissa.
    mutating func nextUnit() -> Double {
        Double(next() >> 11) * (1.0 / 9007199254740992.0)
    }
}

// MARK: - Debug visual check

#if DEBUG
private struct _ConstellationLayoutDebug: View {
    let count: Int
    let seed: UInt64

    var body: some View {
        GeometryReader { geo in
            let result = ConstellationLayout.generate(count: count, seed: seed)
            ZStack {
                Path { path in
                    for e in result.edges {
                        path.move(to: scaled(result.points[e.a], geo.size))
                        path.addLine(to: scaled(result.points[e.b], geo.size))
                    }
                }
                .stroke(Color.white.opacity(0.4), lineWidth: 0.8)

                ForEach(Array(result.points.enumerated()), id: \.offset) { i, p in
                    let isHero = i == result.heroIndex
                    Circle()
                        .fill(isHero ? Color.white : AppColors.spectrumMagenta)
                        .frame(width: isHero ? 11 : 6, height: isHero ? 11 : 6)
                        .shadow(color: AppColors.spectrumPurple.opacity(0.6), radius: 4)
                        .position(scaled(p, geo.size))
                }
            }
        }
    }

    private func scaled(_ p: CGPoint, _ size: CGSize) -> CGPoint {
        CGPoint(x: p.x * size.width, y: p.y * size.height)
    }
}

#Preview("Layout — counts (same seed)") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VStack(spacing: AppSpacing.lg) {
            ForEach([1, 2, 5, 9, 14], id: \.self) { c in
                _ConstellationLayoutDebug(count: c, seed: 7)
                    .frame(height: 110)
                    .overlay(alignment: .topLeading) {
                        Text("\(c)").font(AppFonts.caption).foregroundStyle(AppColors.textTertiary)
                    }
            }
        }
        .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}

#Preview("Layout — variety (5 stars, 4 seeds)") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VStack(spacing: AppSpacing.lg) {
            ForEach([UInt64(7), 42, 1000, 999999], id: \.self) { s in
                _ConstellationLayoutDebug(count: 5, seed: s)
                    .frame(height: 110)
            }
        }
        .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
#endif

```

---

## File: `Vayl/Core/Models/CompanionCard.swift` {#file-vayl-core-models-companioncard-swift}

```swift
//
//  CompanionCard.swift
//  Vayl
//
//  STUB — "Desire Map companion cards." After a couple completes the Desire Map, a companion
//  card bridges a result into a next step: a short conversation prompt and/or a suggested deck
//  to open together. Linked from `DesireMatch.bridgeCardId`. Pure data shape (Model layer).
//  Real content (companion_cards.json) + per-item deck linkage is future work.
//

import Foundation

struct CompanionCard: Codable, Identifiable, Hashable {
    let id: String              // == DesireMatch.bridgeCardId
    let desireItemId: String    // the desire item this companion bridges
    let title: String
    let prompt: String          // the conversation companion prompt
    let suggestedDeckId: String?  // a deck to open next (stub link, nil until wired)
}

// MARK: - Tier

enum CompanionCardTier: String, Codable {
    case mutual
    case adjacent
    case consentOpened = "consent_opened"
}

// MARK: - Content pool (deserialized from companion_cards.json)

struct CompanionCardPool: Codable {
    let tier: CompanionCardTier
    let prompts: [CompanionCardPrompt]
}

struct CompanionCardPrompt: Codable, Identifiable {
    let id: String
    let text: String
}

```

---

## File: `Vayl/Features/Desire Map/Store/CompanionCardStore.swift` {#file-vayl-features-desire-map-store-companioncardstore-swift}

```swift
//
//  CompanionCardStore.swift
//  Vayl
//
//  Resolves a tier-appropriate conversation prompt for a desire item.
//  Owned by VaultStore. Calls ContentLoader (service layer) for content.
//

import Foundation

@Observable
@MainActor
final class CompanionCardStore {

    private var pools: [CompanionCardPool] = []

    init() {
        pools = (try? ContentLoader.loadCompanionCards()) ?? []
    }

    /// Returns a CompanionCard for a mutual or adjacent match.
    /// Prompt selection is stable: same itemId always returns the same prompt from the tier pool.
    func card(forItemId itemId: String, tier: CompanionCardTier) -> CompanionCard? {
        guard let pool = pools.first(where: { $0.tier == tier }),
              !pool.prompts.isEmpty else { return nil }
        let idx = stableIndex(for: itemId, count: pool.prompts.count)
        let prompt = pool.prompts[idx]
        return CompanionCard(
            id: "discussion_\(tier.rawValue)_\(itemId)",
            desireItemId: itemId,
            title: "Talk about this",
            prompt: prompt.text,
            suggestedDeckId: nil
        )
    }

    // MARK: - Private

    /// Deterministic index derived from the itemId string -- stable across process restarts.
    /// Uses Unicode scalar sum (not hashValue, which is randomized in Swift).
    private func stableIndex(for itemId: String, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let sum = itemId.unicodeScalars.reduce(0 as UInt) { $0 &+ UInt($1.value) }
        return Int(sum % UInt(count))
    }
}

```

---

## File: `Vayl/Features/Desire Map/Store/DesireMapStore.swift` {#file-vayl-features-desire-map-store-desiremapstore-swift}

```swift
//
//  DesireMapStore.swift
//  Vayl
//
//  Store layer for the Desire Map rater (4-Layer arch: View → Store → Service/Model).
//  Owns rater state, resolves the cohort TRACK from the local profile, and upserts
//  one DesireMapEntry per (userId, itemId). Local-only in D1 — no Service/sync calls.
//
//  TRACK resolution (D1, local): UserProfile.nmStage → "curious" | "established".
//  The couple-level rule (either partner curious → both get the Curious set) needs the
//  partner's nmStage and lands at compare time (D3/D4); this resolves the local user only.
//

import Foundation
import SwiftData

@Observable
@MainActor
final class DesireMapStore: Identifiable {

    /// Identity for `.sheet`/`.fullScreenCover(item:)` presentation.
    let id = UUID()

    // MARK: - Published state

    /// Items for the resolved track, ordered by sortOrder.
    private(set) var items: [DesireItem] = []

    /// itemId → chosen weight. Mirrors the persisted DesireMapEntry rows.
    private(set) var ratings: [String: DesireRatingValue] = [:]

    /// "curious" | "established" — drives which answer copy the View shows.
    private(set) var track: String = "curious"

    /// Set when there is no local profile / load failed; the View shows an empty state.
    private(set) var loadError: String?

    var totalCount: Int { items.count }
    var ratedCount: Int { items.reduce(0) { $0 + (ratings[$1.id] != nil ? 1 : 0) } }
    var isComplete: Bool { totalCount > 0 && ratedCount == totalCount }

    // MARK: - Dependencies

    private let modelContainer: ModelContainer
    private let appState: AppState
    private var userId: UUID?      // PRIVATE local profile id — stamped on each entry
    private var nmStageRaw: String = "curious"   // raw nm_stage — synced for the match edge fn

    /// Sync seam. Defaults to the real best-effort SyncManager push; tests inject a no-op (or a
    /// capture) so completion never spawns a background network/SwiftData Task that races teardown.
    /// Mirrors `CoupleSessionStore.enqueueSync`.
    private let enqueueSync: @MainActor ([PendingDesireRating], String) -> Void

    init(
        modelContainer: ModelContainer,
        appState: AppState,
        enqueueSync: (@MainActor ([PendingDesireRating], String) -> Void)? = nil
    ) {
        self.modelContainer = modelContainer
        self.appState = appState
        self.enqueueSync = enqueueSync ?? { snapshot, stage in
            Task { await SyncManager.shared.syncDesireMap(ratings: snapshot, nmStage: stage) }
        }
    }

    // MARK: - Load

    /// Resolve the profile + track, load the track's items, and hydrate any existing ratings.
    func load() {
        resolveProfile()
        loadItems()
        loadExistingRatings()
        if isComplete {
            // Self-heal: a map completed before the completion flag was written still marks
            // the profile complete (idempotent).
            markProfileComplete()
            // Offline-retry: if a prior completion failed to sync, retry now that the rater is open.
            if UserDefaults.standard.bool(forKey: "pendingDesireSync") {
                triggerSync()
            }
        }
    }

    private func resolveProfile() {
        let context = ModelContext(modelContainer)
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else {
            loadError = "No profile found — finish onboarding first."
            return
        }
        userId = profile.id
        nmStageRaw = profile.nmStage.rawValue
        track = (profile.nmStage == .curious) ? "curious" : "established"
    }

    private func loadItems() {
        do {
            let all = try ContentLoader.loadDesireItems()
            items = all
                .filter { $0.appears(in: track) }
                .sorted { $0.sortOrder < $1.sortOrder }
        } catch {
            loadError = "Couldn't load desire items: \(error.localizedDescription)"
            items = []
        }
    }

    private func loadExistingRatings() {
        guard let userId else { return }
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<DesireMapEntry>(
            predicate: #Predicate { $0.userId == userId }
        )
        guard let entries = try? context.fetch(descriptor) else { return }
        ratings = Dictionary(entries.map { ($0.itemId, $0.rating) }, uniquingKeysWith: { _, latest in latest })
    }

    // MARK: - Rate (upsert)

    /// Save or update the user's rating for one item. Re-rating updates in place
    /// (one DesireMapEntry per (userId, itemId), mirroring the desire_ratings unique key).
    func rate(itemId: String, rating: DesireRatingValue) {
        guard let userId else { loadError = "No profile"; return }
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<DesireMapEntry>(
            predicate: #Predicate { $0.userId == userId && $0.itemId == itemId }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.rating = rating
            existing.completedAt = Date()
        } else {
            context.insert(DesireMapEntry(userId: userId, itemId: itemId, rating: rating))
        }
        try? context.save()
        ratings[itemId] = rating

        // On completion: durably mark the local profile complete (the truth the rest of the app
        // reads — HomeStore.myMapComplete, Getting Started, desireMapState), THEN sync. Local-first:
        // the flag is set independently of sync success (sync is best-effort and retried on reopen).
        if isComplete {
            markProfileComplete()
            triggerSync()
        }
    }

    // MARK: - Completion flag

    /// Durably mark the local profile's Desire Map complete — the single source of truth the rest
    /// of the app reads (`HomeStore.myMapComplete`, Getting Started, `desireMapState`). Set on
    /// completion, independently of remote sync. Idempotent.
    private func markProfileComplete() {
        guard let userId else { return }
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.id == userId }
        )
        guard let profile = try? context.fetch(descriptor).first,
              !profile.hasCompletedDesireMap else { return }
        profile.hasCompletedDesireMap = true
        try? context.save()
    }

    // MARK: - Sync (D2)

    /// Snapshot all of this user's entries and push to Supabase (best-effort, via SyncManager).
    private func triggerSync() {
        let snapshot = entrySnapshots()
        guard !snapshot.isEmpty else { return }
        enqueueSync(snapshot, nmStageRaw)
    }

    private func entrySnapshots() -> [PendingDesireRating] {
        guard let userId else { return [] }
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<DesireMapEntry>(
            predicate: #Predicate { $0.userId == userId }
        )
        guard let entries = try? context.fetch(descriptor) else { return [] }
        return entries.map(PendingDesireRating.init)
    }

    // MARK: - View helpers

    /// The four answer strings for `item` on the resolved track, in DesireRatingValue.allCases order.
    func answers(for item: DesireItem) -> [String] {
        item.answers(for: track) ?? []
    }

    func existingRating(for itemId: String) -> DesireRatingValue? {
        ratings[itemId]
    }
}

```

---

## File: `Vayl/Features/Desire Map/Views/DesireMapView.swift` {#file-vayl-features-desire-map-views-desiremapview-swift}

```swift
import SwiftUI
import SwiftData

// MARK: - DesireMapView
// Two-track card rater (View layer — reads DesireMapStore, forwards taps; no DB/Service).
// One desire per card; the four answers + which items appear are cohort-driven (store.track).
// Only the WEIGHT (DesireRatingValue) is stored — the displayed string is cohort copy.
//
// RaterPhase drives the visual state machine:
//   .start   — invitation screen + spectrum-bloom entrance (S2.1)
//   .rating  — void layout, pills, growing star sky (S2.2)
//   .charted — hesitant constellation lines + "Your map is charted." (S2.3)
//   .mirror  — solo wait: grouped private answers, no progress race (S2.4)
//   .ready   — first finisher re-entry: same mirror + "partner finished" bar (S2.4)

struct DesireMapView: View {

    let store: DesireMapStore
    /// Display name for the partner — shown in charted + mirror copy.
    var partnerName: String = "your partner"
    /// True when the partner has also completed their map. Drives the ready bar in mirror.
    var partnerComplete: Bool = false

    @Environment(\.vaylDismiss) private var vaylDismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Presentation phase

    private enum RaterPhase { case start, rating, charted, mirror, ready }
    @State private var raterPhase: RaterPhase = .start

    // MARK: - Rating navigation

    @State private var index: Int = 0

    // MARK: - Bloom entrance (S2.1)

    @State private var bloomScale: CGFloat  = 0.01
    @State private var bloomOpacity: Double = 0.0
    @State private var startVisible: Bool   = true
    @State private var ratingVisible: Bool  = false

    // MARK: - Charted beat (S2.3)

    @State private var chartedStarsVisible: Bool = false
    @State private var chartedLinesActive: Bool  = false
    @State private var chartedTitleVisible: Bool = false

    /// The charted-finish ceremony, held so a tap (skip) or disappear can cancel it.
    @State private var chartedTask: Task<Void, Never>? = nil

    // MARK: - Star-rise sync (S2.2)
    // Bumped on every answer commit so the accumulating sky animates the new star
    // rising on desireStarRise, synced to the question receding on desireDepthExit.
    @State private var starRiseTick: Int = 0
    @State private var sparkBreath: Bool = false

    // MARK: - Haptics

    @State private var hapticTick: Int = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            OnboardingAtmosphere(config: atmosphereConfig).ignoresSafeArea()
            if raterPhase == .start {
                starField.ignoresSafeArea()
            }

            content

            GlowOrb(color: AppColors.spectrumMagenta, size: 300)
                .scaleEffect(bloomScale)
                .opacity(bloomOpacity)
                .allowsHitTesting(false)
                .ignoresSafeArea()
        }
        .screenshotProtected()
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTick)
        .onAppear {
            store.load()
            if let firstUnrated = store.items.firstIndex(where: { store.existingRating(for: $0.id) == nil }) {
                index = firstUnrated
            }
            if !store.items.isEmpty, store.ratedCount > 0 {
                raterPhase = store.ratedCount >= store.totalCount
                    ? (partnerComplete ? .ready : .mirror)
                    : .rating
                ratingVisible = true
            }
        }
        .onChange(of: index) { _, newValue in
            guard newValue >= store.items.count, raterPhase == .rating else { return }
            withAnimation(AppAnimation.desireFinishFade) { raterPhase = .charted }
            runChartedSequence()
        }
        .onDisappear {
            // Don't let the charted ceremony outlive the view.
            chartedTask?.cancel()
            chartedTask = nil
        }
    }

    // MARK: - Atmosphere config

    private var atmosphereConfig: AtmosphereConfig {
        raterPhase == .start ? .modeSelect : .cardReveal
    }

    // MARK: - Phase routing

    @ViewBuilder
    private var content: some View {
        if let error = store.loadError {
            emptyState(error)
        } else if store.items.isEmpty {
            emptyState("No desire items to show.")
        } else {
            switch raterPhase {
            case .start:
                startScreen
                    .opacity(startVisible ? 1 : 0)
                    .animation(AppAnimation.desireFinishFade.reduceMotionSafe, value: startVisible)
                    .transition(.opacity)

            case .rating:
                raterContent
                    .opacity(ratingVisible ? 1 : 0)
                    .animation(AppAnimation.desireStarIgnite.reduceMotionSafe, value: ratingVisible)
                    .transition(.opacity)

            case .charted:
                chartedScreen
                    // Tap anywhere during the charted hold skips the ceremony and proceeds.
                    .contentShape(Rectangle())
                    .onTapGesture { skipChartedSequence() }
                    .transition(.opacity)

            case .mirror, .ready:
                mirrorScreen
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Start screen (S2.1)

    private var startScreen: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()

                Text("Desire Map")
                    .font(AppFonts.overline)
                    .tracking(1.5)
                    .foregroundStyle(AppColors.textTertiary)
                    .padding(.bottom, AppSpacing.lg)

                VStack(spacing: 2) {
                    Text("See where your desires")
                        .font(AppFonts.heroTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                    LivingText(text: "meet", font: AppFonts.heroTitle)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)

                Text("Opening up usually waits on a conversation no one wants to start. So you each answer in private, and only the desires you **both** want are ever revealed. You begin already knowing where you agree.")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxl)
                    .padding(.bottom, AppSpacing.md)

                HStack(alignment: .top, spacing: AppSpacing.xs) {
                    Text("◇")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                    Text("If only one of you wants it, it stays private. Your no is never shown to your partner.")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, AppSpacing.xxl)

                Spacer()

                VStack(spacing: AppSpacing.sm) {
                    VaylButton(label: "Begin", style: .primary, size: .fullWidth) { beginTapped() }
                        .frame(height: VaylButtonSize.fullWidth.height)

                    let count = store.totalCount > 0 ? store.totalCount : 17
                    Text("\(count) questions · about 3 minutes")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)
            }

            VStack {
                HStack {
                    Spacer()
                    Button { hapticTick += 1; vaylDismiss(confirm: false) } label: {
                        Image(systemName: "xmark")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textTertiary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(AppColors.cardBg.opacity(0.55)))
                            .overlay(Circle().stroke(AppColors.borderSubtle, lineWidth: 1))
                    }
                    .buttonStyle(_RaterPressStyle())
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Star field (S2.1 background, 44 stars ~18 twinkling)

    private static let _bgStars: [(Double, Double, Double, Double, Double)] = [
        (0.08, 0.04, 1.2, 0.20, 0), (0.52, 0.03, 1.0, 0.14, 0), (0.75, 0.12, 0.7, 0.10, 0),
        (0.42, 0.16, 0.8, 0.12, 0), (0.05, 0.28, 0.9, 0.18, 0), (0.35, 0.32, 0.7, 0.08, 0),
        (0.80, 0.30, 1.2, 0.15, 0), (0.70, 0.35, 0.8, 0.10, 0), (0.60, 0.50, 0.9, 0.12, 0),
        (0.32, 0.55, 1.3, 0.08, 0), (0.05, 0.58, 0.8, 0.07, 0), (0.45, 0.65, 1.0, 0.09, 0),
        (0.15, 0.70, 0.7, 0.07, 0), (0.62, 0.78, 0.9, 0.07, 0), (0.38, 0.82, 1.2, 0.08, 0),
        (0.10, 0.85, 0.6, 0.06, 0), (0.72, 0.88, 1.0, 0.07, 0), (0.50, 0.92, 0.8, 0.05, 0),
        (0.30, 0.20, 0.9, 0.13, 0), (0.90, 0.14, 0.7, 0.09, 0), (0.18, 0.44, 0.8, 0.10, 0),
        (0.85, 0.50, 0.7, 0.08, 0), (0.25, 0.62, 1.0, 0.08, 0), (0.68, 0.62, 0.8, 0.07, 0),
        (0.95, 0.72, 0.6, 0.06, 0), (0.55, 0.88, 0.9, 0.06, 0),
        (0.92, 0.07, 0.9, 0.20, 3.2), (0.28, 0.10, 1.5, 0.22, 4.8),
        (0.18, 0.18, 1.1, 0.18, 3.8), (0.65, 0.08, 1.3, 0.20, 4.1),
        (0.87, 0.21, 1.0, 0.16, 2.9), (0.55, 0.25, 1.4, 0.22, 4.5),
        (0.12, 0.38, 1.0, 0.18, 3.6), (0.48, 0.42, 1.1, 0.16, 2.7),
        (0.22, 0.45, 1.5, 0.20, 4.2), (0.90, 0.44, 0.8, 0.14, 3.4),
        (0.78, 0.60, 1.0, 0.12, 4.7), (0.88, 0.72, 1.1, 0.10, 3.1),
        (0.58, 0.15, 1.2, 0.18, 4.0), (0.40, 0.75, 1.3, 0.10, 2.8),
        (0.96, 0.38, 0.9, 0.12, 3.9), (0.02, 0.52, 1.0, 0.10, 4.3),
        (0.73, 0.48, 0.8, 0.12, 2.6), (0.14, 0.96, 1.1, 0.08, 3.7),
    ]

    private var starField: some View {
        TimelineView(.periodic(from: .now, by: 0.067)) { timeline in
            Canvas { ctx, size in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: 1000)
                for (idx, star) in DesireMapView._bgStars.enumerated() {
                    let (xr, yr, d, base, period) = star
                    let opacity: Double = period > 0
                        ? 0.2 + (sin((elapsed / period + Double(idx) * 0.37) * .pi * 2) * 0.5 + 0.5) * 0.6
                        : base
                    let x = size.width * xr
                    let y = size.height * yr
                    let r = d / 2
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: d, height: d)),
                             with: .color(.white.opacity(opacity)))
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Bloom entrance

    private func beginTapped() {
        hapticTick += 1
        guard !reduceMotion else {
            startVisible = false; raterPhase = .rating; ratingVisible = true
            return
        }
        // Sleep beats are expressed as fractions of the bloom token's duration, not
        // free magic numbers: the fade-out begins as the bloom nears its peak (~80%),
        // and the orb resets once the fade has largely cleared. bloomDuration mirrors
        // AppAnimation.desireRevealBloom (0.80s) so the timing stays tied to that token.
        let bloomDuration: Double = 0.80
        withAnimation(AppAnimation.desireRevealBloom) {
            bloomScale = 20; bloomOpacity = 0.65; startVisible = false
        }
        Task {
            try? await Task.sleep(for: .seconds(bloomDuration * 0.80))
            withAnimation(AppAnimation.standard) { bloomOpacity = 0 }
            raterPhase = .rating
            withAnimation(AppAnimation.desireStarIgnite.reduceMotionSafe) { ratingVisible = true }
            try? await Task.sleep(for: .seconds(bloomDuration * 0.62))
            bloomScale = 0.01
        }
    }

    // MARK: - Rater (S2.2)

    @ViewBuilder
    private var raterContent: some View {
        if index < store.items.count {
            rater(item: store.items[index])
        }
    }

    private var positiveRatings: [DesireRatingValue] {
        store.items.compactMap { item in
            guard let r = store.existingRating(for: item.id),
                  r == .excitedAboutIt || r == .openToIt else { return nil }
            return r
        }
    }

    private func rater(item: DesireItem) -> some View {
        let answers = store.answers(for: item)
        return ZStack(alignment: .top) {
            // Stars only appear for excited + open answers (stars mark desire, not avoidance)
            _StarAccum(ratings: positiveRatings, riseTrigger: starRiseTick)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.xs)

                // Space for stars to be visible
                Spacer(minLength: 140)

                // Question — transitions on each answer
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(item.category.uppercased())
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .foregroundStyle(AppColors.spectrumMagenta.opacity(0.85))

                    Text(item.name)
                        .font(AppFonts.cardTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.lg)
                .id(index)
                // Two-phase depth: the incoming question emerges from depth on
                // desireDepthEnter; the outgoing one recedes on desireDepthExit.
                // Carrying the animation on each side of the transition lets the
                // single index change drive both phases at their own pace.
                .transition(.asymmetric(
                    insertion: .opacity
                        .combined(with: .scale(scale: 1.04))
                        .animation(AppAnimation.desireDepthEnter.reduceMotionSafe),
                    removal: .opacity
                        .combined(with: .scale(scale: 0.90))
                        .animation(AppAnimation.desireDepthExit.reduceMotionSafe)
                ))

                Spacer(minLength: AppSpacing.lg)

                // Answer area
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("How do you feel about this?")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .padding(.horizontal, AppSpacing.lg)

                    VStack(spacing: AppSpacing.sm) {
                        ForEach(Array(answers.enumerated()), id: \.offset) { idx, label in
                            if idx < DesireRatingValue.allCases.count {
                                let weight = DesireRatingValue.allCases[idx]
                                _RaterPill(
                                    label: label,
                                    hint: pillHint(for: weight),
                                    accent: accentColor(for: weight),
                                    isBoundary: weight == .notForMe,
                                    isSelected: store.existingRating(for: item.id) == weight
                                ) { choose(weight, for: item) }
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }

                // Privacy footer
                Text("Private — only your mutual matches are ever revealed.")
                    .font(AppFonts.meta)
                    .foregroundStyle(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AppSpacing.xxl)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var topBar: some View {
        HStack(spacing: AppSpacing.md) {
            Button { back() } label: {
                Image(systemName: "chevron.left")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(_RaterPressStyle())
            .opacity(index == 0 ? 0.25 : 1)
            .disabled(index == 0)

            progressTrack

            Text("\(index + 1) of \(store.totalCount)")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)

            Button { hapticTick += 1; vaylDismiss(confirm: false) } label: {
                Image(systemName: "xmark")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(_RaterPressStyle())
        }
    }

    private var progressTrack: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.08))
                Capsule()
                    .fill(LinearGradient(
                        colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: geo.size.width * progressRatio)
            }
        }
        .frame(height: 3)
        .animation(AppAnimation.standard, value: store.ratedCount)
    }

    private var progressRatio: CGFloat {
        guard store.totalCount > 0 else { return 0 }
        return CGFloat(store.ratedCount) / CGFloat(store.totalCount)
    }

    // MARK: - Charted beat (S2.3)

    private var chartedScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            GeometryReader { geo in
                let W = geo.size.width
                let H = geo.size.height
                // 6 nodes from the mockup (relative positions in 0-1 space)
                let nodes: [(CGFloat, CGFloat)] = [
                    (0.50, 0.30), (0.26, 0.22), (0.72, 0.26),
                    (0.34, 0.62), (0.68, 0.58), (0.48, 0.80),
                ]
                let connections: [(Int, Int, Double)] = [
                    (0, 1, 0.0), (0, 2, 0.6), (0, 3, 1.2), (2, 4, 0.9), (3, 5, 1.6),
                ]

                ZStack {
                    if chartedLinesActive {
                        ForEach(connections.indices, id: \.self) { i in
                            let c = connections[i]
                            _ChartedLine(
                                sx: nodes[c.0].0 * W, sy: nodes[c.0].1 * H,
                                ex: nodes[c.1].0 * W, ey: nodes[c.1].1 * H,
                                delay: c.2
                            )
                        }
                    }
                    ForEach(nodes.indices, id: \.self) { i in
                        _AccumStar()
                            .frame(width: 34, height: 34)
                            .position(x: nodes[i].0 * W, y: nodes[i].1 * H)
                            .opacity(chartedStarsVisible ? 1 : 0)
                            .animation(
                                AppAnimation.desireFinishFlair.delay(Double(i) * 0.06).reduceMotionSafe,
                                value: chartedStarsVisible
                            )
                    }
                }
            }
            .frame(maxWidth: 340, maxHeight: 200)
            .padding(.horizontal, AppSpacing.xl)

            Spacer().frame(height: AppSpacing.xl)

            VStack(spacing: AppSpacing.sm) {
                Text("Your map is charted.")
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("All \(store.totalCount). The lines find \(partnerName)'s once they finish theirs.")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppSpacing.xxl)
            .opacity(chartedTitleVisible ? 1 : 0)
            .animation(AppAnimation.desireChartedFadeIn.reduceMotionSafe, value: chartedTitleVisible)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // Sleep beats for the charted ceremony. These mirror the documented durations of
    // the matching AppAnimation tokens (desireFinishFade 0.35, desireFinishFlair 0.80),
    // kept here as named Doubles because an Animation token can't report its own
    // duration to Task.sleep. The hold uses the raw-Double token directly.
    private static let chartedStarSettle: Double = 0.35   // desireFinishFade
    private static let chartedLinesDraw:  Double = 0.80   // desireFinishFlair (line-draw wait)

    private func runChartedSequence() {
        chartedTask?.cancel()
        chartedTask = Task {
            if reduceMotion {
                chartedStarsVisible = true
                chartedTitleVisible = true
                try? await Task.sleep(for: .seconds(AppAnimation.desireChartedHold))
                guard !Task.isCancelled else { return }
                advancePastCharted()
                return
            }
            // Last star flair — the climactic ignite of the rating beat. The flair
            // animation rides on the chartedScreen star's .animation(value:) modifier.
            chartedStarsVisible = true
            try? await Task.sleep(for: .seconds(Self.chartedStarSettle))
            guard !Task.isCancelled else { return }
            // Lines activate (each handles own timing via onAppear)
            chartedLinesActive = true
            // Wait for all lines to finish drawing (~2.6s for last line to complete)
            try? await Task.sleep(for: .seconds(Self.chartedLinesDraw))
            guard !Task.isCancelled else { return }
            // Charted-text fades in once the flair settles (desireChartedFadeIn on the view).
            chartedTitleVisible = true
            // Hold long enough to read both lines (tap-anywhere skips).
            try? await Task.sleep(for: .seconds(AppAnimation.desireChartedHold))
            guard !Task.isCancelled else { return }
            advancePastCharted()
        }
    }

    /// Leaves the charted beat for its branch target. Shared by the timed auto-advance
    /// and the tap-to-skip path, so both land on the same destination.
    private func advancePastCharted() {
        withAnimation(AppAnimation.enter) {
            raterPhase = partnerComplete ? .ready : .mirror
        }
    }

    /// Tap-anywhere during the charted hold cancels the ceremony and proceeds now.
    private func skipChartedSequence() {
        guard raterPhase == .charted else { return }
        chartedTask?.cancel()
        chartedTask = nil
        // Settle the visuals so the skip doesn't snap mid-draw, then advance.
        chartedStarsVisible = true
        chartedTitleVisible = true
        advancePastCharted()
    }

    // MARK: - Mirror screen (S2.4)
    // Matches flow-family screen 4/5: scrollable grouped list on the void.
    // topspark → heading → subtitle → .agroup rows → spacer → waitline

    private var mirrorScreen: some View {
        VStack(spacing: 0) {
            // Fixed close affordance. The mirror is a terminal waiting state inside a
            // .vaylCover (interactive-dismiss disabled), so it must always offer an explicit
            // exit — the readyBar only appears for the second-finisher (.ready), not here.
            HStack {
                Spacer()
                Button { hapticTick += 1; vaylDismiss(confirm: false) } label: {
                    Image(systemName: "xmark")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(AppColors.cardBg.opacity(0.55)))
                        .overlay(Circle().stroke(AppColors.borderSubtle, lineWidth: 1))
                }
                .buttonStyle(_RaterPressStyle())
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.sm)

            ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                if raterPhase == .ready {
                    readyBar
                        .padding(.bottom, AppSpacing.md)
                }

                // Overline label (the desire-map identity is the aperture mark, not a sparkle).
                HStack(spacing: AppSpacing.xs) {
                    Text("just for you")
                        .font(AppFonts.overline)
                        .tracking(1.4)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .padding(.bottom, AppSpacing.sm)

                Text("Everything you said")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.bottom, AppSpacing.xs)

                Text(raterPhase == .ready
                     ? "Still yours, still private. Tap above to see where you two meet."
                     : "Your full read, kept private. Where it meets \(partnerName)'s appears once they finish theirs.")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, AppSpacing.lg)

                // Answer groups
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    ForEach(Array(ratedItemsByGroup.enumerated()), id: \.element.0) { idx, pair in
                        _MirrorGroup(rating: pair.0, items: pair.1, index: idx)
                    }
                }

                if raterPhase != .ready {
                    Text("No rush, and no race. Your overlap with \(partnerName) appears whenever they finish.")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, AppSpacing.xl)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var readyBar: some View {
        // A Button (not a bare onTapGesture) so it carries the press style + haptic,
        // matching every other tappable affordance in the rater.
        Button { hapticTick += 1; vaylDismiss(confirm: false) } label: {
            HStack(spacing: AppSpacing.sm) {
                Text("**\(partnerName) finished.** Your map is ready.")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text("→")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.spectrumMagenta)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(LinearGradient(
                        colors: [AppColors.spectrumMagenta.opacity(0.12), AppColors.spectrumPurple.opacity(0.18)],
                        startPoint: .leading, endPoint: .trailing
                    ))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(AppColors.spectrumPurple.opacity(0.45), lineWidth: 1)
            )
        }
        .buttonStyle(_RaterPressStyle())
    }

    private var ratedItemsByGroup: [(DesireRatingValue, [DesireItem])] {
        let rated = store.items.filter { store.existingRating(for: $0.id) != nil }
        let grouped = Dictionary(grouping: rated) { store.existingRating(for: $0.id)! }
        return DesireRatingValue.allCases.compactMap { rating in
            guard let items = grouped[rating], !items.isEmpty else { return nil }
            return (rating, items)
        }
    }

    // MARK: - Empty / error

    private func emptyState(_ message: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "heart.text.square")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textTertiary)
            Text("Desire Map unavailable")
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text(message)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
            Button { hapticTick += 1; vaylDismiss(confirm: false) } label: {
                Text("Close").font(AppFonts.ctaLabel).foregroundStyle(AppColors.textSecondary)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, AppSpacing.sm)
        }
        .padding(AppSpacing.xl)
    }

    // MARK: - Actions

    private func choose(_ weight: DesireRatingValue, for item: DesireItem) {
        store.rate(itemId: item.id, rating: weight)
        hapticTick += 1

        // Two-phase depth-push, synced with the rising star: the new answer star
        // lifts into the sky on desireStarRise, fired alongside the outgoing question
        // receding (desireDepthExit) while the incoming question emerges from depth
        // (desireDepthEnter). The per-phase depth animations ride on the question
        // transition itself; this withAnimation only triggers the index change.
        withAnimation(AppAnimation.desireStarRise.reduceMotionSafe) { starRiseTick += 1 }
        withAnimation(AppAnimation.desireDepthExit.reduceMotionSafe) { index += 1 }
    }

    private func back() {
        guard index > 0 else { return }
        // Snappier back read — the emerging question arrives on desireDepthEnter.
        withAnimation(AppAnimation.desireDepthEnter.reduceMotionSafe) { index -= 1 }
    }

    private func accentColor(for weight: DesireRatingValue) -> Color {
        switch weight {
        case .excitedAboutIt: return AppColors.spectrumCyan
        case .openToIt:       return AppColors.spectrumPurple
        case .probablyNot:    return AppColors.textTertiary
        case .notForMe:       return AppColors.spectrumMagenta
        }
    }

    private func pillHint(for weight: DesireRatingValue) -> String {
        switch weight {
        case .excitedAboutIt: return "i want this"
        case .openToIt:       return "i'm curious"
        case .probablyNot:    return "not right now"
        case .notForMe:       return "stays private"
        }
    }
}

// MARK: - Press style

private struct _RaterPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AppAnimation.fast, value: configuration.isPressed)
    }
}

// MARK: - Rater pill (S2.2, replaces RatingRow)

private struct _RaterPill: View {
    let label: String
    let hint: String
    let accent: Color
    let isBoundary: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Circle()
                    .fill(accent)
                    .frame(width: 9, height: 9)

                Text(label)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)

                Spacer(minLength: 0)

                if isBoundary {
                    Image(systemName: "lock.fill")
                        .font(AppFonts.meta)
                        .foregroundStyle(AppColors.textTertiary.opacity(0.45))
                } else if !hint.isEmpty {
                    Text(hint)
                        .font(AppFonts.meta)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .frame(height: 54)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .fill(isSelected
                        ? AnyShapeStyle(LinearGradient(
                            colors: [AppColors.spectrumMagenta.opacity(0.14), AppColors.spectrumPurple.opacity(0.18)],
                            startPoint: .leading, endPoint: .trailing
                          ))
                        : AnyShapeStyle(Color.white.opacity(0.03))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .stroke(
                        isSelected ? AppColors.spectrumPurple.opacity(0.80) : Color.white.opacity(0.10),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(color: isSelected ? AppColors.spectrumPurple.opacity(0.28) : .clear, radius: 11)
        }
        .buttonStyle(_RaterPressStyle())
        .animation(AppAnimation.fast, value: isSelected)
    }
}

// MARK: - Star accumulation field (S2.2)

// Vogel phyllotaxis spiral, upper 38% of screen. Stars ONLY appear for excited/open answers.
// Excited stars are larger and brighter than open stars — the sky remembers your enthusiasm.
private struct _StarAccum: View {
    /// Ordered list of positive ratings (excited/open) in answer order.
    let ratings: [DesireRatingValue]
    /// Bumped on each answer commit so the newly added star rises in sync with the
    /// question receding (desireStarRise fired alongside desireDepthExit in choose()).
    var riseTrigger: Int = 0

    private static let positions: [(CGFloat, CGFloat)] = {
        let golden: Double = 2.399963229728653
        return (0..<17).map { i in
            let t   = Double(i + 1) / 20.0
            let r   = sqrt(t) * 0.36
            let ang = Double(i) * golden
            let x   = CGFloat(max(0.09, min(0.91, 0.50 + r * cos(ang))))
            let y   = CGFloat(max(0.04, min(0.40, 0.22 + r * sin(ang) * 0.72)))
            return (x, y)
        }
    }()

    var body: some View {
        GeometryReader { geo in
            let count = min(ratings.count, Self.positions.count)
            ForEach(0..<count, id: \.self) { i in
                let excited = ratings[i] == .excitedAboutIt
                let sz: CGFloat = excited ? 34 : 24
                _AccumStar(isExcited: excited)
                    .frame(width: sz, height: sz)
                    .position(
                        x: geo.size.width  * Self.positions[i].0,
                        y: geo.size.height * Self.positions[i].1
                    )
                    .transition(
                        .scale(scale: 0.1)
                        .combined(with: .opacity)
                        .combined(with: .offset(y: 28))
                    )
            }
        }
        // The accumulating star rises on desireStarRise, driven by the answer-tap
        // trigger so it lifts in sync with the question receding (desireDepthExit).
        .animation(AppAnimation.desireStarRise.reduceMotionSafe, value: riseTrigger)
    }
}

// Star node with cross-hair glow lines, matching the HTML reference.
// Excited: larger glow (34px), brighter core (4.5pt). Open: smaller (24px), dimmer (3.2pt).
private struct _AccumStar: View {
    var isExcited: Bool = false

    private var glowSize: CGFloat { isExcited ? 34 : 24 }
    private var coreSize: CGFloat { isExcited ? 4.5 : 3.2 }
    private var restOpacity: Double { isExcited ? 0.72 : 0.50 }

    var body: some View {
        ZStack {
            // Outer glow blob
            Circle()
                .fill(RadialGradient(
                    colors: [.white.opacity(0.55), AppColors.spectrumMagenta.opacity(0.32), .clear],
                    center: .center, startRadius: 0, endRadius: glowSize / 2
                ))
                .blur(radius: 5)

            // Horizontal cross line
            Rectangle()
                .fill(LinearGradient(
                    colors: [.clear, .white.opacity(0.50), .clear],
                    startPoint: .leading, endPoint: .trailing
                ))
                .frame(width: glowSize, height: 1)

            // Vertical cross line
            Rectangle()
                .fill(LinearGradient(
                    colors: [.clear, .white.opacity(0.50), .clear],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: 1, height: glowSize)

            // Bright core dot
            Circle()
                .fill(.white)
                .frame(width: coreSize, height: coreSize)
                .shadow(color: AppColors.spectrumMagenta.opacity(0.80), radius: 3)
                .shadow(color: AppColors.spectrumPurple.opacity(0.40), radius: 7)
        }
        .frame(width: glowSize, height: glowSize)
        .opacity(restOpacity)
    }
}

// MARK: - Charted line (S2.3 — hesitant sketch animation)

private struct _ChartedLine: View {
    let sx: CGFloat; let sy: CGFloat
    let ex: CGFloat; let ey: CGFloat
    let delay: Double

    @State private var trimTo: CGFloat  = 0
    @State private var lineOp: Double   = 0

    var body: some View {
        Path { p in p.move(to: CGPoint(x: sx, y: sy)); p.addLine(to: CGPoint(x: ex, y: ey)) }
            .trim(from: 0, to: trimTo)
            .stroke(Color.white.opacity(0.35), lineWidth: 1)
            .opacity(lineOp)
            .onAppear {
                Task {
                    try? await Task.sleep(for: .seconds(delay))
                    withAnimation(.easeOut(duration: 0.45)) { trimTo = 0.88; lineOp = 0.22 }
                    try? await Task.sleep(for: .seconds(0.45))
                    withAnimation(.easeInOut(duration: 0.35)) { trimTo = 0.52; lineOp = 0.12 }
                    try? await Task.sleep(for: .seconds(0.45))
                    withAnimation(.easeOut(duration: 0.35)) { trimTo = 0; lineOp = 0 }
                }
            }
    }
}

// MARK: - Mirror group (S2.4 — one per rating group, matches HTML .agroup/.arow pattern)
// Label: small uppercase in accent color. Rows: subtle dark bg + thin border, 3px accent bar.
// Positive rows get a "›" in purple; muted rows (probably not / not for me) get no bg fill.

private struct _MirrorGroup: View {
    let rating: DesireRatingValue
    let items: [DesireItem]
    let index: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var label: String {
        switch rating {
        case .excitedAboutIt: return "Excited about it"
        case .openToIt:       return "Open to it"
        case .probablyNot:    return "Probably not"
        case .notForMe:       return "Not for me"
        }
    }

    private var isMuted: Bool {
        rating == .probablyNot || rating == .notForMe
    }

    private var labelColor: Color {
        switch rating {
        case .excitedAboutIt: return AppColors.spectrumCyan
        case .openToIt:       return AppColors.spectrumPurple
        case .probablyNot:    return AppColors.textTertiary
        case .notForMe:       return AppColors.spectrumMagenta
        }
    }

    private var barColor: Color {
        switch rating {
        case .excitedAboutIt: return AppColors.spectrumCyan
        case .openToIt:       return AppColors.spectrumPurple
        case .probablyNot:    return Color.white.opacity(0.22)
        case .notForMe:       return AppColors.spectrumMagenta
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(label.uppercased())
                .font(AppFonts.overline)
                .tracking(1.4)
                .foregroundStyle(labelColor)

            ForEach(items) { item in
                HStack(spacing: AppSpacing.md) {
                    // Lit accent chip — a soft same-colour glow gives each row its emotion's
                    // light (the star/core glow language in _AccumStar). Muted rows stay flat.
                    RoundedRectangle(cornerRadius: AppRadius.pill)
                        .fill(barColor)
                        .frame(width: 3, height: 18)
                        .shadow(color: isMuted ? .clear : barColor.opacity(0.6), radius: 3)

                    Text(item.name)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(isMuted ? AppColors.textTertiary : AppColors.textPrimary)

                    Spacer(minLength: 0)

                    if !isMuted {
                        Text("›")
                            .font(AppFonts.bodyText)
                            .foregroundStyle(AppColors.spectrumPurple)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                // Canonical glass surface; positive rows carry their emotion in the hairline,
                // muted rows recede (neutral, dimmed). Replaces the near-invisible hand-rolled fill.
                .vaylGlassCard(accent: isMuted ? nil : barColor, radius: AppRadius.md)
                .opacity(isMuted ? 0.5 : 1)
            }
        }
        // Groups arrive with a soft staggered lift (reduce-motion: a clean fade, no travel).
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : (reduceMotion ? 0 : 10))
        .onAppear {
            withAnimation(
                AppAnimation.desireDepthEnter
                    .delay(Double(index) * AppAnimation.desireBeatStaggerStep)
                    .reduceMotionSafe
            ) {
                appeared = true
            }
        }
    }
}

// MARK: - Previews

#Preview("Start screen") {
    let container = ModelContainer.previewContainerWithProfile
    let appState = AppState()
    let store = DesireMapStore(modelContainer: container, appState: appState)
    store.load()
    return DesireMapView(store: store)
        .environment(appState)
        .preferredColorScheme(.dark)
}

#Preview("Rating — mid-map") {
    let container = ModelContainer.previewContainer
    container.mainContext.insert(UserProfile(displayName: "Jordan", nmStage: .curious))
    try? container.mainContext.save()
    let appState = AppState()
    let store = DesireMapStore(modelContainer: container, appState: appState)
    store.load()
    return DesireMapView(store: store, partnerName: "Alex")
        .environment(appState)
        .preferredColorScheme(.dark)
}

#Preview("Mirror — first finisher") {
    let container = ModelContainer.previewContainerWithProfile
    let appState = AppState()
    let store = DesireMapStore(modelContainer: container, appState: appState)
    store.load()
    // Pre-rate all items so the mirror screen shows
    DesireRatingValue.allCases.enumerated().forEach { idx, weight in
        if idx < store.items.count { store.rate(itemId: store.items[idx].id, rating: weight) }
    }
    return DesireMapView(store: store, partnerName: "Alex")
        .environment(appState)
        .preferredColorScheme(.dark)
}

#Preview("Ready bar — partner done") {
    let container = ModelContainer.previewContainerWithProfile
    let appState = AppState()
    let store = DesireMapStore(modelContainer: container, appState: appState)
    store.load()
    DesireRatingValue.allCases.enumerated().forEach { idx, weight in
        if idx < store.items.count { store.rate(itemId: store.items[idx].id, rating: weight) }
    }
    return DesireMapView(store: store, partnerName: "Alex", partnerComplete: true)
        .environment(appState)
        .preferredColorScheme(.dark)
}

```

---

## File: `Vayl/Core/Models/DesireMatch.swift` {#file-vayl-core-models-desirematch-swift}

```swift
//
//  DesireMatch.swift
//  Vayl
//

import Foundation
import SwiftData

// MARK: - DesireMatch
// Represents a positive match between two partners on a Desire Map item.
// Computed by the Supabase Edge Function — never by the client.
// Contains no individual ratings — only confirmed mutual positives.
//
// notForUs combinations never produce a DesireMatch.
// Individual ratings live in DesireMapEntry — local only, never crossed.
//
// isFreeReveal is server-authoritative — the client cannot set this to true.
// If the client could set it, the paywall is trivially bypassed.

@Model
final class DesireMatch {

    // MARK: - Identity

    var id: UUID
    var coupleId: UUID
    var itemId: String          // one of 17 canonical item IDs
    var computedAt: Date

    // MARK: - Match Type

    var matchType: DesireMatchType  // mutual (both yes) / adjacent (one yes, one curious)

    // MARK: - Reveal State

    var isFreeReveal: Bool      // the one free match — set by Edge Function only
    var bridgeCardId: String?   // stub link to a CompanionCard (the desire-map → deck/conversation bridge)

    // MARK: - Init

    init(
        coupleId: UUID,
        itemId: String,
        matchType: DesireMatchType
    ) {
        self.id = UUID()
        self.coupleId = coupleId
        self.itemId = itemId
        self.matchType = matchType
        self.computedAt = Date()
        self.isFreeReveal = false   // always set by Edge Function — never client
        self.bridgeCardId = nil
    }

    // MARK: - Preview Helpers

    static let example = DesireMatch(
        coupleId: UUID(),
        itemId: "desire-001",
        matchType: .mutual
    )

    static let freeRevealExample: DesireMatch = {
        let m = DesireMatch(
            coupleId: UUID(),
            itemId: "desire-002",
            matchType: .adjacent
        )
        m.isFreeReveal = true
        return m
    }()
}

```

---

## File: `Vayl/Core/Models/DesireItem.swift` {#file-vayl-core-models-desireitem-swift}

```swift
//
//  DesireItem.swift
//  Vayl
//
//  A single Desire Map prompt loaded from desire_items.json.
//  Pure data shape — no logic, no dependencies (Model layer).
//
//  COHORT-ADAPTIVE: `tracks` says which cohort(s) see this item; `answers` holds the
//  four answer strings PER track, in fixed weight order:
//      [excitedAboutIt, openToIt, probablyNot, notForMe]   (DesireRatingValue.allCases order)
//  Only the WEIGHT (index) is ever stored/synced — the displayed string is cohort copy.
//  Item identity (id/name/description) is cohort-neutral so a mixed couple rates the same item.
//

import Foundation

struct DesireItem: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let category: String        // structures / emotional / sexual / communication / health / logistics
    let sensitivity: Int        // 1–3, drives primer framing later
    let sortOrder: Int
    let tracks: [String]        // "curious" / "established"
    let answers: [String: [String]]   // track -> 4 answers, in DesireRatingValue.allCases order

    /// The four answer strings for a given track, weight-ordered. nil if this item
    /// isn't part of that track.
    func answers(for track: String) -> [String]? {
        answers[track]
    }

    /// Whether this item is shown to the given cohort track.
    func appears(in track: String) -> Bool {
        tracks.contains(track)
    }
}

```

---

## File: `Vayl/Core/Models/DesireRating.swift` {#file-vayl-core-models-desirerating-swift}

```swift
//
//  DesireMapEntry.swift
//  Vayl
//

import Foundation
import SwiftData

// MARK: - DesireMapEntry
// One person's private rating for a single Desire Map item.
//
// PRIVACY: matches the ratified "sync-all, obscure at the match layer" posture
// (see DesireRatingValue in AppDesireEnums). userId is PRIVATE and never shown to
// the partner. All four weights sync to desire_ratings, INCLUDING notForMe. The
// boundary is enforced partner-vs-partner, not by withholding at upload:
//   1. Supabase RLS: a partner can never query your desire_ratings, ever.
//   2. Edge function: notForMe is excluded from desire_matches, so it never
//      surfaces in the shared reveal.
// The old "notForMe never leaves the device" model is retired.

@Model
final class DesireMapEntry {

    // MARK: - Identity

    var id: UUID
    var userId: UUID            // PRIVATE — never crosses to partner
    var itemId: String          // one of 17 canonical item IDs
    var rating: DesireRatingValue
    var completedAt: Date

    // MARK: - Init

    init(userId: UUID, itemId: String, rating: DesireRatingValue) {
        self.id = UUID()
        self.userId = userId
        self.itemId = itemId
        self.rating = rating
        self.completedAt = Date()
    }

}

// MARK: - DesireMapStatus
// Tracks completion state per couple — NOT individual ratings.
// Both partners can read the partnerXComplete booleans.
// Neither partner can ever read the other's DesireMapEntry records.
// waitingStateSince is stored explicitly — never derived from completion dates.

@Model
final class DesireMapStatus {

    // MARK: - Identity

    var id: UUID
    var coupleId: UUID

    // MARK: - Completion State

    var partnerAComplete: Bool
    var partnerBComplete: Bool
    var partnerACompletedAt: Date?
    var partnerBCompletedAt: Date?

    // MARK: - Waiting State
    // Reveal/unlock state is NOT mirrored here: Available = bothComplete (above),
    // Unlocked = couples.access_tier (EntitlementStore), Seen = desire_reveal_progress.

    var waitingStateSince: Date?    // set when first partner completes — powers 7-day timer

    // MARK: - Computed

    var bothComplete: Bool {
        partnerAComplete && partnerBComplete
    }

    var waitingForPartner: Bool {
        partnerAComplete != partnerBComplete
    }

    // MARK: - Init

    init(coupleId: UUID) {
        self.id = UUID()
        self.coupleId = coupleId
        self.partnerAComplete = false
        self.partnerBComplete = false
        self.partnerACompletedAt = nil
        self.partnerBCompletedAt = nil
        self.waitingStateSince = nil
    }

    // MARK: - Preview Helpers

    static let example = DesireMapStatus(coupleId: UUID())

    static let waitingExample: DesireMapStatus = {
        let s = DesireMapStatus(coupleId: UUID())
        s.partnerAComplete = true
        s.partnerACompletedAt = Date()
        s.waitingStateSince = Date()
        return s
    }()

    static let bothCompleteExample: DesireMapStatus = {
        let s = DesireMapStatus(coupleId: UUID())
        s.partnerAComplete = true
        s.partnerBComplete = true
        s.partnerACompletedAt = Date()
        s.partnerBCompletedAt = Date()
        s.waitingStateSince = Date()
        return s
    }()
}

```

---

## File: `Vayl/Core/Models/Enums/AppDesireEnums.swift` {#file-vayl-core-models-enums-appdesireenums-swift}

```swift
//
//  AppDesireEnums.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/22/26.
//

import Foundation
import SwiftUI


/// State of the Desire Map indicator on the home dashboard.
/// Computed by HomeEventEngine. Never stored directly.
enum DesireMapState {
    case hidden                                             // partner not yet linked
    case gated                                              // linked but neither has started
    case yourTurn                                           // this user has not completed
    case youDone(partnerName: String)                       // this user done, partner not yet
    case waiting                                            // generic waiting state
    case bothReady                                          // both complete, reveal not triggered
    case freeRevealSeen(matchCount: Int)                    // free reveal viewed
    case matchReady                                         // paywall cleared, ready to show
    case redoInProgress(partnerName: String, matchCount: Int) // redo underway
    case revealed                                           // full reveal complete
    case fullyUnlocked                                      // all access granted
}

extension DesireMapState: Equatable {
    static func == (lhs: DesireMapState, rhs: DesireMapState) -> Bool {
        switch (lhs, rhs) {
        case (.hidden, .hidden),
             (.gated, .gated),
             (.yourTurn, .yourTurn),
             (.waiting, .waiting),
             (.bothReady, .bothReady),
             (.matchReady, .matchReady),
             (.revealed, .revealed),
             (.fullyUnlocked, .fullyUnlocked):
            return true
        case (.youDone(let a), .youDone(let b)):
            return a == b
        case (.freeRevealSeen(let a), .freeRevealSeen(let b)):
            return a == b
        case (.redoInProgress(let a, let b), .redoInProgress(let c, let d)):
            return a == c && b == d
        default:
            return false
        }
    }
}



// ─────────────────────────────────────────────────────────────
// MARK: - Desire Map
// ─────────────────────────────────────────────────────────────

/// How a partner rates a Desire Map item — a fixed 4-point weight (the displayed
/// answer copy is cohort-adaptive; only this stored weight crosses to matching).
/// All four weights sync to `desire_ratings`. `notForMe` is the boundary: it is
/// protected by own-only RLS (a partner cannot read your ratings) and excluded from
/// `desire_matches` by the edge function. It is obscured at the match layer, not
/// withheld at upload — the privacy boundary is partner-vs-partner, enforced by RLS.
enum DesireRatingValue: String, CaseIterable, Codable {
    case excitedAboutIt
    case openToIt
    case probablyNot
    case notForMe

    var displayName: String {
        switch self {
        case .excitedAboutIt: return "Excited About It"
        case .openToIt:       return "Open To It"
        case .probablyNot:    return "Probably Not"
        case .notForMe:       return "Not For Me"
        }
    }
}

/// The type of match computed by the Edge Function.
/// Only positive matches are ever stored.
/// notForUs combinations are never written to desire_matches.
enum DesireMatchType: String, CaseIterable, Codable {
    case mutual     // both rated yes
    case adjacent   // one yes, one curious

    var displayName: String {
        switch self {
        case .mutual:   return "Mutual"
        case .adjacent: return "Worth Exploring"
        }
    }
}


```

---

## File: `Vayl/Core/Services/AppState.swift` {#file-vayl-core-services-appstate-swift}

```swift
//
//  AppState.swift
//  Vayl
//

import Foundation
import OSLog
import SwiftData

private let logger = Logger(
    subsystem: "com.vayl.app",
    category: "AppState"
)

/// Central app-level state. Injected as @Environment at the root.
/// Owns onboarding gate, link state, and tab routing.
/// Does not own feature-level state — that lives in feature Stores.
@MainActor
@Observable
final class AppState {

    // MARK: - Onboarding

    /// The single in-memory read surface for onboarding completion. Read-only from
    /// outside — mutated only by the onboarding writers below, so it can never desync
    /// from the durable truth (UserProfile). Its didSet is the ONLY UserDefaults
    /// cache-write site.
    private(set) var isOnboardingComplete: Bool {
        didSet {
            UserDefaults.standard.set(isOnboardingComplete, forKey: UserDefaultsKey.hasCompletedOnboarding)
            logger.info("Onboarding complete: \(self.isOnboardingComplete)")
        }
    }

    // MARK: - Identity

    var displayName: String {
        didSet {
            persist(displayName, forKey: .displayName)
        }
    }

    // MARK: - Routing

    /// Whether this user has linked a partner.
    /// Drives content visibility and home state rendering.
    var linkState: LinkState {
        didSet {
            persist(linkState.rawValue, forKey: .linkState)
            logger.info("LinkState changed to: \(self.linkState.rawValue)")
        }
    }

    /// The mode the user selected in onboarding — together, solo, or browsing.
    /// Mutable — user can switch in Settings (browsing users cannot switch without re-onboarding).
    var appMode: AppMode {
        didSet {
            persist(appMode.rawValue, forKey: .appMode)
            logger.info("AppMode changed to: \(self.appMode.rawValue)")
        }
    }

    /// The couple ID assigned after partner linking.
    /// Mirrors UserProfile.coupleId — UserProfile is the source of truth.
    /// Persisted to UserDefaults for fast in-memory routing on relaunch.
    var coupleId: UUID? {
        didSet {
            if let id = coupleId {
                persist(id.uuidString, forKey: .coupleId)
                logger.info("CoupleId set: \(id)")
            } else {
                UserDefaults.standard.removeObject(forKey: PersistenceKey.coupleId.rawValue)
                logger.info("CoupleId cleared")
            }
        }
    }

    // MARK: - Navigation

    var selectedTab: AppTab = .home
    /// Transient flag: set true to signal MapView to auto-open the Vault.
    /// MapView resets it to false immediately after presenting.
    var vaultOpenPending: Bool = false
    var loadState: AppLoadState = .idle

    // MARK: - Init

    init() {
        // isOnboardingComplete
        self.isOnboardingComplete = UserDefaults.standard.bool(
            forKey: UserDefaultsKey.hasCompletedOnboarding
        )

        // displayName
        let savedName = UserDefaults.standard.string(
            forKey: PersistenceKey.displayName.rawValue
        )
        #if DEBUG
        if savedName == nil || savedName!.isEmpty {
            UserDefaults.standard.set("Jordan", forKey: PersistenceKey.displayName.rawValue)
        }
        #endif
        self.displayName = UserDefaults.standard.string(
            forKey: PersistenceKey.displayName.rawValue
        ) ?? ""

        // linkState
        let savedLinkRaw = UserDefaults.standard.string(
            forKey: PersistenceKey.linkState.rawValue
        )
        if let raw = savedLinkRaw, let resolved = LinkState(rawValue: raw) {
            self.linkState = resolved
        } else {
            self.linkState = .unlinked
        }

        // appMode
        let savedAppModeRaw = UserDefaults.standard.string(
            forKey: PersistenceKey.appMode.rawValue
        )
        if let raw = savedAppModeRaw, let resolved = AppMode(rawValue: raw) {
            self.appMode = resolved
        } else {
            self.appMode = .together
            if savedAppModeRaw != nil {
                logger.warning("Unrecognised appMode in UserDefaults — defaulting to together")
            }
        }

        // coupleId
        if let savedCoupleId = UserDefaults.standard.string(
            forKey: PersistenceKey.coupleId.rawValue
        ), let uuid = UUID(uuidString: savedCoupleId) {
            self.coupleId = uuid
        } else {
            self.coupleId = nil
        }
    }

    // MARK: - Onboarding Writers
    //
    // The ONLY writers of onboarding completion. UserProfile is the durable truth;
    // isOnboardingComplete is the in-memory surface; the UserDefaults cache is written
    // by the surface's didSet. Setting all three here — and only here — is what makes
    // completion impossible to desync.

    /// Marks onboarding complete across truth (UserProfile) + surface + cache.
    /// The single completion writer. Callers pass the profile + the context it was
    /// fetched on so truth and surface commit together.
    func markOnboardingComplete(_ profile: UserProfile, context: ModelContext) {
        profile.hasCompletedOnboarding = true
        profile.onboardingCompletedAt  = Date()
        try? context.save()
        isOnboardingComplete = true   // didSet writes the UserDefaults cache
    }

    /// Clears onboarding completion across truth + surface + cache. The single reset.
    /// Pass nil profile/context to clear only the surface + cache (e.g. when no
    /// profile exists yet) — though a launch reconcile would re-derive from truth.
    func resetOnboarding(_ profile: UserProfile?, context: ModelContext?) {
        profile?.hasCompletedOnboarding = false
        profile?.onboardingCompletedAt  = nil
        if let context { try? context.save() }
        isOnboardingComplete = false
    }

    /// Reconciles the in-memory surface (and thus the cache) against the durable
    /// truth at launch — UserProfile wins. `init` reads the UserDefaults cache for
    /// instant synchronous routing; this corrects any drift (e.g. from remote sync).
    /// Call once at startup.
    func hydrateOnboardingState(from container: ModelContainer) {
        let context = ModelContext(container)
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        if isOnboardingComplete != profile.hasCompletedOnboarding {
            isOnboardingComplete = profile.hasCompletedOnboarding
        }
    }

    // MARK: - Unlink (Seg 9 scaffold — UNVERIFIED)
    //
    // Local breakup/dissolve: drops the partner link so routing returns to an
    // unlinked state. ARCHIVAL, not deletion — we do NOT delete the Couple or its
    // history (Couple's deleteRule is .nullify). The remote side (marking the
    // couples row dissolved, tearing down any open curated_session, revoking the
    // partner's device tokens) is NOT wired — it needs the backend work + a
    // two-device test. Per CLAUDE.md humility, a breakup needs no in-app fanfare;
    // this is quiet data hygiene.

    /// Clears the local partner link. Leaves history and the remote Couple row intact.
    func unlink() {
        coupleId = nil
        linkState = .unlinked
        logger.info("Local unlink — partner link cleared (history retained)")
    }

    // MARK: - Private Helpers

    private func persist(_ value: String, forKey key: PersistenceKey) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    // MARK: - Persistence Keys

    // Note: the onboarding-completion flag is keyed by the shared
    // `UserDefaultsKey.hasCompletedOnboarding` (see isOnboardingComplete), not this enum.
    private enum PersistenceKey: String {
        case displayName         = "displayName"
        case linkState           = "linkState"
        case appMode             = "appMode"
        case coupleId            = "coupleId"
    }
}

// MARK: - App Load State

enum AppLoadState {
    case idle
    case loading
    case ready
    case error(String)
}

```

---

## File: `Vayl/Core/Services/DesireSyncService.swift` {#file-vayl-core-services-desiresyncservice-swift}

```swift
//
//  SupabaseDesireRating.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/10/26.
//


//
//  DesireSyncService.swift
//  Open Lightly
//
//  Created in Batch 10 — Desire Ratings Sync
//
//  PURPOSE:
//  Pushes desire map ratings from SwiftData to Supabase after the user
//  completes the desire map during onboarding (or updates ratings later).
//
//  TABLE: `desire_ratings`
//  Each row = one user's private rating for one desire item.
//
//  PRIVACY NOTE:
//  Desire ratings are PRIVATE — they are never shown to the partner directly.
//  They're only used server-side to compute DesireMatch results (overlapping
//  interests between two paired users). The raw ratings stay private.
//
//  SAME PATTERN:
//  1. SwiftData saves first (instant, offline-capable)
//  2. This service pushes to Supabase (async, might fail)
//  3. If push fails → SyncManager flags for retry
//

import Foundation
import Supabase
import Combine

/// Value snapshot of a `DesireMapEntry`, taken on the main actor BEFORE any await so we
/// never touch a SwiftData `@Model` across a suspension point. ALL weights sync (incl.
/// `notForMe`) — boundaries are obscured at the reveal layer (edge fn), not withheld here.
struct PendingDesireRating: Sendable {
    let id: UUID
    let itemId: String
    let rating: DesireRatingValue
    let completedAt: Date

    init(_ entry: DesireMapEntry) {
        self.id = entry.id
        self.itemId = entry.itemId
        self.rating = entry.rating
        self.completedAt = entry.completedAt
    }
}

// MARK: - Supabase DTO

/// Maps one desire rating to the `desire_ratings` table in Supabase.
/// Plain Codable struct — NOT a SwiftData model.
struct SupabaseDesireRating: Codable {
    let id: UUID
    let userId: UUID
    let desireItemId: String
    let rating: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case desireItemId = "desire_item_id"
        case rating
        case createdAt = "created_at"
    }
}

// MARK: - Service

@MainActor
class DesireSyncService: ObservableObject {

    /// Shared singleton — access with DesireSyncService.shared
    static let shared = DesireSyncService()

    /// Reference to the Supabase client.
    private var supabase: SupabaseClient {
        SupabaseManager.shared.client
    }

    /// ISO 8601 formatter for converting Dates to Postgres-friendly strings.
    private let isoFormatter = ISO8601DateFormatter()

    private let profileService = ProfileService()

    // MARK: - Sync All Ratings

    /// Pushes all desire ratings for a user to Supabase in one batch.
    ///
    /// WHEN TO CALL:
    /// After the user completes the desire map during onboarding
    /// and all DesireRating objects have been saved to SwiftData.
    ///
    /// WHAT IT DOES:
    /// 1. Converts each local DesireRating into a SupabaseDesireRating
    /// 2. Sends them all to Supabase in one batch INSERT
    ///
    /// WHY BATCH INSERT?
    /// The desire map might have 30–50+ items. One HTTP request per rating
    /// would be painfully slow. Batch insert sends them all at once.
    ///
    /// - Parameters:
    ///   - ratings: Array of local SwiftData DesireRating objects
    ///   - authId: The authenticated user's UUID
    func syncRatings(_ ratings: [PendingDesireRating]) async throws {
        guard !ratings.isEmpty else { return }

        // desire_ratings.user_id is a FK to user_profiles.id — use the PROFILE id, not the auth uid.
        let authId = try await supabase.auth.session.user.id
        let profileId = try await profileService.ensureProfileExists(authId: authId)

        let rows = ratings.map { r in
            SupabaseDesireRating(
                id: r.id,
                userId: profileId,
                desireItemId: r.itemId,
                rating: r.rating.rawValue,
                createdAt: isoFormatter.string(from: r.completedAt)
            )
        }

        // Upsert on (user_id, desire_item_id) so re-rating updates in place.
        try await supabase
            .from("desire_ratings")
            .upsert(rows, onConflict: "user_id,desire_item_id")
            .execute()

        #if DEBUG
        print("✅ \(rows.count) desire ratings upserted to Supabase")
        #endif
    }

    // MARK: - Compute Matches (D3)

    /// Invokes the `compute-desire-matches` edge function: marks the caller's side complete and,
    /// if BOTH partners are done, computes `desire_matches` server-side. `isFreeReveal` is set by
    /// the function only (never the client). Call after ratings have synced.
    @discardableResult
    func computeMatches() async throws -> ComputeMatchesResponse {
        let response: ComputeMatchesResponse = try await supabase.functions.invoke(
            "compute-desire-matches",
            options: FunctionInvokeOptions()
        )
        return response
    }

    // MARK: - Read back (D-read)

    /// Reads the couple's computed matches. Selects ONLY client-safe columns — never
    /// `partner_a/b_value` (the partner's raw answer is never shown). RLS scopes to the couple.
    func fetchMatches(coupleId: UUID) async throws -> [DesireMatchRow] {
        try await supabase
            .from("desire_matches")
            .select("id, desire_item_id, alignment_level, is_free_reveal, bridge_card_id")
            .eq("couple_id", value: coupleId.uuidString)
            .execute()
            .value
    }

    /// Reads the couple's completion / reveal status, or nil if neither partner has finished.
    func fetchStatus(coupleId: UUID) async throws -> DesireMapStatusRow? {
        let rows: [DesireMapStatusRow] = try await supabase
            .from("desire_map_status")
            .select("track, partner_a_complete, partner_b_complete")
            .eq("couple_id", value: coupleId.uuidString)
            .execute()
            .value
        return rows.first
    }

    // MARK: - Reveal progress (per-user "Seen"; own-user RLS)

    /// This user's reveal viewing state for the couple, or nil if they have not opened it yet.
    func fetchRevealProgress(coupleId: UUID) async throws -> RevealProgressRow? {
        let authId = try await supabase.auth.session.user.id
        let profileId = try await profileService.ensureProfileExists(authId: authId)
        let rows: [RevealProgressRow] = try await supabase
            .from("desire_reveal_progress")
            .select("free_reveal_seen_at, full_reveal_seen_at")
            .eq("user_id", value: profileId.uuidString)
            .eq("couple_id", value: coupleId.uuidString)
            .execute()
            .value
        return rows.first
    }

    /// Stamp that this user watched the reveal. `full == false` stamps the free reveal;
    /// `full == true` stamps the post-unlock full reveal. Upsert on (user_id, couple_id);
    /// only the named column is written, so stamping one never clears the other.
    func markRevealSeen(coupleId: UUID, full: Bool) async throws {
        let authId = try await supabase.auth.session.user.id
        let profileId = try await profileService.ensureProfileExists(authId: authId)
        let now = isoFormatter.string(from: Date())
        var row: [String: String] = [
            "user_id": profileId.uuidString,
            "couple_id": coupleId.uuidString,
            "updated_at": now,
        ]
        row[full ? "full_reveal_seen_at" : "free_reveal_seen_at"] = now
        try await supabase
            .from("desire_reveal_progress")
            .upsert(row, onConflict: "user_id,couple_id")
            .execute()
    }
}

/// One computed match, client-safe — NO partner raw values (the edge fn stores them null).
struct DesireMatchRow: Decodable, Identifiable, Sendable {
    let id: UUID
    let desireItemId: String
    let alignmentLevel: String     // "mutual" | "adjacent"
    let isFreeReveal: Bool
    let bridgeCardId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case desireItemId = "desire_item_id"
        case alignmentLevel = "alignment_level"
        case isFreeReveal = "is_free_reveal"
        case bridgeCardId = "bridge_card_id"
    }

    var matchType: DesireMatchType? { DesireMatchType(rawValue: alignmentLevel) }
}

/// The couple's completion + reveal state, client-safe.
struct DesireMapStatusRow: Decodable, Sendable {
    let track: String?
    let partnerAComplete: Bool
    let partnerBComplete: Bool

    enum CodingKeys: String, CodingKey {
        case track
        case partnerAComplete = "partner_a_complete"
        case partnerBComplete = "partner_b_complete"
    }

    var bothComplete: Bool { partnerAComplete && partnerBComplete }
}

/// Result of the `compute-desire-matches` edge function.
struct ComputeMatchesResponse: Decodable {
    let status: String       // "waiting" | "computed" | "unpaired"
    let track: String?
    let matchCount: Int?
}

/// This user's reveal viewing state, client-safe (own row only).
struct RevealProgressRow: Decodable, Sendable {
    let freeRevealSeenAt: String?
    let fullRevealSeenAt: String?

    enum CodingKeys: String, CodingKey {
        case freeRevealSeenAt = "free_reveal_seen_at"
        case fullRevealSeenAt = "full_reveal_seen_at"
    }

    var hasSeenFree: Bool { freeRevealSeenAt != nil }
    var hasSeenFull: Bool { fullRevealSeenAt != nil }
}

```

---

## File: `Vayl/Core/Services/EntitlementService.swift` {#file-vayl-core-services-entitlementservice-swift}

```swift
//
//  EntitlementService.swift
//  Vayl
//
//  Service layer (network I/O) for couple-level entitlements — Monetization M1.
//  Injected into EntitlementStore; no Store/View references, no state ownership.
//
//  Read path:  couples.access_tier (the denormalized resolved tier; RLS scopes it to the
//              couple's members). The raw `entitlements` ledger is SERVICE-ROLE-ONLY and is
//              never read by the client — who-paid is support-only.
//  Write path: the `grant-entitlement` edge function. The server validates the purchase
//              (StoreKit 2 JWS, wired in M2) and writes the couple entitlement via the service
//              role, returning the resolved tier. Invoked from the StoreKit flow in M2.
//

import Foundation
import Supabase

final class EntitlementService {

    private let supabase: SupabaseClient

    init(supabase: SupabaseClient = SupabaseManager.shared.client) {
        self.supabase = supabase
    }

    // MARK: - Read tier

    /// Reads the couple's resolved tier + unlock state. RLS scopes the row to couple members,
    /// so a non-member (or unpaired caller) reads nothing → returns nil.
    func fetchTier(coupleId: UUID) async throws -> CoupleTierRow? {
        let rows: [CoupleTierRow] = try await supabase
            .from("couples")
            .select("access_tier, core_unlocked_at, is_founding_member")
            .eq("id", value: coupleId.uuidString)
            .execute()
            .value
        return rows.first
    }

    // MARK: - Grant (server-authoritative)

    /// Invokes `grant-entitlement`. The server validates the StoreKit 2 signed transaction
    /// (M2) and writes the couple entitlement via the service role — one purchase unlocks BOTH
    /// partners. Returns the resolved tier. Wired into purchase + restore in M2.
    @discardableResult
    func grantCore(
        productId: String = "com.vayl.core.lifetime",
        signedTransaction: String
    ) async throws -> GrantResponse {
        try await supabase.functions.invoke(
            "grant-entitlement",
            options: FunctionInvokeOptions(
                body: ["productId": productId, "signedTransaction": signedTransaction]
            )
        )
    }
}

// MARK: - DTOs

/// The couple's client-safe resolved tier. Mirrors the non-sensitive columns on
/// `public.couples` — deliberately NEVER includes who paid (support-only, service-role-only).
struct CoupleTierRow: Decodable, Sendable {
    let accessTier: String
    let coreUnlockedAt: String?
    let isFoundingMember: Bool

    enum CodingKeys: String, CodingKey {
        case accessTier = "access_tier"
        case coreUnlockedAt = "core_unlocked_at"
        case isFoundingMember = "is_founding_member"
    }

    var tier: AccessTier { AccessTier(rawValue: accessTier) ?? .free }
}

/// Result of `grant-entitlement` — tier only, never the receipt/buyer details.
struct GrantResponse: Decodable, Sendable {
    let tier: String
    let coupleId: UUID

    var resolvedTier: AccessTier { AccessTier(rawValue: tier) ?? .free }
}

```

---

## File: `Vayl/Features/Monetization/Store/EntitlementStore.swift` {#file-vayl-features-monetization-store-entitlementstore-swift}

```swift
//
//  EntitlementStore.swift
//  Vayl
//
//  Central read surface for the couple's access tier — Monetization M1 + M2.
//  The single `isCore`/`tier` that every gate reads (M3+). Couple-level: one purchase unlocks
//  BOTH partners. `isCore` resolves from TWO sources OR'd (guide Part D):
//    • the couple's SERVER tier (couples.access_tier) — covers the partner (no local txn), and
//    • local StoreKit ownership — covers the buyer fast/offline, before the server grant propagates.
//
//  4-Layer arch: View → Store → Service. Views never call StoreKit — they read `isCore`/`tier`
//  and call `purchase()`/`restore()`. The Store decides; StoreKitService + EntitlementService do I/O.
//

import Foundation
import SwiftData
import StoreKit

@Observable
@MainActor
final class EntitlementStore {

    // MARK: - Published state

    /// The couple's resolved SERVER tier. `.free` until a paired couple resolves `core`.
    private(set) var tier: AccessTier = .free

    /// Founding-member perk flag (first-year-free Pro when Act 2 lands). Not sensitive.
    private(set) var isFoundingMember: Bool = false

    /// This device's Apple ID owns Core locally (StoreKit). The buyer's fast/offline fallback;
    /// the partner has no local transaction and unlocks from the server `tier` instead.
    private(set) var localOwnsCore: Bool = false

    /// Core product metadata for the paywall price label (nil until loaded / if ASC not set up yet).
    private(set) var coreProduct: Product?

    /// In-flight purchase/restore flag for the paywall UI.
    private(set) var isPurchasing: Bool = false

    /// Set when a server refresh failed; the last known tier still stands (offline-safe).
    private(set) var loadError: String?

    /// The single gate every paywalled surface reads (M3+). Server tier OR local StoreKit ownership.
    var isCore: Bool { tier != .free || localOwnsCore }

    /// Display price for the paywall CTA (e.g. "$24.99"), if the product loaded.
    var corePriceText: String? { coreProduct?.displayPrice }

    // MARK: - Dependencies

    private let modelContainer: ModelContainer
    private let appState: AppState
    private let service: EntitlementService
    private let storeKit: StoreKitService
    private var updatesTask: Task<Void, Never>?

    init(
        modelContainer: ModelContainer,
        appState: AppState,
        service: EntitlementService? = nil,
        storeKit: StoreKitService? = nil
    ) {
        self.modelContainer = modelContainer
        self.appState = appState
        // Construct in the @MainActor init body (not as a default arg, which is nonisolated).
        self.service = service ?? EntitlementService()
        self.storeKit = storeKit ?? StoreKitService()
        // Instant offline read from the local mirror; bootstrap()/refresh() corrects from server + StoreKit.
        hydrateFromLocal()
    }

    // MARK: - Bootstrap (app launch)

    /// Load the product, resolve tier from all sources, and start the StoreKit updates listener.
    /// Call once after the session is ready (VaylApp). Supersedes a bare refresh().
    func bootstrap() async {
        coreProduct = try? await storeKit.loadCoreProduct()
        await refresh()
        if updatesTask == nil {
            updatesTask = storeKit.observeTransactionUpdates { [weak self] _, jws, revoked in
                guard let self else { return }
                await self.handleTransactionUpdate(jws: jws, revoked: revoked)
            }
        }
    }

    // MARK: - Resolve tier (server OR local)

    /// Re-resolve `isCore` from the local StoreKit entitlement + the couple's server tier.
    /// Best-effort: on server failure the last known tier stands (offline / transient is non-fatal).
    func refresh() async {
        localOwnsCore = await storeKit.ownsCore()
        guard let coupleId = appState.coupleId else {
            apply(tier: .free, founding: false, coupleId: nil)
            return
        }
        do {
            guard let row = try await service.fetchTier(coupleId: coupleId) else { return }
            apply(tier: row.tier, founding: row.isFoundingMember, coupleId: coupleId)
            loadError = nil
        } catch {
            loadError = error.localizedDescription
            // Keep the last tier — do not downgrade a paid couple on a network blip.
        }
    }

    // MARK: - Purchase / restore (M2)

    /// Run the Core purchase. On a verified transaction → push the signed JWS to the server
    /// (grant-entitlement writes the COUPLE entitlement so the partner unlocks too) → re-resolve.
    /// Returns true once the couple is Core. Safe from the paywall / D4 unlock CTA.
    @discardableResult
    func purchase() async -> Bool {
        guard !isPurchasing else { return isCore }
        if coreProduct == nil { coreProduct = try? await storeKit.loadCoreProduct() }
        guard let product = coreProduct else {
            loadError = "Core isn't available right now."
            return false
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            switch try await storeKit.purchase(product) {
            case .success(_, let jws):
                localOwnsCore = true                                   // buyer unlocks immediately
                _ = try? await service.grantCore(signedTransaction: jws)   // server → partner unlocks too
                await refresh()
                return isCore
            case .pending, .userCancelled:
                return false
            case .unverified:
                loadError = "That purchase couldn't be verified."
                return false
            }
        } catch {
            loadError = error.localizedDescription
            return false
        }
    }

    /// Explicit "Restore Purchases" (Apple requires a restore path for non-consumables). Re-syncs
    /// from the App Store; if Core is owned, re-grants the couple server-side and re-resolves.
    @discardableResult
    func restore() async -> Bool {
        guard !isPurchasing else { return isCore }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            if let (_, jws) = try await storeKit.restore() {
                localOwnsCore = true
                _ = try? await service.grantCore(signedTransaction: jws)
            }
            await refresh()
        } catch {
            loadError = error.localizedDescription
        }
        return isCore
    }

    // MARK: - Background updates

    /// Handle a transaction arriving outside an explicit purchase (Ask-to-Buy, another device,
    /// refund/revocation). Refund → drop the local fallback + re-resolve (couple-level downgrade
    /// is server-driven via the refund webhook — a documented fast-follow).
    private func handleTransactionUpdate(jws: String, revoked: Bool) async {
        if revoked {
            localOwnsCore = false
            await refresh()
        } else {
            localOwnsCore = true
            _ = try? await service.grantCore(signedTransaction: jws)
            await refresh()
        }
    }

    // MARK: - Local mirror

    /// Seed the in-memory tier from the local Couple at init (before the network resolves).
    private func hydrateFromLocal() {
        guard let coupleId = appState.coupleId,
              let couple = localCouple(coupleId) else { return }
        tier = couple.entitlementTier
        isFoundingMember = couple.isFoundingMember
    }

    /// Update the in-memory surface and mirror into the local Couple (if one exists) so offline
    /// reads and `Couple.canRevealDesireMap` stay correct. Never creates/owns Couple rows.
    private func apply(tier newTier: AccessTier, founding: Bool, coupleId: UUID?) {
        tier = newTier
        isFoundingMember = founding
        guard let coupleId, let couple = localCouple(coupleId) else { return }
        couple.entitlementTier = newTier
        couple.isFoundingMember = founding
        if newTier != .free && couple.coreUnlockedAt == nil {
            couple.coreUnlockedAt = Date()
        }
        try? couple.modelContext?.save()
    }

    private func localCouple(_ coupleId: UUID) -> Couple? {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
        return try? context.fetch(descriptor).first
    }
}

```

---

## File: `Vayl/Features/Monetization/Views/PaywallSheet.swift` {#file-vayl-features-monetization-views-paywallsheet-swift}

```swift
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
    // behind the hook. NOT design tokens; same convention as VaylSheetChrome's purpleTint/darken.
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
    // else the scrollable fallback. vaylSheetChrome forces maxHeight:.infinity (shared, off-limits),
    // so the chrome wraps BOTH candidates: with .fixedSize it hugs content; inside the ScrollView
    // it fills the screen and the content scrolls (the CTA + footer stay reachable).
    @ViewBuilder private var sizedSheet: some View {
        ViewThatFits(in: .vertical) {
            sheetStack
                .vaylSheetChrome()
                // .fixedSize(vertical) overrides the chrome's maxHeight:.infinity so the sheet hugs
                // content; horizontal:false keeps full-bleed width (no GeometryReader, no width bug).
                .fixedSize(horizontal: false, vertical: true)
            ScrollView(showsIndicators: false) { sheetStack }
                .vaylSheetChrome()
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
    // ONLY here, never in the shared vaylSheetChrome (FounderLetter/CredentialEditor reuse that).
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

```

---

## File: `Vayl/Core/Models/EntitlementRecord.swift` {#file-vayl-core-models-entitlementrecord-swift}

```swift
//
//  EntitlementRecord.swift
//  Vayl
//
//  Created by Bryan Jorden on 4/27/26.
//


//
//  EntitlementRecord.swift
//  Vayl
//

import Foundation
import SwiftData

// MARK: - EntitlementRecord
// Records a purchase that unlocks Core tier for a couple.
// Lives on Couple — one purchase covers both partners.
// No hierarchy displayed to either partner.
//
// Receipt validation happens server-side via Edge Function.
// Never client-only validation.
//
// isFoundingMember enables first-year-free Pro when Act 2 launches.
// Lifetime purchases (expiresAt nil) are never revoked except
// for confirmed refunds.
// purchasedBy is recorded for support resolution only —
// never shown to either partner under any circumstances.

@Model
final class EntitlementRecord {

    // MARK: - Identity

    var id: UUID
    var coupleId: UUID
    var productId: String           // StoreKit product identifier
    var transactionId: String       // StoreKit transaction ID

    // MARK: - Purchase Metadata

    var purchasedBy: UUID           // support use only — never shown to partner
    var purchasedAt: Date
    var isActive: Bool
    var expiresAt: Date?            // nil for lifetime purchases

    // MARK: - Founding Member

    var isFoundingMember: Bool      // true if purchased before Pro launches
                                    // enables first-year-free Pro in Act 2

    // MARK: - Init

    init(
        coupleId: UUID,
        productId: String,
        purchasedBy: UUID,
        transactionId: String
    ) {
        self.id = UUID()
        self.coupleId = coupleId
        self.productId = productId
        self.purchasedBy = purchasedBy
        self.purchasedAt = Date()
        self.transactionId = transactionId
        self.isActive = true
        self.expiresAt = nil
        self.isFoundingMember = false
    }

    // MARK: - Computed

    var isLifetime: Bool {
        expiresAt == nil
    }

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt < Date()
    }

    // MARK: - Preview Helpers

    static let example = EntitlementRecord(
        coupleId: UUID(),
        productId: "com.vayl.core.lifetime",
        purchasedBy: UUID(),
        transactionId: "txn-preview-001"
    )

    static let foundingMemberExample: EntitlementRecord = {
        let e = EntitlementRecord(
            coupleId: UUID(),
            productId: "com.vayl.core.lifetime",
            purchasedBy: UUID(),
            transactionId: "txn-preview-002"
        )
        e.isFoundingMember = true
        return e
    }()
}

// MARK: - ConnectionEntitlement
// Records a $7.99 additional connection purchase.
// Permanent — no expiry, survives relationship dissolution.
//
// The $7.99 Permanent Bill of Rights — regardless of future
// pricing changes, this purchase always includes forever:
//   Infinite card sessions with that specific connection
//   Multi-person decks for that configuration
//   Shared Lock In with that connection
//   Desire Map input with that connection

@Model
final class ConnectionEntitlement {

    // MARK: - Identity

    var id: UUID
    var purchasedBy: UUID
    var connectionCoupleId: UUID    // which additional connection this unlocks
    var purchasedAt: Date
    var transactionId: String       // StoreKit transaction ID

    // No expiresAt — $7.99 is permanent, no expiry ever

    // MARK: - Init

    init(
        purchasedBy: UUID,
        connectionCoupleId: UUID,
        transactionId: String
    ) {
        self.id = UUID()
        self.purchasedBy = purchasedBy
        self.connectionCoupleId = connectionCoupleId
        self.purchasedAt = Date()
        self.transactionId = transactionId
    }

    // MARK: - Preview Helpers

    static let example = ConnectionEntitlement(
        purchasedBy: UUID(),
        connectionCoupleId: UUID(),
        transactionId: "txn-connection-preview-001"
    )
}
```

---

## File: `Vayl/Features/Home/Views/HomeRouterView.swift` {#file-vayl-features-home-views-homerouterview-swift}

```swift
//
//  HomeRouterView.swift
//  Vayl
//
//  Thin view. Renders only.
//  All routing logic lives in HomeStore.
//  All state lives in HomeStore.
//  This file switches on store.homeState and renders the result.
//

import SwiftUI
import SwiftData

struct HomeRouterView: View {

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HomeRouterInnerView(
            appState: appState,
            modelContainer: modelContext.container
        )
    }
}

private struct HomeRouterInnerView: View {

    @Environment(AppState.self) private var appState
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.modelContext) private var modelContext

    @State private var store: HomeStore

    // ── Session presentation ─────────────────────────────────────────────
    // Created here because HomeRouterView owns appState and modelContext.
    // Presented as a sheet over the home content.
    @State private var activeSession: SessionStore? = nil

    // ── Desire Map rater presentation ────────────────────────────────────
    // Presented as a .vaylCover so the rater is a protected, immersive, unhurried
    // beat (interactive-dismiss disabled; exit is explicit via vaylDismiss).
    // Reachable for unpaired users too (head-start hook).
    @State private var activeMap: DesireMapStore? = nil

    // Captured when the rater opens, so the dismiss handler can tell whether the user JUST
    // completed (false → true) and should see the one-shot completion beat.
    @State private var mapWasCompleteOnOpen = false

    // ── Desire-Map reveal presentation (D4) ──────────────────────────────
    // Full-screen "magic moment" — celebrates where the couple aligns (free/locked split).
    @State private var activeReveal: DesireRevealStore? = nil

    // ── Getting Started "Path" overlay ───────────────────────────────────
    // The day-1 activation expands the dashboard entry card (matched geometry)
    // into a Path overlay over a blurred Home. Hosted here — not a cover — so
    // the blurred Home shows behind it.
    @Namespace private var pathNamespace
    @State private var showPath = false

    init(appState: AppState, modelContainer: ModelContainer) {
        _store = State(initialValue: HomeStore(modelContainer: modelContainer, appState: appState))
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let layout = AppLayout.from(geo)

            Group {
                routedContent(store: store, layout: layout)
            }
        }
        .sheet(item: $activeSession) { session in
            SessionView(store: session)
        }
        .vaylCover(
            isPresented: Binding(
                get: { activeMap != nil },
                set: { if !$0 { activeMap = nil } }
            ),
            confirmOnExit: false,
            // The rater is a natural-end exit (no confirm dialog). The dismiss handler
            // fires via the cover's onExit hook, preserving the completion-beat behavior.
            onExit: handleRaterDismiss
        ) {
            if let mapStore = activeMap {
                DesireMapView(
                    store: mapStore,
                    partnerName: store.partnerName ?? "your partner",
                    partnerComplete: store.partnerMapComplete
                )
            }
        }
        .vaylCover(
            isPresented: Binding(
                get: { activeReveal != nil },
                set: { if !$0 { activeReveal = nil } }
            ),
            confirmOnExit: false
        ) {
            if let revealStore = activeReveal {
                DesireRevealView(store: revealStore)
            }
        }
    }

    // MARK: - Routed Content

    @ViewBuilder
    private func routedContent(store: HomeStore, layout: AppLayout) -> some View {
        ZStack {
            // Home leads with the dashboard from day one; .gated is vestigial. The waiting/reveal
            // progression is surfaced via the Getting Started path + partner pill, not a dashboard
            // card. The dashboard blurs behind the one-shot map-charted moment.
            Group {
                switch store.homeState {
                case .gated, .dashboard, .soloUnpaired:
                    dashboardContent(store: store)
                        .transition(.opacity)
                }
            }
            .blur(radius: store.showCompletionBeat ? 18 : 0)
            .animation(AppAnimation.enter, value: store.showCompletionBeat)

            // The Path overlay sits above the dashboard so the blurred Home shows behind it.
            if showPath {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { withAnimation(AppAnimation.spring) { showPath = false } }

                GettingStartedPathView(
                    gettingStarted: store.gettingStarted,
                    namespace: pathNamespace,
                    onSelect: { kind in
                        withAnimation(AppAnimation.spring) { showPath = false }
                        handleStep(kind, store: store)
                    },
                    onClose: { withAnimation(AppAnimation.spring) { showPath = false } }
                )
                .padding(.horizontal, AppSpacing.lg)
                .transition(.opacity)
            }

            // One-shot completion beat — a brief moment over the dashboard, never a home state.
            if store.showCompletionBeat {
                MapChartedMoment(
                    partnerName: store.partnerName ?? "your partner",
                    onDone: { store.dismissCompletionBeat() }
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(AppAnimation.enter, value: store.homeState)
        .animation(AppAnimation.spring, value: showPath)
        .animation(AppAnimation.enter, value: store.showCompletionBeat)
        .task {
            await store.loadAll()
        }

        #if DEBUG
        .overlay(alignment: .bottomTrailing) {
            debugControls(store: store, layout: layout)
        }
        #endif
    }

    // MARK: - Dashboard Content

    @ViewBuilder
    private func dashboardContent(store: HomeStore) -> some View {
        if let error = store.deckLoadError {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: AppIcons.exclamationTriangle)
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(AppColors.accentTertiary)

                Text("Couldn't load your deck")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)

                Text(error)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                Button("Try Again") {
                    Task { await store.loadDeck() }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(AppSpacing.xl)

        } else if store.isLoadingDeck || store.deck == nil {
            VStack(spacing: AppSpacing.sm) {
                ProgressView()
                    .tint(AppColors.accentPrimary)
                Text("Loading your deck...")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
            }

        } else if let loadedDeck = store.deck {
            HomeDashboardView(
                displayName:         appState.displayName,
                partnerChipState:    store.partnerChipState,
                cards:               loadedDeck.orderedCards,
                desireMapState:      store.desireMapState,
                reflectionCardState: store.reflectionCardState,
                pickUpItems:         [],
                stageIndex:          store.stageIndex,
                cardsCompleted:      store.cardsCompleted,
                recentEvents:        [],
                isSolo:              store.isSolo,
                gettingStarted:      store.gettingStarted,
                pathNamespace:       pathNamespace,
                pathOpen:            showPath,
                onOpenPath:          { withAnimation(AppAnimation.spring) { showPath = true } },
                onCardAction:        { card, action in
                    handleCardAction(card: card, action: action, deck: loadedDeck, store: store)
                },
                onInvitePartner:     { appState.selectedTab = .map },
                onPartnerTap:        { appState.selectedTab = .map },
                onOpenLexicon:       { appState.selectedTab = .learn },
                onPulseTap:          { appState.selectedTab = .map },
                // Interim: route to the Pulse surface. Final: present the shared
                // check-in sheet in place (Bryan's PulseWidget pass).
                onCheckIn:           { appState.selectedTab = .map },
                onOpenSettings:      { appState.selectedTab = .settings }
            )
        }
    }

    // MARK: - Card Action Handler

    /// Handles card actions from HomeDashboardView.
    /// Lives here because this view owns appState and modelContext.
    private func handleCardAction(card: Card, action: CardAction, deck: Deck, store: HomeStore) {
        switch action {

        case .startSession:
            // Resume from current progress — startIndex from store.cardsCompleted
            activeSession = SessionStore(
                deck: deck,
                startIndex: store.cardsCompleted,
                modelContainer: modelContext.container,
                appState: appState
            )

        case .navigateToPlay:
            appState.selectedTab = .play

        default:
            break
        }
    }

    // MARK: - Getting Started Step Router

    /// Routes a tapped Path step to its destination. Only `.active` steps are tappable
    /// (enforced in GettingStartedPathView), so this just opens the right surface.
    private func handleStep(_ kind: GettingStartedStepKind, store: HomeStore) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        // TODO(Moments): when gettingStarted advances a step (e.g. map → invite), fire a warm
        // HomeEvent/Moment ("First Spark") via the (future) Moments surface. No silent flag.
        switch kind {
        case .mapDesires:
            mapWasCompleteOnOpen = store.myMapComplete
            activeMap = DesireMapStore(
                modelContainer: modelContext.container,
                appState: appState
            )
        case .invitePartner:
            appState.selectedTab = .map     // pairing lives on the Map tab today (PairingSettingsView)
        case .seeReveal:
            presentReveal()                  // D4 reveal (stub) — full-screen "magic moment"
        case .profile:
            break                            // profile already done
        }
    }

    /// Presents the Desire-Map reveal (D4). Reads matches + the entitlement gate via the store.
    private func presentReveal() {
        activeReveal = DesireRevealStore(appState: appState, entitlements: entitlements)
    }

    /// Gap between the rater cover dismissing and the reveal cover rising. Two covers on one
    /// host cannot transition at once, so the reveal waits for the rater's dismiss to settle.
    private static let raterToRevealHandoff: Double = 0.35

    /// On rater close: refresh Home, then branch. If both maps are now complete and the reveal
    /// has not been seen, hand straight off to the reveal (the second-finisher gift, or a first
    /// finisher re-entering once their partner has finished). Otherwise, if the map JUST flipped
    /// to complete (first finisher, partner still pending), play the one-shot completion beat.
    /// The map is a moment, not a home state.
    private func handleRaterDismiss() {
        Task {
            let wasComplete = mapWasCompleteOnOpen
            await store.loadAll()
            guard store.myMapComplete == true else { return }
            if store.partnerMapComplete, !store.revealDone {
                try? await Task.sleep(for: .seconds(Self.raterToRevealHandoff))
                presentReveal()
            } else if !wasComplete, store.isPaired {
                // First finisher, paired: the one-shot map-charted moment. (Solo completion is
                // the solo-funnel beat, deferred — no partner to "see where you align" with yet.)
                store.celebrateMapCompletion()
            }
        }
    }

    // MARK: - Debug Controls

    #if DEBUG
    private func debugControls(store: HomeStore, layout: AppLayout) -> some View {
        VStack(alignment: .trailing, spacing: AppSpacing.sm) {
            Text("HomeState: \(String(describing: store.homeState))")
                .font(AppFonts.meta)
                .foregroundStyle(AppColors.textTertiary)

            Button("OB ✓") {
                let profile: UserProfile
                if let existing = try? modelContext.fetch(FetchDescriptor<UserProfile>()).first {
                    profile = existing
                } else {
                    profile = UserProfile(displayName: "Debug User")
                    modelContext.insert(profile)
                }
                appState.markOnboardingComplete(profile, context: modelContext)
            }

            Button(store.myMapComplete ? "Map ✓" : "Map ✗") {
                store.myMapComplete.toggle()
            }
            Button(store.postReflectionDone ? "Reflected ✓" : "Reflected ✗") {
                store.postReflectionDone.toggle()
            }
            Button(store.partnerMapComplete ? "Partner ✓" : "Partner ✗") {
                store.partnerMapComplete.toggle()
            }
            Button(store.revealDone ? "Reveal ✓" : "Reveal ✗") {
                store.revealDone.toggle()
            }
            // Direct reveal entry for testing — the production link is the Getting Started
            // `.seeReveal` step, only reachable once BOTH partners finish. One button per variant
            // so all three telegraphs are feelable solo (production picks one by coupleId).
            Button("Reveal · Gather ▶")      { presentSampleReveal(.gather) }
            Button("Reveal · Sweep ▶")       { presentSampleReveal(.sweep) }
            Button("Reveal · Constellate ▶") { presentSampleReveal(.constellate) }
        }
        .font(AppFonts.overline)
        .foregroundStyle(AppColors.accentPrimary)
        .padding(AppSpacing.sm)
        .background(AppColors.cardBackground.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .padding(.trailing, AppSpacing.md)
        .bottomContentInset(layout)
    }

    /// Opens the reveal with sample matches and a forced ceremony variant (debug feel-testing).
    private func presentSampleReveal(_ variant: CeremonyVariant) {
        let reveal = DesireRevealStore.previewStore(matches: [
            .sample("New Relationship Energy", .mutual, free: true),
            .sample("Overnight Stays With Others", .adjacent, locked: true),
            .sample("Meeting Your Partner's Connections", .mutual, locked: true),
            .sample("Shared Space Agreements", .mutual, locked: true),
            .sample("Deep Conversations Outside", .adjacent, locked: true),
        ], entitlements: entitlements)
        reveal.debugVariantOverride = variant
        activeReveal = reveal
    }
    #endif
}

```

---

## File: `Vayl/Features/Home/Store/HomeStore.swift` {#file-vayl-features-home-store-homestore-swift}

```swift
//
//  HomeStore.swift
//  Vayl
//
//  Brain of the Home flow.
//  Owns all routing state, deck loading, and map completion tracking.
//  The view renders. The store decides.
//
//  Dependencies injected via init — never from @Environment.
//  ModelContext created fresh at write time — never stored on self.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(
    subsystem: "com.vayl.app",
    category: "HomeStore"
)

@Observable
@MainActor
final class HomeStore {

    // MARK: - Routing State

    /// The single computed state that drives all routing in HomeRouterView.
    /// View reads this. View never writes this.
    var homeState: HomeState { resolveHomeState() }

    /// The post-onboarding "first steps" activation, derived from the same flags as `homeState`.
    var gettingStarted: GettingStarted {
        GettingStarted.resolve(
            myMapComplete: myMapComplete,
            isPaired: isPaired,
            partnerMapComplete: partnerMapComplete,
            revealDone: revealDone
        )
    }

    // MARK: - Map Completion

    var myMapComplete: Bool = false
    var partnerMapComplete: Bool = false
    var revealDone: Bool = false
    var postReflectionDone: Bool = false
    var partnerName: String? = nil
    var reflectionStep: Int = 1

    /// One-shot: set when the user just completed their Desire Map in the rater they closed.
    /// The dashboard plays a brief completion beat once, then clears it — the map is a moment,
    /// never a persistent home state.
    var showCompletionBeat: Bool = false

    // MARK: - Deck Loading

    var deck: Deck? = nil
    var deckLoadError: String? = nil
    var isLoadingDeck: Bool = false

    /// The deck Home leads with — the couple's most-recently-played deck, resolved
    /// from DeckProgress.lastPlayedAt. Falls back to the opener for a fresh couple.
    private var recentDeckId: String = "the-opener"

    // MARK: - Dashboard Data

    /// Cards completed in the active deck — derived from DeckProgress.
    /// Zero until DeckProgress exists for this couple and deck.
    var cardsCompleted: Int = 0

    /// Stage index — hardcoded to 1 until Stage model exists.
    /// TODO: wire from Stage model when built.
    var stageIndex: Int = 1

    /// Desire map state — derived from UserProfile and link state.
    var desireMapState: DesireMapState = .hidden

    /// Reflection card state — derived from most recent CardSession.
    var reflectionCardState: ReflectionCardState = .hidden

    // MARK: - Dependencies

    private let modelContainer: ModelContainer
    private let appState: AppState

    // MARK: - Init

    init(modelContainer: ModelContainer, appState: AppState) {
        self.modelContainer = modelContainer
        self.appState = appState

        #if DEBUG
        // Development quick-jump — skip to dashboard state.
        // Production always starts at false.
        self.myMapComplete = true
        self.partnerMapComplete = true
        self.revealDone = true
        self.postReflectionDone = true
        self.partnerName = "Alex"
        #endif
    }

    // MARK: - Derived

    var isPaired: Bool {
        appState.appMode == .together
    }

    var isSolo: Bool {
        appState.appMode == .solo
    }

    var partnerChipState: PartnerChipState {
        switch appState.linkState {
        case .linked:
            if let name = partnerName, !name.isEmpty {
                return .active(name: name, initial: String(name.prefix(1)).uppercased())
            }
            return .invitePending
        case .unlinked:
            return isPaired ? .invitePending : .none
        }
    }

    // MARK: - Routing

    /// Resolves the current HomeState from completion flags.
    /// Each guard gates the next state — order is intentional.
    private func resolveHomeState() -> HomeState {
        // Home ALWAYS leads with the card dashboard — the deck is the premiere product; the
        // Desire Map is secondary and must never gate Home. The post-map progression (your turn →
        // waiting on partner → reveal-ready) is surfaced quietly in the Getting Started path and a
        // one-shot completion beat — not as a full-screen takeover. The reveal itself stays
        // reachable via the Getting Started `seeReveal` step (gated on both maps, inherently).
        // Home always leads with the dashboard. `.gated` is vestigial (renders the dashboard);
        // `.postReflection/.waiting/.matchReady` are removed — "waiting on your partner" is driven
        // by the Getting Started tracker + partner pill, and the both-complete celebration is a
        // separate screen (Segment 3).
        if isSolo && appState.linkState == .unlinked { return .soloUnpaired }
        return .dashboard
    }

    /// Whether a given tab should be locked in the current home state.
    func isTabLocked(_ tab: AppTab) -> Bool {
        switch homeState {
        case .dashboard:
            return false
        case .soloUnpaired:
            return tab == .map   // starter deck (play) reachable; Desire Map locked until paired
        default:
            return tab == .play || tab == .map
        }
    }

    // MARK: - Actions

    func markPostReflectionDone() {
        postReflectionDone = true
    }

    /// Trigger the one-shot map-completion beat (called by the router when the rater the user
    /// just closed flipped the map false → true).
    func celebrateMapCompletion() {
        showCompletionBeat = true
    }

    func dismissCompletionBeat() {
        showCompletionBeat = false
    }

    func advanceReflectionStep() {
        reflectionStep += 1
    }

    // MARK: - Load

    /// Loads all data the home screen depends on in one pass.
    /// Call once on appear from HomeRouterView.
    func loadAll() async {
        await loadProfile()
        await loadDesireStatus()
        resolveRecentDeck()
        await loadDeckProgress()
        await loadReflectionState()
        await loadDeck()
    }

    // MARK: - Recent Deck

    /// Picks the couple's most-recently-played deck (by lastPlayedAt, then firstOpenedAt).
    /// Leaves `recentDeckId` at the opener default when there's no history.
    private func resolveRecentDeck() {
        guard let coupleId = appState.coupleId else { return }
        let context = ModelContext(modelContainer)
        do {
            let all = try context.fetch(FetchDescriptor<DeckProgress>(
                predicate: #Predicate { $0.coupleId == coupleId }
            ))
            let recent = all.max {
                ($0.lastPlayedAt ?? $0.firstOpenedAt ?? .distantPast) <
                ($1.lastPlayedAt ?? $1.firstOpenedAt ?? .distantPast)
            }
            if let recent, !recent.deckId.isEmpty, recent.lastPlayedAt != nil {
                recentDeckId = recent.deckId
                logger.info("HomeStore: recent deck = \(recent.deckId)")
            }
        } catch {
            logger.error("HomeStore: recent deck resolve failed — \(error.localizedDescription)")
        }
    }

    // MARK: - Desire Status Load (D-read)

    /// Reads the couple's `desire_map_status` to drive the waiting → match-ready flow.
    /// `partnerMapComplete` is derived from `bothComplete` — we only reach the partner gate
    /// once our own map is done, so `bothComplete` equals the partner's completion at that point.
    private func loadDesireStatus() async {
        guard appState.appMode == .together, let coupleId = appState.coupleId else { return }
        guard let status = try? await DesireSyncService.shared.fetchStatus(coupleId: coupleId) else { return }
        partnerMapComplete = status.bothComplete
        let progress = try? await DesireSyncService.shared.fetchRevealProgress(coupleId: coupleId)
        revealDone = progress?.hasSeenFree ?? false
        resolvePostStatusDesireMapState(coupleId: coupleId)
    }

    /// Refines desireMapState after server status is known (partner completion + reveal progress).
    /// Called at the end of loadDesireStatus, after revealDone and partnerMapComplete are set.
    /// The initial state from loadProfile/resolveDesireMapState is still useful as a fast-path
    /// before the server responds.
    private func resolvePostStatusDesireMapState(coupleId: UUID) {
        guard isPaired else { return }
        let context = ModelContext(modelContainer)
        let canReveal = (try? context.fetch(
            FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
        ).first)?.canRevealDesireMap ?? false

        if !myMapComplete { desireMapState = .yourTurn; return }
        if canReveal { desireMapState = .fullyUnlocked; return }
        if revealDone { desireMapState = .freeRevealSeen(matchCount: 0); return }
        if partnerMapComplete { desireMapState = .bothReady; return }
        desireMapState = .youDone(partnerName: partnerName ?? "your partner")
    }

    // MARK: - Profile Load

    /// Reads UserProfile to resolve map completion and desire map state.
    private func loadProfile() async {
        let context = ModelContext(modelContainer)

        do {
            let descriptor = FetchDescriptor<UserProfile>()
            let profiles = try context.fetch(descriptor)

            guard let profile = profiles.first else {
                logger.info("HomeStore: no UserProfile found — staying at defaults")
                return
            }

            myMapComplete = profile.hasCompletedDesireMap
            desireMapState = resolveDesireMapState(from: profile)

            logger.info("HomeStore: profile loaded — mapComplete: \(profile.hasCompletedDesireMap)")

        } catch {
            logger.error("HomeStore: profile load failed — \(error.localizedDescription)")
        }
    }

    /// Derives DesireMapState from UserProfile fields and current link state.
    private func resolveDesireMapState(from profile: UserProfile) -> DesireMapState {
        guard isPaired else { return .hidden }

        switch appState.linkState {
        case .unlinked:
            return profile.hasCompletedDesireMap ? .youDone(partnerName: "your partner") : .yourTurn
        case .linked:
            if !profile.hasCompletedDesireMap { return .yourTurn }
            // Conservative fast-path: the partner's completion is not known until the server
            // resolve (resolvePostStatusDesireMapState) runs a hop later. Show "waiting" rather
            // than optimistically flashing "both ready" — the server resolve upgrades to
            // .bothReady / .fullyUnlocked once it confirms.
            return .youDone(partnerName: partnerName ?? "your partner")
        }
    }

    // MARK: - Deck Progress Load

    /// Reads DeckProgress to resolve cardsCompleted for the active deck.
    private func loadDeckProgress() async {
        guard let coupleId = appState.coupleId else {
            logger.info("HomeStore: no coupleId — skipping DeckProgress fetch")
            return
        }

        let context = ModelContext(modelContainer)
        let deckId = recentDeckId

        do {
            var descriptor = FetchDescriptor<DeckProgress>(
                predicate: #Predicate { $0.coupleId == coupleId && $0.deckId == deckId }
            )
            descriptor.fetchLimit = 1
            let results = try context.fetch(descriptor)

            if let progress = results.first {
                cardsCompleted = progress.currentCardIndex
                logger.info("HomeStore: DeckProgress loaded — cardsCompleted: \(progress.currentCardIndex)")
            }

        } catch {
            logger.error("HomeStore: DeckProgress load failed — \(error.localizedDescription)")
        }
    }

    // MARK: - Reflection State Load

    /// Reads the most recent completed CardSession to derive reflectionCardState.
    private func loadReflectionState() async {
        guard let coupleId = appState.coupleId else {
            logger.info("HomeStore: no coupleId — skipping CardSession fetch")
            return
        }

        let context = ModelContext(modelContainer)

        do {
            var descriptor = FetchDescriptor<CardSession>(
                predicate: #Predicate { $0.coupleId == coupleId },
                sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
            )
            descriptor.fetchLimit = 1
            let sessions = try context.fetch(descriptor)

            guard let session = sessions.first,
                  session.completedAt != nil else {
                reflectionCardState = .hidden
                return
            }

            // Session exists and is complete — surface pending reflection.
            // sessionLabel derived from deckId until Deck model has a title lookup.
            // TODO: resolve human-readable deck title from ContentLoader.
            let label = "Session \(session.sessionNumber)"
            reflectionCardState = .pendingYours(
                sessionLabel: label,
                sessionDate: session.completedAt ?? session.startedAt
            )

            logger.info("HomeStore: reflection state — pendingYours for session \(session.sessionNumber)")

        } catch {
            logger.error("HomeStore: CardSession load failed — \(error.localizedDescription)")
        }
    }

    // MARK: - Deck Loading

    func loadDeck() async {
        guard !isLoadingDeck else { return }
        isLoadingDeck = true
        deckLoadError = nil

        do {
            let loaded = try ContentLoader.loadDeck(id: recentDeckId)
            deck = loaded
            logger.info("HomeStore: deck loaded — \(loaded.id)")
        } catch {
            // Recent deck couldn't be loaded — fall back to the opener.
            if recentDeckId != "the-opener", let fallback = try? ContentLoader.loadDeck(id: "the-opener") {
                recentDeckId = "the-opener"
                deck = fallback
                logger.info("HomeStore: recent deck failed, fell back to the-opener")
            } else {
                deckLoadError = error.localizedDescription
                logger.error("HomeStore: deck load failed — \(error.localizedDescription)")
            }
        }

        isLoadingDeck = false
    }
}

```

---

## File: `Vayl/Features/Home/Components/DesireMapIndicator.swift` {#file-vayl-features-home-components-desiremapindicator-swift}

```swift
// Home/Components/DesireMapIndicator.swift

import SwiftUI

struct DesireMapIndicator: View {
    let state: DesireMapState
    var onReveal: (() -> Void)? = nil
    var onUnlock: (() -> Void)? = nil
    var onRemind: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        switch state {
        case .hidden, .fullyUnlocked:
            EmptyView()

        case .youDone(let partnerName):
            statusCard {
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("DESIRE MAP")
                            .font(AppFonts.overline)
                            .tracking(1.2)
                            .foregroundStyle(AppColors.textTertiary)

                        HStack(spacing: AppSpacing.md) {
                            HStack(spacing: AppSpacing.xs) {
                                Circle()
                                    .fill(colorScheme == .light
                                        ? AppColors.accentTertiary
                                        : AppColors.accentPrimary)
                                    .frame(width: 7, height: 7)
                                Text("You're done")
                                    .font(AppFonts.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            HStack(spacing: AppSpacing.xs) {
                                Circle()
                                    .stroke(AppColors.textTertiary, lineWidth: 1)
                                    .frame(width: 7, height: 7)
                                Text(partnerName)
                                    .font(AppFonts.caption)
                                    .foregroundStyle(AppColors.textTertiary)
                            }
                        }
                    }
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onRemind?()
                    } label: {
                        Text("Remind \(partnerName) →")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.accentTertiary
                                : AppColors.accentPrimary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.md)
            }

        case .bothReady:
            bothReadyCard

        case .freeRevealSeen(_):
            statusCard {
                HStack(spacing: AppSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .light
                                ? AppColors.accentTertiary.opacity(0.10)
                                : AppColors.accentSecondary.opacity(0.15))
                            .frame(width: 38, height: 38)
                        Image(systemName: AppIcons.heartTextSquare)
                            // .body scales with Dynamic Type — correct for
                            // icon badges at this visual weight.
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.accentTertiary, AppColors.safetyAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.accentSecondary, AppColors.accentTertiary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing)))
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("1 match revealed")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        Text("+ more waiting")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onUnlock?()
                    } label: {
                        Text("Unlock →")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.accentTertiary
                                : AppColors.accentPrimary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.md)
            }

        case .redoInProgress(let partnerName, let matchCount):
            redoInProgressCard(partnerName: partnerName, matchCount: matchCount)

        case .gated, .yourTurn, .waiting, .matchReady, .revealed:
            EmptyView()
        }
    }

    // MARK: - Case cards
    // Extracted from the `body` switch so each is type-checked in isolation
    // (the combined switch was 177ms).

    private var bothReadyCard: some View {
        // Elevated treatment — highest CTA weight on screen
        let buttonTextColor: Color = colorScheme == .light ? AppColors.textSecondary : .white
        let buttonFill: AnyShapeStyle = colorScheme == .light
            ? AnyShapeStyle(LinearGradient(
                colors: [AppColors.accentTertiary.opacity(0.18), AppColors.safetyAccent.opacity(0.14)],
                startPoint: .leading, endPoint: .trailing))
            : AnyShapeStyle(LinearGradient(
                colors: [AppColors.accentPrimary, AppColors.accentSecondary, AppColors.accentTertiary],
                startPoint: .leading, endPoint: .trailing))
        let buttonShadow: Color = colorScheme == .light ? AppColors.shadowMagenta : AppColors.accentSecondary.opacity(0.4)
        let cardBorder: AnyShapeStyle = colorScheme == .light
            ? AnyShapeStyle(AppColors.spectrumBorder.opacity(0.6))
            : AnyShapeStyle(LinearGradient(
                colors: [AppColors.accentPrimary.opacity(0.5), AppColors.accentSecondary.opacity(0.4), AppColors.accentTertiary.opacity(0.3)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
        let cardShadow: Color = colorScheme == .light ? AppColors.shadowPurple : AppColors.accentSecondary.opacity(0.2)

        return VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("DESIRE MAP")
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .foregroundStyle(AppColors.textTertiary)
                    Spacer()
                    Text("You're both ready")
                        .font(AppFonts.caption)
                        .foregroundStyle(accentEmphasis)
                }

                HStack(spacing: AppSpacing.md) {
                    HStack(spacing: AppSpacing.xs) {
                        Circle()
                            .fill(accentEmphasis)
                            .frame(width: 7, height: 7)
                        Text("You")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    HStack(spacing: AppSpacing.xs) {
                        Circle()
                            .fill(colorScheme == .light ? AppColors.safetyAccent : AppColors.accentSecondary)
                            .frame(width: 7, height: 7)
                        Text("Partner")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)

            Spacer(minLength: AppSpacing.md)

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onReveal?()
            } label: {
                Text("See Your First Match")
                    .font(AppFonts.ctaLabel)
                    .foregroundStyle(buttonTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: AppRadius.md).fill(buttonFill)
                    }
                    .shadow(color: buttonShadow, radius: 12, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.md)
        }
        .background {
            RoundedRectangle(cornerRadius: AppRadius.lg).fill(AppColors.cardBackground)
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.lg).stroke(cardBorder, lineWidth: 1.5)
        }
        .shadow(color: cardShadow, radius: 20, y: 6)
    }

    private func redoInProgressCard(partnerName: String, matchCount: Int) -> some View {
        let partnerStarted: Bool = matchCount != 0
        let partnerDotFill: Color = partnerStarted
            ? (colorScheme == .light ? AppColors.safetyAccent : AppColors.accentSecondary)
            : Color.clear
        let partnerLabel: String = partnerStarted ? "\(partnerName) in progress" : "\(partnerName) hasn't started"
        let partnerLabelColor: Color = partnerStarted ? AppColors.textSecondary : AppColors.textTertiary

        return statusCard {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(spacing: AppSpacing.sm) {
                        Text("DESIRE MAP")
                            .font(AppFonts.overline)
                            .tracking(1.2)
                            .foregroundStyle(AppColors.textTertiary)
                        Text("· Check-in")
                            .font(AppFonts.overline)
                            .foregroundStyle(accentEmphasis)
                    }

                    HStack(spacing: AppSpacing.md) {
                        HStack(spacing: AppSpacing.xs) {
                            Circle()
                                .fill(accentEmphasis)
                                .frame(width: 7, height: 7)
                            Text("You — redoing")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        HStack(spacing: AppSpacing.xs) {
                            Circle()
                                .fill(partnerDotFill)
                                .overlay {
                                    if !partnerStarted {
                                        Circle().stroke(AppColors.textTertiary, lineWidth: 1)
                                    }
                                }
                                .frame(width: 7, height: 7)
                            Text(partnerLabel)
                                .font(AppFonts.caption)
                                .foregroundStyle(partnerLabelColor)
                        }
                    }
                }
                Spacer()
                if !partnerStarted {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onRemind?()
                    } label: {
                        Text("Remind →")
                            .font(AppFonts.caption)
                            .foregroundStyle(accentEmphasis)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.md)
        }
    }

    /// Light → tertiary, dark → primary. The single most-repeated accent choice.
    private var accentEmphasis: Color {
        colorScheme == .light ? AppColors.accentTertiary : AppColors.accentPrimary
    }

    // MARK: - Shared card shell for compact states

    @ViewBuilder
    private func statusCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .background {
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(colorScheme == .light
                        ? AppColors.glassFrostCard
                        : AppColors.cardBackground)
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(AppColors.borderSubtle, lineWidth: 1)
            }
    }
}

```

---

## File: `Vayl/Features/Home/Views/MapChartedMoment.swift` {#file-vayl-features-home-views-mapchartedmoment-swift}

```swift
//
//  MapChartedMoment.swift
//  Vayl
//
//  The one-shot "map charted" moment. When the first finisher completes their Desire Map,
//  the Vayl aperture draws itself on over an obscured Home, then the copy resolves. Plays
//  ONCE and dismisses, a brief beat, never a home state. The ongoing "waiting on your partner"
//  status lives quietly as an icon in the partner pill, not here.
//
//  The desire-map "world" is re-established over the obscured Home with a semi-transparent
//  atmosphere + a StarVeil, so the dimmed dashboard reads faintly through (almost home, but
//  still in the map's world). The presenter is responsible for the Home blur behind this.
//

import SwiftUI

/// How the copy enters after the mark has drawn. Tunable on device.
enum MomentCopyEntrance: String, CaseIterable {
    /// Blur → sharp: the words resolve into focus (clarity emerging, on-theme with the veil).
    case focusResolve
    /// The title fades in carrying a gentle spectrum glow that echoes the mark.
    case glowIgnite
    /// The copy springs up from beneath the mark, as if it surfaced from the aperture.
    case springRise
}

struct MapChartedMoment: View {
    let partnerName: String
    var copyEntrance: MomentCopyEntrance = .focusResolve
    var onDone: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draw: CGFloat = 0
    @State private var copyT: CGFloat = 0
    @State private var titleGlow: Double = 0
    @State private var contentOpacity: Double = 1
    @State private var didDismiss = false
    @State private var autoAdvance: Task<Void, Never>?

    var body: some View {
        ZStack {
            // Desire-map world over the obscured Home. Transparent enough that the dimmed
            // dashboard still reads faintly through (these opacities are the "how obscured" knobs).
            OnboardingAtmosphere(config: .cardReveal, opacity: 0.7)
                .ignoresSafeArea()
            StarVeil()
                .ignoresSafeArea()
                .opacity(0.6)
            AppColors.void.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                VaylMark(drawProgress: draw)
                    .frame(width: 116, height: 116)

                copyBlock
            }
            .padding(.horizontal, AppSpacing.xl)
        }
        .opacity(contentOpacity)
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .onAppear(perform: animateIn)
        .onDisappear { autoAdvance?.cancel() }
    }

    private var copyBlock: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("That's yours now")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
                .modifier(TitleGlow(active: copyEntrance == .glowIgnite, intensity: titleGlow))

            Text("When \(partnerName) finishes theirs,\nyou'll see where you align.")
                .font(AppFonts.bodyText)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .modifier(CopyTransition(style: copyEntrance, t: copyT))
    }

    private func animateIn() {
        if reduceMotion {
            draw = 1; copyT = 1; titleGlow = 0.5
        } else {
            withAnimation(AppAnimation.markDraw) { draw = 1 }

            let copyAnimation: Animation = copyEntrance == .springRise
                ? AppAnimation.spring
                : AppAnimation.markCopyRise
            withAnimation(copyAnimation.delay(AppAnimation.markCopyDelay)) { copyT = 1 }

            if copyEntrance == .glowIgnite {
                withAnimation(AppAnimation.markCopyRise.delay(AppAnimation.markCopyDelay)) { titleGlow = 0.55 }
            }
        }
        scheduleAutoAdvance()
    }

    /// Hold once the copy has resolved, then ease back to Home on its own. The "waiting on
    /// your partner" status persists in the partner pill, so this moment does not linger.
    private func scheduleAutoAdvance() {
        let lead = reduceMotion ? 0 : AppAnimation.markCopyDelay
        autoAdvance = Task {
            try? await Task.sleep(for: .seconds(lead + AppAnimation.markHold))
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }

    /// Ease the whole moment out, then notify the presenter. Idempotent; a tap can trigger it
    /// early (skipping the hold).
    private func dismiss() {
        guard !didDismiss else { return }
        didDismiss = true
        autoAdvance?.cancel()
        guard !reduceMotion else { onDone(); return }
        withAnimation(AppAnimation.exit) {
            contentOpacity = 0
        } completion: {
            onDone()
        }
    }
}

// MARK: - Copy entrance modifiers

private struct CopyTransition: ViewModifier {
    let style: MomentCopyEntrance
    let t: CGFloat

    func body(content: Content) -> some View {
        switch style {
        case .focusResolve:
            content
                .opacity(Double(t))
                .blur(radius: (1 - t) * 6)
        case .glowIgnite:
            content
                .opacity(Double(t))
        case .springRise:
            content
                .opacity(Double(t))
                .scaleEffect(0.9 + 0.1 * t)
                .offset(y: (1 - t) * 20)
        }
    }
}

private struct TitleGlow: ViewModifier {
    let active: Bool
    let intensity: Double

    @ViewBuilder
    func body(content: Content) -> some View {
        if active {
            content.spectrumBorderGlow(intensity: intensity)
        } else {
            content
        }
    }
}

// MARK: - Previews

private func momentPreview(_ style: MomentCopyEntrance) -> some View {
    ZStack {
        // Mock obscured Home behind the moment (the presenter blurs the real dashboard).
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat)
            .ignoresSafeArea()
            .blur(radius: 8)
            .opacity(0.45)

        MapChartedMoment(partnerName: "Alex", copyEntrance: style)
    }
    .preferredColorScheme(.dark)
}

#Preview("1 · focus resolve") { momentPreview(.focusResolve) }
#Preview("2 · glow ignite")   { momentPreview(.glowIgnite) }
#Preview("3 · spring rise")   { momentPreview(.springRise) }

```

---

## File: `Vayl/Features/Map/MapView.swift` {#file-vayl-features-map-mapview-swift}

```swift
//
//  MapView.swift
//  Vayl
//
//  The Map tab — the personal / mirror dashboard, paired with Home. Seg 0 is the
//  shell: void + atmosphere (identical to Home / Play / Learn), the Home-grammar
//  personal masthead (name + sub-line + gear), and the Me / Us segmented toggle
//  over empty layer scaffolds. Content (Pulse, the Record, the Me Card, the Us
//  layer, the Vault) lands in Segments 1-5. View -> MapStore; no service or fetch
//  logic lives here.
//

import SwiftUI
import SwiftData

struct MapView: View {

    @Environment(AppState.self) private var appState
    @Environment(PulseStore.self) private var pulse
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.modelContext) private var modelContext
    @State private var store = MapStore()

    @State private var showCheckIn = false
    @State private var showPulseSheet = false
    @State private var showMeCard = false
    @State private var showVault = false
    @State private var showPaywall = false
    @State private var vaultStore = VaultStore()

    var body: some View {
        @Bindable var store = store
        GeometryReader { geo in
            let layout = AppLayout.from(geo)

            ZStack(alignment: .top) {
                // Same floor + sky as every other tab.
                AppColors.void.ignoresSafeArea()
                OnboardingAtmosphere(config: .stat)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        masthead   // the name wordmark IS the Me/Us switch now

                        layerContent
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollIndicators(.hidden)
            }
            // Pin the screen to the true width so an ignoresSafeArea child (the
            // atmosphere) cannot inflate the container and shove the column off-centre.
            .frame(width: layout.screenWidth, alignment: .center)
            .vaylSheet(
                isPresented: $showCheckIn,
                heightFraction: 0.82,
                screenHeight: layout.screenHeight
            ) {
                PulseCheckInView(store: pulse, onClose: { showCheckIn = false })
            }
            .onChange(of: appState.vaultOpenPending) { _, pending in
                if pending {
                    showVault = true
                    appState.vaultOpenPending = false
                }
            }
            .vaylSheet(
                isPresented: $showPulseSheet,
                heightFraction: 0.92,
                screenHeight: layout.screenHeight
            ) {
                PulseFullView(
                    entries: pulse.entries,
                    onDismiss: { showPulseSheet = false }
                )
            }
            .vaylSheet(
                isPresented: $showMeCard,
                heightFraction: 0.9,
                screenHeight: layout.screenHeight
            ) {
                MeCardSheet(
                    card: store.meCard,
                    onChooseTitle: { store.setTitle($0, context: modelContext) },
                    onChooseFlavor: { store.setFlavor($0, context: modelContext) }
                )
            }
            .vaylSheet(
                isPresented: $showVault,
                heightFraction: 0.9,
                screenHeight: layout.screenHeight
            ) {
                VaultSheet(store: vaultStore, onUnlock: { showPaywall = true })
            }
            .vaylSheet(
                isPresented: $showPaywall,
                heightFraction: 0.92,
                screenHeight: layout.screenHeight
            ) {
                PaywallSheet(entry: .reveal, onUnlocked: {
                    showPaywall = false
                    Task { await vaultStore.loadDesire(appState: appState, context: modelContext, isCore: entitlements.isCore) }
                })
            }
        }
        .task {
            store.load(appState: appState, context: modelContext, isCore: entitlements.isCore)
            await vaultStore.loadDesire(appState: appState, context: modelContext, isCore: entitlements.isCore)
            await store.loadPartner(appState: appState)
        }
    }

    // MARK: - Masthead (Home grammar: personal name + sub-line + gear)

    private var masthead: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                if !store.displayName.isEmpty {
                    nameToggle
                }
                if !store.subtitle.isEmpty {
                    Text(store.subtitle)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // The header IS the Me/Us switch: your name always glows; the partner's name
    // sits dimmed in Me and lights up (with the period) in Us. Tapping the partner's
    // name toggles the lens. No pill, no chevron. Falls back to your name alone when
    // unpaired / the partner name hasn't loaded.
    private var nameToggle: some View {
        let name = store.displayName
        let partner = store.partnerName
        let isUs = store.layer == .us
        return HStack(spacing: 0) {
            // Your name → the Me lens (always lit; you're always in view).
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(AppAnimation.spring) { store.layer = .me }
            } label: {
                Text(isUs ? name : "\(name).")
                    .foregroundStyle(AppColors.spectrumText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Show just you")
            .accessibilityAddTraits(isUs ? .isButton : [.isButton, .isSelected])

            // Partner's name → the Us lens (dim in Me, lit in Us; period follows).
            if !partner.isEmpty {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(AppAnimation.spring) { store.layer = .us }
                } label: {
                    Text(isUs ? " & \(partner)." : " & \(partner)")
                        .foregroundStyle(isUs
                            ? AnyShapeStyle(AppColors.spectrumText)
                            : AnyShapeStyle(AppColors.textTertiary))
                        // Dim the inactive partner name further so it reads clearly
                        // "off" (grey + reduced opacity), not just a grey colour.
                        .opacity(isUs ? 1.0 : 0.45)
                }
                .buttonStyle(.plain)
                .transition(.opacity)   // fades in the first time the name loads
                .accessibilityLabel("Show you and \(partner) together")
                .accessibilityAddTraits(isUs ? [.isButton, .isSelected] : .isButton)
            }
        }
        .font(AppFonts.display(40, weight: .bold, relativeTo: .largeTitle))
        // Animate only the partner-name LOAD (""→name) so it fades in once; the
        // Me/Us colour/period changes are animated separately by the button taps.
        .animation(AppAnimation.slow, value: store.partnerName)
    }


    // MARK: - Layers (empty scaffolds in Seg 0; filled in Segments 1-5)

    @ViewBuilder
    private var layerContent: some View {
        switch store.layer {
        case .me: meLayer
        case .us: usLayer
        }
    }

    private var meLayer: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            MapPulseHero(
                onCheckIn: { startCheckIn() },
                onOpenHistory: { showPulseSheet = true }
            )
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                MapSectionHeader(title: "Your card")
                MeCardCompact(card: store.meCard, onTap: { showMeCard = true })
            }
            MapRecord(sessions: store.sessions, shares: store.categoryShares)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var usLayer: some View {
        MapUsLayer(
            stats:            store.usStats,
            align:            store.alignItems,
            lockedAlignCount: store.lockedAlignCount,
            onOpenVault:      { showVault = true },
            partnerPosition:  store.partnerPosition,
            partnerName:      store.partnerName
        )
    }

    // MARK: - Pulse check-in

    private func startCheckIn() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        showCheckIn = true
    }
}

// MARK: - Preview

#Preview("Map tab") {
    let state = { let s = AppState(); s.displayName = "Jordan"; return s }()
    return MapView()
        .environment(state)
        .environment(PulseStore())
        .environment(EntitlementStore(modelContainer: .previewContainerWithProfile, appState: state))
        .modelContainer(.previewContainer)
        .preferredColorScheme(.dark)
}

```

---

## File: `Vayl/Features/Map/MapStore.swift` {#file-vayl-features-map-mapstore-swift}

```swift
//
//  MapStore.swift
//  Vayl
//
//  The Map tab's state owner (4-layer: View -> Store -> Service -> Model). Owns the
//  Me/Us layer toggle, derives the personal masthead, and assembles the Record
//  (session history + category distribution) from the couple's CardSession data.
//  Later segments extend it (Me Card, Us layer, Vault). The store fetches; views
//  only read.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class MapStore {

    /// The two faces of the Map: your own mirror, and the couple layer.
    enum Layer: String, CaseIterable {
        case me, us
    }

    /// Which layer the segmented control is showing.
    var layer: Layer = .me

    // MARK: - Derived masthead

    private(set) var displayName: String = ""
    private(set) var subtitle: String = ""

    /// The linked partner's name — drives the "Jordan & Alex." header toggle.
    /// Empty when unpaired or not yet fetched (header falls back to your name only).
    private(set) var partnerName: String = ""

    // MARK: - The Record (Me layer)

    struct RecordSession: Identifiable {
        let id: UUID
        let deckName: String
        let category: DeckCategory
        let date: Date
        let cardCount: Int
    }

    struct CategoryShare: Identifiable {
        let category: DeckCategory
        let count: Int
        var id: String { category.rawValue }
    }

    private(set) var sessions: [RecordSession] = []
    private(set) var categoryShares: [CategoryShare] = []

    // MARK: - The Me Card (Me layer)

    struct DrawnTag: Identifiable, Hashable {
        let name: String
        let isShared: Bool
        var id: String { name }
    }

    struct MeCard {
        var flavor: Flavor = .explorer
        var name: String = ""
        var title: String = ""
        var tags: [DrawnTag] = []
    }

    private(set) var meCard = MeCard()

    // MARK: - Pulse positions

    /// The partner's current circumplex position. nil until Segment 7 wires PulseSyncService.
    private(set) var partnerPosition: PulsePosition? = nil

    // MARK: - The Us layer

    struct UsStats {
        var isLinked: Bool = false
        var tenureStage: String? = nil
        var tenureTime: String? = nil
        var weeksOnVayl: Int = 0
        var sessionCount: Int = 0
    }

    struct AlignItem: Identifiable {
        let id: String
        let name: String
        let isMutual: Bool
    }

    private(set) var usStats = UsStats()
    private(set) var alignItems: [AlignItem] = []
    private(set) var lockedAlignCount: Int = 0

    // MARK: - Load

    /// Idempotent — safe to call on every appear. `isCore` is the OR'd entitlement
    /// source of truth (server tier OR local StoreKit ownership), threaded in from the
    /// View; the desire-match gate reads it rather than the lagging local Couple mirror.
    func load(appState: AppState, context: ModelContext, isCore: Bool) {
        loadMasthead(appState: appState, context: context)
        loadRecord(coupleId: appState.coupleId, context: context)
        loadMeCard(context: context)
        loadUs(appState: appState, context: context)
        Task { await loadServerAlignData(appState: appState, context: context, isCore: isCore) }
    }

    /// Async: fetches the partner's name for the header toggle. Safe to await on appear.
    func loadPartner(appState: AppState) async {
        // Load once, then persist — so "& Alex" fades in a single time and never
        // flickers in/out on subsequent appears.
        guard partnerName.isEmpty else { return }
        if appState.linkState == .linked,
           let identity = try? await PairingService().fetchPartner(),
           let name = identity.name, !name.isEmpty {
            partnerName = name
            return
        }
        #if DEBUG
        partnerName = "Alex"   // dev: show the toggle without a live paired backend
        #else
        partnerName = ""       // unpaired / partner has no name → just your name, no toggle
        #endif
    }

    private func loadMasthead(appState: AppState, context: ModelContext) {
        displayName = appState.displayName
        let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first
        let stageLabel = (profile?.nmStage ?? .exploring).displayName
        subtitle = Self.subtitle(stageLabel: stageLabel, joinedAt: profile?.createdAt)
    }

    private func loadRecord(coupleId: UUID?, context: ModelContext) {
        guard let coupleId else {
            sessions = []
            categoryShares = []
            return
        }

        // Deck content is bundle JSON (not network); safe to load in the store.
        let summaries = (try? DeckCatalogService().loadSummaries()) ?? []
        let byId = Dictionary(summaries.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        var fetch = FetchDescriptor<CardSession>(
            predicate: #Predicate { $0.coupleId == coupleId },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        fetch.fetchLimit = 50
        let raw = (try? context.fetch(fetch)) ?? []

        sessions = raw.map { s in
            let summary = byId[s.deckId]
            return RecordSession(
                id: s.id,
                deckName: summary?.title ?? "A deck",
                category: summary?.category ?? .wildcard,
                date: s.startedAt,
                cardCount: s.cardsDiscussed
            )
        }

        let counts = Dictionary(grouping: sessions, by: { $0.category }).mapValues(\.count)
        categoryShares = counts
            .map { CategoryShare(category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    private func loadMeCard(context: ModelContext) {
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else {
            meCard = MeCard(
                flavor: .explorer,
                name: displayName,
                title: Flavor.explorer.titles.first ?? "",
                tags: []
            )
            return
        }
        let flavor = profile.flavor.flatMap(Flavor.init(rawValue:)) ?? .explorer
        let title = profile.chosenTitle ?? flavor.titles.first ?? ""
        let tags = Self.drawnTags(userId: profile.id, coupleId: profile.coupleId, context: context)
        meCard = MeCard(flavor: flavor, name: profile.displayName, title: title, tags: tags)
    }

    /// Derives the "Drawn to" tags from the user's positive Desire ratings. Shared (mutual)
    /// state is resolved asynchronously in loadServerAlignData after the server fetch arrives;
    /// this synchronous path produces un-glowed tags as an immediate placeholder.
    private static func drawnTags(userId: UUID, coupleId: UUID?, context: ModelContext) -> [DrawnTag] {
        let items = (try? ContentLoader.loadDesireItems()) ?? []
        let nameById = Dictionary(items.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })

        let entryFetch = FetchDescriptor<DesireMapEntry>(predicate: #Predicate { $0.userId == userId })
        let entries = (try? context.fetch(entryFetch)) ?? []
        let positive = entries.filter { $0.rating == .excitedAboutIt || $0.rating == .openToIt }

        // Shared tags are resolved in loadServerAlignData after the server fetch.
        let sharedIds = Set<String>()
        _ = coupleId  // coupleId retained in signature for future local-cache fast path

        let tags = positive.map { entry in
            DrawnTag(name: nameById[entry.itemId] ?? entry.itemId, isShared: sharedIds.contains(entry.itemId))
        }
        // Shared first, then a small cap so the card stays calm.
        return Array(tags.sorted { $0.isShared && !$1.isShared }.prefix(5))
    }

    // MARK: - Me Card editing

    func setFlavor(_ flavor: Flavor, context: ModelContext) {
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        profile.flavor = flavor.rawValue
        // Drop a title that does not belong to the new flavor (falls back to default).
        if let current = profile.chosenTitle, !flavor.titles.contains(current) {
            profile.chosenTitle = nil
        }
        try? context.save()
        loadMeCard(context: context)
    }

    func setTitle(_ title: String, context: ModelContext) {
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        profile.chosenTitle = title
        try? context.save()
        loadMeCard(context: context)
    }

    // MARK: - The Us layer

    private func loadUs(appState: AppState, context: ModelContext) {
        var stats = UsStats(isLinked: appState.linkState == .linked, sessionCount: sessions.count)

        if let coupleId = appState.coupleId,
           let couple = try? context.fetch(
                FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
           ).first {
            stats.tenureStage = couple.relationshipTenure?.stageLabel
            stats.tenureTime  = couple.relationshipTenure?.timeLabel
            stats.weeksOnVayl = Self.weeks(since: couple.createdAt)
        }
        usStats = stats

        // Server matches are fetched async in loadServerAlignData — local mirror is not populated.
        alignItems = []
        lockedAlignCount = 0
    }

    /// Fetches server desire matches and updates the Us align list and meCard tags.
    /// Runs after loadUs so the synchronous scaffold is already in place.
    private func loadServerAlignData(appState: AppState, context: ModelContext, isCore: Bool) async {
        guard let coupleId = appState.coupleId else { return }

        let matchRows = (try? await DesireSyncService.shared.fetchMatches(coupleId: coupleId)) ?? []

        // Gate on the OR'd entitlement (server tier OR local StoreKit ownership), not the
        // local Couple.canRevealDesireMap mirror, which can lag a just-purchased buyer.
        let canReveal = isCore

        // Build the Us align list using the server-authoritative gate rule.
        let items = (try? ContentLoader.loadDesireItems()) ?? []
        let nameById = Dictionary(items.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        var revealed: [AlignItem] = []
        var locked = 0
        for row in matchRows {
            if canReveal || row.isFreeReveal {
                revealed.append(AlignItem(
                    id: row.desireItemId,
                    name: nameById[row.desireItemId] ?? row.desireItemId,
                    isMutual: row.matchType == .mutual
                ))
            } else {
                locked += 1
            }
        }
        alignItems = revealed.sorted { $0.isMutual && !$1.isMutual }
        lockedAlignCount = locked

        // Update meCard tags: mutual shared items glow once server data arrives.
        if let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first {
            let sharedIds = Set(
                matchRows
                    .filter { (canReveal || $0.isFreeReveal) && $0.matchType == .mutual }
                    .map(\.desireItemId)
            )
            // Capture the UUID into a local let so the #Predicate macro can see a plain value.
            let profileId = profile.id
            let entryFetch = FetchDescriptor<DesireMapEntry>(predicate: #Predicate { $0.userId == profileId })
            let entries = (try? context.fetch(entryFetch)) ?? []
            let positive = entries.filter { $0.rating == .excitedAboutIt || $0.rating == .openToIt }
            let tags = positive.map { entry in
                DrawnTag(name: nameById[entry.itemId] ?? entry.itemId, isShared: sharedIds.contains(entry.itemId))
            }
            meCard.tags = Array(tags.sorted { $0.isShared && !$1.isShared }.prefix(5))
        }
    }

    private static func weeks(since date: Date) -> Int {
        max(0, Calendar.current.dateComponents([.weekOfYear], from: date, to: Date()).weekOfYear ?? 0)
    }

    // MARK: - Helpers

    /// "Exploring · 14 weeks on Vayl" once there is real tenure, otherwise the
    /// forming variant.
    private static func subtitle(stageLabel: String, joinedAt: Date?) -> String {
        guard let joinedAt else { return "\(stageLabel) · your map is just beginning" }
        let weeks = Calendar.current
            .dateComponents([.weekOfYear], from: joinedAt, to: Date())
            .weekOfYear ?? 0
        guard weeks >= 1 else { return "\(stageLabel) · your map is just beginning" }
        let unit = weeks == 1 ? "week" : "weeks"
        return "\(stageLabel) · \(weeks) \(unit) on Vayl"
    }
}

```

---

## File: `Vayl/Features/Map/MeCardSheet.swift` {#file-vayl-features-map-mecardsheet-swift}

```swift
//
//  MeCardSheet.swift
//  Vayl
//
//  The full Me Card + editor, presented as a .vaylSheet. Shows the large card,
//  then a Title chooser (the flavor's shortlist) and a Flavor chooser. Selecting
//  either persists via MapStore and re-renders the card. Portrait stays the lattice
//  sigil in V1 (opt-in photo deferred).
//

import SwiftUI

struct MeCardSheet: View {

    let card: MapStore.MeCard
    var onChooseTitle: (String) -> Void
    var onChooseFlavor: (Flavor) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                fullCard
                titleChooser
                flavorChooser
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - The full card

    private var fullCard: some View {
        VStack(spacing: AppSpacing.md) {
            FlavorPortrait(size: 92)

            VStack(spacing: AppSpacing.xxs) {
                Text(card.name)
                    .font(AppFonts.display(18, weight: .semibold, relativeTo: .title3))
                    .foregroundStyle(AppColors.textSecondary)
                Text(card.title)
                    .font(AppFonts.display(26, weight: .bold, relativeTo: .title))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, card.flavor.color],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: AppSpacing.sm) {
                FlavorChip(flavor: card.flavor)
                Text(card.flavor.essence)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            if !card.tags.isEmpty {
                FlowLayout(spacing: AppSpacing.xs) {
                    ForEach(card.tags) { tag in
                        DrawnTagChip(tag: tag, flavor: card.flavor)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity)
        .vaylGlassCard(accent: card.flavor.color, radius: AppRadius.xl)
    }

    // MARK: - Choosers

    private var titleChooser: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Choose your title")
                .font(AppFonts.overline)
                .tracking(1.0)
                .foregroundStyle(AppColors.textTertiary)
            FlowLayout(spacing: AppSpacing.xs) {
                ForEach(card.flavor.titles, id: \.self) { title in
                    choiceChip(label: title, selected: title == card.title, accent: card.flavor.color) {
                        onChooseTitle(title)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var flavorChooser: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Your flavor")
                .font(AppFonts.overline)
                .tracking(1.0)
                .foregroundStyle(AppColors.textTertiary)
            FlowLayout(spacing: AppSpacing.xs) {
                ForEach(Flavor.allCases) { flavor in
                    choiceChip(label: flavor.label, icon: flavor.icon,
                               selected: flavor == card.flavor, accent: flavor.color) {
                        onChooseFlavor(flavor)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func choiceChip(
        label: String,
        icon: String? = nil,
        selected: Bool,
        accent: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: AppSpacing.xs) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 11, weight: .semibold))
                }
                Text(label).font(AppFonts.caption)
            }
            .foregroundStyle(selected ? .white : AppColors.textSecondary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs + 1)
            .background(Capsule().fill(selected ? accent.opacity(0.20) : AppColors.glassSurface))
            .overlay(
                Capsule().strokeBorder(
                    selected ? accent.opacity(0.55) : AppColors.borderSubtle,
                    lineWidth: 1
                )
            )
        }
        .buttonStyle(PressableCardStyle())
    }
}

```

---

## File: `Vayl/Features/Map/PrismView.swift` {#file-vayl-features-map-prismview-swift}

```swift
// Features/Home/Components/PrismView.swift
// Vayl
//
// Shell chrome (surface, orbs, rim, border, shadows, underglow)
// owned by HomeWidgetShell — this view provides zero chrome.
// PrismView renders content only — header, tabs, pill switcher.
//
// Wrapped in HomeWidgetShell in HomeDashboardView ambientZone.
// breathPhase driven externally — shared 8s cycle with GravLift.

import SwiftUI

// MARK: - Prism Mode

enum PrismMode: CaseIterable {
    case journal
    case reflect
    case agreements

    var label: String {
        switch self {
        case .journal:    return "Journal"
        case .reflect:    return "Reflect"
        case .agreements: return "Agreements"
        }
    }

    var color: Color {
        switch self {
        case .journal:    return AppColors.accentPrimary
        case .reflect:    return AppColors.accentSecondary
        case .agreements: return AppColors.accentTertiary
        }
    }

    var privateLabel: String {
        switch self {
        case .journal:    return "PRIVATE · NEVER SYNCED"
        case .reflect:    return "SOLO ONLY · NOT SHARED"
        case .agreements: return "READ ONLY · WITH ALEX"
        }
    }

    var timeAwarePrompt: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch self {
        case .journal:
            switch hour {
            case 5..<12:  return "What are you bringing into today?"
            case 12..<17: return "What's sitting underneath the surface right now?"
            case 17..<21: return "What happened today that you haven't processed yet?"
            default:      return "What are you not saying to anyone?"
            }
        case .reflect:
            switch hour {
            case 5..<12:  return "What do you need to look at before the day starts?"
            case 12..<17: return "What are you avoiding right now?"
            case 17..<21: return "What came up today that needs space?"
            default:      return "What truth are you sitting with?"
            }
        case .agreements:
            return "Your current agreements with Alex."
        }
    }
}

// MARK: - PrismView

struct PrismView: View {

    // MARK: - External breath phase
    // Driven by HomeDashboardView — shared 8s linear cycle.
    // Do not start a local animation for this.
    let breathPhase: CGFloat

    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // MARK: - State
    @Namespace private var pillNamespace

    @State private var activeMode:  PrismMode = .journal
    @State private var expanded:    Bool      = false
    @State private var cursorOn:    Bool      = true
    @State private var cursorTimer: Timer?    = nil
    @State private var cardDrawn:   Bool      = false
    @State private var cardShimmer: Bool      = false
    @State private var journalText: String    = ""

    // MARK: - Derived
    private var modeColor: Color { activeMode.color }

    // Hoisted color choices. Resolving these isLight ternaries once (as typed
    // computed properties) keeps the agreements/pill view bodies cheap to
    // type-check — inline they forced repeated Color + CGFloat/Double inference.
    private var labelMutedColor:     Color { isLight ? AppColors.textTertiary : AppColors.textMuted }
    private var secondaryQuoteColor: Color { AppColors.textSecondary.opacity(0.65) }
    private var cardFillColor:       Color { isLight ? Color.black.opacity(0.03) : Color.white.opacity(0.03) }
    private var pillBackgroundColor: Color { isLight ? Color.black.opacity(0.04) : Color.white.opacity(0.03) }
    private var pillBorderColor:     Color { isLight ? Color.black.opacity(0.07) : AppColors.borderSubtle }

    // MARK: - Body
    // Zero chrome — HomeWidgetShell owns surface, rim, border, shadows.
    // Content only rendered here.

    var body: some View {
        content
            .onAppear { startCursorBlink() }
            .onDisappear {
                cursorTimer?.invalidate()
                cursorTimer = nil
            }
            .animation(AppAnimation.standard, value: activeMode)
            .animation(AppAnimation.spring, value: expanded)
            .animation(AppAnimation.spring, value: cardDrawn)
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 0) {
            headerRow
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.md)

            Divider()
                .background(
                    isLight
                        ? Color.black.opacity(0.07)
                        : AppColors.borderSubtle
                )
                .padding(.horizontal, AppSpacing.md)

            TabView(selection: $activeMode) {
                journalContent
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)
                    .frame(
                        minHeight: expanded ? 200 : 180,
                        maxHeight: expanded ? .infinity : 180,
                        alignment: .top
                    )
                    .tag(PrismMode.journal)

                reflectContent
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)
                    .frame(
                        minHeight: expanded ? 200 : 180,
                        maxHeight: expanded ? .infinity : 180,
                        alignment: .top
                    )
                    .tag(PrismMode.reflect)

                agreementsContent
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)
                    .frame(
                        minHeight: expanded ? 200 : 180,
                        maxHeight: expanded ? .infinity : 180,
                        alignment: .top
                    )
                    .tag(PrismMode.agreements)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: expanded ? 280 : 196)
            .onChange(of: activeMode) { _, _ in
                withAnimation(AppAnimation.spring) {
                    expanded    = false
                    cardDrawn   = false
                    journalText = ""
                }
            }

            pillSwitcher
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.xs)
                .padding(.bottom, AppSpacing.md)
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(alignment: .center) {
            HStack(spacing: AppSpacing.sm) {
                Circle()
                    .fill(modeColor)
                    .frame(width: 6, height: 6)
                    .shadow(color: modeColor, radius: 4)
                    .animation(AppAnimation.standard, value: activeMode)

                Text(activeMode.privateLabel)
                    .font(AppFonts.overline)
                    .tracking(1.0)
                    .foregroundStyle(modeColor.opacity(0.55))
                    .animation(AppAnimation.fast, value: activeMode)
            }

            Spacer()

            if expanded {
                Button {
                    withAnimation(AppAnimation.spring) {
                        expanded    = false
                        cardDrawn   = false
                        journalText = ""
                    }
                } label: {
                    Text("Close")
                        .font(AppFonts.body(12, weight: .medium, relativeTo: .caption))
                        .foregroundStyle(
                            isLight
                                ? AppColors.textTertiary
                                : AppColors.textTertiary
                        )
                        .padding(.leading, AppSpacing.sm)
                }
            }
        }
    }

    // MARK: - Journal Content

    @ViewBuilder
    private var journalContent: some View {
        if !expanded {
            VStack(alignment: .leading, spacing: 0) {

                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(activeMode.timeAwarePrompt)
                        .font(AppFonts.body(15, weight: .regular, relativeTo: .body))
                        .foregroundStyle(
                            isLight
                                ? AppColors.textSecondary.opacity(0.80)
                                : AppColors.textSecondary.opacity(0.80)
                        )
                        .lineSpacing(4)
                    Text(cursorOn ? "|" : " ")
                        .font(AppFonts.body(15, weight: .regular, relativeTo: .body))
                        .foregroundStyle(AppColors.accentPrimary.opacity(0.65))
                }
                .padding(.bottom, AppSpacing.md)

                Button {
                    withAnimation(AppAnimation.spring) {
                        expanded = true
                    }
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                            .fill(AppColors.accentPrimary.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                    .strokeBorder(AppColors.accentPrimary.opacity(0.22), lineWidth: 1)
                            )
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text("+")
                                    .font(Font.custom("Switzer-Regular", size: 16, relativeTo: .body))
                                    .foregroundStyle(AppColors.accentPrimary)
                            )

                        Text("Write entry")
                            .font(AppFonts.body(12, weight: .medium, relativeTo: .caption))
                            .foregroundStyle(AppColors.accentPrimary.opacity(0.65))

                        Spacer()

                        HStack(spacing: AppSpacing.xs) {
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .fill(i == 0
                                          ? AppColors.accentPrimary
                                          : (isLight ? Color.black.opacity(0.10) : AppColors.borderSubtle))
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                }
                .padding(.bottom, AppSpacing.md)

                Divider()
                    .background(
                        isLight
                            ? Color.black.opacity(0.07)
                            : AppColors.borderSubtle
                    )
                    .padding(.bottom, AppSpacing.md)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("LAST ENTRY · 2 DAYS AGO")
                        .font(AppFonts.overline)
                        .tracking(1.8)
                        .foregroundStyle(
                            isLight
                                ? AppColors.textTertiary
                                : AppColors.textMuted
                        )

                    Text("\"Didn't expect to feel that settled after the conversation about...\"")
                        .font(AppFonts.body(12, weight: .regular, relativeTo: .caption))
                        .foregroundStyle(
                            isLight
                                ? AppColors.textSecondary.opacity(0.65)
                                : AppColors.textTertiary
                        )
                        .lineSpacing(3)
                        .lineLimit(2)
                }
                .padding(.bottom, AppSpacing.xs)
            }

        } else {

            VStack(alignment: .leading, spacing: AppSpacing.sm) {

                Text(activeMode.timeAwarePrompt)
                    .font(AppFonts.body(13, weight: .regular, relativeTo: .caption))
                    .foregroundStyle(
                        journalText.isEmpty
                            ? (isLight
                                ? AppColors.textSecondary.opacity(0.45)
                                : AppColors.textSecondary.opacity(0.45))
                            : (isLight
                                ? AppColors.textTertiary
                                : AppColors.textMuted)
                    )
                    .italic()

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(
                            isLight
                                ? Color.black.opacity(0.03)
                                : Color.white.opacity(0.03)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .strokeBorder(AppColors.accentPrimary.opacity(0.18), lineWidth: 1)
                        )
                        .frame(minHeight: 110)

                    if journalText.isEmpty {
                        Text("Start writing...")
                            .font(AppFonts.body(14, weight: .regular, relativeTo: .callout))
                            .foregroundStyle(
                                isLight
                                    ? AppColors.textTertiary
                                    : AppColors.textMuted
                            )
                            .padding(AppSpacing.md)
                    }
                }

                HStack(spacing: AppSpacing.sm) {
                    Button { } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(AppIcons.mic)
                                .font(Font.custom("Switzer-Regular", size: 12, relativeTo: .caption))
                            Text("Dictate")
                                .font(AppFonts.body(12, weight: .medium, relativeTo: .caption))
                        }
                        .foregroundStyle(AppColors.accentPrimary.opacity(0.65))
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColors.accentPrimary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .strokeBorder(AppColors.accentPrimary.opacity(0.18), lineWidth: 1)
                        )
                    }

                    Spacer()

                    Button {
                        withAnimation(AppAnimation.spring) {
                            expanded = false
                        }
                    } label: {
                        Text("Save")
                            .font(AppFonts.body(12, weight: .semibold, relativeTo: .caption))
                            .foregroundStyle(AppColors.accentPrimary)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColors.accentPrimary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                    .strokeBorder(AppColors.accentPrimary.opacity(0.28), lineWidth: 1)
                            )
                    }
                }
                .padding(.bottom, AppSpacing.xs)
            }
        }
    }

    // MARK: - Reflect Content

    @ViewBuilder
    private var reflectContent: some View {
        VStack(spacing: 0) {
            if !cardDrawn {

                Button {
                    if !expanded {
                        withAnimation(AppAnimation.spring) {
                            expanded = true
                        }
                    } else {
                        drawSoloCard()
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.accentSecondary.opacity(0.16),
                                        AppColors.accentSecondary.opacity(0.07)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint:   .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                                    .strokeBorder(AppColors.accentSecondary.opacity(0.28), lineWidth: 1)
                            )
                            .frame(height: expanded ? 100 : 80)

                        ZStack {
                            ForEach([1.0, 0.65, 0.35], id: \.self) { scale in
                                Circle()
                                    .strokeBorder(
                                        AppColors.accentSecondary.opacity(0.10 + scale * 0.08),
                                        lineWidth: 1
                                    )
                                    .frame(width: 60 * scale, height: 60 * scale)
                            }
                            Circle()
                                .fill(AppColors.accentSecondary.opacity(0.20))
                                .frame(width: 8, height: 8)
                                .shadow(color: AppColors.accentSecondary, radius: 4)
                        }
                        .opacity(cardShimmer ? 0 : 1)

                        if expanded {
                            Text("Draw a card")
                                .font(AppFonts.body(13, weight: .semibold, relativeTo: .caption))
                                .foregroundStyle(AppColors.accentSecondary.opacity(0.75))
                                .offset(y: 28)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(.bottom, expanded ? 0 : AppSpacing.md)

                if !expanded {
                    Divider()
                        .background(
                            isLight
                                ? Color.black.opacity(0.07)
                                : AppColors.borderSubtle
                        )
                        .padding(.bottom, AppSpacing.md)

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("LAST REFLECTION · 5 DAYS AGO")
                            .font(AppFonts.overline)
                            .tracking(1.8)
                            .foregroundStyle(
                                isLight
                                    ? AppColors.textTertiary
                                    : AppColors.textMuted
                            )

                        Text("You drew from the solo deck. No note saved.")
                            .font(AppFonts.body(12, weight: .regular, relativeTo: .caption))
                            .foregroundStyle(
                                isLight
                                    ? AppColors.textSecondary.opacity(0.65)
                                    : AppColors.textTertiary
                            )
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, AppSpacing.xs)
                }

            } else {

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.06, green: 0.04, blue: 0.16),
                                    AppColors.accentSecondary.opacity(0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint:   .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                                .strokeBorder(AppColors.accentSecondary.opacity(0.40), lineWidth: 1)
                        )
                        .overlay(alignment: .topLeading) {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("SOLO · INNER WORK")
                                    .font(AppFonts.overline)
                                    .tracking(2.0)
                                    .foregroundStyle(AppColors.accentSecondary.opacity(0.65))

                                Text("When do you find yourself editing your feelings before sharing them?")
                                    .font(AppFonts.body(14, weight: .regular, relativeTo: .callout))
                                    .foregroundStyle(AppColors.textPrimary.opacity(0.85))
                                    .lineSpacing(4)
                            }
                            .padding(AppSpacing.md)
                        }
                        .frame(minHeight: 100)

                    HStack(spacing: AppSpacing.sm) {
                        Button {
                            withAnimation(AppAnimation.spring) {
                                cardDrawn = false
                            }
                        } label: {
                            Text("Draw another")
                                .font(AppFonts.body(12, weight: .medium, relativeTo: .caption))
                                .foregroundStyle(
                                    isLight
                                        ? AppColors.textTertiary
                                        : AppColors.textTertiary
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.sm)
                                .background(
                                    isLight
                                        ? Color.black.opacity(0.04)
                                        : Color.white.opacity(0.04)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                        .strokeBorder(
                                            isLight
                                                ? Color.black.opacity(0.08)
                                                : AppColors.borderSubtle,
                                            lineWidth: 1
                                        )
                                )
                        }

                        Button { } label: {
                            Text("Write a note")
                                .font(AppFonts.body(12, weight: .semibold, relativeTo: .caption))
                                .foregroundStyle(AppColors.accentSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.sm)
                                .background(AppColors.accentSecondary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                        .strokeBorder(AppColors.accentSecondary.opacity(0.30), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.bottom, AppSpacing.xs)
                }
            }
        }
    }

    // MARK: - Agreements Content

    private var agreementsData: [(date: String, text: String)] {
        [
            (date: "Jun 12", text: "We check in before making plans that affect both of us."),
            (date: "Jun 8",  text: "Sleepovers with new connections need 48 hours notice."),
            (date: "May 28", text: "No phones during our first hour back together."),
        ]
    }

    @ViewBuilder
    private var agreementsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !expanded {
                collapsedAgreements
            } else {
                expandedAgreements
            }
        }
    }

    @ViewBuilder
    private var collapsedAgreements: some View {
        let first = agreementsData[0]

        Text("\"\(first.text)\"")
            .font(AppFonts.body(14, weight: .regular, relativeTo: .callout))
            .foregroundStyle(secondaryQuoteColor)
            .lineSpacing(4)
            .padding(.bottom, AppSpacing.md)

        HStack {
            Text("Added \(first.date) · \(agreementsData.count) total")
                .font(AppFonts.overline)
                .tracking(1.2)
                .foregroundStyle(labelMutedColor)

            Spacer()

            Button {
                withAnimation(AppAnimation.spring) {
                    expanded = true
                }
            } label: {
                Text("View all →")
                    .font(AppFonts.body(12, weight: .medium, relativeTo: .caption))
                    .foregroundStyle(AppColors.accentTertiary.opacity(0.65))
            }
        }
        .padding(.bottom, AppSpacing.xs)
    }

    @ViewBuilder
    private var expandedAgreements: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(Array(agreementsData.enumerated()), id: \.offset) { i, a in
                agreementRow(index: i, date: a.date, text: a.text)
            }

            HStack {
                Text("Changes made in Map tab")
                    .font(AppFonts.body(11, weight: .regular, relativeTo: .caption2))
                    .foregroundStyle(labelMutedColor)
                Spacer()
                Text("Go to Map →")
                    .font(AppFonts.body(11, weight: .medium, relativeTo: .caption2))
                    .foregroundStyle(AppColors.accentTertiary.opacity(0.55))
            }
            .padding(.horizontal, AppSpacing.xs)
            .padding(.top, AppSpacing.xs)
            .padding(.bottom, AppSpacing.xs)
        }
    }

    private func agreementRow(index i: Int, date: String, text: String) -> some View {
        let border: Color = i == 0 ? AppColors.accentTertiary.opacity(0.25) : pillBorderColor

        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(date)
                .font(AppFonts.overline)
                .tracking(1.2)
                .foregroundStyle(labelMutedColor)

            Text("\"\(text)\"")
                .font(AppFonts.body(13, weight: .regular, relativeTo: .caption))
                .foregroundStyle(AppColors.textSecondary.opacity(0.70))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(cardFillColor)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(border, lineWidth: 1)
        )
    }

    // MARK: - Pill Switcher

    private var pillSwitcher: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(PrismMode.allCases, id: \.label) { mode in
                pillButton(for: mode)
            }
        }
        .padding(AppSpacing.sm)
        .background(pillBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(pillBorderColor, lineWidth: 1)
        )
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    let all = PrismMode.allCases
                    guard let current = all.firstIndex(of: activeMode) else { return }
                    let next: Int
                    if value.translation.width < 0 {
                        next = min(current + 1, all.count - 1)
                    } else {
                        next = max(current - 1, 0)
                    }
                    guard next != current else { return }
                    withAnimation(AppAnimation.spring) {
                        activeMode  = all[next]
                        expanded    = false
                        cardDrawn   = false
                        journalText = ""
                    }
                }
        )
    }

    private func pillButton(for mode: PrismMode) -> some View {
        let isActive: Bool = mode == activeMode
        let labelColor: Color = isActive ? mode.color : AppColors.textTertiary

        return Button {
            withAnimation(AppAnimation.spring) {
                activeMode  = mode
                expanded    = false
                cardDrawn   = false
                journalText = ""
            }
        } label: {
            Text(mode.label)
                .font(AppFonts.body(11, weight: isActive ? .semibold : .regular, relativeTo: .caption2))
                .foregroundStyle(labelColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background {
                    if isActive {
                        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                            .fill(mode.color.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                    .strokeBorder(mode.color.opacity(0.35), lineWidth: 1.0)
                            )
                            .matchedGeometryEffect(id: "pill", in: pillNamespace)
                    }
                }
        }
    }

    // MARK: - Helpers

    private func startCursorBlink() {
        cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.53, repeats: true) { _ in
            cursorOn.toggle()
        }
    }

    private func drawSoloCard() {
        cardShimmer = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(AppAnimation.spring) {
                cardDrawn   = true
                cardShimmer = false
            }
        }
    }
}

// MARK: - Previews
// Wrapped in HomeWidgetShell to match real usage context.

#Preview("Prism — dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ScrollView {
            HomeWidgetShell(
                isLight:     false,
                accentColor: AppColors.accentSecondary,
                rimVariant:  .prism
            ) {
                ZStack {
                    OrbLayer(
                        accentColor: AppColors.accentSecondary,
                        height:      300,
                        variant:     .prism
                    )
                    PrismView(breathPhase: 0)
                }
            }
            .padding(AppSpacing.md)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Prism — light") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ScrollView {
            HomeWidgetShell(
                isLight:     true,
                accentColor: AppColors.accentSecondary,
                rimVariant:  .prism
            ) {
                PrismView(breathPhase: 0)
            }
            .padding(AppSpacing.md)
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Prism — Journal expanded — dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ScrollView {
            HomeWidgetShell(
                isLight:     false,
                accentColor: AppColors.accentSecondary,
                rimVariant:  .prism
            ) {
                ZStack {
                    OrbLayer(accentColor: AppColors.accentSecondary, height: 300, variant: .prism)
                    PrismView(breathPhase: 0)
                }
            }
            .padding(AppSpacing.md)
        }
    }
    .preferredColorScheme(.dark)
}

```

---

## File: `Vayl/Features/Map/Components/FlavorVisuals.swift` {#file-vayl-features-map-components-flavorvisuals-swift}

```swift
//
//  FlavorVisuals.swift
//  Vayl
//
//  Shared visual atoms for the Me Card: the lattice sigil portrait, the flavor
//  chip, and the "Drawn to" tag (shared tags glow in the flavor colour). Used by
//  both the compact card and the full editor sheet.
//

import SwiftUI

/// Two nested diamonds — the lattice sigil used on identity surfaces.
struct FlavorSigil: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let cx = w / 2, cy = h / 2
        p.move(to: CGPoint(x: cx, y: 0))
        p.addLine(to: CGPoint(x: w, y: cy))
        p.addLine(to: CGPoint(x: cx, y: h))
        p.addLine(to: CGPoint(x: 0, y: cy))
        p.closeSubpath()
        let inset = min(w, h) * 0.28
        p.move(to: CGPoint(x: cx, y: inset))
        p.addLine(to: CGPoint(x: w - inset, y: cy))
        p.addLine(to: CGPoint(x: cx, y: h - inset))
        p.addLine(to: CGPoint(x: inset, y: cy))
        p.closeSubpath()
        return p
    }
}

/// The portrait: a spectrum ring around the lattice sigil (V1 has no opt-in photo).
struct FlavorPortrait: View {
    var size: CGFloat = 56

    private var spectrum: LinearGradient {
        LinearGradient(
            colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            Circle().strokeBorder(spectrum, lineWidth: 2)
            FlavorSigil()
                .stroke(spectrum, style: StrokeStyle(lineWidth: 1.3, lineJoin: .round))
                .frame(width: size * 0.46, height: size * 0.46)
        }
        .frame(width: size, height: size)
    }
}

/// The flavor chip (icon + label, tinted by the flavor colour).
struct FlavorChip: View {
    let flavor: Flavor

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: flavor.icon)
                .font(.system(size: 11, weight: .semibold))
            Text(flavor.label.uppercased())
                .font(AppFonts.overline)
                .tracking(0.6)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs + 1)
        .background(Capsule().fill(flavor.color.opacity(0.22)))
        .overlay(Capsule().strokeBorder(flavor.color.opacity(0.45), lineWidth: 1))
    }
}

/// A "Drawn to" tag. Shared (mutual) tags glow in the flavor colour.
struct DrawnTagChip: View {
    let tag: MapStore.DrawnTag
    let flavor: Flavor

    var body: some View {
        HStack(spacing: 3) {
            if tag.isShared {
                Image(systemName: "sparkle").font(.system(size: 8))
            }
            Text(tag.name).font(AppFonts.caption)
        }
        .foregroundStyle(tag.isShared ? .white : AppColors.textBody)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(Capsule().fill(tag.isShared ? flavor.color.opacity(0.18) : AppColors.glassSurface))
        .overlay(
            Capsule().strokeBorder(
                tag.isShared ? flavor.color.opacity(0.45) : AppColors.borderSubtle,
                lineWidth: 1
            )
        )
    }
}

// MARK: - Couple crest

/// Two side-by-side diamonds — the couple crest (the Us-layer counterpart to the
/// single-diamond Me sigil).
struct CoupleCrestSigil: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(rect.width, rect.height) * 0.30
        diamond(&p, center: CGPoint(x: rect.midX - r * 0.7, y: rect.midY), radius: r)
        diamond(&p, center: CGPoint(x: rect.midX + r * 0.7, y: rect.midY), radius: r)
        return p
    }

    private func diamond(_ p: inout Path, center c: CGPoint, radius r: CGFloat) {
        p.move(to: CGPoint(x: c.x, y: c.y - r))
        p.addLine(to: CGPoint(x: c.x + r, y: c.y))
        p.addLine(to: CGPoint(x: c.x, y: c.y + r))
        p.addLine(to: CGPoint(x: c.x - r, y: c.y))
        p.closeSubpath()
    }
}

/// A couple crest portrait — spectrum ring around the twin-diamond crest.
struct CoupleCrestPortrait: View {
    var size: CGFloat = 52

    private var spectrum: LinearGradient {
        LinearGradient(
            colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            Circle().strokeBorder(spectrum, lineWidth: 2)
            CoupleCrestSigil()
                .stroke(spectrum, style: StrokeStyle(lineWidth: 1.3, lineJoin: .round))
                .frame(width: size * 0.62, height: size * 0.62)
        }
        .frame(width: size, height: size)
    }
}

```

---

## File: `Vayl/Features/Map/Components/MapPrimitives.swift` {#file-vayl-features-map-components-mapprimitives-swift}

```swift
//
//  MapPrimitives.swift
//  Vayl
//
//  Small shared building blocks for the Map tab: the section eyebrow, the empty /
//  forming state (cohesion rule #7), and the Record's category colour mapping.
//  Kept in one place so every Map surface speaks the same visual language.
//

import SwiftUI

// MARK: - Section header (eyebrow + optional trailing link)

struct MapSectionHeader: View {
    let title: String
    var linkLabel: String? = nil
    var onLink: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(AppFonts.overline)
                .tracking(1.2)
                .foregroundStyle(AppColors.textTertiary)
            Spacer()
            if let linkLabel, let onLink {
                Button(action: onLink) {
                    Text(linkLabel)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.accentSecondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Empty / forming state
//
// Icon + headline + sub-label per the CLAUDE.md empty-state spec. Every Map data
// block routes its empty/forming case through this, so they all read alike.

struct MapEmptyState: View {
    let icon: String
    let headline: String
    let message: String

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(AppColors.textTertiary)
            Text(headline)
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textSecondary)
            Text(message)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
        .padding(.horizontal, AppSpacing.lg)
    }
}

// MARK: - Deck category colour (Map-local)
//
// No canonical per-category colour exists in the system, so this is a Map-local
// spectrum mapping for the Record's distribution bar + row dots. Tokens only.

extension DeckCategory {
    var mapColor: Color {
        switch self {
        case .foundationEntry:     return AppColors.spectrumCyan
        case .relationshipCore:    return AppColors.accentPrimary
        case .nmSpecific:          return AppColors.spectrumMagenta
        case .styleSpecific:       return AppColors.spectrumPurple
        case .experienceArc:       return AppColors.accentSecondary
        case .identityDynamics:    return AppColors.pulseTierSovereign
        case .advancedExperienced: return AppColors.pulseTierFriction
        case .soloPrep:            return AppColors.pulseTierProtective
        case .wildcard:            return AppColors.accentTertiary
        case .multiPerson:         return AppColors.pulseTierExpansive
        }
    }
}

// MARK: - Flow layout (wrapping chip cloud)
//
// A minimal wrapping layout for the Me Card's Drawn-to tags + the Title / Flavor
// choosers. Lays subviews left to right, wrapping to a new row when the proposed
// width runs out.

struct FlowLayout: Layout {
    var spacing: CGFloat = AppSpacing.xs

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        let width = maxWidth == .infinity ? x : maxWidth
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

```

---

## File: `Vayl/Features/Map/Components/MapPulseHero.swift` {#file-vayl-features-map-components-mappulsehero-swift}

```swift
// Features/Map/Components/MapPulseHero.swift
//
// The Me layer's Pulse section on the Map tab.
//
// Glance: aura hero (148pt) + Space name + sublabel + weather one-liner.
// "tap to map →" opens a sheet with the full 2D field at the user's current position.
//
// Visual reference: docs/prototypes/map-pulse-final.html — "Me · the glance" phone.

import SwiftUI

struct MapPulseHero: View {

    @Environment(PulseStore.self) private var pulse

    var onCheckIn:    () -> Void
    var onOpenHistory: () -> Void

    @State private var showMap = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader

            // Aura — tapping it opens the field-map sheet.
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showMap = true
            } label: {
                PulseAura(quadrant: currentQuadrant, size: 148)
                    .frame(maxWidth: .infinity)
                    .padding(.top, AppSpacing.lg)
            }
            .buttonStyle(.plain)
            .scaleEffect(1.0)   // placeholder for press state — wire if adding isPressed

            // Space name + sublabel
            VStack(spacing: AppSpacing.xxs) {
                Text(currentQuadrant.spaceName)
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(currentQuadrant.sublabel)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                if let wl = weatherLine {
                    Text(wl)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.spectrumCyan)
                        .padding(.top, AppSpacing.xxs)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.sm)

            // History grid — last 30 logged check-ins, never "last 30 days".
            if !meGridQuadrants.isEmpty {
                PulseHistoryGrid(mode: .me(meGridQuadrants))
                    .padding(.top, AppSpacing.lg)
            }
        }
        .vaylSheet(isPresented: $showMap, heightFraction: 0.88) {
            MapFieldSheet(position: currentPosition, quadrant: currentQuadrant)
        }
    }

    // MARK: - Section header

    private var sectionHeader: some View {
        HStack {
            Text("The Pulse")
                .font(AppFonts.overline)
                .foregroundStyle(AppColors.textTertiary)
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showMap = true
            } label: {
                Text("tap to map →")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Derived state

    private var currentPosition: PulsePosition {
        pulse.entries.last?.resolvedPosition ?? PulsePosition(energy: 0.5, openness: 0.5)
    }

    private var currentQuadrant: PulseQuadrant { currentPosition.quadrant }

    private var meGridQuadrants: [PulseQuadrant] {
        PulseHistory.lastLogged(pulse.entries).map { $0.resolvedPosition.quadrant }
    }

    private var weatherLine: String? {
        let entries = pulse.entries
        guard
            let today = entries.last(where: { Calendar.current.isDateInToday($0.date) }),
            let yesterday = entries.last(where: { Calendar.current.isDateInYesterday($0.date) })
        else { return nil }

        let delta = today.resolvedPosition.energy - yesterday.resolvedPosition.energy
        if abs(delta) < 0.05 { return "About the same as yesterday" }
        return delta > 0 ? "Brighter than yesterday" : "A bit quieter today"
    }
}

// MARK: - Field map sheet

/// The "your map" panel — the PulseField fills the full sheet width so the zone
/// glows are one with the sheet surface. GeometryReader at the root gives a stable
/// width measurement without feedback loops.
private struct MapFieldSheet: View {
    let position: PulsePosition
    let quadrant: PulseQuadrant

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            // AppColors.void here is load-bearing: PulseField zone gradients fade to
            // .clear, which otherwise shows the semi-transparent modalBackground and
            // lets the Map tab content bleed through. Void blocks it and makes the
            // zone glows feel one with the surface.
            ZStack(alignment: .top) {
                AppColors.void
                ScrollView {
                    VStack(spacing: 0) {
                        PulseField(
                            entries: [PulseFieldEntry(position: position, auraSize: 60)],
                            size: w,
                            showAxisLabels: true
                        )
                        .padding(.top, AppSpacing.xs)

                        VStack(spacing: AppSpacing.xxs) {
                            Text(readCopy)
                                .font(AppFonts.display(15, weight: .semibold, relativeTo: .subheadline))
                                .foregroundStyle(AppColors.textPrimary)
                                .multilineTextAlignment(.center)
                            Text(descCopy)
                                .font(AppFonts.body(11, weight: .regular, relativeTo: .footnote))
                                .foregroundStyle(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.md)

                        Spacer(minLength: AppSpacing.xl)
                    }
                    .frame(minHeight: geo.size.height)
                }
            }
        }
    }

    private var readCopy: String {
        switch quadrant {
        case .expansive:  return "You're in an Expansive day"
        case .friction:   return "A Friction day"
        case .sovereign:  return "A Sovereign day"
        case .protective: return "A Protective day"
        }
    }

    private var descCopy: String {
        switch quadrant {
        case .expansive:  return "High energy and open. A good day to connect and explore."
        case .friction:   return "High energy, turned inward. Things feel charged right now."
        case .sovereign:  return "Grounded and open, moving at your own pace."
        case .protective: return "Low energy and guarded. You need space right now."
        }
    }
}

// MARK: - Preview

#Preview("Hero + sheet") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        ScrollView {
            VStack {
                MapPulseHero(onCheckIn: {}, onOpenHistory: {})
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.lg)
            }
        }
    }
    .environment({
        let s = PulseStore()
        return s
    }())
    .preferredColorScheme(.dark)
}

```

---

## File: `Vayl/Features/Map/Components/MapRecord.swift` {#file-vayl-features-map-components-maprecord-swift}

```swift
//
//  MapRecord.swift
//  Vayl
//
//  The Record (Me layer): a slim category-distribution bar over the recent-sessions
//  list, both derived from the couple's CardSession history (resolved to deck titles
//  + categories via the deck catalog). Empty state when there are no sessions yet.
//  Display-only; MapStore owns the data.
//

import SwiftUI

struct MapRecord: View {

    let sessions: [MapStore.RecordSession]
    let shares: [MapStore.CategoryShare]

    private var totalCount: Int { shares.reduce(0) { $0 + $1.count } }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            MapSectionHeader(title: "The Record")

            if sessions.isEmpty {
                MapEmptyState(
                    icon: "rectangle.stack",
                    headline: "No sessions yet",
                    message: "When you play a deck together, it lands here, and the Map begins to learn the shape of your conversations."
                )
                .vaylGlassCard()
            } else {
                let shown = Array(sessions.prefix(5))
                VStack(spacing: 0) {
                    distribution
                    ForEach(Array(shown.enumerated()), id: \.element.id) { idx, session in
                        row(session)
                        if idx < shown.count - 1 {
                            Rectangle()
                                .fill(AppColors.borderSubtle)
                                .frame(height: 1)
                        }
                    }
                }
                .vaylGlassCard()
            }
        }
    }

    // MARK: - Distribution bar

    private var distribution: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(shares) { share in
                        share.category.mapColor
                            .frame(width: max(2, geo.size.width * fraction(share.count)))
                    }
                }
            }
            .frame(height: 7)
            .clipShape(Capsule())

            Text(distributionCaption)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.md)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppColors.borderSubtle).frame(height: 1)
        }
    }

    private func fraction(_ count: Int) -> CGFloat {
        totalCount > 0 ? CGFloat(count) / CGFloat(totalCount) : 0
    }

    private var distributionCaption: String {
        let top = shares.prefix(2).map { $0.category.displayName }
        switch top.count {
        case 2...:  return "Where your conversations have gone · most in \(top[0]), then \(top[1])"
        case 1:     return "Where your conversations have gone · all in \(top[0])"
        default:    return "Where your conversations have gone"
        }
    }

    // MARK: - Session row

    private func row(_ s: MapStore.RecordSession) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Circle()
                .fill(s.category.mapColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(s.deckName)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textBody)
                HStack(spacing: AppSpacing.xs) {
                    Text(s.date, format: .relative(presentation: .named))
                    Text("·")
                    Text(s.category.displayName)
                }
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
            }

            Spacer()

            HStack(spacing: 3) {
                Text("\(s.cardCount)")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                Text("cards")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 2)
    }
}

```

---

## File: `Vayl/Features/Map/Components/MapUsLayer.swift` {#file-vayl-features-map-components-mapuslayer-swift}

```swift
// Features/Map/Components/MapUsLayer.swift
//
// The Us layer of the Map tab: two auras in a shared PulseField, enclosed by
// PulseCapsule, headline + copy derived from distance, and the 30-entry split grid.
//
// Visual reference: docs/prototypes/map-pulse-us.html — "A wide day" / "Same space".
//
// Layout contract (matches mockup proportions):
//   - The field fills the available content width (no hardcoded px).
//   - "You"/"Alex" tags are placed at 18% of fieldSize above/below the orb center.
//   - Copy is centered, 15pt Clash Display headline, 11pt body sublabel.
//   - VStack gaps are tight (xs) so the field dominates.

import SwiftUI

struct MapUsLayer: View {

    @Environment(PulseStore.self) private var pulse

    let stats:             MapStore.UsStats
    let align:             [MapStore.AlignItem]
    let lockedAlignCount:  Int
    var onOpenVault:       () -> Void
    var partnerPosition:   PulsePosition? = nil
    var partnerName:       String         = ""

    // MARK: - Derived state

    private var myPosition: PulsePosition {
        pulse.entries.last?.resolvedPosition ?? PulsePosition(energy: 0.5, openness: 0.5)
    }

    private var myQuadrant: PulseQuadrant { myPosition.quadrant }

    private var distance: Double {
        guard let partner = partnerPosition else { return 0 }
        return myPosition.distance(to: partner)
    }

    // "A wide day between you" vs "Close today" — FEEL: tune threshold on device.
    private var headline: String {
        guard partnerPosition != nil else { return "Pulse · together" }
        return distance > 0.45 ? "A wide day between you" : "Close today"
    }

    private var descCopy: String {
        guard let partner = partnerPosition else {
            return "Partner hasn't checked in yet today."
        }
        let pq = partner.quadrant
        let pName = partnerName.isEmpty ? "Your partner" : partnerName
        return "You're in the \(myQuadrant.spaceName); \(pName) is in the \(pq.spaceName)."
    }

    private var usGridPairs: [(mine: PulseQuadrant, partner: PulseQuadrant?)] {
        PulseHistory.pairedLastLogged(mine: pulse.entries, partner: [])
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .center, spacing: AppSpacing.xs) {
            fieldBlock
            copyBlock
            if !usGridPairs.isEmpty {
                PulseHistoryGrid(mode: .us(usGridPairs, partnerName: partnerName))
                    .padding(.top, AppSpacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Field block (fills available content width)

    private var fieldBlock: some View {
        // A clear square that fills the parent's width drives the field size.
        // GeometryReader reads the actual rendered width so PulseField + the
        // overlaid labels and capsule all share the same coordinate system.
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    let size = geo.size.width
                    ZStack {
                        PulseField(
                            entries: fieldEntries,
                            size: size,
                            showAxisLabels: true
                        )

                        if let partner = partnerPosition {
                            PulseCapsule(
                                myPosition:      myPosition,
                                partnerPosition: partner,
                                myColor:         myQuadrant.capacityColor.auraCore,
                                partnerColor:    partner.quadrant.capacityColor.auraCore,
                                fieldSize:       size
                            )
                            auraLabel("You",
                                      position: myPosition,
                                      color:    myQuadrant.capacityColor.auraCore,
                                      above:    true,
                                      fieldSize: size)
                            auraLabel(partnerName.isEmpty ? "Partner" : partnerName,
                                      position: partner,
                                      color:    partner.quadrant.capacityColor.auraCore,
                                      above:    false,
                                      fieldSize: size)
                        }
                    }
                    .frame(width: size, height: size)
                }
            }
    }

    private var fieldEntries: [PulseFieldEntry] {
        var entries: [PulseFieldEntry] = [
            PulseFieldEntry(id: "me", position: myPosition, auraSize: 44)
        ]
        if let partner = partnerPosition {
            entries.append(PulseFieldEntry(id: "partner", position: partner, auraSize: 44))
        }
        return entries
    }

    // Tag placed at 18% of fieldSize from the orb center — matches the mockup proportion.
    private func auraLabel(
        _ text:      String,
        position:    PulsePosition,
        color:       Color,
        above:       Bool,
        fieldSize:   CGFloat
    ) -> some View {
        let x  = position.openness * fieldSize
        let y  = (1 - position.energy) * fieldSize
        let dy = fieldSize * 0.18   // FEEL: tune vs the HTML mockup tag distance

        return Text(text)
            .font(.system(size: 9, weight: .bold))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(color)
            .position(x: x, y: y + (above ? -dy : dy))
    }

    // MARK: - Copy block

    private var copyBlock: some View {
        VStack(spacing: AppSpacing.xxs) {
            Text(headline)
                .font(AppFonts.display(15, weight: .semibold, relativeTo: .subheadline))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(descCopy)
                .font(AppFonts.body(11, weight: .regular, relativeTo: .footnote))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Wide day") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        ScrollView {
            MapUsLayer(
                stats: .init(),
                align: [],
                lockedAlignCount: 0,
                onOpenVault: {},
                partnerPosition: PulsePosition(energy: 0.18, openness: 0.22),
                partnerName: "Alex"
            )
            .padding(.horizontal, AppSpacing.lg)
        }
    }
    .environment({
        let s = PulseStore()
        return s
    }())
    .preferredColorScheme(.dark)
}

#Preview("Same space") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()
        ScrollView {
            MapUsLayer(
                stats: .init(),
                align: [],
                lockedAlignCount: 0,
                onOpenVault: {},
                partnerPosition: PulsePosition(energy: 0.78, openness: 0.72),
                partnerName: "Alex"
            )
            .padding(.horizontal, AppSpacing.lg)
        }
    }
    .environment({
        let s = PulseStore()
        return s
    }())
    .preferredColorScheme(.dark)
}

```

---

## File: `Vayl/Features/Map/Components/MeCardCompact.swift` {#file-vayl-features-map-components-mecardcompact-swift}

```swift
//
//  MeCardCompact.swift
//  Vayl
//
//  The title-led Me Card as it sits on the Me layer: flavor-tinted glass surface,
//  lattice portrait, name + chosen Title, flavor chip + essence, and the derived
//  "Drawn to" tags (shared ones glow). Tapping opens the full card + editor sheet.
//  Display-only; MapStore owns the data.
//

import SwiftUI

struct MeCardCompact: View {

    let card: MapStore.MeCard
    var onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("\(card.flavor.label) Type".uppercased())
                    .font(AppFonts.overline)
                    .tracking(1.0)
                    .foregroundStyle(AppColors.textTertiary)
                Spacer()
                Text("Edit")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }

            HStack(spacing: AppSpacing.md) {
                FlavorPortrait(size: 56)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(card.name)
                        .font(AppFonts.display(15, weight: .semibold, relativeTo: .subheadline))
                        .foregroundStyle(AppColors.textSecondary)
                    Text(card.title)
                        .font(AppFonts.display(20, weight: .bold, relativeTo: .title3))
                        .foregroundStyle(titleGradient)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    HStack(spacing: AppSpacing.sm) {
                        FlavorChip(flavor: card.flavor)
                        Text(card.flavor.essence)
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
            }

            if !card.tags.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Drawn to".uppercased())
                        .font(AppFonts.overline)
                        .tracking(1.0)
                        .foregroundStyle(AppColors.textTertiary)
                    FlowLayout(spacing: AppSpacing.xs) {
                        ForEach(card.tags) { tag in
                            DrawnTagChip(tag: tag, flavor: card.flavor)
                        }
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .vaylGlassCard(accent: card.flavor.color)
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }
    }

    private var titleGradient: LinearGradient {
        LinearGradient(
            colors: [.white, card.flavor.color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

```

---

## File: `Vayl/Features/Map/Vault/VaultSheet.swift` {#file-vayl-features-map-vault-vaultsheet-swift}

```swift
//
//  VaultSheet.swift
//  Vayl
//
//  The Vault, presented as a .vaylSheet from the Us layer. Segment 1 (foundation):
//  the header + the Desire Map / Agreements / Log segmented control over the shared
//  glass card. The Desire Map segment is live; Agreements and Log are forming-state
//  placeholders until Segments 2 and 3.
//

import SwiftUI

struct VaultSheet: View {

    @Bindable var store: VaultStore
    var onUnlock: () -> Void

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var logEditorOpen = false
    @State private var editingEntry: EventLogEntry? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("The Vault")
                        .font(AppFonts.sectionHeading)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("What the two of you have uncovered and agreed, held together, opened by consent.")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                LearnSegmented<VaultStore.Segment>(
                    items: [
                        .init(.desire, "Desire Map"),
                        .init(.agreements, "Agreements"),
                        .init(.log, "Log"),
                    ],
                    selection: $store.segment,
                    accent: AppColors.accentSecondary
                )

                section
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task(id: store.segment) {
            switch store.segment {
            case .agreements:
                await store.loadAgreements(appState: appState, context: modelContext)
            case .log:
                store.loadLog(context: modelContext)
                await store.syncLogDown(context: modelContext)
            case .desire:
                await store.loadConsent(appState: appState, context: modelContext)
            }
        }
        .vaylSheet(isPresented: $logEditorOpen, heightFraction: 0.9) {
            EventEntryEditor(entry: editingEntry, store: store, onDone: {
                logEditorOpen = false
                store.loadLog(context: modelContext)
            })
        }
        .vaylSheet(
            isPresented: Binding(
                get: { store.selectedDiscussionCard != nil },
                set: { if !$0 { store.closeDiscussion() } }
            ),
            heightFraction: 0.80
        ) {
            if let card = store.selectedDiscussionCard {
                DiscussionCardView(card: card, onDismiss: { store.closeDiscussion() })
            }
        }
    }

    @ViewBuilder
    private var section: some View {
        switch store.segment {
        case .desire:
            VaultDesireSection(
                summary: store.desire,
                align: store.align,
                lockedCount: store.lockedAlignCount,
                onUnlock: onUnlock,
                store: store
            )
        case .agreements:
            VaultAgreementsSection(store: store)
        case .log:
            VaultLogSection(
                entries: store.logEntries,
                onAdd: { editingEntry = nil; logEditorOpen = true },
                onEdit: { editingEntry = $0; logEditorOpen = true }
            )
        }
    }
}

```

---

## File: `Vayl/Features/Map/Vault/VaultStore.swift` {#file-vayl-features-map-vault-vaultstore-swift}

```swift
//
//  VaultStore.swift
//  Vayl
//
//  State owner for the Vault sheet (Map -> Us layer -> Vault). Segment 1 (foundation)
//  owns the segment selection + the Desire Map summary derived from local data.
//  Agreements, the Event Log, and the consent exchange extend this in later segments.
//  Spec: docs/superpowers/specs/2026-06-24-vault-design.md.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class VaultStore {

    enum Segment: String, CaseIterable {
        case desire, agreements, log
    }

    var segment: Segment = .desire
    var showPaywall = false

    // MARK: - Desire Map summary (Segment 1, local data)

    struct DesireSummary {
        var rated: Int = 0
        var yes: Int = 0       // excitedAboutIt
        var curious: Int = 0   // openToIt
        var kept: Int = 0      // notForMe (private)
    }

    private(set) var desire = DesireSummary()
    private(set) var align: [MapStore.AlignItem] = []
    private(set) var lockedAlignCount: Int = 0

    /// Builds the Desire Map summary from the user's local ratings + server matches,
    /// gated on `isCore` (the OR'd entitlement: server tier OR local StoreKit ownership),
    /// threaded in from the View. Idempotent; safe to re-run after a paywall unlock.
    func loadDesire(appState: AppState, context: ModelContext, isCore: Bool) async {
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else {
            desire = DesireSummary()
            align = []
            lockedAlignCount = 0
            return
        }

        let userId = profile.id
        let entries = (try? context.fetch(
            FetchDescriptor<DesireMapEntry>(predicate: #Predicate { $0.userId == userId })
        )) ?? []

        var summary = DesireSummary(rated: entries.count)
        for entry in entries {
            switch entry.rating {
            case .excitedAboutIt: summary.yes += 1
            case .openToIt:       summary.curious += 1
            case .notForMe:       summary.kept += 1
            default:              break
            }
        }
        desire = summary

        var revealed: [MapStore.AlignItem] = []
        var locked = 0
        if let coupleId = appState.coupleId {
            // Gate on the OR'd entitlement, not the local Couple mirror (which can lag a
            // just-purchased buyer and under-reveal the Vault while the reveal shows unlocked).
            let canReveal = isCore
            let rows = (try? await DesireSyncService.shared.fetchMatches(coupleId: coupleId)) ?? []
            let items = (try? ContentLoader.loadDesireItems()) ?? []
            let nameById = Dictionary(items.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
            for row in rows {
                if canReveal || row.isFreeReveal {
                    revealed.append(MapStore.AlignItem(
                        id: row.desireItemId,
                        name: nameById[row.desireItemId] ?? row.desireItemId,
                        isMutual: row.matchType == .mutual
                    ))
                } else {
                    locked += 1
                }
            }
        }
        align = revealed.sorted { $0.isMutual && !$1.isMutual }
        lockedAlignCount = locked
    }

    // MARK: - Agreements (Phase A: dual-lock, mutual approval to change)

    struct AgreementVM: Identifiable { let id: UUID; let text: String }

    struct ProposalVM: Identifiable {
        let id: UUID
        let action: String          // create | edit | retire
        let proposedText: String?
        let targetId: UUID?
        let mineToDecide: Bool      // true when my partner proposed it (I'm the approver)
    }

    private(set) var safeWord: String = "red"
    private(set) var agreements: [AgreementVM] = []
    private(set) var proposals: [ProposalVM] = []
    private let agreementsService = AgreementsService()

    /// Loads the shared safe word + active agreements + pending proposals.
    func loadAgreements(appState: AppState, context: ModelContext) async {
        guard let coupleId = appState.coupleId,
              let me = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        if let couple = try? context.fetch(
            FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
        ).first {
            safeWord = couple.sharedSafeWord
        }
        let rows = (try? await agreementsService.fetchAgreements(coupleId: coupleId)) ?? []
        let pending = (try? await agreementsService.fetchPendingProposals(coupleId: coupleId)) ?? []
        agreements = rows.filter(\.isActive).map { AgreementVM(id: $0.id, text: $0.text) }
        proposals = pending.map {
            ProposalVM(id: $0.id, action: $0.action, proposedText: $0.proposedText,
                       targetId: $0.targetAgreementId, mineToDecide: $0.proposedBy != me.id)
        }
    }

    /// Proposes a create / edit / retire. Takes effect only once the partner approves.
    func propose(action: String, text: String?, targetId: UUID?,
                 appState: AppState, context: ModelContext) async {
        guard let coupleId = appState.coupleId,
              let me = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        try? await agreementsService.propose(coupleId: coupleId, proposerId: me.id,
            action: action, targetAgreementId: targetId, text: text)
        await loadAgreements(appState: appState, context: context)
    }

    /// Approves or declines a pending proposal (the partner's decision).
    func decideProposal(_ proposalId: UUID, approve: Bool,
                        appState: AppState, context: ModelContext) async {
        try? await agreementsService.decide(proposalId: proposalId, approve: approve)
        await loadAgreements(appState: appState, context: context)
    }

    // MARK: - Event Log (Phase B: private or shared, local-first + synced)

    private(set) var logEntries: [EventLogEntry] = []
    private let eventLogService = EventLogService()

    /// Loads local entries (the source of truth), newest first.
    func loadLog(context: ModelContext) {
        logEntries = (try? context.fetch(
            FetchDescriptor<EventLogEntry>(sortBy: [SortDescriptor(\.occurredOn, order: .reverse)])
        )) ?? []
    }

    /// Creates or updates an entry locally, then pushes it up. `id == nil` creates.
    func saveEntry(id: UUID?, date: Date, title: String, note: String?,
                   mood: EventMood?, tags: [EventTag], who: String?,
                   visibility: EventVisibility, appState: AppState, context: ModelContext) {
        guard let me = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        let coupleId = visibility == .shared ? appState.coupleId : nil

        let entry: EventLogEntry
        if let id, let existing = logEntries.first(where: { $0.id == id }) {
            entry = existing
            entry.occurredOn = date
            entry.title = title
            entry.note = note
            entry.mood = mood?.rawValue
            entry.tags = tags.map(\.rawValue)
            entry.who = who
            entry.visibility = visibility.rawValue
            entry.coupleId = coupleId
            entry.updatedAt = Date()
        } else {
            entry = EventLogEntry(authorId: me.id, coupleId: coupleId, occurredOn: date,
                                  title: title, note: note, mood: mood?.rawValue,
                                  tags: tags.map(\.rawValue), who: who,
                                  visibility: visibility.rawValue)
            context.insert(entry)
        }
        try? context.save()
        loadLog(context: context)

        let payload = EventLogUpsert(
            id: entry.id.uuidString, author_id: entry.authorId.uuidString,
            couple_id: entry.coupleId?.uuidString,
            occurred_on: EventLogService.dayFormatter.string(from: entry.occurredOn),
            title: entry.title, note: entry.note, mood: entry.mood,
            tags: entry.tags, who: entry.who, visibility: entry.visibility)
        Task { try? await eventLogService.push(payload) }
    }

    func deleteEntry(_ entry: EventLogEntry, context: ModelContext) {
        let id = entry.id
        context.delete(entry)
        try? context.save()
        loadLog(context: context)
        Task { try? await eventLogService.delete(id: id) }
    }

    /// Pulls remote entries (own + shared) and upserts them into local SwiftData, so a
    /// new device restores your entries and the partner's shared entries appear.
    func syncLogDown(context: ModelContext) async {
        guard let rows = try? await eventLogService.pull() else { return }
        for row in rows {
            let rid = row.id
            let existing = (try? context.fetch(
                FetchDescriptor<EventLogEntry>(predicate: #Predicate { $0.id == rid })
            ))?.first
            let date = EventLogService.dayFormatter.date(from: row.occurredOn) ?? Date()
            if let e = existing {
                e.title = row.title; e.note = row.note; e.mood = row.mood
                e.tags = row.tags; e.who = row.who; e.visibility = row.visibility
                e.coupleId = row.coupleId; e.occurredOn = date
            } else {
                let e = EventLogEntry(authorId: row.authorId, coupleId: row.coupleId,
                                      occurredOn: date, title: row.title, note: row.note,
                                      mood: row.mood, tags: row.tags, who: row.who,
                                      visibility: row.visibility)
                e.id = rid
                context.insert(e)
            }
        }
        try? context.save()
        loadLog(context: context)
    }

    // MARK: - Consent exchange (Phase C: open a conversation; a decline never discloses)

    struct ConsentVM: Identifiable {
        let id: UUID
        let itemId: String
        let itemName: String
        let status: String          // pending | opened
        let iAmAsker: Bool
        let discussionCardId: String?
    }

    struct ConsentTopic: Identifiable {
        let id: String              // itemId
        let name: String
    }

    private(set) var myAsks: [ConsentVM] = []      // I asked, still pending (stays pending even if declined)
    private(set) var incoming: [ConsentVM] = []    // partner asked me, pending, not yet declined by me
    private(set) var openedConsent: [ConsentVM] = []
    private(set) var askableTopics: [ConsentTopic] = []
    private let consentService = ConsentService()

    func loadConsent(appState: AppState, context: ModelContext) async {
        guard let coupleId = appState.coupleId,
              let me = try? context.fetch(FetchDescriptor<UserProfile>()).first else {
            myAsks = []; incoming = []; openedConsent = []; askableTopics = []
            return
        }
        let items = (try? ContentLoader.loadDesireItems()) ?? []
        let nameById = Dictionary(items.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })

        let requests = (try? await consentService.fetchRequests(coupleId: coupleId)) ?? []
        let declines = (try? await consentService.fetchMyDeclines(coupleId: coupleId)) ?? []
        let declinedIds = Set(declines.map(\.itemId))
        let requestedIds = Set(requests.map(\.itemId))

        let all = requests.map { r in
            ConsentVM(id: r.id, itemId: r.itemId, itemName: nameById[r.itemId] ?? r.itemId,
                      status: r.status, iAmAsker: r.askerId == me.id, discussionCardId: r.discussionCardId)
        }
        openedConsent = all.filter { $0.status == "opened" }
        myAsks = all.filter { $0.status == "pending" && $0.iAmAsker }
        incoming = all.filter { $0.status == "pending" && !$0.iAmAsker && !declinedIds.contains($0.itemId) }

        // Askable: my positive local items with no request yet (a short, calm list).
        let userId = me.id
        let entries = (try? context.fetch(
            FetchDescriptor<DesireMapEntry>(predicate: #Predicate { $0.userId == userId })
        )) ?? []
        let positive = entries.filter { $0.rating == .excitedAboutIt || $0.rating == .openToIt }
        askableTopics = Array(
            positive
                .filter { !requestedIds.contains($0.itemId) }
                .map { ConsentTopic(id: $0.itemId, name: nameById[$0.itemId] ?? $0.itemId) }
                .sorted { $0.name < $1.name }
                .prefix(5)
        )
    }

    func askToOpen(itemId: String, appState: AppState, context: ModelContext) async {
        try? await consentService.ask(itemId: itemId)
        await loadConsent(appState: appState, context: context)
    }

    func respondToOpen(itemId: String, open: Bool, appState: AppState, context: ModelContext) async {
        try? await consentService.respond(itemId: itemId, open: open)
        await loadConsent(appState: appState, context: context)
    }

    // MARK: - Discussion card

    private let companionCardStore = CompanionCardStore()
    private(set) var selectedDiscussionCard: CompanionCard? = nil

    /// Opens the discussion card for a desire item at the given tier.
    func openDiscussion(itemId: String, itemName: String, tier: CompanionCardTier) {
        let card = companionCardStore.card(forItemId: itemId, tier: tier)
            ?? CompanionCard(
                id: "discussion_fallback_\(itemId)",
                desireItemId: itemId,
                title: itemName,
                prompt: "What would you want to explore together here?",
                suggestedDeckId: nil
            )
        selectedDiscussionCard = card
    }

    /// Clears the discussion card state.
    func closeDiscussion() {
        selectedDiscussionCard = nil
    }
}

```

---

## File: `Vayl/Features/Map/Vault/EventEntryEditor.swift` {#file-vayl-features-map-vault-evententryeditor-swift}

```swift
//
//  EventEntryEditor.swift
//  Vayl
//
//  Add / edit one Event Log entry, presented as a .vaylSheet from the Vault. Date,
//  what happened, how it felt (one mood, distinct from the Pulse), tags, who (free
//  text), notes, and a prominent private / shared toggle. Save writes through VaultStore
//  (local first, then sync). Free.
//

import SwiftUI

struct EventEntryEditor: View {

    let entry: EventLogEntry?
    let store: VaultStore
    var onDone: () -> Void

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var date: Date
    @State private var title: String
    @State private var note: String
    @State private var mood: EventMood?
    @State private var tags: Set<EventTag>
    @State private var who: String
    @State private var visibility: EventVisibility

    init(entry: EventLogEntry?, store: VaultStore, onDone: @escaping () -> Void) {
        self.entry = entry
        self.store = store
        self.onDone = onDone
        _date = State(initialValue: entry?.occurredOn ?? Date())
        _title = State(initialValue: entry?.title ?? "")
        _note = State(initialValue: entry?.note ?? "")
        _mood = State(initialValue: entry?.moodValue)
        _tags = State(initialValue: Set(entry?.tagValues ?? []))
        _who = State(initialValue: entry?.who ?? "")
        _visibility = State(initialValue: EventVisibility(rawValue: entry?.visibility ?? "private") ?? .onlyMe)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text(entry == nil ? "New entry" : "Edit entry")
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textPrimary)

                field("When") {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                        .tint(AppColors.accentPrimary)
                }
                field("What happened") {
                    TextField("A date, a night, a moment", text: $title)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(AppColors.textPrimary)
                }
                field("How it felt") { moodRow }
                field("Tags") { tagRow }
                field("Who") {
                    TextField("optional", text: $who)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(AppColors.textPrimary)
                }
                field("Notes") {
                    TextField("optional", text: $note, axis: .vertical)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(3...8)
                }
                field("Visibility") {
                    LearnSegmented<EventVisibility>(
                        items: [.init(.onlyMe, "Private"), .init(.shared, "Shared")],
                        selection: $visibility,
                        accent: AppColors.accentSecondary
                    )
                }
                Text(visibility == .onlyMe ? "Only you can ever see this." : "Shared with your partner.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)

                saveButton
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func field<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label.uppercased())
                .font(AppFonts.overline)
                .tracking(1.0)
                .foregroundStyle(AppColors.textTertiary)
            content()
        }
    }

    private var moodRow: some View {
        FlowLayout(spacing: AppSpacing.xs) {
            ForEach(EventMood.allCases) { m in
                chip(m.label, selected: mood == m) { mood = (mood == m ? nil : m) }
            }
        }
    }

    private var tagRow: some View {
        FlowLayout(spacing: AppSpacing.xs) {
            ForEach(EventTag.allCases) { t in
                chip(t.label, selected: tags.contains(t)) {
                    if tags.contains(t) { tags.remove(t) } else { tags.insert(t) }
                }
            }
        }
    }

    private func chip(_ label: String, selected: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(selected ? .white : AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs + 1)
                .background(Capsule().fill(selected ? AppColors.accentSecondary.opacity(0.25) : AppColors.glassSurface))
                .overlay(Capsule().strokeBorder(selected ? AppColors.accentSecondary.opacity(0.55) : AppColors.borderSubtle, lineWidth: 1))
        }
        .buttonStyle(PressableCardStyle())
    }

    private var saveButton: some View {
        let blank = title.trimmingCharacters(in: .whitespaces).isEmpty
        return Button {
            store.saveEntry(
                id: entry?.id, date: date, title: title,
                note: note.isEmpty ? nil : note, mood: mood,
                tags: Array(tags), who: who.isEmpty ? nil : who,
                visibility: visibility, appState: appState, context: modelContext)
            onDone()
        } label: {
            Text("Save")
                .font(AppFonts.buttonLabel)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(Capsule().fill(AppColors.accentSecondary))
        }
        .buttonStyle(PressableCardStyle())
        .disabled(blank)
        .opacity(blank ? 0.5 : 1)
    }
}

```

---

## File: `Vayl/Features/Map/Vault/Components/VaultDesireSection.swift` {#file-vayl-features-map-vault-components-vaultdesiresection-swift}

```swift
//
//  VaultDesireSection.swift
//  Vayl
//
//  The Vault's Desire Map segment (Segment 1): your private map summary, where you
//  align (revealed mutual/adjacent), a locked-more paywall row, and a placeholder for
//  the consent exchange (Segment 4). Display-only; VaultStore owns the data.
//
//  NOTE: the align row + match badge below intentionally mirror MapUsLayer's; factor
//  into one shared component during the Segment 6 cohesion sweep.
//

import SwiftUI

struct VaultDesireSection: View {

    let summary: VaultStore.DesireSummary
    let align: [MapStore.AlignItem]
    let lockedCount: Int
    var onUnlock: () -> Void
    let store: VaultStore

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            yourMap
            whereYouAlign
            openAConversation
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Your map

    private var yourMap: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            MapSectionHeader(title: "Your map")
            if summary.rated == 0 {
                MapEmptyState(
                    icon: "circle.grid.2x2",
                    headline: "Your map is empty",
                    message: "Complete your Desire Map and your private summary appears here."
                )
                .vaylGlassCard()
            } else {
                VStack(spacing: AppSpacing.sm) {
                    HStack(spacing: AppSpacing.sm) {
                        countChip("\(summary.rated)", "rated")
                        countChip("\(summary.yes)", "yes", tint: AppColors.spectrumCyan)
                        countChip("\(summary.curious)", "curious", tint: AppColors.spectrumBridge)
                        countChip("\(summary.kept)", "private", tint: AppColors.textTertiary)
                    }
                }
                .padding(AppSpacing.md)
                .vaylGlassCard()

                Text("Only you ever see what you keep private.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }

    private func countChip(_ value: String, _ label: String, tint: Color = AppColors.textPrimary) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppFonts.display(18, weight: .bold, relativeTo: .title3))
                .foregroundStyle(tint)
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Where you align

    private var whereYouAlign: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            MapSectionHeader(title: "Where you align")
            if align.isEmpty {
                MapEmptyState(
                    icon: "diamond",
                    headline: "No matches yet",
                    message: "Revealed together, the overlap appears here, only ever the overlap, never the gaps."
                )
                .vaylGlassCard()
            } else {
                let shown = Array(align.prefix(6))
                VStack(spacing: 0) {
                    ForEach(Array(shown.enumerated()), id: \.element.id) { idx, item in
                        alignRow(item)
                        if idx < shown.count - 1 {
                            Rectangle().fill(AppColors.borderSubtle).frame(height: 1)
                        }
                    }
                    if lockedCount > 0 { lockedRow }
                }
                .vaylGlassCard()
            }
        }
    }

    private func alignRow(_ item: MapStore.AlignItem) -> some View {
        let tier: CompanionCardTier = item.isMutual ? .mutual : .adjacent
        return Button {
            store.openDiscussion(itemId: item.id, itemName: item.name, tier: tier)
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "diamond")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppColors.spectrumBridge)
                Text(item.name)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textBody)
                Spacer()
                badge(item.isMutual)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm + 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableCardStyle())
    }

    private func badge(_ isMutual: Bool) -> some View {
        let tint = isMutual ? AppColors.spectrumCyan : AppColors.spectrumBridge
        return Text(isMutual ? "Mutual" : "Adjacent")
            .font(AppFonts.overline)
            .tracking(0.4)
            .foregroundStyle(tint)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xxs + 1)
            .background(Capsule().fill(tint.opacity(0.12)))
            .overlay(Capsule().strokeBorder(tint.opacity(0.3), lineWidth: 1))
    }

    private var lockedRow: some View {
        Button(action: onUnlock) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "lock")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppColors.textTertiary)
                Text("\(lockedCount) more where you align")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Text("Unlock the full map")
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.accentPrimary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm + 2)
            .overlay(alignment: .top) {
                Rectangle().fill(AppColors.borderSubtle).frame(height: 1)
            }
        }
        .buttonStyle(PressableCardStyle())
    }

    // MARK: - Open a conversation (Segment 4 placeholder)

    private var openAConversation: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            MapSectionHeader(title: "Open a conversation")

            let isEmpty = store.incoming.isEmpty && store.openedConsent.isEmpty
                && store.myAsks.isEmpty && store.askableTopics.isEmpty
            if isEmpty {
                MapEmptyState(
                    icon: "bubble.left.and.bubble.right",
                    headline: "Nothing to open yet",
                    message: "When you're curious about something private, ask to open it together here. A decline never discloses."
                )
                .vaylGlassCard()
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(store.incoming) { incomingCard($0) }
                    ForEach(store.openedConsent) { openedRow($0) }
                    ForEach(store.myAsks) { waitingRow($0) }
                    ForEach(store.askableTopics) { askRow($0) }
                }
            }
        }
    }

    private func incomingCard(_ c: VaultStore.ConsentVM) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Your partner asked to open this together")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
            Text(c.itemName)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textPrimary)
            Text("Open it and a neutral card appears for you both. Pass, and they are never told it was a no.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: AppSpacing.sm) {
                Button("Not now") { respond(c, open: false) }
                    .buttonStyle(.plain)
                    .font(AppFonts.buttonLabelSmall)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Button("Open it") { respond(c, open: true) }
                    .buttonStyle(PressableCardStyle())
                    .font(AppFonts.buttonLabelSmall)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.xs + 1)
                    .background(Capsule().fill(AppColors.accentSecondary.opacity(0.85)))
            }
        }
        .padding(AppSpacing.md)
        .vaylGlassCard(accent: AppColors.accentSecondary)
    }

    private func openedRow(_ c: VaultStore.ConsentVM) -> some View {
        Button {
            store.openDiscussion(itemId: c.itemId, itemName: c.itemName, tier: .consentOpened)
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.spectrumCyan)
                VStack(alignment: .leading, spacing: 1) {
                    Text(c.itemName).font(AppFonts.bodyMedium).foregroundStyle(AppColors.textBody)
                    Text("Opened together").font(AppFonts.caption).foregroundStyle(AppColors.spectrumCyan)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(AppSpacing.md)
            .contentShape(Rectangle())
            .vaylGlassCard()
        }
        .buttonStyle(PressableCardStyle())
    }

    private func waitingRow(_ c: VaultStore.ConsentVM) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "clock")
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textTertiary)
            VStack(alignment: .leading, spacing: 1) {
                Text(c.itemName).font(AppFonts.bodyMedium).foregroundStyle(AppColors.textBody)
                Text("Asked, waiting").font(AppFonts.caption).foregroundStyle(AppColors.textTertiary)
            }
            Spacer()
        }
        .padding(AppSpacing.md)
        .vaylGlassCard()
    }

    private func askRow(_ t: VaultStore.ConsentTopic) -> some View {
        HStack(spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 1) {
                Text(t.name).font(AppFonts.bodyMedium).foregroundStyle(AppColors.textBody)
                Text("You're curious. Ask to open it together.")
                    .font(AppFonts.caption).foregroundStyle(AppColors.textTertiary)
            }
            Spacer()
            Button("Ask") { ask(t.id) }
                .buttonStyle(PressableCardStyle())
                .font(AppFonts.buttonLabelSmall)
                .foregroundStyle(.white)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs + 1)
                .background(Capsule().fill(AppColors.accentSecondary.opacity(0.85)))
        }
        .padding(AppSpacing.md)
        .vaylGlassCard()
    }

    private func ask(_ itemId: String) {
        Task { await store.askToOpen(itemId: itemId, appState: appState, context: modelContext) }
    }

    private func respond(_ c: VaultStore.ConsentVM, open: Bool) {
        Task { await store.respondToOpen(itemId: c.itemId, open: open, appState: appState, context: modelContext) }
    }
}

```

---

## File: `Vayl/Features/Map/Vault/Components/VaultAgreementsSection.swift` {#file-vayl-features-map-vault-components-vaultagreementssection-swift}

```swift
//
//  VaultAgreementsSection.swift
//  Vayl
//
//  The Vault's Agreements segment (Phase A): the shared safe word, pending proposals
//  (the dual lock, you approve your partner's, they approve yours), the active list,
//  and an inline propose / edit / retire flow. Every change is a proposal that takes
//  effect only once both agree. Free. VaultStore owns the data + the async actions.
//

import SwiftUI

struct VaultAgreementsSection: View {

    @Bindable var store: VaultStore
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var composingNew = false
    @State private var newText = ""
    @State private var editingId: UUID? = nil
    @State private var editText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            safeWordCard
            pendingProposals
            activeAgreements
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Safe word

    private var safeWordCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            MapSectionHeader(title: "Shared safe word")
            HStack {
                Text(store.safeWord)
                    .font(AppFonts.display(20, weight: .bold, relativeTo: .title2))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Image(systemName: "lifepreserver")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(AppColors.safetyAccent)
            }
            .padding(AppSpacing.md)
            .vaylGlassCard(accent: AppColors.safetyAccent)
        }
    }

    // MARK: - Pending proposals (the dual lock)

    @ViewBuilder
    private var pendingProposals: some View {
        if !store.proposals.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                MapSectionHeader(title: "Awaiting agreement")
                VStack(spacing: 0) {
                    ForEach(Array(store.proposals.enumerated()), id: \.element.id) { idx, p in
                        proposalRow(p)
                        if idx < store.proposals.count - 1 {
                            Rectangle().fill(AppColors.borderSubtle).frame(height: 1)
                        }
                    }
                }
                .vaylGlassCard(accent: AppColors.accentSecondary)
            }
        }
    }

    private func proposalRow(_ p: VaultStore.ProposalVM) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(proposalLabel(p))
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textBody)
                .fixedSize(horizontal: false, vertical: true)
            if p.mineToDecide {
                HStack(spacing: AppSpacing.sm) {
                    Button("Not now") { decide(p, approve: false) }
                        .buttonStyle(.plain)
                        .font(AppFonts.buttonLabelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Button("Approve") { decide(p, approve: true) }
                        .buttonStyle(PressableCardStyle())
                        .font(AppFonts.buttonLabelSmall)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs + 1)
                        .background(Capsule().fill(AppColors.accentSecondary.opacity(0.85)))
                }
            } else {
                Text("Awaiting your partner")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.md)
    }

    private func proposalLabel(_ p: VaultStore.ProposalVM) -> String {
        switch p.action {
        case "create": return "New agreement: \(p.proposedText ?? "")"
        case "edit":   return "Change to: \(p.proposedText ?? "")"
        case "retire": return "Retire an agreement"
        default:       return "A proposed change"
        }
    }

    // MARK: - Active agreements + propose

    private var activeAgreements: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            MapSectionHeader(title: "Agreements")
            if store.agreements.isEmpty && !composingNew {
                VStack(spacing: 0) {
                    MapEmptyState(
                        icon: "doc.text",
                        headline: "No agreements yet",
                        message: "Propose one. It becomes active once you both agree, and changing it later needs you both too."
                    )
                    composeRow
                }
                .vaylGlassCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(store.agreements) { a in
                        agreementRow(a)
                        Rectangle().fill(AppColors.borderSubtle).frame(height: 1)
                    }
                    composeRow
                }
                .vaylGlassCard()
            }
        }
    }

    private func agreementRow(_ a: VaultStore.AgreementVM) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(a.text)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
                .fixedSize(horizontal: false, vertical: true)
            if editingId == a.id {
                TextField("New wording", text: $editText, axis: .vertical)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textPrimary)
                HStack {
                    Button("Cancel") { editingId = nil }
                        .font(AppFonts.buttonLabelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Button("Propose change") {
                        propose(action: "edit", text: editText, target: a.id)
                        editingId = nil
                    }
                    .font(AppFonts.buttonLabelSmall)
                    .foregroundStyle(AppColors.accentPrimary)
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: AppSpacing.lg) {
                    Button("Propose change") { editingId = a.id; editText = a.text }
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.accentSecondary)
                    Button("Retire") { propose(action: "retire", text: nil, target: a.id) }
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.md)
    }

    private var composeRow: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if composingNew {
                TextField("Propose an agreement", text: $newText, axis: .vertical)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textPrimary)
                HStack {
                    Button("Cancel") { composingNew = false; newText = "" }
                        .font(AppFonts.buttonLabelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Button("Propose") {
                        propose(action: "create", text: newText, target: nil)
                        composingNew = false; newText = ""
                    }
                    .font(AppFonts.buttonLabelSmall)
                    .foregroundStyle(AppColors.accentPrimary)
                    .disabled(newText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .buttonStyle(.plain)
            } else {
                Button { composingNew = true } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "plus")
                        Text("Propose an agreement")
                    }
                    .font(AppFonts.buttonLabelSmall)
                    .foregroundStyle(AppColors.accentSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.md)
    }

    // MARK: - Actions

    private func propose(action: String, text: String?, target: UUID?) {
        Task {
            await store.propose(action: action, text: text, targetId: target,
                                appState: appState, context: modelContext)
        }
    }

    private func decide(_ p: VaultStore.ProposalVM, approve: Bool) {
        Task {
            await store.decideProposal(p.id, approve: approve,
                                       appState: appState, context: modelContext)
        }
    }
}

```

---

## File: `Vayl/Features/Map/Vault/Components/VaultLogSection.swift` {#file-vayl-features-map-vault-components-vaultlogsection-swift}

```swift
//
//  VaultLogSection.swift
//  Vayl
//
//  The Vault's Log segment (Phase B): a newest-first timeline of event entries with a
//  per-entry private / shared marker, mood, who, and tags. Tapping an entry edits it;
//  "Add" opens the editor. Display-only; VaultStore owns the data, the editor writes.
//

import SwiftUI

struct VaultLogSection: View {

    let entries: [EventLogEntry]
    var onAdd: () -> Void
    var onEdit: (EventLogEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            MapSectionHeader(title: "Your log", linkLabel: "Add", onLink: onAdd)

            if entries.isEmpty {
                MapEmptyState(
                    icon: "book",
                    headline: "No entries yet",
                    message: "Log a date, a night, a feeling. Keep it private, or share it with your partner."
                )
                .vaylGlassCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { idx, e in
                        row(e)
                        if idx < entries.count - 1 {
                            Rectangle().fill(AppColors.borderSubtle).frame(height: 1)
                        }
                    }
                }
                .vaylGlassCard()
            }
        }
    }

    private func row(_ e: EventLogEntry) -> some View {
        Button { onEdit(e) } label: {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(alignment: .top) {
                    Text(e.title)
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textBody)
                    Spacer()
                    Image(systemName: e.isShared ? "person.2.fill" : "lock.fill")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(AppColors.textTertiary)
                }

                HStack(spacing: AppSpacing.xs) {
                    Text(e.occurredOn, format: .dateTime.month().day())
                    if let m = e.moodValue { Text("·"); Text(m.label) }
                    if let who = e.who, !who.isEmpty { Text("·"); Text(who) }
                }
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)

                if !e.tagValues.isEmpty {
                    HStack(spacing: AppSpacing.xs) {
                        ForEach(e.tagValues) { t in
                            Text(t.label)
                                .font(AppFonts.overline)
                                .foregroundStyle(AppColors.textSecondary)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(AppColors.glassSurface))
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

```

---

## File: `Vayl/Features/Map/Vault/Components/DiscussionCardView.swift` {#file-vayl-features-map-vault-components-discussioncardview-swift}

```swift
//
//  DiscussionCardView.swift
//  Vayl
//
//  Renders a companion discussion card: the desire item name as context above,
//  then a ConversationCard showing the tier-appropriate prompt.
//  Hosted as a .vaylSheet from VaultSheet. Never forked -- reuses ConversationCard.
//

import SwiftUI

struct DiscussionCardView: View {

    let card: CompanionCard
    var onDismiss: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Context header
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("Talk about this")
                    .font(AppFonts.overline)
                    .tracking(1.0)
                    .foregroundStyle(AppColors.textTertiary)
                Text(card.title)
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)

            // Prompt card
            ConversationCard(
                content: .prompt(card.prompt),
                fuseConfig: .none,
                ghostDeckMode: .none,
                onContinue: onDismiss
            )
            .padding(.horizontal, AppSpacing.md)

            Spacer(minLength: AppSpacing.lg)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.void.ignoresSafeArea())
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Mutual prompt") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        DiscussionCardView(
            card: CompanionCard(
                id: "preview-mutual",
                desireItemId: "desire-001",
                title: "New Relationship Energy",
                prompt: "What part of this feels most exciting to you?",
                suggestedDeckId: nil
            )
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Consent opened prompt") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        DiscussionCardView(
            card: CompanionCard(
                id: "preview-consent",
                desireItemId: "desire-007",
                title: "Overnight Stays",
                prompt: "No rush here. Where would you want to start?",
                suggestedDeckId: nil
            )
        )
    }
    .preferredColorScheme(.dark)
}
#endif

```

---

## File: `Vayl/Features/Sessions/AirlockView.swift` {#file-vayl-features-sessions-airlockview-swift}

```swift
//
//  AirlockView.swift
//  Vayl
//
//  Screen 1 of the couple session cover: the airlock.
//  House rules fold into a 2x2, your bandwidth is a private segmented reading,
//  and the lock-in is the hold-and-release sync ring — both hold, the ring
//  fills, both release at close-enough points. Off → reset. In sync → the
//  phones-down transition, then the first card.
//
//  Faithful to docs/prototypes/couple-session-airlock.html. The both-release
//  tolerance is the friction that keeps it honest: forgiving for two people in
//  a room, not fakeable solo. Partner presence + the partner release point are
//  mocked in the store for now (no Realtime).
//

import SwiftUI

struct AirlockView: View {

    @Bindable var store: CoupleSessionStore

    @Environment(\.vaylDismiss) private var vaylDismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Ring rendering geometry (rendering constants, like ScoreRing).
    private let ringSize: CGFloat = 156
    private let ringRadius: CGFloat = 62
    private let fillSeconds: Double = 3.2
    private let tolerance: CGFloat = 0.13

    private enum SyncPhase { case waiting, ready, holding, synced, miss }
    @State private var syncPhase: SyncPhase = .waiting
    @State private var fill: CGFloat = 0
    @State private var holding = false
    @State private var youFraction: CGFloat = 0
    @State private var partnerFraction: CGFloat = 0
    @State private var ringAlive = false
    @State private var glowBreathe = false
    @State private var showSyncTutorial = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Text("Before we start")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.top, AppSpacing.md)

            rulesGrid
                .padding(.top, AppSpacing.md)

            syncArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.xxl)
        .padding(.bottom, AppSpacing.xl)
        .onAppear { store.armPresence() }
        .onChange(of: store.partnerPresent) { _, present in
            if present, syncPhase == .waiting {
                withAnimation(AppAnimation.slow) { syncPhase = .ready }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { vaylDismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(AppColors.cardBackground))
                    .overlay(Circle().strokeBorder(AppColors.borderDefault, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("The Opener · \(store.hand.count) \(store.hand.count == 1 ? "card" : "cards") · ~\(max(1, store.hand.count * 2)) min")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    // MARK: - 2x2 rules grid

    private var rulesGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: AppSpacing.sm),
            GridItem(.flexible(), spacing: AppSpacing.sm)
        ]
        return LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
            ruleBox(title: "Take your time",
                    sub: "Silence is fine. Both of you answer, every card.")
            ruleBox(title: "Listen first",
                    sub: "Say what you heard before it's your turn.")
            ruleBox(title: "No fixing",
                    sub: "Just get each other. Pass anytime. It stays here.")
            bandwidthBox
        }
    }

    private func ruleBox(title: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Circle()
                .fill(AppColors.spectrumBorder)
                .frame(width: 8, height: 8)
            Spacer(minLength: 0)
            Text(title)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textBody)
            Text(sub)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .padding(AppSpacing.md)
        .background(boxBackground)
    }

    private var bandwidthBox: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Your pulse")
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textBody)
            Text("how much you've got tonight · shared")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
            Spacer(minLength: 0)
            HStack(spacing: AppSpacing.xs) {
                ForEach(CoupleSessionStore.Bandwidth.allCases, id: \.self) { b in
                    bandwidthChip(b)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .padding(AppSpacing.md)
        .background(boxBackground)
    }

    private func bandwidthChip(_ b: CoupleSessionStore.Bandwidth) -> some View {
        let selected = store.bandwidth == b
        return Text(b.label)
            .font(AppFonts.buttonLabelSmall)
            .textCase(.uppercase)
            .foregroundStyle(selected ? AppColors.void : AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .fill(selected ? AnyShapeStyle(AppColors.spectrumBorder)
                                   : AnyShapeStyle(Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .strokeBorder(AppColors.borderDefault, lineWidth: selected ? 0 : 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                UISelectionFeedbackGenerator().selectionChanged()
                withAnimation(AppAnimation.fast) { store.setBandwidth(b) }
            }
    }

    private var boxBackground: some View {
        RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
            .fill(AppColors.cardBg)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
                    .strokeBorder(AppColors.spectrumBorder.opacity(0.4), lineWidth: 0.8)
            )
    }

    // MARK: - Sync ring

    private var syncArea: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                Spacer()
                Button { showSyncTutorial = true } label: {
                    Image(systemName: "info.circle")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("How syncing works")
            }

            Spacer(minLength: 0)

            ring
                .opacity(syncPhase == .waiting ? 0.32 : 1)
                .animation(AppAnimation.slow, value: syncPhase)

            Text(syncMessage)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
                .multilineTextAlignment(.center)
                .frame(minHeight: 22)

            presenceRow
        }
        .vaylSheet(isPresented: $showSyncTutorial, heightFraction: 0.55) { syncTutorialSheet }
    }

    // MARK: - Sync tutorial sheet

    private var syncTutorialSheet: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.xs) {
                Text("Syncing to begin")
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textPrimary)
                Text("A shared breath, on both phones at once.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            HStack(spacing: AppSpacing.md) {
                tutorialPhone
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundStyle(AppColors.textTertiary)
                tutorialPhone
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                tutorialStep(1, "Both of you press and hold. Each ring fills.")
                tutorialStep(2, "On a shared count, release at the same time.")
                tutorialStep(3, "Land close enough and you're in. Off, and it resets.")
            }

            Button { showSyncTutorial = false } label: {
                Text("Got it")
                    .font(AppFonts.ctaLabel)
                    .foregroundStyle(AppColors.textBody)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            .strokeBorder(AppColors.spectrumBorder.opacity(0.4), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.lg)
        .padding(.top, AppSpacing.sm)        // grabber (in .vaylSheet) supplies the top gap
    }

    private var tutorialPhone: some View {
        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
            .fill(AppColors.cardBg)
            .frame(width: 76, height: 138)
            .overlay(
                Circle()
                    .strokeBorder(AppColors.spectrumBorder, lineWidth: 3)
                    .frame(width: 44, height: 44)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(AppColors.borderDefault, lineWidth: 1)
            )
    }

    private func tutorialStep(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Text("\(n)")
                .font(AppFonts.buttonLabelSmall)
                .foregroundStyle(AppColors.textBody)
                .frame(width: 20, height: 20)
                .overlay(Circle().strokeBorder(AppColors.borderDefault, lineWidth: 1))
            Text(text)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
        }
    }

    private var ring: some View {
        ZStack {
            // Track
            Circle()
                .stroke(AppColors.textPrimary.opacity(0.10), lineWidth: 4)

            // Breathing glow when ready
            Circle()
                .stroke(AppColors.spectrumBorder, lineWidth: 13)
                .blur(radius: 7)
                .opacity(ringAlive && (syncPhase == .ready || syncPhase == .synced)
                         ? (glowBreathe ? 0.85 : 0.4) : 0)
                .ambientAnimation(
                    .easeInOut(duration: AppAnimation.ambientPulse * 1.5).repeatForever(autoreverses: true),
                    value: glowBreathe
                )

            // Progress arc
            Circle()
                .trim(from: 0, to: fill)
                .stroke(AppColors.spectrumBorder,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Release markers
            if syncPhase == .synced || syncPhase == .miss {
                marker(at: youFraction, color: AppColors.textBody)
                marker(at: partnerFraction, color: AppColors.spectrumMagenta)
            }

            Text(ringHint)
                .font(AppFonts.overline)
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(width: ringSize, height: ringSize)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in startHold() }
                .onEnded { _ in endHold() }
        )
        .onChange(of: syncPhase) { _, phase in
            ringAlive = (phase == .ready || phase == .synced)
            if ringAlive { glowBreathe = true }
        }
    }

    private func marker(at fraction: CGFloat, color: Color) -> some View {
        let angle = (-90 + Double(fraction) * 360) * .pi / 180
        let r = ringRadius
        let x = ringSize / 2 + r * CGFloat(cos(angle))
        let y = ringSize / 2 + r * CGFloat(sin(angle))
        return Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .position(x: x, y: y)
    }

    private var presenceRow: some View {
        HStack(spacing: AppSpacing.lg) {
            presenceChip(name: "You", detail: store.bandwidth.label, present: true, you: true)
            presenceChip(name: "Partner",
                         detail: store.partnerPresent ? store.partnerBandwidth.label : nil,
                         present: store.partnerPresent, you: false)
        }
    }

    private func presenceChip(name: String, detail: String?, present: Bool, you: Bool) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Circle()
                .fill(present
                      ? AnyShapeStyle(you
                            ? LinearGradient(colors: [AppColors.spectrumCyan, AppColors.accentSecondary],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [AppColors.spectrumMagenta, AppColors.accentSecondary],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                      : AnyShapeStyle(Color.clear))
                .frame(width: 8, height: 8)
                .overlay(Circle().strokeBorder(AppColors.textTertiary, lineWidth: present ? 0 : 1.3))
                .opacity(present ? 1 : (waitingPulse ? 1 : 0.35))
                .ambientAnimation(
                    .easeInOut(duration: AppAnimation.ambientPulse / 1.5).repeatForever(autoreverses: true),
                    value: waitingPulse
                )
            Text(detail != nil ? "\(name) · \(detail!)" : name)
                .font(AppFonts.caption)
                .foregroundStyle(present ? AppColors.textBody : AppColors.textSecondary)
        }
        .onAppear { waitingPulse = true }
    }

    @State private var waitingPulse = false

    // MARK: - Copy

    private var syncMessage: String {
        switch syncPhase {
        case .waiting: return "waiting for your partner to join…"
        case .ready:   return "hold, then release together"
        case .holding: return "hold…"
        case .synced:  return "you're in sync"
        case .miss:    return "release at the same time, try again"
        }
    }

    private var ringHint: String {
        switch syncPhase {
        case .waiting, .ready: return "hold"
        case .holding:         return "release"
        case .synced:          return "in sync"
        case .miss:            return "almost"
        }
    }

    // MARK: - Hold / release mechanic

    private func startHold() {
        guard syncPhase == .ready, !holding else { return }
        holding = true
        syncPhase = .holding
        fill = 0
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        let start = Date()
        Task { @MainActor in
            while holding {
                let elapsed = Date().timeIntervalSince(start)
                fill = min(1, CGFloat(elapsed / fillSeconds))
                if fill >= 1 {
                    holding = false
                    tooLong()
                    break
                }
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func endHold() {
        guard holding else { return }
        holding = false
        release(at: fill)
    }

    private func release(at fraction: CGFloat) {
        youFraction = fraction
        // Mock the partner's release point near yours (Realtime later).
        let offset = CGFloat.random(in: -0.10...0.10)
        partnerFraction = max(0.05, min(0.97, fraction + offset))

        if abs(youFraction - partnerFraction) <= tolerance {
            synced()
        } else {
            miss()
        }
    }

    private func synced() {
        syncPhase = .synced
        withAnimation(AppAnimation.standard) { fill = 1 }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.1))
            store.confirmSynced()
        }
    }

    private func miss() {
        syncPhase = .miss
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        resetRingAfterBeat()
    }

    private func tooLong() {
        syncPhase = .miss
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        resetRingAfterBeat()
    }

    private func resetRingAfterBeat() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(AppAnimation.standard) { fill = 0 }
            youFraction = 0
            partnerFraction = 0
            if store.partnerPresent { syncPhase = .ready }
        }
    }
}

// MARK: - Preview

#Preview("Airlock") {
    ZStack {
        SessionAtmosphere()
        AirlockView(store: CoupleSessionStore(
            hand: Array(Card.samples.prefix(8)),
            modelContainer: .previewContainer,
            appState: AppState()
        ))
    }
    .preferredColorScheme(.dark)
}

```

---

## File: `Vayl/App/Theme/AppColors.swift` {#file-vayl-app-theme-appcolors-swift}

```swift
// App/Theme/AppColors.swift

import SwiftUI

// ─────────────────────────────────────────────────────────────
// Tier 2 — Semantic color tokens.
//
// Rules:
//   • Every token has ONE name describing purpose, not appearance
//   • Every token resolves automatically for light and dark via
//     UIColor(dynamicProvider:) — no manual branching in views
//   • Every token maps exclusively to VaylPrimitives values
//   • Every token has a one-line use context comment
//   • VaylPrimitives is NEVER referenced outside this file
//
// Light = Dawn mode   (warm cream, refractive atmosphere)
// Dark  = Midnight mode (deep ink, emissive glows)
// ─────────────────────────────────────────────────────────────

struct AppColors {

    // ─────────────────────────────────────────────
    // MARK: Backgrounds — elevation hierarchy
    //
    // Page → Card → Modal. Never nest a higher
    // elevation color inside a lower one.
    // ─────────────────────────────────────────────

    /// Root view background. One per screen, never nested.
    static let pageBackground = Color.dynamic(
        light: VaylPrimitives.warmCream,
        dark:  VaylPrimitives.inkBase
    )

    /// Content containers that sit directly on pageBackground.
    static let cardBackground = Color.dynamic(
        light: VaylPrimitives.pureWhite,
        dark:  VaylPrimitives.inkCard
    )

    /// Second-tier elevated cards that sit on cardBackground.
    static let cardBackgroundRaised = Color.dynamic(
        light: VaylPrimitives.roseWhite,
        dark:  VaylPrimitives.inkCardRaised
    )

    /// Sheets, modals, overlays. Always sits above cardBackground.
    static let modalBackground = Color.dynamic(
        light: VaylPrimitives.pureWhite,
        dark:  VaylPrimitives.inkSurface
    )

    /// Holographic shimmer pill base. HolographicShimmer use only.
    static let shimmerBase    = Color(uiColor: VaylPrimitives.inkShimmerBase)
    /// Dark muted orb colours — not the vivid spectrum anchors. HolographicShimmer use only.
    static let shimmerViolet  = Color(uiColor: VaylPrimitives.inkShimmerViolet)
    static let shimmerCyan    = Color(uiColor: VaylPrimitives.inkShimmerCyan)
    static let shimmerPurple  = Color(uiColor: VaylPrimitives.inkShimmerPurple)
    static let shimmerMagenta = Color(uiColor: VaylPrimitives.inkShimmerMagenta)
    static let shimmerIndigo  = Color(uiColor: VaylPrimitives.inkShimmerIndigo)

    /// Input fields and inset wells. Recessed below pageBackground.
    static let inputBackground = Color.dynamic(
        light: VaylPrimitives.offWhite,
        dark:  VaylPrimitives.inkRaised
    )

    /// Home widget base layers only. Between page and card elevation.
    static let widgetBackground = Color.dynamic(
        light: VaylPrimitives.warmCream,
        dark:  VaylPrimitives.inkWidget
    )

    /// Constellation node core fill. Slightly lighter than pageBackground with a
    /// purple undertone. Distinct from cardBackground / modalBackground — not a
    /// general surface token; use only in ConstellationView node circles.
    static let constellationNodeCore = Color.dynamic(
        light: VaylPrimitives.pureWhite,
        dark:  VaylPrimitives.inkNodeCore
    )

    // ─────────────────────────────────────────────
    // MARK: OB StatPhase — ethos gradient
    //
    // Exclusive to EthosTextView in StatPhase.
    // Bakes the per-mode accent colors and their specific opacity values
    // into tokens so no numeric opacity literals appear in the View layer.
    // ─────────────────────────────────────────────

    /// Ethos gradient lead stop. accentPrimary at near-opaque presence.
    /// 10% transparency softens the hard start of the gradient sweep.
    static let ethosGradientLead = Color.dynamic(
        light: VaylPrimitives.magenta.withAlphaComponent(0.90),
        dark:  VaylPrimitives.cyan.withAlphaComponent(0.90)
    )

    /// Ethos gradient trail stop. accentSecondary at softened presence.
    /// 20% drop from lead produces a gentle luminosity fade across the short phrase.
    static let ethosGradientTrail = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.80),
        dark:  VaylPrimitives.purple.withAlphaComponent(0.80)
    )

    // ─────────────────────────────────────────────
    // MARK: OB Flourish — decorative component
    //
    // These tokens are exclusive to VaylFlourishView.
    // Sourced from the same hue palette as the "1 in 5" headline gradient
    // so the flourish reads as an extension of that typography.
    // ─────────────────────────────────────────────

    /// Flourish gradient left stop — purple end, mirrors accentSecondary palette.
    static let flourishLeft: Color = Color(uiColor: VaylPrimitives.purpleLight)

    /// Flourish gradient midpoint — lavender bridge between purple and coral.
    static let flourishMid: Color = Color(uiColor: VaylPrimitives.purpleBright)

    /// Flourish gradient right stop — coral/pink end, mirrors accentTertiary palette.
    static let flourishRight: Color = Color(uiColor: VaylPrimitives.magentaLight)

    /// Flourish Canvas layer base opacity. Renders as subtle texture, not decoration.
    static let flourishBaseOpacity: Double = 0.75

    // ─────────────────────────────────────────────
    // MARK: OB Canvas
    //
    // These tokens are exclusive to the Onboarding canvas.
    // They must never appear in main-app screens.
    //
    // Light-mode values are placeholders — they mirror the dark
    // values until OB Dawn mode is designed. Update both the
    // primitive and the light: stop here when that work begins.
    // Do not remove the light: parameter — it future-proofs the
    // token for adaptive resolution.
    // ─────────────────────────────────────────────

    /// Absolute floor of the OB canvas. The void the table sits in.
    /// Slightly warmer and more violet than inkBase — gives the table
    /// world its own atmospheric identity separate from the main app.
    /// Light: placeholder mirrors dark until OB Dawn is designed.
    static let void = Color.dynamic(
        light: VaylPrimitives.inkVoid,
        dark:  VaylPrimitives.inkVoid
    )

    /// OB card glass surface. Applied to VaylCardBack and VaylCardFace.
    /// Distinct from cardBackground (inkCard #12111A) — the OB card
    /// surface is #120f1a, a fraction warmer in the blue channel.
    /// Light: placeholder mirrors dark until OB Dawn is designed.
    static let cardBg = Color.dynamic(
        light: VaylPrimitives.inkCardOB,
        dark:  VaylPrimitives.inkCardOB
    )

    // ─────────────────────────────────────────────
    // MARK: OB Table Surface — rendering constants
    //
    // These tokens are exclusive to TableSurfaceView.
    // They simulate physical light on baize and an overhead
    // lamp — they are rendering constants, not brand colors.
    // They must never appear in any other view or component.
    //
    // Light-mode values mirror dark until OB Dawn is designed.
    // ─────────────────────────────────────────────

    /// Felt fill gradient — center stop. TableSurfaceView use only.
    static let tableFeltCore = Color.dynamic(
        light: VaylPrimitives.tableFeltCore,
        dark:  VaylPrimitives.tableFeltCore
    )

    /// Felt fill gradient — mid stop. TableSurfaceView use only.
    static let tableFeltMid = Color.dynamic(
        light: VaylPrimitives.tableFeltMid,
        dark:  VaylPrimitives.tableFeltMid
    )

    /// Felt fill gradient — outer stop. TableSurfaceView use only.
    static let tableFeltOuter = Color.dynamic(
        light: VaylPrimitives.tableFeltOuter,
        dark:  VaylPrimitives.tableFeltOuter
    )

    /// Felt fill gradient — trailing edge stop. TableSurfaceView use only.
    static let tableFeltEdge = Color.dynamic(
        light: VaylPrimitives.tableFeltEdge,
        dark:  VaylPrimitives.tableFeltEdge
    )

    /// Topo contour line stroke. TableSurfaceView use only.
    static let tableTopoLine = Color.dynamic(
        light: VaylPrimitives.tableTopoLine,
        dark:  VaylPrimitives.tableTopoLine
    )

    /// Compass star base color. TableSurfaceView use only.
    static let tableCompassStar = Color.dynamic(
        light: VaylPrimitives.tableCompassStar,
        dark:  VaylPrimitives.tableCompassStar
    )

    /// Amber overhead lamp pool center stop. TableSurfaceView use only.
    static let tableAmberPool = Color.dynamic(
        light: VaylPrimitives.tableAmberPool,
        dark:  VaylPrimitives.tableAmberPool
    )

    // ─────────────────────────────────────────────
    // MARK: Spectrum — fixed accent values
    //
    // These three tokens resolve the fixed spectrum anchor colors
    // used for hairlines, glows, and accents throughout the app.
    // They are NOT adaptive — the spectrum is the same in both modes.
    // Use these tokens wherever a single spectrum channel is needed.
    // For full spectrum gradients use spectrumBorder or spectrumText.
    // ─────────────────────────────────────────────

    /// Spectrum cyan anchor. #00C2FF. Hairlines, glows, accents.
    static let spectrumCyan    = Color(uiColor: VaylPrimitives.cyan)

    /// Spectrum purple anchor. #6C3AE0. Hairlines, glows, accents.
    static let spectrumPurple  = Color(uiColor: VaylPrimitives.purple)

    /// Spectrum magenta anchor. #FF006A. Hairlines, glows, accents.
    static let spectrumMagenta = Color(uiColor: VaylPrimitives.magenta)

    /// Mid-spectrum gradient bridge. Wordmark and spectrum sweep use only.
    /// Sits between cyan and magenta on the gradient arc — not a standalone accent.
    static let spectrumBridge  = Color(uiColor: VaylPrimitives.spectrumBridge)

    // ─────────────────────────────────────────────
    // MARK: Text — hierarchy
    //
    // Never use a lower-hierarchy token for primary content.
    // ─────────────────────────────────────────────

    /// Headings, screen titles, display text.
    static let textPrimary = Color.dynamic(
        light: VaylPrimitives.wineDeep,
        dark:  VaylPrimitives.inkText
    )

    /// Paragraph content, card text, descriptions.
    static let textBody = Color.dynamic(
        light: VaylPrimitives.wineMid,
        dark:  VaylPrimitives.pureWhite
    )

    /// Labels, descriptions, supporting copy. 60% hierarchy.
    static let textSecondary = Color.dynamic(
        light: VaylPrimitives.wineMid.withAlphaComponent(0.60),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.65)
    )

    /// Timestamps, metadata, counts. 38% hierarchy.
    /// Apply .italic() at usage site — italic is the semantic signal.
    static let textTertiary = Color.dynamic(
        light: VaylPrimitives.wineMid.withAlphaComponent(0.38),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.38)
    )

    /// Placeholder text, pronoun hints, inline helper copy.
    static let textHint = Color.dynamic(
        light: VaylPrimitives.magentaDark.withAlphaComponent(0.50),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.42)
    )

    /// Disabled states, ghost copy. Lowest visible hierarchy.
    static let textMuted = Color.dynamic(
        light: VaylPrimitives.wineMid.withAlphaComponent(0.22),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.20)
    )

    /// Overline labels and status counts. Must survive a tinted
    /// ambient background — device-absolute, never tinted.
    static let textBright = Color.dynamic(
        light: VaylPrimitives.wineDeep,
        dark:  UIColor(white: 0.90, alpha: 1)
    )

    /// Tappable links and accent body text.
    static let textAccent = Color.dynamic(
        light: VaylPrimitives.magentaDark,
        dark:  VaylPrimitives.cyan
    )

    /// Card overline and section labels with spectrum tint.
    static let textCardLabel = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.70),
        dark:  VaylPrimitives.cyan.withAlphaComponent(0.60)
    )

    /// Section headers and eyebrow labels — the lavender-purple from docs/prototypes/settings-v2.html.
    /// Matches `--label: rgba(160,125,205,0.5)` in HTML prototypes. Softer than textCardLabel
    /// (which skews cyan in Midnight). Use for .sec-h style grouping labels in list screens.
    static let textSectionLabel = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.65),
        dark:  VaylPrimitives.purpleBright.withAlphaComponent(0.55)
    )

    // ─────────────────────────────────────────────
    // MARK: Accent — action and emphasis
    // ─────────────────────────────────────────────

    /// Primary interactive accent. CTAs, active states, focus rings.
    /// Midnight: cyan (emissive). Dawn: magenta (refractive).
    static let accentPrimary = Color.dynamic(
        light: VaylPrimitives.magenta,
        dark:  VaylPrimitives.cyan
    )

    /// Secondary accent. Decorative spectrum, orbit trails.
    static let accentSecondary = Color.dynamic(
        light: VaylPrimitives.purple,
        dark:  VaylPrimitives.purple
    )

    /// Tertiary accent. Badge fills, atmospheric tints.
    static let accentTertiary = Color.dynamic(
        light: VaylPrimitives.gold,
        dark:  VaylPrimitives.magenta
    )

    // ─────────────────────────────────────────────
    // MARK: Borders
    // ─────────────────────────────────────────────

    /// Default card and surface border. Barely visible structural edge.
    static let borderSubtle = Color.dynamic(
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.06),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.06)
    )

    /// Hover and focus border. Slightly more present than subtle.
    static let borderDefault = Color.dynamic(
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.10),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.10)
    )

    /// Active, selected, or structural border.
    static let borderActive = Color.dynamic(
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.15),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.15)
    )

    /// Accent-tinted border. Focus rings on accent inputs.
    static let borderAccent = Color.dynamic(
        light: VaylPrimitives.magenta.withAlphaComponent(0.22),
        dark:  VaylPrimitives.cyan.withAlphaComponent(0.20)
    )

    /// Purple-tinted structural border. Cards and fields in light mode.
    static let borderPurple = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.14),
        dark:  VaylPrimitives.purple.withAlphaComponent(0.14)
    )

    // ─────────────────────────────────────────────
    // MARK: Feedback states
    // ─────────────────────────────────────────────

    /// Destructive actions, error states, irreversible confirmations.
    static let destructive = Color.dynamic(
        light: VaylPrimitives.destructiveRed,
        dark:  VaylPrimitives.destructiveRed
    )

    /// Success confirmations, completed states.
    static let success = Color.dynamic(
        light: VaylPrimitives.successGreen,
        dark:  VaylPrimitives.successGreen
    )

    // ─────────────────────────────────────────────
    // MARK: Gold — safety signal
    //
    // At full or near-full opacity: safety signals only.
    // (safe word button, warnings, hard stop actions)
    // Aurora atmospheric use at ≤8% opacity is acceptable —
    // it cannot be read as a directional signal at that opacity.
    // If it is visible enough to be noticed as gold, it is
    // too opaque for non-safety use.
    // ─────────────────────────────────────────────

    /// Safety signal accent. Safe word, warnings, hard stops only.
    static let safetyAccent = Color.dynamic(
        light: VaylPrimitives.gold,
        dark:  VaylPrimitives.gold
    )

    /// Aurora atmospheric wash. ≤8% opacity enforced at call sites.
    static let safetyAtmosphere = Color.dynamic(
        light: VaylPrimitives.gold,
        dark:  VaylPrimitives.gold
    )

    // ─────────────────────────────────────────────
    // MARK: Shadows and glows
    // ─────────────────────────────────────────────

    /// Modal scrims and card drop shadows.
    static let shadowDeep = Color.dynamic(
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.12),
        dark:  VaylPrimitives.pureBlack.withAlphaComponent(0.50)
    )

    /// Dawn tinted shadow — magenta channel. Cards in light mode.
    static let shadowMagenta = Color.dynamic(
        light: VaylPrimitives.magenta.withAlphaComponent(0.18),
        dark:  VaylPrimitives.magenta.withAlphaComponent(0.10)
    )

    /// Dawn tinted shadow — purple channel. Cards in light mode.
    static let shadowPurple = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.12),
        dark:  VaylPrimitives.purple.withAlphaComponent(0.08)
    )

    /// Dawn tinted shadow — gold warmth layer. Lowest shadow channel.
    static let shadowGold = Color.dynamic(
        light: VaylPrimitives.gold.withAlphaComponent(0.07),
        dark:  VaylPrimitives.gold.withAlphaComponent(0.04)
    )

    // ─────────────────────────────────────────────
    // MARK: Aurora atmosphere
    //
    // Background blobs behind frosted surfaces.
    // Opacity intentionally low — felt, not seen.
    // ─────────────────────────────────────────────

    /// Aurora blob — top right corner.
    static let auroraBlob1 = Color.dynamic(
        light: VaylPrimitives.magenta.withAlphaComponent(0.09),
        dark:  VaylPrimitives.magenta.withAlphaComponent(0.09)
    )

    /// Aurora blob — bottom left corner.
    static let auroraBlob2 = Color.dynamic(
        light: VaylPrimitives.purple.withAlphaComponent(0.08),
        dark:  VaylPrimitives.purple.withAlphaComponent(0.08)
    )

    // ─────────────────────────────────────────────
    // MARK: Glass fills
    //
    // Opaque values only. Semi-transparent fills multiply with
    // container opacity and vanish at disabled (0.45).
    // These hold shape identity at any opacity level.
    // ─────────────────────────────────────────────

    /// Frosted card fill. Warm near-white over aurora in Dawn.
    static let glassFrostCard = Color.dynamic(
        light: VaylPrimitives.frostCard,
        dark:  VaylPrimitives.inkCard
    )

    /// Unselected pill fill. Visible contrast against page background.
    static let glassFrostPill = Color.dynamic(
        light: VaylPrimitives.frostPill,
        dark:  VaylPrimitives.inkPill
    )

    /// Selected pill fill. Lifts visibly over unselected state.
    static let glassFrostPillSelected = Color.dynamic(
        light: VaylPrimitives.frostPillSelected,
        dark:  VaylPrimitives.inkSurface
    )

    /// CTA button fill. Warm rose on Dawn, ink surface on Midnight.
    static let glassFrostCTA = Color.dynamic(
        light: VaylPrimitives.frostCTA,
        dark:  VaylPrimitives.inkSurface
    )

    /// Translucent glass surface for cards that float on the void + atmosphere
    /// (the Map tab and any void-native surface). Unlike `glassFrostCard` /
    /// `cardBackground` (the opaque `inkCard`), this lets the aurora bloom read
    /// through the card. The canonical `.vaylGlassCard` fill — mockup parity is
    /// rgba(255,255,255,0.03) over the void.
    static let glassSurface = Color.dynamic(
        light: VaylPrimitives.frostCard,
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.03)
    )

    // ─────────────────────────────────────────────
    // MARK: Pill surface — Midnight mode
    //
    // ~15% brighter than cardBackground so pill labels have a
    // contrast floor against the purple ambient atmosphere.
    // ─────────────────────────────────────────────

    /// Unselected pill interior gradient — bottom stop.
    static let pillSurfaceBottom = Color.dynamic(
        light: VaylPrimitives.frostPillBottom,
        dark:  VaylPrimitives.inkPillBottom
    )

    /// Ambient lift shadow on every pill.
    static let pillGlow = Color.dynamic(
        light: VaylPrimitives.pureBlack.withAlphaComponent(0.04),
        dark:  VaylPrimitives.pureWhite.withAlphaComponent(0.04)
    )

    // ─────────────────────────────────────────────
    // MARK: Input
    // ─────────────────────────────────────────────

    /// Floating label color when a text field is focused.
    static let inputLabelFocused = Color.dynamic(
        light: VaylPrimitives.magentaDark,
        dark:  VaylPrimitives.cyan
    )

    // ─────────────────────────────────────────────
    // MARK: Icon badge backgrounds
    // ─────────────────────────────────────────────

    /// Magenta-tinted icon badge background.
    static let iconBadgeMagenta = Color.dynamic(
        light: VaylPrimitives.magenta.withAlphaComponent(0.18),
        dark:  VaylPrimitives.magenta.withAlphaComponent(0.12)
    )

    /// Amber-tinted icon badge background.
    static let iconBadgeAmber = Color.dynamic(
        light: VaylPrimitives.orangeHot.withAlphaComponent(0.14),
        dark:  VaylPrimitives.orangeHot.withAlphaComponent(0.10)
    )

    /// Gold-tinted icon badge background.
    static let iconBadgeGold = Color.dynamic(
        light: VaylPrimitives.gold.withAlphaComponent(0.14),
        dark:  VaylPrimitives.gold.withAlphaComponent(0.10)
    )

    // ─────────────────────────────────────────────
    // MARK: Toggle
    // ─────────────────────────────────────────────

    /// Active toggle and switch fill.
    static let toggleActive = Color.dynamic(
        light: VaylPrimitives.magenta,
        dark:  VaylPrimitives.cyan
    )

    // ─────────────────────────────────────────────
    // MARK: Progress bar
    // ─────────────────────────────────────────────

    /// Leading stop of onboarding progress bar fill.
    static let progressBarLeading = Color.dynamic(
        light: VaylPrimitives.orangeHot,
        dark:  VaylPrimitives.cyan
    )

    /// Trailing stop of onboarding progress bar fill.
    static let progressBarTrailing = Color.dynamic(
        light: VaylPrimitives.orangeDeep,
        dark:  VaylPrimitives.purple
    )

    // ─────────────────────────────────────────────
    // MARK: App icon
    // ─────────────────────────────────────────────

    /// App icon launch background. Asset-matched fixed value.
    static let appIconBackground = Color(uiColor: VaylPrimitives.inkAppIcon)

    // ─────────────────────────────────────────────
    // MARK: Gradient stop tokens — structural only
    //
    // These are building blocks for gradients below.
    // Not for direct use in views — if you see gradientStop*
    // in a view file, that is a violation.
    //
    // Midnight: cyan  → purple → magenta   (emissive spectrum)
    // Dawn:     purple → magenta → gold    (refractive aurora)
    //
    // Cyan never appears in Dawn — it reads clinical on warm cream.
    // ─────────────────────────────────────────────

    private static let gradientStop1 = Color.dynamic(
        light: VaylPrimitives.purple,
        dark:  VaylPrimitives.cyan
    )
    private static let gradientStop2 = Color.dynamic(
        light: VaylPrimitives.magenta,
        dark:  VaylPrimitives.purple
    )
    private static let gradientStop3 = Color.dynamic(
        light: VaylPrimitives.gold,
        dark:  VaylPrimitives.magenta
    )

    // ─────────────────────────────────────────────
    // MARK: Gradients — public tokens
    // ─────────────────────────────────────────────

    /// Universal spectrum border.
    /// Midnight: cyan → purple → magenta
    /// Dawn:     purple → magenta → gold
    /// Applied to every prompt card and bordered surface.
    /// OB files reference this token as spectrumGradient — use this instead.
    static let spectrumBorder = LinearGradient(
        colors: [gradientStop1, gradientStop2, gradientStop3],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Universal spectrum text highlight.
    /// Same adaptive stops as spectrumBorder, horizontal direction.
    /// Use with .foregroundStyle() on keyword Text views.
    /// OB files reference this token as spectrumTextGradient — use this instead.
    static let spectrumText = LinearGradient(
        colors: [gradientStop1, gradientStop2, gradientStop3],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Light mode shimmer sweep. Used in LightModeShimmer.swift only.
    static let lightShimmerColors: [Color] = [
        Color(uiColor: VaylPrimitives.purple.withAlphaComponent(0.22)),
        Color(uiColor: VaylPrimitives.magenta.withAlphaComponent(0.20)),
        Color(uiColor: VaylPrimitives.gold.withAlphaComponent(0.18)),
        Color(uiColor: VaylPrimitives.magenta.withAlphaComponent(0.18)),
        Color(uiColor: VaylPrimitives.purple.withAlphaComponent(0.22)),
    ]

    // ─────────────────────────────────────────────
    // MARK: Card intensity — tinted backgrounds
    //
    // Used by CardIntensity extension only.
    // Not for general use in views or components.
    // ─────────────────────────────────────────────

    static let cardIntensityTintCyan       = Color(uiColor: VaylPrimitives.tintCyan)
    static let cardIntensityTintPurple     = Color(uiColor: VaylPrimitives.tintPurple)
    static let cardIntensityTintMagenta    = Color(uiColor: VaylPrimitives.tintMagenta)
    static let cardIntensityTintNavy       = Color(uiColor: VaylPrimitives.tintNavy)
    static let cardIntensityTintIndigo     = Color(uiColor: VaylPrimitives.tintIndigo)
    static let cardIntensityTintPlum       = Color(uiColor: VaylPrimitives.tintPlum)
    static let cardIntensityTintSupernovaA = Color(uiColor: VaylPrimitives.tintSupernovaA)
    static let cardIntensityTintSupernovaB = Color(uiColor: VaylPrimitives.tintSupernovaB)
    static let cardIntensityTintSupernovaC = Color(uiColor: VaylPrimitives.tintSupernovaC)
    static let cardIntensityTintSupernovaD = Color(uiColor: VaylPrimitives.tintSupernovaD)

    // ─────────────────────────────────────────────────────────────
    // MARK: Pulse tier — data visualization only
    //
    // These colors represent emotional capacity states on a scale.
    // Used exclusively in pulse graph and tier indicators.
    // Never used for UI interaction states or accents.
    //
    // Midnight: emissive spectrum — cyan down to soft magenta
    // Dawn:     refractive spectrum — magenta down to muted wine
    // ─────────────────────────────────────────────────────────────

    /// Pulse tier 1 — Expansive. Highest capacity. Connected, adventurous.
    static let pulseTierExpansive = Color.dynamic(
        light: VaylPrimitives.magenta,
        dark:  VaylPrimitives.cyan
    )

    /// Pulse tier 2 — Sovereign. Stable capacity. Grounded, secure.
    static let pulseTierSovereign = Color.dynamic(
        light: VaylPrimitives.purple,
        dark:  VaylPrimitives.purple
    )

    /// Pulse tier 3 — Friction. Reduced capacity. Anxious, defensive.
    static let pulseTierFriction = Color.dynamic(
        light: VaylPrimitives.magentaDark,
        dark:  VaylPrimitives.magenta
    )

    /// Pulse tier 4 — Protective. Lowest capacity. Overwhelmed, needs space.
    static let pulseTierProtective = Color.dynamic(
        light: VaylPrimitives.wineFaint,
        dark:  VaylPrimitives.magentaLight
    )

    // ─────────────────────────────────────────────────────────────
    // MARK: Aura tier color ramps — PulseAura use only
    //
    // Each tier: core (midpoint) / light (inner highlight) / deep (outer edge) / glow (shadow).
    // Maps to HTML: .cyan → expansive, .indigo → sovereign, .magenta → friction, .rose → protective.
    // FEEL: intensities tuned on device against docs/prototypes/pulse-aura-glass.html.
    // ─────────────────────────────────────────────────────────────

    static let auraCoreCyan     = Color(uiColor: VaylPrimitives.cyan)
    static let auraLightCyan    = Color(uiColor: VaylPrimitives.cyanLight)
    static let auraDeepCyan     = Color(uiColor: VaylPrimitives.cyanDark)
    static let auraGlowCyan     = Color(uiColor: VaylPrimitives.cyan).opacity(0.30)

    static let auraCoreIndigo   = Color(uiColor: VaylPrimitives.electricViolet)
    static let auraLightIndigo  = Color(uiColor: VaylPrimitives.purpleBright)
    static let auraDeepIndigo   = Color(uiColor: VaylPrimitives.purple)
    static let auraGlowIndigo   = Color(uiColor: VaylPrimitives.electricViolet).opacity(0.30)

    static let auraCoreMagenta  = Color(uiColor: VaylPrimitives.magenta)
    static let auraLightMagenta = Color(uiColor: VaylPrimitives.magentaLight)
    static let auraDeepMagenta  = Color(uiColor: VaylPrimitives.magentaDark)
    static let auraGlowMagenta  = Color(uiColor: VaylPrimitives.magenta).opacity(0.28)

    static let auraCoreRose     = Color(uiColor: VaylPrimitives.rose)
    static let auraLightRose    = Color(uiColor: VaylPrimitives.roseLight)
    static let auraDeepRose     = Color(uiColor: VaylPrimitives.roseDark)
    static let auraGlowRose     = Color(uiColor: VaylPrimitives.rose).opacity(0.26)
}


// MARK: - Color.dynamic

extension Color {
    /// Always resolves to the dark variant — app is dark-only (Act 1).
    /// light: param is retained for future Dawn-mode work; it is currently ignored.
    /// No @Environment(\.colorScheme) branching required in views.
    static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: dark)
    }
}

// MARK: - Color(hex:) — SwiftUI convenience

extension Color {
    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }
}

// MARK: - PulseCapacityColor aura ramp

extension PulseCapacityColor {
    /// Aura body radial gradient center color.
    var auraCore: Color {
        switch self {
        case .cyan:    return AppColors.auraCoreCyan
        case .indigo:  return AppColors.auraCoreIndigo
        case .magenta: return AppColors.auraCoreMagenta
        case .rose:    return AppColors.auraCoreRose
        }
    }
    /// Aura body inner highlight (lightest, at center).
    var auraLight: Color {
        switch self {
        case .cyan:    return AppColors.auraLightCyan
        case .indigo:  return AppColors.auraLightIndigo
        case .magenta: return AppColors.auraLightMagenta
        case .rose:    return AppColors.auraLightRose
        }
    }
    /// Aura body outer edge color (darkest, at rim).
    var auraDeep: Color {
        switch self {
        case .cyan:    return AppColors.auraDeepCyan
        case .indigo:  return AppColors.auraDeepIndigo
        case .magenta: return AppColors.auraDeepMagenta
        case .rose:    return AppColors.auraDeepRose
        }
    }
    /// Glow shadow color for the soft outer halo.
    var auraGlow: Color {
        switch self {
        case .cyan:    return AppColors.auraGlowCyan
        case .indigo:  return AppColors.auraGlowIndigo
        case .magenta: return AppColors.auraGlowMagenta
        case .rose:    return AppColors.auraGlowRose
        }
    }
}

```

---

## File: `Vayl/App/Theme/AppFonts.swift` {#file-vayl-app-theme-appfonts-swift}

```swift
// App/Theme/AppFonts.swift

import SwiftUI

// ─────────────────────────────────────────────────────────────
// Typography scale.
//
// Rules:
//   • Every token uses Font.custom(_:size:relativeTo:) — no exceptions
//   • relativeTo: maps to the TextStyle closest to the token's
//     visual role — this is what Dynamic Type scales against
//   • Font.system(size:) is banned in this file
//   • assertionFailure fires on unsupported weights in debug
//     before the fallback path — surfaces programmer errors
//     without crashing in production
//   • Every token has a one-sentence use context comment
// ─────────────────────────────────────────────────────────────

struct AppFonts {

    // ─────────────────────────────────────────────
    // MARK: Typeface constructors
    //
    // Not for direct use in views.
    // Use the semantic tokens below.
    // ─────────────────────────────────────────────

    static func display(
        _ size: CGFloat,
        weight: Font.Weight = .bold,
        relativeTo textStyle: Font.TextStyle
    ) -> Font {
        switch weight {
        case .bold:
            return Font.custom("ClashDisplay-Bold",     size: size, relativeTo: textStyle)
        case .semibold:
            return Font.custom("ClashDisplay-Semibold", size: size, relativeTo: textStyle)
        case .medium:
            return Font.custom("ClashDisplay-Medium",   size: size, relativeTo: textStyle)
        default:
            assertionFailure(
                "AppFonts.display: unsupported weight \(weight). " +
                "Supported: .bold, .semibold, .medium"
            )
            return Font.custom("ClashDisplay-Bold", size: size, relativeTo: textStyle)
        }
    }

    static func body(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo textStyle: Font.TextStyle
    ) -> Font {
        switch weight {
        case .regular:
            return Font.custom("Switzer-Regular",  size: size, relativeTo: textStyle)
        case .medium:
            return Font.custom("Switzer-Medium",   size: size, relativeTo: textStyle)
        case .semibold:
            return Font.custom("Switzer-Semibold", size: size, relativeTo: textStyle)
        case .bold:
            return Font.custom("Switzer-Bold",     size: size, relativeTo: textStyle)
        default:
            assertionFailure(
                "AppFonts.body: unsupported weight \(weight). " +
                "Supported: .regular, .medium, .semibold, .bold"
            )
            return Font.custom("Switzer-Regular", size: size, relativeTo: textStyle)
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Display scale — ClashDisplay
    // ─────────────────────────────────────────────

    /// Full-screen hero text. Splash screens and empty state illustrations only.
    static var heroTitle: Font {
        display(42, weight: .bold, relativeTo: .largeTitle)
    }

    /// Oversized display numeral or word. One element per screen maximum.
    static var displayHero: Font {
        display(64, weight: .bold, relativeTo: .largeTitle)
    }

    /// StatPhase "1 in 5" holographic hero. Larger than displayHero (64) and
    /// responsive — the size comes from AppLayout.statHeroSize(usableHeight:screenWidth:),
    /// never an inline literal. relativeTo: .largeTitle so Dynamic Type still scales it.
    /// Exclusive to the StatPhase arrival hero; one per app.
    static func statHero(_ size: CGFloat) -> Font {
        display(size, weight: .bold, relativeTo: .largeTitle)
    }

    /// Numeric data display — scores, counts, codes. Never prose.
    static var scoreDisplay: Font {
        display(32, weight: .bold, relativeTo: .title)
    }

    /// One per screen. Top of content area, primary screen identifier.
    static var screenTitle: Font {
        display(24, weight: .semibold, relativeTo: .title)
    }

    /// Onboarding phase headline. One per OB phase screen.
    /// Used for the cinematic opening statement on each onboarding phase —
    /// "Let's get acquainted.", "Good to meet you.", and equivalent lines
    /// on subsequent phases. Larger than screenTitle to anchor the emotional
    /// beat of each phase as a hero statement, not a navigation label.
    /// Never use outside the Onboarding canvas.
    /// relativeTo: .largeTitle — scales against the largest Dynamic Type style
    /// so the statement remains dominant at all accessibility sizes.
    static var obPhaseTitle: Font {
        display(32, weight: .semibold, relativeTo: .largeTitle)
    }

    /// Primary text inside a card surface. Never the screen title.
    static var cardTitle: Font {
        display(22, weight: .semibold, relativeTo: .title2)
    }

    /// Section labels inside a screen. Never the screen title.
    static var sectionHeading: Font {
        display(20, weight: .medium, relativeTo: .title3)
    }

    /// Category tags and grouped list headers.
    static var sectionLabelSmall: Font {
        display(13, weight: .medium, relativeTo: .subheadline)
    }

    /// The question or statement on a prompt card.
    static var prompt: Font {
        display(17, weight: .medium, relativeTo: .body)
    }

    /// Keyword emphasis within a prompt. Gradient foreground applied at usage site.
    static var promptHighlight: Font {
        display(17, weight: .semibold, relativeTo: .body)
    }

    // ─────────────────────────────────────────────
    // MARK: Body scale — Switzer
    // ─────────────────────────────────────────────

    /// Primary CTA button label. One per screen.
    static var ctaLabel: Font {
        body(17, weight: .semibold, relativeTo: .body)
    }

    /// Paragraph content. Never UI labels or navigation elements.
    static var bodyText: Font {
        body(16, weight: .regular, relativeTo: .body)
    }

    /// Emphasized body. Form labels, card subtitles, inline emphasis.
    static var bodyMedium: Font {
        body(15, weight: .medium, relativeTo: .body)
    }

    /// Secondary button and action label. Not the primary CTA.
    static var buttonLabel: Font {
        body(14, weight: .semibold, relativeTo: .callout)
    }

    /// Supporting information. Never primary content.
    static var caption: Font {
        body(13, weight: .regular, relativeTo: .caption)
    }

    /// Section dividers only. Always uppercase with tracking at usage site.
    static var overline: Font {
        body(11, weight: .semibold, relativeTo: .caption2)
    }

    /// Compact pill and chip labels only.
    static var buttonLabelSmall: Font {
        body(11, weight: .medium, relativeTo: .caption2)
    }

    /// Navigation labels at the bottom of the screen.
    static var tabLabel: Font {
        body(10, weight: .medium, relativeTo: .caption2)
    }

    /// Badges, counts, status indicators.
    static var label: Font {
        body(10, weight: .semibold, relativeTo: .caption2)
    }

    /// Notification and count badges only.
    static var badge: Font {
        body(10, weight: .medium, relativeTo: .caption2)
    }

    /// Timestamps, counts, secondary metadata. Never primary content.
    static var meta: Font {
        body(10, weight: .regular, relativeTo: .caption2)
    }

    // ─────────────────────────────────────────────
    // MARK: Founder letter — Menlo monospace
    //
    // One-screen use only: FounderLetterPhase.
    // Monospace signals "written by a person" —
    // subconscious dealer/typewriter register.
    // ─────────────────────────────────────────────

    /// Founder letter body. Size is geometry-driven — use letterFont(for:) in FounderLetterPhase.
    static func founderLetter(_ size: CGFloat) -> Font {
        Font.custom("Menlo-Regular", size: size, relativeTo: .body)
    }

    /// Founder letter sign-off weight. Heavier than body to anchor the close.
    static func founderLetterBold(_ size: CGFloat) -> Font {
        Font.custom("Menlo-Bold", size: size, relativeTo: .body)
    }

    // ─────────────────────────────────────────────
    // MARK: Debug
    // ─────────────────────────────────────────────

    static func debugFontList() {
        for family in UIFont.familyNames.sorted() {
            print("\n\(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  \(name)")
            }
        }
    }
}

```

---

## File: `Vayl/App/Theme/AppSpacing.swift` {#file-vayl-app-theme-appspacing-swift}

```swift
//
//  AppSpacing.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//


// App/Theme/AppSpacing.swift

import CoreGraphics

/// Tier 2 — Semantic spacing tokens.
/// Every padding, gap, and spacing value in the codebase must reference one of these.
/// Hardcoded numeric values in `.padding()`, `.spacing()`, or `.offset()` are a violation.
/// Nothing in this file may be referenced from VaylPrimitives — spacing has no primitive tier.
internal enum AppSpacing {

    /// 2pt — Micro-adjustments only.
    /// Use for drag handle gaps, dot separators, and sub-pixel optical corrections.
    /// Never use as a structural gap or content spacing value.
    static let xxs: CGFloat = 2

    /// 4pt — Tight internal gaps only.
    /// Use between an icon and its adjacent label, or between two tightly coupled inline elements.
    /// Never use as a structural margin or between independent content blocks.
    static let xs: CGFloat = 4

    /// 8pt — Compact vertical or horizontal gaps between related elements.
    /// Use between a title and its subtitle, between stacked labels in a card, or inside a pill's internal padding.
    /// Never use as a screen-edge margin or between independent sections.
    static let sm: CGFloat = 8

    /// 16pt — Default structural gap and card-edge padding.
    /// Use as the standard horizontal padding inside cards, the gap between form fields,
    /// and the vertical spacing between related content groups within a section.
    static let md: CGFloat = 16

    /// 24pt — Section separation and screen-edge horizontal margin.
    /// Use as the leading and trailing margin from screen edges to content,
    /// and as the vertical gap between independent sections on a screen.
    static let lg: CGFloat = 24

    /// 32pt — Bottom padding above sticky or bottom-anchored CTAs.
    /// Use to create breathing room between the last content element and a fixed bottom button.
    /// Also use as generous internal vertical padding on tall modal surfaces.
    static let xl: CGFloat = 32

    /// 48pt — Hero and top-of-screen breathing room.
    /// Use as the top padding above a screen's primary headline, and as the vertical gap
    /// between major structural breaks such as a hero block and the first content section.
    static let xxl: CGFloat = 48
}
```

---

## File: `Vayl/App/Theme/AppRadius.swift` {#file-vayl-app-theme-appradius-swift}

```swift
//
//  AppRadius.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//


// App/Theme/AppRadius.swift

import CoreGraphics

/// Tier 2 — Semantic corner radius tokens.
/// Every `.cornerRadius()`, `.clipShape()`, or `RoundedRectangle(cornerRadius:)` call
/// in the codebase must reference one of these tokens.
/// Hardcoded numeric values in any corner radius context are a violation.
/// Nothing in this file may reference VaylPrimitives — radius has no primitive tier.
///
/// Grid note: Radius tokens use a 4pt grid. This is intentional and independent
/// of the 8pt spacing grid — radius granularity requirements are finer than spacing
/// requirements. The two grids do not need to be unified.
internal enum AppRadius {

    /// 2pt — Drag handle pills and fine decorative dividers.
    /// Use for drag handle capsules, hairline divider end-caps, and sub-pixel decorative rounding.
    /// Never use for interactive elements, cards, or any tappable surface.
    static let micro: CGFloat = 2

    /// 8pt — Small interactive chips, tags, and badge labels.
    /// Use for pills that display metadata (counts, status tags) and small category chips.
    /// Never use for primary buttons, cards, or any surface larger than a label container.
    static let sm: CGFloat = 8

    /// 12pt — Input fields and secondary buttons.
    /// Use for text input containers, secondary action buttons, and segmented control backgrounds.
    /// Never use for primary CTAs, cards, or modal surfaces.
    static let md: CGFloat = 12

    /// 16pt — Cards and primary action buttons.
    /// Use for all content cards regardless of elevation level, and for the HoloCTAButton.
    /// Never use for modals, sheets, or surfaces larger than a card.
    static let lg: CGFloat = 16

    /// 24pt — Modals, sheets, and large overlay surfaces.
    /// Use for bottom sheets, full-screen overlays presented over content, and large surface containers.
    /// Never use for cards or buttons — this radius is reserved for surfaces that sit above cards.
    static let xl: CGFloat = 24

    /// 20pt — Onboarding cards, home widgets, and pairing surfaces.
    /// Use for the dominant off-grid card radius seen across onboarding and home feature surfaces.
    /// Distinct from lg (16pt cards) and xl (24pt modals) — sits between them for hero containers.
    static let container: CGFloat = 20

    /// Infinity — Fully rounded capsule shape.
    /// Use for selectable pills, toggle tracks, and any element that must render as a perfect capsule.
    /// SwiftUI mathematically clamps .infinity to perfectly round the shortest edge.
    /// Never use for cards, buttons, inputs, or any rectangular surface.
    static let pill: CGFloat = .infinity

    /// 57pt — Native-style presented sheet corners for Dynamic Island devices.
    /// Apple's native bottom sheets on modern Pro devices (iPhone 14/15 Pro) use
    /// a much larger continuous corner radius of ~55pt to match the hardware corners.
    /// Because VaylSheetChrome applies a 2pt bleed (pushing the shape off-screen),
    /// we increase this to 57pt. This ensures exactly 55pt of the curve is
    /// visible on-screen.
    static let sheet: CGFloat = 57

    // MARK: - OB Card Radii
    // These tokens are exclusive to the Onboarding canvas and its card components.
    // They must never appear in main-app screens — the table metaphor does not
    // leave the OB boundary.

    /// 14pt — Full-size OB vertical card.
    /// Applied to VaylCardBack, VaylCardFace, and VaylCardRenderer frame clips.
    /// Distinct from lg (16pt) — the slightly tighter radius reads as a playing card,
    /// not a UI card. Do not substitute lg here.
    /// Vertical cards are OB/personal only. This token never appears on session cards.
    static let obCard: CGFloat = 14

    /// 4pt — Corner deck mini-card stack.
    /// Applied to the scaled-down card representations in CornerDeckView.
    /// At the rendered scale of the corner deck (~22% of full card size), 4pt
    /// produces the correct visual proportion of the obCard radius.
    /// Never use for full-size cards.
    static let cornerCard: CGFloat = 4

    /// 16pt — Foil wrapper overlay in BuildDeckPhase.
    /// Applied to FoilRenderer as it wraps the assembled deck.
    /// Matches lg intentionally — the foil sits over the deck surface and its
    /// edge radius must align with the card stack beneath it.
    static let foilEdge: CGFloat = 16
}

```

---

## File: `Vayl/App/Theme/AppAnimation.swift` {#file-vayl-app-theme-appanimation-swift}

```swift
//
//  AppAnimation.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//

// App/Theme/AppAnimation.swift

import SwiftUI
import UIKit

/// Tier 2 — Semantic animation tokens.
/// Every animation in the codebase must reference one of these tokens.
/// Ad hoc values like .easeOut(duration: 0.3) anywhere outside this file are a violation.
///
/// Two animation classes exist and must never be confused:
///   Reactive  — responds directly to a user action (tap, swipe, drag release).
///               Always takes priority. Never cancel or defer a reactive animation.
///   Ambient   — runs continuously without user input (pulse, glow, orbit).
///               Always yields to reactive animations. Never block user feedback.
///
/// Reduce Motion rules:
///   Every token has a documented reduce-motion fallback.
///   Reactive animations: replace movement with an instant opacity cross-fade.
///   Ambient animations: disable entirely — remove the animation, not just slow it down.
///   Never use .default or .linear as a reduce-motion fallback — they still move.
///   The correct fallback for movement is no movement. Opacity change is permitted.
internal enum AppAnimation {

    // MARK: — Reactive Animations
    // These respond to user actions. They must feel immediate and confirm input.
    // Reduce motion fallback for all reactive tokens: .easeOut(duration: 0.15)
    // This preserves the state change confirmation while eliminating spatial movement.

    /// 0.15s ease-out — Immediate micro-responses to user input.
    /// Use for button press states, toggle flips, selection highlights, and icon state changes.
    /// The speed communicates that the app registered the tap instantly.
    /// Reduce motion: use as-is — at 0.15s this is already at the threshold of perception.
    static let fast: Animation = .easeOut(duration: 0.15)

    /// 0.3s ease-out — Standard state transitions driven by user action.
    /// Use for screen element rearrangement after a selection, card state changes,
    /// and any layout shift that results directly from a tap or swipe.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — confirm the change, skip the travel.
    static let standard: Animation = .easeOut(duration: 0.3)

    /// 0.5s ease-out — Deliberate, weighty transitions for significant state changes.
    /// Use for onboarding step transitions, modal presentations driven by user action,
    /// and reveal animations where the user has explicitly requested new content.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — the reveal happens, the travel does not.
    static let slow: Animation = .easeOut(duration: 0.5)

    // MARK: — Cinematic Duration
    // Not an Animation value — a raw duration for use with .easeOut(duration: AppAnimation.cinematic).
    // Reserved for screen-level content reveals requiring ceremony beyond slow (0.5s).
    // Ambient animations must be disabled entirely when reduce motion is active.

    /// 1.2s — Cinematic reveal duration.
    /// Use for name reveals, tagline entrances, and LivingText fade-in arrivals that
    /// require ceremony beyond slow (0.5s). Not an Animation instance — pass as a
    /// duration parameter: .easeOut(duration: AppAnimation.cinematic).
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    /// Do not use for UI response animations — those use slow or enter.
    static let cinematic: Double = 1.2

    /// Cinematic ease-out — TableSurfaceView fade in/out.
    /// Use this instead of constructing .easeOut(duration: AppAnimation.cinematic) inline.
    static let cinematicFade: Animation = .easeOut(duration: AppAnimation.cinematic)

    // MARK: — StatPhase Arrival Ignition
    // The "1 in 5" hero fires a one-time light-catch as it seats: a bright specular
    // sweep crosses the numeral, the glow blooms past its resting level then settles,
    // and a soft haptic lands. Tuned in docs/prototypes/statphase-arrival.html.
    // Reduce motion: skip the sweep + bloom entirely (visual only); the soft land
    // haptic still fires (haptics are not motion).

    /// 0.76s — Delay from the stat's cascade entrance to the ignition firing, so the
    /// light catches the numeral as it *seats* rather than on first appearance.
    static let statIgnitionDelay: Double = 0.76

    /// 0.68s ease-out — The one bright specular sweep travelling across the numeral on land.
    static let statIgnitionSweep: Animation = .easeOut(duration: 0.68)

    /// 0.14s ease-out — Glow blooming up to its ignition peak as the numeral seats.
    static let statGlowBloomIn: Animation = .easeOut(duration: 0.14)

    /// 0.16s — Hold at the bloom peak before it settles back to the resting glow.
    /// Must exceed statGlowBloomIn (0.14s) or the settle retargets the bloom mid-flight.
    static let statGlowBloomHold: Double = 0.16

    /// 0.46s settle — Glow easing back down from the ignition peak to its resting level.
    /// timingCurve (0.22, 1, 0.36, 1): snappy ease-out, no overshoot.
    static let statGlowBloomSettle: Animation = .timingCurve(0.22, 1, 0.36, 1, duration: 0.46)

    /// 0.65s ease-out — StatPhase exit: the entire phase fades out after "Begin" is tapped.
    /// Long enough that the phase cross-fade (AppAnimation.slow) absorbs the remaining tail.
    /// Reduce motion: replace with AppAnimation.fast at call site.
    static let statExitFade: Animation = .easeOut(duration: 0.65)

    /// 0.32s ease-in-out — StatPhase citation panel toggle (open and close).
    /// Calm dim + fade — not snappy, not ceremonial. The panel is reference content.
    /// Reduce motion: replace with AppAnimation.fast at call site.
    static let statCitationToggle: Animation = .easeInOut(duration: 0.32)

    /// 0.35s material expand — Citation panel expand and collapse.
    /// timingCurve (0.4, 0, 0.2, 1): standard deceleration curve — element
    /// enters fast and eases into its resting position. Used for the expandable
    /// citation card in StatPhase. Not a general-purpose animation token — do
    /// not use outside StatPhase without deliberate intent.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let materialExpand: Animation = .timingCurve(0.4, 0, 0.2, 1, duration: 0.35)

    /// Spring — Physical, elastic responses to direct manipulation.
    /// Use for card lifts, pill selections, drag release snapping, and any interaction
    /// where the element should feel like it has mass and momentum.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — confirm without the bounce.
    static let spring: Animation = .spring(response: 0.5, dampingFraction: 0.85)

    // MARK: — Directional Transition Animations
    // Use for elements entering or leaving the screen as a result of navigation.
    // Reduce motion fallback: replace directional movement with opacity only.

    /// 0.4s ease-out — Elements entering the screen or becoming visible.
    /// Use for views sliding or fading into position after navigation, and for
    /// content appearing after an async load completes.
    /// Reduce motion: replace movement with .opacity animation at 0.2s duration.
    static let enter: Animation = .easeOut(duration: 0.4)

    /// 0.2s ease-in — Elements leaving the screen or becoming hidden.
    /// Use for views dismissing after navigation away, and for
    /// content disappearing before a state replacement.
    /// Ease-in for exit makes the departure feel intentional, not interrupted.
    /// Reduce motion: replace movement with .opacity animation at 0.15s duration.
    static let exit: Animation = .easeIn(duration: 0.2)

    // MARK: — Ambient Animation Durations
    // These are not Animation values — they are raw durations for use with
    // TimelineView, withAnimation loops, or RepeatForever animations.
    // Ambient animations must be disabled entirely when reduce motion is active.
    // Never use these durations inside a withAnimation block that responds to user input.

    /// 2.0s — Slow, continuous ambient pulse.
    /// Use for background glow breathe cycles, aura scale oscillation,
    /// and any effect that communicates the app is alive and listening.
    /// Reduce motion: remove the animation entirely. The static state must be visually complete.
    static let ambientPulse: Double = 2.0

    /// 4.0s — Very slow ambient drift.
    /// Use for aurora blob position shifts, background gradient rotation,
    /// and effects that should feel geological — barely perceptible movement.
    /// Reduce motion: remove the animation entirely. The static state must be visually complete.
    static let ambientDrift: Double = 4.0

    /// 1.2s — Medium ambient shimmer cycle.
    /// Use for specular highlight sweeps across card surfaces, shimmer loading states,
    /// and light-catch effects on premium surfaces.
    /// Reduce motion: remove the animation entirely — shimmer is purely decorative.
    static let ambientShimmer: Double = 1.2

    /// 2.2s — Duration of one direction of a candle's breath (in OR out). Build the
    /// animation at the call site with `.easeInOut(duration: AppAnimation.candleBreathDuration)`
    /// and sleep the same span between toggles so each inhale/exhale fully completes.
    /// The candle breathes in, then out, then RESTS (see candleBreathHold) rather than
    /// oscillating continuously — keeps the hand calm with occasional, subtle motion.
    /// Pair the amplitude small (~1.5–2%) so the breath reads as life, not a pulse.
    /// Reduce motion: no breathing; the candle holds its static frame.
    static let candleBreathDuration: Double = 2.2

    /// 3.0s — Intermittent rest between candle breaths. After a full in/out breath the
    /// candle holds still for this long before the next, so the motion is occasional.
    static let candleBreathHold: Double = 3.0

    // MARK: — Border Effect
        // Used by VaylBorderEffect. Applied to the spectrum stroke fill and glow pop
        // on VaylButton, SelectablePill, sheets, and any bordered surface.
        //
        // Spring timing note:
        // borderFill uses a spring, not a cubic-bezier. Spring animations do not
        // have a fixed wall-clock duration — response: 0.36 is the spring's natural
        // period, not its settle time. The actual visual settle is longer (~0.52s
        // at dampingFraction: 0.9). borderFillDuration accounts for this by using
        // the observed settle time rather than the spring response value.
        // If borderFill's spring parameters change, re-measure and update
        // borderFillDuration to match the new observed settle time.
        //
        // Reduce motion fallback: borderFill → instant state change, no animation.
        // Hairline tokens are opacity-only — safe under reduce motion as-is.

        /// Observed settle duration of borderFill — used in onPressUp() to calculate
        /// how long to wait before firing the glow so it lands exactly when the arcs meet.
        /// This is NOT the spring response value. It is the wall-clock time at which
        /// the spring animation is perceptually complete (within 1pt of target).
        /// Re-measure if borderFill spring parameters change.
        static let borderFillDuration: Double = 0.30

        /// Spring — Spectrum border filling around a pill on press.
        /// Two arcs sweep from top-center down to meet at bottom-center simultaneously.
        /// response: 0.36, dampingFraction: 0.9 — snappy initial velocity, no visible
        /// bounce. The circuit-completing feel comes from the arcs arriving with
        /// confidence rather than coasting in.
        /// Reduce motion: skip animation entirely — border jumps to filled state.
        static let borderFill: Animation = .spring(response: 0.36, dampingFraction: 0.9)

        /// 0.12s ease-out — Glow bursting on the moment arcs meet at bottom-center.
        /// Short and fast — this should feel like a flash of energy completing the
        /// circuit, not a bloom or fade-in. The intensity peak is immediate.
        /// Reduce motion: skip — no glow fires under reduce motion.
        static let borderGlowIn: Animation = .easeOut(duration: 0.12)

        /// 0.28s ease-in — Glow dissipating after the hold period.
        /// Ease-in communicates energy draining — the glow accelerates away from
        /// the peak rather than fading linearly. Faster than the previous 0.38s
        /// so the button feels resolved rather than lingering.
        /// Reduce motion: skip — no glow fires under reduce motion.
        static let borderGlowOut: Animation = .easeIn(duration: 0.28)

        /// How long the glow holds at full intensity before borderGlowOut begins.
        /// Not an Animation — a raw TimeInterval consumed by Task.sleep in VaylButton.
        /// 0.12s is short enough to clear before a rapid second tap, long enough
        /// to register as a deliberate energy burst rather than a flicker.
        /// Reduce motion: unused — glow sequence is skipped entirely.
        static let borderGlowHoldDuration: TimeInterval = 0.12

        /// 0.12s ease-in — Hairline retracting as border fill begins.
        /// Fast ease-in so the hairline clears before the arc strokes are visible.
        /// No visual overlap between hairline and arcs at any point in the transition.
        /// Reduce motion: use as-is — opacity only, no spatial movement.
        static let hairlineRetract: Animation = .easeIn(duration: 0.12)

        /// 0.35s ease-out — Hairline returning after border resets on cancel.
        /// Slower than retract — eases back in gently rather than snapping.
        /// Reduce motion: use as-is — opacity only, no spatial movement.
        static let hairlineReturn: Animation = .easeOut(duration: 0.35)

        /// 0.16s ease-in — Border retreating after a cancelled press.
        /// Ease-in signals a decisive abort — the border accelerates away from
        /// the pressed state rather than drifting back.
        /// Reduce motion: instant borderProgress = 0, no animation.
        static let borderRetract: Animation = .easeIn(duration: 0.16)
    // MARK: — Splash Screen
    // These tokens are exclusive to VaylSplashScreen.
    // They must never appear in any other screen — the cold launch ceremony
    // does not repeat as a UI pattern anywhere in the main app.
    //
    // Sequence timing (absolute offsets from cold launch):
    //   0.000s  void       — black screen, destination renders silently underneath
    //   0.250s  slit       — spectrum line aperture opens at constant velocity
    //   0.280s  bloom creep — line bloom builds from 0.35 → 0.58 over 300ms
    //   0.600s  ignition   — wordmark reveal begins, bloom spikes to 1.0
    //   0.640s  pulse      — linePulse fires 40ms after ignition (reveal leads)
    //   0.900s  hold       — bloom settles to 0.65, ambient oscillation begins
    //   1.660s  anticipate — zoom container micro-squeezes to 0.97× (40ms)
    //   1.700s  zoom       — camera crashes into line at 3.5×
    //   1.950s  tear       — panels snap apart, destination revealed
    //   2.200s  home fade  — destination opacity confirms (no animation — instant)
    //   2.400s  dismiss    — splash container removed from hierarchy
    //
    // Reduce motion fallback for all splash tokens:
    //   Skip the sequence entirely. Crossfade from void to destination at
    //   AppAnimation.standard duration. The destination must be visually
    //   complete at rest — no motion required to read it.

    /// 0.08s linear — Spectrum line aperture opening.
    /// Constant velocity communicates mechanical precision — an iris or shutter
    /// opening, not a fade. Linear is intentional and correct here.
    /// Reduce motion: skip — line appears instantly at full opacity.
    static let splashLineAppear: Animation = .linear(duration: 0.08)

    /// 0.58s easeOutExpo approximation — Wordmark reveal from light source.
    /// timingCurve (0.16, 1.0, 0.3, 1.0): high initial velocity decelerating
    /// sharply — communicates the letterforms arriving with mass from the energy
    /// of the line. Do NOT substitute .easeOut — it will feel lighter and faster.
    /// Reduce motion: skip — wordmark appears at full reveal instantly.
    static let splashReveal: Animation = .timingCurve(0.16, 1.0, 0.3, 1.0, duration: 0.58)

    /// 0.18s overshoot — Bloom energy spike at ignition.
    /// timingCurve (0.0, 0.8, 0.2, 1.2): y2 of 1.2 produces a genuine mathematical
    /// overshoot beyond the target bloom value before settling. This makes the
    /// ignition feel like a physical energy punch, not a fade-up.
    /// Reduce motion: skip — bloom appears at hold level instantly.
    static let splashBloomIgnite: Animation = .timingCurve(0.0, 0.8, 0.2, 1.2, duration: 0.18)

    /// 0.35s settle — Bloom returning to hold level after ignition overshoot.
    /// timingCurve (0.22, 1.0, 0.36, 1.0): snappy ease-out, no overshoot.
    /// Fired after splashBloomIgnite completes — bloom coasts down to resting glow.
    /// Reduce motion: not reached — reduce motion skips the ignition entirely.
    static let splashBloomSettle: Animation = .timingCurve(0.22, 1.0, 0.36, 1.0, duration: 0.35)

    /// 0.04s ease — Zoom container micro-squeeze anticipation.
    /// timingCurve (0.4, 0.0, 0.6, 1.0): scales the container to 0.97× in 40ms
    /// immediately before the zoom fires. The brief compression makes the zoom
    /// feel launched rather than switched on — physical cause before effect.
    /// Reduce motion: skip — zoom is suppressed entirely under reduce motion.
    static let splashZoomAnticipate: Animation = .timingCurve(0.4, 0.0, 0.6, 1.0, duration: 0.04)

    /// 0.38s crash — Camera zoom into the spectrum line.
    /// timingCurve (0.12, 0.9, 0.2, 1.0): acceleration-dominant curve that
    /// commits to the zoom early and arrives with confidence. The transform origin
    /// is locked to LINE_Y — the line stays fixed while everything else expands.
    /// Reduce motion: skip — zoom does not fire, sequence jumps straight to tear.
    static let splashZoom: Animation = .timingCurve(0.12, 0.9, 0.2, 1.0, duration: 0.38)

    /// 0.28s snap — Panels separating on tear.
    /// timingCurve (0.2, 0.9, 0.2, 1.0): near-instant initial velocity communicates
    /// a physical snap rather than a slide. The 20ms ramp at the start (x1=0.2)
    /// provides a one-frame buffer against dropped first frames on older hardware.
    /// Pairs with a keyframe overshoot: panels travel to H*0.74 then settle at H*0.70.
    /// Reduce motion: replace with .easeOut(duration: 0.15) on opacity only —
    /// panels do not move, destination crossfades in.
    static let splashTear: Animation = .timingCurve(0.2, 0.9, 0.2, 1.0, duration: 0.28)

    /// Tear overshoot distance as a ratio of panel travel distance.
    /// Panels snap to (tearDistance * splashTearOvershoot) then settle back to tearDistance.
    /// 1.056 = ~5.6% overshoot — enough to read as physical momentum, not noticeable as error.
    /// Used by the KeyframeAnimator driving panel translation. Not an Animation value.
    static let splashTearOvershoot: CGFloat = 1.056

    // MARK: — OB Card Physics
    // These tokens are exclusive to the Onboarding canvas. They must never appear
    // in main-app screens — the table metaphor does not leave the OB boundary.
    // Reduce motion fallback for all card physics tokens: .easeOut(duration: 0.15)
    // on opacity only. Card travel stops. State changes are still confirmed.

    /// 0.85s custom ease — Card travelling from deal point to table position.
    /// Cubic bezier (0, 0, 0.2, 1): accelerates instantly off the deal point,
    /// decelerates sharply into the landing position. Communicates weight and arrival.
    /// Reduce motion: replace with .easeOut(duration: 0.15) on opacity — card appears in place.
    static let cardSlide: Animation = .timingCurve(0, 0, 0.2, 1, duration: 0.85)

    /// Spring — Card settling after it lands on the table.
    /// High damping (0.92) gives a single, confident settle with no secondary bounce.
    /// Fired immediately after cardSlide completes at the destination.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — skip the physical settle.
    static let cardSettle: Animation = .spring(response: 0.55, dampingFraction: 0.92)

    /// Spring — Card sliding from table scatter position to center-screen.
    /// response: 0.72, dampingFraction: 1.0 — critically damped, zero wobble per spec.
    /// Communicates the card arriving with impossible smoothness — no physical bounce.
    /// Fired after the landing breath pause in NamePhase.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — centers without travel.
    // critically damped — zero wobble per spec. was response:0.6, dampingFraction:0.75
    static let cardCenter: Animation = .spring(response: 0.72, dampingFraction: 1.0)

    /// 0.52s custom ease — Card pocketing to the corner deck.
    /// Cubic bezier (0.4, 0, 1, 1): eases into motion then accelerates off-screen.
    /// The asymmetric exit communicates the card is being filed away, not dismissed.
    /// Reduce motion: replace with .easeOut(duration: 0.15) on opacity — card disappears in place.
    static let cardPocket: Animation = .timingCurve(0.4, 0, 1, 1, duration: 0.52)

    /// 0.2s ease-in, delayed 0.32s — Card alpha fading out at the END of a pocket flight.
    /// Companion to cardPocket: the card stays visible for ~90% of the travel and dissolves
    /// INTO the corner deck rather than fading at launch (fading across the whole flight made
    /// it vanish in ~0.15s, so the handoff never visibly arrived). Used at every pocket site —
    /// NamePhase, DemoPhase, GenderPhase, CuriosityPhase handoff, and ThreeCardFanController.
    /// Reduce motion: via .reduceMotionSafe → .easeOut(duration: 0.15); the delay is dropped.
    static let pocketAlphaFade: Animation = .easeIn(duration: 0.2).delay(0.32)

    /// Spring — the ContextPhase carousel assembling up off the receding felt. A touch of
    /// overshoot (lower damping than the general `spring` 0.5/0.85) so the cards ARRIVE
    /// rather than fade in. FEEL-GATE — tuned on device.
    /// Reduce motion: guarded at the call site (only fires on the non-RM entrance path).
    static let carouselAssemble: Animation = .spring(response: 0.6, dampingFraction: 0.74)

    /// Spring — ConfirmationPhase fan dealing out of the corner deck onto the felt.
    /// Applied per-card with a staggered .delay() at the call site (rightmost deals first).
    /// Reduce motion: call site returns AppAnimation.fast instead.
    static let confirmDeal: Animation = .spring(response: 0.46, dampingFraction: 0.84)   // FEEL-GATE: snappier, livelier deal (was 0.55 / 0.86)

    /// Spring — ConfirmationPhase fan GATHERING into the deck on confirm (the keystone
    /// "six credentials become THE deck" moment). 0.8 response so the collapse reads as a
    /// deliberate gather, not a snap. Applied per-card with a staggered .delay() at the call site.
    /// Reduce motion: call site returns AppAnimation.fast instead.
    static let confirmGather: Animation = .spring(response: 0.8, dampingFraction: 0.85)

    /// Spring — ConfirmationPhase cards turning face-down as they gather (their truths go
    /// private on the way to the deck). Applied per-card with a staggered .delay() at the call site.
    /// Reduce motion: call site returns AppAnimation.fast instead.
    static let confirmFlip: Animation = .spring(response: 0.5, dampingFraction: 0.9)

    /// 0.36s custom ease — Curiosity sort card flung off-screen on a keep/pass commit.
    /// Cubic bezier (0.4, 0, 0.5, 1): eases off the release point then accelerates
    /// away — the card is thrown clear of the pile, not filed. Value is the locked
    /// feel reference (docs/prototypes/curiosity-swipe-prototype.html, --throw-ms).
    /// Reduce motion: replace with .easeOut(duration: 0.15) — card exits without travel.
    static let curiosityThrow: Animation = .timingCurve(0.4, 0, 0.5, 1, duration: 0.36)

    /// 0.22s custom ease — Next curiosity card rising into the top slot after a commit.
    /// Cubic bezier (0.2, 0.8, 0.2, 1): high initial velocity decelerating into place —
    /// the card snaps up crisply rather than settling with spring overshoot. Matches the
    /// locked feel reference (docs/prototypes/curiosity-swipe-prototype.html, commit()).
    /// Reduce motion: replace with .easeOut(duration: 0.15) — card appears in place.
    static let curiosityRise: Animation = .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.22)

    /// 0.58s custom ease — Card flipping face-up or face-down.
    /// Cubic bezier (0.4, 0, 0.6, 1): symmetric ease creates the sense of rotation
    /// through space. Applied to scaleX: 1 → 0 (first half) then -1 → 0 (second half).
    /// The renderer swaps VaylCardBack ↔ VaylCardFace at the scaleX = 0 moment.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — card face changes without rotating.
    static let cardFlip: Animation = .timingCurve(0.4, 0, 0.6, 1, duration: 0.58)

    /// 0.95s custom ease — Card lifting off the table toward the user.
    /// Cubic bezier (0.4, 0, 0.2, 1): gradual initial lift that carries through to the
    /// extended hold position. Elevation value drives shadow deepening simultaneously.
    /// Used for raise-and-confirm mechanic and full-bleed card expansion.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — card confirms raised state instantly.
    static let cardLift: Animation = .timingCurve(0.4, 0, 0.2, 1, duration: 0.95)

    /// Spring — Fan of cards spreading from a deck.
    /// Lower damping (0.88) than cardSettle allows a soft overshoot as cards fan apart,
    /// reinforcing the sense of physical playing cards spreading under slight tension.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — fan state appears without travel.
    static let deckFan: Animation = .spring(response: 0.70, dampingFraction: 0.88)

    /// 0.72s ease — Deck weave shuffle (interleaving two halves).
    /// Standard ease (0.25, 0.46, 0.45, 0.94) used here because the weave is a
    /// composed sequence — each card's motion looks hand-applied, not mechanical.
    /// Applied per-card with staggered delays, not to the deck as a whole.
    /// Reduce motion: skip the shuffle sequence entirely — deck goes directly to squared state.
    static let deckWeave: Animation = .timingCurve(0.25, 0.46, 0.45, 0.94, duration: 0.72)

    /// 0.65s ease-in — Foil surface dissolving after sufficient tears.
    /// Ease-in curve communicates the foil burning outward from tear edges —
    /// starts slow at the breach, accelerates as integrity collapses.
    /// Reduce motion: replace with .easeOut(duration: 0.15) on opacity — foil disappears instantly.
    static let foilDissolve: Animation = .easeIn(duration: 0.65)

    /// 0.70s custom ease — Table surface receding during hand-raise and full-bleed phases.
    /// Cubic bezier (0.4, 0, 0.6, 1): symmetric ease so the table feels like it is
    /// physically pulling back rather than fading. Applied to tableFade in VaylDirector.
    /// Reduce motion: replace with .easeOut(duration: 0.15) on opacity — table dims instantly.
    static let tableRecede: Animation = .timingCurve(0.4, 0, 0.6, 1, duration: 0.70)

    /// 0.70s ease-out — The felt blooming UP onto the table (the inverse of tableRecede).
    /// One characteristic weight for every felt fade-IN after the first arrival, so the
    /// table reads as one physical surface: ModeSelect entry, Confirmation entry, and the
    /// Context felt re-emerging after the carousel. (The very first felt arrival in Demo
    /// stays on the heavier cinematicFade — the world's debut.) FEEL-GATE.
    /// Reduce motion: via .reduceMotionSafe → .easeOut(duration: 0.15) — felt appears.
    static let tableBloom: Animation = .easeOut(duration: 0.70)

    /// 1.0s ease-in-out — OB atmosphere crossfade between phases (OnboardingAtmosphere).
    /// Slow + geological so the background shifts beneath attention, never snappy. Single
    /// owner of the config crossfade — the canvas no longer double-animates it.
    /// Reduce motion: ambient background; acceptable as-is (opacity-only crossfade).
    static let atmosphereShift: Animation = .easeInOut(duration: 1.0)

    /// Spring — Corner deck receiving a newly pocketed card.
    /// Fast response (0.40) makes the receive feel reactive to the arriving card.
    /// The glow pulse uses this same token and fades after 600ms.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — card count increments without bounce.
    static let deckReceive: Animation = .spring(response: 0.40, dampingFraction: 0.85)

    /// 0.50s ease-out — Dealer line projecting onto the felt surface.
    /// Matched to the scaleY (0.94 → 1.0) and opacity entrance of ProjectedTextView.
    /// Text must be fully legible before the phase interaction begins — do not rush this token.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — text appears without scaling.
    static let textProject: Animation = .easeOut(duration: 0.50)

    /// 3.2s ease-in-out repeating — Subtle card surface breathe on the table.
    /// Applied to the elevation/glow of a stationary card while it awaits user input.
    /// Communicates that the card is alive and waiting, not frozen.
    /// This is an ambient animation — remove entirely under reduce motion.
    /// Use .ambientAnimation(AppAnimation.cardBreathe, value:) at every call site.
    static let cardBreathe: Animation = .easeInOut(duration: 3.2).repeatForever(autoreverses: true)

    /// 0.29s per half — One half of a card flip (scaleX 1→0 or 0→-1).
    /// Two halves compose the full 0.58s cardFlip total.
    /// Reduce motion: skip flip entirely — face swaps without rotation.
    static let cardFlipHalf: Animation = .timingCurve(0.4, 0, 0.6, 1, duration: 0.29)

    /// 0.42s per half — Demo card 3D flip. Same cubic as cardFlipHalf (0.4,0,0.6,1)
    /// but slower — DemoPhase is the user's first flip encounter; extra weight adds ceremony.
    /// Two halves compose a full 0.84s Demo flip. Not interchangeable with cardFlipHalf.
    /// Reduce motion: skip flip entirely — face swaps without rotation.
    static let demoFlipHalf: Animation = .timingCurve(0.4, 0, 0.6, 1, duration: 0.42)

    /// 0.52s cubic — 3D edge-turn on ExperienceLevelPhase card flip.
    /// timingCurve (0.45, 0.05, 0.55, 0.95): slight ease-in gathering momentum,
    /// then easing out as the card faces the user. Not a general flip token.
    /// Reduce motion: skip the turn — face swaps instantly.
    static let cardTurn3D: Animation = .timingCurve(0.45, 0.05, 0.55, 0.95, duration: 0.52)

    // MARK: — DemoPhase Sequence
    // Tokens for the Demo "I want ___" card: sentence melt → verb cycle → seal → dissolve.
    // These are ceremony-level animations that ONLY belong in DemoPhase — do not reuse.

    /// 1.05s ease-out — "I want" sentence dissolving / melting onto the card face.
    /// Deliberately slow — the melt is the first "magic" moment the user sees.
    /// Reduce motion: replace with AppAnimation.fast at call site.
    static let demoSentenceMelt: Animation = .easeOut(duration: 1.05)

    /// 0.24s ease-in-out — Verb slot-machine crossfade during the intro cycle.
    /// Short enough that the cycle feels quick and mechanical.
    /// Reduce motion: cycle is skipped entirely at call site.
    static let demoVerbCrossfade: Animation = .easeInOut(duration: 0.24)

    /// Spring — Demo card gliding to stage centre. response: 0.95, dampingFraction: 1.0 —
    /// critically damped (no oscillation), deliberately slower than cardCenter (0.72s).
    /// The demo card should feel weighty arriving at its presentation spot.
    /// Reduce motion: replace with AppAnimation.standard at call site.
    static let demoCenterDeliberate: Animation = .spring(response: 0.95, dampingFraction: 1.0)

    /// 0.35s ease-in-out — Sentence fusing into the seal line (chevron + prompt resolve).
    /// Runs before the dissolve — traces the line, THEN breaks it into motes.
    /// Reduce motion: replace with AppAnimation.fast at call site.
    static let sealTrace: Animation = .easeInOut(duration: 0.35)

    /// 1.0s ease-out — Card dissolving into spectrum motes after seal.
    /// Runs concurrently with the pocket animation — motes lift off before card flies.
    /// sealBloom (0.5s) uses AppAnimation.slow (exact match) — no separate token.
    /// Reduce motion: dissolve is skipped entirely at call site.
    static let sealDissolve: Animation = .easeOut(duration: 1.0)

    /// 0.60s custom ease — Table rim burst decaying after card lands.
    /// Cubic bezier (0.2, 0.8, 0.4, 1.0). was 0.50s — corrected to spec.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let rimBurstDecay: Animation = .timingCurve(0.2, 0.8, 0.4, 1.0, duration: 0.60)

    /// 0.55s ease-in — Blur ramping in as card lifts toward the camera.
    /// Also used for tableFade during the same lift sequence.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let liftBlurRamp: Animation = .easeIn(duration: 0.55)

    /// 0.40s ease-in — Card screen alpha fading out at peak of lift sequence.
    /// Ease-in communicates the card accelerating away from the user's plane.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let liftCardFade: Animation = .easeIn(duration: 0.40)

    /// 0.55s ease-in — Table surface fading during the lift sequence.
    static let tableFadeOut: Animation = .easeIn(duration: 0.55)

    /// 0.45s ease-out — Card surface properties restoring after name is submitted.
    /// Scale and angle are reset instantly before this fires — only opacity
    /// and blur animate, producing a cross-fade rather than a zoom-in.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let cardRestore: Animation = .easeOut(duration: 0.45)

    /// 0.52s ease-out — Name input UI fading in after card lift sequence.
    /// Reduce motion: replaced with .linear(duration: 0.1) at call site.
    static let uiFadeIn: Animation = .easeOut(duration: 0.52)

    /// Spring — Greeting "Hi [name]" row settling into view after typing pause.
    /// response: 1.1, dampingFraction: 0.88 — slow deliberate arrival with
    /// minimal overshoot. The greeting should feel earned, not snappy.
    /// Reduce motion: replace with AppAnimation.standard at call site.
    static let greetingSettle: Animation = .spring(response: 1.1, dampingFraction: 0.88)

    /// 0.35s ease-in-out — Header text fading out/in during the crossfade
    /// sequence after the name is confirmed. Applied per-line.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let headerFade: Animation = .easeInOut(duration: 0.35)

    /// Spring — Keystroke micro-bounce on underline. High stiffness, low damping —
    /// snappy downward kick that reads as the line reacting to each character arriving.
    /// Reduce motion: skip entirely — no bounce fires under reduce motion.
    static let keystrokeBounce: Animation = .interpolatingSpring(stiffness: 600, damping: 12)

    /// Spring — Underline returning to baseline after keystroke bounce.
    /// Lower stiffness than keystrokeBounce — the return is softer than the kick.
    /// Reduce motion: skip entirely — no bounce fires under reduce motion.
    static let keystrokeBounceReturn: Animation = .interpolatingSpring(stiffness: 400, damping: 18)

    /// 0.40s ease-out — Impact ring expanding outward after card lands on table.
    static let impactRingDecay: Animation = .easeOut(duration: 0.40)

    /// 0.35s ease-out — Radial burst fading after card flip completes.
    static let flipBurstDecay: Animation = .easeOut(duration: 0.35)

    /// 0.45s ease-out — Spectrum underline sweeping in on first field focus.
    static let lineReveal: Animation = .easeOut(duration: 0.45)

    /// 0.30s ease-in — Coach mark or hint element fading into view.
    static let coachMarkIn: Animation = .easeIn(duration: 0.30)

    /// 0.55s ease-in-out — Coach mark travelling downward during the hint sequence.
    static let coachMarkTravel: Animation = .easeInOut(duration: 0.55)

    /// 0.35s ease-out — Coach mark or hint element fading out of view.
    static let coachMarkOut: Animation = .easeOut(duration: 0.35)

    /// Spring — Screen nudging downward to hint at the swipe affordance.
    /// response: 0.45, dampingFraction: 0.62 — perceptible overshoot that
    /// communicates the screen is moveable.
    static let screenNudge: Animation = .spring(response: 0.45, dampingFraction: 0.62)

    /// Spring — Screen returning to baseline after the nudge hint.
    /// Higher damping than screenNudge — the return is settled, not bouncy.
    static let screenNudgeReturn: Animation = .spring(response: 0.55, dampingFraction: 0.78)

    /// 0.25s ease-in — Hint arrow chevron fading into view.
    static let hintArrowIn: Animation = .easeIn(duration: 0.25)

    /// 0.45s ease-out — Hint arrow chevron fading out of view.
    static let hintArrowOut: Animation = .easeOut(duration: 0.45)

    /// 0.55s ease-in-out — Name glow pulse expanding on the greeting.
    /// Applied in both directions: scale up and scale back to 1.0.
    static let glowPulse: Animation = .easeInOut(duration: 0.55)

    /// 4.0s ease-in-out — VaylFlourishView ambient breathing pulse.
    /// Apply .repeatForever(autoreverses: true) at the call site.
    /// This is an ambient animation — remove entirely under reduce motion.
    static let flourishBreath: Animation = .easeInOut(duration: 4.0)

    // MARK: — Gender Phase: Swipe Hint
    // An intermittent "swipe right" demo that runs only after the user has settled the
    // gender drum — i.e. has actively made a choice and earned the prompt. The card
    // flicks right then springs home, pauses, and repeats, modeled on how dating apps
    // demonstrate a right-swipe. No rotation: pure directional translation so it reads
    // as the swipe gesture itself, not a tilt. Stops the instant the user grabs the card
    // or re-scrolls the drum.
    // Ambient: suppressed entirely under reduce motion (guarded at the call site by
    // the View's accessibilityReduceMotion value). Settle to rest with the spring /
    // AppAnimation.standard when the hint stops.

    /// 0.26s ease-out — Card throwing right during one swipe-hint flick.
    /// Fast departure that reads as the start of a real right-swipe; paired with
    /// AppAnimation.spring for the settle back home, then a still pause before repeating.
    /// Reduce motion: never fires — the start branch is guarded by reduceMotion.
    static let swipeHintFlick: Animation = .easeOut(duration: 0.26)

    // MARK: — FounderLetterPhase
    /// 0.45s ease-in-out — The OB's final swipe-down descent ("curtain falls").
    /// Heavier than exit (0.2s easeIn) — the last gesture deserves weight.
    /// Half of the letter's own 0.4s arrival, so it mirrors rather than outdoes it.
    /// Apply .reduceMotionSafe at the call site.
    static let curtainFall: Animation = .easeInOut(duration: 0.45)

    // MARK: — Desire Map
    // Tokens for the ten-screen Desire Map flow (rater + reveal + paywall).
    // Two classes, same rules as the rest of this file:
    //   Reactive  — screen transitions, star ignitions, sheet rises, depth-push.
    //               Reduce motion fallback: .easeOut(duration: 0.15).
    //   Ambient   — sparkle cadence, hesitant line sketch, charted hold.
    //               Disable entirely under reduce motion — skip the .task / loop,
    //               hold the static state.
    //
    // Starting values tuned from the storyboard prototypes. Bryan dials final feel
    // on device — do not lock these before the device pass.

    // Reveal reactive
    /// 0.80s ease-out — Spectrum-bloom entrance wash as the rater opens.
    /// The one ceremonial entrance: the start screen recedes and Q1 emerges from depth.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let desireRevealBloom: Animation = .easeOut(duration: 0.80)

    /// 0.72s ease-out — Free star glow blooming in on reveal open.
    /// Fires on .onAppear of the free star; the star ignites to full then sparkles.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — star appears lit, no bloom.
    static let desireStarIgnite: Animation = .easeOut(duration: 0.72)

    /// 0.56s overshoot — a matched star blooming from two seeds into one bright star (the merge
    /// settle). The timingCurve's y2 > 1 produces a soft overshoot past full size before it settles.
    /// Feel reference: docs/prototypes/desire-map-match-ceremony.html
    /// Reduce motion: the two-seed entrance is skipped entirely; the star renders lit.
    static let desireStarMergeSettle: Animation = .timingCurve(0.34, 1.3, 0.5, 1, duration: 0.56)

    /// 0.56s — the two seeds (your purple, their magenta) drifting together as the star ignites.
    /// Slightly less overshoot than the bloom so the points arrive cleanly into one.
    /// Reduce motion: the entrance is skipped.
    static let desireStarSeedDrift: Animation = .timingCurve(0.34, 1.2, 0.5, 1, duration: 0.56)

    /// 0.18s — the bloom starts this long after the seeds begin converging, so the star brightens
    /// as the seeds arrive rather than before. Consumed as a `.delay`. Reduce motion: unused.
    static let desireStarMergeBloomDelay: Double = 0.18

    /// 0.76s ease-out — Constellation lines drawing on at the reveal.
    /// Applied to a trimFraction (0 → 1) on the confident-mode path in ConstellationField.
    /// Reduce motion: lines appear at full opacity, no draw-on travel.
    static let desireLineDraw: Animation = .easeOut(duration: 0.76)

    /// 0.50s ease-out — Detail / full-map / paywall sheet rising from the bottom.
    /// Applied to the .move(edge: .bottom) transition inside the cover's sheet host.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — sheet appears in place.
    static let desireSheetRise: Animation = .easeOut(duration: 0.50)

    // Rater depth-push reactive
    /// 0.20s ease-in — Current question receding on answer: scale .93 + translateY 7 + fade.
    /// Fast exit clears the stage for the incoming question without lingering.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — question disappears.
    static let desireDepthExit: Animation = .easeIn(duration: 0.20)

    /// 0.34s ease-out — Next question emerging from depth: scale 1.07 → 1 + fade-in.
    /// Slightly longer than exit — the arrival has more presence than the departure.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — question appears.
    static let desireDepthEnter: Animation = .easeOut(duration: 0.34)

    /// 0.56s ease-out — Answer star rising into the personal sky above.
    /// Synced to fire alongside desireDepthExit so the star lifts as the question recedes.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — star appears in sky position.
    static let desireStarRise: Animation = .easeOut(duration: 0.56)

    // Finish-beat reactive
    /// 0.35s ease-out — Last question and answer rows fading out at completion.
    /// Clears the stage for the finish-flair star rise.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let desireFinishFade: Animation = .easeOut(duration: 0.35)

    /// 0.80s ease-out — Last star rising with extra ignite + sparkle burst on completion.
    /// Brighter and slower than a normal desireStarRise — the climactic beat of rating.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — final star appears lit.
    static let desireFinishFlair: Animation = .easeOut(duration: 0.80)

    /// 0.60s ease-out — "Your map is charted." copy + hesitant constellation lines fading in.
    /// Fired after the finish-flair star settles, not immediately after the last rate().
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let desireChartedFadeIn: Animation = .easeOut(duration: 0.60)

    // Desire Map ambient (raw Double — not Animation instances)
    // All three: disable the .task / loop entirely when reduce motion is active.
    // The static state (a resting cross + glow, faint partial lines) must read without motion.

    /// 0.95s — Total duration of one sparkle keyframe (scale 0→1→0.55, opacity 0→1→0, slight rotation).
    /// Not an Animation — consumed by KeyframeAnimator total. Divide across CubicKeyframe tracks at the call site.
    /// Reduce motion: skip the .task trigger entirely; sparkle never fires.
    static let desireSparkleDuration: Double = 0.95

    /// 3.5s — Mean cadence for free/active star sparkle.
    /// Randomize ±55–160% at the call site (.task sleeps desireSparkleFreeRate * factor)
    /// so stars twinkle out of phase rather than in sync.
    /// Reduce motion: .task is never started.
    static let desireSparkleFreeRate: Double = 3.5

    /// 7.0s — Mean cadence for locked/dim star sparkle.
    /// Same randomize recipe as desireSparkleFreeRate; locked stars twinkle rarely.
    /// Reduce motion: .task is never started.
    static let desireSparkleLockedRate: Double = 7.0

    /// 2.0s — Hold at the charted screen before auto-advancing (tap-anywhere skips).
    /// Not an Animation — consumed by Task.sleep at the call site.
    /// Reduce motion: use as-is; the hold is timing, not motion.
    static let desireChartedHold: Double = 2.0

    /// 4.2s — One full pass of the hesitant constellation line sketch loop.
    /// Lines draw partway, pull back, fade, and restart — never locking.
    /// Not an Animation — consumed by a repeating loop at the call site.
    /// Reduce motion: loop never starts; lines hold at a faint partial-draw static state.
    static let desireHesitantSketch: Double = 4.2

    // Reveal 3-beat ceremony holds (raw Double — consumed by Task.sleep in DesireRevealStore).
    // Reduce motion: collapse both holds to ~0 so the reveal resolves instantly (no timed ceremony).

    /// 1.5s — Beat 1 → Beat 2: the free star settles before the locked gap appears.
    static let desireBeatHold1: Double = 1.5

    /// 1.2s — Beat 2 → Beat 3: the gap holds before the paywall rises.
    static let desireBeatHold2: Double = 1.2

    /// 0.08s — Per-locked-row stagger step (added per locked match before the Beat-2 hold begins).
    static let desireBeatStaggerStep: Double = 0.08

    /// 0.14s — Base offset before the locked-row stagger (the first row's lead-in).
    static let desireBeatStaggerBase: Double = 0.14

    /// 0.36s — A single locked teaser row fading/staggering into the gap (Beat 2).
    /// Reduce motion: falls back via `.reduceMotionSafe` to a fast opacity confirm.
    static let desireLockedRowEnter: Animation = .easeOut(duration: 0.36)

    // Reveal ceremony — the telegraphed constellation assembly (DesireConstellationView).
    // Stars light in the variant's order with a budgeted stagger; lines draw when both ends are
    // lit; a telegraph wind-up precedes. Reduce motion: skip to the static lit sky (no assembly).

    /// 1.4s — total budget to light all non-hero stars; per-star stagger = budget / count (clamped),
    /// so many stars do not drag.
    static let desireCeremonyBudget: Double = 1.4
    /// 0.5s — gap after the hero ignites before the rest begin (Gather).
    static let desireCeremonyHeroLead: Double = 0.5
    /// Per-star stagger clamps during the assembly.
    static let desireCeremonyStaggerMin: Double = 0.09
    static let desireCeremonyStaggerMax: Double = 0.30
    /// 1.7s — the Sweep band's full pass across the field; stars light as it reaches them.
    static let desireSweepDuration: Double = 1.7
    /// Linear sweep of the telegraph band across the field.
    static let desireSweepBand: Animation = .linear(duration: desireSweepDuration)
    /// 0.64s ease-in — the Gather telegraph contracting a point of light to center before the hero.
    static let desireGatherPulse: Animation = .easeIn(duration: 0.64)
    /// 0.5s — how long the Gather wind-up holds before the hero forms. Consumed by Task.sleep.
    static let desireGatherLead: Double = 0.5

    // Vayl mark ceremony — the one-shot "map charted" moment (MapChartedMoment).
    // Reduce motion: skip both; the mark is shown fully drawn and the copy is shown at once.

    /// 1.0s — The aperture draws/assembles on: rings trim in, glow blooms, core ignites.
    static let markDraw: Animation = .easeOut(duration: 1.0)

    /// 0.5s — The copy fades up after the mark has mostly assembled.
    static let markCopyRise: Animation = .easeOut(duration: 0.5)

    /// 0.9s — How long the copy waits for the mark to draw before rising (a `.delay`).
    static let markCopyDelay: Double = 0.9

    /// 2.8s — Hold after the copy resolves before the moment auto-advances back to Home.
    /// Reduce motion: measured from appear (no draw lead). Consumed by Task.sleep.
    static let markHold: Double = 2.8

    // MARK: — Pulse Aura
    // Ambient durations for PulseAura (raw Doubles — construct with .easeInOut at call site).
    // All three are ambient: guard with `!reduceMotion` in PulseAura; never fire under reduce motion.
    // FEEL: all values tuned on device against docs/prototypes/pulse-aura-glass.html.

    /// 5.4s — Aura body breathe (scale 1 ↔ 1.045, autoreverses). FEEL: tune on device.
    static let auraBreathe: Double = 5.4

    /// 7.0s — Caustic drift, one leg (offsets alternate, autoreverses). FEEL: tune on device.
    static let auraCausticDrift: Double = 7.0

    /// 17.0s — Glass sweep full non-reversing cycle. The strip travels the full frame;
    /// the visible pass through the circle is ~10% of travel = ~1.7s. FEEL: tune on device.
    static let auraGlassSweep: Double = 17.0
}

// MARK: — Reduce Motion Helpers

extension Animation {

    /// Returns the reduce-motion safe version of a reactive animation.
    /// Replaces spatial movement with a fast opacity confirmation.
    /// Uses UIAccessibility directly — safe to call outside of a View context.
    /// Use at every call site where the animation drives positional change.
    ///
    /// Example:
    ///   withAnimation(.standard.reduceMotionSafe) { ... }
    var reduceMotionSafe: Animation {
        if UIAccessibility.isReduceMotionEnabled {
            return .easeOut(duration: 0.15)
        }
        return self
    }
}

extension View {

    /// Conditionally applies an ambient animation only when reduce motion is not active.
    /// Uses a Transaction to bind the animation to a specific value — avoids the deprecated
    /// unbound .animation() modifier which caused unpredictable propagation in iOS 15+.
    /// When reduce motion is active, the animation is stripped entirely from the transaction.
    /// The view renders in its static state — not slowed down, fully removed.
    ///
    /// Example:
    ///   myGlowView
    ///       .ambientAnimation(.easeInOut(duration: AppAnimation.ambientPulse).repeatForever(),
    ///                         value: isAnimating)
    func ambientAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        self.transaction { transaction in
            if UIAccessibility.isReduceMotionEnabled {
                transaction.animation = nil
            } else {
                transaction.animation = animation
            }
        }
    }
}

```

---

## File: `Vayl/Features/Settings/SettingsView.swift` {#file-vayl-features-settings-settingsview-swift}

```swift
// Vayl/Features/Settings/SettingsView.swift

import SwiftUI
import SwiftData

// MARK: - Main view

struct SettingsView: View {
    var isTab: Bool = false

    @Environment(AppState.self)          private var appState
    @Environment(EntitlementStore.self)  private var entitlements
    @Environment(AuthService.self)       private var authService
    @Environment(\.dismiss)             private var dismiss
    @Environment(\.modelContext)         private var modelContext

    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }

    // Sub-screen navigation
    @State private var showYou:           Bool = false
    @State private var showPrivacy:       Bool = false
    @State private var showNotifications: Bool = false
    @State private var showAppearance:    Bool = false
    @State private var showPartner:       Bool = false

    // Sheet / dialog state
    @State private var showInvite:          Bool = false
    @State private var showJoin:            Bool = false
    @State private var showUnlink:          Bool = false
    @State private var showSignOutConfirm:  Bool = false
    @State private var showDeleteConfirm:   Bool = false

    var body: some View {
        GeometryReader { geo in
            let layout = AppLayout.from(geo)
            ZStack {
                AppColors.void.ignoresSafeArea()
                OnboardingAtmosphere(config: .stat).ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        settingsHeader
                        youSection
                        partnerSection
                        appSection
                        accountSection
                        aboutSection
                        membershipCard
                        versionLabel
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .frame(width: layout.screenWidth)
            .vaylSheet(isPresented: $showYou, heightFraction: 0.92, screenHeight: layout.screenHeight) {
                SettingsIdentityView()
            }
            .vaylSheet(isPresented: $showPrivacy, heightFraction: 0.92, screenHeight: layout.screenHeight) {
                SettingsPrivacyView()
            }
            .vaylSheet(isPresented: $showNotifications, heightFraction: 0.92, screenHeight: layout.screenHeight) {
                SettingsNotificationsView()
            }
            .vaylSheet(isPresented: $showAppearance, heightFraction: 0.92, screenHeight: layout.screenHeight) {
                SettingsAppearanceView()
            }
            .vaylSheet(isPresented: $showPartner, heightFraction: 0.92, screenHeight: layout.screenHeight) {
                SettingsPartnerView()
            }
        }
        .sheet(isPresented: $showInvite) {
            PairingInviteView(store: PairingStore(modelContainer: modelContext.container, appState: appState))
                .environment(appState)
        }
        .sheet(isPresented: $showJoin) {
            PairingJoinView(store: PairingStore(modelContainer: modelContext.container, appState: appState))
                .environment(appState)
        }
        .confirmationDialog("Unlink partner?", isPresented: $showUnlink, titleVisibility: .visible) {
            Button("Unlink", role: .destructive) {
                // Unlink UX deferred to V1.1
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You and your partner will lose access to shared content.")
        }
        .confirmationDialog("Sign out?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) {
                Task { await authService.signOut() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete account?", isPresented: $showDeleteConfirm) {
            Button("Delete everything", role: .destructive) {
                // Full deletion deferred to V1.1 — requires server-side cleanup
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your data and cannot be undone.")
        }
    }

    // MARK: - Header

    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text("Settings")
                    .font(AppFonts.overline)
                    .tracking(2)
                    .foregroundStyle(AppColors.textSectionLabel)
                Spacer()
                if !isTab {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(AppColors.glassSurface))
                    }
                    .buttonStyle(PressableCardStyle())
                    .accessibilityLabel("Close settings")
                }
            }
            .padding(.top, AppSpacing.md)

            Text(appState.displayName.isEmpty ? "Settings." : "\(appState.displayName).")
                .font(AppFonts.screenTitle)
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.top, AppSpacing.xs)
                .padding(.bottom, AppSpacing.sm)
        }
    }

    private func spectrumBadge(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.overline)
            .tracking(1.5)
            .foregroundStyle(
                LinearGradient(
                    colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(AppColors.spectrumPurple.opacity(0.10))
                    .overlay(Capsule().strokeBorder(AppColors.spectrumPurple.opacity(0.32), lineWidth: 1))
            )
    }

    private func plainBadge(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.overline)
            .tracking(1.5)
            .foregroundStyle(AppColors.textSecondary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(AppColors.glassSurface)
                    .overlay(Capsule().strokeBorder(AppColors.borderSubtle, lineWidth: 1))
            )
    }

    // MARK: - Membership

    @ViewBuilder
    private var membershipCard: some View {
        SettingsSectionLabel(text: "Membership")
        if entitlements.isCore {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.spectrumCyan)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(AppColors.spectrumCyan.opacity(0.12))
                            .overlay(RoundedRectangle(cornerRadius: AppRadius.sm)
                                .strokeBorder(AppColors.spectrumCyan.opacity(0.34), lineWidth: 1))
                    )
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Vayl Lifetime")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Full access, forever.")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                Spacer()
                Button("Restore") {
                    // Not wired in V1
                }
                .font(AppFonts.caption.bold())
                .foregroundStyle(AppColors.spectrumCyan)
                .buttonStyle(PressableCardStyle())
            }
            .padding(AppSpacing.md)
            .vaylGlassCard(accent: AppColors.spectrumCyan, radius: AppRadius.container)
            .overlay(alignment: .top) { spectrumTopLine }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.container))
        } else {
            Button {
                // Not wired in V1 — open paywall
            } label: {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppColors.spectrumPurple)
                            .accessibilityHidden(true)
                        Text("Vayl · Lifetime")
                            .font(AppFonts.overline)
                            .tracking(2)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Text("Unlock every deck and the full Desire Map.")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)

                    Group {
                        Text("$24.99")
                            .font(AppFonts.bodyMedium.bold())
                            .foregroundStyle(AppColors.textPrimary)
                        + Text("  once · yours to keep")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PressableCardStyle())
            .background(
                RoundedRectangle(cornerRadius: AppRadius.container, style: .continuous)
                    .fill(LinearGradient(
                        colors: [
                            AppColors.spectrumCyan.opacity(0.09),
                            AppColors.spectrumPurple.opacity(0.12),
                            AppColors.spectrumMagenta.opacity(0.09)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .vaylGlassCard(radius: AppRadius.container)
            .overlay(alignment: .top) { premiumHairline }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.container))
        }
    }

    private var spectrumTopLine: some View {
        LinearGradient(
            colors: [
                .clear,
                AppColors.spectrumCyan.opacity(0.55),
                AppColors.spectrumPurple.opacity(0.5),
                AppColors.spectrumMagenta.opacity(0.55),
                .clear
            ],
            startPoint: .leading, endPoint: .trailing
        )
        .frame(height: 1)
    }

    private var premiumHairline: some View {
        let gradient = LinearGradient(
            colors: [.clear, AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta, .clear],
            startPoint: .leading, endPoint: .trailing
        )
        return ZStack(alignment: .top) {
            gradient.frame(height: 8).blur(radius: 5).opacity(0.55)
            gradient.frame(height: 1)
        }
    }

    // MARK: - You

    private var youSection: some View {
        Button { showYou = true } label: {
            HStack(spacing: AppSpacing.md) {
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(AppColors.glassSurface)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppColors.textSecondary)
                            .accessibilityHidden(true)
                    )
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Profile")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)

                    let sub = [
                        profile?.pronouns.isEmpty == false ? profile?.pronouns.joined(separator: "/") : nil
                    ].compactMap { $0 }.joined(separator: " · ")
                    if !sub.isEmpty {
                        Text(sub)
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    } else {
                        Text("Tap to complete your profile")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textMuted)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(AppSpacing.md)
        }
        .buttonStyle(PressableCardStyle())
        .vaylGlassCard(radius: AppRadius.container)
        .overlay(alignment: .top) { spectrumTopLine }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.container))
    }

    // MARK: - Partner

    private var partnerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionLabel(text: "Partner")
            SettingsCard {
                if appState.linkState == .linked {
                    VStack(spacing: 0) {
                        Button { showPartner = true } label: {
                            SettingsNavRow(
                                icon: "person.2.fill",
                                label: "Linked",
                                subtitle: "Add relationship details"
                            )
                        }
                        .buttonStyle(PressableCardStyle())

                        Divider().overlay(AppColors.borderSubtle)

                        Button { showUnlink = true } label: {
                            SettingsNavRow(
                                icon: "person.badge.minus",
                                label: "Unlink partner",
                                labelColor: AppColors.destructive,
                                iconTint: AppColors.destructive,
                                iconBg: AppColors.destructive.opacity(0.09)
                            )
                        }
                        .buttonStyle(PressableCardStyle())
                    }
                } else {
                    VStack(spacing: 0) {
                        Button { showInvite = true } label: {
                            SettingsNavRow(
                                icon: "person.badge.plus",
                                label: "Invite a partner",
                                subtitle: "Share a code to link your apps"
                            )
                        }
                        .buttonStyle(PressableCardStyle())

                        Divider().overlay(AppColors.borderSubtle)

                        Button { showJoin = true } label: {
                            SettingsNavRow(
                                icon: "link.badge.plus",
                                label: "Enter a code"
                            )
                        }
                        .buttonStyle(PressableCardStyle())
                    }
                }
            }
        }
    }

    // MARK: - App (Privacy, Notifications, Appearance)

    private var appSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionLabel(text: "App")
            SettingsCard {
                VStack(spacing: 0) {
                    Button { showPrivacy = true } label: {
                        SettingsNavRow(icon: "lock.fill", label: "Privacy & safety")
                    }
                    .buttonStyle(PressableCardStyle())

                    Divider().overlay(AppColors.borderSubtle)

                    Button { showNotifications = true } label: {
                        SettingsNavRow(icon: "bell.fill", label: "Notifications")
                    }
                    .buttonStyle(PressableCardStyle())

                    Divider().overlay(AppColors.borderSubtle)

                    Button { showAppearance = true } label: {
                        SettingsNavRow(icon: "paintpalette.fill", label: "Appearance")
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
        }
    }

    // MARK: - Account & Data

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionLabel(text: "Account & data")
            SettingsCard {
                VStack(spacing: 0) {
                    Button { showSignOutConfirm = true } label: {
                        SettingsNavRow(icon: "rectangle.portrait.and.arrow.right", label: "Sign out")
                    }
                    .buttonStyle(PressableCardStyle())

                    Divider().overlay(AppColors.borderSubtle)

                    Button {} label: {
                        SettingsNavRow(icon: "square.and.arrow.up", label: "Export my data")
                    }
                    .buttonStyle(PressableCardStyle())

                    Divider().overlay(AppColors.borderSubtle)

                    Button { showDeleteConfirm = true } label: {
                        SettingsNavRow(
                            icon: "trash.fill",
                            label: "Delete account",
                            labelColor: AppColors.destructive,
                            iconTint: AppColors.destructive,
                            iconBg: AppColors.destructive.opacity(0.09)
                        )
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionLabel(text: "About")
            SettingsCard {
                VStack(spacing: 0) {
                    Button {} label: {
                        SettingsNavRow(icon: "hand.raised.fill", label: "Privacy policy")
                    }
                    .buttonStyle(PressableCardStyle())

                    Divider().overlay(AppColors.borderSubtle)

                    Button {} label: {
                        SettingsNavRow(icon: "doc.text.fill", label: "Terms of service")
                    }
                    .buttonStyle(PressableCardStyle())

                    Divider().overlay(AppColors.borderSubtle)

                    Button {} label: {
                        SettingsNavRow(icon: "questionmark.circle.fill", label: "Support")
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
        }
    }

    // MARK: - Version

    private var versionLabel: some View {
        Text("Vayl · v0.1.0")
            .font(AppFonts.overline)
            .tracking(1)
            .foregroundStyle(AppColors.textMuted)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, AppSpacing.lg)
    }
}

// MARK: - Shared sub-screen shell

struct SettingsSubScreenShell<Content: View>: View {
    let title: String
    var onBack: (() -> Void)? = nil
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            OnboardingAtmosphere(config: .stat).ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        onBack?()
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Settings")
                                .font(AppFonts.bodyMedium)
                        }
                        .foregroundStyle(AppColors.textSecondary)
                    }
                    .buttonStyle(PressableCardStyle())
                    .padding(.top, AppSpacing.md)

                    Text(title)
                        .font(AppFonts.screenTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.top, AppSpacing.sm)

                    content
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let state = AppState()
    state.displayName = "Jordan"
    return SettingsView()
        .preferredColorScheme(.dark)
        .environment(state)
        .environment(EntitlementStore(modelContainer: .previewContainer, appState: state))
        .environment(AuthService())
        .modelContainer(ModelContainer.previewContainer)
}
#endif

```

---

