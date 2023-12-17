//
//  NetworkDetailModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

struct NetworkDetailModel {
    var title: String?
    var content: String?
    var url: String?
    var image: UIImage?
    var blankContent: String?
    var isLast = false
    var requestSerializer: RequestSerializer = .JSON // default JSON format
    var requestHeaderFields: [String: Any]?
    var responseHeaderFields: [String: Any]?
    var requestData: Data?
    var responseData: Data?
    var httpModel: HttpModel?

    init(
        title: String? = nil,
        content: String? = "",
        url: String? = "",
        image: UIImage? = nil,
        httpModel: HttpModel? = nil
    ) {
        self.title = title?.replacingOccurrences(of: "\\/", with: "/")
        self.content = content?.replacingOccurrences(of: "\\/", with: "/")
        self.url = url?.replacingOccurrences(of: "\\/", with: "/")
        self.image = image
        self.httpModel = httpModel
    }
}
