import XCTest
@testable import Vayl

// Reconciled for the ContextPhase 2×3 redesign:
//   • AppMode is now only .together / .solo (.browsing removed)
//   • RelationshipContext expanded to 26 across 6 cells (Curious cells hold 5, others 4)
//   • the anxious register set changed with the couple-curious split
// Source of truth: AppEnums.swift (enums) + ContextOption.swift (options + derivedRegister).
final class ContextOptionTests: XCTestCase {

    private let modes: [AppMode] = [.together, .solo]

    // Each (mode, stage) cell ends with a first-class "undecided" escape card (the .ember one).
    func test_everyCellEndsWithUndecidedCard() {
        for mode in modes {
            for stage in NMStage.allCases {
                let opts = ContextOption.options(appMode: mode, stage: stage)
                XCTAssertTrue(
                    opts.last?.id.hasSuffix("_undecided") ?? false,
                    "\(mode)/\(stage) should end with an undecided card"
                )
                XCTAssertEqual(opts.last?.accent, .ember, "\(mode)/\(stage) undecided card uses .ember")
            }
        }
    }

    // The 2×3 matrix: Curious cells carry an extra concrete situation (5); the rest hold 4.
    func test_cellCounts_matchTheTwoByThreeMatrix() {
        XCTAssertEqual(ContextOption.options(appMode: .solo,     stage: .curious).count,     5)
        XCTAssertEqual(ContextOption.options(appMode: .solo,     stage: .exploring).count,   4)
        XCTAssertEqual(ContextOption.options(appMode: .solo,     stage: .experienced).count, 4)
        XCTAssertEqual(ContextOption.options(appMode: .together, stage: .curious).count,     5)
        XCTAssertEqual(ContextOption.options(appMode: .together, stage: .exploring).count,   4)
        XCTAssertEqual(ContextOption.options(appMode: .together, stage: .experienced).count, 4)
    }

    func test_undecidedCardIsLast() {
        let last = ContextOption.options(appMode: .solo, stage: .curious).last
        XCTAssertEqual(last?.id, "solo_curious_undecided")
        XCTAssertEqual(last?.accent, .ember)
    }

    func test_derivedRegister_anxiousContexts() {
        let anxious: [RelationshipContext] = [
            .partneredUndisclosed, .partneredHesitantCurious, .coupleProcessingCurious,
            .coupleStalledConversation, .coupleReorienting, .coupleEvolving,
        ]
        for ctx in anxious {
            XCTAssertEqual(register(for: ctx), .anxious, "\(ctx) should be anxious")
        }
    }

    func test_derivedRegister_excitedContexts() {
        let excited: [RelationshipContext] = [
            .singleExploring, .singleExperienced, .soloPolyIndependent,
            .coupleSolidifying, .coupleFreshIntentional, .coupleSkillBuilding,
        ]
        for ctx in excited {
            XCTAssertEqual(register(for: ctx), .excited, "\(ctx) should be excited")
        }
    }

    func test_undecidedContextsAreFlexible() {
        let undecided: [RelationshipContext] = [
            .soloCuriousUndecided, .soloExploringUndecided, .soloExperiencedUndecided,
            .coupleCuriousUndecided, .coupleExploringUndecided, .coupleExperiencedUndecided,
        ]
        for ctx in undecided {
            XCTAssertEqual(register(for: ctx), .flexible, "\(ctx) should be flexible")
        }
    }

    // Every defined RelationshipContext is reachable through exactly the 2×3 option matrix —
    // no orphan contexts, no duplicates. Self-maintaining against future context additions.
    func test_everyContextReachableExactlyOnce() {
        var seen: [RelationshipContext] = []
        for mode in modes {
            for stage in NMStage.allCases {
                seen.append(contentsOf: ContextOption.options(appMode: mode, stage: stage).map(\.context))
            }
        }
        XCTAssertEqual(
            Set(seen), Set(RelationshipContext.allCases),
            "every RelationshipContext should be reachable through some cell"
        )
        XCTAssertEqual(
            seen.count, RelationshipContext.allCases.count,
            "no context should appear in more than one cell"
        )
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
