// Home/Components/PartnerChipExpand.swift

import SwiftUI

/// The quick-view popover that opens beneath the partner chip on tap.
/// Anchored top-right, expands in place — NOT a `.vaylSheet`/`.vaylCover`
/// (this is an inline-expand discovery interaction, not a task or immersive
/// mode, per the presentation-grammar contract in CLAUDE.md).
struct PartnerChipExpand: View {
    let state: PartnerChipState
    let desireMapState: DesireMapState
    let partnerPulsePosition: PulsePosition?
    var onDesireMapTap: (() -> Void)? = nil
    var onPulseTap: (() -> Void)? = nil
    var onManageTap: (() -> Void)? = nil

    var body: some View {
        Group {
            switch state {
            case .active(let name, let initial):
                activeContent(name: name, initial: initial)
            default:
                EmptyView() // only .active renders content here — other states route elsewhere
            }
        }
    }

    /// The Pulse tile's copy, trimmed to fit a two-column tile at 224pt width.
    /// `PartnerChipPulseCopy.tileText(for:)` returns `PulseQuadrant.spaceName`'s
    /// full phrase ("The Expansive Space") — too long for this tile. No shorter
    /// accessor exists on `PulseQuadrant`, and that type is out of scope here
    /// (shared cross-feature enum), so the trim happens at this consumer, where
    /// the width constraint actually lives. "Not sharing" passes through
    /// unchanged since it matches neither pattern.
    private var pulseTileShortText: String {
        let full = PartnerChipPulseCopy.tileText(for: partnerPulsePosition)
        return full
            .replacingOccurrences(of: "The ", with: "")
            .replacingOccurrences(of: " Space", with: "")
    }

    @ViewBuilder
    private func activeContent(name: String, initial: String) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.sm) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 22, height: 22)
                    .overlay(
                        Text(initial)
                            .font(.caption2).fontWeight(.bold)
                            .foregroundStyle(.white)
                    )
                Text(name)
                    // cardTitle (22pt) is sized for a screen-level card headline —
                    // too large next to a 22pt avatar circle in a 224pt popover.
                    // cardTitleCompact (16pt) is the token meant for exactly this:
                    // dense rows / compact widget titles.
                    .font(AppFonts.cardTitleCompact)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
            }
            .padding(AppSpacing.md)

            HStack(spacing: AppSpacing.sm) {
                tile(
                    label: "Desire Map",
                    icon: AppIcons.heartTextSquare,
                    text: PartnerChipDesireMapCopy.tileText(for: desireMapState, partnerName: name),
                    action: onDesireMapTap
                )
                pulseTile(action: onPulseTap)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.sm)

            Divider().overlay(AppColors.borderSubtle)

            Button {
                onManageTap?()
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: AppIcons.gear)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Text("Manage pairing")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textBody)
                    Spacer()
                    Image(systemName: AppIcons.chevronRight)
                        .font(.caption2)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .padding(AppSpacing.md)
            }
            .buttonStyle(PressableCardStyle())
        }
        .frame(width: 224)
        .themedCard()
    }

    @ViewBuilder
    private func tile(label: String, icon: String, text: String, action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            VStack(spacing: AppSpacing.xs) {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppColors.textTertiary)
                Image(systemName: icon)
                    .foregroundStyle(AppColors.spectrumPurple)
                Text(text)
                    .font(.caption)
                    .foregroundStyle(AppColors.textBody)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.sm)
            .background(AppColors.whisperFill)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .buttonStyle(PressableCardStyle())
    }

    @ViewBuilder
    private func pulseTile(action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            VStack(spacing: AppSpacing.xs) {
                Text("PULSE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppColors.textTertiary)
                if let position = partnerPulsePosition {
                    Circle()
                        .fill(position.quadrant.capacityColor.auraCore)
                        .frame(width: 18, height: 18)
                } else {
                    Circle()
                        .fill(AppColors.textMuted)
                        .frame(width: 18, height: 18)
                }
                Text(pulseTileShortText)
                    .font(.caption)
                    .foregroundStyle(AppColors.textBody)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.sm)
            .background(AppColors.whisperFill)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .buttonStyle(PressableCardStyle())
    }
}

// MARK: - Previews

#Preview("Dark — Active, Pulse shared") {
    ZStack(alignment: .topTrailing) {
        AppColors.pageBackground.ignoresSafeArea()
        PartnerChipExpand(
            state: .active(name: "Alex", initial: "A"),
            desireMapState: .bothReady,
            partnerPulsePosition: PulsePosition(energy: 0.8, openness: 0.7)
        )
        .padding(.top, AppSpacing.xl)
        .padding(.trailing, AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}

#Preview("Dark — Active, Pulse not sharing") {
    ZStack(alignment: .topTrailing) {
        AppColors.pageBackground.ignoresSafeArea()
        PartnerChipExpand(
            state: .active(name: "Alex", initial: "A"),
            desireMapState: .youDone(partnerName: "Alex"),
            partnerPulsePosition: nil
        )
        .padding(.top, AppSpacing.xl)
        .padding(.trailing, AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
