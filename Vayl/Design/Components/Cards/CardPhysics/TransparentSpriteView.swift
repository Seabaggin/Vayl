// Features/Onboarding/Canvas/TransparentSpriteView.swift

import SpriteKit
import SwiftUI

/// Drop-in replacement for SwiftUI's `SpriteView` that forces the underlying `SKView`
/// to composite as transparent.
///
/// `SpriteView(options: [.allowsTransparency])` doesn't reliably propagate to the
/// Simulator's Metal backend: the SKView falls back to an opaque light-gray fill
/// that washes out everything beneath it (void, atmosphere), even though the scene
/// has `backgroundColor = .clear` and no children to draw. Setting `allowsTransparency`
/// / `isOpaque` directly on the SKView before it presents the scene fixes it — this is
/// the standard workaround for this SpriteKit/Metal compositing quirk. Renders
/// correctly on device either way.
///
/// Preserves the same frame-rate cap and idle-render gate as SwiftUI's SpriteView,
/// driven by a CADisplayLink instead of the built-in `shouldRender` parameter.
struct TransparentSpriteView: UIViewRepresentable {
    let scene: SKScene
    let preferredFramesPerSecond: Int
    let shouldRender: (TimeInterval) -> Bool

    func makeUIView(context: Context) -> SKView {
        let view = SKView(frame: .zero)
        view.allowsTransparency = true
        view.isOpaque = false
        view.backgroundColor = .clear
        view.preferredFramesPerSecond = preferredFramesPerSecond
        view.presentScene(scene)
        context.coordinator.attach(to: view, shouldRender: shouldRender)
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        private weak var view: SKView?
        private var shouldRender: ((TimeInterval) -> Bool)?
        nonisolated(unsafe) private var displayLink: CADisplayLink?

        func attach(to view: SKView, shouldRender: @escaping (TimeInterval) -> Bool) {
            self.view = view
            self.shouldRender = shouldRender
            let link = CADisplayLink(target: self, selector: #selector(tick))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }

        @objc private func tick(_ link: CADisplayLink) {
            guard let view, let shouldRender else { return }
            view.isPaused = !shouldRender(link.timestamp)
        }

        deinit {
            displayLink?.invalidate()
        }
    }
}
