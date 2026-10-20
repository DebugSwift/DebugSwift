//
//  CrashHandlerTests.swift
//  DebugSwift
//
//  Created by gua on 2026/10/21.
//

import Darwin
import XCTest
@testable import DebugSwift

final class CrashHandlerTests: XCTestCase {
    private var details: CrashModel.Details {
        .init(name: "startup", date: .distantPast, appVersion: "cached", appBuild: "1",
              iosVersion: "cached-os", deviceModel: "cached-device", reachability: "cached-network")
    }

    private var crash: CrashModel {
        .init(type: .nsexception, details: details,
              context: .init(image: nil, consoleOutput: "", errorOutput: ""), traces: [])
    }

    private func withStore(_ body: (CrashManager) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(CrashType.nsexception.fileName))
            _ = rmdir(directory.path)
        }
        try body(CrashManager(directory: directory))
    }

    func testConstructionDoesNotReplaceStaticCallbacks() {
        let signalCallback = CrashSignalExceptionHandler.exceptionReceiveClosure
        let exceptionCallback = CrashUncaughtExceptionHandler.exceptionReceiveClosure
        defer {
            CrashSignalExceptionHandler.exceptionReceiveClosure = signalCallback
            CrashUncaughtExceptionHandler.exceptionReceiveClosure = exceptionCallback
        }
        var signalCalls = 0
        var exceptionCalls = 0
        CrashSignalExceptionHandler.exceptionReceiveClosure = { _, _, _ in signalCalls += 1 }
        CrashUncaughtExceptionHandler.exceptionReceiveClosure = { _, _, _, _ in exceptionCalls += 1 }
        _ = CrashHandler()
        _ = CrashHandler()
        CrashSignalExceptionHandler.exceptionReceiveClosure?(SIGABRT, nil, "recovered")
        CrashUncaughtExceptionHandler.callbackIfAvailable()?(nil, nil, "exception", [])
        XCTAssertEqual(signalCalls, 1)
        XCTAssertEqual(exceptionCalls, 1)
    }

    func testCombinedCallbackIsExplicitAndProcessWide() {
        let signalCallback = CrashSignalExceptionHandler.exceptionReceiveClosure
        let exceptionCallback = CrashUncaughtExceptionHandler.exceptionReceiveClosure
        defer {
            CrashSignalExceptionHandler.exceptionReceiveClosure = signalCallback
            CrashUncaughtExceptionHandler.exceptionReceiveClosure = exceptionCallback
        }
        let first = CrashHandler()
        var calls = 0
        first.exceptionReceiveClosure = { _, _, _ in calls += 1 }
        let second = CrashHandler()
        second.exceptionReceiveClosure?(SIGABRT, nil, "signal")
        CrashUncaughtExceptionHandler.callbackIfAvailable()?(nil, nil, "exception", [])
        XCTAssertEqual(calls, 2)
        second.exceptionReceiveClosure = nil
        XCTAssertNil(CrashSignalExceptionHandler.exceptionReceiveClosure)
        XCTAssertNil(CrashUncaughtExceptionHandler.exceptionReceiveClosure)
    }

    func testExceptionPersistenceDoesNotWaitForItsOwnLock() throws {
        try withStore { store in
            let value = crash
            XCTAssertTrue(store.persistException {
                XCTAssertFalse(store.persistException {
                    XCTFail("A reentrant report must be skipped before building it")
                    return value
                })
                return value
            })
            XCTAssertEqual(store.recover(ofType: .nsexception).count, 1)
        }
    }

    func testExceptionPersistenceDoesNotWaitForAnotherThread() throws {
        try withStore { store in
            let value = crash
            let held = DispatchSemaphore(value: 0)
            let release = DispatchSemaphore(value: 0)
            let finished = expectation(description: "normal writer finished")
            DispatchQueue.global().async {
                store.persistException {
                    held.signal()
                    // A regression remains bounded instead of hanging the test runner.
                    _ = release.wait(timeout: .now() + 3)
                    return value
                }
                finished.fulfill()
            }
            XCTAssertEqual(held.wait(timeout: .now() + 3), .success)
            let start = Date()
            XCTAssertFalse(store.persistException {
                XCTFail("A contended report must be skipped before building it")
                return value
            })
            XCTAssertLessThan(Date().timeIntervalSince(start), 1)
            release.signal()
            wait(for: [finished], timeout: 5)
        }
    }

    func testExceptionCaptureUsesStartupMetadataWithoutUIKitOrConsoleContext() throws {
        try withStore { store in
            let capture = ExceptionCrashCapture(manager: store, details: details)
            let start = Date()
            XCTAssertTrue(capture.persist(name: "fatal exception", symbols: ["original frame"]))
            let report = try XCTUnwrap(store.recover(ofType: .nsexception).first)
            XCTAssertEqual(report.details.name, "fatal exception")
            XCTAssertGreaterThanOrEqual(report.details.date, start)
            XCTAssertEqual(report.details.appVersion, "cached")
            XCTAssertEqual(report.details.deviceModel, "cached-device")
            XCTAssertEqual(report.traces.map(\.title), ["original frame"])
            XCTAssertNil(report.context.image)
            XCTAssertTrue(report.context.consoleOutput.isEmpty)
            XCTAssertTrue(report.context.errorOutput.isEmpty)
        }
    }

    func testExceptionCallbackLookupDoesNotReenterSetterLock() {
        let previous = CrashUncaughtExceptionHandler.exceptionReceiveClosure
        defer { CrashUncaughtExceptionHandler.exceptionReceiveClosure = previous }
        var checked = false
        // Releasing the previous observer can run arbitrary deinit code while the
        // setter owns its lock. A fatal-path lookup must return nil, never wait.
        func installObserver() {
            let sentinel = DeinitObserver {
                XCTAssertNil(CrashUncaughtExceptionHandler.callbackIfAvailable())
                checked = true
            }
            CrashUncaughtExceptionHandler.exceptionReceiveClosure = { [sentinel] _, _, _, _ in
                _ = sentinel
            }
        }
        installObserver()
        CrashUncaughtExceptionHandler.exceptionReceiveClosure = nil
        XCTAssertTrue(checked)
    }
}

private final class DeinitObserver {
    private let action: () -> Void
    init(_ action: @escaping () -> Void) { self.action = action }
    deinit { action() }
}
