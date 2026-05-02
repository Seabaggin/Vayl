//
//  VaylPrimitives.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//


// App/Theme/VaylPrimitives.swift

import SwiftUI

// ─────────────────────────────────────────────────────────────
// Tier 1 — Raw color values.
//
// Rules:
//   • internal — not accessible outside the module accidentally
//   • Named for appearance, never purpose
//   • Never referenced in any view, component, or feature file
//   • The ONLY permitted consumer is AppColors.swift
//
// If you are reading this in a view file, that is a violation.
// ─────────────────────────────────────────────────────────────

enum VaylPrimitives {

    // ── Spectrum anchors ──────────────────────────────────────
    static let cyan           = UIColor(hex: "#00C2FF")
    static let cyanLight      = UIColor(hex: "#4DD8FF")
    static let cyanDark       = UIColor(hex: "#0891B2")

    static let purple         = UIColor(hex: "#6C3AE0")
    static let purpleLight    = UIColor(hex: "#A78BFA")
    static let purpleBright   = UIColor(hex: "#C084FC")
    static let purpleVivid    = UIColor(hex: "#9333EA")
    static let electricViolet = UIColor(hex: "#8B5CF6")

    static let magenta        = UIColor(hex: "#FF006A")
    static let magentaLight   = UIColor(hex: "#FF4D94")
    static let magentaDark    = UIColor(hex: "#BE185D")
    static let pink           = UIColor(hex: "#FF2D8A")

    static let deepBlue       = UIColor(hex: "#0078FF")

    // ── Neutrals — dark side ──────────────────────────────────
    static let inkBase        = UIColor(hex: "#030305")  // page floor
    static let inkCard        = UIColor(hex: "#12111A")  // card interior
    static let inkSurface     = UIColor(hex: "#1A1825")  // elevated surface
    static let inkRaised      = UIColor(hex: "#0C0C10")  // input fields
    static let inkWidget      = UIColor(hex: "#08060A")  // widget dark floor
    static let inkNodeCore    = UIColor(hex: "#0A0814")  // constellation node core
    static let inkAppIcon     = UIColor(hex: "#090B17")

    // ── Tinted card darks ─────────────────────────────────────
    static let tintCyan       = UIColor(hex: "#061018")
    static let tintPurple     = UIColor(hex: "#080614")
    static let tintMagenta    = UIColor(hex: "#120610")
    static let tintNavy       = UIColor(hex: "#0A1018")
    static let tintIndigo     = UIColor(hex: "#0A0820")
    static let tintPlum       = UIColor(hex: "#180818")

    static let tintSupernovaA = UIColor(hex: "#081420")
    static let tintSupernovaB = UIColor(hex: "#0C0624")
    static let tintSupernovaC = UIColor(hex: "#1A0620")
    static let tintSupernovaD = UIColor(hex: "#1C0818")

    // ── Neutrals — light side ─────────────────────────────────
    static let warmCream      = UIColor(hex: "#F8F6EE")  // page floor
    static let pureWhite      = UIColor(hex: "#FFFFFF")
    static let offWhite       = UIColor(hex: "#F2EFE6")  // inset fields

    // ── Wine scale — light mode text ──────────────────────────
    static let wineDeep       = UIColor(hex: "#3D1A26")                                   // headlines
    static let wineMid        = UIColor(red: 0.36,  green: 0.12,  blue: 0.21,  alpha: 1) // body
    static let wineLight      = UIColor(red: 0.478, green: 0.176, blue: 0.271, alpha: 1) // accent
    static let wineFaint      = UIColor(red: 0.44,  green: 0.07,  blue: 0.18,  alpha: 1) // pills/CTA
    static let nearBlack      = UIColor(hex: "#1A1A1E")

    // ── Gold / amber ──────────────────────────────────────────
    // Safety signal. Full usage rules in AppColors.swift.
    static let gold           = UIColor(hex: "#C8960A")
    static let goldLight      = UIColor(hex: "#E2B93B")
    static let goldDark       = UIColor(hex: "#8B6914")
    static let orangeHot      = UIColor(hex: "#E07020")
    static let orangeDeep     = UIColor(hex: "#C8710A")

    // ── Utility ───────────────────────────────────────────────
    static let destructiveRed = UIColor(hex: "#FF4444")
    static let successGreen   = UIColor(hex: "#00CC88")
}

// MARK: - UIColor hex initialiser (internal — primitives layer only)

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            alpha: Double(a) / 255
        )
    }
}