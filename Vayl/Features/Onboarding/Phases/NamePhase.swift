// Vayl/Features/Onboarding/Phases/NamePhase.swift

import SwiftUI

struct NamePhase: View {

    let director:   VaylDirector
    let screenSize: CGSize

    @State private var name:       String  = ""
    @State private var uiAlpha:    Double  = 0
    @State private var dragY:      CGFloat = 0
    @State private var isCharging: Bool    = false

    private var safeTop: CGFloat {
        guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow })
        else { return 44 }
        return window.safeAreaInsets.top
    }

    private var safeBottom: CGFloat {
        guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow })
        else { return 34 }
        return window.safeAreaInsets.bottom
    }

    var body: some View {
        if director.nameInputVisible {
            nameInputLayer
                .opacity(uiAlpha)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.52)) { uiAlpha = 1.0 }
                }
        }
    }

    // MARK: - Name Input Layer

    private var nameInputLayer: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: safeTop + 58)

            // Back button
            Circle()
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                .frame(width: 30, height: 30)
                .overlay {
                    Text("←")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.25))
                }
                .padding(.bottom, 32)

            // Header
            VStack(alignment: .leading, spacing: 0) {
                Text("Let's get")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)
                Text("acquainted.")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.spectrumBorder)
            }
            .padding(.bottom, 32)

            // Name field
            VStack(alignment: .leading, spacing: 5) {
                Text("WHAT DO I CALL YOU?")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.spectrumPurple.opacity(0.78))
                    .tracking(2.5)

                TextField("", text: $name)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .tint(AppColors.spectrumCyan)

                Rectangle()
                    .fill(AppColors.spectrumBorder.opacity(0.60))
                    .frame(height: 2)

                Rectangle()
                    .fill(AppColors.spectrumBorder.opacity(0.15))
                    .frame(height: 8)
                    .blur(radius: 4)
                    .padding(.top, -6)
            }

            Divider()
                .background(AppColors.spectrumPurple.opacity(0.12))
                .padding(.vertical, 24)

            Spacer()

            Text("terms · privacy")
                .font(AppFonts.caption)
                .foregroundStyle(Color.white.opacity(0.09))
                .tracking(2)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer().frame(height: safeBottom + 42)
        }
        .padding(.horizontal, 32)
        .offset(y: dragY)
        .gesture(
            DragGesture()
                .onChanged { v in
                    if v.translation.height > 0 { dragY = v.translation.height }
                }
                .onEnded { v in handleSwipeDown(v.translation.height) }
        )
    }

    // MARK: - Submission

    @MainActor
    private func handleSwipeDown(_ translationY: CGFloat) {
        guard translationY > 80 else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { dragY = 0 }
            return
        }

        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { dragY = 0 }
            return
        }

        submitName()
    }

    @MainActor
    private func submitName() {
        isCharging = true

        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()

        director.onboardingData.displayName = name.trimmingCharacters(in: .whitespaces)

        withAnimation(.easeIn(duration: 0.20)) { uiAlpha = 0 }
        withAnimation(.spring(response: 0.48, dampingFraction: 0.88)) {
            dragY = screenSize.height * 1.2
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(480))
            director.advance(to: .gender)
        }
    }
}

#Preview("NamePhase — name input state") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OBDeepCardFace(deepT: 3.0)
            .ignoresSafeArea()
            .drawingGroup()

        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 58)
            Text("Let's get").font(AppFonts.screenTitle).foregroundStyle(AppColors.textPrimary)
            Text("acquainted.").font(AppFonts.screenTitle).foregroundStyle(AppColors.spectrumBorder)
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    .preferredColorScheme(.dark)
}
