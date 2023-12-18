//
//  Network.ViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

class NetworkViewModel {
    //    var models = [NetworkCellModel]()

    var reachEnd = true
    var firstIn = true
    var reloadDataFinish = true

    var models = HttpDatasource.shared.httpModels
    var cacheModels = [HttpModel]()
    var searchModels = [HttpModel]()

    var networkSearchWord = ""

    func applyFilter() {
        cacheModels = HttpDatasource.shared.httpModels
        searchModels = cacheModels

        if networkSearchWord.isEmpty {
            models = cacheModels
        } else {
            searchModels = searchModels.filter {
                $0.url?.absoluteString.lowercased().contains(networkSearchWord.lowercased()) == true
            }

            models = searchModels
        }
    }

    func handleClearAction() {
        HttpDatasource.shared.removeAll()
        models.removeAll()
    }
}
