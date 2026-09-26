import Foundation
import Combine

/// Loads/saves K1Config as JSON in `directory`/config.json. With no file yet it
/// seeds first-run bindings. A file it can't read is moved aside (see
/// `unreadableConfigBackup`) rather than ever being overwritten.
public final class ConfigStore: ObservableObject {
    @Published public private(set) var config: K1Config
    /// Where an unreadable config.json was moved at load, so the app can tell the user.
    public private(set) var unreadableConfigBackup: URL?

    private let fileURL: URL

    private enum LoadError: Error { case invalidStructure }

    public static func defaultDirectory() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MagicKeys")
    }

    public init(directory: URL = ConfigStore.defaultDirectory()) {
        self.fileURL = directory.appendingPathComponent("config.json")
        guard let data = try? Data(contentsOf: fileURL) else {
            // First run: nothing on disk yet → seed useful first-run bindings.
            self.config = K1Config.makeSeeded()
            return
        }
        do {
            let loaded = try JSONDecoder().decode(K1Config.self, from: data)
            guard loaded.isValid else { throw LoadError.invalidStructure }
            self.config = loaded
        } catch {
            // A typo from hand-editing, or a file written by a newer build: keep
            // it beside the fresh config instead of letting the next save erase it.
            self.config = K1Config.makeSeeded()
            self.unreadableConfigBackup = Self.moveAside(fileURL)
            NSLog("MagicKeys: couldn't read config.json (\(error)); moved it to \(unreadableConfigBackup?.lastPathComponent ?? "nowhere")")
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

    /// Renames `url` to config.unreadable-<timestamp>.json in the same folder.
    private static func moveAside(_ url: URL) -> URL? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let backup = url.deletingLastPathComponent()
            .appendingPathComponent("config.unreadable-\(formatter.string(from: Date())).json")
        do {
            try FileManager.default.moveItem(at: url, to: backup)
            return backup
        } catch {
            NSLog("MagicKeys: couldn't move the unreadable config aside: \(error)")
            return nil
        }
    }
}
