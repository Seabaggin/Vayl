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
        case .quiz, .desireMap: return AppColors.magenta
        default:                return AppColors.cyan
        }
    }
    
    private var darkSelectedBorder: LinearGradient {
        switch option.contentType {
        case .quiz, .desireMap:
            return LinearGradient(
                colors: [AppColors.magenta, AppColors.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                
                // ── Icon slot ─────────────────────────────────────────
                ZStack {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(
                                isLight
                                ? AnyShapeStyle(AppColors.magenta)
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                            )
                            .shadow(
                                color: isLight
                                ? AppColors.magenta.opacity(0.40)
                                : AppColors.cyan.opacity(0.55),
                                radius: 6
                            )
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 14, height: 14)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
                .accessibilityHidden(true)
                
                // ── Label ─────────────────────────────────────────────
                Text(option.label)
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(
                        isSelected
                        ? (isLight
                           ? AnyShapeStyle(AppColors.lightCardTitle)
                           : AnyShapeStyle(AppColors.textPrimary))
                        : (isLight
                           ? AnyShapeStyle(AppColors.lightBodyWineDark)
                           : AnyShapeStyle(AppColors.textBright))
                    )
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)   // true — lets height grow
                    .multilineTextAlignment(.leading)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .frame(minHeight: pillHeight + 8)   // min not fixed — grows for two-line labels
            .background(pillBackground)
            .overlay(pillBorder)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .shadow(
            color: isSelected
            ? (isLight ? AppColors.lightShadowMagenta : accentColor.opacity(0.35))
            : .clear,
            radius: 10
        )
        .shadow(
            color: isLight ? .clear : AppColors.pillGlow,
            radius: 8
        )
        .shadow(
            color: (!isSelected && option.isEmphasized && !isLight)
            ? AppColors.cyan.opacity(0.12)
            : .clear,
            radius: 6
        )
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var pillBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                isSelected
                ? (isLight
                   ? LinearGradient(
                    colors: [AppColors.lightFrostPillSel, AppColors.lightFrostPillSel],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                   : LinearGradient(
                    colors: [accentColor.opacity(0.08), AppColors.purple.opacity(0.06)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                : (isLight
                   ? LinearGradient(
                    colors: [AppColors.lightFrostPill, AppColors.lightFrostPill],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                   : LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.09, blue: 0.16),
                        Color(red: 0.08, green: 0.07, blue: 0.13),
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
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: AppColors.magenta,   location: 0.00),
                                    .init(color: AppColors.orangeHot, location: 0.50),
                                    .init(color: AppColors.gold,      location: 1.00),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: AppColors.magenta,   location: 0.00),
                                    .init(color: AppColors.orangeHot, location: 0.50),
                                    .init(color: AppColors.gold,      location: 1.00),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3.5
                        )
                        .blur(radius: 6)
                        .opacity(0.25)
                }
                .shadow(color: AppColors.lightShadowMagenta, radius: 8,  x: 0, y: 3)
                .shadow(color: AppColors.lightShadowPurple,  radius: 16, x: 0, y: 5)
                .shadow(color: AppColors.lightShadowGold,    radius: 6,  x: 0, y: 2)
            } else {
                // Dark selected border
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        darkSelectedBorder,
                        lineWidth: 2.0
                    )
                    .opacity(0.85)
            }
        } else {
            // Unselected border (dark only)
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    Color.white.opacity(0.08),
                    lineWidth: 1.0
                )
        }
    }
}
