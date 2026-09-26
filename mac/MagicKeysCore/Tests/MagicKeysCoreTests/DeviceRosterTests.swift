import XCTest
@testable import MagicKeysCore

final class DeviceRosterTests: XCTestCase {
    func testFirstDeviceBecomesActive() {
        var roster = DeviceRoster<String>()
        XCTAssertTrue(roster.attach("a"))
        XCTAssertEqual(roster.active, "a")
    }

    func testSecondDeviceWaitsOnStandby() {
        var roster = DeviceRoster<String>()
        roster.attach("a")
        XCTAssertFalse(roster.attach("b"))
        XCTAssertEqual(roster.active, "a")
    }

    func testUnpluggingASpareKeepsTheActivePad() {
        var roster = DeviceRoster<String>()
        roster.attach("a"); roster.attach("b")
        XCTAssertEqual(roster.remove("b"), .standby)
        XCTAssertEqual(roster.active, "a")
    }

    func testUnpluggingTheActivePadPromotesASpare() {
        var roster = DeviceRoster<String>()
        roster.attach("a"); roster.attach("b")
        XCTAssertEqual(roster.remove("a"), .activeReplaced(by: "b"))
        XCTAssertEqual(roster.active, "b")
    }

    func testUnpluggingTheLastPadDisconnects() {
        var roster = DeviceRoster<String>()
        roster.attach("a")
        XCTAssertEqual(roster.remove("a"), .activeGone)
        XCTAssertNil(roster.active)
    }

    func testUnknownDeviceIsIgnored() {
        var roster = DeviceRoster<String>()
        roster.attach("a")
        XCTAssertNil(roster.remove("z"))
        XCTAssertEqual(roster.active, "a")
    }

    func testReattachingADeviceDoesNotDuplicateIt() {
        var roster = DeviceRoster<String>()
        roster.attach("a"); roster.attach("b"); roster.attach("b"); roster.attach("a")
        XCTAssertEqual(roster.remove("a"), .activeReplaced(by: "b"))
        XCTAssertEqual(roster.remove("b"), .activeGone)
    }
}
