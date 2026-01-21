//
//  ManualLoggingTests.swift
//  DebugSwiftTests
//
//  Tests for manual request logging API
//

import XCTest
@testable import DebugSwift

@MainActor
final class ManualLoggingTests: XCTestCase {
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Enable network monitoring
        await NetworkHelper.shared.enable()
        
        // Clear any existing data
        HttpDatasource.shared.removeAll()
    }
    
    override func tearDown() async throws {
        // Clean up
        HttpDatasource.shared.removeAll()
        await NetworkHelper.shared.disable()
        
        try await super.tearDown()
    }
    
    // MARK: - Basic Logging Tests
    
    func testLogBasicRequest() async throws {
        // Given
        let url = URL(string: "https://api.example.com/test")!
        let startTime = Date()
        let endTime = Date(timeIntervalSinceNow: 0.5)
        let requestData = "test request".data(using: .utf8)
        let responseData = "{\"success\":true}".data(using: .utf8)
        
        // When
        DebugSwift.Network.shared.logRequest(
            url: url,
            method: "POST",
            requestData: requestData,
            requestHeaders: ["Content-Type": "application/json"],
            responseData: responseData,
            statusCode: 200,
            responseHeaders: ["Content-Type": "application/json"],
            mimeType: "application/json",
            startTime: startTime,
            endTime: endTime,
            error: nil
        )
        
        // Then
        let requests = HttpDatasource.shared.httpModels
        XCTAssertEqual(requests.count, 1)
        
        let request = requests.first!
        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/test")
        XCTAssertEqual(request.method, "POST")
        XCTAssertEqual(request.statusCode, "200")
        XCTAssertEqual(request.mineType, "application/json")
        XCTAssertEqual(request.requestData, requestData)
        XCTAssertEqual(request.responseData, responseData)
        XCTAssertTrue(request.isSuccess)
    }
    
    func testLogRequestWithError() async throws {
        // Given
        let url = URL(string: "https://api.example.com/fail")!
        let startTime = Date()
        let endTime = Date(timeIntervalSinceNow: 0.1)
        let error = NSError(
            domain: "TestError",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Internal Server Error"]
        )
        
        // When
        DebugSwift.Network.shared.logRequest(
            url: url,
            method: "GET",
            requestData: nil,
            requestHeaders: nil,
            responseData: nil,
            statusCode: 500,
            responseHeaders: nil,
            startTime: startTime,
            endTime: endTime,
            error: error
        )
        
        // Then
        let requests = HttpDatasource.shared.httpModels
        XCTAssertEqual(requests.count, 1)
        
        let request = requests.first!
        XCTAssertEqual(request.statusCode, "500")
        XCTAssertFalse(request.isSuccess)
        XCTAssertEqual(request.errorDescription, "Internal Server Error")
        XCTAssertEqual(request.errorLocalizedDescription, "Internal Server Error")
    }
    
    // MARK: - GraphQL/Apollo Simulation Tests
    
    func testLogGraphQLRequest() async throws {
        // Given - Simulate a GraphQL query
        let url = URL(string: "https://api.example.com/graphql")!
        let startTime = Date()
        let endTime = Date(timeIntervalSinceNow: 0.3)
        
        let graphQLQuery = """
        {
            "query": "query GetUser($id: ID!) { user(id: $id) { name email } }",
            "variables": { "id": "123" }
        }
        """
        let requestData = graphQLQuery.data(using: .utf8)
        
        let graphQLResponse = """
        {
            "data": {
                "user": {
                    "name": "John Doe",
                    "email": "john@example.com"
                }
            }
        }
        """
        let responseData = graphQLResponse.data(using: .utf8)
        
        // When
        DebugSwift.Network.shared.logRequest(
            url: url,
            method: "POST",
            requestData: requestData,
            requestHeaders: [
                "Content-Type": "application/json",
                "Authorization": "Bearer test-token"
            ],
            responseData: responseData,
            statusCode: 200,
            responseHeaders: ["Content-Type": "application/json"],
            mimeType: "application/json",
            startTime: startTime,
            endTime: endTime,
            error: nil
        )
        
        // Then
        let requests = HttpDatasource.shared.httpModels
        XCTAssertEqual(requests.count, 1)
        
        let request = requests.first!
        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/graphql")
        XCTAssertEqual(request.method, "POST")
        XCTAssertTrue(request.isSuccess)
        
        // Verify request contains GraphQL query
        if let requestString = String(data: request.requestData ?? Data(), encoding: .utf8) {
            XCTAssertTrue(requestString.contains("query GetUser"))
        }
        
        // Verify response contains data
        if let responseString = String(data: request.responseData ?? Data(), encoding: .utf8) {
            XCTAssertTrue(responseString.contains("John Doe"))
        }
    }
    
    func testLogGraphQLRequestWithErrors() async throws {
        // Given - GraphQL with errors
        let url = URL(string: "https://api.example.com/graphql")!
        let startTime = Date()
        let endTime = Date(timeIntervalSinceNow: 0.2)
        
        let graphQLResponse = """
        {
            "errors": [
                {
                    "message": "Field 'invalidField' doesn't exist on type 'User'",
                    "locations": [{"line": 2, "column": 3}]
                }
            ],
            "data": null
        }
        """
        let responseData = graphQLResponse.data(using: .utf8)
        
        let error = NSError(
            domain: "GraphQLError",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Field 'invalidField' doesn't exist"]
        )
        
        // When
        DebugSwift.Network.shared.logRequest(
            url: url,
            method: "POST",
            requestData: Data(),
            requestHeaders: ["Content-Type": "application/json"],
            responseData: responseData,
            statusCode: 200,
            responseHeaders: ["Content-Type": "application/json"],
            mimeType: "application/json",
            startTime: startTime,
            endTime: endTime,
            error: error
        )
        
        // Then
        let requests = HttpDatasource.shared.httpModels
        XCTAssertEqual(requests.count, 1)
        
        let request = requests.first!
        XCTAssertEqual(request.statusCode, "200") // GraphQL errors still return 200
        XCTAssertFalse(request.isSuccess) // But marked as failed due to error
        XCTAssertNotNil(request.errorDescription)
    }
    
    // MARK: - Timing Tests
    
    func testRequestTimingCalculation() async throws {
        // Given
        let url = URL(string: "https://api.example.com/slow")!
        let startTime = Date()
        let endTime = Date(timeIntervalSinceNow: 2.5) // 2.5 seconds
        
        // When
        DebugSwift.Network.shared.logRequest(
            url: url,
            method: "GET",
            requestData: nil,
            requestHeaders: nil,
            responseData: Data(),
            statusCode: 200,
            responseHeaders: nil,
            startTime: startTime,
            endTime: endTime,
            error: nil
        )
        
        // Then
        let requests = HttpDatasource.shared.httpModels
        let request = requests.first!
        
        XCTAssertNotNil(request.totalDuration)
        // Duration should be around 2.5 seconds
        if let duration = request.totalDuration, duration.contains("2.5") {
            XCTAssertTrue(true)
        } else {
            XCTFail("Duration not calculated correctly")
        }
    }
    
    // MARK: - URL Filtering Tests
    
    func testRequestFilteringWithIgnoredURLs() async throws {
        // Given
        DebugSwift.Network.shared.ignoredURLs = ["analytics.com"]
        let url = URL(string: "https://analytics.com/track")!
        
        // When
        DebugSwift.Network.shared.logRequest(
            url: url,
            method: "POST",
            requestData: Data(),
            requestHeaders: nil,
            responseData: Data(),
            statusCode: 200,
            responseHeaders: nil,
            startTime: Date(),
            endTime: Date(),
            error: nil
        )
        
        // Then
        let requests = HttpDatasource.shared.httpModels
        XCTAssertEqual(requests.count, 0, "Request should be filtered out")
        
        // Cleanup
        DebugSwift.Network.shared.ignoredURLs = []
    }
    
    func testRequestFilteringWithOnlyURLs() async throws {
        // Given
        DebugSwift.Network.shared.onlyURLs = ["api.example.com"]
        
        // When - Log allowed URL
        DebugSwift.Network.shared.logRequest(
            url: URL(string: "https://api.example.com/test")!,
            method: "GET",
            requestData: nil,
            requestHeaders: nil,
            responseData: Data(),
            statusCode: 200,
            responseHeaders: nil,
            startTime: Date(),
            endTime: Date(),
            error: nil
        )
        
        // When - Log disallowed URL
        DebugSwift.Network.shared.logRequest(
            url: URL(string: "https://other.com/test")!,
            method: "GET",
            requestData: nil,
            requestHeaders: nil,
            responseData: Data(),
            statusCode: 200,
            responseHeaders: nil,
            startTime: Date(),
            endTime: Date(),
            error: nil
        )
        
        // Then
        let requests = HttpDatasource.shared.httpModels
        XCTAssertEqual(requests.count, 1, "Only allowed URL should be logged")
        XCTAssertTrue(requests.first?.url?.absoluteString.contains("api.example.com") ?? false)
        
        // Cleanup
        DebugSwift.Network.shared.onlyURLs = []
    }
    
    // MARK: - Custom Request ID Tests
    
    func testCustomRequestId() async throws {
        // Given
        let customId = "my-custom-request-id-123"
        
        // When
        DebugSwift.Network.shared.logRequest(
            url: URL(string: "https://api.example.com/test")!,
            method: "GET",
            requestData: nil,
            requestHeaders: nil,
            responseData: Data(),
            statusCode: 200,
            responseHeaders: nil,
            startTime: Date(),
            endTime: Date(),
            error: nil,
            requestId: customId
        )
        
        // Then
        let requests = HttpDatasource.shared.httpModels
        XCTAssertEqual(requests.first?.requestId, customId)
    }
    
    func testAutoGeneratedRequestId() async throws {
        // When - No custom ID provided
        DebugSwift.Network.shared.logRequest(
            url: URL(string: "https://api.example.com/test")!,
            method: "GET",
            requestData: nil,
            requestHeaders: nil,
            responseData: Data(),
            statusCode: 200,
            responseHeaders: nil,
            startTime: Date(),
            endTime: Date(),
            error: nil
        )
        
        // Then
        let requests = HttpDatasource.shared.httpModels
        XCTAssertNotNil(requests.first?.requestId)
        XCTAssertFalse(requests.first?.requestId?.isEmpty ?? true)
    }
}


