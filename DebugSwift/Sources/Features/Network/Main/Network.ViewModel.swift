//
//  Network.ViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

final class NetworkViewModel {
    var reachEnd = true
    var firstIn = true
    var reloadDataFinish = true

    var models = HttpDatasource.shared.httpModels
    var cacheModels = [HttpModel]()
    var searchModels = [HttpModel]()
    var filteredModels = [HttpModel]()

    var networkSearchWord = ""
    var currentAdvancedFilter: HTTPRequestFilter?
    
    // Separate data arrays for different modes
    var httpModels: [HttpModel] { 
        HttpDatasource.shared.httpModels.filter { !isWebViewRequest($0) }
    }
    
    var webViewModels: [HttpModel] {
        HttpDatasource.shared.httpModels.filter { isWebViewRequest($0) }
    }

    func applyFilter(for mode: NetworkInspectorMode = .http) {
        // Select the appropriate data source based on mode
        switch mode {
        case .http:
            cacheModels = httpModels
        case .webview:
            cacheModels = webViewModels
        case .websocket:
            cacheModels = [] // WebSocket uses different data structure
        }
        
        searchModels = cacheModels

        if networkSearchWord.isEmpty {
            models = cacheModels
        } else {
            searchModels = searchModels.filter {
                $0.url?.absoluteString.lowercased().contains(networkSearchWord.lowercased()) == true ||
                    $0.statusCode?.lowercased().contains(networkSearchWord.lowercased()) == true ||
                    $0.endTime?.lowercased().contains(networkSearchWord.lowercased()) == true
            }

            models = searchModels
        }
        
        // Apply advanced filter if set
        if let advancedFilter = currentAdvancedFilter, advancedFilter.isActive {
            models = models.filter { advancedFilter.matches($0) }
        }
    }
    
    func applyAdvancedFilter(_ filter: HTTPRequestFilter, for mode: NetworkInspectorMode = .http) {
        currentAdvancedFilter = filter
        applyFilter(for: mode)
    }
    
    func handleClearAction(for mode: NetworkInspectorMode = .http) {
        switch mode {
        case .http:
            // Remove only HTTP requests (non-WebView)
            let webViewRequests = webViewModels
            HttpDatasource.shared.removeAll()
            // Re-add WebView requests
            webViewRequests.forEach { _ = HttpDatasource.shared.addHttpRequest($0) }
        case .webview:
            // Remove only WebView requests
            let httpRequests = httpModels
            HttpDatasource.shared.removeAll()
            // Re-add HTTP requests
            httpRequests.forEach { _ = HttpDatasource.shared.addHttpRequest($0) }
        case .websocket:
            // WebSocket clearing handled elsewhere
            break
        }
        models.removeAll()
    }
    
    // Helper method to identify WebView requests
    private func isWebViewRequest(_ model: HttpModel) -> Bool {
        return model.responseHeaderFields?["X-DebugSwift-Source"] as? String == "WKWebView"
    }
}
