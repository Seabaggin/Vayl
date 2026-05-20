//
//  ModeFaceContent.swift
//  Vayl
//
//  Created by Claude Code Agent.
//
//  Design/Components/Cards/VaylCardFace/ModeFaceContent.swift
//
//  Mode selection card face — Solo Discovery / Shared Journey.
//  STUB — full implementation pending design review after Step 8.
//  Internal — only VaylCardFace.swift initialises this.
//

import SwiftUI

/// Mode selection card face. Displays title, subtitle, and orbit animation.
/// Full design is pending mock-up review — this stub compiles and renders a placeholder.
// STUB — this entire body will be replaced after design review
internal struct ModeFaceContent: View {

    let title:    String
    let subtitle: String
    let orbit:    OrbitStyle

    var body: some View {
        VStack(spacing: 12) {
            // Orbit placeholder — replace with real orbit animation after design review
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                .frame(width: 32, height: 32)

            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .padding(20)
    }
}
