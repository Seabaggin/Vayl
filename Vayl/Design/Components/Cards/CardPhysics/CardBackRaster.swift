//
//  CardBackRaster.swift
//  Vayl
//
//  Design/Components/Cards/CardPhysics/CardBackRaster.swift
//

import SwiftUI

/// One-slot cache for the rasterized VaylCardBack the SpriteKit deals fly.
///
/// ImageRenderer.uiImage on a VaylCardBack (Canvas: five-pass wordmark + hex
/// moiré, through .drawingGroup) is a synchronous main-thread rasterize —
/// expensive enough to hitch the exact frame a deal launches on. Every deal in
/// a phase asks for the same size + scale, so render once and reuse; re-render
/// only when the requested size or scale changes.
///
/// Sequencers that know a deal is coming call `prewarm` at phase entry so even
/// the first deal's raster cost lands on an idle frame, not the deal frame.
@MainActor
enum CardBackRaster {

    private static var cached: (width: CGFloat, height: CGFloat, scale: CGFloat, image: UIImage)?

    /// The rasterized card back at `width` × `height` points, `scale` px/pt.
    /// Returns the cached image when the request matches the last render.
    static func image(width: CGFloat, height: CGFloat, scale: CGFloat) -> UIImage? {
        if let cached, cached.width == width, cached.height == height, cached.scale == scale {
            return cached.image
        }
        let renderer = ImageRenderer(
            content: VaylCardBack().frame(width: width, height: height)
        )
        renderer.scale = scale
        guard let image = renderer.uiImage else { return nil }
        cached = (width, height, scale, image)
        return image
    }

    /// Render ahead of the first deal so the raster never lands on the deal frame.
    static func prewarm(width: CGFloat, height: CGFloat, scale: CGFloat) {
        _ = image(width: width, height: height, scale: scale)
    }
}
