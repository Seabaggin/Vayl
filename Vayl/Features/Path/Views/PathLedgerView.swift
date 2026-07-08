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
        List {
            ForEach(store.phases) { phase in
                Section(phase.name) {
                    ForEach(store.visibleLandmarks.filter { $0.phaseId == phase.id }) { landmark in
                        row(for: landmark)
                            .contentShape(Rectangle())
                            .onTapGesture { onSelect(landmark.id) }
                    }
                }
            }
        }
    }

    private func row(for landmark: PathLandmark) -> some View {
        HStack(spacing: AppSpacing.sm) {
            stateDot(for: landmark.id)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(landmark.title)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textBody)
                if let meta = statusText(for: landmark.id) {
                    Text(meta)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }

    private func statusText(for landmarkId: String) -> String? {
        switch store.state(for: landmarkId) {
        case .untouched: return nil
        case .curious: return "Curious"
        case .discussed:
            let via = store.discussedVia(for: landmarkId) == .session ? "via session" : "noted"
            return "Discussed · \(via)"
        case .planning: return "Planning"
        case .didIt:
            guard let date = store.didItDate(for: landmarkId) else { return "Did it" }
            return "Did it · \(date.formatted(.relative(presentation: .named)))"
        case .skipped: return nil
        }
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
        switch store.state(for: landmarkId) {
        case .untouched:
            Circle().stroke(AppColors.borderSubtle, lineWidth: 1.5).frame(width: 20, height: 20)
        case .curious:
            Circle().stroke(AppColors.spectrumMagenta, lineWidth: 1.5).frame(width: 20, height: 20)
        case .discussed:
            Circle().stroke(AppColors.spectrumPurple, lineWidth: 1.5).frame(width: 20, height: 20)
        case .planning:
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                .foregroundStyle(AppColors.spectrumCyan)
                .frame(width: 20, height: 20)
        case .didIt:
            Circle().fill(AppColors.spectrumBorder).frame(width: 20, height: 20)
        case .skipped:
            EmptyView() // never rendered — skipped landmarks are excluded via visibleLandmarks
        }
    }
}

// MARK: - Previews

#if DEBUG
/// Reuses PathTrailView's preview harness scenario so the Ledger and Trail
/// previews prove the same five-state/no-cascade story from two readings.
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
            .task { try? await store.load() }
    }
}

#Preview("PathLedgerView — status/date text the trail omits") {
    PathLedgerPreviewHarness()
}
#endif
