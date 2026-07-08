//
//  UnspokenSliderView.swift
//  Vayl
//
//  Unspoken reveal: each partner privately places a slider on the card's
//  spectrum → seal → both positions land on ONE spectrum bar. Thin skin over
//  RevealEngine; the position payload is a Double 0…1 in the envelope body.
//

import SwiftUI

struct UnspokenSliderView: View {

    @Bindable var store: CoupleSessionStore
    let recomposing: Bool

    @State private var position: Double = 0.5

    private var engine: RevealEngine { store.revealEngine }

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
                    revealedSpectrum
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var composer: some View {
        VStack(spacing: AppSpacing.md) {
            Text(recomposing
                 ? "that one got lost in the air, place it again"
                 : "place yourself, private until you both seal")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)

            Slider(value: $position, in: 0...1)
                .tint(AppColors.accentPrimary)
                .disabled(engine.phase != .composing)
                .screenshotProtected()

            Button {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                engine.seal(.position(position))
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
            .disabled(engine.phase != .composing)

            if engine.phase == .sealedMine {
                Text("sealed, waiting on them")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    /// Both positions on one spectrum: a spectrum bar, a magenta dot (you),
    /// a cyan dot (them).
    private var revealedSpectrum: some View {
        VStack(spacing: AppSpacing.md) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.spectrumBorder)
                        .frame(height: AppSpacing.xs)
                        .frame(maxHeight: .infinity, alignment: .center)
                    dot(AppColors.spectrumMagenta)
                        .offset(x: geo.size.width * myPosition - AppSpacing.sm)
                    dot(AppColors.spectrumCyan)
                        .offset(x: geo.size.width * partnerPosition - AppSpacing.sm)
                }
            }
            .frame(height: AppSpacing.xl)

            HStack {
                legend("you", tint: AppColors.spectrumMagenta)
                Spacer()
                legend("them", tint: AppColors.spectrumCyan)
            }
        }
        .transition(.opacity)
    }

    private var myPosition: Double {
        if case .position(let p)? = engine.myEnvelope?.body { return p }
        return 0.5
    }
    private var partnerPosition: Double {
        if case .position(let p)? = engine.partnerEnvelope?.body { return p }
        return 0.5
    }

    private func dot(_ tint: Color) -> some View {
        Circle()
            .fill(tint)
            .frame(width: AppSpacing.md, height: AppSpacing.md)
            .frame(maxHeight: .infinity, alignment: .center)
    }

    private func legend(_ label: String, tint: Color) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Circle().fill(tint).frame(width: AppSpacing.sm, height: AppSpacing.sm)
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}
