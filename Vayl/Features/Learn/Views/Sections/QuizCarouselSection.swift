// Features/Learn/Views/Sections/QuizCarouselSection.swift
//
// Section 1 — self-discovery quizzes as a horizontal carousel. STUB:
// a horizontal ScrollView of quiz cards; paging/snap feel is deferred.

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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(quizzes) { quiz in
                        Button { onSelect(quiz) } label: { quizCard(quiz) }
                            .buttonStyle(.plain)
                    }
                }
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
            Text(quiz.subtitle)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .frame(width: 260, height: 150, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.xl)
                        .stroke(AppColors.spectrumCyan.opacity(0.28), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        QuizCarouselSection(quizzes: [
            LearnQuiz(id: "flavor", kind: "flavor", title: "What's Your Flavor of NM?", subtitle: "Where you actually land.", questionCount: 12),
            LearnQuiz(id: "boundary", kind: "boundary", title: "Where Are Your Lines?", subtitle: "Boundaries as a spectrum.", questionCount: 12)
        ])
        .padding()
    }
}
