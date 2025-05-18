//
//  UserInfoTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/2024.
//

import XCTest
@testable import DebugSwift

final class UserInfoTests: XCTestCase {

    func testGetAppVersionInfo() {
        // Given
        let expectedTitle = "App Version:"
        let expectedDetail = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

        // When
        let info = UserInfo.getAppVersionInfo()

        // Then
        XCTAssertEqual(info?.title, expectedTitle)
        XCTAssertEqual(info?.detail, expectedDetail)
    }

    func testGetAppBuildInfo() {
        // Given
        let expectedTitle = "Build Version:"
        let expectedDetail = "Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "")"

        // When
        let info = UserInfo.getAppBuildInfo()

        // Then
        XCTAssertEqual(info?.title, expectedTitle)
        XCTAssertEqual(info?.detail, expectedDetail)
    }

    func testGetBundleName() {
        // Given
        let expectedTitle = "Bundle Name:"
        let expectedDetail = Bundle.main.infoDictionary?["CFBundleName"] as? String

        // When
        let info = UserInfo.getBundleName()

        // Then
        XCTAssertEqual(info?.title, expectedTitle)
        XCTAssertEqual(info?.detail, expectedDetail)
    }

    func testGetBundleId() {
        // Given
        let expectedTitle = "Bundle ID:"
        let expectedDetail = Bundle.main.bundleIdentifier

        // When
        let info = UserInfo.getBundleId()

        // Then
        XCTAssertEqual(info?.title, expectedTitle)
        XCTAssertEqual(info?.detail, expectedDetail)
    }

    func testGetScreenResolution() {
        // Given
        let screen = UIScreen.main
        let bounds = screen.bounds
        let scale = screen.scale
        let expectedTitle = "Screen Resolution:"
        let expectedDetail = "\(bounds.size.width * scale) x \(bounds.size.height * scale) points"

        // When
        let info = UserInfo.getScreenResolution()

        // Then
        XCTAssertEqual(info.title, expectedTitle)
        XCTAssertEqual(info.detail, expectedDetail)
    }

    func testGetDeviceModelInfo() {
        // Given
        let expectedTitle = "Device Model:"
        let expectedDetail = UIDevice.current.modelName

        // When
        let info = UserInfo.getDeviceModelInfo()

        // Then
        XCTAssertEqual(info.title, expectedTitle)
        XCTAssertEqual(info.detail, expectedDetail)
    }

    func testGetIOSVersionInfo() {
        // Given
        let expectedTitle = "iOS Version:"
        let expectedDetail = UIDevice.current.systemVersion

        // When
        let info = UserInfo.getIOSVersionInfo()

        // Then
        XCTAssertEqual(info.title, expectedTitle)
        XCTAssertEqual(info.detail, expectedDetail)
    }

    func testGetMeasureAppStartUpTime() {
        // Given
        let expectedTitle = "Initialization Time:"
        let expectedDetail = String(format: "%.4lf%", LaunchTimeTracker.shared.launchStartTime ?? 0) + " (s)"

        // When
        let info = UserInfo.getMeasureAppStartUpTime()

        // Then
        XCTAssertEqual(info?.title, expectedTitle)
        XCTAssertEqual(info?.detail, expectedDetail)
    }

    func testGetReachability() {
        // Given
        let expectedTitle = "Connection Type:"
        let expectedDetail = ReachabilityManager.connection.description

        // When
        let info = UserInfo.getReachability()

        // Then
        XCTAssertEqual(info.title, expectedTitle)
        XCTAssertEqual(info.detail, expectedDetail)
    }
}
