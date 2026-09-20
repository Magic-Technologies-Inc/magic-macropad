import XCTest
@testable import MagicKeysCore

final class ActionsTests: XCTestCase {
    func testActionConfigRoundTripsThroughJSON() throws {
        let actions: [ActionConfig] = [
            .openApp(bundleID: "com.apple.Music"),
            .openURL(urlString: "https://usemagic.io"),
            .keystroke(keyCode: 15, modifiers: [.command, .shift]),
            .media(command: .playPause),
            .pasteText(text: "hello@usemagic.io"),
            .system(command: .toggleMicMute),
            .shellScript(script: "echo hi", name: "Say hi"),
            .shellScript(script: "echo hi", name: nil),
        ]
        let data = try JSONEncoder().encode(actions)
        let decoded = try JSONDecoder().decode([ActionConfig].self, from: data)
        XCTAssertEqual(decoded, actions)
    }

    func testLegacyShellScriptWithoutNameDecodes() throws {
        // Pre-naming wire format: shellScript had only `script`.
        let legacy = #"[{"shellScript":{"script":"clear"}}]"#
        let decoded = try JSONDecoder().decode([ActionConfig].self, from: Data(legacy.utf8))
        XCTAssertEqual(decoded, [.shellScript(script: "clear", name: nil)])
    }

    func testEverySystemCommandRoundTrips() throws {
        let actions = SystemCommand.allCases.map { ActionConfig.system(command: $0) }
        let data = try JSONEncoder().encode(actions)
        XCTAssertEqual(try JSONDecoder().decode([ActionConfig].self, from: data), actions)
    }

    func testDefaultConfigHasOneDefaultProfileWithEmptyBindings() {
        let config = K1Config.makeDefault()
        XCTAssertEqual(config.profiles.count, 1)
        let profile = config.defaultProfile
        XCTAssertNil(profile.bundleID)
        XCTAssertEqual(profile.keys.count, K1Protocol.keyCount)
        for binding in profile.keys {
            XCTAssertNil(binding.tap)
            XCTAssertNil(binding.doubleTap)
            XCTAssertNil(binding.hold)
        }
        XCTAssertTrue(config.isValid)
    }

    func testBindingLookupByGesture() {
        var config = K1Config.makeDefault()
        config.profiles[0].keys[1].doubleTap = .media(command: .mute)
        config.profiles[0].keys[2].hold = .shellScript(script: "echo hold", name: nil)
        let profile = config.defaultProfile
        XCTAssertEqual(profile.action(for: .doubleTap(key: 1)), .media(command: .mute))
        XCTAssertNil(profile.action(for: .tap(key: 1)))
        XCTAssertNil(profile.action(for: .doubleTap(key: 0)))
        XCTAssertNil(profile.action(for: .tap(key: 9)))  // out of range is nil, not a crash
        XCTAssertEqual(profile.action(for: .hold(key: 2)), .shellScript(script: "echo hold", name: nil))
        XCTAssertNil(profile.action(for: .hold(key: 0)))
    }

    func testActionLookupUsesFrontAppProfile() {
        var config = K1Config.makeDefault()
        config.profiles[0].keys[0].tap = .media(command: .playPause)          // default
        let id = config.addProfile(bundleID: "com.apple.Terminal", name: "Terminal", symbol: "terminal")
        let i = config.profileIndex(id: id)!
        config.profiles[i].keys[0].tap = .shellScript(script: "clear", name: nil)         // Terminal-only

        XCTAssertEqual(config.action(for: .tap(key: 0), bundleID: "com.apple.Terminal"),
                       .shellScript(script: "clear", name: nil))
        XCTAssertEqual(config.action(for: .tap(key: 0), bundleID: "com.apple.Safari"),
                       .media(command: .playPause))  // no Safari profile -> default
        XCTAssertEqual(config.action(for: .tap(key: 0), bundleID: nil),
                       .media(command: .playPause))
    }

    func testUnboundAppGestureInheritsDefault() {
        var config = K1Config.makeDefault()
        config.profiles[0].keys[1].hold = .media(command: .mute)               // default hold
        let id = config.addProfile(bundleID: "com.apple.Terminal", name: "Terminal", symbol: "terminal")
        let i = config.profileIndex(id: id)!
        config.profiles[i].keys[1].tap = .shellScript(script: "clear", name: nil)         // Terminal tap only

        // Terminal defines tap but not hold -> hold inherits the default.
        XCTAssertEqual(config.action(for: .tap(key: 1), bundleID: "com.apple.Terminal"),
                       .shellScript(script: "clear", name: nil))
        XCTAssertEqual(config.action(for: .hold(key: 1), bundleID: "com.apple.Terminal"),
                       .media(command: .mute))
        // The default profile itself never "inherits" (returns nil when unbound).
        XCTAssertNil(config.action(for: .doubleTap(key: 1), bundleID: nil))
        XCTAssertEqual(config.inheritedAction(for: .hold(key: 1), profileID: id), .media(command: .mute))
        XCTAssertNil(config.inheritedAction(for: .hold(key: 1), profileID: config.defaultProfile.id))
    }

    func testAddAndRemoveProfile() {
        var config = K1Config.makeDefault()
        let id = config.addProfile(bundleID: "com.apple.Terminal", name: "Terminal", symbol: "terminal")
        XCTAssertEqual(config.profiles.count, 2)
        // Adding the same bundle id again is idempotent.
        XCTAssertEqual(config.addProfile(bundleID: "com.apple.Terminal", name: "Terminal", symbol: "terminal"), id)
        XCTAssertEqual(config.profiles.count, 2)
        config.removeProfile(id: id)
        XCTAssertEqual(config.profiles.count, 1)
        // The default profile can never be removed.
        config.removeProfile(id: config.defaultProfile.id)
        XCTAssertEqual(config.profiles.count, 1)
        XCTAssertTrue(config.isValid)
    }

    func testK1ConfigRoundTripsThroughJSON() throws {
        var config = K1Config.makeDefault()
        config.profiles[0].keys[0].tap = .openApp(bundleID: "com.apple.Music")
        config.addProfile(bundleID: "com.apple.Terminal", name: "Terminal", symbol: "terminal")
        config.timing = GestureTiming(doubleTapWindow: 0.25, holdThreshold: 0.5)
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(K1Config.self, from: data)
        XCTAssertEqual(decoded, config)
    }

    func testLegacyFlatConfigMigratesToDefaultProfile() throws {
        // Pre-profiles schema: a flat `keys` array with `timing`.
        let legacy = """
        {
          "keys": [
            { "tap": { "openURL": { "urlString": "https://usemagic.io" } } },
            {},
            {}
          ],
          "timing": { "doubleTapWindow": 0.3, "holdThreshold": 0.4 }
        }
        """
        let decoded = try JSONDecoder().decode(K1Config.self, from: Data(legacy.utf8))
        XCTAssertEqual(decoded.profiles.count, 1)
        XCTAssertTrue(decoded.defaultProfile.isDefault)
        XCTAssertEqual(decoded.defaultProfile.keys.count, K1Protocol.keyCount)
        XCTAssertEqual(decoded.defaultProfile.keys[0].tap, .openURL(urlString: "https://usemagic.io"))
        XCTAssertTrue(decoded.isValid)
    }
}
