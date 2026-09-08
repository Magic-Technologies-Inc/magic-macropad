import XCTest
@testable import MagicKeysCore

final class ActionsTests: XCTestCase {
    func testActionConfigRoundTripsThroughJSON() throws {
        let actions: [ActionConfig] = [
            .openApp(bundleID: "com.apple.Music"),
            .openURL(urlString: "https://usemagic.io"),
            .keystroke(keyCode: 15, modifiers: [.command, .shift]),
            .media(command: .playPause),
            .shellScript(script: "echo hi"),
        ]
        let data = try JSONEncoder().encode(actions)
        let decoded = try JSONDecoder().decode([ActionConfig].self, from: data)
        XCTAssertEqual(decoded, actions)
    }

    func testDefaultConfigHasThreeEmptyBindings() {
        let config = K1Config.makeDefault()
        XCTAssertEqual(config.keys.count, 3)
        for binding in config.keys {
            XCTAssertNil(binding.tap)
            XCTAssertNil(binding.doubleTap)
            XCTAssertNil(binding.hold)
        }
    }

    func testBindingLookupByGesture() {
        var config = K1Config.makeDefault()
        config.keys[1].doubleTap = .media(command: .mute)
        XCTAssertEqual(config.action(for: .doubleTap(key: 1)), .media(command: .mute))
        XCTAssertNil(config.action(for: .tap(key: 1)))
        XCTAssertNil(config.action(for: .doubleTap(key: 0)))
        XCTAssertNil(config.action(for: .tap(key: 9)))  // out of range is nil, not a crash
    }
}
