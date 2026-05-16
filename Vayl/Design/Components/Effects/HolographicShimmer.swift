// Shared/Components/Effects/HolographicShimmer.swift

import SwiftUI

// MARK: - Orb Model

private struct ShimmerOrb {
    let color:         Color
    let alpha:         Double
    let anchorX:       Double
    let anchorY:       Double
    let driftX:        Double
    let driftY:        Double
    let widthMultiple: Double
    let freqX:         Double
    let freqY:         Double
    let phaseX:        Double
    let phaseY:        Double
    let blurRadius:    CGFloat

    func position(in size: CGSize, t: Double) -> CGPoint {
        let travelX = size.width  * driftX
        let travelY = size.height * driftY
        let x = size.width  * anchorX + sin(t * freqX + phaseX) * travelX
        let y = size.height * anchorY + cos(t * freqY + phaseY) * travelY
        return CGPoint(x: x, y: y)
    }

    func orbSize(in size: CGSize) -> CGSize {
        let w = size.width * widthMultiple
        let h = size.width * (widthMultiple * 2.2)
        return CGSize(width: w, height: h)
    }
}

// MARK: - Orb Data

private let shimmerOrbs: [ShimmerOrb] = [
    ShimmerOrb(
        color: Color(.sRGB, red:   0/255, green: 160/255, blue: 220/255),
        alpha: 0.15,
        anchorX: 0.38, anchorY: 0.48,
        driftX: 0.46, driftY: 0.52,
        widthMultiple: 0.60,
        freqX: 0.38, freqY: 0.30,
        phaseX: 0.0, phaseY: 0.0,
        blurRadius: 30
    ),
    ShimmerOrb(
        color: Color(.sRGB, red:  90/255, green:  60/255, blue: 180/255),
        alpha: 0.18,
        anchorX: 0.62, anchorY: 0.52,
        driftX: 0.46, driftY: 0.52,
        widthMultiple: 0.55,
        freqX: 0.51, freqY: 0.41,
        phaseX: 2.0, phaseY: 2.5,
        blurRadius: 28
    ),
    ShimmerOrb(
        color: Color(.sRGB, red:  40/255, green:  80/255, blue: 200/255),
        alpha: 0.12,
        anchorX: 0.30, anchorY: 0.38,
        driftX: 0.46, driftY: 0.52,
        widthMultiple: 0.50,
        freqX: 0.63, freqY: 0.50,
        phaseX: 3.9, phaseY: 1.2,
        blurRadius: 26
    ),
    ShimmerOrb(
        color: Color(.sRGB, red: 180/255, green:   0/255, blue:  90/255),
        alpha: 0.10,
        anchorX: 0.68, anchorY: 0.62,
        driftX: 0.46, driftY: 0.52,
        widthMultiple: 0.65,
        freqX: 0.27, freqY: 0.21,
        phaseX: 5.0, phaseY: 0.7,
        blurRadius: 34
    ),
    ShimmerOrb(
        color: Color(.sRGB, red: 100/255, green:  20/255, blue: 200/255),
        alpha: 0.12,
        anchorX: 0.55, anchorY: 0.45,
        driftX: 0.46, driftY: 0.52,
        widthMultiple: 0.42,
        freqX: 0.74, freqY: 0.60,
        phaseX: 1.9, phaseY: 4.1,
        blurRadius: 24
    ),
]

// MARK: - Sweep Math

private func fract(_ x: Double) -> Double { x - floor(x) }

private func hash1D(_ i: Double) -> Double {
    fract(sin(i * 127.1) * 43758.5453)
}

private func valueNoise1D(_ t: Double) -> Double {
    let i = floor(t)
    let f = t - i
    let u = f * f * (3 - 2 * f)
    return hash1D(i) + (hash1D(i + 1) - hash1D(i)) * u
}

// MARK: - Grain Canvas

private struct GrainCanvas: View {
    let tileWidth:  CGFloat
    let tileHeight: CGFloat
    let frequency:  Float
    let octaves:    Int
    let xStretch:   Float

    var body: some View {
        Canvas { ctx, size in
            let tileW = Int(tileWidth)
            let tileH = Int(tileHeight)
            guard tileW > 0, tileH > 0 else { return }

            var pixels = [UInt8](repeating: 0, count: tileW * tileH * 4)
            for y in 0 ..< tileH {
                for x in 0 ..< tileW {
                    let n = fbmNoise(
                        x: Float(x) / Float(tileW) * frequency,
                        y: Float(y) / Float(tileH) * (frequency / xStretch),
                        octaves: octaves
                    )
                    let v = UInt8(((n * 0.5 + 0.5) * 255).clamped(to: 0...255))
                    let i = (y * tileW + x) * 4
                    pixels[i]     = v
                    pixels[i + 1] = v
                    pixels[i + 2] = v
                    pixels[i + 3] = 255
                }
            }

            let cfData   = CFDataCreate(nil, pixels, pixels.count)!
            let provider = CGDataProvider(data: cfData)!
            let cgImage  = CGImage(
                width: tileW, height: tileH,
                bitsPerComponent: 8, bitsPerPixel: 32,
                bytesPerRow: tileW * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil, shouldInterpolate: false,
                intent: .defaultIntent
            )!

            let tile = Image(cgImage, scale: 1, label: Text(""))
            var xOff: CGFloat = 0
            while xOff < size.width {
                var yOff: CGFloat = 0
                while yOff < size.height {
                    ctx.draw(tile, at: CGPoint(x: xOff, y: yOff), anchor: .topLeading)
                    yOff += tileHeight
                }
                xOff += tileWidth
            }
        }
    }

    private func fbmNoise(x: Float, y: Float, octaves: Int) -> Float {
        var val:  Float = 0
        var amp:  Float = 0.5
        var freq: Float = 1.0
        for _ in 0 ..< octaves {
            val  += amp * smoothNoise(SIMD2<Float>(x, y) * freq)
            amp  *= 0.5
            freq *= 2.0
        }
        return val
    }

    private func hash(_ p: SIMD2<Float>) -> SIMD2<Float> {
        var q = SIMD2<Float>(p.x * 127.1 + p.y * 311.7, p.x * 269.5 + p.y * 183.3)
        q = SIMD2<Float>(sin(q.x) * 43758.5453, sin(q.y) * 43758.5453)
        return SIMD2<Float>(q.x - floor(q.x), q.y - floor(q.y)) * 2 - 1
    }

    private func smoothNoise(_ p: SIMD2<Float>) -> Float {
        let i = SIMD2<Float>(floor(p.x), floor(p.y))
        let f = p - i
        let u = f * f * (3 - 2 * f)
        let a = dot(hash(i + SIMD2(0, 0)), f - SIMD2(0, 0))
        let b = dot(hash(i + SIMD2(1, 0)), f - SIMD2(1, 0))
        let c = dot(hash(i + SIMD2(0, 1)), f - SIMD2(0, 1))
        let d = dot(hash(i + SIMD2(1, 1)), f - SIMD2(1, 1))
        return mix(mix(a, b, t: u.x), mix(c, d, t: u.x), t: u.y)
    }

    private func mix(_ a: Float, _ b: Float, t: Float) -> Float { a + (b - a) * t }
    private func dot(_ a: SIMD2<Float>, _ b: SIMD2<Float>) -> Float { a.x * b.x + a.y * b.y }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - HolographicShimmer

struct HolographicShimmer: View {
    var duration: Double = 6

    private let noiseSpeed: Double = 0.09

    @State private var phaseOffset: Double = Double.random(in: 0...100)

    var body: some View {
        // Rectangle is the layout root — it accepts whatever frame
        // the parent proposes and fills it exactly.
        // The GeometryReader lives inside .overlay so it reads the
        // settled frame and renders on top of the base fill.
        // Never competes with VaylButton's outer GeometryReader.
        Rectangle()
            .fill(Color(.sRGB, red: 32/255, green: 28/255, blue: 52/255))
            .overlay(
                GeometryReader { geo in
                    let size = geo.size

                    TimelineView(.animation) { tl in
                        let t = tl.date.timeIntervalSinceReferenceDate
                        let noisePosition = valueNoise1D(t * noiseSpeed + phaseOffset)
                        let sweepOffset = (noisePosition * 2 - 1.5) * size.width

                        ZStack {
                            // Layer 0: Base — opaque foundation for the ZStack.
                            Color(.sRGB, red: 32/255, green: 28/255, blue: 52/255)

                            // Layer 1: Specular sweep
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        stops: [
                                            .init(color: Color(.sRGB, red: 255/255, green: 226/255, blue: 125/255).opacity(0.00), location: 0.00),
                                            .init(color: Color(.sRGB, red: 255/255, green: 226/255, blue: 125/255).opacity(0.07), location: 0.30),
                                            .init(color: Color(.sRGB, red: 255/255, green: 226/255, blue: 125/255).opacity(0.22), location: 0.39),
                                            .init(color: Color(.sRGB, red: 100/255, green: 227/255, blue: 255/255).opacity(0.18), location: 0.44),
                                            .init(color: Color(.sRGB, red: 145/255, green: 146/255, blue: 255/255).opacity(0.11), location: 0.50),
                                            .init(color: Color(.sRGB, red: 145/255, green: 146/255, blue: 255/255).opacity(0.03), location: 0.58),
                                            .init(color: Color(.sRGB, red: 145/255, green: 146/255, blue: 255/255).opacity(0.00), location: 1.00),
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: size.width * 2, height: size.height)
                                .offset(x: sweepOffset)

                            // Layer 2: Orbs
                            ZStack {
                                ForEach(shimmerOrbs.indices, id: \.self) { i in
                                    let orb = shimmerOrbs[i]
                                    let pos = orb.position(in: size, t: t)
                                    let sz  = orb.orbSize(in: size)

                                    Ellipse()
                                        .fill(orb.color.opacity(orb.alpha))
                                        .frame(width: sz.width, height: sz.height)
                                        .blur(radius: orb.blurRadius)
                                        .position(pos)
                                        .blendMode(.screen)
                                }
                            }
                            .drawingGroup()

                            // Layer 3: Dim overlay
                            Color(.sRGB, red: 13/255, green: 11/255, blue: 26/255)
                                .opacity(0.10)

                            // Layer 4: Vignette — fitted to frame so the ellipse
                            // tracks the capsule boundary rather than bleeding past it.
                            EllipticalGradient(
                                stops: [
                                    .init(color: .clear,               location: 0.50),
                                    .init(color: .black.opacity(0.30), location: 1.0),
                                ],
                                center: .center
                            )

                            // Layer 5: Coarse grain
                            GrainCanvas(
                                tileWidth: 180, tileHeight: 60,
                                frequency: 0.85 * 180,
                                octaves: 5,
                                xStretch: 5.0
                            )
                            .blendMode(.screen)
                            .opacity(0.08)

                            // Layer 6: Fine grain
                            GrainCanvas(
                                tileWidth: 120, tileHeight: 40,
                                frequency: 1.2 * 120,
                                octaves: 3,
                                xStretch: 3.5
                            )
                            .blendMode(.softLight)
                            .opacity(0.096)
                        }
                        .frame(width: size.width, height: size.height)
                    }
                }
            )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(red: 8/255, green: 6/255, blue: 18/255).ignoresSafeArea()

        VStack(spacing: 20) {
            ForEach([340, 280, 200] as [CGFloat], id: \.self) { width in
                Capsule()
                    .fill(Color(.sRGB, red: 13/255, green: 11/255, blue: 26/255))
                    .overlay {
                        HolographicShimmer().clipShape(Capsule())
                    }
                    .frame(width: width, height: 56)
            }
        }
    }
    .preferredColorScheme(.dark)
}
