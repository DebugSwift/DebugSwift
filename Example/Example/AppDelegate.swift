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
        DebugSwift.setup()
        DebugSwift.App.customInfo = {
            [
                .init(
                    title: "Info 1",
                    infos: [
                        .init(title: "title 1", subtitle: "title 2")
                    ]
                )
            ]
        }

        DebugSwift.Network.ignoredURLs = ["https://reqres.in/api/users/23"]
        DebugSwift.show()

        return true
    }

    // MARK: UISceneSession Lifecycle

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

    func application(
        _: UIApplication, didDiscardSceneSessions _: Set<UISceneSession>
    ) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
