//
//  DeckGlyph.swift
//  Vayl — Play
//
//  A small starter set of monoline spectrum symbols, one per category (some
//  shared). OB stroke language: 1D outline, spectrum gradient. Expand the set
//  later; `DeckGlyphKind(for:)` is the only thing that maps category → mark.
//

import SwiftUI

enum DeckGlyphKind: CaseIterable {
    case cards      // foundationEntry, soloPrep
    case spark      // wildcard, experienceArc
    case knot       // relationshipCore, nmSpecific
    case compass    // identityDynamics, styleSpecific
    case network    // multiPerson
    case key        // advancedExperienced

    init(for category: DeckCategory) {
        switch category {
        case .foundationEntry, .soloPrep:        self = .cards
        case .wildcard, .experienceArc:          self = .spark
        case .relationshipCore, .nmSpecific:     self = .knot
        case .identityDynamics, .styleSpecific:  self = .compass
        case .multiPerson:                       self = .network
        case .advancedExperienced:               self = .key
        }
    }

    /// Monoline path defined in a 44 × 40 box.
    var path: Path {
        var p = Path()
        switch self {
        case .cards:
            // three fanned rounded cards
            for (cx, deg) in [(15.0, -16.0), (22.0, 0.0), (29.0, 16.0)] {
                let rect = CGRect(x: cx - 9, y: 9, width: 18, height: 24)
                let m = CGAffineTransform(translationX: -rect.midX, y: -rect.midY)
                    .concatenating(CGAffineTransform(rotationAngle: deg * .pi / 180))
                    .concatenating(CGAffineTransform(translationX: rect.midX, y: rect.midY))
                p.addPath(Path(roundedRect: rect, cornerRadius: 3).applying(m))
            }
        case .spark:
            p.move(to: .init(x: 22, y: 6));  p.addLine(to: .init(x: 22, y: 34))
            p.move(to: .init(x: 8, y: 20));  p.addLine(to: .init(x: 36, y: 20))
            p.move(to: .init(x: 12, y: 10)); p.addLine(to: .init(x: 32, y: 30))
            p.move(to: .init(x: 32, y: 10)); p.addLine(to: .init(x: 12, y: 30))
        case .knot:
            p.addEllipse(in: .init(x: 7, y: 12, width: 16, height: 16))
            p.addEllipse(in: .init(x: 21, y: 12, width: 16, height: 16))
        case .compass:
            p.addEllipse(in: .init(x: 9, y: 7, width: 26, height: 26))
            p.move(to: .init(x: 22, y: 12))
            p.addLine(to: .init(x: 27, y: 23))
            p.addLine(to: .init(x: 22, y: 28))
            p.addLine(to: .init(x: 17, y: 23))
            p.closeSubpath()
        case .network:
            let nodes: [CGPoint] = [.init(x: 22, y: 8), .init(x: 10, y: 30), .init(x: 34, y: 30)]
            for i in 0..<3 { p.move(to: nodes[i]); p.addLine(to: nodes[(i + 1) % 3]) }
            for n in nodes { p.addEllipse(in: .init(x: n.x - 3, y: n.y - 3, width: 6, height: 6)) }
        case .key:
            p.addEllipse(in: .init(x: 8, y: 11, width: 14, height: 14))
            p.move(to: .init(x: 21, y: 18)); p.addLine(to: .init(x: 37, y: 18))
            p.move(to: .init(x: 31, y: 18)); p.addLine(to: .init(x: 31, y: 24))
            p.move(to: .init(x: 37, y: 18)); p.addLine(to: .init(x: 37, y: 26))
        }
        return p
    }
}

/// Draws a `DeckGlyphKind` as a spectrum-stroked monoline mark, scaled to fit.
/// `tint` overrides the spectrum (used dimmed on sealed cases).
struct DeckGlyph: View {
    let kind: DeckGlyphKind
    var lineWidth: CGFloat = 2
    var tint: Color?

    var body: some View {
        GeometryReader { geo in
            let s  = min(geo.size.width / 44, geo.size.height / 40)
            let dx = (geo.size.width  - 44 * s) / 2
            let dy = (geo.size.height - 40 * s) / 2
            kind.path
                .applying(CGAffineTransform(scaleX: s, y: s)
                    .concatenating(CGAffineTransform(translationX: dx, y: dy)))
                .stroke(stroke, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        }
    }

    private var stroke: AnyShapeStyle {
        if let tint { return AnyShapeStyle(tint) }
        return AnyShapeStyle(LinearGradient(
            colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
            startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}

#if DEBUG
#Preview("Glyphs") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        HStack(spacing: AppSpacing.md) {
            ForEach(Array(DeckGlyphKind.allCases.enumerated()), id: \.offset) { _, k in
                DeckGlyph(kind: k).frame(width: 36, height: 33)
            }
        }
    }
    .preferredColorScheme(.dark)
}
#endif
