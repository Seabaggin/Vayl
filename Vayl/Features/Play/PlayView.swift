//
//  PlayView.swift
//  Vayl — Play
//
//  Tab root + screen. Builds the PlayStore from the environment, then lays out
//  the Cards masthead (pinned), the active-deck hero + docked deck wall (or the
//  expanded canvas), with the float-in-space detail, the Begin ceremony, and
//  the session cover layered above.
//

import SwiftUI
import SwiftData

struct PlayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(CoupleContext.self) private var coupleContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var store: PlayStore?
    @State private var entryStore: SessionEntryStore?
    @State private var scrollY: CGFloat = 0
    @Namespace private var deckZoom

    /// Inject a store for previews; nil in the app (built from the environment).
    var injectedStore: PlayStore?

    /// 0 = hero full at rest, 1 = collapsed. Mirrors Home's scroll-linked hero transform
    /// (same ~320pt range). Reduce Motion pins it to 0 (plain scroll, no collapse).
    private var collapse: Double {
        reduceMotion ? 0 : min(1, max(0, Double(scrollY) / 320))
    }

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            if let store = store ?? injectedStore {
                content(store)
            }
        }
        .task {
            if store == nil && injectedStore == nil {
                store = PlayStore(modelContainer: modelContext.container,
                                  appState: appState,
                                  entitlements: entitlements,
                                  coupleContext: coupleContext)
            }
            if entryStore == nil {
                entryStore = SessionEntryStore(
                    modelContainer: modelContext.container,
                    appState: appState,
                    partnerName: { [couple = coupleContext] in couple.partnerName }
                )
            }
            entryStore?.refresh()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { entryStore?.refresh() }
        }
    }

    @ViewBuilder
    private func content(_ store: PlayStore) -> some View {
        ZStack(alignment: .top) {
            OnboardingAtmosphere(config: .stat).ignoresSafeArea()

            VStack(spacing: 0) {
                if store.isEmpty {
                    PlayMastheadView()
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.xs)
                    PlayEmptyState(message: store.loadError) { store.retry() }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: AppSpacing.xl) {
                            PlayMastheadView()
                                .padding(.horizontal, AppSpacing.lg)
                                .padding(.top, AppSpacing.xs)
                            PlayHeroView(store: store, collapse: collapse)
                            DeckWallView(store: store, namespace: deckZoom)
                        }
                        .padding(.top, AppSpacing.sm)
                        // No bottom clearance here: AppShell's .safeAreaInset
                        // tab bar reserves its own height for every tab.
                    }
                    .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { _, y in
                        scrollY = y
                    }
                }
            }

            DeckDetailView(store: store, namespace: deckZoom)

            if store.ceremonyDeckID != nil {
                DeckBeginCeremony(store: store)
                    .transition(.opacity)
                    .zIndex(10)
            }

            // Failed session open — the plan is kept; "Try again" re-runs it.
            if let error = store.openError {
                VStack {
                    Spacer()
                    openErrorBanner(store, message: error)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.lg)
                }
                .transition(.opacity)
                .zIndex(25)
            }

            // Joiner banner — above the ceremony (20 > 10).
            if let pending = entryStore?.pendingSession {
                VStack {
                    PendingSessionBanner(
                        initiatorName: pending.initiatorName,
                        deckTitle: pending.deckTitle,
                        onJoin: { entryStore?.accept() },
                        onDismiss: { entryStore?.dismissBanner() }
                    )
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.top, AppSpacing.sm)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(20)
            }
        }
        .animation(AppAnimation.enter, value: store.ceremonyDeckID)
        .animation(AppAnimation.spring, value: entryStore?.pendingSession)
        .animation(AppAnimation.standard, value: store.openError)
        .onChange(of: entryStore?.acceptedLaunch) { _, launch in
            if let launch {
                store.launch = launch          // reuses the session cover below
                entryStore?.acceptedLaunch = nil
            }
        }
        .vaylSheet(
            isPresented: Binding(
                get: { store.builderDeck != nil },
                set: { if !$0 { store.cancelBuilder() } }
            ),
            heightFraction: 0.92
        ) {
            if let deck = store.builderDeck {
                SessionBuilderView(
                    deck: deck,
                    onConfirm: { plan in store.builderDidFinish(plan) },
                    onCancel: { store.cancelBuilder() },
                    composition: store.composition,
                    startIndex: store.builderStartIndex
                )
            }
        }
        .vaylCover(isPresented: Binding(
            get: { store.launch != nil },
            set: { if !$0 { store.endSession() } }
        )) {
            if let launch = store.launch {
                CardSessionContainerView(launch: launch)
                    .id(launch.id)             // re-key: each launch boots fresh
            }
        }
        .vaylSheet(
            isPresented: Binding(
                get: { store.paywallDeck != nil },
                set: { if !$0 { store.dismissPaywall() } }
            ),
            heightFraction: 0.92
        ) {
            PaywallSheet(
                entry: .playDeck(name: store.paywallDeck?.title ?? "this deck"),
                onUnlocked: { store.dismissPaywall() }
            )
        }
    }

    /// The failed-open banner: the built plan is retryable in place.
    private func openErrorBanner(_ store: PlayStore, message: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            Text(message)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textBody)
            Spacer(minLength: 0)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                store.retryOpen()
            } label: {
                Text("Try again")
                    .font(AppFonts.buttonLabelSmall)
                    .foregroundStyle(AppColors.spectrumText)
            }
            .buttonStyle(.plain)
            Button {
                store.dismissOpenError()
            } label: {
                Image(systemName: "xmark")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss error")
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + AppSpacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .strokeBorder(AppColors.borderDefault, lineWidth: 1)
                )
        )
    }
}

#if DEBUG
#Preview("Play") {
    let state = AppState()
    let entitlements = EntitlementStore(modelContainer: .previewContainer, appState: state)
    return PlayView(injectedStore: .preview)
        .environment(state)
        .environment(entitlements)
        .environment(CoupleContext(appState: state, entitlements: entitlements, modelContainer: .previewContainer))
        .modelContainer(.previewContainer)
        .preferredColorScheme(.dark)
}
#endif
