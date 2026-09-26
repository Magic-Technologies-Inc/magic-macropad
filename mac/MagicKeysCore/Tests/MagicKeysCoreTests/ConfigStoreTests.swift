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

    func testMissingFileYieldsSeededConfig() {
        let store = ConfigStore(directory: dir)
        XCTAssertEqual(store.config, K1Config.makeSeeded())
        // Seed is a valid config with at least one binding.
        XCTAssertTrue(store.config.isValid)
        XCTAssertNotNil(store.config.defaultProfile.keys[0].tap)
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
        XCTAssertEqual(store.config, K1Config.makeSeeded())
    }

    func testWrongKeyCountFallsBackToDefault() throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var short = K1Config.makeDefault()
        short.profiles[0].keys.removeLast()  // valid JSON, but only 2 keys
        let data = try JSONEncoder().encode(short)
        try data.write(to: dir.appendingPathComponent("config.json"))
        let store = ConfigStore(directory: dir)
        XCTAssertEqual(store.config, K1Config.makeSeeded())
    }

    func testMissingFileLeavesNoBackup() {
        XCTAssertNil(ConfigStore(directory: dir).unreadableConfigBackup)
    }

    func testUnreadableFileIsMovedAsideNotOverwritten() throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let original = Data(#"{"profiles": [ {"id": "default",}, ]}"#.utf8)  // hand-edit typo
        try original.write(to: dir.appendingPathComponent("config.json"))

        let store = ConfigStore(directory: dir)
        XCTAssertEqual(store.config, K1Config.makeSeeded())
        let backup = try XCTUnwrap(store.unreadableConfigBackup)
        XCTAssertEqual(try Data(contentsOf: backup), original)

        store.update { $0.profiles[0].keys[0].tap = .media(command: .mute) }
        XCTAssertEqual(try Data(contentsOf: backup), original, "saving must never clobber the unreadable original")
        XCTAssertEqual(ConfigStore(directory: dir).config.profiles[0].keys[0].tap, .media(command: .mute))
    }

    func testConfigFromANewerBuildIsKept() throws {
        // An action this build doesn't know makes the whole file undecodable.
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let newer = #"{"profiles":[{"id":"default","name":"macOS","symbol":"desktopcomputer","keys":[{"tap":{"system":{"command":"toggleWifi"}}},{},{}]}],"timing":{"doubleTapWindow":0.3,"holdThreshold":0.4}}"#
        try Data(newer.utf8).write(to: dir.appendingPathComponent("config.json"))

        let store = ConfigStore(directory: dir)
        let backup = try XCTUnwrap(store.unreadableConfigBackup)
        XCTAssertEqual(try String(contentsOf: backup, encoding: .utf8), newer)
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
