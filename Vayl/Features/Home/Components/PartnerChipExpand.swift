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
    var partnerPulseFetchFailed: Bool = false
    var onDesireMapTap: (() -> Void)? = nil
    var onPulseTap: (() -> Void)? = nil
    var onManageTap: (() -> Void)? = nil

    var body: some View {
        Group {
            switch state {
            case .active(let name, _):
                activeContent(name: name)
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
        let full = PartnerChipPulseCopy.tileText(
            for: partnerPulsePosition,
            fetchFailed: partnerPulseFetchFailed
        )
        return full
            .replacingOccurrences(of: "The ", with: "")
            .replacingOccurrences(of: " Space", with: "")
    }

    @ViewBuilder
    private func activeContent(name: String) -> some View {
        VStack(spacing: 0) {
            // Same glass-capsule treatment as the at-rest PartnerChip's .active
            // case, so the header reads as that pill continuing into the
            // expanded card rather than a bare row on the card background.
            // Content is this HStack's own body (self); the glass Capsule is a
            // .background, not glassEffect's own composited content (its
            // vibrancy pass darkens/desaturates content that renders through
            // it — same fix as PartnerChip.swift's .active case). Making the
            // HStack self (not the bare Capsule) also matters for SIZING: a
            // `Capsule().overlay{ HStack }` arrangement makes the capsule — a
            // Shape with no content-driven size, which greedily fills any
            // proposed height — the flexible element in this VStack.
            // `HomeDashboardView` positions this popover inside a
            // `.frame(maxWidth: .infinity, maxHeight: .infinity, ...)`
            // wrapper, which proposes near-infinite height; the bare capsule
            // soaked that up and stretched into a screen-tall stadium shape,
            // shoving the tiles and "Manage pairing" row far down the screen.
            // Content as self sizes off the actual name row instead.
            HStack(spacing: AppSpacing.sm) {
                Text(name)
                    // cardTitleCompact (16pt) is the token meant for dense
                    // rows / compact widget titles — matches the pill's scale.
                    .font(AppFonts.cardTitleCompact)
                    .foregroundStyle(AppColors.textBright)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background {
                Capsule()
                    .fill(.clear)
                    .glassEffect(.regular, in: Capsule())
                    .overlay(
                        Capsule().strokeBorder(AppColors.spectrumBorder, lineWidth: 1.5)
                    )
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.sm)

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

            Divider().overlay(AppColors.spectrumText.opacity(0.35))

            Button {
                onManageTap?()
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: AppIcons.gear)
                        .font(AppFonts.body(12, weight: .regular, relativeTo: .caption))
                        .foregroundStyle(AppColors.textSecondary)
                    Text("Manage pairing")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textBody)
                    Spacer()
                    Image(systemName: AppIcons.chevronRight)
                        .font(AppFonts.body(11, weight: .regular, relativeTo: .caption2))
                        .foregroundStyle(AppColors.textTertiary)
                }
                .padding(AppSpacing.md)
            }
            .buttonStyle(PressableCardStyle())
        }
        .frame(width: 224)
        .themedCard()
        // The pill above carries a spectrum-gradient outline; this hairline
        // + soft glow read as that same material continuing down into the
        // card, rather than the card being a bare, disconnected surface.
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .strokeBorder(AppColors.spectrumBorder, lineWidth: 1)
        )
        .spectrumBorderGlow(intensity: 0.4)
    }

    @ViewBuilder
    private func tile(label: String, icon: String, text: String, action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            VStack(spacing: AppSpacing.xs) {
                Text(label.uppercased())
                    .font(AppFonts.microBadge)
                    .foregroundStyle(AppColors.textTertiary)
                Image(systemName: icon)
                    .foregroundStyle(AppColors.spectrumPurple)
                Text(text)
                    .font(AppFonts.body(12, weight: .regular, relativeTo: .caption))
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
                    .font(AppFonts.microBadge)
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
                    .font(AppFonts.body(12, weight: .regular, relativeTo: .caption))
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
