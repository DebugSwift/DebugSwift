//
//  ExampleModel.swift
//  Example
//
//  Programmatic Core Data model definition
//

import Foundation
import CoreData

extension NSPersistentContainer {
    convenience init(name: String) {
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
        
        let birthDateAttribute = NSAttributeDescription()
        birthDateAttribute.name = "birthDate"
        birthDateAttribute.attributeType = .dateAttributeType
        birthDateAttribute.isOptional = true
        
        let isActiveAttribute = NSAttributeDescription()
        isActiveAttribute.name = "isActive"
        isActiveAttribute.attributeType = .booleanAttributeType
        isActiveAttribute.isOptional = false
        isActiveAttribute.defaultValue = true
        
        personEntity.properties = [nameAttribute, ageAttribute, birthDateAttribute, isActiveAttribute]
        
        // Address Entity
        let addressEntity = NSEntityDescription()
        addressEntity.name = "Address"
        addressEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        
        let streetAttribute = NSAttributeDescription()
        streetAttribute.name = "street"
        streetAttribute.attributeType = .stringAttributeType
        streetAttribute.isOptional = false
        
        let cityAttribute = NSAttributeDescription()
        cityAttribute.name = "city"
        cityAttribute.attributeType = .stringAttributeType
        cityAttribute.isOptional = false
        
        let zipCodeAttribute = NSAttributeDescription()
        zipCodeAttribute.name = "zipCode"
        zipCodeAttribute.attributeType = .stringAttributeType
        zipCodeAttribute.isOptional = true
        
        addressEntity.properties = [streetAttribute, cityAttribute, zipCodeAttribute]
        
        // Task Entity
        let taskEntity = NSEntityDescription()
        taskEntity.name = "Task"
        taskEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        
        let titleAttribute = NSAttributeDescription()
        titleAttribute.name = "title"
        titleAttribute.attributeType = .stringAttributeType
        titleAttribute.isOptional = false
        
        let taskDescriptionAttribute = NSAttributeDescription()
        taskDescriptionAttribute.name = "taskDescription"
        taskDescriptionAttribute.attributeType = .stringAttributeType
        taskDescriptionAttribute.isOptional = true
        
        let isCompletedAttribute = NSAttributeDescription()
        isCompletedAttribute.name = "isCompleted"
        isCompletedAttribute.attributeType = .booleanAttributeType
        isCompletedAttribute.isOptional = false
        isCompletedAttribute.defaultValue = false
        
        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = false
        
        taskEntity.properties = [titleAttribute, taskDescriptionAttribute, isCompletedAttribute, createdAtAttribute]
        
        // Relationships
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
        
        let personTasksRelationship = NSRelationshipDescription()
        personTasksRelationship.name = "tasks"
        personTasksRelationship.destinationEntity = taskEntity
        personTasksRelationship.minCount = 0
        personTasksRelationship.maxCount = 0
        personTasksRelationship.deleteRule = .cascadeDeleteRule
        
        let taskPersonRelationship = NSRelationshipDescription()
        taskPersonRelationship.name = "person"
        taskPersonRelationship.destinationEntity = personEntity
        taskPersonRelationship.minCount = 0
        taskPersonRelationship.maxCount = 1
        taskPersonRelationship.deleteRule = .nullifyDeleteRule
        
        personTasksRelationship.inverseRelationship = taskPersonRelationship
        taskPersonRelationship.inverseRelationship = personTasksRelationship
        
        personEntity.properties.append(personTasksRelationship)
        taskEntity.properties.append(taskPersonRelationship)
        
        model.entities = [personEntity, addressEntity, taskEntity]
        
        self.init(name: name, managedObjectModel: model)
    }
}
