//
//  Accessibility.Models.swift
//  DebugSwift
//
//  Created by Matheus Gois on 07/03/26.
//

import UIKit

public enum WCAGLevel: String, CaseIterable {
    case AAA = "WCAG AAA"
    case AA = "WCAG AA"
    case A = "WCAG A"
    case nonCompliant = "Non-Compliant"
    
    var emoji: String {
        switch self {
        case .AAA: return "⭐⭐⭐"
        case .AA: return "⭐⭐"
        case .A: return "⭐"
        case .nonCompliant: return "❌"
        }
    }
}

public enum AccessibilityIssueSeverity: String, Comparable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var emoji: String {
        switch self {
        case .critical: return "🔴"
        case .high: return "🟠"
        case .medium: return "🟡"
        case .low: return "🔵"
        }
    }
    
    var color: UIColor {
        switch self {
        case .critical: return .systemRed
        case .high: return .systemOrange
        case .medium: return .systemYellow
        case .low: return .systemBlue
        }
    }
    
    public static func < (lhs: AccessibilityIssueSeverity, rhs: AccessibilityIssueSeverity) -> Bool {
        let order: [AccessibilityIssueSeverity] = [.low, .medium, .high, .critical]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

public enum AccessibilityIssueType: String, CaseIterable {
    case missingLabel = "Missing Label"
    case missingHint = "Missing Hint"
    case poorContrast = "Poor Contrast"
    case smallTouchTarget = "Small Touch Target"
    case noDynamicType = "No Dynamic Type"
    case missingTrait = "Missing Trait"
    case poorHierarchy = "Poor Hierarchy"
    case missingImageDescription = "Missing Image Description"
    case hintTooLong = "Hint Too Long"
    case labelTooShort = "Label Too Short"
    
    var icon: String {
        switch self {
        case .missingLabel: return "textformat"
        case .missingHint: return "questionmark.circle"
        case .poorContrast: return "eye.slash"
        case .smallTouchTarget: return "hand.tap"
        case .noDynamicType: return "textformat.size"
        case .missingTrait: return "tag"
        case .poorHierarchy: return "list.bullet.indent"
        case .missingImageDescription: return "photo"
        case .hintTooLong: return "text.quote"
        case .labelTooShort: return "text.word.spacing"
        }
    }
}

public struct AccessibilityIssue: Identifiable {
    public let id: UUID
    public let severity: AccessibilityIssueSeverity
    public let type: AccessibilityIssueType
    public weak var element: UIView?
    public let elementDescription: String
    public let description: String
    public let wcagReference: String
    public let fixSuggestion: String
    public let codeExample: String?
    public let location: String
    
    public init(
        id: UUID = UUID(),
        severity: AccessibilityIssueSeverity,
        type: AccessibilityIssueType,
        element: UIView?,
        elementDescription: String,
        description: String,
        wcagReference: String,
        fixSuggestion: String,
        codeExample: String? = nil,
        location: String = ""
    ) {
        self.id = id
        self.severity = severity
        self.type = type
        self.element = element
        self.elementDescription = elementDescription
        self.description = description
        self.wcagReference = wcagReference
        self.fixSuggestion = fixSuggestion
        self.codeExample = codeExample
        self.location = location
    }
}

public struct AuditReport {
    public let timestamp: Date
    public let viewController: String
    public let issues: [AccessibilityIssue]
    public let score: Int
    
    public var wcagLevel: WCAGLevel {
        switch score {
        case 95...100: return .AAA
        case 80...94: return .AA
        case 60...79: return .A
        default: return .nonCompliant
        }
    }
    
    public var criticalCount: Int {
        issues.filter { $0.severity == .critical }.count
    }
    
    public var highCount: Int {
        issues.filter { $0.severity == .high }.count
    }
    
    public var mediumCount: Int {
        issues.filter { $0.severity == .medium }.count
    }
    
    public var lowCount: Int {
        issues.filter { $0.severity == .low }.count
    }
    
    public init(
        timestamp: Date = Date(),
        viewController: String,
        issues: [AccessibilityIssue],
        score: Int
    ) {
        self.timestamp = timestamp
        self.viewController = viewController
        self.issues = issues
        self.score = score
    }
}
