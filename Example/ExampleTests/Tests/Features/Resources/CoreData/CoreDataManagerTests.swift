//
//  CoreDataManagerTests.swift
//  ExampleTests
//
//  Tests for CoreDataManager
//

import XCTest
import CoreData
@testable import DebugSwift

@MainActor
final class CoreDataManagerTests: XCTestCase {
    
    var persistentContainer: NSPersistentContainer!
    var testContext: NSManagedObjectContext!
    var manager: CoreDataManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        manager = CoreDataManager.shared
        
        // Create in-memory persistent container for testing
        let model = createTestModel()
        persistentContainer = NSPersistentContainer(name: "TestModel", managedObjectModel: model)
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        let expectation = self.expectation(description: "Load persistent stores")
        persistentContainer.loadPersistentStores { description, error in
            XCTAssertNil(error, "Failed to load persistent stores: \(String(describing: error))")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        testContext = persistentContainer.viewContext
    }
    
    override func tearDownWithError() throws {
        testContext = nil
        persistentContainer = nil
        manager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Test Model Creation
    
    func createTestModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // Person Entity
        let personEntity = NSEntityDescription()
        personEntity.name = "Person"
        personEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        
        let nameAttribute = NSAttributeDescription()
        nameAttribute.name = "name"
        nameAttribute.attributeType = .stringAttributeType
        nameAttribute.isOptional = false
        
        let ageAttribute = NSAttributeDescription()
        ageAttribute.name = "age"
        ageAttribute.attributeType = .integer32AttributeType
        ageAttribute.isOptional = false
        
        personEntity.properties = [nameAttribute, ageAttribute]
        
        // Address Entity
        let addressEntity = NSEntityDescription()
        addressEntity.name = "Address"
        addressEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        
        let streetAttribute = NSAttributeDescription()
        streetAttribute.name = "street"
        streetAttribute.attributeType = .stringAttributeType
        streetAttribute.isOptional = false
        
        addressEntity.properties = [streetAttribute]
        
        // Relationship
        let personAddressRelationship = NSRelationshipDescription()
        personAddressRelationship.name = "address"
        personAddressRelationship.destinationEntity = addressEntity
        personAddressRelationship.minCount = 0
        personAddressRelationship.maxCount = 1
        personAddressRelationship.deleteRule = .cascadeDeleteRule
        
        let addressPersonRelationship = NSRelationshipDescription()
        addressPersonRelationship.name = "person"
        addressPersonRelationship.destinationEntity = personEntity
        addressPersonRelationship.minCount = 0
        addressPersonRelationship.maxCount = 1
        addressPersonRelationship.deleteRule = .nullifyDeleteRule
        
        personAddressRelationship.inverseRelationship = addressPersonRelationship
        addressPersonRelationship.inverseRelationship = personAddressRelationship
        
        personEntity.properties.append(personAddressRelationship)
        addressEntity.properties.append(addressPersonRelationship)
        
        model.entities = [personEntity, addressEntity]
        
        return model
    }
    
    // MARK: - Configuration Tests
    
    func testConfigureWithContainer() {
        // Given
        let container = persistentContainer!
        
        // When
        manager.configure(container: container)
        
        // Then
        let contexts = manager.getAvailableContexts()
        XCTAssertEqual(contexts.count, 1)
        XCTAssertEqual(contexts.first?.name, "Main")
    }
    
    func testConfigureWithContext() {
        // Given
        let context = testContext!
        
        // When
        manager.configure(context: context)
        
        // Then
        let contexts = manager.getAvailableContexts()
        XCTAssertEqual(contexts.count, 1)
        XCTAssertEqual(contexts.first?.name, "Main")
    }
    
    func testConfigureWithMultipleContexts() {
        // Given
        let mainContext = testContext!
        let backgroundContext = persistentContainer.newBackgroundContext()
        let contexts = ["Main": mainContext, "Background": backgroundContext]
        
        // When
        manager.configure(contexts: contexts)
        
        // Then
        let availableContexts = manager.getAvailableContexts()
        XCTAssertEqual(availableContexts.count, 2)
        XCTAssertTrue(availableContexts.contains(where: { $0.name == "Main" }))
        XCTAssertTrue(availableContexts.contains(where: { $0.name == "Background" }))
    }
    
    func testGetDefaultContext() {
        // Given
        manager.configure(container: persistentContainer)
        
        // When
        let defaultContext = manager.getDefaultContext()
        
        // Then
        XCTAssertNotNil(defaultContext)
        XCTAssertEqual(defaultContext, testContext)
    }
    
    // MARK: - Entity Discovery Tests
    
    func testGetEntities() {
        // Given
        manager.configure(context: testContext)
        
        // When
        let entities = manager.getEntities(for: testContext)
        
        // Then
        XCTAssertEqual(entities.count, 2)
        XCTAssertTrue(entities.contains(where: { $0.name == "Person" }))
        XCTAssertTrue(entities.contains(where: { $0.name == "Address" }))
    }
    
    func testGetEntitiesWithAttributes() {
        // Given
        manager.configure(context: testContext)
        
        // When
        let entities = manager.getEntities(for: testContext)
        let personEntity = entities.first(where: { $0.name == "Person" })
        
        // Then
        XCTAssertNotNil(personEntity)
        XCTAssertEqual(personEntity?.attributes.count, 2)
        XCTAssertTrue(personEntity?.attributes.contains(where: { $0.name == "name" }) ?? false)
        XCTAssertTrue(personEntity?.attributes.contains(where: { $0.name == "age" }) ?? false)
    }
    
    func testGetEntitiesWithRelationships() {
        // Given
        manager.configure(context: testContext)
        
        // When
        let entities = manager.getEntities(for: testContext)
        let personEntity = entities.first(where: { $0.name == "Person" })
        
        // Then
        XCTAssertNotNil(personEntity)
        XCTAssertEqual(personEntity?.relationships.count, 1)
        XCTAssertEqual(personEntity?.relationships.first?.name, "address")
        XCTAssertEqual(personEntity?.relationships.first?.destinationEntity, "Address")
    }
    
    func testEntityObjectCount() {
        // Given
        manager.configure(context: testContext)
        createTestPerson(name: "John", age: 30)
        createTestPerson(name: "Jane", age: 25)
        
        // When
        let entities = manager.getEntities(for: testContext)
        let personEntity = entities.first(where: { $0.name == "Person" })
        
        // Then
        XCTAssertEqual(personEntity?.objectCount, 2)
    }
    
    // MARK: - Fetch Objects Tests
    
    func testFetchObjects() {
        // Given
        manager.configure(context: testContext)
        createTestPerson(name: "John", age: 30)
        createTestPerson(name: "Jane", age: 25)
        
        // When
        let objects = manager.fetchObjects(entityName: "Person", context: testContext)
        
        // Then
        XCTAssertEqual(objects.count, 2)
    }
    
    func testFetchObjectsWithPredicate() {
        // Given
        manager.configure(context: testContext)
        createTestPerson(name: "John", age: 30)
        createTestPerson(name: "Jane", age: 25)
        
        // When
        let predicate = NSPredicate(format: "name == %@", "John")
        let objects = manager.fetchObjects(entityName: "Person", context: testContext, predicate: predicate)
        
        // Then
        XCTAssertEqual(objects.count, 1)
        XCTAssertEqual(objects.first?.value(forKey: "name") as? String, "John")
    }
    
    func testFetchObjectsWithSortDescriptors() {
        // Given
        manager.configure(context: testContext)
        createTestPerson(name: "John", age: 30)
        createTestPerson(name: "Alice", age: 25)
        createTestPerson(name: "Bob", age: 35)
        
        // When
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let objects = manager.fetchObjects(entityName: "Person", context: testContext, sortDescriptors: [sortDescriptor])
        
        // Then
        XCTAssertEqual(objects.count, 3)
        XCTAssertEqual(objects[0].value(forKey: "name") as? String, "Alice")
        XCTAssertEqual(objects[1].value(forKey: "name") as? String, "Bob")
        XCTAssertEqual(objects[2].value(forKey: "name") as? String, "John")
    }
    
    func testFetchObjectsWithLimit() {
        // Given
        manager.configure(context: testContext)
        for i in 1...10 {
            createTestPerson(name: "Person \(i)", age: Int32(20 + i))
        }
        
        // When
        let objects = manager.fetchObjects(entityName: "Person", context: testContext, limit: 5)
        
        // Then
        XCTAssertEqual(objects.count, 5)
    }
    
    // MARK: - Save and Delete Tests
    
    func testSaveContext() throws {
        // Given
        manager.configure(context: testContext)
        let person = NSEntityDescription.insertNewObject(forEntityName: "Person", into: testContext)
        person.setValue("John", forKey: "name")
        person.setValue(30, forKey: "age")
        
        // When
        try manager.save(context: testContext)
        
        // Then
        let objects = manager.fetchObjects(entityName: "Person", context: testContext)
        XCTAssertEqual(objects.count, 1)
    }
    
    func testDeleteObject() throws {
        // Given
        manager.configure(context: testContext)
        let person = createTestPerson(name: "John", age: 30)
        
        // When
        try manager.deleteObject(person, context: testContext)
        
        // Then
        let objects = manager.fetchObjects(entityName: "Person", context: testContext)
        XCTAssertEqual(objects.count, 0)
    }
    
    func testRollback() {
        // Given
        manager.configure(context: testContext)
        createTestPerson(name: "John", age: 30)
        let person = NSEntityDescription.insertNewObject(forEntityName: "Person", into: testContext)
        person.setValue("Jane", forKey: "name")
        person.setValue(25, forKey: "age")
        
        // When
        manager.rollback(context: testContext)
        
        // Then
        let objects = manager.fetchObjects(entityName: "Person", context: testContext)
        XCTAssertEqual(objects.count, 1) // Only the saved one remains
    }
    
    // MARK: - Helper Methods
    
    @discardableResult
    func createTestPerson(name: String, age: Int32) -> NSManagedObject {
        let person = NSEntityDescription.insertNewObject(forEntityName: "Person", into: testContext)
        person.setValue(name, forKey: "name")
        person.setValue(Int32(age), forKey: "age")
        try? testContext.save()
        return person
    }
}

// MARK: - NSAttributeType Extension Tests

final class NSAttributeTypeExtensionTests: XCTestCase {
    
    func testDisplayNameForAllTypes() {
        // Given / When / Then
        XCTAssertEqual(NSAttributeType.integer16AttributeType.displayName, "Int16")
        XCTAssertEqual(NSAttributeType.integer32AttributeType.displayName, "Int32")
        XCTAssertEqual(NSAttributeType.integer64AttributeType.displayName, "Int64")
        XCTAssertEqual(NSAttributeType.decimalAttributeType.displayName, "Decimal")
        XCTAssertEqual(NSAttributeType.doubleAttributeType.displayName, "Double")
        XCTAssertEqual(NSAttributeType.floatAttributeType.displayName, "Float")
        XCTAssertEqual(NSAttributeType.stringAttributeType.displayName, "String")
        XCTAssertEqual(NSAttributeType.booleanAttributeType.displayName, "Bool")
        XCTAssertEqual(NSAttributeType.dateAttributeType.displayName, "Date")
        XCTAssertEqual(NSAttributeType.binaryDataAttributeType.displayName, "Data")
        XCTAssertEqual(NSAttributeType.UUIDAttributeType.displayName, "UUID")
        XCTAssertEqual(NSAttributeType.URIAttributeType.displayName, "URI")
        XCTAssertEqual(NSAttributeType.transformableAttributeType.displayName, "Transformable")
        XCTAssertEqual(NSAttributeType.objectIDAttributeType.displayName, "ObjectID")
        
        if #available(iOS 17.0, *) {
            XCTAssertEqual(NSAttributeType.compositeAttributeType.displayName, "Composite")
        }
    }
}

// MARK: - NSDeleteRule Extension Tests

final class NSDeleteRuleExtensionTests: XCTestCase {
    
    func testDisplayNameForAllRules() {
        // Given / When / Then
        XCTAssertEqual(NSDeleteRule.noActionDeleteRule.displayName, "No Action")
        XCTAssertEqual(NSDeleteRule.nullifyDeleteRule.displayName, "Nullify")
        XCTAssertEqual(NSDeleteRule.cascadeDeleteRule.displayName, "Cascade")
        XCTAssertEqual(NSDeleteRule.denyDeleteRule.displayName, "Deny")
    }
}

// MARK: - Core Data Models Tests

final class CoreDataModelsTests: XCTestCase {
    
    func testCoreDataEntityModel() {
        // Given
        let attributes = [
            CoreDataAttribute(name: "name", type: "String", isOptional: false, defaultValue: nil),
            CoreDataAttribute(name: "age", type: "Int32", isOptional: false, defaultValue: 0)
        ]
        
        let relationships = [
            CoreDataRelationship(
                name: "address",
                destinationEntity: "Address",
                isToMany: false,
                isOptional: true,
                deleteRule: "Cascade"
            )
        ]
        
        // When
        let entity = CoreDataEntity(
            name: "Person",
            managedObjectClassName: "Person",
            objectCount: 10,
            attributes: attributes,
            relationships: relationships
        )
        
        // Then
        XCTAssertEqual(entity.name, "Person")
        XCTAssertEqual(entity.objectCount, 10)
        XCTAssertEqual(entity.attributes.count, 2)
        XCTAssertEqual(entity.relationships.count, 1)
    }
    
    func testCoreDataAttributeModel() {
        // Given / When
        let attribute = CoreDataAttribute(
            name: "email",
            type: "String",
            isOptional: true,
            defaultValue: "test@example.com"
        )
        
        // Then
        XCTAssertEqual(attribute.name, "email")
        XCTAssertEqual(attribute.type, "String")
        XCTAssertTrue(attribute.isOptional)
        XCTAssertEqual(attribute.defaultValue as? String, "test@example.com")
    }
    
    func testCoreDataRelationshipModel() {
        // Given / When
        let relationship = CoreDataRelationship(
            name: "tasks",
            destinationEntity: "Task",
            isToMany: true,
            isOptional: false,
            deleteRule: "Cascade"
        )
        
        // Then
        XCTAssertEqual(relationship.name, "tasks")
        XCTAssertEqual(relationship.destinationEntity, "Task")
        XCTAssertTrue(relationship.isToMany)
        XCTAssertFalse(relationship.isOptional)
        XCTAssertEqual(relationship.deleteRule, "Cascade")
    }
}
