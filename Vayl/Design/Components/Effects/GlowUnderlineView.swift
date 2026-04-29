//
//  GlowUnderlineView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/12/26.
//


import SwiftUI

struct GlowUnderlineView: View {
    let isLight: Bool
    var flash: CGFloat = 0
    @State private var breathe: Bool = false
    
    var body: some View {
        ZStack {
            // The solid core
            Rectangle()
                .fill(isLight ? AnyShapeStyle(AppColors.warmAuroraBorder) : AnyShapeStyle(AppColors.spectrumBorder))
                .frame(height: 3)
                .opacity(Double(1 - flash * 0.6))
            
            // The tight neon glow
            Rectangle()
                .fill(LinearGradient(
                    colors: isLight 
                        ? [AppColors.magenta.opacity(0.9), AppColors.pink, AppColors.purple.opacity(0.9), AppColors.magenta.opacity(0.9)]
                        : [AppColors.cyan, AppColors.purple, AppColors.pink, AppColors.cyan],
                    startPoint: .leading, endPoint: .trailing
                ))
                .frame(height: 3)
                .blur(radius: 6)
                .opacity(Double(breathe ? 1.0 : 0.7) * Double(1 - flash * 0.7))
            
            // The wide bloom
            Rectangle()
                .fill(LinearGradient(
                    colors: isLight 
                        ? [AppColors.magenta.opacity(0.35), AppColors.pink.opacity(0.50), AppColors.purple.opacity(0.40), AppColors.magenta.opacity(0.35)]
                        : [AppColors.cyan.opacity(0.35), AppColors.purple.opacity(0.50), AppColors.pink.opacity(0.45), AppColors.cyan.opacity(0.35)],
                    startPoint: .leading, endPoint: .trailing
                ))
                .frame(height: 14)
                .blur(radius: 8)
                .opacity(Double(breathe ? 1.0 : 0.5) * Double(1 - flash * 0.8))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }
}