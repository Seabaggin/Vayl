//
//  LiftHalo.swift
//  Vayl
//

import SwiftUI

/// The spectrum focus ring shown around a *lifted* OB card.
///
/// One source of truth for the tap-to-lift affordance. NamePhase teaches the
/// "pick it up → slide it up to me" grammar on the user's first card; every
/// selection phase (ModeSelect, ExperienceLevel, …) reuses the identical ring so
/// the lesson transfers by sight. Previously this was duplicated inline in each
/// phase — keep it here, applied as an `.overlay(LiftHalo(visible:))`, so the
/// lifted-card look can never drift between phases.
///
/// Hit-testing is disabled — the card beneath owns the gesture.
struct LiftHalo: View {
    let visible: Bool

    private var spectrum: LinearGradient {
        LinearGradient(
            colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            // Halo — blurred spectrum stroke, outward bleed only.
            RoundedRectangle(cornerRadius: AppRadius.obCard)
                .stroke(spectrum, lineWidth: AppGlows.spectrumBorder.strokeActive)
                .blur(radius: 7)
                .opacity(visible ? 0.50 : 0)

            // Crisp border stroke with the layered spectrum glow.
            RoundedRectangle(cornerRadius: AppRadius.obCard)
                .stroke(spectrum, lineWidth: AppGlows.spectrumBorder.strokeGlowing)
                .opacity(visible ? 0.92 : 0)
                .spectrumBorderGlow(intensity: visible ? 0.72 : 0)
        }
        .animation(AppAnimation.standard, value: visible)
        .allowsHitTesting(false)
    }
}
