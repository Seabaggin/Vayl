//
//  SnapshotCardFace.swift
//  Vayl
//
//  Design/Components/Cards/CardFaces/SnapshotCardFace.swift
//
//  DemoPhase snapshot card face — renders "I [verb] [noun]." as a sentence
//  completion. Display only: the verb drum and noun field are gesture overlays
//  the phase owns (compassSlider precedent). Used live during DemoPhase and
//  statically (sealed) in ConfirmationPhase's review fan.
//

import SwiftUI

struct SnapshotCardFace: View {

    let cardWidth:    CGFloat
    let cardHeight:   CGFloat
    let verb:         DemoVerb
    let noun:         String
    let toneProgress: Double   // 0 cool (need) → 1 warm (desire)
    let sealProgress: Double   // 0 composing → 1 sealed

    /// Tone tint: need = cool cyan, want = neutral purple, desire = warm magenta.
    /// SwiftUI interpolates the gradient color when the phase animates the change.
    private var toneColor: Color {
        switch toneProgress {
        case ..<0.34: return AppColors.spectrumCyan
        case ..<0.67: return AppColors.spectrumPurple
        default:      return AppColors.spectrumMagenta
        }
    }

    private var sentenceSize: CGFloat { min(cardWidth * 0.13, 32) }

    var body: some View {
        ZStack {
            // Tone wash — a soft bloom that warms/cools with the verb.
            RadialGradient(
                colors: [toneColor.opacity(0.18), .clear],
                center: .center,
                startRadius: 0,
                endRadius: cardWidth * 0.72
            )
            .animation(AppAnimation.standard, value: toneProgress)

            VStack(spacing: cardHeight * 0.05) {
                // Line 1 — "I want": "I" regular, verb white + extra-bold with a
                // thin spectrum underline.
                HStack(spacing: cardWidth * 0.03) {
                    Text("I")
                        .font(AppFonts.display(sentenceSize, weight: .medium, relativeTo: .title))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(verb.rawValue)
                        .font(AppFonts.display(sentenceSize, weight: .bold, relativeTo: .title))
                        .foregroundStyle(.white)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(AppColors.spectrumBorder)
                                .frame(height: 1.5)
                                .opacity(0.45)
                                .offset(y: 3)
                        }
                }
                // Line 2 — the word, living spectrum text.
                if noun.isEmpty {
                    Text(" ")
                        .font(AppFonts.display(sentenceSize, weight: .semibold, relativeTo: .title))
                } else {
                    LivingText(text: noun,
                               font: AppFonts.display(sentenceSize, weight: .semibold, relativeTo: .title))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .frame(width: cardWidth, height: cardHeight)
        .allowsHitTesting(false)
    }
}
