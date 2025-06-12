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

    func applyFilter() {
        cacheModels = HttpDatasource.shared.httpModels
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
    
    func applyAdvancedFilter(_ filter: HTTPRequestFilter) {
        currentAdvancedFilter = filter
        applyFilter()
    }

    func handleClearAction() {
        HttpDatasource.shared.removeAll()
        models.removeAll()
    }
}
