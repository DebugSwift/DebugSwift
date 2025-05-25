//
//  Bundle+Tests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/2024.
//

import XCTest
@testable import DebugSwift

final class BundleTests: XCTestCase {

    func testModuleBundleExists() {
        // Given
        #if !SWIFT_PACKAGE
        let bundle = Bundle.module

        // When
        let resourceURL = bundle.resourceURL

        // Then
        XCTAssertNotNil(resourceURL, "The DebugSwift.bundle should exist in the module bundle")
        #endif
    }
}
