//
//  Network.Model.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

struct NetworkCellModel {
    let method: String
    let number: String
    let statusCode: String
    let description: String
    let timestamp: String
    let isSuccess: Bool
    let log: NetworkLogModel
}

struct NetworkLogModel {
    let requestHeader: String
    let requestBody: String
    let responseHeader: String
    let responseBody: String
    let responseSize: String
    let totalTime: String
    let mimeType: String
}
