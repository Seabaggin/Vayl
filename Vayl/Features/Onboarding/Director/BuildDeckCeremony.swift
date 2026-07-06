//
//  BuildDeckCeremony.swift
//  Vayl
//
//  Manages the foil tear composition and shatter logic for BuildDeckPhase.
//

import SwiftUI

@Observable
@MainActor
final class BuildDeckCeremony {
    
    var foilIntegrity: Double = 1.0
    var foilTears: [FoilTear] = []
    
    private var strikeSequenceIndex: Int = 0
    private var strikeMirrored: Bool = false
    
    private static let strikeSequences: [[(zone: CGPoint, angleDeg: Double)]] = [
        [(CGPoint(x: 0.28, y: 0.233),  10),
         (CGPoint(x: 0.74, y: 0.480), 125),
         (CGPoint(x: 0.45, y: 0.747),  85)],
         
        [(CGPoint(x: 0.25, y: 0.230), 45),
         (CGPoint(x: 0.75, y: 0.770), 45),
         (CGPoint(x: 0.50, y: 0.500), 45)],
         
        [(CGPoint(x: 0.70, y: 0.787), 175),
         (CGPoint(x: 0.26, y: 0.467),  80),
         (CGPoint(x: 0.52, y: 0.200),  35)],
    ]
    
    func runEntry() {
        foilIntegrity = 1.0
        foilTears = []
        
        // Locked to "The Pincer"
        strikeSequenceIndex = 1
        strikeMirrored = false
    }
    
    func addFoilTear(atFaceUV uv: CGPoint) {
        guard foilIntegrity > 0.5, foilTears.count < 3 else { return }
        
        let spec = Self.strikeSequences[strikeSequenceIndex][foilTears.count]
        var zone = spec.zone
        var angle = spec.angleDeg
        
        if strikeMirrored {
            zone.x = 1 - zone.x
            angle = 180 - angle
        }
        
        let pulled = CGPoint(x: uv.x + (zone.x - uv.x) * 0.75,
                             y: uv.y + (zone.y - uv.y) * 0.75)
        let dx = pulled.x - zone.x
        let dy = pulled.y - zone.y
        let offset = (dx * dx + dy * dy).squareRoot()
        let maxOffset: CGFloat = 0.10
        let strike = offset <= maxOffset ? pulled
            : CGPoint(x: zone.x + dx / offset * maxOffset,
                      y: zone.y + dy / offset * maxOffset)
                      
        foilTears.append(FoilTear(faceUV: strike, angleDeg: angle))
        
        if foilTears.count >= 3 {
            withAnimation(AppAnimation.foilDissolve.reduceMotionSafe) {
                self.foilIntegrity = 0
            }
        }
    }
}
