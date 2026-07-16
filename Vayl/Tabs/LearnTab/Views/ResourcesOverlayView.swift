// Features/Learn/Views/ResourcesOverlayView.swift
//
// "Vayl isn't therapy" — the persistent resources sheet. Two tiers:
// ongoing support (cyan) and in-crisis (gold). Crisis rows open
// tel:/sms: actions.

import SwiftUI

struct ResourcesOverlayView: View {
    let resources: [SupportResource]
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    Image(systemName: AppIcons.lifepreserver)
                        .font(AppFonts.body(19, weight: .regular, relativeTo: .body)).foregroundStyle(AppColors.spectrumCyan)
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Vayl isn't therapy")
                            .font(AppFonts.cardTitle).foregroundStyle(AppColors.textPrimary)
                        Text("And it isn't trying to be. Think of us as the lifeguard at the edge of the pool — not to keep you from the deep end, but to throw you a line if you ever need one.")
                            .font(AppFonts.caption).foregroundStyle(AppColors.textSecondary)
                    }
                }

                tier("Looking for ongoing support?", .ongoing, AppColors.spectrumCyan)
                tier("In crisis right now?", .crisis, AppColors.safetyAccent)
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColors.modalBackground)
    }

    private func tier(_ heading: String, _ which: ResourceTier, _ accent: Color) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(heading)
                .overlineTracked()
                .foregroundStyle(accent)
                .padding(.top, AppSpacing.sm)
            ForEach(resources.filter { $0.tier == which }) { r in
                Button { if let url = URL(string: r.action) { openURL(url) } } label: {
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: r.icon).foregroundStyle(accent)
                            .frame(width: 32, height: 32)
                            .background(RoundedRectangle(cornerRadius: AppRadius.md).fill(accent.opacity(0.08)))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(r.title).font(AppFonts.bodyMedium).foregroundStyle(AppColors.textPrimary)
                            Text(r.detail).font(AppFonts.caption).foregroundStyle(AppColors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: which == .crisis ? AppIcons.arrowRight : AppIcons.arrowUpRight)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    .padding(AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .fill(which == .crisis ? accent.opacity(0.05) : AppColors.cardBackground)
                            .overlay(RoundedRectangle(cornerRadius: AppRadius.lg)
                                .stroke(accent.opacity(which == .crisis ? 0.2 : 0.12), lineWidth: 1))
                    )
                }
                .buttonStyle(PressableCardStyle())
            }
        }
    }
}

#Preview {
    ResourcesOverlayView(resources: LearnStore().supportResources)
}
