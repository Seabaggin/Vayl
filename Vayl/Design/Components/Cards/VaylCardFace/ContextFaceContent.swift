//
//  ContextFaceContent.swift
//  Vayl
//
//  Created by Claude Code Agent.
//
//  Design/Components/Cards/VaylCardFace/ContextFaceContent.swift
//
//  Context selection card face — numbered card with title, subtitle, detail copy.
//  STUB — full implementation pending design review.
//  Internal — only VaylCardFace.swift initialises this.
//

import SwiftUI

// STUB — full implementation pending
internal struct ContextFaceContent: View {
    let number:   String
    let title:    String
    let subtitle: String
    let detail:   String

    var body: some View {
        VStack(spacing: 8) {
            Text(number).font(.system(size: 11)).foregroundStyle(.white.opacity(0.3))
            Text(title).font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
            Text(subtitle).font(.system(size: 11)).foregroundStyle(.white.opacity(0.5))
            Text(detail).font(.system(size: 10)).foregroundStyle(.white.opacity(0.35))
        }
        .padding(20)
    }
}
