//
//  DebugSwift.PushNotification.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import Foundation
import UserNotifications

extension DS {
    public enum PushNotification {
        
        // MARK: - Core Configuration
        
        /// Enables push notification simulation
        /// This will request notification permissions and set up the simulation environment
        public static func enableSimulation() {
            Task { @MainActor in
                PushNotificationSimulator.shared.enable()
            }
        }
        
        /// Disables push notification simulation
        /// This will remove all pending simulated notifications
        public static func disableSimulation() {
            Task { @MainActor in
                PushNotificationSimulator.shared.disable()
            }
        }
        
        /// Checks if push notification simulation is currently enabled
        @MainActor public static var isEnabled: Bool {
            return PushNotificationSimulator.shared.isEnabled
        }
        
        // MARK: - Quick Simulation Methods
        
        /// Simulates a simple push notification
        /// - Parameters:
        ///   - title: The notification title
        ///   - body: The notification body
        ///   - delay: Optional delay before showing the notification (default: immediate)
        public static func simulate(title: String, body: String, delay: TimeInterval = 0) {
            let trigger: SimulatedNotification.NotificationTrigger = delay > 0 ? .timeInterval(delay) : .immediate
            let notification = SimulatedNotification(
                title: title,
                body: body,
                trigger: trigger
            )
            
            Task { @MainActor in
                await PushNotificationSimulator.shared.simulateNotification(notification)
            }
        }
        
        /// Simulates a push notification with detailed content
        /// - Parameters:
        ///   - title: The notification title
        ///   - body: The notification body
        ///   - subtitle: Optional subtitle
        ///   - badge: Optional badge number
        ///   - sound: Optional sound name (use "default" for system sound)
        ///   - userInfo: Optional user info dictionary
        ///   - delay: Optional delay before showing the notification
        public static func simulate(
            title: String,
            body: String,
            subtitle: String? = nil,
            badge: Int? = nil,
            sound: String? = nil,
            userInfo: [String: String] = [:],
            delay: TimeInterval = 0
        ) {
            let trigger: SimulatedNotification.NotificationTrigger = delay > 0 ? .timeInterval(delay) : .immediate
            let notification = SimulatedNotification(
                title: title,
                body: body,
                subtitle: subtitle,
                badge: badge,
                sound: sound,
                userInfo: userInfo,
                trigger: trigger
            )
            
            Task { @MainActor in
                await PushNotificationSimulator.shared.simulateNotification(notification)
            }
        }
        
        /// Simulates a push notification using a predefined template
        /// - Parameters:
        ///   - templateName: Name of the template to use
        ///   - delay: Optional delay before showing the notification
        public static func simulateFromTemplate(_ templateName: String, delay: TimeInterval = 0) {
            Task { @MainActor in
                let simulator = PushNotificationSimulator.shared
                guard let template = simulator.templates.first(where: { $0.name == templateName }) else {
                    print("⚠️ Template '\(templateName)' not found")
                    return
                }
                
                let trigger: SimulatedNotification.NotificationTrigger = delay > 0 ? .timeInterval(delay) : .immediate
                await simulator.simulateFromTemplate(template, trigger: trigger)
            }
        }
        
        // MARK: - Interaction Simulation
        
        /// Simulates user interaction with a notification
        /// - Parameter identifier: The notification identifier
        public static func simulateInteraction(identifier: String) {
            Task { @MainActor in
                PushNotificationSimulator.shared.simulateInteraction(identifier: identifier)
            }
        }
        
        /// Simulates a notification appearing while the app is in the foreground
        /// - Parameter identifier: The notification identifier
        public static func simulateForegroundNotification(identifier: String) {
            Task { @MainActor in
                PushNotificationSimulator.shared.simulateForegroundNotification(identifier: identifier)
            }
        }
        
        /// Simulates a notification appearing while the app is in the background
        /// - Parameter identifier: The notification identifier
        public static func simulateBackgroundNotification(identifier: String) {
            Task { @MainActor in
                PushNotificationSimulator.shared.simulateBackgroundNotification(identifier: identifier)
            }
        }
        
        // MARK: - Template Management
        
        /// Adds a custom notification template
        /// - Parameter template: The template to add
        public static func addTemplate(_ template: NotificationTemplate) {
            Task { @MainActor in
                PushNotificationSimulator.shared.addTemplate(template)
            }
        }
        
        /// Removes a notification template
        /// - Parameter templateId: The ID of the template to remove
        public static func removeTemplate(id templateId: String) {
            Task { @MainActor in
                PushNotificationSimulator.shared.removeTemplate(id: templateId)
            }
        }
        
        /// Gets all available templates
        @MainActor public static var templates: [NotificationTemplate] {
            return PushNotificationSimulator.shared.templates
        }
        
        // MARK: - History Management
        
        /// Gets the notification history
        @MainActor public static var history: [SimulatedNotification] {
            return PushNotificationSimulator.shared.notificationHistory
        }
        
        /// Clears the notification history
        public static func clearHistory() {
            Task { @MainActor in
                PushNotificationSimulator.shared.clearHistory()
            }
        }
        
        /// Removes a specific notification from history
        /// - Parameter notificationId: The ID of the notification to remove
        public static func removeNotification(id notificationId: String) {
            Task { @MainActor in
                PushNotificationSimulator.shared.removeNotification(id: notificationId)
            }
        }
        
        // MARK: - Configuration
        
        /// Updates the notification simulation configuration
        /// - Parameter config: The new configuration
        public static func updateConfiguration(_ config: NotificationConfiguration) {
            Task { @MainActor in
                PushNotificationSimulator.shared.updateConfiguration(config)
            }
        }
        
        /// Gets the current configuration
        @MainActor public static var configuration: NotificationConfiguration {
            return PushNotificationSimulator.shared.configuration
        }
        
        // MARK: - Advanced Simulation
        
        /// Creates and schedules multiple notifications for testing scenarios
        /// - Parameter scenario: The test scenario to run
        public static func runTestScenario(_ scenario: TestScenario) {
            Task { @MainActor in
                await scenario.execute()
            }
        }
        
        // MARK: - Test Scenarios
        
        @MainActor public enum TestScenario {
            case messageFlow
            case newsUpdates
            case marketingCampaign
            case systemAlerts
            case customFlow([SimulatedNotification])
            
            @MainActor func execute() async {
                let simulator = PushNotificationSimulator.shared
                
                switch self {
                case .messageFlow:
                    await executeMessageFlow(simulator)
                case .newsUpdates:
                    await executeNewsUpdates(simulator)
                case .marketingCampaign:
                    await executeMarketingCampaign(simulator)
                case .systemAlerts:
                    await executeSystemAlerts(simulator)
                case .customFlow(let notifications):
                    for notification in notifications {
                        await simulator.simulateNotification(notification)
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                    }
                }
            }
            
            @MainActor private func executeMessageFlow(_ simulator: PushNotificationSimulator) async {
                let notifications = [
                    SimulatedNotification(title: "New Message", body: "You have a message from John", trigger: .immediate),
                    SimulatedNotification(title: "Message Delivered", body: "Your message was delivered", trigger: .timeInterval(3)),
                    SimulatedNotification(title: "John is typing...", body: "John is composing a message", trigger: .timeInterval(6))
                ]
                
                for notification in notifications {
                    await simulator.simulateNotification(notification)
                }
            }
            
            private func executeNewsUpdates(_ simulator: PushNotificationSimulator) async {
                let notifications = [
                    SimulatedNotification(title: "Breaking News", body: "Major technology breakthrough announced", subtitle: "Technology", trigger: .immediate),
                    SimulatedNotification(title: "Sports Update", body: "Championship game ends in overtime", subtitle: "Sports", trigger: .timeInterval(5)),
                    SimulatedNotification(title: "Weather Alert", body: "Severe weather warning in your area", subtitle: "Weather", trigger: .timeInterval(10))
                ]
                
                for notification in notifications {
                    await simulator.simulateNotification(notification)
                }
            }
            
            private func executeMarketingCampaign(_ simulator: PushNotificationSimulator) async {
                let notifications = [
                    SimulatedNotification(title: "Welcome Offer! 🎉", body: "Get 50% off your first purchase", badge: 1, trigger: .immediate),
                    SimulatedNotification(title: "Cart Reminder", body: "You have items waiting in your cart", trigger: .timeInterval(300)), // 5 minutes
                    SimulatedNotification(title: "Flash Sale! ⚡", body: "24-hour flash sale starts now", badge: 2, trigger: .timeInterval(600)) // 10 minutes
                ]
                
                for notification in notifications {
                    await simulator.simulateNotification(notification)
                }
            }
            
            private func executeSystemAlerts(_ simulator: PushNotificationSimulator) async {
                let notifications = [
                    SimulatedNotification(title: "Security Alert", body: "New login from unknown device", sound: "alarm", trigger: .immediate),
                    SimulatedNotification(title: "Backup Complete", body: "Your data has been backed up successfully", trigger: .timeInterval(2)),
                    SimulatedNotification(title: "Update Available", body: "A new app update is available", badge: 1, trigger: .timeInterval(4))
                ]
                
                for notification in notifications {
                    await simulator.simulateNotification(notification)
                }
            }
        }
    }
}

// MARK: - Convenience Extensions

extension DebugSwift.PushNotification {
    /// Quick message notification
    public static func simulateMessage(from sender: String, message: String) {
        simulate(
            title: "New Message",
            body: message,
            subtitle: "From \(sender)",
            userInfo: ["type": "message", "sender": sender]
        )
    }
    
    /// Quick reminder notification
    public static func simulateReminder(_ task: String, in delay: TimeInterval = 0) {
        simulate(
            title: "Reminder",
            body: "Don't forget: \(task)",
            badge: 1,
            userInfo: ["type": "reminder", "task": task],
            delay: delay
        )
    }
    
    /// Quick news notification
    public static func simulateNews(headline: String, category: String = "General") {
        simulate(
            title: "Breaking News",
            body: headline,
            subtitle: category,
            userInfo: ["type": "news", "category": category]
        )
    }
    
    /// Quick marketing notification
    public static func simulateMarketing(title: String, offer: String, discount: String? = nil) {
        var userInfo = ["type": "marketing", "offer": offer]
        if let discount = discount {
            userInfo["discount"] = discount
        }
        
        simulate(
            title: title,
            body: offer,
            subtitle: discount != nil ? "\(discount!)% off" : nil,
            badge: 1,
            userInfo: userInfo
        )
    }
} 