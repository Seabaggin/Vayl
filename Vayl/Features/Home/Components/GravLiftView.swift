/// Features/Home/Components/GravLiftView.swift
// Vayl

import SwiftUI

// MARK: - GravLiftView

struct GravLiftView: View {

    var breathPhase: CGFloat = 0

    private var breathSin: Double {
        sin(Double(breathPhase) * .pi * 2)
    }

    private var coneOpacity: Double { 0.72 + breathSin * 0.22 }
    private var haloOpacity: Double { 0.45 + breathSin * 0.18 }
    private var scanOpacity: Double { 0.85 + breathSin * 0.15 }

    var body: some View {
        GeometryReader { geo in
            let layout = AppLayout.from(geo)
            let w = layout.screenWidth
            let h = layout.screenHeight
            let cx = w / 2

            ZStack {

                // ── Wide outer cone ────────────────────────
                LinearGradient(
                    stops: [
                        .init(color: .clear,                                        location: 0.00),
                        .init(color: AppColors.accentPrimary.opacity(coneOpacity * 0.20),    location: 0.25),
                        .init(color: AppColors.accentSecondary.opacity(coneOpacity * 0.28),  location: 0.55),
                        .init(color: AppColors.accentSecondary.opacity(coneOpacity * 0.14),  location: 0.82),
                        .init(color: .clear,                                        location: 1.00),
                    ],
                    startPoint: .top,
                    endPoint:   .bottom
                )
                .frame(width: 400, height: h)
                .blur(radius: 22)

                // ── Narrow inner cone ──────────────────────
                LinearGradient(
                    stops: [
                        .init(color: .clear,                                        location: 0.00),
                        .init(color: AppColors.accentPrimary.opacity(coneOpacity * 0.50),    location: 0.20),
                        .init(color: AppColors.accentSecondary.opacity(coneOpacity * 0.70),  location: 0.52),
                        .init(color: AppColors.accentSecondary.opacity(coneOpacity * 0.40),  location: 0.80),
                        .init(color: .clear,                                        location: 1.00),
                    ],
                    startPoint: .top,
                    endPoint:   .bottom
                )
                .frame(width: 160, height: h)
                .blur(radius: 8)

                // ── Atmospheric halo at base ───────────────
                EllipticalGradient(
                    stops: [
                        .init(color: AppColors.accentSecondary.opacity(haloOpacity * 0.22), location: 0.0),
                        .init(color: AppColors.accentPrimary.opacity(haloOpacity * 0.10),   location: 0.5),
                        .init(color: .clear,                                        location: 1.0),
                    ],
                    center:    .init(x: 0.5, y: 0.78),
                    startRadiusFraction: 0,
                    endRadiusFraction:   0.5
                )
                .frame(width: 340, height: h * 0.55)
                .blur(radius: 12)
                .frame(maxHeight: .infinity, alignment: .bottom)

                // ── Scan line — wide bloom ─────────────────
                LinearGradient(
                    stops: [
                        .init(color: .clear,                                         location: 0.00),
                        .init(color: AppColors.accentPrimary.opacity(scanOpacity * 0.90),     location: 0.12),
                        .init(color: AppColors.accentSecondary.opacity(scanOpacity),          location: 0.50),
                        .init(color: AppColors.accentPrimary.opacity(scanOpacity * 0.90),     location: 0.88),
                        .init(color: .clear,                                         location: 1.00),
                    ],
                    startPoint: .leading,
                    endPoint:   .trailing
                )
                .frame(width: 200, height: 14)
                .blur(radius: 8)
                .opacity(scanOpacity * 0.35)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, AppSpacing.sm)

                // ── Scan line — tight bloom ────────────────
                LinearGradient(
                    stops: [
                        .init(color: .clear,                                         location: 0.00),
                        .init(color: AppColors.accentPrimary.opacity(scanOpacity * 0.90),     location: 0.12),
                        .init(color: AppColors.accentSecondary.opacity(scanOpacity),          location: 0.50),
                        .init(color: AppColors.accentPrimary.opacity(scanOpacity * 0.90),     location: 0.88),
                        .init(color: .clear,                                         location: 1.00),
                    ],
                    startPoint: .leading,
                    endPoint:   .trailing
                )
                .frame(width: 200, height: 5)
                .blur(radius: 3)
                .opacity(scanOpacity * 0.65)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, AppSpacing.xxs)

                // ── Scan line — crisp 1pt ──────────────────
                LinearGradient(
                    stops: [
                        .init(color: .clear,                                         location: 0.00),
                        .init(color: AppColors.accentPrimary.opacity(scanOpacity * 0.90),     location: 0.12),
                        .init(color: AppColors.accentSecondary.opacity(scanOpacity),          location: 0.50),
                        .init(color: AppColors.accentPrimary.opacity(scanOpacity * 0.90),     location: 0.88),
                        .init(color: .clear,                                         location: 1.00),
                    ],
                    startPoint: .leading,
                    endPoint:   .trailing
                )
                .frame(width: 200, height: 1)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(width: w, height: h)
        }
        .frame(height: 72)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Previews

#Preview("GravLift — static") {
    GeometryReader { geo in
        let layout = AppLayout.from(geo)
        ZStack {
            AppColors.pageBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .frame(height: 60)
                    .padding(.horizontal, AppSpacing.lg)
                GravLiftView(breathPhase: 0.5)
                    .padding(.horizontal, AppSpacing.lg)
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .fill(Color(red: 0.024, green: 0.024, blue: 0.039).opacity(0.72))
                    .frame(height: 60)
                    .padding(.horizontal, AppSpacing.lg)
            }
            .topClearance(layout)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("GravLift — breathing") {
    struct BreathPreview: View {
        @State private var phase: CGFloat = 0
        var body: some View {
            GeometryReader { geo in
                let layout = AppLayout.from(geo)
                ZStack {
                    AppColors.pageBackground.ignoresSafeArea()
                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                            .frame(height: 60)
                            .padding(.horizontal, AppSpacing.lg)
                        GravLiftView(breathPhase: phase)
                            .padding(.horizontal, AppSpacing.lg)
                        RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                            .fill(Color(red: 0.024, green: 0.024, blue: 0.039).opacity(0.72))
                            .frame(height: 60)
                            .padding(.horizontal, AppSpacing.lg)
                    }
                    .topClearance(layout)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    phase = 1.0
                }
            }
        }
    }
    return BreathPreview()
}
