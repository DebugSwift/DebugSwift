//
//  HTTPProtocol.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

public final class CustomHTTPProtocol: URLProtocol, @unchecked Sendable {
    private static let requestProperty = "com.custom.http.protocol"

    public final class func clearCache() {
        URLCache.customHttp.removeAllCachedResponses()
    }

    public final class func start() {
        URLProtocol.registerClass(self)
    }

    public final class func stop() {
        URLProtocol.unregisterClass(self)
    }

    private final class func canServeRequest(_ request: URLRequest) -> Bool {
        if let _ = property(forKey: requestProperty, in: request) { return false }

        // Never intercept WebSocket requests - they should be handled by WebSocketMonitor
        if let scheme = request.url?.scheme?.lowercased() {
            if scheme == "ws" || scheme == "wss" {
                return false
            }
        }

        for onlyScheme in DebugSwift.Network.shared.onlySchemes {
            if let scheme = request.url?.scheme?.lowercased(), scheme == onlyScheme.rawValue {
                return true
            }
        }

        return false
    }

    public override final class func canInit(with request: URLRequest) -> Bool {
        canServeRequest(request)
    }

    public override final class func canInit(with task: URLSessionTask) -> Bool {
        guard let request = task.currentRequest else { return false }
        return canServeRequest(request)
    }

    public override final class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    private var session: URLSession?
    private var dataTask: URLSessionDataTask?
    private var cachePolicy: URLCache.StoragePolicy = .notAllowed
    private var data: Data = .init()
    private var didRetry = false
    private var didReceiveData = false
    private var startTime = Date()
    private var response: HTTPURLResponse?
    private var error: Error?
    private var prevUrl: URL?
    private var prevStartTime: Date?
    private var matchedRewriteRule: ResponseBodyRewriteRule?

    private var threadOperator: ThreadOperator?
    
    // Store reference to original delegate for forwarding
    private weak var originalDelegate: URLSessionDelegate?

    private func use(_ cache: CachedURLResponse) {
        DebugSwift.Network.shared.delegate?.urlSession(
            self,
            didReceive: cache.response
        )
        client?.urlProtocol(
            self,
            didReceive: cache.response,
            cacheStoragePolicy: .allowed
        )

        DebugSwift.Network.shared.delegate?.urlSession(
            self,
            didReceive: cache.data
        )
        client?.urlProtocol(
            self,
            didLoad: cache.data
        )

        DebugSwift.Network.shared.delegate?.didFinishLoading(self)
        client?.urlProtocolDidFinishLoading(self)
    }

    public override func startLoading() {
        guard let newRequest = (request as NSObject).mutableCopy() as? NSMutableURLRequest else {
            fatalError("Can not convert to NSMutableURLRequest")
        }

        URLProtocol.setProperty(true, forKey: CustomHTTPProtocol.requestProperty, in: newRequest)
        
        // Track request for threshold monitoring
        if let url = request.url {
            NetworkThresholdTracker.shared.trackRequest(url: url)
        }

        if let cache = URLCache.customHttp.validCache(for: request) {
            use(cache)

            Debug.execute {
                if let name = request.url?.lastPathComponent {
                    Debug.print("Use cache for \(name)")
                } else {
                    Debug.print("Use cache")
                }
            }

            return
        }

        Debug.print(request.requestId)
        
        // Apply delay injection first (synchronous)
        NetworkInjectionManager.shared.applyDelayIfNeeded(for: request)
        
        // Check for failure injection
        let (shouldInject, injectedError, statusCode) = NetworkInjectionManager.shared.shouldInjectFailure(for: request)
        
        if shouldInject {
            // Inject HTTP error with status code if specified
            if let statusCode = statusCode {
                injectHTTPError(statusCode: statusCode, for: request)
            } else if let error = injectedError {
                // Inject network error
                injectNetworkError(error)
            }
            return
        }
        
        // Resolve rewrite rule once per request (first-match-wins order)
        matchedRewriteRule = NetworkInjectionManager.shared.matchingRewriteRule(for: request)
        
        threadOperator = ThreadOperator()
        startTime = Date()
        prevUrl = request.url
        prevStartTime = startTime
        
        // Capture the most recent application delegate for forwarding authentication challenges
        originalDelegate = URLSessionDelegateRegistry.shared.getMostRecentDelegate()
        
        // Use preserved configuration if available, otherwise fall back to default
        let config = getPreservedConfigurationForRequest() ?? URLSessionConfiguration.default
        
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        dataTask = session?.dataTask(with: newRequest as URLRequest)
        dataTask?.resume()
    }
    
    private func injectHTTPError(statusCode: Int, for request: URLRequest) {
        guard let url = request.url else { return }
        
        // Create a mock HTTP response with error status code
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )
        
        // Create error response body
        let errorBody = """
        {
            "error": "Injected HTTP Error",
            "statusCode": \(statusCode),
            "message": "This is a simulated HTTP \(statusCode) error for testing purposes.",
            "injected": true
        }
        """.data(using: .utf8) ?? Data()
        
        // Notify client of response
        if let response = httpResponse {
            self.response = response
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: errorBody)
            
            self.data = errorBody
        }
        
        client?.urlProtocolDidFinishLoading(self)
        
        let method = request.httpMethod
        let capturedStartTime = startTime
        let requestId = request.requestId
        let cachePolicy = getCachePolicy(value: request.cachePolicy.rawValue)
        let requestHeaderFields = request.allHTTPHeaderFields

        // Process for DebugSwift tracking
        Task { @MainActor in
            let data = NetworkReportData(
                url: url,
                method: method,
                requestData: nil,
                responseData: errorBody,
                statusCode: "\(statusCode)",
                mineType: "application/json",
                startTime: capturedStartTime,
                endTime: Date(),
                error: nil,
                requestHeaderFields: requestHeaderFields,
                responseHeaderFields: ["Content-Type": "application/json"],
                requestId: requestId,
                cachePolicy: cachePolicy
            )
            Self.report(data)
        }
    }
    
    private func injectNetworkError(_ error: Error) {
        self.error = error
        client?.urlProtocol(self, didFailWithError: error)
        
        let url = request.url
        let method = request.httpMethod
        let capturedStartTime = startTime
        let requestId = request.requestId
        let cachePolicy = getCachePolicy(value: request.cachePolicy.rawValue)
        let requestHeaderFields = request.allHTTPHeaderFields
        let capturedError = error

        // Process for DebugSwift tracking
        Task { @MainActor in
            let data = NetworkReportData(
                url: url,
                method: method,
                requestData: nil,
                responseData: nil,
                statusCode: "0",
                mineType: nil,
                startTime: capturedStartTime,
                endTime: Date(),
                error: capturedError,
                requestHeaderFields: requestHeaderFields,
                responseHeaderFields: nil,
                requestId: requestId,
                cachePolicy: cachePolicy
            )
            Self.report(data)
        }
    }
    
    private func getPreservedConfigurationForRequest() -> URLSessionConfiguration? {
        // Check if we have stored TLS configuration settings
        guard UserDefaults.standard.bool(forKey: "DebugSwift.HasTLSConfig") else {
            return nil
        }
        
        // Create a configuration with preserved TLS settings
        let config = URLSessionConfiguration.default
        
        let minVersion = UserDefaults.standard.integer(forKey: "DebugSwift.TLSMinVersion")
        let maxVersion = UserDefaults.standard.integer(forKey: "DebugSwift.TLSMaxVersion")
        
        if minVersion > 0, let tlsMin = tls_protocol_version_t(rawValue: UInt16(minVersion)) {
            config.tlsMinimumSupportedProtocolVersion = tlsMin
        }
        if maxVersion > 0, let tlsMax = tls_protocol_version_t(rawValue: UInt16(maxVersion)) {
            config.tlsMaximumSupportedProtocolVersion = tlsMax
        }
        
        return config
    }

    public override func stopLoading() {
        dataTask?.cancel()

        if let task = dataTask {
            task.cancel()
            dataTask = nil
        }
        
        // Invalidate session to break retain cycle
        session?.invalidateAndCancel()
        session = nil

        let url = request.url
        let method = request.httpMethod
        let requestData = request.httpBody ?? request.httpBodyStream?.toData()
        let responseData = data
        let statusCode = response.map { "\($0.statusCode)" }
        let mineType = response?.mimeType
        let capturedStartTime = startTime
        let capturedError = error
        let requestHeaderFields = request.allHTTPHeaderFields
        let responseHeaderFields = headersToString(response?.allHeaderFields)
        let requestId = request.requestId
        let cachePolicy = getCachePolicy(value: request.cachePolicy.rawValue)

        Task { @MainActor in
            guard NetworkHelper.shared.isNetworkEnable else {
                return
            }
            
            let reportData = NetworkReportData(
                url: url,
                method: method,
                requestData: requestData,
                responseData: responseData,
                statusCode: statusCode,
                mineType: mineType,
                startTime: capturedStartTime,
                endTime: Date(),
                error: capturedError,
                requestHeaderFields: requestHeaderFields,
                responseHeaderFields: responseHeaderFields,
                requestId: requestId,
                cachePolicy: cachePolicy
            )
            Self.report(reportData)
        }
    }
    
    @MainActor
    private static func report(_ data: NetworkReportData) {
        var model = HttpModel()
        model.url = data.url
        model.method = data.method
        model.mineType = data.mineType

        model.requestData = data.requestData

        if let statusCode = data.statusCode {
            model.statusCode = statusCode
        }

        model.responseData = data.responseData
        model.size = data.responseData?.formattedSize()
        model.isImage = (data.mineType?.contains("image")) ?? false

        // Time
        let startTimeDouble = data.startTime.timeIntervalSince1970
        let endTimeDouble = data.endTime.timeIntervalSince1970
        let durationDouble = abs(endTimeDouble - startTimeDouble)
        let formattedDuration = String(format: "%.4f", durationDouble)

        model.startTime = "\(data.startTime.formatted())"
        model.endTime = "\(data.endTime.formatted())"
        model.totalDuration = "\(formattedDuration) (s)"

        model.errorDescription = data.error?.localizedDescription ?? ""
        model.errorLocalizedDescription = data.error?.localizedDescription ?? ""
        model.requestHeaderFields = data.requestHeaderFields

        model.responseHeaderFields = data.responseHeaderFields
        model.responseHeaderFields?.updateValue(data.cachePolicy, forKey: "Cache-Policy")

        if let responseDate = model.endTime {
            model.responseHeaderFields?.updateValue(responseDate, forKey: "Response-Date")
        }

        if data.mineType == nil {
            model.isImage = false
        }

        if let urlString = model.url?.absoluteString, urlString.count > 4 {
            let str = String(urlString.suffix(4))
            if ["png", "PNG", "jpg", "JPG", "gif", "GIF"].contains(str) {
                model.isImage = true
            }
        }

        if let urlString = model.url?.absoluteString, urlString.count > 5 {
            let str = String(urlString.suffix(5))
            if ["jpeg", "JPEG"].contains(str) {
                model.isImage = true
            }
        }

        model.requestId = data.requestId
        model = ErrorHelper.handle(data.error, model: model)
        if HttpDatasource.shared.addHttpRequest(model) {
            NotificationCenter.default.post(
                name: NSNotification.Name("reloadHttp_DebugSwift"),
                object: model.isSuccess
            )
        }
    }

    private func headersToString(_ headers: [AnyHashable: Any]?) -> [String: String]? {
        guard let headers = headers else { return nil }
        var result = [String: String]()
        for (key, value) in headers {
            result["\(key)"] = "\(value)"
        }
        return result
    }
}

extension CustomHTTPProtocol: URLSessionDataDelegate {
    public func urlSession(
        _: URLSession,
        task _: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        threadOperator?.execute { [weak self] in
            guard let self else { return }
            Debug.print(#function)

            self.client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
            self.response = response
            completionHandler(request)
        }
    }

    public func urlSession(
        _: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        threadOperator?.execute { [weak self] in
            guard let self else { return }
            Debug.print(#function)

            if let response = response as? HTTPURLResponse, let request = dataTask.originalRequest {
                self.cachePolicy = CacheHelper.cacheStoragePolicy(for: request, and: response)
            }

            var interceptedResponse = response
            if let httpResponse = response as? HTTPURLResponse, let matchedRewriteRule = self.matchedRewriteRule {
                interceptedResponse = self.rewriteResponse(
                    from: httpResponse,
                    using: matchedRewriteRule
                ) ?? response
            }
            
            DebugSwift.Network.shared.delegate?.urlSession(
                self,
                didReceive: interceptedResponse
            )
            self.client?.urlProtocol(self, didReceive: interceptedResponse, cacheStoragePolicy: self.cachePolicy)
            self.response = interceptedResponse as? HTTPURLResponse
            completionHandler(.allow)
        }
    }

    public func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive data: Data) {
        threadOperator?.execute { [weak self] in
            guard let self else { return }
            Debug.print(#function)
            
            if self.matchedRewriteRule != nil {
                if self.cachePolicy == .allowed {
                    self.data.append(data)
                } else if self.data.isEmpty {
                    self.data = data
                } else {
                    self.data.append(data)
                }
                
                self.didReceiveData = true
                return
            }

            var hasAddedData = false
            if self.cachePolicy == .allowed {
                self.data.append(data)
                hasAddedData = true
            }

            DebugSwift.Network.shared.delegate?.urlSession(
                self,
                didReceive: data
            )
            self.client?.urlProtocol(self, didLoad: data)
            self.didReceiveData = true
            if prevUrl == response?.url, prevStartTime == startTime {
                if !hasAddedData { self.data.append(data) }
            } else {
                self.data = data
            }
        }
    }

    private func canRetry(error: NSError) -> Bool {
        guard error.code == Int(CFNetworkErrors.cfurlErrorNetworkConnectionLost.rawValue),
              !didRetry,
              !didReceiveData
        else {
            return false
        }

        Debug.print("Retry download...")
        return true
    }

    private func getCachePolicy(value: UInt?) -> String {
        switch value {
        case 0:
            return "useProtocolCachePolicy"
        case 1:
            return "reloadIgnoringLocalCacheData"
        case 4:
            return "reloadIgnoringLocalAndRemoteCacheData"
        case 3:
            return "returnCacheDataDontLoad"
        case 2:
            return "returnCacheDataElseLoad"
        case 5:
            return "reloadRevalidatingCacheData"
        default:
            return "reloadIgnoringCacheData"
        }
    }
    
    private func rewriteResponse(
        from response: HTTPURLResponse,
        using rule: ResponseBodyRewriteRule
    ) -> HTTPURLResponse? {
        guard let responseURL = response.url ?? request.url else { return nil }
        
        var headers = [String: String]()
        response.allHeaderFields.forEach { key, value in
            headers["\(key)"] = "\(value)"
        }
        
        headers = headers.filter { headerKey, _ in
            headerKey.caseInsensitiveCompare("Content-Length") != .orderedSame
        }
        
        return HTTPURLResponse(
            url: responseURL,
            statusCode: rule.responseStatusCode ?? response.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        threadOperator?.execute { [weak self] in
            guard let self else { return }
            if let error {
                self.error = error
                if self.canRetry(error: error as NSError), let request = task.originalRequest {
                    self.didRetry = true
                    self.dataTask = session.dataTask(with: request)
                    self.dataTask?.resume()
                    return
                }
                DebugSwift.Network.shared.delegate?.urlSession(
                    self,
                    didFailWithError: error
                )
                self.client?.urlProtocol(self, didFailWithError: error)
                
                // Invalidate session to break retain cycle
                self.session?.finishTasksAndInvalidate()
                self.session = nil
                return
            }
            
            if let matchedRewriteRule = self.matchedRewriteRule {
                let rewrittenData = matchedRewriteRule.responseBody.data(using: .utf8) ?? Data()
                self.data = rewrittenData
                
                DebugSwift.Network.shared.delegate?.urlSession(
                    self,
                    didReceive: rewrittenData
                )
                self.client?.urlProtocol(self, didLoad: rewrittenData)
            }

            DebugSwift.Network.shared.delegate?.didFinishLoading(self)
            self.client?.urlProtocolDidFinishLoading(self)

            if self.cachePolicy == .allowed {
                URLCache.customHttp.storeIfNeeded(for: task, data: self.data)
            }
            
            // Invalidate session to break retain cycle
            self.session?.finishTasksAndInvalidate()
            self.session = nil
        }
    }
}

extension CustomHTTPProtocol: URLSessionTaskDelegate {
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        threadOperator?.execute { [weak self] in
            guard let self else { return }
            Debug.print(#function)

            DebugSwift.Network.shared.delegate?.urlSession(
                self,
                session,
                task: task,
                didSendBodyData: bytesSent,
                totalBytesSent: totalBytesSent,
                totalBytesExpectedToSend: totalBytesExpectedToSend
            )
        }
    }
    
    // MARK: - Authentication Challenge Forwarding (Fix for issue #240)
    
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        threadOperator?.execute { [weak self] in
            guard let self else {
                completionHandler(.performDefaultHandling, nil)
                return
            }
            
            Debug.print(#function)
            
            // Forward to original delegate if available and implements the method
            if let originalDelegate = self.originalDelegate,
               originalDelegate.responds(to: #selector(URLSessionDelegate.urlSession(_:didReceive:completionHandler:))) {
                originalDelegate.urlSession?(session, didReceive: challenge, completionHandler: completionHandler)
            } else {
                // Default handling if no original delegate
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        threadOperator?.execute { [weak self] in
            guard let self else {
                completionHandler(.performDefaultHandling, nil)
                return
            }
            
            Debug.print(#function)
            
            // Forward to original delegate if available and implements the method
            if let originalDelegate = self.originalDelegate as? URLSessionTaskDelegate,
               originalDelegate.responds(to: #selector(URLSessionTaskDelegate.urlSession(_:task:didReceive:completionHandler:))) {
                originalDelegate.urlSession?(session, task: task, didReceive: challenge, completionHandler: completionHandler)
            } else {
                // Fallback to session-level challenge if task-level not implemented
                self.urlSession(session, didReceive: challenge, completionHandler: completionHandler)
            }
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willBeginDelayedRequest request: URLRequest,
        completionHandler: @escaping @Sendable (URLSession.DelayedRequestDisposition, URLRequest?) -> Void
    ) {
        threadOperator?.execute { [weak self] in
            guard let self else {
                completionHandler(.continueLoading, nil)
                return
            }
            
            Debug.print(#function)
            
            // Forward to original delegate if available and implements the method
            if let originalDelegate = self.originalDelegate as? URLSessionTaskDelegate,
               originalDelegate.responds(to: #selector(URLSessionTaskDelegate.urlSession(_:task:willBeginDelayedRequest:completionHandler:))) {
                originalDelegate.urlSession?(session, task: task, willBeginDelayedRequest: request, completionHandler: completionHandler)
            } else {
                completionHandler(.continueLoading, nil)
            }
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        taskIsWaitingForConnectivity task: URLSessionTask
    ) {
        threadOperator?.execute { [weak self] in
            guard let self else { return }
            
            Debug.print(#function)
            
            // Forward to original delegate if available and implements the method
            if let originalDelegate = self.originalDelegate as? URLSessionTaskDelegate,
               originalDelegate.responds(to: #selector(URLSessionTaskDelegate.urlSession(_:taskIsWaitingForConnectivity:))) {
                originalDelegate.urlSession?(session, taskIsWaitingForConnectivity: task)
            }
        }
    }
}

// MARK: - Network Reporting Data

struct NetworkReportData: Sendable {
    let url: URL?
    let method: String?
    let requestData: Data?
    let responseData: Data?
    let statusCode: String?
    let mineType: String?
    let startTime: Date
    let endTime: Date
    let error: Error?
    let requestHeaderFields: [String: String]?
    let responseHeaderFields: [String: String]?
    let requestId: String
    let cachePolicy: String

    init(
        url: URL?,
        method: String?,
        requestData: Data?,
        responseData: Data?,
        statusCode: String?,
        mineType: String?,
        startTime: Date,
        endTime: Date,
        error: Error?,
        requestHeaderFields: [String: String]?,
        responseHeaderFields: [String: String]?,
        requestId: String,
        cachePolicy: String
    ) {
        self.url = url
        self.method = method
        self.requestData = requestData
        self.responseData = responseData
        self.statusCode = statusCode
        self.mineType = mineType
        self.startTime = startTime
        self.endTime = endTime
        self.error = error
        self.requestHeaderFields = requestHeaderFields
        self.responseHeaderFields = responseHeaderFields
        self.requestId = requestId
        self.cachePolicy = cachePolicy
    }
}
