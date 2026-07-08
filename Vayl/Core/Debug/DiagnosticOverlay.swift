// DiagnosticOverlay.swift
// Vayl — DEBUG ONLY
// Drop this file anywhere in the project. All content is #if DEBUG guarded.
// Usage:
//   In StatPhase ZStack:       .overlay(alignment: .bottom) { CTAPositionMarker(label: "StatPhase CTA", color: .cyan) }
//   In OBCanvas PhaseOverlay:  .overlay(alignment: .bottom) { CTAPositionMarker(label: "OBCanvas CTA", color: .orange) }
//   On any view:               .measurePosition(label: "my view")

#if DEBUG

import SwiftUI

// MARK: - Screen Ruler
// Full-height vertical ruler on the right edge showing absolute Y positions.
// Drop on the root ZStack of OBCanvas to see both CTAs referenced against
// the same coordinate space.

struct ScreenRuler: View {
    var color: Color = .yellow.opacity(0.6)
    var tickInterval: CGFloat = 50

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width

            ZStack(alignment: .topLeading) {
                // Ruler spine
                Rectangle()
                    .fill(color)
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                    .position(x: w - 20, y: h / 2)

                // Ticks + labels
                ForEach(Array(stride(from: CGFloat(0), through: h, by: tickInterval)), id: \.self) { y in
                    HStack(spacing: 2) {
                        Text("\(Int(y))")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(color)
                        Rectangle()
                            .fill(color)
                            .frame(width: y.truncatingRemainder(dividingBy: 100) == 0 ? 10 : 5, height: 1)
                    }
                    .position(x: w - 30, y: y)
                }
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

// MARK: - CTA Position Marker
// Horizontal line + label showing the top edge of the CTA button.
// Place as .overlay on the VaylButton itself.

struct CTAPositionMarker: View {
    let label: String
    var color: Color = .cyan

    var body: some View {
        GeometryReader { geo in
            let globalFrame = geo.frame(in: .global)

            ZStack(alignment: .topLeading) {
                // Horizontal line across full width at top of CTA
                Rectangle()
                    .fill(color)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                    .position(x: geo.size.width / 2, y: 0)

                // Y position label
                HStack(spacing: 4) {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                    Text("\(label): y=\(Int(globalFrame.minY)) bottom=\(Int(globalFrame.maxY))")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(color)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(3)
                }
                .position(x: geo.size.width / 2, y: -12)
            }
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Safe Area Bands
// Colored bands showing where the top and bottom safe areas are.
// Drop on the root ZStack of OBCanvas.

struct SafeAreaBands: View {
    var body: some View {
        GeometryReader { geo in
            let insets = geo.safeAreaInsets

            ZStack {
                // Top safe area band
                Rectangle()
                    .fill(Color.green.opacity(0.25))
                    .frame(height: max(insets.top, 1))
                    .frame(maxWidth: .infinity)
                    .overlay(
                        Text("safe top: \(Int(insets.top))pt  geo.h: \(Int(geo.size.height))")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                            .padding(.leading, AppSpacing.sm),
                        alignment: .bottomLeading
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                // Bottom safe area band
                Rectangle()
                    .fill(Color.orange.opacity(0.25))
                    .frame(height: max(insets.bottom, 1))
                    .frame(maxWidth: .infinity)
                    .overlay(
                        Text("safe bottom: \(Int(insets.bottom))pt")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                            .padding(.leading, AppSpacing.sm),
                        alignment: .topLeading
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Position Reporter
// Prints and overlays the global frame of any view.

struct MeasurePosition: ViewModifier {
    let label: String
    var color: Color = .pink

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    let f = geo.frame(in: .global)
                    ZStack {
                        Rectangle()
                            .strokeBorder(color, lineWidth: 1)
                        VStack {
                            Text("\(label)")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                            Text("y:\(Int(f.minY)) h:\(Int(f.height))")
                                .font(.system(size: 8, design: .monospaced))
                        }
                        .foregroundColor(color)
                        .padding(AppSpacing.xxs)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(3)
                    }
                    .allowsHitTesting(false)
                    .onAppear {
                        print("📏 \(label) — global frame: \(f)")
                    }
                }
            )
    }
}

extension View {
    func measurePosition(label: String, color: Color = .pink) -> some View {
        modifier(MeasurePosition(label: label, color: color))
    }
}

#endif
