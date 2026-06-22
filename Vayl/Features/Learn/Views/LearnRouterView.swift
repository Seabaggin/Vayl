// Features/Learn/Views/LearnRouterView.swift
//
// Thin router: creates the LearnStore and owns sheet presentation for
// the research database, finding detail, and resources overlay.
// Mirrors the Home tab's Router pattern.

import SwiftUI

struct LearnRouterView: View {
    var body: some View { LearnRouterInnerView() }
}

private struct LearnRouterInnerView: View {
    @State private var store = LearnStore()
    @State private var showDatabase = false
    @State private var showResources = false
    @State private var selectedFinding: ResearchFinding?

    var body: some View {
        LearnDashboardView(
            store: store,
            onOpenDatabase: { showDatabase = true },
            onOpenResources: { showResources = true },
            onOpenFinding: { selectedFinding = $0 }
        )
        .vaylSheet(isPresented: $showDatabase, heightFraction: 0.92) {
            ResearchDatabaseView(store: store, onOpenFinding: { f in
                showDatabase = false
                selectedFinding = f
            })
        }
        .vaylSheet(isPresented: $showResources, heightFraction: 0.82) {
            ResourcesOverlayView(resources: store.supportResources)
        }
        .vaylSheet(isPresented: detailBinding, heightFraction: 0.85) {
            if let f = selectedFinding {
                FindingDetailView(finding: f, store: store, onOpenFinding: { selectedFinding = $0 })
            }
        }
    }

    private var detailBinding: Binding<Bool> {
        Binding(get: { selectedFinding != nil },
                set: { if !$0 { selectedFinding = nil } })
    }
}

#Preview {
    LearnRouterView()
}
