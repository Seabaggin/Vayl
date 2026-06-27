//
//  PushService.swift
//  Vayl
//
//  Seg 8 (push invite) — CLIENT scaffold. UNVERIFIED, and intentionally NOT wired
//  into app launch yet, so the verified launch path is untouched.
//
//  To make this functional, the following are YOURS to do (need an Apple Developer
//  account + a real device; none can be done or tested from here):
//    1. Add the Push Notifications capability (aps-environment entitlement) to the
//       Vayl target, and the "remote-notification" background mode if using silent pushes.
//    2. Add a `UIApplicationDelegateAdaptor` (or SceneDelegate) that forwards
//       `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` to
//       `PushService.shared.handleDeviceToken(_:userId:)`.
//    3. Create an APNs auth key (.p8) in App Store Connect and store it as a Supabase
//       secret for the `send-session-invite` edge function.
//    4. Apply the `device_tokens` migration and deploy `send-session-invite`.
//
//  iOS 26 note: authorization uses `.banner` (never `.alert` — a hard error now).
//

import Foundation
import UserNotifications
import UIKit
import OSLog
import Supabase

@MainActor
final class PushService {

    static let shared = PushService()
    private let logger = Logger(subsystem: "com.vayl.app", category: "PushService")
    private init() {}

    /// Ask permission and register with APNs. Call once the user has opted into
    /// session invites — never at cold launch.
    ///
    /// iOS 26 note (corrected): `UNAuthorizationOptions` has no `.banner` — the
    /// `.alert` → `.banner` change is for FOREGROUND PRESENTATION
    /// (`UNNotificationPresentationOptions` in the delegate), not authorization.
    /// Requesting sound/badge here keeps the scaffold compiling and avoids the
    /// banned `.alert`; set the alert/banner presentation style in the notification
    /// delegate when you wire it up.
    func requestAuthorizationAndRegister() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.sound, .badge])
            guard granted else {
                logger.info("push authorization not granted")
                return
            }
            UIApplication.shared.registerForRemoteNotifications()
        } catch {
            logger.warning("push authorization failed (scaffold, unverified): \(error.localizedDescription)")
        }
    }

    /// Forward the APNs token here from the app delegate's
    /// `didRegisterForRemoteNotificationsWithDeviceToken`. Upserts it to `device_tokens`.
    func handleDeviceToken(_ deviceToken: Data, userId: UUID) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        let row = DeviceTokenRow(userId: userId.uuidString, token: token, platform: "ios")
        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("device_tokens")
                    .upsert(row, onConflict: "token")
                    .execute()
                logger.info("device token uploaded (scaffold, unverified)")
            } catch {
                logger.warning("device token upload failed (scaffold): \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Upload payload

private struct DeviceTokenRow: Encodable {
    let userId: String
    let token: String
    let platform: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case token
        case platform
    }
}
