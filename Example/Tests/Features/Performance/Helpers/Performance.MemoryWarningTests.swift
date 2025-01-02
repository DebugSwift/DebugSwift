//
//  Performance.MemoryWarningTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 27/12/2024.
//

import XCTest
@testable import DebugSwift

class PerformanceMemoryWarningTests: XCTestCase {

    func testGenerateMemoryWarning() {
        // Given
        let app = UIApplication.shared
        let selector = Selector(("_performMemoryWarning"))

        // When
        PerformanceMemoryWarning.generate()

        // Then
        XCTAssertTrue(app.responds(to: selector), "UIApplication should respond to _performMemoryWarning selector")
    }
}
