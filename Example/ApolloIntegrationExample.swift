//
//  ApolloIntegrationExample.swift
//  DebugSwift
//
//  Example demonstrating Apollo iOS integration with DebugSwift
//

#if canImport(Apollo)
import Foundation
import Apollo
import DebugSwift

/// Example showing how to set up Apollo iOS with DebugSwift logging
final class ApolloIntegrationExample {
    
    // MARK: - Basic Setup
    
    /// Creates an Apollo client with DebugSwift interceptor
    static func createBasicClient() -> ApolloClient {
        let store = ApolloStore()
        let baseProvider = DefaultInterceptorProvider(store: store)
        
        // Wrap with DebugSwift interceptor
        let debugProvider = DebugSwiftApolloInterceptorProvider(
            interceptorProvider: baseProvider
        )
        
        let transport = RequestChainNetworkTransport(
            interceptorProvider: debugProvider,
            endpointURL: URL(string: "https://countries.trevorblades.com/")!
        )
        
        return ApolloClient(networkTransport: transport, store: store)
    }
    
    // MARK: - With Authentication
    
    /// Creates an Apollo client with both authentication and DebugSwift logging
    static func createAuthenticatedClient(token: String) -> ApolloClient {
        let store = ApolloStore()
        
        // Create custom provider with auth
        let authProvider = AuthInterceptorProvider(
            authToken: token,
            store: store
        )
        
        let transport = RequestChainNetworkTransport(
            interceptorProvider: authProvider,
            endpointURL: URL(string: "https://api.example.com/graphql")!
        )
        
        return ApolloClient(networkTransport: transport, store: store)
    }
    
    // MARK: - Usage Examples
    
    static func exampleQuery() {
        let client = createBasicClient()
        
        // Example query - will be automatically logged to DebugSwift
        // client.fetch(query: YourQuery()) { result in
        //     switch result {
        //     case .success(let graphQLResult):
        //         print("Success: \(graphQLResult.data)")
        //     case .failure(let error):
        //         print("Error: \(error)")
        //     }
        // }
    }
}

// MARK: - Custom Interceptor Provider with Auth

final class AuthInterceptorProvider: DefaultInterceptorProvider {
    
    private let authToken: String
    
    init(authToken: String, store: ApolloStore) {
        self.authToken = authToken
        super.init(store: store)
    }
    
    override func interceptors<Operation: GraphQLOperation>(
        for operation: Operation
    ) -> [ApolloInterceptor] {
        var interceptors = super.interceptors(for: operation)
        
        // IMPORTANT: Add DebugSwift interceptor FIRST to capture all requests
        interceptors.insert(DebugSwiftApolloInterceptor(), at: 0)
        
        // Then add auth interceptor
        interceptors.insert(AuthInterceptor(authToken: authToken), at: 1)
        
        return interceptors
    }
}

final class AuthInterceptor: ApolloInterceptor {
    
    let id: String = UUID().uuidString
    private let authToken: String
    
    init(authToken: String) {
        self.authToken = authToken
    }
    
    func interceptAsync<Operation: GraphQLOperation>(
        chain: RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) {
        // Add auth header
        request.addHeader(name: "Authorization", value: "Bearer \(authToken)")
        
        // Continue chain
        chain.proceedAsync(
            request: request,
            response: response,
            interceptor: self,
            completion: completion
        )
    }
}

// MARK: - Usage in AppDelegate or SceneDelegate

extension ApolloIntegrationExample {
    
    /// Example of setting up Apollo with DebugSwift in your app
    static func setupInApp() {
        #if DEBUG
        // 1. Setup DebugSwift first
        let debugSwift = DebugSwift()
        debugSwift.setup()
        debugSwift.show()
        
        // 2. Create Apollo client with DebugSwift interceptor
        let apolloClient = createBasicClient()
        
        // 3. Use apolloClient for your GraphQL queries
        // All requests will now appear in DebugSwift's Network tab!
        #endif
    }
}

// MARK: - Manual Logging Example

extension ApolloIntegrationExample {
    
    /// Example of manually logging Apollo requests (if you need custom control)
    static func manualLoggingExample() {
        let startTime = Date()
        let requestUrl = URL(string: "https://api.example.com/graphql")!
        
        // Your Apollo request execution here...
        
        // Then manually log to DebugSwift
        Task { @MainActor in
            DebugSwift.Network.shared.logRequest(
                url: requestUrl,
                method: "POST",
                requestData: Data(), // Your GraphQL query data
                requestHeaders: ["Content-Type": "application/json"],
                responseData: Data(), // Response data
                statusCode: 200,
                responseHeaders: ["Content-Type": "application/json"],
                mimeType: "application/json",
                startTime: startTime,
                endTime: Date(),
                error: nil
            )
        }
    }
}

#endif


