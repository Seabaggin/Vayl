//
//  DeckStyle.swift
//  Vayl — Play
//
//  Deck visual identity, GENERATED. No deck is hand-designed: its category sets
//  a colorway family (the legend FoilDeckTheme promised), and a stable hash of
//  the deck id nudges hue + holo phase so no two cases look identical.
//

import SwiftUI

// MARK: - Generated style

struct DeckStyle: Equatable {
    let colorway: FoilColorway
    let glyph: DeckGlyphKind
    let holoPhase: Double            // 0...1 — offsets the foil sheen per deck
    var accent: Color { colorway.c1 }

    static func make(for summary: DeckSummary) -> DeckStyle {
        let base  = FoilColorway.legend(for: summary.category)
        let seed  = stableHash(summary.id)
        let delta = (Double(seed % 1000) / 1000.0 - 0.5) * 18.0      // ±9° hue nudge
        let cw = FoilColorway(
            c0: base.c0.hueRotated(byDegrees: delta),
            c1: base.c1.hueRotated(byDegrees: delta),
            c2: base.c2.hueRotated(byDegrees: delta)
        )
        let phase = Double((seed >> 11) % 1000) / 1000.0
        return DeckStyle(colorway: cw,
                         glyph: DeckGlyphKind(for: summary.category),
                         holoPhase: phase)
    }

    /// Stable FNV-1a — identical styling every launch (NOT Swift's per-run hash).
    static func stableHash(_ s: String) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for b in s.utf8 { h = (h ^ UInt64(b)) &* 0x100000001b3 }
        return h
    }
}

// MARK: - Category → spectrum slice (the legend)

extension FoilColorway {
    static func legend(for category: DeckCategory) -> FoilColorway {
        let p = category.spectrumPosition
        return FoilColorway(
            c0: spectrumColor(at: p - 0.12),
            c1: spectrumColor(at: p),
            c2: spectrumColor(at: p + 0.14)
        )
    }
}

extension DeckCategory {
    /// Hand-placed position on cyan(0) → purple(0.5) → magenta(1). The ONE bit of
    /// authored taste; everything else is generated from it.
    var spectrumPosition: Double {
        switch self {
        case .soloPrep:            return 0.00
        case .foundationEntry:     return 0.10
        case .wildcard:            return 0.24
        case .experienceArc:       return 0.38
        case .relationshipCore:    return 0.48
        case .styleSpecific:       return 0.58
        case .identityDynamics:    return 0.70
        case .multiPerson:         return 0.80
        case .nmSpecific:          return 0.90
        case .advancedExperienced: return 0.98
        }
    }
}

/// Interpolate the app spectrum at p in 0...1 (clamped). Cyan → purple → magenta.
func spectrumColor(at p: Double) -> Color {
    let x = min(1, max(0, p))
    func lerp(_ a: UIColor, _ b: UIColor, _ t: CGFloat) -> Color {
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return Color(red: Double(ar + (br - ar) * t),
                     green: Double(ag + (bg - ag) * t),
                     blue: Double(ab + (bb - ab) * t))
    }
    let cyan = UIColor(AppColors.spectrumCyan)
    let purple = UIColor(AppColors.spectrumPurple)
    let magenta = UIColor(AppColors.spectrumMagenta)
    return x < 0.5 ? lerp(cyan, purple, CGFloat(x / 0.5))
                   : lerp(purple, magenta, CGFloat((x - 0.5) / 0.5))
}

extension Color {
    /// Rotate hue by degrees, preserving S/B/A. Drives per-deck colorway variation.
    func hueRotated(byDegrees deg: Double) -> Color {
        let ui = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return self }
        var nh = (h + CGFloat(deg / 360.0)).truncatingRemainder(dividingBy: 1)
        if nh < 0 { nh += 1 }
        return Color(hue: Double(nh), saturation: Double(s), brightness: Double(b), opacity: Double(a))
    }
}
