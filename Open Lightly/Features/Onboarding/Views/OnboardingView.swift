//
//  OnboardingView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//


// ✅ Design system audit — verified March 9, 2026


import SwiftUI

struct OnboardingView: View {
    @Environment(\.theme) private var t

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()

            GlowOrb(color: t.cyan, size: 280)
                .offset(x: 40, y: -200)
            GlowOrb(color: t.magenta, size: 200)
                .offset(x: -50, y: 180)

            VStack(spacing: 0) {
                Spacer()

                Text("🚪")
                    .font(.system(size: 48))
                    .frame(width: 100, height: 100)
                    .background(t.glowCyan)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(t.cardBorder, lineWidth: 1.5)
                    )
                    .shadow(
                        color: t.isAmoled ? t.glowCyan : .clear,
                        radius: 30
                    )
                    .shadow(
                        color: t.isAmoled ? t.glowMagenta : .clear,
                        radius: 50
                    )
                    .padding(.bottom, 24)

                Text("Open Lightly")
                    .font(.system(size: 28, weight: .bold))
                    .tracking(-0.8)
                    .foregroundStyle(t.text)

                Text("The \(Text("pre-flight check").foregroundStyle(t.cyan).fontWeight(.semibold)) for your relationship's \(Text("next chapter").foregroundStyle(t.magenta).fontWeight(.semibold))")
                    .foregroundStyle(t.textSecondary)
            
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 6)
                .padding(.horizontal, 40)

                SpectrumBar()
                    .frame(width: 80)
                    .padding(.top, 14)

                Spacer()

                GradientButton(title: "Begin Together") {}
                    .padding(.horizontal, 24)

                Button {
                    // solo flow
                } label: {
                    Text("I'll explore solo first")
                        .font(.system(size: 12))
                        .foregroundStyle(t.textMuted)
                }
                .padding(.top, 14)

                HStack(spacing: 6) {
                    Capsule()
                        .fill(t.buttonGradient)
                        .frame(width: 20, height: 6)
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(t.surface3)
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 30)
            }
        }
    }
}
