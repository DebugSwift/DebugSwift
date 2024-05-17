//
//  ReachabilityManager.swift
//  DebugSwift
//
//  Created by Matheus Gois on 18/01/24.
//

import CoreTelephony
import Foundation

enum ReachabilityManager {

    private static var reachability = try? Reachability()

    static var connection: NetworkType {
        reachability?.getNetworkType() ?? .unknownTechnology
    }
}
