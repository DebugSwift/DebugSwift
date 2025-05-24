//
//  BaseTableControllerTests.swift
//  DebugSwiftTests
//
//  Created by Matheus Gois on 27/12/2024.
//

@testable import DebugSwift
import Testing
import UIKit

struct BaseTableControllerTests {
    
    @Test("Init with default style")
    @MainActor
    func initWithDefaultStyle() async {
        // Given
        let controller = BaseTableController()

        // Then
        #expect(controller.tableView.style == .grouped)
    }

    @Test("Init with custom style")
    @MainActor
    func initWithCustomStyle() async {
        // Given
        let controller = BaseTableController(style: .plain)

        // Then
        #expect(controller.tableView.style == .plain)
    }

    @Test("ViewWillAppear sets large titles")
    @MainActor
    func viewWillAppearSetsLargeTitles() async {
        // Given
        let controller = BaseTableController()
        let navigationController = UINavigationController(rootViewController: controller)

        // When
        controller.viewWillAppear(false)

        // Then
        #expect(navigationController.navigationBar.prefersLargeTitles == true)
    }

    @Test("Configure appearance overrides user interface style")
    @MainActor
    func configureAppearanceOverridesUserInterfaceStyle() async {
        // Given
        let controller = BaseTableController()
        let expectedStyle: UIUserInterfaceStyle = .dark
        
        // When
        controller.configureAppearance()
        
        // Then
        if #available(iOS 13.0, *) {
            #expect(controller.overrideUserInterfaceStyle == expectedStyle)
        }
    }
}
