//
//  AppDelegate.swift
//  Example
//
//  Created by Matheus Gois on 16/12/23.
//

import DebugSwift
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // DebugSwift.setup(hideFeatures: [.resources, .app, .interface, .interface, .performance])
        DebugSwift.setup()

        // Setup .light or dark mode, `default is .dark`.
        DebugSwift.theme(appearance: .dark)

        // MARK: - Custom Info

        DebugSwift.App.customInfo = {
            [
                .init(
                    title: "Info 1",
                    infos: [
                        .init(title: "title 1", subtitle: "subtitle 1")
                    ]
                )
            ]
        }

        // MARK: - Custom Actions

        DebugSwift.App.customAction = {
            [
                .init(
                    title: "Action 1",
                    actions: [
                        .init(title: "action 1") { // [weak self] in
                            print("Action 1")
                        }
                    ]
                )
            ]
        }

        // MARK: - Custom Controllers

        DebugSwift.App.customControllers = {
            let controller1 = UITableViewController()
            controller1.title = "Custom TableVC 1"

            let controller2 = UITableViewController()
            controller2.title = "Custom TableVC 2"

            return [controller1, controller2]
        }

        // MARK: - Customs

        // DebugSwift.Network.ignoredURLs = ["https://reqres.in/api/users/23"]
        // DebugSwift.Console.onlyLogs = ["DebugSwift"]

        // MARK: - Enable/Disable Debugger

        DebugSwift.Debugger.logEnable = true
        DebugSwift.Debugger.feedbackEnable = true

        DebugSwift.show()

        return true
    }
}

// MARK: - Enable motion detection example.

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            DebugSwift.toggle()
        }
    }
}
