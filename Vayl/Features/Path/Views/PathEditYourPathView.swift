//
//  PathEditYourPathView.swift
//  Vayl — Path
//
//  The ⋯ overflow's first destination (PathScreen, Task 12/§03 of the mockup):
//  every landmark, including anything skipped, with a switch to bring it back.
//  No stage information here — this screen only ever asks "is this landmark
//  part of your path or not," never what state it's in (mockup §06).
//
//  Content only — presented via `.vaylSheet` (PathScreen), which already
//  supplies the sheet chrome + grabber + scrim/drag dismissal, so there is no
//  NavigationStack or navigation bar here (same "content dropped into
//  whatever wraps it" contract as PathNodeView.swift). The void + atmosphere
//  background and the List-transparency treatment mirror SessionSettingsSheet
//  (content-only `.vaylSheet` over its own solid backdrop) and PathLedgerView
//  (List grouped by phase, `.scrollContentBackground(.hidden)` +
//  `.listRowBackground(Color.clear)` hiding the system chrome) respectively —
//  both existing, reviewed precedents in this exact area of the codebase.
//

import SwiftUI

struct PathEditYourPathView: View {
    @Bindable var store: PathStore

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            OnboardingAtmosphere(config: .stat).ignoresSafeArea()

            VStack(spacing: 0) {
                header
                landmarkList
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text("Edit your path")
                .font(AppFonts.cardTitleCompact)
                .foregroundStyle(AppColors.textPrimary)
            Text("Toggle any landmark on or off.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.xs)
    }

    // MARK: - Landmark list

    private var landmarkList: some View {
        List {
            ForEach(store.phases) { phase in
                Section(phase.name) {
                    ForEach(store.landmarks.filter { $0.phaseId == phase.id }) { landmark in
                        row(for: landmark)
                            .listRowBackground(Color.clear)
                    }
                }
            }
        }
        .listStyle(.plain)
        // Same treatment as PathLedgerView's List over this exact void +
        // atmosphere background — hides the opaque system row/section chrome
        // that would otherwise float a native gray list on top of the sheet.
        .scrollContentBackground(.hidden)
    }

    private func row(for landmark: PathLandmark) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Text(landmark.title)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
            Spacer(minLength: AppSpacing.sm)
            Toggle(landmark.title, isOn: Binding(
                get: { store.state(for: landmark.id) != .skipped },
                set: { isOn in
                    Task {
                        if isOn {
                            try? await store.restore(landmark.id)
                        } else {
                            try? await store.skip(landmark.id)
                        }
                    }
                }
            ))
            .labelsHidden()
            // Never the raw system-blue Toggle — same tint token
            // SettingsToggleRow uses for every other on/off switch in the app.
            .tint(AppColors.accentPrimary)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - Previews

#if DEBUG
private struct PathEditYourPathPreviewHarness: View {
    private let store: PathStore

    init() {
        let coupleId = UUID()
        let profileId = UUID()
        let now = Date()
        let transport = MockPathTransport()
        transport.progress = [
            PathLandmarkProgress(
                id: UUID(), coupleId: coupleId, pathStyle: "swinging", landmarkId: "nm-mixer",
                state: .skipped, discussedVia: nil, didItDate: nil, setBy: profileId, updatedAt: now
            )
        ]
        store = PathStore(coupleId: coupleId, profileId: profileId, pathStyle: "swinging", transport: transport)
    }

    var body: some View {
        PathEditYourPathView(store: store)
            .task { try? await store.load() }
    }
}

#Preview("PathEditYourPathView — toggle skipped back on") {
    PathEditYourPathPreviewHarness()
}
#endif
