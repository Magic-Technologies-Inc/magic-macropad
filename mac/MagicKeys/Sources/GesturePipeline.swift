import Foundation
import MagicKeysCore

/// Feeds key events into the GestureEngine and owns the deadline timer.
/// Main-actor bound: HID callbacks already arrive on the main run loop.
@MainActor
final class GesturePipeline {
    var onGesture: ((Gesture) -> Void)?

    private let engine: GestureEngine
    private var timer: Timer?
    private var clock: () -> TimeInterval

    init(timing: GestureTiming, clock: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }) {
        self.engine = GestureEngine(timing: timing)
        self.clock = clock
    }

    func handle(_ event: KeyEvent) {
        emit(engine.handle(event, at: clock()))
        reschedule()
    }

    private func expire() {
        emit(engine.expire(at: clock()))
        reschedule()
    }

    private func emit(_ gestures: [Gesture]) {
        for gesture in gestures { onGesture?(gesture) }
    }

    private func reschedule() {
        timer?.invalidate()
        timer = nil
        guard let deadline = engine.nextDeadline else { return }
        let delay = max(0, deadline - clock())
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.expire() }
        }
    }
}
