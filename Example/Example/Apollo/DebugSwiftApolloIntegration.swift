//
//  DebugSwiftApolloIntegration.swift
//  Example
//
//  Apollo Client integration with DebugSwift
//  Solution for issue #231 - Apollo Client HTTP Requests & Response logging
//
//  The key insight: Apollo's URLSession will automatically use the CustomHTTPProtocol
//  because we register it globally with URLProtocol.registerClass()
//  So Apollo requests are ALREADY being logged - we just need to use Apollo normally!
//

#if canImport(Apollo)
import Foundation
import Apollo
import DebugSwift

// MARK: - Simple Apollo Client Factory

/// Creates an Apollo Client - requests will automatically be logged by DebugSwift
/// This works because DebugSwift's CustomHTTPProtocol is registered globally
public func createApolloClientWithDebugSwift(
    endpointURL: URL,
    store: ApolloStore = ApolloStore()
) -> ApolloClient {
    
    // Create a simple Apollo client
    // The CustomHTTPProtocol is already registered globally, so it will
    // automatically intercept Apollo's URLSession requests
    let transport = RequestChainNetworkTransport(
        interceptorProvider: DefaultInterceptorProvider(store: store),
        endpointURL: endpointURL
    )
    
    return ApolloClient(networkTransport: transport, store: store)
}

#endif
