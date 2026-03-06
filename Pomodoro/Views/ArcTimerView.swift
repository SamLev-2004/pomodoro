import SwiftUI

struct ArcTimerView: View {
    @ObservedObject private var store = TimerStore.shared

    private let lineWidth: CGFloat = 2.0
    private let size: CGFloat = 16

    var body: some View {
        // TimelineView forces re-renders every 0.5s — MenuBarExtra labels
        // don't reliably propagate @ObservedObject updates on their own.
        TimelineView(.periodic(from: .now, by: 0.5)) { _ in
            Image(systemName: "circle")
                .font(.system(size: size, weight: .ultraLight))
                .foregroundStyle(.secondary.opacity(0.4))
                .overlay {
                    Circle()
                        .trim(from: 0, to: store.progress)
                        .stroke(store.phase.arcColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .padding(2)
                }
        }
    }
}
