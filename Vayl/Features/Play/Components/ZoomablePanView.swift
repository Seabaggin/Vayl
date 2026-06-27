//
//  ZoomablePanView.swift
//  Vayl — Play
//
//  A UIScrollView that pinch-zooms and pans arbitrary SwiftUI content. Used for
//  the expanded deck wall so browsing feels like roaming a premium gallery.
//  Content MUST be static/cheap (flat DeckCaseViews) — never live shaders.
//

import SwiftUI

struct ZoomablePanView<Content: View>: UIViewRepresentable {
    var minZoom: CGFloat = 0.6
    var maxZoom: CGFloat = 1.8
    @ViewBuilder var content: () -> Content

    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.minimumZoomScale = minZoom
        scroll.maximumZoomScale = maxZoom
        scroll.bouncesZoom = true
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.delegate = context.coordinator
        scroll.backgroundColor = .clear
        scroll.contentInsetAdjustmentBehavior = .never

        let host = context.coordinator.host
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            host.view.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
        ])
        return scroll
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.host.rootView = AnyView(content())
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        let host = UIHostingController(rootView: AnyView(EmptyView()))
        func viewForZooming(in scrollView: UIScrollView) -> UIView? { host.view }
    }
}
