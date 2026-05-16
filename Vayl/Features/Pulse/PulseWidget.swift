//
//  PulseWidget.swift
//  Vayl
//
//  Compact Pulse timeline widget for the Home dashboard.
//  Shell chrome owned by HomeWidgetShell — this view provides zero chrome.
//

import SwiftUI

struct PulseWidget: View {

    // MARK: - Store

    @Environment(PulseStore.self) private var store

    // MARK: - Inputs

    var onOpenInMap: (() -> Void)? = nil

    // MARK: - State

    @State private var showSheet:    Bool        = false
    @State private var showCheckIn:  Bool        = false
    @State private var pendingEntry: PulseEntry? = nil

    @State private var camScale:     CGFloat = 1.0
    @State private var camTx:        CGFloat = 0.0
    @State private var camTy:        CGFloat = 0.0
    @State private var liveScore:    Double? = nil
    @State private var drawProgress: CGFloat = 0.0

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Computed

    private var entries: [PulseEntry] { store.entries }

    private var currentTier: PulseTier {
        guard let last = entries.last else { return PulseTier.tier(for: 2.5) }
        return PulseTier.tier(for: last.capacityScore)
    }

    private var snapshotEntries: [PulseEntry] {
        Array(entries.suffix(7))
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = geo.size.height

            ZStack(alignment: .top) {
                graphLayer(width: W, height: H)
                floatingHeader
                    .frame(width: W)
            }
            .frame(width: W, height: H)
        }
        .sheet(isPresented: $showSheet) {
            PulseSheetView(
                entries:     entries,
                onDismiss:   { showSheet = false },
                onOpenInMap: {
                    showSheet = false
                    onOpenInMap?()
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.clear)
        }
        .fullScreenCover(isPresented: $showCheckIn) {
            CheckInShell(
                entries:      entries,
                camScale:     $camScale,
                camTx:        $camTx,
                camTy:        $camTy,
                liveScore:    $liveScore,
                drawProgress: $drawProgress,
                onComplete: { entry in
                    pendingEntry = entry
                    showCheckIn  = false
                },
                onDismiss: {
                    resetCheckInState()
                    showCheckIn = false
                }
            )
        }
        .onChange(of: showCheckIn) { _, isShowing in
            if !isShowing, let entry = pendingEntry {
                handleNewEntry(entry)
            }
        }
    }

    // MARK: - Graph Layer

    private func graphLayer(width: CGFloat, height: CGFloat) -> some View {
        let clearance: CGFloat = 32
        return PulseGraph(
            entries:          snapshotEntries,
            graphWidth:       width,
            graphHeight:      height - clearance,
            disableTouchGlow: true
        )
        .frame(width: width, height: height - clearance)
        .frame(width: width, height: height, alignment: .bottom)
    }

    // MARK: - Floating Header

    private var floatingHeader: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    LivingText(
                        text: currentTier.label,
                        font: AppFonts.body(22, weight: .bold, relativeTo: .title2)
                    )

                    Text(currentTier.sublabel)
                        .font(AppFonts.body(12, weight: .regular, relativeTo: .caption))
                        .foregroundStyle(
                            isLight
                                ? AppColors.textSecondary.opacity(0.75)
                                : AppColors.textSecondary.opacity(0.75)
                        )

                    Button {
                        showSheet = true
                    } label: {
                        Text("View Full History")
                            .font(AppFonts.body(11, weight: .semibold, relativeTo: .caption2))
                            .foregroundStyle(
                                isLight
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.accentSecondary, AppColors.accentTertiary, AppColors.safetyAccent],
                                        startPoint: .leading,
                                        endPoint:   .trailing
                                      ))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.accentPrimary, AppColors.accentSecondary, AppColors.accentTertiary],
                                        startPoint: .leading,
                                        endPoint:   .trailing
                                      ))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, AppSpacing.xxs)
                }
                .opacity(entries.isEmpty ? 0 : 1)

                Spacer()

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    resetCheckInState()
                    showCheckIn = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                isLight
                                    ? AppColors.accentTertiary.opacity(0.10)
                                    :AppColors.accentSecondary.opacity(0.20)
                            )
                            .frame(width: 32, height: 32)

                        Circle()
                            .strokeBorder(
                                isLight
                                    ? AnyShapeStyle(AppColors.spectrumBorder.opacity(0.60))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.accentPrimary, AppColors.accentSecondary, AppColors.accentTertiary],
                                        startPoint: .topLeading,
                                        endPoint:   .bottomTrailing
                                      )),
                                lineWidth: 1.2
                            )
                            .frame(width: 32, height: 32)

                        Image(AppIcons.plus)
                            .font(AppFonts.caption)
                            .foregroundStyle(
                                isLight ? AppColors.accentTertiary : AppColors.accentSecondary
                            )
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start daily check-in")
                .simultaneousGesture(TapGesture().onEnded {})
                .padding(.top, AppSpacing.xxs)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.sm)

            LinearGradient(
                colors: [
                    (isLight ? Color.white : AppColors.widgetBackground).opacity(0),
                    Color.clear
                ],
                startPoint: .top,
                endPoint:   .bottom
            )
            .frame(height: 20)
        }
        .background {
            LinearGradient(
                colors: [
                    isLight
                        ? Color.white.opacity(0.55)
                        : AppColors.widgetBackground.opacity(0.55),
                    isLight
                        ? Color.white.opacity(0.25)
                        : AppColors.widgetBackground.opacity(0.28),
                    Color.clear
                ],
                startPoint: .top,
                endPoint:   .bottom
            )
            .allowsHitTesting(false)
        }
    }

    // MARK: - Entry Handling

    private func handleNewEntry(_ entry: PulseEntry) {
        store.add(entry)
        pendingEntry = nil
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            resetCheckInState()
        }
    }

    private func resetCheckInState() {
        camScale     = 1.0
        camTx        = 0.0
        camTy        = 0.0
        liveScore    = nil
        drawProgress = 0.0
    }
}

// MARK: - Previews

private func seededStore(_ entries: [PulseEntry] = PulseEntry.previews) -> PulseStore {
    let s = PulseStore()
    entries.forEach { s.add($0) }
    return s
}

#Preview("14 entries — dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ScrollView {
            HomeWidgetShell(
                isLight:     false,
                accentColor: AppColors.accentPrimary,
                rimVariant:  .pulse
            ) {
                ZStack {
                    OrbLayer(accentColor: AppColors.accentPrimary, height: 300, variant: .pulse)
                    PulseWidget()
                }
            }
            .padding(AppSpacing.lg)
        }
    }
    .environment(seededStore())
    .preferredColorScheme(.dark)
}

#Preview("14 entries — light") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ScrollView {
            HomeWidgetShell(
                isLight:     true,
                accentColor: AppColors.accentTertiary,
                rimVariant:  .pulse
            ) {
                PulseWidget()
            }
            .padding(AppSpacing.lg)
        }
    }
    .environment(seededStore())
    .preferredColorScheme(.light)
}

#Preview("Zero entries — dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ScrollView {
            HomeWidgetShell(
                isLight:     false,
                accentColor: AppColors.accentPrimary,
                rimVariant:  .pulse
            ) {
                ZStack {
                    OrbLayer(accentColor: AppColors.accentPrimary, height: 300, variant: .pulse)
                    PulseWidget()
                }
            }
            .padding(AppSpacing.lg)
        }
    }
    .environment(seededStore([]))
    .preferredColorScheme(.dark)
}

#Preview("Single entry — dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ScrollView {
            HomeWidgetShell(
                isLight:     false,
                accentColor: AppColors.accentPrimary,
                rimVariant:  .pulse
            ) {
                ZStack {
                    OrbLayer(accentColor: AppColors.accentPrimary, height: 300, variant: .pulse)
                    PulseWidget()
                }
            }
            .padding(AppSpacing.lg)
        }
    }
    .environment(seededStore([PulseEntry.previews[0]]))
    .preferredColorScheme(.dark)
}
