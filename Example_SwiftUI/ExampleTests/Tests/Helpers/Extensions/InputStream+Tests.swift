//
//  InputStream+Tests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/2024.
//

import XCTest
@testable import DebugSwift

final class InputStreamTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testToDataWithValidInputStream() throws {
        // Given
        let string = "Hello, world!"
        let data = string.data(using: .utf8)!
        let inputStream = InputStream(data: data)

        // When
        let resultData = inputStream.toData()

        // Then
        XCTAssertEqual(resultData, data, "The data should match the original input data.")
    }

    func testToDataWithEmptyInputStream() throws {
        // Given
        let data = Data()
        let inputStream = InputStream(data: data)

        // When
        let resultData = inputStream.toData()

        // Then
        XCTAssertEqual(resultData, data, "The data should be empty.")
    }

    func testToDataWithLargeInputStream() throws {
        // Given
        let string = String(repeating: "A", count: 10_000)
        let data = string.data(using: .utf8)!
        let inputStream = InputStream(data: data)

        // When
        let resultData = inputStream.toData()

        // Then
        XCTAssertEqual(resultData, data, "The data should match the original large input data.")
    }

    func testToDataWithError() throws {
        // Given
        let inputStream = InputStream(data: Data())
        inputStream.close() // Force an error state

        // When
        let resultData = inputStream.toData()

        // Then
        XCTAssertEqual(resultData, Data(), "The data should be empty when an error occurs.")
    }
}
