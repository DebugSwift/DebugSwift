//
//  AccessibilityAuditorTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 07/03/26.
//

import XCTest
@testable import DebugSwift

@MainActor
class AccessibilityAuditorTests: XCTestCase {
    
    var auditor: AccessibilityAuditor!
    
    override func setUp() async throws {
        try await super.setUp()
        auditor = AccessibilityAuditor.shared
    }
    
    override func tearDown() async throws {
        auditor = nil
        try await super.tearDown()
    }
    
    func testMissingAccessibilityLabel() {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        
        let issues = auditor.auditView(button)
        
        XCTAssertTrue(issues.contains { $0.type == .missingLabel })
        let missingLabelIssue = issues.first { $0.type == .missingLabel }
        XCTAssertEqual(missingLabelIssue?.severity, .critical)
    }
    
    func testButtonWithAccessibilityLabel() {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        button.accessibilityLabel = "Submit Button"
        
        let issues = auditor.auditView(button)
        
        XCTAssertFalse(issues.contains { $0.type == .missingLabel })
    }
    
    func testSmallTouchTarget() {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.accessibilityLabel = "Small Button"
        
        let issues = auditor.auditView(button)
        
        XCTAssertTrue(issues.contains { $0.type == .smallTouchTarget })
        let touchTargetIssue = issues.first { $0.type == .smallTouchTarget }
        XCTAssertEqual(touchTargetIssue?.severity, .critical)
    }
    
    func testValidTouchTarget() {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        button.accessibilityLabel = "Valid Button"
        
        let issues = auditor.auditView(button)
        
        XCTAssertFalse(issues.contains { $0.type == .smallTouchTarget })
    }
    
    func testColorContrastCalculation() {
        let blackColor = UIColor.black
        let whiteColor = UIColor.white
        
        let testView = UIView()
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        label.textColor = blackColor
        label.backgroundColor = whiteColor
        label.text = "Test"
        testView.addSubview(label)
        
        let issues = auditor.auditView(testView)
        
        XCTAssertFalse(issues.contains { $0.type == .poorContrast })
    }
    
    func testPoorColorContrast() {
        let testView = UIView()
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        label.textColor = UIColor(white: 0.5, alpha: 1.0)
        label.backgroundColor = UIColor(white: 0.6, alpha: 1.0)
        label.text = "Test"
        testView.addSubview(label)
        
        let issues = auditor.auditView(testView)
        
        XCTAssertTrue(issues.contains { $0.type == .poorContrast })
    }
    
    func testDynamicTypeSupport() {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        label.text = "Test"
        label.font = UIFont.systemFont(ofSize: 20)
        label.adjustsFontForContentSizeCategory = false
        
        let issues = auditor.auditView(label)
        
        XCTAssertTrue(issues.contains { $0.type == .noDynamicType })
    }
    
    func testDynamicTypeSupportEnabled() {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        label.text = "Test"
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        
        let issues = auditor.auditView(label)
        
        XCTAssertFalse(issues.contains { $0.type == .noDynamicType })
    }
    
    func testMissingButtonTrait() {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        button.accessibilityLabel = "Test Button"
        button.accessibilityTraits = []
        
        let issues = auditor.auditView(button)
        
        XCTAssertTrue(issues.contains { $0.type == .missingTrait })
    }
    
    func testButtonWithCorrectTrait() {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        button.accessibilityLabel = "Test Button"
        button.accessibilityTraits = .button
        
        let issues = auditor.auditView(button)
        
        XCTAssertFalse(issues.contains { $0.type == .missingTrait })
    }
    
    func testMissingImageDescription() {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        imageView.image = UIImage()
        imageView.isAccessibilityElement = true
        
        let issues = auditor.auditView(imageView)
        
        XCTAssertTrue(issues.contains { $0.type == .missingImageDescription })
    }
    
    func testImageWithDescription() {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        imageView.image = UIImage()
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = "Profile picture"
        
        let issues = auditor.auditView(imageView)
        
        XCTAssertFalse(issues.contains { $0.type == .missingImageDescription })
    }
    
    func testHintTooLong() {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        button.accessibilityLabel = "Submit"
        button.accessibilityHint = String(repeating: "This is a very long hint that exceeds the recommended length. ", count: 3)
        
        let issues = auditor.auditView(button)
        
        XCTAssertTrue(issues.contains { $0.type == .hintTooLong })
    }
    
    func testLabelTooShort() {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        button.accessibilityLabel = "A"
        
        let issues = auditor.auditView(button)
        
        XCTAssertTrue(issues.contains { $0.type == .labelTooShort })
    }
    
    func testScoreCalculation() {
        let testView = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        
        let goodButton = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        goodButton.accessibilityLabel = "Good Button"
        goodButton.accessibilityTraits = .button
        testView.addSubview(goodButton)
        
        let badButton = UIButton(frame: CGRect(x: 0, y: 100, width: 30, height: 30))
        testView.addSubview(badButton)
        
        let report = AuditReport(
            viewController: "TestViewController",
            issues: auditor.auditView(testView),
            score: 50
        )
        
        XCTAssertGreaterThan(report.score, 0)
        XCTAssertLessThanOrEqual(report.score, 100)
    }
    
    func testWCAGLevelCalculation() {
        let reportAAA = AuditReport(viewController: "Test", issues: [], score: 98)
        XCTAssertEqual(reportAAA.wcagLevel, .AAA)
        
        let reportAA = AuditReport(viewController: "Test", issues: [], score: 85)
        XCTAssertEqual(reportAA.wcagLevel, .AA)
        
        let reportA = AuditReport(viewController: "Test", issues: [], score: 70)
        XCTAssertEqual(reportA.wcagLevel, .A)
        
        let reportNonCompliant = AuditReport(viewController: "Test", issues: [], score: 50)
        XCTAssertEqual(reportNonCompliant.wcagLevel, .nonCompliant)
    }
    
    func testExportReport() {
        let issues = [
            AccessibilityIssue(
                severity: .critical,
                type: .missingLabel,
                element: nil,
                elementDescription: "UIButton",
                description: "Button is missing accessibility label",
                wcagReference: "WCAG 2.1 Level A - 4.1.2",
                fixSuggestion: "Add accessibility label",
                codeExample: "button.accessibilityLabel = \"Submit\"",
                location: "ViewController"
            )
        ]
        
        let report = AuditReport(
            viewController: "TestViewController",
            issues: issues,
            score: 75
        )
        
        let auditor = AccessibilityAuditor.shared
        let testView = UIView()
        _ = auditor.auditView(testView)
        
        let exportData = auditor.exportReport()
        
        XCTAssertNotNil(exportData)
    }
    
    func testIssueSeverityComparison() {
        XCTAssertTrue(AccessibilityIssueSeverity.low < .medium)
        XCTAssertTrue(AccessibilityIssueSeverity.medium < .high)
        XCTAssertTrue(AccessibilityIssueSeverity.high < .critical)
    }
    
    func testMultipleIssuesInSingleView() {
        let testView = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        
        let button1 = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        testView.addSubview(button1)
        
        let button2 = UIButton(frame: CGRect(x: 0, y: 50, width: 100, height: 44))
        testView.addSubview(button2)
        
        let label = UILabel(frame: CGRect(x: 0, y: 100, width: 100, height: 44))
        label.text = "Test"
        label.font = UIFont.systemFont(ofSize: 20)
        label.adjustsFontForContentSizeCategory = false
        testView.addSubview(label)
        
        let issues = auditor.auditView(testView)
        
        XCTAssertGreaterThan(issues.count, 0)
        XCTAssertTrue(issues.contains { $0.type == .missingLabel })
        XCTAssertTrue(issues.contains { $0.type == .smallTouchTarget })
    }
    
    func testReportIssueCounts() {
        let issues = [
            AccessibilityIssue(
                severity: .critical,
                type: .missingLabel,
                element: nil,
                elementDescription: "UIButton",
                description: "Test",
                wcagReference: "WCAG 2.1",
                fixSuggestion: "Fix it",
                location: "Test"
            ),
            AccessibilityIssue(
                severity: .critical,
                type: .smallTouchTarget,
                element: nil,
                elementDescription: "UIButton",
                description: "Test",
                wcagReference: "WCAG 2.1",
                fixSuggestion: "Fix it",
                location: "Test"
            ),
            AccessibilityIssue(
                severity: .high,
                type: .poorContrast,
                element: nil,
                elementDescription: "UILabel",
                description: "Test",
                wcagReference: "WCAG 2.1",
                fixSuggestion: "Fix it",
                location: "Test"
            ),
            AccessibilityIssue(
                severity: .medium,
                type: .noDynamicType,
                element: nil,
                elementDescription: "UILabel",
                description: "Test",
                wcagReference: "WCAG 2.1",
                fixSuggestion: "Fix it",
                location: "Test"
            ),
            AccessibilityIssue(
                severity: .low,
                type: .hintTooLong,
                element: nil,
                elementDescription: "UIButton",
                description: "Test",
                wcagReference: "WCAG 2.1",
                fixSuggestion: "Fix it",
                location: "Test"
            )
        ]
        
        let report = AuditReport(viewController: "Test", issues: issues, score: 50)
        
        XCTAssertEqual(report.criticalCount, 2)
        XCTAssertEqual(report.highCount, 1)
        XCTAssertEqual(report.mediumCount, 1)
        XCTAssertEqual(report.lowCount, 1)
        XCTAssertEqual(report.issues.count, 5)
    }
}
