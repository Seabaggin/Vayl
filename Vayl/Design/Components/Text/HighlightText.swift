import SwiftUI

/// The calm sibling to LivingText: a static two-stop spectrum gradient, no
/// breathing glow, no blur layers. For emphasis that shouldn't compete for
/// attention — headers where LivingText's animated bloom reads as too much,
/// and (via `highlighted(_:words:...)`) the shared per-word treatment for
/// `Card.highlightWords` inside flowing card text.
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

    /// Builds one flowing `Text` with `words` set in `highlightFont` + the
    /// spectrum gradient, and the rest of `text` in `baseFont` / `baseColor`.
    /// Segments are folded via string interpolation (`Text("\(a)\(b)")`), not
    /// the `Text.+` operator — deprecated in iOS 26 in favor of exactly this
    /// pattern. An `AttributedString` run can't stand in for this: it only
    /// carries a solid `foregroundColor`, never a gradient `ShapeStyle`.
    /// Matching is case-sensitive exact substring, same as content authoring
    /// expects from `highlightWords`. Overlapping matches are skipped (first
    /// match wins) rather than double-styled.
    static func highlighted(
        _ text: String,
        words: [String],
        baseFont: Font,
        highlightFont: Font,
        baseColor: Color
    ) -> Text {
        guard !text.isEmpty else { return Text("") }
        guard !words.isEmpty else {
            return Text(text).font(baseFont).foregroundStyle(baseColor)
        }

        var ranges: [Range<String.Index>] = []
        for word in words where !word.isEmpty {
            var cursor = text.startIndex
            while let range = text.range(of: word, range: cursor..<text.endIndex) {
                ranges.append(range)
                cursor = range.upperBound
            }
        }
        ranges.sort { $0.lowerBound < $1.lowerBound }

        var segments: [Text] = []
        var cursor = text.startIndex
        for range in ranges {
            guard range.lowerBound >= cursor else { continue }   // overlap — skip
            if range.lowerBound > cursor {
                segments.append(
                    Text(text[cursor..<range.lowerBound]).font(baseFont).foregroundStyle(baseColor)
                )
            }
            segments.append(
                Text(text[range]).font(highlightFont).foregroundStyle(gradient)
            )
            cursor = range.upperBound
        }
        if cursor < text.endIndex {
            segments.append(
                Text(text[cursor...]).font(baseFont).foregroundStyle(baseColor)
            )
        }

        return segments.dropFirst().reduce(segments[0]) { acc, next in
            Text("\(acc)\(next)")
        }
    }
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
