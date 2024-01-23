//
//  Example_SwiftUIApp.swift
//  Example_SwiftUI
//
//  Created by Matheus Gois on 16/12/23.
//

import DebugSwift
import SwiftUI

@available(iOS 14.0, *)
@main
struct Example_SwiftUIApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Remove comment below if u want to hide some features and don't forget to comment DebugSwift.setup()
        // DebugSwift.hideFeatureByIndexAndSetup(indexArr: [1,2,3,4])
        DebugSwift.setup()
        DebugSwift.show()
        return true
    }
}
