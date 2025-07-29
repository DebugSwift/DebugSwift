//
//  ExampleApp.swift
//  Example
//
//  Created by Matheus Gois on 16/12/23.
//

import DebugSwift
import SwiftUI
import UserNotifications
import UIKit

@available(iOS 14.0, *)
@main
struct ExampleApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear() {
                    DebugSwift.PushNotification.enableSimulation()
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    private let debugSwift = DebugSwift()

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Remove comment below to remove specific features and comment DebugSwift.setup() not to double trigger.
        // DebugSwift.setup(hideFeatures: [.interface, .app, .resources, .performance])
        
        // If you have New Relic, disable leak detector to prevent conflicts:
        // debugSwift.setup(disable: [.leaksDetector])
        
        print("Hey, DebugSwift is running! 🎉")
        
        debugSwift
            .setup(enableBetaFeatures: [.swiftUIRenderTracking])
            .show()

        // To fix Alamofire `uploadProgress`
//        DebugSwift.Network.delegate = self
        
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

extension AppDelegate {
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

// MARK: - Alamofire bugfix in uploadProgress

extension AppDelegate: @preconcurrency CustomHTTPProtocolDelegate {
    func urlSession(
        _ protocol: URLProtocol,
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        // This is a workaround to fix the uploadProgress bug in Alamofire
        // It will be removed in the future when Alamofire is fixed
        // Please check the Alamofire issue for more details:
//        Session.default.session.getAllTasks { tasks in
//            let uploadTask = tasks.first(where: { $0.taskIdentifier == task.taskIdentifier }) ?? task
//            Session.default.rootQueue.async {
//                Session.default.delegate.urlSession(
//                    session,
//                    task: uploadTask,
//                    didSendBodyData: bytesSent,
//                    totalBytesSent: totalBytesSent,
//                    totalBytesExpectedToSend: totalBytesExpectedToSend
//                )
//            }
//        }
    }
}
