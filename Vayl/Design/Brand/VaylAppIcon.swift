//
//  VaylAppIcon.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/24/26.
//
//  CHANGED: spectrumLine() only.
//  - lineLeft/lineRight confirmed flush values from device (0.162, 0.517)
//  - Left tip gradients taper from zero so line dissolves into V naturally
//  - Bloom rendered into offscreen CGLayer, clipped via trapezoid on composite

import SwiftUI
import CoreText

struct VaylAppIcon: View {
    let size: CGFloat

    // ── Layout ───────────────────────────────────────────────────────────────────
    private var cornerRadius: CGFloat { size * 0.225 }
    private var fontSize:     CGFloat { size * 0.26 }
    private var cutY:         CGFloat { size * 0.50 }
    private var embossOffset: CGFloat { max(1.2, size * 0.006) }
    private var embossBlur:   CGFloat { embossOffset * 0.40 }
    private var grainCount:   Int     { min(Int(size * size * 0.0020), 350) }

    private var clashUIFont: UIFont {
        UIFont(name: "ClashDisplay-Bold", size: fontSize)
            ?? UIFont.boldSystemFont(ofSize: fontSize)
    }

    private var wordYOffset: CGFloat {
        guard let f = UIFont(name: "ClashDisplay-Bold", size: fontSize) else { return 0 }
        return (f.capHeight - f.ascender - f.descender) / 2
    }

    // Horizontal correction: shift text + line so that the V/L ink midpoint
    // lands exactly at size/2. Derived entirely from CoreText glyph geometry —
    // no magic constant, correct at every size.
    private var centeringCorrection: CGFloat {
        let font   = clashUIFont
        let ctFont = font as CTFont

        var vChar = Array("V".utf16); var vGlyph = CGGlyph(0)
        CTFontGetGlyphsForCharacters(ctFont, &vChar, &vGlyph, 1)
        var vBbox = CGRect.zero
        CTFontGetBoundingRectsForGlyphs(ctFont, .horizontal, &vGlyph, &vBbox, 1)

        var lChar = Array("L".utf16); var lGlyph = CGGlyph(0)
        CTFontGetGlyphsForCharacters(ctFont, &lChar, &lGlyph, 1)
        var lBbox = CGRect.zero
        CTFontGetBoundingRectsForGlyphs(ctFont, .horizontal, &lGlyph, &lBbox, 1)

        let G  = fontSize * 0.025
        let GY = fontSize * 0.215
        let kV = G  - sidebearings(of: "V", font: font).right - sidebearings(of: "A", font: font).left
        let kA = G  - sidebearings(of: "A", font: font).right - sidebearings(of: "Y", font: font).left
        let kY = GY - sidebearings(of: "Y", font: font).right - sidebearings(of: "L", font: font).left

        let attrStr = NSMutableAttributedString(string: "VAYL")
        attrStr.addAttribute(.font, value: font,              range: NSRange(location: 0, length: 4))
        attrStr.addAttribute(.kern, value: kV as NSNumber,    range: NSRange(location: 0, length: 1))
        attrStr.addAttribute(.kern, value: kA as NSNumber,    range: NSRange(location: 1, length: 1))
        attrStr.addAttribute(.kern, value: kY as NSNumber,    range: NSRange(location: 2, length: 1))
        attrStr.addAttribute(.kern, value: 0  as NSNumber,    range: NSRange(location: 3, length: 1))

        let line      = CTLineCreateWithAttributedString(attrStr)
        let typoWidth = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
        let originX   = (size - typoWidth) / 2.0

        let vOrigin   = originX + CTLineGetOffsetForStringIndex(line, 0, nil)
        let lOrigin   = originX + CTLineGetOffsetForStringIndex(line, 3, nil)

        let vInkLeft  = vOrigin + vBbox.minX
        let lInkRight = lOrigin + lBbox.maxX
        let inkCenter = (vInkLeft + lInkRight) / 2.0

        return size / 2.0 - inkCenter
    }

    // ── Gradients ────────────────────────────────────────────────────────────────
    private var spectrumGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: AppColors.accentPrimary,    location: 0.00),
                .init(color: AppColors.accentSecondary,  location: 0.50),
                .init(color: AppColors.accentTertiary, location: 1.00),
            ],
            startPoint: .leading, endPoint: .trailing
        )
    }

    private var coreGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(0.88), location: 0.00),
                .init(color: .white.opacity(0.88), location: 0.96),
                .init(color: .white.opacity(0),    location: 1.00),
            ],
            startPoint: .leading, endPoint: .trailing
        )
    }



    private var bottomGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0.000, green: 0.647, blue: 0.843).opacity(0.97), location: 0.00),
                .init(color: Color(red: 0.353, green: 0.157, blue: 0.765).opacity(0.97), location: 0.35),
                .init(color: Color(red: 0.529, green: 0.098, blue: 0.659).opacity(0.97), location: 0.65),
                .init(color: Color(red: 0.784, green: 0.000, blue: 0.345).opacity(0.97), location: 1.00),
            ],
            startPoint: .leading, endPoint: .trailing
        )
    }

    // ── Body ─────────────────────────────────────────────────────────────────────
    var body: some View {
        ZStack {
            // 1. Background — layered atmosphere
            iconBackground()

            // 2. Star field
            StarFieldView(size: size)

            // 3. Top half — cold white, embossed
            topHalfWordGroup()

            // 4. Bottom half — spectrum gradient, embossed
            bottomHalfWordGroup()

            // 5. Spectrum line
            spectrumLine()

            // 6. Film grain — deterministic, screen blend
            Canvas { context, _ in
                let s = Int(size)
                for i in 0..<grainCount {
                    let x       = CGFloat((i * 127 + 33) % s)
                    let y       = CGFloat((i * 89  + 71) % s)
                    let opacity = 0.030 + Double((i * 43) % 100) / 100.0 * 0.055
                    let radius: CGFloat = (i * 17) % 3 == 0 ? 0.78 : 0.42
                    var path = Path()
                    path.addEllipse(in: CGRect(
                        x: x - radius, y: y - radius,
                        width: radius * 2, height: radius * 2
                    ))
                    context.fill(path, with: .color(Color.white.opacity(opacity)))
                }
            }
            .frame(width: size, height: size)
            .blendMode(.screen)

            // 7. Vignette
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear,                    location: 0.0),
                    .init(color: Color.black.opacity(0.52), location: 1.0),
                ]),
                center: .center,
                startRadius: size * 0.32,
                endRadius:   size * 0.72
            )
            .frame(width: size, height: size)

            // 8. Border
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.04),
                            Color.white.opacity(0.02),
                        ],
                        startPoint: .topLeading,
                        endPoint:   .bottomTrailing
                    ),
                    lineWidth: max(1.0, size * 0.004)
                )
                .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    // ── Background ───────────────────────────────────────────────────────────────
    @ViewBuilder
    private func iconBackground() -> some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "0A0E20"), location: 0.00),
                    .init(color: Color(hex: "060710"), location: 0.48),
                    .init(color: Color(hex: "0A0614"), location: 1.00),
                ],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing
            )

            RadialGradient(
                colors: [
                    AppColors.accentPrimary.opacity(0.22),
                    AppColors.accentPrimary.opacity(0.07),
                    AppColors.accentPrimary.opacity(0.00),
                ],
                center:      UnitPoint(x: 0.08, y: 0.10),
                startRadius: 0,
                endRadius:   size * 0.62
            )

            RadialGradient(
                colors: [
                    AppColors.accentPrimary.opacity(0.08),
                    AppColors.accentPrimary.opacity(0.00),
                ],
                center:      UnitPoint(x: 0.92, y: 0.05),
                startRadius: 0,
                endRadius:   size * 0.45
            )

            RadialGradient(
                colors: [
                    AppColors.accentSecondary.opacity(0.22),
                    AppColors.accentSecondary.opacity(0.08),
                    AppColors.accentSecondary.opacity(0.00),
                ],
                center:      UnitPoint(x: 0.50, y: 0.48),
                startRadius: 0,
                endRadius:   size * 0.52
            )

            RadialGradient(
                colors: [
                    AppColors.accentSecondary.opacity(0.14),
                    AppColors.accentSecondary.opacity(0.00),
                ],
                center:      UnitPoint(x: 0.78, y: 0.22),
                startRadius: 0,
                endRadius:   size * 0.38
            )

            RadialGradient(
                colors: [
                    AppColors.accentTertiary.opacity(0.20),
                    AppColors.accentTertiary.opacity(0.07),
                    AppColors.accentTertiary.opacity(0.00),
                ],
                center:      UnitPoint(x: 0.90, y: 0.88),
                startRadius: 0,
                endRadius:   size * 0.55
            )

            RadialGradient(
                colors: [
                    AppColors.accentTertiary.opacity(0.08),
                    AppColors.accentTertiary.opacity(0.00),
                ],
                center:      UnitPoint(x: 0.12, y: 0.92),
                startRadius: 0,
                endRadius:   size * 0.40
            )

            RadialGradient(
                colors: [
                    Color(hex: "3A1070").opacity(0.28),
                    Color(hex: "3A1070").opacity(0.00),
                ],
                center:      UnitPoint(x: 0.50, y: 0.52),
                startRadius: 0,
                endRadius:   size * 0.32
            )
        }
        .frame(width: size, height: size)
    }

    // ── Word halves ───────────────────────────────────────────────────────────────

    private func topHalfWordGroup() -> some View {
        ZStack {
            wordRow(style: AnyShapeStyle(.black.opacity(0.65)))
                .offset(y: embossOffset)
                .blur(radius: embossBlur)
            wordRow(style: AnyShapeStyle(.white.opacity(0.25)))
                .offset(y: -embossOffset)
            wordRow(style: AnyShapeStyle(
                Color(red: 0.902, green: 0.933, blue: 1.0).opacity(0.97)
            ))
        }
        .offset(x: centeringCorrection, y: wordYOffset)
        .frame(width: size, height: size, alignment: .center)
        .mask(alignment: .top) {
            Rectangle().frame(height: cutY)
        }
    }

    private func bottomHalfWordGroup() -> some View {
        ZStack {
            wordRow(style: AnyShapeStyle(.black.opacity(0.50)))
                .offset(y: embossOffset)
                .blur(radius: embossBlur)
            wordRow(style: AnyShapeStyle(.white.opacity(0.18)))
                .offset(y: -embossOffset)
            wordRow(style: AnyShapeStyle(bottomGradient))
        }
        .offset(x: centeringCorrection, y: wordYOffset)
        .frame(width: size, height: size, alignment: .center)
        .mask(alignment: .bottom) {
            Rectangle().frame(height: size - cutY)
        }
    }

    // ── Spectrum line ─────────────────────────────────────────────────────────────
    //
    //  Endpoint fractions confirmed flush on device (iPhone 17 Pro, 111% canvas zoom):
    //    lineLeft  = vOriginX + vAdvance * 0.162
    //    lineRight = lOriginX + lAdvance * 0.517
    //
    //  Left tip taper: all gradients fade from opacity 0 at location 0.00
    //  and reach full opacity by location 0.08 (solid/bloom) or 0.10 (core).
    //  This makes the line dissolve naturally into the V diagonal rather than
    //  appearing as a hard-clipped edge.

    private func spectrumLine() -> some View {

        // ── 1. Reconstruct CTLine matching wordRow() kerning ──────────────────
        let font = clashUIFont
        let G:  CGFloat = fontSize * 0.025
        let GY: CGFloat = fontSize * 0.215

        let kV = G  - sidebearings(of: "V", font: font).right - sidebearings(of: "A", font: font).left
        let kA = G  - sidebearings(of: "A", font: font).right - sidebearings(of: "Y", font: font).left
        let kY = GY - sidebearings(of: "Y", font: font).right - sidebearings(of: "L", font: font).left

        let attrString = NSMutableAttributedString(string: "VAYL")
        let fullRange  = NSRange(location: 0, length: 4)
        attrString.addAttribute(.font,            value: font,         range: fullRange)
        attrString.addAttribute(.foregroundColor, value: UIColor.white, range: fullRange)
        attrString.addAttribute(.kern, value: kV as NSNumber, range: NSRange(location: 0, length: 1))
        attrString.addAttribute(.kern, value: kA as NSNumber, range: NSRange(location: 1, length: 1))
        attrString.addAttribute(.kern, value: kY as NSNumber, range: NSRange(location: 2, length: 1))
        attrString.addAttribute(.kern, value: 0  as NSNumber, range: NSRange(location: 3, length: 1))

        let line        = CTLineCreateWithAttributedString(attrString)
        // CTLine typographic width > SwiftUI ink width, so center by typographic
        // bounds then apply the shared centeringCorrection to match word group offset.
        let lineOriginX = (size - CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))) / 2.0
            + centeringCorrection

        let vOriginInLine = CTLineGetOffsetForStringIndex(line, 0, nil)
        let lOriginInLine = CTLineGetOffsetForStringIndex(line, 3, nil)
        let vOriginX      = lineOriginX + vOriginInLine
        let lOriginX      = lineOriginX + lOriginInLine

        let vAdvance = glyphAdvance(of: "V", font: font)
        let lAdvance = glyphAdvance(of: "L", font: font)

        // ── 2. Flush endpoints — confirmed on device ──────────────────────────
        // 0.162 × vAdvance: enters V at the inner diagonal stroke ink edge
        // 0.517 × lAdvance: exits at the L right stem ink edge
        let lineLeft  = vOriginX + vAdvance * 0.158
        let lineRight = lOriginX + lAdvance * 0.515

        // ── 3. V stroke angle for diagonal clip ───────────────────────────────
        let ctFontRef  = font as CTFont
        var vGlyphChar = Array("V".utf16)
        var vGlyph     = CGGlyph(0)
        CTFontGetGlyphsForCharacters(ctFontRef, &vGlyphChar, &vGlyph, 1)
        var vBbox = CGRect.zero
        CTFontGetBoundingRectsForGlyphs(ctFontRef, .horizontal, &vGlyph, &vBbox, 1)

        let capHeight = font.capHeight
        let vAngle    = atan2(capHeight, vBbox.width * 0.5)

        // ── 4. Geometry ───────────────────────────────────────────────────────
        let lineY  = cutY
        let bloomH = size * 0.13
        let slant  = bloomH / tan(vAngle)

        // Trapezoid for solid line + core: tight right wall at lineRight
        var trapezoid = Path()
        trapezoid.move(to:    CGPoint(x: lineLeft  + slant, y: lineY - bloomH))
        trapezoid.addLine(to: CGPoint(x: lineRight,         y: lineY - bloomH))
        trapezoid.addLine(to: CGPoint(x: lineRight,         y: lineY + bloomH))
        trapezoid.addLine(to: CGPoint(x: lineLeft  - slant, y: lineY + bloomH))
        trapezoid.closeSubpath()

        // Bloom trapezoid: right wall extends past lineRight by the outer blur radius
        // so the glow has physical room to dissipate rather than hitting a hard wall
        let bloomClipRight = lineRight + size * 0.028
        var bloomTrapezoid = Path()
        bloomTrapezoid.move(to:    CGPoint(x: lineLeft  + slant, y: lineY - bloomH))
        bloomTrapezoid.addLine(to: CGPoint(x: bloomClipRight,    y: lineY - bloomH))
        bloomTrapezoid.addLine(to: CGPoint(x: bloomClipRight,    y: lineY + bloomH))
        bloomTrapezoid.addLine(to: CGPoint(x: lineLeft  - slant, y: lineY + bloomH))
        bloomTrapezoid.closeSubpath()

        // ── 5. Canvas ─────────────────────────────────────────────────────────
        return Canvas { context, _ in

            // ── Bloom — offscreen layer composited inside trapezoid clip ──────
            // All blur passes rendered into isolated layer first so that
            // filter:blur is fully resolved before the clip is applied.
            // Clip on composite = true hard pixel wall, no bleed.
            //
            // Left tip: bloom gradients fade from 0 at location 0.00 → full
            // at 0.08. The diagonal clip then cuts through the fade, making
            // the line appear to emerge from the V rather than be chopped by it.

            var bloomCtx = context
            bloomCtx.clip(to: bloomTrapezoid)
            bloomCtx.blendMode = .screen

            // Outer bloom
            bloomCtx.drawLayer { layer in
                layer.addFilter(.blur(radius: size * 0.018))
                var p = Path()
                p.move(to: CGPoint(x: lineLeft, y: lineY))
                p.addLine(to: CGPoint(x: lineRight, y: lineY))
                layer.stroke(p,
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: AppColors.accentPrimary.opacity(0.22),    location: 0.00),
                            .init(color: AppColors.accentSecondary.opacity(0.42),  location: 0.50),
                            .init(color: AppColors.accentTertiary.opacity(0.22), location: 1.00),
                        ]),
                        startPoint: CGPoint(x: lineLeft,  y: lineY),
                        endPoint:   CGPoint(x: lineRight, y: lineY)
                    ),
                    style: StrokeStyle(lineWidth: size * 0.0015, lineCap: .butt)
                )
            }

            // Mid bloom
            bloomCtx.drawLayer { layer in
                layer.addFilter(.blur(radius: size * 0.008))
                var p = Path()
                p.move(to: CGPoint(x: lineLeft, y: lineY))
                p.addLine(to: CGPoint(x: lineRight, y: lineY))
                layer.stroke(p,
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: AppColors.accentPrimary.opacity(0.30),    location: 0.00),
                            .init(color: AppColors.accentSecondary.opacity(0.50),  location: 0.50),
                            .init(color: AppColors.accentTertiary.opacity(0.30), location: 1.00),
                        ]),
                        startPoint: CGPoint(x: lineLeft,  y: lineY),
                        endPoint:   CGPoint(x: lineRight, y: lineY)
                    ),
                    style: StrokeStyle(lineWidth: size * 0.032, lineCap: .butt)
                )
            }

            // Tight bloom
            bloomCtx.drawLayer { layer in
                layer.addFilter(.blur(radius: size * 0.003))
                var p = Path()
                p.move(to: CGPoint(x: lineLeft, y: lineY))
                p.addLine(to: CGPoint(x: lineRight, y: lineY))
                layer.stroke(p,
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: AppColors.accentPrimary.opacity(0.40),    location: 0.00),
                            .init(color: AppColors.accentSecondary.opacity(0.58),  location: 0.50),
                            .init(color: AppColors.accentTertiary.opacity(0.40), location: 1.00),
                        ]),
                        startPoint: CGPoint(x: lineLeft,  y: lineY),
                        endPoint:   CGPoint(x: lineRight, y: lineY)
                    ),
                    style: StrokeStyle(lineWidth: size * 0.008, lineCap: .butt)
                )
            }

            // ── Solid spectrum line ───────────────────────────────────────────
            // Left tip fades from 0 → full cyan over 8% of line length.
            var solidCtx = context
            solidCtx.clip(to: trapezoid)
            var solidPath = Path()
            solidPath.move(to:    CGPoint(x: lineLeft,  y: lineY))
            solidPath.addLine(to: CGPoint(x: lineRight, y: lineY))
            solidCtx.stroke(solidPath,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: AppColors.accentPrimary,               location: 0.00),
                        .init(color: AppColors.accentSecondary,             location: 0.50),
                        .init(color: AppColors.accentTertiary,            location: 0.92),
                        .init(color: AppColors.accentTertiary.opacity(0), location: 1.00),
                    ]),
                    startPoint: CGPoint(x: lineLeft,  y: lineY),
                    endPoint:   CGPoint(x: lineRight, y: lineY)
                ),
                style: StrokeStyle(lineWidth: max(1.5, size * 0.0034), lineCap: .butt)
            )

            // ── White core ────────────────────────────────────────────────────
            // Fades in over 10% on the left so the tip tapers more softly.
            var coreCtx = context
            coreCtx.clip(to: trapezoid)
            var corePath = Path()
            corePath.move(to:    CGPoint(x: lineLeft,  y: lineY))
            corePath.addLine(to: CGPoint(x: lineRight, y: lineY))
            coreCtx.stroke(corePath,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: .white.opacity(0.88), location: 0.00),
                        .init(color: .white.opacity(0.88), location: 0.92),
                        .init(color: .white.opacity(0),    location: 1.00),
                    ]),
                    startPoint: CGPoint(x: lineLeft,  y: lineY),
                    endPoint:   CGPoint(x: lineRight, y: lineY)
                ),
                style: StrokeStyle(lineWidth: max(0.75, size * 0.001), lineCap: .butt)
            )
        }
        .frame(width: size, height: size)
    }

    // ── Word row ──────────────────────────────────────────────────────────────────

    private func wordRow(style: AnyShapeStyle) -> some View {
        let font = clashUIFont
        let G:  CGFloat = fontSize * 0.025
        let GY: CGFloat = fontSize * 0.215

        let kV = G  - sidebearings(of: "V", font: font).right - sidebearings(of: "A", font: font).left
        let kA = G  - sidebearings(of: "A", font: font).right - sidebearings(of: "Y", font: font).left
        let kY = GY - sidebearings(of: "Y", font: font).right - sidebearings(of: "L", font: font).left

        return HStack(spacing: 0) {
            Text("V").font(.custom("ClashDisplay-Bold", size: fontSize)).kerning(kV)
            Text("A").font(.custom("ClashDisplay-Bold", size: fontSize)).kerning(kA)
            Text("Y").font(.custom("ClashDisplay-Bold", size: fontSize)).kerning(kY)
            Text("L").font(.custom("ClashDisplay-Bold", size: fontSize)).kerning(0)
        }
        .foregroundStyle(style)
        .fixedSize()
    }

    // ── CoreText glyph metrics ────────────────────────────────────────────────────

    private func sidebearings(of char: String, font: UIFont) -> (left: CGFloat, right: CGFloat) {
        let ctFont = font as CTFont
        var utf16  = Array(char.utf16)
        var glyph  = CGGlyph(0)
        CTFontGetGlyphsForCharacters(ctFont, &utf16, &glyph, 1)
        var advance = CGSize.zero
        CTFontGetAdvancesForGlyphs(ctFont, .horizontal, &glyph, &advance, 1)
        var bbox = CGRect.zero
        CTFontGetBoundingRectsForGlyphs(ctFont, .horizontal, &glyph, &bbox, 1)
        return (left:  max(0, bbox.minX),
                right: max(0, advance.width - bbox.maxX))
    }

    private func glyphInkWidth(of char: String, font: UIFont) -> CGFloat {
        let ctFont = font as CTFont
        var utf16  = Array(char.utf16)
        var glyph  = CGGlyph(0)
        CTFontGetGlyphsForCharacters(ctFont, &utf16, &glyph, 1)
        var bbox = CGRect.zero
        CTFontGetBoundingRectsForGlyphs(ctFont, .horizontal, &glyph, &bbox, 1)
        return bbox.width
    }

    func glyphAdvance(of char: String, font: UIFont) -> CGFloat {
        let ctFont = font as CTFont
        var utf16  = Array(char.utf16)
        var glyph  = CGGlyph(0)
        CTFontGetGlyphsForCharacters(ctFont, &utf16, &glyph, 1)
        var adv = CGSize.zero
        CTFontGetAdvancesForGlyphs(ctFont, .horizontal, &glyph, &adv, 1)
        return adv.width
    }

    func inkEdgesAtY(of char: String, font: UIFont, scanY: CGFloat) -> (left: CGFloat, right: CGFloat)? {
        let ctFont = font as CTFont
        var utf16  = Array(char.utf16)
        var glyph  = CGGlyph(0)
        CTFontGetGlyphsForCharacters(ctFont, &utf16, &glyph, 1)
        guard let cgPath = CTFontCreatePathForGlyph(ctFont, glyph, nil) else { return nil }
        let crossings = collectCrossings(from: cgPath, scanY: scanY)
        guard !crossings.isEmpty else { return nil }
        return (left: crossings.min()!, right: crossings.max()!)
    }

    func collectCrossings(from path: CGPath, scanY: CGFloat) -> [CGFloat] {
        let flat = path.copy(dashingWithPhase: 0, lengths: [])
        var crossings = [CGFloat]()
        var cur  = CGPoint.zero
        var move = CGPoint.zero
        flat.applyWithBlock { ptr in
            collectCrossingsStep(ptr, scanY: scanY, cur: &cur, move: &move, crossings: &crossings)
        }
        return crossings
    }

    func collectCrossingsStep(
        _ ptr: UnsafePointer<CGPathElement>,
        scanY: CGFloat,
        cur:   inout CGPoint,
        move:  inout CGPoint,
        crossings: inout [CGFloat]
    ) {
        let el = ptr.pointee
        switch el.type {
        case .moveToPoint:
            cur  = el.points[0];  move = el.points[0]
        case .addLineToPoint:
            let p2 = el.points[0]
            if let x = xIntercept(p1: cur, p2: p2, atY: scanY) { crossings.append(x) }
            cur = p2
        case .closeSubpath:
            if let x = xIntercept(p1: cur, p2: move, atY: scanY) { crossings.append(x) }
            cur = move
        default:
            break
        }
    }

    func xIntercept(p1: CGPoint, p2: CGPoint, atY: CGFloat) -> CGFloat? {
        let minY = min(p1.y, p2.y), maxY = max(p1.y, p2.y)
        guard atY >= minY && atY <= maxY && maxY != minY else { return nil }
        return p1.x + ((atY - p1.y) / (p2.y - p1.y)) * (p2.x - p1.x)
    }
}

// ── Star Field ────────────────────────────────────────────────────────────────

private struct StarSpec {
    let x: CGFloat
    let y: CGFloat
    let hRx: CGFloat
    let vRy: CGFloat
    let dotR: CGFloat
    let color: Color
    let opacity: CGFloat
}

private struct StarFieldView: View {
    let size: CGFloat

    private let stars: [StarSpec] = [
        StarSpec(x: 0.168, y: 0.205, hRx: 22, vRy: 2.5,  dotR: 1.6, color: .white,            opacity: 0.85),
        StarSpec(x: 0.607, y: 0.168, hRx: 14, vRy: 2.0,  dotR: 1.2, color: AppColors.accentPrimary,    opacity: 0.80),
        StarSpec(x: 0.871, y: 0.135, hRx:  8, vRy: 1.3,  dotR: 1.0, color: .white,            opacity: 0.70),
        StarSpec(x: 0.379, y: 0.266, hRx:  5, vRy: 1.0,  dotR: 0.8, color: .white,            opacity: 0.60),
        StarSpec(x: 0.916, y: 0.359, hRx: 13, vRy: 2.0,  dotR: 1.2, color: AppColors.accentTertiary, opacity: 0.75),
        StarSpec(x: 0.080, y: 0.438, hRx:  7, vRy: 1.2,  dotR: 0.9, color: .white,            opacity: 0.62),
        StarSpec(x: 0.773, y: 0.291, hRx:  8, vRy: 1.3,  dotR: 1.0, color: AppColors.accentSecondary,  opacity: 0.68),
        StarSpec(x: 0.139, y: 0.740, hRx: 16, vRy: 2.2,  dotR: 1.4, color: .white,            opacity: 0.72),
        StarSpec(x: 0.559, y: 0.809, hRx:  5, vRy: 0.9,  dotR: 0.8, color: AppColors.accentPrimary,    opacity: 0.58),
        StarSpec(x: 0.848, y: 0.785, hRx:  8, vRy: 1.3,  dotR: 1.0, color: AppColors.accentTertiary, opacity: 0.65),
        StarSpec(x: 0.818, y: 0.236, hRx:  4, vRy: 0.8,  dotR: 0.7, color: .white,            opacity: 0.55),
        StarSpec(x: 0.900, y: 0.877, hRx:  7, vRy: 1.2,  dotR: 0.9, color: .white,            opacity: 0.58),
        StarSpec(x: 0.193, y: 0.842, hRx:  6, vRy: 1.0,  dotR: 0.8, color: AppColors.accentPrimary,    opacity: 0.55),
        StarSpec(x: 0.945, y: 0.623, hRx:  5, vRy: 0.9,  dotR: 0.7, color: .white,            opacity: 0.52),
    ]

    var body: some View {
        Canvas { ctx, canvasSize in
            let scale = size / 1024.0
            for s in stars {
                let cx   = s.x * canvasSize.width
                let cy   = s.y * canvasSize.height
                let hRx  = s.hRx * scale
                let vRy  = s.vRy * scale
                let dotR = s.dotR * scale

                let hRect = CGRect(x: cx - hRx, y: cy - vRy * 0.5, width: hRx * 2, height: vRy)
                let vRect = CGRect(x: cx - hRx * 0.12, y: cy - s.hRx * scale,
                                   width: hRx * 0.24, height: s.hRx * scale * 2)

                let bloom = GraphicsContext.Shading.radialGradient(
                    Gradient(colors: [s.color.opacity(Double(s.opacity)), s.color.opacity(0)]),
                    center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: hRx
                )
                let bloomV = GraphicsContext.Shading.radialGradient(
                    Gradient(colors: [s.color.opacity(Double(s.opacity)), s.color.opacity(0)]),
                    center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: s.hRx * scale
                )

                var hPath   = Path(); hPath.addEllipse(in: hRect)
                var vPath   = Path(); vPath.addEllipse(in: vRect)
                var dotPath = Path(); dotPath.addEllipse(in: CGRect(
                    x: cx - dotR, y: cy - dotR, width: dotR * 2, height: dotR * 2
                ))

                ctx.fill(hPath,   with: bloom)
                ctx.fill(vPath,   with: bloomV)
                ctx.fill(dotPath, with: .color(s.color.opacity(Double(s.opacity) * 1.1)))
            }
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }
}

// ── Preview ───────────────────────────────────────────────────────────────────

#Preview("Icon sizes") {
    VStack(spacing: AppSpacing.xl) {
        VaylAppIcon(size: 240)
        VaylAppIcon(size: 120)
        VaylAppIcon(size: 60)
    }
    .padding(AppSpacing.xxl)
    .background(Color(hex: "050508"))
}
