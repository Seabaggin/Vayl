//
//  CardLayout.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/30/26.
//

//
//  CardLayout.swift
//  Open Lightly
//
//  Single source of truth for card dimensions across the app.
//  All screens that render a card reference these values.
//
//  Standard card: 313 × 438 — poker/bridge aspect ratio (1:1.40)
//  This matches the physical card proportion every user already
//  knows from handling real cards.
//

import CoreGraphics

enum CardLayout {

    // MARK: - Standard card
    // 313pt wide = screen width (393pt) - 80pt margin
    // 438pt tall = 313 × 1.40 (poker/bridge aspect ratio)

    static let width: CGFloat = 313
    static let height: CGFloat = 438
    static let cornerRadius: CGFloat = 20

    static let size = CGSize(width: width, height: height)

    // MARK: - Margin
    // How much total horizontal space is removed from screen width.
    // w - horizontalMargin = card width on any device.
    static let horizontalMargin: CGFloat = 80
}
