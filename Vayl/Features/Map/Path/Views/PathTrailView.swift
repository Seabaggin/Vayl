//
//  PathTrailView.swift
//  Vayl — Path
//
//  The spatial trail — the primary reading of the couple's Path map (spec
//  §2.1, docs/superpowers/specs/2026-07-06-path-feature-design.md; re-skinned
//  for the five-state model by docs/superpowers/specs/2026-07-07-path-node-
//  state-redesign.md). A literal, coordinate-for-coordinate port of
//  docs/prototypes/path-full-flow.html §02's 264×836 SVG stage — node
//  positions and the connecting bezier geometry are never re-derived, only
//  translated into SwiftUI Path/Shape calls.
//
//  Node colors follow docs/prototypes/path-node-state-redesign-suite.html
//  §01's legend (magenta = Curious, purple = Discussed, dashed cyan =
//  Planning, spectrum-gradient = Did it, dim outline = Untouched). Labels are
//  name only — no status/date text on the trail (§02's own note: "Status and
//  timing live in the ledger instead"). No cascading: each node's look comes
//  straight from `store.state(for:)`, independent of every other landmark
//  (PathStore's no-cascading guarantee) — this is what makes "Lifestyle
//  club" reading Did it while "Flirt at a bar" / "An NM mixer" sit behind it
//  visually possible without any special-casing here.
//
//  This view is presentation only, no tap handling — same "content dropped
//  into whatever wraps it" posture as PathNodeView; wiring taps to open
//  NodeView and the ☰/⚷/⋯ header contract belong to PathScreen (Task 12).
//

import SwiftUI

struct PathTrailView: View {
    let store: PathStore

    /// Literal port of the node coordinates from path-full-flow.html §02's
    /// 264×836 stage — same 13 landmarks, same positions, never re-derived.
    private static let nodePositions: [String: CGPoint] = [
        "fantasy-talk": CGPoint(x: 59, y: 40),
        "watch-together": CGPoint(x: 199, y: 88),
        "virtual-hellos": CGPoint(x: 77, y: 143),
        "strip-club": CGPoint(x: 187, y: 220),
        "flirt-bar": CGPoint(x: 70, y: 278),
        "nm-mixer": CGPoint(x: 192, y: 330),
        "lifestyle-club": CGPoint(x: 79, y: 406),
        "seen-as-couple": CGPoint(x: 187, y: 458),
        "dinner-couple": CGPoint(x: 68, y: 535),
        "same-room": CGPoint(x: 187, y: 588),
        "soft-swap": CGPoint(x: 81, y: 642),
        "full-swap": CGPoint(x: 192, y: 693),
        "solo-night": CGPoint(x: 132, y: 774)
    ]

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
                    icon: "map",
                    headline: "No landmarks yet",
                    message: "Your shared path will appear here once it's set up."
                )
            } else {
                trail
            }
        }
    }

    private var trail: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                trailCurve
                ForEach(store.visibleLandmarks) { landmark in
                    if let point = Self.nodePositions[landmark.id] {
                        nodeView(for: landmark)
                            .position(point)
                        Text(landmark.title)
                            .font(AppFonts.sectionLabelSmall)
                            .foregroundStyle(landmark.id == store.nowLandmarkId ? AppColors.textBright : AppColors.textPrimary)
                            .position(x: point.x + 60, y: point.y - 8)
                    }
                }
            }
            .frame(width: 264, height: 836)
        }
    }

    // MARK: - Trail curve — literal bezier port, never re-derived
    //
    // Static background geometry, independent of any landmark's live state —
    // the identical AHEAD (dashed, dim)/TRAVELED (bright, glow+crisp two-pass)
    // shape every time, exactly as path-node-state-redesign-suite.html §02
    // renders it regardless of which nodes are Did it (spec §2/§2.1: "not to
    // be redrawn or approximated").

    private var trailCurve: some View {
        ZStack {
            PathAheadShape()
                .stroke(AppColors.spectrumPurple.opacity(0.32), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [1, 7]))
            PathForkShape()
                .stroke(AppColors.spectrumPurple.opacity(0.3), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [1, 7]))
            PathTraveledShape()
                .stroke(AppColors.spectrumBorder, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .opacity(0.6)
                .blur(radius: 4)
            PathTraveledShape()
                .stroke(AppColors.spectrumBorder, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        }
    }

    // MARK: - Node

    @ViewBuilder
    private func nodeView(for landmark: PathLandmark) -> some View {
        let state = store.state(for: landmark.id)
        let isNow = landmark.id == store.nowLandmarkId
        Group {
            switch state {
            case .untouched:
                Circle().stroke(AppColors.borderSubtle, lineWidth: 2).frame(width: 10, height: 10)
            case .curious:
                Circle().stroke(AppColors.spectrumMagenta, lineWidth: 1.5).frame(width: 12, height: 12)
                    .background(Circle().fill(AppColors.spectrumMagenta.opacity(0.12)))
            case .discussed:
                Circle().stroke(AppColors.spectrumPurple, lineWidth: 1.5).frame(width: 13, height: 13)
                    .background(Circle().fill(AppColors.spectrumPurple.opacity(0.16)))
            case .planning:
                Circle().strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    .foregroundStyle(AppColors.spectrumCyan)
                    .frame(width: 13, height: 13)
            case .didIt:
                Circle()
                    .fill(AppColors.spectrumBorder)
                    .frame(width: 14, height: 14)
            case .skipped:
                EmptyView() // never rendered — skipped landmarks are excluded via visibleLandmarks
            }
        }
        .overlay(isNow ? Circle().stroke(AppColors.spectrumCyan, lineWidth: 2).frame(width: 22, height: 22) : nil)
    }
}

// MARK: - Trail curve shapes — literal bezier port from path-full-flow.html
// §02's 264×836 SVG (the exact same coordinate family used throughout this
// mockup suite; see also path-node-state-redesign-suite.html §02). Every
// control point below is copied straight from the SVG `d` attributes, not
// re-derived from the node positions above.

/// The "ahead" segment — dim, dashed, unfilled — from the strip club down to
/// the solo-night branch point.
private struct PathAheadShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 187, y: 220))
        path.addCurve(to: CGPoint(x: 70, y: 278), control1: CGPoint(x: 187, y: 249), control2: CGPoint(x: 70, y: 249))
        path.addCurve(to: CGPoint(x: 192, y: 330), control1: CGPoint(x: 70, y: 304), control2: CGPoint(x: 192, y: 304))
        path.addCurve(to: CGPoint(x: 79, y: 406), control1: CGPoint(x: 192, y: 368), control2: CGPoint(x: 79, y: 368))
        path.addCurve(to: CGPoint(x: 187, y: 458), control1: CGPoint(x: 79, y: 432), control2: CGPoint(x: 187, y: 432))
        path.addCurve(to: CGPoint(x: 68, y: 535), control1: CGPoint(x: 187, y: 496), control2: CGPoint(x: 68, y: 496))
        path.addCurve(to: CGPoint(x: 187, y: 588), control1: CGPoint(x: 68, y: 561), control2: CGPoint(x: 187, y: 561))
        path.addCurve(to: CGPoint(x: 81, y: 642), control1: CGPoint(x: 187, y: 614), control2: CGPoint(x: 81, y: 614))
        path.addCurve(to: CGPoint(x: 192, y: 693), control1: CGPoint(x: 81, y: 668), control2: CGPoint(x: 192, y: 668))
        path.addCurve(to: CGPoint(x: 132, y: 774), control1: CGPoint(x: 192, y: 733), control2: CGPoint(x: 132, y: 733))
        return path
    }
}

/// The terminal fork at the solo-night branch point — two short dashed
/// strokes splitting off the end of the ahead path, where a solo night's
/// paths split (spec: docs/superpowers/specs/2026-07-06-path-feature-design.md §2).
private struct PathForkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 132, y: 774))
        path.addCurve(to: CGPoint(x: 104, y: 804), control1: CGPoint(x: 128.4, y: 789), control2: CGPoint(x: 110, y: 791))
        path.move(to: CGPoint(x: 132, y: 774))
        path.addCurve(to: CGPoint(x: 160, y: 804), control1: CGPoint(x: 135.6, y: 789), control2: CGPoint(x: 154, y: 791))
        return path
    }
}

/// The "traveled" segment — bright, glow+crisp two-pass gradient stroke —
/// from the fantasy talk landmark down to the strip club.
private struct PathTraveledShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 59, y: 40))
        path.addCurve(to: CGPoint(x: 199, y: 88), control1: CGPoint(x: 59, y: 64), control2: CGPoint(x: 199, y: 64))
        path.addCurve(to: CGPoint(x: 77, y: 143), control1: CGPoint(x: 199, y: 115), control2: CGPoint(x: 77, y: 115))
        path.addCurve(to: CGPoint(x: 187, y: 220), control1: CGPoint(x: 77, y: 181), control2: CGPoint(x: 187, y: 181))
        return path
    }
}

// MARK: - Previews

#if DEBUG
/// Seeds the exact scenario path-node-state-redesign-suite.html §02 uses to
/// prove its two hardest rules:
/// (a) no-cascading — "Lifestyle club" (landmark 7) reads Did it while
///     "Flirt at a bar" (5) and "An NM mixer" (6), both earlier and smaller,
///     sit at Curious and Untouched. Nothing cascades from the later, bigger
///     mark.
/// (b) Now is pure wayfinding, not a state — "The strip club" carries the
///     Now ring AND an independent Planning color at the same time, proving
///     "Now never encoded state on its own."
private struct PathTrailPreviewHarness: View {
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
            // "strip-club" is Planning, not untouched — it's still the
            // earliest not-yet-Did-it/skipped landmark, so it's ALSO where
            // PathStore.nowLandmarkId anchors "Now" (proof b, above).
            row("strip-club", .planning),
            row("flirt-bar", .curious),
            // "nm-mixer" stays untouched — smaller and later than
            // lifestyle-club, proving the no-cascade rule below (proof a).
            row("lifestyle-club", .didIt),
            row("seen-as-couple", .discussed, discussedVia: .session),
            row("dinner-couple", .discussed, discussedVia: .manual)
        ]
        transport.privateMarks = [
            PathPrivateMark(id: UUID(), profileId: profileId, coupleId: coupleId, pathStyle: "swinging", landmarkId: "soft-swap", markedAt: now)
        ]

        store = PathStore(coupleId: coupleId, profileId: profileId, pathStyle: "swinging", transport: transport)
    }

    var body: some View {
        PathTrailView(store: store)
            .background(AppColors.void.ignoresSafeArea())
            .task { await store.load() }
    }
}

#Preview("PathTrailView — five states, no-cascade proof") {
    PathTrailPreviewHarness()
}
#endif
