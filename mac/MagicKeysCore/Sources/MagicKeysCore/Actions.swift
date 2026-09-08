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

public struct K1Config: Codable, Equatable, Sendable {
    public var keys: [KeyBinding]
    public var timing: GestureTiming

    public static func makeDefault() -> K1Config {
        K1Config(keys: Array(repeating: KeyBinding(), count: K1Protocol.keyCount),
                 timing: GestureTiming())
    }

    public func action(for gesture: Gesture) -> ActionConfig? {
        switch gesture {
        case .tap(let key): return keys.indices.contains(key) ? keys[key].tap : nil
        case .doubleTap(let key): return keys.indices.contains(key) ? keys[key].doubleTap : nil
        case .hold(let key): return keys.indices.contains(key) ? keys[key].hold : nil
        }
    }
}
