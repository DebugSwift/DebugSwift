//
//  SwiftDataExample.swift
//  Example
//
//  SwiftData example setup for DebugSwift testing
//

import Foundation
import DebugSwift

#if canImport(SwiftData)
import SwiftData

@available(iOS 17.0, *)
@Model
final class SwiftDataPerson {
    var name: String
    var age: Int
    var createdAt: Date

    init(name: String, age: Int, createdAt: Date = Date()) {
        self.name = name
        self.age = age
        self.createdAt = createdAt
    }
}

@available(iOS 17.0, *)
@MainActor
final class SwiftDataExample {
    static let shared = SwiftDataExample()

    private init() {}

    lazy var modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: SwiftDataPerson.self)
        } catch {
            fatalError("Unable to create SwiftData model container: \(error)")
        }
    }()

    func setupDebugSwift() {
        let models: [SwiftDataModelRegistration] = [
            .init(SwiftDataPerson.self, displayName: "SwiftData Person") {
                SwiftDataPerson(
                    name: "New Person",
                    age: Int.random(in: 18...65)
                )
            }
        ]

        DebugSwift.Resources.shared.configureSwiftData(contexts: [
            .init(name: "Main", container: modelContainer, models: models)
        ])
    }

    func createSampleDataIfNeeded() {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<SwiftDataPerson>()

        do {
            let existing = try context.fetch(descriptor)
            guard existing.isEmpty else { return }

            for i in 1...5 {
                let person = SwiftDataPerson(
                    name: "SwiftData Person \(i)",
                    age: 20 + i,
                    createdAt: Date().addingTimeInterval(TimeInterval(-i * 3_600))
                )
                context.insert(person)
            }

            try context.save()
            print("✅ Sample SwiftData created successfully")
        } catch {
            print("❌ Failed to setup SwiftData sample data: \(error)")
        }
    }
}

#endif
