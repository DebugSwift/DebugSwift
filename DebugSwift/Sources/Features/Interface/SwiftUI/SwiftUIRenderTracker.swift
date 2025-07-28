//
//  SwiftUIRenderTracker.swift
//  DebugSwift
//
//  Created by DebugSwift on 2025/01/27.
//

import UIKit
import SwiftUI

@MainActor
public class SwiftUIRenderTracker: @unchecked Sendable {
    public static let shared = SwiftUIRenderTracker()
    
    private init() {}
    
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
    
    /// Controls the visual overlay style for render highlights
    public var overlayStyle: RenderOverlayStyle = .borderWithCount
    
    /// Duration for the render highlight overlay
    public var overlayDuration: TimeInterval = 1
    
    /// Controls logging of render events
    public var loggingEnabled: Bool = true
    
    // MARK: - Render Overlay Styles
    
    public enum RenderOverlayStyle {
        case flash          // Quick colored flash
        case border         // Colored border that fades
        case pulse          // Pulsing effect
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
        
        switch overlayStyle {
        case .flash:
            showFlashOverlay(on: view, identifier: identifier)
        case .border:
            showBorderOverlay(on: view, identifier: identifier)
        case .pulse:
            showPulseOverlay(on: view, identifier: identifier)
        case .borderWithCount:
            showBorderWithCountOverlay(on: view, viewType: viewType, renderCount: renderCount, identifier: identifier)
        case .none:
            break
        }
    }
    
    private func showFlashOverlay(on view: UIView, identifier: String) {
        guard let window = view.window else {
            activeOverlays.remove(identifier)
            return
        }
        
        let viewFrame = view.convert(view.bounds, to: window)
        let overlayView = UIView(frame: viewFrame)
        overlayView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.3)
        overlayView.layer.cornerRadius = view.layer.cornerRadius
        overlayView.isUserInteractionEnabled = false
        
        window.addSubview(overlayView)
        
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
    
    private func showBorderOverlay(on view: UIView, identifier: String) {
        guard let window = view.window else {
            activeOverlays.remove(identifier)
            return
        }
        
        let viewFrame = view.convert(view.bounds, to: window)
        let overlayView = UIView(frame: viewFrame)
        overlayView.backgroundColor = UIColor.clear
        overlayView.layer.borderColor = UIColor.systemBlue.cgColor
        overlayView.layer.borderWidth = 2.0
        overlayView.layer.cornerRadius = view.layer.cornerRadius
        overlayView.isUserInteractionEnabled = false
        
        window.addSubview(overlayView)
        
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
    
    private func showPulseOverlay(on view: UIView, identifier: String) {
        guard let window = view.window else {
            activeOverlays.remove(identifier)
            return
        }
        
        let viewFrame = view.convert(view.bounds, to: window)
        let overlayView = UIView(frame: viewFrame)
        overlayView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
        overlayView.layer.cornerRadius = view.layer.cornerRadius
        overlayView.isUserInteractionEnabled = false
        
        window.addSubview(overlayView)
        
        UIView.animate(
            withDuration: self.overlayDuration / 2,
            animations: {
                overlayView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            },
            completion: { [self] _ in
                UIView.animate(
                    withDuration: self.overlayDuration / 2,
                    animations: {
                        overlayView.alpha = 0
                        overlayView.transform = .identity
                    },
                    completion: { _ in
                        overlayView.removeFromSuperview()
                        self.activeOverlays.remove(identifier)
                    }
                )
            }
        )
    }
    
    private func showBorderWithCountOverlay(on view: UIView, viewType: String, renderCount: Int, identifier: String) {
        guard let window = view.window else {
            activeOverlays.remove(identifier)
            return
        }
        
        // Convert view frame to window coordinates
        let viewFrame = view.convert(view.bounds, to: window)
        
        // Create overlay view that won't trigger layout in the original view
        let overlayView = UIView(frame: viewFrame)
        overlayView.backgroundColor = UIColor.clear
        overlayView.layer.borderColor = UIColor.systemOrange.cgColor
        overlayView.layer.borderWidth = 2.0
        overlayView.layer.cornerRadius = view.layer.cornerRadius
        overlayView.isUserInteractionEnabled = false
        
        // Add to window directly to avoid affecting original view hierarchy
        window.addSubview(overlayView)
        
        // Add render count label
        let countText = "\(renderCount)"
        let countLabel = UILabel()
        countLabel.text = countText
        countLabel.font = UIFont.boldSystemFont(ofSize: 16)
        countLabel.textColor = UIColor.white
        countLabel.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.9)
        countLabel.textAlignment = .center
        countLabel.layer.cornerRadius = 8
        countLabel.clipsToBounds = true
        
        // Calculate label size
        countLabel.sizeToFit()
        let labelWidth = max(countLabel.frame.width + 16, 30)
        let labelHeight = countLabel.frame.height + 8
        
        // Position in top-right corner
        countLabel.frame = CGRect(
            x: overlayView.frame.width - labelWidth - 5,
            y: 5,
            width: labelWidth,
            height: labelHeight
        )
        
        overlayView.addSubview(countLabel)
        
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

// MARK: - UIView Extensions for SwiftUI Hosting Detection

extension UIView {
    
    /// Enables SwiftUI render tracking through method swizzling
    static func enableSwiftUIRenderTracking() {
        DispatchQueue.once(token: "debugswift.swiftuirendertracker.enable") {
            // Note: We integrate with existing UIView swizzling rather than creating new swizzling
            // The actual tracking happens in the existing layoutSubviews swizzling
            NotificationCenter.default.addObserver(
                forName: UserInterfaceToolkit.notification,
                object: nil,
                queue: .main
            ) { _ in
                // React to UI toolkit state changes
            }
        }
    }
    
    /// Call this from existing layoutSubviews swizzling to check for SwiftUI renders
    func checkForSwiftUIRender() {
        // Check if this is a SwiftUI-related view
        if isSwiftUIHostingView {
            let viewType = detectSwiftUIViewType()
            SwiftUIRenderTracker.shared.trackRender(for: self, viewType: viewType)
        }
    }
    
    /// Detects if this view is part of SwiftUI's hosting infrastructure
    private var isSwiftUIHostingView: Bool {
        let className = NSStringFromClass(type(of: self))
        
        // Check for known SwiftUI hosting classes
        return className.contains("UIHosting") ||
               className.contains("SwiftUI") ||
               className.contains("_UIHosting") ||
               className.contains("_SwiftUI") ||
               className.hasPrefix("SwiftUI.") ||
               className.contains("ViewHost") ||
               className.contains("PlatformView") ||
               // Additional SwiftUI internal classes
               className.contains("DisplayList") ||
               className.contains("ViewGraph") ||
               className.contains("ModifiedContent")
    }
    
    /// Attempts to detect the specific SwiftUI view type
    private func detectSwiftUIViewType() -> String {
        let className = NSStringFromClass(type(of: self))
        
        // Extract meaningful SwiftUI view type
        if className.contains("UIHostingView") {
            return "UIHostingView"
        } else if className.contains("UIHostingController") {
            return "UIHostingController"
        } else if className.contains("PlatformView") {
            return "PlatformView"
        } else if className.contains("ViewHost") {
            return "ViewHost"
        } else if className.contains("SwiftUI") {
            // Try to extract the actual SwiftUI view name
            let components = className.components(separatedBy: ".")
            return components.last?.replacingOccurrences(of: "Host", with: "") ?? "SwiftUIView"
        } else {
            return className
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let swiftUIViewDidRender = Notification.Name("SwiftUIViewDidRender")
} 
