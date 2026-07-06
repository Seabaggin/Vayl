// Design/Components/Cards/InfiniteCarousel.swift
//
// A full-width paging carousel that:
//   • auto-advances on an interval (discoverability),
//   • supports swipe (TabView page style), and
//   • loops infinitely via clone-and-reset at the seam.
//
// Reduce Motion disables the auto-advance (swipe still works). A fixed height
// is required — TabView's page style does not size to its content.
//
// DEVICE-TUNE (per Build Protocol — feel is confirmed on device, not in code):
//   • `interval`, the advance animation, and the seam-reset `jump` delay are
//     placeholder timings; verify the loop reads seamless and adjust to taste.
//   • TabView page style is the simplest swipe+paging primitive but is fiddly;
//     if the seam flickers on device, the fallback is a ScrollView + paging.

import SwiftUI

struct InfiniteCarousel<Item: Identifiable, Content: View>: View {
    let items: [Item]
    var interval: TimeInterval = 5
    var height: CGFloat
    @ViewBuilder var content: (Item) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selection: Int = 1

    private var realCount: Int { items.count }
    private var paddedCount: Int { realCount + 2 }
    private var realIndex: Int {
        guard realCount > 0 else { return 0 }
        return ((selection - 1) % realCount + realCount) % realCount
    }

    var body: some View {
        if items.isEmpty {
            EmptyView()
        } else if items.count == 1 {
            content(items[0]).frame(height: height)
        } else {
            VStack(spacing: AppSpacing.sm) {
                TabView(selection: $selection) {
                    ForEach(0..<paddedCount, id: \.self) { i in
                        content(paddedItem(at: i)).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: height)
                .onChange(of: selection) { _, new in handleSeam(new) }
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

    private func paddedItem(at i: Int) -> Item {
        if i == 0 { return items[realCount - 1] }      // clone of last
        if i == paddedCount - 1 { return items[0] }    // clone of first
        return items[i - 1]
    }

    // When the user lands on a clone, snap (without animation) back to the
    // matching real slide once the paging animation has settled.
    private func handleSeam(_ new: Int) {
        guard realCount > 1 else { return }
        if new == 0 {
            jump(to: realCount)
        } else if new == paddedCount - 1 {
            jump(to: 1)
        }
    }

    private func jump(to index: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { selection = index }
        }
    }

    private func autoAdvance() async {
        guard !reduceMotion, realCount > 1 else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(interval))
            guard !Task.isCancelled else { break }
            withAnimation(AppAnimation.standard) { selection += 1 }
        }
    }
}
