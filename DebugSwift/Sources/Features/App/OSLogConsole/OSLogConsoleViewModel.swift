//
//  OSLogConsoleViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 12/05/26.
//

import UIKit

@available(iOS 15.0, *)
final class OSLogConsoleViewModel: NSObject {
    private let monitor = OSLogMonitor.shared
    
    var onUpdate: (() -> Void)?
    var onLoadingChanged: ((Bool) -> Void)?
    
    var isCaptureEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: "debugswift.oslog.capturingEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "debugswift.oslog.capturingEnabled")
            if newValue {
                monitor.start()
            } else {
                monitor.stop()
            }
        }
    }
    
    var searchText: String = "" {
        didSet {
            onUpdate?()
        }
    }
    
    var selectedSubsystems = Set<String>() {
        didSet {
            onUpdate?()
        }
    }
    
    var autoScroll = true
    
    var showAppleSubsystems: Bool {
        get { monitor.showAppleSubsystems }
        set { monitor.showAppleSubsystems = newValue }
    }
    
    override init() {
        super.init()
        setupMonitor()
    }
    
    func toggleAppleSubsystems() {
        showAppleSubsystems.toggle()
        onUpdate?()
    }
    
    private func setupMonitor() {
        monitor.onEntriesUpdated = { [weak self] in
            self?.onUpdate?()
        }
        
        monitor.onLoadingChanged = { [weak self] isLoading in
            self?.onLoadingChanged?(isLoading)
        }
        
        monitor.onSubsystemsUpdated = { [weak self] _ in
            self?.onUpdate?()
        }
    }
    
    func start() {
        if isCaptureEnabled {
            monitor.start()
        }
    }
    
    func stop() {
        monitor.stop()
    }
    
    func clear() {
        monitor.clear()
        selectedSubsystems.removeAll()
    }
    
    func getFilteredEntries() -> [OSLogEntry] {
        var result = monitor.entries
        
        // Filter by subsystems
        if !selectedSubsystems.isEmpty {
            result = result.filter { entry in
                guard let sub = entry.subsystem else { return false }
                return selectedSubsystems.contains(sub)
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            let query = searchText
            result = result.filter { entry in
                entry.message.localizedCaseInsensitiveContains(query)
                    || (entry.subsystem?.localizedCaseInsensitiveContains(query) ?? false)
                    || (entry.category?.localizedCaseInsensitiveContains(query) ?? false)
            }
        }
        
        return result
    }
    
    func exportLogs() -> String {
        getFilteredEntries().map(\.formattedLine).joined(separator: "\n")
    }
    
    var availableSubsystems: [String] {
        monitor.availableSubsystems
    }
    
    var isLoading: Bool {
        monitor.isLoading
    }
    
    var isCapturing: Bool {
        monitor.isCapturing
    }
}
