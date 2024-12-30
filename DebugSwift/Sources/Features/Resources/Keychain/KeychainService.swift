//
//  KeychainService.swift
//  KeychainAccess
//
//  Created by kishikawa katsumi on 2014/12/24.
//  Copyright (c) 2014 kishikawa katsumi. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import Security
#if os(iOS) || os(OSX)
import LocalAuthentication
#endif

public let KeychainAccessErrorDomain = "com.kishikawakatsumi.KeychainAccess.error"

public enum ItemClass {
    case genericPassword
    case internetPassword
}

public enum ProtocolType {
    case ftp
    case ftpAccount
    case http
    case irc
    case nntp
    case pop3
    case smtp
    case socks
    case imap
    case ldap
    case appleTalk
    case afp
    case telnet
    case ssh
    case ftps
    case https
    case httpProxy
    case httpsProxy
    case ftpProxy
    case smb
    case rtsp
    case rtspProxy
    case daap
    case eppc
    case ipp
    case nntps
    case ldaps
    case telnetS
    case imaps
    case ircs
    case pop3S
}

public enum AuthenticationType {
    case ntlm
    case msn
    case dpa
    case rpa
    case httpBasic
    case httpDigest
    case htmlForm
    case `default`
}

public enum Accessibility {
    /**
     Item data can only be accessed
     while the device is unlocked. This is recommended for items that only
     need be accesible while the application is in the foreground. Items
     with this attribute will migrate to a new device when using encrypted
     backups.
     */
    case whenUnlocked

    /**
     Item data can only be
     accessed once the device has been unlocked after a restart. This is
     recommended for items that need to be accesible by background
     applications. Items with this attribute will migrate to a new device
     when using encrypted backups.
     */
    case afterFirstUnlock

    /**
     Item data can always be accessed
     regardless of the lock state of the device. This is not recommended
     for anything except system use. Items with this attribute will migrate
     to a new device when using encrypted backups.
     */
    @available(macCatalyst, unavailable)
    case always

    /**
     Item data can
     only be accessed while the device is unlocked. This class is only
     available if a passcode is set on the device. This is recommended for
     items that only need to be accessible while the application is in the
     foreground. Items with this attribute will never migrate to a new
     device, so after a backup is restored to a new device, these items
     will be missing. No items can be stored in this class on devices
     without a passcode. Disabling the device passcode will cause all
     items in this class to be deleted.
     */
    @available(iOS 8.0, OSX 10.10, *)
    case whenPasscodeSetThisDeviceOnly

    /**
     Item data can only
     be accessed while the device is unlocked. This is recommended for items
     that only need be accesible while the application is in the foreground.
     Items with this attribute will never migrate to a new device, so after
     a backup is restored to a new device, these items will be missing.
     */
    case whenUnlockedThisDeviceOnly

    /**
     Item data can
     only be accessed once the device has been unlocked after a restart.
     This is recommended for items that need to be accessible by background
     applications. Items with this attribute will never migrate to a new
     device, so after a backup is restored to a new device these items will
     be missing.
     */
    case afterFirstUnlockThisDeviceOnly

    /**
     Item data can always
     be accessed regardless of the lock state of the device. This option
     is not recommended for anything except system use. Items with this
     attribute will never migrate to a new device, so after a backup is
     restored to a new device, these items will be missing.
     */
    @available(macCatalyst, unavailable)
    case alwaysThisDeviceOnly
}

/**
 Predefined item attribute constants used to get or set values
 in a dictionary. The kSecUseAuthenticationUI constant is the key and its
 value is one of the constants defined here.
 If the key kSecUseAuthenticationUI not provided then kSecUseAuthenticationUIAllow
 is used as default.
 */
public enum AuthenticationUI {
    /**
     Specifies that authenticate UI can appear.
     */
    case allow

    /**
     Specifies that the error
     errSecInteractionNotAllowed will be returned if an item needs
     to authenticate with UI
     */
    case fail

    /**
     Specifies that all items which need
     to authenticate with UI will be silently skipped. This value can be used
     only with SecItemCopyMatching.
     */
    case skip
}

@available(iOS 9.0, OSX 10.11, *)
extension AuthenticationUI {
    public var rawValue: String {
        switch self {
        case .allow:
            return UseAuthenticationUIAllow
        case .fail:
            return UseAuthenticationUIFail
        case .skip:
            return UseAuthenticationUISkip
        }
    }

    public var description: String {
        switch self {
        case .allow:
            return "allow"
        case .fail:
            return "fail"
        case .skip:
            return "skip"
        }
    }
}

public struct AuthenticationPolicy: OptionSet {
    /**
     User presence policy using Touch ID or Passcode. Touch ID does not
     have to be available or enrolled. Item is still accessible by Touch ID
     even if fingers are added or removed.
     */
    @available(iOS 8.0, OSX 10.10, watchOS 2.0, tvOS 8.0, *)
    public static let userPresence = AuthenticationPolicy(rawValue: 1 << 0)

    /**
     Constraint: Touch ID (any finger) or Face ID. Touch ID or Face ID must be available. With Touch ID
     at least one finger must be enrolled. With Face ID user has to be enrolled. Item is still accessible by Touch ID even
     if fingers are added or removed. Item is still accessible by Face ID if user is re-enrolled.
     */
    @available(iOS 11.3, OSX 10.13.4, watchOS 4.3, tvOS 11.3, *)
    public static let biometryAny = AuthenticationPolicy(rawValue: 1 << 1)

    /**
     Deprecated, please use biometryAny instead.
     */
    @available(iOS, introduced: 9.0, deprecated: 11.3, renamed: "biometryAny")
    @available(OSX, introduced: 10.12.1, deprecated: 10.13.4, renamed: "biometryAny")
    @available(watchOS, introduced: 2.0, deprecated: 4.3, renamed: "biometryAny")
    @available(tvOS, introduced: 9.0, deprecated: 11.3, renamed: "biometryAny")
    public static let touchIDAny = AuthenticationPolicy(rawValue: 1 << 1)

    /**
     Constraint: Touch ID from the set of currently enrolled fingers. Touch ID must be available and at least one finger must
     be enrolled. When fingers are added or removed, the item is invalidated. When Face ID is re-enrolled this item is invalidated.
     */
    @available(iOS 11.3, OSX 10.13, watchOS 4.3, tvOS 11.3, *)
    public static let biometryCurrentSet = AuthenticationPolicy(rawValue: 1 << 3)

    /**
     Deprecated, please use biometryCurrentSet instead.
     */
    @available(iOS, introduced: 9.0, deprecated: 11.3, renamed: "biometryCurrentSet")
    @available(OSX, introduced: 10.12.1, deprecated: 10.13.4, renamed: "biometryCurrentSet")
    @available(watchOS, introduced: 2.0, deprecated: 4.3, renamed: "biometryCurrentSet")
    @available(tvOS, introduced: 9.0, deprecated: 11.3, renamed: "biometryCurrentSet")
    public static let touchIDCurrentSet = AuthenticationPolicy(rawValue: 1 << 3)

    /**
     Constraint: Device passcode
     */
    @available(iOS 9.0, OSX 10.11, watchOS 2.0, tvOS 9.0, *)
    public static let devicePasscode = AuthenticationPolicy(rawValue: 1 << 4)

    /**
     Constraint: Watch
     */
    @available(iOS, unavailable)
    @available(OSX 10.15, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    public static let watch = AuthenticationPolicy(rawValue: 1 << 5)

    /**
     Constraint logic operation: when using more than one constraint,
     at least one of them must be satisfied.
     */
    @available(iOS 9.0, OSX 10.12.1, watchOS 2.0, tvOS 9.0, *)
    public static let or = AuthenticationPolicy(rawValue: 1 << 14)

    /**
     Constraint logic operation: when using more than one constraint,
     all must be satisfied.
     */
    @available(iOS 9.0, OSX 10.12.1, watchOS 2.0, tvOS 9.0, *)
    public static let and = AuthenticationPolicy(rawValue: 1 << 15)

    /**
     Create access control for private key operations (i.e. sign operation)
     */
    @available(iOS 9.0, OSX 10.12.1, watchOS 2.0, tvOS 9.0, *)
    public static let privateKeyUsage = AuthenticationPolicy(rawValue: 1 << 30)

    /**
     Security: Application provided password for data encryption key generation.
     This is not a constraint but additional item encryption mechanism.
     */
    @available(iOS 9.0, OSX 10.12.1, watchOS 2.0, tvOS 9.0, *)
    public static let applicationPassword = AuthenticationPolicy(rawValue: 1 << 31)

    #if swift(>=2.3)
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    #else
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    #endif
}

public struct Attributes {
    public var `class`: String? {
        attributes[Class] as? String
    }

    public var data: Data? {
        attributes[ValueData] as? Data
    }

    public var ref: Data? {
        attributes[ValueRef] as? Data
    }

    public var persistentRef: Data? {
        attributes[ValuePersistentRef] as? Data
    }

    public var accessible: String? {
        attributes[AttributeAccessible] as? String
    }

    public var accessControl: SecAccessControl? {
        if #available(OSX 10.10, *) {
            if let accessControl = attributes[AttributeAccessControl] {
                return (accessControl as! SecAccessControl)
            }
            return nil
        } else {
            return nil
        }
    }

    public var accessGroup: String? {
        attributes[AttributeAccessGroup] as? String
    }

    public var synchronizable: Bool? {
        attributes[AttributeSynchronizable] as? Bool
    }

    public var creationDate: Date? {
        attributes[AttributeCreationDate] as? Date
    }

    public var modificationDate: Date? {
        attributes[AttributeModificationDate] as? Date
    }

    public var attributeDescription: String? {
        attributes[AttributeDescription] as? String
    }

    public var comment: String? {
        attributes[AttributeComment] as? String
    }

    public var creator: String? {
        attributes[AttributeCreator] as? String
    }

    public var type: String? {
        attributes[AttributeType] as? String
    }

    public var label: String? {
        attributes[AttributeLabel] as? String
    }

    public var isInvisible: Bool? {
        attributes[AttributeIsInvisible] as? Bool
    }

    public var isNegative: Bool? {
        attributes[AttributeIsNegative] as? Bool
    }

    public var account: String? {
        attributes[AttributeAccount] as? String
    }

    public var service: String? {
        attributes[AttributeService] as? String
    }

    public var generic: Data? {
        attributes[AttributeGeneric] as? Data
    }

    public var securityDomain: String? {
        attributes[AttributeSecurityDomain] as? String
    }

    public var server: String? {
        attributes[AttributeServer] as? String
    }

    public var `protocol`: String? {
        attributes[AttributeProtocol] as? String
    }

    public var authenticationType: String? {
        attributes[AttributeAuthenticationType] as? String
    }

    public var port: Int? {
        attributes[AttributePort] as? Int
    }

    public var path: String? {
        attributes[AttributePath] as? String
    }

    fileprivate let attributes: [String: Any]

    init(attributes: [String: Any]) {
        self.attributes = attributes
    }

    public subscript(key: String) -> Any? {
        attributes[key]
    }
}

public final class Keychain {
    public var itemClass: ItemClass {
        options.itemClass
    }

    public var service: String {
        options.service
    }

    // This attribute (kSecAttrAccessGroup) applies to macOS keychain items only if you also set a value of true for the
    // kSecUseDataProtectionKeychain key, the kSecAttrSynchronizable key, or both.
    public var accessGroup: String? {
        options.accessGroup
    }

    public var server: URL {
        options.server
    }

    public var protocolType: ProtocolType {
        options.protocolType
    }

    public var authenticationType: AuthenticationType {
        options.authenticationType
    }

    public var accessibility: Accessibility {
        options.accessibility
    }

    @available(iOS 8.0, OSX 10.10, *)
    @available(watchOS, unavailable)
    public var authenticationPolicy: AuthenticationPolicy? {
        options.authenticationPolicy
    }

    public var synchronizable: Bool {
        options.synchronizable
    }

    public var label: String? {
        options.label
    }

    public var comment: String? {
        options.comment
    }

    @available(iOS 8.0, OSX 10.10, *)
    @available(watchOS, unavailable)
    public var authenticationPrompt: String? {
        options.authenticationPrompt
    }

    @available(iOS 9.0, OSX 10.11, *)
    public var authenticationUI: AuthenticationUI {
        options.authenticationUI ?? .allow
    }

    #if os(iOS) || os(OSX)
    @available(iOS 9.0, OSX 10.11, *)
    public var authenticationContext: LAContext? {
        options.authenticationContext as? LAContext
    }
    #endif

    private let options: Options

    // MARK: 

    public convenience init() {
        var options = Options()
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            options.service = bundleIdentifier
        }
        self.init(options)
    }

    public convenience init(service: String) {
        var options = Options()
        options.service = service
        self.init(options)
    }

    public convenience init(accessGroup: String) {
        var options = Options()
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            options.service = bundleIdentifier
        }
        options.accessGroup = accessGroup
        self.init(options)
    }

    public convenience init(service: String, accessGroup: String) {
        var options = Options()
        options.service = service
        options.accessGroup = accessGroup
        self.init(options)
    }

    public convenience init(server: String, protocolType: ProtocolType, accessGroup: String? = nil, authenticationType: AuthenticationType = .default) {
        self.init(server: URL(string: server)!, protocolType: protocolType, accessGroup: accessGroup, authenticationType: authenticationType)
    }

    public convenience init(server: URL, protocolType: ProtocolType, accessGroup: String? = nil, authenticationType: AuthenticationType = .default) {
        var options = Options()
        options.itemClass = .internetPassword
        options.server = server
        options.protocolType = protocolType
        options.accessGroup = accessGroup
        options.authenticationType = authenticationType
        self.init(options)
    }

    private init(_ opts: Options) {
        self.options = opts
    }

    // MARK: 

    public func accessibility(_ accessibility: Accessibility) -> Keychain {
        var options = options
        options.accessibility = accessibility
        return Keychain(options)
    }

    @available(iOS 8.0, OSX 10.10, *)
    @available(watchOS, unavailable)
    public func accessibility(_ accessibility: Accessibility, authenticationPolicy: AuthenticationPolicy) -> Keychain {
        var options = options
        options.accessibility = accessibility
        options.authenticationPolicy = authenticationPolicy
        return Keychain(options)
    }

    public func synchronizable(_ synchronizable: Bool) -> Keychain {
        var options = options
        options.synchronizable = synchronizable
        return Keychain(options)
    }

    public func label(_ label: String) -> Keychain {
        var options = options
        options.label = label
        return Keychain(options)
    }

    public func comment(_ comment: String) -> Keychain {
        var options = options
        options.comment = comment
        return Keychain(options)
    }

    public func attributes(_ attributes: [String: Any]) -> Keychain {
        var options = options
        attributes.forEach { options.attributes.updateValue($1, forKey: $0) }
        return Keychain(options)
    }

    @available(iOS 8.0, OSX 10.10, *)
    @available(watchOS, unavailable)
    public func authenticationPrompt(_ authenticationPrompt: String) -> Keychain {
        var options = options
        options.authenticationPrompt = authenticationPrompt
        return Keychain(options)
    }

    @available(iOS 9.0, OSX 10.11, *)
    public func authenticationUI(_ authenticationUI: AuthenticationUI) -> Keychain {
        var options = options
        options.authenticationUI = authenticationUI
        return Keychain(options)
    }

    #if os(iOS) || os(OSX)
    @available(iOS 9.0, OSX 10.11, *)
    public func authenticationContext(_ authenticationContext: LAContext) -> Keychain {
        var options = options
        options.authenticationContext = authenticationContext
        return Keychain(options)
    }
    #endif

    // MARK: 

    public func get(_ key: String, ignoringAttributeSynchronizable: Bool = true) throws -> String? {
        try getString(key, ignoringAttributeSynchronizable: ignoringAttributeSynchronizable)
    }

    public func getString(_ key: String, ignoringAttributeSynchronizable: Bool = true) throws -> String? {
        guard let data = try getData(key, ignoringAttributeSynchronizable: ignoringAttributeSynchronizable) else {
            return nil
        }
        guard let string = String(data: data, encoding: .utf8) else {
            print("failed to convert data to string")
            throw Status.conversionError
        }
        return string
    }

    public func getData(_ key: String, ignoringAttributeSynchronizable: Bool = true) throws -> Data? {
        var query = options.query(ignoringAttributeSynchronizable: ignoringAttributeSynchronizable)

        query[MatchLimit] = MatchLimitOne
        query[ReturnData] = kCFBooleanTrue

        query[AttributeAccount] = key

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw Status.unexpectedError
            }
            return data
        case errSecItemNotFound:
            return nil
        default:
            throw securityError(status: status)
        }
    }

    public func get<T>(_ key: String, ignoringAttributeSynchronizable: Bool = true, handler: (Attributes?) -> T) throws -> T {
        var query = options.query(ignoringAttributeSynchronizable: ignoringAttributeSynchronizable)

        query[MatchLimit] = MatchLimitOne

        query[ReturnData] = kCFBooleanTrue
        query[ReturnAttributes] = kCFBooleanTrue
        query[ReturnRef] = kCFBooleanTrue
        query[ReturnPersistentRef] = kCFBooleanTrue

        query[AttributeAccount] = key

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let attributes = result as? [String: Any] else {
                throw Status.unexpectedError
            }
            return handler(Attributes(attributes: attributes))
        case errSecItemNotFound:
            return handler(nil)
        default:
            throw securityError(status: status)
        }
    }

    // MARK: 

    public func set(_ value: String, key: String, ignoringAttributeSynchronizable: Bool = true) throws {
        guard let data = value.data(using: .utf8, allowLossyConversion: false) else {
            print("failed to convert string to data")
            throw Status.conversionError
        }
        try set(data, key: key, ignoringAttributeSynchronizable: ignoringAttributeSynchronizable)
    }

    public func set(_ value: Data, key: String, ignoringAttributeSynchronizable: Bool = true) throws {
        var query = options.query(ignoringAttributeSynchronizable: ignoringAttributeSynchronizable)
        query[AttributeAccount] = key
        #if os(iOS)
        if #available(iOS 9.0, *) {
            if let authenticationUI = options.authenticationUI {
                query[UseAuthenticationUI] = authenticationUI.rawValue
            } else {
                query[UseAuthenticationUI] = UseAuthenticationUIFail
            }
        } else {
            query[UseNoAuthenticationUI] = kCFBooleanTrue
        }
        #elseif os(OSX)
        query[ReturnData] = kCFBooleanTrue
        if #available(OSX 10.11, *) {
            if let authenticationUI = options.authenticationUI {
                query[UseAuthenticationUI] = authenticationUI.rawValue
            } else {
                query[UseAuthenticationUI] = UseAuthenticationUIFail
            }
        }
        #else
        if let authenticationUI = options.authenticationUI {
            query[UseAuthenticationUI] = authenticationUI.rawValue
        }
        #endif

        var status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess, errSecInteractionNotAllowed:
            var query = options.query()
            query[AttributeAccount] = key

            var (attributes, error) = options.attributes(key: nil, value: value)
            if let error {
                print(error.localizedDescription)
                throw error
            }

            options.attributes.forEach { attributes.updateValue($1, forKey: $0) }

            #if os(iOS)
            if status == errSecInteractionNotAllowed, floor(NSFoundationVersionNumber) <= floor(NSFoundationVersionNumber_iOS_8_0) {
                try remove(key)
                try set(value, key: key)
            } else {
                status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
                if status != errSecSuccess {
                    throw securityError(status: status)
                }
            }
            #else
            status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            if status != errSecSuccess {
                throw securityError(status: status)
            }
            #endif
        case errSecItemNotFound:
            var (attributes, error) = options.attributes(key: key, value: value)
            if let error {
                print(error.localizedDescription)
                throw error
            }

            options.attributes.forEach { attributes.updateValue($1, forKey: $0) }

            status = SecItemAdd(attributes as CFDictionary, nil)
            if status != errSecSuccess {
                throw securityError(status: status)
            }
        default:
            throw securityError(status: status)
        }
    }

    public subscript(key: String) -> String? {
        get {
            #if swift(>=5.0)
            return try? get(key)
            #else
            return (try? get(key)).flatMap { $0 }
            #endif
        }

        set {
            if let value = newValue {
                do {
                    try set(value, key: key)
                } catch {}
            } else {
                do {
                    try remove(key)
                } catch {}
            }
        }
    }

    public subscript(string key: String) -> String? {
        get {
            self[key]
        }

        set {
            self[key] = newValue
        }
    }

    public subscript(data key: String) -> Data? {
        get {
            #if swift(>=5.0)
            return try? getData(key)
            #else
            return (try? getData(key)).flatMap { $0 }
            #endif
        }

        set {
            if let value = newValue {
                do {
                    try set(value, key: key)
                } catch {}
            } else {
                do {
                    try remove(key)
                } catch {}
            }
        }
    }

    public subscript(attributes key: String) -> Attributes? {
        #if swift(>=5.0)
        return try? get(key) { $0 }
        #else
        return (try? get(key) { $0 }).flatMap { $0 }
        #endif
    }

    // MARK: 

    public func remove(_ key: String, ignoringAttributeSynchronizable: Bool = true) throws {
        var query = options.query(ignoringAttributeSynchronizable: ignoringAttributeSynchronizable)
        query[AttributeAccount] = key

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess, status != errSecItemNotFound {
            throw securityError(status: status)
        }
    }

    public func removeAll() throws {
        var query = options.query()
        #if !os(iOS) && !os(watchOS) && !os(tvOS)
        query[MatchLimit] = MatchLimitAll
        #endif

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess, status != errSecItemNotFound {
            throw securityError(status: status)
        }
    }

    // MARK: 

    public func contains(_ key: String, withoutAuthenticationUI: Bool = false) throws -> Bool {
        var query = options.query()
        query[AttributeAccount] = key

        if withoutAuthenticationUI {
            #if os(iOS) || os(watchOS) || os(tvOS)
            if #available(iOS 9.0, *) {
                if let authenticationUI = options.authenticationUI {
                    query[UseAuthenticationUI] = authenticationUI.rawValue
                } else {
                    query[UseAuthenticationUI] = UseAuthenticationUIFail
                }
            } else {
                query[UseNoAuthenticationUI] = kCFBooleanTrue
            }
            #else
            if #available(OSX 10.11, *) {
                if let authenticationUI = options.authenticationUI {
                    query[UseAuthenticationUI] = authenticationUI.rawValue
                } else {
                    query[UseAuthenticationUI] = UseAuthenticationUIFail
                }
            } else if #available(OSX 10.10, *) {
                query[UseNoAuthenticationUI] = kCFBooleanTrue
            }
            #endif
        } else {
            if #available(iOS 9.0, OSX 10.11, *) {
                if let authenticationUI = options.authenticationUI {
                    query[UseAuthenticationUI] = authenticationUI.rawValue
                }
            }
        }

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            return true
        case errSecInteractionNotAllowed:
            if withoutAuthenticationUI {
                return true
            }
            return false
        case errSecItemNotFound:
            return false
        default:
            throw securityError(status: status)
        }
    }

    // MARK: 

    public final class func allKeys(_ itemClass: ItemClass) -> [(String, String)] {
        var query = [String: Any]()
        query[Class] = itemClass.rawValue
        query[AttributeSynchronizable] = SynchronizableAny
        query[MatchLimit] = MatchLimitAll
        query[ReturnAttributes] = kCFBooleanTrue

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            if let items = result as? [[String: Any]] {
                return prettify(itemClass: itemClass, items: items).map {
                    switch itemClass {
                    case .genericPassword:
                        return (($0["service"] ?? "") as! String, ($0["key"] ?? "") as! String)
                    case .internetPassword:
                        return (($0["server"] ?? "") as! String, ($0["key"] ?? "") as! String)
                    }
                }
            }
        case errSecItemNotFound:
            return []
        default: ()
        }

        securityError(status: status)
        return []
    }

    public func allKeys() -> [String] {
        let allItems = Self.prettify(itemClass: itemClass, items: items())
        let filter: ([String: Any]) -> String? = { $0["key"] as? String }

        #if swift(>=4.1)
        return allItems.compactMap(filter)
        #else
        return allItems.flatMap(filter)
        #endif
    }

    public final class func allItems(_ itemClass: ItemClass) -> [[String: Any]] {
        var query = [String: Any]()
        query[Class] = itemClass.rawValue
        query[MatchLimit] = MatchLimitAll
        query[ReturnAttributes] = kCFBooleanTrue
        #if os(iOS) || os(watchOS) || os(tvOS)
        query[ReturnData] = kCFBooleanTrue
        #endif

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            if let items = result as? [[String: Any]] {
                return prettify(itemClass: itemClass, items: items)
            }
        case errSecItemNotFound:
            return []
        default: ()
        }

        securityError(status: status)
        return []
    }

    public func allItems() -> [[String: Any]] {
        Self.prettify(itemClass: itemClass, items: items())
    }

    #if os(iOS) && !targetEnvironment(macCatalyst)
    @available(iOS 8.0, *)
    public func getSharedPassword(_ completion: @escaping (_ account: String?, _ password: String?, _ error: Error?) -> Void = { _, _, _ in }) {
        if let domain = server.host {
            Self.requestSharedWebCredential(domain: domain, account: nil) { credentials, error in
                if let credential = credentials.first {
                    let account = credential["account"]
                    let password = credential["password"]
                    completion(account, password, error)
                } else {
                    completion(nil, nil, error)
                }
            }
        } else {
            let error = securityError(status: Status.param.rawValue)
            completion(nil, nil, error)
        }
    }
    #endif

    #if os(iOS) && !targetEnvironment(macCatalyst)
    @available(iOS 8.0, *)
    public func getSharedPassword(_ account: String, completion: @escaping (_ password: String?, _ error: Error?) -> Void = { _, _ in }) {
        if let domain = server.host {
            Self.requestSharedWebCredential(domain: domain, account: account) { credentials, error in
                if let credential = credentials.first {
                    if let password = credential["password"] {
                        completion(password, error)
                    } else {
                        completion(nil, error)
                    }
                } else {
                    completion(nil, error)
                }
            }
        } else {
            let error = securityError(status: Status.param.rawValue)
            completion(nil, error)
        }
    }
    #endif

    #if os(iOS) && !targetEnvironment(macCatalyst)
    @available(iOS 8.0, *)
    public func setSharedPassword(_ password: String, account: String, completion: @escaping (_ error: Error?) -> Void = { _ in }) {
        setSharedPassword(password as String?, account: account, completion: completion)
    }
    #endif

    #if os(iOS) && !targetEnvironment(macCatalyst)
    @available(iOS 8.0, *)
    fileprivate func setSharedPassword(_ password: String?, account: String, completion: @escaping (_ error: Error?) -> Void = { _ in }) {
        if let domain = server.host {
            SecAddSharedWebCredential(domain as CFString, account as CFString, password as CFString?) { error in
                if let error {
                    completion(error.error)
                } else {
                    completion(nil)
                }
            }
        } else {
            let error = securityError(status: Status.param.rawValue)
            completion(error)
        }
    }
    #endif

    #if os(iOS) && !targetEnvironment(macCatalyst)
    @available(iOS 8.0, *)
    public func removeSharedPassword(_ account: String, completion: @escaping (_ error: Error?) -> Void = { _ in }) {
        setSharedPassword(nil, account: account, completion: completion)
    }
    #endif

    #if os(iOS) && !targetEnvironment(macCatalyst)
    @available(iOS 8.0, *)
    public final class func requestSharedWebCredential(_ completion: @escaping (_ credentials: [[String: String]], _ error: Error?) -> Void = { _, _ in }) {
        requestSharedWebCredential(domain: nil, account: nil, completion: completion)
    }
    #endif

    #if os(iOS) && !targetEnvironment(macCatalyst)
    @available(iOS 8.0, *)
    public final class func requestSharedWebCredential(domain: String, completion: @escaping (_ credentials: [[String: String]], _ error: Error?) -> Void = { _, _ in }) {
        requestSharedWebCredential(domain: domain, account: nil, completion: completion)
    }
    #endif

    #if os(iOS) && !targetEnvironment(macCatalyst)
    @available(iOS 8.0, *)
    public final class func requestSharedWebCredential(domain: String, account: String, completion: @escaping (_ credentials: [[String: String]], _ error: Error?) -> Void = { _, _ in }) {
        requestSharedWebCredential(domain: Optional(domain), account: Optional(account)!, completion: completion)
    }
    #endif

    #if os(iOS) && !targetEnvironment(macCatalyst)
    @available(iOS 8.0, *)
    fileprivate final class func requestSharedWebCredential(domain: String?, account: String?, completion: @escaping (_ credentials: [[String: String]], _ error: Error?) -> Void) {
        SecRequestSharedWebCredential(domain as CFString?, account as CFString?) { credentials, error in
            var remoteError: NSError?
            if let error {
                remoteError = error.error
                if remoteError?.code != Int(errSecItemNotFound) {
                    print("error:[\(remoteError!.code)] \(remoteError!.localizedDescription)")
                }
            }
            if let credentials {
                let credentials = (credentials as NSArray).map { credentials -> [String: String] in
                    var credential = [String: String]()
                    if let credentials = credentials as? [String: String] {
                        if let server = credentials[AttributeServer] {
                            credential["server"] = server
                        }
                        if let account = credentials[AttributeAccount] {
                            credential["account"] = account
                        }
                        if let password = credentials[SharedPassword] {
                            credential["password"] = password
                        }
                    }
                    return credential
                }
                completion(credentials, remoteError)
            } else {
                completion([], remoteError)
            }
        }
    }
    #endif

    #if os(iOS) && !targetEnvironment(macCatalyst)
    /**
     @abstract Returns a randomly generated password.
     @return String password in the form xxx-xxx-xxx-xxx where x is taken from the sets "abcdefghkmnopqrstuvwxy", "ABCDEFGHJKLMNPQRSTUVWXYZ", "3456789" with at least one character from each set being present.
     */
    @available(iOS 8.0, *)
    public final class func generatePassword() -> String {
        SecCreateSharedWebCredentialPassword()! as String
    }
    #endif

    // MARK: 

    private func items() -> [[String: Any]] {
        var query = options.query()
        query[MatchLimit] = MatchLimitAll
        query[ReturnAttributes] = kCFBooleanTrue
        #if os(iOS) || os(watchOS) || os(tvOS)
        query[ReturnData] = kCFBooleanTrue
        #endif

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            if let items = result as? [[String: Any]] {
                return items
            }
        case errSecItemNotFound:
            return []
        default: ()
        }

        securityError(status: status)
        return []
    }

    private final class func prettify(itemClass: ItemClass, items: [[String: Any]]) -> [[String: Any]] {
        return items.map { attributes -> [String: Any] in
            var item = [String: Any]()

            item["class"] = itemClass.description

            if let accessGroup = attributes[AttributeAccessGroup] as? String {
                item["accessGroup"] = accessGroup
            }

            switch itemClass {
            case .genericPassword:
                if let service = attributes[AttributeService] as? String {
                    item["service"] = service
                }
            case .internetPassword:
                if let server = attributes[AttributeServer] as? String {
                    item["server"] = server
                }
                if let proto = attributes[AttributeProtocol] as? String {
                    if let protocolType = ProtocolType(rawValue: proto) {
                        item["protocol"] = protocolType.description
                    }
                }
                if let auth = attributes[AttributeAuthenticationType] as? String {
                    if let authenticationType = AuthenticationType(rawValue: auth) {
                        item["authenticationType"] = authenticationType.description
                    }
                }
            }

            if let key = attributes[AttributeAccount] as? String {
                item["key"] = key
            }
            if let data = attributes[ValueData] as? Data {
                if let text = String(data: data, encoding: .utf8) {
                    item["value"] = text
                } else {
                    item["value"] = data
                }
            }

            if let accessible = attributes[AttributeAccessible] as? String {
                if let accessibility = Accessibility(rawValue: accessible) {
                    item["accessibility"] = accessibility.description
                }
            }
            if let synchronizable = attributes[AttributeSynchronizable] as? Bool {
                item["synchronizable"] = synchronizable ? "true" : "false"
            }

            return item
        }
    }

    // MARK: 

    @discardableResult
    private final class func securityError(status: OSStatus) -> Error {
        let error = Status(status: status)
        if error != .userCanceled {
            print("OSStatus error:[\(error.errorCode)] \(error.description)")
        }

        return error
    }

    @discardableResult
    private func securityError(status: OSStatus) -> Error {
        Self.securityError(status: status)
    }
}

struct Options {
    var itemClass: ItemClass = .genericPassword

    var service = ""
    var accessGroup: String?

    var server: URL!
    var protocolType: ProtocolType!
    var authenticationType: AuthenticationType = .default

    var accessibility: Accessibility = .afterFirstUnlock
    var authenticationPolicy: AuthenticationPolicy?

    var synchronizable = false

    var label: String?
    var comment: String?

    var authenticationPrompt: String?
    var authenticationUI: AuthenticationUI?
    var authenticationContext: AnyObject?

    var attributes = [String: Any]()
}

/** Class Key Constant */
private let Class = String(kSecClass)

/** Attribute Key Constants */
private let AttributeAccessible = String(kSecAttrAccessible)

@available(iOS 8.0, OSX 10.10, *)
private let AttributeAccessControl = String(kSecAttrAccessControl)

private let AttributeAccessGroup = String(kSecAttrAccessGroup)
private let AttributeSynchronizable = String(kSecAttrSynchronizable)
private let AttributeCreationDate = String(kSecAttrCreationDate)
private let AttributeModificationDate = String(kSecAttrModificationDate)
private let AttributeDescription = String(kSecAttrDescription)
private let AttributeComment = String(kSecAttrComment)
private let AttributeCreator = String(kSecAttrCreator)
private let AttributeType = String(kSecAttrType)
private let AttributeLabel = String(kSecAttrLabel)
private let AttributeIsInvisible = String(kSecAttrIsInvisible)
private let AttributeIsNegative = String(kSecAttrIsNegative)
private let AttributeAccount = String(kSecAttrAccount)
private let AttributeService = String(kSecAttrService)
private let AttributeGeneric = String(kSecAttrGeneric)
private let AttributeSecurityDomain = String(kSecAttrSecurityDomain)
private let AttributeServer = String(kSecAttrServer)
private let AttributeProtocol = String(kSecAttrProtocol)
private let AttributeAuthenticationType = String(kSecAttrAuthenticationType)
private let AttributePort = String(kSecAttrPort)
private let AttributePath = String(kSecAttrPath)

private let SynchronizableAny = kSecAttrSynchronizableAny

/** Search Constants */
private let MatchLimit = String(kSecMatchLimit)
private let MatchLimitOne = kSecMatchLimitOne
private let MatchLimitAll = kSecMatchLimitAll

/** Return Type Key Constants */
private let ReturnData = String(kSecReturnData)
private let ReturnAttributes = String(kSecReturnAttributes)
private let ReturnRef = String(kSecReturnRef)
private let ReturnPersistentRef = String(kSecReturnPersistentRef)

/** Value Type Key Constants */
private let ValueData = String(kSecValueData)
private let ValueRef = String(kSecValueRef)
private let ValuePersistentRef = String(kSecValuePersistentRef)

/** Other Constants */
@available(iOS 8.0, OSX 10.10, tvOS 8.0, *)
private let UseOperationPrompt = String(kSecUseOperationPrompt)

@available(iOS, introduced: 8.0, deprecated: 9.0, message: "Use a UseAuthenticationUI instead.")
@available(OSX, introduced: 10.10, deprecated: 10.11, message: "Use UseAuthenticationUI instead.")
@available(watchOS, introduced: 2.0, deprecated: 2.0, message: "Use UseAuthenticationUI instead.")
@available(tvOS, introduced: 8.0, deprecated: 9.0, message: "Use UseAuthenticationUI instead.")
private let UseNoAuthenticationUI = String(kSecUseNoAuthenticationUI)

@available(iOS 9.0, OSX 10.11, watchOS 2.0, tvOS 9.0, *)
private let UseAuthenticationUI = String(kSecUseAuthenticationUI)

@available(iOS 9.0, OSX 10.11, watchOS 2.0, tvOS 9.0, *)
private let UseAuthenticationContext = String(kSecUseAuthenticationContext)

@available(iOS 9.0, OSX 10.11, watchOS 2.0, tvOS 9.0, *)
private let UseAuthenticationUIAllow = String(kSecUseAuthenticationUIAllow)

@available(iOS 9.0, OSX 10.11, watchOS 2.0, tvOS 9.0, *)
private let UseAuthenticationUIFail = String(kSecUseAuthenticationUIFail)

@available(iOS 9.0, OSX 10.11, watchOS 2.0, tvOS 9.0, *)
private let UseAuthenticationUISkip = String(kSecUseAuthenticationUISkip)

#if os(iOS) && !targetEnvironment(macCatalyst)
/** Credential Key Constants */
private let SharedPassword = String(kSecSharedPassword)
#endif

extension Keychain: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        let items = allItems()
        if items.isEmpty {
            return "[]"
        }
        var description = "[\n"
        for item in items {
            description += "  "
            description += "\(item)\n"
        }
        description += "]"
        return description
    }

    public var debugDescription: String {
        "\(items())"
    }
}

extension Options {
    func query(ignoringAttributeSynchronizable: Bool = true) -> [String: Any] {
        var query = [String: Any]()

        query[Class] = itemClass.rawValue
        if let accessGroup {
            query[AttributeAccessGroup] = accessGroup
        }
        if ignoringAttributeSynchronizable {
            query[AttributeSynchronizable] = SynchronizableAny
        } else {
            query[AttributeSynchronizable] = synchronizable ? kCFBooleanTrue : kCFBooleanFalse
        }

        switch itemClass {
        case .genericPassword:
            query[AttributeService] = service
        case .internetPassword:
            query[AttributeServer] = server.host
            query[AttributePort] = server.port
            query[AttributeProtocol] = protocolType.rawValue
            query[AttributeAuthenticationType] = authenticationType.rawValue
        }

        if #available(OSX 10.10, *) {
            if authenticationPrompt != nil {
                query[UseOperationPrompt] = authenticationPrompt
            }
        }

        #if !os(watchOS)
        if #available(iOS 9.0, OSX 10.11, *) {
            if authenticationContext != nil {
                query[UseAuthenticationContext] = authenticationContext
            }
        }
        #endif

        return query
    }

    func attributes(key: String?, value: Data) -> ([String: Any], Error?) {
        var attributes: [String: Any]

        if key != nil {
            attributes = query()
            attributes[AttributeAccount] = key
        } else {
            attributes = [String: Any]()
        }

        attributes[ValueData] = value

        if label != nil {
            attributes[AttributeLabel] = label
        }
        if comment != nil {
            attributes[AttributeComment] = comment
        }

        if let policy = authenticationPolicy {
            if #available(OSX 10.10, *) {
                var error: Unmanaged<CFError>?
                guard let accessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault, accessibility.rawValue as CFTypeRef, SecAccessControlCreateFlags(rawValue: CFOptionFlags(policy.rawValue)), &error) else {
                    if let error = error?.takeUnretainedValue() {
                        return (attributes, error.error)
                    }

                    return (attributes, Status.unexpectedError)
                }
                attributes[AttributeAccessControl] = accessControl
            } else {
                print("Unavailable 'Touch ID integration' on OS X versions prior to 10.10.")
            }
        } else {
            attributes[AttributeAccessible] = accessibility.rawValue
        }

        attributes[AttributeSynchronizable] = synchronizable ? kCFBooleanTrue : kCFBooleanFalse

        return (attributes, nil)
    }
}

// MARK: 

extension Attributes: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        "\(attributes)"
    }

    public var debugDescription: String {
        description
    }
}

extension ItemClass: RawRepresentable, CustomStringConvertible {
    public init?(rawValue: String) {
        switch rawValue {
        case String(kSecClassGenericPassword):
            self = .genericPassword
        case String(kSecClassInternetPassword):
            self = .internetPassword
        default:
            return nil
        }
    }

    public var rawValue: String {
        switch self {
        case .genericPassword:
            return String(kSecClassGenericPassword)
        case .internetPassword:
            return String(kSecClassInternetPassword)
        }
    }

    public var description: String {
        switch self {
        case .genericPassword:
            return "GenericPassword"
        case .internetPassword:
            return "InternetPassword"
        }
    }
}

extension ProtocolType: RawRepresentable, CustomStringConvertible {
    public init?(rawValue: String) {
        switch rawValue {
        case String(kSecAttrProtocolFTP):
            self = .ftp
        case String(kSecAttrProtocolFTPAccount):
            self = .ftpAccount
        case String(kSecAttrProtocolHTTP):
            self = .http
        case String(kSecAttrProtocolIRC):
            self = .irc
        case String(kSecAttrProtocolNNTP):
            self = .nntp
        case String(kSecAttrProtocolPOP3):
            self = .pop3
        case String(kSecAttrProtocolSMTP):
            self = .smtp
        case String(kSecAttrProtocolSOCKS):
            self = .socks
        case String(kSecAttrProtocolIMAP):
            self = .imap
        case String(kSecAttrProtocolLDAP):
            self = .ldap
        case String(kSecAttrProtocolAppleTalk):
            self = .appleTalk
        case String(kSecAttrProtocolAFP):
            self = .afp
        case String(kSecAttrProtocolTelnet):
            self = .telnet
        case String(kSecAttrProtocolSSH):
            self = .ssh
        case String(kSecAttrProtocolFTPS):
            self = .ftps
        case String(kSecAttrProtocolHTTPS):
            self = .https
        case String(kSecAttrProtocolHTTPProxy):
            self = .httpProxy
        case String(kSecAttrProtocolHTTPSProxy):
            self = .httpsProxy
        case String(kSecAttrProtocolFTPProxy):
            self = .ftpProxy
        case String(kSecAttrProtocolSMB):
            self = .smb
        case String(kSecAttrProtocolRTSP):
            self = .rtsp
        case String(kSecAttrProtocolRTSPProxy):
            self = .rtspProxy
        case String(kSecAttrProtocolDAAP):
            self = .daap
        case String(kSecAttrProtocolEPPC):
            self = .eppc
        case String(kSecAttrProtocolIPP):
            self = .ipp
        case String(kSecAttrProtocolNNTPS):
            self = .nntps
        case String(kSecAttrProtocolLDAPS):
            self = .ldaps
        case String(kSecAttrProtocolTelnetS):
            self = .telnetS
        case String(kSecAttrProtocolIMAPS):
            self = .imaps
        case String(kSecAttrProtocolIRCS):
            self = .ircs
        case String(kSecAttrProtocolPOP3S):
            self = .pop3S
        default:
            return nil
        }
    }

    public var rawValue: String {
        switch self {
        case .ftp:
            return String(kSecAttrProtocolFTP)
        case .ftpAccount:
            return String(kSecAttrProtocolFTPAccount)
        case .http:
            return String(kSecAttrProtocolHTTP)
        case .irc:
            return String(kSecAttrProtocolIRC)
        case .nntp:
            return String(kSecAttrProtocolNNTP)
        case .pop3:
            return String(kSecAttrProtocolPOP3)
        case .smtp:
            return String(kSecAttrProtocolSMTP)
        case .socks:
            return String(kSecAttrProtocolSOCKS)
        case .imap:
            return String(kSecAttrProtocolIMAP)
        case .ldap:
            return String(kSecAttrProtocolLDAP)
        case .appleTalk:
            return String(kSecAttrProtocolAppleTalk)
        case .afp:
            return String(kSecAttrProtocolAFP)
        case .telnet:
            return String(kSecAttrProtocolTelnet)
        case .ssh:
            return String(kSecAttrProtocolSSH)
        case .ftps:
            return String(kSecAttrProtocolFTPS)
        case .https:
            return String(kSecAttrProtocolHTTPS)
        case .httpProxy:
            return String(kSecAttrProtocolHTTPProxy)
        case .httpsProxy:
            return String(kSecAttrProtocolHTTPSProxy)
        case .ftpProxy:
            return String(kSecAttrProtocolFTPProxy)
        case .smb:
            return String(kSecAttrProtocolSMB)
        case .rtsp:
            return String(kSecAttrProtocolRTSP)
        case .rtspProxy:
            return String(kSecAttrProtocolRTSPProxy)
        case .daap:
            return String(kSecAttrProtocolDAAP)
        case .eppc:
            return String(kSecAttrProtocolEPPC)
        case .ipp:
            return String(kSecAttrProtocolIPP)
        case .nntps:
            return String(kSecAttrProtocolNNTPS)
        case .ldaps:
            return String(kSecAttrProtocolLDAPS)
        case .telnetS:
            return String(kSecAttrProtocolTelnetS)
        case .imaps:
            return String(kSecAttrProtocolIMAPS)
        case .ircs:
            return String(kSecAttrProtocolIRCS)
        case .pop3S:
            return String(kSecAttrProtocolPOP3S)
        }
    }

    public var description: String {
        switch self {
        case .ftp:
            return "FTP"
        case .ftpAccount:
            return "FTPAccount"
        case .http:
            return "HTTP"
        case .irc:
            return "IRC"
        case .nntp:
            return "NNTP"
        case .pop3:
            return "POP3"
        case .smtp:
            return "SMTP"
        case .socks:
            return "SOCKS"
        case .imap:
            return "IMAP"
        case .ldap:
            return "LDAP"
        case .appleTalk:
            return "AppleTalk"
        case .afp:
            return "AFP"
        case .telnet:
            return "Telnet"
        case .ssh:
            return "SSH"
        case .ftps:
            return "FTPS"
        case .https:
            return "HTTPS"
        case .httpProxy:
            return "HTTPProxy"
        case .httpsProxy:
            return "HTTPSProxy"
        case .ftpProxy:
            return "FTPProxy"
        case .smb:
            return "SMB"
        case .rtsp:
            return "RTSP"
        case .rtspProxy:
            return "RTSPProxy"
        case .daap:
            return "DAAP"
        case .eppc:
            return "EPPC"
        case .ipp:
            return "IPP"
        case .nntps:
            return "NNTPS"
        case .ldaps:
            return "LDAPS"
        case .telnetS:
            return "TelnetS"
        case .imaps:
            return "IMAPS"
        case .ircs:
            return "IRCS"
        case .pop3S:
            return "POP3S"
        }
    }
}

extension AuthenticationType: RawRepresentable, CustomStringConvertible {
    public init?(rawValue: String) {
        switch rawValue {
        case String(kSecAttrAuthenticationTypeNTLM):
            self = .ntlm
        case String(kSecAttrAuthenticationTypeMSN):
            self = .msn
        case String(kSecAttrAuthenticationTypeDPA):
            self = .dpa
        case String(kSecAttrAuthenticationTypeRPA):
            self = .rpa
        case String(kSecAttrAuthenticationTypeHTTPBasic):
            self = .httpBasic
        case String(kSecAttrAuthenticationTypeHTTPDigest):
            self = .httpDigest
        case String(kSecAttrAuthenticationTypeHTMLForm):
            self = .htmlForm
        case String(kSecAttrAuthenticationTypeDefault):
            self = .default
        default:
            return nil
        }
    }

    public var rawValue: String {
        switch self {
        case .ntlm:
            return String(kSecAttrAuthenticationTypeNTLM)
        case .msn:
            return String(kSecAttrAuthenticationTypeMSN)
        case .dpa:
            return String(kSecAttrAuthenticationTypeDPA)
        case .rpa:
            return String(kSecAttrAuthenticationTypeRPA)
        case .httpBasic:
            return String(kSecAttrAuthenticationTypeHTTPBasic)
        case .httpDigest:
            return String(kSecAttrAuthenticationTypeHTTPDigest)
        case .htmlForm:
            return String(kSecAttrAuthenticationTypeHTMLForm)
        case .default:
            return String(kSecAttrAuthenticationTypeDefault)
        }
    }

    public var description: String {
        switch self {
        case .ntlm:
            return "NTLM"
        case .msn:
            return "MSN"
        case .dpa:
            return "DPA"
        case .rpa:
            return "RPA"
        case .httpBasic:
            return "HTTPBasic"
        case .httpDigest:
            return "HTTPDigest"
        case .htmlForm:
            return "HTMLForm"
        case .default:
            return "Default"
        }
    }
}

extension Accessibility: RawRepresentable, CustomStringConvertible {
    public init?(rawValue: String) {
        if #available(OSX 10.10, *) {
            switch rawValue {
            case String(kSecAttrAccessibleWhenUnlocked):
                self = .whenUnlocked
            case String(kSecAttrAccessibleAfterFirstUnlock):
                self = .afterFirstUnlock
            case String(kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly):
                self = .whenPasscodeSetThisDeviceOnly
            case String(kSecAttrAccessibleWhenUnlockedThisDeviceOnly):
                self = .whenUnlockedThisDeviceOnly
            case String(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly):
                self = .afterFirstUnlockThisDeviceOnly
            default:
                return nil
            }
        } else {
            switch rawValue {
            case String(kSecAttrAccessibleWhenUnlocked):
                self = .whenUnlocked
            case String(kSecAttrAccessibleAfterFirstUnlock):
                self = .afterFirstUnlock
            #if !targetEnvironment(macCatalyst)
            case String(kSecAttrAccessibleAlways):
                self = .always
            #endif
            case String(kSecAttrAccessibleWhenUnlockedThisDeviceOnly):
                self = .whenUnlockedThisDeviceOnly
            case String(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly):
                self = .afterFirstUnlockThisDeviceOnly
            #if !targetEnvironment(macCatalyst)
            case String(kSecAttrAccessibleAlwaysThisDeviceOnly):
                self = .alwaysThisDeviceOnly
            #endif
            default:
                return nil
            }
        }
    }

    public var rawValue: String {
        switch self {
        case .whenUnlocked:
            return String(kSecAttrAccessibleWhenUnlocked)
        case .afterFirstUnlock:
            return String(kSecAttrAccessibleAfterFirstUnlock)
        case .whenPasscodeSetThisDeviceOnly:
            if #available(OSX 10.10, *) {
                return String(kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly)
            } else {
                fatalError("'Accessibility.WhenPasscodeSetThisDeviceOnly' is not available on this version of OS.")
            }
        case .whenUnlockedThisDeviceOnly:
            return String(kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
        case .afterFirstUnlockThisDeviceOnly:
            return String(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
        default:
            return String(kSecAttrAccessibleWhenUnlocked)
        }
    }

    public var description: String {
        switch self {
        case .whenUnlocked:
            return "WhenUnlocked"
        case .afterFirstUnlock:
            return "AfterFirstUnlock"
        #if !targetEnvironment(macCatalyst)
        case .always:
            return "Always"
        #endif
        case .whenPasscodeSetThisDeviceOnly:
            return "WhenPasscodeSetThisDeviceOnly"
        case .whenUnlockedThisDeviceOnly:
            return "WhenUnlockedThisDeviceOnly"
        case .afterFirstUnlockThisDeviceOnly:
            return "AfterFirstUnlockThisDeviceOnly"
        #if !targetEnvironment(macCatalyst)
        case .alwaysThisDeviceOnly:
            return "AlwaysThisDeviceOnly"
        #endif
        }
    }
}

extension CFError {
    var error: NSError {
        let domain = CFErrorGetDomain(self) as String
        let code = CFErrorGetCode(self)
        let userInfo = CFErrorCopyUserInfo(self) as! [String: Any]

        return NSError(domain: domain, code: code, userInfo: userInfo)
    }
}

public enum Status: OSStatus, Error {
    case success = 0
    case unimplemented = -4
    case diskFull = -34
    case io = -36
    case opWr = -49
    case param = -50
    case wrPerm = -61
    case allocate = -108
    case userCanceled = -128
    case badReq = -909
    case internalComponent = -2070
    case notAvailable = -25_291
    case readOnly = -25_292
    case authFailed = -25_293
    case noSuchKeychain = -25_294
    case invalidKeychain = -25_295
    case duplicateKeychain = -25_296
    case duplicateCallback = -25_297
    case invalidCallback = -25_298
    case duplicateItem = -25_299
    case itemNotFound = -25_300
    case bufferTooSmall = -25_301
    case dataTooLarge = -25_302
    case noSuchAttr = -25_303
    case invalidItemRef = -25_304
    case invalidSearchRef = -25_305
    case noSuchClass = -25_306
    case noDefaultKeychain = -25_307
    case interactionNotAllowed = -25_308
    case readOnlyAttr = -25_309
    case wrongSecVersion = -25_310
    case keySizeNotAllowed = -25_311
    case noStorageModule = -25_312
    case noCertificateModule = -25_313
    case noPolicyModule = -25_314
    case interactionRequired = -25_315
    case dataNotAvailable = -25_316
    case dataNotModifiable = -25_317
    case createChainFailed = -25_318
    case invalidPrefsDomain = -25_319
    case inDarkWake = -25_320
    case aclNotSimple = -25_240
    case policyNotFound = -25_241
    case invalidTrustSetting = -25_242
    case noAccessForItem = -25_243
    case invalidOwnerEdit = -25_244
    case trustNotAvailable = -25_245
    case unsupportedFormat = -25_256
    case unknownFormat = -25_257
    case keyIsSensitive = -25_258
    case multiplePrivKeys = -25_259
    case passphraseRequired = -25_260
    case invalidPasswordRef = -25_261
    case invalidTrustSettings = -25_262
    case noTrustSettings = -25_263
    case pkcs12VerifyFailure = -25_264
    case invalidCertificate = -26_265
    case notSigner = -26_267
    case policyDenied = -26_270
    case invalidKey = -26_274
    case decode = -26_275
    case `internal` = -26_276
    case unsupportedAlgorithm = -26_268
    case unsupportedOperation = -26_271
    case unsupportedPadding = -26_273
    case itemInvalidKey = -34_000
    case itemInvalidKeyType = -34_001
    case itemInvalidValue = -34_002
    case itemClassMissing = -34_003
    case itemMatchUnsupported = -34_004
    case useItemListUnsupported = -34_005
    case useKeychainUnsupported = -34_006
    case useKeychainListUnsupported = -34_007
    case returnDataUnsupported = -34_008
    case returnAttributesUnsupported = -34_009
    case returnRefUnsupported = -34_010
    case returnPersitentRefUnsupported = -34_011
    case valueRefUnsupported = -34_012
    case valuePersistentRefUnsupported = -34_013
    case returnMissingPointer = -34_014
    case matchLimitUnsupported = -34_015
    case itemIllegalQuery = -34_016
    case waitForCallback = -34_017
    case missingEntitlement = -34_018
    case upgradePending = -34_019
    case mpSignatureInvalid = -25_327
    case otrTooOld = -25_328
    case otrIDTooNew = -25_329
    case serviceNotAvailable = -67_585
    case insufficientClientID = -67_586
    case deviceReset = -67_587
    case deviceFailed = -67_588
    case appleAddAppACLSubject = -67_589
    case applePublicKeyIncomplete = -67_590
    case appleSignatureMismatch = -67_591
    case appleInvalidKeyStartDate = -67_592
    case appleInvalidKeyEndDate = -67_593
    case conversionError = -67_594
    case appleSSLv2Rollback = -67_595
    case quotaExceeded = -67_596
    case fileTooBig = -67_597
    case invalidDatabaseBlob = -67_598
    case invalidKeyBlob = -67_599
    case incompatibleDatabaseBlob = -67_600
    case incompatibleKeyBlob = -67_601
    case hostNameMismatch = -67_602
    case unknownCriticalExtensionFlag = -67_603
    case noBasicConstraints = -67_604
    case noBasicConstraintsCA = -67_605
    case invalidAuthorityKeyID = -67_606
    case invalidSubjectKeyID = -67_607
    case invalidKeyUsageForPolicy = -67_608
    case invalidExtendedKeyUsage = -67_609
    case invalidIDLinkage = -67_610
    case pathLengthConstraintExceeded = -67_611
    case invalidRoot = -67_612
    case crlExpired = -67_613
    case crlNotValidYet = -67_614
    case crlNotFound = -67_615
    case crlServerDown = -67_616
    case crlBadURI = -67_617
    case unknownCertExtension = -67_618
    case unknownCRLExtension = -67_619
    case crlNotTrusted = -67_620
    case crlPolicyFailed = -67_621
    case idpFailure = -67_622
    case smimeEmailAddressesNotFound = -67_623
    case smimeBadExtendedKeyUsage = -67_624
    case smimeBadKeyUsage = -67_625
    case smimeKeyUsageNotCritical = -67_626
    case smimeNoEmailAddress = -67_627
    case smimeSubjAltNameNotCritical = -67_628
    case sslBadExtendedKeyUsage = -67_629
    case ocspBadResponse = -67_630
    case ocspBadRequest = -67_631
    case ocspUnavailable = -67_632
    case ocspStatusUnrecognized = -67_633
    case endOfData = -67_634
    case incompleteCertRevocationCheck = -67_635
    case networkFailure = -67_636
    case ocspNotTrustedToAnchor = -67_637
    case recordModified = -67_638
    case ocspSignatureError = -67_639
    case ocspNoSigner = -67_640
    case ocspResponderMalformedReq = -67_641
    case ocspResponderInternalError = -67_642
    case ocspResponderTryLater = -67_643
    case ocspResponderSignatureRequired = -67_644
    case ocspResponderUnauthorized = -67_645
    case ocspResponseNonceMismatch = -67_646
    case codeSigningBadCertChainLength = -67_647
    case codeSigningNoBasicConstraints = -67_648
    case codeSigningBadPathLengthConstraint = -67_649
    case codeSigningNoExtendedKeyUsage = -67_650
    case codeSigningDevelopment = -67_651
    case resourceSignBadCertChainLength = -67_652
    case resourceSignBadExtKeyUsage = -67_653
    case trustSettingDeny = -67_654
    case invalidSubjectName = -67_655
    case unknownQualifiedCertStatement = -67_656
    case mobileMeRequestQueued = -67_657
    case mobileMeRequestRedirected = -67_658
    case mobileMeServerError = -67_659
    case mobileMeServerNotAvailable = -67_660
    case mobileMeServerAlreadyExists = -67_661
    case mobileMeServerServiceErr = -67_662
    case mobileMeRequestAlreadyPending = -67_663
    case mobileMeNoRequestPending = -67_664
    case mobileMeCSRVerifyFailure = -67_665
    case mobileMeFailedConsistencyCheck = -67_666
    case notInitialized = -67_667
    case invalidHandleUsage = -67_668
    case pvcReferentNotFound = -67_669
    case functionIntegrityFail = -67_670
    case internalError = -67_671
    case memoryError = -67_672
    case invalidData = -67_673
    case mdsError = -67_674
    case invalidPointer = -67_675
    case selfCheckFailed = -67_676
    case functionFailed = -67_677
    case moduleManifestVerifyFailed = -67_678
    case invalidGUID = -67_679
    case invalidHandle = -67_680
    case invalidDBList = -67_681
    case invalidPassthroughID = -67_682
    case invalidNetworkAddress = -67_683
    case crlAlreadySigned = -67_684
    case invalidNumberOfFields = -67_685
    case verificationFailure = -67_686
    case unknownTag = -67_687
    case invalidSignature = -67_688
    case invalidName = -67_689
    case invalidCertificateRef = -67_690
    case invalidCertificateGroup = -67_691
    case tagNotFound = -67_692
    case invalidQuery = -67_693
    case invalidValue = -67_694
    case callbackFailed = -67_695
    case aclDeleteFailed = -67_696
    case aclReplaceFailed = -67_697
    case aclAddFailed = -67_698
    case aclChangeFailed = -67_699
    case invalidAccessCredentials = -67_700
    case invalidRecord = -67_701
    case invalidACL = -67_702
    case invalidSampleValue = -67_703
    case incompatibleVersion = -67_704
    case privilegeNotGranted = -67_705
    case invalidScope = -67_706
    case pvcAlreadyConfigured = -67_707
    case invalidPVC = -67_708
    case emmLoadFailed = -67_709
    case emmUnloadFailed = -67_710
    case addinLoadFailed = -67_711
    case invalidKeyRef = -67_712
    case invalidKeyHierarchy = -67_713
    case addinUnloadFailed = -67_714
    case libraryReferenceNotFound = -67_715
    case invalidAddinFunctionTable = -67_716
    case invalidServiceMask = -67_717
    case moduleNotLoaded = -67_718
    case invalidSubServiceID = -67_719
    case attributeNotInContext = -67_720
    case moduleManagerInitializeFailed = -67_721
    case moduleManagerNotFound = -67_722
    case eventNotificationCallbackNotFound = -67_723
    case inputLengthError = -67_724
    case outputLengthError = -67_725
    case privilegeNotSupported = -67_726
    case deviceError = -67_727
    case attachHandleBusy = -67_728
    case notLoggedIn = -67_729
    case algorithmMismatch = -67_730
    case keyUsageIncorrect = -67_731
    case keyBlobTypeIncorrect = -67_732
    case keyHeaderInconsistent = -67_733
    case unsupportedKeyFormat = -67_734
    case unsupportedKeySize = -67_735
    case invalidKeyUsageMask = -67_736
    case unsupportedKeyUsageMask = -67_737
    case invalidKeyAttributeMask = -67_738
    case unsupportedKeyAttributeMask = -67_739
    case invalidKeyLabel = -67_740
    case unsupportedKeyLabel = -67_741
    case invalidKeyFormat = -67_742
    case unsupportedVectorOfBuffers = -67_743
    case invalidInputVector = -67_744
    case invalidOutputVector = -67_745
    case invalidContext = -67_746
    case invalidAlgorithm = -67_747
    case invalidAttributeKey = -67_748
    case missingAttributeKey = -67_749
    case invalidAttributeInitVector = -67_750
    case missingAttributeInitVector = -67_751
    case invalidAttributeSalt = -67_752
    case missingAttributeSalt = -67_753
    case invalidAttributePadding = -67_754
    case missingAttributePadding = -67_755
    case invalidAttributeRandom = -67_756
    case missingAttributeRandom = -67_757
    case invalidAttributeSeed = -67_758
    case missingAttributeSeed = -67_759
    case invalidAttributePassphrase = -67_760
    case missingAttributePassphrase = -67_761
    case invalidAttributeKeyLength = -67_762
    case missingAttributeKeyLength = -67_763
    case invalidAttributeBlockSize = -67_764
    case missingAttributeBlockSize = -67_765
    case invalidAttributeOutputSize = -67_766
    case missingAttributeOutputSize = -67_767
    case invalidAttributeRounds = -67_768
    case missingAttributeRounds = -67_769
    case invalidAlgorithmParms = -67_770
    case missingAlgorithmParms = -67_771
    case invalidAttributeLabel = -67_772
    case missingAttributeLabel = -67_773
    case invalidAttributeKeyType = -67_774
    case missingAttributeKeyType = -67_775
    case invalidAttributeMode = -67_776
    case missingAttributeMode = -67_777
    case invalidAttributeEffectiveBits = -67_778
    case missingAttributeEffectiveBits = -67_779
    case invalidAttributeStartDate = -67_780
    case missingAttributeStartDate = -67_781
    case invalidAttributeEndDate = -67_782
    case missingAttributeEndDate = -67_783
    case invalidAttributeVersion = -67_784
    case missingAttributeVersion = -67_785
    case invalidAttributePrime = -67_786
    case missingAttributePrime = -67_787
    case invalidAttributeBase = -67_788
    case missingAttributeBase = -67_789
    case invalidAttributeSubprime = -67_790
    case missingAttributeSubprime = -67_791
    case invalidAttributeIterationCount = -67_792
    case missingAttributeIterationCount = -67_793
    case invalidAttributeDLDBHandle = -67_794
    case missingAttributeDLDBHandle = -67_795
    case invalidAttributeAccessCredentials = -67_796
    case missingAttributeAccessCredentials = -67_797
    case invalidAttributePublicKeyFormat = -67_798
    case missingAttributePublicKeyFormat = -67_799
    case invalidAttributePrivateKeyFormat = -67_800
    case missingAttributePrivateKeyFormat = -67_801
    case invalidAttributeSymmetricKeyFormat = -67_802
    case missingAttributeSymmetricKeyFormat = -67_803
    case invalidAttributeWrappedKeyFormat = -67_804
    case missingAttributeWrappedKeyFormat = -67_805
    case stagedOperationInProgress = -67_806
    case stagedOperationNotStarted = -67_807
    case verifyFailed = -67_808
    case querySizeUnknown = -67_809
    case blockSizeMismatch = -67_810
    case publicKeyInconsistent = -67_811
    case deviceVerifyFailed = -67_812
    case invalidLoginName = -67_813
    case alreadyLoggedIn = -67_814
    case invalidDigestAlgorithm = -67_815
    case invalidCRLGroup = -67_816
    case certificateCannotOperate = -67_817
    case certificateExpired = -67_818
    case certificateNotValidYet = -67_819
    case certificateRevoked = -67_820
    case certificateSuspended = -67_821
    case insufficientCredentials = -67_822
    case invalidAction = -67_823
    case invalidAuthority = -67_824
    case verifyActionFailed = -67_825
    case invalidCertAuthority = -67_826
    case invaldCRLAuthority = -67_827
    case invalidCRLEncoding = -67_828
    case invalidCRLType = -67_829
    case invalidCRL = -67_830
    case invalidFormType = -67_831
    case invalidID = -67_832
    case invalidIdentifier = -67_833
    case invalidIndex = -67_834
    case invalidPolicyIdentifiers = -67_835
    case invalidTimeString = -67_836
    case invalidReason = -67_837
    case invalidRequestInputs = -67_838
    case invalidResponseVector = -67_839
    case invalidStopOnPolicy = -67_840
    case invalidTuple = -67_841
    case multipleValuesUnsupported = -67_842
    case notTrusted = -67_843
    case noDefaultAuthority = -67_844
    case rejectedForm = -67_845
    case requestLost = -67_846
    case requestRejected = -67_847
    case unsupportedAddressType = -67_848
    case unsupportedService = -67_849
    case invalidTupleGroup = -67_850
    case invalidBaseACLs = -67_851
    case invalidTupleCredendtials = -67_852
    case invalidEncoding = -67_853
    case invalidValidityPeriod = -67_854
    case invalidRequestor = -67_855
    case requestDescriptor = -67_856
    case invalidBundleInfo = -67_857
    case invalidCRLIndex = -67_858
    case noFieldValues = -67_859
    case unsupportedFieldFormat = -67_860
    case unsupportedIndexInfo = -67_861
    case unsupportedLocality = -67_862
    case unsupportedNumAttributes = -67_863
    case unsupportedNumIndexes = -67_864
    case unsupportedNumRecordTypes = -67_865
    case fieldSpecifiedMultiple = -67_866
    case incompatibleFieldFormat = -67_867
    case invalidParsingModule = -67_868
    case databaseLocked = -67_869
    case datastoreIsOpen = -67_870
    case missingValue = -67_871
    case unsupportedQueryLimits = -67_872
    case unsupportedNumSelectionPreds = -67_873
    case unsupportedOperator = -67_874
    case invalidDBLocation = -67_875
    case invalidAccessRequest = -67_876
    case invalidIndexInfo = -67_877
    case invalidNewOwner = -67_878
    case invalidModifyMode = -67_879
    case missingRequiredExtension = -67_880
    case extendedKeyUsageNotCritical = -67_881
    case timestampMissing = -67_882
    case timestampInvalid = -67_883
    case timestampNotTrusted = -67_884
    case timestampServiceNotAvailable = -67_885
    case timestampBadAlg = -67_886
    case timestampBadRequest = -67_887
    case timestampBadDataFormat = -67_888
    case timestampTimeNotAvailable = -67_889
    case timestampUnacceptedPolicy = -67_890
    case timestampUnacceptedExtension = -67_891
    case timestampAddInfoNotAvailable = -67_892
    case timestampSystemFailure = -67_893
    case signingTimeMissing = -67_894
    case timestampRejection = -67_895
    case timestampWaiting = -67_896
    case timestampRevocationWarning = -67_897
    case timestampRevocationNotification = -67_898
    case unexpectedError = -99_999
}

extension Status: RawRepresentable, CustomStringConvertible {
    public init(status: OSStatus) {
        if let mappedStatus = Status(rawValue: status) {
            self = mappedStatus
        } else {
            self = .unexpectedError
        }
    }

    public var description: String {
        switch self {
        case .success:
            return "No error."
        case .unimplemented:
            return "Function or operation not implemented."
        case .diskFull:
            return "The disk is full."
        case .io:
            return "I/O error (bummers)"
        case .opWr:
            return "file already open with with write permission"
        case .param:
            return "One or more parameters passed to a function were not valid."
        case .wrPerm:
            return "write permissions error"
        case .allocate:
            return "Failed to allocate memory."
        case .userCanceled:
            return "User canceled the operation."
        case .badReq:
            return "Bad parameter or invalid state for operation."
        case .internalComponent:
            return ""
        case .notAvailable:
            return "No keychain is available. You may need to restart your computer."
        case .readOnly:
            return "This keychain cannot be modified."
        case .authFailed:
            return "The user name or passphrase you entered is not correct."
        case .noSuchKeychain:
            return "The specified keychain could not be found."
        case .invalidKeychain:
            return "The specified keychain is not a valid keychain file."
        case .duplicateKeychain:
            return "A keychain with the same name already exists."
        case .duplicateCallback:
            return "The specified callback function is already installed."
        case .invalidCallback:
            return "The specified callback function is not valid."
        case .duplicateItem:
            return "The specified item already exists in the keychain."
        case .itemNotFound:
            return "The specified item could not be found in the keychain."
        case .bufferTooSmall:
            return "There is not enough memory available to use the specified item."
        case .dataTooLarge:
            return "This item contains information which is too large or in a format that cannot be displayed."
        case .noSuchAttr:
            return "The specified attribute does not exist."
        case .invalidItemRef:
            return "The specified item is no longer valid. It may have been deleted from the keychain."
        case .invalidSearchRef:
            return "Unable to search the current keychain."
        case .noSuchClass:
            return "The specified item does not appear to be a valid keychain item."
        case .noDefaultKeychain:
            return "A default keychain could not be found."
        case .interactionNotAllowed:
            return "User interaction is not allowed."
        case .readOnlyAttr:
            return "The specified attribute could not be modified."
        case .wrongSecVersion:
            return "This keychain was created by a different version of the system software and cannot be opened."
        case .keySizeNotAllowed:
            return "This item specifies a key size which is too large."
        case .noStorageModule:
            return "A required component (data storage module) could not be loaded. You may need to restart your computer."
        case .noCertificateModule:
            return "A required component (certificate module) could not be loaded. You may need to restart your computer."
        case .noPolicyModule:
            return "A required component (policy module) could not be loaded. You may need to restart your computer."
        case .interactionRequired:
            return "User interaction is required, but is currently not allowed."
        case .dataNotAvailable:
            return "The contents of this item cannot be retrieved."
        case .dataNotModifiable:
            return "The contents of this item cannot be modified."
        case .createChainFailed:
            return "One or more certificates required to validate this certificate cannot be found."
        case .invalidPrefsDomain:
            return "The specified preferences domain is not valid."
        case .inDarkWake:
            return "In dark wake, no UI possible"
        case .aclNotSimple:
            return "The specified access control list is not in standard (simple) form."
        case .policyNotFound:
            return "The specified policy cannot be found."
        case .invalidTrustSetting:
            return "The specified trust setting is invalid."
        case .noAccessForItem:
            return "The specified item has no access control."
        case .invalidOwnerEdit:
            return "Invalid attempt to change the owner of this item."
        case .trustNotAvailable:
            return "No trust results are available."
        case .unsupportedFormat:
            return "Import/Export format unsupported."
        case .unknownFormat:
            return "Unknown format in import."
        case .keyIsSensitive:
            return "Key material must be wrapped for export."
        case .multiplePrivKeys:
            return "An attempt was made to import multiple private keys."
        case .passphraseRequired:
            return "Passphrase is required for import/export."
        case .invalidPasswordRef:
            return "The password reference was invalid."
        case .invalidTrustSettings:
            return "The Trust Settings Record was corrupted."
        case .noTrustSettings:
            return "No Trust Settings were found."
        case .pkcs12VerifyFailure:
            return "MAC verification failed during PKCS12 import (wrong password?)"
        case .invalidCertificate:
            return "This certificate could not be decoded."
        case .notSigner:
            return "A certificate was not signed by its proposed parent."
        case .policyDenied:
            return "The certificate chain was not trusted due to a policy not accepting it."
        case .invalidKey:
            return "The provided key material was not valid."
        case .decode:
            return "Unable to decode the provided data."
        case .internal:
            return "An internal error occurred in the Security framework."
        case .unsupportedAlgorithm:
            return "An unsupported algorithm was encountered."
        case .unsupportedOperation:
            return "The operation you requested is not supported by this key."
        case .unsupportedPadding:
            return "The padding you requested is not supported."
        case .itemInvalidKey:
            return "A string key in dictionary is not one of the supported keys."
        case .itemInvalidKeyType:
            return "A key in a dictionary is neither a CFStringRef nor a CFNumberRef."
        case .itemInvalidValue:
            return "A value in a dictionary is an invalid (or unsupported) CF type."
        case .itemClassMissing:
            return "No kSecItemClass key was specified in a dictionary."
        case .itemMatchUnsupported:
            return "The caller passed one or more kSecMatch keys to a function which does not support matches."
        case .useItemListUnsupported:
            return "The caller passed in a kSecUseItemList key to a function which does not support it."
        case .useKeychainUnsupported:
            return "The caller passed in a kSecUseKeychain key to a function which does not support it."
        case .useKeychainListUnsupported:
            return "The caller passed in a kSecUseKeychainList key to a function which does not support it."
        case .returnDataUnsupported:
            return "The caller passed in a kSecReturnData key to a function which does not support it."
        case .returnAttributesUnsupported:
            return "The caller passed in a kSecReturnAttributes key to a function which does not support it."
        case .returnRefUnsupported:
            return "The caller passed in a kSecReturnRef key to a function which does not support it."
        case .returnPersitentRefUnsupported:
            return "The caller passed in a kSecReturnPersistentRef key to a function which does not support it."
        case .valueRefUnsupported:
            return "The caller passed in a kSecValueRef key to a function which does not support it."
        case .valuePersistentRefUnsupported:
            return "The caller passed in a kSecValuePersistentRef key to a function which does not support it."
        case .returnMissingPointer:
            return "The caller passed asked for something to be returned but did not pass in a result pointer."
        case .matchLimitUnsupported:
            return "The caller passed in a kSecMatchLimit key to a call which does not support limits."
        case .itemIllegalQuery:
            return "The caller passed in a query which contained too many keys."
        case .waitForCallback:
            return "This operation is incomplete, until the callback is invoked (not an error)."
        case .missingEntitlement:
            return "Internal error when a required entitlement isn't present, client has neither application-identifier nor keychain-access-groups entitlements."
        case .upgradePending:
            return "Error returned if keychain database needs a schema migration but the device is locked, clients should wait for a device unlock notification and retry the command."
        case .mpSignatureInvalid:
            return "Signature invalid on MP message"
        case .otrTooOld:
            return "Message is too old to use"
        case .otrIDTooNew:
            return "Key ID is too new to use! Message from the future?"
        case .serviceNotAvailable:
            return "The required service is not available."
        case .insufficientClientID:
            return "The client ID is not correct."
        case .deviceReset:
            return "A device reset has occurred."
        case .deviceFailed:
            return "A device failure has occurred."
        case .appleAddAppACLSubject:
            return "Adding an application ACL subject failed."
        case .applePublicKeyIncomplete:
            return "The public key is incomplete."
        case .appleSignatureMismatch:
            return "A signature mismatch has occurred."
        case .appleInvalidKeyStartDate:
            return "The specified key has an invalid start date."
        case .appleInvalidKeyEndDate:
            return "The specified key has an invalid end date."
        case .conversionError:
            return "A conversion error has occurred."
        case .appleSSLv2Rollback:
            return "A SSLv2 rollback error has occurred."
        case .quotaExceeded:
            return "The quota was exceeded."
        case .fileTooBig:
            return "The file is too big."
        case .invalidDatabaseBlob:
            return "The specified database has an invalid blob."
        case .invalidKeyBlob:
            return "The specified database has an invalid key blob."
        case .incompatibleDatabaseBlob:
            return "The specified database has an incompatible blob."
        case .incompatibleKeyBlob:
            return "The specified database has an incompatible key blob."
        case .hostNameMismatch:
            return "A host name mismatch has occurred."
        case .unknownCriticalExtensionFlag:
            return "There is an unknown critical extension flag."
        case .noBasicConstraints:
            return "No basic constraints were found."
        case .noBasicConstraintsCA:
            return "No basic CA constraints were found."
        case .invalidAuthorityKeyID:
            return "The authority key ID is not valid."
        case .invalidSubjectKeyID:
            return "The subject key ID is not valid."
        case .invalidKeyUsageForPolicy:
            return "The key usage is not valid for the specified policy."
        case .invalidExtendedKeyUsage:
            return "The extended key usage is not valid."
        case .invalidIDLinkage:
            return "The ID linkage is not valid."
        case .pathLengthConstraintExceeded:
            return "The path length constraint was exceeded."
        case .invalidRoot:
            return "The root or anchor certificate is not valid."
        case .crlExpired:
            return "The CRL has expired."
        case .crlNotValidYet:
            return "The CRL is not yet valid."
        case .crlNotFound:
            return "The CRL was not found."
        case .crlServerDown:
            return "The CRL server is down."
        case .crlBadURI:
            return "The CRL has a bad Uniform Resource Identifier."
        case .unknownCertExtension:
            return "An unknown certificate extension was encountered."
        case .unknownCRLExtension:
            return "An unknown CRL extension was encountered."
        case .crlNotTrusted:
            return "The CRL is not trusted."
        case .crlPolicyFailed:
            return "The CRL policy failed."
        case .idpFailure:
            return "The issuing distribution point was not valid."
        case .smimeEmailAddressesNotFound:
            return "An email address mismatch was encountered."
        case .smimeBadExtendedKeyUsage:
            return "The appropriate extended key usage for SMIME was not found."
        case .smimeBadKeyUsage:
            return "The key usage is not compatible with SMIME."
        case .smimeKeyUsageNotCritical:
            return "The key usage extension is not marked as critical."
        case .smimeNoEmailAddress:
            return "No email address was found in the certificate."
        case .smimeSubjAltNameNotCritical:
            return "The subject alternative name extension is not marked as critical."
        case .sslBadExtendedKeyUsage:
            return "The appropriate extended key usage for SSL was not found."
        case .ocspBadResponse:
            return "The OCSP response was incorrect or could not be parsed."
        case .ocspBadRequest:
            return "The OCSP request was incorrect or could not be parsed."
        case .ocspUnavailable:
            return "OCSP service is unavailable."
        case .ocspStatusUnrecognized:
            return "The OCSP server did not recognize this certificate."
        case .endOfData:
            return "An end-of-data was detected."
        case .incompleteCertRevocationCheck:
            return "An incomplete certificate revocation check occurred."
        case .networkFailure:
            return "A network failure occurred."
        case .ocspNotTrustedToAnchor:
            return "The OCSP response was not trusted to a root or anchor certificate."
        case .recordModified:
            return "The record was modified."
        case .ocspSignatureError:
            return "The OCSP response had an invalid signature."
        case .ocspNoSigner:
            return "The OCSP response had no signer."
        case .ocspResponderMalformedReq:
            return "The OCSP responder was given a malformed request."
        case .ocspResponderInternalError:
            return "The OCSP responder encountered an internal error."
        case .ocspResponderTryLater:
            return "The OCSP responder is busy, try again later."
        case .ocspResponderSignatureRequired:
            return "The OCSP responder requires a signature."
        case .ocspResponderUnauthorized:
            return "The OCSP responder rejected this request as unauthorized."
        case .ocspResponseNonceMismatch:
            return "The OCSP response nonce did not match the request."
        case .codeSigningBadCertChainLength:
            return "Code signing encountered an incorrect certificate chain length."
        case .codeSigningNoBasicConstraints:
            return "Code signing found no basic constraints."
        case .codeSigningBadPathLengthConstraint:
            return "Code signing encountered an incorrect path length constraint."
        case .codeSigningNoExtendedKeyUsage:
            return "Code signing found no extended key usage."
        case .codeSigningDevelopment:
            return "Code signing indicated use of a development-only certificate."
        case .resourceSignBadCertChainLength:
            return "Resource signing has encountered an incorrect certificate chain length."
        case .resourceSignBadExtKeyUsage:
            return "Resource signing has encountered an error in the extended key usage."
        case .trustSettingDeny:
            return "The trust setting for this policy was set to Deny."
        case .invalidSubjectName:
            return "An invalid certificate subject name was encountered."
        case .unknownQualifiedCertStatement:
            return "An unknown qualified certificate statement was encountered."
        case .mobileMeRequestQueued:
            return "The MobileMe request will be sent during the next connection."
        case .mobileMeRequestRedirected:
            return "The MobileMe request was redirected."
        case .mobileMeServerError:
            return "A MobileMe server error occurred."
        case .mobileMeServerNotAvailable:
            return "The MobileMe server is not available."
        case .mobileMeServerAlreadyExists:
            return "The MobileMe server reported that the item already exists."
        case .mobileMeServerServiceErr:
            return "A MobileMe service error has occurred."
        case .mobileMeRequestAlreadyPending:
            return "A MobileMe request is already pending."
        case .mobileMeNoRequestPending:
            return "MobileMe has no request pending."
        case .mobileMeCSRVerifyFailure:
            return "A MobileMe CSR verification failure has occurred."
        case .mobileMeFailedConsistencyCheck:
            return "MobileMe has found a failed consistency check."
        case .notInitialized:
            return "A function was called without initializing CSSM."
        case .invalidHandleUsage:
            return "The CSSM handle does not match with the service type."
        case .pvcReferentNotFound:
            return "A reference to the calling module was not found in the list of authorized callers."
        case .functionIntegrityFail:
            return "A function address was not within the verified module."
        case .internalError:
            return "An internal error has occurred."
        case .memoryError:
            return "A memory error has occurred."
        case .invalidData:
            return "Invalid data was encountered."
        case .mdsError:
            return "A Module Directory Service error has occurred."
        case .invalidPointer:
            return "An invalid pointer was encountered."
        case .selfCheckFailed:
            return "Self-check has failed."
        case .functionFailed:
            return "A function has failed."
        case .moduleManifestVerifyFailed:
            return "A module manifest verification failure has occurred."
        case .invalidGUID:
            return "An invalid GUID was encountered."
        case .invalidHandle:
            return "An invalid handle was encountered."
        case .invalidDBList:
            return "An invalid DB list was encountered."
        case .invalidPassthroughID:
            return "An invalid passthrough ID was encountered."
        case .invalidNetworkAddress:
            return "An invalid network address was encountered."
        case .crlAlreadySigned:
            return "The certificate revocation list is already signed."
        case .invalidNumberOfFields:
            return "An invalid number of fields were encountered."
        case .verificationFailure:
            return "A verification failure occurred."
        case .unknownTag:
            return "An unknown tag was encountered."
        case .invalidSignature:
            return "An invalid signature was encountered."
        case .invalidName:
            return "An invalid name was encountered."
        case .invalidCertificateRef:
            return "An invalid certificate reference was encountered."
        case .invalidCertificateGroup:
            return "An invalid certificate group was encountered."
        case .tagNotFound:
            return "The specified tag was not found."
        case .invalidQuery:
            return "The specified query was not valid."
        case .invalidValue:
            return "An invalid value was detected."
        case .callbackFailed:
            return "A callback has failed."
        case .aclDeleteFailed:
            return "An ACL delete operation has failed."
        case .aclReplaceFailed:
            return "An ACL replace operation has failed."
        case .aclAddFailed:
            return "An ACL add operation has failed."
        case .aclChangeFailed:
            return "An ACL change operation has failed."
        case .invalidAccessCredentials:
            return "Invalid access credentials were encountered."
        case .invalidRecord:
            return "An invalid record was encountered."
        case .invalidACL:
            return "An invalid ACL was encountered."
        case .invalidSampleValue:
            return "An invalid sample value was encountered."
        case .incompatibleVersion:
            return "An incompatible version was encountered."
        case .privilegeNotGranted:
            return "The privilege was not granted."
        case .invalidScope:
            return "An invalid scope was encountered."
        case .pvcAlreadyConfigured:
            return "The PVC is already configured."
        case .invalidPVC:
            return "An invalid PVC was encountered."
        case .emmLoadFailed:
            return "The EMM load has failed."
        case .emmUnloadFailed:
            return "The EMM unload has failed."
        case .addinLoadFailed:
            return "The add-in load operation has failed."
        case .invalidKeyRef:
            return "An invalid key was encountered."
        case .invalidKeyHierarchy:
            return "An invalid key hierarchy was encountered."
        case .addinUnloadFailed:
            return "The add-in unload operation has failed."
        case .libraryReferenceNotFound:
            return "A library reference was not found."
        case .invalidAddinFunctionTable:
            return "An invalid add-in function table was encountered."
        case .invalidServiceMask:
            return "An invalid service mask was encountered."
        case .moduleNotLoaded:
            return "A module was not loaded."
        case .invalidSubServiceID:
            return "An invalid subservice ID was encountered."
        case .attributeNotInContext:
            return "An attribute was not in the context."
        case .moduleManagerInitializeFailed:
            return "A module failed to initialize."
        case .moduleManagerNotFound:
            return "A module was not found."
        case .eventNotificationCallbackNotFound:
            return "An event notification callback was not found."
        case .inputLengthError:
            return "An input length error was encountered."
        case .outputLengthError:
            return "An output length error was encountered."
        case .privilegeNotSupported:
            return "The privilege is not supported."
        case .deviceError:
            return "A device error was encountered."
        case .attachHandleBusy:
            return "The CSP handle was busy."
        case .notLoggedIn:
            return "You are not logged in."
        case .algorithmMismatch:
            return "An algorithm mismatch was encountered."
        case .keyUsageIncorrect:
            return "The key usage is incorrect."
        case .keyBlobTypeIncorrect:
            return "The key blob type is incorrect."
        case .keyHeaderInconsistent:
            return "The key header is inconsistent."
        case .unsupportedKeyFormat:
            return "The key header format is not supported."
        case .unsupportedKeySize:
            return "The key size is not supported."
        case .invalidKeyUsageMask:
            return "The key usage mask is not valid."
        case .unsupportedKeyUsageMask:
            return "The key usage mask is not supported."
        case .invalidKeyAttributeMask:
            return "The key attribute mask is not valid."
        case .unsupportedKeyAttributeMask:
            return "The key attribute mask is not supported."
        case .invalidKeyLabel:
            return "The key label is not valid."
        case .unsupportedKeyLabel:
            return "The key label is not supported."
        case .invalidKeyFormat:
            return "The key format is not valid."
        case .unsupportedVectorOfBuffers:
            return "The vector of buffers is not supported."
        case .invalidInputVector:
            return "The input vector is not valid."
        case .invalidOutputVector:
            return "The output vector is not valid."
        case .invalidContext:
            return "An invalid context was encountered."
        case .invalidAlgorithm:
            return "An invalid algorithm was encountered."
        case .invalidAttributeKey:
            return "A key attribute was not valid."
        case .missingAttributeKey:
            return "A key attribute was missing."
        case .invalidAttributeInitVector:
            return "An init vector attribute was not valid."
        case .missingAttributeInitVector:
            return "An init vector attribute was missing."
        case .invalidAttributeSalt:
            return "A salt attribute was not valid."
        case .missingAttributeSalt:
            return "A salt attribute was missing."
        case .invalidAttributePadding:
            return "A padding attribute was not valid."
        case .missingAttributePadding:
            return "A padding attribute was missing."
        case .invalidAttributeRandom:
            return "A random number attribute was not valid."
        case .missingAttributeRandom:
            return "A random number attribute was missing."
        case .invalidAttributeSeed:
            return "A seed attribute was not valid."
        case .missingAttributeSeed:
            return "A seed attribute was missing."
        case .invalidAttributePassphrase:
            return "A passphrase attribute was not valid."
        case .missingAttributePassphrase:
            return "A passphrase attribute was missing."
        case .invalidAttributeKeyLength:
            return "A key length attribute was not valid."
        case .missingAttributeKeyLength:
            return "A key length attribute was missing."
        case .invalidAttributeBlockSize:
            return "A block size attribute was not valid."
        case .missingAttributeBlockSize:
            return "A block size attribute was missing."
        case .invalidAttributeOutputSize:
            return "An output size attribute was not valid."
        case .missingAttributeOutputSize:
            return "An output size attribute was missing."
        case .invalidAttributeRounds:
            return "The number of rounds attribute was not valid."
        case .missingAttributeRounds:
            return "The number of rounds attribute was missing."
        case .invalidAlgorithmParms:
            return "An algorithm parameters attribute was not valid."
        case .missingAlgorithmParms:
            return "An algorithm parameters attribute was missing."
        case .invalidAttributeLabel:
            return "A label attribute was not valid."
        case .missingAttributeLabel:
            return "A label attribute was missing."
        case .invalidAttributeKeyType:
            return "A key type attribute was not valid."
        case .missingAttributeKeyType:
            return "A key type attribute was missing."
        case .invalidAttributeMode:
            return "A mode attribute was not valid."
        case .missingAttributeMode:
            return "A mode attribute was missing."
        case .invalidAttributeEffectiveBits:
            return "An effective bits attribute was not valid."
        case .missingAttributeEffectiveBits:
            return "An effective bits attribute was missing."
        case .invalidAttributeStartDate:
            return "A start date attribute was not valid."
        case .missingAttributeStartDate:
            return "A start date attribute was missing."
        case .invalidAttributeEndDate:
            return "An end date attribute was not valid."
        case .missingAttributeEndDate:
            return "An end date attribute was missing."
        case .invalidAttributeVersion:
            return "A version attribute was not valid."
        case .missingAttributeVersion:
            return "A version attribute was missing."
        case .invalidAttributePrime:
            return "A prime attribute was not valid."
        case .missingAttributePrime:
            return "A prime attribute was missing."
        case .invalidAttributeBase:
            return "A base attribute was not valid."
        case .missingAttributeBase:
            return "A base attribute was missing."
        case .invalidAttributeSubprime:
            return "A subprime attribute was not valid."
        case .missingAttributeSubprime:
            return "A subprime attribute was missing."
        case .invalidAttributeIterationCount:
            return "An iteration count attribute was not valid."
        case .missingAttributeIterationCount:
            return "An iteration count attribute was missing."
        case .invalidAttributeDLDBHandle:
            return "A database handle attribute was not valid."
        case .missingAttributeDLDBHandle:
            return "A database handle attribute was missing."
        case .invalidAttributeAccessCredentials:
            return "An access credentials attribute was not valid."
        case .missingAttributeAccessCredentials:
            return "An access credentials attribute was missing."
        case .invalidAttributePublicKeyFormat:
            return "A public key format attribute was not valid."
        case .missingAttributePublicKeyFormat:
            return "A public key format attribute was missing."
        case .invalidAttributePrivateKeyFormat:
            return "A private key format attribute was not valid."
        case .missingAttributePrivateKeyFormat:
            return "A private key format attribute was missing."
        case .invalidAttributeSymmetricKeyFormat:
            return "A symmetric key format attribute was not valid."
        case .missingAttributeSymmetricKeyFormat:
            return "A symmetric key format attribute was missing."
        case .invalidAttributeWrappedKeyFormat:
            return "A wrapped key format attribute was not valid."
        case .missingAttributeWrappedKeyFormat:
            return "A wrapped key format attribute was missing."
        case .stagedOperationInProgress:
            return "A staged operation is in progress."
        case .stagedOperationNotStarted:
            return "A staged operation was not started."
        case .verifyFailed:
            return "A cryptographic verification failure has occurred."
        case .querySizeUnknown:
            return "The query size is unknown."
        case .blockSizeMismatch:
            return "A block size mismatch occurred."
        case .publicKeyInconsistent:
            return "The public key was inconsistent."
        case .deviceVerifyFailed:
            return "A device verification failure has occurred."
        case .invalidLoginName:
            return "An invalid login name was detected."
        case .alreadyLoggedIn:
            return "The user is already logged in."
        case .invalidDigestAlgorithm:
            return "An invalid digest algorithm was detected."
        case .invalidCRLGroup:
            return "An invalid CRL group was detected."
        case .certificateCannotOperate:
            return "The certificate cannot operate."
        case .certificateExpired:
            return "An expired certificate was detected."
        case .certificateNotValidYet:
            return "The certificate is not yet valid."
        case .certificateRevoked:
            return "The certificate was revoked."
        case .certificateSuspended:
            return "The certificate was suspended."
        case .insufficientCredentials:
            return "Insufficient credentials were detected."
        case .invalidAction:
            return "The action was not valid."
        case .invalidAuthority:
            return "The authority was not valid."
        case .verifyActionFailed:
            return "A verify action has failed."
        case .invalidCertAuthority:
            return "The certificate authority was not valid."
        case .invaldCRLAuthority:
            return "The CRL authority was not valid."
        case .invalidCRLEncoding:
            return "The CRL encoding was not valid."
        case .invalidCRLType:
            return "The CRL type was not valid."
        case .invalidCRL:
            return "The CRL was not valid."
        case .invalidFormType:
            return "The form type was not valid."
        case .invalidID:
            return "The ID was not valid."
        case .invalidIdentifier:
            return "The identifier was not valid."
        case .invalidIndex:
            return "The index was not valid."
        case .invalidPolicyIdentifiers:
            return "The policy identifiers are not valid."
        case .invalidTimeString:
            return "The time specified was not valid."
        case .invalidReason:
            return "The trust policy reason was not valid."
        case .invalidRequestInputs:
            return "The request inputs are not valid."
        case .invalidResponseVector:
            return "The response vector was not valid."
        case .invalidStopOnPolicy:
            return "The stop-on policy was not valid."
        case .invalidTuple:
            return "The tuple was not valid."
        case .multipleValuesUnsupported:
            return "Multiple values are not supported."
        case .notTrusted:
            return "The trust policy was not trusted."
        case .noDefaultAuthority:
            return "No default authority was detected."
        case .rejectedForm:
            return "The trust policy had a rejected form."
        case .requestLost:
            return "The request was lost."
        case .requestRejected:
            return "The request was rejected."
        case .unsupportedAddressType:
            return "The address type is not supported."
        case .unsupportedService:
            return "The service is not supported."
        case .invalidTupleGroup:
            return "The tuple group was not valid."
        case .invalidBaseACLs:
            return "The base ACLs are not valid."
        case .invalidTupleCredendtials:
            return "The tuple credentials are not valid."
        case .invalidEncoding:
            return "The encoding was not valid."
        case .invalidValidityPeriod:
            return "The validity period was not valid."
        case .invalidRequestor:
            return "The requestor was not valid."
        case .requestDescriptor:
            return "The request descriptor was not valid."
        case .invalidBundleInfo:
            return "The bundle information was not valid."
        case .invalidCRLIndex:
            return "The CRL index was not valid."
        case .noFieldValues:
            return "No field values were detected."
        case .unsupportedFieldFormat:
            return "The field format is not supported."
        case .unsupportedIndexInfo:
            return "The index information is not supported."
        case .unsupportedLocality:
            return "The locality is not supported."
        case .unsupportedNumAttributes:
            return "The number of attributes is not supported."
        case .unsupportedNumIndexes:
            return "The number of indexes is not supported."
        case .unsupportedNumRecordTypes:
            return "The number of record types is not supported."
        case .fieldSpecifiedMultiple:
            return "Too many fields were specified."
        case .incompatibleFieldFormat:
            return "The field format was incompatible."
        case .invalidParsingModule:
            return "The parsing module was not valid."
        case .databaseLocked:
            return "The database is locked."
        case .datastoreIsOpen:
            return "The data store is open."
        case .missingValue:
            return "A missing value was detected."
        case .unsupportedQueryLimits:
            return "The query limits are not supported."
        case .unsupportedNumSelectionPreds:
            return "The number of selection predicates is not supported."
        case .unsupportedOperator:
            return "The operator is not supported."
        case .invalidDBLocation:
            return "The database location is not valid."
        case .invalidAccessRequest:
            return "The access request is not valid."
        case .invalidIndexInfo:
            return "The index information is not valid."
        case .invalidNewOwner:
            return "The new owner is not valid."
        case .invalidModifyMode:
            return "The modify mode is not valid."
        case .missingRequiredExtension:
            return "A required certificate extension is missing."
        case .extendedKeyUsageNotCritical:
            return "The extended key usage extension was not marked critical."
        case .timestampMissing:
            return "A timestamp was expected but was not found."
        case .timestampInvalid:
            return "The timestamp was not valid."
        case .timestampNotTrusted:
            return "The timestamp was not trusted."
        case .timestampServiceNotAvailable:
            return "The timestamp service is not available."
        case .timestampBadAlg:
            return "An unrecognized or unsupported Algorithm Identifier in timestamp."
        case .timestampBadRequest:
            return "The timestamp transaction is not permitted or supported."
        case .timestampBadDataFormat:
            return "The timestamp data submitted has the wrong format."
        case .timestampTimeNotAvailable:
            return "The time source for the Timestamp Authority is not available."
        case .timestampUnacceptedPolicy:
            return "The requested policy is not supported by the Timestamp Authority."
        case .timestampUnacceptedExtension:
            return "The requested extension is not supported by the Timestamp Authority."
        case .timestampAddInfoNotAvailable:
            return "The additional information requested is not available."
        case .timestampSystemFailure:
            return "The timestamp request cannot be handled due to system failure."
        case .signingTimeMissing:
            return "A signing time was expected but was not found."
        case .timestampRejection:
            return "A timestamp transaction was rejected."
        case .timestampWaiting:
            return "A timestamp transaction is waiting."
        case .timestampRevocationWarning:
            return "A timestamp authority revocation warning was issued."
        case .timestampRevocationNotification:
            return "A timestamp authority revocation notification was issued."
        case .unexpectedError:
            return "Unexpected error has occurred."
        }
    }
}

extension Status: CustomNSError {
    public static let errorDomain = KeychainAccessErrorDomain

    public var errorCode: Int {
        Int(rawValue)
    }

    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: description]
    }
}
