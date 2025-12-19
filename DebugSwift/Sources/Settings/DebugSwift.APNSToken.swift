//
//  DebugSwift.APNSToken.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import Foundation

extension DS {
    public enum APNSToken {
        
        /// Call this method when your app successfully registers for remote notifications
        /// Add this to your AppDelegate's didRegisterForRemoteNotificationsWithDeviceToken method
        /// 
        /// Example usage:
        /// ```swift
        /// func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        ///     DebugSwift.APNSToken.didRegister(deviceToken: deviceToken)
        ///     // Your existing push notification setup code here
        /// }
        /// ```
        /// - Parameter deviceToken: The device token data from the delegate method
        @MainActor
        public static func didRegister(deviceToken: Data) {
            APNSTokenManager.shared.didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
        }
        
        /// Call this method when your app fails to register for remote notifications
        /// Add this to your AppDelegate's didFailToRegisterForRemoteNotificationsWithError method
        /// 
        /// Example usage:
        /// ```swift
        /// func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        ///     DebugSwift.APNSToken.didFailToRegister(error: error)
        ///     // Your existing error handling code here
        /// }
        /// ```
        /// - Parameter error: The error from the delegate method
        @MainActor
        public static func didFailToRegister(error: Error) {
            APNSTokenManager.shared.didFailToRegisterForRemoteNotifications(withError: error)
        }
        
        /// Call this method when you're about to request notification permissions
        /// This helps DebugSwift track the registration state more accurately
        /// 
        /// Example usage:
        /// ```swift
        /// DebugSwift.APNSToken.willRequestPermissions()
        /// UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        ///     // Handle response
        /// }
        /// ```
        @MainActor
        public static func willRequestPermissions() {
            APNSTokenManager.shared.willRequestNotificationPermissions()
        }
        
        /// Call this method when notification permissions are denied by the user
        /// This is optional but helps provide more accurate status information
        @MainActor
        public static func didDenyPermissions() {
            APNSTokenManager.shared.didDenyNotificationPermissions()
        }
        
        /// Get the current device token if available
        /// - Returns: The hex-encoded device token string, or nil if not available
        @MainActor
        public static var deviceToken: String? {
            return APNSTokenManager.shared.deviceToken
        }
        
        /// Get the current registration state
        /// - Returns: The current APNS registration state
        @MainActor
        public static var registrationState: APNSTokenManager.RegistrationState {
            return APNSTokenManager.shared.registrationState
        }
        
        /// Get the current APNS environment (sandbox vs production)
        /// - Returns: The detected APNS environment
        @MainActor
        public static var environment: APNSTokenManager.APNSEnvironment {
            return APNSTokenManager.shared.apnsEnvironment
        }
        
        /// Copy the current device token to clipboard
        /// - Returns: true if token was copied successfully, false otherwise
        @MainActor
        @discardableResult
        public static func copyToClipboard() -> Bool {
            return APNSTokenManager.shared.copyTokenToClipboard()
        }
        
        /// Refresh the current registration status by checking system notification settings
        /// This will update the internal state and may trigger re-registration if needed
        @MainActor
        public static func refreshStatus() async {
            await APNSTokenManager.shared.refreshRegistrationStatus()
        }
    }
} 