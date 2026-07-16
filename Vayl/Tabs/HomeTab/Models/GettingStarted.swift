//
//  GettingStarted.swift
//  Vayl
//
//  Pure derivation of the post-onboarding "first steps" activation (Model layer — no SwiftUI).
//  The displayed Path + entry card both read this. Derived from HomeStore flags; never stored.
//

import Foundation

enum GettingStartedStepKind: String, CaseIterable, Hashable {
    case profile        // set up your space (onboarding)
    case mapDesires     // rate the desire map
    case invitePartner  // pair with your partner
    case seeReveal      // the couple reveal (gated)
}

enum GettingStartedStepState: Hashable {
    case done
    case active     // the single current next action
    case upcoming   // not yet, but reachable
    case locked     // blocked until earlier steps finish
}

struct GettingStartedStep: Identifiable, Hashable {
    let kind: GettingStartedStepKind
    let state: GettingStartedStepState
    var id: GettingStartedStepKind { kind }

    var title: String {
        switch kind {
        case .profile:       return "Set up your space"
        case .mapDesires:    return "Map your desires"
        case .invitePartner: return "Bring in your partner"
        case .seeReveal:     return "See what you share"
        }
    }
    var subtitle: String {
        switch kind {
        case .profile:       return "Done in onboarding"
        case .mapDesires:    return "Rate what you want, privately"
        case .invitePartner: return "They map theirs too"
        case .seeReveal:     return "Unlocks when you both finish"
        }
    }
}

struct GettingStarted: Equatable {
    let steps: [GettingStartedStep]

    func state(of kind: GettingStartedStepKind) -> GettingStartedStepState {
        steps.first { $0.kind == kind }?.state ?? .locked
    }
    var nextStep: GettingStartedStep? { steps.first { $0.state == .active } }
    var completedCount: Int { steps.filter { $0.state == .done }.count }
    var totalCount: Int { steps.count }
    var isComplete: Bool { completedCount == totalCount }
    var progress: Double { totalCount == 0 ? 0 : Double(completedCount) / Double(totalCount) }

    /// Derive the activation from the couple's real flags. `profile` is always done (we only reach
    /// Home post-onboarding). `invitePartner` is done when already paired. Exactly one step is
    /// `.active` (the next action); everything after it is `.locked`.
    static func resolve(myMapComplete: Bool, isPaired: Bool, partnerMapComplete: Bool, revealDone: Bool) -> GettingStarted {
        let done: Set<GettingStartedStepKind> = {
            var s: Set<GettingStartedStepKind> = [.profile]
            if myMapComplete { s.insert(.mapDesires) }
            if isPaired { s.insert(.invitePartner) }
            if revealDone { s.insert(.seeReveal) }
            return s
        }()
        // `seeReveal` only becomes reachable (active) once BOTH partners have mapped.
        let order: [GettingStartedStepKind] = [.profile, .mapDesires, .invitePartner, .seeReveal]
        var activeAssigned = false
        let steps: [GettingStartedStep] = order.map { kind in
            if done.contains(kind) { return GettingStartedStep(kind: kind, state: .done) }
            // reveal is gated on both-complete regardless of order position
            let reachable = (kind != .seeReveal) || (myMapComplete && partnerMapComplete)
            if reachable && !activeAssigned {
                activeAssigned = true
                return GettingStartedStep(kind: kind, state: .active)
            }
            return GettingStartedStep(kind: kind, state: reachable ? .upcoming : .locked)
        }
        return GettingStarted(steps: steps)
    }
}
