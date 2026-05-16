// Features/Onboarding/Layout/OnboardingLayout.swift
//
// Shared proportional spacing constants for the onboarding flow.
// All values are expressed as fractions of the screen's live height or width
// so that the layout scales correctly across the full device matrix:
//
//   iPhone SE 2/3    375 × 667 pt   (home button, no bottom safe area)
//   iPhone 16        393 × 852 pt   (34 pt bottom safe area)
//   iPhone 16 Plus   430 × 932 pt   (34 pt bottom safe area)
//   iPhone 16 Pro    402 × 874 pt   (34 pt bottom safe area)
//   iPhone 16 Pro Max 440 × 956 pt  (34 pt bottom safe area)
//
// Reference device: iPhone 16 (852 pt height).
// Fraction × 852 == the original hardcoded pt value at reference size.
//
// Usage:
//   GeometryReader { geo in
//       let h = geo.size.height
//       let w = geo.size.width
//       VStack(spacing: 0) { ... }
//           .padding(.top, OL.navTop(h))
//   }

import SwiftUI

typealias OL = OnboardingLayout

enum OnboardingLayout {

    // MARK: - Nav Bar

    /// Fixed top padding for the nav bar across all major iPhone models.
    /// GeometryReader height (safe-area-excluded) is the key.
    /// Values validated against:
    ///   SE 2/3        667pt   → 8pt
    ///   iPhone 14/15  844pt   → 12pt
    ///   iPhone 16     852pt   → 12pt
    ///   iPhone 16 Pro 874pt   → 14pt
    ///   iPhone 16 Plus 932pt  → 14pt
    ///   iPhone 16 Pro Max 956pt → 16pt
    ///   iPhone 17 Pro Max 956pt → 16pt
    static func navTop(_ h: CGFloat) -> CGFloat {
        switch h {
        case ..<700:  return 8
        case ..<860:  return 12
        case ..<940:  return 14
        default:      return 16
        }
    }

    /// Gap between nav bar and first content element.
    /// SE: ~14pt  |   reference: ~20pt   |   Pro Max: ~22pt
    static func navBottom(_ h: CGFloat) -> CGFloat { h * 0.023 }

    // MARK: - Vertical Rhythm Scale

    /// Tight gap — between tightly-coupled elements (label → sub-label).
    /// SE: ~9pt   |   reference: ~12pt   |   Pro Max: ~13pt
    static func compact(_ h: CGFloat) -> CGFloat   { h * 0.014 }

    /// Standard section gap — between distinct content blocks.
    /// SE: ~19pt  |   reference: ~24pt   |   Pro Max: ~27pt
    static func standard(_ h: CGFloat) -> CGFloat  { h * 0.028 }

    /// Loose breathing room — between major sections or before/after CTA.
    /// SE: ~31pt  |   reference: ~40pt   |   Pro Max: ~45pt
    static func loose(_ h: CGFloat) -> CGFloat     { h * 0.047 }

    // MARK: - Progress Bar Clearance

    /// Space above the progress bar (below nav / safe area).
    /// SE: ~19pt  |   reference: ~24pt   |   Pro Max: ~27pt
    static func progressTop(_ h: CGFloat) -> CGFloat    { h * 0.028 }

    /// Space below the progress bar before the first text element.
    /// SE: ~15pt  |   reference: ~20pt   |   Pro Max: ~22pt
    static func progressBottom(_ h: CGFloat) -> CGFloat { h * 0.023 }

    // MARK: - Spacer Bounds

    /// Minimum spacer height — prevents content from touching on SE.
    static func spacerMin(_ h: CGFloat) -> CGFloat  { h * 0.033 }

    /// Maximum spacer height — prevents excessive dead space on Pro Max.
    static func spacerMax(_ h: CGFloat) -> CGFloat  { h * 0.075 }

    // MARK: - Atmosphere Decoration

    /// Width for full-bleed atmosphere ellipses (maps 600 pt at 393 w reference).
    static func atmosW(_ w: CGFloat) -> CGFloat { w * 1.53 }

    /// Height for full-bleed atmosphere ellipses (maps 500 pt at 852 h reference).
    static func atmosH(_ h: CGFloat) -> CGFloat { h * 0.587 }

    // MARK: - ScrollView Content

    /// Minimum VStack height inside a ScrollView — fills screen before
    /// scroll activates, preventing compression on small devices.
    static func scrollMinH(_ h: CGFloat) -> CGFloat { h * 0.85 }
}
