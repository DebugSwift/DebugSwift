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
        // Remove comment below if you want to specific which features that will be removed. and don't forget to comment DebugSwift.setup()
        // DebugSwift.setup(hideFeatures: [.resources, .network, .app, .interface, .interface])
        DebugSwift.setup()
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

        // DebugSwift.Network.ignoredURLs = ["https://reqres.in/api/users/23"]
//        DebugSwift.Console.onlyLogs = ["DebugSwift"]
        DebugSwift.show()

        return true
    }

    func application(
        _: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        UISceneConfiguration(
            name: "Default Configuration", sessionRole: connectingSceneSession.role
        )
    }
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            DebugSwift.toggle()
        }
    }
}
