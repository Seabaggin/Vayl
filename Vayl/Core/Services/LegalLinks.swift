//
//  LegalLinks.swift
//  Vayl
//
//  Single source of truth for the app's legal-document URLs (Terms of Service +
//  Privacy Policy), consumed by the paywall footer and the sign-in legal line.
//
//  ⚠️ PLACEHOLDER URLs (2026-06-20) — these point at Apple's public legal pages as
//  live, clean-rendering stand-ins so the in-app links route during development.
//  REPLACE BOTH with Vayl's own hosted pages during the App Store Ready pass, and
//  set the Privacy URL in App Store Connect. Checklist:
//  docs/superpowers/specs/2026-06-20-legal-pages-restore-wiring-design.md (§8).
//

import Foundation

enum LegalLinks {

    /// Terms of Service. PLACEHOLDER → Apple's standard Licensed Application EULA
    /// (a real, shippable Terms stand-in). Replace with Vayl's hosted Terms.
    // Compile-time-constant literal URL — never nil.
    // swiftlint:disable:next force_unwrapping
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    /// Privacy Policy. PLACEHOLDER → Apple's public privacy policy (renders cleanly).
    /// Replace with Vayl's hosted Privacy Policy + set it in App Store Connect.
    // Compile-time-constant literal URL — never nil.
    // swiftlint:disable:next force_unwrapping
    static let privacy = URL(string: "https://www.apple.com/legal/privacy/")!
}

/// Which legal document to present — drives `.sheet(item:)` in the consumers.
enum LegalDoc: String, Identifiable {
    case terms
    case privacy

    var id: String { rawValue }

    var url: URL {
        switch self {
        case .terms:   LegalLinks.terms
        case .privacy: LegalLinks.privacy
        }
    }
}
