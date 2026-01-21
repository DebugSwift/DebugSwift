//
//  ApolloInterceptor.swift
//  DebugSwift
//
//  Created for Apollo iOS Integration
//

#if canImport(Apollo)
import Foundation
import Apollo

/// Apollo iOS interceptor that logs GraphQL requests and responses to DebugSwift
///
/// Usage:
/// ```swift
/// let store = ApolloStore()
/// let interceptorProvider = DefaultInterceptorProvider(store: store)
/// let transport = RequestChainNetworkTransport(
///     interceptorProvider: DebugSwiftApolloInterceptorProvider(
///         interceptorProvider: interceptorProvider,
///         store: store
///     ),
///     endpointURL: URL(string: "https://api.example.com/graphql")!
/// )
/// let client = ApolloClient(networkTransport: transport, store: store)
/// ```
@available(iOS 14.0, *)
public final class DebugSwiftApolloInterceptor: ApolloInterceptor, @unchecked Sendable {
    
    public var id: String = UUID().uuidString
    
    private let startTimeKey = "DebugSwift.Apollo.StartTime"
    private let requestIdKey = "DebugSwift.Apollo.RequestId"
    
    public init() {}
    
    public func interceptAsync<Operation: GraphQLOperation>(
        chain: RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) {
        // Store start time for this request
        let startTime = Date()
        let requestId = UUID().uuidString
        
        // Store timing info in request context
        request.additionalHeaders[startTimeKey] = "\(startTime.timeIntervalSince1970)"
        request.additionalHeaders[requestIdKey] = requestId
        
        // Log request
        Task { @MainActor in
            await self.logRequest(request, startTime: startTime, requestId: requestId)
        }
        
        chain.proceedAsync(
            request: request,
            response: response,
            interceptor: self
        ) { result in
            // Log response
            Task { @MainActor in
                await self.logResponse(
                    request: request,
                    result: result,
                    startTime: startTime,
                    requestId: requestId
                )
            }
            
            completion(result)
        }
    }
    
    @MainActor
    private func logRequest<Operation: GraphQLOperation>(
        _ request: HTTPRequest<Operation>,
        startTime: Date,
        requestId: String
    ) async {
        guard await NetworkHelper.shared.isNetworkEnable else { return }
        
        // Request will be fully logged when response arrives
        // This is just to track timing
    }
    
    @MainActor
    private func logResponse<Operation: GraphQLOperation>(
        request: HTTPRequest<Operation>,
        result: Result<GraphQLResult<Operation.Data>, Error>,
        startTime: Date,
        requestId: String
    ) async {
        guard await NetworkHelper.shared.isNetworkEnable else { return }
        
        var model = HttpModel()
        
        // URL and method
        model.url = request.toURLRequest()?.url
        model.method = "POST" // GraphQL is typically POST
        model.requestId = requestId
        
        // Request data (GraphQL query/mutation)
        if let urlRequest = request.toURLRequest() {
            model.requestData = urlRequest.httpBody
            model.requestHeaderFields = urlRequest.allHTTPHeaderFields
        }
        
        // Time calculation
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        let formattedDuration = String(format: "%.4f", duration)
        
        model.startTime = "\(startTime.formatted())"
        model.endTime = "\(endTime.formatted())"
        model.totalDuration = "\(formattedDuration) (s)"
        
        // Process result
        switch result {
        case .success(let graphQLResult):
            model.statusCode = "200"
            model.mineType = "application/json"
            
            // Convert GraphQL response to JSON
            if let jsonData = try? JSONEncoder().encode(graphQLResult) {
                model.responseData = jsonData
                model.size = jsonData.formattedSize()
            }
            
            // Check for GraphQL errors
            if let errors = graphQLResult.errors, !errors.isEmpty {
                let errorMessages = errors.map { $0.localizedDescription }.joined(separator: "\n")
                model.errorDescription = "GraphQL Errors: \(errorMessages)"
                model.errorLocalizedDescription = errorMessages
            }
            
        case .failure(let error):
            model.statusCode = "0"
            model.errorDescription = error.localizedDescription
            model.errorLocalizedDescription = error.localizedDescription
            
            // Try to extract HTTP status code from error
            if let nsError = error as NSError? {
                if let statusCode = nsError.userInfo["StatusCode"] as? Int {
                    model.statusCode = "\(statusCode)"
                }
            }
        }
        
        // Add to DebugSwift
        if HttpDatasource.shared.addHttpRequest(model) {
            NotificationCenter.default.post(
                name: NSNotification.Name("reloadHttp_DebugSwift"),
                object: model.isSuccess
            )
        }
    }
}

/// Interceptor provider that wraps an existing provider and adds DebugSwift logging
@available(iOS 14.0, *)
public final class DebugSwiftApolloInterceptorProvider: InterceptorProvider {
    
    private let baseProvider: InterceptorProvider
    
    public init(interceptorProvider: InterceptorProvider) {
        self.baseProvider = interceptorProvider
    }
    
    public func interceptors<Operation: GraphQLOperation>(
        for operation: Operation
    ) -> [ApolloInterceptor] {
        var interceptors = baseProvider.interceptors(for: operation)
        
        // Insert DebugSwift interceptor at the beginning to capture everything
        interceptors.insert(DebugSwiftApolloInterceptor(), at: 0)
        
        return interceptors
    }
}

// MARK: - Helper Extensions

extension HTTPRequest {
    func toURLRequest() -> URLRequest? {
        guard let url = graphQLEndpoint else { return nil }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        
        // Add headers
        for (key, value) in additionalHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add body
        if let bodyData = try? JSONSerialization.data(withJSONObject: body) {
            urlRequest.httpBody = bodyData
        }
        
        return urlRequest
    }
}

extension GraphQLResult: Encodable where Data: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(errors?.map { $0.description }, forKey: .errors)
        try container.encodeIfPresent(extensions, forKey: .extensions)
    }
    
    enum CodingKeys: String, CodingKey {
        case data
        case errors
        case extensions
    }
}

#endif


