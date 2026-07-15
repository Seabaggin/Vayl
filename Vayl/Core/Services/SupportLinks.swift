//
//  SupportLinks.swift
//  Vayl
//
//  Single source of truth for the app's support contact, consumed by the
//  Settings → Support row.
//
//  ⚠️ PLACEHOLDER (2026-07-14) — `email` is a stand-in so the Support row has real
//  behavior (opens the user's mail composer) instead of being a dead no-op. REPLACE
//  with a real support inbox you monitor before submission — the SAME contact email
//  you put in the legal pages (see legal-site/README.md). Then delete this comment.
//

import Foundation

enum SupportLinks {

    /// The support inbox. PLACEHOLDER — replace with Vayl's real monitored address.
    static let email = "support@vayl.app"

    /// Prefilled mail-composer link for the Settings → Support row.
    /// Compile-time-constant literal URL — never nil.
    // swiftlint:disable:next force_unwrapping
    static let contactURL = URL(string: "mailto:\(email)?subject=Vayl%20Support")!
}
