import SwiftUI

// MARK: - PromptDifficulty Visual Extensions
extension PromptDifficulty {
    var backgroundTint: Color {
        switch self {
        case .easy:      return AppColors.cyan.opacity(0.03)
        case .light:     return AppColors.cyan.opacity(0.05)
        case .medium:    return AppColors.purple.opacity(0.06)
        case .deep:      return AppColors.purple.opacity(0.08)
        case .sensitive: return AppColors.magenta.opacity(0.10)
        case .ultimate:  return AppColors.magenta.opacity(0.14)
        }
    }
    var borderOpacity: Double {
        switch self {
        case .easy:      return 0.4
        case .light:     return 0.5
        case .medium:    return 0.6
        case .deep:      return 0.7
        case .sensitive: return 0.85
        case .ultimate:  return 1.0
        }
    }
    var glowColor: Color {
        switch self {
        case .easy, .light:         return AppColors.cyan
        case .medium, .deep:        return AppColors.purple
        case .sensitive, .ultimate: return AppColors.magenta
        }
    }
    var glowRadius: CGFloat {
        switch self {
        case .easy:      return 20
        case .light:     return 25
        case .medium:    return 30
        case .deep:      return 40
        case .sensitive: return 50
        case .ultimate:  return 65
        }
    }
}

struct PromptCard: View {
    let prompt: Prompt
    var showDifficultyDots: Bool = true
    @Environment(\.colorScheme) private var colorScheme

    var intensity: PromptDifficulty {
        prompt.difficulty
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Outer container
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(intensity.backgroundTint)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(AppColors.spectrumGradient.opacity(intensity.borderOpacity), lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(
                    color: colorScheme == .dark ? intensity.glowColor : Color.black.opacity(0.10),
                    radius: colorScheme == .dark ? intensity.glowRadius * 0.5 : 12,
                    x: 0, y: 4
                )

            // Radial glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [intensity.glowColor, .clear]),
                        center: .center,
                        startRadius: 0,
                        endRadius: intensity.glowRadius * 1.5
                    )
                )
                .frame(width: intensity.glowRadius * 3, height: intensity.glowRadius * 3)
                .offset(x: 60, y: -40)
                .blur(radius: intensity.glowRadius)
                .allowsHitTesting(false)

            // Content stack
            VStack(alignment: .leading, spacing: 16) {
                // Category label
                Text(prompt.category.rawValue.uppercased())
                    .font(AppFonts.overline)
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundColor(AppColors.textTertiary)

                // Prompt text
                KeywordHighlightText(
                    fullText: prompt.text,
                    keywords: prompt.highlightWords.map { (text: $0, type: "cyan") },
                    lineLimit: 3,
                    minimumScaleFactor: 0.80
                )
                    .font(AppFonts.cardTitle)
                    .lineSpacing(4)
                    .foregroundColor(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: false)

                // Footer row
                HStack {
                    // Intensity label
                    Text(intensity.displayName.capitalized)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)

                    Spacer()

                    // Difficulty dots
                    if showDifficultyDots {
                        HStack(spacing: 4) {
                            let difficultyOrder = [PromptDifficulty.easy, .light, .medium, .deep, .sensitive, .ultimate]
                            ForEach(0..<6, id: \ .self) { i in
                                Circle()
                                    .frame(width: 6, height: 6)
                                    .foregroundStyle(
                                        i <= difficultyOrder.firstIndex(of: prompt.difficulty) ?? 0 ? AppColors.cyan : Color.white.opacity(0.15)
                                    )
                            }
                        }
                    }
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        PromptCard(prompt: Prompt(
            text: "What first attracted you to the idea of opening your relationship?",
            highlightWords: ["opening your relationship"],
            category: .prompt,
            difficulty: .easy,
            meta: "",
            isSensitive: false,
            canSkip: true,
            whoStarts: .partnerA
        ))
        PromptCard(prompt: Prompt(
            text: "How do you handle jealousy when it shows up unexpectedly?",
            highlightWords: ["jealousy"],
            category: .reflect,
            difficulty: .medium,
            meta: "",
            isSensitive: true,
            canSkip: true,
            whoStarts: .partnerB
        ))
        PromptCard(prompt: Prompt(
            text: "If there were no fear and no judgment — what would your ideal relationship actually look like?",
            highlightWords: ["no fear", "no judgment"],
            category: .ultimate,
            difficulty: .ultimate,
            meta: "",
            isSensitive: true,
            canSkip: false,
            whoStarts: .both
        ))
    }
    .padding()
    .background(AppColors.background)
}
