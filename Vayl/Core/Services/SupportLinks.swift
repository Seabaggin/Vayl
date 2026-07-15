//
//  SupportLinks.swift
//  Vayl
//
//  Single source of truth for the app's support contact, consumed by the
//  Settings → Support row. Builds a prefilled mail-composer URL seeded with a
//  diagnostic block so every incoming "ticket" arrives debuggable.
//
//  `profileId` is the correlation key: it is the same id the app's analytics
//  (FunnelEventService) key on, so once the PostHog SDK is wired and
//  identify(profileId) is called, this id IS the PostHog distinct_id and the
//  support email links straight to the user's session replay.
//

import Foundation
import UIKit

enum SupportLinks {

    /// The support inbox (Cloudflare Email Routing → forwarded to the team inbox).
    /// Also used as the legal / privacy contact address.
    static let email = "support@intothevayl.app"

    /// Prefilled mail-composer link for the Settings → Support row.
    static func mailURL(profileId: String?, coupleId: String?) -> URL {
        let body = """
        Write your message above this line.
        ------------------------------------------------------

        App: \(appVersion)
        Device: \(deviceModel)
        OS: \(osVersion)
        User: \(profileId ?? "not signed in")
        Couple: \(coupleId ?? "-")
        """
        var comps = URLComponents()
        comps.scheme = "mailto"
        comps.path = email
        comps.queryItems = [
            URLQueryItem(name: "subject", value: "Vayl Support"),
            URLQueryItem(name: "body", value: body),
        ]
        // Fallback: a bare mailto if composition ever fails.
        // swiftlint:disable:next force_unwrapping
        return comps.url ?? URL(string: "mailto:\(email)")!
    }

    // MARK: - Diagnostic context

    private static let appVersion: String = {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(v) (\(b))"
    }()

    /// Hardware identifier, e.g. "iPhone17,1" — more useful for support than the
    /// generic "iPhone" UIDevice.model returns.
    private static var deviceModel: String {
        var sys = utsname()
        uname(&sys)
        let id = withUnsafePointer(to: &sys.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
        return id.isEmpty ? "unknown" : id
    }

    private static var osVersion: String {
        "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
    }
}
