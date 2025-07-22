//
//  ExampleAppFixed.swift
//  Example
//
//  Shows how to fix the DebugSwift console interception deadlock
//

import DebugSwift
import SwiftUI
import UserNotifications
import UIKit

/*
 * FIXED VERSION - To use this instead of the buggy version:
 * 1. Rename ExampleApp.swift to ExampleAppBuggy.swift
 * 2. Rename this file to ExampleApp.swift
 * 3. Update @main to point to this struct
 */

@available(iOS 14.0, *)
struct ExampleAppFixed: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegateFixed

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear() {
                    DebugSwift.PushNotification.enableSimulation()
                }
        }
    }
}

class AppDelegateFixed: NSObject, UIApplicationDelegate {
    private let debugSwift = DebugSwift()

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        print("Hey, DebugSwift is running! 🎉 (FIXED VERSION)")
        
        // ✅ FIXED: Disable console interception to prevent deadlock
        debugSwift
            .setup(
                disable: [.console]  // This prevents the console interception deadlock
            )
            .show()

        // Request push notification permissions for APNS token demo
        requestPushNotificationPermissions()

        return true
    }

    func additionalViewControllers() -> [UIViewController] {
        let viewController = UITableViewController()
        viewController.title = "PURE"
        return [viewController]
    }
    
    // MARK: - Push Notification Setup
    
    private func requestPushNotificationPermissions() {
        Task { @MainActor in
            let center = UNUserNotificationCenter.current()
            
            // Inform DebugSwift that we're about to request permissions
            DebugSwift.APNSToken.willRequestPermissions()
            
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                if granted {
                    // Register for remote notifications
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    // Inform DebugSwift that permissions were denied
                    DebugSwift.APNSToken.didDenyPermissions()
                }
            } catch {
                print("Failed to request notification permissions: \(error)")
                DebugSwift.APNSToken.didFailToRegister(error: error)
            }
        }
    }
}

// MARK: - Push Notification Delegate Methods

extension AppDelegateFixed {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Register the device token with DebugSwift for debugging
        DebugSwift.APNSToken.didRegister(deviceToken: deviceToken)
        
        // Your existing push notification setup code would go here
        // For example, sending the token to your server
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 Registered for push notifications with token: \(tokenString)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Register the failure with DebugSwift for debugging
        DebugSwift.APNSToken.didFailToRegister(error: error)
        
        // Your existing error handling code would go here
        print("❌ Failed to register for push notifications: \(error.localizedDescription)")
    }
} 