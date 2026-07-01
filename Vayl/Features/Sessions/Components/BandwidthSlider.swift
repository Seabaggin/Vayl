//
//  BandwidthSlider.swift
//  Vayl
//
//  3-detent bandwidth reading (Light / Open / Deep) per the cover-family mockup:
//  tactile "dial it in" without false precision. Set privately; never shown to
//  the partner. Snaps to the nearest detent on drag.
//

import SwiftUI

struct BandwidthSlider: View {

    @Binding var selection: CoupleSessionStore.Bandwidth

    private let detents: [CoupleSessionStore.Bandwidth] = [.light, .open, .deep]

    private var fraction: CGFloat {
        switch selection {
        case .light: return 0
        case .open:  return 0.5
        case .deep:  return 1
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("tonight I'm…")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)

            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.borderSubtle)
                        .frame(height: 2)
                        .frame(maxHeight: .infinity, alignment: .center)

                    Capsule()
                        .fill(LinearGradient(
                            colors: [AppColors.spectrumCyan, AppColors.spectrumPurple],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, w * fraction), height: 2)
                        .frame(maxHeight: .infinity, alignment: .center)

                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(AppColors.void)
                            .overlay(Circle().strokeBorder(AppColors.borderDefault, lineWidth: 1))
                            .frame(width: 6, height: 6)
                            .position(x: w * CGFloat(i) / 2, y: geo.size.height / 2)
                    }

                    Circle()
                        .fill(LinearGradient(
                            colors: [AppColors.spectrumCyan, AppColors.spectrumMagenta],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 20, height: 20)
                        .overlay(Circle().strokeBorder(AppColors.borderDefault, lineWidth: 2))
                        .position(x: max(10, min(w - 10, w * fraction)), y: geo.size.height / 2)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { g in
                            let t = max(0, min(1, g.location.x / w))
                            let idx = Int((t * 2).rounded())
                            let next = detents[idx]
                            if next != selection {
                                UISelectionFeedbackGenerator().selectionChanged()
                                withAnimation(AppAnimation.fast) { selection = next }
                            }
                        }
                )
            }
            .frame(height: 24)

            HStack {
                stop("light", is: .light)
                Spacer()
                stop("open", is: .open)
                Spacer()
                stop("deep", is: .deep)
            }

            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "lock")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.spectrumPurple)
                Text("just for you: sets how deep the deck goes")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }

    private func stop(_ label: String, is b: CoupleSessionStore.Bandwidth) -> some View {
        Text(label)
            .font(AppFonts.overline)
            .tracking(1)
            .textCase(.uppercase)
            .foregroundStyle(selection == b ? AppColors.textBody : AppColors.textTertiary)
    }
}
