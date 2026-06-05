// Features/Onboarding/Canvas/CardFlightScene.swift

import SpriteKit
import UIKit

final class CardFlightScene: SKScene {

    /// Per-card callbacks fired on @MainActor when each card's flight completes.
    /// Keyed by the same id passed to dealCard — allows sailCard and dealCards
    /// to register handlers concurrently without overwriting each other.
    var onCardRested: [String: (String, CGPoint, CGFloat) -> Void] = [:]

    private var cardNodes: [String: SKSpriteNode] = [:]
    private var restedIDs: Set<String>            = []

    /// Set by the caller before invoking dealCard to control overshoot for that deal.
    /// Consumed on use and reset to false automatically — no cleanup needed.
    var pendingShouldOvershoot: Bool = false

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        physicsWorld.gravity = .zero
    }

    /// Flies one card from `origin` to `destination`.
    ///
    /// Easing: `1 − (1 − t)³` — starts fast, decelerates to zero velocity on arrival.
    /// Position and rotation share the same curve so the card moves as one rigid object.
    ///
    /// Multiple concurrent calls are safe — each `id` gets its own SKSpriteNode.
    /// When the node rests, `onCardRested` is called with the id, position, and rotation,
    /// then the node stays until `clearCard(id:)` is called.
    func dealCard(
        id:             String,
        image:          UIImage,
        from origin:    CGPoint,
        to destination: CGPoint,
        initialAngle:   CGFloat      = -0.24,
        finalAngle:     CGFloat      = 0.0314,
        zPosition:      CGFloat      = 0,
        duration:       TimeInterval = 0.55
    ) {
        cardNodes[id]?.removeFromParent()
        restedIDs.remove(id)

        let node = SKSpriteNode(texture: SKTexture(image: image))
        node.position  = origin
        node.zRotation = initialAngle
        node.zPosition = zPosition
        addChild(node)
        cardNodes[id] = node

        let sx = origin.x,      sy = origin.y
        let dx = destination.x - sx, dy = destination.y - sy
        let da = finalAngle - initialAngle

        // Consume the caller's overshoot decision — reset immediately so
        // a subsequent call without a new assignment defaults to false.
        let shouldOvershoot = pendingShouldOvershoot
        pendingShouldOvershoot = false
        let overshootAmount = shouldOvershoot
            ? Double.random(in: 1.12...1.22)  // vary the overshoot distance
            : 1.0                              // no overshoot — clean stop

        node.run(SKAction.customAction(withDuration: duration) { node, elapsed in
            let t = min(Double(elapsed) / duration, 1.0)

            // ── Two-phase motion ─────────────────────────────────────────
            //
            // PHASE 1 — Flight (t < landingT)
            //   Power-2 ease-IN: card accelerates into the surface,
            //   building momentum that friction then spends.
            //
            // PHASE 2 — Slide (t ≥ landingT)
            //   Power-3 ease-out: sharp initial bite of friction, then a
            //   long tail as kinetic energy bleeds off across the table.
            //
            // At landingT = landingFrac = 0.50 the exit velocity of flight
            // and the entry velocity of slide match exactly — seamless
            // physical hand-off. Dial landingFrac 0.45–0.55 to tune how
            // dramatic the impact "skip" feels vs. a clean transition.
            //
            // landingT    — when the card contacts the table (fraction of duration)
            // landingFrac — how far along origin→destination the card lands
            //               (leaves this much distance left to slide)
            // ─────────────────────────────────────────────────────────────

            let landingT    = 0.10   // impact at 10% — card barely has a flight phase
            let landingFrac = 0.30   // card is 30% there at impact; 70% is pure felt slide

            let positionFrac: Double
            if t < landingT {
                // Flight: power-3 ease-in — steeper acceleration reads as a
                // real throw at short durations, not a drift.
                let tN = t / landingT
                positionFrac = (tN * tN * tN) * landingFrac
            } else {
                let tN     = (t - landingT) / (1.0 - landingT)
                let splitT = 0.70

                if shouldOvershoot && tN < splitT {
                    // Fast slide to overshoot position
                    let tA    = tN / splitT
                    let invTA = 1.0 - tA
                    let slideA = 1.0 - (invTA * invTA)
                    positionFrac = landingFrac +
                        (1.0 - landingFrac) * slideA * overshootAmount
                } else if shouldOvershoot && tN >= splitT {
                    // Snap back from overshoot to final position
                    let tB    = (tN - splitT) / (1.0 - splitT)
                    let invTB = 1.0 - tB
                    let snapback = overshootAmount -
                        (overshootAmount - 1.0) * (1.0 - invTB * invTB * invTB)
                    positionFrac = landingFrac +
                        (1.0 - landingFrac) * snapback
                } else {
                    // Clean stop — power-2 ease-out
                    let invTN = 1.0 - tN
                    let slide = 1.0 - (invTN * invTN * invTN * invTN)
                    positionFrac = landingFrac +
                        (1.0 - landingFrac) * slide
                }
            }

            node.position = CGPoint(x: sx + dx * CGFloat(positionFrac),
                                    y: sy + dy * CGFloat(positionFrac))

            // Rotation: power-5 ease-out over the full duration.
            // Settles slightly before position — the card corrects its
            // angle in the air just before sliding to a stop.
            let invT     = 1.0 - t
            let rotSlide = 1.0 - (invT * invT * invT * invT * invT)
            node.zRotation = initialAngle + da * CGFloat(rotSlide)
        }) { [weak self, id] in
            // Snap to exact final values on completion —
            // eliminates any floating point drift from the spring function.
            self?.cardNodes[id]?.position  = destination
            self?.cardNodes[id]?.zRotation = finalAngle

            guard let self, let n = self.cardNodes[id] else { return }
            self.restedIDs.insert(id)
            let pos = n.position, rot = n.zRotation
            DispatchQueue.main.async {
                if let handler = self.onCardRested[id] {
                    self.onCardRested.removeValue(forKey: id)
                    handler(id, pos, rot)
                }
            }
        }
    }

    /// Removes the node for a specific card. Safe to call even if the card never landed.
    func clearCard(id: String) {
        cardNodes[id]?.removeFromParent()
        cardNodes.removeValue(forKey: id)
        restedIDs.remove(id)
    }

    /// Removes all card nodes. Use when resetting the scene between phases.
    func clearAllCards() {
        cardNodes.values.forEach { $0.removeFromParent() }
        cardNodes.removeAll()
        restedIDs.removeAll()
    }
}
