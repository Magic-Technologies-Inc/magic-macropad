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
        XCTAssertEqual(config.keys.count, K1Protocol.keyCount)
        for binding in config.keys {
            XCTAssertNil(binding.tap)
            XCTAssertNil(binding.doubleTap)
            XCTAssertNil(binding.hold)
        }
    }

    func testBindingLookupByGesture() {
        var config = K1Config.makeDefault()
        config.keys[1].doubleTap = .media(command: .mute)
        config.keys[2].hold = .shellScript(script: "echo hold")
        XCTAssertEqual(config.action(for: .doubleTap(key: 1)), .media(command: .mute))
        XCTAssertNil(config.action(for: .tap(key: 1)))
        XCTAssertNil(config.action(for: .doubleTap(key: 0)))
        XCTAssertNil(config.action(for: .tap(key: 9)))  // out of range is nil, not a crash
        XCTAssertEqual(config.action(for: .hold(key: 2)), .shellScript(script: "echo hold"))
        XCTAssertNil(config.action(for: .hold(key: 0)))
    }

    func testK1ConfigRoundTripsThroughJSON() throws {
        var config = K1Config(keys: Array(repeating: KeyBinding(), count: K1Protocol.keyCount),
                              timing: GestureTiming(doubleTapWindow: 0.25, holdThreshold: 0.5))
        config.keys[0].tap = .openApp(bundleID: "com.apple.Music")
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(K1Config.self, from: data)
        XCTAssertEqual(decoded, config)
    }
}
