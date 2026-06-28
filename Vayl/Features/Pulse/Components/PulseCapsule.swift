// Features/Pulse/Components/PulseCapsule.swift
//
// The Us connector: a stadium (capsule) enclosing two PulsePositions with a
// gradient stroke that blends from one tier colour to the other.
//
// IMPORTANT — coordinate space: PulseCapsule MUST live in the SAME coordinate
// space as the auras it encloses (a ZStack or overlay sized to fieldSize × fieldSize),
// NOT in a separate SVG viewBox. The % orb positions and the capsule are computed
// from the SAME `fieldSize` origin, so they cannot drift apart.
//
// Geometry (mirrors map-pulse-us.html .capsule):
//   capHeight = auraSize + clearance  (the cap's diameter, centred on each orb)
//   capWidth  = distance(centers) + capHeight
//   rotate    = atan2(dy, dx) of the axis from myPosition → partnerPosition
//   position  = midpoint of the two orb centers
//
// When the two positions coincide, capWidth collapses to capHeight, producing
// a tight ring around the shared point.

import SwiftUI

struct PulseCapsule: View {

    let myPosition:      PulsePosition
    let partnerPosition: PulsePosition
    let myColor:         Color
    let partnerColor:    Color
    let fieldSize:       CGFloat
    var auraSize:        CGFloat = 44    // FEEL: must match the aura diameter in the field

    // MARK: - Geometry

    private func fieldPoint(_ pos: PulsePosition) -> CGPoint {
        CGPoint(
            x: pos.openness * fieldSize,
            y: (1 - pos.energy) * fieldSize
        )
    }

    private var geometry: (midX: CGFloat, midY: CGFloat, width: CGFloat, height: CGFloat, angle: Angle) {
        let a  = fieldPoint(myPosition)
        let b  = fieldPoint(partnerPosition)
        let dx = b.x - a.x
        let dy = b.y - a.y
        let dist   = (dx * dx + dy * dy).squareRoot()
        let capH   = auraSize * 1.42                    // FEEL: clearance multiplier
        return (
            midX:  (a.x + b.x) / 2,
            midY:  (a.y + b.y) / 2,
            width:  max(dist + capH, capH),             // collapses to ring when coincident
            height: capH,
            angle:  .radians(atan2(dy, dx))
        )
    }

    // MARK: - Body

    var body: some View {
        let g = geometry
        Capsule()
            .stroke(
                LinearGradient(
                    colors: [myColor, partnerColor],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 1.6
            )
            .frame(width: g.width, height: g.height)
            .rotationEffect(g.angle)
            .position(x: g.midX, y: g.midY)
            .shadow(color: AppColors.borderSubtle.opacity(0.3), radius: 12)
            .opacity(0.82)                              // FEEL: tune vs map-pulse-us.html
    }
}

// MARK: - Preview

#Preview("Wide day / same space") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat).ignoresSafeArea()

        let fieldSize: CGFloat = 260
        let wideMy  = PulsePosition(energy: 0.82, openness: 0.78)
        let widePrt = PulsePosition(energy: 0.18, openness: 0.22)
        let samePos = PulsePosition(energy: 0.82, openness: 0.78)

        VStack(spacing: AppSpacing.xxl) {
            Text("Wide day").font(AppFonts.caption).foregroundStyle(AppColors.textTertiary)
            ZStack {
                PulseField(
                    entries: [
                        PulseFieldEntry(id: "me",      position: wideMy),
                        PulseFieldEntry(id: "partner", position: widePrt),
                    ],
                    size: fieldSize
                )
                PulseCapsule(
                    myPosition: wideMy, partnerPosition: widePrt,
                    myColor: AppColors.auraCoreCyan, partnerColor: AppColors.auraCoreRose,
                    fieldSize: fieldSize
                )
            }
            .frame(width: fieldSize, height: fieldSize)

            Text("Same space").font(AppFonts.caption).foregroundStyle(AppColors.textTertiary)
            ZStack {
                PulseField(
                    entries: [
                        PulseFieldEntry(id: "me",      position: samePos),
                        PulseFieldEntry(id: "partner", position: PulsePosition(energy: 0.80, openness: 0.75)),
                    ],
                    size: fieldSize
                )
                PulseCapsule(
                    myPosition: samePos,
                    partnerPosition: PulsePosition(energy: 0.80, openness: 0.75),
                    myColor: AppColors.auraCoreCyan, partnerColor: AppColors.auraCoreCyan,
                    fieldSize: fieldSize
                )
            }
            .frame(width: fieldSize, height: fieldSize)
        }
    }
    .preferredColorScheme(.dark)
}
