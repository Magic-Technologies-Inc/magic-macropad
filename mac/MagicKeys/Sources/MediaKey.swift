import AppKit

/// Posts media keys as system-defined NSEvents (the same mechanism the
/// keyboard's media keys use). No special permission required.
enum MediaKey: UInt32 {
    case playPause = 16     // NX_KEYTYPE_PLAY
    case nextTrack = 17     // NX_KEYTYPE_NEXT
    case previousTrack = 18 // NX_KEYTYPE_PREVIOUS
    case volumeUp = 0       // NX_KEYTYPE_SOUND_UP
    case volumeDown = 1     // NX_KEYTYPE_SOUND_DOWN
    case mute = 7           // NX_KEYTYPE_MUTE

    func post() {
        postPhase(down: true)
        postPhase(down: false)
    }

    private func postPhase(down: Bool) {
        let flags: NSEvent.ModifierFlags = down ? .init(rawValue: 0xA00) : .init(rawValue: 0xB00)
        let data1 = Int((rawValue << 16) | (down ? 0x0A00 : 0x0B00))
        guard let event = NSEvent.otherEvent(
            with: .systemDefined, location: .zero, modifierFlags: flags,
            timestamp: 0, windowNumber: 0, context: nil,
            subtype: 8, data1: data1, data2: -1) else { return }
        event.cgEvent?.post(tap: .cghidEventTap)
    }
}
