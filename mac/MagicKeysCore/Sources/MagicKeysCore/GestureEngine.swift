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

    private let timing: GestureTiming
    private var states: [KeyState]

    public init(keyCount: Int = K1Protocol.keyCount, timing: GestureTiming = GestureTiming()) {
        self.timing = timing
        self.states = Array(repeating: .idle, count: keyCount)
    }

    public func handle(_ event: KeyEvent, at time: TimeInterval) -> [Gesture] {
        guard states.indices.contains(event.key) else { return [] }
        let key = event.key
        let epsilon = 1e-10
        switch (states[key], event.isDown) {
        case (.idle, true):
            states[key] = .firstDown(since: time)
            return []
        case (.firstDown(let since), false):
            if time - since >= timing.holdThreshold - epsilon {
                states[key] = .idle
                return [.hold(key: key)]
            }
            states[key] = .awaitingSecondTap(deadline: time + timing.doubleTapWindow)
            return []
        case (.awaitingSecondTap, true):
            states[key] = .secondDown(since: time)
            return []
        case (.secondDown(let since), false):
            states[key] = .idle
            if time - since >= timing.holdThreshold - epsilon {
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

    public func expire(at time: TimeInterval) -> [Gesture] {
        var fired: [Gesture] = []
        let epsilon = 1e-10
        for key in 0..<states.count {
            switch states[key] {
            case .firstDown(let since):
                if time - since >= timing.holdThreshold - epsilon {
                    states[key] = .holdFired
                    fired.append(.hold(key: key))
                }
            case .secondDown(let since):
                if time - since >= timing.holdThreshold - epsilon {
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
