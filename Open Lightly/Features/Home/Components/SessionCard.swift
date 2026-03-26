// Home/Components/SessionCard.swift

import SwiftUI

struct SessionCard: View {
    let state: SessionCardState
    var onContinue: (() -> Void)? = nil
    var onRemindPartner: (() -> Void)? = nil
    var onGoToLearn: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch state {
            case .dayZero:
                dayZeroContent
            case .midDeck(let completed, let total, let prompt):
                midDeckContent(completed: completed,
                               total: total,
                               prompt: prompt)
            case .deckComplete(let stageName, let stageIndex,
                               let nextName, let nextCards):
                deckCompleteContent(stageName: stageName,
                                    stageIndex: stageIndex,
                                    nextStageName: nextName,
                                    nextStageCards: nextCards)
            case .waitingOnPartner(let name, let completed, let total):
                waitingContent(partnerName: name,
                               completed: completed,
                               total: total)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .light
                    ? AppColors.lightCardFill
                    : AppColors.cardBg)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    colorScheme == .light
                        ? AnyShapeStyle(
                            AppColors.warmAuroraBorder.opacity(0.5))
                        : AnyShapeStyle(LinearGradient(
                            colors: [
                                AppColors.cyan.opacity(0.4),
                                AppColors.purple.opacity(0.3),
                                AppColors.magenta.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )),
                    lineWidth: 1.5
                )
        }
        .shadow(
            color: colorScheme == .light
                ? AppColors.lightShadowPurple
                : AppColors.purple.opacity(0.12),
            radius: 20, y: 6
        )
    }

    // MARK: - Day Zero

    private var dayZeroContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeader(overline: "STAGE 1 · CURIOSITY",
                       stageName: "Curiosity")
                .padding(.horizontal, 20)
                .padding(.top, 20)

            Spacer(minLength: 16)

            promptPreview(
                label: "FIRST PROMPT",
                text: "What's one thing about non-monogamy that excites you most? Just one."
            )

            Spacer(minLength: 16)

            ctaButton(label: "Start Your First Session",
                      action: onContinue)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
        }
    }

    // MARK: - Mid Deck

    private func midDeckContent(completed: Int,
                                 total: Int,
                                 prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                cardHeader(overline: "STAGE 1 · CURIOSITY",
                           stageName: "Foundation Conversations")

                // Progress bar
                HStack(spacing: 10) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(colorScheme == .light
                                    ? Color.black.opacity(0.08)
                                    : Color.white.opacity(0.12))
                                .frame(height: 3)

                            let ratio = total > 0
                                ? CGFloat(completed) / CGFloat(total)
                                : 0

                            Capsule()
                                .fill(colorScheme == .light
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.magenta,
                                                 AppColors.gold],
                                        startPoint: .leading,
                                        endPoint: .trailing))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.cyan,
                                                 AppColors.purple,
                                                 AppColors.magenta],
                                        startPoint: .leading,
                                        endPoint: .trailing)))
                                .frame(width: geo.size.width * ratio,
                                       height: 3)
                                .animation(.easeInOut(duration: 0.6),
                                           value: completed)
                        }
                    }
                    .frame(height: 3)

                    Text("\(completed) of \(total)")
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                        .fixedSize()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Spacer(minLength: 16)

            promptPreview(label: "NEXT PROMPT", text: prompt)

            Spacer(minLength: 16)

            ctaButton(label: "Continue Session",
                      action: onContinue)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
        }
    }

    // MARK: - Deck Complete

    private func deckCompleteContent(stageName: String,
                                      stageIndex: Int,
                                      nextStageName: String,
                                      nextStageCards: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Completion header
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(colorScheme == .light
                        ? AnyShapeStyle(LinearGradient(
                            colors: [AppColors.magenta, AppColors.gold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan, AppColors.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing)))

                Text("STAGE \(stageIndex) COMPLETE")
                    .font(AppFonts.overline)
                    .tracking(1.5)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Text("You finished \(stageName).")
                .font(AppFonts.bodyMedium)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextPrimary
                    : AppColors.textPrimary)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            // Divider
            Rectangle()
                .fill(colorScheme == .light
                    ? Color.black.opacity(0.06)
                    : Color.white.opacity(0.06))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

            // Next stage
            VStack(alignment: .leading, spacing: 6) {
                Text("STAGE \(stageIndex + 1) · \(nextStageName.uppercased())")
                    .font(AppFonts.overline)
                    .tracking(1.5)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)

                Text(nextStageName)
                    .font(AppFonts.cardTitle)
                    .foregroundStyle(colorScheme == .light
                        ? AnyShapeStyle(LinearGradient(
                            colors: [AppColors.magenta, AppColors.gold],
                            startPoint: .leading,
                            endPoint: .trailing))
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan, AppColors.purple],
                            startPoint: .leading,
                            endPoint: .trailing)))

                Text("\(nextStageCards) cards · When you're ready")
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 16)

            ctaButton(label: "Start Stage \(stageIndex + 1)",
                      action: onContinue)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
        }
    }

    // MARK: - Waiting on Partner

    private func waitingContent(partnerName: String,
                                 completed: Int,
                                 total: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                cardHeader(overline: "STAGE 1 · CURIOSITY",
                           stageName: "Foundation Conversations")

                // Progress bar
                HStack(spacing: 10) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(colorScheme == .light
                                    ? Color.black.opacity(0.08)
                                    : Color.white.opacity(0.12))
                                .frame(height: 3)

                            let ratio = total > 0
                                ? CGFloat(completed) / CGFloat(total)
                                : 0

                            Capsule()
                                .fill(colorScheme == .light
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.magenta,
                                                 AppColors.gold],
                                        startPoint: .leading,
                                        endPoint: .trailing))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.cyan,
                                                 AppColors.purple,
                                                 AppColors.magenta],
                                        startPoint: .leading,
                                        endPoint: .trailing)))
                                .frame(width: geo.size.width * ratio,
                                       height: 3)
                        }
                    }
                    .frame(height: 3)

                    Text("\(completed) of \(total)")
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                        .fixedSize()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Text("\(partnerName) isn't ready yet")
                .font(AppFonts.bodyText)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextSecondary
                    : AppColors.textSecondary)
                .padding(.horizontal, 20)
                .padding(.top, 12)

            Spacer(minLength: 16)

            // Two CTAs
            HStack(spacing: 10) {
                // Outlined remind button
                Button {
                    UIImpactFeedbackGenerator(style: .light)
                        .impactOccurred()
                    onRemindPartner?()
                } label: {
                    Text("Remind \(partnerName)")
                        .font(AppFonts.ctaLabel)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextSecondary
                            : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(colorScheme == .light
                                    ? AppColors.lightBorder
                                    : AppColors.border,
                                    lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)

                // Filled learn button
                Button {
                    UIImpactFeedbackGenerator(style: .medium)
                        .impactOccurred()
                    onGoToLearn?()
                } label: {
                    Text("Go to Learn")
                        .font(AppFonts.ctaLabel)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.wineDark
                            : AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .light
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.magenta.opacity(0.12),
                                                 AppColors.gold.opacity(0.10)],
                                        startPoint: .leading,
                                        endPoint: .trailing))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.cyan.opacity(0.2),
                                                 AppColors.purple.opacity(0.15)],
                                        startPoint: .leading,
                                        endPoint: .trailing)))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(colorScheme == .light
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.magenta,
                                                 AppColors.gold],
                                        startPoint: .leading,
                                        endPoint: .trailing))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.cyan,
                                                 AppColors.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing)),
                                    lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Shared Subviews

    private func cardHeader(overline: String,
                             stageName: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(overline)
                .font(AppFonts.overline)
                .tracking(1.5)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextTertiary
                    : AppColors.textTertiary)

            Text(stageName)
                .font(AppFonts.cardTitle)
                .foregroundStyle(colorScheme == .light
                    ? AnyShapeStyle(LinearGradient(
                        colors: [AppColors.magenta, AppColors.gold],
                        startPoint: .leading,
                        endPoint: .trailing))
                    : AnyShapeStyle(LinearGradient(
                        colors: [AppColors.cyan, AppColors.purple],
                        startPoint: .leading,
                        endPoint: .trailing)))
        }
    }

    private func promptPreview(label: String,
                                text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(AppFonts.overline)
                .tracking(1.5)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextTertiary
                    : AppColors.textTertiary)
                .padding(.horizontal, 20)

            Text("\"\(text)\"")
                .font(AppFonts.bodyMedium)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextSecondary
                    : AppColors.textSecondary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorScheme == .light
                            ? Color.black.opacity(0.03)
                            : Color.white.opacity(0.04))
                }
                .padding(.horizontal, 16)
        }
    }

    private func ctaButton(label: String,
                            action: (() -> Void)?) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action?()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text(label)
                    .font(AppFonts.ctaLabel)
            }
            .foregroundStyle(colorScheme == .light
                ? AppColors.wineDark
                : AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(colorScheme == .light
                        ? AnyShapeStyle(AppColors.lightFrostCTA)
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan.opacity(0.15),
                                     AppColors.purple.opacity(0.12)],
                            startPoint: .leading,
                            endPoint: .trailing)))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(colorScheme == .light
                        ? AnyShapeStyle(LinearGradient(
                            colors: [AppColors.magenta,
                                     AppColors.gold],
                            startPoint: .leading,
                            endPoint: .trailing))
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan,
                                     AppColors.purple,
                                     AppColors.magenta],
                            startPoint: .leading,
                            endPoint: .trailing)),
                        lineWidth: 1.5)
            }
            .shadow(color: colorScheme == .light
                ? AppColors.lightShadowMagenta
                : AppColors.cyan.opacity(0.15),
                    radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }
}
