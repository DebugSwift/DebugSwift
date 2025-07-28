//
//  SwiftUIRenderTracker.swift
//  DebugSwift
//
//  Created by DebugSwift on 2025/01/27.
//

import UIKit
import SwiftUI

/// Weak reference to track original views for overlay cleanup
private class WeakViewReference {
    weak var view: UIView?
    
    init(_ view: UIView) {
        self.view = view
    }
}

@MainActor
public class SwiftUIRenderTracker: @unchecked Sendable {
    public static let shared = SwiftUIRenderTracker()
    
    private init() {}
    
    deinit {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }
    
    // MARK: - Configuration
    
    /// Enables or disables SwiftUI render tracking
    public var isEnabled: Bool = false {
        didSet {
            if isEnabled != oldValue {
                NotificationCenter.default.post(
                    name: Self.renderTrackingStateChangedNotification,
                    object: NSNumber(value: isEnabled)
                )
            }
        }
    }
    
    /// Visual style for render highlights
    public var overlayStyle: RenderOverlayStyle = .borderWithCount
    
    /// Duration for the render highlight overlay
    public var overlayDuration: TimeInterval = 1
    
    /// Controls logging of render events
    public var loggingEnabled: Bool = true
    
    /// When true, overlays will persist and not fade out automatically
    public var persistentOverlays: Bool = false {
        didSet {
            if persistentOverlays != oldValue {
                if persistentOverlays {
                    startOrphanCleanupTimer()
                } else {
                    stopOrphanCleanupTimer()
                    clearAllPersistentOverlays()
                }
            }
        }
    }
    
    // MARK: - Render Overlay Styles
    
    public enum RenderOverlayStyle {
        case border         // Colored border that fades
        case borderWithCount // Border with render count text
        case none           // Only logging, no visual
    }
    
    // MARK: - Notifications
    
    public static let renderTrackingStateChangedNotification = Notification.Name(
        "SwiftUIRenderTracker.StateChanged"
    )
    
    // MARK: - Render Statistics
    
    private var renderCounts: [String: Int] = [:]
    private var lastRenderTimes: [String: Date] = [:]
    private var activeOverlays: Set<String> = [] // Track active overlays to prevent loops
    private var persistentOverlayViews: [String: UIView] = [:] // Track persistent overlay views
    private var overlayViewAssociations: [String: WeakViewReference] = [:] // Track original views for cleanup
    
    public func getRenderStats() -> [String: Any] {
        return [
            "totalViews": renderCounts.count,
            "totalRenders": renderCounts.values.reduce(0, +),
            "renderCounts": renderCounts,
            "lastRenderTimes": lastRenderTimes
        ]
    }
    
    public func clearStats() {
        renderCounts.removeAll()
        lastRenderTimes.removeAll()
        activeOverlays.removeAll() // Clear active overlays to prevent stuck states
        clearAllPersistentOverlays() // Clear any persistent overlays
    }
    
    /// Clear all persistent overlays from the screen
    public func clearAllPersistentOverlays() {
        for (_, overlayView) in persistentOverlayViews {
            overlayView.removeFromSuperview()
        }
        persistentOverlayViews.removeAll()
        overlayViewAssociations.removeAll()
    }
    
    /// Clean up orphaned overlays whose original views are no longer in the hierarchy
    public func cleanupOrphanedOverlays() {
        guard persistentOverlays else { return }
        
        var overlaysToRemove: [String] = []
        
        for (identifier, viewRef) in overlayViewAssociations {
            guard let overlayView = persistentOverlayViews[identifier] else {
                // Overlay view is missing, mark for cleanup
                overlaysToRemove.append(identifier)
                continue
            }
            
            // Check if the original view is still valid and in the hierarchy
            if let originalView = viewRef.view,
               originalView.window != nil,
               originalView.superview != nil,
               originalView.window == overlayView.superview {
                // View is still valid and in the same window, update overlay position
                updateOverlayPosition(overlayView, for: originalView, identifier: identifier)
            } else {
                // Original view is no longer valid or in a different context, mark for removal
                overlaysToRemove.append(identifier)
            }
        }
        
        // Remove orphaned overlays
        for identifier in overlaysToRemove {
            if let overlayView = persistentOverlayViews[identifier] {
                overlayView.removeFromSuperview()
            }
            persistentOverlayViews.removeValue(forKey: identifier)
            overlayViewAssociations.removeValue(forKey: identifier)
        }
    }
    
    /// Update overlay position to match its original view's current position
    private func updateOverlayPosition(_ overlayView: UIView, for originalView: UIView, identifier: String) {
        guard let window = originalView.window else { return }
        
        let newFrame = originalView.convert(originalView.bounds, to: window)
        
        // Only update if the frame has changed significantly (avoid micro-adjustments)
        let currentFrame = overlayView.frame
        if abs(newFrame.origin.x - currentFrame.origin.x) > 1 ||
           abs(newFrame.origin.y - currentFrame.origin.y) > 1 ||
           abs(newFrame.size.width - currentFrame.size.width) > 1 ||
           abs(newFrame.size.height - currentFrame.size.height) > 1 {
            
            overlayView.frame = newFrame
            
            // Update count label position as well
            if let countLabel = overlayView.subviews.first(where: { $0.tag == 999 }) as? UILabel {
                let labelWidth = countLabel.frame.width
                let labelHeight = countLabel.frame.height
                countLabel.frame = CGRect(
                    x: newFrame.width - labelWidth - 5,
                    y: 5,
                    width: labelWidth,
                    height: labelHeight
                )
            }
        }
    }
    
    /// Clear all active overlays (useful for cleanup)
    private func clearActiveOverlays() {
        activeOverlays.removeAll()
    }
    
    // MARK: - SwiftUI Render Detection
    
    internal func trackRender(for view: UIView, viewType: String) {
        guard isEnabled else { return }
        
        let identifier = "\(viewType)_\(ObjectIdentifier(view))"
        
        // Prevent infinite loops by checking if we're already tracking this view
        guard !activeOverlays.contains(identifier) else { return }
        
        // Update statistics
        renderCounts[identifier, default: 0] += 1
        lastRenderTimes[identifier] = Date()
        
        // Log render event
        if loggingEnabled {
            let renderCount = renderCounts[identifier] ?? 0
            Debug.print("🎨 SwiftUI Render: \(viewType) - Render #\(renderCount)")
        }
        
        // Show visual overlay (with protection against loops)
        showRenderOverlay(on: view, viewType: viewType)
        
        // Post notification for external observers
        NotificationCenter.default.post(
            name: .swiftUIViewDidRender,
            object: [
                "view": view,
                "viewType": viewType,
                "renderCount": renderCounts[identifier] ?? 0
            ]
        )
    }
    
    private func showRenderOverlay(on view: UIView, viewType: String) {
        guard overlayStyle != .none, view.window != nil else { return }
        
        let identifier = "\(viewType)_\(ObjectIdentifier(view))"
        let renderCount = renderCounts[identifier] ?? 0
        
        // Mark this overlay as active to prevent loops
        activeOverlays.insert(identifier)
        
        // Clean up any orphaned overlays first if in persistent mode
        if persistentOverlays {
            cleanupOrphanedOverlays()
        }
        
        switch overlayStyle {
        case .border:
            showBorderOverlay(on: view, identifier: identifier)
        case .borderWithCount:
            showBorderWithCountOverlay(on: view, viewType: viewType, renderCount: renderCount, identifier: identifier)
        case .none:
            break
        }
    }
    
    private func showBorderOverlay(on view: UIView, identifier: String) {
        guard let window = view.window else {
            activeOverlays.remove(identifier)
            return
        }
        
        // If persistent overlays are enabled and we already have one, skip
        if persistentOverlays && persistentOverlayViews[identifier] != nil {
            activeOverlays.remove(identifier)
            return
        }
        
        let viewFrame = view.convert(view.bounds, to: window)
        let overlayView = UIView(frame: viewFrame)
        overlayView.backgroundColor = UIColor.clear
        overlayView.layer.borderColor = UIColor.systemOrange.cgColor
        overlayView.layer.borderWidth = 1.0
        overlayView.layer.cornerRadius = view.layer.cornerRadius
        overlayView.isUserInteractionEnabled = false
        
        window.addSubview(overlayView)
        
        if persistentOverlays {
            persistentOverlayViews[identifier] = overlayView
            overlayViewAssociations[identifier] = WeakViewReference(view)
            activeOverlays.remove(identifier)
        } else {
            UIView.animate(
                withDuration: overlayDuration,
                animations: {
                    overlayView.alpha = 0
                },
                completion: { _ in
                    overlayView.removeFromSuperview()
                    self.activeOverlays.remove(identifier)
                }
            )
        }
    }
    
    private func showBorderWithCountOverlay(on view: UIView, viewType: String, renderCount: Int, identifier: String) {
        guard let window = view.window else {
            activeOverlays.remove(identifier)
            return
        }
        
        // If we have persistent overlays enabled, check if we already have one for this view
        if persistentOverlays {
            if let existingOverlay = persistentOverlayViews[identifier] {
                // Update the existing overlay's count label
                updatePersistentOverlayCount(existingOverlay, renderCount: renderCount)
                activeOverlays.remove(identifier)
                return
            }
        }
        
        // Convert view frame to window coordinates
        let viewFrame = view.convert(view.bounds, to: window)
        
        // Create overlay view that won't trigger layout in the original view
        let overlayView = UIView(frame: viewFrame)
        overlayView.backgroundColor = UIColor.clear
        overlayView.layer.borderColor = UIColor.systemOrange.cgColor
        overlayView.layer.borderWidth = 1.0
        overlayView.layer.cornerRadius = view.layer.cornerRadius
        overlayView.isUserInteractionEnabled = false
        
        // Add to window directly to avoid affecting original view hierarchy
        window.addSubview(overlayView)
        
        // Add render count label
        let countText = "\(renderCount)"
        let countLabel = UILabel()
        countLabel.text = countText
        countLabel.font = UIFont.boldSystemFont(ofSize: 8)
        countLabel.textColor = UIColor.white
        countLabel.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.9)
        countLabel.textAlignment = .center
        countLabel.layer.cornerRadius = 4
        countLabel.clipsToBounds = true
        countLabel.tag = 999 // Tag for easy finding when updating
        
        // Calculate label size
        countLabel.sizeToFit()
        let labelWidth = max(countLabel.frame.width + 2, 20)
        let labelHeight = countLabel.frame.height + 2
        
        // Position in top-right corner
        countLabel.frame = CGRect(
            x: overlayView.frame.width - labelWidth,
            y: 5,
            width: labelWidth,
            height: labelHeight
        )
        
        overlayView.addSubview(countLabel)
        
        if persistentOverlays {
            // Store persistent overlay and view association for future updates and cleanup
            persistentOverlayViews[identifier] = overlayView
            overlayViewAssociations[identifier] = WeakViewReference(view)
            activeOverlays.remove(identifier)
        } else {
            // Animate fade out and remove
            UIView.animate(
                withDuration: overlayDuration,
                animations: {
                    overlayView.alpha = 0
                },
                completion: { _ in
                    overlayView.removeFromSuperview()
                    self.activeOverlays.remove(identifier)
                }
            )
        }
    }
    
    /// Update the count label on a persistent overlay
    private func updatePersistentOverlayCount(_ overlayView: UIView, renderCount: Int) {
        // Find the count label and update its text
        if let countLabel = overlayView.subviews.first(where: { $0.tag == 999 }) as? UILabel {
            countLabel.text = "\(renderCount)"
            countLabel.sizeToFit()
            
            // Update frame to accommodate new size
            let labelWidth = max(countLabel.frame.width + 16, 30)
            let labelHeight = countLabel.frame.height + 8
            countLabel.frame = CGRect(
                x: overlayView.frame.width - labelWidth - 5,
                y: 5,
                width: labelWidth,
                height: labelHeight
            )
        }
    }
    
    // MARK: - Cleanup Timer
    
    private nonisolated(unsafe) var cleanupTimer: Timer?
    
    private nonisolated func startOrphanCleanupTimer() {
        stopOrphanCleanupTimer()
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.cleanupOrphanedOverlays()
            }
        }
    }
    
    private nonisolated func stopOrphanCleanupTimer() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }
}

// MARK: - UIView Extensions for SwiftUI Hosting Detection



// MARK: - Notification Names

extension Notification.Name {
    static let swiftUIViewDidRender = Notification.Name("SwiftUIViewDidRender")
}
