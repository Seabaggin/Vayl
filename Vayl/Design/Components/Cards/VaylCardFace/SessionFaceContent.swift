//
//  SessionFaceContent.swift
//  Vayl
//
//  Created by Claude Code Agent.
//
//  Design/Components/Cards/VaylCardFace/SessionFaceContent.swift
//
//  Session prompt card face — prompt text with highlighted keywords.
//  STUB — full implementation pending design review.
//  Internal — only VaylCardFace.swift initialises this.
//

import SwiftUI

// STUB — full implementation pending
internal struct SessionFaceContent: View {
    let prompt:     String
    let highlights: [String]

    var body: some View {
        Text(prompt)
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(20)
    }
}
