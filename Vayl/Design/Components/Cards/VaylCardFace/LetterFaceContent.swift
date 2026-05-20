//
//  LetterFaceContent.swift
//  Vayl
//
//  Created by Claude Code Agent.
//
//  Design/Components/Cards/VaylCardFace/LetterFaceContent.swift
//
//  Founder letter card face — personalised letter with name and body.
//  STUB — full implementation pending design review.
//  Internal — only VaylCardFace.swift initialises this.
//

import SwiftUI

// STUB — full implementation pending
internal struct LetterFaceContent: View {
    let name:       String
    let letterBody: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(name).font(.system(size: 14, weight: .semibold, design: .monospaced)).foregroundStyle(.white)
            Text(letterBody).font(.system(size: 11, weight: .regular, design: .monospaced)).foregroundStyle(.white.opacity(0.8))
        }
        .padding(20)
    }
}
