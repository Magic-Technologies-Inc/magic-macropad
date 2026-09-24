import Foundation

/// Turns raw key down/up events into tap / doubleTap / tripleTap / hold gestures.
/// Pure logic: no timers. Callers watch `nextDeadline` and call `expire(at:)`
/// when it passes.
public final class GestureEngine {
    private static let maxTaps = 3

    private enum KeyState: Equatable {
        case idle
        case down(since: TimeInterval, count: Int)     // key pressed; the count-th press
        case awaiting(deadline: TimeInterval, count: Int)  // released after `count` taps
        case holdFired
    }

    private static let epsilon: TimeInterval = 1e-10

    private let timing: GestureTiming
    private var states: [KeyState]

    public init(keyCount: Int = K1Protocol.keyCount, timing: GestureTiming = GestureTiming()) {
        self.timing = timing
        self.states = Array(repeating: .idle, count: keyCount)
    }

    /// Clears all per-key state back to idle. Used when a higher layer (e.g. a
    /// multi-key chord) takes over and the in-flight per-key gestures should be
    /// dropped rather than firing on release.
    public func reset() {
        for i in states.indices { states[i] = .idle }
    }

    private static func tapGesture(count: Int, key: Int) -> Gesture {
        switch count {
        case 1: return .tap(key: key)
        case 2: return .doubleTap(key: key)
        default: return .tripleTap(key: key)
        }
    }

    /// Feeds one raw key down/up event into the state machine for `event.key`.
    ///
    /// Calling contract: for a given key, `time` must be non-decreasing across
    /// successive calls (events must be delivered in chronological order).
    /// The engine is defensive about events that arrive later than they
    /// "should" have — e.g. a next press that shows up after its multi-tap
    /// window already lapsed is resolved as a fresh first press rather than
    /// trusted blindly — but callers should still call `expire(at:)` promptly
    /// once `nextDeadline` passes so pending gestures resolve in a timely way.
    public func handle(_ event: KeyEvent, at time: TimeInterval) -> [Gesture] {
        guard states.indices.contains(event.key) else { return [] }
        let key = event.key
        switch (states[key], event.isDown) {
        case (.idle, true):
            states[key] = .down(since: time, count: 1)
            return []

        case (.down(let since, let count), false):
            if time - since >= timing.holdThreshold - Self.epsilon {
                states[key] = .idle
                return [.hold(key: key)]
            }
            if count >= Self.maxTaps {
                // Max taps reached — fire immediately, no need to wait.
                states[key] = .idle
                return [Self.tapGesture(count: count, key: key)]
            }
            states[key] = .awaiting(deadline: time + timing.doubleTapWindow, count: count)
            return []

        case (.awaiting(let deadline, let count), true):
            if time >= deadline {
                // The multi-tap window already lapsed — a timer that should have
                // called `expire()` first was coalesced or delayed. Resolve the
                // pending gesture and treat this press as a brand-new first press.
                states[key] = .down(since: time, count: 1)
                return [Self.tapGesture(count: count, key: key)]
            }
            states[key] = .down(since: time, count: count + 1)
            return []

        case (.holdFired, false):
            states[key] = .idle
            return []

        default:
            return []  // duplicate down/up in same state — ignore
        }
    }

    /// The earliest time at which some key has a pending gesture that needs
    /// resolving — a hold threshold or a multi-tap window deadline. `nil` when
    /// no key has anything pending.
    public var nextDeadline: TimeInterval? {
        states.compactMap { state -> TimeInterval? in
            switch state {
            case .down(let since, _):
                return since + timing.holdThreshold
            case .awaiting(let deadline, _):
                return deadline
            case .idle, .holdFired:
                return nil
            }
        }.min()
    }

    /// Resolves any pending gesture whose deadline is `<= time`. Safe to call
    /// early or speculatively — before any deadline has passed this is a no-op.
    public func expire(at time: TimeInterval) -> [Gesture] {
        var fired: [Gesture] = []
        for key in 0..<states.count {
            switch states[key] {
            case .down(let since, _):
                if time - since >= timing.holdThreshold - Self.epsilon {
                    states[key] = .holdFired
                    fired.append(.hold(key: key))
                }
            case .awaiting(let deadline, let count):
                if time >= deadline {
                    states[key] = .idle
                    fired.append(Self.tapGesture(count: count, key: key))
                }
            case .idle, .holdFired:
                break
            }
        }
        return fired
    }
}
