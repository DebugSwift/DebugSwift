//
//  DebugSwift.Network.swift
//  DebugSwift
//
//  Created by Matheus Gois on 11/06/24.
//

import UIKit

extension DebugSwift {
    public class Network: @unchecked Sendable {
        public static let shared = Network()
        private init() {}
        
        public var ignoredURLs = [String]()
        public var onlyURLs = [String]()
        public var onlySchemes = CustomHTTPProtocolURLScheme.allCases
        public var delegate: CustomHTTPProtocolDelegate?
    }
}
