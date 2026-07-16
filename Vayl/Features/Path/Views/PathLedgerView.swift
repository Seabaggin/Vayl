//
//  PathLedgerView.swift
//  Vayl — Path
//
//  The list reading of the couple's shared Path map — the detail-bearing
//  counterpart to PathTrailView's name-only spatial trail (spec §12: "the
//  trail's labels were simplified to name-only... with a ⚷ legend and the
//  Ledger view as the detail-bearing fallbacks"). Grouped by phase, each row
//  carries the status/date text the trail deliberately omits. Presentation
//  (the ☰/⚷/⋯ header, tap → PathNodeView) belongs to PathScreen (Task 12).
//

import SwiftUI

struct PathLedgerView: View {
    let store: PathStore
    let onSelect: (String) -> Void

    var body: some View {
        Group {
            if let error = store.loadError {
                MapEmptyState(
                    icon: "exclamationmark.triangle",
                    headline: "Couldn't load your path",
                    message: error
                )
            } else if store.isLoading && store.landmarks.isEmpty {
                ProgressView()
                    .tint(AppColors.accentPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.visibleLandmarks.isEmpty {
                MapEmptyState(
                    icon: "list.bullet",
                    headline: "No landmarks yet",
                    message: "Your shared path will appear here once it's set up."
                )
            } else {
                ledgerList
            }
        }
    }

    private var ledgerList: some View {
        List {
            ForEach(store.phases) { phase in
                Section(phase.name) {
                    ForEach(store.visibleLandmarks.filter { $0.phaseId == phase.id }) { landmark in
                        Button { onSelect(landmark.id) } label: {
                            row(for: landmark)
                        }
                        .buttonStyle(PressableCardStyle())
                        .listRowBackground(Color.clear)
                    }
                }
            }
        }
        .listStyle(.plain)
        // PathScreen (Task 12) puts this List on the same void+atmosphere
        // background every screen root uses — SessionBuilderView.swift is
        // this codebase's existing precedent for a List over that background,
        // and it hides the same opaque system chrome the same way.
        .scrollContentBackground(.hidden)
    }

    private func row(for landmark: PathLandmark) -> some View {
        let isNow = landmark.id == store.nowLandmarkId
        return HStack(spacing: AppSpacing.sm) {
            stateDot(for: landmark.id)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(landmark.title)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textBody)
                if let meta = statusText(for: landmark.id) {
                    Text(meta)
                        .font(AppFonts.caption)
                        .foregroundStyle(isNow ? AppColors.spectrumCyan : AppColors.textSecondary)
                }
            }
        }
    }

    private func statusText(for landmarkId: String) -> String? {
        let base: String?
        switch store.state(for: landmarkId) {
        case .untouched: base = nil
        case .curious: base = "Curious"
        case .discussed:
            let via = store.discussedVia(for: landmarkId) == .session ? "via session" : "noted"
            base = "Discussed · \(via)"
        case .planning: base = "Planning"
        case .didIt:
            if let date = store.didItDate(for: landmarkId) {
                base = "Did it · \(date.formatted(.relative(presentation: .named)))"
            } else {
                base = "Did it"
            }
        case .skipped: base = nil
        }
        // The Now anchor is a pure wayfinding cue the trail shows as a beacon;
        // the ledger surfaces it in words instead (mockup §03: "Here now · Planning").
        if landmarkId == store.nowLandmarkId {
            if let base { return "Here now · \(base)" }
            return "Here now"
        }
        return base
    }

    // Same five-state color language as PathTrailView's nodeView — kept in
    // sync manually since SwiftUI has no shared shape-builder between a
    // ZStack-positioned node and a List row; if these drift, fix here first.
    // Token choices mirror PathTrailView.nodeView exactly (AppColors.spectrumCyan/
    // Purple/Magenta/Border, AppColors.borderSubtle) rather than the
    // AppColors.spectrum.* / AppColors.hairline names, which don't exist in
    // AppColors.swift — verified against the real token source before use.
    @ViewBuilder
    private func stateDot(for landmarkId: String) -> some View {
        baseDot(for: landmarkId)
            // The Now anchor rides on top of whatever state dot sits there — a
            // cyan ring, mirroring the trail beacon (Now never encodes a state).
            .overlay {
                if landmarkId == store.nowLandmarkId {
                    Circle().stroke(AppColors.spectrumCyan, lineWidth: 2).frame(width: 26, height: 26)
                }
            }
    }

    @ViewBuilder
    private func baseDot(for landmarkId: String) -> some View {
        switch store.state(for: landmarkId) {
        case .untouched:
            Circle().stroke(AppColors.borderSubtle, lineWidth: 1.5).frame(width: 20, height: 20)
        case .curious:
            Circle().stroke(AppColors.spectrumMagenta, lineWidth: 1.5).frame(width: 20, height: 20)
                .overlay(dotGlyph(AppIcons.heartFill, AppColors.spectrumMagenta))
        case .discussed:
            Circle().stroke(AppColors.spectrumPurple, lineWidth: 1.5).frame(width: 20, height: 20)
                .overlay(dotGlyph(AppIcons.bubbleLeftAndBubbleRightFill, AppColors.spectrumPurple))
        case .planning:
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                .foregroundStyle(AppColors.spectrumCyan)
                .frame(width: 20, height: 20)
        case .didIt:
            Circle().fill(AppColors.spectrumBorder).frame(width: 20, height: 20)
                .overlay(dotGlyph(AppIcons.checkmark, Color.white))
        case .skipped:
            EmptyView() // never rendered — skipped landmarks are excluded via visibleLandmarks
        }
    }

    /// The small glyph inside a ledger dot (mockup §03: ♥ curious, ▤/bubble
    /// discussed, ✓ did it). Sized off AppFonts.meta so it stays token-clean.
    private func dotGlyph(_ systemName: String, _ color: Color) -> some View {
        Image(systemName: systemName)
            .font(AppFonts.meta)
            .foregroundStyle(color)
    }
}

// MARK: - Previews

#if DEBUG
/// Reuses PathTrailView's preview harness scenario so the Ledger and Trail
/// previews prove the same five-state/no-cascade story from two readings.
@MainActor
private struct PathLedgerPreviewHarness: View {
    private let store: PathStore

    init() {
        let coupleId = UUID()
        let profileId = UUID()
        let now = Date()
        let transport = MockPathTransport()

        func row(_ landmarkId: String, _ state: PathLandmarkState, discussedVia: DiscussedVia? = nil) -> PathLandmarkProgress {
            PathLandmarkProgress(
                id: UUID(), coupleId: coupleId, pathStyle: "swinging", landmarkId: landmarkId,
                state: state, discussedVia: discussedVia, didItDate: state == .didIt ? now : nil,
                setBy: profileId, updatedAt: now
            )
        }

        transport.progress = [
            row("fantasy-talk", .didIt),
            row("watch-together", .didIt),
            row("virtual-hellos", .didIt),
            row("strip-club", .planning),
            row("flirt-bar", .curious),
            row("lifestyle-club", .didIt),
            row("seen-as-couple", .discussed, discussedVia: .session),
            row("dinner-couple", .discussed, discussedVia: .manual)
        ]

        store = PathStore(coupleId: coupleId, profileId: profileId, pathStyle: "swinging", transport: transport)
    }

    var body: some View {
        PathLedgerView(store: store, onSelect: { _ in })
            .task { await store.load() }
    }
}

#Preview("PathLedgerView — status/date text the trail omits") {
    PathLedgerPreviewHarness()
}
#endif
