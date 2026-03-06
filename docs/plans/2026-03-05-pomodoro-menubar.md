# Pomodoro Menu Bar App — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a native macOS menu bar Pomodoro timer with an animated arc icon, minimal popover controls, and a full settings window.

**Architecture:** A `TimerStore` ObservableObject drives all state; a `MenuBarExtra` renders an animated `Canvas` arc in the menu bar and a floating window popover for controls. Settings persist via `@AppStorage` in a shared `AppSettings` singleton.

**Tech Stack:** Swift 5.9, SwiftUI, macOS 13+, Combine, XCTest, `KeyboardShortcuts` SPM package (sindresorhus/KeyboardShortcuts), xcodegen (brew)

---

## Task 1: Project Scaffolding

**Files:**
- Create: `project.yml`
- Create: `Pomodoro/Info.plist`
- Create: `Pomodoro/Pomodoro.entitlements`
- Generated: `Pomodoro.xcodeproj/` (via xcodegen)

**Step 1: Install xcodegen**

```bash
brew install xcodegen
```

**Step 2: Create `project.yml`**

```yaml
name: Pomodoro
options:
  bundleIdPrefix: com.pomodoro
  deploymentTarget:
    macOS: "13.0"
  createIntermediateGroups: true

packages:
  KeyboardShortcuts:
    url: https://github.com/sindresorhus/KeyboardShortcuts
    from: "2.0.0"

targets:
  Pomodoro:
    type: application
    platform: macOS
    sources:
      - path: Pomodoro
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.pomodoro.app
        SWIFT_VERSION: "5.9"
        MACOSX_DEPLOYMENT_TARGET: "13.0"
        INFOPLIST_FILE: Pomodoro/Info.plist
        CODE_SIGN_ENTITLEMENTS: Pomodoro/Pomodoro.entitlements
    dependencies:
      - package: KeyboardShortcuts

  PomodoroTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - path: PomodoroTests
    dependencies:
      - target: Pomodoro
    settings:
      base:
        MACOSX_DEPLOYMENT_TARGET: "13.0"
```

**Step 3: Create `Pomodoro/Info.plist`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Pomodoro</string>
    <key>CFBundleIdentifier</key>
    <string>com.pomodoro.app</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSUserNotificationAlertStyle</key>
    <string>alert</string>
</dict>
</plist>
```

**Step 4: Create `Pomodoro/Pomodoro.entitlements`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.network.client</key>
    <false/>
</dict>
</plist>
```

**Step 5: Generate Xcode project**

```bash
cd /Users/samuellevkovsky/Desktop/Projects/pomodoro_app
xcodegen generate
```

Expected: `Pomodoro.xcodeproj` created with no errors.

**Step 6: Create source and test directories**

```bash
mkdir -p Pomodoro/Views PomodoroTests
```

**Step 7: Verify build compiles (empty app)**

Create `Pomodoro/PomodoroApp.swift` with a minimal stub:

```swift
import SwiftUI

@main
struct PomodoroApp: App {
    var body: some Scene {
        Settings { EmptyView() }
    }
}
```

```bash
xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro build 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

**Step 8: Commit**

```bash
git init
git add .
git commit -m "feat: scaffold Xcode project with xcodegen"
```

---

## Task 2: SessionPhase + AppSettings

**Files:**
- Create: `Pomodoro/SessionPhase.swift`
- Create: `Pomodoro/AppSettings.swift`
- Create: `PomodoroTests/AppSettingsTests.swift`

**Step 1: Write the failing tests**

Create `PomodoroTests/AppSettingsTests.swift`:

```swift
import XCTest
@testable import Pomodoro

final class AppSettingsTests: XCTestCase {
    func test_defaultWorkDuration_is25Minutes() {
        let settings = AppSettings()
        XCTAssertEqual(settings.workDuration, 25 * 60)
    }

    func test_defaultShortBreakDuration_is5Minutes() {
        let settings = AppSettings()
        XCTAssertEqual(settings.shortBreakDuration, 5 * 60)
    }

    func test_defaultLongBreakDuration_is15Minutes() {
        let settings = AppSettings()
        XCTAssertEqual(settings.longBreakDuration, 15 * 60)
    }

    func test_defaultSessionsBeforeLongBreak_is4() {
        let settings = AppSettings()
        XCTAssertEqual(settings.sessionsBeforeLongBreak, 4)
    }
}
```

**Step 2: Run to confirm failure**

```bash
xcodebuild test -project Pomodoro.xcodeproj -scheme PomodoroTests -destination 'platform=macOS' 2>&1 | grep -E "FAILED|error:|test_"
```

Expected: build error — `AppSettings` not defined.

**Step 3: Create `Pomodoro/SessionPhase.swift`**

```swift
import SwiftUI

enum SessionPhase: String, Equatable {
    case work
    case shortBreak
    case longBreak

    var label: String {
        switch self {
        case .work: return "Work"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }

    var arcColor: Color {
        switch self {
        case .work: return .red
        case .shortBreak: return Color(red: 0.2, green: 0.8, blue: 0.6)
        case .longBreak: return .blue
        }
    }
}
```

**Step 4: Create `Pomodoro/AppSettings.swift`**

```swift
import Foundation

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var workDuration: Int {
        didSet { UserDefaults.standard.set(workDuration, forKey: "workDuration") }
    }
    @Published var shortBreakDuration: Int {
        didSet { UserDefaults.standard.set(shortBreakDuration, forKey: "shortBreakDuration") }
    }
    @Published var longBreakDuration: Int {
        didSet { UserDefaults.standard.set(longBreakDuration, forKey: "longBreakDuration") }
    }
    @Published var sessionsBeforeLongBreak: Int {
        didSet { UserDefaults.standard.set(sessionsBeforeLongBreak, forKey: "sessionsBeforeLongBreak") }
    }
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }
    @Published var soundName: String {
        didSet { UserDefaults.standard.set(soundName, forKey: "soundName") }
    }
    @Published var autoStart: Bool {
        didSet { UserDefaults.standard.set(autoStart, forKey: "autoStart") }
    }

    init() {
        let d = UserDefaults.standard
        self.workDuration = d.object(forKey: "workDuration") as? Int ?? 25 * 60
        self.shortBreakDuration = d.object(forKey: "shortBreakDuration") as? Int ?? 5 * 60
        self.longBreakDuration = d.object(forKey: "longBreakDuration") as? Int ?? 15 * 60
        self.sessionsBeforeLongBreak = d.object(forKey: "sessionsBeforeLongBreak") as? Int ?? 4
        self.soundEnabled = d.object(forKey: "soundEnabled") as? Bool ?? true
        self.soundName = d.string(forKey: "soundName") ?? "Glass"
        self.autoStart = d.object(forKey: "autoStart") as? Bool ?? false
    }

    func duration(for phase: SessionPhase) -> Int {
        switch phase {
        case .work: return workDuration
        case .shortBreak: return shortBreakDuration
        case .longBreak: return longBreakDuration
        }
    }
}
```

**Step 5: Run tests**

```bash
xcodebuild test -project Pomodoro.xcodeproj -scheme PomodoroTests -destination 'platform=macOS' 2>&1 | grep -E "passed|failed|error:"
```

Expected: 4 tests passed.

**Step 6: Commit**

```bash
git add Pomodoro/SessionPhase.swift Pomodoro/AppSettings.swift PomodoroTests/AppSettingsTests.swift
git commit -m "feat: add SessionPhase and AppSettings"
```

---

## Task 3: TimerStore

**Files:**
- Create: `Pomodoro/TimerStore.swift`
- Create: `PomodoroTests/TimerStoreTests.swift`

**Step 1: Write the failing tests**

Create `PomodoroTests/TimerStoreTests.swift`:

```swift
import XCTest
@testable import Pomodoro

@MainActor
final class TimerStoreTests: XCTestCase {
    var store: TimerStore!
    var settings: AppSettings!

    override func setUp() {
        super.setUp()
        settings = AppSettings()
        settings.workDuration = 25 * 60
        settings.shortBreakDuration = 5 * 60
        settings.longBreakDuration = 15 * 60
        settings.sessionsBeforeLongBreak = 4
        settings.autoStart = false
        store = TimerStore(settings: settings)
    }

    func test_initialState_isWorkPhase() {
        XCTAssertEqual(store.phase, .work)
    }

    func test_initialSecondsRemaining_equalsWorkDuration() {
        XCTAssertEqual(store.secondsRemaining, settings.workDuration)
    }

    func test_initialState_isNotRunning() {
        XCTAssertFalse(store.isRunning)
    }

    func test_progress_isZeroAtStart() {
        XCTAssertEqual(store.progress, 0.0, accuracy: 0.001)
    }

    func test_progress_isOneWhenSecondsRemainingIsZero() {
        store.secondsRemaining = 0
        XCTAssertEqual(store.progress, 1.0, accuracy: 0.001)
    }

    func test_skip_workPhase_advancesToShortBreak() {
        store.skip()
        XCTAssertEqual(store.phase, .shortBreak)
    }

    func test_skip_workPhase_incrementsSessionCount() {
        store.skip()
        XCTAssertEqual(store.sessionCount, 1)
    }

    func test_skip_afterFourWorkSessions_advancesToLongBreak() {
        store.skip() // → shortBreak (count=1)
        store.skip() // → work (count=1)
        store.skip() // → shortBreak (count=2)
        store.skip() // → work (count=2)
        store.skip() // → shortBreak (count=3)
        store.skip() // → work (count=3)
        store.skip() // → longBreak (count=0, reset)
        XCTAssertEqual(store.phase, .longBreak)
        XCTAssertEqual(store.sessionCount, 0)
    }

    func test_skip_longBreak_advancesToWork() {
        // Get to long break
        for _ in 0..<7 { store.skip() }
        XCTAssertEqual(store.phase, .longBreak)
        store.skip()
        XCTAssertEqual(store.phase, .work)
    }

    func test_reset_restoresSecondsRemainingForCurrentPhase() {
        store.secondsRemaining = 100
        store.reset()
        XCTAssertEqual(store.secondsRemaining, settings.workDuration)
    }

    func test_reset_stopsTimer() {
        store.start()
        store.reset()
        XCTAssertFalse(store.isRunning)
    }

    func test_updateWorkDuration_resetsSecondsRemaining() {
        settings.workDuration = 30 * 60
        store.applySettingsChange()
        XCTAssertEqual(store.secondsRemaining, 30 * 60)
    }
}
```

**Step 2: Run to confirm failure**

```bash
xcodebuild test -project Pomodoro.xcodeproj -scheme PomodoroTests -destination 'platform=macOS' 2>&1 | grep -E "error:|FAILED"
```

Expected: build error — `TimerStore` not defined.

**Step 3: Create `Pomodoro/TimerStore.swift`**

```swift
import Foundation
import Combine
import UserNotifications
import AppKit

@MainActor
class TimerStore: ObservableObject {
    @Published var phase: SessionPhase = .work
    @Published var secondsRemaining: Int
    @Published var isRunning: Bool = false
    @Published var sessionCount: Int = 0

    let settings: AppSettings

    var progress: Double {
        let total = settings.duration(for: phase)
        guard total > 0 else { return 0 }
        return 1.0 - Double(secondsRemaining) / Double(total)
    }

    private var cancellable: AnyCancellable?
    private var startDate: Date?
    private var startSecondsRemaining: Int = 0
    private var settingsCancellable: AnyCancellable?

    init(settings: AppSettings = .shared) {
        self.settings = settings
        self.secondsRemaining = settings.workDuration
        observeSleep()
    }

    // MARK: - Controls

    func start() {
        guard !isRunning else { return }
        isRunning = true
        startDate = Date()
        startSecondsRemaining = secondsRemaining
        cancellable = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in self?.tick() }
            }
    }

    func pause() {
        isRunning = false
        cancellable = nil
    }

    func reset() {
        pause()
        secondsRemaining = settings.duration(for: phase)
    }

    func skip() {
        pause()
        advancePhase()
    }

    // MARK: - Internal

    func tick() {
        guard let startDate = startDate else { return }
        let elapsed = Int(Date().timeIntervalSince(startDate))
        secondsRemaining = max(0, startSecondsRemaining - elapsed)
        if secondsRemaining == 0 {
            sessionComplete()
        }
    }

    private func sessionComplete() {
        pause()
        playSound()
        sendNotification()
        advancePhase()
        if settings.autoStart {
            start()
        }
    }

    private func advancePhase() {
        switch phase {
        case .work:
            sessionCount += 1
            if sessionCount >= settings.sessionsBeforeLongBreak {
                sessionCount = 0
                phase = .longBreak
            } else {
                phase = .shortBreak
            }
        case .shortBreak, .longBreak:
            phase = .work
        }
        secondsRemaining = settings.duration(for: phase)
    }

    func applySettingsChange() {
        let wasRunning = isRunning
        pause()
        secondsRemaining = settings.duration(for: phase)
        if wasRunning { start() }
    }

    // MARK: - Sound & Notifications

    private func playSound() {
        guard settings.soundEnabled else { return }
        NSSound(named: NSSound.Name(settings.soundName))?.play()
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "\(phase.label) complete"
        content.body = phase == .work ? "Time for a break." : "Back to work."
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // MARK: - Sleep/Wake

    private func observeSleep() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func handleWake() {
        guard isRunning, let startDate = startDate else { return }
        let elapsed = Int(Date().timeIntervalSince(startDate))
        secondsRemaining = max(0, startSecondsRemaining - elapsed)
        if secondsRemaining == 0 {
            Task { @MainActor in sessionComplete() }
        }
    }
}
```

**Step 4: Run tests**

```bash
xcodebuild test -project Pomodoro.xcodeproj -scheme PomodoroTests -destination 'platform=macOS' 2>&1 | grep -E "passed|failed|error:"
```

Expected: 11 tests passed.

**Step 5: Commit**

```bash
git add Pomodoro/TimerStore.swift PomodoroTests/TimerStoreTests.swift
git commit -m "feat: add TimerStore with session logic and sleep/wake handling"
```

---

## Task 4: ArcTimerView

**Files:**
- Create: `Pomodoro/Views/ArcTimerView.swift`

**Step 1: Create `Pomodoro/Views/ArcTimerView.swift`**

No unit tests for pure drawing views — tested manually.

```swift
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
```

**Step 2: Build to confirm no compile errors**

```bash
xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro build 2>&1 | tail -3
```

Expected: `BUILD SUCCEEDED`

**Step 3: Commit**

```bash
git add Pomodoro/Views/ArcTimerView.swift
git commit -m "feat: add ArcTimerView with canvas arc animation"
```

---

## Task 5: ControlPopoverView

**Files:**
- Create: `Pomodoro/Views/ControlPopoverView.swift`

**Step 1: Create `Pomodoro/Views/ControlPopoverView.swift`**

```swift
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
```

**Step 2: Build**

```bash
xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro build 2>&1 | tail -3
```

Expected: `BUILD SUCCEEDED`

**Step 3: Commit**

```bash
git add Pomodoro/Views/ControlPopoverView.swift
git commit -m "feat: add ControlPopoverView with countdown and session dots"
```

---

## Task 6: SettingsView

**Files:**
- Create: `Pomodoro/Views/SettingsView.swift`

**Step 1: Create `Pomodoro/Views/SettingsView.swift`**

```swift
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
        .onChange(of: settings.workDuration) { _, _ in store.applySettingsChange() }
        .onChange(of: settings.shortBreakDuration) { _, _ in store.applySettingsChange() }
        .onChange(of: settings.longBreakDuration) { _, _ in store.applySettingsChange() }
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
```

**Step 2: Build**

```bash
xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro build 2>&1 | tail -3
```

Expected: `BUILD SUCCEEDED`

**Step 3: Commit**

```bash
git add Pomodoro/Views/SettingsView.swift
git commit -m "feat: add SettingsView with duration, sound, and shortcut configuration"
```

---

## Task 7: App Entry Point + Keyboard Shortcut

**Files:**
- Modify: `Pomodoro/PomodoroApp.swift`

**Step 1: Replace stub with full app**

```swift
import SwiftUI
import KeyboardShortcuts

@main
struct PomodoroApp: App {
    private let settings = AppSettings.shared
    @StateObject private var store = TimerStore()

    var body: some Scene {
        MenuBarExtra {
            ControlPopoverView(store: store)
        } label: {
            ArcTimerView(store: store)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(settings: settings, store: store)
        }
    }

    init() {
        TimerStore().requestNotificationPermission()
        setupKeyboardShortcut()
    }

    private func setupKeyboardShortcut() {
        KeyboardShortcuts.onKeyUp(for: .startPause) { [self] in
            Task { @MainActor in
                if store.isRunning { store.pause() } else { store.start() }
            }
        }
    }
}
```

> **Note:** The `init()` creates a temporary `TimerStore` only to call `requestNotificationPermission()`. This is a side-effect call — refactor to a static method if it feels odd.

**Step 2: Build**

```bash
xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro build 2>&1 | tail -3
```

Expected: `BUILD SUCCEEDED`

**Step 3: Run the app manually**

```bash
open /Users/samuellevkovsky/Desktop/Projects/pomodoro_app/build/Debug/Pomodoro.app
# Or run from Xcode: Cmd+R
```

**Manual checklist:**
- [ ] Arc appears in menu bar
- [ ] Clicking the icon opens the popover
- [ ] Play button starts countdown, arc animates
- [ ] Pause stops it; progress is preserved
- [ ] Reset restores full time
- [ ] Skip advances to next phase (Work → Short Break)
- [ ] After 4 work sessions, skip leads to Long Break
- [ ] Settings window opens from popover button
- [ ] Changing durations in settings updates the timer
- [ ] Keyboard shortcut (⌘⇧P default) toggles start/pause
- [ ] Notification fires when a session completes (test with 1-minute work duration)
- [ ] App stays in menu bar only (not in Dock or Cmd+Tab switcher)

**Step 4: Commit**

```bash
git add Pomodoro/PomodoroApp.swift
git commit -m "feat: wire up app entry point with MenuBarExtra, Settings, and keyboard shortcut"
```

---

## Task 8: Final Cleanup + Run All Tests

**Step 1: Run all unit tests**

```bash
xcodebuild test -project Pomodoro.xcodeproj -scheme PomodoroTests -destination 'platform=macOS' 2>&1 | grep -E "passed|failed|error:"
```

Expected: All tests passed, 0 failures.

**Step 2: Save memory note**

Create `/Users/samuellevkovsky/.claude/projects/-Users-samuellevkovsky-Desktop-Projects-pomodoro-app/memory/MEMORY.md`:

```markdown
# Pomodoro App Memory

## Project
- Swift/SwiftUI macOS menu bar app
- Project file: `Pomodoro.xcodeproj` (generated via xcodegen from `project.yml`)
- Min deployment: macOS 13
- SPM dependency: KeyboardShortcuts (sindresorhus)

## Key Files
- `Pomodoro/PomodoroApp.swift` — app entry, MenuBarExtra, Settings scene
- `Pomodoro/AppSettings.swift` — shared singleton, UserDefaults persistence
- `Pomodoro/TimerStore.swift` — session state machine, Combine timer, sleep/wake
- `Pomodoro/SessionPhase.swift` — phase enum with label and arc color
- `Pomodoro/Views/ArcTimerView.swift` — Canvas arc drawn from store.progress
- `Pomodoro/Views/ControlPopoverView.swift` — minimal popover controls
- `Pomodoro/Views/SettingsView.swift` — settings form with KeyboardShortcuts recorder
- `PomodoroTests/TimerStoreTests.swift` — session logic unit tests

## Build
- `xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro build`
- `xcodebuild test -project Pomodoro.xcodeproj -scheme PomodoroTests -destination 'platform=macOS'`
- Regenerate Xcode project: `xcodegen generate`
```

**Step 3: Final commit**

```bash
git add .
git commit -m "chore: complete Pomodoro menu bar app implementation"
```
