//
//  HTTP.Model.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

public enum RequestSerializer: UInt {
    case json = 0
    case form
}

public final class HttpModel: NSObject {
    public var url: URL?
    public var requestData: Data?
    public var responseData: Data?
    public var decryptedResponseData: Data?
    public var requestId: String?
    public var method: String?
    public var statusCode: String?
    public var mineType: String?
    public var startTime: String?
    public var endTime: String?
    public var totalDuration: String?
    public var isImage = false
    public var isEncrypted = false

    public var requestHeaderFields: [String: Any]?
    public var responseHeaderFields: [String: Any]?
    public var isTag = false
    public var isSelected = false
    public var requestSerializer: RequestSerializer = .json
    public var errorDescription: String?
    public var errorLocalizedDescription: String?
    public var size: String?
    public var index: Int = .zero
    public var id: String { String(index) }

    public override init() {
        super.init()
        self.statusCode = "0"
        self.url = URL(string: "")
    }

    public var isSuccess: Bool {
        errorDescription == nil || errorDescription?.isEmpty == true
    }
}
