import XCTest
@testable import Vayl

// Reconciled for the ContextPhase reason-based redesign (2026-06-20):
//   • 4 sets: solo/couple × {curious, in-it}; exploring + experienced share the "in it" set.
//   • Reason-based RelationshipContext (15 cases); `single` shared across both solo sets.
//   • No "undecided" escape card — the low-commitment options ("here to learn", "checking
//     it out") cover that, and solo sets are single-anchored (last).
// Source of truth: AppEnums.swift (enums) + ContextOption.swift (options + derivedRegister).
final class ContextOptionTests: XCTestCase {

    private let modes: [AppMode] = [.together, .solo]

    // Exploring + experienced resolve to the SAME "in it" set per mode.
    func test_exploringAndExperiencedShareTheInItSet() {
        for mode in modes {
            let exploring   = ContextOption.options(appMode: mode, stage: .exploring).map(\.id)
            let experienced = ContextOption.options(appMode: mode, stage: .experienced).map(\.id)
            XCTAssertEqual(exploring, experienced,
                           "\(mode): exploring + experienced should be the same 'in it' set")
        }
    }

    // Every cell holds four real options (no forced undecided padding).
    func test_cellCounts() {
        for mode in modes {
            for stage in NMStage.allCases {
                XCTAssertEqual(
                    ContextOption.options(appMode: mode, stage: stage).count, 4,
                    "\(mode)/\(stage) should hold 4 options"
                )
            }
        }
    }

    // Solo sets are single-anchored: the last card is "I'm single" (context .single).
    func test_soloSetsEndWithSingle() {
        for stage in NMStage.allCases {
            let last = ContextOption.options(appMode: .solo, stage: stage).last
            XCTAssertEqual(last?.context, .single, "solo/\(stage) should end with the single card")
        }
    }

    // Couple sets never contain the single card.
    func test_coupleSetsHaveNoSingle() {
        for stage in NMStage.allCases {
            let contexts = ContextOption.options(appMode: .together, stage: stage).map(\.context)
            XCTAssertFalse(contexts.contains(.single), "couple/\(stage) should not offer the single card")
        }
    }

    func test_derivedRegister_anxiousContexts() {
        let anxious: [RelationshipContext] = [
            .soloUndisclosed, .coupleNervous, .coupleInitiator, .coupleRecalibrating
        ]
        for ctx in anxious {
            XCTAssertEqual(register(for: ctx), .anxious, "\(ctx) should be anxious")
        }
    }

    func test_derivedRegister_excitedContexts() {
        let excited: [RelationshipContext] = [
            .single, .soloIntentional, .coupleExcited, .coupleGoDeeper
        ]
        for ctx in excited {
            XCTAssertEqual(register(for: ctx), .excited, "\(ctx) should be excited")
        }
    }

    func test_derivedRegister_flexibleContexts() {
        let flexible: [RelationshipContext] = [
            .soloLearning, .soloSeekingClarity, .soloExpandKnowledge, .soloCheckingOut,
            .coupleFiguringOut, .coupleGetBetter, .coupleKeepItFun
        ]
        for ctx in flexible {
            XCTAssertEqual(register(for: ctx), .flexible, "\(ctx) should be flexible")
        }
    }

    // Every defined RelationshipContext is reachable through some cell (no orphans).
    // `single` is intentionally shared across both solo cells, so this is "at least once."
    func test_everyContextReachable() {
        var seen: Set<RelationshipContext> = []
        for mode in modes {
            for stage in NMStage.allCases {
                seen.formUnion(ContextOption.options(appMode: mode, stage: stage).map(\.context))
            }
        }
        XCTAssertEqual(seen, Set(RelationshipContext.allCases),
                       "every RelationshipContext should be reachable through some cell")
    }

    private func register(for ctx: RelationshipContext) -> SituationalRegister? {
        for mode in modes {
            for stage in NMStage.allCases {
                if let opt = ContextOption.options(appMode: mode, stage: stage)
                    .first(where: { $0.context == ctx }) {
                    return opt.derivedRegister
                }
            }
        }
        return nil
    }
}
