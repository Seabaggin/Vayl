// HomeWidgetShell.swift
// Open Lightly
//
// Unified card shell for PulseWidget and PrismView.
// Height is owned internally — callers never pass a size.
// Ratio: width × 0.88 — Oura-scale, content-rich.
// One place to change the ratio for both widgets.

import SwiftUI

// ═══════════════════════════════════════════
// RIM VARIANT
// ═══════════════════════════════════════════
enum RimVariant {
    case pulse, prism
    var baseOpacity: Double { switch self { case .pulse: return 0.62; case .prism: return 0.45 } }
    var leadTaper: Double { switch self { case .pulse: return 0.04; case .prism: return 0.10 } }
    var trailTaper: Double { switch self { case .pulse: return 0.04; case .prism: return 0.10 } }
}

// ═══════════════════════════════════════════
// HEIGHT RATIO
// Change this one constant to resize both
// Pulse and Prism cards simultaneously.
// ═══════════════════════════════════════════
private let kWidgetHeightRatio: CGFloat = 0.88

// ═══════════════════════════════════════════
// ORB LAYER
// ═══════════════════════════════════════════
struct OrbLayer: View {
    let accentColor: Color
    let height: CGFloat
    let variant: RimVariant

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct OrbSpec {
        let color: Color
        let size: CGSize
        let anchor: UnitPoint
        let driftX: Double
        let driftY: Double
        let phaseOffset: Double
        let blur: CGFloat
        let opMin: Double
        let opMax: Double
        let speed: Double
    }

    private var orbs: [OrbSpec] {
        let orbB = OrbSpec(
            color: AppColors.accentSecondary,
            size: CGSize(width: 190, height: 155),
            anchor: UnitPoint(x: 0.72, y: 0.65),
            driftX: 0.09, driftY: 0.09,
            phaseOffset: 1.0,
            blur: 20,
            opMin: 0.10, opMax: 0.28,
            speed: 0.17
        )
        let orbC = OrbSpec(
            color: variant == .prism ? AppColors.accentPrimary : AppColors.accentSecondary,
            size: CGSize(width: 240, height: 120),
            anchor: UnitPoint(x: 0.50, y: 0.42),
            driftX: 0.16, driftY: 0.07,
            phaseOffset: 2.4,
            blur: 24,
            opMin: 0.07, opMax: 0.20,
            speed: 0.13
        )
        return [orbB, orbC]
    }

    var body: some View {
        if reduceMotion || AppAnimation.lowPower {
            EmptyView()
        } else {
            GeometryReader { geo in
                let W: CGFloat = geo.size.width
                let H: CGFloat = geo.size.height
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { tl in
                    let t: Double = tl.date.timeIntervalSinceReferenceDate
                    ZStack {
                        primaryOrb(t: t, w: W, h: H)
                        ForEach(Array(orbs.enumerated()), id: \.offset) { i, spec in
                            secondaryOrb(spec: spec, index: i, t: t, w: W, h: H)
                        }
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }

    /// Breathing primary orb — anchor/size/drift vary by `variant`.
    /// Math is isolated here so the `body` result-builder stays trivial to type-check.
    @ViewBuilder
    private func primaryOrb(t: Double, w W: CGFloat, h H: CGFloat) -> some View {
        let aSize: CGSize    = variant == .pulse
            ? CGSize(width: 220, height: 180)
            : CGSize(width: 200, height: 160)
        let aAnchor: UnitPoint = variant == .pulse
            ? UnitPoint(x: 0.15, y: 0.22)
            : UnitPoint(x: 0.20, y: 0.25)
        let aDriftX: Double  = variant == .pulse ? 0.10 : 0.12
        let aDriftY: Double  = variant == .pulse ? 0.12 : 0.14
        let aBlur: CGFloat = variant == .pulse ? 18   : 20
        let aOpMin: Double  = variant == .pulse ? 0.14 : 0.12
        let aOpMax: Double  = variant == .pulse ? 0.35 : 0.32

        let axPhase: Double = t * 0.22
        let ayPhase: Double = t * 0.18 + 1.0
        let aBreath: Double = (sin(t * 0.45) + 1) / 2
        let aOp: Double = aOpMin + aBreath * (aOpMax - aOpMin)
        let posX: CGFloat = W * CGFloat(Double(aAnchor.x) + sin(axPhase) * aDriftX)
        let posY: CGFloat = H * CGFloat(Double(aAnchor.y) + sin(ayPhase) * aDriftY)

        Ellipse()
            .fill(
                RadialGradient(
                    stops: [
                        .init(color: accentColor.opacity(aOp), location: 0.00),
                        .init(color: accentColor.opacity(aOp * 0.4), location: 0.55),
                        .init(color: .clear, location: 1.00)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(aSize.width, aSize.height) * 0.5
                )
            )
            .frame(width: aSize.width, height: aSize.height)
            .position(x: posX, y: posY)
            .blur(radius: aBlur)
    }

    /// Drifting secondary orb driven by its `OrbSpec`. Isolated for type-check speed.
    @ViewBuilder
    private func secondaryOrb(spec: OrbSpec, index i: Int, t: Double, w W: CGFloat, h H: CGFloat) -> some View {
        let p1: Double = t * spec.speed + spec.phaseOffset
        let p2: Double = t * (spec.speed - 0.04) + spec.phaseOffset + 2.1
        let breath: Double = (sin(t * (0.38 - Double(i) * 0.07) + spec.phaseOffset) + 1) / 2
        let op: Double = spec.opMin + breath * (spec.opMax - spec.opMin)
        let posX: CGFloat = W * CGFloat(Double(spec.anchor.x) + sin(p1) * spec.driftX)
        let posY: CGFloat = H * CGFloat(Double(spec.anchor.y) + sin(p2) * spec.driftY)

        Ellipse()
            .fill(
                RadialGradient(
                    stops: [
                        .init(color: spec.color.opacity(op), location: 0.00),
                        .init(color: spec.color.opacity(op * 0.4), location: 0.55),
                        .init(color: .clear, location: 1.00)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(spec.size.width, spec.size.height) * 0.5
                )
            )
            .frame(width: spec.size.width, height: spec.size.height)
            .position(x: posX, y: posY)
            .blur(radius: spec.blur)
    }
}

// ═══════════════════════════════════════════
// HOME WIDGET SHELL
// Height is owned internally via GeometryReader.
// Callers do NOT pass a height parameter.
// ═══════════════════════════════════════════
struct HomeWidgetShell<Content: View>: View {

    // height removed from public API
    let isLight: Bool
    let accentColor: Color
    let rimVariant: RimVariant
    @ViewBuilder let content: Content

    private let corner: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            let h = floor(geo.size.width * kWidgetHeightRatio)

            ZStack {
                if isLight { lightSurface(height: h) } else { darkSurface(height: h) }
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                insetShadows
            }
            .frame(width: geo.size.width, height: h)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(alignment: .top) { rim }
            .overlay {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(borderGradient, lineWidth: isLight ? 1.5 : 1.0)
            }
            .shadow(
                color: isLight ? AppColors.accentSecondary.opacity(0x18 / 255.0) : .black.opacity(0.30),
                radius: 4, y: 2
            )
            .shadow(
                color: isLight ? AppColors.accentTertiary.opacity(0x14 / 255.0) : .black.opacity(0.48),
                radius: isLight ? 14 : 18,
                y: isLight ?  8 : 10
            )
            .shadow(
                color: isLight ? .black.opacity(0.08) : AppColors.accentSecondary.opacity(0x14 / 255.0),
                radius: isLight ? 24 : 30,
                y: isLight ? 20 :  0
            )
            .shadow(
                color: isLight ? AppColors.accentSecondary.opacity(0.20) : AppColors.accentPrimary.opacity(0.18),
                radius: 8, x: 0, y: -2
            )
            .shadow(
                color: isLight ? AppColors.accentTertiary.opacity(0.28) : AppColors.accentSecondary.opacity(0.24),
                radius: 6, x: 0, y: -4
            )
            .background(alignment: .bottom) {
                if !isLight { underglow(width: geo.size.width) }
            }
        }
        // Outer frame constrains GeometryReader to the correct aspect ratio.
        // Without this GeometryReader expands to fill available height.
        .aspectRatio(1.0 / kWidgetHeightRatio, contentMode: .fit)
    }

    // ═══════════════════════════════════════════
    // DARK SURFACE
    // height passed in from GeometryReader above
    // ═══════════════════════════════════════════
    private func darkSurface(height: CGFloat) -> some View {
        ZStack {
            Color.white.opacity(0.035)

            LinearGradient(
                stops: [
                    .init(color: AppColors.widgetBackground.opacity(0.85), location: 0.00),
                    .init(color: AppColors.widgetBackground.opacity(0.45), location: 0.55),
                    .init(color: AppColors.widgetBackground.opacity(0.00), location: 1.00)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: height * 0.40)
            .frame(maxHeight: .infinity, alignment: .top)

            LinearGradient(
                stops: [
                    .init(color: AppColors.widgetBackground.opacity(0.72), location: 0.00),
                    .init(color: AppColors.widgetBackground.opacity(0.35), location: 0.55),
                    .init(color: AppColors.widgetBackground.opacity(0.00), location: 1.00)
                ],
                startPoint: .bottom, endPoint: .top
            )
            .frame(height: height * 0.22)
            .frame(maxHeight: .infinity, alignment: .bottom)

            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.10), location: 0.00),
                    .init(color: .white.opacity(0.04), location: 0.22),
                    .init(color: .clear, location: 0.50)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            RadialGradient(
                stops: [
                    .init(color: .white.opacity(0.05), location: 0.0),
                    .init(color: .clear, location: 1.0)
                ],
                center: UnitPoint(x: 0.10, y: 0.08),
                startRadius: 0,
                endRadius: 120
            )

            LinearGradient(
                stops: [
                    .init(color: AppColors.accentPrimary.opacity(0.18), location: 0.00),
                    .init(color: AppColors.accentPrimary.opacity(0.10), location: 0.20),
                    .init(color: AppColors.accentSecondary.opacity(0.16), location: 0.40),
                    .init(color: AppColors.accentTertiary.opacity(0.10), location: 0.60),
                    .init(color: AppColors.accentSecondary.opacity(0.12), location: 0.80),
                    .init(color: AppColors.accentPrimary.opacity(0.08), location: 1.00)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [.clear, .black.opacity(0.32)],
                startPoint: UnitPoint(x: 0.5, y: 0.65),
                endPoint: .bottom
            )

            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.12), location: 0.00),
                        .init(color: .white.opacity(0.04), location: 0.08),
                        .init(color: .clear, location: 0.20)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.18), location: 0.00),
                        .init(color: .black.opacity(0.06), location: 0.12),
                        .init(color: .clear, location: 0.25)
                    ],
                    startPoint: .bottom, endPoint: .top
                )
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.06), location: 0.00),
                        .init(color: .clear, location: 0.08)
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.08), location: 0.00),
                        .init(color: .clear, location: 0.08)
                    ],
                    startPoint: .trailing, endPoint: .leading
                )
            }
            .allowsHitTesting(false)
        }
    }

    // ═══════════════════════════════════════════
    // LIGHT SURFACE
    // ═══════════════════════════════════════════
    private func lightSurface(height: CGFloat) -> some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: AppColors.accentSecondary.opacity(0.60), location: 0.00),
                    .init(color: AppColors.accentSecondary.opacity(0.55), location: 0.20),
                    .init(color: Color(red: 0.55, green: 0.11, blue: 0.64).opacity(0.50), location: 0.35),
                    .init(color: AppColors.accentTertiary.opacity(0.45), location: 0.50),
                    .init(color: AppColors.accentTertiary.opacity(0.40), location: 0.62),
                    .init(color: Color(red: 0.94, green: 0.30, blue: 0.22).opacity(0.42), location: 0.72),
                    .init(color: AppColors.safetyAccent.opacity(0.40), location: 0.85),
                    .init(color: AppColors.safetyAccent.opacity(0.32), location: 1.00)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            Color.white.opacity(0.08)

            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.82), location: 0.00),
                    .init(color: .white.opacity(0.55), location: 0.08),
                    .init(color: .white.opacity(0.22), location: 0.18),
                    .init(color: .white.opacity(0.00), location: 0.28)
                ],
                startPoint: .top, endPoint: .bottom
            )

            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.65), location: 0.00),
                    .init(color: .white.opacity(0.28), location: 0.18),
                    .init(color: .white.opacity(0.08), location: 0.30),
                    .init(color: .white.opacity(0.00), location: 0.40)
                ],
                startPoint: .bottom, endPoint: .top
            )

            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.01), location: 0.00),
                    .init(color: .white.opacity(0.18), location: 0.20),
                    .init(color: .clear, location: 0.48)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.22), location: 0.00),
                    .init(color: .clear, location: 0.32)
                ],
                startPoint: .bottomTrailing, endPoint: .topLeading
            )

            LinearGradient(
                stops: [
                    .init(color: AppColors.accentPrimary.opacity(0.15), location: 0.00),
                    .init(color: .clear, location: 0.26),
                    .init(color: AppColors.accentTertiary.opacity(0.12), location: 0.50),
                    .init(color: .clear, location: 0.64),
                    .init(color: AppColors.safetyAccent.opacity(0.10), location: 0.88),
                    .init(color: .clear, location: 1.00)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.55), location: 0.00),
                        .init(color: .white.opacity(0.20), location: 0.06),
                        .init(color: .clear, location: 0.18)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.05), location: 0.00),
                        .init(color: .black.opacity(0.02), location: 0.10),
                        .init(color: .clear, location: 0.22)
                    ],
                    startPoint: .bottom, endPoint: .top
                )
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.35), location: 0.00),
                        .init(color: .clear, location: 0.06)
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.04), location: 0.00),
                        .init(color: .clear, location: 0.06)
                    ],
                    startPoint: .trailing, endPoint: .leading
                )
            }
            .allowsHitTesting(false)

            LinearGradient(
                colors: [.clear, .black.opacity(0.04)],
                startPoint: UnitPoint(x: 0.5, y: 0.72),
                endPoint: .bottom
            )
        }
    }

    // ═══════════════════════════════════════════
    // INSET SHADOWS
    // ═══════════════════════════════════════════
    private var insetShadows: some View {
        Canvas { ctx, size in
            var top = ctx
            top.opacity = isLight ? 0.95 : 0.10
            var topPath = Path()
            topPath.addRect(CGRect(x: 0, y: 0, width: size.width, height: 1))
            top.fill(topPath, with: .color(.white))

            var bot = ctx
            bot.opacity = isLight ? 0.04 : 0.20
            var botPath = Path()
            botPath.addRect(CGRect(x: 0, y: size.height - 1, width: size.width, height: 1))
            bot.fill(botPath, with: .color(.black))
        }
        .allowsHitTesting(false)
    }

    // ═══════════════════════════════════════════
    // BORDER
    // ═══════════════════════════════════════════
    private var borderGradient: LinearGradient {
        isLight
        ? LinearGradient(
            stops: [
                .init(color: AppColors.accentPrimary.opacity(0x88 / 255.0), location: 0.0),
                .init(color: AppColors.accentTertiary.opacity(0x72 / 255.0), location: 0.5),
                .init(color: AppColors.safetyAccent.opacity(0x60 / 255.0), location: 1.0)
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
          )
        : LinearGradient(
            stops: [
                .init(color: AppColors.accentPrimary.opacity(0x65 / 255.0), location: 0.0),
                .init(color: AppColors.accentSecondary.opacity(0x50 / 255.0), location: 0.5),
                .init(color: AppColors.accentTertiary.opacity(0x40 / 255.0), location: 1.0)
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
          )
    }

    // ═══════════════════════════════════════════
    // RIM
    // ═══════════════════════════════════════════
    private var rim: some View {
        let taper = rimVariant.leadTaper
        let trail = 1.0 - rimVariant.trailTaper
        let op    = rimVariant.baseOpacity
        let light = isLight

        let darkStops: [Gradient.Stop] = [
            .init(color: .clear, location: 0.00),
            .init(color: .clear, location: taper),
            .init(color: AppColors.accentPrimary, location: taper + 0.02),
            .init(color: AppColors.accentSecondary, location: 0.32),
            .init(color: AppColors.accentTertiary, location: 0.50),
            .init(color: AppColors.accentSecondary, location: 0.68),
            .init(color: AppColors.accentPrimary, location: trail - 0.02),
            .init(color: .clear, location: trail),
            .init(color: .clear, location: 1.00)
        ]

        let lightStops: [Gradient.Stop] = [
            .init(color: .clear, location: 0.00),
            .init(color: .clear, location: taper),
            .init(color: AppColors.accentSecondary, location: taper + 0.04),
            .init(color: AppColors.accentTertiary, location: 0.50),
            .init(color: AppColors.safetyAccent, location: trail - 0.04),
            .init(color: .clear, location: trail),
            .init(color: .clear, location: 1.00)
        ]

        let stops = isLight ? lightStops : darkStops

        return ZStack {
            Canvas { ctx, size in
                let grad = GraphicsContext.Shading.linearGradient(
                    Gradient(stops: stops),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: size.width, y: 0)
                )
                var pass = ctx
                pass.opacity = op * (light ? 0.20 : 0.18)
                pass.addFilter(.blur(radius: 6))
                var path = Path()
                path.addRect(CGRect(x: 0, y: 0, width: size.width, height: 8))
                pass.fill(path, with: grad)
            }
            Canvas { ctx, size in
                let grad = GraphicsContext.Shading.linearGradient(
                    Gradient(stops: stops),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: size.width, y: 0)
                )
                var pass = ctx
                pass.opacity = op * (light ? 0.35 : 0.40)
                pass.addFilter(.blur(radius: 2))
                var path = Path()
                path.addRect(CGRect(x: 0, y: 0, width: size.width, height: 4))
                pass.fill(path, with: grad)
            }
            Canvas { ctx, size in
                let grad = GraphicsContext.Shading.linearGradient(
                    Gradient(stops: stops),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: size.width, y: 0)
                )
                var pass = ctx
                pass.opacity = op * (light ? 1.0 : 0.90)
                var path = Path()
                path.addRect(CGRect(x: 0, y: 0, width: size.width, height: 1.5))
                pass.fill(path, with: grad)
            }
        }
        .frame(height: 10)
        .frame(maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
    }

    // ═══════════════════════════════════════════
    // UNDERGLOW
    // ═══════════════════════════════════════════
    private func underglow(width: CGFloat) -> some View {
        Ellipse()
            .fill(RadialGradient(
                stops: [
                    .init(color: accentColor.opacity(0x30 / 255.0), location: 0.00),
                    .init(color: AppColors.accentSecondary.opacity(0x1C / 255.0), location: 0.55),
                    .init(color: .clear, location: 0.80)
                ],
                center: .center, startRadius: 0, endRadius: 80
            ))
            .frame(width: width * 0.80, height: 28)
            .blur(radius: 18)
            .offset(x: width * 0.10, y: 14)
            .allowsHitTesting(false)
    }
}

// ═══════════════════════════════════════════════════════════════
// PREVIEWS
// No manual cardH calculation needed — shell owns its height.
// ═══════════════════════════════════════════════════════════════

#Preview("Dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ScrollView {
            VStack(spacing: AppSpacing.sm) {
                HomeWidgetShell(
                    isLight: false,
                    accentColor: AppColors.accentPrimary,
                    rimVariant: .pulse
                ) {
                    ZStack {
                        OrbLayer(
                            accentColor: AppColors.accentPrimary,
                            height: 300,   // approx — orb positions are relative anyway
                            variant: .pulse
                        )
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("THE PULSE")
                                .font(AppFonts.overline)
                                .tracking(2.5)
                                .foregroundStyle(AppColors.textTertiary)
                            Text("Sovereign Space")
                                .font(AppFonts.sectionHeading)
                                .foregroundStyle(AppColors.textPrimary)
                            Text("High capacity · 14 check-ins")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        .padding(AppSpacing.lg)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                }

                HomeWidgetShell(
                    isLight: false,
                    accentColor: AppColors.accentSecondary,
                    rimVariant: .prism
                ) {
                    ZStack {
                        OrbLayer(
                            accentColor: AppColors.accentSecondary,
                            height: 300,
                            variant: .prism
                        )
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("THE PRISM")
                                .font(AppFonts.overline)
                                .tracking(2.5)
                                .foregroundStyle(AppColors.textTertiary)
                            Text("What are you bringing into today?")
                                .font(AppFonts.bodyMedium)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        .padding(AppSpacing.lg)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                }
            }
            .padding(AppSpacing.md)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ScrollView {
            VStack(spacing: AppSpacing.sm) {
                HomeWidgetShell(
                    isLight: true,
                    accentColor: AppColors.accentTertiary,
                    rimVariant: .pulse
                ) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("THE PULSE")
                            .font(AppFonts.overline)
                            .tracking(2.5)
                            .foregroundStyle(AppColors.textTertiary)
                        Text("Sovereign Space")
                            .font(AppFonts.sectionHeading)
                            .foregroundStyle(AppColors.textPrimary)
                        Text("High capacity · 14 check-ins")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .padding(AppSpacing.lg)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }

                HomeWidgetShell(
                    isLight: true,
                    accentColor: AppColors.accentSecondary,
                    rimVariant: .prism
                ) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("THE PRISM")
                            .font(AppFonts.overline)
                            .tracking(2.5)
                            .foregroundStyle(AppColors.textTertiary)
                        Text("What are you bringing into today?")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .padding(AppSpacing.lg)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            .padding(AppSpacing.md)
        }
    }
    .preferredColorScheme(.light)
}
