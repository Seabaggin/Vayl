import SwiftUI

/// The calm sibling to LivingText: a static two-stop spectrum gradient, no
/// breathing glow, no blur layers. For emphasis that shouldn't compete for
/// attention — headers where LivingText's animated bloom reads as too much,
/// and the shared color identity for highlightWords inside flowing card
/// text (see `wordColor` — SwiftUI can't put a moving gradient on individual
/// words within wrapped text without breaking line flow, so per-word
/// highlights use a solid color rather than the full gradient).
struct HighlightText: View {
    let text: String
    var font: Font = AppFonts.display(28, weight: .semibold, relativeTo: .title2)

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(HighlightText.gradient)
            .accessibilityLabel(text)
    }

    /// Static — no per-frame recomputation, no TimelineView.
    static let gradient = LinearGradient(
        colors: [AppColors.spectrumCyan, AppColors.spectrumPurple],
        startPoint: .leading, endPoint: .trailing
    )

    /// The solid-color equivalent for per-word highlights inside an
    /// AttributedString (card highlightWords) — see the type doc above.
    static let wordColor = AppColors.spectrumCyan
}

// MARK: - Previews

#Preview("Dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            HighlightText(text: "acquainted.",
                          font: AppFonts.display(42, weight: .bold, relativeTo: .largeTitle))
            HighlightText(text: "exploring?", font: AppFonts.heroTitle)
            HighlightText(text: "Conversations", font: AppFonts.screenTitle)
        }
        .padding(AppSpacing.xl)
    }
    .preferredColorScheme(.dark)
}
