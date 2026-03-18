//  AppFonts.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

struct AppFonts {
    // MARK: - Display Font (Clash Display)
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        switch weight {
        case .bold:
            return Font.custom("ClashDisplay-Bold", size: size)
        case .semibold:
            return Font.custom("ClashDisplay-Semibold", size: size)
        case .medium:
            return Font.custom("ClashDisplay-Medium", size: size)
        default:
            return Font.system(size: size, weight: .bold, design: .default)
        }
    }

    // MARK: - Body Font (Switzer)
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .regular:
            return Font.custom("Switzer-Regular", size: size)
        case .medium:
            return Font.custom("Switzer-Medium", size: size)
        case .semibold:
            return Font.custom("Switzer-Semibold", size: size)
        case .bold:
            return Font.custom("Switzer-Bold", size: size)
        default:
            return Font.system(size: size, weight: .regular, design: .default)
        }
    }

    // MARK: - Semantic Tokens
    static var heroTitle: Font { display(42, weight: .bold) }
    static var cardTitle: Font { display(22, weight: .semibold) }
    static var sectionHeading: Font { display(20, weight: .medium) }
    static var bodyText: Font { body(16, weight: .regular) }
    static var bodyMedium: Font { body(15, weight: .medium) }
    static var caption: Font { body(13, weight: .regular) }
    static var overline: Font { body(11, weight: .semibold) }
    static var buttonLabel: Font { body(14, weight: .semibold) }

    // MARK: - Debug Font List
    static func debugFontList() {
        for family in UIFont.familyNames.sorted() {
            print("\n\(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  \(name)")
            }
        }
    }

    static var prompt: Font          { display(17, weight: .medium) }
    static var promptHighlight: Font { display(17, weight: .semibold) }
    static var badge: Font           { body(10, weight: .medium) }
    static var button: Font          { body(11, weight: .medium) }
    static var meta: Font            { body(10, weight: .regular) }
    static var sectionHeader: Font   { display(13, weight: .medium) }
    static var screenTitle: Font     { display(24, weight: .semibold) }
    static var label: Font           { body(10, weight: .semibold) }
    static var tabLabel: Font        { body(10, weight: .medium) }
    static var scoreDisplay: Font    { display(32, weight: .bold) }
    static var ctaLabel: Font        { body(16, weight: .semibold) }
}
