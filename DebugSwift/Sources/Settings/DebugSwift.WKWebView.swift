//
//  DebugSwift.WKWebView.swift
//  DebugSwift
//
//  Created by Matheus Gois.
//  Copyright © 2024 DebugSwift. All rights reserved.
//

import Foundation

extension DS {
    
    /// Configuration and utilities for WKWebView network monitoring
    public final class WKWebView: @unchecked Sendable {
        
        /// Shared instance for WKWebView configuration
        public static let shared = WKWebView()
        
        /// Whether WKWebView network monitoring is enabled
        public var isEnabled: Bool {
            get {
                UserDefaults.standard.bool(forKey: "DebugSwift.WKWebView.isEnabled")
            }
            set {
                UserDefaults.standard.set(newValue, forKey: "DebugSwift.WKWebView.isEnabled")
                updateMonitoringState()
            }
        }
        
        /// Whether to capture request bodies in WKWebView monitoring
        public var captureRequestBodies: Bool {
            get {
                UserDefaults.standard.object(forKey: "DebugSwift.WKWebView.captureRequestBodies") as? Bool ?? true
            }
            set {
                UserDefaults.standard.set(newValue, forKey: "DebugSwift.WKWebView.captureRequestBodies")
            }
        }
        
        /// Whether to capture response headers in WKWebView monitoring
        public var captureResponseHeaders: Bool {
            get {
                UserDefaults.standard.object(forKey: "DebugSwift.WKWebView.captureResponseHeaders") as? Bool ?? true
            }
            set {
                UserDefaults.standard.set(newValue, forKey: "DebugSwift.WKWebView.captureResponseHeaders")
            }
        }
        
        /// Maximum number of WebView requests to store (0 = unlimited)
        public var maxStoredRequests: Int {
            get {
                let stored = UserDefaults.standard.integer(forKey: "DebugSwift.WKWebView.maxStoredRequests")
                return stored == 0 ? 1000 : stored  // Default to 1000 if not set
            }
            set {
                UserDefaults.standard.set(newValue, forKey: "DebugSwift.WKWebView.maxStoredRequests")
            }
        }
        
        private init() {
            // Set default values on first launch
            if !UserDefaults.standard.bool(forKey: "DebugSwift.WKWebView.hasSetDefaults") {
                UserDefaults.standard.set(true, forKey: "DebugSwift.WKWebView.hasSetDefaults")
                UserDefaults.standard.set(true, forKey: "DebugSwift.WKWebView.isEnabled")
                UserDefaults.standard.set(true, forKey: "DebugSwift.WKWebView.captureRequestBodies")
                UserDefaults.standard.set(true, forKey: "DebugSwift.WKWebView.captureResponseHeaders")
                UserDefaults.standard.set(1000, forKey: "DebugSwift.WKWebView.maxStoredRequests")
            }
        }
        
        /// Manually enable WKWebView network monitoring
        public func enable() {
            isEnabled = true
        }
        
        /// Manually disable WKWebView network monitoring
        public func disable() {
            isEnabled = false
        }

        /// Install WKWebView network monitoring (called automatically when network monitoring is enabled)
        @MainActor
        public func install() {
            guard isEnabled else { return }
            WKWebViewNetworkMonitor.shared.install()
        }
        
        /// Get current configuration as dictionary
        public func getConfiguration() -> [String: Any] {
            return [
                "isEnabled": isEnabled,
                "captureRequestBodies": captureRequestBodies,
                "captureResponseHeaders": captureResponseHeaders,
                "maxStoredRequests": maxStoredRequests
            ]
        }
        
        /// Reset WKWebView settings to defaults
        public func resetToDefaults() {
            UserDefaults.standard.removeObject(forKey: "DebugSwift.WKWebView.isEnabled")
            UserDefaults.standard.removeObject(forKey: "DebugSwift.WKWebView.captureRequestBodies")
            UserDefaults.standard.removeObject(forKey: "DebugSwift.WKWebView.captureResponseHeaders")
            UserDefaults.standard.removeObject(forKey: "DebugSwift.WKWebView.maxStoredRequests")
            UserDefaults.standard.removeObject(forKey: "DebugSwift.WKWebView.hasSetDefaults")
            
            // Reinitialize defaults
            if !UserDefaults.standard.bool(forKey: "DebugSwift.WKWebView.hasSetDefaults") {
                UserDefaults.standard.set(true, forKey: "DebugSwift.WKWebView.hasSetDefaults")
                UserDefaults.standard.set(true, forKey: "DebugSwift.WKWebView.isEnabled")
                UserDefaults.standard.set(true, forKey: "DebugSwift.WKWebView.captureRequestBodies")
                UserDefaults.standard.set(true, forKey: "DebugSwift.WKWebView.captureResponseHeaders")
                UserDefaults.standard.set(1000, forKey: "DebugSwift.WKWebView.maxStoredRequests")
            }
            
            updateMonitoringState()
        }
        
        private func updateMonitoringState() {
            // Just enable/disable the monitoring based on current setting
            // The actual network state check is done in NetworkHelper
            if isEnabled {
                Task { @MainActor in
                    WKWebViewNetworkMonitor.shared.install()
                }
            } else {
                Task { @MainActor in
                    WKWebViewNetworkMonitor.shared.uninstall()
                }
            }
        }
    }
}
