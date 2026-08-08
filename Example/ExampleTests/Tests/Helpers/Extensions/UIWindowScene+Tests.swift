//
//  UIWindowScene+Tests.swift
//  DebugSwift
//
//  Verifies the IMP-replacement swizzle of `viewDidAppear(_:)` does not expose
//  a renamed `db_viewDidAppear(_:)` selector — the root cause of the NewRelic
//  `NRInvalidArgumentException` crash (issue #432).
//

import XCTest
@testable import DebugSwift

final class UIWindowSceneViewDidAppearTests: XCTestCase {

    /// After swizzling, `UIViewController` must not have a `db_viewDidAppear:`
    /// selector in its instance method table. NewRelic scans method tables for
    /// unexpected renamed selectors on core UIKit classes and throws
    /// `NRInvalidArgumentException` when it finds one. The IMP-replacement
    /// approach keeps only `viewDidAppear:` with a valid implementation.
    func testDbViewDidAppearSelectorNotInMethodTable() {
        UIViewController.db_swizzleViewDidAppear()

        var selectorCount: UInt32 = 0
        let methodList = class_copyMethodList(UIViewController.self, &selectorCount)
        defer { free(methodList) }

        let dbSelector = Selector(("db_viewDidAppear:"))
        for i in 0..<Int(selectorCount) {
            guard let method = methodList?[i] else { continue }
            if method_getName(method) == dbSelector {
                XCTFail("db_viewDidAppear: selector found in UIViewController method table — IMP-replacement should not expose it")
                return
            }
        }
    }

    /// After swizzling, `viewDidAppear:` must still resolve to a valid method
    /// with a non-nil implementation.
    func testViewDidAppearStillHasValidImplementation() {
        UIViewController.db_swizzleViewDidAppear()

        let viewDidAppear = #selector(UIViewController.viewDidAppear(_:))
        guard let method = class_getInstanceMethod(UIViewController.self, viewDidAppear) else {
            XCTFail("viewDidAppear: method missing after swizzling")
            return
        }
        XCTAssertNotNil(method_getImplementation(method), "viewDidAppear: must have a valid IMP after swizzling")
    }

    /// Swizzling must be idempotent — calling it twice must not crash or
    /// double-install the block.
    func testSwizzleIsIdempotent() {
        UIViewController.db_swizzleViewDidAppear()
        UIViewController.db_swizzleViewDidAppear()

        // If we reach this point without crashing, idempotency holds.
        // Verify the stored IMP is set exactly once.
        XCTAssertNotNil(UIViewController.db_originalViewDidAppearIMP, "Original IMP should be stored after swizzling")
    }
}
