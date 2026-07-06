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
    static let spectrumBridge = UIColor(hex: "#8B6FD4") // mid-spectrum gradient bridge — cyan to magenta wordmark sweep
    static let periwinkle     = UIColor(hex: "#82A0E6") // soft cornflower blue — Pulse capsule halo (map-pulse-us.html .capsule glow)

    static let magenta        = UIColor(hex: "#FF006A")
    static let magentaLight   = UIColor(hex: "#FF4D94")
    static let magentaDark    = UIColor(hex: "#BE185D")
    static let pink           = UIColor(hex: "#FF2D8A")

    static let rose           = UIColor(hex: "#C76A86")  // Protective/Empty tier core
    static let roseLight      = UIColor(hex: "#ECC0CE")  // Protective tier highlight
    static let roseDark       = UIColor(hex: "#8F4A60")  // Protective tier deep

    // Neutral Space — Lavender Silver (both axes in the 0.475–0.525 border zone).
    static let lavenderSilverCore  = UIColor(hex: "#B0AECE")
    static let lavenderSilverLight = UIColor(hex: "#E4E2F4")
    static let lavenderSilverDeep  = UIColor(hex: "#4A4868")

    // Uncharted Space — Sage Deep (contradictory answers on both axes; see PulseAnswers).
    static let sageDeepCore  = UIColor(hex: "#3D9E72")
    static let sageDeepLight = UIColor(hex: "#96CEB0")
    static let sageDeepDeep  = UIColor(hex: "#174D35")

    static let deepBlue       = UIColor(hex: "#0078FF")

    // ── Neutrals — dark side ──────────────────────────────────
    static let inkBase        = UIColor(hex: "#030305")  // page floor
    static let inkCard        = UIColor(hex: "#12111A")  // card interior
    static let inkSurface     = UIColor(hex: "#1A1825")  // elevated surface
    static let inkRaised      = UIColor(hex: "#0C0C10")  // input fields
    static let inkWidget      = UIColor(hex: "#08060A")  // widget dark floor
    static let inkShimmerBase    = UIColor(hex: "#0D0B1A")                                          // holographic shimmer pill base — HolographicShimmer use only
    static let inkShimmerViolet  = UIColor(red: 140/255, green:  0/255, blue: 255/255, alpha: 1)  // deep violet orb — HolographicShimmer use only
    static let inkShimmerCyan    = UIColor(red:   0/255, green: 90/255, blue: 160/255, alpha: 1)  // dark muted cyan orb — HolographicShimmer use only
    static let inkShimmerPurple  = UIColor(red:  55/255, green: 20/255, blue: 130/255, alpha: 1)  // dark muted purple orb — HolographicShimmer use only
    static let inkShimmerMagenta = UIColor(red: 130/255, green: 10/255, blue:  80/255, alpha: 1)  // dark muted magenta orb — HolographicShimmer use only
    static let inkShimmerIndigo  = UIColor(red:  20/255, green: 30/255, blue: 110/255, alpha: 1)  // dark muted indigo orb — HolographicShimmer use only
    static let inkNodeCore    = UIColor(hex: "#0A0814")  // constellation node core
    static let inkAppIcon     = UIColor(hex: "#090B17")

    // ── OB canvas darks ───────────────────────────────────────
    // Distinct from the main-app ink scale.
    // inkVoid is the absolute floor of the OB canvas — slightly warmer/cooler
    // than inkBase to give the table world its own atmospheric identity.
    // inkCardOB is the OB card glass surface — not interchangeable with inkCard.
    // Light-mode equivalents are placeholders until OB Dawn is designed.
    static let inkVoid        = UIColor(hex: "#0a0810")  // OB canvas void floor
    static let inkCardOB      = UIColor(hex: "#120f1a")  // OB card glass surface

    static let tableFeltCore    = UIColor(red: 22/255,  green: 17/255,  blue: 38/255,  alpha: 0.95) // felt fill center
    static let tableFeltMid     = UIColor(red: 18/255,  green: 14/255,  blue: 33/255,  alpha: 0.90) // felt fill mid
    static let tableFeltOuter   = UIColor(red: 14/255,  green: 11/255,  blue: 26/255,  alpha: 0.85) // felt fill outer
    static let tableFeltEdge    = UIColor(red: 10/255,  green:  8/255,  blue: 18/255,  alpha: 0.10) // felt fill trailing edge
    static let tableTopoLine    = UIColor(red: 150/255, green: 132/255, blue: 208/255, alpha: 1)    // topo contour stroke
    static let tableCompassStar = UIColor(red: 232/255, green: 228/255, blue: 222/255, alpha: 1)    // compass star
    static let tableAmberPool   = UIColor(red: 255/255, green: 235/255, blue: 180/255, alpha: 0.055) // amber pool center

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

    // ── Pure values ───────────────────────────────────────────
    static let pureBlack        = UIColor(hex: "#000000")

    // ── Text ──────────────────────────────────────────────────
    static let inkText          = UIColor(hex: "#E8E8F0")

    // ── Card surfaces ─────────────────────────────────────────
    static let roseWhite        = UIColor(red: 1.0,   green: 0.957, blue: 0.965, alpha: 1)
    static let inkCardRaised    = UIColor(red: 0.086, green: 0.078, blue: 0.141, alpha: 0.92)
    static let frostCard        = UIColor(red: 0.989, green: 0.985, blue: 0.972, alpha: 1)

    // ── Pill surfaces ─────────────────────────────────────────
    static let frostPill        = UIColor(red: 0.910, green: 0.875, blue: 0.945, alpha: 1)
    static let inkPill          = UIColor(red: 0.10,  green: 0.09,  blue: 0.16,  alpha: 1)
    static let frostPillSelected = UIColor(red: 0.958, green: 0.875, blue: 0.925, alpha: 1)
    static let frostPillBottom  = UIColor(red: 0.880, green: 0.845, blue: 0.920, alpha: 1)
    static let inkPillBottom    = UIColor(red: 0.08,  green: 0.07,  blue: 0.13,  alpha: 1)

    // ── CTA ───────────────────────────────────────────────────
    static let frostCTA         = UIColor(red: 0.98,  green: 0.91,  blue: 0.93,  alpha: 1)

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
