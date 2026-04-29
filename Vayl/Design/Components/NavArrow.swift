// NavArrow.swift
// Open Lightly
//
// Pill nav arrow — adaptive dark/light.
// Dark:  pillBorder()       (cyan → purple → magenta) border + arrow
// Light: warmAuroraBorder() border, magenta → orangeHot → gold arrow

import SwiftUI

// MARK: - Enums

enum ArrowDirection {
    case back
    case forward
}

enum OnboardingArrowStyle {
    case aurora
    case magentaGold
}

// MARK: - Size Constants

extension CGSize {
    /// Top nav bar weight — sits beside progress indicator
    static let navArrowTopBar = CGSize(width: 80, height: 44)
    /// Compact nav bar — smaller screens or tighter headers  //
      static let navArrowCompact = CGSize(width: 56, height: 32)
}

// MARK: - Shared Gradients

/// Dark mode — arrow + border: cyan → purple → magenta
private let spectrumGradient = LinearGradient(
    colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
    startPoint: .topLeading,
    endPoint:   .bottomTrailing
)

/// Light mode — arrow: magenta → orangeHot → gold
private let magentaGoldGradient = LinearGradient(
    stops: [
        .init(color: AppColors.magenta,   location: 0.00),
        .init(color: AppColors.orangeHot, location: 0.55),
        .init(color: AppColors.gold,      location: 1.00),
    ],
    startPoint: .topLeading,
    endPoint:   .bottomTrailing
)

// MARK: - NavArrowShape
// Direct port of the HTML SVG — viewBox 0 0 48 48
//
// Chevron top arm : (22,10) → (10,24)
// Chevron bot arm : (10,24) → (22,38)
// Upper line      : (14,20) → (38,20)
// Lower line      : (14,28) → (38,28)

struct NavArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        // ── Chevron top arm: (22,10) → (10,24)
        path.move(to:    CGPoint(x: w * (22/48), y: h * (10/48)))
        path.addLine(to: CGPoint(x: w * (10/48), y: h * (24/48)))

        // ── Chevron bot arm: (10,24) → (22,38)
        path.addLine(to: CGPoint(x: w * (22/48), y: h * (38/48)))

        // ── Upper line: (14,20) → (38,20)
        path.move(to:    CGPoint(x: w * (14/48), y: h * (20/48)))
        path.addLine(to: CGPoint(x: w * (38/48), y: h * (20/48)))

        // ── Lower line: (14,28) → (38,28)
        path.move(to:    CGPoint(x: w * (14/48), y: h * (28/48)))
        path.addLine(to: CGPoint(x: w * (38/48), y: h * (28/48)))

        return path
    }
}

// MARK: - GradientStrokeArrow

struct GradientStrokeArrow: View {
    var gradient:     LinearGradient
    var strokeWidth:  CGFloat = 2.8
    var shadowColor1: Color
    var shadowColor2: Color

    var body: some View {
        NavArrowShape()
            .stroke(
                gradient,
                style: StrokeStyle(
                    lineWidth:  strokeWidth,
                    lineCap:    .round,
                    lineJoin:   .round
                )
            )
            .shadow(color: shadowColor1.opacity(0.55), radius: 5)
            .shadow(color: shadowColor2.opacity(0.30), radius: 10)
    }
}

// MARK: - DarkNavArrow
//
// Parameter order: size → action (enables trailing closure, fixes init ordering)
//
// Pill:  surfaceBg fill at 0.85 opacity + pillBorder() spectrum border
// Arrow: spectrumGradient (cyan → purple → magenta)
// Glow:  blurred border duplicate at 0.50 opacity
// strokeWidth scales proportionally with pill height.

struct DarkNavArrow: View {
    var size:   CGSize = .navArrowCompact  // ← first
    var action: () -> Void                // ← last, enables trailing closure

    // Stroke scales with height — 1.8 at 44pt
    private var strokeWidth: CGFloat {
        (size.height / 44) * 1.8
    }

    var body: some View {
        Button(action: action, label: {
            ZStack {

                // ── Pill fill
                Capsule()
                    .fill(AppColors.surfaceBg.opacity(0.85))
                    .frame(width: size.width, height: size.height)

                // ── Crisp spectrum border via existing modifier
                Capsule()
                    .strokeBorder(Color.clear, lineWidth: 0)
                    .frame(width: size.width, height: size.height)
                    .pillBorder()

                // ── Blurred glow border duplicate
                Capsule()
                    .strokeBorder(spectrumGradient, lineWidth: 4)
                    .blur(radius: 7)
                    .opacity(0.50)
                    .frame(width: size.width, height: size.height)

                // ── Arrow glyph — spectrum, 65% of pill
                GradientStrokeArrow(
                    gradient:     spectrumGradient,
                    strokeWidth:  strokeWidth,
                    shadowColor1: AppColors.cyan,
                    shadowColor2: AppColors.purple
                )
                .frame(
                    width:  size.width  * 0.65,
                    height: size.height * 0.65
                )
            }
            .frame(width: size.width, height: size.height)
            .shadow(color: AppColors.purple.opacity(0.22), radius: 8)
            .shadow(color: AppColors.cyan.opacity(0.12),   radius: 20)
            .shadow(color: AppColors.purple.opacity(0.08), radius: 28)
        })
        .buttonStyle(.plain)
    }
}

// MARK: - LightNavArrow
//
// Parameter order: size → style → action (enables trailing closure, fixes init ordering)
//
// Pill:  lightCardBg fill + warmAuroraBorder() or magentaGoldBorder()
// Arrow: magentaGoldGradient (magenta → orangeHot → gold)
// Glow:  coloured spread shadows
// strokeWidth scales proportionally with pill height.

struct LightNavArrow: View {
    var size:   CGSize               = .navArrowCompact  // ← first
    var style:  OnboardingArrowStyle = .magentaGold     // ← second
    var action: () -> Void                              // ← last, enables trailing closure

    // Stroke scales with height — 2.1 at 44pt
    private var strokeWidth: CGFloat {
        (size.height / 44) * 2.1
    }

    var body: some View {
        Button(action: action, label: {
            ZStack {

                // ── Pill fill
                Capsule()
                    .fill(AppColors.lightCardBg)
                    .frame(width: size.width, height: size.height)

                // ── Border — aurora or magentaGold
                Capsule()
                    .strokeBorder(Color.clear, lineWidth: 0)
                    .frame(width: size.width, height: size.height)
                    .modifier(LightBorderModifier(style: style))

                // ── Arrow glyph — magenta gold, 65% of pill
                GradientStrokeArrow(
                    gradient:     magentaGoldGradient,
                    strokeWidth:  strokeWidth,
                    shadowColor1: AppColors.magenta,
                    shadowColor2: AppColors.orangeHot
                )
                .frame(
                    width:  size.width  * 0.65,
                    height: size.height * 0.65
                )
            }
            .frame(width: size.width, height: size.height)
            .shadow(color: AppColors.lightShadowMagenta.opacity(0.35), radius: 10, x: 0, y: 4)
            .shadow(color: AppColors.lightShadowPurple.opacity(0.22),  radius: 20, x: 0, y: 6)
            .shadow(color: AppColors.lightShadowGold.opacity(0.18),    radius: 8,  x: 0, y: 2)
        })
        .buttonStyle(.plain)
    }
}

// MARK: - LightBorderModifier

private struct LightBorderModifier: ViewModifier {
    let style: OnboardingArrowStyle

    func body(content: Content) -> some View {
        switch style {
        case .aurora:
            content.warmAuroraBorder()
        case .magentaGold:
            content.magentaGoldBorder()
        }
    }
}

// MARK: - OnboardingNavArrow (Adaptive Wrapper)

/// Single drop-in component for all onboarding back/forward navigation.
/// Reads colorScheme automatically.
/// Mirrors horizontally for forward direction.
///
/// Usage (ModeSelectView and all onboarding screens):
///   OnboardingNavArrow(direction: .back)    { goBack() }
///   OnboardingNavArrow(direction: .forward) { goNext() }

struct OnboardingNavArrow: View {
    var direction: ArrowDirection                          // ← first
    var size:      CGSize               = .navArrowTopBar // ← second
    var style:     OnboardingArrowStyle = .magentaGold    // ← third, light mode only
    var action:    () -> Void                             // ← last, enables trailing closure

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if colorScheme == .dark {
                DarkNavArrow(size: size, action: action)
            } else {
                LightNavArrow(size: size, style: style, action: action)
            }
        }
        .scaleEffect(x: direction == .forward ? -1 : 1)
        .accessibilityLabel(direction == .back ? "Go back" : "Continue")
    }
}

// MARK: - Previews

#Preview("NavArrow Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        HStack(spacing: 24) {
            OnboardingNavArrow(direction: .back)    { }
            OnboardingNavArrow(direction: .forward) { }
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("NavArrow Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        HStack(spacing: 24) {
            OnboardingNavArrow(direction: .back)    { }
            OnboardingNavArrow(direction: .forward) { }
        }
    }
    .preferredColorScheme(.light)
}
