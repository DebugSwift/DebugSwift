//
//  DocRecorderExporter.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/05/26.
//

import Foundation
import UIKit

@MainActor
final class DocRecorderExporter {
    private var temporaryFileURLs: [URL] = []

    func export(steps: [RecordingSession.Step], completion: @escaping () -> Void) {
        let images = steps.map { $0.annotatedImage }

        guard !images.isEmpty else {
            completion()
            return
        }

        let fileURLs = saveImagesToTemporaryFiles(images: images)
        guard !fileURLs.isEmpty else {
            completion()
            return
        }

        temporaryFileURLs = fileURLs

        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else {
            cleanupTemporaryFiles()
            completion()
            return
        }

        guard let topViewController = windowScene.windows
            .first(where: { $0.isKeyWindow })?
            .rootViewController?
            .docRecorder_topmostViewController()
        else {
            cleanupTemporaryFiles()
            completion()
            return
        }

        let activityViewController = UIActivityViewController(
            activityItems: fileURLs,
            applicationActivities: nil
        )

        activityViewController.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.cleanupTemporaryFiles()
            completion()
        }

        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = topViewController.view
            popoverController.sourceRect = CGRect(
                x: topViewController.view.bounds.midX,
                y: topViewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }

        topViewController.present(activityViewController, animated: true)
    }

    private func saveImagesToTemporaryFiles(images: [UIImage]) -> [URL] {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DocRecorder-\(UUID().uuidString)", isDirectory: true)

        do {
            try FileManager.default.createDirectory(
                at: tempDirectory, withIntermediateDirectories: true
            )
        } catch {
            return []
        }

        var fileURLs: [URL] = []

        for (index, image) in images.enumerated() {
            let fileName = String(format: "screenshot-%03d.png", index + 1)
            let fileURL = tempDirectory.appendingPathComponent(fileName)

            guard let pngData = image.pngData() else { continue }

            do {
                try pngData.write(to: fileURL)
                fileURLs.append(fileURL)
            } catch {}
        }

        return fileURLs
    }

    private func cleanupTemporaryFiles() {
        for url in temporaryFileURLs {
            if url.deletingLastPathComponent().path.contains("DocRecorder") {
                try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
                break
            }
        }
        temporaryFileURLs.removeAll()
    }
}

extension UIViewController {
    func docRecorder_topmostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.docRecorder_topmostViewController()
        }
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.docRecorder_topmostViewController() ?? self
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.docRecorder_topmostViewController() ?? self
        }
        return self
    }
}
