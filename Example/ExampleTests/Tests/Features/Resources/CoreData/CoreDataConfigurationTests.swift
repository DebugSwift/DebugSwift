//
//  CoreDataConfigurationTests.swift
//  ExampleTests
//
//  Tests for DebugSwift Core Data configuration API
//

import XCTest
import CoreData
@testable import DebugSwift

@MainActor
final class CoreDataConfigurationTests: XCTestCase {
    
    var persistentContainer: NSPersistentContainer!
    var testContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory persistent container for testing
        let model = createTestModel()
        persistentContainer = NSPersistentContainer(name: "TestModel", managedObjectModel: model)
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        let expectation = self.expectation(description: "Load persistent stores")
        persistentContainer.loadPersistentStores { description, error in
            XCTAssertNil(error, "Failed to load persistent stores")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        testContext = persistentContainer.viewContext
    }
    
    override func tearDownWithError() throws {
        // Reset configuration
        DebugSwift.Resources.shared.coreDataContainer = nil
        DebugSwift.Resources.shared.coreDataContext = nil
        DebugSwift.Resources.shared.coreDataContexts = [:]
        DebugSwift.Resources.shared.coreDataReadOnly = false
        
        testContext = nil
        persistentContainer = nil
        try super.tearDownWithError()
    }
    
    func createTestModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        let entity = NSEntityDescription()
        entity.name = "TestEntity"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        
        let attribute = NSAttributeDescription()
        attribute.name = "name"
        attribute.attributeType = .stringAttributeType
        attribute.isOptional = false
        
        entity.properties = [attribute]
        model.entities = [entity]
        
        return model
    }
    
    // MARK: - Container Configuration Tests
    
    func testConfigureCoreDataWithContainer() async {
        // Given
        let container = persistentContainer!
        
        // When
        DebugSwift.Resources.shared.configureCoreData(container: container)
        
        // Wait for async configuration
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertNotNil(DebugSwift.Resources.shared.coreDataContainer)
        XCTAssertEqual(DebugSwift.Resources.shared.coreDataContainer, container)
    }
    
    func testCoreDataContainerProperty() async {
        // Given
        let container = persistentContainer!
        
        // When
        DebugSwift.Resources.shared.coreDataContainer = container
        
        // Wait for async configuration
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(DebugSwift.Resources.shared.coreDataContainer, container)
    }
    
    // MARK: - Context Configuration Tests
    
    func testConfigureCoreDataWithContext() async {
        // Given
        let context = testContext!
        
        // When
        DebugSwift.Resources.shared.configureCoreData(context: context)
        
        // Wait for async configuration
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertNotNil(DebugSwift.Resources.shared.coreDataContext)
        XCTAssertEqual(DebugSwift.Resources.shared.coreDataContext, context)
    }
    
    func testCoreDataContextProperty() async {
        // Given
        let context = testContext!
        
        // When
        DebugSwift.Resources.shared.coreDataContext = context
        
        // Wait for async configuration
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(DebugSwift.Resources.shared.coreDataContext, context)
    }
    
    // MARK: - Multiple Contexts Configuration Tests
    
    func testConfigureCoreDataWithMultipleContexts() async {
        // Given
        let mainContext = testContext!
        let backgroundContext = persistentContainer.newBackgroundContext()
        let contexts = ["Main": mainContext, "Background": backgroundContext]
        
        // When
        DebugSwift.Resources.shared.configureCoreData(contexts: contexts)
        
        // Wait for async configuration
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(DebugSwift.Resources.shared.coreDataContexts.count, 2)
        XCTAssertEqual(DebugSwift.Resources.shared.coreDataContexts["Main"], mainContext)
        XCTAssertEqual(DebugSwift.Resources.shared.coreDataContexts["Background"], backgroundContext)
    }
    
    func testCoreDataContextsProperty() async {
        // Given
        let mainContext = testContext!
        let backgroundContext = persistentContainer.newBackgroundContext()
        let contexts = ["Main": mainContext, "Background": backgroundContext]
        
        // When
        DebugSwift.Resources.shared.coreDataContexts = contexts
        
        // Wait for async configuration
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(DebugSwift.Resources.shared.coreDataContexts.count, 2)
        XCTAssertTrue(DebugSwift.Resources.shared.coreDataContexts.keys.contains("Main"))
        XCTAssertTrue(DebugSwift.Resources.shared.coreDataContexts.keys.contains("Background"))
    }
    
    // MARK: - Read-Only Mode Tests
    
    func testCoreDataReadOnlyDefault() {
        // Given / When
        let isReadOnly = DebugSwift.Resources.shared.coreDataReadOnly
        
        // Then
        XCTAssertFalse(isReadOnly, "Read-only mode should be disabled by default")
    }
    
    func testSetCoreDataReadOnly() {
        // Given
        DebugSwift.Resources.shared.coreDataReadOnly = false
        
        // When
        DebugSwift.Resources.shared.coreDataReadOnly = true
        
        // Then
        XCTAssertTrue(DebugSwift.Resources.shared.coreDataReadOnly)
    }
    
    func testToggleCoreDataReadOnly() {
        // Given
        let initialValue = DebugSwift.Resources.shared.coreDataReadOnly
        
        // When
        DebugSwift.Resources.shared.coreDataReadOnly = !initialValue
        
        // Then
        XCTAssertNotEqual(DebugSwift.Resources.shared.coreDataReadOnly, initialValue)
    }
    
    // MARK: - Configuration Persistence Tests
    
    func testMultipleConfigurationsOverwrite() async {
        // Given
        let container1 = persistentContainer!
        let context1 = testContext!
        
        // When
        DebugSwift.Resources.shared.configureCoreData(container: container1)
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        DebugSwift.Resources.shared.configureCoreData(context: context1)
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        // Then
        XCTAssertNotNil(DebugSwift.Resources.shared.coreDataContext)
        XCTAssertEqual(DebugSwift.Resources.shared.coreDataContext, context1)
    }
    
    // MARK: - Integration Tests
    
    func testConfigurationWithRealCoreDataStack() async {
        // Given
        let container = persistentContainer!
        
        // When
        DebugSwift.Resources.shared.configureCoreData(container: container)
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Create a test object
        let entity = NSEntityDescription.insertNewObject(forEntityName: "TestEntity", into: testContext)
        entity.setValue("Test", forKey: "name")
        try? testContext.save()
        
        // Then
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TestEntity")
        let count = try? testContext.count(for: fetchRequest)
        XCTAssertEqual(count, 1)
    }
    
    func testConfigurationPersistsAcrossReads() async {
        // Given
        let container = persistentContainer!
        
        // When
        DebugSwift.Resources.shared.configureCoreData(container: container)
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        let firstRead = DebugSwift.Resources.shared.coreDataContainer
        let secondRead = DebugSwift.Resources.shared.coreDataContainer
        
        // Then
        XCTAssertEqual(firstRead, secondRead)
        XCTAssertEqual(firstRead, container)
    }
}
