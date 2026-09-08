import Foundation
import Combine

/// Loads/saves K1Config as JSON in `directory`/config.json.
/// Falls back to the default config on missing or corrupt files.
public final class ConfigStore: ObservableObject {
    @Published public private(set) var config: K1Config

    private let fileURL: URL

    public static func defaultDirectory() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MagicKeys")
    }

    public init(directory: URL = ConfigStore.defaultDirectory()) {
        self.fileURL = directory.appendingPathComponent("config.json")
        if let data = try? Data(contentsOf: fileURL),
           let loaded = try? JSONDecoder().decode(K1Config.self, from: data),
           loaded.keys.count == K1Protocol.keyCount {
            self.config = loaded
        } else {
            self.config = K1Config.makeDefault()
        }
    }

    public func update(_ mutate: (inout K1Config) -> Void) {
        var updated = config
        mutate(&updated)
        config = updated
        save()
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(config).write(to: fileURL, options: .atomic)
        } catch {
            // Persisting config is best-effort; the in-memory config stays authoritative.
            NSLog("MagicKeys: failed to save config: \(error)")
        }
    }
}
