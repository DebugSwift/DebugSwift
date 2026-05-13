//
//  OSLogMonitor.swift
//  DebugSwift
//
//  Created by Matheus Gois on 12/05/26.
//

import Foundation
import OSLog

@available(iOS 15.0, *)
final class OSLogMonitor: @unchecked Sendable {
    static let shared = OSLogMonitor()
    
    private(set) var entries: [OSLogEntry] = []
    private(set) var isCapturing = false
    private(set) var isLoading = false
    private(set) var availableSubsystems: [String] = []
    
    // Filter configuration
    var ignoredSubsystemPrefixes: [String] = ["com.apple"]
    var showAppleSubsystems: Bool {
        get { !ignoredSubsystemPrefixes.contains("com.apple") }
        set {
            if newValue {
                ignoredSubsystemPrefixes.removeAll { $0 == "com.apple" }
            } else if !ignoredSubsystemPrefixes.contains("com.apple") {
                ignoredSubsystemPrefixes.append("com.apple")
            }
        }
    }
    
    private var refreshTimer: Timer?
    private var refCount = 0
    private var captureStartDate: Date?
    private var lastLogPollDate: Date?
    private var seenLogIDs = Set<String>()
    private var subsystemSet = Set<String>()
    
    private static let maxEntries = 5000
    private let pollQueue = DispatchQueue(label: "com.debugswift.oslog.poll", qos: .utility)
    private let subsystemLock = NSLock()
    
    var onEntriesUpdated: (() -> Void)?
    var onLoadingChanged: ((Bool) -> Void)?
    var onSubsystemsUpdated: (([String]) -> Void)?
    
    private init() {}
    
    // MARK: - Lifecycle
    
    func start() {
        refCount += 1
        guard refreshTimer == nil else { return }
        
        let now = Date()
        captureStartDate = now
        lastLogPollDate = now
        isCapturing = true
        isLoading = true
        
        onLoadingChanged?(true)
        
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: 2.0,
            repeats: true
        ) { [weak self] _ in
            self?.scheduleRefresh()
        }
        
        if let timer = refreshTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
        
        scheduleRefresh()
    }
    
    func stop() {
        refCount -= 1
        guard refCount <= 0 else { return }
        
        refCount = 0
        refreshTimer?.invalidate()
        refreshTimer = nil
        isCapturing = false
    }
    
    func clear() {
        pollQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.seenLogIDs.removeAll()
            self.subsystemLock.lock()
            self.subsystemSet.removeAll()
            self.subsystemLock.unlock()
            self.lastLogPollDate = Date()
            
            DispatchQueue.main.async { [weak self] in
                self?.entries = []
                self?.availableSubsystems = []
                self?.onEntriesUpdated?()
                self?.onSubsystemsUpdated?([])
            }
        }
    }
    
    // MARK: - Private
    
    private func scheduleRefresh() {
        pollQueue.async { [weak self] in
            guard let self = self else { return }
            self.pollOSLog()
            
            self.subsystemLock.lock()
            let subsystems = self.subsystemSet.sorted()
            self.subsystemLock.unlock()
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.availableSubsystems = subsystems
                self.onLoadingChanged?(false)
                self.onSubsystemsUpdated?(subsystems)
            }
        }
    }
    
    private func pollOSLog() {
        guard let startDate = captureStartDate else { return }
        
        do {
            let store = try OSLogStore(scope: .currentProcessIdentifier)
            let position = store.position(date: lastLogPollDate ?? startDate)
            let logEntries = try store.getEntries(at: position)
            
            var newEntries = [OSLogEntry]()
            var newCount = 0
            let batchLimit = 500
            
            for entry in logEntries {
                guard let logEntry = entry as? OSLogEntryLog else { continue }
                guard newCount < batchLimit else { break }
                
                let entryID = "\(logEntry.date.timeIntervalSince1970)-\(logEntry.composedMessage.hashValue)"
                guard !seenLogIDs.contains(entryID) else { continue }
                
                seenLogIDs.insert(entryID)
                
                let sub = logEntry.subsystem.isEmpty ? nil : logEntry.subsystem
                let cat = logEntry.category.isEmpty ? nil : logEntry.category
                
                // Filter out ignored subsystems
                if let sub = sub, shouldIgnoreSubsystem(sub) {
                    continue
                }
                
                if let sub {
                    subsystemLock.lock()
                    subsystemSet.insert(sub)
                    subsystemLock.unlock()
                }
                
                newEntries.append(OSLogEntry(
                    message: logEntry.composedMessage,
                    timestamp: logEntry.date,
                    subsystem: sub,
                    category: cat
                ))
                
                newCount += 1
            }
            
            if !newEntries.isEmpty {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    var current = self.entries
                    current.append(contentsOf: newEntries)
                    
                    if current.count > Self.maxEntries {
                        current = Array(current.suffix(Self.maxEntries))
                    }
                    
                    self.entries = current
                    self.onEntriesUpdated?()
                }
            }
            
            lastLogPollDate = Date()
        } catch {
            // OSLogStore not available — silently degrade
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                self?.onLoadingChanged?(false)
            }
        }
    }
    
    // MARK: - Filtering
    
    private func shouldIgnoreSubsystem(_ subsystem: String) -> Bool {
        for prefix in ignoredSubsystemPrefixes {
            if subsystem.hasPrefix(prefix) {
                return true
            }
        }
        return false
    }
}
