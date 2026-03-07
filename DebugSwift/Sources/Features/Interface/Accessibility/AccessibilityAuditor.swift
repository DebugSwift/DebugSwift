//
//  AccessibilityAuditor.swift
//  DebugSwift
//
//  Created by Matheus Gois on 07/03/26.
//

import UIKit

public final class AccessibilityAuditor: @unchecked Sendable {
    public static let shared = AccessibilityAuditor()
    
    private var currentReport: AuditReport?
    private let minimumTouchTargetSize: CGFloat = 44.0
    private let maxHintLength = 100
    private let minLabelLength = 2
    
    private init() {}
    
    @MainActor
    public func auditCurrentScreen() -> AuditReport {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return AuditReport(viewController: "Unknown", issues: [], score: 0)
        }
        
        // Find the main app window (not CustomWindow from DebugSwift)
        let appWindow = windowScene.windows.first { window in
            let isCustomWindow = String(describing: type(of: window)).contains("CustomWindow")
            return !isCustomWindow && window.rootViewController != nil
        }
        
        guard let window = appWindow,
              let rootViewController = window.rootViewController else {
            return AuditReport(viewController: "Unknown", issues: [], score: 0)
        }
        
        let topViewController = getTopViewController(from: rootViewController)
        return auditViewController(topViewController)
    }
    
    @MainActor
    public func auditViewController(_ viewController: UIViewController) -> AuditReport {
        let view = viewController.view ?? UIView()
        let issues = auditView(view)
        let score = calculateScore(issues: issues, totalElements: countAuditableElements(in: view))
        
        let report = AuditReport(
            viewController: String(describing: type(of: viewController)),
            issues: issues.sorted { $0.severity > $1.severity },
            score: score
        )
        
        currentReport = report
        return report
    }
    
    @MainActor
    public func auditView(_ view: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        issues.append(contentsOf: checkAccessibilityLabels(in: view))
        issues.append(contentsOf: checkTouchTargetSizes(in: view))
        issues.append(contentsOf: checkColorContrast(in: view))
        issues.append(contentsOf: checkDynamicTypeSupport(in: view))
        issues.append(contentsOf: checkAccessibilityTraits(in: view))
        issues.append(contentsOf: checkAccessibilityHints(in: view))
        issues.append(contentsOf: checkImageDescriptions(in: view))
        
        return issues
    }
    
    public func getComplianceScore() -> Int {
        return currentReport?.score ?? 0
    }
    
    public func exportReport() -> Data? {
        guard let report = currentReport else { return nil }
        
        var reportText = """
        Accessibility Audit Report
        ==========================
        Date: \(DateFormatter.localizedString(from: report.timestamp, dateStyle: .medium, timeStyle: .short))
        View Controller: \(report.viewController)
        Score: \(report.score)/100
        WCAG Level: \(report.wcagLevel.rawValue)
        
        Summary
        -------
        Total Issues: \(report.issues.count)
        Critical: \(report.criticalCount)
        High: \(report.highCount)
        Medium: \(report.mediumCount)
        Low: \(report.lowCount)
        
        Issues
        ------
        """
        
        for (index, issue) in report.issues.enumerated() {
            reportText += """
            
            \(index + 1). [\(issue.severity.rawValue)] \(issue.type.rawValue)
               Element: \(issue.elementDescription)
               Location: \(issue.location)
               Description: \(issue.description)
               WCAG Reference: \(issue.wcagReference)
               Fix: \(issue.fixSuggestion)
            """
            
            if let code = issue.codeExample {
                reportText += "\n   Code Example:\n   \(code.replacingOccurrences(of: "\n", with: "\n   "))"
            }
        }
        
        return reportText.data(using: .utf8)
    }
    
    @MainActor
    private func getTopViewController(from rootViewController: UIViewController) -> UIViewController {
        if let presented = rootViewController.presentedViewController {
            return getTopViewController(from: presented)
        }
        
        if let navigationController = rootViewController as? UINavigationController {
            if let topViewController = navigationController.topViewController {
                return getTopViewController(from: topViewController)
            }
        }
        
        if let tabBarController = rootViewController as? UITabBarController {
            if let selectedViewController = tabBarController.selectedViewController {
                return getTopViewController(from: selectedViewController)
            }
        }
        
        return rootViewController
    }
    
    @MainActor
    private func checkAccessibilityLabels(in view: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        func traverse(_ view: UIView, path: String = "") {
            if shouldHaveAccessibilityLabel(view) {
                let currentPath = path.isEmpty ? view.className : "\(path) > \(view.className)"
                
                if view.accessibilityLabel == nil || view.accessibilityLabel?.isEmpty == true {
                    issues.append(AccessibilityIssue(
                        severity: .critical,
                        type: .missingLabel,
                        element: view,
                        elementDescription: view.className,
                        description: "\(view.className) is missing accessibility label",
                        wcagReference: "WCAG 2.1 Level A - 4.1.2",
                        fixSuggestion: "Add meaningful accessibilityLabel to describe the element's purpose",
                        codeExample: "element.accessibilityLabel = \"Descriptive text\"",
                        location: currentPath
                    ))
                } else if let label = view.accessibilityLabel, label.count < minLabelLength {
                    issues.append(AccessibilityIssue(
                        severity: .medium,
                        type: .labelTooShort,
                        element: view,
                        elementDescription: view.className,
                        description: "Accessibility label is too short: '\(label)'",
                        wcagReference: "WCAG 2.1 Level A - 4.1.2",
                        fixSuggestion: "Provide a more descriptive label",
                        codeExample: "element.accessibilityLabel = \"More descriptive text\"",
                        location: currentPath
                    ))
                }
            }
            
            view.subviews.forEach { traverse($0, path: path.isEmpty ? view.className : "\(path) > \(view.className)") }
        }
        
        traverse(view)
        return issues
    }
    
    @MainActor
    private func checkAccessibilityHints(in view: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        func traverse(_ view: UIView, path: String = "") {
            if let hint = view.accessibilityHint, hint.count > maxHintLength {
                let currentPath = path.isEmpty ? view.className : "\(path) > \(view.className)"
                issues.append(AccessibilityIssue(
                    severity: .low,
                    type: .hintTooLong,
                    element: view,
                    elementDescription: view.className,
                    description: "Accessibility hint is too long (\(hint.count) characters)",
                    wcagReference: "Apple Human Interface Guidelines",
                    fixSuggestion: "Keep hints brief and focused",
                    codeExample: "element.accessibilityHint = \"Brief description of result\"",
                    location: currentPath
                ))
            }
            
            view.subviews.forEach { traverse($0, path: path.isEmpty ? view.className : "\(path) > \(view.className)") }
        }
        
        traverse(view)
        return issues
    }
    
    @MainActor
    private func checkTouchTargetSizes(in view: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        func traverse(_ view: UIView, path: String = "") {
            if view is UIControl || view.isAccessibilityElement {
                let frame = view.frame
                let currentPath = path.isEmpty ? view.className : "\(path) > \(view.className)"
                
                if frame.width < minimumTouchTargetSize || frame.height < minimumTouchTargetSize {
                    let severity: AccessibilityIssueSeverity = frame.width < 30 || frame.height < 30 ? .critical : .high
                    issues.append(AccessibilityIssue(
                        severity: severity,
                        type: .smallTouchTarget,
                        element: view,
                        elementDescription: view.className,
                        description: "Touch target too small: \(Int(frame.width))x\(Int(frame.height))pt (minimum: \(Int(minimumTouchTargetSize))x\(Int(minimumTouchTargetSize))pt)",
                        wcagReference: "WCAG 2.1 Level AAA - 2.5.5",
                        fixSuggestion: "Increase size to minimum 44x44pt or add padding",
                        codeExample: """
                        // Option 1: Increase frame size
                        element.frame.size = CGSize(width: 44, height: 44)
                        
                        // Option 2: Add hit target extension
                        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
                            let expandedBounds = bounds.insetBy(dx: -10, dy: -10)
                            return expandedBounds.contains(point)
                        }
                        """,
                        location: currentPath
                    ))
                }
            }
            
            view.subviews.forEach { traverse($0, path: path.isEmpty ? view.className : "\(path) > \(view.className)") }
        }
        
        traverse(view)
        return issues
    }
    
    @MainActor
    private func checkColorContrast(in view: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        func traverse(_ view: UIView, path: String = "") {
            let currentPath = path.isEmpty ? view.className : "\(path) > \(view.className)"
            
            if let label = view as? UILabel {
                let textColor = label.textColor ?? .label
                let backgroundColor = label.backgroundColor ?? view.backgroundColor ?? view.superview?.backgroundColor ?? .systemBackground
                
                let contrast = calculateContrastRatio(textColor, backgroundColor)
                let fontSize = label.font.pointSize
                let requiredContrast: CGFloat = fontSize >= 18 || (fontSize >= 14 && label.font.fontDescriptor.symbolicTraits.contains(.traitBold)) ? 3.0 : 4.5
                
                if contrast < requiredContrast {
                    issues.append(AccessibilityIssue(
                        severity: .high,
                        type: .poorContrast,
                        element: view,
                        elementDescription: view.className,
                        description: "Color contrast too low: \(String(format: "%.2f", contrast)):1 (required: \(String(format: "%.1f", requiredContrast)):1)",
                        wcagReference: "WCAG 2.1 Level AA - 1.4.3",
                        fixSuggestion: "Increase contrast between text and background colors",
                        codeExample: """
                        // Use system colors or ensure sufficient contrast
                        label.textColor = .label
                        label.backgroundColor = .systemBackground
                        """,
                        location: currentPath
                    ))
                }
            } else if let button = view as? UIButton {
                if let titleColor = button.titleColor(for: .normal) {
                    let backgroundColor = button.backgroundColor ?? view.superview?.backgroundColor ?? .systemBackground
                    let contrast = calculateContrastRatio(titleColor, backgroundColor)
                    let fontSize = button.titleLabel?.font.pointSize ?? 17
                    let requiredContrast: CGFloat = fontSize >= 18 ? 3.0 : 4.5
                    
                    if contrast < requiredContrast {
                        issues.append(AccessibilityIssue(
                            severity: .high,
                            type: .poorContrast,
                            element: view,
                            elementDescription: view.className,
                            description: "Button text contrast too low: \(String(format: "%.2f", contrast)):1",
                            wcagReference: "WCAG 2.1 Level AA - 1.4.3",
                            fixSuggestion: "Increase contrast between button text and background",
                            codeExample: "button.setTitleColor(.label, for: .normal)",
                            location: currentPath
                        ))
                    }
                }
            }
            
            view.subviews.forEach { traverse($0, path: path.isEmpty ? view.className : "\(path) > \(view.className)") }
        }
        
        traverse(view)
        return issues
    }
    
    @MainActor
    private func checkDynamicTypeSupport(in view: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        func traverse(_ view: UIView, path: String = "") {
            let currentPath = path.isEmpty ? view.className : "\(path) > \(view.className)"
            
            if let label = view as? UILabel {
                if !label.adjustsFontForContentSizeCategory {
                    let fontName = label.font.fontName
                    if !fontName.contains("System") || label.font.pointSize != UIFont.labelFontSize {
                        issues.append(AccessibilityIssue(
                            severity: .medium,
                            type: .noDynamicType,
                            element: view,
                            elementDescription: view.className,
                            description: "Label doesn't support Dynamic Type",
                            wcagReference: "WCAG 2.1 Level AA - 1.4.4",
                            fixSuggestion: "Enable Dynamic Type support for better accessibility",
                            codeExample: """
                            label.font = .preferredFont(forTextStyle: .body)
                            label.adjustsFontForContentSizeCategory = true
                            """,
                            location: currentPath
                        ))
                    }
                }
            } else if let textView = view as? UITextView {
                if !textView.adjustsFontForContentSizeCategory {
                    issues.append(AccessibilityIssue(
                        severity: .medium,
                        type: .noDynamicType,
                        element: view,
                        elementDescription: view.className,
                        description: "Text view doesn't support Dynamic Type",
                        wcagReference: "WCAG 2.1 Level AA - 1.4.4",
                        fixSuggestion: "Enable Dynamic Type support",
                        codeExample: """
                        textView.font = .preferredFont(forTextStyle: .body)
                        textView.adjustsFontForContentSizeCategory = true
                        """,
                        location: currentPath
                    ))
                }
            }
            
            view.subviews.forEach { traverse($0, path: path.isEmpty ? view.className : "\(path) > \(view.className)") }
        }
        
        traverse(view)
        return issues
    }
    
    @MainActor
    private func checkAccessibilityTraits(in view: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        func traverse(_ view: UIView, path: String = "") {
            let currentPath = path.isEmpty ? view.className : "\(path) > \(view.className)"
            
            if view is UIButton {
                if !view.accessibilityTraits.contains(.button) {
                    issues.append(AccessibilityIssue(
                        severity: .medium,
                        type: .missingTrait,
                        element: view,
                        elementDescription: view.className,
                        description: "Button missing .button trait",
                        wcagReference: "WCAG 2.1 Level A - 4.1.2",
                        fixSuggestion: "Add .button trait to UIButton elements",
                        codeExample: "button.accessibilityTraits = .button",
                        location: currentPath
                    ))
                }
            } else if view is UIImageView, view.isAccessibilityElement {
                if !view.accessibilityTraits.contains(.image) {
                    issues.append(AccessibilityIssue(
                        severity: .low,
                        type: .missingTrait,
                        element: view,
                        elementDescription: view.className,
                        description: "Image missing .image trait",
                        wcagReference: "WCAG 2.1 Level A - 4.1.2",
                        fixSuggestion: "Add .image trait to accessible images",
                        codeExample: "imageView.accessibilityTraits = .image",
                        location: currentPath
                    ))
                }
            }
            
            view.subviews.forEach { traverse($0, path: path.isEmpty ? view.className : "\(path) > \(view.className)") }
        }
        
        traverse(view)
        return issues
    }
    
    @MainActor
    private func checkImageDescriptions(in view: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        func traverse(_ view: UIView, path: String = "") {
            let currentPath = path.isEmpty ? view.className : "\(path) > \(view.className)"
            
            if let imageView = view as? UIImageView, imageView.image != nil {
                if imageView.isAccessibilityElement && (imageView.accessibilityLabel == nil || imageView.accessibilityLabel?.isEmpty == true) {
                    issues.append(AccessibilityIssue(
                        severity: .high,
                        type: .missingImageDescription,
                        element: view,
                        elementDescription: view.className,
                        description: "Image missing accessibility description",
                        wcagReference: "WCAG 2.1 Level A - 1.1.1",
                        fixSuggestion: "Add accessibility label describing image content",
                        codeExample: "imageView.accessibilityLabel = \"Description of image\"",
                        location: currentPath
                    ))
                }
            }
            
            view.subviews.forEach { traverse($0, path: path.isEmpty ? view.className : "\(path) > \(view.className)") }
        }
        
        traverse(view)
        return issues
    }
    
    @MainActor
    private func shouldHaveAccessibilityLabel(_ view: UIView) -> Bool {
        return (view is UIButton ||
                view is UIImageView ||
                view is UIControl ||
                view.isAccessibilityElement) &&
                !view.accessibilityElementsHidden
    }
    
    private func calculateContrastRatio(_ color1: UIColor, _ color2: UIColor) -> CGFloat {
        let l1 = relativeLuminance(color1)
        let l2 = relativeLuminance(color2)
        
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    private func relativeLuminance(_ color: UIColor) -> CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        func adjust(_ c: CGFloat) -> CGFloat {
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        
        return 0.2126 * adjust(r) + 0.7152 * adjust(g) + 0.0722 * adjust(b)
    }
    
    @MainActor
    private func countAuditableElements(in view: UIView) -> Int {
        var count = 0
        
        func traverse(_ view: UIView) {
            if shouldHaveAccessibilityLabel(view) || view is UILabel {
                count += 1
            }
            view.subviews.forEach { traverse($0) }
        }
        
        traverse(view)
        return max(count, 1)
    }
    
    private func calculateScore(issues: [AccessibilityIssue], totalElements: Int) -> Int {
        let criticalWeight = 10.0
        let highWeight = 5.0
        let mediumWeight = 2.0
        let lowWeight = 1.0
        
        let criticalPenalty = Double(issues.filter { $0.severity == .critical }.count) * criticalWeight
        let highPenalty = Double(issues.filter { $0.severity == .high }.count) * highWeight
        let mediumPenalty = Double(issues.filter { $0.severity == .medium }.count) * mediumWeight
        let lowPenalty = Double(issues.filter { $0.severity == .low }.count) * lowWeight
        
        let totalPenalty = criticalPenalty + highPenalty + mediumPenalty + lowPenalty
        let maxPenalty = Double(totalElements) * criticalWeight
        
        let score = max(0, 100 - Int((totalPenalty / max(maxPenalty, 1)) * 100))
        
        return score
    }
}

private extension UIView {
    var className: String {
        return String(describing: type(of: self))
    }
}
