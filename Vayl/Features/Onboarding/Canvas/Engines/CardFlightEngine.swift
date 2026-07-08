import SwiftUI
import SpriteKit
import OSLog

private let logger = Logger(
    subsystem: "com.vayl.app",
    category: "CardFlightEngine"
)

@MainActor
final class CardFlightEngine {
    weak var director: VaylDirector?

    // Slot pool — tracks which landing zones are still available this round.
    // Starts full; shrinks as cards are dealt; auto-resets when exhausted.
    private var availableSlotIDs: [Int] = AppLayout.obCardLandingSlots.map(\.id)

    init(director: VaylDirector) {
        self.director = director
    }

    /// Picks a random unused slot from the pool, removes it so the next call gets
    /// a different zone, and returns a resolved position + angle for `screenSize`.
    /// When all slots are exhausted the pool resets automatically, so a long flow
    /// that deals more than 5 cards simply cycles through all zones again.
    func claimLandingSlot(screenSize: CGSize) -> CardLandingSlot.Resolved {
        if availableSlotIDs.isEmpty {
            availableSlotIDs = AppLayout.obCardLandingSlots.map(\.id)
        }
        let pickIndex  = availableSlotIDs.indices.randomElement()!
        let slotID     = availableSlotIDs.remove(at: pickIndex)
        let slot       = AppLayout.obCardLandingSlots.first(where: { $0.id == slotID })!
        return slot.resolve(in: screenSize)
    }

    /// Resets the slot pool so the next deal sequence starts fresh.
    /// Call this when entering a new OB phase that deals cards.
    func resetSlotPool() {
        availableSlotIDs = AppLayout.obCardLandingSlots.map(\.id)
    }

    /// Flies a single card via SpriteKit and returns its rested position and rotation.
    func sailCard(
        cardID: String,
        image: UIImage,
        from: CGPoint,
        to: CGPoint,
        sceneSize: CGSize,
        duration: TimeInterval = 0.92,
        initialAngle: CGFloat      = -0.24,
        finalAngle: CGFloat      = 0.0314,
        zPosition: CGFloat      = 0
    ) async -> (CGPoint, CGFloat) {
        guard let director = director else { return (to, finalAngle) }

        if director.cardFlightScene.size == .zero || director.cardFlightScene.size != sceneSize {
            director.cardFlightScene.size = sceneSize
        }

        let skOrigin = CGPoint(x: from.x, y: sceneSize.height - from.y)
        let skDest   = CGPoint(x: to.x, y: sceneSize.height - to.y)

        return await withCheckedContinuation { continuation in
            director.cardFlightScene.onCardRested[cardID] = { [weak director] _, pos, rot in
                guard let _ = director else { return }
                let swiftUIPos = CGPoint(x: pos.x, y: sceneSize.height - pos.y)
                continuation.resume(returning: (swiftUIPos, -rot * (180 / .pi)))
            }
            director.cardFlightScene.dealCard(
                id: cardID,
                image: image,
                from: skOrigin,
                to: skDest,
                initialAngle: initialAngle,
                finalAngle: finalAngle,
                zPosition: zPosition,
                duration: duration
            )
        }
    }

    /// Deals a single card to a natural landing slot via CardFlightScene.
    /// `scale` is the caller's display scale for the card-back snapshot (passed in so
    /// this stays free of UIApplication globals and is the single owner of deal physics).
    func dealSingleCard(
        screenSize: CGSize,
        scale: CGFloat
    ) async -> (offset: CGSize, angle: Double, flightID: String)? {
        guard let director = director else { return nil }

        let cardW = AppLayout.obTableCardWidth(in: screenSize.width)  * AppLayout.obTableCardCinematicScale
        let cardH = AppLayout.obTableCardHeight(in: screenSize.width) * AppLayout.obTableCardCinematicScale

        // Yield before rasterizing so any in-flight SwiftUI animation frames
        // are committed first — a cache MISS in CardBackRaster is a synchronous
        // main-thread rasterize (hits return instantly).
        await Task.yield()
        guard let cardImage = CardBackRaster.image(width: cardW, height: cardH, scale: scale) else {
            logger.error("dealSingleCard: VaylCardBack snapshot failed")
            return nil
        }

        let flightID      = UUID().uuidString
        let startAngleDeg = Double.random(in: 11.0...16.0)
        let launchX       = screenSize.width * CGFloat.random(in: -0.45...1.45)

        let origin = CGPoint(
            x: launchX,
            y: screenSize.height * AppLayout.tableHorizonYFrac
        )

        let minTravelDistance = screenSize.width * 0.75
        var slot = claimLandingSlot(screenSize: screenSize)
        for _ in 0..<4 {
            let dist = hypot(slot.position.x - origin.x,
                             slot.position.y - origin.y)
            if dist >= minTravelDistance { break }
            slot = claimLandingSlot(screenSize: screenSize)
        }

        let overshootDist   = slot.position.x + (slot.position.x - origin.x) * 0.22
        let cardThird       = cardW / 3
        let wouldClearLeft  = overshootDist < -cardThird
        let wouldClearRight = overshootDist > screenSize.width + cardThird
        let canOvershoot    = wouldClearLeft || wouldClearRight
        director.cardFlightScene.pendingShouldOvershoot = canOvershoot && Double.random(in: 0...1) < 0.60

        let skInitialAngle = CGFloat(-startAngleDeg * .pi / 180)
        let skFinalAngle   = CGFloat(-slot.angleDeg  * .pi / 180)

        let (restPos, restRot) = await sailCard(
            cardID: flightID,
            image: cardImage,
            from: origin,
            to: slot.position,
            sceneSize: screenSize,
            duration: 0.45,
            initialAngle: skInitialAngle,
            finalAngle: skFinalAngle
        )

        let offset = CGSize(
            width: restPos.x - screenSize.width  / 2,
            height: restPos.y - screenSize.height / 2
        )
        return (offset, Double(restRot), flightID)
    }

    // Multi-card deal (dealCards), single-card slide (dealCard), and the corner-deck
    // pocket helper were removed in the C2 cleanup — they had no callers. The live
    // single-card dealer is dealSingleCard above; ThreeCardFanController / CardMirrorDeal
    // own the fan/mirror deals via their own scenes.
}
