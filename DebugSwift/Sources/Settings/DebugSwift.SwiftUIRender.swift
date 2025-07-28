//
//  DebugSwift.SwiftUIRender.swift
//  DebugSwift
//
//  Created by DebugSwift on 2025/01/27.
//

import Foundation

extension DebugSwift {
    @MainActor
    public class SwiftUIRender: @unchecked Sendable {
        public static let shared = SwiftUIRender()
        private init() {}
        
        /// Enable or disable SwiftUI render tracking
        public var isEnabled: Bool {
            get { SwiftUIRenderTracker.shared.isEnabled }
            set { SwiftUIRenderTracker.shared.isEnabled = newValue }
        }
        
        /// Configure the visual overlay style for render highlights
        public var overlayStyle: SwiftUIRenderTracker.RenderOverlayStyle {
            get { SwiftUIRenderTracker.shared.overlayStyle }
            set { SwiftUIRenderTracker.shared.overlayStyle = newValue }
        }
        
        /// Configure the duration for render highlight overlays
        public var overlayDuration: TimeInterval {
            get { SwiftUIRenderTracker.shared.overlayDuration }
            set { SwiftUIRenderTracker.shared.overlayDuration = newValue }
        }
        
        /// Enable or disable logging of render events to console
        public var loggingEnabled: Bool {
            get { SwiftUIRenderTracker.shared.loggingEnabled }
            set { SwiftUIRenderTracker.shared.loggingEnabled = newValue }
        }
        
        /// When enabled, overlays will persist and not fade out automatically
        public var persistentOverlays: Bool {
            get { SwiftUIRenderTracker.shared.persistentOverlays }
            set { SwiftUIRenderTracker.shared.persistentOverlays = newValue }
        }
        
        /// Clear all persistent overlays from the screen
        public func clearPersistentOverlays() {
            SwiftUIRenderTracker.shared.clearAllPersistentOverlays()
        }
        
        /// Clean up orphaned overlays whose original views are no longer visible
        public func cleanupOrphanedOverlays() {
            SwiftUIRenderTracker.shared.cleanupOrphanedOverlays()
        }
        
        /// Get render statistics
        public func getRenderStats() -> [String: Any] {
            SwiftUIRenderTracker.shared.getRenderStats()
        }
        
        /// Clear render statistics
        public func clearStats() {
            SwiftUIRenderTracker.shared.clearStats()
        }
    }
} 