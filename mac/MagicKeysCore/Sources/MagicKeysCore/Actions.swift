import Foundation

public enum Gesture: Equatable, Sendable {
    case tap(key: Int)
    case doubleTap(key: Int)
    case hold(key: Int)
}

public enum KeyModifier: String, Codable, CaseIterable, Sendable {
    case command, shift, option, control
}

public enum MediaCommand: String, Codable, CaseIterable, Sendable {
    case playPause, volumeUp, volumeDown, mute
}

/// Persisted to disk as JSON via synthesized Codable: case names and associated-value
/// labels ARE the wire format. Renaming any of them breaks existing config files —
/// add explicit CodingKeys before renaming.
public enum ActionConfig: Codable, Equatable, Sendable {
    case openApp(bundleID: String)
    case openURL(urlString: String)
    case keystroke(keyCode: UInt16, modifiers: [KeyModifier])
    case media(command: MediaCommand)
    case shellScript(script: String)
}

public struct KeyBinding: Codable, Equatable, Sendable {
    public var tap: ActionConfig?
    public var doubleTap: ActionConfig?
    public var hold: ActionConfig?

    public init(tap: ActionConfig? = nil, doubleTap: ActionConfig? = nil, hold: ActionConfig? = nil) {
        self.tap = tap
        self.doubleTap = doubleTap
        self.hold = hold
    }
}

public struct GestureTiming: Codable, Equatable, Sendable {
    public var doubleTapWindow: TimeInterval
    public var holdThreshold: TimeInterval

    public init(doubleTapWindow: TimeInterval = 0.3, holdThreshold: TimeInterval = 0.4) {
        self.doubleTapWindow = doubleTapWindow
        self.holdThreshold = holdThreshold
    }
}

/// A set of key bindings scoped to one application (or the global fallback).
/// The profile whose `bundleID` matches the front app wins at gesture time;
/// the profile with `bundleID == nil` is the default used when nothing matches.
public struct AppProfile: Codable, Equatable, Sendable, Identifiable {
    public var id: String        // stable; "default" for the global fallback
    public var name: String      // display name for the chip ("macOS", "Terminal")
    public var bundleID: String? // nil => global/default profile
    public var symbol: String    // SF Symbol name for the chip
    public var keys: [KeyBinding]

    public init(id: String, name: String, bundleID: String?, symbol: String, keys: [KeyBinding]) {
        self.id = id
        self.name = name
        self.bundleID = bundleID
        self.symbol = symbol
        self.keys = keys
    }

    public var isDefault: Bool { bundleID == nil }

    public static func makeDefaultProfile() -> AppProfile {
        AppProfile(id: "default", name: "macOS", bundleID: nil, symbol: "desktopcomputer",
                   keys: Array(repeating: KeyBinding(), count: K1Protocol.keyCount))
    }

    public func action(for gesture: Gesture) -> ActionConfig? {
        switch gesture {
        case .tap(let key): return keys.indices.contains(key) ? keys[key].tap : nil
        case .doubleTap(let key): return keys.indices.contains(key) ? keys[key].doubleTap : nil
        case .hold(let key): return keys.indices.contains(key) ? keys[key].hold : nil
        }
    }
}

public struct K1Config: Codable, Equatable, Sendable {
    public var profiles: [AppProfile]
    public var timing: GestureTiming

    enum CodingKeys: String, CodingKey { case profiles, timing, keys }

    public init(profiles: [AppProfile], timing: GestureTiming) {
        self.profiles = profiles
        self.timing = timing
    }

    /// Decodes the current schema, and migrates the legacy flat `keys` array
    /// (pre-profiles) into the default profile.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.timing = try c.decodeIfPresent(GestureTiming.self, forKey: .timing) ?? GestureTiming()
        if let profiles = try c.decodeIfPresent([AppProfile].self, forKey: .profiles), !profiles.isEmpty {
            self.profiles = profiles
        } else if let keys = try c.decodeIfPresent([KeyBinding].self, forKey: .keys) {
            var defaultProfile = AppProfile.makeDefaultProfile()
            defaultProfile.keys = keys
            self.profiles = [defaultProfile]
        } else {
            self.profiles = [AppProfile.makeDefaultProfile()]
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(profiles, forKey: .profiles)
        try c.encode(timing, forKey: .timing)
    }

    public static func makeDefault() -> K1Config {
        K1Config(profiles: [.makeDefaultProfile()], timing: GestureTiming())
    }

    /// The global fallback profile (always present as an invariant).
    public var defaultProfile: AppProfile {
        profiles.first(where: { $0.isDefault }) ?? profiles[0]
    }

    /// The profile that applies for a given front-app bundle id.
    public func profile(forBundleID bundleID: String?) -> AppProfile {
        if let bundleID, let match = profiles.first(where: { $0.bundleID == bundleID }) {
            return match
        }
        return defaultProfile
    }

    /// Runtime lookup: resolve a gesture to an action using the front app's
    /// profile, falling back to the default profile when the app profile leaves
    /// that gesture unbound — so a key still does its default thing.
    public func action(for gesture: Gesture, bundleID: String?) -> ActionConfig? {
        let appProfile = profile(forBundleID: bundleID)
        if let action = appProfile.action(for: gesture) { return action }
        return appProfile.isDefault ? nil : defaultProfile.action(for: gesture)
    }

    /// The default-profile action a gesture would inherit (for showing an
    /// "inherited from macOS" hint in an app profile). Nil for the default profile.
    public func inheritedAction(for gesture: Gesture, profileID: String) -> ActionConfig? {
        guard let profile = profiles.first(where: { $0.id == profileID }), !profile.isDefault else { return nil }
        return defaultProfile.action(for: gesture)
    }

    /// Structural invariants ConfigStore requires before accepting a loaded file.
    public var isValid: Bool {
        !profiles.isEmpty
            && profiles.contains(where: { $0.isDefault })
            && profiles.allSatisfy { $0.keys.count == K1Protocol.keyCount }
    }

    // MARK: Profile management (used by the config UI)

    /// Adds an app profile if one for `bundleID` doesn't already exist; returns its id.
    @discardableResult
    public mutating func addProfile(bundleID: String, name: String, symbol: String) -> String {
        if let existing = profiles.first(where: { $0.bundleID == bundleID }) { return existing.id }
        let profile = AppProfile(id: bundleID, name: name, bundleID: bundleID, symbol: symbol,
                                 keys: Array(repeating: KeyBinding(), count: K1Protocol.keyCount))
        profiles.append(profile)
        return profile.id
    }

    /// Removes a profile by id. The default profile can never be removed.
    public mutating func removeProfile(id: String) {
        profiles.removeAll { $0.id == id && !$0.isDefault }
    }

    public func profileIndex(id: String) -> Int? {
        profiles.firstIndex(where: { $0.id == id })
    }
}
