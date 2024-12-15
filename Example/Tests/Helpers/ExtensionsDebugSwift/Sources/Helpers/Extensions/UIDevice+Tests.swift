//
//  UIDevice+Tests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/2024.
//

import XCTest
@testable import DebugSwift

final class UIDeviceUIDeviceTests: XCTestCase {

    func testModelNameForSimulator() {
        // Given
        let device = UIDevice()
        let identifiers = ["i386", "x86_64", "arm64"]

        for identifier in identifiers {
            // When
            let modelName = UIDevice.current.modelName

            // Then
            XCTAssertEqual(modelName, "iPhone Simulator", "The model name for \(identifier) should be iPhone Simulator")
        }
    }

}
