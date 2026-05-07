//
//  APNSTokenManager.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import Foundation
import UIKit
@preconcurrency import UserNotifications

@MainActor
public class APNSTokenManager: NSObject, @unchecked Sendable {
    public static let shared = APNSTokenManager()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Storage Keys
    private let tokenKey = "DebugSwift.APNSToken"
    private let registrationStateKey = "DebugSwift.APNSRegistrationState"
    private let registrationErrorKey = "DebugSwift.APNSRegistrationError"
    private let environmentKey = "DebugSwift.APNSEnvironment"
    
    // MARK: - Registration State
    public enum RegistrationState: String, CaseIterable {
        case notRequested = "not_requested"
        case pending = "pending"
        case registered = "registered"
        case failed = "failed"
        case denied = "denied"
    }
    
    // MARK: - APNS Environment
    public enum APNSEnvironment: String, CaseIterable {
        case development = "development"
        case production = "production"
        case unknown = "unknown"
    }
    
    // MARK: - Public Properties
    public var deviceToken: String? {
        get {
            UserDefaults.standard.string(forKey: tokenKey)
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: tokenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: tokenKey)
            }
        }
    }
    
    public var registrationState: RegistrationState {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: registrationStateKey),
                  let state = RegistrationState(rawValue: rawValue) else {
                return .notRequested
            }
            return state
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: registrationStateKey)
        }
    }
    
    public var registrationError: String? {
        get {
            UserDefaults.standard.string(forKey: registrationErrorKey)
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: registrationErrorKey)
            } else {
                UserDefaults.standard.removeObject(forKey: registrationErrorKey)
            }
        }
    }
    
    public var apnsEnvironment: APNSEnvironment {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: environmentKey),
                  let environment = APNSEnvironment(rawValue: rawValue) else {
                return detectAPNSEnvironment()
            }
            return environment
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: environmentKey)
        }
    }
    
    // MARK: - Public Methods
    
    /// Call this method when the app successfully registers for remote notifications
    /// - Parameter deviceToken: The device token data from didRegisterForRemoteNotificationsWithDeviceToken
    public func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString
        self.registrationState = .registered
        self.registrationError = nil
        self.apnsEnvironment = detectAPNSEnvironment()
        
        Debug.print("📱 APNS Token registered: \(tokenString)")
    }
    
    /// Call this method when the app fails to register for remote notifications
    /// - Parameter error: The error from didFailToRegisterForRemoteNotificationsWithError
    public func didFailToRegisterForRemoteNotifications(withError error: Error) {
        self.registrationState = .failed
        self.registrationError = error.localizedDescription
        self.deviceToken = nil
        
        Debug.print("❌ APNS Registration failed: \(error.localizedDescription)")
    }
    
    /// Call this method when requesting notification permissions
    public func willRequestNotificationPermissions() {
        registrationState = .pending
        registrationError = nil
    }
    
    /// Call this method when notification permissions are denied
    public func didDenyNotificationPermissions() {
        registrationState = .denied
        registrationError = "User denied notification permissions"
        deviceToken = nil
    }
    
    /// Get the current token info for display in the debug interface
    public func getTokenInfo() -> UserInfo.Info {
        switch registrationState {
        case .notRequested:
            return UserInfo.Info(
                title: "Push Token:",
                detail: "(not requested)"
            )
        case .pending:
            return UserInfo.Info(
                title: "Push Token:",
                detail: "(pending registration...)"
            )
        case .registered:
            if let token = deviceToken {
                let environmentText = apnsEnvironment == .unknown ? "" : " (\(apnsEnvironment.rawValue))"
                return UserInfo.Info(
                    title: "Push Token:",
                    detail: "\(token)\(environmentText)"
                )
            } else {
                return UserInfo.Info(
                    title: "Push Token:",
                    detail: "(registered but no token found)"
                )
            }
        case .failed:
            let errorText = registrationError ?? "Unknown error"
            return UserInfo.Info(
                title: "Push Token:",
                detail: "⚠️ (registration failed: \(errorText))"
            )
        case .denied:
            return UserInfo.Info(
                title: "Push Token:",
                detail: "🚫 (permissions denied)"
            )
        }
    }
    
    /// Copy the current device token to clipboard
    /// - Returns: true if token was copied, false if no token available
    public func copyTokenToClipboard() -> Bool {
        guard let token = deviceToken, registrationState == .registered else {
            return false
        }
        
        UIPasteboard.general.string = token
        return true
    }
    
    /// Check current notification authorization status and update state accordingly
    public func refreshRegistrationStatus() async {
        let authStatus = await Task { @Sendable in
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            return settings.authorizationStatus
        }.value
        
        switch authStatus {
        case .notDetermined:
            if registrationState != .pending {
                registrationState = .notRequested
            }
        case .denied:
            registrationState = .denied
            registrationError = "User denied notification permissions"
            deviceToken = nil
        case .authorized, .provisional, .ephemeral:
            // If authorized but no token, we need to re-register
            if deviceToken == nil && registrationState != .pending {
                registrationState = .pending
                // Trigger re-registration
                UIApplication.shared.registerForRemoteNotifications()
            }
        @unknown default:
            break
        }
    }
    
    // MARK: - Private Methods
    
    private func detectAPNSEnvironment() -> APNSEnvironment {
        // Try to detect from embedded provisioning profile
        guard let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"),
              let data = NSData(contentsOfFile: path) else {
            return .unknown
        }
        
        // Convert to string and look for aps-environment
        let string = String(data: data as Data, encoding: .ascii) ?? ""
        if string.contains("aps-environment</key>") {
            if string.contains("<string>development</string>") {
                return .development
            } else if string.contains("<string>production</string>") {
                return .production
            }
        }
        
        return .unknown
    }
}

// MARK: - Convenience Extensions

extension APNSTokenManager {
    /// Get a formatted, readable token string with spaces for better readability
    public var formattedToken: String? {
        guard let token = deviceToken else { return nil }
        
        // Insert spaces every 8 characters for better readability
        let chunks = token.enumerated().compactMap { index, character in
            return index % 8 == 0 && index > 0 ? " \(character)" : String(character)
        }
        
        return chunks.joined()
    }
} 
