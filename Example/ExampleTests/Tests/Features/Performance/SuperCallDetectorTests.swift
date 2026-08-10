//
//  SuperCallDetectorTests.swift
//  ExampleTests
//
//  Tests for issue #376: detect lifecycle methods not calling super.
//

import XCTest
@testable import DebugSwift

final class SuperCallDetectorTests: XCTestCase {

    override func setUp() {
        super.setUp()
        SuperCallDetector.shared.clearViolations()
        SuperCallDetector.shared.callback = nil
        SuperCallDetector.shared.setIgnoredClasses([])
    }

    override func tearDown() {
        SuperCallDetector.shared.clearViolations()
        SuperCallDetector.shared.callback = nil
        SuperCallDetector.shared.setIgnoredClasses([])
        super.tearDown()
    }

    // MARK: - Violation recording

    func testReportViolationStoresViolation() {
        let violation = SuperCallViolation(
            className: "TestVC",
            methodName: "viewDidLoad",
            revealedBy: "viewWillAppear"
        )
        SuperCallDetector.shared.reportViolation(violation)

        XCTAssertEqual(SuperCallDetector.shared.violations.count, 1)
        XCTAssertEqual(SuperCallDetector.shared.violations.first?.className, "TestVC")
        XCTAssertEqual(SuperCallDetector.shared.violations.first?.methodName, "viewDidLoad")
    }

    func testDuplicateViolationsAreDeduplicated() {
        let v1 = SuperCallViolation(className: "TestVC", methodName: "viewDidLoad", revealedBy: "viewWillAppear")
        let v2 = SuperCallViolation(className: "TestVC", methodName: "viewDidLoad", revealedBy: "viewDidAppear")

        SuperCallDetector.shared.reportViolation(v1)
        SuperCallDetector.shared.reportViolation(v2)

        XCTAssertEqual(SuperCallDetector.shared.violations.count, 1)
    }

    func testDifferentClassesProduceSeparateViolations() {
        let v1 = SuperCallViolation(className: "VC1", methodName: "viewDidLoad", revealedBy: "viewWillAppear")
        let v2 = SuperCallViolation(className: "VC2", methodName: "viewDidLoad", revealedBy: "viewWillAppear")

        SuperCallDetector.shared.reportViolation(v1)
        SuperCallDetector.shared.reportViolation(v2)

        XCTAssertEqual(SuperCallDetector.shared.violations.count, 2)
    }

    func testDifferentMethodsProduceSeparateViolations() {
        let v1 = SuperCallViolation(className: "TestVC", methodName: "viewDidLoad", revealedBy: "viewWillAppear")
        let v2 = SuperCallViolation(className: "TestVC", methodName: "viewDidAppear", revealedBy: "viewWillDisappear")

        SuperCallDetector.shared.reportViolation(v1)
        SuperCallDetector.shared.reportViolation(v2)

        XCTAssertEqual(SuperCallDetector.shared.violations.count, 2)
    }

    // MARK: - Clear

    func testClearViolationsRemovesAll() {
        let violation = SuperCallViolation(className: "TestVC", methodName: "viewDidLoad", revealedBy: "viewWillAppear")
        SuperCallDetector.shared.reportViolation(violation)
        XCTAssertEqual(SuperCallDetector.shared.violations.count, 1)

        SuperCallDetector.shared.clearViolations()
        XCTAssertTrue(SuperCallDetector.shared.violations.isEmpty)
    }

    // MARK: - Ignore list

    func testIgnoredClassIsNotRecorded() {
        SuperCallDetector.shared.ignoreClass("IgnoredVC")
        let violation = SuperCallViolation(className: "IgnoredVC", methodName: "viewDidLoad", revealedBy: "viewWillAppear")
        SuperCallDetector.shared.reportViolation(violation)

        XCTAssertTrue(SuperCallDetector.shared.violations.isEmpty)
    }

    func testSetIgnoredClassesReplacesList() {
        SuperCallDetector.shared.ignoreClass("VC1")
        SuperCallDetector.shared.setIgnoredClasses(["VC2", "VC3"])

        // VC1 should no longer be ignored after setIgnoredClasses replaces the set
        let v1 = SuperCallViolation(className: "VC1", methodName: "viewDidLoad", revealedBy: "viewWillAppear")
        SuperCallDetector.shared.reportViolation(v1)
        XCTAssertEqual(SuperCallDetector.shared.violations.count, 1)

        // VC2 should be ignored
        let v2 = SuperCallViolation(className: "VC2", methodName: "viewDidLoad", revealedBy: "viewWillAppear")
        SuperCallDetector.shared.reportViolation(v2)
        XCTAssertEqual(SuperCallDetector.shared.violations.count, 1)
    }

    // MARK: - Callback

    func testCallbackFiresForNewViolation() {
        let expectation = XCTestExpectation(description: "callback")
        SuperCallDetector.shared.callback = { violation in
            guard violation.className == "TestVC" else { return }
            XCTAssertEqual(violation.className, "TestVC")
            expectation.fulfill()
        }

        let violation = SuperCallViolation(className: "TestVC", methodName: "viewDidLoad", revealedBy: "viewWillAppear")
        SuperCallDetector.shared.reportViolation(violation)

        wait(for: [expectation], timeout: 1.0)
    }

    func testCallbackDoesNotFireForDuplicate() {
        let expectation = XCTestExpectation(description: "callback should fire once")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true

        SuperCallDetector.shared.callback = { violation in
            guard violation.className == "TestVC" else { return }
            expectation.fulfill()
        }

        let v1 = SuperCallViolation(className: "TestVC", methodName: "viewDidLoad", revealedBy: "viewWillAppear")
        let v2 = SuperCallViolation(className: "TestVC", methodName: "viewDidLoad", revealedBy: "viewDidAppear")

        SuperCallDetector.shared.reportViolation(v1)
        SuperCallDetector.shared.reportViolation(v2)

        wait(for: [expectation], timeout: 1.0)
    }

    func testCallbackDoesNotFireForIgnored() {
        let expectation = XCTestExpectation(description: "callback should not fire")
        expectation.isInverted = true

        SuperCallDetector.shared.callback = { violation in
            guard violation.className == "IgnoredVC" else { return }
            expectation.fulfill()
        }

        SuperCallDetector.shared.ignoreClass("IgnoredVC")
        let violation = SuperCallViolation(className: "IgnoredVC", methodName: "viewDidLoad", revealedBy: "viewWillAppear")
        SuperCallDetector.shared.reportViolation(violation)

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - SuperCallViolation message

    func testViolationMessageFormat() {
        let v = SuperCallViolation(className: "MyVC", methodName: "viewDidLoad", revealedBy: "viewWillAppear")
        XCTAssertEqual(v.message, "MyVC does not call super.viewDidLoad() — revealed by viewWillAppear()")
    }

    // MARK: - LifecycleEvent

    func testLifecycleEventOrder() {
        XCTAssertEqual(LifecycleEvent.viewDidLoad.rawValue, 0)
        XCTAssertEqual(LifecycleEvent.viewWillAppear.rawValue, 1)
        XCTAssertEqual(LifecycleEvent.viewDidAppear.rawValue, 2)
        XCTAssertEqual(LifecycleEvent.viewWillDisappear.rawValue, 3)
        XCTAssertEqual(LifecycleEvent.viewDidDisappear.rawValue, 4)
    }

    func testLifecycleEventAllCasesCount() {
        XCTAssertEqual(LifecycleEvent.allCases.count, 5)
    }

    // MARK: - Public API: SuperCallChecker

    func testPublicAPIViolationsMirrorDetector() {
        let violation = SuperCallViolation(className: "TestVC", methodName: "viewDidLoad", revealedBy: "viewWillAppear")
        SuperCallDetector.shared.reportViolation(violation)

        XCTAssertEqual(DebugSwift.Performance.SuperCallChecker.violations.count, 1)
    }

    func testPublicAPIClearViolations() {
        let violation = SuperCallViolation(className: "TestVC", methodName: "viewDidLoad", revealedBy: "viewWillAppear")
        SuperCallDetector.shared.reportViolation(violation)

        DebugSwift.Performance.SuperCallChecker.clearViolations()
        XCTAssertTrue(DebugSwift.Performance.SuperCallChecker.violations.isEmpty)
    }

    func testPublicAPIIgnoreClass() {
        DebugSwift.Performance.SuperCallChecker.ignoreClass("PublicIgnoredVC")
        let violation = SuperCallViolation(className: "PublicIgnoredVC", methodName: "viewDidLoad", revealedBy: "viewWillAppear")
        SuperCallDetector.shared.reportViolation(violation)

        XCTAssertTrue(DebugSwift.Performance.SuperCallChecker.violations.isEmpty)
    }

    func testPublicAPISetIgnoredClasses() {
        DebugSwift.Performance.SuperCallChecker.setIgnoredClasses(["A", "B"])
        let v = SuperCallViolation(className: "A", methodName: "viewDidLoad", revealedBy: "viewWillAppear")
        SuperCallDetector.shared.reportViolation(v)

        XCTAssertTrue(DebugSwift.Performance.SuperCallChecker.violations.isEmpty)
    }

    // MARK: - End-to-end: real VC lifecycle

    /// Swizzle must be installed for these tests. The FeatureHandling
    /// setup runs at app launch, but in the test host it may not have
    /// run yet, so we install it explicitly.
    override class func setUp() {
        UIViewController.db_swizzleLifecycleForSuperCallDetection()
    }

    /// A VC that calls super in every lifecycle method — no violations.
    private class GoodVC: UIViewController {
        override func viewDidLoad() { super.viewDidLoad() }
        override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated) }
        override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated) }
        override func viewWillDisappear(_ animated: Bool) { super.viewWillDisappear(animated) }
        override func viewDidDisappear(_ animated: Bool) { super.viewDidDisappear(animated) }
    }

    /// A VC that skips super.viewDidLoad() — should produce a violation
    /// when viewWillAppear fires.
    private class BadViewDidLoadVC: UIViewController {
        override func viewDidLoad() {
            // Intentionally does NOT call super.viewDidLoad()
        }
        override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated) }
    }

    /// A VC that skips super.viewDidAppear() — should produce a violation
    /// when viewWillDisappear fires.
    private class BadViewDidAppearVC: UIViewController {
        override func viewDidLoad() { super.viewDidLoad() }
        override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated) }
        override func viewDidAppear(_ animated: Bool) {
            // Intentionally does NOT call super.viewDidAppear()
        }
        override func viewWillDisappear(_ animated: Bool) { super.viewWillDisappear(animated) }
    }

    func testGoodVcProducesNoViolations() {
        let before = SuperCallDetector.shared.violations.count
        let vc = GoodVC()
        vc.viewDidLoad()
        vc.viewWillAppear(false)
        vc.viewDidAppear(false)
        vc.viewWillDisappear(false)
        vc.viewDidDisappear(false)
        let after = SuperCallDetector.shared.violations.count
        XCTAssertEqual(after, before, "GoodVC should not produce violations")
    }

    func testBadViewDidLoadProducesViolation() {
        let before = SuperCallDetector.shared.violations.count
        let vc = BadViewDidLoadVC()
        vc.viewDidLoad()
        vc.viewWillAppear(false)
        let after = SuperCallDetector.shared.violations.count

        let newViolations = SuperCallDetector.shared.violations.dropFirst(before)
        XCTAssertTrue(newViolations.contains {
            $0.methodName == "viewDidLoad" && $0.revealedBy == "viewWillAppear"
        }, "BadViewDidLoadVC should produce a viewDidLoad violation revealed by viewWillAppear")
    }

    func testBadViewDidAppearProducesViolation() {
        let before = SuperCallDetector.shared.violations.count
        let vc = BadViewDidAppearVC()
        vc.viewDidLoad()
        vc.viewWillAppear(false)
        vc.viewDidAppear(false)
        vc.viewWillDisappear(false)
        let after = SuperCallDetector.shared.violations.count

        let newViolations = SuperCallDetector.shared.violations.dropFirst(before)
        XCTAssertTrue(newViolations.contains {
            $0.methodName == "viewDidAppear" && $0.revealedBy == "viewWillDisappear"
        }, "BadViewDidAppearVC should produce a viewDidAppear violation revealed by viewWillDisappear")
    }
}
