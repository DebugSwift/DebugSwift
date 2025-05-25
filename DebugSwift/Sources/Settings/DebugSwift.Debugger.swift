//
//  DebugSwift.Debugger.swift
//  DebugSwift
//
//  Created by Matheus Gois on 11/06/24.
//

import UIKit

extension DebugSwift {
    public class Debugger {
        /// Enable/Disable logs in Xcode console
        public var logEnable: Bool {
            get {
                Debug.enable
            } set {
                Debug.enable = newValue
            }
        }

        /// Enable/Disable `ImpactFeedback`
        public var feedbackEnable: Bool {
            get {
                ImpactFeedback.enable
            } set {
                ImpactFeedback.enable = newValue
            }
        }
    }
}
