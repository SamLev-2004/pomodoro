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
