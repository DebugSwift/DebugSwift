//
//  UserInterfaceToolkit.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import SwiftUI
import Combine

@MainActor
class UserInterfaceToolkit: @unchecked Sendable {
    // MARK: - Properties

    static let shared = UserInterfaceToolkit()

    var gridOverlay = GridOverlayView()
    var gridOverlayColorSchemes: [GridOverlayColorScheme] = [
        .init(primaryColor: .red, secondaryColor: .white),
        .init(primaryColor: .blue, secondaryColor: .white),
        .init(primaryColor: .green, secondaryColor: .white),
        .init(primaryColor: .yellow, secondaryColor: .white),
        .init(primaryColor: .white, secondaryColor: .white),
        .init(primaryColor: .gray, secondaryColor: .white)
    ]
    var isGridOverlayShown = false {
        didSet {
            gridOverlay.toggle(with: isGridOverlayShown)
        }
    }

    var slowAnimationsEnabled = false {
        didSet {
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                guard oldValue != self.slowAnimationsEnabled else { return }
                self.updateAnimationSpeed()
            }
        }
    }
    
    static var colorizedViewBordersEnabled = false {
        didSet {
            guard oldValue != colorizedViewBordersEnabled else { return }
            NotificationCenter.default.post(
                name: Self.notification,
                object: NSNumber(value: colorizedViewBordersEnabled)
            )
        }
    }
    
    var showingTouchesEnabled = false {
        didSet {
            guard oldValue != showingTouchesEnabled else { return }
            updateShowingTouches()
        }
    }
    
    var darkModeEnabled: Bool = false {
        didSet {
            guard oldValue != darkModeEnabled else { return }
            updateColorScheme()
        }
    }
    
    var swiftUIRenderTrackingEnabled: Bool = false {
        didSet {
            guard oldValue != swiftUIRenderTrackingEnabled else { return }
            SwiftUIRenderTracker.shared.isEnabled = swiftUIRenderTrackingEnabled
        }
    }
    
    var selectedGridOverlayColorSchemeIndex: Int = 0 {
        didSet {
            if gridOverlayColorSchemes.indices.contains(selectedGridOverlayColorSchemeIndex) {
                gridOverlay.colorScheme = gridOverlayColorSchemes[selectedGridOverlayColorSchemeIndex]
            }
        }
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupInitialState()
        registerForNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupInitialState() {
        darkModeEnabled = UIScreen.main.traitCollection.userInterfaceStyle == .dark
        
        // Set initial color scheme
        if let colorScheme = gridOverlay.colorScheme,
           let index = gridOverlayColorSchemes.firstIndex(of: colorScheme) {
            selectedGridOverlayColorSchemeIndex = index
        }
    }
    
    // MARK: - Window notifications
    
    private func registerForNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(newKeyWindowNotification(_:)),
            name: UIWindow.didBecomeKeyNotification,
            object: nil
        )
    }
    
    @objc private func newKeyWindowNotification(_ notification: Notification) {
        if let newKeyWindow = notification.object as? UIWindow {
            setSpeed(for: newKeyWindow)
            setShowingTouchesEnabled(for: newKeyWindow)
        }
    }
    
    // MARK: - Public methods
    
    func autolayoutTrace() -> String? {
        guard let window = UIWindow.keyWindow else { return nil }
        let key = String(
            data: Data([
                0x5f, 0x61, 0x75, 0x74, 0x6f, 0x6c, 0x61, 0x79, 0x6f, 0x75, 0x74, 0x54, 0x72, 0x61, 0x63,
                0x65
            ]), encoding: .ascii
        )
        let selector = NSSelectorFromString(key ?? "")
        return (window.perform(selector)?.takeUnretainedValue as? () -> String)?()
    }
    
    func viewDescription(_ view: UIView) -> String? {
        let key = String(
            data: Data([
                0x72, 0x65, 0x63, 0x75, 0x72, 0x73, 0x69, 0x76, 0x65, 0x44, 0x65, 0x73, 0x63, 0x72, 0x69,
                0x70, 0x74, 0x69, 0x6f, 0x6e
            ]), encoding: .ascii
        )
        let selector = NSSelectorFromString(key ?? "")
        return (view.perform(selector)?.takeUnretainedValue as? () -> String)?()
    }
    
    func viewControllerHierarchy() -> String? {
        guard let rootViewController = UIWindow.keyWindow?.rootViewController else { return nil }
        let key = String(
            data: Data([
                0x5f, 0x70, 0x72, 0x69, 0x6e, 0x74, 0x48, 0x69, 0x65, 0x72, 0x61, 0x72, 0x63, 0x68, 0x79
            ]), encoding: .ascii
        )
        let selector = NSSelectorFromString(key ?? "")
        return (rootViewController.perform(selector)?.takeUnretainedValue as? () -> String)?()
    }
    
    // MARK: - Private methods
    
    private func updateAnimationSpeed() {
        UIWindowScene._windows.forEach { setSpeed(for: $0) }
    }
    
    private func updateShowingTouches() {
        UIWindowScene._windows.forEach { setShowingTouchesEnabled(for: $0) }
    }
    
    private func updateColorScheme() {
        UIWindowScene._windows.forEach { window in
            window.overrideUserInterfaceStyle = darkModeEnabled ? .dark : .light
        }
    }
    
    private func setSpeed(for window: UIWindow) {
        let speed: Float = slowAnimationsEnabled ? 0.1 : 1.0
        window.layer.speed = speed
    }
    
    private func setShowingTouchesEnabled(for window: UIWindow) {
        window.setShowingTouchesEnabled(showingTouchesEnabled)
    }
}

// MARK: - Extensions

extension UserInterfaceToolkit {
    static let notification = Notification.Name(
        "UserInterfaceToolkitColorizedViewBordersChangedNotification")
}

// MARK: - Environment Key

private struct UserInterfaceToolkitEnvironmentKey: EnvironmentKey {
    static let defaultValue: UserInterfaceToolkit? = nil
}

extension EnvironmentValues {
    var userInterfaceToolkit: UserInterfaceToolkit? {
        get { self[UserInterfaceToolkitEnvironmentKey.self] }
        set { self[UserInterfaceToolkitEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Extension for convenience

extension View {
    func userInterfaceToolkit(_ toolkit: UserInterfaceToolkit) -> some View {
        self.environment(\.userInterfaceToolkit, toolkit)
    }
}
