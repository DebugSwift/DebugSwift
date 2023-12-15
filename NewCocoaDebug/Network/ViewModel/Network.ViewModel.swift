//
//  Network.ViewModel.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

class NetworkViewModel {
//    var models = [NetworkCellModel]()

    var reachEnd: Bool = true
    var firstIn: Bool = true
    var reloadDataFinish: Bool = true

    var models = [HttpModel]()
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
}
