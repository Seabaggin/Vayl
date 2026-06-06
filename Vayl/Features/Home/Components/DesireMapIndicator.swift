// Home/Components/DesireMapIndicator.swift

import SwiftUI

struct DesireMapIndicator: View {
    let state: DesireMapState
    var onReveal: (() -> Void)? = nil
    var onUnlock: (() -> Void)? = nil
    var onRemind: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        switch state {
        case .hidden, .fullyUnlocked:
            EmptyView()

        case .youDone(let partnerName):
            statusCard {
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("DESIRE MAP")
                            .font(AppFonts.overline)
                            .tracking(1.2)
                            .foregroundStyle(AppColors.textTertiary)

                        HStack(spacing: AppSpacing.md) {
                            HStack(spacing: AppSpacing.xs) {
                                Circle()
                                    .fill(colorScheme == .light
                                        ? AppColors.accentTertiary
                                        : AppColors.accentPrimary)
                                    .frame(width: 7, height: 7)
                                Text("You're done")
                                    .font(AppFonts.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            HStack(spacing: AppSpacing.xs) {
                                Circle()
                                    .stroke(AppColors.textTertiary, lineWidth: 1)
                                    .frame(width: 7, height: 7)
                                Text(partnerName)
                                    .font(AppFonts.caption)
                                    .foregroundStyle(AppColors.textTertiary)
                            }
                        }
                    }
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onRemind?()
                    } label: {
                        Text("Remind \(partnerName) →")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.accentTertiary
                                : AppColors.accentPrimary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.md)
            }

        case .bothReady:
            bothReadyCard

        case .freeRevealSeen(_):
            statusCard {
                HStack(spacing: AppSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .light
                                ? AppColors.accentTertiary.opacity(0.10)
                                : AppColors.accentSecondary.opacity(0.15))
                            .frame(width: 38, height: 38)
                        Image(systemName: AppIcons.heartTextSquare)
                            // .body scales with Dynamic Type — correct for
                            // icon badges at this visual weight.
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.accentTertiary, AppColors.safetyAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.accentSecondary, AppColors.accentTertiary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing)))
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("1 match revealed")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        Text("+ more waiting")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onUnlock?()
                    } label: {
                        Text("Unlock →")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.accentTertiary
                                : AppColors.accentPrimary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.md)
            }

        case .redoInProgress(let partnerName, let matchCount):
            redoInProgressCard(partnerName: partnerName, matchCount: matchCount)

        case .gated, .yourTurn, .waiting, .matchReady, .revealed:
            EmptyView()
        }
    }

    // MARK: - Case cards
    // Extracted from the `body` switch so each is type-checked in isolation
    // (the combined switch was 177ms).

    private var bothReadyCard: some View {
        // Elevated treatment — highest CTA weight on screen
        let buttonTextColor: Color = colorScheme == .light ? AppColors.textSecondary : .white
        let buttonFill: AnyShapeStyle = colorScheme == .light
            ? AnyShapeStyle(LinearGradient(
                colors: [AppColors.accentTertiary.opacity(0.18), AppColors.safetyAccent.opacity(0.14)],
                startPoint: .leading, endPoint: .trailing))
            : AnyShapeStyle(LinearGradient(
                colors: [AppColors.accentPrimary, AppColors.accentSecondary, AppColors.accentTertiary],
                startPoint: .leading, endPoint: .trailing))
        let buttonShadow: Color = colorScheme == .light ? AppColors.shadowMagenta : AppColors.accentSecondary.opacity(0.4)
        let cardBorder: AnyShapeStyle = colorScheme == .light
            ? AnyShapeStyle(AppColors.spectrumBorder.opacity(0.6))
            : AnyShapeStyle(LinearGradient(
                colors: [AppColors.accentPrimary.opacity(0.5), AppColors.accentSecondary.opacity(0.4), AppColors.accentTertiary.opacity(0.3)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
        let cardShadow: Color = colorScheme == .light ? AppColors.shadowPurple : AppColors.accentSecondary.opacity(0.2)

        return VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("DESIRE MAP")
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .foregroundStyle(AppColors.textTertiary)
                    Spacer()
                    Text("You're both ready")
                        .font(AppFonts.caption)
                        .foregroundStyle(accentEmphasis)
                }

                HStack(spacing: AppSpacing.md) {
                    HStack(spacing: AppSpacing.xs) {
                        Circle()
                            .fill(accentEmphasis)
                            .frame(width: 7, height: 7)
                        Text("You")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    HStack(spacing: AppSpacing.xs) {
                        Circle()
                            .fill(colorScheme == .light ? AppColors.safetyAccent : AppColors.accentSecondary)
                            .frame(width: 7, height: 7)
                        Text("Partner")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)

            Spacer(minLength: AppSpacing.md)

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onReveal?()
            } label: {
                Text("See Your First Match")
                    .font(AppFonts.ctaLabel)
                    .foregroundStyle(buttonTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: AppRadius.md).fill(buttonFill)
                    }
                    .shadow(color: buttonShadow, radius: 12, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.md)
        }
        .background {
            RoundedRectangle(cornerRadius: AppRadius.lg).fill(AppColors.cardBackground)
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.lg).stroke(cardBorder, lineWidth: 1.5)
        }
        .shadow(color: cardShadow, radius: 20, y: 6)
    }

    private func redoInProgressCard(partnerName: String, matchCount: Int) -> some View {
        let partnerStarted: Bool = matchCount != 0
        let partnerDotFill: Color = partnerStarted
            ? (colorScheme == .light ? AppColors.safetyAccent : AppColors.accentSecondary)
            : Color.clear
        let partnerLabel: String = partnerStarted ? "\(partnerName) in progress" : "\(partnerName) hasn't started"
        let partnerLabelColor: Color = partnerStarted ? AppColors.textSecondary : AppColors.textTertiary

        return statusCard {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(spacing: AppSpacing.sm) {
                        Text("DESIRE MAP")
                            .font(AppFonts.overline)
                            .tracking(1.2)
                            .foregroundStyle(AppColors.textTertiary)
                        Text("· Check-in")
                            .font(AppFonts.overline)
                            .foregroundStyle(accentEmphasis)
                    }

                    HStack(spacing: AppSpacing.md) {
                        HStack(spacing: AppSpacing.xs) {
                            Circle()
                                .fill(accentEmphasis)
                                .frame(width: 7, height: 7)
                            Text("You — redoing")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        HStack(spacing: AppSpacing.xs) {
                            Circle()
                                .fill(partnerDotFill)
                                .overlay {
                                    if !partnerStarted {
                                        Circle().stroke(AppColors.textTertiary, lineWidth: 1)
                                    }
                                }
                                .frame(width: 7, height: 7)
                            Text(partnerLabel)
                                .font(AppFonts.caption)
                                .foregroundStyle(partnerLabelColor)
                        }
                    }
                }
                Spacer()
                if !partnerStarted {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onRemind?()
                    } label: {
                        Text("Remind →")
                            .font(AppFonts.caption)
                            .foregroundStyle(accentEmphasis)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.md)
        }
    }

    /// Light → tertiary, dark → primary. The single most-repeated accent choice.
    private var accentEmphasis: Color {
        colorScheme == .light ? AppColors.accentTertiary : AppColors.accentPrimary
    }

    // MARK: - Shared card shell for compact states

    @ViewBuilder
    private func statusCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .background {
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(colorScheme == .light
                        ? AppColors.glassFrostCard
                        : AppColors.cardBackground)
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(AppColors.borderSubtle, lineWidth: 1)
            }
    }
}
