import Foundation
import OSLog
import PostHog

private let logger = Logger(subsystem: "com.vayl.app", category: "PostHogService")

@MainActor
final class PostHogService {
    static let shared = PostHogService()

    private enum ConfigKey {
        static let apiKey = "POSTHOG_API_KEY"
        static let host = "POSTHOG_HOST"
    }

    private(set) var isConfigured = false

    private init() {}

    func setupIfNeeded() {
        guard !isConfigured else { return }
        guard let apiKey = configurationValue(for: ConfigKey.apiKey),
              let host = configurationValue(for: ConfigKey.host) else {
            logger.warning("PostHog NOT configured: POSTHOG_API_KEY/POSTHOG_HOST missing or unsubstituted. All analytics events will be dropped. Run scripts/generate-vayl-xcconfig.sh (keys go in .env) and rebuild.")
            return
        }

        let config = PostHogConfig(apiKey: apiKey, host: host)
        config.captureApplicationLifecycleEvents = true
        config.captureScreenViews = false
        config.errorTrackingConfig.autoCapture = true
        #if DEBUG
        config.debug = true
        #endif
        PostHogSDK.shared.setup(config)
        isConfigured = true
    }

    func identify(authId: UUID, email: String? = nil, userProperties: [String: Any]? = nil) {
        setupIfNeeded()
        var properties = userProperties ?? [:]
        properties["auth_id"] = authId.uuidString
        if let email, !email.isEmpty {
            properties["email"] = email
        }
        PostHogSDK.shared.identify(authId.uuidString, userProperties: properties)
        PostHogSDK.shared.register(["auth_id": authId.uuidString])
    }

    func reset() {
        setupIfNeeded()
        PostHogSDK.shared.reset()
    }

    func capture(_ event: String, properties: [String: Any] = [:]) {
        setupIfNeeded()
        PostHogSDK.shared.capture(event, properties: properties)
    }

    private func configurationValue(for key: String) -> String? {
        if let infoValue = Bundle.main.object(forInfoDictionaryKey: key) as? String,
           !infoValue.isEmpty,
           !infoValue.contains("$(") {
            return infoValue
        }

        let envValue = ProcessInfo.processInfo.environment[key]
        if let envValue, !envValue.isEmpty {
            return envValue
        }

        return nil
    }
}
