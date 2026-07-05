// Home/Components/PartnerChip.swift

import SwiftUI

struct PartnerChip: View {
    let state: PartnerChipState
    /// You finished your Desire Map and are waiting on your partner — surfaces a small aperture
    /// in the active pill (the desire-map waiting status, no dashboard card).
    var waiting: Bool = false
    var onInviteTap:  (() -> Void)? = nil
    var onPartnerTap: (() -> Void)? = nil

    var body: some View {
        switch state {

        // ── No partner — invite circle button ─────────────────
        case .none:
            Button {
                onInviteTap?()
            } label: {
                ZStack {
                    Circle()
                        .fill(AppColors.accentPrimary.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .blur(radius: 8)

                    Circle()
                        .fill(AppColors.accentSecondary.opacity(0.20))
                        .frame(width: 40, height: 40)
                        .blur(radius: 6)

                    HolographicShimmer(duration: 6)
                        .clipShape(Circle())
                        .frame(width: 36, height: 36)
                        .opacity(0.85)

                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    AppColors.accentPrimary,
                                    AppColors.accentSecondary,
                                    AppColors.accentTertiary
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: AppIcons.personBadgePlus)
                        // .caption scales with Dynamic Type — correct for
                        // compact icon badges at this visual weight.
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.white)
                }
            }
            .buttonStyle(.plain)

        // ── Invite pending ─────────────────────────────────────
        case .invitePending:
            Button {
                onPartnerTap?()
            } label: {
                ZStack {
                    Circle()
                        .fill(AppColors.accentTertiary.opacity(0.20))
                        .frame(width: 48, height: 48)
                        .blur(radius: 10)

                    Circle()
                        .fill(AppColors.accentSecondary.opacity(0.25))
                        .frame(width: 42, height: 42)
                        .blur(radius: 8)

                    HolographicShimmer(duration: 4)
                        .clipShape(Circle())
                        .frame(width: 36, height: 36)
                        .opacity(0.95)

                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    AppColors.accentPrimary,
                                    AppColors.accentSecondary,
                                    AppColors.accentTertiary
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: AppIcons.personBadgeClock)
                        // .caption scales with Dynamic Type — correct for
                        // compact icon badges at this visual weight.
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.white)
                }
            }
            .buttonStyle(.plain)

        // ── Active partner ─────────────────────────────────────
        case .active(let name, let initial):
            Button {
                onPartnerTap?()
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.spectrumCyan,
                                        AppColors.spectrumPurple,
                                        AppColors.spectrumMagenta
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 20, height: 20)
                        Text(String(initial))
                            // .caption2 scales with Dynamic Type — correct for
                            // single-letter avatar initials in a 20pt circle.
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    Text(name)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)

                    if waiting {
                        VaylMark(ringCount: 1, glow: 0.55, showsCore: true)
                            .frame(width: 15, height: 15)
                    }

                    Image(systemName: AppIcons.chevronRight)
                        // .caption2 scales with Dynamic Type — correct for
                        // small directional indicators in compact chips.
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                // iOS 26 Liquid Glass — the partner pill is a native floating control.
                .glassEffect(.regular, in: Capsule())
            }
            .buttonStyle(.plain)

        // ── Multiple partners — V1.1 stub ──────────────────────
        case .multipleActive:
            HStack(spacing: AppSpacing.xs) {
                Text("All ·")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .glassEffect(.regular, in: Capsule())

        // ── Nudge — same at-rest visual as invitePending; the tone
        // shift lives in PartnerChipExpand (a later task), not here.
        case .nudge:
            Button {
                onPartnerTap?()
            } label: {
                ZStack {
                    Circle()
                        .fill(AppColors.accentTertiary.opacity(0.20))
                        .frame(width: 48, height: 48)
                        .blur(radius: 10)

                    Circle()
                        .fill(AppColors.accentSecondary.opacity(0.25))
                        .frame(width: 42, height: 42)
                        .blur(radius: 8)

                    HolographicShimmer(duration: 4)
                        .clipShape(Circle())
                        .frame(width: 36, height: 36)
                        .opacity(0.95)

                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    AppColors.accentPrimary,
                                    AppColors.accentSecondary,
                                    AppColors.accentTertiary
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: AppIcons.personBadgeClock)
                        // .caption scales with Dynamic Type — correct for
                        // compact icon badges at this visual weight.
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.white)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Previews

#Preview("Dark — None") {
    PartnerChip(state: .none, onInviteTap: {})
        .padding()
        .background(AppColors.pageBackground)
        .preferredColorScheme(.dark)
}

#Preview("Dark — Invite Pending") {
    PartnerChip(state: .invitePending)
        .padding()
        .background(AppColors.pageBackground)
        .preferredColorScheme(.dark)
}

#Preview("Dark — Active") {
    PartnerChip(
        state: .active(name: "Alex", initial: "A"),
        onPartnerTap: {}
    )
    .padding()
    .background(AppColors.pageBackground)
    .preferredColorScheme(.dark)
}

#Preview("Dark — Multiple V1.1 Stub") {
    PartnerChip(state: .multipleActive(
        partners: [("Alex", "A"), ("Sam", "S")],
        selected: nil)
    )
    .padding()
    .background(AppColors.pageBackground)
    .preferredColorScheme(.dark)
}

#Preview("Dark — Nudge") {
    PartnerChip(state: .nudge, onPartnerTap: {})
        .padding()
        .background(AppColors.pageBackground)
        .preferredColorScheme(.dark)
}
