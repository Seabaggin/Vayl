//
//  KeywordHighlightText.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

// MARK: - KeywordHighlightText — keyword highlighting
struct KeywordHighlightText: View {
    let fullText: String
    let keywords: [(text: String, type: String)]
    var font: Font = AppFonts.cardTitle
    var baseColor: Color = AppColors.textPrimary

    private func highlightUIColor(for type: String) -> UIColor {
        switch type.lowercased() {
        case "cyan": return UIColor(AppColors.accentPrimary)
        case "magenta": return UIColor(AppColors.accentTertiary)
        case "gold": return UIColor(AppColors.safetyAccent)
        default: return UIColor(baseColor)
        }
    }

    var lineLimit: Int? = nil
    var minimumScaleFactor: CGFloat = 1.0

    var body: some View {
        Text(buildAttributedString())
            .font(font)
            .lineLimit(lineLimit)
            .minimumScaleFactor(minimumScaleFactor)
    }

    private func buildAttributedString() -> AttributedString {
        var result = AttributedString(fullText)
        result.font = font
        result.foregroundColor = UIColor(baseColor)
        for keyword in keywords {
            var searchRange = result.startIndex..<result.endIndex
            while let range = result[searchRange].range(of: keyword.text, options: .caseInsensitive) {
                result[range].foregroundColor = highlightUIColor(for: keyword.type)
                if range.upperBound < result.endIndex {
                    searchRange = range.upperBound..<result.endIndex
                } else {
                    break
                }
            }
        }
        return result
    }
}

// MARK: - Preview
#Preview {
    KeywordHighlightText(
        fullText: "What does vulnerability look like when you feel truly safe?",
        keywords: [
            (text: "vulnerability", type: "cyan"),
            (text: "truly safe", type: "magenta")
        ]
    )
    .padding()
    .background(AppColors.pageBackground)
}
