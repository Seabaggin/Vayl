//
//  ScoreRing.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//


import SwiftUI

struct ScoreRing: View {
    @Environment(\.theme) private var t
    let score: Int
    var size: CGFloat = 110
    var lineWidth: CGFloat = 9

    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    t.isAmoled ? .white.opacity(0.06) : t.surface3,
                    lineWidth: lineWidth
                )

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    t.ringGradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text(score, format: .number)
                    .font(.system(
                        size: size > 80 ? 28 : 16,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundStyle(t.text)

                if size > 80 {
                    Text("OF 100")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(t.textMuted)
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                progress = CGFloat(score) / 100.0
            }
        }
    }
}
