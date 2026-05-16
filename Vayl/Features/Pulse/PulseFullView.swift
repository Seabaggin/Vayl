//
//  PulseFullView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/7/26.
//


// Features/Pulse/PulseFullView.swift
// Open Lightly
//
// Full Pulse history screen — lives on the Me|Us tab.
// Stub only — full implementation pending Me|Us tab design.
// Accepts entries + window selection for future build-out.
// Film burn dot summary presented here (not widget).

import SwiftUI

// MARK: - PulseFullView

struct PulseFullView: View {

    // MARK: - Inputs

    var entries:   [PulseEntry]  = PulseEntry.previews
    var onDismiss: (() -> Void)? = nil

    // MARK: - Window State
    // Owned here — widget always uses .twoWeeks

    @State private var selectedWindow: PulseWindow = .twoWeeks

    // MARK: - Camera State
    // Independent from widget — each manages its own camera

    @State private var camScale:     CGFloat = 1.0
    @State private var camTx:        CGFloat = 0.0
    @State private var camTy:        CGFloat = 0.0
    @State private var liveScore:    Double? = nil
    @State private var drawProgress: CGFloat = 0.0

    // MARK: - Dot Summary State
    // Full burn animation lives here — not in widget

    @State private var summaryEntry:    PulseEntry? = nil
    @State private var summaryPosition: CGPoint     = .zero
    @State private var showSummary:     Bool        = false

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Computed

    private var filteredEntries: [PulseEntry] {
        selectedWindow.filter(entries)
    }

    private var graphHeight: CGFloat { 240 }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let layout = AppLayout.from(geo)
            ZStack {
                AppColors.pageBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    // ── Navigation bar ────────────────────────
                    navBar
                        .padding(.horizontal, AppSpacing.md)
                        .topClearance(layout)
                        .padding(.bottom, AppSpacing.lg)

                    // ── Window selector ───────────────────────
                    windowSelector
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, AppSpacing.lg)

                    // ── Graph ─────────────────────────────────
                    let pointSpacing:    CGFloat = 65
                    let safeCount                = max(0, filteredEntries.count - 1)
                    let graphContentWidth        = max(layout.screenWidth, CGFloat(safeCount) * pointSpacing + 104)
                    let graphContentHeight       = graphHeight * 1.6

                    ScrollView([.horizontal, .vertical], showsIndicators: false) {
                        PulseGraph(
                            entries:          filteredEntries,
                            graphWidth:       graphContentWidth,
                            graphHeight:      graphContentHeight,
                            liveScore:        liveScore,
                            drawProgress:     drawProgress,
                            onDotTapped: { entry, point in
                                summaryEntry    = entry
                                summaryPosition = point
                                showSummary     = true
                            },
                            disableTouchGlow: true
                        )
                        .frame(width: graphContentWidth, height: graphContentHeight)
                    }
                    .frame(height: graphContentHeight)
                    .defaultScrollAnchor(.trailing)
                    .padding(.bottom, AppSpacing.lg)

                    // ── Insights placeholder ──────────────────
                    insightsPlaceholder
                        .padding(.horizontal, AppSpacing.md)

                    Spacer()
                }

                // ── Burn overlay — full screen, no clipping ──
                if showSummary, let entry = summaryEntry {
                    PulseDotSummary(
                        entry:       entry,
                        dotPosition: summaryPosition,
                        graphHeight: layout.screenHeight,
                        onDismiss: {
                            showSummary  = false
                            summaryEntry = nil
                        }
                    )
                    .ignoresSafeArea()
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Text("The Pulse")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            if onDismiss != nil {
                Button {
                    onDismiss?()
                } label: {
                    Image(systemName: AppIcons.close)
                        // .callout scales with Dynamic Type — correct for
                        // close buttons at this visual weight.
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background {
                            Circle()
                                .fill(
                                    isLight
                                        ? Color.black.opacity(0.05)
                                        : Color.white.opacity(0.08)
                                )
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
        }
    }

    // MARK: - Window Selector

    private var windowSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(PulseWindow.allCases) { window in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(AppAnimation.fast) {
                            selectedWindow = window
                        }
                    } label: {
                        Text(window.label)
                            .font(AppFonts.buttonLabelSmall)
                            .foregroundStyle(
                                selectedWindow == window
                                    ? (isLight ? AppColors.textPrimary : AppColors.textPrimary)
                                    : (isLight ? AppColors.textTertiary : AppColors.textTertiary)
                            )
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background {
                                Capsule()
                                    .fill(
                                        selectedWindow == window
                                            ? (isLight
                                                ? AnyShapeStyle(AppColors.accentTertiary.opacity(0.10))
                                                : AnyShapeStyle(AppColors.accentSecondary.opacity(0.20)))
                                            : AnyShapeStyle(
                                                (isLight ? Color.black : Color.white).opacity(0.05)
                                              )
                                    )
                            }
                            .overlay {
                                if selectedWindow == window {
                                    Capsule()
                                        .strokeBorder(
                                            isLight
                                                ? AnyShapeStyle(AppColors.spectrumBorder.opacity(0.5))
                                                : AnyShapeStyle(LinearGradient(
                                                    colors: [AppColors.accentPrimary, AppColors.accentSecondary, AppColors.accentTertiary],
                                                    startPoint: .topLeading,
                                                    endPoint:   .bottomTrailing
                                                  )),
                                            lineWidth: 1
                                        )
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            // .padding(.horizontal, 2) // intentional micro-inset — AppSpacing.xxs overshoots — intentional micro-inset preventing
            // pill stroke clipping at scroll view edges. Not a spacing token candidate.
            .padding(.horizontal, 2) // intentional micro-inset — AppSpacing.xxs overshoots
        }
    }

    // MARK: - Insights Placeholder
    // Scaffold for future trend + insight sections.
    // Shows a clear "coming later" state without feeling broken.

    private var insightsPlaceholder: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {

            Text("INSIGHTS")
                .font(AppFonts.overline)
                .tracking(2)
                .foregroundStyle(AppColors.textTertiary)

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Trends unlock after 4 weeks")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textSecondary)
                        Text("Keep checking in daily to see patterns emerge.")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    Spacer()

                    // Progress indicator — entries toward 28 day threshold
                    let progress = min(1.0, Double(entries.count) / 28.0)
                    ZStack {
                        Circle()
                            .stroke(
                                (isLight ? Color.black : Color.white).opacity(0.08),
                                lineWidth: 3
                            )
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                isLight ? AppColors.accentTertiary : AppColors.accentSecondary,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        Text("\(entries.count)")
                            .font(AppFonts.meta)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .frame(width: 40, height: 40)
                }
                .padding(AppSpacing.md)
            }
            .background {
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(AppColors.cardBackground)
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(AppColors.borderSubtle, lineWidth: 1)
            }
        }
    }
}

// MARK: - Previews

#Preview("14 entries — dark") {
    PulseFullView(entries: PulseEntry.previews)
        .preferredColorScheme(.dark)
}

#Preview("14 entries — light") {
    PulseFullView(entries: PulseEntry.previews)
        .preferredColorScheme(.light)
}

#Preview("Zero entries — dark") {
    PulseFullView(entries: [])
        .preferredColorScheme(.dark)
}
