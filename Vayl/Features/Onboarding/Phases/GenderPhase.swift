//
//  GenderPhase.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/10/26.
//

import SwiftUI

struct GenderPhase: View {

    let director:   VaylDirector
    let screenSize: CGSize

    // TODO: Bryan supplies final copy for GenderPhase
    private let copyLineOne = "One thing helps me read the table right."
    private let copyLineTwo = "How do you identify?"

    private let identities: [String] = [
        "Man", "Woman", "Non-binary", "Transgender", "Genderfluid",
        "Agender", "Bigender", "Genderqueer", "Intersex", "Questioning"
    ]

    // ── Picker state ───────────────────────────────────────────────────────────
    @State private var pickerAlpha:      Double = 0
    @State private var selectedIdentity: String = "Non-binary"
    @State private var isScrolling:      Bool   = false
    @State private var confirmAlpha:     Double = 0
    @State private var confirmTask:      Task<Void, Never>? = nil

    // ── Copy state ─────────────────────────────────────────────────────────────
    @State private var copyAlpha: Double = 0

    // ── Card geometry (needed for drag target sizing and copy positioning) ──────
    private var cardWidth:  CGFloat { AppLayout.obCardWidth(in: screenSize.width) }
    private var cardHeight: CGFloat { AppLayout.obCardHeight(in: screenSize.width) }

    // Resting position offset from center — used to position copy and drag target
    private var cardRestingOffset: CGSize {
        CGSize(
            width:  0,
            height: AppLayout.obTableCardCenterY(in: screenSize.height) - screenSize.height / 2
        )
    }

    // ── Safe area ──────────────────────────────────────────────────────────────
    private var safeBottom: CGFloat {
        guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow })
        else { return 34 }
        return window.safeAreaInsets.bottom
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Invisible drag target — forwards gestures to director for the canvas-level card
            if director.phase == .gender && !director.genderPickerVisible {
                Color.clear
                    .frame(width: cardWidth, height: cardHeight)
                    .contentShape(Rectangle())
                    .position(
                        x: screenSize.width / 2,
                        y: AppLayout.obTableCardCenterY(in: screenSize.height)
                    )
                    .gesture(dragGesture)
            }

            // Copy lines — visible while card is face-down
            if director.genderCopyVisible {
                copyLayer
                    .opacity(copyAlpha)
                    .transition(.opacity.animation(.easeOut(duration: 0.20)))
            }

            // Picker — appears after portal dissolve
            if director.genderPickerVisible {
                pickerLayer
                    .opacity(pickerAlpha)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.52)) { pickerAlpha = 1.0 }
                        // Show confirm button on initial appear (no scroll event yet)
                        confirmTask = Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(900))
                            guard !Task.isCancelled else { return }
                            withAnimation(AppAnimation.standard) { confirmAlpha = 1 }
                        }
                    }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.52)) { copyAlpha = 1.0 }
        }
        .onDisappear { cancelAllTasks() }
    }

    // MARK: - Copy Layer

    private var copyLayer: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(copyLineOne)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textBody)
                .tracking(0.4)
                .multilineTextAlignment(.center)

            Text(copyLineTwo)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, AppSpacing.xl)
        .offset(y: cardRestingOffset.height - cardHeight / 2 - AppSpacing.lg)
    }

    // MARK: - Picker Layer

    private var pickerLayer: some View {
        VStack(spacing: 0) {
            Spacer()

            Picker("Identity", selection: $selectedIdentity) {
                ForEach(identities, id: \.self) { identity in
                    Text(identity)
                        .font(AppFonts.screenTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .tag(identity)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 200)
            .clipped()
            .onChange(of: selectedIdentity) {
                isScrolling = true
                confirmTask?.cancel()
                withAnimation(AppAnimation.fast) { confirmAlpha = 0 }
                confirmTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(600))
                    guard !Task.isCancelled else { return }
                    isScrolling = false
                    withAnimation(AppAnimation.standard) { confirmAlpha = 1 }
                }
            }

            Button {
                confirmSelection()
            } label: {
                Text("That's me")
                    .font(AppFonts.ctaLabel)
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppLayout.ctaHeight)
                    .background(identityGradient(for: selectedIdentity))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            }
            .opacity(confirmAlpha)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)

            Spacer().frame(height: safeBottom + AppSpacing.lg)
        }
    }

    // MARK: - Identity Gradient

    private func identityGradient(for identity: String) -> LinearGradient {
        let colors: (Color, Color) = {
            switch identity {
            case "Man":          return (Color(red: 0.24, green: 0.51, blue: 0.95), Color(red: 0.13, green: 0.36, blue: 0.78))
            case "Woman":        return (Color(red: 0.90, green: 0.35, blue: 0.65), Color(red: 0.70, green: 0.20, blue: 0.50))
            case "Non-binary":   return (Color(red: 0.97, green: 0.84, blue: 0.20), Color(red: 0.60, green: 0.22, blue: 0.80))
            case "Transgender":  return (Color(red: 0.36, green: 0.78, blue: 0.95), Color(red: 0.90, green: 0.50, blue: 0.65))
            case "Genderfluid":  return (Color(red: 0.60, green: 0.22, blue: 0.80), Color(red: 0.24, green: 0.51, blue: 0.95))
            case "Agender":      return (Color(red: 0.45, green: 0.45, blue: 0.45), Color(red: 0.20, green: 0.20, blue: 0.20))
            case "Bigender":     return (Color(red: 0.90, green: 0.35, blue: 0.65), Color(red: 0.24, green: 0.51, blue: 0.95))
            case "Genderqueer":  return (Color(red: 0.60, green: 0.22, blue: 0.80), Color(red: 0.13, green: 0.55, blue: 0.13))
            case "Intersex":     return (Color(red: 0.97, green: 0.78, blue: 0.10), Color(red: 0.55, green: 0.15, blue: 0.75))
            case "Questioning":  return (Color(red: 0.24, green: 0.51, blue: 0.95), Color(red: 0.60, green: 0.22, blue: 0.80))
            default:             return (AppColors.spectrumPurple, AppColors.spectrumCyan)
            }
        }()
        return LinearGradient(colors: [colors.0, colors.1], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                director.applyGenderDrag(dy: value.translation.height)
            }
            .onEnded { value in
                director.endGenderDrag(
                    translationY: value.translation.height,
                    velocityY:    value.predictedEndLocation.y - value.location.y
                )
            }
    }

    // MARK: - Confirm Selection

    @MainActor
    private func confirmSelection() {
        director.onboardingData.genderIdentity = selectedIdentity

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        withAnimation(AppAnimation.fast) { pickerAlpha = 0 }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            director.collectGenderCard()
        }
    }

    // MARK: - Cleanup

    private func cancelAllTasks() {
        confirmTask?.cancel()
        director.cancelGenderTasks()
    }
}
