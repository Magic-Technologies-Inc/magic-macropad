import XCTest
@testable import MagicKeysCore

final class GestureEngineTests: XCTestCase {
    private var engine: GestureEngine!

    override func setUp() {
        engine = GestureEngine(keyCount: 3, timing: GestureTiming(doubleTapWindow: 0.3, holdThreshold: 0.4))
    }

    private func down(_ key: Int, at t: TimeInterval) -> [Gesture] {
        engine.handle(KeyEvent(key: key, isDown: true, seq: 0), at: t)
    }

    private func up(_ key: Int, at t: TimeInterval) -> [Gesture] {
        engine.handle(KeyEvent(key: key, isDown: false, seq: 0), at: t)
    }

    func testTapFiresAfterDoubleTapWindow() {
        XCTAssertEqual(down(0, at: 0.0), [])
        XCTAssertEqual(up(0, at: 0.1), [])
        XCTAssertEqual(engine.nextDeadline, 0.4)  // 0.1 + 0.3 window
        XCTAssertEqual(engine.expire(at: 0.4), [.tap(key: 0)])
        XCTAssertNil(engine.nextDeadline)
    }

    func testDoubleTapFiresAfterWindow() {
        _ = down(0, at: 0.0)
        _ = up(0, at: 0.1)
        _ = down(0, at: 0.25)
        // Second release no longer fires immediately — it waits to see a third tap.
        XCTAssertEqual(up(0, at: 0.35), [])
        XCTAssertEqual(engine.nextDeadline ?? 0, 0.65, accuracy: 1e-9)  // 0.35 + 0.3 window
        XCTAssertEqual(engine.expire(at: 0.66), [.doubleTap(key: 0)])
        XCTAssertNil(engine.nextDeadline)
    }

    func testTripleTapFiresOnThirdRelease() {
        _ = down(0, at: 0.0)
        _ = up(0, at: 0.1)     // awaiting (count 1)
        _ = down(0, at: 0.2)
        _ = up(0, at: 0.3)     // awaiting (count 2)
        _ = down(0, at: 0.4)
        // Third release fires immediately (max taps reached).
        XCTAssertEqual(up(0, at: 0.5), [.tripleTap(key: 0)])
        XCTAssertNil(engine.nextDeadline)
    }

    func testThirdPressHeldBecomesHold() {
        _ = down(0, at: 0.0)
        _ = up(0, at: 0.1)
        _ = down(0, at: 0.2)
        _ = up(0, at: 0.3)
        _ = down(0, at: 0.4)
        XCTAssertEqual(engine.expire(at: 0.8), [.hold(key: 0)])  // 0.4 + 0.4 held
        XCTAssertEqual(up(0, at: 0.9), [])
    }

    func testHoldFiresAtThresholdAndReleaseIsSilent() {
        XCTAssertEqual(down(0, at: 0.0), [])
        XCTAssertEqual(engine.nextDeadline, 0.4)  // hold threshold
        XCTAssertEqual(engine.expire(at: 0.4), [.hold(key: 0)])
        XCTAssertEqual(up(0, at: 1.0), [])
    }

    func testLongPressReleasedBeforeExpireStillCountsAsHold() {
        _ = down(0, at: 0.0)
        XCTAssertEqual(up(0, at: 0.5), [.hold(key: 0)])  // expire never called
    }

    func testSecondPressHeldBecomesHold() {
        _ = down(0, at: 0.0)
        _ = up(0, at: 0.1)
        _ = down(0, at: 0.2)
        XCTAssertEqual(engine.expire(at: 0.6), [.hold(key: 0)])  // 0.2 + 0.4
        XCTAssertEqual(up(0, at: 0.7), [])
    }

    func testTwoSlowTapsAreTwoTaps() {
        _ = down(0, at: 0.0)
        _ = up(0, at: 0.1)
        XCTAssertEqual(engine.expire(at: 0.4), [.tap(key: 0)])
        _ = down(0, at: 0.5)
        _ = up(0, at: 0.6)
        XCTAssertEqual(engine.expire(at: 0.9), [.tap(key: 0)])
    }

    func testKeysAreIndependent() {
        _ = down(0, at: 0.0)
        _ = down(1, at: 0.05)
        _ = up(0, at: 0.1)
        _ = up(1, at: 0.15)
        let gestures = engine.expire(at: 0.5)
        XCTAssertEqual(Set(gestures.map(String.init(describing:))),
                       Set([Gesture.tap(key: 0), Gesture.tap(key: 1)].map(String.init(describing:))))
    }

    func testNextDeadlineIsEarliestAcrossKeys() {
        _ = down(0, at: 0.0)   // hold deadline 0.4
        _ = down(1, at: 0.1)   // hold deadline 0.5
        XCTAssertEqual(engine.nextDeadline, 0.4)
    }

    func testOutOfRangeKeyIsIgnored() {
        XCTAssertEqual(engine.handle(KeyEvent(key: 9, isDown: true, seq: 0), at: 0), [])
    }

    func testLateSecondPressIsNotADoubleTap() {
        _ = down(0, at: 0.0)
        _ = up(0, at: 0.1)            // window deadline: 0.4
        // Timer never fired; a new press arrives after the window lapsed.
        XCTAssertEqual(down(0, at: 0.9), [.tap(key: 0)])  // first press resolves as tap
        XCTAssertEqual(up(0, at: 1.0), [])                 // new press is a fresh first tap...
        XCTAssertEqual(engine.expire(at: 1.3), [.tap(key: 0)])  // ...that resolves via expire
    }

    func testDuplicateDownEventsAreIgnored() {
        _ = down(0, at: 0.0)
        XCTAssertEqual(down(0, at: 0.05), [])  // HID repeat — must not reset hold timer
        XCTAssertEqual(engine.nextDeadline, 0.4)  // still 0.0 + 0.4
        _ = up(0, at: 0.1)
        XCTAssertEqual(engine.expire(at: 0.4), [.tap(key: 0)])
    }

    func testStrayUpWhileIdleIsIgnored() {
        XCTAssertEqual(up(0, at: 0.0), [])
        XCTAssertNil(engine.nextDeadline)
    }

    func testResetClearsPendingGestures() {
        _ = down(0, at: 0.0)          // a hold would be pending
        _ = down(1, at: 0.0)
        engine.reset()
        XCTAssertNil(engine.nextDeadline)               // nothing pending
        XCTAssertEqual(engine.expire(at: 10.0), [])     // and nothing fires later
        // Engine is usable again after reset.
        _ = down(0, at: 11.0)
        XCTAssertEqual(up(0, at: 11.05), [])
        XCTAssertEqual(engine.expire(at: 11.7), [.tap(key: 0)])
    }
}
