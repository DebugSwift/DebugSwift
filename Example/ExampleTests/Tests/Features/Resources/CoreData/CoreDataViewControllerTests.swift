//
//  CoreDataViewControllerTests.swift
//  ExampleTests
//
//  Tests for Core Data view controllers
//

import XCTest
import CoreData
@testable import DebugSwift

@MainActor
final class CoreDataBrowserViewControllerTests: XCTestCase {
    
    var viewController: CoreDataBrowserViewController!
    var persistentContainer: NSPersistentContainer!
    var testContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create test model and container
        let model = createTestModel()
        persistentContainer = NSPersistentContainer(name: "TestModel", managedObjectModel: model)
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        let expectation = self.expectation(description: "Load persistent stores")
        persistentContainer.loadPersistentStores { _, error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        testContext = persistentContainer.viewContext
        
        // Configure CoreDataManager
        CoreDataManager.shared.configure(container: persistentContainer)
        
        // Create view controller
        viewController = CoreDataBrowserViewController()
    }
    
    override func tearDownWithError() throws {
        viewController = nil
        testContext = nil
        persistentContainer = nil
        try super.tearDownWithError()
    }
    
    func createTestModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        let personEntity = NSEntityDescription()
        personEntity.name = "Person"
        personEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        
        let nameAttribute = NSAttributeDescription()
        nameAttribute.name = "name"
        nameAttribute.attributeType = .stringAttributeType
        nameAttribute.isOptional = false
        
        personEntity.properties = [nameAttribute]
        
        let addressEntity = NSEntityDescription()
        addressEntity.name = "Address"
        addressEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        
        let streetAttribute = NSAttributeDescription()
        streetAttribute.name = "street"
        streetAttribute.attributeType = .stringAttributeType
        streetAttribute.isOptional = false
        
        addressEntity.properties = [streetAttribute]
        
        model.entities = [personEntity, addressEntity]
        
        return model
    }
    
    // MARK: - Initialization Tests
    
    func testViewControllerInitialization() {
        // Given / When
        let vc = CoreDataBrowserViewController()
        
        // Then
        XCTAssertNotNil(vc)
    }
    
    func testViewControllerTitle() {
        // Given
        _ = viewController.view
        
        // When / Then
        XCTAssertEqual(viewController.title, "Core Data Browser")
    }
    
    // MARK: - View Lifecycle Tests
    
    func testViewDidLoad() {
        // Given / When
        _ = viewController.view
        
        // Then
        XCTAssertNotNil(viewController.view)
    }
    
    // MARK: - Empty State Tests
    
    func testEmptyStateWithNoConfiguration() {
        // Given
        CoreDataManager.shared.configure(contexts: [:])
        let vc = CoreDataBrowserViewController()
        
        // When
        _ = vc.view
        
        // Then
        XCTAssertNotNil(vc.view)
    }
}

@MainActor
final class CoreDataEntityViewControllerTests: XCTestCase {
    
    var viewController: CoreDataEntityViewController!
    var persistentContainer: NSPersistentContainer!
    var testContext: NSManagedObjectContext!
    var testEntity: CoreDataEntity!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create test model and container
        let model = createTestModel()
        persistentContainer = NSPersistentContainer(name: "TestModel", managedObjectModel: model)
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        let expectation = self.expectation(description: "Load persistent stores")
        persistentContainer.loadPersistentStores { _, error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        testContext = persistentContainer.viewContext
        
        // Create test entity
        testEntity = CoreDataEntity(
            name: "Person",
            managedObjectClassName: "Person",
            objectCount: 0,
            attributes: [
                CoreDataAttribute(name: "name", type: "String", isOptional: false, defaultValue: nil),
                CoreDataAttribute(name: "age", type: "Int32", isOptional: false, defaultValue: nil)
            ],
            relationships: []
        )
        
        // Create view controller
        viewController = CoreDataEntityViewController(entity: testEntity, context: testContext)
    }
    
    override func tearDownWithError() throws {
        viewController = nil
        testEntity = nil
        testContext = nil
        persistentContainer = nil
        try super.tearDownWithError()
    }
    
    func createTestModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        let entity = NSEntityDescription()
        entity.name = "Person"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        
        let nameAttribute = NSAttributeDescription()
        nameAttribute.name = "name"
        nameAttribute.attributeType = .stringAttributeType
        nameAttribute.isOptional = false
        
        let ageAttribute = NSAttributeDescription()
        ageAttribute.name = "age"
        ageAttribute.attributeType = .integer32AttributeType
        ageAttribute.isOptional = false
        
        entity.properties = [nameAttribute, ageAttribute]
        model.entities = [entity]
        
        return model
    }
    
    // MARK: - Initialization Tests
    
    func testViewControllerInitialization() {
        // Given / When
        let vc = CoreDataEntityViewController(entity: testEntity, context: testContext)
        
        // Then
        XCTAssertNotNil(vc)
    }
    
    func testViewControllerTitle() {
        // Given
        _ = viewController.view
        
        // When / Then
        XCTAssertEqual(viewController.title, "Person")
    }
    
    // MARK: - View Lifecycle Tests
    
    func testViewDidLoad() {
        // Given / When
        _ = viewController.view
        
        // Then
        XCTAssertNotNil(viewController.view)
    }
    
    // MARK: - Empty State Tests
    
    func testEmptyStateWithNoObjects() {
        // Given
        _ = viewController.view
        
        // When
        viewController.viewWillAppear(false)
        
        // Then - View should handle empty state
        XCTAssertNotNil(viewController.view)
    }
    
    // MARK: - Data Loading Tests
    
    func testLoadObjectsWithData() {
        // Given
        createTestPerson(name: "John", age: 30)
        createTestPerson(name: "Jane", age: 25)
        
        // When
        _ = viewController.view
        viewController.viewWillAppear(false)
        
        // Then - Should load without crashing
        XCTAssertNotNil(viewController.view)
    }
    
    // MARK: - Helper Methods
    
    @discardableResult
    func createTestPerson(name: String, age: Int32) -> NSManagedObject {
        let person = NSEntityDescription.insertNewObject(forEntityName: "Person", into: testContext)
        person.setValue(name, forKey: "name")
        person.setValue(age, forKey: "age")
        try? testContext.save()
        return person
    }
}

@MainActor
final class CoreDataObjectDetailViewControllerTests: XCTestCase {
    
    var viewController: CoreDataObjectDetailViewController!
    var persistentContainer: NSPersistentContainer!
    var testContext: NSManagedObjectContext!
    var testObject: NSManagedObject!
    var testEntity: CoreDataEntity!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create test model and container
        let model = createTestModel()
        persistentContainer = NSPersistentContainer(name: "TestModel", managedObjectModel: model)
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        let expectation = self.expectation(description: "Load persistent stores")
        persistentContainer.loadPersistentStores { _, error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        testContext = persistentContainer.viewContext
        
        // Create test object
        testObject = NSEntityDescription.insertNewObject(forEntityName: "Person", into: testContext)
        testObject.setValue("John Doe", forKey: "name")
        testObject.setValue(Int32(30), forKey: "age")
        try? testContext.save()
        
        // Create test entity
        testEntity = CoreDataEntity(
            name: "Person",
            managedObjectClassName: "Person",
            objectCount: 1,
            attributes: [
                CoreDataAttribute(name: "name", type: "String", isOptional: false, defaultValue: nil),
                CoreDataAttribute(name: "age", type: "Int32", isOptional: false, defaultValue: nil)
            ],
            relationships: []
        )
        
        // Create view controller
        viewController = CoreDataObjectDetailViewController(
            object: testObject,
            entity: testEntity,
            context: testContext
        )
    }
    
    override func tearDownWithError() throws {
        viewController = nil
        testObject = nil
        testEntity = nil
        testContext = nil
        persistentContainer = nil
        try super.tearDownWithError()
    }
    
    func createTestModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        let entity = NSEntityDescription()
        entity.name = "Person"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        
        let nameAttribute = NSAttributeDescription()
        nameAttribute.name = "name"
        nameAttribute.attributeType = .stringAttributeType
        nameAttribute.isOptional = false
        
        let ageAttribute = NSAttributeDescription()
        ageAttribute.name = "age"
        ageAttribute.attributeType = .integer32AttributeType
        ageAttribute.isOptional = false
        
        entity.properties = [nameAttribute, ageAttribute]
        model.entities = [entity]
        
        return model
    }
    
    // MARK: - Initialization Tests
    
    func testViewControllerInitialization() {
        // Given / When
        let vc = CoreDataObjectDetailViewController(
            object: testObject,
            entity: testEntity,
            context: testContext
        )
        
        // Then
        XCTAssertNotNil(vc)
    }
    
    func testViewControllerTitle() {
        // Given
        _ = viewController.view
        
        // When / Then
        XCTAssertEqual(viewController.title, "Object Detail")
    }
    
    // MARK: - View Lifecycle Tests
    
    func testViewDidLoad() {
        // Given / When
        _ = viewController.view
        
        // Then
        XCTAssertNotNil(viewController.view)
    }
    
    // MARK: - Read-Only Mode Tests
    
    func testReadOnlyModeHidesEditButton() {
        // Given
        DebugSwift.Resources.shared.coreDataReadOnly = true
        
        // When
        _ = viewController.view
        
        // Then
        XCTAssertNil(viewController.navigationItem.rightBarButtonItem)
        
        // Cleanup
        DebugSwift.Resources.shared.coreDataReadOnly = false
    }
    
    func testEditModeShowsEditButton() {
        // Given
        DebugSwift.Resources.shared.coreDataReadOnly = false
        
        // When
        _ = viewController.view
        
        // Then
        XCTAssertNotNil(viewController.navigationItem.rightBarButtonItem)
    }
}
