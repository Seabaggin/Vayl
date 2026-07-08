//
//  PathScreen.swift
//  Vayl — Path
//
//  Trail and Ledger are one screen toggled by ☰ (per this conversation's
//  resolved navigation design, not yet folded into the written spec — see
//  docs/prototypes/path-node-state-redesign-suite.html §02/§03). Trail's
//  header carries ⚷ (the legend, since its labels lost their status text —
//  spec §12). Ledger's header carries ⋯ — the *only* doorway to Edit your
//  path / Path activity (mockup §03: "reached only from here"), never a
//  redundant trigger elsewhere.
//
//  Presented as a `.vaylCover` from MapView (Task 15) — a protected,
//  territory-drilling mode per the Map dashboard spec. Leaving asks the
//  cover's `vaylDismiss` guard, never a raw `dismiss()`, per
//  VaylPresentation.swift's own contract for content inside a `.vaylCover`.
//

import SwiftUI

struct PathScreen: View {
    @Bindable var store: PathStore
    @Environment(\.vaylDismiss) private var vaylDismiss

    private enum Mode { case trail, ledger }
    @State private var mode: Mode = .trail
    @State private var showLegend = false
    @State private var showOverflow = false
    @State private var selectedLandmarkId: String?
    @State private var showEditPath = false
    @State private var showActivity = false

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let layout = AppLayout.from(geo)

                // Same floor + sky as every other tab/screen root (Design Token
                // Contract's "every screen background" rule) — void first, then
                // the OB atmosphere, matching MapView/SettingsView/LearnView's
                // exact GeometryReader-outer/ZStack-inner ordering.
                ZStack {
                    AppColors.void.ignoresSafeArea()
                    OnboardingAtmosphere(config: .stat).ignoresSafeArea()

                    VStack {
                        switch mode {
                        case .trail:
                            PathTrailView(store: store) { selectedLandmarkId = $0 }
                        case .ledger:
                            PathLedgerView(store: store) { selectedLandmarkId = $0 }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .popover(isPresented: $showLegend) {
                    // Without this, SwiftUI's default compact-width adaptation
                    // turns an anchored popover into a full sheet on iPhone —
                    // the mockup (§02) shows a small floating panel, not a modal.
                    PathLegendPopover()
                        .presentationCompactAdaptation(.popover)
                }
                .confirmationDialog("Path", isPresented: $showOverflow) {
                    Button("Edit your path") { showEditPath = true }
                    Button("Path activity") { showActivity = true }
                }
                // The landmark tap destination — a "previewing something you
                // return from" surface (VaylPresentation's mental-state table),
                // so it routes through `.vaylSheet` like every other modal here,
                // never a raw `.sheet(item:)`. `screenHeight: layout.screenHeight`
                // is threaded into PathNodeView itself too, matching the
                // screenHeight: layout.screenHeight pattern MapView/SettingsView
                // already use, so PathNodeView's own nested date-editor sheet
                // measures the true screen height instead of this sheet's
                // intrinsic content height (see PathNodeView.swift's doc comment).
                .vaylSheet(
                    isPresented: Binding(
                        get: { selectedLandmarkId != nil },
                        set: { isPresented in if !isPresented { selectedLandmarkId = nil } }
                    ),
                    screenHeight: layout.screenHeight
                ) {
                    if let selectedLandmarkId {
                        PathNodeView(store: store, landmarkId: selectedLandmarkId, screenHeight: layout.screenHeight)
                    }
                }
                .vaylSheet(isPresented: $showEditPath, screenHeight: layout.screenHeight) {
                    PathEditYourPathView(store: store)
                }
                .vaylSheet(isPresented: $showActivity, screenHeight: layout.screenHeight) {
                    PathActivityLogView(store: store)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Map") { vaylDismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    // Trail mode: ⚷ legend. Ledger mode: ⋯ overflow — the ONLY
                    // entry point to Edit your path / Path activity, per spec.
                    // Mutually exclusive by construction (one `mode`, one
                    // branch) — toggling never shows both icons at once.
                    if mode == .trail {
                        Button { showLegend = true } label: { Image(systemName: AppIcons.key) }
                            .accessibilityLabel("Legend")
                    } else {
                        Button { showOverflow = true } label: { Image(systemName: AppIcons.ellipsis) }
                            .accessibilityLabel("More options")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        mode = (mode == .trail) ? .ledger : .trail
                    } label: {
                        Image(systemName: AppIcons.listBullet)
                    }
                    .accessibilityLabel(mode == .trail ? "Show ledger" : "Show trail")
                }
            }
        }
        .task { await store.load() }
    }
}
