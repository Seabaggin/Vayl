//
//  AnimatedSignature.swift
//  Vayl
//
//  Created by Bryan Jorden on 6/13/26.
//
//  Native SwiftUI draw-on of the founder's handwritten signature, played once
//  when the founder letter settles (FounderLetterPhase, Beat 8).
//
//  Feel notes:
//   · The signature draws as its THREE natural pen-strokes — first name, middle
//     initial, last name — each eased in/out, with a brief pen-lift pause
//     between. That lift cadence is what gives the draw its weight; a single
//     uniform sweep across all three reads as a mechanical wipe.
//   · Every stroke is rendered in two passes — a blurred spectrum glow and a
//     crisp spectrum line — matching the OB two-render-pass rule and echoing the
//     spectrum VAYL wordmark at the top of the letter.
//

import SwiftUI

struct AnimatedSignature: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Per-stroke trim progress (0 → 1). One state value per pen-stroke so each
    // animates independently and the gaps between them read as pen-lifts.
    @State private var firstProgress:  CGFloat = 0
    @State private var middleProgress: CGFloat = 0
    @State private var lastProgress:   CGFloat = 0

    // MARK: - Stroke styling

    /// Crisp + glow share one width; the glow pass is just blurred and dimmed.
    private let lineStyle = StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
    private let glowBlur: CGFloat = 6
    private let glowOpacity: Double = 0.6

    // MARK: - Timing (deliberate, hand-paced)
    //
    // Durations are roughly proportional to each name's length so the pen keeps
    // a steady speed. The pen-lift gaps are the weight. Tune freely on device.

    private let startDelay:     Double = 0.4
    private let firstDuration:  Double = 1.5
    private let middleDuration: Double = 0.55
    private let lastDuration:   Double = 1.2
    private let penLift:        Double = 0.22

    var body: some View {
        ZStack {
            strokeView(.first,  progress: firstProgress)
            strokeView(.middle, progress: middleProgress)
            strokeView(.last,   progress: lastProgress)
        }
        .onAppear(perform: play)
        .accessibilityLabel("Founder's signature")
    }

    // MARK: - One pen-stroke, two render passes

    private func strokeView(_ stroke: SignatureGeometry.Stroke, progress: CGFloat) -> some View {
        let trimmed = SignatureStroke(stroke: stroke).trim(from: 0, to: progress)
        return ZStack {
            // Glow pass — blurred, low opacity spectrum bloom.
            trimmed
                .stroke(AppColors.spectrumText, style: lineStyle)
                .blur(radius: glowBlur)
                .opacity(glowOpacity)

            // Crisp pass — full opacity spectrum line.
            trimmed
                .stroke(AppColors.spectrumText, style: lineStyle)
        }
    }

    // MARK: - Playback

    private func play() {
        guard !reduceMotion else {
            // Reduce Motion — show the finished signature with no draw-on.
            firstProgress = 1; middleProgress = 1; lastProgress = 1
            return
        }

        let middleStart = startDelay + firstDuration + penLift
        let lastStart   = middleStart + middleDuration + penLift

        withAnimation(.easeInOut(duration: firstDuration).delay(startDelay)) {
            firstProgress = 1
        }
        withAnimation(.easeInOut(duration: middleDuration).delay(middleStart)) {
            middleProgress = 1
        }
        withAnimation(.easeInOut(duration: lastDuration).delay(lastStart)) {
            lastProgress = 1
        }
    }
}

// MARK: - Stroke shape

/// A single pen-stroke of the signature, aspect-fit and centred into its frame
/// using the geometry's shared transform (so all three strokes stay aligned).
fileprivate struct SignatureStroke: Shape {
    let stroke: SignatureGeometry.Stroke

    func path(in rect: CGRect) -> Path {
        SignatureGeometry.path(for: stroke, in: rect)
    }
}

// MARK: - Signature geometry

/// Builds the signature's three pen-strokes and fits them, as a group, into a
/// target rect. Coordinates were authored against a 250×100 reference box; the
/// real ink only occupies the upper-left of that box, so every stroke is
/// aspect-fit and centred against the *union* of all three bounding boxes. That
/// keeps the strokes aligned to each other AND lets the full cyan→magenta
/// spectrum read across the whole signature.
fileprivate enum SignatureGeometry {

    enum Stroke: CaseIterable { case first, middle, last }

    /// Reference box the normalized path coordinates were drawn against.
    private static let refWidth:  CGFloat = 250
    private static let refHeight: CGFloat = 100

    // MARK: Typesetting (tunable)
    //
    // The traced names sit at their own positions and baselines, so left alone
    // they stair-step with wide gaps. We re-lay them out as a single row: packed
    // left→right with `strokeGap` between names, each shifted so its `baseline`
    // sits on one common line (descenders hang below it naturally). Metrics are
    // measured from the traced paths (ref space, 250×100) — tweak `strokeGap` to
    // tighten/loosen spacing, or a stroke's `baseline` to nudge it onto the line.

    /// Horizontal space between names (ref space).
    private static let strokeGap: CGFloat = 7
    /// Inset so round caps / descenders / glow don't clip the frame edge.
    private static let edgePad: CGFloat = 5

    private struct Metrics {
        let minX, maxX, minY, maxY, baseline: CGFloat
        var width: CGFloat { maxX - minX }
    }

    private static func metrics(_ s: Stroke) -> Metrics {
        switch s {
        case .first:  return Metrics(minX:  22.53, maxX:  61.29, minY: 7.60, maxY: 46.70, baseline: 39.74)
        case .middle: return Metrics(minX:  77.16, maxX:  92.68, minY: 9.93, maxY: 35.12, baseline: 33.22)
        case .last:   return Metrics(minX: 107.40, maxX: 141.83, minY: 6.43, maxY: 34.36, baseline: 33.50)
        }
    }

    private static func rawPath(_ s: Stroke) -> Path {
        switch s {
        case .first:  return firstName()
        case .middle: return middleInitial()
        case .last:   return lastName()
        }
    }

    /// Left edge where `s` is placed in the packed row.
    private static func placedMinX(_ s: Stroke) -> CGFloat {
        var x: CGFloat = 0
        for stroke in Stroke.allCases {
            if stroke == s { return x }
            x += metrics(stroke).width + strokeGap
        }
        return x
    }

    /// Move `s` into the row: left edge → its slot, baseline → y = 0.
    private static func placement(_ s: Stroke) -> CGAffineTransform {
        let m = metrics(s)
        return CGAffineTransform(translationX: placedMinX(s) - m.minX, y: -m.baseline)
    }

    /// Bounds of the whole laid-out row (analytic — no path building).
    private static func rowBounds() -> CGRect {
        let totalWidth = Stroke.allCases.reduce(CGFloat(0)) { $0 + metrics($1).width }
            + strokeGap * CGFloat(Stroke.allCases.count - 1)
        let minY = Stroke.allCases.map { metrics($0).minY - metrics($0).baseline }.min() ?? 0
        let maxY = Stroke.allCases.map { metrics($0).maxY - metrics($0).baseline }.max() ?? 0
        return CGRect(x: 0, y: minY, width: totalWidth, height: maxY - minY)
    }

    static func path(for stroke: Stroke, in rect: CGRect) -> Path {
        rawPath(stroke)
            .applying(placement(stroke))
            .applying(fitTransform(in: rect))
    }

    /// Aspect-fit + centre the laid-out row into `rect`, inset by `edgePad`.
    private static func fitTransform(in rect: CGRect) -> CGAffineTransform {
        let area = rect.insetBy(dx: edgePad, dy: edgePad)
        let union = rowBounds()
        guard union.width > 0, union.height > 0, area.width > 0, area.height > 0 else { return .identity }

        let scale = min(area.width / union.width, area.height / union.height)
        let tx = area.minX + (area.width  - union.width  * scale) / 2 - union.minX * scale
        let ty = area.minY + (area.height - union.height * scale) / 2 - union.minY * scale

        return CGAffineTransform(scaleX: scale, y: scale)
            .concatenating(CGAffineTransform(translationX: tx, y: ty))
    }

    // MARK: Raw strokes (250×100 reference space)

    private static func firstName() -> Path {
        var path = Path()
        let width = refWidth
        let height = refHeight

        path.move(to: CGPoint(x: 0.09012*width, y: 0.30501*height))
        path.addCurve(to: CGPoint(x: 0.10398*width, y: 0.26113*height), control1: CGPoint(x: 0.09012*width, y: 0.29068*height), control2: CGPoint(x: 0.10056*width, y: 0.27125*height))
        path.addCurve(to: CGPoint(x: 0.14295*width, y: 0.16413*height), control1: CGPoint(x: 0.11588*width, y: 0.22585*height), control2: CGPoint(x: 0.13038*width, y: 0.19765*height))
        path.addCurve(to: CGPoint(x: 0.16807*width, y: 0.10408*height), control1: CGPoint(x: 0.15097*width, y: 0.14275*height), control2: CGPoint(x: 0.15953*width, y: 0.12399*height))
        path.addCurve(to: CGPoint(x: 0.17846*width, y: 0.07867*height), control1: CGPoint(x: 0.1715*width, y: 0.09606*height), control2: CGPoint(x: 0.17481*width, y: 0.08597*height))
        path.addCurve(to: CGPoint(x: 0.18019*width, y: 0.07636*height), control1: CGPoint(x: 0.17898*width, y: 0.07764*height), control2: CGPoint(x: 0.17983*width, y: 0.07493*height))
        path.addCurve(to: CGPoint(x: 0.16807*width, y: 0.14796*height), control1: CGPoint(x: 0.18264*width, y: 0.08617*height), control2: CGPoint(x: 0.16981*width, y: 0.13969*height))
        path.addCurve(to: CGPoint(x: 0.13342*width, y: 0.3027*height), control1: CGPoint(x: 0.15705*width, y: 0.2002*height), control2: CGPoint(x: 0.14555*width, y: 0.25238*height))
        path.addCurve(to: CGPoint(x: 0.12649*width, y: 0.33042*height), control1: CGPoint(x: 0.13117*width, y: 0.31204*height), control2: CGPoint(x: 0.12822*width, y: 0.32031*height))
        path.addCurve(to: CGPoint(x: 0.1161*width, y: 0.3974*height), control1: CGPoint(x: 0.1227*width, y: 0.35268*height), control2: CGPoint(x: 0.12021*width, y: 0.37546*height))
        path.addCurve(to: CGPoint(x: 0.11264*width, y: 0.41125*height), control1: CGPoint(x: 0.11559*width, y: 0.40011*height), control2: CGPoint(x: 0.11412*width, y: 0.41125*height))
        path.addCurve(to: CGPoint(x: 0.11523*width, y: 0.38354*height), control1: CGPoint(x: 0.10982*width, y: 0.41125*height), control2: CGPoint(x: 0.11479*width, y: 0.38593*height))
        path.addCurve(to: CGPoint(x: 0.13082*width, y: 0.30963*height), control1: CGPoint(x: 0.11994*width, y: 0.35846*height), control2: CGPoint(x: 0.12509*width, y: 0.33326*height))
        path.addCurve(to: CGPoint(x: 0.17153*width, y: 0.14334*height), control1: CGPoint(x: 0.14435*width, y: 0.2539*height), control2: CGPoint(x: 0.15594*width, y: 0.19533*height))
        path.addCurve(to: CGPoint(x: 0.19058*width, y: 0.10177*height), control1: CGPoint(x: 0.17684*width, y: 0.12563*height), control2: CGPoint(x: 0.18333*width, y: 0.11283*height))
        path.addCurve(to: CGPoint(x: 0.19491*width, y: 0.09484*height), control1: CGPoint(x: 0.19205*width, y: 0.09954*height), control2: CGPoint(x: 0.19398*width, y: 0.09111*height))
        path.addCurve(to: CGPoint(x: 0.19058*width, y: 0.13179*height), control1: CGPoint(x: 0.19754*width, y: 0.10536*height), control2: CGPoint(x: 0.19216*width, y: 0.1241*height))
        path.addCurve(to: CGPoint(x: 0.16027*width, y: 0.24265*height), control1: CGPoint(x: 0.18232*width, y: 0.17221*height), control2: CGPoint(x: 0.17305*width, y: 0.21102*height))
        path.addCurve(to: CGPoint(x: 0.15421*width, y: 0.25651*height), control1: CGPoint(x: 0.15832*width, y: 0.24748*height), control2: CGPoint(x: 0.15618*width, y: 0.25174*height))
        path.addCurve(to: CGPoint(x: 0.14555*width, y: 0.28423*height), control1: CGPoint(x: 0.15343*width, y: 0.2584*height), control2: CGPoint(x: 0.14477*width, y: 0.2801*height))
        path.addCurve(to: CGPoint(x: 0.15334*width, y: 0.2773*height), control1: CGPoint(x: 0.14603*width, y: 0.28679*height), control2: CGPoint(x: 0.15273*width, y: 0.27852*height))
        path.addCurve(to: CGPoint(x: 0.17413*width, y: 0.25189*height), control1: CGPoint(x: 0.1591*width, y: 0.26578*height), control2: CGPoint(x: 0.16687*width, y: 0.25576*height))
        path.addCurve(to: CGPoint(x: 0.18106*width, y: 0.2542*height), control1: CGPoint(x: 0.17538*width, y: 0.25122*height), control2: CGPoint(x: 0.18065*width, y: 0.24979*height))
        path.addCurve(to: CGPoint(x: 0.17413*width, y: 0.28885*height), control1: CGPoint(x: 0.18183*width, y: 0.26242*height), control2: CGPoint(x: 0.17565*width, y: 0.28316*height))
        path.addCurve(to: CGPoint(x: 0.14641*width, y: 0.36506*height), control1: CGPoint(x: 0.16632*width, y: 0.31799*height), control2: CGPoint(x: 0.15647*width, y: 0.34161*height))
        path.addCurve(to: CGPoint(x: 0.13862*width, y: 0.38123*height), control1: CGPoint(x: 0.14407*width, y: 0.37053*height), control2: CGPoint(x: 0.14076*width, y: 0.37553*height))
        path.addCurve(to: CGPoint(x: 0.13602*width, y: 0.39047*height), control1: CGPoint(x: 0.13789*width, y: 0.38318*height), control2: CGPoint(x: 0.13758*width, y: 0.39047*height))
        path.addCurve(to: CGPoint(x: 0.13689*width, y: 0.38585*height), control1: CGPoint(x: 0.13537*width, y: 0.39047*height), control2: CGPoint(x: 0.13648*width, y: 0.38719*height))
        path.addCurve(to: CGPoint(x: 0.13948*width, y: 0.37892*height), control1: CGPoint(x: 0.13765*width, y: 0.3833*height), control2: CGPoint(x: 0.13862*width, y: 0.38123*height))
        path.addCurve(to: CGPoint(x: 0.14381*width, y: 0.36968*height), control1: CGPoint(x: 0.14195*width, y: 0.37234*height), control2: CGPoint(x: 0.14054*width, y: 0.37551*height))
        path.addCurve(to: CGPoint(x: 0.16374*width, y: 0.33735*height), control1: CGPoint(x: 0.15034*width, y: 0.35808*height), control2: CGPoint(x: 0.15687*width, y: 0.34781*height))
        path.addCurve(to: CGPoint(x: 0.17326*width, y: 0.32349*height), control1: CGPoint(x: 0.16444*width, y: 0.33628*height), control2: CGPoint(x: 0.17263*width, y: 0.32179*height))
        path.addCurve(to: CGPoint(x: 0.1698*width, y: 0.34197*height), control1: CGPoint(x: 0.17509*width, y: 0.32836*height), control2: CGPoint(x: 0.1698*width, y: 0.34197*height))
        path.addCurve(to: CGPoint(x: 0.17067*width, y: 0.33735*height), control1: CGPoint(x: 0.1698*width, y: 0.34197*height), control2: CGPoint(x: 0.17028*width, y: 0.33872*height))
        path.addCurve(to: CGPoint(x: 0.17586*width, y: 0.32118*height), control1: CGPoint(x: 0.17218*width, y: 0.33195*height), control2: CGPoint(x: 0.17424*width, y: 0.32636*height))
        path.addCurve(to: CGPoint(x: 0.19058*width, y: 0.28885*height), control1: CGPoint(x: 0.17955*width, y: 0.30939*height), control2: CGPoint(x: 0.18563*width, y: 0.29678*height))
        path.addCurve(to: CGPoint(x: 0.19925*width, y: 0.28192*height), control1: CGPoint(x: 0.19141*width, y: 0.28752*height), control2: CGPoint(x: 0.19871*width, y: 0.27908*height))
        path.addCurve(to: CGPoint(x: 0.18539*width, y: 0.33042*height), control1: CGPoint(x: 0.20092*width, y: 0.29083*height), control2: CGPoint(x: 0.18539*width, y: 0.32311*height))
        path.addCurve(to: CGPoint(x: 0.18885*width, y: 0.32349*height), control1: CGPoint(x: 0.18539*width, y: 0.33427*height), control2: CGPoint(x: 0.18773*width, y: 0.32589*height))
        path.addCurve(to: CGPoint(x: 0.19145*width, y: 0.31887*height), control1: CGPoint(x: 0.18967*width, y: 0.32176*height), control2: CGPoint(x: 0.19064*width, y: 0.3206*height))
        path.addCurve(to: CGPoint(x: 0.20531*width, y: 0.29116*height), control1: CGPoint(x: 0.19302*width, y: 0.31553*height), control2: CGPoint(x: 0.20377*width, y: 0.28704*height))
        path.addCurve(to: CGPoint(x: 0.19925*width, y: 0.32811*height), control1: CGPoint(x: 0.20735*width, y: 0.2966*height), control2: CGPoint(x: 0.2003*width, y: 0.32391*height))
        path.addCurve(to: CGPoint(x: 0.17153*width, y: 0.42049*height), control1: CGPoint(x: 0.19112*width, y: 0.36062*height), control2: CGPoint(x: 0.18124*width, y: 0.39137*height))
        path.addCurve(to: CGPoint(x: 0.16287*width, y: 0.45283*height), control1: CGPoint(x: 0.16822*width, y: 0.43043*height), control2: CGPoint(x: 0.16584*width, y: 0.44228*height))
        path.addCurve(to: CGPoint(x: 0.162*width, y: 0.46207*height), control1: CGPoint(x: 0.16103*width, y: 0.45937*height), control2: CGPoint(x: 0.16264*width, y: 0.45524*height))
        path.addCurve(to: CGPoint(x: 0.16114*width, y: 0.46668*height), control1: CGPoint(x: 0.16185*width, y: 0.46374*height), control2: CGPoint(x: 0.16085*width, y: 0.46822*height))
        path.addCurve(to: CGPoint(x: 0.2105*width, y: 0.31887*height), control1: CGPoint(x: 0.17135*width, y: 0.4122*height), control2: CGPoint(x: 0.1932*width, y: 0.35732*height))
        path.addCurve(to: CGPoint(x: 0.22436*width, y: 0.28192*height), control1: CGPoint(x: 0.21493*width, y: 0.30903*height), control2: CGPoint(x: 0.21919*width, y: 0.28881*height))
        path.addCurve(to: CGPoint(x: 0.2261*width, y: 0.28192*height), control1: CGPoint(x: 0.22488*width, y: 0.28123*height), control2: CGPoint(x: 0.22578*width, y: 0.28064*height))
        path.addCurve(to: CGPoint(x: 0.22003*width, y: 0.32349*height), control1: CGPoint(x: 0.22825*width, y: 0.29055*height), control2: CGPoint(x: 0.22189*width, y: 0.31687*height))
        path.addCurve(to: CGPoint(x: 0.2157*width, y: 0.33966*height), control1: CGPoint(x: 0.21977*width, y: 0.32441*height), control2: CGPoint(x: 0.21534*width, y: 0.33933*height))
        path.addCurve(to: CGPoint(x: 0.2261*width, y: 0.3258*height), control1: CGPoint(x: 0.21737*width, y: 0.34114*height), control2: CGPoint(x: 0.22456*width, y: 0.32814*height))
        path.addCurve(to: CGPoint(x: 0.24515*width, y: 0.30501*height), control1: CGPoint(x: 0.2319*width, y: 0.31695*height), control2: CGPoint(x: 0.23826*width, y: 0.30501*height))

        return path
    }

    private static func middleInitial() -> Path {
        var path = Path()
        let width = refWidth
        let height = refHeight

        path.move(to: CGPoint(x: 0.33869*width, y: 0.11563*height))
        path.addCurve(to: CGPoint(x: 0.33436*width, y: 0.16644*height), control1: CGPoint(x: 0.33566*width, y: 0.13175*height), control2: CGPoint(x: 0.33559*width, y: 0.14892*height))
        path.addCurve(to: CGPoint(x: 0.32829*width, y: 0.23803*height), control1: CGPoint(x: 0.33267*width, y: 0.19042*height), control2: CGPoint(x: 0.33024*width, y: 0.21419*height))
        path.addCurve(to: CGPoint(x: 0.3153*width, y: 0.33042*height), control1: CGPoint(x: 0.32568*width, y: 0.27008*height), control2: CGPoint(x: 0.32142*width, y: 0.30185*height))
        path.addCurve(to: CGPoint(x: 0.30924*width, y: 0.35121*height), control1: CGPoint(x: 0.31367*width, y: 0.33804*height), control2: CGPoint(x: 0.31243*width, y: 0.34908*height))
        path.addCurve(to: CGPoint(x: 0.31011*width, y: 0.32118*height), control1: CGPoint(x: 0.30747*width, y: 0.35238*height), control2: CGPoint(x: 0.3101*width, y: 0.32124*height))
        path.addCurve(to: CGPoint(x: 0.31963*width, y: 0.2542*height), control1: CGPoint(x: 0.31271*width, y: 0.2986*height), control2: CGPoint(x: 0.31625*width, y: 0.2761*height))
        path.addCurve(to: CGPoint(x: 0.35168*width, y: 0.11563*height), control1: CGPoint(x: 0.32765*width, y: 0.20226*height), control2: CGPoint(x: 0.33595*width, y: 0.15407*height))
        path.addCurve(to: CGPoint(x: 0.35774*width, y: 0.09946*height), control1: CGPoint(x: 0.35379*width, y: 0.11048*height), control2: CGPoint(x: 0.35497*width, y: 0.10131*height))
        path.addCurve(to: CGPoint(x: 0.35601*width, y: 0.13641*height), control1: CGPoint(x: 0.36203*width, y: 0.0966*height), control2: CGPoint(x: 0.35818*width, y: 0.12399*height))
        path.addCurve(to: CGPoint(x: 0.35254*width, y: 0.15489*height), control1: CGPoint(x: 0.35492*width, y: 0.14265*height), control2: CGPoint(x: 0.35387*width, y: 0.14899*height))
        path.addCurve(to: CGPoint(x: 0.33263*width, y: 0.23342*height), control1: CGPoint(x: 0.34642*width, y: 0.18209*height), control2: CGPoint(x: 0.33996*width, y: 0.20827*height))
        path.addCurve(to: CGPoint(x: 0.32916*width, y: 0.24727*height), control1: CGPoint(x: 0.33135*width, y: 0.2378*height), control2: CGPoint(x: 0.32769*width, y: 0.24335*height))
        path.addCurve(to: CGPoint(x: 0.35168*width, y: 0.24496*height), control1: CGPoint(x: 0.32989*width, y: 0.24922*height), control2: CGPoint(x: 0.34876*width, y: 0.2433*height))
        path.addCurve(to: CGPoint(x: 0.369*width, y: 0.28192*height), control1: CGPoint(x: 0.35869*width, y: 0.24897*height), control2: CGPoint(x: 0.36582*width, y: 0.26493*height))
        path.addCurve(to: CGPoint(x: 0.37073*width, y: 0.3027*height), control1: CGPoint(x: 0.37036*width, y: 0.28915*height), control2: CGPoint(x: 0.36942*width, y: 0.29571*height))

        return path
    }

    private static func lastName() -> Path {
        var path = Path()
        let width = refWidth
        let height = refHeight

        path.move(to: CGPoint(x: 0.49285*width, y: 0.29578*height))
        path.addCurve(to: CGPoint(x: 0.49458*width, y: 0.29347*height), control1: CGPoint(x: 0.49343*width, y: 0.295*height), control2: CGPoint(x: 0.49504*width, y: 0.29468*height))
        path.addCurve(to: CGPoint(x: 0.47466*width, y: 0.28423*height), control1: CGPoint(x: 0.49373*width, y: 0.29119*height), control2: CGPoint(x: 0.47672*width, y: 0.2854*height))
        path.addCurve(to: CGPoint(x: 0.43482*width, y: 0.21956*height), control1: CGPoint(x: 0.46068*width, y: 0.27624*height), control2: CGPoint(x: 0.43862*width, y: 0.26346*height))
        path.addCurve(to: CGPoint(x: 0.44782*width, y: 0.15258*height), control1: CGPoint(x: 0.43266*width, y: 0.19453*height), control2: CGPoint(x: 0.44234*width, y: 0.169*height))
        path.addCurve(to: CGPoint(x: 0.49545*width, y: 0.07405*height), control1: CGPoint(x: 0.46043*width, y: 0.11474*height), control2: CGPoint(x: 0.47823*width, y: 0.09339*height))
        path.addCurve(to: CGPoint(x: 0.51277*width, y: 0.06482*height), control1: CGPoint(x: 0.50081*width, y: 0.06804*height), control2: CGPoint(x: 0.50682*width, y: 0.06255*height))
        path.addCurve(to: CGPoint(x: 0.51364*width, y: 0.08791*height), control1: CGPoint(x: 0.51635*width, y: 0.06618*height), control2: CGPoint(x: 0.51431*width, y: 0.08295*height))
        path.addCurve(to: CGPoint(x: 0.49458*width, y: 0.16182*height), control1: CGPoint(x: 0.51004*width, y: 0.11429*height), control2: CGPoint(x: 0.50064*width, y: 0.13921*height))
        path.addCurve(to: CGPoint(x: 0.44868*width, y: 0.29578*height), control1: CGPoint(x: 0.48134*width, y: 0.21127*height), control2: CGPoint(x: 0.46516*width, y: 0.25394*height))
        path.addCurve(to: CGPoint(x: 0.44089*width, y: 0.31425*height), control1: CGPoint(x: 0.44616*width, y: 0.30217*height), control2: CGPoint(x: 0.44359*width, y: 0.30841*height))
        path.addCurve(to: CGPoint(x: 0.42963*width, y: 0.33966*height), control1: CGPoint(x: 0.4401*width, y: 0.31595*height), control2: CGPoint(x: 0.42909*width, y: 0.33538*height))
        path.addCurve(to: CGPoint(x: 0.44782*width, y: 0.3258*height), control1: CGPoint(x: 0.4313*width, y: 0.35301*height), control2: CGPoint(x: 0.44647*width, y: 0.32809*height))
        path.addCurve(to: CGPoint(x: 0.49112*width, y: 0.2542*height), control1: CGPoint(x: 0.46113*width, y: 0.3032*height), control2: CGPoint(x: 0.47506*width, y: 0.26134*height))
        path.addCurve(to: CGPoint(x: 0.48506*width, y: 0.28654*height), control1: CGPoint(x: 0.49826*width, y: 0.25103*height), control2: CGPoint(x: 0.48623*width, y: 0.28418*height))
        path.addCurve(to: CGPoint(x: 0.48246*width, y: 0.29347*height), control1: CGPoint(x: 0.48408*width, y: 0.2885*height), control2: CGPoint(x: 0.48333*width, y: 0.29116*height))
        path.addCurve(to: CGPoint(x: 0.48073*width, y: 0.29578*height), control1: CGPoint(x: 0.482*width, y: 0.29468*height), control2: CGPoint(x: 0.48027*width, y: 0.29456*height))
        path.addCurve(to: CGPoint(x: 0.49718*width, y: 0.2773*height), control1: CGPoint(x: 0.48306*width, y: 0.30199*height), control2: CGPoint(x: 0.49467*width, y: 0.27059*height))
        path.addCurve(to: CGPoint(x: 0.49285*width, y: 0.30039*height), control1: CGPoint(x: 0.4978*width, y: 0.27895*height), control2: CGPoint(x: 0.49285*width, y: 0.29727*height))
        path.addCurve(to: CGPoint(x: 0.49805*width, y: 0.30039*height), control1: CGPoint(x: 0.49285*width, y: 0.30939*height), control2: CGPoint(x: 0.49683*width, y: 0.30299*height))
        path.addCurve(to: CGPoint(x: 0.51017*width, y: 0.26344*height), control1: CGPoint(x: 0.50274*width, y: 0.29039*height), control2: CGPoint(x: 0.50639*width, y: 0.27555*height))
        path.addCurve(to: CGPoint(x: 0.53962*width, y: 0.13641*height), control1: CGPoint(x: 0.522*width, y: 0.22561*height), control2: CGPoint(x: 0.52973*width, y: 0.17785*height))
        path.addCurve(to: CGPoint(x: 0.54828*width, y: 0.11101*height), control1: CGPoint(x: 0.54215*width, y: 0.12581*height), control2: CGPoint(x: 0.54415*width, y: 0.11762*height))
        path.addCurve(to: CGPoint(x: 0.55002*width, y: 0.1087*height), control1: CGPoint(x: 0.54884*width, y: 0.11012*height), control2: CGPoint(x: 0.54966*width, y: 0.10727*height))
        path.addCurve(to: CGPoint(x: 0.53875*width, y: 0.16644*height), control1: CGPoint(x: 0.55172*width, y: 0.11553*height), control2: CGPoint(x: 0.54036*width, y: 0.15976*height))
        path.addCurve(to: CGPoint(x: 0.5171*width, y: 0.24265*height), control1: CGPoint(x: 0.53222*width, y: 0.19356*height), control2: CGPoint(x: 0.52511*width, y: 0.21846*height))
        path.addCurve(to: CGPoint(x: 0.50151*width, y: 0.29808*height), control1: CGPoint(x: 0.51223*width, y: 0.25737*height), control2: CGPoint(x: 0.50394*width, y: 0.2787*height))
        path.addCurve(to: CGPoint(x: 0.50671*width, y: 0.30732*height), control1: CGPoint(x: 0.50038*width, y: 0.30717*height), control2: CGPoint(x: 0.50423*width, y: 0.30953*height))
        path.addCurve(to: CGPoint(x: 0.51277*width, y: 0.29578*height), control1: CGPoint(x: 0.5075*width, y: 0.30662*height), control2: CGPoint(x: 0.51266*width, y: 0.29597*height))
        path.addCurve(to: CGPoint(x: 0.52576*width, y: 0.2773*height), control1: CGPoint(x: 0.51694*width, y: 0.28882*height), control2: CGPoint(x: 0.52164*width, y: 0.28462*height))
        path.addCurve(to: CGPoint(x: 0.53269*width, y: 0.27037*height), control1: CGPoint(x: 0.5267*width, y: 0.27564*height), control2: CGPoint(x: 0.53108*width, y: 0.26606*height))
        path.addCurve(to: CGPoint(x: 0.53096*width, y: 0.28192*height), control1: CGPoint(x: 0.53449*width, y: 0.27515*height), control2: CGPoint(x: 0.53161*width, y: 0.27974*height))
        path.addCurve(to: CGPoint(x: 0.5249*width, y: 0.3027*height), control1: CGPoint(x: 0.5289*width, y: 0.28877*height), control2: CGPoint(x: 0.5249*width, y: 0.3027*height))
        path.addCurve(to: CGPoint(x: 0.52923*width, y: 0.29116*height), control1: CGPoint(x: 0.5249*width, y: 0.3027*height), control2: CGPoint(x: 0.52779*width, y: 0.295*height))
        path.addCurve(to: CGPoint(x: 0.53789*width, y: 0.27499*height), control1: CGPoint(x: 0.53163*width, y: 0.28477*height), control2: CGPoint(x: 0.5347*width, y: 0.27839*height))
        path.addCurve(to: CGPoint(x: 0.55175*width, y: 0.27268*height), control1: CGPoint(x: 0.54335*width, y: 0.26916*height), control2: CGPoint(x: 0.54645*width, y: 0.27444*height))
        path.addCurve(to: CGPoint(x: 0.56734*width, y: 0.26806*height), control1: CGPoint(x: 0.55721*width, y: 0.27086*height), control2: CGPoint(x: 0.56175*width, y: 0.26806*height))

        return path
    }
}

// MARK: - Preview

#Preview("Signature draw-on") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        AnimatedSignature()
            .frame(width: 280, height: 110)
    }
    .preferredColorScheme(.dark)
}
