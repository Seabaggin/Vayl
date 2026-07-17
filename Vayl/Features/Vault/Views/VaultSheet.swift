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
import SwiftData

struct VaultSheet: View {

    @Bindable var store: VaultStore
    var onUnlock: () -> Void

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    // The log editor and discussion card are presented by MapView (the screen
    // root), not here — this view is itself `.vaylSheet` content, and a
    // `.vaylSheet` anchors to the view it's attached to. Presentation state
    // lives on VaultStore (openLogEditor / openDiscussion).

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

                SegmentedPillGroup<VaultStore.Segment>(
                    options: [
                        .init(.desire, label: "Desire Map", accent: AppColors.spectrumCyan),
                        .init(.agreements, label: "Agreements", accent: AppColors.spectrumPurple),
                        .init(.log, label: "Log", accent: AppColors.spectrumMagenta)
                    ],
                    selection: $store.segment
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
        .screenshotProtected()
    }

    @ViewBuilder
    private var section: some View {
        if let error = store.loadError {
            VStack(spacing: AppSpacing.md) {
                MapEmptyState(
                    icon: "exclamationmark.triangle",
                    headline: "Couldn't load this",
                    message: error
                )
                Button("Try Again") {
                    Task { await reloadCurrentSegment() }
                }
                .buttonStyle(.borderedProminent)
            }
        } else if store.isLoading {
            VStack(spacing: AppSpacing.sm) {
                ProgressView()
                    .tint(AppColors.accentPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.xl)
        } else {
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
                    onAdd: { store.openLogEditor() },
                    onEdit: { store.openLogEditor($0) }
                )
            }
        }
    }

    private func reloadCurrentSegment() async {
        switch store.segment {
        case .agreements:
            await store.loadAgreements(appState: appState, context: modelContext)
        case .log:
            store.loadLog(context: modelContext)
            await store.syncLogDown(context: modelContext)
        case .desire:
            await store.loadDesire(appState: appState, context: modelContext)
            await store.loadConsent(appState: appState, context: modelContext)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Vault — in rail") {
    VaylSheetPreviewHost(heightFraction: 0.9) {
        VaultSheet(store: VaultStore(), onUnlock: {})
    }
    .environment(AppState())
    .modelContainer(.previewContainer)
}
#endif
