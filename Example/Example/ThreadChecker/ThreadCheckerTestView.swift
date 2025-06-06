//
//  ThreadCheckerTestView.swift
//  Example
//
//  Created by DebugSwift on 2024.
//

import SwiftUI
import DebugSwift

@available(iOS 14.0, *)
struct ThreadCheckerTestView: View {
    @State private var testResults: [String] = []
    @State private var isRunning = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("ThreadChecker Test Suite")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                VStack(spacing: 15) {
                    // Control buttons
                    HStack(spacing: 15) {
                        Button("Enable ThreadChecker") {
                            PerformanceThreadChecker.shared.enable()
                            addResult("✅ ThreadChecker enabled")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(8)
                        
                        Button("Disable ThreadChecker") {
                            PerformanceThreadChecker.shared.disable()
                            addResult("❌ ThreadChecker disabled")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(8)
                    }
                    
                    HStack(spacing: 15) {
                        Button("Enable Auto-Fix") {
                            PerformanceThreadChecker.shared.enableAutoFix()
                            addResult("🔧 Auto-fix enabled")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                        
                        Button("Clear Violations") {
                            PerformanceThreadChecker.shared.clearViolations()
                            addResult("🗑️ Violations cleared")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(8)
                    }
                }
                .padding()
                
                Divider()
                
                VStack(spacing: 15) {
                    Text("Test Scenarios")
                        .font(.headline)
                    
                    Button("Test Manual Check (Main Thread)") {
                        testManualCheckMainThread()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(8)
                    
                    Button("Test Manual Check (Background Thread)") {
                        testManualCheckBackgroundThread()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(8)
                    
                    Button("Test UI Operations on Background Thread") {
                        testUIOperationsOnBackgroundThread()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(8)
                    
                    Button("Test Different Severity Levels") {
                        testDifferentSeverityLevels()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(8)
                    
                    Button("Test Ignored Classes") {
                        testIgnoredClasses()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(8)
                    
                    Button("Stress Test (Multiple Violations)") {
                        stressTest()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(8)
                }
                .padding()
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Test Results")
                        .font(.headline)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 5) {
                            ForEach(testResults.indices, id: \.self) { index in
                                Text(testResults[index])
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                    }
                    .frame(maxHeight: 200)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("ThreadChecker Test")
            .onAppear {
                setupThreadChecker()
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupThreadChecker() {
        // Enable ThreadChecker by default
        DebugSwift.Performance.ThreadChecker.enable()
        DebugSwift.Performance.ThreadChecker.setShowVisualAlerts(true)
        DebugSwift.Performance.ThreadChecker.setLogToConsole(true)
        
        addResult("🚀 ThreadChecker initialized and ready for testing")
    }
    
    // MARK: - Test Methods
    
    private func testManualCheckMainThread() {
        addResult("Testing manual check on main thread...")
        
        // This should NOT trigger a violation since we're on main thread
        PerformanceThreadChecker.shared.checkMainThread(
            methodName: "testMethod",
            className: "ThreadCheckerTestView"
        )
        
        addResult("✅ Main thread check completed (should be no violation)")
    }
    
    private func testManualCheckBackgroundThread() {
        addResult("Testing manual check on background thread...")
        
        DispatchQueue.global(qos: .background).async {
            // This SHOULD trigger a violation since we're on background thread
            PerformanceThreadChecker.shared.checkMainThread(
                methodName: "backgroundTestMethod",
                className: "ThreadCheckerTestView"
            )
            
            DispatchQueue.main.async {
                self.addResult("⚠️ Background thread check completed (should trigger violation)")
            }
        }
    }
    
    private func testUIOperationsOnBackgroundThread() {
        addResult("Testing UI operations on background thread...")
        
        DispatchQueue.global(qos: .background).async {
            // Simulate UI operations that would normally trigger violations
            PerformanceThreadChecker.shared.checkMainThread(
                methodName: "setNeedsLayout",
                className: "UIView"
            )
            
            PerformanceThreadChecker.shared.checkMainThread(
                methodName: "setNeedsDisplay",
                className: "UIView"
            )
            
            PerformanceThreadChecker.shared.checkMainThread(
                methodName: "removeFromSuperview",
                className: "UIView"
            )
            
            DispatchQueue.main.async {
                self.addResult("⚠️ UI operations simulation completed")
            }
        }
    }
    
    private func testDifferentSeverityLevels() {
        addResult("Testing different severity levels...")
        
        DispatchQueue.global(qos: .background).async {
            // Warning level
            PerformanceThreadChecker.shared.checkMainThread(
                methodName: "setNeedsLayout",
                className: "UIView"
            )
            
            // Error level
            PerformanceThreadChecker.shared.checkMainThread(
                methodName: "removeFromSuperview",
                className: "UIView"
            )
            
            // Critical level
            PerformanceThreadChecker.shared.checkMainThread(
                methodName: "addSubview",
                className: "UIView"
            )
            
            DispatchQueue.main.async {
                self.addResult("⚠️❌🚨 Different severity levels tested")
            }
        }
    }
    
    private func testIgnoredClasses() {
        addResult("Testing ignored classes...")
        
        // Add a test class to ignored list
        DebugSwift.Performance.ThreadChecker.ignoreClass("TestIgnoredClass")
        
        DispatchQueue.global(qos: .background).async {
            // This should NOT trigger a violation due to ignored class
            PerformanceThreadChecker.shared.checkMainThread(
                methodName: "testMethod",
                className: "TestIgnoredClass"
            )
            
            DispatchQueue.main.async {
                self.addResult("🚫 Ignored class test completed (should be no violation)")
            }
        }
    }
    
    private func stressTest() {
        addResult("Starting stress test...")
        isRunning = true
        
        let dispatchGroup = DispatchGroup()
        
        // Create multiple background threads with violations
        for i in 1...10 {
            dispatchGroup.enter()
            DispatchQueue.global(qos: .background).async {
                PerformanceThreadChecker.shared.checkMainThread(
                    methodName: "stressTest_\(i)",
                    className: "StressTestClass"
                )
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.isRunning = false
            self.addResult("💥 Stress test completed (10 violations generated)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func addResult(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        testResults.append("[\(timestamp)] \(message)")
    }
}

// MARK: - Preview

@available(iOS 14.0, *)
struct ThreadCheckerTestView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadCheckerTestView()
    }
} 
