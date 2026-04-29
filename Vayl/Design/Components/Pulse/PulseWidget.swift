// Features/Pulse/PulseWidget.swift
// Open Lightly
//
// Compact Pulse timeline widget for the Home dashboard.
// Shell chrome (surface, orbs, rim, border, shadows, underglow)
// owned by HomeWidgetShell — this view provides zero chrome.
//
// Layout:
//   Header — "THE PULSE" overline + LivingText tier name + sublabel
//   Graph  — static 7-day snapshot, fills remaining space
//   Footer — "The Pulse" label only. No history link — Map tab owns that.
//
// Interactions:
//   Tap anywhere on card → sheet (PulseSheetView)
//   Tap [+] → fullScreenCover (CheckInShell) — stops propagation
//
// isGraphActive removed — no scrollable graph, nothing to lock.
// onViewAll removed — replaced by onOpenInMap threaded to sheet.
// cardHeight owned by HomeWidgetShell via GeometryReader.
// PulseWidget never drives its own size.

import SwiftUI

// MARK: - PulseWidget

struct PulseWidget: View {

    // MARK: - Store

    @EnvironmentObject private var store: PulseStore

    // MARK: - Inputs

    var onOpenInMap: (() -> Void)? = nil

    // MARK: - State

    @State private var showSheet:    Bool        = false
    @State private var showCheckIn:  Bool        = false
    @State private var pendingEntry: PulseEntry? = nil

    // Camera + live state — owned here, passed into CheckInShell
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

    // Last 7 logged entries for the snapshot graph
    private var snapshotEntries: [PulseEntry] {
        Array(entries.suffix(7))
    }

    // MARK: - Body
    // Zero chrome. HomeWidgetShell owns surface, rim, border, shadows.
    // This view renders content only.

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = geo.size.height

            ZStack(alignment: .top) {

                // ── Graph ─────────────────────────────────────
                graphLayer(width: W, height: H)

                // ── Header ────────────────────────────────────
                // Rendered above graph so buttons receive taps
                floatingHeader
                    .frame(width: W)

            }
            .frame(width: W, height: H)
        }
        // ── Sheet — PulseSheetView ─────────────────────────────
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
        // ── Check-in — fullScreenCover ─────────────────────────
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
    // Static PulseGraph — last 7 entries, no scroll, no dot taps.
    // Dot taps belong to PulseSheetView and MapPulseView.

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
    // Overline + LivingText tier name + sublabel + [+] button.
    // Floor gradient uses widgetDarkFloor / white to match
    // HomeWidgetShell header floor layer beneath it.

    private var floatingHeader: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {

                // Left — label stack
                VStack(alignment: .leading, spacing: 2) {

                    // LivingText — tier name is the primary data
                    LivingText(
                        text: currentTier.label,
                        font: AppFonts.body(22, weight: .bold)
                    )

                    // Sublabel — what it correlates to
                    Text(currentTier.sublabel)
                        .font(AppFonts.body(12, weight: .regular))
                        .foregroundStyle(
                            isLight
                                ? AppColors.lightTextSecondary.opacity(0.75)
                                : AppColors.textSecondary.opacity(0.75)
                        )

                    // View Full History — gradient text, opens PulseSheetView
                    Button {
                        showSheet = true
                    } label: {
                        Text("View Full History")
                            .font(AppFonts.body(11, weight: .semibold))
                            .foregroundStyle(
                                isLight
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.purple, AppColors.magenta, AppColors.gold],
                                        startPoint: .leading,
                                        endPoint:   .trailing
                                      ))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                                        startPoint: .leading,
                                        endPoint:   .trailing
                                      ))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
                .opacity(entries.isEmpty ? 0 : 1)

                Spacer()

                // [+] check-in button — stops propagation
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    resetCheckInState()
                    showCheckIn = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                isLight
                                    ? AppColors.magenta.opacity(0.10)
                                    : AppColors.electricViolet.opacity(0.20)
                            )
                            .frame(width: 32, height: 32)

                        Circle()
                            .strokeBorder(
                                isLight
                                    ? AnyShapeStyle(AppColors.warmAuroraBorder.opacity(0.60))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                                        startPoint: .topLeading,
                                        endPoint:   .bottomTrailing
                                      )),
                                lineWidth: 1.2
                            )
                            .frame(width: 32, height: 32)

                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(
                                isLight ? AppColors.magenta : AppColors.purpleBright
                            )
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start daily check-in")
                // Stops the card tap gesture firing beneath this button
                .simultaneousGesture(TapGesture().onEnded {})
                .padding(.top, 2)
            }
            .padding(.horizontal, 15)
            .padding(.top, 13)
            .padding(.bottom, 8)

            // Gradient dissolve into graph
            LinearGradient(
                colors: [
                    (isLight ? Color.white : AppColors.widgetDarkFloor).opacity(0),
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
                        : AppColors.widgetDarkFloor.opacity(0.55),
                    isLight
                        ? Color.white.opacity(0.25)
                        : AppColors.widgetDarkFloor.opacity(0.28),
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
        AppColors.pageBg.ignoresSafeArea()
        ScrollView {
            HomeWidgetShell(
                isLight:     false,
                accentColor: AppColors.cyan,
                rimVariant:  .pulse
            ) {
                ZStack {
                    OrbLayer(accentColor: AppColors.cyan, height: 300, variant: .pulse)
                    PulseWidget()
                }
            }
            .padding(20)
        }
    }
    .environmentObject(seededStore())
    .preferredColorScheme(.dark)
}

#Preview("14 entries — light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        ScrollView {
            HomeWidgetShell(
                isLight:     true,
                accentColor: AppColors.magenta,
                rimVariant:  .pulse
            ) {
                PulseWidget()
            }
            .padding(20)
        }
    }
    .environmentObject(seededStore())
    .preferredColorScheme(.light)
}

#Preview("Zero entries — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        ScrollView {
            HomeWidgetShell(
                isLight:     false,
                accentColor: AppColors.cyan,
                rimVariant:  .pulse
            ) {
                ZStack {
                    OrbLayer(accentColor: AppColors.cyan, height: 300, variant: .pulse)
                    PulseWidget()
                }
            }
            .padding(20)
        }
    }
    .environmentObject(seededStore([]))
    .preferredColorScheme(.dark)
}

#Preview("Single entry — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        ScrollView {
            HomeWidgetShell(
                isLight:     false,
                accentColor: AppColors.cyan,
                rimVariant:  .pulse
            ) {
                ZStack {
                    OrbLayer(accentColor: AppColors.cyan, height: 300, variant: .pulse)
                    PulseWidget()
                }
            }
            .padding(20)
        }
    }
    .environmentObject(seededStore([PulseEntry.previews[0]]))
    .preferredColorScheme(.dark)
}
