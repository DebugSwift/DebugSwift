//
//  FileSharingManager.swift
//  DebugSwift
//
//  Created by Matheus Gois on 19/05/24.
//

import UIKit

enum FileSharingManager {
    static func generateFileAndShare(text: String, fileName: String) {
        let tempURL = URL(
            fileURLWithPath: NSTemporaryDirectory()
        ).appendingPathComponent("\(fileName).txt")

        do {
            try text.write(to: tempURL, atomically: true, encoding: .utf8)
            share(tempURL)
        } catch {
            Debug.print("Error: \(error.localizedDescription)")
        }
    }

    static func share(_ tempURL: URL) {
        let activity = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )

        guard let controller = UIApplication.topViewController() else { return }

        if let popover = activity.popoverPresentationController {
            popover.sourceView = controller.view
            popover.permittedArrowDirections = .up
        }

        controller.present(activity, animated: true, completion: nil)
    }
}
