//
//  CompanionCardStore.swift
//  Vayl
//
//  Resolves a tier-appropriate conversation prompt for a desire item.
//  Owned by VaultStore. Calls ContentLoader (service layer) for content.
//

import Foundation

@Observable
@MainActor
final class CompanionCardStore {

    private var pools: [CompanionCardPool] = []

    init() {
        pools = (try? ContentLoader.loadCompanionCards()) ?? []
    }

    /// Returns a CompanionCard for a mutual or adjacent match.
    /// Prompt selection is stable: same itemId always returns the same prompt from the tier pool.
    func card(forItemId itemId: String, tier: CompanionCardTier) -> CompanionCard? {
        guard let pool = pools.first(where: { $0.tier == tier }),
              !pool.prompts.isEmpty else { return nil }
        let idx = stableIndex(for: itemId, count: pool.prompts.count)
        let prompt = pool.prompts[idx]
        return CompanionCard(
            id: "discussion_\(tier.rawValue)_\(itemId)",
            desireItemId: itemId,
            title: "Talk about this",
            prompt: prompt.text,
            suggestedDeckId: nil
        )
    }

    // MARK: - Private

    /// Deterministic index derived from the itemId string -- stable across process restarts.
    /// Uses Unicode scalar sum (not hashValue, which is randomized in Swift).
    private func stableIndex(for itemId: String, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let sum = itemId.unicodeScalars.reduce(0 as UInt) { $0 &+ UInt($1.value) }
        return Int(sum % UInt(count))
    }
}
