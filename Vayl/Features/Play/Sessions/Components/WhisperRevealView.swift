//
//  WhisperRevealView.swift
//  Vayl
//
//  Whisper reveal: private text → seal → 3-2-1 → side-by-side, color-coded.
//  whatIf is the same mechanic with different framing copy (spec §4.3).
//  Thin skin over RevealEngine — no wire access, no persistence. The compose
//  field is screenshot-protected; answers exist only in engine memory.
//

import SwiftUI

struct WhisperRevealView: View {

    @Bindable var store: CoupleSessionStore
    /// True when the card is a whatIf (framing changes, mechanic identical).
    let isWhatIf: Bool
    /// True when a reconnect re-prompted compose (restore → .recompose).
    let recomposing: Bool

    @State private var draft: String = ""
    @FocusState private var focused: Bool

    private var engine: RevealEngine { store.revealEngine }

    var body: some View {
        RevealCardChrome(intensity: chromeIntensity) {
            VStack(spacing: AppSpacing.lg) {
                switch engine.phase {
                case .composing, .sealedMine:
                    composer
                case .bothSealed:
                    waitingBeat
                case .countdown(let n):
                    countdownFace(n)
                case .revealed:
                    revealedFace
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var chromeIntensity: Double {
        switch engine.phase {
        case .composing:  return 0.3
        case .sealedMine: return 0.5
        case .bothSealed: return 0.7
        case .countdown:  return 1.0
        case .revealed:   return 0.8
        }
    }

    // MARK: - Compose

    private var composer: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(framingLine)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)

            TextField(isWhatIf ? "what if…" : "type it, then seal", text: $draft, axis: .vertical)
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

            sealRow
        }
    }

    private var framingLine: String {
        if recomposing {
            return "that one got lost in the air, type it again"
        }
        return isWhatIf
            ? "answer the what-if honestly, private until you both seal"
            : "just for this reveal, private until you both seal"
    }

    private var sealRow: some View {
        HStack {
            if engine.partnerSealed, engine.phase == .composing {
                Text("they sealed, waiting on you")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.spectrumCyan)
            } else if engine.phase == .sealedMine {
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

    // MARK: - Waiting / countdown / reveal

    private var waitingBeat: some View {
        Text("both sealed")
            .font(AppFonts.cardTitle)
            .foregroundStyle(AppColors.spectrumText)
    }

    private func countdownFace(_ n: Int) -> some View {
        Text("\(n)")
            .font(AppFonts.displayHero)
            .foregroundStyle(AppColors.spectrumText)
            .contentTransition(.numericText(countsDown: true))
            .animation(AppAnimation.standard, value: n)
    }

    private var revealedFace: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            answerBlock("you", myText, tint: AppColors.spectrumMagenta)
            answerBlock("them", partnerText, tint: AppColors.spectrumCyan)
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

    private func answerBlock(_ who: String, _ text: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(who)
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
