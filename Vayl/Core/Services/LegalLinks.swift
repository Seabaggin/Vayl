//
//  LegalLinks.swift
//  Vayl
//
//  Single source of truth for the app's legal-document URLs (Terms of Service +
//  Privacy Policy), consumed by the paywall footer and the sign-in legal line.
//
//  Hosted on Cloudflare Pages (project "vayl-legal"), source in /legal-site.
//  Remember to keep the Privacy URL set in App Store Connect → App Privacy.
//

import Foundation

enum LegalLinks {

    /// Terms of Service (hosted at legal.intothevayl.app/terms).
    // Compile-time-constant literal URL — never nil.
    // swiftlint:disable:next force_unwrapping
    static let terms = URL(string: "https://legal.intothevayl.app/terms")!

    /// Privacy Policy (hosted at legal.intothevayl.app/privacy). Also set in
    /// App Store Connect → App Privacy → Privacy Policy URL.
    // Compile-time-constant literal URL — never nil.
    // swiftlint:disable:next force_unwrapping
    static let privacy = URL(string: "https://legal.intothevayl.app/privacy")!
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
