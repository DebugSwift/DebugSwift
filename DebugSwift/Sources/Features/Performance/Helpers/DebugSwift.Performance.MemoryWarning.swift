//
//  Performance.MemoryWarning.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/05/24.
//

import UIKit
import os.log

@MainActor
final class PerformanceMemoryWarning {
    
    // MARK: - Properties
    
    private var isSimulating = false
    private var allocatedMemory: [UnsafeMutableRawPointer] = []
    
    private var logger: Any? {
        if #available(iOS 14.0, *) {
            return Logger(subsystem: "DebugSwift", category: "MemoryWarning")
        }
        return nil
    }
    
    private func log(_ message: String, type: LogType = .info) {
        if #available(iOS 14.0, *), let logger = logger as? Logger {
            switch type {
            case .info:
                logger.info("\(message)")
            case .warning:
                logger.warning("\(message)")
            case .error:
                logger.error("\(message)")
            case .debug:
                logger.debug("\(message)")
            }
        } else {
            print("[MemoryWarning] \(message)")
        }
    }
    
    private enum LogType {
        case info, warning, error, debug
    }
    
    // MARK: - Public Methods
    
    /// Generates a memory warning with realistic memory pressure
    func generate() {
        guard !isSimulating else {
            log("Memory warning simulation already in progress", type: .warning)
            return
        }
        
        isSimulating = true
        log("🚨 Starting memory warning simulation...")
        
        // Perform the warning immediately
        performSystemMemoryWarning()
        
        // Create realistic memory pressure in background
        Task.detached(priority: .background) { [weak self] in
            await self?.simulateMemoryPressure()
        }
    }
    
    // MARK: - Private Methods
    
    private func performSystemMemoryWarning() {
        // Method 1: Use the private API (most effective)
        if UIApplication.shared.responds(to: Selector(("_performMemoryWarning"))) {
            UIApplication.shared.perform(Selector(("_performMemoryWarning")))
            log("✅ System memory warning triggered via private API")
        }
        
        // Method 2: Send memory warning notification manually
        NotificationCenter.default.post(
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: UIApplication.shared
        )
        log("📢 Memory warning notification sent")
        
        // Method 3: Trigger on all view controllers in the hierarchy
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            triggerMemoryWarningOnViewController(rootViewController)
            log("🎯 Memory warning sent to view controller hierarchy")
        }
    }
    
    private func triggerMemoryWarningOnViewController(_ viewController: UIViewController) {
        // Trigger memory warning on the view controller
        viewController.didReceiveMemoryWarning()
        
        // Recursively trigger on child view controllers
        for child in viewController.children {
            triggerMemoryWarningOnViewController(child)
        }
        
        // Handle presented view controllers
        if let presented = viewController.presentedViewController {
            triggerMemoryWarningOnViewController(presented)
        }
    }
    
    private func simulateMemoryPressure() async {
        let chunkSize = 10 * 1024 * 1024 // 10MB chunks
        let maxChunks = 50 // Max 500MB
        
        await MainActor.run {
            self.log("🔥 Simulating memory pressure with \(maxChunks) chunks of 10MB each")
        }
        
        // Allocate memory in chunks to create realistic pressure
        for i in 0..<maxChunks {
            // Check if we should stop (app might have been backgrounded or memory warning handled)
            if !self.isSimulating {
                break
            }
            
            if let memory = malloc(chunkSize) {
                // Fill with random data to prevent optimization
                let buffer = memory.assumingMemoryBound(to: UInt8.self)
                for j in 0..<chunkSize {
                    buffer[j] = UInt8.random(in: 0...255)
                }
                
                await MainActor.run {
                    self.allocatedMemory.append(memory)
                    self.log("📈 Allocated chunk \(i + 1)/\(maxChunks) - Current chunks: \(self.allocatedMemory.count)", type: .debug)
                }
                
                // Wait between allocations to create gradual pressure
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            } else {
                await MainActor.run {
                    self.log("❌ Failed to allocate memory chunk \(i + 1)", type: .error)
                }
                break
            }
        }
        
        // Hold memory for a brief period
        await MainActor.run {
            self.log("⏳ Maintaining memory pressure for 2 seconds...")
        }
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Cleanup
        await cleanupAllocatedMemory()
    }
    
    private func cleanupAllocatedMemory() async {
        await MainActor.run {
            self.log("🧹 Cleaning up allocated memory...")
            
            for memory in self.allocatedMemory {
                free(memory)
            }
            self.allocatedMemory.removeAll()
            self.isSimulating = false
            self.log("✨ Memory cleanup completed")
        }
        
        // Force garbage collection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // This will trigger any remaining cleanup
            autoreleasepool {
                // Empty autoreleasepool to trigger cleanup
            }
        }
    }
    
    // MARK: - Public Utilities
    
    /// Returns the current simulation status
    var isCurrentlySimulating: Bool {
        return isSimulating
    }
    
    /// Manually stops the memory pressure simulation
    func stopSimulation() {
        guard isSimulating else { return }
        
        log("🛑 Manually stopping memory warning simulation")
        isSimulating = false
        
        Task.detached(priority: .background) { [weak self] in
            await self?.cleanupAllocatedMemory()
        }
    }
}
