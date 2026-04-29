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
            ZStack {
                // Background
                (isLight ? AppColors.lightPageBg : AppColors.pageBg)
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    // ── Navigation bar ────────────────────────
                    navBar
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                        .padding(.bottom, 24)

                    // ── Window selector ───────────────────────
                    windowSelector
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                    // ── Graph ─────────────────────────────────
                    let pointSpacing:    CGFloat = 65
                    let safeCount                = max(0, filteredEntries.count - 1)
                    let graphContentWidth        = max(geo.size.width, CGFloat(safeCount) * pointSpacing + 104)
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
                    .padding(.bottom, 24)
                    // ── Insights placeholder ──────────────────
                    insightsPlaceholder
                        .padding(.horizontal, 20)

                    Spacer()
                }

                // ── Burn overlay — full screen, no clipping ──
                if showSummary, let entry = summaryEntry {
                    PulseDotSummary(
                        entry:       entry,
                        dotPosition: summaryPosition,
                        graphHeight: geo.size.height,
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
                .foregroundStyle(
                    isLight ? AppColors.lightTextPrimary : AppColors.textPrimary
                )

            Spacer()

            if onDismiss != nil {
                Button {
                    onDismiss?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            isLight ? AppColors.lightTextSecondary : AppColors.textSecondary
                        )
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
            }
        }
    }

    // MARK: - Window Selector

    private var windowSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PulseWindow.allCases) { window in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedWindow = window
                        }
                    } label: {
                        Text(window.label)
                            .font(AppFonts.buttonLabelSmall)
                            .foregroundStyle(
                                selectedWindow == window
                                    ? (isLight ? AppColors.lightTextPrimary : AppColors.textPrimary)
                                    : (isLight ? AppColors.lightTextTertiary : AppColors.textTertiary)
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background {
                                Capsule()
                                    .fill(
                                        selectedWindow == window
                                            ? (isLight
                                                ? AnyShapeStyle(AppColors.magenta.opacity(0.10))
                                                : AnyShapeStyle(AppColors.electricViolet.opacity(0.20)))
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
                                                ? AnyShapeStyle(AppColors.warmAuroraBorder.opacity(0.5))
                                                : AnyShapeStyle(LinearGradient(
                                                    colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
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
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Insights Placeholder
    // Scaffold for future trend + insight sections.
    // Shows a clear "coming later" state without feeling broken.

    private var insightsPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("INSIGHTS")
                .font(AppFonts.overline)
                .tracking(2)
                .foregroundStyle(
                    isLight ? AppColors.lightTextTertiary : AppColors.textTertiary
                )

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trends unlock after 4 weeks")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(
                                isLight
                                    ? AppColors.lightTextSecondary
                                    : AppColors.textSecondary
                            )
                        Text("Keep checking in daily to see patterns emerge.")
                            .font(AppFonts.caption)
                            .foregroundStyle(
                                isLight
                                    ? AppColors.lightTextTertiary
                                    : AppColors.textTertiary
                            )
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
                                isLight ? AppColors.magenta : AppColors.electricViolet,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        Text("\(entries.count)")
                            .font(AppFonts.meta)
                            .foregroundStyle(
                                isLight
                                    ? AppColors.lightTextSecondary
                                    : AppColors.textSecondary
                            )
                    }
                    .frame(width: 40, height: 40)
                }
                .padding(16)
            }
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isLight ? AppColors.lightCardFill : AppColors.cardBg
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isLight ? AppColors.lightBorder : AppColors.border,
                        lineWidth: 1
                    )
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
