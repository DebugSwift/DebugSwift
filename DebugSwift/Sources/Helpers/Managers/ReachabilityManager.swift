//
//  ReachabilityManager.swift
//  DebugSwift
//
//  Created by Matheus Gois on 18/01/24.
//

import Foundation

struct ReachabilityManager {

    private static var reachability = try? Reachability()

    static var connection: NetworkType {
        reachability?.getNetworkType() ?? .unknownTechnology
    }
}
