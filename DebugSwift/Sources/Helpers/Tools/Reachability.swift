// swiftlint:disable all

/*
 Copyright (c) 2014, Ashley Mills
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation
import SystemConfiguration
import CoreTelephony

enum ReachabilityError: Error {
    case failedToCreateWithAddress(sockaddr, Int32)
    case failedToCreateWithHostname(String, Int32)
    case unableToSetCallback(Int32)
    case unableToSetDispatchQueue(Int32)
    case unableToGetFlags(Int32)
}

@available(*, unavailable, renamed: "Notification.Name.reachabilityChanged")
let ReachabilityChangedNotification = NSNotification.Name("ReachabilityChangedNotification")

extension Notification.Name {
    static let reachabilityChanged = Notification.Name("reachabilityChanged")
}

class Reachability {

    typealias NetworkReachable = (Reachability) -> Void
    typealias NetworkUnreachable = (Reachability) -> Void

    @available(*, unavailable, renamed: "Connection")
    enum NetworkStatus: CustomStringConvertible {
        case notReachable, reachableViaWiFi, reachableViaWWAN
        var description: String {
            switch self {
            case .reachableViaWWAN: return "cellular".localized()
            case .reachableViaWiFi: return "wifi".localized()
            case .notReachable: return "noConnection".localized()
            }
        }
    }

    enum Connection: CustomStringConvertible {
        case none
        case unavailable, wifi, cellular
        var description: String {
            switch self {
            case .cellular: return "cellular".localized()
            case .wifi: return "wifi".localized()
            case .unavailable: return "noConnection".localized()
            case .none: return "unavailable".localized()
            }
        }
    }

    var whenReachable: NetworkReachable?
    var whenUnreachable: NetworkUnreachable?

    /// Set to `false` to force Reachability.connection to .none when on cellular connection (default value `true`)
    var allowsCellularConnection: Bool

    // The notification center on which "reachability changed" events are being posted
    var notificationCenter = NotificationCenter.default

    var connection: Connection {
        if flags == nil {
            try? setReachabilityFlags()
        }

        switch flags?.connection {
        case .unavailable, nil:
            return .unavailable
        case .cellular:
            return allowsCellularConnection ? .cellular : .unavailable
        case .wifi:
            return .wifi
        case .some(.none):
            return .unavailable
        }
    }

    private var isRunningOnDevice: Bool = {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }()

    private(set) var notifierRunning = false
    private let reachabilityRef: SCNetworkReachability
    private let reachabilitySerialQueue: DispatchQueue
    private let notificationQueue: DispatchQueue?
    private(set) var flags: SCNetworkReachabilityFlags? {
        didSet {
            guard flags != oldValue else { return }
            notifyReachabilityChanged()
        }
    }

    required init(
        reachabilityRef: SCNetworkReachability,
        queueQoS: DispatchQoS = .default,
        targetQueue: DispatchQueue? = nil,
        notificationQueue: DispatchQueue? = .main
    ) {
        self.allowsCellularConnection = true
        self.reachabilityRef = reachabilityRef
        self.reachabilitySerialQueue = DispatchQueue(
            label: "uk.co.ashleymills.reachability",
            qos: queueQoS,
            target: targetQueue
        )
        self.notificationQueue = notificationQueue
    }

    convenience init(
        hostname: String,
        queueQoS: DispatchQoS = .default,
        targetQueue: DispatchQueue? = nil,
        notificationQueue: DispatchQueue? = .main
    ) throws {
        guard let ref = SCNetworkReachabilityCreateWithName(nil, hostname) else {
            throw ReachabilityError.failedToCreateWithHostname(hostname, SCError())
        }
        self.init(
            reachabilityRef: ref,
            queueQoS: queueQoS,
            targetQueue: targetQueue,
            notificationQueue: notificationQueue
        )
    }

    convenience init(
        queueQoS: DispatchQoS = .default,
        targetQueue: DispatchQueue? = nil,
        notificationQueue: DispatchQueue? = .main
    ) throws {
        var zeroAddress = sockaddr()
        zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zeroAddress.sa_family = sa_family_t(AF_INET)

        guard let ref = SCNetworkReachabilityCreateWithAddress(nil, &zeroAddress) else {
            throw ReachabilityError.failedToCreateWithAddress(zeroAddress, SCError())
        }

        self.init(
            reachabilityRef: ref,
            queueQoS: queueQoS,
            targetQueue: targetQueue,
            notificationQueue: notificationQueue
        )
    }

    deinit {
        stopNotifier()
    }
}

extension Reachability {

    // MARK: - *** Notifier methods ***

    func startNotifier() throws {
        guard !notifierRunning else { return }

        let callback: SCNetworkReachabilityCallBack = { _, flags, info in
            guard let info = info else { return }

            // `weakifiedReachability` is guaranteed to exist by virtue of our
            // retain/release callbacks which we provided to the `SCNetworkReachabilityContext`.
            let weakifiedReachability = Unmanaged<ReachabilityWeakifier>.fromOpaque(info).takeUnretainedValue()

            // The weak `reachability` _may_ no longer exist if the `Reachability`
            // object has since been deallocated but a callback was already in flight.
            weakifiedReachability.reachability?.flags = flags
        }

        let weakifiedReachability = ReachabilityWeakifier(reachability: self)
        let opaqueWeakifiedReachability = Unmanaged<ReachabilityWeakifier>
            .passUnretained(weakifiedReachability)
            .toOpaque()

        var context = SCNetworkReachabilityContext(
            version: 0,
            info: UnsafeMutableRawPointer(opaqueWeakifiedReachability),
            retain: { (info: UnsafeRawPointer) -> UnsafeRawPointer in
                let unmanagedWeakifiedReachability = Unmanaged<ReachabilityWeakifier>.fromOpaque(info)
                _ = unmanagedWeakifiedReachability.retain()
                return UnsafeRawPointer(unmanagedWeakifiedReachability.toOpaque())
            },
            release: { (info: UnsafeRawPointer) in
                let unmanagedWeakifiedReachability = Unmanaged<ReachabilityWeakifier>.fromOpaque(info)
                unmanagedWeakifiedReachability.release()
            },
            copyDescription: { (info: UnsafeRawPointer) -> Unmanaged<CFString> in
                let unmanagedWeakifiedReachability = Unmanaged<ReachabilityWeakifier>.fromOpaque(info)
                let weakifiedReachability = unmanagedWeakifiedReachability.takeUnretainedValue()
                let description = weakifiedReachability.reachability?.description ?? "nil"
                return Unmanaged.passRetained(description as CFString)
            }
        )

        if !SCNetworkReachabilitySetCallback(reachabilityRef, callback, &context) {
            stopNotifier()
            throw ReachabilityError.unableToSetCallback(SCError())
        }

        if !SCNetworkReachabilitySetDispatchQueue(reachabilityRef, reachabilitySerialQueue) {
            stopNotifier()
            throw ReachabilityError.unableToSetDispatchQueue(SCError())
        }

        // Perform an initial check
        try setReachabilityFlags()

        notifierRunning = true
    }

    func stopNotifier() {
        defer { notifierRunning = false }

        SCNetworkReachabilitySetCallback(reachabilityRef, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachabilityRef, nil)
    }

    // MARK: - *** Connection test methods ***

    var description: String { flags?.description ?? "unavailable flags" }
}

extension Reachability {

    private func setReachabilityFlags() throws {
        try reachabilitySerialQueue.sync { [weak self] in
            guard let self = self else { return }
            var flags = SCNetworkReachabilityFlags()
            if !SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags) {
                self.stopNotifier()
                throw ReachabilityError.unableToGetFlags(SCError())
            }

            self.flags = flags
        }
    }

    private func notifyReachabilityChanged() {
        let notify = { [weak self] in
            guard let self = self else { return }
            if self.connection != .unavailable {
                self.whenReachable?(self)
            } else {
                self.whenUnreachable?(self)
            }
            self.notificationCenter.post(name: .reachabilityChanged, object: self)
        }

        // notify on the configured `notificationQueue`, or the caller's (i.e. `reachabilitySerialQueue`)
        notificationQueue?.async(execute: notify) ?? notify()
    }
}

extension SCNetworkReachabilityFlags {

    typealias Connection = Reachability.Connection

    var connection: Connection {
        guard isReachableFlagSet else { return .unavailable }

        // If we're reachable, but not on an iOS device (i.e. simulator), we must be on WiFi
        #if targetEnvironment(simulator)
        return .wifi
        #else
        var connection = Connection.unavailable

        if !isConnectionRequiredFlagSet {
            connection = .wifi
        }

        if isConnectionOnTrafficOrDemandFlagSet {
            if !isInterventionRequiredFlagSet {
                connection = .wifi
            }
        }

        if isOnWWANFlagSet {
            connection = .cellular
        }

        return connection
        #endif
    }

    var isOnWWANFlagSet: Bool {
        #if os(iOS)
        return contains(.isWWAN)
        #else
        return false
        #endif
    }

    var isReachableFlagSet: Bool { contains(.reachable) }
    var isConnectionRequiredFlagSet: Bool { contains(.connectionRequired) }
    var isInterventionRequiredFlagSet: Bool { contains(.interventionRequired) }
    var isConnectionOnTrafficFlagSet: Bool { contains(.connectionOnTraffic) }
    var isConnectionOnDemandFlagSet: Bool { contains(.connectionOnDemand) }
    var isTransientConnectionFlagSet: Bool { contains(.transientConnection) }
    var isLocalAddressFlagSet: Bool { contains(.isLocalAddress) }
    var isDirectFlagSet: Bool { contains(.isDirect) }

    var isConnectionOnTrafficOrDemandFlagSet: Bool {
        !intersection([.connectionOnTraffic, .connectionOnDemand]).isEmpty
    }

    var isConnectionRequiredAndTransientFlagSet: Bool {
        intersection([.connectionRequired, .transientConnection]) == [.connectionRequired, .transientConnection]
    }

    var description: String {
        let W = isOnWWANFlagSet ? "W" : "-"
        let R = isReachableFlagSet ? "R" : "-"
        let c = isConnectionRequiredFlagSet ? "c" : "-"
        let t = isTransientConnectionFlagSet ? "t" : "-"
        let i = isInterventionRequiredFlagSet ? "i" : "-"
        let C = isConnectionOnTrafficFlagSet ? "C" : "-"
        let D = isConnectionOnDemandFlagSet ? "D" : "-"
        let l = isLocalAddressFlagSet ? "l" : "-"
        let d = isDirectFlagSet ? "d" : "-"

        return "\(W)\(R) \(c)\(t)\(i)\(C)\(D)\(l)\(d)"
    }
}

/**
 `ReachabilityWeakifier` weakly wraps the `Reachability` class
 in order to break retain cycles when interacting with CoreFoundation.

 CoreFoundation callbacks expect a pair of retain/release whenever an
 opaque `info` parameter is provided. These callbacks exist to guard
 against memory management race conditions when invoking the callbacks.

 #### Race Condition

 If we passed `SCNetworkReachabilitySetCallback` a direct reference to our
 `Reachability` class without also providing corresponding retain/release
 callbacks, then a race condition can lead to crashes when:
 - `Reachability` is deallocated on thread X
 - A `SCNetworkReachability` callback(s) is already in flight on thread Y

 #### Retain Cycle

 If we pass `Reachability` to CoreFoundtion while also providing retain/
 release callbacks, we would create a retain cycle once CoreFoundation
 retains our `Reachability` class. This fixes the crashes and his how
 CoreFoundation expects the API to be used, but doesn't play nicely with
 Swift/ARC. This cycle would only be broken after manually calling
 `stopNotifier()` — `deinit` would never be called.

 #### ReachabilityWeakifier

 By providing both retain/release callbacks and wrapping `Reachability` in
 a weak wrapper, we:
 - interact correctly with CoreFoundation, thereby avoiding a crash.
 See "Memory Management Programming Guide for Core Foundation".
 - don't alter the API of `Reachability.swift` in any way
 - still allow for automatic stopping of the notifier on `deinit`.
 */
private class ReachabilityWeakifier {
    weak var reachability: Reachability?
    init(reachability: Reachability) {
        self.reachability = reachability
    }
}

enum NetworkType: Int, CaseIterable {
    case unknown
    case noConnection
    case wifi
    case cellular
    case ethernet
    case wwan2g
    case wwan3g
    case wwan4g
    case wwan5g
    case unknownTechnology

    var description: String {
        switch self {
        case .noConnection:
            return "noConnection".localized()
        case .wifi:
            return "wifi".localized()
        case .cellular:
            return "cellular".localized()
        case .ethernet:
            return "Ethernet"
        case .wwan2g:
            return "2G"
        case .wwan3g:
            return "3G"
        case .wwan4g:
            return "4G"
        case .wwan5g:
            return "5G"
        case .unknown, .unknownTechnology:
            return "unavailable".localized()
        }
    }

    var icon: String {
        switch self {
        case .unknown, .unknownTechnology:
            return "mdi:help-circle"
        case .noConnection:
            return "mdi:sim-off"
        case .wifi:
            return "mdi:wifi"
        case .cellular:
            return "mdi:signal"
        case .ethernet:
            return "mdi:ethernet"
        case .wwan2g:
            return "mdi:signal-2g"
        case .wwan3g:
            return "mdi:signal-3g"
        case .wwan4g:
            return "mdi:signal-4g"
        case .wwan5g:
            return "mdi:signal-5g"
        }
    }

    #if os(iOS) && !targetEnvironment(macCatalyst)
    init(_ radioTech: String) {
        if #available(iOS 14.1, *) {
            if [CTRadioAccessTechnologyNR, CTRadioAccessTechnologyNRNSA].contains(radioTech) {
                // although these are declared available in 14.0, they will crash on use before 14.1
                self = .wwan5g
                return
            }
        }

        switch radioTech {
        case CTRadioAccessTechnologyGPRS,
             CTRadioAccessTechnologyEdge,
             CTRadioAccessTechnologyCDMA1x:
            self = .wwan2g
        case CTRadioAccessTechnologyWCDMA,
             CTRadioAccessTechnologyHSDPA,
             CTRadioAccessTechnologyHSUPA,
             CTRadioAccessTechnologyCDMAEVDORev0,
             CTRadioAccessTechnologyCDMAEVDORevA,
             CTRadioAccessTechnologyCDMAEVDORevB,
             CTRadioAccessTechnologyeHRPD:
            self = .wwan3g
        case CTRadioAccessTechnologyLTE:
            self = .wwan4g
        default:
            self = .unknownTechnology
        }
    }
    #endif
}

#if os(iOS)
extension Reachability {
    func getSimpleNetworkType() -> NetworkType {
        try? startNotifier()

        switch connection {
        case .none:
            return .noConnection
        case .wifi:
            return .wifi
        case .cellular:
            return .cellular
        case .unavailable:
            return .noConnection
        }
    }

    func getNetworkType() -> NetworkType {
        try? startNotifier()

        switch connection {
        case .none:
            return .noConnection
        case .wifi:
            return .wifi
        case .cellular:
            #if !targetEnvironment(macCatalyst)
            return Reachability.getWWANNetworkType()
            #else
            return .cellular
            #endif
        case .unavailable:
            return .noConnection
        }
    }

    #if !targetEnvironment(macCatalyst)
    static func getWWANNetworkType() -> NetworkType {
        let networkTypes = (CTTelephonyNetworkInfo().serviceCurrentRadioAccessTechnology ?? [:])
            .sorted(by: { $0.key < $1.key })
            .map(\.value)
            .map(NetworkType.init(_:))

        return networkTypes.first(where: { $0 != .unknownTechnology }) ?? .unknown
    }
    #endif
}
#endif
