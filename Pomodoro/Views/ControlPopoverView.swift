import SwiftUI

struct ControlPopoverView: View {
    @ObservedObject var store: TimerStore

    var body: some View {
        VStack(spacing: 14) {
            // Session label
            Text(store.phase.label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.secondary)

            // Countdown
            Text(timeString(store.secondsRemaining))
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .contentTransition(.numericText())

            // Session dot indicators
            HStack(spacing: 5) {
                ForEach(0..<store.settings.sessionsBeforeLongBreak, id: \.self) { i in
                    Circle()
                        .fill(i < store.sessionCount % store.settings.sessionsBeforeLongBreak
                              ? store.phase.arcColor
                              : Color.secondary.opacity(0.25))
                        .frame(width: 5, height: 5)
                }
            }

            // Controls
            HStack(spacing: 24) {
                Button(action: store.reset) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Button(action: { store.isRunning ? store.pause() : store.start() }) {
                    Image(systemName: store.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 22, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)

                Button(action: store.skip) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 15, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Divider()
                .padding(.horizontal, -16)

            Button("Settings...") {
                if #available(macOS 14, *) {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                } else {
                    NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: 220)
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
