//
//  ContrastCheckerTests.swift
//  ExampleTests
//
//  Created by Matheus Gois on 16/07/26.
//

import XCTest
import UIKit
@testable import DebugSwift

final class ContrastCheckerTests: XCTestCase {

    // MARK: - Helpers

    private func color(_ r: Double, _ g: Double, _ b: Double) -> (red: Double, green: Double, blue: Double) {
        (r, g, b)
    }

    private let black = (red: 0.0, green: 0.0, blue: 0.0)
    private let white = (red: 1.0, green: 1.0, blue: 1.0)

    // MARK: - ContrastChecker: relativeLuminance

    func testRelativeLuminance_blackIsZero() {
        XCTAssertEqual(ContrastChecker.relativeLuminance(black), 0.0, accuracy: 0.0001)
    }

    func testRelativeLuminance_whiteIsOne() {
        XCTAssertEqual(ContrastChecker.relativeLuminance(white), 1.0, accuracy: 0.0001)
    }

    // MARK: - ContrastChecker: ratio

    func testRatio_blackOnWhite_is21() {
        XCTAssertEqual(ContrastChecker.ratio(foreground: black, background: white), 21.0, accuracy: 0.01)
    }

    func testRatio_whiteOnBlack_is21() {
        XCTAssertEqual(ContrastChecker.ratio(foreground: white, background: black), 21.0, accuracy: 0.01)
    }

    func testRatio_sameColor_isOne() {
        XCTAssertEqual(ContrastChecker.ratio(foreground: black, background: black), 1.0, accuracy: 0.0001)
    }

    func testRatio_midGrayOnWhite() {
        // rgb(118,118,118) normalized = 118/255 ≈ 0.4627
        let gray = color(118.0 / 255.0, 118.0 / 255.0, 118.0 / 255.0)
        let ratio = ContrastChecker.ratio(foreground: gray, background: white)
        XCTAssertEqual(ratio, 4.54, accuracy: 0.05)
        XCTAssertEqual(ContrastChecker.grade(ratio), .levelAA)
    }

    // MARK: - ContrastChecker: grade

    func testGrade_ratio7plus_isAAA() {
        XCTAssertEqual(ContrastChecker.grade(7.0), .levelAAA)
        XCTAssertEqual(ContrastChecker.grade(10.0), .levelAAA)
    }

    func testGrade_ratio4point5to7_isAA() {
        XCTAssertEqual(ContrastChecker.grade(4.5), .levelAA)
        XCTAssertEqual(ContrastChecker.grade(6.9), .levelAA)
    }

    func testGrade_below4point5_isFail() {
        XCTAssertEqual(ContrastChecker.grade(1.0), .fail)
        XCTAssertEqual(ContrastChecker.grade(4.4), .fail)
    }

    // MARK: - ContrastAdapter: rgb

    func testRgb_fromUIColor_extractsCorrectValues() {
        let red = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        let (r, g, b) = ContrastAdapter.rgb(from: red)
        XCTAssertEqual(r, 1.0, accuracy: 0.01)
        XCTAssertEqual(g, 0.0, accuracy: 0.01)
        XCTAssertEqual(b, 0.0, accuracy: 0.01)
    }

    // MARK: - ContrastAdapter: ratio

    func testRatio_fromUIColors() {
        let blackUI = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        let whiteUI = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        XCTAssertEqual(ContrastAdapter.ratio(foreground: blackUI, background: whiteUI), 21.0, accuracy: 0.01)
    }

    // MARK: - ContrastAdapter: grade

    func testGrade_fromUIColors() {
        let blackUI = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        let whiteUI = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        XCTAssertEqual(ContrastAdapter.grade(foreground: blackUI, background: whiteUI), .levelAAA)
    }

    // MARK: - ContrastAdapter: report

    func testReport_returnsFormattedString() {
        let blackUI = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        let whiteUI = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        let report = ContrastAdapter.report(foreground: blackUI, background: whiteUI)
        XCTAssertTrue(report.contains("Ratio"))
        XCTAssertTrue(report.contains("AAA") || report.contains("AA") || report.contains("FAIL"))
    }
}
