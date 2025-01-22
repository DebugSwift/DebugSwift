//
//  MeasurementWindowManager.swift
//  HyperionSwift
//
//  Created by Matheus Gois on 01/01/25.
//

import Foundation
import UIKit

public enum MeasurementWindowManager {
    public static var attachedWindow: UIWindow? {
        didSet {
            presentController.attachedWindow = attachedWindow
            let isEnabled = attachedWindow != nil

            window.isHidden = !isEnabled
        }
    }

    static var currentWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows.filter { $0.isKeyWindow }.first
        } else {
            return UIApplication.shared.keyWindow
        }
    }

    private static var rootNavigation: UINavigationController? {
        let navigation = window.rootViewController as? UINavigationController
        return navigation
    }

    private static var presentController: CustomViewController {
        return rootNavigation!.topViewController! as! CustomViewController
    }

    private static let window: MeasurementWindow = {
        let window: MeasurementWindow
        if #available(iOS 13.0, *),
           let scene = currentWindow?.windowScene {
            window = MeasurementWindow(windowScene: scene)
        } else {
            window = MeasurementWindow(frame: UIScreen.main.bounds)
        }

        let navigation = UINavigationController(rootViewController: CustomViewController())
        window.rootViewController = navigation
        window.isHidden = false

        return window
    }()
}

final class MeasurementWindow: UIWindow {
    override var description: String {
        "MeasurementWindow is \(isHidden ? "hidden" : "visible")"
    }

    override var windowLevel: UIWindow.Level {
        get {
            .alert + 1
        }
        set {}
    }
}

final class CustomViewController: UIViewController, MeasurementViewDelegate {
    var attachedWindow: UIWindow? {
        didSet {
            if attachedWindow != nil {
                view = MeasurementsView(delegate: self)
            }
        }
    }

    var contentView: MeasurementsView { view as! MeasurementsView }

    override func loadView() {
        super.loadView()
        view = MeasurementsView(delegate: self)
    }
}
