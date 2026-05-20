//
//  VaylCardFace.swift
//  Vayl
//
//  Design/Components/Cards/VaylCardFace.swift
//  (file stays at original path for now — move to subfolder in next Xcode refactor session)
//
//  Public router. Switches on VaylCardContent and delegates to the correct private face.
//  This file stays small. All rendering logic lives in the individual face files.
//  To add a new face type: add a case to VaylCardContent, create a new face file, add a case here.
//

import SwiftUI

/// Public card face router.
/// Accepts a VaylCardContent value and renders the correct face.
/// Accepts an optional onAction closure — pass this from the phase, not from VaylCardRenderer.
/// VaylCardRenderer passes it through without inspecting it.
public struct VaylCardFace: View {

    public let content:  VaylCardContent
    public var onAction: ((VaylCardAction) -> Void)? = nil

    public init(content: VaylCardContent, onAction: ((VaylCardAction) -> Void)? = nil) {
        self.content  = content
        self.onAction = onAction
    }

    public var body: some View {
        switch content {

        case .portal(let startDate):
            PortalFaceContent(startDate: startDate)

        case .mode(let title, let subtitle, let orbit):
            ModeFaceContent(title: title, subtitle: subtitle, orbit: orbit)

        case .context(let number, let title, let subtitle, let detail):
            ContextFaceContent(number: number, title: title, subtitle: subtitle, detail: detail)

        case .curiosity(let category):
            CuriosityFaceContent(category: category)

        case .session(let prompt, let highlights):
            SessionFaceContent(prompt: prompt, highlights: highlights)

        case .letter(let name, let body):
            LetterFaceContent(name: name, letterBody: body)

        case .blank:
            Color.clear
        }
    }
}

// MARK: — Previews

#Preview("Portal Face") {
    ZStack {
        Color.black.ignoresSafeArea()
        VaylCardFace(content: .portal(startDate: Date()))
            .frame(width: 280, height: 392)
    }
    .preferredColorScheme(.dark)
}

#Preview("Mode Face — Solo") {
    ZStack {
        Color.black.ignoresSafeArea()
        VaylCardFace(content: .mode(title: "Solo Discovery", subtitle: "Just you, at your own pace", orbit: .single))
            .frame(width: 280, height: 392)
    }
    .preferredColorScheme(.dark)
}

#Preview("Context Face") {
    ZStack {
        Color.black.ignoresSafeArea()
        VaylCardFace(content: .context(number: "01", title: "We're new", subtitle: "Just getting started", detail: "Under a year together"))
            .frame(width: 280, height: 392)
    }
    .preferredColorScheme(.dark)
}
