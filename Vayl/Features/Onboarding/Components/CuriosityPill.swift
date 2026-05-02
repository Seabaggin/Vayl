//
//  CuriosityPill.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/30/26.
//


//
//  CuriosityPill.swift
//  Open Lightly
//
//  Selectable pill for the curiosity picker panels.
//  Shows a gradient checkmark when selected.
//  Border and background adapt to content type and selection state.
//

import SwiftUI

struct CuriosityPill: View {
    let option:     CuriosityOption
    let isSelected: Bool
    let pillHeight: CGFloat
    let onTap:      () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }
    
    private var accentColor: Color {
        switch option.contentType {
        case .quiz, .desireMap: return AppColors.accentTertiary
        default:                return AppColors.accentPrimary
        }
    }
    
    private var darkSelectedBorder: LinearGradient {
        switch option.contentType {
        case .quiz, .desireMap:
            return LinearGradient(
                colors: [AppColors.accentTertiary, AppColors.accentSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [AppColors.accentPrimary, AppColors.accentSecondary, AppColors.accentTertiary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        Button(action: onTap, label: {
            HStack(spacing: AppSpacing.sm) {
                
                // ── Icon slot ─────────────────────────────────────────
                ZStack {
                    if isSelected {
                        Image(AppIcons.checkmark)
                            .font(AppFonts.overline)
                            .foregroundStyle(
                                isLight
                                ? AnyShapeStyle(AppColors.accentTertiary)
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.accentPrimary, AppColors.accentSecondary, AppColors.accentTertiary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                            )
                            .shadow(
                                color: isLight
                                ? AppColors.accentTertiary.opacity(0.40)
                                : AppColors.accentPrimary.opacity(0.55),
                                radius: 6
                            )
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 14, height: 14)
                .animation(AppAnimation.spring, value: isSelected)
                .accessibilityHidden(true)
                
                // ── Label ─────────────────────────────────────────────
                Text(option.label)
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(
                        isSelected
                        ? (isLight
                           ? AnyShapeStyle(AppColors.textBody)  // TODO: verify token — original was AppColors.textBody
                           : AnyShapeStyle(AppColors.textPrimary))
                        : (isLight
                           ? AnyShapeStyle(AppColors.textSecondary) // TODO: verify token — original was AppColors.textSecondary
                           : AnyShapeStyle(AppColors.textBright))
                    )
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)   // true — lets height grow
                    .multilineTextAlignment(.leading)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.md)
            .frame(maxWidth: .infinity)
            .frame(minHeight: pillHeight + 8)   // min not fixed — grows for two-line labels
            .background(pillBackground)
            .overlay(pillBorder)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.container))
        })
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(AppAnimation.spring, value: isSelected)
        .shadow(
            color: isSelected
            ? (isLight ? AppColors.shadowMagenta : accentColor.opacity(0.35))
            : .clear,
            radius: 10
        )
        .shadow(
            color: isLight ? .clear : AppColors.pillGlow,
            radius: 8
        )
        .shadow(
            color: (!isSelected && option.isEmphasized && !isLight)
            ? AppColors.accentPrimary.opacity(0.12)
            : .clear,
            radius: 6
        )
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var pillBackground: some View {
        RoundedRectangle(cornerRadius: AppRadius.container)
            .fill(
                isSelected
                ? (isLight
                   ? LinearGradient(
                    colors: [AppColors.glassFrostPillSelected, AppColors.glassFrostPillSelected],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                   : LinearGradient(
                    colors: [accentColor.opacity(0.08), AppColors.accentSecondary.opacity(0.06)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                : (isLight
                   ? LinearGradient(
                    colors: [AppColors.glassFrostPill, AppColors.glassFrostPill],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                   : LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.09, blue: 0.16), // intentional exception: art direction hex — no token for this onboarding glass surface
                        Color(red: 0.08, green: 0.07, blue: 0.13), // intentional exception: art direction hex — no token for this onboarding glass surface
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
            )
    }
    
    // MARK: - Border
    
    @ViewBuilder
    private var pillBorder: some View {
        if isSelected {
            if isLight {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.container)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: AppColors.accentTertiary,   location: 0.00),
                                    .init(color: AppColors.progressBarLeading, location: 0.50),
                                    .init(color: AppColors.safetyAccent,      location: 1.00),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                    RoundedRectangle(cornerRadius: AppRadius.container)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: AppColors.accentTertiary,   location: 0.00),
                                    .init(color: AppColors.progressBarLeading, location: 0.50),
                                    .init(color: AppColors.safetyAccent,      location: 1.00),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3.5
                        )
                        .blur(radius: 6)
                        .opacity(0.25)
                }
                .shadow(color: AppColors.shadowMagenta, radius: 8,  x: 0, y: 3)
                .shadow(color: AppColors.shadowPurple,  radius: 16, x: 0, y: 5)
                .shadow(color: AppColors.shadowGold,    radius: 6,  x: 0, y: 2)
            } else {
                // Dark selected border
                RoundedRectangle(cornerRadius: AppRadius.container)
                    .strokeBorder(
                        darkSelectedBorder,
                        lineWidth: 2.0
                    )
                    .opacity(0.85)
            }
        } else {
            // Unselected border (dark only)
            RoundedRectangle(cornerRadius: AppRadius.container)
                .strokeBorder(
                    Color.white.opacity(0.08),
                    lineWidth: 1.0
                )
        }
    }
}
