//
//  HTTPProtocolDelegate.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

public protocol CustomHTTPProtocolDelegate: AnyObject {
    func urlSession(
        _ protocol: URLProtocol,
        didReceive response: URLResponse
    )

    func urlSession(
        _ protocol: URLProtocol,
        didReceive data: Data
    )

    func didFinishLoading(
        _ protocol: URLProtocol
    )

    func urlSession(
        _ protocol: URLProtocol,
        didFailWithError error: Error
    )

    func urlSession(
        _ protocol: URLProtocol,
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    )
}

public extension CustomHTTPProtocolDelegate {
    func urlSession(
        _ protocol: URLProtocol,
        didReceive response: URLResponse
    ) {}
    func urlSession(
        _ protocol: URLProtocol,
        didReceive data: Data
    ) {}
    func didFinishLoading(
        _ protocol: URLProtocol
    ) {}
    func urlSession(
        _ protocol: URLProtocol,
        didFailWithError error: Error
    ) {}
    func urlSession(
        _ protocol: URLProtocol,
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {}
}

public enum CustomHTTPProtocolURLScheme: String, CaseIterable {
    case http
    case https
    case ftp
    case mailto
    case file
    case data
    case tel
    case sms
    case ws
    case wss
}