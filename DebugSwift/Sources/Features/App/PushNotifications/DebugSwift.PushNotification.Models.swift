//
//  PushNotification.Models.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import Foundation
import UIKit
import UserNotifications

// MARK: - SimulatedNotification

public struct SimulatedNotification: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let body: String
    public let subtitle: String?
    public let badge: Int?
    public let sound: String?
    public let category: String?
    public let userInfo: [String: String]
    public let scheduledDate: Date
    public let deliveryDate: Date?
    public let status: NotificationStatus
    public let trigger: NotificationTrigger
    public let interactionType: InteractionType?
    
    public enum NotificationStatus: String, Codable, CaseIterable, Sendable {
        case scheduled = "Scheduled"
        case delivered = "Delivered"
        case interacted = "Interacted"
        case dismissed = "Dismissed"
        case failed = "Failed"
        
        public var emoji: String {
            switch self {
            case .scheduled: return "⏰"
            case .delivered: return "✅"
            case .interacted: return "👆"
            case .dismissed: return "❌"
            case .failed: return "🚫"
            }
        }
        
        public var colorHex: String {
            switch self {
            case .scheduled: return "#FF8C00"
            case .delivered: return "#32CD32"
            case .interacted: return "#1E90FF"
            case .dismissed: return "#808080"
            case .failed: return "#FF4500"
            }
        }
    }
    
    public enum NotificationTrigger: Codable, Sendable {
        case immediate
        case timeInterval(TimeInterval)
        case date(Date)
        case location(String)
        
        public var description: String {
            switch self {
            case .immediate:
                return "Immediate"
            case .timeInterval(let interval):
                return "In \(Int(interval))s"
            case .date(let date):
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                formatter.dateStyle = .short
                return formatter.string(from: date)
            case .location(let location):
                return "At \(location)"
            }
        }
    }
    
    public enum InteractionType: String, Codable, CaseIterable, Sendable {
        case tap = "Tap"
        case action = "Action"
        case dismiss = "Dismiss"
        case none = "None"
    }
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        body: String,
        subtitle: String? = nil,
        badge: Int? = nil,
        sound: String? = nil,
        category: String? = nil,
        userInfo: [String: String] = [:],
        trigger: NotificationTrigger = .immediate,
        status: NotificationStatus = .scheduled
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.subtitle = subtitle
        self.badge = badge
        self.sound = sound
        self.category = category
        self.userInfo = userInfo
        self.scheduledDate = Date()
        self.deliveryDate = nil
        self.status = status
        self.trigger = trigger
        self.interactionType = nil
    }
}

// MARK: - NotificationTemplate

public struct NotificationTemplate: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let title: String
    public let body: String
    public let subtitle: String?
    public let badge: Int?
    public let sound: String?
    public let category: String?
    public let userInfo: [String: String]
    public let isDefault: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        title: String,
        body: String,
        subtitle: String? = nil,
        badge: Int? = nil,
        sound: String? = nil,
        category: String? = nil,
        userInfo: [String: String] = [:],
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.body = body
        self.subtitle = subtitle
        self.badge = badge
        self.sound = sound
        self.category = category
        self.userInfo = userInfo
        self.isDefault = isDefault
    }
    
    public func toSimulatedNotification(trigger: SimulatedNotification.NotificationTrigger = .immediate) -> SimulatedNotification {
        return SimulatedNotification(
            title: title,
            body: body,
            subtitle: subtitle,
            badge: badge,
            sound: sound,
            category: category,
            userInfo: userInfo,
            trigger: trigger
        )
    }
}

// MARK: - NotificationConfiguration

public struct NotificationConfiguration: Codable, Sendable {
    public var isEnabled: Bool
    public var showInForeground: Bool
    public var playSound: Bool
    public var showBadge: Bool
    public var autoInteraction: Bool
    public var interactionDelay: TimeInterval
    public var simulateRealPush: Bool
    public var defaultSound: String
    public var maxHistoryCount: Int
    
    public static let `default` = NotificationConfiguration(
        isEnabled: true,
        showInForeground: true,
        playSound: true,
        showBadge: true,
        autoInteraction: false,
        interactionDelay: 3.0,
        simulateRealPush: false,
        defaultSound: "default",
        maxHistoryCount: 100
    )
    
    public init(
        isEnabled: Bool = true,
        showInForeground: Bool = true,
        playSound: Bool = true,
        showBadge: Bool = true,
        autoInteraction: Bool = false,
        interactionDelay: TimeInterval = 3.0,
        simulateRealPush: Bool = false,
        defaultSound: String = "default",
        maxHistoryCount: Int = 100
    ) {
        self.isEnabled = isEnabled
        self.showInForeground = showInForeground
        self.playSound = playSound
        self.showBadge = showBadge
        self.autoInteraction = autoInteraction
        self.interactionDelay = interactionDelay
        self.simulateRealPush = simulateRealPush
        self.defaultSound = defaultSound
        self.maxHistoryCount = maxHistoryCount
    }
}

// MARK: - Default Templates

extension NotificationTemplate {
    public static let defaultTemplates: [NotificationTemplate] = [
        NotificationTemplate(
            name: "Message",
            title: "New Message",
            body: "You have a new message from {{sender}}",
            userInfo: ["type": "message", "sender": "John Doe"],
            isDefault: true
        ),
        NotificationTemplate(
            name: "News Update",
            title: "Breaking News",
            body: "{{headline}}",
            subtitle: "{{category}}",
            userInfo: ["type": "news", "category": "Technology"],
            isDefault: true
        ),
        NotificationTemplate(
            name: "Reminder",
            title: "Reminder",
            body: "Don't forget: {{task}}",
            badge: 1,
            userInfo: ["type": "reminder"],
            isDefault: true
        ),
        NotificationTemplate(
            name: "Marketing",
            title: "Special Offer! 🎉",
            body: "Get {{discount}}% off your next purchase",
            subtitle: "Limited time offer",
            userInfo: ["type": "marketing", "discount": "50"],
            isDefault: true
        ),
        NotificationTemplate(
            name: "System Alert",
            title: "System Notification",
            body: "{{message}}",
            sound: "system",
            userInfo: ["type": "system"],
            isDefault: true
        )
    ]
} 