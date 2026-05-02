// ✅ Design system audit — verified March 9, 2026

import SwiftUI

// MARK: - RatingButtonGroup
// 2x2 grid of rating buttons for Desire Map
// (Arrows replaced: use <- and -> in comments, not unicode)
struct RatingButtonGroup: View {
    @Binding var selected: DesireLevel?

    private let ratings: [DesireLevel] = [.excitedAboutIt, .openToIt, .probablyNot, .notForMe]
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
            ForEach(ratings, id: \.self) { rating in
                let isSelected = selected == rating
                Button {
                    withAnimation(AppAnimation.spring) {
                        if isSelected {
                            selected = nil
                        } else {
                            selected = rating
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    VStack(spacing: AppSpacing.xs) {
                        Text(rating.displayLabel)
                            .font(AppFonts.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .padding(.vertical, AppSpacing.sm)
                    .padding(.horizontal, AppSpacing.sm)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .fill(isSelected
                                ? accentColor(for: rating).opacity(0.06)
                                :  AppColors.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(isSelected
                                ? accentColor(for: rating)
                                : AppColors.borderSubtle, lineWidth: 1.5)
                    )
                    .scaleEffect(isSelected ? 0.97 : 1.0)
                    .animation(AppAnimation.spring, value: isSelected)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, AppSpacing.xs)
        .padding(.horizontal, AppSpacing.xxs)
    }

    private func accentColor(for rating: DesireLevel) -> Color {
        switch rating {
        case .excitedAboutIt: return AppColors.accentTertiary
        case .openToIt:       return AppColors.accentPrimary
        case .probablyNot:    return Color.white.opacity(0.5)
        case .notForMe:       return AppColors.safetyAccent
        }
    }
}

// MARK: - Preview
struct RatingButtonGroup_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RatingButtonGroup(selected: .constant(nil))
                .padding()
        }
        .preferredColorScheme(.dark)
    }
}
