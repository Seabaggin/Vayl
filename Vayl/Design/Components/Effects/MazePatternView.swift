//
//  MazePatternView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/30/26.
//


//
//  MazePatternView.swift
//  Open Lightly
//

import SwiftUI

struct MazePatternView: View {

    var color:         Color
    var opacity:       Double = 0.28
    var glowColor:     Color  = .clear
    var glowOpacity:   Double = 0.0
    var orbitCount:    Int    = 3
    var isOrbitActive: Bool   = true

    private struct Ring {
        let radiusFraction: CGFloat
        let gaps: [(Double, Double)]
    }

    private let rings: [Ring] = [
        Ring(
            radiusFraction: 0.42,
            gaps: [(10, 40), (100, 125), (200, 225), (290, 320)]
        ),
        Ring(
            radiusFraction: 0.30,
            gaps: [(30, 60), (150, 180), (250, 275)]
        ),
        Ring(
            radiusFraction: 0.19,
            gaps: [(60, 90), (180, 210)]
        ),
    ]

    private struct Spoke {
        let angleDeg:  Double
        let innerFrac: CGFloat
        let outerFrac: CGFloat
    }

    private let spokes: [Spoke] = [
        Spoke(angleDeg:  15, innerFrac: 0.19, outerFrac: 0.30),
        Spoke(angleDeg:  75, innerFrac: 0.30, outerFrac: 0.42),
        Spoke(angleDeg: 135, innerFrac: 0.19, outerFrac: 0.30),
        Spoke(angleDeg: 195, innerFrac: 0.30, outerFrac: 0.42),
        Spoke(angleDeg: 255, innerFrac: 0.19, outerFrac: 0.30),
        Spoke(angleDeg: 315, innerFrac: 0.19, outerFrac: 0.42),
    ]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let cx = size / 2
            let cy = size / 2
            ZStack {
                // AFTER
                // Layer 0 — glow bloom (light mode only)
                              if glowOpacity > 0 {
                                  mazePath(size: size, radiusOffset: 0, lineWidth: 3.0)
                                      .stroke(glowColor, lineWidth: 3.0)
                                      .opacity(glowOpacity * 0.55)
                                      .blur(radius: 2.5)
                              }

                              // Layer 1 — groove shadow
                              mazePath(size: size, radiusOffset: 0.5, lineWidth: 2.8)
                                  .stroke(color, lineWidth: 2.8)
                                  .opacity(opacity * 0.22)

                              // Layer 2 — main engraved line
                              mazePath(size: size, radiusOffset: 0, lineWidth: 1.8)
                                  .stroke(color, lineWidth: 1.8)
                                  .opacity(opacity)
                                  .drawingGroup()

                              // Layer 3 — highlight edge
                              mazePath(size: size, radiusOffset: -0.5, lineWidth: 0.8)
                                  .stroke(Color.white, lineWidth: 0.8)
                                  .opacity(opacity * 0.45)

                // Orbit — rendered here so it shares the GeometryReader's
                // coordinate space. cx/cy are the exact same values used
                // by the maze rings — guaranteed to be co-centered.
                TileOrbitView(
                    orbitCount: orbitCount,
                    isActive:   isOrbitActive,
                    size:       120,
                    glowScale:  0.45   // tight context — glow matches maze line weight
                )
                .frame(width: 120, height: 120)
                .position(x: cx, y: cy)
            }
        }
    }

    private func mazePath(
        size:         CGFloat,
        radiusOffset: CGFloat,
        lineWidth:    CGFloat
    ) -> Path {
        var path = Path()
        let cx = size / 2
        let cy = size / 2

        for ring in rings {
            let r = size * ring.radiusFraction + radiusOffset
            var current: Double = 0
            for (gStart, gEnd) in ring.gaps {
                if current < gStart {
                    path.addArc(
                        center:     CGPoint(x: cx, y: cy),
                        radius:     r,
                        startAngle: .degrees(current),
                        endAngle:   .degrees(gStart),
                        clockwise:  false
                    )
                    let nextX = cx + r * CGFloat(cos(gEnd * .pi / 180))
                    let nextY = cy + r * CGFloat(sin(gEnd * .pi / 180))
                    path.move(to: CGPoint(x: nextX, y: nextY))
                }
                current = gEnd
            }
            if current < 360 {
                path.addArc(
                    center:     CGPoint(x: cx, y: cy),
                    radius:     r,
                    startAngle: .degrees(current),
                    endAngle:   .degrees(360),
                    clockwise:  false
                )
            }
        }

        for spoke in spokes {
            let rad   = spoke.angleDeg * .pi / 180
            let nudge = CGFloat(radiusOffset == 0 ? 0 : (radiusOffset > 0 ? 0.4 : -0.3))
            let x1 = cx + size * spoke.innerFrac * CGFloat(cos(rad)) + nudge
            let y1 = cy + size * spoke.innerFrac * CGFloat(sin(rad)) + nudge
            let x2 = cx + size * spoke.outerFrac * CGFloat(cos(rad)) + nudge
            let y2 = cy + size * spoke.outerFrac * CGFloat(sin(rad)) + nudge
            path.move(to:    CGPoint(x: x1, y: y1))
            path.addLine(to: CGPoint(x: x2, y: y2))
        }

        return path
    }
}

#Preview("Dark") {
    ZStack {
        Color(red: 0.051, green: 0.043, blue: 0.122).ignoresSafeArea()
        MazePatternView(
            color:       AppColors.accentTertiary,
            opacity:     0.28,
            glowColor:   .clear,
            glowOpacity: 0.0
        )
        .frame(width: 280, height: 280)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        MazePatternView(
            color:       AppColors.progressBarLeading,
            opacity:     0.32,
            glowColor:   AppColors.progressBarLeading,
            glowOpacity: 0.18
        )
        .frame(width: 280, height: 280)
    }
    .preferredColorScheme(.light)
}
