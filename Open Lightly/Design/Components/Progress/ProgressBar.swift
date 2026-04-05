//
//  ProgressBar.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//


import SwiftUI

struct ProgressBar: View {
    @Environment(\.theme) private var t
    let value: Double
    let max: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(t.isDark ? .white.opacity(0.06) : t.surface3)

                Capsule()
                    .fill(t.buttonGradient)
                    .frame(width: geo.size.width * (value / max))
                    .animation(.easeOut(duration: 0.6), value: value)
            }
        }
        .frame(height: 4)
    }
}
