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
            DesireStarfield().ignoresSafeArea()

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
        case .empty(let reason):
            // Three honest empties (review 2026-07-09 §1.4) — never a verdict about the
            // couple, and the unpaired variant never references a partner who isn't there.
            switch reason {
            case .unpaired:
                emptyState(
                    icon: "sparkles",
                    title: "Where you meet lives here",
                    message: "Pair with your partner, then finish both maps to see what you share."
                )
            case .waitingForPartner:
                emptyState(
                    icon: "sparkles",
                    title: "No shared matches yet",
                    message: "When you've both finished your maps, what you share appears here."
                )
            case .noMatches:
                emptyState(
                    icon: "sparkles",
                    title: "No mutual matches this round",
                    message: "That's real information too, and it's a starting point, not a verdict. Everything you each said is still yours, privately."
                )
            }
        case .ready:
            beatReveal
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            VaylCloseButton { vaylDismiss(confirm: false) }

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
        GeometryReader { geo in
            // `.top` alignment is load-bearing: without it a bare ZStack centers its VStack
            // vertically, and `bottomSection` grows from a two-line caption (beat1) to the taller
            // locked-rows list (beat2/3) — a taller centered stack pushes everything above it,
            // including the whole constellation, upward. Anchoring to the top means bottomSection
            // growing only ever extends downward; the constellation never has to move to make room.
            ZStack(alignment: .top) {
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
                    // Layout + hero placement live on the store (Blueprint C) — the view
                    // only renders what it's handed.
                    //
                    // ONE constant frame — sized to just past where ConstellationLayout actually
                    // places stars (their y is confined to roughly the frame's own top half) — for
                    // the entire ceremony, beat1 through revealed. Two earlier attempts tried to give
                    // beat1 a dramatic full-bleed size and beat2/3 a smaller one (first by animating
                    // a single instance's frame height, then by cross-fading between two differently
                    // sized instances); both still produced a visible jump or abrupt landing, because
                    // every star's `.position()` is a fraction of whatever frame the constellation
                    // resolves to, and the surrounding VStack's layout snapped to the new slot size
                    // the moment the beat changed even when the star content tried to animate.
                    // Removing the size change entirely removes the whole family of bugs: nothing
                    // about the constellation's layout ever changes across beats, so its stars and
                    // lines never move. `bottomSection` below it already fades its own content in
                    // and out independently — it now simply has a stable amount of room reserved
                    // below the constellation at all times, instead of needing it to shrink. Sized to
                    // 0.38 (not the full 0.5 the frame used before stars were confined to the upper
                    // half) — small enough that the caption/locked-rows below don't sit behind a dead
                    // gap of empty sky, but tall enough that halos/labels at high match counts have
                    // room to breathe within the compressed upper-half band.
                    constellationView
                        .frame(maxWidth: .infinity, maxHeight: geo.size.height * 0.38)
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
    }

    /// The constellation. Factored out of `beatReveal` for readability — it's still exactly one
    /// call site now, but keeping it separate keeps `beatReveal`'s body scannable.
    private var constellationView: some View {
        DesireConstellationView(
            stars: store.placedStars,
            edges: store.layout.edges,
            variant: ceremonyVariant,
            mode: constellationMode,
            onTap: { id in
                hapticTick += 1
                if let match = store.matches.first(where: { $0.id.uuidString == id }) {
                    store.selectStar(match)
                }
            }
        )
    }

    @ViewBuilder
    private var bottomSection: some View {
        if store.unlockPending {
            // Charge landed, grant still resolving server-side (review §1.2: unlock truth =
            // server tier). Quiet interim state; the ceremony plays when real rows arrive.
            VStack(spacing: AppSpacing.sm) {
                ProgressView()
                    .tint(AppColors.textTertiary)
                Text("Payment received. Lighting your sky…")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppSpacing.xxl)
            .padding(.bottom, AppSpacing.xxl)
            .transition(.opacity)
        } else {
            beatBottomSection
        }
    }

    @ViewBuilder
    private var beatBottomSection: some View {
        switch store.beatPhase {
        case .idle:
            EmptyView()

        case .beat1:
            // Caption for the free match
            VStack(spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.xs) {
                    Text("You both marked this")
                        .font(AppFonts.bodyText)
                        .foregroundStyle(AppColors.textSecondary)
                    Text("✦")
                        .font(AppFonts.bodyText)
                        .foregroundStyle(LinearGradient(
                            colors: [AppColors.spectrumCyan, AppColors.spectrumMagenta],
                            startPoint: .leading, endPoint: .trailing
                        ))
                }
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
                hero: store.heroMatch,
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
                HStack(spacing: AppSpacing.xs) {
                    Text("\(n) desire\(n == 1 ? "" : "s") you share")
                        .font(AppFonts.bodyText)
                        .foregroundStyle(AppColors.textSecondary)
                    Text("✦")
                        .font(AppFonts.bodyText)
                        .foregroundStyle(LinearGradient(
                            colors: [AppColors.spectrumCyan, AppColors.spectrumMagenta],
                            startPoint: .leading, endPoint: .trailing
                        ))
                }
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

    /// What the constellation does at the current beat.
    private var constellationMode: DesireConstellationView.Mode {
        switch store.beatPhase {
        case .idle, .beat1:   return .intro
        case .beat2, .beat3:  return .teasers
        case .revealed:       return reduceMotion ? .resolved : .assemble
        }
    }

    // MARK: - Sheet host layer

    // Scrim + sheet slot. Sheets are pinned to bottom and transition .move(edge:.bottom).
    // S1.4 adds PaywallSheet; S1.5 adds DesireMapListSheet.
    private var sheetHostLayer: some View {
        ZStack(alignment: .bottom) {
            AppColors.scrimHeavy
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

            // S1.4 — paywall (capped to ~two-thirds; content scrolls within via
            // PaywallSheet's own ViewThatFits fallback, so the CTA stays reachable)
            if store.showPaywall {
                GeometryReader { g in
                    PaywallSheet(entry: .reveal, onUnlocked: {
                        store.handleUnlockSuccess()
                    }, onClose: {
                        store.closePaywall()
                    })
                    .frame(height: g.size.height * 0.65)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
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
// The hero (the one match already revealed via the constellation) shows first, fully legible —
// otherwise this list reads as "everything is locked," which contradicts the lit star above it.
// Locked rows carry NO real name anymore (server-enforced paywall, review 2026-07-09 §1.2):
// they render the honest category teaser ("A shared desire · EMOTIONAL") as plain text — a
// blur would fake a secret the client doesn't hold, and blurred Text leaked to VoiceOver.

private struct _LockedSection: View {
    let hero: RevealMatch?
    let matches: [RevealMatch]
    let isVisible: Bool

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            if let hero {
                _LockedPreviewRow(title: hero.itemName ?? hero.teaserTitle, isRevealed: true)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 22)
                    .animation(AppAnimation.desireLockedRowEnter.reduceMotionSafe, value: isVisible)
            }

            ForEach(Array(matches.filter { $0.id != hero?.id }.prefix(4).enumerated()), id: \.element.id) { i, match in
                _LockedPreviewRow(title: match.teaserTitle, isRevealed: false)
                    .accessibilityLabel("Hidden match")
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 22)
                    // Fix #5: tokenized locked-row stagger (was .easeOut 0.36 / 0.08 step),
                    // reduceMotionSafe so it collapses to a fast opacity confirm. Offset by
                    // one extra step so locked rows cascade in just after the hero row.
                    .animation(
                        AppAnimation.desireLockedRowEnter
                            .delay(Double(i + 1) * AppAnimation.desireBeatStaggerStep)
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

// MARK: - Locked preview row (Card Weight materials, no interaction)
// Shares DesireAnswerPill's visual language — radius, top sheen, orb accent — without being a
// tappable/selectable component. `isRevealed` distinguishes the hero row (real name, bright
// text, lit magenta accent) from a locked one (plain category teaser, dim text + accent).
// No blur: locked rows only ever hold the teaser string, and nothing about it is secret.

private struct _LockedPreviewRow: View {
    let title: String
    let isRevealed: Bool

    private var accent: Color { isRevealed ? AppColors.spectrumMagenta : .white }
    private var textColor: Color { isRevealed ? AppColors.textBright : Color.white.opacity(0.30) }

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [.white.opacity(0.05), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 14)

            HStack(spacing: AppSpacing.md) {
                orb
                Text(title)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.md)
        }
        .frame(height: 46)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .fill(isRevealed ? AppColors.spectrumMagenta.opacity(0.08) : AppColors.whisperFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .stroke(isRevealed ? AppColors.spectrumMagenta.opacity(0.35) : AppColors.borderDefault, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isRevealed ? title : "Locked desire")
    }

    private var orb: some View {
        ZStack {
            Circle()
                .fill(accent)
                .frame(width: 17, height: 17)
                .blur(radius: 6)
                .opacity(isRevealed ? 0.7 : 0.35)
            Circle()
                .fill(.white)
                .frame(width: 7, height: 7)
                .opacity(isRevealed ? 1.0 : 0.5)
        }
        .frame(width: 17, height: 17)
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
/// A server-shaped locked stub: no name, category teaser only.
private func _stub(_ category: String?) -> RevealMatch {
    RevealMatch(id: UUID(), itemName: nil, itemCategory: category, alignment: nil,
                isLocked: true, bridgeCardId: nil)
}

#Preview("Free reveal — 1 lit + 3 locked stubs") {
    let appState = AppState()
    DesireRevealView(store: .previewStore(matches: [
        .sample("New Relationship Energy", .mutual, free: true),
        _stub("logistics"),
        _stub("emotional"),
        _stub(nil)
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
        .sample("Deep Conversations", .adjacent)
    ]))
    .environment(appState)
    .environment(EntitlementStore(modelContainer: .previewContainer, appState: appState))
    .preferredColorScheme(.dark)
}

#Preview("Empty — unpaired") {
    let appState = AppState()
    DesireRevealView(store: .previewStore(matches: [], phase: .empty(.unpaired)))
        .environment(appState)
        .environment(EntitlementStore(modelContainer: .previewContainer, appState: appState))
        .preferredColorScheme(.dark)
}

#Preview("Empty — waiting for partner") {
    let appState = AppState()
    DesireRevealView(store: .previewStore(matches: [], phase: .empty(.waitingForPartner)))
        .environment(appState)
        .environment(EntitlementStore(modelContainer: .previewContainer, appState: appState))
        .preferredColorScheme(.dark)
}

#Preview("Empty — true zero") {
    let appState = AppState()
    DesireRevealView(store: .previewStore(matches: [], phase: .empty(.noMatches)))
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
