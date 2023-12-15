//
//  HttpModel.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

enum RequestSerializer: UInt {
    case JSON = 0
    case form
}

class HttpModel: NSObject {
    var url: URL?
    var requestData: Data?
    var responseData: Data?
    var requestId: String?
    var method: String?
    var statusCode: String?
    var mineType: String?
    var startTime: String?
    var endTime: String?
    var totalDuration: String?
    var isImage: Bool = false

    var requestHeaderFields: [String: Any]?
    var responseHeaderFields: [String: Any]?
    var isTag: Bool = false
    var isSelected: Bool = false
    var requestSerializer: RequestSerializer = .JSON
    var errorDescription: String?
    var errorLocalizedDescription: String?
    var size: String?
    var index: Int = .zero
    var id: String { String(index) }

    // Default initializer with default property values
    override init() {
        super.init()
        self.statusCode = "0"
        self.url = URL(string: "")
    }

    var isSuccess: Bool {
        errorDescription == nil || errorDescription?.isEmpty == true
    }
}
