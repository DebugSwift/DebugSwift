//
//  HTTPRequestFilterTests.swift
//  ExampleTests
//
//  Created by DebugSwift on 2026.
//

import XCTest
@testable import DebugSwift

final class HTTPRequestFilterTests: XCTestCase {

    // MARK: - Helpers

    private func makeRequest(
        method: String? = "GET",
        statusCode: String? = "200",
        mimeType: String? = nil,
        totalDuration: String? = nil,
        responseData: Data? = nil,
        errorDescription: String? = nil,
        url: URL? = URL(string: "https://api.example.com/users")
    ) -> HttpModel {
        let model = HttpModel()
        model.method = method
        model.statusCode = statusCode
        model.mineType = mimeType
        model.totalDuration = totalDuration
        model.responseData = responseData
        model.errorDescription = errorDescription
        model.url = url
        return model
    }

    // MARK: - isActive Tests

    func testIsActive_defaultFilter_isFalse() {
        let filter = HTTPRequestFilter()
        XCTAssertFalse(filter.isActive)
    }

    func testIsActive_withMethodFilter_isTrue() {
        var filter = HTTPRequestFilter()
        filter.methods = ["GET"]
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_withStatusCodeRange_isTrue() {
        var filter = HTTPRequestFilter()
        filter.statusCodeRanges = [.success]
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_withContentType_isTrue() {
        var filter = HTTPRequestFilter()
        filter.contentTypes = ["application/json"]
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_withMinResponseTime_isTrue() {
        var filter = HTTPRequestFilter()
        filter.minResponseTime = 0.5
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_withMaxResponseTime_isTrue() {
        var filter = HTTPRequestFilter()
        filter.maxResponseTime = 5.0
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_withMinSize_isTrue() {
        var filter = HTTPRequestFilter()
        filter.minSize = 100
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_withMaxSize_isTrue() {
        var filter = HTTPRequestFilter()
        filter.maxSize = 1024
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_withShowOnlyErrors_isTrue() {
        var filter = HTTPRequestFilter()
        filter.showOnlyErrors = true
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_withShowOnlySuccessful_isTrue() {
        var filter = HTTPRequestFilter()
        filter.showOnlySuccessful = true
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_withHostFilter_isTrue() {
        var filter = HTTPRequestFilter()
        filter.hostFilters = ["api.example.com"]
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_withTimeRange_isTrue() {
        var filter = HTTPRequestFilter()
        filter.timeRange = .lastHour
        XCTAssertTrue(filter.isActive)
    }

    // MARK: - matches - Method Filter Tests

    func testMatches_noMethodFilter_matchesAnyMethod() {
        let filter = HTTPRequestFilter()
        let request = makeRequest(method: "DELETE")
        XCTAssertTrue(filter.matches(request))
    }

    func testMatches_methodFilter_matchesCorrectMethod() {
        var filter = HTTPRequestFilter()
        filter.methods = ["GET"]
        let request = makeRequest(method: "GET")
        XCTAssertTrue(filter.matches(request))
    }

    func testMatches_methodFilter_doesNotMatchOtherMethod() {
        var filter = HTTPRequestFilter()
        filter.methods = ["GET"]
        let request = makeRequest(method: "POST")
        XCTAssertFalse(filter.matches(request))
    }

    func testMatches_methodFilter_multipleMethodsMatchesAny() {
        var filter = HTTPRequestFilter()
        filter.methods = ["GET", "POST"]
        let getRequest = makeRequest(method: "GET")
        let postRequest = makeRequest(method: "POST")
        let deleteRequest = makeRequest(method: "DELETE")
        XCTAssertTrue(filter.matches(getRequest))
        XCTAssertTrue(filter.matches(postRequest))
        XCTAssertFalse(filter.matches(deleteRequest))
    }

    func testMatches_methodFilter_nilMethodDoesNotMatch() {
        var filter = HTTPRequestFilter()
        filter.methods = ["GET"]
        let request = makeRequest(method: nil)
        XCTAssertFalse(filter.matches(request))
    }

    // MARK: - matches - Status Code Filter Tests

    func testMatches_statusCodeFilter_matchesCodeInRange() {
        var filter = HTTPRequestFilter()
        filter.statusCodeRanges = [.success]
        let request = makeRequest(statusCode: "200")
        XCTAssertTrue(filter.matches(request))
    }

    func testMatches_statusCodeFilter_doesNotMatchCodeOutsideRange() {
        var filter = HTTPRequestFilter()
        filter.statusCodeRanges = [.success]
        let request = makeRequest(statusCode: "404")
        XCTAssertFalse(filter.matches(request))
    }

    func testMatches_statusCodeFilter_multipleRangesMatchesAny() {
        var filter = HTTPRequestFilter()
        filter.statusCodeRanges = [.clientError, .serverError]
        XCTAssertTrue(filter.matches(makeRequest(statusCode: "404")))
        XCTAssertTrue(filter.matches(makeRequest(statusCode: "500")))
        XCTAssertFalse(filter.matches(makeRequest(statusCode: "200")))
    }

    func testMatches_statusCodeFilter_nilStatusCodeDoesNotMatch() {
        var filter = HTTPRequestFilter()
        filter.statusCodeRanges = [.success]
        let request = makeRequest(statusCode: nil)
        XCTAssertFalse(filter.matches(request))
    }

    // MARK: - matches - Content Type Filter Tests

    func testMatches_contentTypeFilter_matchesCorrectMimeType() {
        var filter = HTTPRequestFilter()
        filter.contentTypes = ["application/json"]
        let request = makeRequest(mimeType: "application/json")
        XCTAssertTrue(filter.matches(request))
    }

    func testMatches_contentTypeFilter_matchesCaseInsensitive() {
        var filter = HTTPRequestFilter()
        filter.contentTypes = ["application/json"]
        let request = makeRequest(mimeType: "Application/JSON")
        XCTAssertTrue(filter.matches(request))
    }

    func testMatches_contentTypeFilter_matchesPartialMimeType() {
        var filter = HTTPRequestFilter()
        filter.contentTypes = ["json"]
        let request = makeRequest(mimeType: "application/json")
        XCTAssertTrue(filter.matches(request))
    }

    func testMatches_contentTypeFilter_doesNotMatchUnrelatedMimeType() {
        var filter = HTTPRequestFilter()
        filter.contentTypes = ["application/json"]
        let request = makeRequest(mimeType: "text/html")
        XCTAssertFalse(filter.matches(request))
    }

    func testMatches_contentTypeFilter_nilMimeTypeDoesNotMatch() {
        var filter = HTTPRequestFilter()
        filter.contentTypes = ["application/json"]
        let request = makeRequest(mimeType: nil)
        XCTAssertFalse(filter.matches(request))
    }

    // MARK: - matches - Response Time Filter Tests

    func testMatches_minResponseTimeFilter_matchesAboveMin() {
        var filter = HTTPRequestFilter()
        filter.minResponseTime = 1.0
        let request = makeRequest(totalDuration: "2.5 (s)")
        XCTAssertTrue(filter.matches(request))
    }

    func testMatches_minResponseTimeFilter_doesNotMatchBelowMin() {
        var filter = HTTPRequestFilter()
        filter.minResponseTime = 1.0
        let request = makeRequest(totalDuration: "0.5 (s)")
        XCTAssertFalse(filter.matches(request))
    }

    func testMatches_maxResponseTimeFilter_matchesBelowMax() {
        var filter = HTTPRequestFilter()
        filter.maxResponseTime = 3.0
        let request = makeRequest(totalDuration: "1.5 (s)")
        XCTAssertTrue(filter.matches(request))
    }

    func testMatches_maxResponseTimeFilter_doesNotMatchAboveMax() {
        var filter = HTTPRequestFilter()
        filter.maxResponseTime = 3.0
        let request = makeRequest(totalDuration: "5.0 (s)")
        XCTAssertFalse(filter.matches(request))
    }

    func testMatches_responseTimeRange_matchesWithinRange() {
        var filter = HTTPRequestFilter()
        filter.minResponseTime = 1.0
        filter.maxResponseTime = 3.0
        let request = makeRequest(totalDuration: "2.0 (s)")
        XCTAssertTrue(filter.matches(request))
    }

    func testMatches_responseTimeRange_doesNotMatchOutsideRange() {
        var filter = HTTPRequestFilter()
        filter.minResponseTime = 1.0
        filter.maxResponseTime = 3.0
        let request = makeRequest(totalDuration: "4.0 (s)")
        XCTAssertFalse(filter.matches(request))
    }

    func testMatches_responseTimeFilter_nilDurationDoesNotMatch() {
        var filter = HTTPRequestFilter()
        filter.minResponseTime = 1.0
        let request = makeRequest(totalDuration: nil)
        XCTAssertFalse(filter.matches(request))
    }

    // MARK: - matches - Size Filter Tests

    func testMatches_minSizeFilter_matchesAboveMin() {
        var filter = HTTPRequestFilter()
        filter.minSize = 100
        let request = makeRequest(responseData: Data(count: 200))
        XCTAssertTrue(filter.matches(request))
    }

    func testMatches_minSizeFilter_doesNotMatchBelowMin() {
        var filter = HTTPRequestFilter()
        filter.minSize = 100
        let request = makeRequest(responseData: Data(count: 50))
        XCTAssertFalse(filter.matches(request))
    }

    func testMatches_maxSizeFilter_matchesBelowMax() {
        var filter = HTTPRequestFilter()
        filter.maxSize = 1000
        let request = makeRequest(responseData: Data(count: 500))
        XCTAssertTrue(filter.matches(request))
    }

    func testMatches_maxSizeFilter_doesNotMatchAboveMax() {
        var filter = HTTPRequestFilter()
        filter.maxSize = 1000
        let request = makeRequest(responseData: Data(count: 2000))
        XCTAssertFalse(filter.matches(request))
    }

    func testMatches_sizeFilter_nilResponseDataCountsAsZero() {
        var filter = HTTPRequestFilter()
        filter.minSize = 1
        let request = makeRequest(responseData: nil)
        XCTAssertFalse(filter.matches(request))
    }

    // MARK: - matches - Error/Success Filter Tests

    func testMatches_showOnlyErrors_excludesSuccessfulRequests() {
        var filter = HTTPRequestFilter()
        filter.showOnlyErrors = true
        let successRequest = makeRequest(errorDescription: nil)
        XCTAssertFalse(filter.matches(successRequest))
    }

    func testMatches_showOnlyErrors_includesFailedRequests() {
        var filter = HTTPRequestFilter()
        filter.showOnlyErrors = true
        let errorRequest = makeRequest(errorDescription: "Connection failed")
        XCTAssertTrue(filter.matches(errorRequest))
    }

    func testMatches_showOnlySuccessful_excludesErrorRequests() {
        var filter = HTTPRequestFilter()
        filter.showOnlySuccessful = true
        let errorRequest = makeRequest(errorDescription: "Connection failed")
        XCTAssertFalse(filter.matches(errorRequest))
    }

    func testMatches_showOnlySuccessful_includesSuccessfulRequests() {
        var filter = HTTPRequestFilter()
        filter.showOnlySuccessful = true
        let successRequest = makeRequest(errorDescription: nil)
        XCTAssertTrue(filter.matches(successRequest))
    }

    // MARK: - matches - Host Filter Tests

    func testMatches_hostFilter_matchesCorrectHost() {
        var filter = HTTPRequestFilter()
        filter.hostFilters = ["api.example.com"]
        let request = makeRequest(url: URL(string: "https://api.example.com/users"))
        XCTAssertTrue(filter.matches(request))
    }

    func testMatches_hostFilter_doesNotMatchDifferentHost() {
        var filter = HTTPRequestFilter()
        filter.hostFilters = ["api.example.com"]
        let request = makeRequest(url: URL(string: "https://other.example.com/users"))
        XCTAssertFalse(filter.matches(request))
    }

    func testMatches_hostFilter_matchesCaseInsensitive() {
        var filter = HTTPRequestFilter()
        filter.hostFilters = ["API.EXAMPLE.COM"]
        let request = makeRequest(url: URL(string: "https://api.example.com/users"))
        XCTAssertTrue(filter.matches(request))
    }

    func testMatches_hostFilter_matchesPartialHost() {
        var filter = HTTPRequestFilter()
        filter.hostFilters = ["example.com"]
        let request = makeRequest(url: URL(string: "https://api.example.com/users"))
        XCTAssertTrue(filter.matches(request))
    }

    func testMatches_hostFilter_nilURLDoesNotMatch() {
        var filter = HTTPRequestFilter()
        filter.hostFilters = ["api.example.com"]
        let request = makeRequest(url: nil)
        XCTAssertFalse(filter.matches(request))
    }

    // MARK: - matches - Time Range Filter Tests

    func testMatches_timeRangeLastHour_matchesRecentRequest() {
        var filter = HTTPRequestFilter()
        filter.timeRange = .lastHour
        let recentDate = Date().addingTimeInterval(-60)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let request = makeRequest()
        request.startTime = formatter.string(from: recentDate)
        XCTAssertTrue(filter.matches(request))
    }

    func testMatches_timeRangeLastHour_doesNotMatchOldRequest() {
        var filter = HTTPRequestFilter()
        filter.timeRange = .lastHour
        let oldDate = Date().addingTimeInterval(-7200)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let request = makeRequest()
        request.startTime = formatter.string(from: oldDate)
        XCTAssertFalse(filter.matches(request))
    }

    func testMatches_timeRangeLastDay_matchesRequestWithinDay() {
        var filter = HTTPRequestFilter()
        filter.timeRange = .lastDay
        let recentDate = Date().addingTimeInterval(-3600)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let request = makeRequest()
        request.startTime = formatter.string(from: recentDate)
        XCTAssertTrue(filter.matches(request))
    }

    func testMatches_timeRangeCustom_matchesRequestInRange() {
        let start = Date().addingTimeInterval(-3600)
        let end = Date().addingTimeInterval(3600)
        var filter = HTTPRequestFilter()
        filter.timeRange = .custom(start: start, end: end)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let request = makeRequest()
        request.startTime = formatter.string(from: Date())
        XCTAssertTrue(filter.matches(request))
    }

    func testMatches_timeRangeCustom_doesNotMatchRequestOutsideRange() {
        let start = Date().addingTimeInterval(-7200)
        let end = Date().addingTimeInterval(-3600)
        var filter = HTTPRequestFilter()
        filter.timeRange = .custom(start: start, end: end)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let request = makeRequest()
        request.startTime = formatter.string(from: Date())
        XCTAssertFalse(filter.matches(request))
    }

    func testMatches_timeRangeFilter_nilStartTimeDoesNotMatch() {
        var filter = HTTPRequestFilter()
        filter.timeRange = .lastHour
        let request = makeRequest()
        request.startTime = nil
        XCTAssertFalse(filter.matches(request))
    }

    // MARK: - StatusCodeRange Tests

    func testStatusCodeRange_contains_returnsTrueForCodeInRange() {
        let range = StatusCodeRange.success
        XCTAssertTrue(range.contains(200))
        XCTAssertTrue(range.contains(250))
        XCTAssertTrue(range.contains(299))
    }

    func testStatusCodeRange_contains_returnsFalseForCodeOutsideRange() {
        let range = StatusCodeRange.success
        XCTAssertFalse(range.contains(199))
        XCTAssertFalse(range.contains(300))
    }

    func testStatusCodeRange_predefinedRanges_haveCorrectBoundaries() {
        XCTAssertEqual(StatusCodeRange.success.min, 200)
        XCTAssertEqual(StatusCodeRange.success.max, 299)
        XCTAssertEqual(StatusCodeRange.redirection.min, 300)
        XCTAssertEqual(StatusCodeRange.redirection.max, 399)
        XCTAssertEqual(StatusCodeRange.clientError.min, 400)
        XCTAssertEqual(StatusCodeRange.clientError.max, 499)
        XCTAssertEqual(StatusCodeRange.serverError.min, 500)
        XCTAssertEqual(StatusCodeRange.serverError.max, 599)
    }

    func testStatusCodeRange_allRanges_containsAllFourRanges() {
        XCTAssertEqual(StatusCodeRange.allRanges.count, 4)
    }

    // MARK: - TimeRange Tests

    func testTimeRange_displayName_lastHour() {
        let range = TimeRange.lastHour
        XCTAssertEqual(range.displayName, "Last Hour")
    }

    func testTimeRange_displayName_lastDay() {
        let range = TimeRange.lastDay
        XCTAssertEqual(range.displayName, "Last Day")
    }

    func testTimeRange_displayName_custom_containsDates() {
        let start = Date(timeIntervalSince1970: 0)
        let end = Date(timeIntervalSince1970: 86400)
        let range = TimeRange.custom(start: start, end: end)
        XCTAssertFalse(range.displayName.isEmpty)
        XCTAssertTrue(range.displayName.contains(" - "))
    }
}
