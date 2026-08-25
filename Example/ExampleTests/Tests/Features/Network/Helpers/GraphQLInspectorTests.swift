//
//  GraphQLInspectorTests.swift
//  ExampleTests
//
//  Created by Matheus Gois on 16/07/26.
//

import XCTest
@testable import DebugSwift

final class GraphQLInspectorTests: XCTestCase {

    // MARK: - Helpers

    /// Wraps a query (and optional variables) as a JSON GraphQL request body.
    private func body(query: String?, variables: [String: Any]? = nil) -> String {
        var dict: [String: Any] = ["query": query as Any]
        if let variables { dict["variables"] = variables }
        let data = try! JSONSerialization.data(withJSONObject: dict)
        return String(data: data, encoding: .utf8)!
    }

    private func jsonBody(_ dict: [String: Any]) -> String {
        let data = try! JSONSerialization.data(withJSONObject: dict)
        return String(data: data, encoding: .utf8)!
    }

    /// Builds an `HttpModel` POST with the given JSON body and content type.
    private func makeModel(method: String = "POST",
                           body: String,
                           contentType: String = "application/json",
                           response: String? = nil,
                           decryptedResponse: String? = nil) -> HttpModel {
        let model = HttpModel()
        model.method = method
        model.requestHeaderFields = ["Content-Type": contentType]
        model.requestData = body.data(using: .utf8)
        if let response {
            model.responseData = response.data(using: .utf8)
        }
        if let decryptedResponse {
            model.decryptedResponseData = decryptedResponse.data(using: .utf8)
        }
        return model
    }

    // MARK: - GraphQLInspector.extractOperation

    func testExtractOperation_namedQuery() {
        let result = GraphQLInspector.extractOperation(from: body(query: "query GetUser { user { id } }"))
        XCTAssertEqual(result, .query(name: "GetUser"))
    }

    func testExtractOperation_namedMutation() {
        let result = GraphQLInspector.extractOperation(from: body(query: "mutation UpdateUser($name: String!) { updateUser(name: $name) { id } }"))
        XCTAssertEqual(result, .mutation(name: "UpdateUser"))
    }

    func testExtractOperation_namedSubscription() {
        let result = GraphQLInspector.extractOperation(from: body(query: "subscription OnMessage { messageAdded { id text } }"))
        XCTAssertEqual(result, .subscription(name: "OnMessage"))
    }

    func testExtractOperation_anonymousQuery() {
        let result = GraphQLInspector.extractOperation(from: body(query: "{ user { id } }"))
        XCTAssertNil(result)
    }

    func testExtractOperation_notGraphQL() {
        // Plain JSON without a "query" field.
        let result = GraphQLInspector.extractOperation(from: jsonBody(["data": ["id": 1]]))
        XCTAssertNil(result)
    }

    func testExtractOperation_invalidJSON() {
        let result = GraphQLInspector.extractOperation(from: "this is not json at all")
        XCTAssertNil(result)
    }

    // MARK: - GraphQLInspector.extractVariables

    func testExtractVariables_returnsDictionary() {
        let result = GraphQLInspector.extractVariables(from: body(query: "query GetUser { user { id } }", variables: ["id": "1", "count": 3]))
        XCTAssertEqual(result?["id"] as? String, "1")
        XCTAssertEqual(result?["count"] as? Int, 3)
    }

    func testExtractVariables_missingVariables() {
        let result = GraphQLInspector.extractVariables(from: body(query: "query GetUser { user { id } }"))
        XCTAssertNil(result)
    }

    // MARK: - GraphQLInspector.splitResponse

    func testSplitResponse_hasDataAndErrors() {
        let response = jsonBody([
            "data": ["user": ["id": "1"]],
            "errors": [["message": "field x is required"]]
        ])
        let result = GraphQLInspector.splitResponse(response)
        XCTAssertNotNil(result?.data)
        XCTAssertNotNil(result?.errors)
        let userDict = (result?.data as? [String: Any])?["user"] as? [String: Any]
        XCTAssertEqual(userDict?["id"] as? String, "1")
        XCTAssertFalse((result?.errors as? [[String: Any]])?.isEmpty ?? true)
    }

    func testSplitResponse_onlyData() {
        let response = jsonBody(["data": ["user": ["id": "1"]]])
        let result = GraphQLInspector.splitResponse(response)
        XCTAssertNotNil(result?.data)
        XCTAssertNil(result?.errors)
    }

    func testSplitResponse_invalidJSON() {
        let result = GraphQLInspector.splitResponse("not json")
        XCTAssertNil(result)
    }

    // MARK: - GraphQLInspector.extractErrors

    func testExtractErrors_messagePathAndCode() {
        let response = jsonBody([
            "data": NSNull(),
            "errors": [[
                "message": "Not authorised to hide this friend",
                "path": ["hideFriendRequest"],
                "extensions": ["code": "FORBIDDEN"]
            ]]
        ])

        let errors = GraphQLInspector.extractErrors(from: response)

        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors.first?.message, "Not authorised to hide this friend")
        XCTAssertEqual(errors.first?.path, "hideFriendRequest")
        XCTAssertEqual(errors.first?.code, "FORBIDDEN")
    }

    func testExtractErrors_multipleErrorsAndNestedPath() {
        let response = jsonBody([
            "errors": [
                ["message": "first", "path": ["user", "friends", 0, "id"]],
                ["message": "second"],
                ["message": "third", "extensions": ["code": "INTERNAL"]]
            ]
        ])

        let errors = GraphQLInspector.extractErrors(from: response)

        XCTAssertEqual(errors.count, 3)
        XCTAssertEqual(errors[0].path, "user.friends.0.id")
        XCTAssertNil(errors[1].path)
        XCTAssertNil(errors[1].code)
        XCTAssertEqual(errors[2].code, "INTERNAL")
    }

    func testExtractErrors_noErrorsField_returnsEmpty() {
        XCTAssertTrue(GraphQLInspector.extractErrors(from: jsonBody(["data": ["id": 1]])).isEmpty)
    }

    func testExtractErrors_invalidJSON_returnsEmpty() {
        XCTAssertTrue(GraphQLInspector.extractErrors(from: "not json").isEmpty)
    }

    // MARK: - GraphQLInspectorAdapter.classify

    func testClassify_populatesErrorsAndFlipsIsSuccess() {
        let model = makeModel(
            body: body(query: "mutation HideFriendRequest { hideFriendRequest { id } }"),
            response: jsonBody(["errors": [["message": "Not authorised to hide this friend"]]])
        )
        model.statusCode = "200"
        XCTAssertTrue(model.isSuccess)

        GraphQLInspectorAdapter.classify(model)

        XCTAssertTrue(model.hasGraphQLErrors)
        XCTAssertFalse(model.isSuccess)
        XCTAssertEqual(model.graphQLErrors.first?.message, "Not authorised to hide this friend")
    }

    func testClassify_successfulResponse_staysSuccess() {
        let model = makeModel(
            body: body(query: "query GetUser { user { id } }"),
            response: jsonBody(["data": ["user": ["id": "1"]]])
        )

        GraphQLInspectorAdapter.classify(model)

        XCTAssertFalse(model.hasGraphQLErrors)
        XCTAssertTrue(model.isSuccess)
    }

    func testClassify_nonGraphQLModel_ignoresErrorsShapedBody() {
        let model = makeModel(method: "GET", body: "",
                              response: jsonBody(["errors": [["message": "not graphql"]]]))

        GraphQLInspectorAdapter.classify(model)

        XCTAssertFalse(model.hasGraphQLErrors)
    }

    func testClassify_doesNotOverwriteProducerSetErrors() {
        let model = makeModel(
            body: body(query: "query GetUser { user { id } }"),
            response: jsonBody(["errors": [["message": "from response"]]])
        )
        model.graphQLErrors = [HttpGraphQLError(message: "from bridge")]

        GraphQLInspectorAdapter.classify(model)

        XCTAssertEqual(model.graphQLErrors.map(\.message), ["from bridge"])
    }

    // MARK: - GraphQLInspectorAdapter.isGraphQL

    func testIsGraphQL_postWithJsonAndQuery_returnsTrue() {
        let model = makeModel(body: body(query: "query GetUser { user { id } }"))
        XCTAssertTrue(GraphQLInspectorAdapter.isGraphQL(model))
    }

    func testIsGraphQL_getRequest_returnsFalse() {
        let model = makeModel(method: "GET", body: body(query: "query GetUser { user { id } }"))
        XCTAssertFalse(GraphQLInspectorAdapter.isGraphQL(model))
    }

    func testIsGraphQL_postWithoutQueryField_returnsFalse() {
        let model = makeModel(body: jsonBody(["data": ["id": 1]]))
        XCTAssertFalse(GraphQLInspectorAdapter.isGraphQL(model))
    }

    func testIsGraphQL_postWithoutJsonContentType_returnsFalse() {
        let model = makeModel(body: body(query: "query GetUser { user { id } }"),
                             contentType: "text/plain")
        XCTAssertFalse(GraphQLInspectorAdapter.isGraphQL(model))
    }

    // MARK: - GraphQLInspectorAdapter.detail

    func testDetail_forGraphQLModel_returnsOperationAndVariables() {
        let model = makeModel(
            body: body(query: "query GetUser { user { id } }", variables: ["id": "1"]),
            response: jsonBody(["data": ["user": ["id": "1"]]])
        )

        let detail = GraphQLInspectorAdapter.detail(for: model)

        XCTAssertEqual(detail.operation, .query(name: "GetUser"))
        XCTAssertEqual(detail.variables?["id"] as? String, "1")
        XCTAssertEqual(detail.query, "query GetUser { user { id } }")
        XCTAssertNotNil(detail.response?.data)
        XCTAssertNil(detail.response?.errors)
    }

    func testDetail_forNonGraphQLModel_returnsNilOperation() {
        let model = makeModel(body: jsonBody(["data": ["id": 1]]))

        let detail = GraphQLInspectorAdapter.detail(for: model)

        XCTAssertNil(detail.operation)
        XCTAssertNil(detail.variables)
        XCTAssertNil(detail.query)
    }

    func testDetail_prefersDecryptedResponseData() {
        let model = makeModel(
            body: body(query: "query GetUser { user { id } }"),
            response: jsonBody(["data": ["encrypted": true]]),
            decryptedResponse: jsonBody(["data": ["user": ["id": "1"]], "errors": [["message": "fail"]]])
        )

        let detail = GraphQLInspectorAdapter.detail(for: model)

        XCTAssertNotNil(detail.response?.data)
        XCTAssertNotNil(detail.response?.errors)
    }

    func testDetail_emptyRequestBodyReturnsAllNil() {
        let model = HttpModel()
        model.method = "POST"
        model.requestHeaderFields = ["Content-Type": "application/json"]
        // requestData is nil

        let detail = GraphQLInspectorAdapter.detail(for: model)

        XCTAssertNil(detail.operation)
        XCTAssertNil(detail.variables)
        XCTAssertNil(detail.response)
        XCTAssertNil(detail.query)
    }
}
