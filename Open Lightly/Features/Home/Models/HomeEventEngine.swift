// Home/Models/HomeEventEngine.swift
//
// Pure logic struct. No views. Takes app state, returns one String.
// Priority: partner events → milestones → time/absence → stage defaults

import Foundation

struct HomeEventEngine {

    // MARK: - Public Interface

    /// Returns the two-line-max sub-copy for the greeting block.
    /// Priority: partner events → milestones → time/absence → stage defaults
    static func oneLiner(
        events: [HomeEvent],
        stageIndex: Int,
        cardsCompleted: Int,
        isSolo: Bool,
        partnerName: String?
    ) -> String {

        let partner = partnerName ?? "your partner"

        // PRIORITY 1 — Partner events
        for event in events {
            switch event {
            case .partnerCompletedDesireMap(let name):
                return "\(name) just finished their map.\nYou're both ready."
            case .partnerReflected(let name, let day):
                return "\(name) reflected on \(day)'s session.\nYour turn when you're ready."
            case .mutualReflectRevealReady:
                return "You both reflected.\nSee what you each said."
            default:
                continue
            }
        }

        // PRIORITY 2 — Milestone events
        for event in events {
            switch event {
            case .bothSawFreeReveal:
                return "You saw your first match together.\nThat's where it starts."
            case .fullMapUnlocked:
                return "The full picture is yours now."
            case .stageCompleted(let name):
                return "You finished \(name).\nTake that in."
            case .stageUnlocked(let index):
                return "Stage \(index) just opened up.\nWhen you're ready."
            case .firstSessionCompleted:
                return "You did your first session.\nThe first one matters most."
            case .firstMutualReflection:
                return "You both reflected on that session.\nThat's more than most."
            default:
                continue
            }
        }

        // PRIORITY 3 — Time / absence events
        for event in events {
            switch event {
            case .daysSinceSession(let days, let name):
                if days >= 3 && days <= 7 {
                    return "No rush.\nIt'll be here when you're ready."
                } else if days >= 8 && days <= 14 {
                    if isSolo {
                        return "Take it at your own pace."
                    } else {
                        return "It's been a little while.\n\(name ?? partner) is ready when you are."
                    }
                } else if days >= 15 {
                    return "It's still here.\nNothing lost."
                }
            case .threeOpensNoSession:
                return "Just looking around is fine too."
            default:
                continue
            }
        }

        // PRIORITY 4 — Stage defaults
        if stageIndex == 0 || (stageIndex == 1 && cardsCompleted == 0) {
            if events.isEmpty {
                return "Take your time looking around."
            }
            return isSolo
                ? "Start when you're ready."
                : "Start when you're both ready."
        }

        switch stageIndex {
        case 1:
            return "Your first deck is waiting."
        case 2:
            return "You've started something real."
        case 3, 4:
            return "You're building real momentum."
        case 5, 6, 7:
            return "You've come a long way."
        default:
            return "Most couples never get here."
        }
    }
}
