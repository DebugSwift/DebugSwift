//
//  HTTPRequestFilterTests.swift
//  DebugSwift
//
//  Created by DebugSwift on 2026.
//  Based on Given methodology
//

import XCTest
@testable import DebugSwift

final class HTTPRequestFilterTests: XCTestCase {

    // MARK: - Helpers

    private func makeRequest(
        method: String? = nil,
        statusCode: String? = nil,
        mimeType: String? = nil,
        totalDuration: String? = nil,
        responseData: Data? = nil,
        errorDescription: String? = nil,
        urlString: String = "https://api.example.com/users",
        startTime: String? = nil
    ) -> HttpModel {
        let model = HttpModel()
        model.method = method
        model.statusCode = statusCode
        model.mineType = mimeType
        model.totalDuration = totalDuration
        model.responseData = responseData
        model.errorDescription = errorDescription
        model.url = URL(string: urlString)
        model.startTime = startTime
        return model
    }

    // MARK: - isActive

    func testIsActive_defaultFilter_isFalse() {
        // Given
        let filter = HTTPRequestFilter()

        // Then
        XCTAssertFalse(filter.isActive)
    }

    func testIsActive_withMethodFilter_isTrue() {
        // Given
        var filter = HTTPRequestFilter()

        // When
        filter.methods = ["GET"]

        // Then
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_withStatusCodeRanges_isTrue() {
        // Given
        var filter = HTTPRequestFilter()

        // When
        filter.statusCodeRanges = [StatusCodeRange.success]

        // Then
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_withContentTypes_isTrue() {
        // Given
        var filter = HTTPRequestFilter()

        // When
        filter.contentTypes = ["application/json"]

        // Then
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_withMinResponseTime_isTrue() {
        // Given
        var filter = HTTPRequestFilter()

        // When
        filter.minResponseTime = 0.5

        // Then
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_withMaxResponseTime_isTrue() {
        // Given
        var filter = HTTPRequestFilter()

        // When
        filter.maxResponseTime = 5.0

        // Then
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_withMinSize_isTrue() {
        // Given
        var filter = HTTPRequestFilter()

        // When
        filter.minSize = 100

        // Then
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_withMaxSize_isTrue() {
        // Given
        var filter = HTTPRequestFilter()

        // When
        filter.maxSize = 1000

        // Then
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_withShowOnlyErrors_isTrue() {
        // Given
        var filter = HTTPRequestFilter()

        // When
        filter.showOnlyErrors = true

        // Then
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_withShowOnlySuccessful_isTrue() {
        // Given
        var filter = HTTPRequestFilter()

        // When
        filter.showOnlySuccessful = true

        // Then
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_withHostFilters_isTrue() {
        // Given
        var filter = HTTPRequestFilter()

        // When
        filter.hostFilters = ["example.com"]

        // Then
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_withTimeRange_isTrue() {
        // Given
        var filter = HTTPRequestFilter()

        // When
        filter.timeRange = .lastHour

        // Then
        XCTAssertTrue(filter.isActive)
    }

    // MARK: - matches: no filters

    func testMatches_noFiltersSet_returnsTrue() {
        // Given
        let filter = HTTPRequestFilter()
        let request = makeRequest(method: "GET", statusCode: "200")

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertTrue(result)
    }

    // MARK: - matches: method filter

    func testMatches_methodFilter_matchingMethod_returnsTrue() {
        // Given
        var filter = HTTPRequestFilter()
        filter.methods = ["GET"]
        let request = makeRequest(method: "GET")

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertTrue(result)
    }

    func testMatches_methodFilter_nonMatchingMethod_returnsFalse() {
        // Given
        var filter = HTTPRequestFilter()
        filter.methods = ["POST"]
        let request = makeRequest(method: "GET")

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertFalse(result)
    }

    func testMatches_methodFilter_nilMethod_returnsFalse() {
        // Given
        var filter = HTTPRequestFilter()
        filter.methods = ["GET"]
        let request = makeRequest(method: nil)

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - matches: status code filter

    func testMatches_statusCodeFilter_matchingCode_returnsTrue() {
        // Given
        var filter = HTTPRequestFilter()
        filter.statusCodeRanges = [StatusCodeRange.success]
        let request = makeRequest(statusCode: "200")

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertTrue(result)
    }

    func testMatches_statusCodeFilter_nonMatchingCode_returnsFalse() {
        // Given
        var filter = HTTPRequestFilter()
        filter.statusCodeRanges = [StatusCodeRange.success]
        let request = makeRequest(statusCode: "404")

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertFalse(result)
    }

    func testMatches_statusCodeFilter_nilStatusCode_returnsFalse() {
        // Given
        var filter = HTTPRequestFilter()
        filter.statusCodeRanges = [StatusCodeRange.success]
        let request = makeRequest(statusCode: nil)

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - matches: content type filter

    func testMatches_contentTypeFilter_matchingType_returnsTrue() {
        // Given
        var filter = HTTPRequestFilter()
        filter.contentTypes = ["application/json"]
        let request = makeRequest(mimeType: "application/json")

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertTrue(result)
    }

    func testMatches_contentTypeFilter_caseInsensitiveMatch_returnsTrue() {
        // Given
        var filter = HTTPRequestFilter()
        filter.contentTypes = ["Application/JSON"]
        let request = makeRequest(mimeType: "application/json; charset=utf-8")

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertTrue(result)
    }

    func testMatches_contentTypeFilter_nonMatchingType_returnsFalse() {
        // Given
        var filter = HTTPRequestFilter()
        filter.contentTypes = ["application/json"]
        let request = makeRequest(mimeType: "text/html")

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertFalse(result)
    }

    func testMatches_contentTypeFilter_nilMimeType_returnsFalse() {
        // Given
        var filter = HTTPRequestFilter()
        filter.contentTypes = ["application/json"]
        let request = makeRequest(mimeType: nil)

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - matches: response time filter

    func testMatches_minResponseTimeFilter_withinRange_returnsTrue() {
        // Given
        var filter = HTTPRequestFilter()
        filter.minResponseTime = 0.5
        let request = makeRequest(totalDuration: "1.0 (s)")

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertTrue(result)
    }

    func testMatches_minResponseTimeFilter_belowRange_returnsFalse() {
        // Given
        var filter = HTTPRequestFilter()
        filter.minResponseTime = 2.0
        let request = makeRequest(totalDuration: "0.5 (s)")

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertFalse(result)
    }

    func testMatches_maxResponseTimeFilter_withinRange_returnsTrue() {
        // Given
        var filter = HTTPRequestFilter()
        filter.maxResponseTime = 5.0
        let request = makeRequest(totalDuration: "1.0 (s)")

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertTrue(result)
    }

    func testMatches_maxResponseTimeFilter_aboveRange_returnsFalse() {
        // Given
        var filter = HTTPRequestFilter()
        filter.maxResponseTime = 1.0
        let request = makeRequest(totalDuration: "3.0 (s)")

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertFalse(result)
    }

    func testMatches_responseTimeRangeFilter_withinRange_returnsTrue() {
        // Given
        var filter = HTTPRequestFilter()
        filter.minResponseTime = 0.5
        filter.maxResponseTime = 5.0
        let request = makeRequest(totalDuration: "2.0 (s)")

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertTrue(result)
    }

    func testMatches_responseTimeRangeFilter_outOfRange_returnsFalse() {
        // Given
        var filter = HTTPRequestFilter()
        filter.minResponseTime = 0.5
        filter.maxResponseTime = 1.0
        let request = makeRequest(totalDuration: "5.0 (s)")

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - matches: size filter

    func testMatches_minSizeFilter_meetingMinimum_returnsTrue() {
        // Given
        var filter = HTTPRequestFilter()
        filter.minSize = 10
        let request = makeRequest(responseData: Data(repeating: 0, count: 20))

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertTrue(result)
    }

    func testMatches_minSizeFilter_belowMinimum_returnsFalse() {
        // Given
        var filter = HTTPRequestFilter()
        filter.minSize = 100
        let request = makeRequest(responseData: Data(repeating: 0, count: 10))

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertFalse(result)
    }

    func testMatches_maxSizeFilter_meetingMaximum_returnsTrue() {
        // Given
        var filter = HTTPRequestFilter()
        filter.maxSize = 100
        let request = makeRequest(responseData: Data(repeating: 0, count: 50))

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertTrue(result)
    }

    func testMatches_maxSizeFilter_aboveMaximum_returnsFalse() {
        // Given
        var filter = HTTPRequestFilter()
        filter.maxSize = 10
        let request = makeRequest(responseData: Data(repeating: 0, count: 20))

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertFalse(result)
    }

    func testMatches_minSizeFilter_nilResponseData_returnsFalse() {
        // Given
        var filter = HTTPRequestFilter()
        filter.minSize = 1
        let request = makeRequest(responseData: nil)

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - matches: error/success filter

    func testMatches_showOnlyErrors_errorRequest_returnsTrue() {
        // Given
        var filter = HTTPRequestFilter()
        filter.showOnlyErrors = true
        let request = makeRequest(errorDescription: "Connection refused")

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertTrue(result)
    }

    func testMatches_showOnlyErrors_successRequest_returnsFalse() {
        // Given
        var filter = HTTPRequestFilter()
        filter.showOnlyErrors = true
        let request = makeRequest(errorDescription: nil)

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertFalse(result)
    }

    func testMatches_showOnlySuccessful_successRequest_returnsTrue() {
        // Given
        var filter = HTTPRequestFilter()
        filter.showOnlySuccessful = true
        let request = makeRequest(errorDescription: nil)

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertTrue(result)
    }

    func testMatches_showOnlySuccessful_errorRequest_returnsFalse() {
        // Given
        var filter = HTTPRequestFilter()
        filter.showOnlySuccessful = true
        let request = makeRequest(errorDescription: "Connection refused")

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - matches: host filter

    func testMatches_hostFilter_matchingHost_returnsTrue() {
        // Given
        var filter = HTTPRequestFilter()
        filter.hostFilters = ["example.com"]
        let request = makeRequest(urlString: "https://api.example.com/users")

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertTrue(result)
    }

    func testMatches_hostFilter_nonMatchingHost_returnsFalse() {
        // Given
        var filter = HTTPRequestFilter()
        filter.hostFilters = ["other.com"]
        let request = makeRequest(urlString: "https://api.example.com/users")

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - matches: time range filter

    func testMatches_timeRangeLastHour_recentRequest_returnsTrue() {
        // Given
        var filter = HTTPRequestFilter()
        filter.timeRange = .lastHour
        let recentDate = Date().addingTimeInterval(-300) // 5 minutes ago
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let request = makeRequest(startTime: formatter.string(from: recentDate))

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertTrue(result)
    }

    func testMatches_timeRangeLastHour_oldRequest_returnsFalse() {
        // Given
        var filter = HTTPRequestFilter()
        filter.timeRange = .lastHour
        let oldDate = Date().addingTimeInterval(-7200) // 2 hours ago
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let request = makeRequest(startTime: formatter.string(from: oldDate))

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertFalse(result)
    }

    func testMatches_timeRangeCustom_withinRange_returnsTrue() {
        // Given
        var filter = HTTPRequestFilter()
        let start = Date().addingTimeInterval(-600)
        let end = Date().addingTimeInterval(600)
        filter.timeRange = .custom(start: start, end: end)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let request = makeRequest(startTime: formatter.string(from: Date()))

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertTrue(result)
    }

    func testMatches_timeRangeCustom_outsideRange_returnsFalse() {
        // Given
        var filter = HTTPRequestFilter()
        let start = Date().addingTimeInterval(-1200)
        let end = Date().addingTimeInterval(-600)
        filter.timeRange = .custom(start: start, end: end)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let request = makeRequest(startTime: formatter.string(from: Date()))

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertFalse(result)
    }

    func testMatches_timeRange_nilStartTime_returnsFalse() {
        // Given
        var filter = HTTPRequestFilter()
        filter.timeRange = .lastHour
        let request = makeRequest(startTime: nil)

        // When
        let result = filter.matches(request)

        // Then
        XCTAssertFalse(result)
    }
}

// MARK: - StatusCodeRangeTests

final class StatusCodeRangeTests: XCTestCase {

    func testContains_codeInRange_returnsTrue() {
        // Given
        let range = StatusCodeRange(min: 200, max: 299, name: "2xx")

        // Then
        XCTAssertTrue(range.contains(200))
        XCTAssertTrue(range.contains(250))
        XCTAssertTrue(range.contains(299))
    }

    func testContains_codeOutOfRange_returnsFalse() {
        // Given
        let range = StatusCodeRange(min: 200, max: 299, name: "2xx")

        // Then
        XCTAssertFalse(range.contains(199))
        XCTAssertFalse(range.contains(300))
    }

    func testStaticRanges_success() {
        XCTAssertTrue(StatusCodeRange.success.contains(200))
        XCTAssertTrue(StatusCodeRange.success.contains(299))
        XCTAssertFalse(StatusCodeRange.success.contains(300))
    }

    func testStaticRanges_redirection() {
        XCTAssertTrue(StatusCodeRange.redirection.contains(301))
        XCTAssertFalse(StatusCodeRange.redirection.contains(200))
    }

    func testStaticRanges_clientError() {
        XCTAssertTrue(StatusCodeRange.clientError.contains(404))
        XCTAssertFalse(StatusCodeRange.clientError.contains(500))
    }

    func testStaticRanges_serverError() {
        XCTAssertTrue(StatusCodeRange.serverError.contains(500))
        XCTAssertFalse(StatusCodeRange.serverError.contains(404))
    }

    func testAllRanges_containsFourRanges() {
        XCTAssertEqual(StatusCodeRange.allRanges.count, 4)
    }
}

// MARK: - TimeRangeTests

final class TimeRangeTests: XCTestCase {

    func testDisplayName_lastHour() {
        // Given
        let range = TimeRange.lastHour

        // Then
        XCTAssertEqual(range.displayName, "Last Hour")
    }

    func testDisplayName_lastDay() {
        // Given
        let range = TimeRange.lastDay

        // Then
        XCTAssertEqual(range.displayName, "Last Day")
    }

    func testDisplayName_custom() {
        // Given
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 1, day: 2))!
        let range = TimeRange.custom(start: start, end: end)

        // When
        let displayName = range.displayName

        // Then
        XCTAssertFalse(displayName.isEmpty)
        XCTAssertTrue(displayName.contains(" - "))
    }
}
