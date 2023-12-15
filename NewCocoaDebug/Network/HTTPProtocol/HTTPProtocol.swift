//
//  CustomHTTPProtocol.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

final class CustomHTTPProtocol: URLProtocol {
    private static let requestProperty = "com.custom.http.protocol"
    static var classDelegate: CustomHTTPProtocolDelegate?

    class func clearCache() {
        URLCache.customHttp.removeAllCachedResponses()
    }

    class func start() {
        URLProtocol.registerClass(self)
    }

    class func stop() {
        URLProtocol.unregisterClass(self)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        if let _ = property(forKey: requestProperty, in: request) { return false }

        if let scheme = request.url?.scheme?.lowercased(), (scheme == "http" || scheme == "https") {
            return true
        }

        return false
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return RequestHelper.canonicalRequest(for: request)
    }

    private var delegate: CustomHTTPProtocolDelegate? { return CustomHTTPProtocol.classDelegate }

    private var session: URLSession?
    private var dataTask: URLSessionDataTask?
    private var cachePolicy: URLCache.StoragePolicy = .notAllowed
    private var data: Data = Data()
    private var didRetry: Bool = false
    private var didReceiveData: Bool = false
    private var startTime = Date()
    private var response: HTTPURLResponse?
    private var error: Error?

    private var threadOperator: ThreadOperator?

    private func use(_ cache: CachedURLResponse) {
        delegate?.customHTTPProtocol(self, didReceive: cache.response)
        client?.urlProtocol(self, didReceive: cache.response, cacheStoragePolicy: .allowed)

        delegate?.customHTTPProtocol(self, didReceive: cache.data)
        client?.urlProtocol(self, didLoad: cache.data)

        delegate?.customHTTPProtocolDidFinishLoading(self)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func startLoading() {
        guard let newRequest = (request as NSObject).mutableCopy() as? NSMutableURLRequest else {
            fatalError("Can not convert to NSMutableURLRequest")
        }

        URLProtocol.setProperty(true, forKey: CustomHTTPProtocol.requestProperty, in: newRequest)

        if let cache = URLCache.customHttp.validCache(for: request) {
            use(cache)

            Debug.execute(level: .full) {
                if let name = request.url?.lastPathComponent {
                    print("Use cache for", name)
                } else {
                    print("Use cache")
                }
            }

            return
        }

        print(request.requestId)
        threadOperator = ThreadOperator()
        startTime = Date()
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        dataTask = session?.dataTask(with: newRequest as URLRequest)
        dataTask?.resume()
    }

    override func stopLoading() {

        dataTask?.cancel()

        if let task = self.dataTask {
            task.cancel()
            self.dataTask = nil
        }

        guard NetworkHelper.shared.isNetworkEnable else {
            return
        }

        var model = HttpModel()
        model.url = request.url
        model.method = request.httpMethod
        model.mineType = response?.mimeType

        if let requestBody = request.httpBody {
            model.requestData = requestBody
        }

        if let requestBodyStream = request.httpBodyStream {
            model.requestData = requestBodyStream.toData()
        }

        if let httpResponse = response {
            model.statusCode = "\(httpResponse.statusCode)"
        }

        model.responseData = data
        model.size = data.formattedSize()
        model.isImage = (response?.mimeType?.contains("image")) ?? false

        // Time
        let startTimeDouble = startTime.timeIntervalSince1970
        let endTimeDouble = Date().timeIntervalSince1970
        let durationDouble = abs(endTimeDouble - startTimeDouble)
        let formattedDuration = String(format: "%.4f", durationDouble)

        model.startTime = "\(startTime.formatted())"
        model.endTime = "\(Date().formatted())"
        model.totalDuration = "\(formattedDuration) (s)"

        model.errorDescription = error?.localizedDescription ?? ""
        model.errorLocalizedDescription = error?.localizedDescription ?? ""
        model.requestHeaderFields = request.allHTTPHeaderFields

        if let response {
            model.responseHeaderFields = response.allHeaderFields.convertKeysToString()
        }

        if self.response?.mimeType == nil {
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

        model.requestId = request.requestId
        model = ErrorHelper.handle(error, model: model)
        if HttpDatasource.shared.addHttpRequest(model) {
            let statusCode = model.statusCode ?? "Unknown"

            NotificationCenter.default.post(
                name: NSNotification.Name("reloadHttp_CocoaDebug"),
                object: nil,
                userInfo: ["statusCode": statusCode]
            )
        }
    }
}

extension CustomHTTPProtocol: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        threadOperator?.execute { [weak self] in
            guard let self else { return }
            Debug.print("willPerformHTTPRedirection", level: .full)
            self.client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
            self.response = response
            completionHandler(request)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        threadOperator?.execute { [weak self] in
            guard let self else { return }
            Debug.print("didReceive response", level: .full)

            if let response = response as? HTTPURLResponse, let request = dataTask.originalRequest {
                self.cachePolicy = CacheHelper.cacheStoragePolicy(for: request, and: response)
            }

            self.delegate?.customHTTPProtocol(self, didReceive: response)
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: self.cachePolicy)
            self.response = response as? HTTPURLResponse
            completionHandler(.allow)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        threadOperator?.execute { [weak self] in
            guard let self else { return }
            Debug.print("didReceive data", level: .full)
            if self.cachePolicy == .allowed {
                self.data.append(data)
            }

            self.delegate?.customHTTPProtocol(self, didReceive: data)
            self.client?.urlProtocol(self, didLoad: data)
            self.didReceiveData = true
            self.data = data
        }
    }

    private func canRetry(error: NSError) -> Bool {
        guard error.code == Int(CFNetworkErrors.cfurlErrorNetworkConnectionLost.rawValue),
              !didRetry,
              !didReceiveData else {
            return false
        }

        print("Retry download...")
        return true
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
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

                Debug.print("didCompleteWithError ERROR", level: .full)
                self.delegate?.customHTTPProtocol(self, didFailWithError: error)
                self.client?.urlProtocol(self, didFailWithError: error)
                return
            }

            Debug.print("didCompleteWithError SUCCESS", level: .full)

            self.delegate?.customHTTPProtocolDidFinishLoading(self)
            self.client?.urlProtocolDidFinishLoading(self)

            if self.cachePolicy == .allowed {
                URLCache.customHttp.storeIfNeeded(for: task, data: self.data)
            }
        }
    }
}
