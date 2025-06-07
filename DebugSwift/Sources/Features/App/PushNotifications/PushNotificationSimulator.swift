//
//  PushNotificationSimulator.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import Foundation
import UserNotifications
import UIKit

@MainActor
public class PushNotificationSimulator: NSObject, ObservableObject {
    public static let shared = PushNotificationSimulator()
    
    @Published public var notificationHistory: [SimulatedNotification] = []
    @Published public var templates: [NotificationTemplate] = []
    @Published public var configuration = NotificationConfiguration.default
    @Published public var isEnabled = false
    
    private let userDefaultsKey = "DebugSwift.PushNotifications"
    private let templatesKey = "DebugSwift.PushNotification.Templates"
    private let historyKey = "DebugSwift.PushNotification.History"
    private let configKey = "DebugSwift.PushNotification.Config"
    
    public override init() {
        super.init()
        loadConfiguration()
        loadTemplates()
        loadHistory()
        setupNotificationCenter()
    }
    
    // MARK: - Public API
    
    public func enable() {
        isEnabled = true
        requestPermissions()
        saveConfiguration()
    }
    
    public func disable() {
        isEnabled = false
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        saveConfiguration()
    }
    
    public func simulateNotification(_ notification: SimulatedNotification) async {
        guard isEnabled else {
            print("⚠️ PushNotificationSimulator is not enabled")
            return
        }
        
        do {
            let request = try createNotificationRequest(from: notification)
            
            // Add to history immediately
            var updatedNotification = notification
            addToHistory(updatedNotification)
            
            // Schedule the notification
            let center = UNUserNotificationCenter.current()
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                center.add(request) { @Sendable error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
            
            // Update status to scheduled
            updatedNotification = updateNotificationStatus(notification.id, status: .scheduled)
            
            print("✅ Scheduled notification: \(notification.title)")
            
            // If immediate trigger, simulate delivery
            if case .immediate = notification.trigger {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    Task { @MainActor in
                        await self.simulateDelivery(notification.id)
                    }
                }
            }
            
        } catch {
            print("❌ Failed to simulate notification: \(error)")
            updateNotificationStatus(notification.id, status: .failed)
        }
    }
    
    public func simulateFromTemplate(_ template: NotificationTemplate, trigger: SimulatedNotification.NotificationTrigger = .immediate) async {
        let notification = template.toSimulatedNotification(trigger: trigger)
        await simulateNotification(notification)
    }
    
    public func simulateInteraction(identifier: String, actionIdentifier: String? = nil) {
        guard let notification = notificationHistory.first(where: { $0.id == identifier }) else {
            print("⚠️ Notification with identifier \(identifier) not found")
            return
        }
        
        let interactionType: SimulatedNotification.InteractionType = actionIdentifier != nil ? .action : .tap
        updateNotificationStatus(identifier, status: .interacted, interactionType: interactionType)
        
        print("👆 Simulated \(interactionType.rawValue.lowercased()) interaction for: \(notification.title)")
        
        // Simulate app opening/foregrounding
        NotificationCenter.default.post(
            name: NSNotification.Name("DebugSwift.PushNotification.Interaction"),
            object: notification,
            userInfo: ["actionIdentifier": actionIdentifier as Any]
        )
    }
    
    public func simulateForegroundNotification(identifier: String) {
        print("📱 Simulating foreground notification: \(identifier)")
        // Notification will appear as banner while app is active
    }
    
    public func simulateBackgroundNotification(identifier: String) {
        print("🔕 Simulating background notification: \(identifier)")
        // Notification will appear in notification center
        updateNotificationStatus(identifier, status: .delivered)
    }
    
    public func clearHistory() {
        notificationHistory.removeAll()
        saveHistory()
    }
    
    public func removeNotification(id: String) {
        notificationHistory.removeAll { $0.id == id }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id])
        saveHistory()
    }
    
    public func addTemplate(_ template: NotificationTemplate) {
        templates.append(template)
        saveTemplates()
    }
    
    public func removeTemplate(id: String) {
        templates.removeAll { $0.id == id }
        saveTemplates()
    }
    
    public func updateConfiguration(_ config: NotificationConfiguration) {
        configuration = config
        saveConfiguration()
    }
    
    // MARK: - Private Methods
    
    private func requestPermissions() {
        Task { @MainActor in
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
                if granted {
                    print("✅ Notification permissions granted")
                } else {
                    print("❌ Notification permissions denied")
                }
            } catch {
                print("❌ Notification permissions denied")
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupNotificationCenter() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    private func createNotificationRequest(from notification: SimulatedNotification) throws -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        
        if let subtitle = notification.subtitle {
            content.subtitle = subtitle
        }
        
        if let badge = notification.badge {
            content.badge = NSNumber(value: badge)
        }
        
        if let sound = notification.sound {
            content.sound = sound == "default" ? .default : UNNotificationSound(named: UNNotificationSoundName(sound))
        } else if configuration.playSound {
            content.sound = .default
        }
        
        if let category = notification.category {
            content.categoryIdentifier = category
        }
        
        // Add user info
        var userInfo: [String: Any] = [:]
        for (key, value) in notification.userInfo {
            userInfo[key] = value
        }
        userInfo["debugswift_simulated"] = true
        userInfo["debugswift_id"] = notification.id
        content.userInfo = userInfo
        
        // Create trigger
        let trigger = createTrigger(from: notification.trigger)
        
        return UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: trigger
        )
    }
    
    private func createTrigger(from trigger: SimulatedNotification.NotificationTrigger) -> UNNotificationTrigger? {
        switch trigger {
        case .immediate:
            return UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        case .timeInterval(let interval):
            return UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        case .date(let date):
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        case .location:
            // For location-based notifications, we'll use a time interval as fallback
            return UNTimeIntervalNotificationTrigger(timeInterval: 5.0, repeats: false)
        }
    }
    
    @discardableResult
    private func updateNotificationStatus(
        _ id: String,
        status: SimulatedNotification.NotificationStatus,
        interactionType: SimulatedNotification.InteractionType? = nil
    ) -> SimulatedNotification {
        guard let index = notificationHistory.firstIndex(where: { $0.id == id }) else {
            print("⚠️ Notification with id \(id) not found in history")
            return notificationHistory.first(where: { $0.id == id }) ?? SimulatedNotification(title: "", body: "")
        }
        
        let originalNotification = notificationHistory[index]
        let updatedNotification = SimulatedNotification(
            id: originalNotification.id,
            title: originalNotification.title,
            body: originalNotification.body,
            subtitle: originalNotification.subtitle,
            badge: originalNotification.badge,
            sound: originalNotification.sound,
            category: originalNotification.category,
            userInfo: originalNotification.userInfo,
            trigger: originalNotification.trigger,
            status: status
        )
        
        // Update notification with new status
        let mutableNotification = updatedNotification
        _ = Mirror(reflecting: mutableNotification)
        
        // Since SimulatedNotification properties are let, we need to create a new instance
        // This is a limitation of the current struct design
        notificationHistory[index] = SimulatedNotification(
            id: originalNotification.id,
            title: originalNotification.title,
            body: originalNotification.body,
            subtitle: originalNotification.subtitle,
            badge: originalNotification.badge,
            sound: originalNotification.sound,
            category: originalNotification.category,
            userInfo: originalNotification.userInfo,
            trigger: originalNotification.trigger,
            status: status
        )
        
        saveHistory()
        return notificationHistory[index]
    }
    
    private func addToHistory(_ notification: SimulatedNotification) {
        notificationHistory.insert(notification, at: 0)
        
        // Limit history size
        if notificationHistory.count > configuration.maxHistoryCount {
            notificationHistory = Array(notificationHistory.prefix(configuration.maxHistoryCount))
        }
        
        saveHistory()
    }
    
    private func simulateDelivery(_ notificationId: String) async {
        // Simulate delivery delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        updateNotificationStatus(notificationId, status: .delivered)
        
        // Auto-interaction if enabled
        if configuration.autoInteraction {
            DispatchQueue.main.asyncAfter(deadline: .now() + configuration.interactionDelay) {
                self.simulateInteraction(identifier: notificationId)
            }
        }
    }
    
    // MARK: - Persistence
    
    private func saveConfiguration() {
        if let encoded = try? JSONEncoder().encode(configuration) {
            UserDefaults.standard.set(encoded, forKey: configKey)
        }
    }
    
    private func loadConfiguration() {
        if let data = UserDefaults.standard.data(forKey: configKey),
           let decoded = try? JSONDecoder().decode(NotificationConfiguration.self, from: data) {
            configuration = decoded
        }
    }
    
    private func saveTemplates() {
        if let encoded = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(encoded, forKey: templatesKey)
        }
    }
    
    private func loadTemplates() {
        if let data = UserDefaults.standard.data(forKey: templatesKey),
           let decoded = try? JSONDecoder().decode([NotificationTemplate].self, from: data) {
            templates = decoded
        } else {
            templates = NotificationTemplate.defaultTemplates
            saveTemplates()
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(notificationHistory) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([SimulatedNotification].self, from: data) {
            notificationHistory = decoded
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationSimulator: UNUserNotificationCenterDelegate {
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Check if this is a simulated notification
        guard notification.request.content.userInfo["debugswift_simulated"] as? Bool == true,
              let notificationId = notification.request.content.userInfo["debugswift_id"] as? String else {
            completionHandler([])
            return
        }
        
        let title = notification.request.content.title
        print("📱 Notification will present in foreground: \(title)")
        
        // Default options for foreground notifications
        var options: UNNotificationPresentationOptions = [.banner, .sound, .badge]
        options.insert(.banner)
        
        completionHandler(options)
        
        // Update status asynchronously
        DispatchQueue.main.async {
            Task { @MainActor [weak self] in
                self?.updateNotificationStatus(notificationId, status: .delivered)
            }
        }
    }
    
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Check if this is a simulated notification
        guard response.notification.request.content.userInfo["debugswift_simulated"] as? Bool == true,
              let notificationId = response.notification.request.content.userInfo["debugswift_id"] as? String else {
            completionHandler()
            return
        }
        
        let title = response.notification.request.content.title
        print("👆 User interacted with notification: \(title)")
        
        let actionIdentifier = response.actionIdentifier == UNNotificationDefaultActionIdentifier ? nil : response.actionIdentifier
        
        // Complete immediately
        completionHandler()
        
        // Handle interaction asynchronously
        DispatchQueue.main.async {
            Task { @MainActor [weak self] in
                self?.simulateInteraction(identifier: notificationId, actionIdentifier: actionIdentifier)
            }
        }
    }
}
