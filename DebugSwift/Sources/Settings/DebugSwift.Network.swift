//
//  DebugSwift.Network.swift
//  DebugSwift
//
//  Created by Matheus Gois on 11/06/24.
//

import UIKit

extension DebugSwift {
    public enum Network {
        public static var ignoredURLs = [String]()
        public static var onlyURLs = [String]()

        public static var delegate: CustomHTTPProtocolDelegate?
    }
}
