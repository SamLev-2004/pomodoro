import XCTest
@testable import Pomodoro

@MainActor
final class AppSettingsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        let d = UserDefaults.standard
        d.removeObject(forKey: "workDuration")
        d.removeObject(forKey: "shortBreakDuration")
        d.removeObject(forKey: "longBreakDuration")
        d.removeObject(forKey: "sessionsBeforeLongBreak")
        d.removeObject(forKey: "soundEnabled")
        d.removeObject(forKey: "soundName")
        d.removeObject(forKey: "autoStart")
    }

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
