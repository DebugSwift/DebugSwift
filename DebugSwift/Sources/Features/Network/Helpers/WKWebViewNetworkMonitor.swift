//
//  WKWebViewNetworkMonitor.swift
//  DebugSwift
//
//  Created by Matheus Gois.
//  Copyright © 2024 DebugSwift. All rights reserved.
//

import Foundation
import WebKit
import ObjectiveC.runtime

// MARK: - WKWebView Network Monitor

/// A Swift 6-compatible WKWebView network monitoring system that integrates with DebugSwift
@MainActor
final class WKWebViewNetworkMonitor: NSObject, Sendable {
    static let shared = WKWebViewNetworkMonitor()
    
    private var isInstalled = false
    private let messageHandlerName = "__debugswift_webview_net__"
    
    override init() {
        super.init()
    }
    
    /// Installs the WKWebView network monitoring system
    func install() {
        guard !isInstalled else { return }
        isInstalled = true

        WKWebViewSwizzler.install()
    }
    
    /// Uninstalls the WKWebView network monitoring system
    func uninstall() {
        guard isInstalled else { return }
        isInstalled = false
    }
}

// MARK: - Swizzler

enum WKWebViewSwizzler {
    private nonisolated(unsafe) static var isInstalled = false
    
    @MainActor
    static func install() {
        guard !isInstalled else { return }
        isInstalled = true
        
        guard let originalMethod = class_getInstanceMethod(
            WKWebView.self, 
            #selector(WKWebView.init(frame:configuration:))
        ) else {
            print("⚠️ DebugSwift: Failed to get WKWebView init method")
            return
        }
        
        guard let swizzledMethod = class_getInstanceMethod(
            WKWebView.self, 
            #selector(WKWebView.debugswift_init(frame:configuration:))
        ) else {
            print("⚠️ DebugSwift: Failed to get WKWebView swizzled method")
            return
        }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
        print("✅ DebugSwift: WKWebView network monitoring installed")
    }
}

// MARK: - WKWebView Extension with Network Injection

private nonisolated(unsafe) var kInjectedConfigKey: UInt8 = 0

extension WKWebView {
    
    @objc 
    func debugswift_init(frame: CGRect, configuration: WKWebViewConfiguration) -> WKWebView {
        // Inject network monitoring into configuration before initialization
        Self.injectNetworkMonitoring(into: configuration)
        
        // Call original initializer (swizzled)
        return self.debugswift_init(frame: frame, configuration: configuration)
    }
    
    @MainActor
    private static func injectNetworkMonitoring(into configuration: WKWebViewConfiguration) {
        // Prevent double injection
        let wasInjected = objc_getAssociatedObject(configuration, &kInjectedConfigKey) as? Bool ?? false
        guard !wasInjected else { return }
        
        objc_setAssociatedObject(configuration, &kInjectedConfigKey, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Create JavaScript injection for network monitoring
        let networkScript = Self.createNetworkMonitoringScript()
        let userScript = WKUserScript(
            source: networkScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        
        // Add script and message handler
        let contentController = configuration.userContentController
        contentController.addUserScript(userScript)
        contentController.add(
            WebViewNetworkMessageHandler.shared,
            name: "__debugswift_webview_net__"
        )
        
        Debug.print("🌐 DebugSwift: Network monitoring injected into WKWebView")
    }
    
    private static func createNetworkMonitoringScript() -> String {
        return """
        (function() {
            'use strict';
            
            // Prevent multiple injections
            if (window.__debugSwiftWebViewNetPatched) return;
            window.__debugSwiftWebViewNetPatched = true;
            
            const messageHandler = '__debugswift_webview_net__';
            
            // Comprehensive navigation data collection
            function collectNavigationInfo(trigger = 'initial_load') {
                const navData = {
                    type: 'navigation',
                    trigger: trigger,
                    timestamp: Date.now(),
                    
                    // URL Information
                    url: window.location.href,
                    protocol: window.location.protocol,
                    hostname: window.location.hostname,
                    port: window.location.port,
                    pathname: window.location.pathname,
                    search: window.location.search,
                    hash: window.location.hash,
                    
                    // Page Information
                    title: document.title,
                    referrer: document.referrer,
                    readyState: document.readyState,
                    
                    // Browser Information
                    userAgent: navigator.userAgent,
                    language: navigator.language,
                    platform: navigator.platform,
                    cookieEnabled: navigator.cookieEnabled,
                    
                    // Viewport Information
                    viewport: {
                        width: window.innerWidth,
                        height: window.innerHeight,
                        screenWidth: window.screen?.width,
                        screenHeight: window.screen?.height,
                        devicePixelRatio: window.devicePixelRatio
                    },
                    
                    // History Information
                    historyLength: window.history?.length,
                    
                    // Performance Timing (if available)
                    timing: getPerformanceTiming(),
                    
                    // Storage Information
                    storage: getStorageInfo(),
                    
                    // Console Errors (recent)
                    errors: getRecentErrors()
                };
                
                safePostMessage(navData);
            }
            
            // Collect detailed performance timing
            function getPerformanceTiming() {
                try {
                    const perf = window.performance;
                    if (!perf || !perf.timing) return null;
                    
                    const timing = perf.timing;
                    const navigationStart = timing.navigationStart;
                    
                    return {
                        // Network timing
                        dnsLookup: timing.domainLookupEnd - timing.domainLookupStart,
                        tcpConnection: timing.connectEnd - timing.connectStart,
                        sslHandshake: timing.secureConnectionStart ? timing.connectEnd - timing.secureConnectionStart : 0,
                        
                        // Request/Response timing
                        requestStart: timing.requestStart - navigationStart,
                        responseStart: timing.responseStart - navigationStart,
                        responseEnd: timing.responseEnd - navigationStart,
                        
                        // DOM timing
                        domLoading: timing.domLoading - navigationStart,
                        domInteractive: timing.domInteractive - navigationStart,
                        domContentLoaded: timing.domContentLoadedEventEnd - navigationStart,
                        domComplete: timing.domComplete - navigationStart,
                        
                        // Page load timing
                        loadEventStart: timing.loadEventStart - navigationStart,
                        loadEventEnd: timing.loadEventEnd - navigationStart,
                        
                        // Total page load time
                        totalLoadTime: timing.loadEventEnd - navigationStart
                    };
                } catch (error) {
                    return { error: error.message };
                }
            }
            
            // Get storage information
            function getStorageInfo() {
                try {
                    const storage = {};
                    
                    // Local Storage
                    if (window.localStorage) {
                        storage.localStorage = {
                            length: localStorage.length,
                            keys: Object.keys(localStorage)
                        };
                    }
                    
                    // Session Storage  
                    if (window.sessionStorage) {
                        storage.sessionStorage = {
                            length: sessionStorage.length,
                            keys: Object.keys(sessionStorage)
                        };
                    }
                    
                    // Cookies
                    storage.cookies = {
                        count: document.cookie ? document.cookie.split(';').length : 0,
                        enabled: navigator.cookieEnabled
                    };
                    
                    return storage;
                } catch (error) {
                    return { error: error.message };
                }
            }
            
            // Track recent JavaScript errors
            let recentErrors = [];
            window.addEventListener('error', function(event) {
                recentErrors.push({
                    message: event.message,
                    filename: event.filename,
                    lineno: event.lineno,
                    colno: event.colno,
                    timestamp: Date.now(),
                    stack: event.error?.stack
                });
                
                // Keep only last 10 errors
                if (recentErrors.length > 10) {
                    recentErrors = recentErrors.slice(-10);
                }
            });
            
            function getRecentErrors() {
                return recentErrors.slice(); // Return copy
            }
            
            // Initial navigation data collection
            collectNavigationInfo('initial_load');
            
            function safePostMessage(data) {
                try {
                    window.webkit?.messageHandlers?.[messageHandler]?.postMessage(data);
                } catch (error) {
                    console.warn('DebugSwift: Failed to post message', error);
                }
            }
            
            function generateRequestId() {
                return 'req_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            }
            
            // Monitor Fetch API
            const originalFetch = window.fetch;
            window.fetch = function(input, init) {
                const requestId = generateRequestId();
                const startTime = Date.now();
                
                try {
                    const url = (typeof input === 'string') ? input : (input?.url || '');
                    const method = init?.method || 'GET';
                    
                    safePostMessage({
                        type: 'request_start',
                        requestId: requestId,
                        url: url,
                        method: method,
                        headers: init?.headers || {},
                        body: init?.body || null,
                        timestamp: startTime
                    });
                    
                } catch (error) {
                    console.warn('DebugSwift: Error capturing fetch request', error);
                }
                
                return originalFetch.apply(this, arguments)
                    .then(function(response) {
                        const endTime = Date.now();
                        
                        try {
                            safePostMessage({
                                type: 'response_received',
                                requestId: requestId,
                                url: response.url,
                                status: response.status,
                                statusText: response.statusText,
                                ok: response.ok,
                                headers: [...(response.headers || [])].reduce((obj, [key, value]) => {
                                    obj[key] = value;
                                    return obj;
                                }, {}),
                                timestamp: endTime,
                                duration: endTime - startTime
                            });
                        } catch (error) {
                            console.warn('DebugSwift: Error capturing fetch response', error);
                        }
                        
                        return response;
                    })
                    .catch(function(error) {
                        const endTime = Date.now();
                        
                        try {
                            safePostMessage({
                                type: 'request_error',
                                requestId: requestId,
                                error: error.message || 'Unknown error',
                                timestamp: endTime,
                                duration: endTime - startTime
                            });
                        } catch (captureError) {
                            console.warn('DebugSwift: Error capturing fetch error', captureError);
                        }
                        
                        throw error;
                    });
            };
            
            // Monitor XMLHttpRequest
            const originalXHROpen = XMLHttpRequest.prototype.open;
            const originalXHRSend = XMLHttpRequest.prototype.send;
            
            XMLHttpRequest.prototype.open = function(method, url) {
                this.__debugSwift = {
                    requestId: generateRequestId(),
                    method: method,
                    url: url,
                    startTime: null
                };
                
                return originalXHROpen.apply(this, arguments);
            };
            
            XMLHttpRequest.prototype.send = function(body) {
                const debugInfo = this.__debugSwift;
                if (debugInfo) {
                    debugInfo.startTime = Date.now();
                    
                    try {
                        safePostMessage({
                            type: 'request_start',
                            requestId: debugInfo.requestId,
                            url: debugInfo.url,
                            method: debugInfo.method,
                            body: body,
                            timestamp: debugInfo.startTime
                        });
                    } catch (error) {
                        console.warn('DebugSwift: Error capturing XHR request', error);
                    }
                    
                    // Monitor response
                    this.addEventListener('loadend', function() {
                        const endTime = Date.now();
                        
                        try {
                            const responseHeaders = {};
                            try {
                                const headerString = this.getAllResponseHeaders();
                                headerString.split('\\r\\n').forEach(function(header) {
                                    const [key, value] = header.split(': ');
                                    if (key && value) {
                                        responseHeaders[key] = value;
                                    }
                                });
                            } catch (headerError) {
                                console.warn('DebugSwift: Error parsing response headers', headerError);
                            }
                            
                            if (this.status === 0 && this.readyState === 4) {
                                // Network error
                                safePostMessage({
                                    type: 'request_error',
                                    requestId: debugInfo.requestId,
                                    error: 'Network error or request aborted',
                                    timestamp: endTime,
                                    duration: endTime - debugInfo.startTime
                                });
                            } else {
                                // Successful response (including 4xx, 5xx)
                                safePostMessage({
                                    type: 'response_received',
                                    requestId: debugInfo.requestId,
                                    url: debugInfo.url,
                                    status: this.status,
                                    statusText: this.statusText,
                                    ok: this.status >= 200 && this.status < 300,
                                    headers: responseHeaders,
                                    timestamp: endTime,
                                    duration: endTime - debugInfo.startTime
                                });
                            }
                        } catch (error) {
                            console.warn('DebugSwift: Error capturing XHR response', error);
                        }
                    });
                }
                
                return originalXHRSend.apply(this, arguments);
            };
            
            // Monitor page visibility changes (useful for SPA navigation)
            document.addEventListener('visibilitychange', function() {
                if (!document.hidden && window.location.href) {
                    collectNavigationInfo('visibility_change');
                }
            });
            
            // Monitor popstate events (back/forward navigation)
            window.addEventListener('popstate', function(event) {
                collectNavigationInfo('popstate');
            });
            
            // Monitor pushState/replaceState for SPA navigation
            const originalPushState = history.pushState;
            const originalReplaceState = history.replaceState;
            
            history.pushState = function() {
                originalPushState.apply(this, arguments);
                setTimeout(() => {
                    collectNavigationInfo('pushstate');
                }, 0);
            };
            
            history.replaceState = function() {
                originalReplaceState.apply(this, arguments);
                setTimeout(() => {
                    collectNavigationInfo('replacestate');
                }, 0);
            };
            
            // Monitor DOM content loaded for additional timing data
            document.addEventListener('DOMContentLoaded', function() {
                collectNavigationInfo('dom_content_loaded');
            });
            
            // Monitor window load for complete page timing
            window.addEventListener('load', function() {
                collectNavigationInfo('window_load');
            });
            
            console.log('🌐 DebugSwift: WebView network monitoring active');
            
        })();
        """
    }
}

// MARK: - Message Handler

final class WebViewNetworkMessageHandler: NSObject, WKScriptMessageHandler {
    static let shared = WebViewNetworkMessageHandler()
    
    private override init() {
        super.init()
    }
    
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let messageBody = message.body as? [String: Any] else {
            print("⚠️ DebugSwift: Invalid WebView network message format")
            return
        }
        
        processNetworkMessage(messageBody, from: message.webView)
    }
    
    private func processNetworkMessage(_ data: [String: Any], from webView: WKWebView?) {
        guard let type = data["type"] as? String else { return }
        
        switch type {
        case "request_start":
            handleRequestStart(data, webView: webView)
        case "response_received":
            handleResponseReceived(data, webView: webView)
        case "request_error":
            handleRequestError(data, webView: webView)
        case "navigation":
            handleNavigation(data, webView: webView)
        default:
            break
        }
    }
    
    private func handleRequestStart(_ data: [String: Any], webView: WKWebView?) {
        guard NetworkHelper.shared.isNetworkEnable else { return }
        
        let requestId = data["requestId"] as? String ?? ""
        let url = data["url"] as? String ?? ""
        let method = data["method"] as? String ?? "GET"
        let timestamp = data["timestamp"] as? Double ?? Date().timeIntervalSince1970 * 1000
        
        // Store request data for matching with response
        let requestInfo: [String: Any] = [
            "requestId": requestId,
            "url": url,
            "method": method,
            "startTime": Date(timeIntervalSince1970: timestamp / 1000),
            "headers": data["headers"] ?? [:],
            "body": data["body"] as Any,
            "webView": webView as Any
        ]
        
        // Store in temporary cache (could be improved with proper storage)
        WebViewRequestCache.shared.store(requestId: requestId, requestInfo: requestInfo)
        
        Debug.print("🌐 WebView Request: \(method) \(url)")
    }
    
    private func handleNavigation(_ data: [String: Any], webView: WKWebView?) {
        let url = data["url"] as? String ?? "unknown"
        let trigger = data["trigger"] as? String ?? "unknown"
        let title = data["title"] as? String ?? ""
        let userAgent = data["userAgent"] as? String ?? ""
        
        Debug.print("🧭 WebView Navigation (\(trigger)): \(url)")
        
        // Create comprehensive navigation event in the network log
        if DebugSwift.WKWebView.shared.isEnabled {
            let model = HttpModel()
            model.url = URL(string: url)
            model.method = "NAVIGATION"
            model.statusCode = "200"
            model.startTime = Date().formatted()
            model.endTime = Date().formatted()
            model.totalDuration = formatNavigationTiming(data["timing"] as? [String: Any])
            model.requestId = "nav_\(UUID().uuidString)"
            
            // Build comprehensive navigation headers
            var headers: [String: String] = [
                "X-DebugSwift-Source": "WKWebView",
                "X-DebugSwift-Type": "Navigation",
                "X-Navigation-Trigger": trigger,
                "User-Agent": userAgent
            ]
            
            // Add page information
            if !title.isEmpty {
                headers["X-Page-Title"] = title
            }
            
            if let referrer = data["referrer"] as? String, !referrer.isEmpty {
                headers["X-Referrer"] = referrer
            }
            
            if let readyState = data["readyState"] as? String {
                headers["X-Document-State"] = readyState
            }
            
            // Add viewport information
            if let viewport = data["viewport"] as? [String: Any] {
                if let width = viewport["width"] as? Int,
                   let height = viewport["height"] as? Int {
                    headers["X-Viewport-Size"] = "\(width)x\(height)"
                }
                if let devicePixelRatio = viewport["devicePixelRatio"] as? Double {
                    headers["X-Device-Pixel-Ratio"] = String(format: "%.2f", devicePixelRatio)
                }
            }
            
            // Add browser information
            if let language = data["language"] as? String {
                headers["X-Browser-Language"] = language
            }
            
            if let platform = data["platform"] as? String {
                headers["X-Platform"] = platform
            }
            
            // Add storage information
            if let storage = data["storage"] as? [String: Any] {
                if let localStorage = storage["localStorage"] as? [String: Any],
                   let localCount = localStorage["length"] as? Int {
                    headers["X-LocalStorage-Items"] = "\(localCount)"
                }
                
                if let sessionStorage = storage["sessionStorage"] as? [String: Any],
                   let sessionCount = sessionStorage["length"] as? Int {
                    headers["X-SessionStorage-Items"] = "\(sessionCount)"
                }
                
                if let cookies = storage["cookies"] as? [String: Any],
                   let cookieCount = cookies["count"] as? Int {
                    headers["X-Cookie-Count"] = "\(cookieCount)"
                }
            }
            
            // Add performance timing summary
            if let timing = data["timing"] as? [String: Any] {
                if let totalLoadTime = timing["totalLoadTime"] as? Double, totalLoadTime > 0 {
                    headers["X-Page-Load-Time"] = "\(Int(totalLoadTime))ms"
                }
                
                if let domContentLoaded = timing["domContentLoaded"] as? Double, domContentLoaded > 0 {
                    headers["X-DOM-Ready-Time"] = "\(Int(domContentLoaded))ms"
                }
            }
            
            // Add error information
            if let errors = data["errors"] as? [[String: Any]], !errors.isEmpty {
                headers["X-JavaScript-Errors"] = "\(errors.count)"
                if let lastError = errors.last?["message"] as? String {
                    headers["X-Last-JS-Error"] = String(lastError.prefix(100)) // Truncate for header
                }
            }
            
            model.responseHeaderFields = headers
            
            // Store detailed navigation data as response body for debugging
            if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) {
                model.responseData = jsonData
            }
            
            if HttpDatasource.shared.addHttpRequest(model) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("reloadHttp_DebugSwift"),
                    object: true
                )
            }
        }
    }
    
    private func formatNavigationTiming(_ timing: [String: Any]?) -> String {
        guard let timing = timing,
              let totalLoadTime = timing["totalLoadTime"] as? Double,
              totalLoadTime > 0 else {
            return "0.000 (s)"
        }
        
        return String(format: "%.3f (s)", totalLoadTime / 1000.0)
    }
    
    private func handleResponseReceived(_ data: [String: Any], webView: WKWebView?) {
        guard NetworkHelper.shared.isNetworkEnable else { return }
        
        let requestId = data["requestId"] as? String ?? ""
        let status = data["status"] as? Int ?? 0
        let duration = data["duration"] as? Double ?? 0
        
        // Get stored request info
        guard let requestInfo = WebViewRequestCache.shared.retrieve(requestId: requestId) else {
            print("⚠️ DebugSwift: No matching request found for WebView response")
            return
        }
        
        // Create HttpModel for DebugSwift integration
        createHttpModel(from: requestInfo, responseData: data, duration: duration)
        
        Debug.print("🌐 WebView Response: \(status) (\(String(format: "%.0f", duration))ms)")
        
        // Clean up
        WebViewRequestCache.shared.remove(requestId: requestId)
    }
    
    private func handleRequestError(_ data: [String: Any], webView: WKWebView?) {
        guard NetworkHelper.shared.isNetworkEnable else { return }
        
        let requestId = data["requestId"] as? String ?? ""
        let error = data["error"] as? String ?? "Unknown error"
        let duration = data["duration"] as? Double ?? 0
        
        // Get stored request info
        guard let requestInfo = WebViewRequestCache.shared.retrieve(requestId: requestId) else {
            print("⚠️ DebugSwift: No matching request found for WebView error")
            return
        }
        
        // Create HttpModel with error
        createHttpModel(from: requestInfo, responseData: data, duration: duration, error: error)
        
        Debug.print("🌐 WebView Error: \(error) (\(String(format: "%.0f", duration))ms)")
        
        // Clean up
        WebViewRequestCache.shared.remove(requestId: requestId)
    }
    
    private func createHttpModel(
        from requestInfo: [String: Any],
        responseData: [String: Any],
        duration: Double,
        error: String? = nil
    ) {
        let model = HttpModel()
        
        // Request data
        if let urlString = requestInfo["url"] as? String {
            model.url = URL(string: urlString)
        }
        model.method = requestInfo["method"] as? String
        model.requestHeaderFields = requestInfo["headers"] as? [String: String]
        
        if let bodyData = requestInfo["body"] as? String {
            model.requestData = bodyData.data(using: .utf8)
        }
        
        // Response data
        if let status = responseData["status"] as? Int {
            model.statusCode = "\(status)"
        }
        
        if let responseHeaders = responseData["headers"] as? [String: String] {
            model.responseHeaderFields = responseHeaders
        }
        
        // Timing
        if let startTime = requestInfo["startTime"] as? Date {
            let endTime = Date()
            model.startTime = startTime.formatted()
            model.endTime = endTime.formatted()
            model.totalDuration = String(format: "%.3f (s)", duration / 1000.0)
        }
        
        // Error handling
        if let error = error {
            model.errorDescription = error
            model.errorLocalizedDescription = error
        }
        
        // WebView-specific data
        model.requestId = requestInfo["requestId"] as? String ?? UUID().uuidString
        
        // Add special header to identify WebView requests
        if model.responseHeaderFields == nil {
            model.responseHeaderFields = [:]
        }
        model.responseHeaderFields?["X-DebugSwift-Source"] = "WKWebView"
        
        // Add to DebugSwift's HTTP datasource
        if HttpDatasource.shared.addHttpRequest(model) {
            NotificationCenter.default.post(
                name: NSNotification.Name("reloadHttp_DebugSwift"),
                object: model.isSuccess
            )
        }
    }
}

// MARK: - Request Cache

struct WebViewRequestInfo: Sendable {
    let requestId: String
    let url: String
    let method: String
    let startTime: Date
    let headers: [String: String]
    let body: String?
    
    init(from dictionary: [String: Any]) {
        self.requestId = dictionary["requestId"] as? String ?? ""
        self.url = dictionary["url"] as? String ?? ""
        self.method = dictionary["method"] as? String ?? "GET"
        self.startTime = dictionary["startTime"] as? Date ?? Date()
        self.headers = dictionary["headers"] as? [String: String] ?? [:]
        
        // Convert body to string if needed
        if let bodyData = dictionary["body"] {
            if let bodyString = bodyData as? String {
                self.body = bodyString
            } else if let bodyDict = bodyData as? [String: Any],
                      let data = try? JSONSerialization.data(withJSONObject: bodyDict),
                      let jsonString = String(data: data, encoding: .utf8) {
                self.body = jsonString
            } else {
                self.body = "\(bodyData)"
            }
        } else {
            self.body = nil
        }
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "requestId": requestId,
            "url": url,
            "method": method,
            "startTime": startTime,
            "headers": headers
        ]
        
        if let body = body {
            dict["body"] = body
        }
        
        return dict
    }
}

final class WebViewRequestCache: @unchecked Sendable {
    static let shared = WebViewRequestCache()
    
    private var cache: [String: WebViewRequestInfo] = [:]
    private let queue = DispatchQueue(label: "com.debugswift.webview.cache", attributes: .concurrent)
    
    private init() {}
    
    nonisolated func store(requestId: String, requestInfo: [String: Any]) {
        let sendableInfo = WebViewRequestInfo(from: requestInfo)
        queue.async(flags: .barrier) { [weak self] in
            self?.cache[requestId] = sendableInfo
        }
    }
    
    nonisolated func retrieve(requestId: String) -> [String: Any]? {
        return queue.sync { [weak self] in
            return self?.cache[requestId]?.toDictionary()
        }
    }
    
    nonisolated func remove(requestId: String) {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeValue(forKey: requestId)
        }
    }
}
