import Foundation
import IOKit.hid
import MagicKeysCore

/// Owns the IOHIDManager session for the pad: hotplug, input reports, GET_INFO.
/// Callbacks are delivered on the main run loop in all common modes, so input
/// keeps flowing while a menu or modal panel is open.
final class HIDService {
    var onMessage: ((K1Message) -> Void)?
    var onConnectionChange: ((Bool) -> Void)?

    private var manager: IOHIDManager?
    // Matching pads that are plugged in; only the active one is listened to.
    private var devices = DeviceRoster<IOHIDDevice>()
    // Must outlive the registered callback, so it's a stable allocation,
    // not a Swift Array (whose withUnsafe... pointer may not escape).
    private let reportBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: K1Protocol.reportSize)
    private var lastSeq: UInt8?

    deinit { reportBuffer.deallocate() }

    func start() {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        self.manager = manager

        // Usage page/usage as well as VID/PID: 1209:0001 is pid.codes' shared
        // test ID, so other hobby boards can wear it too.
        let matching: [String: Any] = [
            kIOHIDVendorIDKey: K1Protocol.vendorID,
            kIOHIDProductIDKey: K1Protocol.productID,
            kIOHIDDeviceUsagePageKey: K1Protocol.usagePage,
            kIOHIDDeviceUsageKey: K1Protocol.usage,
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)

        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, _, _, device in
            let service = Unmanaged<HIDService>.fromOpaque(context!).takeUnretainedValue()
            service.deviceAttached(device)
        }, context)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, _, _, device in
            let service = Unmanaged<HIDService>.fromOpaque(context!).takeUnretainedValue()
            service.deviceRemoved(device)
        }, context)

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    private func deviceAttached(_ device: IOHIDDevice) {
        if devices.attach(device) { listen(to: device) }
    }

    private func deviceRemoved(_ device: IOHIDDevice) {
        switch devices.remove(device) {
        case .activeGone:
            onConnectionChange?(false)
        case .activeReplaced(let next):
            onConnectionChange?(false)  // drops in-flight gestures from the pad that left
            listen(to: next)
        case .standby, nil:
            break
        }
    }

    /// Takes input reports from `device`, the one pad being listened to.
    private func listen(to device: IOHIDDevice) {
        lastSeq = nil
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(
            device, reportBuffer, K1Protocol.reportSize,
            { context, _, _, _, _, report, reportLength in
                let service = Unmanaged<HIDService>.fromOpaque(context!).takeUnretainedValue()
                let bytes = Array(UnsafeBufferPointer(start: report, count: reportLength))
                service.handleReport(bytes)
            }, context)

        onConnectionChange?(true)
        sendGetInfo()
    }

    private func handleReport(_ bytes: [UInt8]) {
        guard let message = K1Protocol.parse(bytes) else {
            NSLog("MagicKeys: dropped malformed report \(bytes)")
            return
        }
        if case .keyEvent(let event) = message {
            if let last = lastSeq, event.seq != last &+ 1 {
                NSLog("MagicKeys: sequence gap \(last) -> \(event.seq)")
            }
            lastSeq = event.seq
        }
        onMessage?(message)
    }

    func sendGetInfo() {
        guard let device = devices.active else { return }
        var report = K1Protocol.getInfoReport
        IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0, &report, report.count)
    }
}
