// Design/Components/OBSheetChrome.swift

import SwiftUI

/// Shared chrome for the OB custom sheets (FounderLetterSheet, CredentialEditor).
/// Matches a native `.sheet`: full-bleed width, continuous (squircle) rounded
/// TOP corners, presented over content. The single accent is a spectrum border
/// that TRACES the rounded top edge and dissolves down the sides — not a flat
/// hairline cutting across below the corners.
///
/// One source of truth so both sheets read identically and there's one knob
/// (AppRadius.sheet) to match the system corner.
private struct OBSheetChrome: ViewModifier {

    /// Extra push-out (per side) for a sheet whose layout bounds sit INSIDE the
    /// physical screen edge. The confirmation overlay is hosted high in the tree
    /// and reaches the edge (widen 0); the founder letter is hosted deep
    /// (PhaseOverlayView → switch) and lands a few points narrow, so it pushes
    /// both fill AND border out by this much to reach the edge. The border moves
    /// with it (toward the edge, still on-screen) rather than being left inset.
    var widen: CGFloat = 0

    // The fill always bleeds a base 2pt so the dark surface reaches the edge.
    private var fillBleed: CGFloat { 2 + widen }

    /// Spectrum-purple wash composited over the (muted gray) modalBackground so
    /// the sheet reads richer/warmer. Tune here — affects both OB sheets.
    private let purpleTint: Double = 0.13
    /// Black wash to lower the overall tone (the tint alone read too bright).
    /// Step this up gradually — small increments so it doesn't go too dark.
    private let darken: Double = 0.18

    func body(content: Content) -> some View {
        let surface = UnevenRoundedRectangle(
            topLeadingRadius:  AppRadius.sheet,
            topTrailingRadius: AppRadius.sheet,
            style: .continuous
        )
        return content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(
                surface
                    .fill(AppColors.modalBackground)
                    // Purple tint over the muted base — gentle vertical falloff
                    // so the top of the sheet is the richest.
                    .overlay(
                        surface.fill(
                            LinearGradient(
                                colors: [
                                    AppColors.spectrumPurple.opacity(purpleTint),
                                    AppColors.spectrumPurple.opacity(purpleTint * 0.55),
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    )
                    // Tone-down wash over the tinted surface.
                    .overlay(surface.fill(Color.black.opacity(darken)))
                    .padding(.horizontal, -fillBleed)
                    .ignoresSafeArea(edges: .bottom)
            )
            // Spectrum border wrapping the rounded top corner, then easing off
            // down the sides with a soft tail (no abrupt cutoff).
            .overlay(alignment: .top) {
                surface
                .strokeBorder(
                    LinearGradient(
                        colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    lineWidth: 1.0
                )
                // Match the fill's bleed so the border lands at the physical edge
                // too — otherwise it traces 2pt inside and the sheet reads narrow.
                .padding(.horizontal, -fillBleed)
                .mask(
                    // Full across the rounded top, then an EASED tail down the
                    // sides — multiple stops curve the fade so it dissolves
                    // gently instead of ending abruptly.
                    LinearGradient(
                        stops: [
                            .init(color: .black,               location: 0.00),
                            .init(color: .black,               location: 0.06),
                            .init(color: .black.opacity(0.65), location: 0.13),
                            .init(color: .black.opacity(0.28), location: 0.20),
                            .init(color: .black.opacity(0.10), location: 0.27),
                            .init(color: .clear,               location: 0.36),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                // Taper the border horizontally as it goes off-screen so it
                // dissolves into the bezel instead of cutting off abruptly.
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.00),
                            .init(color: .black, location: 0.015), // taper in over the first 1.5%
                            .init(color: .black, location: 0.985), // taper out over the last 1.5%
                            .init(color: .clear, location: 1.00)
                        ],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .allowsHitTesting(false)
            }
            .modalElevation()
    }
}

extension View {
    /// Native-style sheet chrome — full-bleed width, continuous rounded top
    /// corners, spectrum top-edge border. See OBSheetChrome.
    /// `widen`: extra push-out per side for sheets whose bounds sit inset from
    /// the physical edge (e.g. the founder letter, hosted deep in the tree).
    func obSheetChrome(widen: CGFloat = 0) -> some View {
        modifier(OBSheetChrome(widen: widen))
    }
}
