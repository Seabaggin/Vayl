import SwiftUI

/// Rounded card container used throughout Settings and any other list-style screen.
/// Usage: wrap any content in `SettingsCard { ... }`
struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(16)
        .cardStyle()
    }
}
