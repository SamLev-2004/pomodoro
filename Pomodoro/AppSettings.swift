import Foundation

@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    static let availableSounds = ["Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero", "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink"]

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
        self.workDuration = max(60, d.object(forKey: "workDuration") as? Int ?? 25 * 60)
        self.shortBreakDuration = max(60, d.object(forKey: "shortBreakDuration") as? Int ?? 5 * 60)
        self.longBreakDuration = max(60, d.object(forKey: "longBreakDuration") as? Int ?? 15 * 60)
        self.sessionsBeforeLongBreak = max(1, d.object(forKey: "sessionsBeforeLongBreak") as? Int ?? 4)
        self.soundEnabled = d.object(forKey: "soundEnabled") as? Bool ?? true
        let stored = d.string(forKey: "soundName") ?? "Glass"
        self.soundName = Self.availableSounds.contains(stored) ? stored : "Glass"
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
