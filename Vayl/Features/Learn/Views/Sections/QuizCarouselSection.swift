// Features/Learn/Views/Sections/QuizCarouselSection.swift
//
// Section 1 — self-discovery quizzes as an auto-advancing, infinite-loop
// paging carousel (InfiniteCarousel). Cyan section hairline.

import SwiftUI

struct QuizCarouselSection: View {
    let quizzes: [LearnQuiz]
    var onSelect: (LearnQuiz) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHairline(color: AppColors.spectrumCyan)
            Text("DISCOVER YOURSELF")
                .font(AppFonts.overline)
                .tracking(1.5)
                .foregroundStyle(AppColors.textSecondary)

            InfiniteCarousel(items: quizzes, interval: 5, height: 232) { quiz in
                Button { onSelect(quiz) } label: { quizCard(quiz) }
                    .buttonStyle(.plain)
            }
        }
    }

    private func quizCard(_ quiz: LearnQuiz) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("QUIZ · \(quiz.questionCount) QUESTIONS")
                .font(AppFonts.overline)
                .foregroundStyle(AppColors.spectrumCyan)
            Text(quiz.title)
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(quiz.subtitle)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            HStack(spacing: AppSpacing.xs) {
                Text("Take the quiz")
                Image(systemName: "arrow.right")
            }
            .font(AppFonts.buttonLabel)
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                Capsule()
                    .fill(AppColors.spectrumCyan.opacity(0.16))
                    .overlay(Capsule().stroke(AppColors.spectrumCyan.opacity(0.35), lineWidth: 1))
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(AppSpacing.lg)
        .learnCard(AppColors.spectrumCyan)
    }
}

#Preview {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        QuizCarouselSection(quizzes: [
            LearnQuiz(id: "flavor", kind: "flavor", title: "What's Your Flavor of NM?", subtitle: "Where you actually land — not where you think you should.", questionCount: 12),
            LearnQuiz(id: "boundary", kind: "boundary", title: "Where Are Your Lines?", subtitle: "Boundaries as a spectrum, not a checklist.", questionCount: 12)
        ])
        .padding()
    }
}
