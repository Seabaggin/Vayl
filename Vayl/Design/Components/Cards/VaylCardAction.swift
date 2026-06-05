//
//  VaylCardAction.swift
//  Vayl
//
//  Design/Components/Cards/VaylCardAction.swift
//
//  Actions a card face can report upward via its onAction closure.
//  Phases receive these and forward intents to VaylDirector.
//  Card faces never talk to VaylDirector directly.
//

import CoreGraphics

public enum VaylCardAction {
    case tapped
    case swipedUp
    case swipedDown
    case dragChanged(translation: CGSize)
    case dragEnded(velocity: CGSize)
    case confirmed
    case identitySelected(identity: String)
}
