// Home/Components/PartnerChip.swift

import SwiftUI

struct PartnerChip: View {
    let state: PartnerChipState
    var onInviteTap:  (() -> Void)? = nil
    var onPartnerTap: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        switch state {

        // ── No partner — invite circle button ─────────────────
        case .none:
            Button {
                onInviteTap?()
            } label: {
                ZStack {
                    Circle()
                        .fill(isLight
                            ? AppColors.auroraBlob2
                            : AppColors.accentPrimary.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .blur(radius: 8)

                    Circle()
                        .fill(isLight
                            ? AppColors.auroraBlob1
                            : AppColors.accentSecondary.opacity(0.20))
                        .frame(width: 40, height: 40)
                        .blur(radius: 6)

                    if isLight {
                        LightModeShimmer(duration: 6, usePillColors: true)
                            .clipShape(Circle())
                            .frame(width: 36, height: 36)
                            .opacity(0.80)
                    } else {
                        HolographicShimmer(duration: 6)
                            .clipShape(Circle())
                            .frame(width: 36, height: 36)
                            .opacity(0.85)
                    }

                    Circle()
                        .strokeBorder(
                            isLight
                                ? AnyShapeStyle(AppColors.spectrumBorder)
                                : AnyShapeStyle(LinearGradient(
                                    colors: [
                                        AppColors.accentPrimary,
                                        AppColors.accentSecondary,
                                        AppColors.accentTertiary
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )),
                            lineWidth: 1.5
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: AppIcons.personBadgePlus)
                        // .caption scales with Dynamic Type — correct for
                        // compact icon badges at this visual weight.
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(isLight
                            ? AnyShapeStyle(AppColors.textPrimary)
                            : AnyShapeStyle(Color.white)
                        )
                }
            }
            .buttonStyle(.plain)

        // ── Invite pending ─────────────────────────────────────
        case .invitePending:
            ZStack {
                Circle()
                    .fill(isLight
                        ? AppColors.accentTertiary.opacity(0.18)
                        : AppColors.accentTertiary.opacity(0.20))
                    .frame(width: 48, height: 48)
                    .blur(radius: 10)

                Circle()
                    .fill(isLight
                        ? AppColors.accentSecondary.opacity(0.14)
                        : AppColors.accentSecondary.opacity(0.25))
                    .frame(width: 42, height: 42)
                    .blur(radius: 8)

                if isLight {
                    LightModeShimmer(duration: 4, usePillColors: true)
                        .clipShape(Circle())
                        .frame(width: 36, height: 36)
                        .opacity(0.90)
                } else {
                    HolographicShimmer(duration: 4)
                        .clipShape(Circle())
                        .frame(width: 36, height: 36)
                        .opacity(0.95)
                }

                Circle()
                    .strokeBorder(
                        isLight
                            ? AnyShapeStyle(AppColors.spectrumBorder)
                            : AnyShapeStyle(LinearGradient(
                                colors: [
                                    AppColors.accentPrimary,
                                    AppColors.accentSecondary,
                                    AppColors.accentTertiary
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )),
                        lineWidth: 2
                    )
                    .frame(width: 36, height: 36)

                Image(systemName: AppIcons.personBadgeClock)
                    // .caption scales with Dynamic Type — correct for
                    // compact icon badges at this visual weight.
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isLight
                        ? AnyShapeStyle(AppColors.textPrimary)
                        : AnyShapeStyle(Color.white)
                    )
            }

        // ── Active partner ─────────────────────────────────────
        case .active(let name, let initial):
            Button {
                onPartnerTap?()
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(isLight
                                ? Color.black.opacity(0.08)
                                : Color.white.opacity(0.12))
                            .frame(width: 20, height: 20)
                        Text(String(initial))
                            // .caption2 scales with Dynamic Type — correct for
                            // single-letter avatar initials in a 20pt circle.
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(isLight
                                ? AppColors.textPrimary
                                : .white)
                    }
                    Text(name)
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight
                            ? AppColors.textSecondary
                            : AppColors.textSecondary)

                    Image(systemName: AppIcons.chevronRight)
                        // .caption2 scales with Dynamic Type — correct for
                        // small directional indicators in compact chips.
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(isLight
                            ? AppColors.textTertiary
                            : AppColors.textTertiary)
                }
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.sm)
                .background {
                    Capsule()
                        .fill(isLight
                            ? AppColors.glassFrostCard
                            : Color.white.opacity(0.04))
                }
                .overlay {
                    Capsule()
                        .stroke(isLight
                            ? AppColors.borderSubtle
                            : Color.white.opacity(0.08),
                            lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

        // ── Multiple partners — V1.1 stub ──────────────────────
        case .multipleActive:
            HStack(spacing: AppSpacing.xs) {
                Text("All ·")
                    .font(AppFonts.caption)
                    .foregroundStyle(isLight
                        ? AppColors.textTertiary
                        : AppColors.textTertiary)
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.sm)
            .background {
                Capsule()
                    .fill(isLight
                        ? AppColors.glassFrostCard
                        : Color.white.opacity(0.04))
            }
            .overlay {
                Capsule()
                    .stroke(isLight
                        ? AppColors.borderSubtle
                        : Color.white.opacity(0.06),
                        lineWidth: 1)
            }

        // ── Nudge state — V1.1 stub ────────────────────────────
        case .nudge:
            EmptyView()
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

#Preview("Light — None") {
    PartnerChip(state: .none, onInviteTap: {})
        .padding()
        .background(AppColors.pageBackground)
        .preferredColorScheme(.light)
}

#Preview("Light — Invite Pending") {
    PartnerChip(state: .invitePending)
        .padding()
        .background(AppColors.pageBackground)
        .preferredColorScheme(.light)
}

#Preview("Light — Active") {
    PartnerChip(
        state: .active(name: "Alex", initial: "A"),
        onPartnerTap: {}
    )
    .padding()
    .background(AppColors.pageBackground)
    .preferredColorScheme(.light)
}

#Preview("Light — Multiple V1.1 Stub") {
    PartnerChip(state: .multipleActive(
        partners: [("Alex", "A"), ("Sam", "S")],
        selected: nil)
    )
    .padding()
    .background(AppColors.pageBackground)
    .preferredColorScheme(.light)
}
