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
    @State private var tableForgeEnergy: Double = 0

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
                    // Config crossfade is owned by OnboardingAtmosphere's internal
                    // atmosphereShift — no second animation here (was double-driving it).
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                // ── Layer 3: Table surface ────────────────────────
                TableSurfaceView(
                    fade:               director.tableFade,
                    rimBurst:           tableRimBurst,
                    dissolutionWarp:    director.gender.dissolutionWarp,
                    dissolutionFlowOut: director.gender.dissolutionFlowOut,
                    forgeEnergy:        tableForgeEnergy
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
                // shouldRender — the scene gates its own frames (renders only
                // while cards exist + a short grace to flush removals), so the
                // idle SpriteView costs no GPU behind the rest of the OB.
                // 120fps — deals render at ProMotion rate instead of the SKView
                // default 60, matching the SwiftUI animations around them
                // (CADisableMinimumFrameDurationOnPhone is set in Vayl.plist;
                // non-ProMotion displays clamp to 60 automatically).
                let flightScene = director.cardFlightScene
                SpriteView(
                    scene:   flightScene,
                    preferredFramesPerSecond: 120,
                    options: [.allowsTransparency],
                    shouldRender: { flightScene.shouldRender(at: $0) }
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
                // Suppressed during .context — ContextPhase renders its OWN copy
                // above its card stack (this canvas layer sits below the phase
                // overlay), so rendering both double-composites the dealer line.
                // Mirrors the corner-deck phase guard below.
                if director.projector.projectedTextVisible,
                   let text = director.projector.projectedText,
                   director.phase != .context {
                    ProjectedTextView(text: text, screenSize: size,
                                      anchorYFrac: director.projector.projectedTextAnchorYFrac)
                        .transition(.opacity)
                }

                // ── Layer 8: Corner deck ─────────────────────────
                // Sits below the phase overlay so form screens naturally
                // cover it — deck is only visible during canvas/table moments.
                // Corner deck follows the table world — visible when tableFade > 0 and a card has been collected.
                // Never independently toggled; visibility is purely derived from state.
                // Hidden during .confirmation — the credential cards deal out of the
                // corner into the review fan (ConfirmationPhase), so the source deck
                // would otherwise double up with them.
                // Also hidden during .buildDeck — those same six credentials have
                // collapsed into the centre deck that the forge melts; a corner deck
                // fading back in top-right would double them and contradict "yours alone".
                if director.tableFade > 0.01 && !director.cornerDeckCards.isEmpty
                    && director.phase != .confirmation
                    && director.phase != .buildDeck {
                    CornerDeckView(
                        cards:      director.cornerDeckCards,
                        screenSize: size,
                        deckPulse:  director.deckPulse
                    )
                    .opacity(director.tableFade)
                    .transition(.opacity)
                }

                // ── Layer 9: Phase overlays ───────────────────────
                PhaseOverlayView(director: director, screenSize: size,
                                 tableRimBurst: $tableRimBurst,
                                 tableForgeEnergy: $tableForgeEnergy)
                    .frame(width: size.width, height: size.height)
                    .ignoresSafeArea()

                // ── Layer 10: Corner marks ────────────────────────
            

                
            }
            .frame(width: size.width, height: size.height)
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .onAppear {
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
    @State private var director = VaylDirector()

    var body: some View {
        @Bindable var director = director
        return GeometryReader { geo in
            ZStack {
                OnboardingCanvasView(director: director)
                    .environment(\.realSafeArea, geo.safeAreaInsets)
                    .ignoresSafeArea()

                // ConfirmationPhase edit sheet. Hosted HERE — outside the canvas
                // boundary — and driven by director.editingCredential. A CUSTOM
                // full-bleed, medium-detent bottom sheet (not native .sheet):
                // iOS 26 native sheets inset to floating cards, so this is the
                // only way to get edge-to-edge full width. Medium detent keeps
                // the review fan visible above it.
                if let credential = director.editingCredential {
                    CredentialEditorOverlay(director: director, credential: credential)
                }

                // Single-user couples-first greeting (ContextPhase) — hosted here, outside
                // the canvas, same as the edit overlay above.
                if director.showSingleGreeting {
                    SingleGreetingOverlay(director: director)
                }
            }
            .animation(AppAnimation.standard.reduceMotionSafe, value: director.editingCredential)
            .animation(AppAnimation.standard.reduceMotionSafe, value: director.showSingleGreeting)
        }
    }
}

// MARK: - Phase Router
// Switch on director.phase. VaylDirector is the only thing that changes director.phase.
// Phases hand over with a continuous depth cross-fade (see `phaseHandoff`): the arriving
// phase settles in from slightly forward, the departing phase recedes back — so the canvas
// reads as one space with z-depth, not a slideshow. Reduce Motion → pure opacity.

private struct PhaseOverlayView: View {
    let director:   VaylDirector
    let screenSize: CGSize
    @Binding var tableRimBurst: Double
    @Binding var tableForgeEnergy: Double

    var body: some View {
        ZStack {
            phaseContent
                .transition(phaseHandoff)
        }
        // Pin the ZStack to screen dimensions.
        // Card transforms during NamePhase (offset to deal origin,
        // scaleEffect during lift) exceed the ZStack's natural content
        // size. Without this frame SwiftUI clips anything that renders
        // outside the smaller collapsed boundary.
        .frame(width: screenSize.width, height: screenSize.height)
        .ignoresSafeArea()
        // `slow` (0.5s) over `standard` (0.3s) — slow's own token doc names it the
        // onboarding step-transition animation. reduceMotionSafe → fast opacity confirm.
        .animation(AppAnimation.slow.reduceMotionSafe, value: director.phase)
    }

    /// The active phase view. Each case is a distinct type, so changing `director.phase`
    /// changes identity → `phaseHandoff` plays on the outgoing + incoming phase.
    @ViewBuilder
    private var phaseContent: some View {
        switch director.phase {
        case .stat:
            StatPhase(director: director)

        case .demo:
            DemoPhase(director: director, screenSize: screenSize, tableRimBurst: $tableRimBurst)

        case .name:
            NamePhase(director: director, screenSize: screenSize, tableRimBurst: $tableRimBurst)

        case .gender:
            GenderPhase(director: director, screenSize: screenSize, tableRimBurst: $tableRimBurst)

        case .modeSelect:
            ModeSelectPhase(director: director, screenSize: screenSize)

        case .experienceLevel:
            ExperienceLevelPhase(director: director, screenSize: screenSize)

        case .context:
            ContextPhase(director: director, screenSize: screenSize)

        case .curiosity:
            CuriosityPhase(director: director, screenSize: screenSize)

        case .confirmation:
            ConfirmationPhase(director: director)

        case .buildDeck:
            BuildDeckPhase(director: director, screenSize: screenSize,
                           tableRimBurst: $tableRimBurst,
                           tableForgeEnergy: $tableForgeEnergy)

        case .founderLetter:
            FounderLetterPhase(director: director)
        }
    }

    /// Continuous phase-to-phase depth handoff. FEEL-GATE — the scale magnitudes are
    /// starting points; verify on device and dial to taste. Incoming settles in from
    /// slightly forward (1.02 → 1.0); outgoing recedes back (1.0 → 0.97). Under Reduce
    /// Motion this collapses to a pure opacity cross-fade — scale is motion.
    private var phaseHandoff: AnyTransition {
        // Confirmation → BuildDeck is a pixel-identical deck handoff (the collapsed
        // credential fan and BuildDeck's VaylDeckStack share point/size/face). A depth
        // scale would counter-scale the two near-identical decks about screen-centre and
        // double-image the swap. Both the leaving Confirmation and the arriving BuildDeck
        // evaluate this against the POST-advance phase, so keying on .buildDeck drops the
        // scale on BOTH sides of this one seam only — every other handoff keeps its depth.
        if director.phase == .buildDeck { return .opacity }
        // Staple 1, Loud register — the OB IS the loud register's reference implementation.
        // vaylDepth handles the Reduce Motion collapse to .opacity internally.
        return .vaylDepth(.loud)
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
            @Bindable var director = director
            return GeometryReader { geo in
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
                                        // Jump through the real navigation path so the target
                                        // phase's entry routine runs (advance → handlePhaseEntry).
                                        // Setting director.phase directly skips entry — e.g.
                                        // Curiosity never arms curiosityDemoActive, so its deal
                                        // bails on the guard and the phase looks stuck until you
                                        // reach it through a real transition. The canvas already
                                        // cross-fades on director.phase, so no withAnimation here.
                                        director.advance(to: phase)
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

                // Mirror OnboardingCanvasWrapper's custom editor overlay so the
                // ConfirmationPhase edit sheet works in the preview too.
                if let credential = director.editingCredential {
                    CredentialEditorOverlay(director: director, credential: credential)
                }

                if director.showSingleGreeting {
                    SingleGreetingOverlay(director: director)
                }
            }
            } // GeometryReader
            .animation(AppAnimation.standard, value: director.editingCredential)
            .animation(AppAnimation.standard, value: director.showSingleGreeting)
        }
    }

    return DevWrapper()
        .environment(store)
        .preferredColorScheme(.dark)
}
#endif
