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
            Text("DISCOVER YOURSELF")
                .font(AppFonts.display(16, weight: .semibold, relativeTo: .title3))
                .foregroundStyle(AppColors.spectrumCyan)

            InfiniteCarousel(items: quizzes, interval: 5, height: 288) { quiz in
                Button { onSelect(quiz) } label: { quizCard(quiz) }
                    .buttonStyle(PressableCardStyle())
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
            if quiz.kind == "flavor" { flavorPills }
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
        .background(quizGlow)
        .learnCard(AppColors.spectrumCyan)
    }

    // Flavor-type teaser pills. Content-coupled to the flavor quiz — the quiz
    // model doesn't carry these yet; lift to data in the quiz-flow pass.
    private var flavorPills: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) { flavorPill("The Explorer"); flavorPill("The Architect") }
            HStack(spacing: AppSpacing.xs) { flavorPill("The Catalyst"); flavorPill("The Anchor") }
        }
        .padding(.top, AppSpacing.xs)
    }

    private func flavorPill(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.label)
            .foregroundStyle(AppColors.spectrumCyan)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(Capsule().fill(AppColors.spectrumCyan.opacity(0.08))
                .overlay(Capsule().stroke(AppColors.spectrumCyan.opacity(0.28), lineWidth: 1)))
    }

    // Soft corner glow inside the card (clipped by learnCard) — cyan only.
    private var quizGlow: some View {
        ZStack {
            RadialGradient(colors: [AppColors.spectrumCyan.opacity(0.18), .clear],
                           center: .topTrailing, startRadius: 0, endRadius: 200)
            RadialGradient(colors: [AppColors.spectrumCyan.opacity(0.08), .clear],
                           center: .bottomLeading, startRadius: 0, endRadius: 160)
        }
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
