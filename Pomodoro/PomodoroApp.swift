import SwiftUI
import KeyboardShortcuts
import UserNotifications

@main
struct PomodoroApp: App {
    @StateObject private var store = TimerStore.shared

    var body: some Scene {
        MenuBarExtra {
            ControlPopoverView(store: store)
        } label: {
            ArcTimerView(store: store)
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
