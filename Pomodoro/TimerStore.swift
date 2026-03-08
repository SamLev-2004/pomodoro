import Foundation
import Combine
import UserNotifications
import AppKit

@MainActor
class TimerStore: ObservableObject {
    static let shared = TimerStore()

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
    private var wakeObserver: NSObjectProtocol?

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
        let name = AppSettings.availableSounds.contains(settings.soundName) ? settings.soundName : "Glass"
        NSSound(named: NSSound.Name(name))?.play()
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
        guard NSApp != nil else { return }
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self,
                  self.isRunning,
                  let startDate = self.startDate else { return }
            let elapsed = Int(Date().timeIntervalSince(startDate))
            self.secondsRemaining = max(0, self.startSecondsRemaining - elapsed)
            if self.secondsRemaining == 0 {
                self.sessionComplete()
            }
        }
    }

    deinit {
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
}
