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
        store.update { $0.keys[0].tap = .openURL(urlString: "https://usemagic.io") }

        let reloaded = ConfigStore(directory: dir)
        XCTAssertEqual(reloaded.config.keys[0].tap, .openURL(urlString: "https://usemagic.io"))
    }

    func testCorruptFileFallsBackToDefault() throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: dir.appendingPathComponent("config.json"))
        let store = ConfigStore(directory: dir)
        XCTAssertEqual(store.config, K1Config.makeDefault())
    }
}
