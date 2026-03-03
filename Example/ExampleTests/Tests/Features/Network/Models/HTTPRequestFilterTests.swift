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

    private func makeModel(
        method: String? = "GET",
        statusCode: String? = "200",
        mimeType: String? = "application/json",
        totalDuration: String? = "1.0 (s)",
        responseData: Data? = nil,
        errorDescription: String? = nil,
        url: URL? = URL(string: "https://api.example.com/users"),
        startTime: String? = nil
    ) -> HttpModel {
        let model = HttpModel()
        model.method = method
        model.statusCode = statusCode
        model.mineType = mimeType
        model.totalDuration = totalDuration
        model.responseData = responseData
        model.errorDescription = errorDescription
        model.url = url
        model.startTime = startTime
        return model
    }

    private func timestamp(minutesAgo: Double) -> String {
        let date = Date().addingTimeInterval(-minutesAgo * 60)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }

    // MARK: - isActive Tests

    func testIsActive_whenEmpty_returnsFalse() {
        let filter = HTTPRequestFilter()
        XCTAssertFalse(filter.isActive)
    }

    func testIsActive_whenMethodsSet_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.methods = ["GET"]
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_whenStatusCodeRangesSet_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.statusCodeRanges = [.success]
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_whenContentTypesSet_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.contentTypes = ["application/json"]
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_whenMinResponseTimeSet_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.minResponseTime = 0.5
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_whenMaxResponseTimeSet_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.maxResponseTime = 5.0
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_whenMinSizeSet_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.minSize = 100
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_whenMaxSizeSet_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.maxSize = 1024
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_whenShowOnlyErrorsTrue_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.showOnlyErrors = true
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_whenShowOnlySuccessfulTrue_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.showOnlySuccessful = true
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_whenHostFiltersSet_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.hostFilters = ["example.com"]
        XCTAssertTrue(filter.isActive)
    }

    func testIsActive_whenTimeRangeSet_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.timeRange = .lastHour
        XCTAssertTrue(filter.isActive)
    }

    // MARK: - matches: no filters

    func testMatches_whenNoFilters_returnsTrue() {
        let filter = HTTPRequestFilter()
        let model = makeModel()
        XCTAssertTrue(filter.matches(model))
    }

    // MARK: - matches: method filter

    func testMatches_methodFilter_whenMethodMatches_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.methods = ["GET", "POST"]
        let model = makeModel(method: "GET")
        XCTAssertTrue(filter.matches(model))
    }

    func testMatches_methodFilter_whenMethodDoesNotMatch_returnsFalse() {
        var filter = HTTPRequestFilter()
        filter.methods = ["POST"]
        let model = makeModel(method: "GET")
        XCTAssertFalse(filter.matches(model))
    }

    func testMatches_methodFilter_whenMethodIsNil_returnsFalse() {
        var filter = HTTPRequestFilter()
        filter.methods = ["GET"]
        let model = makeModel(method: nil)
        XCTAssertFalse(filter.matches(model))
    }

    // MARK: - matches: status code filter

    func testMatches_statusCodeFilter_whenCodeInRange_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.statusCodeRanges = [.success]
        let model = makeModel(statusCode: "200")
        XCTAssertTrue(filter.matches(model))
    }

    func testMatches_statusCodeFilter_whenCodeNotInRange_returnsFalse() {
        var filter = HTTPRequestFilter()
        filter.statusCodeRanges = [.success]
        let model = makeModel(statusCode: "404")
        XCTAssertFalse(filter.matches(model))
    }

    func testMatches_statusCodeFilter_whenStatusCodeIsNil_returnsFalse() {
        var filter = HTTPRequestFilter()
        filter.statusCodeRanges = [.success]
        let model = makeModel(statusCode: nil)
        XCTAssertFalse(filter.matches(model))
    }

    func testMatches_statusCodeFilter_matchesAcrossMultipleRanges() {
        var filter = HTTPRequestFilter()
        filter.statusCodeRanges = [.success, .clientError]
        let successModel = makeModel(statusCode: "201")
        let errorModel = makeModel(statusCode: "400")
        let serverErrorModel = makeModel(statusCode: "500")
        XCTAssertTrue(filter.matches(successModel))
        XCTAssertTrue(filter.matches(errorModel))
        XCTAssertFalse(filter.matches(serverErrorModel))
    }

    // MARK: - matches: content type filter

    func testMatches_contentTypeFilter_whenTypeMatches_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.contentTypes = ["application/json"]
        let model = makeModel(mimeType: "application/json; charset=utf-8")
        XCTAssertTrue(filter.matches(model))
    }

    func testMatches_contentTypeFilter_caseInsensitive_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.contentTypes = ["Application/JSON"]
        let model = makeModel(mimeType: "application/json")
        XCTAssertTrue(filter.matches(model))
    }

    func testMatches_contentTypeFilter_whenTypeDoesNotMatch_returnsFalse() {
        var filter = HTTPRequestFilter()
        filter.contentTypes = ["text/html"]
        let model = makeModel(mimeType: "application/json")
        XCTAssertFalse(filter.matches(model))
    }

    func testMatches_contentTypeFilter_whenMimeTypeIsNil_returnsFalse() {
        var filter = HTTPRequestFilter()
        filter.contentTypes = ["application/json"]
        let model = makeModel(mimeType: nil)
        XCTAssertFalse(filter.matches(model))
    }

    // MARK: - matches: response time filter

    func testMatches_minResponseTimeFilter_whenDurationMeetsMin_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.minResponseTime = 0.5
        let model = makeModel(totalDuration: "1.0 (s)")
        XCTAssertTrue(filter.matches(model))
    }

    func testMatches_minResponseTimeFilter_whenDurationBelowMin_returnsFalse() {
        var filter = HTTPRequestFilter()
        filter.minResponseTime = 2.0
        let model = makeModel(totalDuration: "1.0 (s)")
        XCTAssertFalse(filter.matches(model))
    }

    func testMatches_maxResponseTimeFilter_whenDurationMeetsMax_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.maxResponseTime = 5.0
        let model = makeModel(totalDuration: "1.0 (s)")
        XCTAssertTrue(filter.matches(model))
    }

    func testMatches_maxResponseTimeFilter_whenDurationExceedsMax_returnsFalse() {
        var filter = HTTPRequestFilter()
        filter.maxResponseTime = 0.5
        let model = makeModel(totalDuration: "1.0 (s)")
        XCTAssertFalse(filter.matches(model))
    }

    func testMatches_bothResponseTimeFilters_whenInRange_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.minResponseTime = 0.5
        filter.maxResponseTime = 2.0
        let model = makeModel(totalDuration: "1.0 (s)")
        XCTAssertTrue(filter.matches(model))
    }

    func testMatches_bothResponseTimeFilters_whenOutOfRange_returnsFalse() {
        var filter = HTTPRequestFilter()
        filter.minResponseTime = 0.5
        filter.maxResponseTime = 2.0
        let model = makeModel(totalDuration: "3.0 (s)")
        XCTAssertFalse(filter.matches(model))
    }

    // MARK: - matches: size filter

    func testMatches_minSizeFilter_whenSizeMeetsMin_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.minSize = 5
        let model = makeModel(responseData: Data(repeating: 0, count: 10))
        XCTAssertTrue(filter.matches(model))
    }

    func testMatches_minSizeFilter_whenSizeBelowMin_returnsFalse() {
        var filter = HTTPRequestFilter()
        filter.minSize = 20
        let model = makeModel(responseData: Data(repeating: 0, count: 10))
        XCTAssertFalse(filter.matches(model))
    }

    func testMatches_maxSizeFilter_whenSizeMeetsMax_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.maxSize = 100
        let model = makeModel(responseData: Data(repeating: 0, count: 10))
        XCTAssertTrue(filter.matches(model))
    }

    func testMatches_maxSizeFilter_whenSizeExceedsMax_returnsFalse() {
        var filter = HTTPRequestFilter()
        filter.maxSize = 5
        let model = makeModel(responseData: Data(repeating: 0, count: 10))
        XCTAssertFalse(filter.matches(model))
    }

    // MARK: - matches: showOnlyErrors / showOnlySuccessful

    func testMatches_showOnlyErrors_whenRequestIsSuccess_returnsFalse() {
        var filter = HTTPRequestFilter()
        filter.showOnlyErrors = true
        let model = makeModel(errorDescription: nil)
        XCTAssertFalse(filter.matches(model))
    }

    func testMatches_showOnlyErrors_whenRequestIsError_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.showOnlyErrors = true
        let model = makeModel(errorDescription: "Connection refused")
        XCTAssertTrue(filter.matches(model))
    }

    func testMatches_showOnlySuccessful_whenRequestIsSuccess_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.showOnlySuccessful = true
        let model = makeModel(errorDescription: nil)
        XCTAssertTrue(filter.matches(model))
    }

    func testMatches_showOnlySuccessful_whenRequestIsError_returnsFalse() {
        var filter = HTTPRequestFilter()
        filter.showOnlySuccessful = true
        let model = makeModel(errorDescription: "Connection refused")
        XCTAssertFalse(filter.matches(model))
    }

    // MARK: - matches: host filter

    func testMatches_hostFilter_whenHostMatches_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.hostFilters = ["api.example.com"]
        let model = makeModel(url: URL(string: "https://api.example.com/users"))
        XCTAssertTrue(filter.matches(model))
    }

    func testMatches_hostFilter_whenHostDoesNotMatch_returnsFalse() {
        var filter = HTTPRequestFilter()
        filter.hostFilters = ["other.com"]
        let model = makeModel(url: URL(string: "https://api.example.com/users"))
        XCTAssertFalse(filter.matches(model))
    }

    func testMatches_hostFilter_caseInsensitive_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.hostFilters = ["API.EXAMPLE.COM"]
        let model = makeModel(url: URL(string: "https://api.example.com/users"))
        XCTAssertTrue(filter.matches(model))
    }

    func testMatches_hostFilter_whenURLIsNil_returnsFalse() {
        var filter = HTTPRequestFilter()
        filter.hostFilters = ["example.com"]
        let model = makeModel(url: nil)
        XCTAssertFalse(filter.matches(model))
    }

    // MARK: - matches: time range filter

    func testMatches_timeRange_lastHour_whenWithinHour_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.timeRange = .lastHour
        let model = makeModel(startTime: timestamp(minutesAgo: 30))
        XCTAssertTrue(filter.matches(model))
    }

    func testMatches_timeRange_lastHour_whenOlderThanHour_returnsFalse() {
        var filter = HTTPRequestFilter()
        filter.timeRange = .lastHour
        let model = makeModel(startTime: timestamp(minutesAgo: 90))
        XCTAssertFalse(filter.matches(model))
    }

    func testMatches_timeRange_lastDay_whenWithinDay_returnsTrue() {
        var filter = HTTPRequestFilter()
        filter.timeRange = .lastDay
        let model = makeModel(startTime: timestamp(minutesAgo: 60))
        XCTAssertTrue(filter.matches(model))
    }

    func testMatches_timeRange_custom_whenWithinRange_returnsTrue() {
        var filter = HTTPRequestFilter()
        let start = Date().addingTimeInterval(-7200)
        let end = Date().addingTimeInterval(-1800)
        filter.timeRange = .custom(start: start, end: end)
        let model = makeModel(startTime: timestamp(minutesAgo: 60))
        XCTAssertTrue(filter.matches(model))
    }

    func testMatches_timeRange_custom_whenOutsideRange_returnsFalse() {
        var filter = HTTPRequestFilter()
        let start = Date().addingTimeInterval(-3600)
        let end = Date().addingTimeInterval(-1800)
        filter.timeRange = .custom(start: start, end: end)
        let model = makeModel(startTime: timestamp(minutesAgo: 5))
        XCTAssertFalse(filter.matches(model))
    }

    func testMatches_timeRange_whenStartTimeIsNil_returnsFalse() {
        var filter = HTTPRequestFilter()
        filter.timeRange = .lastHour
        let model = makeModel(startTime: nil)
        XCTAssertFalse(filter.matches(model))
    }

    // MARK: - StatusCodeRange Tests

    func testStatusCodeRange_contains_whenInRange_returnsTrue() {
        let range = StatusCodeRange(min: 200, max: 299, name: "2xx")
        XCTAssertTrue(range.contains(200))
        XCTAssertTrue(range.contains(250))
        XCTAssertTrue(range.contains(299))
    }

    func testStatusCodeRange_contains_whenOutOfRange_returnsFalse() {
        let range = StatusCodeRange(min: 200, max: 299, name: "2xx")
        XCTAssertFalse(range.contains(199))
        XCTAssertFalse(range.contains(300))
    }

    func testStatusCodeRange_staticRanges_haveCorrectBounds() {
        XCTAssertEqual(StatusCodeRange.success.min, 200)
        XCTAssertEqual(StatusCodeRange.success.max, 299)
        XCTAssertEqual(StatusCodeRange.redirection.min, 300)
        XCTAssertEqual(StatusCodeRange.redirection.max, 399)
        XCTAssertEqual(StatusCodeRange.clientError.min, 400)
        XCTAssertEqual(StatusCodeRange.clientError.max, 499)
        XCTAssertEqual(StatusCodeRange.serverError.min, 500)
        XCTAssertEqual(StatusCodeRange.serverError.max, 599)
    }

    func testStatusCodeRange_allRanges_containsFourRanges() {
        XCTAssertEqual(StatusCodeRange.allRanges.count, 4)
    }

    // MARK: - TimeRange displayName Tests

    func testTimeRange_displayName_lastHour() {
        XCTAssertEqual(TimeRange.lastHour.displayName, "Last Hour")
    }

    func testTimeRange_displayName_lastDay() {
        XCTAssertEqual(TimeRange.lastDay.displayName, "Last Day")
    }

    func testTimeRange_displayName_custom_containsDates() {
        let start = Date(timeIntervalSince1970: 0)
        let end = Date(timeIntervalSince1970: 86400)
        let displayName = TimeRange.custom(start: start, end: end).displayName
        XCTAssertFalse(displayName.isEmpty)
        XCTAssertTrue(displayName.contains(" - "))
    }
}
