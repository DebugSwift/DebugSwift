//
//  SignalCrashMetadata.swift
//  DebugSwift
//
//  Created by gua on 2026/10/20.
//

import Foundation

/// Independent startup payload, encoded before installation. Keep its schema separate
/// from the domain model; the fault name/time are supplied at the recovery boundary.
struct SignalCrashMetadata: Codable {
    let captureID: UUID
    let appVersion: String?
    let appBuild: String?
    let iosVersion: String
    let deviceModel: String
    let reachability: String

    init(details: CrashModel.Details, captureID: UUID = UUID()) {
        self.captureID = captureID
        self.appVersion = details.appVersion
        self.appBuild = details.appBuild
        self.iosVersion = details.iosVersion
        self.deviceModel = details.deviceModel
        self.reachability = details.reachability
    }

    func makeDetails(name: String, date: Date) -> CrashModel.Details {
        .init(
            name: name,
            date: date,
            appVersion: appVersion,
            appBuild: appBuild,
            iosVersion: iosVersion,
            deviceModel: deviceModel,
            reachability: reachability
        )
    }
}
