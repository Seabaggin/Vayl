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
    var onDismiss:   (() -> Void)? = nil
    var onOpenInMap: (() -> Void)? = nil

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
        var streak    = 0
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
        // TODO: Color(hex: "34C759") requires AppColors.trendPositive token before migration.
        // Flagged — do not replace with a raw hex elsewhere in the codebase.
        if trendLabel.hasPrefix("↑") { return Color(hex: "34C759") }
        if trendLabel.hasPrefix("↓") { return isLight ? AppColors.accentTertiary : AppColors.accentPrimary }
        return isLight ? AppColors.textSecondary : AppColors.textSecondary
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {

            // Background
            // TODO: Color(hex: "0D0B14") requires an AppColors token before migration.
            // pageBackground is the semantic replacement candidate — confirm with design.
            (isLight ? AppColors.pageBackground : Color(hex: "0D0B14"))
                .ignoresSafeArea()

            atmosphereLayer
                .ignoresSafeArea()
                .allowsHitTesting(false)

            sheetRim

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // Drag handle
                    dragHandle
                        .padding(.top, AppSpacing.sm)
                        .padding(.bottom, AppSpacing.md)

                    // Header — mirrors PulseWidget
                    headerRow
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, AppSpacing.lg)

                    // Stats
                    statsRow
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, AppSpacing.md)

                    // Window selector
                    windowSelector
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, AppSpacing.md)

                    // Graph
                    graphCard
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, AppSpacing.lg)

                    // Divider
                    Divider()
                        .background(isLight
                            ? Color.black.opacity(0.07)
                            : Color.white.opacity(0.07))
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, AppSpacing.lg)

                    // Open in Map CTA
                    openInMapButton
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, AppSpacing.xl)
                }
            }
        }
    }

    // MARK: - Drag Handle

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 2) // intentional micro-radius
            // cornerRadius: 2 — micro-radius on drag handle pill.
            // Intentional — do not migrate to AppRadius token.
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
                .init(color: .clear,                                                              location: 0.00),
                .init(color: isLight
                    ? AppColors.accentSecondary.opacity(0.45)
                    : AppColors.accentPrimary.opacity(0.45),                                      location: 0.08),
                .init(color: isLight
                    ? AppColors.accentTertiary.opacity(0.45)
                    : AppColors.accentSecondary.opacity(0.45),                                    location: 0.50),
                .init(color: isLight
                    ? AppColors.safetyAccent.opacity(0.40)
                    : AppColors.accentTertiary.opacity(0.40),                                     location: 0.92),
                .init(color: .clear,                                                              location: 1.00),
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
                    .fill(AppColors.accentTertiary.opacity(0.06))
                    .frame(width: 300, height: 250)
                    .blur(radius: 90)
                    .offset(x: -80, y: 40)
                Ellipse()
                    .fill(AppColors.accentSecondary.opacity(0.05))
                    .frame(width: 250, height: 200)
                    .blur(radius: 90)
                    .offset(x: 100, y: 100)
            }
        } else {
            ZStack {
                Ellipse()
                    .fill(AppColors.accentSecondary.opacity(0.10))
                    .frame(width: 300, height: 250)
                    .blur(radius: 80)
                    .offset(x: -80, y: 40)
                Ellipse()
                    .fill(AppColors.accentTertiary.opacity(0.07))
                    .frame(width: 250, height: 200)
                    .blur(radius: 80)
                    .offset(x: 100, y: 100)
            }
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {

                Text("THE PULSE")
                    .font(AppFonts.overline)
                    .tracking(2.5)
                    .foregroundStyle(
                        isLight ? AppColors.textTertiary : AppColors.textTertiary
                    )

                LivingText(
                    text: "The \(currentTier.label) Space",
                    font: AppFonts.sectionHeading
                )

                Text(currentTier.sublabel)
                    .font(AppFonts.caption)
                    .foregroundStyle(
                        isLight
                            ? AppColors.textSecondary.opacity(0.75)
                            : AppColors.textSecondary.opacity(0.75)
                    )
            }

            Spacer()

            Button {
                onDismiss?()
            } label: {
                Image(systemName: AppIcons.close)
                    // .caption scales with Dynamic Type — correct for
                    // icon-only close buttons at this visual weight.
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        isLight ? AppColors.textTertiary : AppColors.textTertiary
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
            .accessibilityLabel("Close")
            .padding(.top, AppSpacing.xs)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: AppSpacing.sm) {
            statCell(
                label: "STREAK",
                value: "\(streakCount) day\(streakCount == 1 ? "" : "s")",
                valueColor: nil
            )
            statCell(
                label: "AVG TIER",
                value: avgTier.label,
                valueColor: isLight ? AppColors.accentTertiary : AppColors.accentSecondary
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
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(label)
                .font(AppFonts.overline)
                .tracking(1.5)
                .foregroundStyle(
                    isLight ? AppColors.textTertiary : AppColors.textTertiary
                )
            Text(value)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(
                    valueColor ?? (isLight
                        ? AppColors.textPrimary
                        : AppColors.textPrimary)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(
                    isLight
                        ? Color.white.opacity(0.60)
                        : Color.white.opacity(0.04)
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
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
        HStack(spacing: AppSpacing.xs) {
            ForEach(PulseWindow.allCases) { window in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(AppAnimation.fast) {
                        selectedWindow = window
                    }
                } label: {
                    Text(window.rawValue)
                        .font(AppFonts.buttonLabelSmall)
                        .foregroundStyle(
                            selectedWindow == window
                                ? AppColors.accentSecondary
                                : (isLight
                                    ? AppColors.textTertiary
                                    : AppColors.textTertiary)
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background {
                            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                .fill(
                                    selectedWindow == window
                                        ? (isLight
                                            ? AppColors.accentSecondary.opacity(0.10)
                                            : AppColors.accentSecondary.opacity(0.20))
                                        : Color.clear
                                )
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                .strokeBorder(
                                    selectedWindow == window
                                        ? AppColors.accentSecondary.opacity(isLight ? 0.35 : 0.40)
                                        : (isLight
                                            ? Color.black.opacity(0.07)
                                            : Color.white.opacity(0.07)),
                                    lineWidth: 1
                                )
                        }
                }
                .buttonStyle(.plain)
                .animation(AppAnimation.fast, value: selectedWindow)
            }
        }
    }

    // MARK: - Graph Card

    private var graphCard: some View {
        GeometryReader { geo in
            let W             = geo.size.width
            let pointSpacing: CGFloat = 55
            let safeCount     = max(0, filteredEntries.count - 1)
            let canvasW       = max(W, CGFloat(safeCount) * pointSpacing + 64)
            let canvasH:      CGFloat = 220

            ZStack {
                // Card surface
                // TODO: Color(hex: "0C0A16") requires an AppColors token before migration.
                // cardBackground is the semantic replacement candidate — confirm with design.
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .fill(
                        isLight
                            ? Color.white.opacity(0.60)
                            : Color(hex: "0C0A16").opacity(0.90)
                    )

                // Subtle iridescence
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: isLight
                                    ? AppColors.accentSecondary.opacity(0.05)
                                    : AppColors.accentPrimary.opacity(0.06),    location: 0.0),
                                .init(color: isLight
                                    ? AppColors.accentTertiary.opacity(0.04)
                                    : AppColors.accentSecondary.opacity(0.05),  location: 0.5),
                                .init(color: isLight
                                    ? AppColors.safetyAccent.opacity(0.03)
                                    : AppColors.accentTertiary.opacity(0.04),   location: 1.0),
                            ],
                            startPoint: .topLeading,
                            endPoint:   .bottomTrailing
                        )
                    )

                // Rim
                LinearGradient(
                    stops: [
                        .init(color: .clear,                                                      location: 0.00),
                        .init(color: isLight
                            ? AppColors.accentSecondary.opacity(0.42)
                            : AppColors.accentPrimary.opacity(0.42),             location: 0.08),
                        .init(color: isLight
                            ? AppColors.accentTertiary.opacity(0.42)
                            : AppColors.accentSecondary.opacity(0.42),           location: 0.50),
                        .init(color: isLight
                            ? AppColors.safetyAccent.opacity(0.36)
                            : AppColors.accentTertiary.opacity(0.36),            location: 0.92),
                        .init(color: .clear,                                                      location: 1.00),
                    ],
                    startPoint: .leading,
                    endPoint:   .trailing
                )
                .frame(height: 1.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                // Border
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: isLight
                                    ? AppColors.accentSecondary.opacity(0.25)
                                    : AppColors.accentPrimary.opacity(0.20),     location: 0.0),
                                .init(color: isLight
                                    ? AppColors.accentTertiary.opacity(0.20)
                                    : AppColors.accentSecondary.opacity(0.16),   location: 0.5),
                                .init(color: isLight
                                    ? AppColors.safetyAccent.opacity(0.16)
                                    : AppColors.accentTertiary.opacity(0.12),    location: 1.0),
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
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            }
            .frame(height: 220)
            .shadow(
                color: isLight
                    ? AppColors.accentSecondary.opacity(0.07)
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
            HStack(spacing: AppSpacing.sm) {
                Text("Open in Map")
                    .font(AppFonts.buttonLabel)
                Image(systemName: AppIcons.arrowRight)
                    // .caption scales with Dynamic Type — correct for
                    // inline directional icons accompanying button label text.
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(AppColors.accentSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(AppColors.accentSecondary.opacity(isLight ? 0.10 : 0.18))
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(
                        AppColors.accentSecondary.opacity(isLight ? 0.35 : 0.45),
                        lineWidth: 1.5
                    )
            }
            .shadow(
                color: AppColors.accentSecondary.opacity(isLight ? 0.12 : 0.20),
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
        AppColors.pageBackground.ignoresSafeArea()
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
        AppColors.pageBackground.ignoresSafeArea()
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
        AppColors.pageBackground.ignoresSafeArea()
        PulseSheetView(
            entries:     [],
            onDismiss:   {},
            onOpenInMap: {}
        )
    }
    .preferredColorScheme(.dark)
}
