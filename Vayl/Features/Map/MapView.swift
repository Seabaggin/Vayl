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
    @Environment(\.modelContext) private var modelContext
    @State private var store = MapStore()

    // Pulse check-in state — the screen owns the cover/sheet (mirrors PulseWidget).
    @State private var showCheckIn = false
    @State private var showPulseSheet = false
    @State private var showMeCard = false
    @State private var showVault = false
    @State private var showPaywall = false
    @State private var showSettings = false
    @State private var vaultStore = VaultStore()
    @State private var pendingEntry: PulseEntry? = nil
    @State private var camScale: CGFloat = 1.0
    @State private var camTx: CGFloat = 0.0
    @State private var camTy: CGFloat = 0.0
    @State private var liveScore: Double? = nil
    @State private var drawProgress: CGFloat = 0.0

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
            .vaylCover(isPresented: $showCheckIn, confirmOnExit: false) {
                CheckInShell(
                    entries:      pulse.entries,
                    camScale:     $camScale,
                    camTx:        $camTx,
                    camTy:        $camTy,
                    liveScore:    $liveScore,
                    drawProgress: $drawProgress,
                    onComplete: { entry in
                        pendingEntry = entry
                        showCheckIn  = false
                    },
                    onDismiss: {
                        resetCheckInState()
                        showCheckIn = false
                    }
                )
            }
            .onChange(of: showCheckIn) { _, isShowing in
                if !isShowing, let entry = pendingEntry {
                    handleNewEntry(entry)
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
                    Task { await vaultStore.loadDesire(appState: appState, context: modelContext) }
                })
            }
            .vaylSheet(isPresented: $showSettings, heightFraction: 0.92, screenHeight: layout.screenHeight) {
                PairingSettingsView()
            }
        }
        .task {
            store.load(appState: appState, context: modelContext)
            await vaultStore.loadDesire(appState: appState, context: modelContext)
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
            gearButton
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

    private var gearButton: some View {
        Button {
            showSettings = true
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 36, height: 36)
                .background(Circle().fill(AppColors.glassSurface))
                .overlay(Circle().strokeBorder(AppColors.borderSubtle, lineWidth: 1))
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityLabel("Settings")
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
            stats: store.usStats,
            align: store.alignItems,
            lockedAlignCount: store.lockedAlignCount,
            onOpenVault: { showVault = true }
        )
    }

    // MARK: - Pulse check-in plumbing (the screen owns the cover, mirrors PulseWidget)

    private func startCheckIn() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        resetCheckInState()
        showCheckIn = true
    }

    private func handleNewEntry(_ entry: PulseEntry) {
        pulse.add(entry)
        pendingEntry = nil
        resetCheckInState()
    }

    private func resetCheckInState() {
        camScale     = 1.0
        camTx        = 0.0
        camTy        = 0.0
        liveScore    = nil
        drawProgress = 0.0
    }
}

// MARK: - Preview

#Preview("Map tab") {
    MapView()
        .environment({ let s = AppState(); s.displayName = "Jordan"; return s }())
        .environment(PulseStore())
        .modelContainer(.previewContainer)
        .preferredColorScheme(.dark)
}
