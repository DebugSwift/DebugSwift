//
//  DebugSwift.HyperionSwift.swift
//  DebugSwift
//
//  Created by Matheus Gois on 02/01/25.
//

import UIKit

extension DS {
    
    /// HyperionSwift UI measurement tools
    public enum Measurement {
        
        /// Activate the HyperionSwift measurement overlay
        /// This creates an interactive overlay that allows you to tap UI elements
        /// and measure distances between them in points
        @MainActor
        public static func activate() {
            HyperionSwift.shared.activateMeasurement()
            
            // Automatically dismiss DebugSwift interface to provide clean measurement view
            WindowManager.removeDebugger()
        }
        
        /// Deactivate the HyperionSwift measurement overlay
        @MainActor
        public static func deactivate() {
            HyperionSwift.shared.deactivateMeasurement()
        }
        
        /// Toggle the HyperionSwift measurement overlay
        @MainActor
        public static func toggle() {
            if isActive {
                deactivate()
            } else {
                activate()
            }
        }
        
        /// Check if HyperionSwift is currently active
        @MainActor
        public static var isActive: Bool {
            return MeasurementWindowManager.attachedWindow != nil
        }
    }
} 