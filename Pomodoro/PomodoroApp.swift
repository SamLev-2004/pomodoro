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
            Image(nsImage: MenuBarIcon.render(
                progress: store.progress,
                phase: store.phase
            ))
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
