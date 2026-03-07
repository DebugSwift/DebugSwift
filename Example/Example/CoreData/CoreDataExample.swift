//
//  CoreDataExample.swift
//  Example
//
//  Core Data example setup for DebugSwift testing
//

import Foundation
import CoreData
import DebugSwift

class CoreDataExample: @unchecked Sendable {
    static let shared = CoreDataExample()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ExampleModel")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func setupDebugSwift() {
        DebugSwift.Resources.shared.configureCoreData(container: persistentContainer)
    }
    
    func createSampleData() {
        let context = viewContext
        
        for i in 1...10 {
            let person = NSEntityDescription.insertNewObject(forEntityName: "Person", into: context)
            person.setValue("Person \(i)", forKey: "name")
            person.setValue(20 + i, forKey: "age")
            person.setValue(Date().addingTimeInterval(TimeInterval(-i * 86400)), forKey: "birthDate")
            person.setValue(i % 2 == 0, forKey: "isActive")
            
            if i % 2 == 0 {
                let address = NSEntityDescription.insertNewObject(forEntityName: "Address", into: context)
                address.setValue("Street \(i)", forKey: "street")
                address.setValue("City \(i)", forKey: "city")
                address.setValue("1000\(i)", forKey: "zipCode")
                person.setValue(address, forKey: "address")
            }
            
            if i <= 5 {
                for j in 1...3 {
                    let task = NSEntityDescription.insertNewObject(forEntityName: "Task", into: context)
                    task.setValue("Task \(i)-\(j)", forKey: "title")
                    task.setValue("Description for task \(i)-\(j)", forKey: "taskDescription")
                    task.setValue(j % 2 == 0, forKey: "isCompleted")
                    task.setValue(Date(), forKey: "createdAt")
                    
                    if let tasks = person.mutableSetValue(forKey: "tasks") as? NSMutableSet {
                        tasks.add(task)
                    }
                }
            }
        }
        
        do {
            try context.save()
            print("✅ Sample Core Data created successfully")
        } catch {
            print("❌ Failed to save sample data: \(error)")
        }
    }
}
