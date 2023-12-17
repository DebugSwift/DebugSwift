//
//  Example_SwiftUIApp.swift
//  Example_SwiftUI
//
//  Created by Matheus Gois on 16/12/23.
//

import SwiftUI
import DebugSwift

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
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        DebugSwiftSettings.setup()
        DebugSwiftSettings.show()
        return true
    }
}
