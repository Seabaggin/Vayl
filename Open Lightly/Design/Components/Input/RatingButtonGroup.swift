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
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(ratings, id: \.self) { rating in
                let isSelected = selected == rating
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        if isSelected {
                            selected = nil
                        } else {
                            selected = rating
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(rating.displayLabel)
                            .font(AppFonts.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected
                                ? accentColor(for: rating).opacity(0.06)
                                : AppColors.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected
                                ? accentColor(for: rating)
                                : AppColors.border, lineWidth: 1.5)
                    )
                    .scaleEffect(isSelected ? 0.97 : 1.0)
                    .animation(.spring(response: 0.3), value: isSelected)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
    }

    private func accentColor(for rating: DesireLevel) -> Color {
        switch rating {
        case .excitedAboutIt: return AppColors.magenta
        case .openToIt:       return AppColors.cyan
        case .probablyNot:    return Color.white.opacity(0.5)
        case .notForMe:       return AppColors.gold
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
