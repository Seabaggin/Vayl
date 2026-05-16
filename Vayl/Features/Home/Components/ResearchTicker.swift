// Home/Components/ResearchTicker.swift

import SwiftUI

struct ResearchTicker: View {
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    private let facts: [ResearchFact] = [
        ResearchFact(category: .research,
            body: "1 in 5 Americans has engaged in CNM\nat some point in their lives.",
            attribution: "— Haupert et al., 2017"),
        ResearchFact(category: .research,
            body: "Communication quality is measurably higher\nin CNM relationships. The structure demands it.",
            attribution: "— Rubel & Bogaert, 2015"),
        ResearchFact(category: .research,
            body: "The biggest predictor of success isn't\ncompatibility — it's whether both people\ngenuinely chose this.",
            attribution: "— Rubel & Bogaert, 2015"),
        ResearchFact(category: .definition,
            body: "Compersion: feeling joy at your partner's\nhappiness with someone else.",
            attribution: nil),
        ResearchFact(category: .definition,
            body: "NRE — New Relationship Energy:\nthe heightened feeling of a new connection.\nReal, temporary, manageable.",
            attribution: nil),
        ResearchFact(category: .definition,
            body: "Metamour: your partner's partner.\nSomeone you may never meet — or become\nclose friends with.",
            attribution: nil),
        ResearchFact(category: .reframe,
            body: "Jealousy is information,\nnot evidence that something is wrong.",
            attribution: nil),
        ResearchFact(category: .reframe,
            body: "Most people who explore CNM\nweren't unhappy. They were curious.",
            attribution: nil),
        ResearchFact(category: .research,
            body: "People who live in alignment with their\nactual desires report lower anxiety —\nregardless of what those desires are.",
            attribution: "— Moors et al., 2017"),
        ResearchFact(category: .reframe,
            body: "Sexual and romantic attraction are\nindependent dimensions. Both matter.\nNeither determines the other.",
            attribution: "— Diamond, 2003"),
    ]

    @State private var currentIndex: Int  = 0
    @State private var opacity:      Double = 1.0

    private let displayDuration: TimeInterval = 10

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Rectangle()
                .fill(isLight
                    ? Color.black.opacity(0.06)
                    : Color.white.opacity(0.06))
                .frame(height: 1)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(facts[currentIndex].category.overlineLabel)
                    .font(AppFonts.overline)
                    .tracking(1.2)
                    .foregroundStyle(AppColors.textTertiary)

                Text(facts[currentIndex].body)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(isLight
                        ? AppColors.textSecondary
                        : AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)

                if let attribution = facts[currentIndex].attribution {
                    Text(attribution)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .opacity(opacity)
            .padding(.vertical, AppSpacing.md)

            Rectangle()
                .fill(isLight
                    ? Color.black.opacity(0.06)
                    : Color.white.opacity(0.06))
                .frame(height: 1)
        }
        .padding(.horizontal, AppSpacing.lg)
        .allowsHitTesting(false)
        .onAppear {
            startCycle()
        }
    }

    private func startCycle() {
        Timer.scheduledTimer(withTimeInterval: displayDuration,
                             repeats: true) { _ in
            withAnimation(AppAnimation.enter) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.4 + 0.1
            ) {
                currentIndex = (currentIndex + 1) % facts.count
                withAnimation(AppAnimation.enter) {
                    opacity = 1
                }
            }
        }
    }
}

#Preview("Ticker Dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ResearchTicker()
    }
    .preferredColorScheme(.dark)
}

#Preview("Ticker Light") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ResearchTicker()
    }
    .preferredColorScheme(.light)
}
