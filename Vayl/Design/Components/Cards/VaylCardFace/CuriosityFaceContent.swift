//
//  CuriosityFaceContent.swift
//  Vayl
//
//  Created by Claude Code Agent.
//
//  Design/Components/Cards/VaylCardFace/CuriosityFaceContent.swift
//
//  Curiosity category card face — category label.
//  STUB — full implementation pending design review.
//  Internal — only VaylCardFace.swift initialises this.
//

import SwiftUI

// STUB — full implementation pending
internal struct CuriosityFaceContent: View {
    let category: String

    var body: some View {
        Text(category)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(20)
    }
}
