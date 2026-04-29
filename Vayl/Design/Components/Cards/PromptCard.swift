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
                    .foregroundStyle(colorScheme == .light ? AppColors.lightTextTertiary : AppColors.textTertiary)
                    .padding(.top, 20)

                Spacer()

                Text(card.text)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .minimumScaleFactor(0.65)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Spacer()

                if showDifficultyDots {
                    Text(card.intensity.displayName)
                        .font(AppFonts.caption)
                        .padding(.bottom, 20)
                }
            }
        }
    }
}
