import SwiftUI
import KeyboardShortcuts
import UserNotifications

@main
struct PomodoroApp: App {
    @StateObject private var store = TimerStore.shared

    var body: some Scene {
        MenuBarExtra(
            store.isRunning
                ? String(format: "%d:%02d", store.secondsRemaining / 60, store.secondsRemaining % 60)
                : "",
            systemImage: "timer"
        ) {
            ControlPopoverView(store: store)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(settings: AppSettings.shared, store: store)
        }
    }

    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        KeyboardShortcuts.onKeyUp(for: .startPause) {
            Task { @MainActor in
                if TimerStore.shared.isRunning {
                    TimerStore.shared.pause()
                } else {
                    TimerStore.shared.start()
                }
            }
        }
    }
}
