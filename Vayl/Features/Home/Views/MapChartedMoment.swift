//
//  MapChartedMoment.swift
//  Vayl
//
//  The one-shot "map charted" moment. When the first finisher completes their Desire Map,
//  the Vayl aperture draws itself on over an obscured Home, then the line resolves. It plays
//  ONCE and dismisses, a brief beat, never a home state. The ongoing "waiting on your partner"
//  status lives quietly as an icon in the partner pill, not here. The presenter blurs + dims
//  the Home behind this; the scrim below deepens it.
//

import SwiftUI

struct MapChartedMoment: View {
    let partnerName: String
    var onDone: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draw: CGFloat = 0
    @State private var copyIn = false

    var body: some View {
        ZStack {
            AppColors.void.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                VaylMark(drawProgress: draw)
                    .frame(width: 116, height: 116)

                VStack(spacing: AppSpacing.sm) {
                    Text("That's yours now")
                        .font(AppFonts.screenTitle)
                        .foregroundStyle(AppColors.textPrimary)

                    Text("When \(partnerName) finishes theirs,\nyou'll see where you align.")
                        .font(AppFonts.bodyText)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(copyIn ? 1 : 0)
                .offset(y: copyIn ? 0 : AppSpacing.sm)
            }
            .padding(.horizontal, AppSpacing.xl)
        }
        .contentShape(Rectangle())
        .onTapGesture { onDone() }
        .onAppear {
            guard !reduceMotion else { draw = 1; copyIn = true; return }
            withAnimation(AppAnimation.markDraw) { draw = 1 }
            withAnimation(AppAnimation.markCopyRise.delay(AppAnimation.markCopyDelay)) { copyIn = true }
        }
    }
}

#Preview("Map charted moment") {
    ZStack {
        // Mock obscured Home behind the moment (the presenter blurs the real dashboard).
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat)
            .ignoresSafeArea()
            .blur(radius: 8)
            .opacity(0.5)

        MapChartedMoment(partnerName: "Alex")
    }
    .preferredColorScheme(.dark)
}
