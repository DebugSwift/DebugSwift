//
//  Example_SwiftUIApp.swift
//  Example_SwiftUI
//
//  Created by Matheus Gois on 16/12/23.
//

import DebugSwift
import SwiftUI
import Alamofire

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
        // Remove comment below to remove specific features and comment DebugSwift.setup() not to double trigger.
        // DebugSwift.setup(hideFeatures: [.interface, .app, .resources, .performance])
        DebugSwift.setup()
        DebugSwift.show()

        DebugSwift.Network.delegate = self
        return true
    }

    func additionalViewControllers() -> [UIViewController] {
        let viewController = UITableViewController()
        viewController.title = "PURE"
        return [viewController]
    }
}

// MARK: - Alamofire bugfix in uploadProgress

extension AppDelegate: CustomHTTPProtocolDelegate {
    func urlSession(
        _ protocol: URLProtocol,
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {

        Session.default.session.getAllTasks { tasks in
            let uploadTask = tasks.first(where: { $0.taskIdentifier == task.taskIdentifier }) ?? task
            Session.default.rootQueue.async {
                Session.default.delegate.urlSession(
                    session,
                    task: uploadTask,
                    didSendBodyData: bytesSent,
                    totalBytesSent: totalBytesSent,
                    totalBytesExpectedToSend: totalBytesExpectedToSend
                )
            }
        }
    }
}
