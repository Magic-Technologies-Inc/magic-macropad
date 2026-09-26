/// Tracks the matching devices that are plugged in and picks one to listen to.
/// The app drives a single pad; extras wait on standby and take over if the
/// active one is unplugged, so unplugging a spare never disconnects the pad in use.
public struct DeviceRoster<Device: Equatable> {
    public private(set) var active: Device?
    private var standby: [Device] = []

    public init() {}

    public enum Removal: Equatable {
        case standby                      // a spare left; nothing changes
        case activeReplaced(by: Device)   // the active pad left and a spare took over
        case activeGone                   // the active pad left and none remain
    }

    /// Adds a device; returns true if it became the active one.
    @discardableResult
    public mutating func attach(_ device: Device) -> Bool {
        if active == nil {
            active = device
            return true
        }
        if active != device && !standby.contains(device) { standby.append(device) }
        return false
    }

    /// Removes a device; nil if it wasn't being tracked.
    public mutating func remove(_ device: Device) -> Removal? {
        if device == active {
            guard !standby.isEmpty else {
                active = nil
                return .activeGone
            }
            let next = standby.removeFirst()
            active = next
            return .activeReplaced(by: next)
        }
        guard let index = standby.firstIndex(of: device) else { return nil }
        standby.remove(at: index)
        return .standby
    }
}
