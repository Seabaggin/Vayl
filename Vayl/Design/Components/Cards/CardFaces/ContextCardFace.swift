// Design/Components/Cards/CardFaces/ContextCardFace.swift
//
// Content face for the relationship-context cards (ContextPhase carousel).
// Rendered by VaylCardFace when its content is `.context(...)`.
//
// Dark-only, spectrum language. All geometry is proportional to the card width
// (OB card-face rule — no fixed pixels). The face renders only the position
// number + title as a punchy headline; subtitle/detail are presented by
// ContextPhase in its bottom panel (subtitle live on swipe, detail on confirm),
// not on the card. The `subtitle`/`detail`/`isFront` props are retained only to
// keep the 4-param `.context` call site in VaylCardFace compiling.

import SwiftUI

struct ContextCardFace: View {

    let number:   String
    let title:    String
    let subtitle: String
    let detail:   String

    /// True when this card is the frontmost (centered) card in the stack.
    /// Drives detail reveal. Defaults true so the face reads fully in isolation/previews.
    var isFront: Bool = true

    var body: some View {
        GeometryReader { geo in
            let w   = geo.size.width
            let pad = w * 0.10

            VStack(alignment: .leading, spacing: w * 0.04) {
                Spacer(minLength: 0)

                // Position number — small spectrum overline
                Text(number)
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.spectrumText)
                    .opacity(0.55)

                // Title — the headline; fills the card
                Text(title)
                    .font(AppFonts.display(26, weight: .semibold, relativeTo: .title))
                    .foregroundStyle(AppColors.spectrumText)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(pad)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
        }
    }
}

// MARK: - Preview

#Preview("Context face — front") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VaylCardFace(
            content: .context(
                number:   "01",
                title:    "We've tried some things",
                subtitle: "Real experiences — good, bad, or somewhere in between",
                detail:   "We'll help you process what happened and decide what comes next."
            )
        )
        .frame(width: 300, height: 340)
    }
    .preferredColorScheme(.dark)
}
