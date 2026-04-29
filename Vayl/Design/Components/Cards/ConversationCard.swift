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

    // MARK: - Callbacks

    var onPillSelected: ((CardRevealPill) -> Void)? = nil
    var onContinue: (() -> Void)? = nil

    // MARK: - Layout

    private let cardHeight: CGFloat = 420
    private let cornerRadius: CGFloat = 20
    private let lineWidth: CGFloat = 1.5

    private var cardWidth: CGFloat {
        ((UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first)?.screen.bounds.width ?? 390) - 48
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
            .scaleEffect(pulsing ? 1.02 : 1.0)
            .animation(
                pulsing
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
                .fill(AppColors.cardBg)

            // Ambient wash — subtle glow at bottom
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.purple.opacity(0.06),
                            AppColors.cyan.opacity(0.04),
                            .clear
                        ],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )

            // Content
            VStack(alignment: .leading, spacing: 24) {
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
            .padding(28)

            // Fuse timer — rendered over card, under content
            fuseOverlay

            // Border
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }

    // MARK: - Back Face

    private var backFace: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(AppColors.cardBg)

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.magenta.opacity(0.05),
                            AppColors.purple.opacity(0.04),
                            .clear
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )

            VStack(alignment: .leading, spacing: 20) {
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
            .padding(28)

            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }

    // MARK: - Pill Grid

    private func pillGrid(pills: [CardRevealPill]) -> some View {
        VStack(spacing: 12) {
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
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 100)
                        .fill(isSelected
                              ? AppColors.purple.opacity(0.15)
                              : Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 100)
                        .stroke(
                            isSelected
                                ? AnyShapeStyle(AppColors.spectrumBorder)
                                : AnyShapeStyle(Color.white.opacity(0.08)),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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
                    let highlighted = try! AttributedString(markdown: "**\(card.highlightedPhrase)**")
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
            .spring(response: 0.65, dampingFraction: 0.78)
        ) {
            isFlipped = true
        }
    }

    private func handlePillSelection(_ pill: CardRevealPill) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedPill = pill
        }
        onPillSelected?(pill)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.4)) {
                showEncouragement = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
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
        AppColors.pageBg.ignoresSafeArea()
        
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
        AppColors.pageBg.ignoresSafeArea()

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
