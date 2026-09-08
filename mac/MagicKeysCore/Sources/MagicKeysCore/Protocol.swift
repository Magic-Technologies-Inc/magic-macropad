import Foundation

public struct KeyEvent: Equatable, Sendable {
    public let key: Int
    public let isDown: Bool
    public let seq: UInt8

    public init(key: Int, isDown: Bool, seq: UInt8) {
        self.key = key
        self.isDown = isDown
        self.seq = seq
    }
}

public struct DeviceInfo: Equatable, Sendable {
    public let firmwareMajor: Int
    public let firmwareMinor: Int
    public let keyCount: Int

    public init(firmwareMajor: Int, firmwareMinor: Int, keyCount: Int) {
        self.firmwareMajor = firmwareMajor
        self.firmwareMinor = firmwareMinor
        self.keyCount = keyCount
    }
}

public enum K1Message: Equatable, Sendable {
    case keyEvent(KeyEvent)
    case info(DeviceInfo)
}

/// Mirrors firmware/main/protocol.h — keep in lockstep.
public enum K1Protocol {
    public static let vendorID = 0x1209
    public static let productID = 0x0001
    public static let usagePage = 0xFF60
    public static let reportSize = 8
    public static let keyCount = 3

    static let msgKeyEvent: UInt8 = 0x01
    static let msgInfo: UInt8 = 0x02
    static let msgGetInfo: UInt8 = 0x10

    public static var getInfoReport: [UInt8] {
        [msgGetInfo, 0, 0, 0, 0, 0, 0, 0]
    }

    public static func parse(_ report: [UInt8]) -> K1Message? {
        guard report.count == reportSize else { return nil }
        switch report[0] {
        case msgKeyEvent:
            let key = Int(report[1])
            guard key < keyCount, report[2] <= 1 else { return nil }
            return .keyEvent(KeyEvent(key: key, isDown: report[2] == 1, seq: report[3]))
        case msgInfo:
            return .info(DeviceInfo(firmwareMajor: Int(report[4]),
                                    firmwareMinor: Int(report[5]),
                                    keyCount: Int(report[6])))
        default:
            return nil
        }
    }
}
