//
//  UILabel+Tests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/2024.
//

import XCTest
@testable import DebugSwift

final class UILabelTests: XCTestCase {

    func testSetAttributedTextWithValidInputs() {
        // Given
        let label = UILabel()
        let title = "Title"
        let subtitle = "Subtitle"
        let scale: CGFloat = 1.0

        // When
        label.setAttributedText(title: title, subtitle: subtitle, scale: scale)

        // Then
        XCTAssertEqual(label.numberOfLines, 0, "The number of lines should be 0")
        XCTAssertNotNil(label.attributedText, "The attributed text should not be nil")
        XCTAssertEqual(label.attributedText?.string, "\(title)\n\(subtitle)", "The attributed text should match the title and subtitle")
    }

    func testSetAttributedTextWithEmptyTitle() {
        // Given
        let label = UILabel()
        let title = ""
        let subtitle = "Subtitle"
        let scale: CGFloat = 1.0

        // When
        label.setAttributedText(title: title, subtitle: subtitle, scale: scale)

        // Then
        XCTAssertEqual(label.numberOfLines, 0, "The number of lines should be 0")
        XCTAssertNotNil(label.attributedText, "The attributed text should not be nil")
        XCTAssertEqual(label.attributedText?.string, "\n\(subtitle)", "The attributed text should match the subtitle with a line break")
    }

    func testSetAttributedTextWithEmptySubtitle() {
        // Given
        let label = UILabel()
        let title = "Title"
        let subtitle = ""
        let scale: CGFloat = 1.0

        // When
        label.setAttributedText(title: title, subtitle: subtitle, scale: scale)

        // Then
        XCTAssertEqual(label.numberOfLines, 0, "The number of lines should be 0")
        XCTAssertNotNil(label.attributedText, "The attributed text should not be nil")
        XCTAssertEqual(label.attributedText?.string, "\(title)\n", "The attributed text should match the title with a line break")
    }

    func testSetAttributedTextWithEmptyTitleAndSubtitle() {
        // Given
        let label = UILabel()
        let title = ""
        let subtitle = ""
        let scale: CGFloat = 1.0

        // When
        label.setAttributedText(title: title, subtitle: subtitle, scale: scale)

        // Then
        XCTAssertEqual(label.numberOfLines, 0, "The number of lines should be 0")
        XCTAssertNotNil(label.attributedText, "The attributed text should not be nil")
        XCTAssertEqual(label.attributedText?.string, "\n", "The attributed text should match a line break")
    }

    func testSetAttributedTextWithDifferentScale() {
        // Given
        let label = UILabel()
        let title = "Title"
        let subtitle = "Subtitle"
        let scale: CGFloat = 2.0

        // When
        label.setAttributedText(title: title, subtitle: subtitle, scale: scale)

        // Then
        XCTAssertEqual(label.numberOfLines, 0, "The number of lines should be 0")
        XCTAssertNotNil(label.attributedText, "The attributed text should not be nil")
        XCTAssertEqual(label.attributedText?.string, "\(title)\n\(subtitle)", "The attributed text should match the title and subtitle")
    }
}
