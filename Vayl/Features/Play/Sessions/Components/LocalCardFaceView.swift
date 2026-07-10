//
//  LocalCardFaceView.swift
//  Vayl
//
//  Per-type face treatment for the LOCAL living cards (no sync, no reveal):
//  dare, greenLight, coolOff, bodyCheck, permissionCard, appreciationInterrupt,
//  openingRitual, closingRitual, pause. Rendered by the prompt engine in place
//  of the generic hero prompt. pause = a held-breath screen, no prompt at all.
//
//  Accent/icon/pacing per type; everything from tokens.
//

import SwiftUI

struct LocalCardFaceView: View {

    let card: Card

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var entered = false
    @State private var breathe = false

    var body: some View {
        Group {
            if card.type == .pause {
                pauseFace
            } else {
                typedFace
            }
        }
        .onAppear {
            withAnimation(reduceMotion ? AppAnimation.fast : face.enterAnimation) {
                entered = true
            }
            if !reduceMotion { breathe = true }
        }
        .onDisappear { entered = false }
    }

    // MARK: - Typed face

    private var typedFace: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: face.icon)
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(face.accent)
                Text(face.label)
                    .font(AppFonts.overline)
                    .tracking(3)
                    .textCase(.uppercase)
                    .foregroundStyle(face.accent)
            }
            .opacity(entered ? 1 : 0)

            Text(card.text)
                .font(AppFonts.display(26, weight: .medium, relativeTo: .title))
                .foregroundStyle(AppColors.textPrimary)
                .lineSpacing(AppSpacing.xs)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(entered ? 1 : 0)
                .offset(y: entered ? 0 : AppSpacing.sm)

            if let sub = face.subline {
                Text(sub)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .opacity(entered ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.xl)
    }

    // MARK: - Pause: the held breath

    private var pauseFace: some View {
        VStack(spacing: AppSpacing.lg) {
            Text("✦")
                .font(AppFonts.display(34, weight: .medium, relativeTo: .largeTitle))
                .foregroundStyle(AppColors.spectrumText)
                .scaleEffect(breathe ? 1.12 : 1.0)
                .ambientAnimation(
                    .easeInOut(duration: AppAnimation.ambientPulse).repeatForever(autoreverses: true),
                    value: breathe
                )
            Text("just breathe for a minute")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Per-type treatment

    private struct FaceTreatment {
        let label: String
        let icon: String
        let accent: Color
        let subline: String?
        let enterAnimation: Animation
    }

    private var face: FaceTreatment {
        switch card.type {
        case .dare:
            return .init(label: "Dare", icon: "flame",
                         accent: AppColors.spectrumMagenta,
                         subline: "do it now, together",
                         enterAnimation: AppAnimation.spring)
        case .greenLight:
            return .init(label: "Green light", icon: "arrowtriangle.forward.circle",
                         accent: AppColors.success,
                         subline: "one of you names a want, the other only says: tell me more",
                         enterAnimation: AppAnimation.enter)
        case .coolOff:
            return .init(label: "Cool off", icon: "wind",
                         accent: AppColors.spectrumCyan,
                         subline: "a pressure valve, take it slow",
                         enterAnimation: AppAnimation.slow)
        case .bodyCheck:
            return .init(label: "Body check", icon: "figure.mind.and.body",
                         accent: AppColors.spectrumPurple,
                         subline: "where does this conversation live in you right now",
                         enterAnimation: AppAnimation.slow)
        case .permissionCard:
            return .init(label: "Permission", icon: "checkmark.seal",
                         accent: AppColors.accentPrimary,
                         subline: "not a question, just read it to each other",
                         enterAnimation: AppAnimation.enter)
        case .appreciationInterrupt:
            return .init(label: "Appreciation", icon: "heart",
                         accent: AppColors.accentSecondary,
                         subline: "a reset, take it",
                         enterAnimation: AppAnimation.spring)
        case .openingRitual:
            return .init(label: "Opening", icon: "sparkle",
                         accent: AppColors.spectrumCyan,
                         subline: "the moment before card one",
                         enterAnimation: AppAnimation.slow)
        case .closingRitual:
            return .init(label: "Closing", icon: "moon.stars",
                         accent: AppColors.spectrumMagenta,
                         subline: "land it well",
                         enterAnimation: AppAnimation.slow)
        default:
            // pause is handled above; anything else falls back neutral.
            return .init(label: "Card", icon: "rectangle.portrait",
                         accent: AppColors.textSecondary,
                         subline: nil,
                         enterAnimation: AppAnimation.enter)
        }
    }
}

#Preview("Dare") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        LocalCardFaceView(card: Card(
            id: "preview-dare",
            deckId: "the-opener",
            text: "Hold eye contact for thirty seconds. No talking. No looking away.",
            highlightWords: ["eye contact"],
            type: .dare,
            intensity: .supernova,
            whoStarts: .both,
            isSensitive: false,
            canSkip: true,
            register: .excited,
            contextBeatType: nil,
            contextBeatCopy: nil,
            backCopy: nil,
            isGenderedCard: false,
            genderedFor: nil,
            sortOrder: 1
        ))
    }
    .preferredColorScheme(.dark)
}

#Preview("Pause") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        LocalCardFaceView(card: Card(
            id: "preview-pause",
            deckId: "the-opener",
            text: "",
            highlightWords: [],
            type: .pause,
            intensity: .deepOcean,
            whoStarts: .both,
            isSensitive: false,
            canSkip: false,
            register: .flexible,
            contextBeatType: nil,
            contextBeatCopy: nil,
            backCopy: nil,
            isGenderedCard: false,
            genderedFor: nil,
            sortOrder: 1
        ))
    }
    .preferredColorScheme(.dark)
}
