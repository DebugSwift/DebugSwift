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
        DebugSwift.setup()
        DebugSwift.show()
        return true
    }
}
