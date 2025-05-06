//
//  HttpDatasourceTests.swift
//  DebugSwift
//
//  Created by Steven Lewi on 01/05/25.
//

import XCTest
@testable import DebugSwift

final class HttpDatasourceTests: XCTestCase {

    private final let httpDataSource = HttpDatasource()

    func testAddHttpRequest_onlyURLs() {
        // Given
        DebugSwift.Network.onlyURLs = [
            "www.example.com",
            "github.com",
            "https://cocoapods.org"
        ]

        // When
        let httpModel = HttpModel()
        httpModel.url = URL(string: "https://github.com/DebugSwift/DebugSwift")!
        let isAddedUrl1 = httpDataSource.addHttpRequest(httpModel)

        let httpModel2 = HttpModel()
        httpModel2.url = URL(string: "https://google.com/")!
        let isAddedUrl2 = httpDataSource.addHttpRequest(httpModel2)

        // Then
        XCTAssertTrue(isAddedUrl1)
        XCTAssertFalse(isAddedUrl2)
    }

    func testAddHttpRequest_ignoredURLs() {
        // Given
        DebugSwift.Network.ignoredURLs = [
            "www.example.com",
            "github.com",
            "https://cocoapods.org"
        ]

        // When
        let httpModel = HttpModel()
        httpModel.url = URL(string: "https://google.com/q=DebugSwift")!
        let isAddedUrl1 = httpDataSource.addHttpRequest(httpModel)

        let httpModel2 = HttpModel()
        httpModel2.url = URL(string: "https://github.com/DebugSwift/DebugSwift")!
        let isAddedUrl2 = httpDataSource.addHttpRequest(httpModel2)

        // Then
        XCTAssertTrue(isAddedUrl1)
        XCTAssertFalse(isAddedUrl2)
    }
}
