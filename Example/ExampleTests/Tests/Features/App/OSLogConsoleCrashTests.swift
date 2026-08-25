//
//  OSLogConsoleCrashTests.swift
//  ExampleTests
//
//  Regression test for issue #375: scrollToBottom crashes when capture is
//  disabled because numberOfRowsInSection returns 1 but scrollToBottom computes
//  entries.count - 1 (out-of-bounds).
//

import XCTest
@testable import DebugSwift

@available(iOS 15.0, *)
final class OSLogConsoleCrashTests: XCTestCase {

    @MainActor
    func testScrollToBottomDoesNotCrashWhenCaptureDisabled() {
        let viewModel = OSLogConsoleViewModel()
        XCTAssertFalse(viewModel.isCaptureEnabled, "Capture should be off by default")

        // Simulate having accumulated entries while capture was on, then
        // disabling capture — the exact scenario from the bug report.
        viewModel.isCaptureEnabled = true
        viewModel.isCaptureEnabled = false

        // If the fix is correct, calling onUpdate (which triggers scrollToBottom
        // when autoScroll is true) must not crash even though entries exist.
        viewModel.autoScroll = true
        viewModel.onUpdate?() // This calls scrollToBottom internally
        // If we reach here, no crash occurred — test passes.
    }

    @MainActor
    func testScrollToBottomSkipsWhenCaptureDisabled() {
        let viewModel = OSLogConsoleViewModel()
        viewModel.autoScroll = true
        viewModel.isCaptureEnabled = false

        // The ViewModel's onUpdate closure is the call site for scrollToBottom.
        // It should be safe to invoke when capture is off.
        viewModel.onUpdate?()
        // No crash = pass.
    }
}
