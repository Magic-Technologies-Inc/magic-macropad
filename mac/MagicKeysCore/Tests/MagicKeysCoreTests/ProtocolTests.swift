import XCTest
@testable import MagicKeysCore

final class ProtocolTests: XCTestCase {
    func testParsesKeyDownEvent() {
        let msg = K1Protocol.parse([0x01, 2, 1, 42, 0, 0, 0, 0])
        XCTAssertEqual(msg, .keyEvent(KeyEvent(key: 2, isDown: true, seq: 42)))
    }

    func testParsesKeyUpEvent() {
        let msg = K1Protocol.parse([0x01, 0, 0, 255, 0, 0, 0, 0])
        XCTAssertEqual(msg, .keyEvent(KeyEvent(key: 0, isDown: false, seq: 255)))
    }

    func testParsesInfo() {
        let msg = K1Protocol.parse([0x02, 0, 0, 7, 0, 1, 3, 0])
        XCTAssertEqual(msg, .info(DeviceInfo(firmwareMajor: 0, firmwareMinor: 1, keyCount: 3)))
    }

    func testRejectsWrongLength() {
        XCTAssertNil(K1Protocol.parse([0x01, 0, 1]))
    }

    func testRejectsUnknownMessage() {
        XCTAssertNil(K1Protocol.parse([0x77, 0, 0, 0, 0, 0, 0, 0]))
    }

    func testRejectsOutOfRangeKey() {
        XCTAssertNil(K1Protocol.parse([0x01, 3, 1, 0, 0, 0, 0, 0]))
    }

    func testRejectsInvalidState() {
        XCTAssertNil(K1Protocol.parse([0x01, 1, 2, 0, 0, 0, 0, 0]))
    }

    func testGetInfoReportShape() {
        XCTAssertEqual(K1Protocol.getInfoReport, [0x10, 0, 0, 0, 0, 0, 0, 0])
    }
}
