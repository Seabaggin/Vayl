//
//  VaylCardAction.swift
//  Vayl
//
//  Created by Claude Code Agent.
//
//  Design/Components/Cards/VaylCardAction.swift
//
//  Actions a card face can report upward via its onAction closure.
//  Child face views call onAction?(.*) when a gesture is detected.
//  The phase receives the action and forwards an intent to VaylDirector.
//  Child faces never know what happens after they report. They just report.
//

import CoreGraphics

/// Actions that a VaylCardFace can emit upward via the onAction closure.
/// Phases receive these and decide what to tell VaylDirector.
/// Card faces never talk to VaylDirector directly.
public enum VaylCardAction {

    /// Card surface was tapped. No additional data.
    case tapped

    /// Card was swiped upward toward the Dealer.
    /// Fires when swipe up velocity exceeds threshold.
    case swipedUp

    /// Card was swiped downward toward the user.
    /// Fires when swipe down velocity exceeds threshold.
    /// Used as drag-to-enter trigger in GenderPhase.
    case swipedDown

    /// Card drag is in progress. Translation is relative to drag start point.
    /// Fires continuously during active drag gesture.
    case dragChanged(translation: CGSize)

    /// Card drag ended. Velocity is the final gesture velocity at release.
    /// Phase uses this to determine if threshold was crossed.
    case dragEnded(velocity: CGSize)

    /// User confirmed a selection — second tap on a raised card, or swipe up.
    /// The phase knows which card fired this and acts accordingly.
    case confirmed

    /// Drum picker settled on a specific gender identity string.
    /// GenderPhase writes this to onboardingData before forwarding to Director.
    case identitySelected(identity: String)
}
