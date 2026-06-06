//
//  GlowUnderline.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/3/26.
//
import SwiftUI

struct GlowUnderline: ViewModifier {
    let isLight: Bool
    var flash: CGFloat = 0
    
    @State private var breathe: Bool = false
    
    private var coreColors: [Color] {
        isLight
            ? [AppColors.accentTertiary.opacity(0.9),
               AppColors.accentTertiary.opacity(1.0),
               AppColors.accentSecondary.opacity(0.9),
               AppColors.accentTertiary.opacity(0.9)]
            : [AppColors.accentPrimary.opacity(1.0),
               AppColors.accentSecondary.opacity(1.0),
               AppColors.accentTertiary.opacity(1.0),
               AppColors.accentPrimary.opacity(1.0)]
    }

    private var haloColors: [Color] {
        isLight
            ? [AppColors.accentTertiary.opacity(0.35),
               AppColors.accentTertiary.opacity(0.50),
               AppColors.accentSecondary.opacity(0.40),
               AppColors.accentTertiary.opacity(0.35)]
            : [AppColors.accentPrimary.opacity(0.35),
               AppColors.accentSecondary.opacity(0.50),
               AppColors.accentTertiary.opacity(0.45),
               AppColors.accentPrimary.opacity(0.35)]
    }

    func body(content: Content) -> some View {
        let baseOpacity:  Double = Double(1 - flash * 0.6)
        let coreOpacity:  Double = Double(breathe ? 1.0 : 0.7) * Double(1 - flash * 0.7)
        let haloOpacity:  Double = Double(breathe ? 1.0 : 0.5) * Double(1 - flash * 0.8)

        return content
            .overlay(alignment: .bottom) {
                ZStack {
                    Rectangle()
                        .fill(AppColors.spectrumBorder)
                        .frame(height: 3)
                        .opacity(baseOpacity)

                    Rectangle()
                        .fill(LinearGradient(colors: coreColors, startPoint: .leading, endPoint: .trailing))
                        .frame(height: 3)
                        .blur(radius: 6)
                        .opacity(coreOpacity)

                    Rectangle()
                        .fill(LinearGradient(colors: haloColors, startPoint: .leading, endPoint: .trailing))
                        .frame(height: 14)
                        .blur(radius: 8)
                        .opacity(haloOpacity)
                }
                .offset(y: 4)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                        breathe = true
                    }
                }
            }
    }
}
