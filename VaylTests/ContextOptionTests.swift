import XCTest
@testable import Vayl

final class ContextOptionTests: XCTestCase {

    func test_everyCellHasFourOptions() {
        for mode in [AppMode.together, .solo, .browsing] {
            for stage in NMStage.allCases {
                XCTAssertEqual(
                    ContextOption.options(appMode: mode, stage: stage).count, 4,
                    "\(mode)/\(stage) should have 4 options"
                )
            }
        }
    }

    func test_browsingFallsBackToSolo() {
        for stage in NMStage.allCases {
            let browsing = ContextOption.options(appMode: .browsing, stage: stage).map(\.id)
            let solo     = ContextOption.options(appMode: .solo,     stage: stage).map(\.id)
            XCTAssertEqual(browsing, solo)
        }
    }

    func test_undecidedCardIsLast() {
        let last = ContextOption.options(appMode: .solo, stage: .curious).last
        XCTAssertEqual(last?.id, "solo_curious_undecided")
        XCTAssertEqual(last?.accent, .ember)
    }

    func test_derivedRegister_anxiousContexts() {
        let anxious: [RelationshipContext] = [
            .partneredUndisclosed, .coupleAsymmetricCurious,
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

    func test_allTwentyFourContextsReachable() {
        var seen = Set<RelationshipContext>()
        for mode in [AppMode.together, .solo] {
            for stage in NMStage.allCases {
                for opt in ContextOption.options(appMode: mode, stage: stage) {
                    seen.insert(opt.context)
                }
            }
        }
        XCTAssertEqual(seen.count, 24)
    }

    private func register(for ctx: RelationshipContext) -> SituationalRegister? {
        for mode in [AppMode.together, .solo] {
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
