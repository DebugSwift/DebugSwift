//
//  ExceptionCrashCapture.swift
//  DebugSwift
//
//  Created by gua on 2026/10/21.
//

import Foundation
#if canImport(DebugSwiftSignalCapture)
internal import DebugSwiftSignalCapture
#endif

/// Normal startup captures metadata and initializes the store BEFORE installing
/// the native terminal handler. Fatal paths never initialize UIKit/console state.
final class ExceptionCrashCapture: @unchecked Sendable {
    static let shared = ExceptionCrashCapture(manager: .shared, details: .builder(name: ""))

    private let manager: CrashManager
    private let details: CrashModel.Details

    init(manager: CrashManager, details: CrashModel.Details) {
        self.manager = manager
        self.details = details
    }

    func prepare() {
        let result = DSExceptionCaptureInstall { pointer in
            guard let pointer else { return }
            let exception = Unmanaged<NSException>.fromOpaque(pointer).takeUnretainedValue()
            UncaughtExceptionHandler(exception: exception)
        }
        if result != 0 {
            Debug.print("Unable to prepare exception crash capture: \(result)")
        }
    }

    @discardableResult
    func persist(name: String, symbols: [String]) -> Bool {
        manager.persistException {
            CrashModel(
                type: .nsexception,
                details: .init(
                    name: name, date: Date(), appVersion: details.appVersion, appBuild: details.appBuild,
                    iosVersion: details.iosVersion, deviceModel: details.deviceModel, reachability: details.reachability
                ),
                context: .init(image: nil, consoleOutput: "", errorOutput: ""),
                traces: .builder(symbols)
            )
        }
    }
}
