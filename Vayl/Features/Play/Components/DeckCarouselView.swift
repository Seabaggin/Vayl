//
//  DeckCarouselView.swift
//  Vayl — Play
//
//  The Explore surface — a full-screen, section-scoped, swipeable deck-detail
//  carousel that replaces the old centered DeckDetailView overlay. Presented as an
//  in-tab ZStack layer (NOT a sheet/cover) driven purely by PlayStore carousel
//  state: renders nothing when `store.carouselSection == nil`, fades in when a
//  section opens.
//
//  Physics come from the shared `CarouselPhysics` engine on the weighted
//  `.deckBrowse` preset (one deliberate deck per flick, firm near-critical settle,
//  firmer end-walls). This view is a CONSUMER of that engine — same gesture→drag/
//  settle pattern as VaylCardCarousel / CardCarousel — it never re-implements the
//  scroll math.
//
//  Spec: docs/superpowers/specs/2026-07-11-play-deck-library-redesign-design.md §8.
//

import SwiftUI

struct DeckCarouselView: View {
    let store: PlayStore

    var body: some View {
        ZStack {
            if let section = store.carouselSection, !section.isEmpty {
                // A fresh stage (fresh @State physics, centered on the tapped deck)
                // whenever the SECTION changes — not when the centered deck changes
                // mid-scroll. The signature is stable across a browse.
                CarouselStage(store: store, section: section)
                    .id(section.map(\.id).joined(separator: "|"))
                    .transition(.opacity)
            }
        }
        .animation(AppAnimation.arrive, value: store.carouselSection?.count ?? 0)
    }
}

// MARK: - Stage

/// One live carousel instance for a given section. Owns the `CarouselPhysics` (via
/// @State, initialised centered on the store's center deck) plus the drag/dismiss
/// gesture state. Recreated by `.id(sectionSignature)` when the section changes.
private struct CarouselStage: View {
    let store: PlayStore
    let section: [DeckSummary]

    @State private var physics: CarouselPhysics
    @State private var dragBegan = false
    /// Trailing (timestamp, translation) samples → a stable release-velocity estimate
    /// (same technique as VaylCardCarousel; steadier than DragGesture.velocity).
    @State private var samples: [(t: TimeInterval, x: CGFloat)] = []
    /// Downward drag of the whole stack for swipe-to-dismiss (0 = resting).
    @State private var verticalDrag: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // ── Feel constants (layout mechanics, not spacing/opacity tokens) ────────────
    // Peer of StackLayout in VaylCardCarousel: the off-center falloff shape. FEEL-GATE.
    private let panelWidthFraction: CGFloat = 0.86   // panel width as a fraction of the stage
    private let neighborSpacing: CGFloat = 0.94   // horizontal push per card-distance (× panelW)
    private let scaleFalloff: CGFloat = 0.14   // scale lost per card-distance
    private let opacityFalloff: Double = 0.72   // opacity lost per card-distance
    private let rotationPerCard: Double = 5.0    // degrees of fan tilt per card-distance
    private let minScale: CGFloat = 0.82
    // Dismiss thresholds.
    private let dismissTravel: CGFloat = 130   // past this downward drag → close
    private let dismissFadeSpan: CGFloat = 320   // drag distance mapped to full fade

    init(store: PlayStore, section: [DeckSummary]) {
        self.store = store
        self.section = section
        let engine = CarouselPhysics(count: section.count, wraps: false, config: .deckBrowse)
        // Center on the tapped deck (position starts at 0; step to its index).
        let start = section.firstIndex { $0.id == store.carouselCenterID } ?? 0
        engine.step(by: start)
        _physics = State(initialValue: engine)
    }

    var body: some View {
        ZStack {
            backdrop
            VStack(spacing: AppSpacing.md) {
                grabBar
                stage
                paginationDots
            }
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.lg)
            .offset(y: verticalDrag)
            .opacity(dismissFade)

            closeButton
        }
    }

    // MARK: - Backdrop

    private var backdrop: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(AppColors.scrimHeavy)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { store.closeCarousel() }
            .accessibilityLabel("Close deck detail")
            .accessibilityAddTraits(.isButton)
    }

    // MARK: - Grab bar (swipe-down-to-dismiss)

    private var grabBar: some View {
        Capsule()
            .fill(AppColors.borderActive)
            .frame(width: 40, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .contentShape(Rectangle())
            .gesture(dismissGesture)
            .accessibilityLabel("Dismiss")
            .accessibilityHint("Swipe down to close")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { store.closeCarousel() }
    }

    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                verticalDrag = max(0, value.translation.height)
            }
            .onEnded { value in
                if value.translation.height > dismissTravel || value.velocity.height > 900 {
                    store.closeCarousel()
                } else {
                    withAnimation(AppAnimation.spring) { verticalDrag = 0 }
                }
            }
    }

    private var dismissFade: Double {
        1 - Double(min(verticalDrag, dismissFadeSpan) / dismissFadeSpan)
    }

    // MARK: - Stage (panel ring)

    private var stage: some View {
        GeometryReader { geo in
            let stageW = geo.size.width
            let stageH = geo.size.height
            let panelW = stageW * panelWidthFraction

            ZStack {
                ForEach(Array(section.enumerated()), id: \.element.id) { index, deck in
                    panel(deck, index: index, panelW: panelW, stageH: stageH)
                }
            }
            .frame(width: stageW, height: stageH)
            .contentShape(Rectangle())
            .gesture(browseGesture)
            // VoiceOver: one adjustable element that steps the carousel left/right.
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Deck \(physics.currentIndex + 1) of \(section.count)")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: step(by: 1)
                case .decrement: step(by: -1)
                @unknown default: break
                }
            }
        }
    }

    private func panel(_ deck: DeckSummary, index: Int, panelW: CGFloat, stageH: CGFloat) -> some View {
        // Continuous signed distance from the scroll position to this panel — the
        // single input for every off-center transform (mirrors VaylCardCarousel).
        let delta = Double(index) - physics.position
        let ad = abs(delta)
        let isCentered = index == physics.currentIndex

        return DeckPanelView(store: store, deck: deck, isCentered: isCentered)
            // Width-fixed, content-height (no forced stageH) so the panel is a compact
            // card centered in the stage, not a full-height sheet with a dead gap.
            .frame(width: panelW)
            .frame(maxHeight: stageH)
            .scaleEffect(max(1 - CGFloat(ad) * scaleFalloff, minScale))
            .rotationEffect(.degrees(reduceMotion ? 0 : delta * rotationPerCard))
            .offset(x: CGFloat(delta) * panelW * neighborSpacing)
            .opacity(max(1 - ad * opacityFalloff, 0))
            .zIndex(-ad)
            // Only the centered panel is interactive; neighbours are dimmed previews.
            .allowsHitTesting(isCentered)
    }

    // MARK: - Browse gesture (drives CarouselPhysics)

    /// minimumDistance 12 so a plain tap falls through to the centered panel's own
    /// controls (ribbon, CTA); only a real horizontal drag browses.
    private var browseGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                if !dragBegan {
                    dragBegan = true
                    samples.removeAll()
                    physics.beginDrag()
                }
                physics.drag(translation: value.translation.width)
                samples.append((Date().timeIntervalSinceReferenceDate, value.translation.width))
                if samples.count > 6 { samples.removeFirst(samples.count - 6) }
            }
            .onEnded { _ in
                defer { dragBegan = false; samples.removeAll() }
                // SwiftUI owns the settle timing (render-server, vsync-locked) → no jank.
                withAnimation(physics.settleAnimation) {
                    physics.settle(predictedVelocity: trailingVelocity())
                }
                store.carouselDidCenter(section[physics.currentIndex].id)
            }
    }

    /// Programmatic step (a11y adjustable) — same settle spring, then recenter.
    private func step(by delta: Int) {
        withAnimation(physics.settleAnimation) { physics.step(by: delta) }
        store.carouselDidCenter(section[physics.currentIndex].id)
    }

    /// Stable release velocity (points/sec) from the trailing samples.
    private func trailingVelocity() -> CGFloat {
        let now = Date().timeIntervalSinceReferenceDate
        let recent = samples.filter { now - $0.t < 0.09 }
        guard let a = recent.first, let b = recent.last, recent.count >= 2 else { return 0 }
        let dt = b.t - a.t
        guard dt > 0 else { return 0 }
        return (b.x - a.x) / CGFloat(dt)
    }

    // MARK: - Pagination dots

    private var paginationDots: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(section.indices, id: \.self) { i in
                let active = i == physics.currentIndex
                Capsule()
                    .fill(active
                          ? AnyShapeStyle(AppColors.spectrumBorder)
                          : AnyShapeStyle(AppColors.borderActive.opacity(0.5)))
                    .frame(width: active ? 16 : 6, height: 6)
                    .animation(AppAnimation.spring, value: physics.currentIndex)
            }
        }
        .accessibilityHidden(true)   // the stage's adjustable element already conveys position
    }

    // MARK: - Close button

    private var closeButton: some View {
        VaylCloseButton(accessibilityLabel: "Close deck detail") { store.closeCarousel() }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
}

#if DEBUG
#Preview("Deck carousel") {
    let store = PlayStore.preview
    store.openCarousel("the-opener")
    return DeckCarouselView(store: store)
        .preferredColorScheme(.dark)
}
#endif
