import Foundation

/// Turns raw key down/up events into tap / doubleTap / hold gestures.
/// Pure logic: no timers. Callers watch `nextDeadline` and call `expire(at:)`
/// when it passes.
public final class GestureEngine {
    private enum KeyState: Equatable {
        case idle
        case firstDown(since: TimeInterval)
        case awaitingSecondTap(deadline: TimeInterval)
        case secondDown(since: TimeInterval)
        case holdFired
    }

    private static let epsilon: TimeInterval = 1e-10

    private let timing: GestureTiming
    private var states: [KeyState]

    public init(keyCount: Int = K1Protocol.keyCount, timing: GestureTiming = GestureTiming()) {
        self.timing = timing
        self.states = Array(repeating: .idle, count: keyCount)
    }

    /// Feeds one raw key down/up event into the state machine for `event.key`.
    ///
    /// Calling contract: for a given key, `time` must be non-decreasing across
    /// successive calls (events must be delivered in chronological order).
    /// The engine is defensive about events that arrive later than they
    /// "should" have — e.g. a second press that shows up after its double-tap
    /// window already lapsed is resolved as a fresh first press rather than
    /// trusted blindly — but callers should still call `expire(at:)` promptly
    /// once `nextDeadline` passes so pending gestures resolve in a timely way.
    public func handle(_ event: KeyEvent, at time: TimeInterval) -> [Gesture] {
        guard states.indices.contains(event.key) else { return [] }
        let key = event.key
        switch (states[key], event.isDown) {
        case (.idle, true):
            states[key] = .firstDown(since: time)
            return []
        case (.firstDown(let since), false):
            if time - since >= timing.holdThreshold - Self.epsilon {
                states[key] = .idle
                return [.hold(key: key)]
            }
            states[key] = .awaitingSecondTap(deadline: time + timing.doubleTapWindow)
            return []
        case (.awaitingSecondTap(let deadline), true):
            if time >= deadline {
                // The double-tap window already lapsed — a timer that should
                // have called `expire()` first was coalesced or delayed.
                // Resolve the pending first press as a tap and treat this
                // press as the start of a brand-new gesture.
                states[key] = .firstDown(since: time)
                return [.tap(key: key)]
            }
            states[key] = .secondDown(since: time)
            return []
        case (.secondDown(let since), false):
            states[key] = .idle
            if time - since >= timing.holdThreshold - Self.epsilon {
                return [.hold(key: key)]
            }
            return [.doubleTap(key: key)]
        case (.holdFired, false):
            states[key] = .idle
            return []
        default:
            return []  // duplicate down/up in same state — ignore
        }
    }

    /// The earliest time at which some key has a pending gesture that needs
    /// resolving — a hold threshold or a double-tap window deadline. `nil`
    /// when no key has anything pending. Callers should schedule a timer for
    /// this deadline and call `expire(at:)` once it passes; `handle` alone
    /// will not resolve a pending gesture whose deadline has elapsed.
    public var nextDeadline: TimeInterval? {
        states.compactMap { state -> TimeInterval? in
            switch state {
            case .firstDown(let since), .secondDown(let since):
                return since + timing.holdThreshold
            case .awaitingSecondTap(let deadline):
                return deadline
            case .idle, .holdFired:
                return nil
            }
        }.min()
    }

    /// Resolves any pending gesture whose deadline is `<= time`. Safe to call
    /// early or speculatively — before any deadline has passed this is a
    /// no-op and returns an empty array. Callers should still call this once
    /// `nextDeadline` passes; `handle` tolerates late events but does not
    /// substitute for calling `expire` when nothing else prompts it (e.g. a
    /// hold with no further key events after it).
    public func expire(at time: TimeInterval) -> [Gesture] {
        var fired: [Gesture] = []
        for key in 0..<states.count {
            switch states[key] {
            case .firstDown(let since), .secondDown(let since):
                if time - since >= timing.holdThreshold - Self.epsilon {
                    states[key] = .holdFired
                    fired.append(.hold(key: key))
                }
            case .awaitingSecondTap(let deadline):
                if time >= deadline {
                    states[key] = .idle
                    fired.append(.tap(key: key))
                }
            case .idle:
                break
            case .holdFired:
                break
            }
        }
        return fired
    }
}
