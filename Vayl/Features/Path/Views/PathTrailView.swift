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
//  Tapping a node opens that landmark's NodeView — the trail is the primary
//  reading, so it is also a primary way in (mockup §04: NodeView is "the
//  primary interaction now"). The presenting surface is still PathScreen's
//  job; this view only forwards the tapped id up through `onSelect`, the same
//  seam PathLedgerView already uses.
//

import SwiftUI

struct PathTrailView: View {
    let store: PathStore
    let onSelect: (String) -> Void

    /// Drives the "Now" beacon's slow breathing glow. Toggled true onAppear; the
    /// `.ambientAnimation` gate disables the loop under Reduce Motion / Low Power,
    /// where it simply resolves to the steady bright state instead.
    @State private var nowBreathe = false

    // The fixed 264×836 coordinate stage the node positions and bezier control
    // points below are a literal port of (path-full-flow.html §02). Named here
    // rather than re-typed as bare literals at each use site.
    private static let stageWidth: CGFloat = 264
    private static let stageHeight: CGFloat = 836
    // A comfortable tap target centered on each (visually much smaller) node.
    private static let nodeHitTarget: CGFloat = 44
    private static let labelWidth: CGFloat = 100
    private static let labelGap: CGFloat = 12

    /// Opacities ported straight from the node-state redesign mockup's node
    /// specs (path-node-state-redesign-suite.html §01), named here so the trail
    /// carries no bare opacity literals.
    private enum Opacity {
        static let curiousFill = 0.12
        static let discussedFill = 0.16
        static let aheadStroke = 0.32
        static let forkStroke = 0.30
        static let traveledGlow = 0.60
        static let privateMarkBorder = 0.45
        static let beaconGlowLow = 0.30
        static let beaconGlowHigh = 0.70
        static let didItInnerHighlight = 0.22
    }

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
        // The node positions and bezier curve are a literal port of a fixed
        // 264-wide SVG stage. Rather than pin the trail to 264pt (which left it
        // a narrow column with dead space either side on any real device), scale
        // that design space up to the available width so it fills the screen the
        // way the mockup's 264-in-270 phone does. Node glyphs and label text stay
        // unscaled (crisp, tappable); only positions and the curve scale.
        GeometryReader { geo in
            let scale = geo.size.width / Self.stageWidth

            ScrollView {
                ZStack(alignment: .topLeading) {
                    trailCurve
                        .frame(width: Self.stageWidth, height: Self.stageHeight)
                        .scaleEffect(scale, anchor: .topLeading)

                    ForEach(store.visibleLandmarks) { landmark in
                        if let point = Self.nodePositions[landmark.id] {
                            Button {
                                onSelect(landmark.id)
                            } label: {
                                nodeView(for: landmark)
                                    .frame(width: Self.nodeHitTarget, height: Self.nodeHitTarget)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(PressableCardStyle())
                            .accessibilityLabel(landmark.title)
                            .position(x: point.x * scale, y: point.y * scale)

                            label(for: landmark, at: point, scale: scale)
                        }
                    }
                }
                .frame(width: geo.size.width, height: Self.stageHeight * scale, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// Places a landmark's name on the open side of the winding trail: left-column
    /// nodes get a left-aligned label to their right, right-column nodes get a
    /// right-aligned label to their left. This is what keeps the right column from
    /// clipping off the stage edge — the old flat `x + 60` pushed every
    /// right-column label (nodes at x≈187-199) past it. `scale` maps the fixed
    /// 264-space anchor into the scaled-to-width layout; the label's own text
    /// stays unscaled.
    private func label(for landmark: PathLandmark, at point: CGPoint, scale: CGFloat) -> some View {
        let isRightColumn = point.x > Self.stageWidth / 2
        let anchorX = point.x * scale
        let centerX = isRightColumn
            ? anchorX - Self.labelGap - Self.labelWidth / 2
            : anchorX + Self.labelGap + Self.labelWidth / 2
        return Text(landmark.title)
            .font(AppFonts.sectionLabelSmall)
            .foregroundStyle(landmark.id == store.nowLandmarkId ? AppColors.textBright : AppColors.textPrimary)
            .frame(width: Self.labelWidth, alignment: isRightColumn ? .trailing : .leading)
            .multilineTextAlignment(isRightColumn ? .trailing : .leading)
            .position(x: centerX, y: point.y * scale - 8)
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
                .stroke(AppColors.spectrumPurple.opacity(Opacity.aheadStroke), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [1, 7]))
            PathForkShape()
                .stroke(AppColors.spectrumPurple.opacity(Opacity.forkStroke), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [1, 7]))
            PathTraveledShape()
                .stroke(AppColors.spectrumBorder, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .opacity(Opacity.traveledGlow)
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
                // On the marking partner's own device only, a landmark they've
                // privately marked Curious (but not yet shared) shows a small
                // magenta corner dot over the plain Untouched node — quiet, never
                // a full trail state (mockup §05). The partner's trail has no such
                // mark, since `privateMarkedLandmarkIds` is this profile's alone.
                let privateCurious = store.isPrivatelyMarkedCurious(landmark.id)
                Circle()
                    .stroke(
                        privateCurious ? AppColors.spectrumMagenta.opacity(Opacity.privateMarkBorder) : AppColors.borderSubtle,
                        lineWidth: 2
                    )
                    .frame(width: 10, height: 10)
                    .overlay(alignment: .topTrailing) {
                        if privateCurious {
                            Circle()
                                .fill(AppColors.spectrumMagenta)
                                .frame(width: 5, height: 5)
                                .offset(x: 2, y: -2)
                        }
                    }
            case .curious:
                Circle().stroke(AppColors.spectrumMagenta, lineWidth: 1.5).frame(width: 12, height: 12)
                    .background(Circle().fill(AppColors.spectrumMagenta.opacity(Opacity.curiousFill)))
            case .discussed:
                // Provenance mark (mockup §01): a structured ▤-style inner rect for
                // a real session, a simple filled dot for a manual "we talked" tap.
                // The Ledger spells it out in words too.
                let via = store.discussedVia(for: landmark.id)
                Circle().stroke(AppColors.spectrumPurple, lineWidth: 1.5).frame(width: 13, height: 13)
                    .background(Circle().fill(AppColors.spectrumPurple.opacity(Opacity.discussedFill)))
                    .overlay {
                        if via == .session {
                            RoundedRectangle(cornerRadius: 1, style: .continuous)
                                .stroke(AppColors.spectrumPurple, lineWidth: 1)
                                .frame(width: 6, height: 4)
                        } else {
                            Circle().fill(AppColors.spectrumPurple).frame(width: 4, height: 4)
                        }
                    }
            case .planning:
                Circle().strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    .foregroundStyle(AppColors.spectrumCyan)
                    .frame(width: 13, height: 13)
            case .didIt:
                // Unified completion look plus the mockup's soft inner highlight
                // (§01: an inset white core at low opacity over the spectrum fill).
                Circle()
                    .fill(AppColors.spectrumBorder)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .fill(Color.white.opacity(Opacity.didItInnerHighlight))
                            .frame(width: 8, height: 8)
                    )
            case .skipped:
                EmptyView() // never rendered — skipped landmarks are excluded via visibleLandmarks
            }
        }
        .overlay(isNow ? nowBeacon : nil)
    }

    /// The wayfinding anchor (spec §8) — the brightest, steadiest mark on the
    /// trail, laid over whatever state node sits at "Now" (Now never encodes a
    /// state of its own). A crisp cyan ring for the anchor plus a screen-blend
    /// blurred cyan glow whose opacity breathes 0.3→0.7 — the glow breathes, not
    /// the core (spectrum glow recipe), and never a full 0→1 (animation contract).
    private var nowBeacon: some View {
        ZStack {
            Circle()
                .stroke(AppColors.spectrumCyan, lineWidth: 3)
                .frame(width: 26, height: 26)
                .blur(radius: 5)
                .blendMode(.screen)
                .opacity(nowBreathe ? Opacity.beaconGlowHigh : Opacity.beaconGlowLow)
                .ambientAnimation(AppAnimation.cardBreathe, value: nowBreathe)
            Circle()
                .stroke(AppColors.spectrumCyan, lineWidth: 2)
                .frame(width: 24, height: 24)
        }
        .onAppear { nowBreathe = true }
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
@MainActor
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
        // Match PathScreen's real background so the preview isn't misleadingly
        // all-black — void + the same OB atmosphere every screen root layers.
        ZStack {
            AppColors.void.ignoresSafeArea()
            PathAtmosphere()
            PathTrailView(store: store, onSelect: { _ in })
        }
        .task { await store.load() }
    }
}

#Preview("PathTrailView — five states, no-cascade proof") {
    PathTrailPreviewHarness()
}
#endif
