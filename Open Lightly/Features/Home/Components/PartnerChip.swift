// Home/Components/PartnerChip.swift

import SwiftUI

struct PartnerChip: View {
    let state: PartnerChipState
    var onInviteTap: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        switch state {
        case .none:
            EmptyView()

        case .invitePending:
            Button {
                onInviteTap?()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                    Text("Invite partner")
                        .font(AppFonts.caption)
                }
                .foregroundStyle(isLight
                    ? AppColors.lightTextTertiary
                    : AppColors.textTertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
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
                            : Color.white.opacity(0.10),
                            lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

        case .active(let name, let initial):
            HStack(spacing: 6) {
                // Avatar circle
                ZStack {
                    Circle()
                        .fill(isLight
                            ? Color.black.opacity(0.08)
                            : Color.white.opacity(0.12))
                        .frame(width: 18, height: 18)
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
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
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
    }
}
