//
//  ThreadCheckerUIKitTestView.swift
//  Example
//
//  Created by DebugSwift on 2024.
//

import UIKit
import DebugSwift

class ThreadCheckerUIKitTestViewController: UIViewController {
    
    private var testView: UIView!
    private var testLabel: UILabel!
    private var resultsTextView: UITextView!
    private var stackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupThreadChecker()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "UIKit ThreadChecker Test"
        
        // Create scroll view to contain everything
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Create main stack view
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        // Add header
        let headerLabel = UILabel()
        headerLabel.text = "UIKit ThreadChecker Test Suite"
        headerLabel.font = .boldSystemFont(ofSize: 20)
        headerLabel.textAlignment = .center
        stackView.addArrangedSubview(headerLabel)
        
        // Add control buttons
        let controlsStack = createControlButtons()
        stackView.addArrangedSubview(controlsStack)
        
        // Add test buttons
        let testsStack = createTestButtons()
        stackView.addArrangedSubview(testsStack)
        
        // Add test view for manipulation
        testView = UIView()
        testView.backgroundColor = .systemBlue
        testView.layer.cornerRadius = 8
        testView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(testView)
        
        testLabel = UILabel()
        testLabel.text = "Test View for UI Operations"
        testLabel.textColor = .white
        testLabel.textAlignment = .center
        testLabel.translatesAutoresizingMaskIntoConstraints = false
        testView.addSubview(testLabel)
        
        // Add results text view
        resultsTextView = UITextView()
        resultsTextView.isEditable = false
        resultsTextView.backgroundColor = .systemGray6
        resultsTextView.layer.cornerRadius = 8
        resultsTextView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        resultsTextView.text = "Test results will appear here...\n"
        resultsTextView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(resultsTextView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
            
            testView.heightAnchor.constraint(equalToConstant: 80),
            
            testLabel.centerXAnchor.constraint(equalTo: testView.centerXAnchor),
            testLabel.centerYAnchor.constraint(equalTo: testView.centerYAnchor),
            
            resultsTextView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func createControlButtons() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        
        let row1 = UIStackView()
        row1.axis = .horizontal
        row1.distribution = .fillEqually
        row1.spacing = 10
        
        let enableButton = createButton(title: "Enable ThreadChecker", color: .systemGreen) {
            PerformanceThreadChecker.shared.enable()
            self.addResult("✅ ThreadChecker enabled")
        }
        
        let disableButton = createButton(title: "Disable ThreadChecker", color: .systemRed) {
            PerformanceThreadChecker.shared.disable()
            self.addResult("❌ ThreadChecker disabled")
        }
        
        row1.addArrangedSubview(enableButton)
        row1.addArrangedSubview(disableButton)
        
        let row2 = UIStackView()
        row2.axis = .horizontal
        row2.distribution = .fillEqually
        row2.spacing = 10
        
        let autoFixButton = createButton(title: "Enable Auto-Fix", color: .systemBlue) {
            PerformanceThreadChecker.shared.enableAutoFix()
            self.addResult("🔧 Auto-fix enabled")
        }
        
        let clearButton = createButton(title: "Clear Violations", color: .systemOrange) {
            PerformanceThreadChecker.shared.clearViolations()
            self.addResult("🗑️ Violations cleared")
        }
        
        row2.addArrangedSubview(autoFixButton)
        row2.addArrangedSubview(clearButton)
        
        stack.addArrangedSubview(row1)
        stack.addArrangedSubview(row2)
        
        return stack
    }
    
    private func createTestButtons() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        
        let tests = [
            ("Test setNeedsLayout", testSetNeedsLayout),
            ("Test setNeedsDisplay", testSetNeedsDisplay),
            ("Test addSubview", testAddSubview),
            ("Test removeFromSuperview", testRemoveFromSuperview),
            ("Test layoutIfNeeded", testLayoutIfNeeded),
            ("Test isHidden", testIsHidden),
            ("Stress Test (All)", stressTestAll)
        ]
        
        for (title, action) in tests {
            let button = createButton(title: title, color: .systemPurple, action: action)
            stack.addArrangedSubview(button)
        }
        
        return stack
    }
    
    private func createButton(title: String, color: UIColor, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = color
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        
        // Use target-action pattern for iOS 14 compatibility
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        button.tag = buttonActions.count
        buttonActions.append(action)
        
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return button
    }
    
    // Store button actions for target-action pattern
    private var buttonActions: [() -> Void] = []
    
    @objc private func buttonTapped(_ sender: UIButton) {
        if sender.tag < buttonActions.count {
            buttonActions[sender.tag]()
        }
    }
    
    private func setupThreadChecker() {
        DebugSwift.Performance.ThreadChecker.enable()
        DebugSwift.Performance.ThreadChecker.setShowVisualAlerts(true)
        DebugSwift.Performance.ThreadChecker.setLogToConsole(true)
        
        addResult("🚀 UIKit ThreadChecker test initialized")
    }
    
    // MARK: - Test Methods
    
    private func testSetNeedsLayout() {
        addResult("Testing setNeedsLayout on background thread...")
        
        DispatchQueue.global(qos: .background).async {
            // This should trigger a violation when performed on background thread
            DispatchQueue.main.async {
                // First show what happens on main thread (no violation)
                self.testView.setNeedsLayout()
                self.addResult("✅ setNeedsLayout on main thread - OK")
            }
            
            // Simulate background thread violation
            PerformanceThreadChecker.shared.checkMainThread(
                methodName: "setNeedsLayout",
                className: "UIView"
            )
            
            DispatchQueue.main.async {
                self.addResult("⚠️ setNeedsLayout violation simulated")
            }
        }
    }
    
    private func testSetNeedsDisplay() {
        addResult("Testing setNeedsDisplay on background thread...")
        
        DispatchQueue.global(qos: .background).async {
            // Simulate background thread violation
            PerformanceThreadChecker.shared.checkMainThread(
                methodName: "setNeedsDisplay",
                className: "UIView"
            )
            
            DispatchQueue.main.async {
                self.testView.setNeedsDisplay()
                self.addResult("⚠️ setNeedsDisplay violation simulated")
            }
        }
    }
    
    private func testAddSubview() {
        addResult("Testing addSubview on background thread...")
        
        DispatchQueue.global(qos: .background).async {
            // Simulate background thread violation (critical level)
            PerformanceThreadChecker.shared.checkMainThread(
                methodName: "addSubview",
                className: "UIView"
            )
            
            DispatchQueue.main.async {
                let tempView = UIView()
                tempView.backgroundColor = .systemRed
                tempView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
                self.testView.addSubview(tempView)
                
                // Remove it after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    tempView.removeFromSuperview()
                }
                
                self.addResult("🚨 addSubview violation simulated (critical)")
            }
        }
    }
    
    private func testRemoveFromSuperview() {
        addResult("Testing removeFromSuperview on background thread...")
        
        // First add a temporary view
        let tempView = UIView()
        tempView.backgroundColor = .systemYellow
        tempView.frame = CGRect(x: 10, y: 10, width: 30, height: 30)
        testView.addSubview(tempView)
        
        DispatchQueue.global(qos: .background).async {
            // Simulate background thread violation
            PerformanceThreadChecker.shared.checkMainThread(
                methodName: "removeFromSuperview",
                className: "UIView"
            )
            
            DispatchQueue.main.async {
                tempView.removeFromSuperview()
                self.addResult("❌ removeFromSuperview violation simulated (error)")
            }
        }
    }
    
    private func testLayoutIfNeeded() {
        addResult("Testing layoutIfNeeded on background thread...")
        
        DispatchQueue.global(qos: .background).async {
            // Simulate background thread violation
            PerformanceThreadChecker.shared.checkMainThread(
                methodName: "layoutIfNeeded",
                className: "UIView"
            )
            
            DispatchQueue.main.async {
                self.testView.layoutIfNeeded()
                self.addResult("⚠️ layoutIfNeeded violation simulated")
            }
        }
    }
    
    private func testIsHidden() {
        addResult("Testing isHidden setter on background thread...")
        
        DispatchQueue.global(qos: .background).async {
            // Simulate background thread violation
            PerformanceThreadChecker.shared.checkMainThread(
                methodName: "setHidden",
                className: "UIView"
            )
            
            DispatchQueue.main.async {
                self.testView.isHidden = !self.testView.isHidden
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.testView.isHidden = !self.testView.isHidden
                }
                self.addResult("⚠️ setHidden violation simulated")
            }
        }
    }
    
    private func stressTestAll() {
        addResult("Starting stress test - all violations...")
        
        let operations = ["setNeedsLayout", "setNeedsDisplay", "addSubview", "removeFromSuperview", "layoutIfNeeded"]
        
        for (index, operation) in operations.enumerated() {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + Double(index) * 0.2) {
                PerformanceThreadChecker.shared.checkMainThread(
                    methodName: operation,
                    className: "UIView"
                )
                
                DispatchQueue.main.async {
                    if index == operations.count - 1 {
                        self.addResult("💥 Stress test completed - \(operations.count) violations")
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func addResult(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let newText = "[\(timestamp)] \(message)\n"
        
        DispatchQueue.main.async {
            self.resultsTextView.text += newText
            
            // Scroll to bottom
            let bottom = NSMakeRange(self.resultsTextView.text.count - 1, 1)
            self.resultsTextView.scrollRangeToVisible(bottom)
        }
    }
}

// MARK: - SwiftUI Wrapper

import SwiftUI

@available(iOS 14.0, *)
struct ThreadCheckerUIKitTestView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ThreadCheckerUIKitTestViewController {
        return ThreadCheckerUIKitTestViewController()
    }
    
    func updateUIViewController(_ uiViewController: ThreadCheckerUIKitTestViewController, context: Context) {
        // No updates needed
    }
} 
