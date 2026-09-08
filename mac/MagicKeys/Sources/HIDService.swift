import Foundation
import IOKit.hid
import MagicKeysCore

/// Owns the IOHIDManager session for the K1: hotplug, input reports, GET_INFO.
/// All callbacks are delivered on the main run loop.
final class HIDService {
    var onMessage: ((K1Message) -> Void)?
    var onConnectionChange: ((Bool) -> Void)?

    private var manager: IOHIDManager?
    private var device: IOHIDDevice?
    // Must outlive the registered callback, so it's a stable allocation,
    // not a Swift Array (whose withUnsafe... pointer may not escape).
    private let reportBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: K1Protocol.reportSize)
    private var lastSeq: UInt8?

    deinit { reportBuffer.deallocate() }

    func start() {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        self.manager = manager

        let matching: [String: Any] = [
            kIOHIDVendorIDKey: K1Protocol.vendorID,
            kIOHIDProductIDKey: K1Protocol.productID,
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)

        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, _, _, device in
            let service = Unmanaged<HIDService>.fromOpaque(context!).takeUnretainedValue()
            service.deviceAttached(device)
        }, context)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, _, _, _ in
            let service = Unmanaged<HIDService>.fromOpaque(context!).takeUnretainedValue()
            service.deviceDetached()
        }, context)

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    private func deviceAttached(_ device: IOHIDDevice) {
        self.device = device
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

    private func deviceDetached() {
        device = nil
        onConnectionChange?(false)
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
        guard let device else { return }
        var report = K1Protocol.getInfoReport
        IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0, &report, report.count)
    }
}
