//
//  UIWindow+Tests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/2024.
//

import XCTest
@testable import DebugSwift

final class UIWindowTests: XCTestCase {

    func testDebuggingInformationOverlayInit() {
        // Given
        let window = UIWindow()

        // When
        let newWindow = window.db_debuggingInformationOverlayInit()

        // Then
        XCTAssertNotNil(newWindow, "Debugging information overlay should be initialized")
    }

    func testSnapshot() {
        // Given
        let window = UIWindow()

        // When
        let snapshot = window._snapshot

        // Then
        XCTAssertNotNil(snapshot, "Snapshot should be taken")
    }

    func testSnapshotWithTouch() {
        // Given
        let window = UIWindow()
        UIWindow.lastTouch = CGPoint(x: 50, y: 50)

        // When
        let snapshotWithTouch = window._snapshotWithTouch

        // Then
        XCTAssertNotNil(snapshotWithTouch, "Snapshot with touch should be taken")
    }
}
