// Features/Pulse/Components/PulseCanvasScrollView.swift
// Open Lightly
//
// Pure SwiftUI ScrollView wrapper for PulseGraph.
// Both axes owned by SwiftUI — no UIKit conflict.
// Anchors to bottom-trailing on appear:
//   trailing → most recent entry visible
//   bottom   → Contracted zone visible, scroll up for Expansive
//
// isGraphActive binding locks the outer HomeDashboardView ScrollView
// the moment a touch lands on the graph. Unlocks on finger lift.
// DragGesture(minimumDistance: 0) fires before the outer ScrollView
// can claim the gesture — so scroll locking is immediate.

import SwiftUI

struct PulseCanvasScrollView: View {

    // MARK: - Inputs

    let entries:      [PulseEntry]
    let cardWidth:    CGFloat
    let cardHeight:   CGFloat
    let canvasWidth:  CGFloat
    let canvasHeight: CGFloat
    var onDotTapped:  ((PulseEntry, CGPoint) -> Void)? = nil

    // MARK: - Outer scroll lock

    @Binding var isGraphActive: Bool

    // MARK: - Internal state

    @State private var hasAnchored = false

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                PulseGraph(
                    entries:          entries,
                    graphWidth:       canvasWidth,
                    graphHeight:      canvasHeight,
                    onDotTapped:      onDotTapped,
                    disableTouchGlow: true
                )
                .frame(width: canvasWidth, height: canvasHeight)
                .overlay(alignment: .bottomTrailing) {
                    Color.clear
                        .frame(width: 1, height: 1)
                        .id("pulseAnchor")
                }
            }
            .onAppear {
                guard !hasAnchored else { return }
                hasAnchored = true
                DispatchQueue.main.async {
                    proxy.scrollTo("pulseAnchor", anchor: .bottomTrailing)
                }
            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }
}
