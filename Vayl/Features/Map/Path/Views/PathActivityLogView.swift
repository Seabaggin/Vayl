//
//  PathActivityLogView.swift
//  Vayl — Path
//
//  The ⋯ overflow's second destination (PathScreen, Task 12/§07 of the mockup):
//  an append-only, plain-language, read-only record of changes to the couple's
//  shared Path map (spec §10). Never a raw `kind` string, never a notification
//  or badge — it exists to be checked, not pushed. Never shows a private,
//  not-yet-shared Curious mark — there is no code path for that, since
//  `PathStore.markCuriousPrivately` never calls `logActivity` (Task 8).
//
//  Content only — presented via `.vaylSheet` (PathScreen), which already
//  supplies the sheet chrome + grabber + scrim/drag dismissal, so there is no
//  NavigationStack or navigation bar here (same "content dropped into whatever
//  wraps it" contract as PathNodeView.swift / PathEditYourPathView.swift). The
//  void + atmosphere background and the List-transparency treatment mirror
//  PathEditYourPathView (its ⋯ sibling) and PathLedgerView exactly — both
//  existing, reviewed precedents in this exact area of the codebase.
//

import SwiftUI

struct PathActivityLogView: View {
    let store: PathStore

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            OnboardingAtmosphere(config: .stat).ignoresSafeArea()

            VStack(spacing: 0) {
                header
                if let error = store.loadError {
                    MapEmptyState(
                        icon: "exclamationmark.triangle",
                        headline: "Couldn't load activity",
                        message: error
                    )
                } else if store.isLoading && store.activity.isEmpty {
                    loadingState
                } else if store.activity.isEmpty {
                    emptyState
                } else {
                    activityList
                }
            }
        }
    }

    // MARK: - Loading state

    private var loadingState: some View {
        VStack(spacing: AppSpacing.sm) {
            ProgressView()
                .tint(AppColors.accentPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text("Path activity")
                .font(AppFonts.cardTitleCompact)
                .foregroundStyle(AppColors.textPrimary)
            Text("A record of changes to your shared map.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.xs)
    }

    // MARK: - Activity list

    private var activityList: some View {
        List(store.activity) { entry in
            row(for: entry)
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        // Same treatment as PathEditYourPathView/PathLedgerView's List over
        // this exact void + atmosphere background — hides the opaque system
        // row/section chrome that would otherwise float a native gray list
        // on top of the sheet.
        .scrollContentBackground(.hidden)
    }

    private func row(for entry: PathActivityEntry) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(description(for: entry))
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
            Text(entry.createdAt.formatted(.relative(presentation: .named)))
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.vertical, AppSpacing.xs)
    }

    /// Plain-language, per spec §10 — never a raw enum name in the UI.
    private func description(for entry: PathActivityEntry) -> String {
        let landmark = store.landmarks.first { $0.id == entry.landmarkId }?.title ?? entry.landmarkId
        switch entry.kind {
        case .curiousShared: return "Shared \(landmark) as Curious"
        case .discussedSession: return "Marked \(landmark) Discussed · via session"
        case .discussedManual: return "Marked \(landmark) Discussed · noted"
        case .planningSet: return "Marked \(landmark) Planning"
        case .didItSet: return "Marked \(landmark) Did it"
        case .didItDateChanged: return "Changed the date on \(landmark)"
        case .skipped: return "Skipped \(landmark)"
        case .restored: return "Restored \(landmark)"
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        MapEmptyState(
            icon: "clock.arrow.circlepath",
            headline: "No activity yet",
            message: "Changes to your shared map will show up here."
        )
    }
}

// MARK: - Previews

#if DEBUG
@MainActor
private struct PathActivityLogPreviewHarness: View {
    private let store: PathStore

    init() {
        let coupleId = UUID()
        let profileId = UUID()
        let partnerId = UUID()
        let now = Date()
        let transport = MockPathTransport()

        func entry(_ landmarkId: String, _ actorId: UUID, _ kind: PathActivityKind, secondsAgo: TimeInterval) -> PathActivityEntry {
            PathActivityEntry(
                id: UUID(), coupleId: coupleId, pathStyle: "swinging", landmarkId: landmarkId,
                actorId: actorId, kind: kind, detail: nil, createdAt: now.addingTimeInterval(-secondsAgo)
            )
        }

        transport.activity = [
            entry("lifestyle-club", profileId, .didItSet, secondsAgo: 60 * 30),
            entry("flirt-bar", partnerId, .curiousShared, secondsAgo: 60 * 90),
            entry("seen-as-couple", profileId, .discussedSession, secondsAgo: 60 * 60 * 24 * 2),
            entry("dinner-couple", partnerId, .discussedManual, secondsAgo: 60 * 60 * 24 * 3),
            entry("virtual-hellos", profileId, .didItDateChanged, secondsAgo: 60 * 60 * 24 * 4),
            entry("nm-mixer", partnerId, .skipped, secondsAgo: 60 * 60 * 24 * 7)
        ]

        store = PathStore(coupleId: coupleId, profileId: profileId, pathStyle: "swinging", transport: transport)
    }

    var body: some View {
        PathActivityLogView(store: store)
            .task { await store.load() }
    }
}

#Preview("PathActivityLogView — plain-language, newest first") {
    PathActivityLogPreviewHarness()
}

@MainActor
private struct PathActivityLogEmptyPreviewHarness: View {
    private let store: PathStore

    init() {
        let transport = MockPathTransport()
        store = PathStore(coupleId: UUID(), profileId: UUID(), pathStyle: "swinging", transport: transport)
    }

    var body: some View {
        PathActivityLogView(store: store)
            .task { await store.load() }
    }
}

#Preview("PathActivityLogView — empty state") {
    PathActivityLogEmptyPreviewHarness()
}
#endif
