//
//  VaylButton.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/10/26.
//

// Shared/Components/Buttons/VaylButton.swift

import SwiftUI

struct VaylButton: View {

    let label: String
    var style: VaylButtonStyle = .primary
    var size: VaylButtonSize   = .fullWidth
    var isLoading: Bool        = false
    var isDisabled: Bool       = false
    var action: () -> Void

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Animation State

    @State private var isPressed: Bool          = false
    @State private var isHovered: Bool          = false
    @State private var borderProgress: CGFloat  = 0
    @State private var glowIntensity: Double    = 0
    @State private var hairlineVisible: Bool    = true

    // CACurrentMediaTime — monotonic, nanosecond-precision.
    // Date() drifts under NTP corrections and has no sub-millisecond
    // guarantee. pressDownTime drives the glow scheduling delay — any
    // imprecision here fires the glow at the wrong moment.
    @State private var pressDownTime: CFTimeInterval = 0
    @State private var glowTask: Task<Void, Never>?

    // MARK: - Haptics
    // @State — UIImpactFeedbackGenerator is a reference type.
    // Storing as private let on a struct recreates the generator on
    // every body evaluation. @State initialises once at view birth
    // and survives all re-renders.

    @State private var softHaptic   = UIImpactFeedbackGenerator(style: .soft)
    @State private var mediumHaptic = UIImpactFeedbackGenerator(style: .medium)

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Base fill — lifted above void so the pill reads as a surface.
                Capsule()
                    .fill(Color(.sRGB, red: 32/255, green: 28/255, blue: 52/255))

                // Holographic shimmer
                // clipShape applied before opacity so the alpha
                // composites against the already-clipped region,
                // not a sharp rectangular boundary.
                HolographicShimmer()
                    .clipShape(Capsule())
                    .opacity(shimmerOpacity)
                    // AUDIT FLAG (2026-07-08): easeInOut(duration: 0.20) has no exact-value
                    // token - existing 0.2s tokens (exit, desireDepthExit) are ease-IN, not
                    // ease-in-out. Left as a raw literal pending a minted token.
                    .animation(.easeInOut(duration: 0.20), value: isPressed)

                // Border effect
                // No drawingGroup() here — VaylBorderEffect uses
                // .mask + .blendMode(.destinationOut) to restrict the
                // halo to the outward-facing stroke edge.
                // drawingGroup() rasterises before the blend resolves,
                // collapsing the mask to a rectangle.
                VaylBorderEffect(
                    width: w,
                    height: h,
                    cornerRadius: h / 2,
                    progress: borderProgress,
                    glowIntensity: glowIntensity,
                    hairlineVisible: hairlineVisible
                )

                // Label or loading indicator
                if isLoading {
                    ProgressView()
                        .tint(Color.white)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                } else {
                    Text(label)
                        .font(AppFonts.ctaLabel)
                        .foregroundStyle(Color.white)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            // AUDIT FLAG (2026-07-08): same untokenized 0.20s easeInOut as above - no exact
            // match among existing 0.2s tokens (all ease-IN). Left raw pending a minted token.
            .animation(.easeInOut(duration: 0.20), value: isLoading)
            .frame(width: w, height: h)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(scaleValue)
            .opacity(isDisabled ? 0.4 : 1.0)
            .animation(
                .timingCurve(0.25, 0.46, 0.45, 0.94, duration: 0.15),
                value: isPressed
            )
            // Minimum 44pt hit target — gesture region matches frame.
            // DragGesture reads from the view frame, not contentShape,
            // so the frame itself must meet the minimum.
            .contentShape(Capsule())
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isDisabled, !isLoading else { return }
                        if !isPressed { onPressDown() }
                    }
                    .onEnded { value in
                        guard !isDisabled, !isLoading else { return }

                        // ±20pt slop in each axis beyond the button boundary.
                        // Previous values (w * 0.70, h * 2.0) covered ~70% of
                        // screen width and fired the action on large thumb drags.
                        let horizontalSlop: CGFloat = 20
                        let verticalSlop: CGFloat = 20
                        let inside =
                            abs(value.translation.width)  < (w / 2) + horizontalSlop
                         && abs(value.translation.height) < (h / 2) + verticalSlop

                        if inside { onPressUp() } else { onPressCancel() }
                    }
            )
            .onChange(of: isLoading) { _, loading  in if loading { resetAnimationState() } }
            .onChange(of: isDisabled) { _, disabled in if disabled { resetAnimationState() } }
            .onAppear {
                softHaptic.prepare()
            }
        }
        .frame(maxWidth: size.width == nil ? .infinity : size.width)
        .frame(height: size.height)
        // The press choreography lives on a DragGesture, so this view never
        // reads as a button to assistive tech (or UI automation) on its own.
        // Expose real button semantics without touching the visual/gesture
        // layer: VoiceOver sees and activates a plain Button.
        .accessibilityRepresentation {
            Button(label, action: action)
                .disabled(isDisabled || isLoading)
        }
    }

    // MARK: - Derived Values

    private var scaleValue: CGFloat {
        if isPressed { return 0.98 }
        if isHovered { return 0.99 }
        return 1.0
    }

    private var shimmerOpacity: Double {
        guard !reduceMotion else {
            return style == .primary ? 0.25 : 0.15
        }
        guard style == .primary else {
            return isPressed ? 0.70 : isHovered ? 0.45 : 0.35
        }
        return isPressed ? 1.0 : isHovered ? 0.85 : 0.75
    }

    // MARK: - Gesture Handlers

    private func onPressDown() {
        glowTask?.cancel()
        glowTask      = nil
        glowIntensity = 0

        isPressed     = true
        pressDownTime = CACurrentMediaTime()

        // Hairline STAYS through the press — it is the resting seed the metal
        // border grows out of (a morph, not a hide-then-fill). The fill trims
        // from location 0 (12 o'clock), exactly where the hairline sits, so the
        // metal unfurls from under the glint rather than replacing it.

        softHaptic.impactOccurred()

        if reduceMotion {
            borderProgress = 1
        } else {
            borderProgress = 0
            withAnimation(AppAnimation.borderFill) {
                borderProgress = 1
            }
        }
    }

    private func onPressUp() {
        isPressed = false
        mediumHaptic.impactOccurred()

        // CACurrentMediaTime is monotonic and nanosecond-precision.
        // Date() can drift under NTP corrections, producing a negative
        // or inflated elapsed value that mis-schedules the glow.
        let elapsed       = CACurrentMediaTime() - pressDownTime
        let remainingFill = max(0, AppAnimation.borderFillDuration - elapsed)

        if !reduceMotion {
            glowTask = Task { @MainActor in

                // Wait for the border arcs to visually close.
                if remainingFill > 0 {
                    try? await Task.sleep(
                        nanoseconds: UInt64(remainingFill * 1_000_000_000)
                    )
                }
                guard !Task.isCancelled else { return }

                // Glow in.
                withAnimation(AppAnimation.borderGlowIn) {
                    glowIntensity = 1.0
                }

                // Wait for glow-in to complete before starting the hold.
                // Previous code started the hold sleep concurrently with
                // glow-in — glowIntensity reached 1.0 for ~0 frames before
                // glow-out fired, reading as a flicker rather than a burst.
                let glowInNanos = UInt64(0.12 * 1_000_000_000)
                try? await Task.sleep(nanoseconds: glowInNanos)
                guard !Task.isCancelled else { return }

                // Hold at full intensity.
                try? await Task.sleep(
                    nanoseconds: UInt64(
                        AppAnimation.borderGlowHoldDuration * 1_000_000_000
                    )
                )
                guard !Task.isCancelled else { return }

                // Glow out.
                withAnimation(AppAnimation.borderGlowOut) {
                    glowIntensity = 0.0
                }
            }
        }

        action()
    }

    private func onPressCancel() {
        isPressed       = false
        hairlineVisible = true

        glowTask?.cancel()
        glowTask = nil

        withAnimation(AppAnimation.borderRetract) {
            borderProgress = 0
        }
        withAnimation(AppAnimation.borderGlowOut) {
            glowIntensity = 0.0
        }
    }

    private func resetAnimationState() {
        isPressed       = false
        hairlineVisible = true

        glowTask?.cancel()
        glowTask = nil

        withAnimation(AppAnimation.borderGlowOut) {
            glowIntensity  = 0.0
            borderProgress = 0
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppColors.void
            .ignoresSafeArea()

        VStack(spacing: 32) {

            VaylButton(label: "Ready to begin?") {
                print("tapped")
            }
            .padding(.horizontal, AppSpacing.lg)

            VaylButton(label: "Ready to begin?", isLoading: true) {}
                .padding(.horizontal, AppSpacing.lg)

            VaylButton(label: "Ready to begin?", isDisabled: true) {}
                .padding(.horizontal, AppSpacing.lg)

            VaylButton(label: "Continue", size: .compact) {
                print("tapped")
            }

            VaylButton(label: "Maybe later", style: .secondary) {
                print("tapped")
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }
    .preferredColorScheme(.dark)
}
