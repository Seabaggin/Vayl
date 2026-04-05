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
            assertionFailure(
                "AppFonts.display: unsupported weight \(weight). " +
                "Supported: .bold, .semibold, .medium"
            )
            return Font.custom("ClashDisplay-Bold", size: size)
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

    // --- Display Scale (Clash Display) ---
    static var heroTitle: Font           { display(42, weight: .bold) }           // 42pt Bold
    static var displayHero: Font         { display(64, weight: .bold) }           // 64pt Bold
    static var scoreDisplay: Font        { display(32, weight: .bold) }           // 32pt Bold
    static var screenTitle: Font         { display(24, weight: .semibold) }       // 24pt Semibold
    static var cardTitle: Font           { display(22, weight: .semibold) }       // 22pt Semibold
    static var sectionHeading: Font      { display(20, weight: .medium) }         // 20pt Medium
    static var sectionLabelSmall: Font   { display(13, weight: .medium) }         // 13pt Medium
    static var prompt: Font              { display(17, weight: .medium) }         // 17pt Medium
    static var promptHighlight: Font     { display(17, weight: .semibold) }       // 17pt Semibold

    // --- Body Scale (Switzer) ---
    static var ctaLabel: Font            { body(16, weight: .semibold) }          // 16pt Semibold
    static var bodyText: Font            { body(16, weight: .regular) }           // 16pt Regular
    static var bodyMedium: Font          { body(15, weight: .medium) }            // 15pt Medium
    static var buttonLabel: Font         { body(14, weight: .semibold) }          // 14pt Semibold
    static var caption: Font             { body(13, weight: .regular) }           // 13pt Regular
    static var overline: Font            { body(11, weight: .semibold) }          // 11pt Semibold
    static var buttonLabelSmall: Font    { body(11, weight: .medium) }            // 11pt Medium
    static var tabLabel: Font            { body(10, weight: .medium) }            // 10pt Medium
    static var label: Font               { body(10, weight: .semibold) }          // 10pt Semibold
    static var badge: Font               { body(10, weight: .medium) }            // 10pt Medium
    static var meta: Font                { body(10, weight: .regular) }           // 10pt Regular

    // MARK: - Debug Font List
    static func debugFontList() {
        for family in UIFont.familyNames.sorted() {
            print("\n\(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  \(name)")
            }
        }
    }
}
