import SwiftUI

struct ArcTimerView: View {
    @ObservedObject var store: TimerStore

    private let lineWidth: CGFloat = 2.0
    private let size: CGFloat = 16

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius = min(canvasSize.width, canvasSize.height) / 2 - lineWidth

            // Background track
            var trackPath = Path()
            trackPath.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(-90),
                endAngle: .degrees(270),
                clockwise: false
            )
            context.stroke(
                trackPath,
                with: .color(.secondary.opacity(0.35)),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )

            // Progress arc
            let endDegrees = -90 + 360 * store.progress
            guard store.progress > 0.001 else { return }
            var arcPath = Path()
            arcPath.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(-90),
                endAngle: .degrees(endDegrees),
                clockwise: false
            )
            context.stroke(
                arcPath,
                with: .color(store.phase.arcColor),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
        }
        .frame(width: size, height: size)
    }
}
