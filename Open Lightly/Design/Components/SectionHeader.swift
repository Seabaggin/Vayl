import SwiftUI

/// All-caps muted label used above sections in Settings, Home, and list screens.
/// Usage: `SectionHeader("PROFILE")`
struct SectionHeader: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(AppFonts.sectionHeader)
            .foregroundColor(AppColors.textMuted)
    }
}
