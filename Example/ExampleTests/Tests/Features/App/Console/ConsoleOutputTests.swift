//
//  ConsoleOutputTests.swift
//  DebugSwift
//
//  Created by DebugSwift on 2026.
//

import XCTest
@testable import DebugSwift

final class ConsoleOutputTests: XCTestCase {

    var sut: ConsoleOutput!

    override func setUp() {
        super.setUp()
        sut = ConsoleOutput.shared
        sut.removeAll()
    }

    override func tearDown() {
        sut.removeAll()
        super.tearDown()
    }

    // MARK: - Print/NSLog Output Tests

    func testAddPrintAndNSLogOutputAppendsToList() {
        // Given
        let message = "Test message"

        // When
        sut.addPrintAndNSLogOutput(message)

        // Then
        let output = sut.getPrintAndNSLogOutput()
        XCTAssertTrue(output.contains(message))
    }

    func testAddMultiplePrintAndNSLogOutputAppendsAll() {
        // Given
        let messages = ["First message", "Second message", "Third message"]

        // When
        messages.forEach { sut.addPrintAndNSLogOutput($0) }

        // Then
        let output = sut.getPrintAndNSLogOutput()
        for message in messages {
            XCTAssertTrue(output.contains(message))
        }
    }

    func testRemoveAllClearsPrintOutput() {
        // Given
        sut.addPrintAndNSLogOutput("Message 1")
        sut.addPrintAndNSLogOutput("Message 2")
        XCTAssertFalse(sut.getPrintAndNSLogOutput().isEmpty)

        // When
        sut.removeAll()

        // Then
        XCTAssertTrue(sut.getPrintAndNSLogOutput().isEmpty)
    }

    func testRemoveAllPrintAndNSLogOutputRemovesMatchingEntries() {
        // Given
        let targetMessage = "Target message"
        let otherMessage = "Other message"
        sut.addPrintAndNSLogOutput(targetMessage)
        sut.addPrintAndNSLogOutput(otherMessage)
        sut.addPrintAndNSLogOutput(targetMessage)

        // When
        sut.removeAllPrintAndNSLogOutput(targetMessage)

        // Then
        let output = sut.getPrintAndNSLogOutput()
        XCTAssertFalse(output.contains(targetMessage))
        XCTAssertTrue(output.contains(otherMessage))
    }

    func testRemovePrintAndNSLogOutputAtIndexRemovesEntry() {
        // Given
        sut.addPrintAndNSLogOutput("Message A")
        sut.addPrintAndNSLogOutput("Message B")
        sut.addPrintAndNSLogOutput("Message C")
        let countBefore = sut.getPrintAndNSLogOutput().count

        // When
        sut.removePrintAndNSLogOutput(at: 0)

        // Then
        let outputAfter = sut.getPrintAndNSLogOutput()
        XCTAssertEqual(outputAfter.count, countBefore - 1)
        XCTAssertFalse(outputAfter.contains("Message A"))
    }

    // MARK: - Formatted Output Tests

    func testPrintAndNSLogOutputFormattedJoinsWithNewlines() {
        // Given
        sut.addPrintAndNSLogOutput("First")
        sut.addPrintAndNSLogOutput("Second")

        // When
        let formatted = sut.printAndNSLogOutputFormatted()

        // Then
        XCTAssertTrue(formatted.contains("First"))
        XCTAssertTrue(formatted.contains("Second"))
        XCTAssertTrue(formatted.contains("\n\n"))
    }

    func testPrintAndNSLogOutputFormattedFiltersInternalDebugSwiftMessages() {
        // Given
        let regularMessage = "Regular message"
        let internalMessage = "[DebugSwift] 🚀 Internal message"
        sut.addPrintAndNSLogOutput(regularMessage)
        sut.addPrintAndNSLogOutput(internalMessage)

        // When
        let formatted = sut.printAndNSLogOutputFormatted()

        // Then
        XCTAssertTrue(formatted.contains(regularMessage))
        XCTAssertFalse(formatted.contains(internalMessage))
    }

    func testPrintAndNSLogOutputFormattedIsReversedOrder() throws {
        // Given
        sut.addPrintAndNSLogOutput("Oldest")
        sut.addPrintAndNSLogOutput("Newest")

        // When
        let formatted = sut.printAndNSLogOutputFormatted()

        // Then - newest should appear before oldest in the formatted output
        let newestRange = try XCTUnwrap(formatted.range(of: "Newest"), "Expected 'Newest' to be present in formatted output")
        let oldestRange = try XCTUnwrap(formatted.range(of: "Oldest"), "Expected 'Oldest' to be present in formatted output")
        XCTAssertLessThan(newestRange.lowerBound, oldestRange.lowerBound, "Formatted output should be in reverse order (newest first)")
    }

    func testPrintAndNSLogOutputFormattedIsEmptyWhenNoOutput() {
        // Given - setUp already calls removeAll()

        // When
        let formatted = sut.printAndNSLogOutputFormatted()

        // Then
        XCTAssertTrue(formatted.isEmpty)
    }

    // MARK: - Error Output Tests

    func testAddErrorOutputAppendsToList() {
        // Given
        let initialCount = sut.getErrorOutput().count
        let errorMessage = UUID().uuidString

        // When
        sut.addErrorOutput(errorMessage)

        // Then
        let errorOutput = sut.getErrorOutput()
        XCTAssertEqual(errorOutput.count, initialCount + 1)
        XCTAssertTrue(errorOutput.contains(errorMessage))
    }

    func testErrorOutputFormattedContainsAddedErrors() {
        // Given
        let errorMessage = UUID().uuidString

        // When
        sut.addErrorOutput(errorMessage)

        // Then
        let formatted = sut.errorOutputFormatted()
        XCTAssertTrue(formatted.contains(errorMessage))
    }

    func testErrorOutputFormattedFiltersInternalDebugSwiftMessages() {
        // Given
        let regularError = UUID().uuidString
        let internalError = "[DebugSwift] 🚀 \(UUID().uuidString)"

        // When
        sut.addErrorOutput(regularError)
        sut.addErrorOutput(internalError)

        // Then
        let formatted = sut.errorOutputFormatted()
        XCTAssertTrue(formatted.contains(regularError))
        XCTAssertFalse(formatted.contains(internalError))
    }
}
