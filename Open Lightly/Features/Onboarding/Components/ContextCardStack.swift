import SwiftUI

/// Infinite-scroll gesture-driven card stack.
/// Swipe to browse, tap front card to confirm/unconfirm, auto-advances 0.8s after confirm.
struct ContextCardStack: View {
    @Binding var selection: ContextOption?
    let options: [ContextOption]
    let onAdvance: () -> Void
    var initialIndex: Int = 0

    @State private var currentIndex: Int   = 0
    @State private var dragOffset: CGFloat = 0
    @State private var autoAdvanceTask: Task<Void, Never>?

    private var renderPositions: [Int] {
        (currentIndex - 2 ... currentIndex + 2).map { $0 }
    }

    private func option(at position: Int) -> ContextOption {
        let count = options.count
        let idx   = ((position % count) + count) % count
        return options[idx]
    }

    var body: some View {
        ZStack {
            ForEach(renderPositions, id: \.self) { pos in
                let opt           = option(at: pos)
                let optionIndex   = ((pos % options.count) + options.count) % options.count
                let diff          = CGFloat(pos - currentIndex)
                let normalDrag    = dragOffset / 300
                let effectiveDiff = diff + normalDrag
                let absDiff       = abs(effectiveDiff)
                let sign: CGFloat = effectiveDiff >= 0 ? 1 : -1

                let xOffset  = absDiff < 0.001 ? CGFloat(0) : sign * (30 + absDiff * 18)
                let scale    = max(1 - absDiff * 0.07, 0.8)
                let yOffset  = absDiff * 6
                let rotation = (pos == currentIndex && dragOffset != 0)
                                 ? Double(dragOffset * 0.03) : 0.0
                let opacity  = max(1 - absDiff * 0.35, 0)
                let zIdx     = Double(20 - Int(absDiff * 5))

                ContextCard(
                    option: opt,
                    isFront: pos == currentIndex,
                    isConfirmed: opt.id == selection?.id,
                    index: optionIndex,
                    total: options.count
                )
                .offset(x: xOffset, y: yOffset)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
                .zIndex(zIdx)
            }
        }
        .frame(width: 300, height: 340)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Block drag while confirmed — only taps allowed
                    guard selection == nil else { return }
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    let horizontalMove = abs(value.translation.width)

                    if horizontalMove < 12 {
                        // Tap: toggle confirm on front card
                        // ...existing code...
                        let front = option(at: currentIndex)
                        if front.id == selection?.id {
                            // Unconfirm — cancel pending advance
                            autoAdvanceTask?.cancel()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { selection = nil }
                        } else {
                            // Confirm — schedule auto-advance
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { selection = front }
                            autoAdvanceTask?.cancel()
                            autoAdvanceTask = Task {
                                try? await Task.sleep(for: .seconds(0.45))
                                if !Task.isCancelled {
                                    await MainActor.run { onAdvance() }
                                }
                            }
                        }
                        return
                    }

                    // Swipe — blocked if confirmed
                    guard selection == nil else {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { dragOffset = 0 }
                        return
                    }

                    let predicted = value.predictedEndTranslation.width
                    let actual    = value.translation.width
                    var newIndex  = currentIndex

                    if predicted > 150 || actual > 50 {
                        newIndex = currentIndex - 1
                    } else if predicted < -150 || actual < -50 {
                        newIndex = currentIndex + 1
                    }

                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        currentIndex = newIndex
                        dragOffset   = 0
                    }
                }
        )
        .onAppear {
            if currentIndex == 0 && initialIndex != 0 {
                currentIndex = initialIndex
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                guard selection == nil else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    dragOffset = 18
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        dragOffset = 0
                    }
                }
            }
        }
        .onDisappear {
            autoAdvanceTask?.cancel()
            autoAdvanceTask = nil
        }
    }
}
