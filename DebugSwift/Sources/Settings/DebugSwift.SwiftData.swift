//
//  DebugSwift.SwiftData.swift
//  DebugSwift
//
//  Public configuration for SwiftData browser
//

import Foundation

#if canImport(SwiftData)
import SwiftData

@available(iOS 17.0, *)
public struct SwiftDataContextRegistration {
    public let name: String
    public let container: ModelContainer
    public let models: [SwiftDataModelRegistration]

    public init(
        name: String,
        container: ModelContainer,
        models: [SwiftDataModelRegistration]
    ) {
        self.name = name
        self.container = container
        self.models = models
    }
}

@available(iOS 17.0, *)
public struct SwiftDataModelRegistration {
    public let displayName: String
    let entityName: String
    let fetch: (@MainActor @Sendable (ModelContext) throws -> [any PersistentModel])
    let create: (@MainActor @Sendable () -> (any PersistentModel))?
    let delete: (@MainActor @Sendable (ModelContext, any PersistentModel) throws -> Void)

    public init<T: PersistentModel>(
        _ type: T.Type,
        displayName: String? = nil,
        create: (@MainActor @Sendable () -> T)? = nil
    ) {
        self.displayName = displayName ?? String(describing: type)
        entityName = String(describing: type)

        fetch = { context in
            let descriptor = FetchDescriptor<T>()
            return try context.fetch(descriptor).map { $0 as any PersistentModel }
        }

        if let create {
            self.create = {
                create() as any PersistentModel
            }
        } else {
            self.create = nil
        }

        delete = { context, model in
            guard let typedModel = model as? T else {
                throw SwiftDataBrowserError.invalidModelType
            }
            context.delete(typedModel)
        }
    }
}

@available(iOS 17.0, *)
public enum SwiftDataBrowserError: LocalizedError {
    case invalidModelType
    case unsupportedEditType
    case propertyUpdateFailed

    public var errorDescription: String? {
        switch self {
        case .invalidModelType:
            return "Invalid model type for this operation."
        case .unsupportedEditType:
            return "Unsupported value type for editing."
        case .propertyUpdateFailed:
            return "Failed to update property."
        }
    }
}

#endif
