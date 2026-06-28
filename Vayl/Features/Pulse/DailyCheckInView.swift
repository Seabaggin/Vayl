// Features/Pulse/CheckIn/DailyCheckInView.swift
// STUB: cinematic camera/line-draw resolution removed with PulseGraph.
// Answer logic extracted to PulseAnswers.swift.
// Will be replaced by PulseCheckInView in Segment 3.

import SwiftUI

// CheckInPhase retained — used by downstream in Segment 3.
enum CheckInPhase: Equatable {
    case idle
    case questions
    case resolving
    case done
}

struct DailyCheckInView: View {
    let entries:     [PulseEntry]
    let graphWidth:  CGFloat
    let graphHeight: CGFloat

    @Binding var camScale:     CGFloat
    @Binding var camTx:        CGFloat
    @Binding var camTy:        CGFloat
    @Binding var liveScore:    Double?
    @Binding var drawProgress: CGFloat

    var onComplete: (PulseEntry) -> Void
    var onDismiss:  () -> Void

    var body: some View {
        Color.clear
    }
}
