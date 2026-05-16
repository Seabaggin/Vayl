import SwiftUI

struct PromptCard: View {
    let card: Card
    let showDifficultyDots: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        PremiumCardShell(isLight: colorScheme == .light) {
            VStack {
                Text(card.type.rawValue.uppercased())
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.textTertiary)
                    .padding(.top, AppSpacing.md)

                Spacer()

                Text(card.text)
                    .font(AppFonts.prompt)
                    .minimumScaleFactor(0.65)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.md)

                Spacer()

                if showDifficultyDots {
                    Text(card.intensity.displayName)
                        .font(AppFonts.caption)
                        .padding(.bottom, AppSpacing.md)
                }
            }
        }
    }
}
