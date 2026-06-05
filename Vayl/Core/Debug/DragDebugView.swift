// DragDebugView.swift
// Vayl — DEBUG ONLY
// Isolated drag gesture test. Run in Preview canvas to verify DragGesture
// fires correctly. If the circle moves on drag, gestures work fine.
// If it doesn't move, something in the view hierarchy is blocking hit testing.

#if DEBUG

import SwiftUI

struct DragDebugView: View {
    @State private var offset:     CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var dragActive: Bool   = false
    @State private var eventLog:   [String] = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Draggable target
            Circle()
                .fill(dragActive ? Color.green : Color.cyan)
                .frame(width: 80, height: 80)
                .overlay(Text("drag me").font(.caption).foregroundStyle(.black))
                .offset(offset)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            dragActive = true
                            offset = CGSize(
                                width:  lastOffset.width  + v.translation.width,
                                height: lastOffset.height + v.translation.height
                            )
                            log("onChange: \(Int(v.translation.width)), \(Int(v.translation.height))")
                        }
                        .onEnded { v in
                            dragActive = false
                            lastOffset = offset
                            log("onEnded ✓")
                        }
                )

            // Event log
            VStack(alignment: .leading, spacing: 4) {
                Text("DRAG DEBUG")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.yellow)
                ForEach(eventLog.suffix(6), id: \.self) { entry in
                    Text(entry)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.white.opacity(0.7))
                }
                if eventLog.isEmpty {
                    Text("no events yet — try dragging the circle")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(20)
            .allowsHitTesting(false)
        }
    }

    private func log(_ msg: String) {
        let trimmed = eventLog.count > 20 ? Array(eventLog.dropFirst()) : eventLog
        eventLog = trimmed + [msg]
    }
}

#Preview("Drag Isolation Test") {
    DragDebugView()
}

#endif
