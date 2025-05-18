//
//  DebugSwift.App.swift
//  DebugSwift
//
//  Created by Matheus Gois on 11/06/24.
//

import UIKit

extension DebugSwift {
    public class App {
        public static let shared = App()
        private init() {}
        
        public var customInfo: (() -> [CustomData])?
        public var customAction: (() -> [CustomAction])?
        public var customControllers: (() -> [UIViewController])?

        var defaultControllers: [UIViewController & MainFeatureType] = [
            NetworkViewController(),
            PerformanceViewController(),
            InterfaceViewController(),
            ResourcesViewController(),
            AppViewController()
        ]

        var disableMethods: [DebugSwiftSwizzleFeature] = []
    }
}
