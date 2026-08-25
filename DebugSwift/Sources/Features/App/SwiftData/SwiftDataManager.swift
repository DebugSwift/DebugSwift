//
//  SwiftDataManager.swift
//  DebugSwift
//
//  SwiftData runtime browsing and editing helpers
//

import Foundation

#if canImport(SwiftData)
import SwiftData

@available(iOS 17.0, *)
@MainActor
final class SwiftDataManager {
    static let shared = SwiftDataManager()

    private init() {}

    private var contexts: [SwiftDataContextRegistration] = []
    var readOnlyMode = false

    func configure(contexts: [SwiftDataContextRegistration]) {
        self.contexts = contexts
    }

    func getAvailableContexts() -> [SwiftDataContextRegistration] {
        contexts.sorted { $0.name < $1.name }
    }

    func getDefaultContext() -> SwiftDataContextRegistration? {
        contexts.sorted { $0.name < $1.name }.first
    }

    func getEntities(for registration: SwiftDataContextRegistration) -> [SwiftDataEntity] {
        let entityNames = registration.container.schema.entitiesByName.keys.sorted()
        return entityNames.map { entityName in
            let modelRegistration = modelRegistration(
                forEntityName: entityName,
                in: registration
            )
            let count = (try? objectCount(for: entityName, in: registration)) ?? 0
            return SwiftDataEntity(
                name: entityName,
                displayName: modelRegistration?.displayName ?? entityName,
                objectCount: count,
                isBrowsable: modelRegistration != nil
            )
        }
    }

    func objectCount(for entityName: String, in registration: SwiftDataContextRegistration) throws -> Int {
        guard let modelRegistration = modelRegistration(
            forEntityName: entityName,
            in: registration
        ) else {
            return 0
        }
        let context = registration.container.mainContext
        return try modelRegistration.fetch(context).count
    }

    func fetchModels(
        entityName: String,
        in registration: SwiftDataContextRegistration
    ) throws -> [any PersistentModel] {
        guard let modelRegistration = modelRegistration(
            forEntityName: entityName,
            in: registration
        ) else {
            return []
        }
        return try modelRegistration.fetch(registration.container.mainContext)
    }

    func createModel(
        entityName: String,
        in registration: SwiftDataContextRegistration
    ) throws {
        guard let modelRegistration = modelRegistration(
            forEntityName: entityName,
            in: registration
        ) else {
            return
        }

        guard let model = modelRegistration.create?() else {
            return
        }

        let context = registration.container.mainContext
        context.insert(model)
        try context.save()
    }

    func deleteModel(
        _ model: any PersistentModel,
        entityName: String,
        in registration: SwiftDataContextRegistration
    ) throws {
        guard let modelRegistration = modelRegistration(
            forEntityName: entityName,
            in: registration
        ) else {
            throw SwiftDataBrowserError.invalidModelType
        }
        let context = registration.container.mainContext
        try modelRegistration.delete(context, model)
        try context.save()
    }

    func getProperties(
        for model: any PersistentModel,
        entityName: String,
        in registration: SwiftDataContextRegistration
    ) -> [SwiftDataPropertyItem] {
        guard let entity = registration.container.schema.entitiesByName[entityName] else {
            return []
        }

        let reflectedValues: [String: Any] = Mirror(reflecting: model).children.reduce(into: [:]) { partialResult, child in
            guard let name = child.label else { return }
            partialResult[name] = child.value
        }

        let properties = entity.storedProperties.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }

        return properties.map { property in
            let value = reflectedValues[property.name]
            return SwiftDataPropertyItem(
                name: property.name,
                valueDescription: formatValue(value),
                isRelationship: property.isRelationship,
                isAttribute: property.isAttribute,
                isTransient: property.isTransient,
                isOptional: property.isOptional,
                isUnique: property.isUnique,
                typeName: String(describing: property.valueType),
                rawValue: value
            )
        }
    }

    func updateProperty(
        model: any PersistentModel,
        entityName: String,
        propertyName: String,
        newValueText: String,
        in registration: SwiftDataContextRegistration
    ) throws {
        guard !DebugSwift.Resources.shared.swiftDataReadOnly else {
            return
        }

        guard let object = model as? NSObject else {
            throw SwiftDataBrowserError.propertyUpdateFailed
        }

        let properties = getProperties(for: model, entityName: entityName, in: registration)
        guard let property = properties.first(where: { $0.name == propertyName }),
              let existingValue = property.rawValue else {
            throw SwiftDataBrowserError.propertyUpdateFailed
        }

        guard let parsedValue = parseValue(newValueText, basedOn: existingValue) else {
            throw SwiftDataBrowserError.unsupportedEditType
        }

        object.setValue(parsedValue, forKey: propertyName)
        try registration.container.mainContext.save()
    }

    func exportAsJSON(
        entityName: String,
        in registration: SwiftDataContextRegistration
    ) throws -> String {
        let models = try fetchModels(entityName: entityName, in: registration)

        let dictionaries = models.map { model -> [String: String] in
            Dictionary(
                uniqueKeysWithValues: Mirror(reflecting: model).children.compactMap { child in
                    guard let label = child.label else { return nil }
                    return (label, formatValue(child.value))
                }
            )
        }

        let data = try JSONSerialization.data(withJSONObject: dictionaries, options: [.prettyPrinted])
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    func makeSummary(for model: any PersistentModel) -> String {
        let values = Mirror(reflecting: model).children.compactMap { child -> String? in
            guard let label = child.label else { return nil }
            let value = formatValue(child.value)
            guard !value.isEmpty else { return nil }
            return "\(label): \(value)"
        }
        return values.prefix(2).joined(separator: " | ")
    }

    private func modelRegistration(
        forEntityName entityName: String,
        in registration: SwiftDataContextRegistration
    ) -> SwiftDataModelRegistration? {
        let normalizedEntityName = normalizeEntityName(entityName)
        return registration.models.first { model in
            normalizeEntityName(model.entityName) == normalizedEntityName
        }
    }

    private func normalizeEntityName(_ name: String) -> String {
        name.split(separator: ".").last.map(String.init) ?? name
    }

    private func parseValue(_ text: String, basedOn existingValue: Any) -> Any? {
        if existingValue is String {
            return text
        }

        if existingValue is Int {
            return Int(text)
        }

        if existingValue is Int16 {
            return Int16(text)
        }

        if existingValue is Int32 {
            return Int32(text)
        }

        if existingValue is Int64 {
            return Int64(text)
        }

        if existingValue is Double {
            return Double(text)
        }

        if existingValue is Float {
            return Float(text)
        }

        if existingValue is Bool {
            let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if normalized == "true" || normalized == "1" {
                return true
            }
            if normalized == "false" || normalized == "0" {
                return false
            }
            return nil
        }

        if existingValue is Date {
            return ISO8601DateFormatter().date(from: text)
        }

        return nil
    }

    private func formatValue(_ value: Any?) -> String {
        guard let value else { return "nil" }

        if let date = value as? Date {
            return ISO8601DateFormatter().string(from: date)
        }

        if let data = value as? Data {
            return "\(data.count) bytes"
        }

        let raw = String(describing: value)
        if raw.count > 200 {
            return String(raw.prefix(200)) + "..."
        }
        return raw
    }
}

@available(iOS 17.0, *)
struct SwiftDataEntity {
    let name: String
    let displayName: String
    let objectCount: Int
    let isBrowsable: Bool
}

@available(iOS 17.0, *)
struct SwiftDataPropertyItem {
    let name: String
    let valueDescription: String
    let isRelationship: Bool
    let isAttribute: Bool
    let isTransient: Bool
    let isOptional: Bool
    let isUnique: Bool
    let typeName: String
    let rawValue: Any?
}

#endif
