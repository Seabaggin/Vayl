// Home/Components/PartnerChip.swift

import SwiftUI

struct PartnerChip: View {
    let state: PartnerChipState
    var onInviteTap: (() -> Void)? = nil
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
                    // ── Outer glow bloom ──────────────────────
                    Circle()
                        .fill(isLight
                            ? AppColors.auroraBlob2
                            : AppColors.cyan.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .blur(radius: 8)

                    Circle()
                        .fill(isLight
                            ? AppColors.auroraBlob1
                            : AppColors.purple.opacity(0.20))
                        .frame(width: 40, height: 40)
                        .blur(radius: 6)

                    // ── Shimmer fill ──────────────────────────
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

                    // ── Border ────────────────────────────────
                    Circle()
                        .strokeBorder(
                            isLight
                                ? AnyShapeStyle(AppColors.warmAuroraBorder)
                                : AnyShapeStyle(LinearGradient(
                                    colors: [
                                        AppColors.cyan,
                                        AppColors.purple,
                                        AppColors.magenta
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )),
                            lineWidth: 1.5
                        )
                        .frame(width: 36, height: 36)

                    // ── Icon ──────────────────────────────────
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(isLight
                            ? AnyShapeStyle(AppColors.lightHeadlineDarkRose)
                            : AnyShapeStyle(Color.white)
                        )
                }
            }
            .buttonStyle(.plain)

        // ── Invite pending ─────────────────────────────────────
        // Invite sent, waiting for partner to accept.
        // Brighter border than .none to signal progress.
        // Not tappable — this is a status indicator only.
        case .invitePending:
            ZStack {
                // ── Outer glow bloom — stronger than .none ────
                Circle()
                    .fill(isLight
                        ? AppColors.magenta.opacity(0.18)
                        : AppColors.magenta.opacity(0.20))
                    .frame(width: 48, height: 48)
                    .blur(radius: 10)

                Circle()
                    .fill(isLight
                        ? AppColors.purple.opacity(0.14)
                        : AppColors.purple.opacity(0.25))
                    .frame(width: 42, height: 42)
                    .blur(radius: 8)

                // ── Shimmer fill ──────────────────────────────
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

                // ── Border — brighter, pulsing ────────────────
                Circle()
                    .strokeBorder(
                        isLight
                            ? AnyShapeStyle(AppColors.warmAuroraBorder)
                            : AnyShapeStyle(LinearGradient(
                                colors: [
                                    AppColors.cyan,
                                    AppColors.purple,
                                    AppColors.magenta
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )),
                        lineWidth: 2
                    )
                    .frame(width: 36, height: 36)

                // ── Icon — clock signals waiting ──────────────
                Image(systemName: "person.badge.clock")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isLight
                        ? AnyShapeStyle(AppColors.lightHeadlineDarkRose)
                        : AnyShapeStyle(Color.white)
                    )
            }

        // ── Active partner ─────────────────────────────────────
        // Tap → Map tab, partner profile
        case .active(let name, let initial):
            Button {
                onPartnerTap?()
            } label: {
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(isLight
                                ? Color.black.opacity(0.08)
                                : Color.white.opacity(0.12))
                            .frame(width: 20, height: 20)
                        Text(String(initial))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(isLight
                                ? AppColors.lightTextPrimary
                                : .white)
                    }
                    Text(name)
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight
                            ? AppColors.lightTextSecondary
                            : AppColors.textSecondary)

                    // Chevron signals tappability
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(isLight
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(isLight
                            ? AppColors.lightFrostCard
                            : Color.white.opacity(0.04))
                }
                .overlay {
                    Capsule()
                        .stroke(isLight
                            ? AppColors.lightBorder
                            : Color.white.opacity(0.08),
                            lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

        // ── Multiple partners — V1.1 stub ──────────────────────
        // Renders as inactive "All ·" pill.
        // No behavior until multi-partner support ships.
        case .multipleActive:
            HStack(spacing: 5) {
                Text("All ·")
                    .font(AppFonts.caption)
                    .foregroundStyle(isLight
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(isLight
                        ? AppColors.lightFrostCard
                        : Color.white.opacity(0.04))
            }
            .overlay {
                Capsule()
                    .stroke(isLight
                        ? AppColors.lightBorder
                        : Color.white.opacity(0.06),
                        lineWidth: 1)
            }
        }
    }
}

// MARK: - Previews

#Preview("Dark — None") {
    PartnerChip(state: .none, onInviteTap: {})
        .padding()
        .background(AppColors.pageBg)
        .preferredColorScheme(.dark)
}

#Preview("Dark — Invite Pending") {
    PartnerChip(state: .invitePending)
        .padding()
        .background(AppColors.pageBg)
        .preferredColorScheme(.dark)
}

#Preview("Dark — Active") {
    PartnerChip(
        state: .active(name: "Alex", initial: "A"),
        onPartnerTap: {}
    )
    .padding()
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

#Preview("Dark — Multiple V1.1 Stub") {
    PartnerChip(state: .multipleActive(
        partners: [("Alex", "A"), ("Sam", "S")],
        selected: nil)
    )
    .padding()
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

#Preview("Light — None") {
    PartnerChip(state: .none, onInviteTap: {})
        .padding()
        .background(AppColors.lightPageBg)
        .preferredColorScheme(.light)
}

#Preview("Light — Invite Pending") {
    PartnerChip(state: .invitePending)
        .padding()
        .background(AppColors.lightPageBg)
        .preferredColorScheme(.light)
}

#Preview("Light — Active") {
    PartnerChip(
        state: .active(name: "Alex", initial: "A"),
        onPartnerTap: {}
    )
    .padding()
    .background(AppColors.lightPageBg)
    .preferredColorScheme(.light)
}

#Preview("Light — Multiple V1.1 Stub") {
    PartnerChip(state: .multipleActive(
        partners: [("Alex", "A"), ("Sam", "S")],
        selected: nil)
    )
    .padding()
    .background(AppColors.lightPageBg)
    .preferredColorScheme(.light)
}
