//
//  DebugSwift.Console.swift
//  DebugSwift
//
//  Created by Matheus Gois on 11/06/24.
//

import UIKit

extension DebugSwift {
    public class Console: @unchecked Sendable {
        public static let shared = Console()
        private init() {}
        
        public var ignoredLogs = [String]()
        public var onlyLogs = [String]()
    }
}
