//
//  DiskAnalyzer.swift
//  DebugSwift
//
//  Created by Matheus Gois on 08/05/26.
//

import Foundation

@MainActor
final class DiskAnalyzer: ObservableObject {
    @Published private(set) var usageInfo: DiskUsageInfo?

    func measure() {
        Task { @MainActor [weak self] in
            let info = await Task.detached {
                DiskAnalyzer.computeUsageInfo()
            }.value
            self?.usageInfo = info
        }
    }

    private nonisolated static func computeUsageInfo() -> DiskUsageInfo? {
        let fileManager = FileManager.default

        guard let attrs = try? fileManager.attributesOfFileSystem(
            forPath: NSHomeDirectory()
        ) else { return nil }

        let totalSpace = (attrs[.systemSize] as? Int64) ?? 0
        let freeSpace = (attrs[.systemFreeSize] as? Int64) ?? 0
        let usedSpace = totalSpace - freeSpace

        let bundleSize = directorySize(at: Bundle.main.bundlePath)
        let cachesSize: Int64
        if let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            cachesSize = directorySize(at: cachesDir.path)
        } else {
            cachesSize = 0
        }
        let tempSize = directorySize(at: NSTemporaryDirectory())
        let documentsSize: Int64
        if let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            documentsSize = directorySize(at: docsDir.path)
        } else {
            documentsSize = 0
        }

        return DiskUsageInfo(
            totalSpace: totalSpace,
            freeSpace: freeSpace,
            usedSpace: usedSpace,
            bundleSize: bundleSize,
            cachesSize: cachesSize,
            tempSize: tempSize,
            documentsSize: documentsSize
        )
    }

    private nonisolated static func directorySize(at path: String) -> Int64 {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(atPath: path) else { return 0 }

        var totalSize: Int64 = 0
        while let file = enumerator.nextObject() as? String {
            let fullPath = (path as NSString).appendingPathComponent(file)
            if let attrs = try? fileManager.attributesOfItem(atPath: fullPath),
               let size = attrs[.size] as? Int64 {
                totalSize += size
            }
        }
        return totalSize
    }
}
