//
//  UITableViewCell+Tests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/2024.
//

import XCTest
@testable import DebugSwift

final class UITableViewCellTests: XCTestCase {

    var cell: UITableViewCell!

    override func setUpWithError() throws {
        try super.setUpWithError()
        cell = UITableViewCell()
    }

    override func tearDownWithError() throws {
        cell = nil
        try super.tearDownWithError()
    }

    func testSetupWithTitleOnly() throws {
        // Given
        let title = "Test Title"

        // When
        cell.setup(title: title)

        // Then
        XCTAssertEqual(cell.textLabel?.text, title)
        XCTAssertEqual(cell.textLabel?.textColor, UIColor.white)
        XCTAssertEqual(cell.textLabel?.font, UIFont.systemFont(ofSize: 16))
    }

    func testSetupWithSubtitle() throws {
        // Given
        let title = "Test Title"
        let subtitle = "Test Subtitle"

        // When
        cell.setup(title: title, subtitle: subtitle)

        // Then
        XCTAssertEqual(cell.textLabel?.textColor, UIColor.white)
        XCTAssertEqual(cell.textLabel?.font, UIFont.systemFont(ofSize: 16))
        XCTAssertNotNil(cell.textLabel?.attributedText)
    }

    @available(iOS 13.0, *)
    func testSetupWithImage() throws {
        // Given
        let title = "Test Title"
        let image = UIImage(systemName: "chevron.right")

        // When
        cell.setup(title: title, image: image)

        // Then
        XCTAssertEqual(cell.textLabel?.text, title)
        XCTAssertNotNil(cell.accessoryView as? UIImageView)
        XCTAssertEqual((cell.accessoryView as? UIImageView)?.image, image)
    }

    func testSetupWithDescription() throws {
        // Given
        let title = "Test Title"
        let description = "Test Description"

        // When
        cell.setup(title: title, description: description)

        // Then
        XCTAssertEqual(cell.textLabel?.text, title)
    }

    func testSetupWithScale() throws {
        // Given
        let title = "Test Title"
        let scale: CGFloat = 2.0

        // When
        cell.setup(title: title, scale: scale)

        // Then
        XCTAssertEqual(cell.textLabel?.text, title)
        XCTAssertEqual(cell.textLabel?.font, UIFont.systemFont(ofSize: 16 * scale))
    }
}
