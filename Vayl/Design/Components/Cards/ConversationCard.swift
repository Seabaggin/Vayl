//  ConversationCard.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/28/26.
//


import SwiftUI

struct ConversationCard: View {

    // MARK: - Inputs

    let content: ConversationCardContent
    let fuseConfig: FuseConfig
    let ghostDeckMode: GhostDeckMode

    // MARK: - State

    @State private var isFlipped = false
    @State private var arrowVisible = false
    @State private var pulsing = false
    @State private var selectedPill: CardRevealPill? = nil
    @State private var showEncouragement = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Callbacks

    var onPillSelected: ((CardRevealPill) -> Void)? = nil
    var onContinue: (() -> Void)? = nil

    // MARK: - Layout

    private let cardHeight: CGFloat = 420
    private let cornerRadius: CGFloat = AppRadius.container
    private let lineWidth: CGFloat = 1.5

    private var cardWidth: CGFloat {
        let scenes: [UIWindowScene] = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        let scene: UIWindowScene? = scenes.first(where: { $0.activationState == .foregroundActive })
            ?? scenes.first
        let screenWidth: CGFloat = scene?.screen.bounds.width ?? 390
        return screenWidth - 48
    }

    var cardSize: CGSize {
        CGSize(width: cardWidth, height: cardHeight)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Ghost deck behind everything
            if case .atmospheric = ghostDeckMode {
                AtmosphericGhostDeck(
                    cardSize: cardSize,
                    cornerRadius: cornerRadius
                )
            }

            // Card itself
            ZStack {
                frontFace
                    .opacity(isFlipped ? 0 : 1)
                    .rotation3DEffect(
                        .degrees(isFlipped ? 180 : 0),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.4
                    )

                backFace
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(
                        .degrees(isFlipped ? 0 : -180),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.4
                    )
            }
            .frame(width: cardWidth, height: cardHeight)
            .scaleEffect((pulsing && !reduceMotion && !AppAnimation.lowPower) ? 1.02 : 1.0)
            .animation(
                (pulsing && !reduceMotion && !AppAnimation.lowPower)
                    ? .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
                    : .default,
                value: pulsing
            )
            .onTapGesture {
                if !isFlipped {
                    flipCard()
                }
            }
        }
    }

    // MARK: - Front Face

    private var frontFace: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(AppColors.cardBackground)

            // Ambient wash — subtle glow at bottom
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.accentSecondary.opacity(0.06),
                            AppColors.accentPrimary.opacity(0.04),
                            .clear
                        ],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )

            // Content
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Overline
                if let overline = frontOverline {
                    Text(overline)
                        .font(AppFonts.overline)
                        .tracking(2)
                        .foregroundStyle(AppColors.textTertiary)
                }

                Spacer()

                // Question
                frontQuestionText

                Spacer()

                // Arrow — fades in after fuse completes
                if arrowVisible {
                    HStack {
                        Spacer()
                    }
                }
            }
            .padding(AppSpacing.xl)

            // Fuse timer — rendered over card, under content
            fuseOverlay

            // Border
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(AppColors.borderSubtle, lineWidth: 1)
        }
    }

    // MARK: - Back Face

    private var backFace: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(AppColors.cardBackground)

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.accentTertiary.opacity(0.05),
                            AppColors.accentSecondary.opacity(0.04),
                            .clear
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )

            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Something came up. What's it closest to?")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)

                Spacer()

                if case .onboarding(let card) = content,
                   case .pills(let pills) = card.backFace {
                    pillGrid(pills: pills)
                }

                Spacer()

                if showEncouragement {
                    encouragementText
                        .transition(.opacity)
                }
            }
            .padding(AppSpacing.xl)

            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(AppColors.borderSubtle, lineWidth: 1)
        }
    }

    // MARK: - Pill Grid

    private func pillGrid(pills: [CardRevealPill]) -> some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(pills) { pill in
                pillButton(pill: pill)
            }
        }
    }

    private func pillButton(pill: CardRevealPill) -> some View {
        let isSelected = selectedPill == pill

        return Button {
            guard selectedPill == nil else { return }
            handlePillSelection(pill)
        } label: {
            Text(pill.rawValue)
                .font(AppFonts.buttonLabel)
                .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.pill)
                        .fill(isSelected
                              ? AppColors.accentSecondary.opacity(0.15)
                              : AppColors.whisperFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.pill)
                        .stroke(
                            isSelected
                                ? AnyShapeStyle(AppColors.spectrumBorder)
                                : AnyShapeStyle(AppColors.borderDefault),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(AppAnimation.spring, value: isSelected)
    }

    // MARK: - Encouragement

    private var encouragementText: some View {
        Text("This journey asks a lot of the people it's meant for. You're in good company.")
            .font(AppFonts.bodyMedium)
            .foregroundStyle(AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Fuse Overlay

    @ViewBuilder
    private var fuseOverlay: some View {
        if case .countdown(let duration, let onComplete) = fuseConfig {
            FuseTimerView(
                size: cardSize,
                cornerRadius: cornerRadius,
                lineWidth: lineWidth,
                duration: duration,
                delay: 1.5,
                onComplete: {
                    withAnimation(.easeIn(duration: 0.4)) {
                        arrowVisible = true
                    }
                    pulsing = true
                    onComplete()
                }
            )
        }
    }

    // MARK: - Helpers

    private var frontOverline: String? {
        switch content {
        case .onboarding(let card): return card.overline
        case .prompt: return nil
        }
    }

    private var frontQuestionText: some View {
        switch content {
        case .onboarding(let card):
            return AnyView(highlightedQuestion(card: card))
        case .prompt(let text):
            return AnyView(
                Text(text)
                    .font(AppFonts.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineSpacing(6)
            )
        }
    }

    private func highlightedQuestion(card: OBCard) -> some View {
        // Split question around highlighted phrase, apply gradient to phrase
        let parts = card.question.components(separatedBy: card.highlightedPhrase)

        return Group {
            if parts.count == 2 {
                VStack(spacing: 0) {
                    Text(parts[0] + card.highlightedPhrase + parts[1])
                        .font(AppFonts.cardTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineSpacing(6)
                }
                .overlay(alignment: .topLeading) {
                    let prefix = AttributedString(parts[0])
                    // Content-driven phrase: unbalanced markdown metachars (*, [, \) would
                    // trap on try!. Fall back to a plain (unstyled) phrase rather than crash.
                    let highlighted = (try? AttributedString(markdown: "**\(card.highlightedPhrase)**"))
                        ?? AttributedString(card.highlightedPhrase)
                    var combined = prefix
                    combined += highlighted

                    return Text(combined)
                        .font(AppFonts.cardTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineSpacing(6)
                }
            } else {
                Text(card.question)
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .font(AppFonts.cardTitle)
        .lineSpacing(6)
    }

    // MARK: - Actions

    private func flipCard() {
        withAnimation(
            AppAnimation.spring
        ) {
            isFlipped = true
        }
    }

    private func handlePillSelection(_ pill: CardRevealPill) {
        withAnimation(AppAnimation.spring) {
            selectedPill = pill
        }
        onPillSelected?(pill)

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            withAnimation(AppAnimation.enter) {
                showEncouragement = true
            }
            try? await Task.sleep(for: .milliseconds(700))
            onContinue?()
        }
    }
}

// MARK: - Convenience Initializer (stub — pending Card integration)

extension ConversationCard {
    /// Convenience initializer for Card usage.
    /// STUB: content mapping will be updated when ConversationCardContent adopts Card.
    init(
        card: Card,
        onDismiss: (() -> Void)? = nil
    ) {
        self.init(
            content: .prompt(card.text),
            fuseConfig: .none,
            ghostDeckMode: .none,
            onPillSelected: nil,
            onContinue: onDismiss
        )
    }
}

// MARK: - Previews

#Preview("Onboarding Card — Full Flow") {
    let obCard = OBCard(
        overline: "YOUR FIRST CARD",
        question: "What would you desire if nobody (not even you) would judge the answer?",
        highlightedPhrase: "(not even you)",
        backFace: .pills(CardRevealPill.allCases)
    )
    
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        
        VStack {
            Spacer()
            ConversationCard(
                content: .onboarding(obCard),
                fuseConfig: .countdown(duration: 12.0, onComplete: { }),
                ghostDeckMode: .atmospheric,
                onPillSelected: { _ in },
                onContinue: { }
            )
            Spacer()
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("Prompt Card — Convenience Init") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()

        VStack {
            Spacer()
            ConversationCard(
                content: .prompt("What's one thing you've never told anyone?"),
                fuseConfig: .none,
                ghostDeckMode: .none,
                onPillSelected: nil,
                onContinue: { }
            )
            Spacer()
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
