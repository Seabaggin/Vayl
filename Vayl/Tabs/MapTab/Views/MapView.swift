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
    /// The Pulse aura's on-screen frame, published by MapPulseHero via `.pulseOrbSource()`.
    /// Handed to the first-run doorway so its entrance starts on the orb the user tapped.
    @State private var pulseOrbFrame: CGRect?
    @State private var showPulseSheet = false
    @State private var showPulseInfo  = false
    @State private var showVault = false
    @State private var showPaywall = false
    @State private var vaultStore = VaultStore()
    /// Rest-zeroed scroll offset driving the masthead collapse (see MastheadCollapse).
    @State private var scrollY: CGFloat = 0

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
            let layout = AppLayout.from(geo)

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
                    // Rest-zeroed offset feeding the masthead shrink (name only).
                    .mastheadScrollReader($scrollY)
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
            // PulseCheckInFlow, not PulseCheckInView — see HomeDashboardView's matching
            // presentation: the flow owns the one-time first-run doorway and its gate, so
            // neither tab carries first-run state. transparentBackground lets the doorway
            // dissolve this screen away around the aura instead of sliding over it.
            .vaylCover(
                isPresented: $showCheckIn,
                confirmOnExit: false,
                transparentBackground: true
            ) {
                PulseCheckInFlow(
                    store: pulse,
                    sourceOrbFrame: pulseOrbFrame,
                    onClose: { showCheckIn = false }
                )
            }
            .onPreferenceChange(PulseOrbFrameKey.self) { pulseOrbFrame = $0 }
            .onChange(of: appState.vaultOpenPending) { _, pending in
                if pending {
                    showVault = true
                    appState.vaultOpenPending = false
                }
            }
            // Presented here, not on MapPulseHero: .vaylSheet is an .overlay that sizes
            // and anchors to the view it's attached to, so hanging it off the hero gave a
            // sheet 0.85 × the hero's height pinned to the hero's bottom edge. Screen
            // level is the only correct host, same as the three sheets below.
            .vaylSheet(
                isPresented: $showPulseInfo,
                heightFraction: 0.85,
                screenHeight: layout.screenHeight
            ) {
                PulseInfoSheet()
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
            // Vault second-level sheets, hoisted from VaultSheet (which is
            // itself `.vaylSheet` content and can't host its own sheets — see
            // the anchoring note above the Pulse info sheet). Presentation
            // state lives on VaultStore so the Vault's rows and this screen
            // read one truth.
            .vaylSheet(
                isPresented: Binding(
                    get: { vaultStore.logEditorOpen },
                    set: { if !$0 { vaultStore.closeLogEditor() } }
                ),
                heightFraction: 0.9,
                screenHeight: layout.screenHeight
            ) {
                EventEntryEditor(entry: vaultStore.editingLogEntry, store: vaultStore, onDone: {
                    vaultStore.closeLogEditor()
                    vaultStore.loadLog(context: modelContext)
                })
            }
            .vaylSheet(
                item: Binding(
                    get: { vaultStore.selectedDiscussionCard },
                    set: { if $0 == nil { vaultStore.closeDiscussion() } }
                ),
                heightFraction: 0.80,
                screenHeight: layout.screenHeight
            ) { card in
                DiscussionCardView(card: card, onDismiss: { vaultStore.closeDiscussion() })
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
                // Us only. The Me lens carries no sublabel: the lit/dim names already say
                // whose map this is, and "Only you" was making a privacy promise the
                // shared orb doesn't keep. Us keeps its line because "your partner sees
                // this" is a disclosure, not a label.
                if store.hasUs, store.layer == .us {
                    Text("Shared · you both see this")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.spectrumMagenta.opacity(0.8))
                        .transition(.opacity)
                        .accessibilityLabel("Shared lens: your partner sees this too")
                }
                if revealStage == 2, store.hasUs {
                    Text("\(store.partnerName) is here. Tap a name to change whose map you're reading.")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .transition(.opacity)
                }
            }
            // Only the name/switch shrinks; the gear holds its position (trailing
            // control, like an iOS large-title bar button). The Me/Us tap targets
            // shrink with the name — acceptable at these sizes, feel-gate on device.
            .mastheadCollapse(scrollY: scrollY)
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
        // Exactly one hero, zero card chrome — the Void Rule's Me shape. The Record left
        // for the Play tab (2026-07-21 scope cut): session history is the Card Game's
        // residue, not the mirror's.
        //
        // No onOpenHistory: the Me lens's history is inline in the hero now (a
        // collapsed strip that expands in place), so the "History" link retired.
        // PulseFullView stays alive — the Us lens still opens it from its own card.
        MapPulseHero(
            layout: layout,
            onCheckIn: { startCheckIn() },
            onOpenInfo: { showPulseInfo = true },
            isLinked: store.hasUs
        )
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

    // MARK: - Pulse check-in

    private func startCheckIn() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        // No system slide — the first-run doorway dissolves this screen away around the
        // aura, which a slide would drag upward. See presentWithoutAnimation.
        presentWithoutAnimation { showCheckIn = true }
    }
}

// MARK: - Preview

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
