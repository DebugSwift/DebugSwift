//
//  CrashDetailViewModelTests.swift
//  DebugSwift
//
//  Created by DebugSwift on 2026.
//

import XCTest
@testable import DebugSwift

final class CrashDetailViewModelTests: XCTestCase {
    // MARK: - Helpers

    private func makeCrash(
        type: CrashType = .nsexception,
        name: String = "nsexception",
        traces: [String] = ["0x0001", "0x0002"]
    ) -> CrashModel {
        let details = CrashModel.Details(
            name: name,
            date: Date(timeIntervalSince1970: 1_750_000_000),
            appVersion: "1.0",
            appBuild: "1",
            iosVersion: "26.3.1",
            deviceModel: "iPhone17,1",
            reachability: "WiFi"
        )
        let context = CrashModel.Context(
            image: nil,
            consoleOutput: "",
            errorOutput: ""
        )
        return CrashModel(
            type: type,
            details: details,
            context: context,
            traces: .builder(traces)
        )
    }

    // MARK: - getAllValues (the contract Copy Text relies on)

    func testGetAllValuesContainsDetailsSection() {
        let viewModel = CrashDetailViewModel(data: makeCrash())

        let values = viewModel.getAllValues()

        XCTAssertTrue(values.contains("Details:"))
        XCTAssertTrue(values.contains("Error: nsexception"))
        XCTAssertTrue(values.contains("App Version:: 1.0"))
        XCTAssertTrue(values.contains("Build Version:: 1"))
        XCTAssertTrue(values.contains("iOS Version:: 26.3.1"))
    }

    func testGetAllValuesContainsStackTraceSection() {
        let viewModel = CrashDetailViewModel(
            data: makeCrash(traces: ["frame_one", "frame_two"])
        )

        let values = viewModel.getAllValues()

        XCTAssertTrue(values.contains("Stack Trace:"))
        XCTAssertTrue(values.contains("frame_one"))
        XCTAssertTrue(values.contains("frame_two"))
    }

    func testGetAllValuesIsWellFormedWhenNoTraces() {
        let viewModel = CrashDetailViewModel(
            data: makeCrash(traces: [])
        )

        let values = viewModel.getAllValues()

        XCTAssertTrue(values.hasPrefix("Details:"))
        XCTAssertTrue(values.contains("Stack Trace:"))
        let stackSection = values.components(separatedBy: "Stack Trace:").last ?? ""
        XCTAssertEqual(stackSection.trimmingCharacters(in: .whitespacesAndNewlines), "")
    }

    func testGetAllValuesForSignalCrashIncludesSignalType() {
        let viewModel = CrashDetailViewModel(
            data: makeCrash(type: .signal, name: "SIGABRT")
        )

        let values = viewModel.getAllValues()

        XCTAssertTrue(values.contains("Error: signal"))
        XCTAssertTrue(values.contains("Error: SIGABRT"))
    }

    /// Regression: getAllValues() must copy the human-readable frame text for
    /// each stack-trace line, NOT the raw struct description
    /// ("Info(title: \"0x0001 main\", detail: \"\")"). Before the fix, tapping
    /// "Copy Text" pasted the Swift struct dump instead of the frame symbols.
    func testGetAllValuesStackTraceIsReadableNotStructDump() {
        let viewModel = CrashDetailViewModel(
            data: makeCrash(traces: ["0x0001 main", "0x0002 foo", "0x0003 bar"])
        )

        let values = viewModel.getAllValues()

        // Must contain the bare frame symbols, as a user would expect.
        XCTAssertTrue(values.contains("0x0001 main"), "Expected frame text in: \(values)")
        XCTAssertTrue(values.contains("0x0002 foo"))
        XCTAssertTrue(values.contains("0x0003 bar"))

        // Must NOT contain the Swift struct description of UserInfo.Info.
        XCTAssertFalse(
            values.contains("Info(title:"),
            "Stack trace should not contain the raw struct dump, got: \(values)"
        )
    }
}
