//
//  SparkleStar.swift
//  Vayl
//

import SwiftUI

/// A 4-point pinched star shape used for sparkle overlay animations on desire stars.
/// All geometry is proportional to the bounding rect — no fixed pixel values.
struct SparkleStar: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        func pt(_ fx: CGFloat, _ fy: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + fx * w, y: rect.minY + fy * h)
        }
        var path = Path()
        path.move(to: pt(0.50, 0.00))
        path.addLine(to: pt(0.53, 0.47))
        path.addLine(to: pt(1.00, 0.50))
        path.addLine(to: pt(0.53, 0.53))
        path.addLine(to: pt(0.50, 1.00))
        path.addLine(to: pt(0.47, 0.53))
        path.addLine(to: pt(0.00, 0.50))
        path.addLine(to: pt(0.47, 0.47))
        path.closeSubpath()
        return path
    }
}
