//
//  UserInterfaceToolkit.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

final class UserInterfaceToolkit {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                guard oldValue != self.slowAnimationsEnabled else { return }
                UIApplication.shared.windows.forEach { self.setSpeed(for: $0) }
            }
        }
    }

    static var colorizedViewBordersEnabled = false {
        didSet {
            guard oldValue != colorizedViewBordersEnabled else { return }
            NotificationCenter.default.post(
                name: notification,
                object: NSNumber(value: colorizedViewBordersEnabled)
            )
        }
    }

    var showingTouchesEnabled = false {
        didSet {
            guard oldValue != showingTouchesEnabled else { return }
            UIApplication.shared.windows.forEach { setShowingTouchesEnabled(for: $0) }
        }
    }

    // MARK: - Initialization

    private init() {
        registerForNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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

    // MARK: - Handling flags

    private func setSpeed(for window: UIWindow) {
        let speed: Float = slowAnimationsEnabled ? 0.1 : 1.0
        window.layer.speed = speed
    }

    private func setShowingTouchesEnabled(for window: UIWindow) {
        window.setShowingTouchesEnabled(showingTouchesEnabled)
    }

    // MARK: - Grid overlay

    func setSelectedGridOverlayColorSchemeIndex(_ selectedGridOverlayColorSchemeIndex: Int) {
        gridOverlay.colorScheme = gridOverlayColorSchemes[selectedGridOverlayColorSchemeIndex]
    }

    var selectedGridOverlayColorSchemeIndex: Int {
        guard let colorScheme = gridOverlay.colorScheme else { return 0 }
        return gridOverlayColorSchemes.firstIndex(
            of: colorScheme
        ) ?? .zero
    }
}

extension UserInterfaceToolkit {
    static let notification = Notification.Name(
        "UserInterfaceToolkitColorizedViewBordersChangedNotification")
}
