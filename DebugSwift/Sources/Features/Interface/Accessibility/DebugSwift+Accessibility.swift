//
//  DebugSwift+Accessibility.swift
//  DebugSwift
//
//  Created by Matheus Gois on 07/03/26.
//

import UIKit

public extension DebugSwift {
    struct Accessibility {
        @MainActor
        public static var targetLevel: WCAGLevel = .AA
        
        @MainActor
        public static func auditCurrentScreen() -> AuditReport {
            return AccessibilityAuditor.shared.auditCurrentScreen()
        }
        
        @MainActor
        public static func auditView(_ view: UIView) -> [AccessibilityIssue] {
            return AccessibilityAuditor.shared.auditView(view)
        }
        
        public static func getComplianceScore() -> Int {
            return AccessibilityAuditor.shared.getComplianceScore()
        }
        
        public static func exportReport() -> Data? {
            return AccessibilityAuditor.shared.exportReport()
        }
    }
}
