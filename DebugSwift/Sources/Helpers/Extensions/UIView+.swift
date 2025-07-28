//
//  UIView+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    // Associated object keys
    private static var showsDebugBorderKey: Void?
    private static var previousBorderColorKey: Void?
    private static var previousBorderWidthKey: Void?
    private static var debugBorderColorKey: Void?
    
    func simulateButtonTap(completion: (() -> Void)? = nil) {
        ImpactFeedback.generate()
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.transform = CGAffineTransform.identity
            }) { _ in
                completion?()
            }
        }
    }

    func addTopBorderWithColor(color: UIColor, thickness: CGFloat = 1) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: thickness)
        layer.addSublayer(border)
    }

    // MARK: - ShowsDebugBorder property

    private var showsDebugBorder: Bool {
        get {
            objc_getAssociatedObject(self, &UIView.showsDebugBorderKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(
                self, &UIView.showsDebugBorderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    // MARK: - PreviousBorderColor property

    private var previousBorderColor: CGColor? {
        get {
            (objc_getAssociatedObject(self, &UIView.previousBorderColorKey) as? UIColor)?.cgColor
        }
        set {
            if let color = newValue {
                objc_setAssociatedObject(
                    self, &UIView.previousBorderColorKey, UIColor(cgColor: color),
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
            }
        }
    }

    // MARK: - PreviousBorderWidth property

    private var previousBorderWidth: CGFloat {
        get {
            objc_getAssociatedObject(self, &UIView.previousBorderWidthKey) as? CGFloat ?? 0.0
        }
        set {
            objc_setAssociatedObject(
                self, &UIView.previousBorderWidthKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    // MARK: - DebugBorderColor property

    private var debugBorderColor: CGColor {
        get {
            if let color = objc_getAssociatedObject(self, &UIView.debugBorderColorKey) as? UIColor {
                return color.cgColor
            }
            let color = UIColor.randomColor()
            objc_setAssociatedObject(
                self, &UIView.debugBorderColorKey, color, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            return color.cgColor
        }
        set {
            objc_setAssociatedObject(
                self, &UIView.debugBorderColorKey, UIColor(cgColor: newValue),
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    // MARK: - Method swizzling

    static func swizzleMethods() {
        DispatchQueue.once(token: UUID().uuidString) {
            SwizzleManager.swizzle(
                self,
                originalSelector: #selector(UIView.init(coder:)),
                swizzledSelector: #selector(UIView.swizzledInitWithCoder(_:))
            )

            SwizzleManager.swizzle(
                self,
                originalSelector: #selector(UIView.init(frame:)),
                swizzledSelector: #selector(UIView.swizzledInitWithFrame(_:))
            )
            
            // Add layoutSubviews swizzling for SwiftUI render tracking
            SwizzleManager.swizzle(
                self,
                originalSelector: #selector(UIView.layoutSubviews),
                swizzledSelector: #selector(UIView.swizzledLayoutSubviews)
            )
        }
    }

    @objc private func swizzledInitWithCoder(_ aDecoder: NSCoder) -> UIView {
        let view = swizzledInitWithCoder(aDecoder)
        view.db_refreshDebugBorders()
        view.db_registerForNotifications()
        return view
    }

    @objc private func swizzledInitWithFrame(_ frame: CGRect) -> UIView {
        let view = swizzledInitWithFrame(frame)
        view.db_refreshDebugBorders()
        view.db_registerForNotifications()
        return view
    }

    @objc private func swizzledDealloc() {
        NotificationCenter.default.removeObserver(self)
        swizzledDealloc()
    }
    
    @objc private func swizzledLayoutSubviews() {
        // Call original implementation first
        swizzledLayoutSubviews()
        
        // Check for SwiftUI render tracking if enabled
        if Self.swiftUIRenderTrackingEnabled {
            checkForSwiftUIRender()
        }
    }
    
    // MARK: - SwiftUI Render Tracking
    
    private static var swiftUIRenderTrackingEnabled: Bool = false
    private static var hasSwizzledLayoutSubviews: Bool = false
    private static var persistentOverlaysEnabled: Bool = false
    private static var overlayDuration: TimeInterval = 1.0
    private static var loggingEnabled: Bool = true
    private static var overlayStyle: OverlayStyle = .borderWithCount
    
    enum OverlayStyle: Equatable {
        case border
        case borderWithCount
        case none
    }
    
    /// Enable SwiftUI render tracking with method swizzling
    static func enableSwiftUIRenderTracking() {
        swiftUIRenderTrackingEnabled = true
        
        // Only swizzle if we haven't already done so
        if !hasSwizzledLayoutSubviews {
            hasSwizzledLayoutSubviews = true
        }
    }
    
    /// Disable SwiftUI render tracking
    static func disableSwiftUIRenderTracking() {
        swiftUIRenderTrackingEnabled = false
        persistentOverlaysEnabled = false
        clearAllPersistentOverlays()
    }
    
    /// Check if SwiftUI render tracking is enabled
    static var isSwiftUIRenderTrackingEnabled: Bool {
        return swiftUIRenderTrackingEnabled
    }
    
    // MARK: - Configuration
    
    static func setPersistentOverlays(_ enabled: Bool) {
        persistentOverlaysEnabled = enabled
        if !enabled {
            clearAllPersistentOverlays()
        }
    }
    
    static var isPersistentOverlaysEnabled: Bool {
        return persistentOverlaysEnabled
    }
    
    static func setOverlayDuration(_ duration: TimeInterval) {
        overlayDuration = duration
    }
    
    static var getOverlayDuration: TimeInterval {
        return overlayDuration
    }
    
    static func setLoggingEnabled(_ enabled: Bool) {
        loggingEnabled = enabled
    }
    
    static var isLoggingEnabled: Bool {
        return loggingEnabled
    }
    
    static func setOverlayStyle(_ style: OverlayStyle) {
        overlayStyle = style
    }
    
    static var getOverlayStyle: OverlayStyle {
        return overlayStyle
    }
    
    // MARK: - SwiftUI Detection & Tracking
    
    func checkForSwiftUIRender() {
        guard isSwiftUIHostingView else { return }
        
        let viewType = detectSwiftUIViewType()
        trackSwiftUIRender(viewType: viewType)
    }
    
    private var isSwiftUIHostingView: Bool {
        let className = NSStringFromClass(type(of: self))
        
        return className.contains("UIHosting") ||
               className.contains("SwiftUI") ||
               className.contains("_UIHosting") ||
               className.contains("_SwiftUI") ||
               className.hasPrefix("SwiftUI.") ||
               className.contains("ViewHost") ||
               className.contains("PlatformView") ||
               className.contains("DisplayList") ||
               className.contains("ViewGraph") ||
               className.contains("ModifiedContent")
    }
    
    private func detectSwiftUIViewType() -> String {
        let className = NSStringFromClass(type(of: self))
        
        if className.contains("UIHostingView") {
            return "UIHostingView"
        } else if className.contains("UIHostingController") {
            return "UIHostingController"
        } else if className.contains("PlatformView") {
            return "PlatformView"
        } else if className.contains("ViewHost") {
            return "ViewHost"
        } else if className.contains("SwiftUI") {
            let components = className.components(separatedBy: ".")
            return components.last?.replacingOccurrences(of: "Host", with: "") ?? "SwiftUIView"
        } else {
            return className
        }
    }
    
    // MARK: - Render Tracking Implementation
    
    private func trackSwiftUIRender(viewType: String) {
        let identifier = "\(viewType)_\(ObjectIdentifier(self))"
        let currentCount = getRenderCount(for: identifier) + 1
        setRenderCount(currentCount, for: identifier)
        
        // Log if enabled
        if Self.loggingEnabled {
            print("🎨 SwiftUI Render: \(viewType) - Render #\(currentCount)")
        }
        
        // Show visual overlay based on style
        switch Self.overlayStyle {
        case .border:
            showBorderOverlay(viewType: viewType, renderCount: currentCount, identifier: identifier)
        case .borderWithCount:
            showBorderWithCountOverlay(viewType: viewType, renderCount: currentCount, identifier: identifier)
        case .none:
            break // Only logging
        }
    }
    
    // MARK: - Render Count Storage
    
    private static var renderCountsKey: Void?
    private static var persistentOverlaysKey: Void?
    private static var activeOverlaysKey: Void?
    
    private func getRenderCount(for identifier: String) -> Int {
        if let counts = objc_getAssociatedObject(UIView.self, &UIView.renderCountsKey) as? [String: Int] {
            return counts[identifier] ?? 0
        }
        return 0
    }
    
    private func setRenderCount(_ count: Int, for identifier: String) {
        var counts = objc_getAssociatedObject(UIView.self, &UIView.renderCountsKey) as? [String: Int] ?? [:]
        counts[identifier] = count
        objc_setAssociatedObject(UIView.self, &UIView.renderCountsKey, counts, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    static func clearSwiftUIRenderStats() {
        objc_setAssociatedObject(UIView.self, &renderCountsKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        clearAllPersistentOverlays()
    }
    
    // MARK: - Persistent Overlays Management
    
    private static func getPersistentOverlays() -> [String: UIView] {
        return objc_getAssociatedObject(UIView.self, &persistentOverlaysKey) as? [String: UIView] ?? [:]
    }
    
    private static func setPersistentOverlays(_ overlays: [String: UIView]) {
        objc_setAssociatedObject(UIView.self, &persistentOverlaysKey, overlays, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    private static func getActiveOverlays() -> Set<String> {
        return objc_getAssociatedObject(UIView.self, &activeOverlaysKey) as? Set<String> ?? Set<String>()
    }
    
    private static func setActiveOverlays(_ overlays: Set<String>) {
        objc_setAssociatedObject(UIView.self, &activeOverlaysKey, overlays, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    static func clearAllPersistentOverlays() {
        let persistentOverlays = getPersistentOverlays()
        for (_, overlayView) in persistentOverlays {
            overlayView.removeFromSuperview()
        }
        setPersistentOverlays([:])
        setActiveOverlays(Set<String>())
    }
    
    /// Clear persistent overlays (public API for tests)
    static func clearPersistentOverlays() {
        clearAllPersistentOverlays()
    }
    
    // MARK: - Visual Overlays
    
    private func showBorderOverlay(viewType: String, renderCount: Int, identifier: String) {
        guard let window = self.window else { return }
        
        // Check if we're already processing this overlay to prevent loops
        var activeOverlays = Self.getActiveOverlays()
        guard !activeOverlays.contains(identifier) else { return }
        activeOverlays.insert(identifier)
        Self.setActiveOverlays(activeOverlays)
        
        // If persistent overlays are enabled, check for existing overlay
        if Self.persistentOverlaysEnabled {
            var persistentOverlays = Self.getPersistentOverlays()
            if let existingOverlay = persistentOverlays[identifier] {
                // Just update the existing overlay (no count to update for plain border)
                activeOverlays.remove(identifier)
                Self.setActiveOverlays(activeOverlays)
                return
            }
        }
        
        let viewFrame = self.convert(self.bounds, to: window)
        let overlayView = createBorderOverlay(frame: viewFrame)
        
        window.addSubview(overlayView)
        
        if Self.persistentOverlaysEnabled {
            // Store as persistent
            var persistentOverlays = Self.getPersistentOverlays()
            persistentOverlays[identifier] = overlayView
            Self.setPersistentOverlays(persistentOverlays)
            
            activeOverlays.remove(identifier)
            Self.setActiveOverlays(activeOverlays)
        } else {
            // Animate and remove
            UIView.animate(
                withDuration: Self.overlayDuration,
                animations: {
                    overlayView.alpha = 0
                },
                completion: { _ in
                    overlayView.removeFromSuperview()
                    var activeOverlays = Self.getActiveOverlays()
                    activeOverlays.remove(identifier)
                    Self.setActiveOverlays(activeOverlays)
                }
            )
        }
    }
    
    private func showBorderWithCountOverlay(viewType: String, renderCount: Int, identifier: String) {
        guard let window = self.window else { return }
        
        // Check if we're already processing this overlay to prevent loops
        var activeOverlays = Self.getActiveOverlays()
        guard !activeOverlays.contains(identifier) else { return }
        activeOverlays.insert(identifier)
        Self.setActiveOverlays(activeOverlays)
        
        // If persistent overlays are enabled, check for existing overlay
        if Self.persistentOverlaysEnabled {
            var persistentOverlays = Self.getPersistentOverlays()
            if let existingOverlay = persistentOverlays[identifier] {
                // Update the count label
                updateCountLabel(in: existingOverlay, count: renderCount)
                activeOverlays.remove(identifier)
                Self.setActiveOverlays(activeOverlays)
                return
            }
        }
        
        let viewFrame = self.convert(self.bounds, to: window)
        let overlayView = createBorderWithCountOverlay(frame: viewFrame, count: renderCount)
        
        window.addSubview(overlayView)
        
        if Self.persistentOverlaysEnabled {
            // Store as persistent
            var persistentOverlays = Self.getPersistentOverlays()
            persistentOverlays[identifier] = overlayView
            Self.setPersistentOverlays(persistentOverlays)
            
            activeOverlays.remove(identifier)
            Self.setActiveOverlays(activeOverlays)
        } else {
            // Animate and remove
            UIView.animate(
                withDuration: Self.overlayDuration,
                animations: {
                    overlayView.alpha = 0
                },
                completion: { _ in
                    overlayView.removeFromSuperview()
                    var activeOverlays = Self.getActiveOverlays()
                    activeOverlays.remove(identifier)
                    Self.setActiveOverlays(activeOverlays)
                }
            )
        }
    }
    
    // MARK: - Overlay Creation Helpers
    
    private func createBorderOverlay(frame: CGRect) -> UIView {
        let overlayView = UIView(frame: frame)
        overlayView.backgroundColor = UIColor.clear
        overlayView.layer.borderColor = UIColor.systemOrange.cgColor
        overlayView.layer.borderWidth = 2.0
        overlayView.layer.cornerRadius = self.layer.cornerRadius
        overlayView.isUserInteractionEnabled = false
        return overlayView
    }
    
    private func createBorderWithCountOverlay(frame: CGRect, count: Int) -> UIView {
        let overlayView = createBorderOverlay(frame: frame)
        
        // Add count label
        let countLabel = UILabel()
        countLabel.text = "\(count)"
        countLabel.font = UIFont.boldSystemFont(ofSize: 16)
        countLabel.textColor = .white
        countLabel.backgroundColor = UIColor.systemOrange
        countLabel.textAlignment = .center
        countLabel.layer.cornerRadius = 10
        countLabel.clipsToBounds = true
        countLabel.tag = 999 // Tag to find it later for updates
        
        // Size and position the label
        countLabel.sizeToFit()
        let labelSize = CGSize(width: max(20, countLabel.frame.width + 8), height: 20)
        countLabel.frame = CGRect(
            x: overlayView.bounds.width - labelSize.width - 4,
            y: 4,
            width: labelSize.width,
            height: labelSize.height
        )
        
        overlayView.addSubview(countLabel)
        return overlayView
    }
    
    private func updateCountLabel(in overlayView: UIView, count: Int) {
        if let countLabel = overlayView.viewWithTag(999) as? UILabel {
            countLabel.text = "\(count)"
            countLabel.sizeToFit()
            let labelSize = CGSize(width: max(20, countLabel.frame.width + 8), height: 20)
            countLabel.frame = CGRect(
                x: overlayView.bounds.width - labelSize.width - 4,
                y: 4,
                width: labelSize.width,
                height: labelSize.height
            )
        }
    }

    // MARK: - Colorized debug borders notifications

    private func db_registerForNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(changedNotification(_:)),
            name: UserInterfaceToolkit.notification,
            object: nil
        )
    }

    @objc private func changedNotification(
        _: Notification
    ) {
        db_refreshDebugBorders()
    }

    // MARK: - Handling debug borders

    private func db_refreshDebugBorders() {
        if UserInterfaceToolkit.colorizedViewBordersEnabled {
            db_showDebugBorders()
        } else {
            db_hideDebugBorders()
        }
    }

    private func db_showDebugBorders() {
        guard !showsDebugBorder else { return }

        showsDebugBorder = true

        previousBorderWidth = layer.borderWidth
        previousBorderColor = layer.borderColor

        layer.borderColor = debugBorderColor
        layer.borderWidth = 1
    }

    private func db_hideDebugBorders() {
        guard showsDebugBorder else { return }
        showsDebugBorder = false
        layer.borderWidth = previousBorderWidth
        layer.borderColor = previousBorderColor
    }
}
