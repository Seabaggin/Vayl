//
//  OnboardingCanvasView.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/9/26.
//


//
//  OnboardingCanvasView.swift
//  Vayl
//

// Features/Onboarding/Canvas/OnboardingCanvasView.swift

import SwiftUI

/// The single persistent canvas for the entire OB flow.
/// One ZStack. Ten layers. Never changes structure.
/// No NavigationStack. No .sheet(isPresented:) within this boundary.
struct OnboardingCanvasView: View {

    @State private var director = VaylDirector()

    // OnboardingStore is injected from the environment at the root.
    // VaylDirector needs a reference to it for commit() at appArrival.
    @Environment(OnboardingStore.self) private var onboardingStore

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                // ── Layer 1: Void ─────────────────────────────────
                AppColors.void
                    .ignoresSafeArea()

                // ── Layer 2: Atmosphere ───────────────────────────
                OnboardingAtmosphere()
                    .opacity(0.68)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                // ── Layer 3: Table surface ────────────────────────
                TableSurfaceView(
                    fade: director.tableFade
                )
                .ignoresSafeArea()

                // ── Layer 4: Deal point ───────────────────────────
                DealPointView(
                    intensity:  director.dealPointIntensity,
                    screenSize: size
                )

                // ── Layer 5: Table cards ──────────────────────────
                ForEach(director.tableCards) { card in
                    VaylCardRenderer(card: card, screenSize: size)
                }

                // ── Layer 6: In-flight cards ──────────────────────
                ForEach(director.inFlightCards) { card in
                    VaylCardRenderer(card: card, screenSize: size)
                }

                // ── Layer 7: Projected dealer text ────────────────
                if director.projectedTextVisible,
                   let text = director.projectedText {
                    ProjectedTextView(text: text, screenSize: size)
                        .transition(.opacity)
                }

                // ── Layer 8: Phase overlays ───────────────────────
                PhaseOverlayView(director: director, screenSize: size)

                // ── Layer 9: Corner deck ──────────────────────────
                if director.cornerDeckVisible {
                    CornerDeckView(
                        cards:      director.cornerDeckCards,
                        screenSize: size
                    )
                }

                // ── Layer 10: Corner marks ────────────────────────
                CornerMarksView()
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

// MARK: - Phase Router
// Switch on director.phase. All transitions use .opacity.
// VaylDirector is the only thing that changes director.phase.

private struct PhaseOverlayView: View {
    let director:   VaylDirector
    let screenSize: CGSize

    var body: some View {
        ZStack {
            switch director.phase {
            case .stat:
                StatPhase(director: director)
                    .transition(.opacity)

            case .name:
                NamePhase(director: director, screenSize: screenSize)
                    .transition(.opacity)

            case .gender:
                GenderPhase(director: director, screenSize: screenSize)
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

            case .quiz:
                QuizPhase(director: director, screenSize: screenSize)
                    .transition(.opacity)

            case .curiosityRound1:
                CuriosityPhase(director: director, round: 1, screenSize: screenSize)
                    .transition(.opacity)

            case .curiosityRound2:
                CuriosityPhase(director: director, round: 2, screenSize: screenSize)
                    .transition(.opacity)

            case .buildingPath:
                BuildingPathPhase(director: director)
                    .transition(.opacity)

            case .foil:
                FoilPhase(director: director, screenSize: screenSize)
                    .transition(.opacity)

            case .founderLetter:
                FounderLetterPhase(director: director)
                    .transition(.opacity)

            case .appArrival:
                // No overlay — home screen rising is the content
                EmptyView()
            }
        }
        .animation(AppAnimation.standard, value: director.phase)
    }
}
