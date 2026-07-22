// Design/Components/Cards/InfiniteCarousel.swift
//
// A full-width paging carousel that:
//   • optionally auto-advances on an interval (discoverability),
//   • supports swipe (native horizontal ScrollView paging), and
//   • shows a page-dot indicator.
//
// 2026-07-21 — the paging engine changed from `TabView(.page)` to a horizontal
// ScrollView with `.scrollTargetBehavior(.paging)`. TabView's page style is
// UIKit's UIPageViewController, which paints its OWN background across the
// paging region — `.background(.clear)` can't clear the page controller's
// internal scroll view — so when the carousel sits inside a clear-glass
// `.learnCard()` the pages covered the glass exactly where the cards are. A
// ScrollView is transparent by default and lets the glass (and the atmosphere
// behind it) read through. Deployment target is 26.0, so the scroll paging APIs
// are available.
//
// TRADE: the old TabView path looped infinitely (clone-and-reset at the seam).
// The paging ScrollView does not wrap — swiping past the last slide stops, which
// is the standard iOS paged-preview behaviour and removes the seam-jump hitch.
// The only call site (ResearchSection) already passed `autoAdvances: false`, so
// no motion behaviour changed there. (The type name is now slightly inaccurate;
// renaming it is a mechanical follow-up, not worth the churn mid-change.)
//
// Reduce Motion / Low Power disable the auto-advance; swipe still works. A
// carousel that moves without the user asking is decorative motion — prefer the
// swipe-only form unless the drift genuinely earns discoverability.
// A fixed height is required — paged slides don't size to content.

import SwiftUI

struct InfiniteCarousel<Item: Identifiable, Content: View, EmptyContent: View>: View {
    let items: [Item]
    var interval: TimeInterval = AppAnimation.ambientDwell
    /// When false, the carousel only moves when the user swipes.
    var autoAdvances: Bool = true
    var height: CGFloat
    @ViewBuilder var content: (Item) -> Content
    /// Shown when `items` is empty. Defaults to the original EmptyView (render
    /// nothing) so existing call sites are untouched; sections that want a
    /// visible empty state pass the contract icon+headline+sub-label here.
    var emptyContent: () -> EmptyContent

    init(
        items: [Item],
        interval: TimeInterval = AppAnimation.ambientDwell,
        autoAdvances: Bool = true,
        height: CGFloat,
        @ViewBuilder content: @escaping (Item) -> Content,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent
    ) {
        self.items = items
        self.interval = interval
        self.autoAdvances = autoAdvances
        self.height = height
        self.content = content
        self.emptyContent = emptyContent
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The id of the slide currently paged into view. Optional per the
    /// `.scrollPosition` contract; nil before the first layout resolves.
    @State private var currentID: Int?

    private var realCount: Int { items.count }
    private var realIndex: Int {
        guard realCount > 0 else { return 0 }
        return min(max(currentID ?? 0, 0), realCount - 1)
    }

    var body: some View {
        if items.isEmpty {
            emptyContent()
        } else if items.count == 1 {
            content(items[0]).frame(height: height)
        } else {
            VStack(spacing: AppSpacing.sm) {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            content(item)
                                .containerRelativeFrame(.horizontal)
                                .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
                .scrollPosition(id: $currentID)
                .frame(height: height)
                .task(id: items.count) { await autoAdvance() }

                dots
            }
        }
    }

    private var dots: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(0..<realCount, id: \.self) { i in
                Capsule()
                    .fill(i == realIndex ? AnyShapeStyle(AppColors.spectrumText)
                                         : AnyShapeStyle(AppColors.textMuted))
                    .frame(width: i == realIndex ? 18 : 6, height: 6)
                    .animation(AppAnimation.standard, value: realIndex)
            }
        }
        .accessibilityHidden(true)
    }

    private func autoAdvance() async {
        guard autoAdvances, !reduceMotion, realCount > 1 else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(interval))
            guard !Task.isCancelled else { break }
            let next = (realIndex + 1) % realCount
            withAnimation(AppAnimation.standard) { currentID = next }
        }
    }
}

extension InfiniteCarousel where EmptyContent == EmptyView {
    /// Preserves the original behavior — an empty `items` renders nothing.
    init(
        items: [Item],
        interval: TimeInterval = AppAnimation.ambientDwell,
        autoAdvances: Bool = true,
        height: CGFloat,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.init(
            items: items,
            interval: interval,
            autoAdvances: autoAdvances,
            height: height,
            content: content,
            emptyContent: { EmptyView() }
        )
    }
}
