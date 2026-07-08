//
//  SnapshotRevealView.swift
//  Vayl
//
//  Snapshot reveal: one word each, private → seal → the two words land
//  together. Thin skin over RevealEngine; the payload is the .word body.
//

import SwiftUI

struct SnapshotRevealView: View {

    @Bindable var store: CoupleSessionStore
    let recomposing: Bool

    @State private var word: String = ""
    @FocusState private var focused: Bool

    private var engine: RevealEngine { store.revealEngine }

    var body: some View {
        RevealCardChrome(intensity: engine.phase == .revealed ? 1.0 : 0.5) {
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
                    landedWords
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var composer: some View {
        VStack(spacing: AppSpacing.md) {
            Text(recomposing
                 ? "that one got lost in the air, one word again"
                 : "one word, private until you both seal")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)

            TextField("one word", text: $word)
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textBody)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focused)
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(AppColors.inputBackground)
                )
                .disabled(engine.phase != .composing)
                .screenshotProtected()
                .onChange(of: word) { _, new in
                    // Snapshot means ONE word — clamp at the first space.
                    if let space = new.firstIndex(of: " ") {
                        word = String(new[..<space])
                    }
                }

            Button {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                engine.seal(.word(word.trimmingCharacters(in: .whitespacesAndNewlines)))
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
            .disabled(word.trimmingCharacters(in: .whitespaces).isEmpty
                      || engine.phase != .composing)

            if engine.phase == .sealedMine {
                Text("sealed, waiting on them")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    /// The two words land together, side by side, color-coded.
    private var landedWords: some View {
        HStack(spacing: AppSpacing.xl) {
            landedWord(myWord, tint: AppColors.spectrumMagenta)
            landedWord(partnerWord, tint: AppColors.spectrumCyan)
        }
        .transition(.scale(scale: 0.8).combined(with: .opacity))
    }

    private var myWord: String {
        if case .word(let w)? = engine.myEnvelope?.body { return w }
        return ""
    }
    private var partnerWord: String {
        if case .word(let w)? = engine.partnerEnvelope?.body { return w }
        return "…"
    }

    private func landedWord(_ w: String, tint: Color) -> some View {
        Text(w)
            .font(AppFonts.display(28, weight: .medium, relativeTo: .title))
            .foregroundStyle(tint)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
    }
}
