import XCTest
@testable import MagicKeysCore

final class URLInputTests: XCTestCase {
    func testBareDomainGetsHTTPS() {
        XCTAssertEqual(URLInput.openable("github.com")?.absoluteString, "https://github.com")
    }

    func testBareDomainKeepsItsPathAndQuery() {
        XCTAssertEqual(URLInput.openable("usemagic.io/docs?q=1")?.absoluteString, "https://usemagic.io/docs?q=1")
    }

    func testSurroundingWhitespaceIsTrimmed() {
        XCTAssertEqual(URLInput.openable("  https://usemagic.io \n")?.absoluteString, "https://usemagic.io")
    }

    func testExistingSchemesAreKept() {
        XCTAssertEqual(URLInput.openable("http://example.com")?.absoluteString, "http://example.com")
        XCTAssertEqual(URLInput.openable("mailto:hello@usemagic.io")?.absoluteString, "mailto:hello@usemagic.io")
    }

    func testEmptyInputIsRejected() {
        XCTAssertNil(URLInput.openable(""))
        XCTAssertNil(URLInput.openable("   "))
    }
}
