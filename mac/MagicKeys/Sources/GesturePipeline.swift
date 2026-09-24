import Foundation
import MagicKeysCore

/// Feeds key events into the GestureEngine and owns the deadline timer.
/// Main-actor bound: HID callbacks already arrive on the main run loop.
@MainActor
final class GesturePipeline {
    var onGesture: ((Gesture) -> Void)?
    /// Fired once when all keys are held down together (the easter-egg chord).
    var onChord: (() -> Void)?

    private let engine: GestureEngine
    private var timer: Timer?
    private var clock: () -> TimeInterval

    // Raw down-key tracking for chord detection, independent of gesture logic.
    private var downKeys = Set<Int>()
    private var chordActive = false

    init(timing: GestureTiming, clock: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }) {
        self.engine = GestureEngine(timing: timing)
        self.clock = clock
    }

    func handle(_ event: KeyEvent) {
        if event.isDown { downKeys.insert(event.key) } else { downKeys.remove(event.key) }

        // All keys down at once → fire the chord, and swallow the per-key
        // gestures for this whole press (drop pending ones so nothing fires on
        // release) until every key is back up.
        if downKeys.count == K1Protocol.keyCount && !chordActive {
            chordActive = true
            engine.reset()
            onChord?()
            reschedule()
            return
        }
        if chordActive {
            if downKeys.isEmpty { chordActive = false }
            reschedule()
            return
        }

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
