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
    private let logger = Logger(subsystem: "DebugSwift", category: "MemoryWarning")
    
    // MARK: - Public Methods
    
    /// Generates a memory warning with realistic memory pressure
    func generate() {
        guard !isSimulating else {
            logger.warning("Memory warning simulation already in progress")
            return
        }
        
        isSimulating = true
        logger.info("🚨 Starting memory warning simulation...")
        
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
            logger.info("✅ System memory warning triggered via private API")
        }
        
        // Method 2: Send memory warning notification manually
        NotificationCenter.default.post(
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: UIApplication.shared
        )
        logger.info("📢 Memory warning notification sent")
        
        // Method 3: Trigger on all view controllers in the hierarchy
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            triggerMemoryWarningOnViewController(rootViewController)
            logger.info("🎯 Memory warning sent to view controller hierarchy")
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
        
        self.logger.info("🔥 Simulating memory pressure with \(maxChunks) chunks of 10MB each")
        
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
                
                self.allocatedMemory.append(memory)
                self.logger.debug("📈 Allocated chunk \(i + 1)/\(maxChunks) - Current chunks: \(self.allocatedMemory.count)")
                
                // Wait between allocations to create gradual pressure
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            } else {
                self.logger.error("❌ Failed to allocate memory chunk \(i + 1)")
                break
            }
        }
        
        // Hold memory for a brief period
        self.logger.info("⏳ Maintaining memory pressure for 2 seconds...")
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Cleanup
        await cleanupAllocatedMemory()
    }
    
    private func cleanupAllocatedMemory() async {
        self.logger.info("🧹 Cleaning up allocated memory...")
        
        await MainActor.run {
            for memory in self.allocatedMemory {
                free(memory)
            }
            self.allocatedMemory.removeAll()
            self.isSimulating = false
            self.logger.info("✨ Memory cleanup completed")
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
        
        logger.info("🛑 Manually stopping memory warning simulation")
        isSimulating = false
        
        Task.detached(priority: .background) { [weak self] in
            await self?.cleanupAllocatedMemory()
        }
    }
}
