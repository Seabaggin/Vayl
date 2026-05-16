//
//  VaylCardBack.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/9/26.
//

// Shared/Components/Cards/VaylCardBack.swift

import SwiftUI

/// The back face of a VaylCard in the OB canvas.
/// Shown when VaylCardModel.flipProgress < 0.5.
///
/// Layer order (bottom to top):
///   1. Base void fill
///   2. Three atmosphere radial gradients
///   3. VAYL wordmark — four glow passes + core letterform
///   4. Hex moiré — two counter-rotated grids
///   5. Inset spectrum frame
///   6. Outer spectrum hairline
///
/// This component does NOT:
///   - Flip itself
///   - Animate itself
///   - Know what card it backs
///   - Respond to gesture
///   - Hold state
///   - Apply shadow, scale, rotation, or opacity
/// The caller (VaylCardRenderer) controls all transforms.
struct VaylCardBack: View {

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = geo.size.height
            let R = AppRadius.obCard

            Canvas { context, size in
                drawBase(context: context, size: size, R: R)
                drawAtmosphere(context: context, size: size)
                drawWordmark(context: context, size: size, W: W, H: H)
                drawHexGrid(context: context, size: size, W: W, H: H)
                drawInsetFrame(context: context, size: size, W: W, H: H, R: R)
            }
            .overlay(alignment: .center) {
                // Outer spectrum hairline — drawn as an overlay stroke so it
                // sits above the Canvas clip and renders on the card boundary.
                RoundedRectangle(cornerRadius: R)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: AppColors.spectrumCyan.opacity(0.52),    location: 0.00),
                                .init(color: AppColors.spectrumPurple.opacity(0.52),  location: 0.50),
                                .init(color: AppColors.spectrumMagenta.opacity(0.52), location: 1.00),
                            ],
                            startPoint: .leading,
                            endPoint:   .trailing
                        ),
                        lineWidth: 1.1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: R))
        }
    }
}

// MARK: — Layer 1: Base Void Fill

private extension VaylCardBack {

    func drawBase(context: GraphicsContext, size: CGSize, R: CGFloat) {
        let path = Path(roundedRect: CGRect(origin: .zero, size: size),
                        cornerRadius: R)
        context.fill(path, with: .color(AppColors.cardBg))
    }
}

// MARK: — Layer 2: Atmosphere

private extension VaylCardBack {

    func drawAtmosphere(context: GraphicsContext, size: CGSize) {
        let W = size.width
        let H = size.height
        let rect = CGRect(origin: .zero, size: size)

        // Cyan blob — top-left quadrant.
        // 0.09 — atmosphere opacity ceiling for OB canvas surfaces.
        // Matches AppColors.auroraBlob1 opacity contract — felt, not seen.
        context.fill(
            Path(rect),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: AppColors.spectrumCyan.opacity(0.09),    location: 0),
                    .init(color: AppColors.spectrumCyan.opacity(0),        location: 1),
                ]),
                center:      CGPoint(x: W * 0.38, y: H * 0.36),
                startRadius: 0,
                endRadius:   min(W, H) * 0.52
            )
        )

        // Magenta blob — bottom-right quadrant.
        // 0.09 — symmetric with cyan blob for tonal balance.
        context.fill(
            Path(rect),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: AppColors.spectrumMagenta.opacity(0.09), location: 0),
                    .init(color: AppColors.spectrumMagenta.opacity(0),    location: 1),
                ]),
                center:      CGPoint(x: W * 0.65, y: H * 0.66),
                startRadius: 0,
                endRadius:   min(W, H) * 0.52
            )
        )

        // Purple center bloom.
        // 0.15 — slightly stronger than the flanking blobs to push the
        // purple atmosphere forward. The wordmark sits inside this bloom.
        context.fill(
            Path(rect),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: AppColors.spectrumPurple.opacity(0.15), location: 0),
                    .init(color: AppColors.spectrumPurple.opacity(0),    location: 1),
                ]),
                center:      CGPoint(x: W * 0.50, y: H * 0.50),
                startRadius: 0,
                endRadius:   min(W, H) * 0.48
            )
        )
    }
}

// MARK: — Layer 3: VAYL Wordmark

private extension VaylCardBack {

    func drawWordmark(context: GraphicsContext, size: CGSize, W: CGFloat, H: CGFloat) {
        let short     = min(W, H)
        let fontSize  = (short * 0.050).rounded() // 5% larger than original 0.048
        let cx        = W / 2
        let cy        = H / 2 + fontSize * 0.10
        let tracking: CGFloat = 7

        let textBounds = CGRect(
            x:      cx - fontSize * 3.2,
            y:      cy - fontSize * 1.1,
            width:  fontSize * 6.4,
            height: fontSize * 1.4
        )

        func resolvedText(size fs: CGFloat) -> Text {
            Text("VAYL")
                .font(AppFonts.display(fs, weight: .medium, relativeTo: .largeTitle))
                .tracking(tracking)
        }

        let spectrumGradient = Gradient(stops: [
            .init(color: AppColors.spectrumCyan,    location: 0.00),
            .init(color: AppColors.spectrumBridge,  location: 0.40),
            .init(color: AppColors.spectrumMagenta, location: 1.00),
        ])

        // Pass 1 — outer bloom. Tight radius — geometric sans needs minimal spread.
        // 0.15 — low opacity. Atmosphere only, not fog.
        var outerBloom = context
        outerBloom.addFilter(.blur(radius: 5))
        outerBloom.draw(
            resolvedText(size: fontSize + 2)
                .foregroundStyle(AppColors.spectrumPurple.opacity(0.15)),
            at: CGPoint(x: cx, y: cy),
            anchor: .center
        )

        // Pass 2 — inner edge glow. Very tight. Gives the stroke face a lit quality.
        // 0.22 — enough to read as emissive edge without bleeding.
        var innerGlow = context
        innerGlow.addFilter(.blur(radius: 1.5))
        innerGlow.draw(
            resolvedText(size: fontSize)
                .foregroundStyle(Color.white.opacity(0.22)),
            at: CGPoint(x: cx, y: cy),
            anchor: .center
        )

        // Pass 2.5a — emboss shadow. Offset down-right, dark.
        // Simulates the shadow cast inside an engraved letterform.
        // x: +0.8, y: +0.9 — sub-pixel offset so the shadow reads as
        // depth without visibly displacing the letterform.
        // 0.55 — dark enough to read as shadow, not a duplicate glyph.
        var shadowPass = context
        shadowPass.addFilter(.blur(radius: 0.8))
        shadowPass.drawLayer { layerContext in
            layerContext.draw(
                resolvedText(size: fontSize)
                    .foregroundStyle(Color.black.opacity(0.55)),
                at: CGPoint(x: cx + 0.8, y: cy + 0.9),
                anchor: .center
            )
        }

        // Pass 2.5b — emboss highlight. Offset up-left, bright white.
        // Simulates the overhead light catching the top edge of the engraving.
        // x: -0.7, y: -0.8 — mirrors the shadow offset direction.
        // 0.45 — bright enough to read as specular, not a ghost glyph.
        var highlightPass = context
        highlightPass.addFilter(.blur(radius: 0.6))
        highlightPass.drawLayer { layerContext in
            layerContext.draw(
                resolvedText(size: fontSize)
                    .foregroundStyle(Color.white.opacity(0.45)),
                at: CGPoint(x: cx - 0.7, y: cy - 0.8),
                anchor: .center
            )
        }

        // Pass 3 — sharp core via clipToLayer gradient mask.
        // 0.90 — near-opaque core so letterforms read as solid emissive objects.
        // clipToLayer is the only reliable way to get a multi-stop gradient on Canvas text.
        var coreContext = context
        coreContext.clipToLayer(opacity: 0.90) { clip in
            clip.draw(
                resolvedText(size: fontSize)
                    .foregroundStyle(Color.white),
                at: CGPoint(x: cx, y: cy),
                anchor: .center
            )
        }
        coreContext.fill(
            Path(textBounds),
            with: .linearGradient(
                spectrumGradient,
                startPoint: CGPoint(x: textBounds.minX, y: cy),
                endPoint:   CGPoint(x: textBounds.maxX, y: cy)
            )
        )
    }
}

// MARK: — Layer 4: Hex Moiré Grid

private extension VaylCardBack {

    /// Draws one hex grid layer rotated by `degrees` around the card center.
    /// Two calls with opposing rotation produce the moiré interference pattern.
    func drawHexLayer(
        context:  GraphicsContext,
        W:        CGFloat,
        H:        CGFloat,
        degrees:  CGFloat,
        color:    Color,
        opacity:  CGFloat,
        hexSize:  CGFloat = 15
    ) {
        // Hex grid origin offsets — match the SVG ox=-40 oy=-60 values.
        // These ensure the grid tiles beyond the card boundary in all directions
        // so the rotation never exposes bare corners.
        let ox: CGFloat = -40
        let oy: CGFloat = -60

        // Column and row counts extend well beyond the card boundary to survive rotation.
        let colRange = -5 ..< 26
        let rowRange = -5 ..< 32

        var gridPath = Path()

        for c in colRange {
            for r in rowRange {
                let x = CGFloat(c) * hexSize * 1.732 + ox
                let y = CGFloat(r) * hexSize * 2 + (c % 2 == 0 ? 0 : hexSize) + oy

                // Four edges of the hex that are visible facing upward/sideways.
                // The full hex has 6 edges — we draw only 4 to avoid double-drawing
                // shared edges which would double the stroke weight at intersections.
                let pts: [CGPoint] = [
                    CGPoint(x: x,                  y: y + hexSize),
                    CGPoint(x: x + hexSize * 0.866, y: y + hexSize * 0.5),
                    CGPoint(x: x + hexSize * 0.866, y: y - hexSize * 0.5),
                    CGPoint(x: x,                  y: y - hexSize),
                ]

                for i in 0 ..< pts.count - 1 {
                    gridPath.move(to: pts[i])
                    gridPath.addLine(to: pts[i + 1])
                }
            }
        }

        // Rotate the entire grid around the card center.
        let cx = W / 2
        let cy = H / 2
        let radians = degrees * .pi / 180

        var transform = CGAffineTransform(translationX: cx, y: cy)
        transform = transform.rotated(by: radians)
        transform = transform.translatedBy(x: -cx, y: -cy)

        var rotatedPath = Path()
        rotatedPath.addPath(gridPath, transform: transform)

        // 0.3px blur — matches SVG filter: blur(0.3px).
        // Softens the aliasing on fine diagonal strokes without blurring
        // the moiré pattern into noise. Rendering constant, not a token.
        var blurredContext = context
        blurredContext.addFilter(.blur(radius: 0.3))
        blurredContext.stroke(
            rotatedPath,
            with: .color(color.opacity(opacity)),
            lineWidth: 0.5
        )
    }

    func drawHexGrid(context: GraphicsContext, size: CGSize, W: CGFloat, H: CGFloat) {
        let isHorizontal = W > H
        // Rotation angle reduces from ±8° to ±6° in landscape — the shallower
        // angle reads better across the wider field. Matches SVG isHoriz logic.
        let angle: CGFloat = isHorizontal ? 6 : 8

        // Cyan grid — positive rotation.
        // 0.20 — hex grid opacity. Low enough to read as texture, not structure.
        drawHexLayer(
            context: context,
            W: W, H: H,
            degrees:  angle,
            color:    AppColors.spectrumCyan,
            opacity:  0.20
        )

        // Magenta grid — negative rotation creates the moiré interference.
        // 0.18 — slightly lower than cyan so the cyan channel leads chromatically.
        drawHexLayer(
            context: context,
            W: W, H: H,
            degrees: -angle,
            color:   AppColors.spectrumMagenta,
            opacity: 0.18
        )
    }
}

// MARK: — Layer 5: Inset Spectrum Frame

private extension VaylCardBack {

    func drawInsetFrame(
        context: GraphicsContext,
        size:    CGSize,
        W:       CGFloat,
        H:       CGFloat,
        R:       CGFloat
    ) {
        // 9pt inset — matches SVG x="9" y="9". Keeps the inner frame
        // visually distinct from the outer hairline without crowding the wordmark.
        let inset: CGFloat = 9
        let innerRect = CGRect(
            x:      inset,
            y:      inset,
            width:  W - inset * 2,
            height: H - inset * 2
        )
        let innerR = R - 4

        let framePath = Path(roundedRect: innerRect, cornerRadius: innerR)

        // 0.27 — inset frame opacity. Secondary presence behind the outer hairline.
        // The inset frame gives the card depth without competing with the hairline.
        context.stroke(
            framePath,
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: AppColors.spectrumCyan.opacity(0.27),    location: 0.00),
                    .init(color: AppColors.spectrumPurple.opacity(0.27),  location: 0.50),
                    .init(color: AppColors.spectrumMagenta.opacity(0.27), location: 1.00),
                ]),
                startPoint: CGPoint(x: innerRect.minX, y: innerRect.midY),
                endPoint:   CGPoint(x: innerRect.maxX, y: innerRect.midY)
            ),
            lineWidth: 0.6
        )
    }
}

#Preview("Vertical") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VaylCardBack()
            .frame(
                width:  AppLayout.obCardWidth(in: 390),
                height: AppLayout.obCardHeight(in: 390)
            )
    }
    .preferredColorScheme(.dark)
}

#Preview("Horizontal") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VaylCardBack()
            .frame(
                width:  AppLayout.sessionCardWidth(in: 390),
                height: AppLayout.sessionCardHeight(in: 390)
            )
    }
    .preferredColorScheme(.dark)
}
