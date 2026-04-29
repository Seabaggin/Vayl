//
//  PulseSheetView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/21/26.
//


// Features/Pulse/PulseSheetView.swift
// Open Lightly
//
// Sheet view — presented when user taps PulseWidget on home screen.
// Slides up as a sheet (.presentationDetents). Drag to dismiss.
//
// Scope: header + 3 stats + window selector + graph + "Open in Map →"
// Does NOT own: entry list, insights, dot burn summary, partner overlay.
// Those live in MapPulseView (Map tab — not yet built).
//
// Header mirrors PulseWidget exactly:
//   "THE PULSE" overline → LivingText tier name → sublabel
// This creates visual continuity — user recognises where they came from.
//
// Graph: PulseGraph with Treatment B tier lines, no fill, tight glow.
// Dot taps are disabled here — burn overlay belongs in MapPulseView.
//
// "Open in Map →" is the single exit. No other navigation.

import SwiftUI

// MARK: - PulseSheetView

struct PulseSheetView: View {

    // MARK: - Inputs

    var entries:     [PulseEntry]
    var onDismiss:   (() -> Void)?   = nil
    var onOpenInMap: (() -> Void)?   = nil

    // MARK: - State

    @State private var selectedWindow: PulseWindow = .oneWeek

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Computed

    private var filteredEntries: [PulseEntry] {
        selectedWindow.filter(entries)
    }

    private var currentTier: PulseTier {
        guard let last = entries.last else { return PulseTier.tier(for: 2.5) }
        return PulseTier.tier(for: last.capacityScore)
    }

    private var streakCount: Int {
        // Count consecutive days with entries ending today
        var streak = 0
        var checkDate = Calendar.current.startOfDay(for: Date())
        let sortedDates = entries
            .map { Calendar.current.startOfDay(for: $0.date) }
            .sorted(by: >)
        for date in sortedDates {
            if date == checkDate {
                streak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return streak
    }

    private var avgTier: PulseTier {
        guard !entries.isEmpty else { return PulseTier.tier(for: 2.5) }
        let avg = entries.map { $0.capacityScore }.reduce(0, +) / Double(entries.count)
        return PulseTier.tier(for: avg)
    }

    private var trendLabel: String {
        guard entries.count >= 4 else { return "Building" }
        let recent = entries.suffix(3).map { $0.capacityScore }
        let prior  = entries.dropLast(3).suffix(3).map { $0.capacityScore }
        guard !prior.isEmpty else { return "Building" }
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let priorAvg  = prior.reduce(0, +)  / Double(prior.count)
        if recentAvg > priorAvg + 0.2 { return "↑ Up" }
        if recentAvg < priorAvg - 0.2 { return "↓ Down" }
        return "→ Steady"
    }

    private var trendColor: Color {
        if trendLabel.hasPrefix("↑") { return Color(hex: "34C759") }
        if trendLabel.hasPrefix("↓") { return isLight ? AppColors.magenta : AppColors.cyan }
        return isLight ? AppColors.lightTextSecondary : AppColors.textSecondary
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {

            // Background
            (isLight ? AppColors.lightPageBg : Color(hex: "0D0B14"))
                .ignoresSafeArea()

            // Atmosphere — faint orbs echo the widget
            atmosphereLayer
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Sheet rim — top edge spectrum line signals
            // continuity with the widget rim above it
            sheetRim

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // Drag handle
                    dragHandle
                        .padding(.top, 12)
                        .padding(.bottom, 18)

                    // Header — mirrors PulseWidget
                    headerRow
                        .padding(.horizontal, 18)
                        .padding(.bottom, 20)

                    // Stats
                    statsRow
                        .padding(.horizontal, 18)
                        .padding(.bottom, 18)

                    // Window selector
                    windowSelector
                        .padding(.horizontal, 18)
                        .padding(.bottom, 14)

                    // Graph
                    graphCard
                        .padding(.horizontal, 18)
                        .padding(.bottom, 20)

                    // Divider
                    Divider()
                        .background(isLight ? Color.black.opacity(0.07) : Color.white.opacity(0.07))
                        .padding(.horizontal, 18)
                        .padding(.bottom, 20)

                    // Open in Map CTA
                    openInMapButton
                        .padding(.horizontal, 18)
                        .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Drag Handle

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                isLight
                    ? Color.black.opacity(0.18)
                    : Color.white.opacity(0.18)
            )
            .frame(width: 36, height: 4)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Sheet Rim

    private var sheetRim: some View {
        LinearGradient(
            stops: [
                .init(color: .clear,                          location: 0.00),
                .init(color: isLight
                    ? AppColors.purple.opacity(0.45)
                    : AppColors.cyan.opacity(0.45),           location: 0.08),
                .init(color: isLight
                    ? AppColors.magenta.opacity(0.45)
                    : AppColors.purple.opacity(0.45),         location: 0.50),
                .init(color: isLight
                    ? AppColors.gold.opacity(0.40)
                    : AppColors.magenta.opacity(0.40),        location: 0.92),
                .init(color: .clear,                          location: 1.00),
            ],
            startPoint: .leading,
            endPoint:   .trailing
        )
        .frame(height: 1.5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
    }

    // MARK: - Atmosphere

    @ViewBuilder
    private var atmosphereLayer: some View {
        if isLight {
            ZStack {
                Ellipse()
                    .fill(AppColors.magenta.opacity(0.06))
                    .frame(width: 300, height: 250)
                    .blur(radius: 90)
                    .offset(x: -80, y: 40)
                Ellipse()
                    .fill(AppColors.purple.opacity(0.05))
                    .frame(width: 250, height: 200)
                    .blur(radius: 90)
                    .offset(x: 100, y: 100)
            }
        } else {
            ZStack {
                Ellipse()
                    .fill(AppColors.purple.opacity(0.10))
                    .frame(width: 300, height: 250)
                    .blur(radius: 80)
                    .offset(x: -80, y: 40)
                Ellipse()
                    .fill(AppColors.magenta.opacity(0.07))
                    .frame(width: 250, height: 200)
                    .blur(radius: 80)
                    .offset(x: 100, y: 100)
            }
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {

                // Overline
                Text("THE PULSE")
                    .font(AppFonts.overline)
                    .tracking(2.5)
                    .foregroundStyle(
                        isLight ? AppColors.lightTextTertiary : AppColors.textTertiary
                    )

                // LivingText tier name
                LivingText(
                    text: "The \(currentTier.label) Space",
                    font: AppFonts.sectionHeading
                )

                // Sublabel — what it correlates to
                Text(currentTier.sublabel)
                    .font(AppFonts.caption)
                    .foregroundStyle(
                        isLight
                            ? AppColors.lightTextSecondary.opacity(0.75)
                            : AppColors.textSecondary.opacity(0.75)
                    )
            }

            Spacer()

            // Close button
            Button {
                onDismiss?()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(
                        isLight ? AppColors.lightTextTertiary : AppColors.textTertiary
                    )
                    .frame(width: 30, height: 30)
                    .background {
                        Circle()
                            .fill(
                                isLight
                                    ? Color.black.opacity(0.05)
                                    : Color.white.opacity(0.07)
                            )
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(
                                isLight
                                    ? Color.black.opacity(0.07)
                                    : Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                    }
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 8) {
            statCell(
                label: "STREAK",
                value: "\(streakCount) day\(streakCount == 1 ? "" : "s")",
                valueColor: nil
            )
            statCell(
                label: "AVG TIER",
                value: avgTier.label,
                valueColor: isLight ? AppColors.magenta : AppColors.electricViolet
            )
            statCell(
                label: "TREND",
                value: trendLabel,
                valueColor: trendColor
            )
        }
    }

    private func statCell(
        label: String,
        value: String,
        valueColor: Color?
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(AppFonts.overline)
                .tracking(1.5)
                .foregroundStyle(
                    isLight ? AppColors.lightTextTertiary : AppColors.textTertiary
                )
            Text(value)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(
                    valueColor ?? (isLight
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    isLight
                        ? Color.white.opacity(0.60)
                        : Color.white.opacity(0.04)
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isLight
                        ? Color.white.opacity(0.80)
                        : Color.white.opacity(0.07),
                    lineWidth: 1
                )
        }
    }

    // MARK: - Window Selector

    private var windowSelector: some View {
        HStack(spacing: 5) {
            ForEach(PulseWindow.allCases) { window in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedWindow = window
                    }
                } label: {
                    Text(window.rawValue)
                        .font(AppFonts.buttonLabelSmall)
                        .foregroundStyle(
                            selectedWindow == window
                                ? AppColors.purple
                                : (isLight
                                    ? AppColors.lightTextTertiary
                                    : AppColors.textTertiary)
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(
                                    selectedWindow == window
                                        ? (isLight
                                            ? AppColors.purple.opacity(0.10)
                                            : AppColors.purple.opacity(0.20))
                                        : Color.clear
                                )
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(
                                    selectedWindow == window
                                        ? AppColors.purple.opacity(isLight ? 0.35 : 0.40)
                                        : (isLight
                                            ? Color.black.opacity(0.07)
                                            : Color.white.opacity(0.07)),
                                    lineWidth: 1
                                )
                        }
                }
                .buttonStyle(.plain)
                .animation(.easeOut(duration: 0.2), value: selectedWindow)
            }
        }
    }

    // MARK: - Graph Card

    private var graphCard: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let pointSpacing: CGFloat = 55
            let safeCount = max(0, filteredEntries.count - 1)
            let canvasW   = max(W, CGFloat(safeCount) * pointSpacing + 64)
            let canvasH:  CGFloat = 220

            ZStack {
                // Card surface
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        isLight
                            ? Color.white.opacity(0.60)
                            : Color(hex: "0C0A16").opacity(0.90)
                    )

                // Subtle iridescence
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: isLight
                                    ? AppColors.purple.opacity(0.05)
                                    : AppColors.cyan.opacity(0.06),    location: 0.0),
                                .init(color: isLight
                                    ? AppColors.magenta.opacity(0.04)
                                    : AppColors.purple.opacity(0.05),  location: 0.5),
                                .init(color: isLight
                                    ? AppColors.gold.opacity(0.03)
                                    : AppColors.magenta.opacity(0.04), location: 1.0),
                            ],
                            startPoint: .topLeading,
                            endPoint:   .bottomTrailing
                        )
                    )

                // Rim
                LinearGradient(
                    stops: [
                        .init(color: .clear,                                              location: 0.00),
                        .init(color: isLight
                            ? AppColors.purple.opacity(0.42)
                            : AppColors.cyan.opacity(0.42),             location: 0.08),
                        .init(color: isLight
                            ? AppColors.magenta.opacity(0.42)
                            : AppColors.purple.opacity(0.42),           location: 0.50),
                        .init(color: isLight
                            ? AppColors.gold.opacity(0.36)
                            : AppColors.magenta.opacity(0.36),          location: 0.92),
                        .init(color: .clear,                                              location: 1.00),
                    ],
                    startPoint: .leading,
                    endPoint:   .trailing
                )
                .frame(height: 1.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                // Border
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: isLight
                                    ? AppColors.purple.opacity(0.25)
                                    : AppColors.cyan.opacity(0.20),     location: 0.0),
                                .init(color: isLight
                                    ? AppColors.magenta.opacity(0.20)
                                    : AppColors.purple.opacity(0.16),   location: 0.5),
                                .init(color: isLight
                                    ? AppColors.gold.opacity(0.16)
                                    : AppColors.magenta.opacity(0.12),  location: 1.0),
                            ],
                            startPoint: .topLeading,
                            endPoint:   .bottomTrailing
                        ),
                        lineWidth: 1
                    )

                // Graph — scrollable, dot taps disabled in sheet
                ScrollView(.horizontal, showsIndicators: false) {
                    PulseGraph(
                        entries:          filteredEntries,
                        graphWidth:       canvasW,
                        graphHeight:      canvasH,
                        disableTouchGlow: true
                    )
                    .frame(width: canvasW, height: canvasH)
                }
                .defaultScrollAnchor(.trailing)
                .frame(height: canvasH)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .frame(height: 220)
            .shadow(
                color: isLight
                    ? AppColors.purple.opacity(0.07)
                    : Color.black.opacity(0.35),
                radius: 20,
                y: 8
            )
        }
        .frame(height: 220)
    }

    // MARK: - Open in Map Button

    private var openInMapButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onOpenInMap?()
        } label: {
            HStack(spacing: 6) {
                Text("Open in Map")
                    .font(AppFonts.buttonLabel)
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(AppColors.purple)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.purple.opacity(isLight ? 0.10 : 0.18))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        AppColors.purple.opacity(isLight ? 0.35 : 0.45),
                        lineWidth: 1.5
                    )
            }
            .shadow(
                color: AppColors.purple.opacity(isLight ? 0.12 : 0.20),
                radius: 16,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }
}



// MARK: - Previews

#Preview("Sheet — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        PulseSheetView(
            entries:     PulseEntry.previews,
            onDismiss:   {},
            onOpenInMap: {}
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Sheet — light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        PulseSheetView(
            entries:     PulseEntry.previews,
            onDismiss:   {},
            onOpenInMap: {}
        )
    }
    .preferredColorScheme(.light)
}

#Preview("Sheet — zero entries") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        PulseSheetView(
            entries:     [],
            onDismiss:   {},
            onOpenInMap: {}
        )
    }
    .preferredColorScheme(.dark)
}