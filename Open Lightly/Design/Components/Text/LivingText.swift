//
//  LivingText.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/16/26.
//

import SwiftUI

// MARK: - LivingText — animated gradient headline with glow pulse + color drift

struct LivingText: View {
    let text: String
    var font: Font = AppFonts.display(28, weight: .semibold)
    var palette: Palette = .cyanPurple

    // Glow control
    var glowRadius: CGFloat = 8
    var glowFloor:  Double  = 0.15
    var glowCeil:   Double  = 0.35

    // Timing
    var breatheDur: Double  = 4.0
    var driftDur:   Double  = 10.0

    @State private var shiftPhase: CGFloat = 0.0
    @State private var glowHigh = false

    // MARK: - Palettes

    enum Palette {
        case cyanPurple       // cool, trust — "acquainted."
        case purpleMagenta    // warm, intimate — "exploring?"
        case cyanMagenta      // full spectrum — "ready?"
        case magentaGold      // heat, confidence — "connected."
        case cyanGold         // discovery, curiosity — "begin."

        var stops: [Gradient.Stop] {
            switch self {
            case .cyanPurple:
                return [
                    .init(color: AppColors.cyan,    location: 0.00),
                    .init(color: AppColors.purple,  location: 1.00),
                ]
            case .purpleMagenta:
                return [
                    .init(color: AppColors.purple,  location: 0.00),
                    .init(color: AppColors.magenta, location: 1.00),
                ]
            case .cyanMagenta:
                return [
                    .init(color: AppColors.cyan,    location: 0.00),
                    .init(color: AppColors.purple,  location: 0.45),
                    .init(color: AppColors.magenta, location: 1.00),
                ]
            case .magentaGold:
                return [
                    .init(color: AppColors.magenta, location: 0.00),
                    .init(color: AppColors.gold,    location: 1.00),
                ]
            case .cyanGold:
                return [
                    .init(color: AppColors.cyan,    location: 0.00),
                    .init(color: AppColors.gold,    location: 1.00),
                ]
            }
        }
    }

    // Gradient built from chosen palette
    private var gradient: LinearGradient {
        LinearGradient(
            stops: palette.stops,
            startPoint: UnitPoint(x: -shiftPhase,      y: 0),
            endPoint:   UnitPoint(x: 1.4 - shiftPhase, y: 1)
        )
    }

    private var baseText: some View {
        Text(text).font(font)
    }

    var body: some View {
        ZStack {
            // Layer 1: Glow underlay — the breath
            baseText
                .foregroundStyle(.clear)
                .overlay { gradient.mask { baseText } }
                .blur(radius: glowRadius)
                .opacity(glowHigh ? glowCeil : glowFloor)
                .padding(-4)

            // Layer 2: Crisp gradient fill
            baseText
                .foregroundStyle(.clear)
                .overlay { gradient.mask { baseText } }
        }
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            withAnimation(
                .easeInOut(duration: driftDur)
                .repeatForever(autoreverses: true)
            ) {
                shiftPhase = 0.5
            }
            withAnimation(
                .easeInOut(duration: breatheDur)
                .repeatForever(autoreverses: true)
            ) {
                glowHigh = true
            }
        }
    }
}

// MARK: - Previews

#Preview("cyanPurple — acquainted") {
    VStack(alignment: .leading, spacing: 4) {
        Text("Let's get")
            .font(AppFonts.display(28, weight: .semibold))
            .foregroundColor(.white)
        LivingText(
            text: "acquainted.",
            palette: .cyanPurple,
            glowRadius: 6,
            glowFloor: 0.12,
            glowCeil: 0.28,
            breatheDur: 5.0,
            driftDur: 12.0
        )
    }
    .padding(28)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(AppColors.pageBg)
}

#Preview("purpleMagenta — exploring") {
    VStack(alignment: .leading, spacing: 4) {
        Text("How are you")
            .font(AppFonts.display(28, weight: .semibold))
            .foregroundColor(.white)
        LivingText(
            text: "exploring?",
            palette: .purpleMagenta,
            glowRadius: 10,
            glowFloor: 0.18,
            glowCeil: 0.38,
            breatheDur: 4.0,
            driftDur: 10.0
        )
    }
    .padding(28)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(AppColors.pageBg)
}

#Preview("cyanMagenta — ready") {
    VStack(alignment: .leading, spacing: 4) {
        Text("Are you")
            .font(AppFonts.display(28, weight: .semibold))
            .foregroundColor(.white)
        LivingText(
            text: "ready?",
            palette: .cyanMagenta,
            glowRadius: 14,
            glowFloor: 0.22,
            glowCeil: 0.45,
            breatheDur: 3.0,
            driftDur: 8.0
        )
    }
    .padding(28)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(AppColors.pageBg)
}

#Preview("magentaGold — connected") {
    VStack(alignment: .leading, spacing: 4) {
        Text("Stay")
            .font(AppFonts.display(28, weight: .semibold))
            .foregroundColor(.white)
        LivingText(
            text: "connected.",
            palette: .magentaGold,
            glowRadius: 10,
            glowFloor: 0.15,
            glowCeil: 0.35,
            breatheDur: 4.0,
            driftDur: 10.0
        )
    }
    .padding(28)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(AppColors.pageBg)
}

#Preview("cyanGold — begin") {
    VStack(alignment: .leading, spacing: 4) {
        Text("Let's")
            .font(AppFonts.display(28, weight: .semibold))
            .foregroundColor(.white)
        LivingText(
            text: "begin.",
            palette: .cyanGold,
            glowRadius: 8,
            glowFloor: 0.15,
            glowCeil: 0.32,
            breatheDur: 4.5,
            driftDur: 11.0
        )
    }
    .padding(28)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(AppColors.pageBg)
}
