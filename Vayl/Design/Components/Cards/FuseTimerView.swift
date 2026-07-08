//
//  FuseTimerView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/28/26.
//

import SwiftUI

struct FuseTimerView: View {

    let size: CGSize
    let cornerRadius: CGFloat
    let lineWidth: CGFloat
    let duration: TimeInterval
    let delay: TimeInterval
    let sparkColor: Color        // NEW — defaults to AppColors.accentPrimary
    let onComplete: () -> Void

    init(
        size: CGSize,
        cornerRadius: CGFloat,
        lineWidth: CGFloat,
        duration: TimeInterval,
        delay: TimeInterval,
        sparkColor: Color = AppColors.accentPrimary,
        onComplete: @escaping () -> Void
    ) {
        self.size         = size
        self.cornerRadius = cornerRadius
        self.lineWidth    = lineWidth
        self.duration     = duration
        self.delay        = delay
        self.sparkColor   = sparkColor
        self.onComplete   = onComplete
    }

    @State private var startDate: Date?
    @State private var progress: Double = 0
    @State private var completed: Bool = false

    var body: some View {
        TimelineView(.animation(paused: completed)) { timeline in
            Canvas { ctx, canvasSize in
                let rect = CGRect(
                    x: lineWidth / 2,
                    y: lineWidth / 2,
                    width: canvasSize.width  - lineWidth,
                    height: canvasSize.height - lineWidth
                )
                let path = RoundedRectangle(cornerRadius: cornerRadius - lineWidth / 2)
                    .path(in: rect)

                drawUnburned(ctx: ctx, path: path, canvasSize: canvasSize)
                drawEmber(ctx: ctx, path: path)
                drawSparkHead(ctx: ctx, path: path)
            }
            .onChange(of: timeline.date) { _, date in
                tick(date: date)
            }
        }
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(delay))
                startDate = Date()
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Tick

    private func tick(date: Date) {
        guard let start = startDate, !completed else { return }
        progress = min(date.timeIntervalSince(start) / duration, 1.0)
        if progress >= 1.0 {
            completed = true
            onComplete()
        }
    }

    // MARK: - Drawing

    // Full border ahead of the spark — this is the unburned segment
    private func drawUnburned(ctx: GraphicsContext, path: Path, canvasSize: CGSize) {
        guard progress < 1.0 else { return }
        let unburned = path.trimmedPath(from: progress, to: 1.0)
        ctx.stroke(
            unburned,
            with: .linearGradient(
                Gradient(colors: [
                    sparkColor.opacity(0.6),
                    sparkColor,
                    sparkColor.opacity(0.6)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: canvasSize.width, y: canvasSize.height)
            ),
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        )
    }

    // Short glowing segment just at the burn edge
    private func drawEmber(ctx: GraphicsContext, path: Path) {
        guard progress < 1.0 else { return }
        let emberEnd = min(progress + 0.04, 1.0)
        let ember    = path.trimmedPath(from: progress, to: emberEnd)
        var emberCtx = ctx
        emberCtx.addFilter(.blur(radius: 3))
        emberCtx.stroke(
            ember,
            with: .color(sparkColor.opacity(0.7)),
            style: StrokeStyle(lineWidth: lineWidth * 1.4, lineCap: .round)
        )
    }

    // Spark head at the current burn position
    private func drawSparkHead(ctx: GraphicsContext, path: Path) {
        let head = path.trimmedPath(from: max(0, progress - 0.001), to: progress)
        guard let pt = head.currentPoint else { return }

        let r    = lineWidth * 1.2
        let rect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)

        // Outer glow
        var glowCtx = ctx
        glowCtx.addFilter(.blur(radius: 5))
        glowCtx.fill(
            Circle().path(in: rect.insetBy(dx: -3, dy: -3)),
            with: .color(sparkColor.opacity(0.6))
        )

        // Core
        ctx.fill(Circle().path(in: rect),
            with: .color(sparkColor))

        // Hot white center
        ctx.fill(Circle().path(in: rect.insetBy(dx: r * 0.45, dy: r * 0.45)),
            with: .color(.white.opacity(0.95)))
    }
}
