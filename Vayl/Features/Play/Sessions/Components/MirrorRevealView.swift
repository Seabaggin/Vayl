//
//  MirrorRevealView.swift
//  Vayl
//
//  Mirror reveal: A answers about themself, B guesses A's answer → both seal
//  → gap reveal (answer beside guess, no scoring, no verdict — the couple
//  reads the gap themselves). Thin skin over RevealEngine.
//

import SwiftUI

struct MirrorRevealView: View {

    @Bindable var store: CoupleSessionStore
    let recomposing: Bool

    @State private var draft: String = ""
    @FocusState private var focused: Bool

    private var engine: RevealEngine { store.revealEngine }
    /// The subject alternates per mirror card (store derives it from the card
    /// index, so both devices agree); the other partner guesses.
    private var isSubject: Bool { store.mirrorSubjectIsMe }

    var body: some View {
        RevealCardChrome(intensity: engine.phase == .revealed ? 0.8 : 0.5) {
            VStack(spacing: AppSpacing.lg) {
                switch engine.phase {
                case .composing, .sealedMine:
                    composer
                case .bothSealed:
                    Text("both sealed")
                        .font(AppFonts.cardTitle)
                        .foregroundStyle(AppColors.spectrumText)
                case .countdown(let n):
                    Text("\(n)")
                        .font(AppFonts.displayHero)
                        .foregroundStyle(AppColors.spectrumText)
                case .revealed:
                    revealedGap
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(roleLine)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)

            TextField(isSubject ? "your answer" : "your guess",
                      text: $draft, axis: .vertical)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
                .lineLimit(3, reservesSpace: true)
                .focused($focused)
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(AppColors.inputBackground)
                )
                .disabled(engine.phase != .composing)
                .screenshotProtected()

            HStack {
                if engine.phase == .sealedMine {
                    Text("sealed, waiting on them")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    engine.seal(.text(draft.trimmingCharacters(in: .whitespacesAndNewlines)))
                    focused = false
                } label: {
                    Text(engine.phase == .sealedMine ? "sealed" : "seal")
                        .font(AppFonts.buttonLabel)
                        .foregroundStyle(AppColors.void)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.sm)
                        .background(Capsule().fill(AppColors.spectrumBorder))
                }
                .buttonStyle(.plain)
                .scaleEffect(engine.phase == .sealedMine ? 0.96 : 1.0)
                .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty
                          || engine.phase != .composing)
            }
        }
    }

    private var roleLine: String {
        if recomposing { return "that one got lost in the air, type it again" }
        return isSubject
            ? "answer for yourself, they are guessing what you will say"
            : "guess what they will say, they are answering for real"
    }

    /// Answer beside guess. Subject's real answer always renders first.
    private var revealedGap: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            gapBlock(
                label: isSubject ? "what you said" : "what they said",
                text: isSubject ? myText : partnerText,
                tint: AppColors.spectrumMagenta
            )
            gapBlock(
                label: isSubject ? "what they guessed" : "what you guessed",
                text: isSubject ? partnerText : myText,
                tint: AppColors.spectrumCyan
            )
        }
        .transition(.opacity)
    }

    private var myText: String {
        if case .text(let t)? = engine.myEnvelope?.body { return t }
        return ""
    }
    private var partnerText: String {
        if case .text(let t)? = engine.partnerEnvelope?.body { return t }
        return "…"
    }

    private func gapBlock(label: String, text: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label)
                .font(AppFonts.overline)
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(tint)
            Text(text)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColors.cardBackground)
        )
    }
}
