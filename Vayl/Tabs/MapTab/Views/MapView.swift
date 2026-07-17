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
    @Environment(CoupleContext.self) private var coupleContext
    @Environment(\.modelContext) private var modelContext
    @State private var store = MapStore()

    @State private var showCheckIn = false
    @State private var showPulseSheet = false
    @State private var showVault = false
    @State private var showPaywall = false
    @State private var vaultStore = VaultStore()

    // TEMPORARY (Task 15) — minimum wiring to reach PathScreen at all. The Map
    // dashboard has no Path widget yet (spec §0 / Bryan's standing direction);
    // replace this row when that widget is designed.
    @State private var showPathScreen = false
    @State private var pathStore: PathStore?

    // TEMPORARY — backs the DEBUG hero tuner. @AppStorage so a scrubbed value
    // survives rebuilds while Bryan gates the feel. Release builds never read it;
    // resolvedLayout(_:) leaves AppLayout.defaultMapHeroOrbFraction untouched.
    #if DEBUG
    @AppStorage("debug.map.heroOrbFraction")
    private var debugOrbFraction: Double = Double(AppLayout.defaultMapHeroOrbFraction)
    #endif

    // FEEL: tune on device
    private let lensTintOpacity: Double = 0.10
    // FEEL: tune on device
    private let lensTintRadius: CGFloat = 420

    // MARK: - Us reveal ceremony (spec §2.4)

    // 0 dormant · 1 name igniting · 2 flipped+line showing · 3 done
    @State private var revealStage: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // FEEL: tune on device
    private let revealIgniteDelay: Double = 1.0
    // FEEL: tune on device
    private let revealLineDuration: Double = 2.0
    // FEEL: tune on device
    private let revealBlurRadius: CGFloat = 6

    private var shouldPlayReveal: Bool {
        store.hasUs && !store.usRevealSeen
    }

    private func playUsReveal() {
        guard shouldPlayReveal else { return }
        store.markUsRevealSeen()   // mark FIRST — a mid-ceremony backgrounding must not replay it
        if reduceMotion {
            withAnimation(AppAnimation.enter) { store.layer = .us; revealStage = 2 }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(revealLineDuration + 0.6))
                withAnimation(AppAnimation.exit) { revealStage = 3 }
            }
            return
        }
        withAnimation(AppAnimation.slow) { revealStage = 1 }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(revealIgniteDelay))
            withAnimation(AppAnimation.spring) { store.layer = .us; revealStage = 2 }
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(revealIgniteDelay + revealLineDuration))
            withAnimation(AppAnimation.exit) { revealStage = 3 }
        }
    }

    var body: some View {
        @Bindable var store = store
        GeometryReader { geo in
            let layout = resolvedLayout(geo)

            ZStack(alignment: .top) {
                // Same floor + sky as every other tab.
                AppColors.void.ignoresSafeArea()
                OnboardingAtmosphere(config: .stat)
                    .ignoresSafeArea()
                RadialGradient(
                    colors: [
                        (store.layer == .us ? AppColors.spectrumMagenta : AppColors.spectrumPurple)
                            .opacity(lensTintOpacity),
                        .clear
                    ],
                    center: .top, startRadius: 0, endRadius: lensTintRadius
                )
                .ignoresSafeArea()
                .animation(AppAnimation.slow, value: store.layer)
                .allowsHitTesting(false)

                if store.isLoading && !store.hasLoadedOnce {
                    VStack(spacing: AppSpacing.sm) {
                        ProgressView()
                            .tint(AppColors.accentPrimary)
                        Text("Loading your map...")
                            .font(AppFonts.bodyText)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                } else if let error = store.loadError {
                    VStack(spacing: AppSpacing.md) {
                        MapEmptyState(
                            icon: "exclamationmark.triangle",
                            headline: "Couldn't load your map",
                            message: error
                        )
                        Button("Try Again") {
                            Task { await loadEverything() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppSpacing.lg) {
                            masthead   // the name wordmark IS the Me/Us switch now

                            // TEMPORARY (Task 15) — DEBUG-only dev entry point to the
                            // unshipped Path feature. Must NOT ship in V1 (Path is post-launch).
                            #if DEBUG
                            Button("Open Path (temporary entry point)") {
                                guard let coupleId = appState.coupleId,
                                      let profileId = try? modelContext.fetch(FetchDescriptor<UserProfile>()).first?.id
                                else { return }
                                pathStore = PathStore(coupleId: coupleId, profileId: profileId, pathStyle: "swinging", transport: PathSyncService())
                                showPathScreen = true
                            }
                            #endif

                            // TEMPORARY — the feel gate for the Map hero orb (Void
                            // Rule clause 2). Scrub it, land on a value, copy it into
                            // AppLayout.defaultMapHeroOrbFraction, delete this block.
                            #if DEBUG
                            MapHeroTuner(
                                fraction: $debugOrbFraction,
                                orbSize: layout.mapHeroOrbSize
                            )
                            #endif

                            layerContent(layout)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .scrollIndicators(.hidden)
                    // Top scroll-edge: the name/Me-Us masthead dissolves under the
                    // Island as it scrolls up, instead of hard-cutting at the edge.
                    .scrollTopEdgeFade()
                }
            }
            .onChange(of: store.hasUs) { _, has in
                store.enforceLensGate()
                if has { playUsReveal() }
            }
            // Pin the screen to the true width so an ignoresSafeArea child (the
            // atmosphere) cannot inflate the container and shove the column off-centre.
            .frame(width: layout.screenWidth, alignment: .center)
            // Full-screen cover — see HomeDashboardView's matching check-in presentation
            // for why (PulseField needs real screen geometry, not a sheet's).
            .vaylCover(isPresented: $showCheckIn, confirmOnExit: false) {
                PulseCheckInView(store: pulse, onClose: { showCheckIn = false })
            }
            // TEMPORARY (Task 15) — see field declarations above. `.vaylCover` per
            // the parent Map dashboard spec's own note: Path is a territory-drilling
            // mode, decided in the roadmap spec as a cover.
            .vaylCover(isPresented: $showPathScreen, confirmOnExit: false) {
                if let pathStore {
                    PathScreen(store: pathStore, partnerName: store.partnerName)
                }
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
                    mapStore: store,
                    myEntries: pulse.entries,
                    partnerEntries: store.partnerEntries,
                    partnerName: store.partnerName,
                    onDismiss: { showPulseSheet = false }
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
                heightFraction: 0.65,
                screenHeight: layout.screenHeight
            ) {
                PaywallSheet(entry: .reveal, onUnlocked: {
                    showPaywall = false
                    // canRevealAll flips via EntitlementStore the moment the purchase
                    // applies — the reload just re-fetches rows under the new gate.
                    Task { await vaultStore.loadDesire(appState: appState, context: modelContext) }
                }, onClose: {
                    showPaywall = false
                }, hostProvidesChrome: true)
            }
        }
        .task { await loadEverything() }
    }

    private func loadEverything() async {
        store.markLoadStarted()
        store.configure(couple: coupleContext)
        vaultStore.configure(couple: coupleContext)
        await coupleContext.refreshIfNeeded()   // partner identity (no-op once loaded)
        store.load(appState: appState, context: modelContext)
        await vaultStore.loadDesire(appState: appState, context: modelContext)
        // Eagerly loaded (not just on Agreements-segment open) so the vault
        // door's stat line has a real count on first render.
        await vaultStore.loadAgreements(appState: appState, context: modelContext)
        await store.loadPartnerPulse(appState: appState)
        store.enforceLensGate()
        playUsReveal()
        store.markLoadFinished()
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
                if store.hasUs {
                    Text(store.layer == .us ? "Shared · you both see this" : "Only you")
                        .font(AppFonts.caption)
                        .foregroundStyle(store.layer == .us
                            ? AppColors.spectrumMagenta.opacity(0.8)
                            : AppColors.spectrumCyan.opacity(0.8))
                        .transition(.opacity)
                        .accessibilityLabel(store.layer == .us
                            ? "Shared lens: your partner sees this too"
                            : "Private lens: only you see this")
                }
                if revealStage == 2, store.hasUs {
                    Text("\(store.partnerName) is here. Tap a name to change whose map you're reading.")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .transition(.opacity)
                }
            }
            Spacer()
            SettingsGearButton { appState.settingsPresented = true }
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
                        // Ceremony-only ignition pass: de-blur as the name lights up.
                        // No-op (blur 0) outside revealStage 1, so steady-state is untouched.
                        .blur(radius: revealStage == 1 ? revealBlurRadius : 0)
                }
                .buttonStyle(.plain)
                .transition(.opacity)   // fades in the first time the name loads
                .accessibilityLabel("Show you and \(partner) together")
                .accessibilityAddTraits(isUs ? [.isButton, .isSelected] : .isButton)
            }
        }
        .font(AppFonts.tabMasthead)
        .vaylDisplayTracking(40)   // tabMasthead is display(40); tighten optically
        // Animate only the partner-name LOAD (""→name) so it fades in once; the
        // Me/Us colour/period changes are animated separately by the button taps.
        .animation(AppAnimation.slow, value: store.partnerName)
    }

    // MARK: - Layers (empty scaffolds in Seg 0; filled in Segments 1-5)

    @ViewBuilder
    private func layerContent(_ layout: AppLayout) -> some View {
        switch store.layer {
        case .me: meLayer(layout)
        case .us: if store.hasUs { usLayer(layout) } else { meLayer(layout) }
        }
    }

    private func meLayer(_ layout: AppLayout) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            MapPulseHero(
                layout: layout,
                onCheckIn: { startCheckIn() },
                onOpenHistory: { showPulseSheet = true },
                isLinked: store.hasUs
            )
            MapRecord(sessions: store.sessions, shares: store.categoryShares)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func usLayer(_ layout: AppLayout) -> some View {
        MapUsLayer(
            layout: layout,
            stats: store.usStats,
            align: store.alignItems,
            lockedAlignCount: store.lockedAlignCount,
            agreementsCount: vaultStore.agreements.count,
            onOpenVault: { showVault = true },
            onCheckIn: { startCheckIn() },
            onOpenPulse: { showPulseSheet = true },
            partnerPosition: store.partnerPosition,
            partnerEntries: store.partnerEntries,
            partnerName: store.partnerName
        )
    }

    // MARK: - Layout

    /// `AppLayout.from(geo)` in release. In DEBUG the hero tuner's scrubbed fraction
    /// is folded in here, so every hero downstream sizes off one resolved layout.
    /// A function, not an inline `var` mutation — a result builder cannot hold a
    /// mutating statement.
    private func resolvedLayout(_ geo: GeometryProxy) -> AppLayout {
        var layout = AppLayout.from(geo)
        #if DEBUG
        layout.mapHeroOrbFraction = CGFloat(debugOrbFraction)
        #endif
        return layout
    }

    // MARK: - Pulse check-in

    private func startCheckIn() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        showCheckIn = true
    }
}

// MARK: - Preview

// MARK: - DEBUG hero tuner (TEMPORARY — delete once the fraction is locked)

#if DEBUG
/// The feel gate for the Map hero orb, per the Void Rule's clause 2
/// (docs/design/2026-07-17-void-rule-and-map-hero-scale.md).
///
/// Exists because the orb's size cannot be derived on paper: MapHeroAmbientGlow
/// washes to 2.6x the orb, so the perceived hero is far larger than the number, and
/// the honest way to pick it is to look at it. Scrub against the real glow on real
/// hardware, then copy the value into AppLayout.defaultMapHeroOrbFraction and delete
/// this struct, the @AppStorage in MapView, and the #if DEBUG block that renders it.
///
/// A concrete View struct, not a @ViewBuilder helper on MapView — conditional
/// @ViewBuilder helpers trip the DebugReplaceableView SIGABRT in previews.
private struct MapHeroTuner: View {

    @Binding var fraction: Double
    let orbSize: CGFloat

    /// Home's deck is min(screenWidth * 0.72, 320) — the widest hero the app ships,
    /// so 0.72 is the ceiling worth trying, not an arbitrary bound.
    private let range: ClosedRange<Double> = 0.20...0.72

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text("HERO ORB — DEBUG")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)

            Slider(value: $fraction, in: range)
                .tint(AppColors.spectrumCyan)

            // Orb / wash / share. The wash is the one that matters: it is what the
            // eye reads, and it is 2.6x the number the slider is setting.
            Text(readout)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)

            Text("Copy into AppLayout.defaultMapHeroOrbFraction, then delete this.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(AppSpacing.sm)
        .vaylGlassCard()
    }

    private var readout: String {
        let wash = orbSize * MapHeroAmbientGlow.outerDiameterMultiple
        let f = String(format: "%.3f", fraction)
        return "fraction \(f) · orb \(Int(orbSize))pt · wash \(Int(wash))pt"
    }
}
#endif

#Preview("Map tab") {
    let state = { let s = AppState(); s.displayName = "Jordan"; return s }()
    let entitlements = EntitlementStore(modelContainer: .previewContainerWithProfile, appState: state)
    return MapView()
        .environment(state)
        .environment(PulseStore())
        .environment(entitlements)
        .environment(CoupleContext(appState: state, entitlements: entitlements, modelContainer: .previewContainerWithProfile))
        .modelContainer(.previewContainer)
        .preferredColorScheme(.dark)
}
