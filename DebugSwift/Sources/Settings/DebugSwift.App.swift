//
//  DebugSwift.App.swift
//  DebugSwift
//
//  Created by Matheus Gois on 11/06/24.
//

import UIKit

extension DebugSwift {
    public class App: @unchecked Sendable {
        public static let shared = App()
        private init() {}
        
        public var customInfo: (() -> [CustomData])?
        public var customAction: (() -> [CustomAction])?
        public var customControllers: (() -> [UIViewController])?

        @MainActor private var _defaultControllers: [UIViewController & MainFeatureType]?
        
        @MainActor var defaultControllers: [UIViewController & MainFeatureType] {
            get {
                if _defaultControllers == nil {
                    _defaultControllers = [
                        NetworkViewController(),
                        PerformanceViewController(),
                        InterfaceViewController(),
                        ResourcesViewController(),
                        AppViewController()
                    ]
                }
                return _defaultControllers!
            }
            set {
                _defaultControllers = newValue
            }
        }

        var disableMethods: [DebugSwiftSwizzleFeature] = []
    }
}
