//
//  AppDelegate.swift
//  NewCocoaDebug
//
//  Created by 周晓瑞 on 2018/6/12.
//  Copyright © 2018年 apple. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        self.window = UIWindow(frame: UIScreen.main.bounds)
        let navigation = UINavigationController(rootViewController: TabBarController())
        self.window?.rootViewController = navigation
        self.window?.makeKeyAndVisible()

        return true
    }

}
