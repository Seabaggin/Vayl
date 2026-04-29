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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DESIRE MAP")
                            .font(AppFonts.overline)
                            .tracking(1.2)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)

                        HStack(spacing: 12) {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(colorScheme == .light
                                        ? AppColors.magenta
                                        : AppColors.cyan)
                                    .frame(width: 7, height: 7)
                                Text("You're done")
                                    .font(AppFonts.caption)
                                    .foregroundStyle(colorScheme == .light
                                        ? AppColors.lightTextSecondary
                                        : AppColors.textSecondary)
                            }
                            HStack(spacing: 5) {
                                Circle()
                                    .stroke(colorScheme == .light
                                        ? AppColors.lightTextTertiary
                                        : AppColors.textTertiary,
                                        lineWidth: 1)
                                    .frame(width: 7, height: 7)
                                Text(partnerName)
                                    .font(AppFonts.caption)
                                    .foregroundStyle(colorScheme == .light
                                        ? AppColors.lightTextTertiary
                                        : AppColors.textTertiary)
                            }
                        }
                    }
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .light)
                            .impactOccurred()
                        onRemind?()
                    } label: {
                        Text("Remind \(partnerName) →")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.magenta
                                : AppColors.cyanLight)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }

        case .bothReady:
            // Elevated treatment — highest CTA weight on screen
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("DESIRE MAP")
                            .font(AppFonts.overline)
                            .tracking(1.2)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)
                        Spacer()
                        Text("You're both ready")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.magenta
                                : AppColors.cyanLight)
                    }

                    HStack(spacing: 16) {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(colorScheme == .light
                                    ? AppColors.magenta
                                    : AppColors.cyan)
                                .frame(width: 7, height: 7)
                            Text("You")
                                .font(AppFonts.bodyMedium)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.lightTextPrimary
                                    : AppColors.textPrimary)
                        }
                        HStack(spacing: 5) {
                            Circle()
                                .fill(colorScheme == .light
                                    ? AppColors.gold
                                    : AppColors.purple)
                                .frame(width: 7, height: 7)
                            Text("Partner")
                                .font(AppFonts.bodyMedium)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.lightTextPrimary
                                    : AppColors.textPrimary)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)

                Spacer(minLength: 14)

                Button {
                    UIImpactFeedbackGenerator(style: .medium)
                        .impactOccurred()
                    onReveal?()
                } label: {
                    Text("See Your First Match")
                        .font(AppFonts.ctaLabel)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightBodyWineDark
                            : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(colorScheme == .light
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.magenta.opacity(0.18),
                                                 AppColors.gold.opacity(0.14)],
                                        startPoint: .leading,
                                        endPoint: .trailing))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.cyan,
                                                 AppColors.purple,
                                                 AppColors.magenta],
                                        startPoint: .leading,
                                        endPoint: .trailing)))
                        }
                        .shadow(color: colorScheme == .light
                            ? AppColors.lightShadowMagenta
                            : AppColors.purple.opacity(0.4),
                                radius: 12, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
            }
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .light
                        ? AppColors.lightCardFill
                        : AppColors.cardBg)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(colorScheme == .light
                        ? AnyShapeStyle(
                            AppColors.warmAuroraBorder.opacity(0.6))
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan.opacity(0.5),
                                     AppColors.purple.opacity(0.4),
                                     AppColors.magenta.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing)),
                        lineWidth: 1.5)
            }
            .shadow(color: colorScheme == .light
                ? AppColors.lightShadowPurple
                : AppColors.purple.opacity(0.2),
                    radius: 20, y: 6)

        case .freeRevealSeen(_):
            statusCard {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .light
                                ? AppColors.magenta.opacity(0.10)
                                : AppColors.purple.opacity(0.15))
                            .frame(width: 38, height: 38)
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.magenta, AppColors.gold],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.purple, AppColors.magenta],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing)))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("1 match revealed")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextPrimary
                                : AppColors.textPrimary)
                        Text("+ more waiting")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)
                    }
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .light)
                            .impactOccurred()
                        onUnlock?()
                    } label: {
                        Text("Unlock →")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.magenta
                                : AppColors.cyanLight)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }

        case .redoInProgress(let partnerName, let partnerStarted):
            statusCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("DESIRE MAP")
                                .font(AppFonts.overline)
                                .tracking(1.2)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.lightTextTertiary
                                    : AppColors.textTertiary)
                            Text("· Check-in")
                                .font(AppFonts.overline)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.magenta
                                    : AppColors.cyanLight)
                        }

                        HStack(spacing: 12) {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(colorScheme == .light
                                        ? AppColors.magenta
                                        : AppColors.cyan)
                                    .frame(width: 7, height: 7)
                                Text("You — redoing")
                                    .font(AppFonts.caption)
                                    .foregroundStyle(colorScheme == .light
                                        ? AppColors.lightTextSecondary
                                        : AppColors.textSecondary)
                            }
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(partnerStarted
                                          ? (colorScheme == .light
                                              ? AppColors.gold
                                              : AppColors.purple)
                                          : Color.clear)
                                    .overlay {
                                        if !partnerStarted {
                                            Circle()
                                                .stroke(colorScheme == .light
                                                    ? AppColors.lightTextTertiary
                                                    : AppColors.textTertiary,
                                                    lineWidth: 1)
                                        }
                                    }
                                    .frame(width: 7, height: 7)
                                Text(partnerStarted
                                     ? "\(partnerName) in progress"
                                     : "\(partnerName) hasn't started")
                                    .font(AppFonts.caption)
                                    .foregroundStyle(
                                        partnerStarted
                                        ? (colorScheme == .light
                                            ? AppColors.lightTextSecondary
                                            : AppColors.textSecondary)
                                        : (colorScheme == .light
                                            ? AppColors.lightTextTertiary
                                            : AppColors.textTertiary)
                                    )
                            }
                        }
                    }
                    Spacer()
                    if !partnerStarted {
                        Button {
                            UIImpactFeedbackGenerator(style: .light)
                                .impactOccurred()
                            onRemind?()
                        } label: {
                            Text("Remind →")
                                .font(AppFonts.caption)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.magenta
                                    : AppColors.cyanLight)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
        }
    }

    // MARK: - Shared card shell for compact states

    @ViewBuilder
    private func statusCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .light
                        ? AppColors.lightFrostCard
                        : AppColors.cardBg)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(colorScheme == .light
                        ? AppColors.lightBorder
                        : AppColors.border,
                        lineWidth: 1)
            }
    }
}
