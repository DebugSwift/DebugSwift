//
//  OrientationForwardingNavigationControllerTests.swift
//  DebugSwift
//
//  Created by Copilot on 10/04/2026.
//

import Testing
import UIKit
@testable import DebugSwift

// MARK: - Mock View Controller for orientation testing

@MainActor
private final class PortraitOnlyViewController: UIViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .portrait
    }
}

@MainActor
private final class LandscapeOnlyViewController: UIViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .landscape
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .landscapeLeft
    }
}

// MARK: - Tests

struct OrientationForwardingNavigationControllerTests {

    // MARK: - Integration: WindowManager uses forwarding nav controller

    @Test("WindowManager window uses OrientationForwardingNavigationController")
    @MainActor
    func windowManagerUsesForwardingNavController() async {
        #expect(WindowManager.window.rootViewController is OrientationForwardingNavigationController)
    }

    // MARK: - Forwarding behavior with an app window present

    @Test("Forwards supportedInterfaceOrientations from app root VC")
    @MainActor
    func forwardsSupportedInterfaceOrientations() async {
        let appWindow = makeAppWindow(rootViewController: PortraitOnlyViewController())
        let navController = OrientationForwardingNavigationController(
            rootViewController: UIViewController()
        )

        #expect(navController.supportedInterfaceOrientations == .portrait)

        cleanUp(window: appWindow)
    }

    @Test("Forwards preferredInterfaceOrientationForPresentation from app root VC")
    @MainActor
    func forwardsPreferredInterfaceOrientationForPresentation() async {
        let appWindow = makeAppWindow(rootViewController: PortraitOnlyViewController())
        let navController = OrientationForwardingNavigationController(
            rootViewController: UIViewController()
        )

        #expect(navController.preferredInterfaceOrientationForPresentation == .portrait)

        cleanUp(window: appWindow)
    }

    @Test("Forwards landscape supportedInterfaceOrientations from app root VC")
    @MainActor
    func forwardsLandscapeSupportedInterfaceOrientations() async {
        let appWindow = makeAppWindow(rootViewController: LandscapeOnlyViewController())
        let navController = OrientationForwardingNavigationController(
            rootViewController: UIViewController()
        )

        #expect(navController.supportedInterfaceOrientations == .landscape)

        cleanUp(window: appWindow)
    }

    @Test("Forwards landscape preferredInterfaceOrientationForPresentation from app root VC")
    @MainActor
    func forwardsLandscapePreferredOrientation() async {
        let appWindow = makeAppWindow(rootViewController: LandscapeOnlyViewController())
        let navController = OrientationForwardingNavigationController(
            rootViewController: UIViewController()
        )

        #expect(navController.preferredInterfaceOrientationForPresentation == .landscapeLeft)

        cleanUp(window: appWindow)
    }

    // MARK: - Fallback behavior (no app window)

    @Test("Falls back to default supportedInterfaceOrientations when no app window")
    @MainActor
    func fallbackSupportedInterfaceOrientations() async {
        let navController = OrientationForwardingNavigationController(
            rootViewController: UIViewController()
        )

        // When no app windows are found, it should return the UINavigationController default
        let defaultNav = UINavigationController(rootViewController: UIViewController())
        #expect(navController.supportedInterfaceOrientations == defaultNav.supportedInterfaceOrientations)
    }

    @Test("Falls back to default preferredInterfaceOrientationForPresentation when no app window")
    @MainActor
    func fallbackPreferredInterfaceOrientationForPresentation() async {
        let navController = OrientationForwardingNavigationController(
            rootViewController: UIViewController()
        )

        let defaultNav = UINavigationController(rootViewController: UIViewController())
        #expect(
            navController.preferredInterfaceOrientationForPresentation
                == defaultNav.preferredInterfaceOrientationForPresentation
        )
    }

    // MARK: - iOS 18+ prefersInterfaceOrientationLocked

    @Test("Forwards prefersInterfaceOrientationLocked from app root VC on iOS 18+")
    @MainActor
    func forwardsPrefersInterfaceOrientationLocked() async {
        guard #available(iOS 18.0, *) else { return }

        let appWindow = makeAppWindow(rootViewController: UIViewController())
        let navController = OrientationForwardingNavigationController(
            rootViewController: UIViewController()
        )

        // Default UIViewController returns false for prefersInterfaceOrientationLocked
        #expect(navController.prefersInterfaceOrientationLocked == false)

        cleanUp(window: appWindow)
    }

    @Test("Falls back to default prefersInterfaceOrientationLocked when no app window on iOS 18+")
    @MainActor
    func fallbackPrefersInterfaceOrientationLocked() async {
        guard #available(iOS 18.0, *) else { return }

        let navController = OrientationForwardingNavigationController(
            rootViewController: UIViewController()
        )

        let defaultNav = UINavigationController(rootViewController: UIViewController())
        #expect(navController.prefersInterfaceOrientationLocked == defaultNav.prefersInterfaceOrientationLocked)
    }

    // MARK: - Helpers

    /// Creates a UIWindow at normal level with the given root VC, attached to the current window scene,
    /// and makes it key so `appRootViewController` can discover it.
    @MainActor
    private func makeAppWindow(rootViewController: UIViewController) -> UIWindow {
        let window: UIWindow
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first {
            window = UIWindow(windowScene: scene)
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
        }
        window.windowLevel = .normal
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        return window
    }

    @MainActor
    private func cleanUp(window: UIWindow) {
        window.isHidden = true
        window.rootViewController = nil
        window.resignKey()
    }
}
