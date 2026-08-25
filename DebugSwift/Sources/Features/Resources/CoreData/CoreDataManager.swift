//
//  CoreDataManager.swift
//  DebugSwift
//
//  Core Data stack management and entity discovery
//

import Foundation
import CoreData

@MainActor
final class CoreDataManager: @unchecked Sendable {
    static let shared = CoreDataManager()
    
    private init() {}
    
    private var container: NSPersistentContainer?
    private var contexts: [String: NSManagedObjectContext] = [:]
    
    // MARK: - Configuration
    
    func configure(container: NSPersistentContainer) {
        self.container = container
        self.contexts = ["Main": container.viewContext]
    }
    
    func configure(context: NSManagedObjectContext) {
        self.contexts = ["Main": context]
        self.container = context.persistentStoreCoordinator?.persistentStores.first?.url.map { url in
            guard let model = context.persistentStoreCoordinator?.managedObjectModel else { return nil }
            let container = NSPersistentContainer(name: "DebugContainer", managedObjectModel: model)
            return container
        } ?? nil
    }
    
    func configure(contexts: [String: NSManagedObjectContext]) {
        self.contexts = contexts
        if let firstContext = contexts.values.first {
            self.container = firstContext.persistentStoreCoordinator?.persistentStores.first?.url.map { url in
                guard let model = firstContext.persistentStoreCoordinator?.managedObjectModel else { return nil }
                let container = NSPersistentContainer(name: "DebugContainer", managedObjectModel: model)
                return container
            } ?? nil
        }
    }
    
    // MARK: - Public Methods
    
    func getAvailableContexts() -> [(name: String, context: NSManagedObjectContext)] {
        return contexts.map { (name: $0.key, context: $0.value) }.sorted { $0.name < $1.name }
    }
    
    func getDefaultContext() -> NSManagedObjectContext? {
        return contexts["Main"] ?? contexts.values.first
    }
    
    func getEntities(for context: NSManagedObjectContext) -> [CoreDataEntity] {
        guard let model = context.persistentStoreCoordinator?.managedObjectModel else {
            return []
        }
        
        return model.entities.compactMap { entityDescription in
            guard let entityName = entityDescription.name else { return nil }
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let count = (try? context.count(for: fetchRequest)) ?? 0
            
            return CoreDataEntity(
                name: entityName,
                managedObjectClassName: entityDescription.managedObjectClassName ?? "",
                objectCount: count,
                attributes: entityDescription.attributesByName.map { (name, attribute) in
                    CoreDataAttribute(
                        name: name,
                        type: attribute.attributeType.displayName,
                        isOptional: attribute.isOptional,
                        defaultValue: attribute.defaultValue
                    )
                }.sorted { $0.name < $1.name },
                relationships: entityDescription.relationshipsByName.map { (name, relationship) in
                    CoreDataRelationship(
                        name: name,
                        destinationEntity: relationship.destinationEntity?.name ?? "",
                        isToMany: relationship.isToMany,
                        isOptional: relationship.isOptional,
                        deleteRule: relationship.deleteRule.displayName
                    )
                }.sorted { $0.name < $1.name }
            )
        }.sorted { $0.name < $1.name }
    }
    
    func fetchObjects(
        entityName: String,
        context: NSManagedObjectContext,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        limit: Int? = nil
    ) -> [NSManagedObject] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        if let limit = limit {
            fetchRequest.fetchLimit = limit
        }
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching objects: \(error)")
            return []
        }
    }
    
    func deleteObject(_ object: NSManagedObject, context: NSManagedObjectContext) throws {
        context.delete(object)
        try context.save()
    }
    
    func save(context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
    func rollback(context: NSManagedObjectContext) {
        context.rollback()
    }
}

// MARK: - Models

struct CoreDataEntity {
    let name: String
    let managedObjectClassName: String
    let objectCount: Int
    let attributes: [CoreDataAttribute]
    let relationships: [CoreDataRelationship]
}

struct CoreDataAttribute {
    let name: String
    let type: String
    let isOptional: Bool
    let defaultValue: Any?
}

struct CoreDataRelationship {
    let name: String
    let destinationEntity: String
    let isToMany: Bool
    let isOptional: Bool
    let deleteRule: String
}

// MARK: - Extensions

extension NSAttributeType {
    var displayName: String {
        switch self {
        case .integer16AttributeType:
            return "Int16"
        case .integer32AttributeType:
            return "Int32"
        case .integer64AttributeType:
            return "Int64"
        case .decimalAttributeType:
            return "Decimal"
        case .doubleAttributeType:
            return "Double"
        case .floatAttributeType:
            return "Float"
        case .stringAttributeType:
            return "String"
        case .booleanAttributeType:
            return "Bool"
        case .dateAttributeType:
            return "Date"
        case .binaryDataAttributeType:
            return "Data"
        case .UUIDAttributeType:
            return "UUID"
        case .URIAttributeType:
            return "URI"
        case .transformableAttributeType:
            return "Transformable"
        case .objectIDAttributeType:
            return "ObjectID"
        case .compositeAttributeType:
            return "Composite"
        case .undefinedAttributeType:
            return "Undefined"
        @unknown default:
            return "Unknown"
        }
    }
}

extension NSDeleteRule {
    var displayName: String {
        switch self {
        case .noActionDeleteRule:
            return "No Action"
        case .nullifyDeleteRule:
            return "Nullify"
        case .cascadeDeleteRule:
            return "Cascade"
        case .denyDeleteRule:
            return "Deny"
        @unknown default:
            return "Unknown"
        }
    }
}
