// Design/Components/Navigation/VaylSheet.swift

import SwiftUI

/// The Vayl sheet surface — the single chrome behind every Vayl sheet.
/// Full-bleed width, continuous (squircle) rounded TOP corners, presented over
/// content. The single accent is a spectrum border that TRACES the rounded top
/// edge and dissolves down the sides — not a flat hairline cutting across below
/// the corners. One source of truth + one knob (AppRadius.sheet) to match the
/// system corner.
///
/// Two ways in:
///   • `.vaylSheet(isPresented:)` (VaylPresentation.swift) — the standard route;
///     applies this chrome + a spaced grabber automatically.
///   • `.vaylSheetChrome(widen:)` — the raw chrome, for OB phases that present
///     their own way (FounderLetterSheet, CredentialEditorSheet, PaywallSheet).
private struct VaylSheetChrome: ViewModifier {

    /// Extra push-out (per side) for a sheet whose layout bounds sit INSIDE the
    /// physical screen edge. The confirmation overlay is hosted high in the tree
    /// and reaches the edge (widen 0); the founder letter is hosted deep
    /// (PhaseOverlayView → switch) and lands a few points narrow, so it pushes
    /// both fill AND border out by this much to reach the edge. The border moves
    /// with it (toward the edge, still on-screen) rather than being left inset.
    var widen: CGFloat = 0

    /// How much brand signature the top edge carries. `.hairline` (default) is a
    /// neutral separator — the workhorse look, one accent (the grabber) per sheet,
    /// content reads first. `.full` restores the spectrum top-edge border, reserved
    /// for ceremonial sheets (the paywall) where the hero treatment earns its keep.
    var signature: VaylSheetSignature = .hairline

    // The fill always bleeds a base 2pt so the dark surface reaches the edge.
    private var fillBleed: CGFloat { 2 + widen }

    /// Spectrum-purple wash composited over the (muted gray) modalBackground so
    /// the sheet reads richer/warmer. Tune here — affects both OB sheets.
    private let purpleTint: Double = 0.13
    /// Black wash to lower the overall tone (the tint alone read too bright).
    /// Step this up gradually — small increments so it doesn't go too dark.
    private let darken: Double = 0.18

    /// The top-edge stroke fill: spectrum gradient for `.full`, a neutral hairline
    /// for `.hairline`. Same tracing geometry either way — only the fill differs.
    private var edgeStyle: AnyShapeStyle {
        switch signature {
        case .full:
            return AnyShapeStyle(LinearGradient(
                colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                startPoint: .leading, endPoint: .trailing
            ))
        case .hairline:
            return AnyShapeStyle(AppColors.borderDefault)
        }
    }

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
            // Top-edge stroke wrapping the rounded corner, then easing off down
            // the sides with a soft tail (no abrupt cutoff). Spectrum for `.full`,
            // a neutral hairline for `.hairline` — same geometry, different fill.
            .overlay(alignment: .top) {
                surface
                .strokeBorder(edgeStyle, lineWidth: signature == .full ? 1.0 : 0.75)
                // Match the fill's bleed so the stroke lands at the physical edge
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

/// How much brand signature a sheet's top edge carries.
enum VaylSheetSignature {
    /// Neutral hairline separator — the workhorse default. One brand accent per
    /// sheet (the grabber); the content reads first.
    case hairline
    /// Spectrum top-edge border — reserved for ceremonial sheets (the paywall),
    /// where the hero treatment is the point rather than noise.
    case full
}

extension View {
    /// Native-style sheet chrome — full-bleed width, continuous rounded top
    /// corners, and a top-edge stroke that is a neutral hairline by default
    /// (`.hairline`) or the spectrum border for ceremony (`.full`). See VaylSheetChrome.
    /// `widen`: extra push-out per side for sheets whose bounds sit inset from
    /// the physical edge (e.g. the founder letter, hosted deep in the tree).
    func vaylSheetChrome(widen: CGFloat = 0, signature: VaylSheetSignature = .hairline) -> some View {
        modifier(VaylSheetChrome(widen: widen, signature: signature))
    }
}

// MARK: - Preview gallery
//
// Every VaylSheet instance in the app, in one canvas, rendered through the real
// VaylSheetChrome + spectrum pull-tab so the surface, top border, and tab read
// together. The bodies are REPRESENTATIVE — the real ones live in their feature
// views (private) and can't be reached from here; these mirror each sheet's
// identity closely enough to review the chrome. Scroll the canvas horizontally.

#if DEBUG
private struct VaylSheetSpecimen<C: View>: View {
    let label: String
    var fraction: CGFloat = 0.6
    @ViewBuilder var content: () -> C

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
            ZStack(alignment: .bottom) {
                AppColors.void
                VStack(spacing: 0) {
                    Capsule()
                        .fill(AppColors.spectrumBorder)
                        .frame(width: 40, height: 4)
                        .opacity(0.6)
                        .padding(.vertical, AppSpacing.sm)
                    content()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 580 * fraction)
                .vaylSheetChrome()
            }
            .frame(width: 320, height: 580)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sheet, style: .continuous))
        }
    }
}

private func specimenChip(_ t: String, on: Bool) -> some View {
    Text(t)
        .font(AppFonts.caption)
        .foregroundStyle(on ? AppColors.void : AppColors.textBody)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(Capsule().fill(on ? AnyShapeStyle(AppColors.spectrumBorder)
                                       : AnyShapeStyle(AppColors.inputBackground)))
        .overlay(Capsule().strokeBorder(AppColors.borderDefault, lineWidth: on ? 0 : 1))
}

private func specimenCTA(_ t: String) -> some View {
    Text(t)
        .font(AppFonts.buttonLabel)
        .foregroundStyle(AppColors.void)
        .padding(.vertical, AppSpacing.md)
        .padding(.horizontal, AppSpacing.lg)
        .background(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
            .fill(AppColors.spectrumBorder))
}

private func specimenRow(_ glyph: String, _ title: String) -> some View {
    HStack(spacing: AppSpacing.md) {
        Text(glyph).frame(width: 22)
        Text(title).font(AppFonts.bodyText).foregroundStyle(AppColors.textBody)
        Spacer()
    }
    .padding(.vertical, AppSpacing.sm)
}

private func specimenStep(_ n: Int) -> some View {
    Text("\(n)")
        .font(AppFonts.buttonLabelSmall)
        .foregroundStyle(AppColors.textBody)
        .frame(width: 28, height: 28)
        .overlay(Circle().strokeBorder(AppColors.borderDefault, lineWidth: 1))
}

#Preview("VaylSheet — all instances") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .top, spacing: AppSpacing.lg) {

            // ── Session: close · reflection (.vaylSheet) ──
            VaylSheetSpecimen(label: "Close · reflection", fraction: 0.66) {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("How was that, for you?")
                        .font(AppFonts.sectionHeading).foregroundStyle(AppColors.textPrimary)
                    Text("just for you · swipe down to skip")
                        .font(AppFonts.caption).foregroundStyle(AppColors.textTertiary)
                    HStack(spacing: AppSpacing.sm) {
                        specimenChip("close", on: true)
                        specimenChip("seen", on: false)
                        specimenChip("warm", on: false)
                    }
                    Spacer(minLength: 0)
                    HStack {
                        Text("Skip").font(AppFonts.buttonLabel).foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        specimenCTA("Save")
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.xs)
                .padding(.bottom, AppSpacing.lg)
            }

            // ── Session: player · care (.vaylSheet) ──
            VaylSheetSpecimen(label: "Player · care", fraction: 0.5) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("if you need a beat")
                        .font(AppFonts.overline).tracking(2).textCase(.uppercase)
                        .foregroundStyle(AppColors.textTertiary)
                        .padding(.bottom, AppSpacing.sm)
                    specimenRow("❚❚", "Pause")
                    specimenRow("🤍", "A 6-second hug")
                    specimenRow("✦", "Say one thing you love")
                    specimenRow("⤼", "Skip this card")
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
            }

            // ── Session: airlock · sync tutorial (.vaylSheet) ──
            VaylSheetSpecimen(label: "Airlock · sync", fraction: 0.55) {
                VStack(spacing: AppSpacing.md) {
                    Text("Syncing to begin")
                        .font(AppFonts.sectionHeading).foregroundStyle(AppColors.textPrimary)
                    Text("A shared breath, on both phones at once.")
                        .font(AppFonts.caption).foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                    HStack(spacing: AppSpacing.md) {
                        specimenStep(1); specimenStep(2); specimenStep(3)
                    }
                }
                .padding(AppSpacing.lg)
            }

            // ── OB: founder letter (.vaylSheetChrome) ──
            VaylSheetSpecimen(label: "OB · founder letter", fraction: 0.6) {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Before you go.")
                        .font(AppFonts.sectionHeading).foregroundStyle(AppColors.textPrimary)
                    Text("A note from the people who made this for you.")
                        .font(AppFonts.founderLetter(13)).foregroundStyle(AppColors.textBody)
                }
                .padding(AppSpacing.lg)
            }

            // ── OB: credential editor (.vaylSheetChrome) ──
            VaylSheetSpecimen(label: "OB · credential editor", fraction: 0.5) {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("EDIT").font(AppFonts.overline).foregroundStyle(AppColors.textTertiary)
                    Text("Your name").font(AppFonts.sectionHeading).foregroundStyle(AppColors.textPrimary)
                    SpectrumHairline()
                    Spacer(minLength: 0)
                    specimenCTA("Done").frame(maxWidth: .infinity)
                }
                .padding(AppSpacing.lg)
            }

            // ── Monetization: paywall (.vaylSheetChrome) ──
            VaylSheetSpecimen(label: "Paywall", fraction: 0.6) {
                VStack(spacing: AppSpacing.md) {
                    Text("See your Desire Map")
                        .font(AppFonts.sectionHeading).foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Unlock everything, once.")
                        .font(AppFonts.caption).foregroundStyle(AppColors.textSecondary)
                    Spacer(minLength: 0)
                    specimenCTA("Unlock · $24.99").frame(maxWidth: .infinity)
                }
                .padding(AppSpacing.lg)
            }
        }
        .padding(AppSpacing.xl)
    }
    .background(Color.black)
    .preferredColorScheme(.dark)
}
#endif
