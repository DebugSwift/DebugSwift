//
//  DebugSwift.Debugger.swift
//  DebugSwift
//
//  Created by Matheus Gois on 11/06/24.
//

import UIKit

extension DebugSwift {
    public enum Debugger {
        /// Enable/Disable logs in Xcode console
        public static var logEnable: Bool {
            get {
                Debug.enable
            } set {
                Debug.enable = newValue
            }
        }

        /// Enable/Disable `ImpactFeedback`
        public static var feedbackEnable: Bool {
            get {
                ImpactFeedback.enable
            } set {
                ImpactFeedback.enable = newValue
            }
        }
    }
}
