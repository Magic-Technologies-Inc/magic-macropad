import XCTest
@testable import MagicKeysCore

final class ConfigStoreTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MagicKeysTests-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    func testMissingFileYieldsDefaultConfig() {
        let store = ConfigStore(directory: dir)
        XCTAssertEqual(store.config, K1Config.makeDefault())
    }

    func testUpdatePersistsAndReloads() {
        let store = ConfigStore(directory: dir)
        store.update { $0.profiles[0].keys[0].tap = .openURL(urlString: "https://usemagic.io") }

        let reloaded = ConfigStore(directory: dir)
        XCTAssertEqual(reloaded.config.profiles[0].keys[0].tap, .openURL(urlString: "https://usemagic.io"))
    }

    func testAddedProfilePersistsAndReloads() {
        let store = ConfigStore(directory: dir)
        store.update { $0.addProfile(bundleID: "com.apple.Terminal", name: "Terminal", symbol: "terminal") }

        let reloaded = ConfigStore(directory: dir)
        XCTAssertEqual(reloaded.config.profiles.count, 2)
        XCTAssertNotNil(reloaded.config.profiles.first { $0.bundleID == "com.apple.Terminal" })
    }

    func testCorruptFileFallsBackToDefault() throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: dir.appendingPathComponent("config.json"))
        let store = ConfigStore(directory: dir)
        XCTAssertEqual(store.config, K1Config.makeDefault())
    }

    func testWrongKeyCountFallsBackToDefault() throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var short = K1Config.makeDefault()
        short.profiles[0].keys.removeLast()  // valid JSON, but only 2 keys
        let data = try JSONEncoder().encode(short)
        try data.write(to: dir.appendingPathComponent("config.json"))
        let store = ConfigStore(directory: dir)
        XCTAssertEqual(store.config, K1Config.makeDefault())
    }

    func testLegacyFileMigratesOnLoad() throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let legacy = """
        {"keys":[{"tap":{"media":{"command":"mute"}}},{},{}],
         "timing":{"doubleTapWindow":0.3,"holdThreshold":0.4}}
        """
        try Data(legacy.utf8).write(to: dir.appendingPathComponent("config.json"))
        let store = ConfigStore(directory: dir)
        XCTAssertEqual(store.config.profiles.count, 1)
        XCTAssertEqual(store.config.defaultProfile.keys[0].tap, .media(command: .mute))
    }
}
