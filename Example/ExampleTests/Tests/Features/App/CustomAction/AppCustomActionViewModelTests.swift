//
//  AppCustomActionViewModelTests.swift
//  DebugSwift
//
//  Created by DebugSwift on 2026.
//

import XCTest
@testable import DebugSwift

final class AppCustomActionViewModelTests: XCTestCase {

    var sut: AppCustomActionViewModel!

    override func setUp() {
        super.setUp()
        let actions: [CustomAction.Action] = [
            .init(title: "Alpha", action: nil),
            .init(title: "Beta", action: nil),
            .init(title: "Gamma", action: nil)
        ]
        sut = AppCustomActionViewModel(data: CustomAction(title: "Test Group", actions: actions))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - viewTitle

    func testViewTitle_returnsCustomActionTitle() {
        XCTAssertEqual(sut.viewTitle(), "Test Group")
    }

    // MARK: - numberOfItems

    func testNumberOfItems_searchInactive_returnsAllActions() {
        sut.isSearchActived = false
        XCTAssertEqual(sut.numberOfItems(), 3)
    }

    func testNumberOfItems_searchActive_returnsFilteredCount() {
        sut.isSearchActived = true
        sut.filterContentForSearchText("Alpha")
        XCTAssertEqual(sut.numberOfItems(), 1)
    }

    // MARK: - dataSourceForItem

    func testDataSourceForItem_searchInactive_returnsCorrectTitle() {
        sut.isSearchActived = false
        let viewData = sut.dataSourceForItem(atIndex: 1)
        XCTAssertEqual(viewData.title, "Beta")
    }

    func testDataSourceForItem_searchActive_returnsFilteredTitle() {
        sut.isSearchActived = true
        sut.filterContentForSearchText("Gamma")
        let viewData = sut.dataSourceForItem(atIndex: 0)
        XCTAssertEqual(viewData.title, "Gamma")
    }

    // MARK: - emptyListDescriptionString

    func testEmptyListDescriptionString_containsTitle() {
        let description = sut.emptyListDescriptionString()
        XCTAssertTrue(description.contains("Test Group"))
    }

    // MARK: - filterContentForSearchText

    func testFilterContentForSearchText_emptyQuery_returnsAllActions() {
        sut.isSearchActived = true
        sut.filterContentForSearchText("")
        XCTAssertEqual(sut.numberOfItems(), 3)
    }

    func testFilterContentForSearchText_matchingQuery_returnsMatchingActions() {
        sut.isSearchActived = true
        sut.filterContentForSearchText("be")
        XCTAssertEqual(sut.numberOfItems(), 1)
        XCTAssertEqual(sut.dataSourceForItem(atIndex: 0).title, "Beta")
    }

    func testFilterContentForSearchText_noMatch_returnsEmpty() {
        sut.isSearchActived = true
        sut.filterContentForSearchText("XYZ")
        XCTAssertEqual(sut.numberOfItems(), 0)
    }

    func testFilterContentForSearchText_isCaseInsensitive() {
        sut.isSearchActived = true
        sut.filterContentForSearchText("alpha")
        XCTAssertEqual(sut.numberOfItems(), 1)
        XCTAssertEqual(sut.dataSourceForItem(atIndex: 0).title, "Alpha")
    }

    // MARK: - didTapItem

    func testDidTapItem_searchInactive_invokesAction() {
        var tapped = false
        let actions: [CustomAction.Action] = [
            .init(title: "Tap Me", action: { tapped = true })
        ]
        sut = AppCustomActionViewModel(data: CustomAction(title: "Actions", actions: actions))
        sut.isSearchActived = false

        sut.didTapItem(index: 0)

        XCTAssertTrue(tapped)
    }

    func testDidTapItem_searchActive_invokesFilteredAction() {
        var tapped = false
        let actions: [CustomAction.Action] = [
            .init(title: "Other", action: nil),
            .init(title: "Target", action: { tapped = true })
        ]
        sut = AppCustomActionViewModel(data: CustomAction(title: "Actions", actions: actions))
        sut.isSearchActived = true
        sut.filterContentForSearchText("Target")

        sut.didTapItem(index: 0)

        XCTAssertTrue(tapped)
    }

    // MARK: - Feature flags

    func testIsDeleteEnable_isFalse() {
        XCTAssertFalse(sut.isDeleteEnable)
    }

    func testIsCustomActionEnable_isTrue() {
        XCTAssertTrue(sut.isCustomActionEnable)
    }
}
