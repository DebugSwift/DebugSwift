//
//  SwizzleManagerTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/2024.
//

import XCTest
@testable import DebugSwift

final class SwizzleManagerTests: XCTestCase {

    class TestClass: NSObject {
        @objc dynamic func originalMethod() -> String {
            return "original"
        }

        @objc dynamic func swizzledMethod() -> String {
            return "swizzled"
        }
    }

    func testSwizzleMethods() {
        // Given
        let testObject = TestClass()
        let originalSelector = #selector(TestClass.originalMethod)
        let swizzledSelector = #selector(TestClass.swizzledMethod)

        // When
        SwizzleManager.swizzle(TestClass.self, originalSelector: originalSelector, swizzledSelector: swizzledSelector)
        let originalResult = testObject.originalMethod()
        let swizzledResult = testObject.swizzledMethod()

        // Then
        XCTAssertEqual(originalResult, "swizzled", "The original method should return 'swizzled' after swizzling")
        XCTAssertEqual(swizzledResult, "original", "The swizzled method should return 'original' after swizzling")
    }
}
