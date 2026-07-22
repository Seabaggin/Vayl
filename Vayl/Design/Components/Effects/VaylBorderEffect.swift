//
//  VaylBorderEffect.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/10/26.
//

// Shared/Components/Effects/VaylBorderEffect.swift

import SwiftUI

struct VaylBorderEffect: View {

    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    /// 0.0 = hairline only (inactive), 1.0 = full border filled (active)
    var progress: CGFloat

    /// 0.0 = no glow, 1.0 = full glow intensity.
    /// Double multiplier — stays fully chromatic at all intermediate values.
    var glowIntensity: Double = 0

    /// Owned by VaylButton and driven from onPressDown / onPressCancel.
    /// Decoupled from progress so there is no single-frame window where
    /// isPressed is true but progress is still 0.0 — which left the
    /// hairline visible for one frame as the border began filling.
    var hairlineVisible: Bool = true

    // MARK: - Stroke Geometry

    /// Linearly interpolated across all three states.
    /// Previous hard-switch at glowIntensity > 0.5 and progress >= 1
    /// produced a visible snap — the stroke jumped a full point in one frame.
    /// Linear blend makes the weight change imperceptible.
    private var strokeWidth: CGFloat {
        let resting = AppGlows.spectrumBorder.strokeResting   // 1.2
        let active  = AppGlows.spectrumBorder.strokeActive    // 1.8
        let glowing = AppGlows.spectrumBorder.strokeGlowing   // 2.0

        // Resting → active as the border fills
        let fillBlend = resting + (active - resting) * min(progress, 1)
        // Active → glowing as the glow fires
        return fillBlend + (glowing - fillBlend) * CGFloat(glowIntensity)
    }

    /// Halo stroke is wider than the crisp stroke so the blur
    /// has surface area to work with on the outward-facing side.
    private var haloStrokeWidth: CGFloat {
        strokeWidth + 2.0
    }

    /// Tighter base keeps the fill clean at rest.
    /// Peak gives the closing moment a readable pulse
    /// without bleeding far beyond the stroke edge.
    private var haloBlurRadius: CGFloat {
        let base: CGFloat = 2.5
        let peak: CGFloat = 7.0
        return base + CGFloat(glowIntensity) * (peak - base)
    }

    /// Base opacity gives the stroke inherent luminosity.
    /// Peak adds the closing-moment energy burst.
    private var haloOpacity: Double {
        let base: Double = 0.30
        let peak: Double = 0.70
        return base + glowIntensity * (peak - base)
    }

    // MARK: - Gradient

    // Liquid-metal material — the fill unfurls this around the ring on press.
    // AngularGradient maps the metal highlights to angular positions so the
    // border reads as metal wrapping, not a flat corner-to-corner gradient.
    private var spectrumGradient: AngularGradient {
        AppColors.spectrumMetalAngular
    }

    // MARK: - Body

    var body: some View {
        ZStack {

            // ── Hairline ──────────────────────────────────────────────
            // Visibility driven by hairlineVisible from VaylButton —
            // not inferred from progress > 0.05.
            // The progress threshold created a one-frame gap on press-down
            // where isPressed was true but progress was still 0.0.

            HairlineView(
                width: width,
                height: height,
                thickness: AppGlows.spectrumBorder.hairlineHeight,
                strokeWidth: 1.5   // resting border stroke — hairline sits on this edge
            )
            .opacity(hairlineVisible ? AppGlows.spectrumBorder.hairlineOpacity : 0.0)
            .animation(
                hairlineVisible
                    ? AppAnimation.hairlineReturn
                    : AppAnimation.hairlineRetract,
                value: hairlineVisible
            )

            // ── Resting shape border ──────────────────────────────────
            // Matches the pill surface color — defines the button boundary
            // at rest without introducing spectrum color.
            // The animated gradient fill strokes render on top at press.
            PillPath(
                width: width,
                height: height,
                cornerRadius: cornerRadius,
                inset: 0.75   // half of 1.5pt stroke
            )
            .stroke(
                AngularGradient(
                    stops: [
                        // Top centre — clear for hairline
                        .init(color: .clear, location: 0.00),
                        // Hold clear only as far as the hairline taper
                        .init(color: .clear, location: 0.20),
                        // Border fades in right at the taper end
                        .init(color: Color(.sRGB, red: 26/255, green: 25/255, blue: 31/255).opacity(0.50), location: 0.23),
                        .init(color: Color(.sRGB, red: 26/255, green: 25/255, blue: 31/255), location: 0.26),
                        // Full opacity across the bottom
                        .init(color: Color(.sRGB, red: 26/255, green: 25/255, blue: 31/255), location: 0.74),
                        // Mirror — fades out as it rounds the left corner back up
                        .init(color: Color(.sRGB, red: 26/255, green: 25/255, blue: 31/255).opacity(0.50), location: 0.77),
                        .init(color: .clear, location: 0.80),
                        // Hold clear back to top centre
                        .init(color: .clear, location: 1.00)
                    ],
                    center: .center,
                    angle: .degrees(-90)   // location 0.0 = 12 o'clock (top centre)
                ),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
            )
            .opacity(hairlineVisible ? 1.0 : 0.0)
            .animation(
                hairlineVisible
                    ? AppAnimation.hairlineReturn
                    : AppAnimation.hairlineRetract,
                value: hairlineVisible
            )

            // ── Halo — outward only ───────────────────────────────────
            // Pattern:
            //   1. Render halo (blurred wide stroke) — bleeds in all directions
            //   2. Mask off the interior with an inverse capsule clip
            //      so only the outward bleed survives
            //   3. Crisp stroke renders on top unclipped
            //
            // Mask geometry:
            //   The capsule is INSET by strokeWidth * 0.5 (positive padding,
            //   which shrinks the shape). This places the mask cutout edge at
            //   the inner boundary of the crisp stroke — the interior and the
            //   inward half of the stroke are punched out, leaving only the
            //   outward blur bleed.
            //
            //   Previous code used padding(-(strokeWidth * 0.5)) which EXPANDED
            //   the capsule beyond the button boundary. destinationOut then
            //   punched out the halo almost entirely — only the extreme outer
            //   pixel survived. The outward glow was effectively invisible.

            ZStack {
                // Right side halo
                PillPath(
                    width: width,
                    height: height,
                    cornerRadius: cornerRadius,
                    inset: haloStrokeWidth / 2
                )
                .trim(from: 0, to: progress / 2)
                .stroke(
                    spectrumGradient,
                    style: StrokeStyle(lineWidth: haloStrokeWidth, lineCap: .round)
                )
                .blur(radius: haloBlurRadius)

                // Left side halo
                PillPath(
                    width: width,
                    height: height,
                    cornerRadius: cornerRadius,
                    inset: haloStrokeWidth / 2
                )
                .trim(from: 1 - progress / 2, to: 1)
                .stroke(
                    spectrumGradient,
                    style: StrokeStyle(lineWidth: haloStrokeWidth, lineCap: .round)
                )
                .blur(radius: haloBlurRadius)
            }
            .opacity(haloOpacity)
            .mask(
                ZStack {
                    // Full rect — allow everything through
                    Rectangle()
                    // Shrink the capsule inward — cuts the interior and the
                    // inner half of the stroke. Only the outward blur survives.
                    Capsule()
                        .padding(strokeWidth * 0.5)      // positive = inset = correct
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
            )
            .animation(AppAnimation.borderFill, value: progress)
            .animation(AppAnimation.borderGlowIn, value: glowIntensity)

            // ── Crisp stroke — right side ─────────────────────────────
            // spectrumBorderGlow applied directly to the stroke path so
            // SwiftUI reads the stroke alpha mask, not the bounding box.
            // The glow shadow emanates from the line itself.

            PillPath(
                width: width,
                height: height,
                cornerRadius: cornerRadius,
                inset: strokeWidth / 2
            )
            .trim(from: 0, to: progress / 2)
            .stroke(
                spectrumGradient,
                style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
            )
            .opacity(0.92)
            .spectrumBorderGlow(intensity: glowIntensity)
            .animation(AppAnimation.borderFill, value: progress)
            .animation(AppAnimation.borderGlowIn, value: glowIntensity)

            // ── Crisp stroke — left side ──────────────────────────────

            PillPath(
                width: width,
                height: height,
                cornerRadius: cornerRadius,
                inset: strokeWidth / 2
            )
            .trim(from: 1 - progress / 2, to: 1)
            .stroke(
                spectrumGradient,
                style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
            )
            .opacity(0.92)
            .spectrumBorderGlow(intensity: glowIntensity)
            .animation(AppAnimation.borderFill, value: progress)
            .animation(AppAnimation.borderGlowIn, value: glowIntensity)
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Pill Path Shape

private struct PillPath: Shape {

    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    var inset: CGFloat = 0

    // pixelRound is no longer a stored closure.
    // Storing a (CGFloat) -> CGFloat closure prevents automatic Equatable
    // synthesis — SwiftUI cannot short-circuit re-renders without it.
    private func pixelRound(_ value: CGFloat) -> CGFloat {
        let scale = UITraitCollection.current.displayScale
        return (value * scale).rounded() / scale
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Shrink geometry by inset so strokes stay fully within the frame.
        let w  = width  - inset
        let h  = height - inset
        let ox = inset / 2   // origin x offset
        let oy = inset / 2   // origin y offset
        let cx = pixelRound(w / 2) + ox
        let r  = max(cornerRadius - inset / 2, 0)

        // Start at top-center
        path.move(to: CGPoint(x: cx, y: oy))

        // Top edge — right half
        let topRightStraight = (ox + w - r) - cx
        if topRightStraight > 0.5 {
            path.addLine(to: CGPoint(x: ox + w - r, y: oy))
        }

        // Right cap — clockwise
        path.addArc(
            center: CGPoint(x: ox + w - r, y: oy + r),
            radius: r,
            startAngle: .degrees(-90),
            endAngle: .degrees(90),
            clockwise: false
        )

        // Bottom edge — right to left
        let bottomStraight = (ox + w - r) - (ox + r)
        if bottomStraight > 0.5 {
            path.addLine(to: CGPoint(x: ox + r, y: oy + h))
        }

        // Left cap — clockwise
        path.addArc(
            center: CGPoint(x: ox + r, y: oy + r),
            radius: r,
            startAngle: .degrees(90),
            endAngle: .degrees(-90),
            clockwise: false
        )

        // Top edge — left half back to top-center
        let topLeftStraight = cx - (ox + r)
        if topLeftStraight > 0.5 {
            path.addLine(to: CGPoint(x: cx, y: oy))
        }

        return path
    }
}

// MARK: - Hairline View

private struct HairlineView: View {

    let width: CGFloat
    let height: CGFloat
    let thickness: CGFloat
    let strokeWidth: CGFloat

    var body: some View {
        TaperedHairlineShape(thickness: thickness)
            .fill(
                // Resting hairline is a metallic glint of the same material the
                // border fills with — bright near-white core (hairline↔metal blend).
                LinearGradient(
                    colors: [
                        .clear,
                        AppColors.spectrumCyan.opacity(0.85),
                        Color(uiColor: VaylPrimitives.metalHiCyan),     // bright metal core
                        Color(uiColor: VaylPrimitives.metalHiMagenta),  // bright metal core
                        AppColors.spectrumMagenta.opacity(0.85),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: thickness)
            .frame(width: width, height: height, alignment: .top)
            .offset(y: (strokeWidth / 2) - (thickness / 2))  // centre hairline on the border stroke centre
    }
}

// MARK: - Tapered Hairline Shape

private struct TaperedHairlineShape: Shape {

    let thickness: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.width
        let h = rect.height

        // How far from each end the line fully vanishes to a point.
        let taperEnd: CGFloat = w * 0.16
        // Control point — keeps the taper sharp at the very tip.
        let cp: CGFloat = w * 0.08

        // Upper arc: left tip → right tip
        path.move(to: CGPoint(x: taperEnd, y: h / 2))
        path.addCurve(
            to: CGPoint(x: w - taperEnd, y: h / 2),
            control1: CGPoint(x: taperEnd + cp, y: 0),
            control2: CGPoint(x: w - taperEnd - cp, y: 0)
        )

        // Lower arc: right tip → left tip
        path.addCurve(
            to: CGPoint(x: taperEnd, y: h / 2),
            control1: CGPoint(x: w - taperEnd - cp, y: h),
            control2: CGPoint(x: taperEnd + cp, y: h)
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppColors.void
            .ignoresSafeArea()

        VStack(spacing: 48) {

            // Resting — hairline visible, no border
            VaylBorderEffect(
                width: 320,
                height: 56,
                cornerRadius: 28,
                progress: 0,
                glowIntensity: 0,
                hairlineVisible: true
            )

            // Mid-fill — hairline hidden, border filling
            VaylBorderEffect(
                width: 320,
                height: 56,
                cornerRadius: 28,
                progress: 0.5,
                glowIntensity: 0,
                hairlineVisible: false
            )

            // Full fill, no glow
            VaylBorderEffect(
                width: 320,
                height: 56,
                cornerRadius: 28,
                progress: 1,
                glowIntensity: 0,
                hairlineVisible: false
            )

            // Full fill, full glow
            VaylBorderEffect(
                width: 320,
                height: 56,
                cornerRadius: 28,
                progress: 1,
                glowIntensity: 1,
                hairlineVisible: false
            )
        }
    }
    .preferredColorScheme(.dark)
}
