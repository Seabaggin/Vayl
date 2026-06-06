//
//  OnboardingCanvasView.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/9/26.
//

// Features/Onboarding/Canvas/OnboardingCanvasView.swift

import SwiftData
import SwiftUI
import SpriteKit

/// The single persistent canvas for the entire OB flow.
/// Layer order: void → atmosphere → table → dealpoint → cardFlight(SpriteKit, 4b) →
///              tableCards → inFlightCards → projectedText → phaseOverlay → cornerDeck → marks
/// No NavigationStack. No .sheet(isPresented:) within this boundary.
struct OnboardingCanvasView: View {

    @State var director: VaylDirector
    @State private var tableRimBurst: Double = 0

    @MainActor init() {
        self._director = State(initialValue: VaylDirector())
    }

    init(director: VaylDirector) {
        self._director = State(initialValue: director)
    }

    private var atmosphereConfig: AtmosphereConfig {
        switch director.phase {
        case .stat:         return .stat
        case .name:         return .name
        case .gender:       return .name        // no distinct gender config — name atmosphere
        case .modeSelect:   return .modeSelect
        case .curiosity:    return .curiosityPicker
        default:            return .name         // all remaining phases use name atmosphere
        }
    }

    // OnboardingStore is injected from the environment at the root.
    // VaylDirector needs a reference to it for commit() at founderLetter.
    @Environment(OnboardingStore.self) private var onboardingStore

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                // ── Layer 1: Void ─────────────────────────────────
                AppColors.void
                    .ignoresSafeArea()

                // ── Layer 2: Atmosphere ───────────────────────────
                OnboardingAtmosphere(config: atmosphereConfig)
                    .opacity(0.68)
                    .animation(AppAnimation.standard, value: atmosphereConfig)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                // ── Layer 3: Table surface ────────────────────────
                TableSurfaceView(
                    fade:               director.tableFade,
                    rimBurst:           tableRimBurst,
                    dissolutionWarp:    director.dissolutionWarp,
                    dissolutionFlowOut: director.dissolutionFlowOut
                )
                .ignoresSafeArea()

                // ── Layer 4: Deal point ───────────────────────────
                DealPointView(
                    intensity:  director.dealPointIntensity,
                    screenSize: size
                )

                // ── Layer 4b: SpriteKit card flight ───────────────
                // Persistent physics scene — clear background so the
                // table surface shows through between card flights.
                // allowsHitTesting false — gestures pass through to
                // phase overlays beneath and above this layer.
                // Scene is sized in .onAppear because size is zero
                // at CardFlightScene() init time.
                //
                // PERF NOTE: SpriteView renders continuously even when inFlightCards is empty.
                // Consider gating with .opacity(director.inFlightCards.isEmpty ? 0 : 1)
                // to eliminate idle GPU cost. Test on A14 before enabling — opacity 0 may
                // not stop Metal rendering on all devices.
                SpriteView(
                    scene:   director.cardFlightScene,
                    options: [.allowsTransparency]
                )
                .frame(width: size.width, height: size.height)
                .allowsHitTesting(false)
                .ignoresSafeArea()
                .onAppear {
                    director.cardFlightScene.size = size
                }

                // ── Layer 5: Table cards ──────────────────────────
                ForEach(director.tableCards) { card in
                    VaylCardRenderer(card: card, screenSize: size)
                        .zIndex(Double(card.zIndex))
                }

                // ── Layer 6: In-flight cards ──────────────────────
                ForEach(director.inFlightCards) { card in
                    VaylCardRenderer(card: card, screenSize: size)
                        .zIndex(Double(card.zIndex))
                }

                // ── Layer 7: Projected dealer text ────────────────
                if director.projectedTextVisible,
                   let text = director.projectedText {
                    ProjectedTextView(text: text, screenSize: size)
                        .transition(.opacity)
                }

                // ── Layer 8: Corner deck ─────────────────────────
                // Sits below the phase overlay so form screens naturally
                // cover it — deck is only visible during canvas/table moments.
                // Corner deck follows the table world — visible when tableFade > 0 and a card has been collected.
                // Never independently toggled; visibility is purely derived from state.
                if director.tableFade > 0.01 && !director.cornerDeckCards.isEmpty {
                    CornerDeckView(
                        cards:      director.cornerDeckCards,
                        screenSize: size,
                        deckPulse:  director.deckPulse
                    )
                    .opacity(director.tableFade)
                    .transition(.opacity)
                }

                // ── Layer 9: Phase overlays ───────────────────────
                PhaseOverlayView(director: director, screenSize: size, tableRimBurst: $tableRimBurst)
                    .frame(width: size.width, height: size.height)
                    .ignoresSafeArea()

                // ── Layer 10: Corner marks ────────────────────────
            

                
            }
            .frame(width: size.width, height: size.height)
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .onAppear {
            director.onboardingStore = onboardingStore
            director.start()
        }
    }
}

// MARK: - OnboardingCanvasWrapper
//
// Use this at every call site (AppRootView) instead of OnboardingCanvasView directly.
// This wrapper's GeometryReader sits *outside* the .ignoresSafeArea() chain, so
// geo.safeAreaInsets correctly reports the real device safe area (top:59, bottom:34
// on Face ID phones). Those values are injected into the environment before the
// canvas's own .ignoresSafeArea() gets to consume them.
struct OnboardingCanvasWrapper: View {
    var body: some View {
        GeometryReader { geo in
            OnboardingCanvasView()
                .environment(\.realSafeArea, geo.safeAreaInsets)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Phase Router
// Switch on director.phase. All transitions use .opacity.
// VaylDirector is the only thing that changes director.phase.

private struct PhaseOverlayView: View {
    let director:   VaylDirector
    let screenSize: CGSize
    @Binding var tableRimBurst: Double

    var body: some View {
        ZStack {
            switch director.phase {
            case .stat:
                StatPhase(director: director)
                    .transition(.opacity)

            case .name:
                NamePhase(director: director, screenSize: screenSize, tableRimBurst: $tableRimBurst)
                    .transition(.opacity)

            case .gender:
                GenderPhase(director: director, screenSize: screenSize, tableRimBurst: $tableRimBurst)
                    .transition(.opacity)

            case .modeSelect:
                ModeSelectPhase(director: director, screenSize: screenSize)
                    .transition(.opacity)

            case .experienceLevel:
                ExperienceLevelPhase(director: director, screenSize: screenSize)
                    .transition(.opacity)

            case .context:
                ContextPhase(director: director, screenSize: screenSize)
                    .transition(.opacity)

            case .curiosity:
                CuriosityPhase(director: director, screenSize: screenSize)
                    .transition(.opacity)

            case .confirmation:
                ConfirmationPhase(director: director)
                    .transition(.opacity)

            case .buildDeck:
                BuildDeckPhase(director: director, screenSize: screenSize)
                    .transition(.opacity)

            case .founderLetter:
                FounderLetterPhase(director: director)
                    .transition(.opacity)
            }
        }
        // Pin the ZStack to screen dimensions.
        // Card transforms during NamePhase (offset to deal origin,
        // scaleEffect during lift) exceed the ZStack's natural content
        // size. Without this frame SwiftUI clips anything that renders
        // outside the smaller collapsed boundary.
        .frame(width: screenSize.width, height: screenSize.height)
        .ignoresSafeArea()
        .animation(AppAnimation.standard, value: director.phase)
    }
}

#if DEBUG
#Preview("Full OB Flow") {
    let appState = AppState()
    let store = OnboardingStore(
        modelContainer: ModelContainer.previewContainer,  // in-memory — never hits disk in previews
        appState: appState
    )

    struct DevWrapper: View {
        @State private var director = VaylDirector()
        @State private var menuVisible = true

        var body: some View {
            GeometryReader { geo in
            ZStack(alignment: .bottom) {
                OnboardingCanvasView(director: director)
                    .environment(\.realSafeArea, geo.safeAreaInsets)
                    .ignoresSafeArea()

                if menuVisible {
                    VStack(spacing: 0) {
                        Divider()
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(OBPhase.allCases, id: \.self) { phase in
                                    Button {
                                        withAnimation(AppAnimation.standard) {
                                            director.phase = phase
                                        }
                                    } label: {
                                        Text(String(describing: phase))
                                            .font(.caption.weight(.bold))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                director.phase == phase
                                                    ? AppColors.accentPrimary
                                                    : Color.black.opacity(0.55)
                                            )
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .background(.ultraThinMaterial)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                VStack {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(AppAnimation.standard) {
                                menuVisible.toggle()
                            }
                        } label: {
                            Image(systemName: menuVisible ? "hammer.fill" : "hammer")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 60)
                    }
                    Spacer()
                }
            }
            } // GeometryReader
        }
    }

    return DevWrapper()
        .environment(store)
        .preferredColorScheme(.dark)
}
#endif
