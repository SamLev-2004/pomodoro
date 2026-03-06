import XCTest
@testable import Pomodoro

@MainActor
final class TimerStoreTests: XCTestCase {
    var store: TimerStore!
    var settings: AppSettings!

    override func setUp() async throws {
        try await super.setUp()
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
        store.skip() // work->shortBreak (count=1)
        store.skip() // shortBreak->work
        store.skip() // work->shortBreak (count=2)
        store.skip() // shortBreak->work
        store.skip() // work->shortBreak (count=3)
        store.skip() // shortBreak->work
        store.skip() // work->longBreak (count=0 reset)
        XCTAssertEqual(store.phase, .longBreak)
        XCTAssertEqual(store.sessionCount, 0)
    }

    func test_skip_longBreak_advancesToWork() {
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
