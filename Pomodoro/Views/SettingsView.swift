import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let startPause = Self("startPause", default: .init(.p, modifiers: [.command, .shift]))
}

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var store: TimerStore

    private let availableSounds = ["Glass", "Ping", "Pop", "Blow", "Bottle", "Frog",
                                   "Funk", "Hero", "Morse", "Purr", "Sosumi", "Submarine", "Tink"]

    var body: some View {
        Form {
            Section("Durations") {
                durationStepper("Work", keyPath: \.workDuration)
                durationStepper("Short Break", keyPath: \.shortBreakDuration)
                durationStepper("Long Break", keyPath: \.longBreakDuration)
                Stepper(
                    "Sessions before long break: \(settings.sessionsBeforeLongBreak)",
                    value: $settings.sessionsBeforeLongBreak,
                    in: 1...8
                )
            }

            Section("Sound") {
                Toggle("Enable sounds", isOn: $settings.soundEnabled)
                if settings.soundEnabled {
                    Picker("Alert sound", selection: $settings.soundName) {
                        ForEach(availableSounds, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                }
            }

            Section("Behavior") {
                Toggle("Auto-start next session", isOn: $settings.autoStart)
            }

            Section("Keyboard Shortcut") {
                KeyboardShortcuts.Recorder("Start / Pause", name: .startPause)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 360)
        .onChange(of: settings.workDuration) { _ in store.applySettingsChange() }
        .onChange(of: settings.shortBreakDuration) { _ in store.applySettingsChange() }
        .onChange(of: settings.longBreakDuration) { _ in store.applySettingsChange() }
    }

    @ViewBuilder
    private func durationStepper(_ label: String, keyPath: ReferenceWritableKeyPath<AppSettings, Int>) -> some View {
        let minutes = Binding<Int>(
            get: { settings[keyPath: keyPath] / 60 },
            set: { settings[keyPath: keyPath] = $0 * 60 }
        )
        Stepper("\(label): \(minutes.wrappedValue) min", value: minutes, in: 1...120)
    }
}
