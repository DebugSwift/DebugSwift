//
//  OrientationForwardingNavigationController.swift
//  DebugSwift
//

import UIKit

final class OrientationForwardingNavigationController: UINavigationController {

    // UIApplication.topViewController walks the full nav/tab/presented chain
    // so it reaches whatever VC the app currently has on screen.
    private var appTopViewController: UIViewController? {
        UIApplication.topViewController()
    }

    override var shouldAutorotate: Bool {
        appTopViewController?.shouldAutorotate ?? super.shouldAutorotate
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        appTopViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        appTopViewController?.preferredInterfaceOrientationForPresentation
            ?? super.preferredInterfaceOrientationForPresentation
    }

}
