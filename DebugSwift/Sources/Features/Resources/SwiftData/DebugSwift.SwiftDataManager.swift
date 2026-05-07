//
//  DebugSwift.SwiftDataManager.swift
//  DebugSwift
//
//  SwiftData stack management and model discovery for the browser
//

import Foundation

#if canImport(SwiftData)
import SwiftData

@available(iOS 17.0, *)
@MainActor
final class SwiftDataManager: @unchecked Sendable {
    static let shared = SwiftDataManager()

    private init() {}

    // MARK: - State

    private var registrations: [SwiftDataContextRegistration] = []
    var readOnlyMode: Bool = false

    // MARK: - Configuration

    func configure(contexts: [SwiftDataContextRegistration]) {
        self.registrations = contexts
    }

    // MARK: - Public Accessors

    func getAvailableContexts() -> [SwiftDataContextRegistration] {
        return registrations
    }

    func getDefaultContext() -> SwiftDataContextRegistration? {
        return registrations.first
    }

    // MARK: - Fetch

    func fetchInstances(
        registration: SwiftDataModelRegistration,
        context: ModelContext
    ) throws -> [any PersistentModel] {
        return try registration.fetch(context)
    }

    // MARK: - Delete

    func deleteInstance(
        _ model: any PersistentModel,
        registration: SwiftDataModelRegistration,
        context: ModelContext
    ) throws {
        try registration.delete(context, model)
        try context.save()
    }

    // MARK: - Property Reflection

    /// Returns a list of (label, value) tuples for all stored properties on a PersistentModel.
    func properties(of model: any PersistentModel) -> [(label: String, value: String)] {
        let mirror = Mirror(reflecting: model)
        var result: [(String, String)] = []

        for child in mirror.children {
            guard let label = child.label else { continue }
            // Skip SwiftData internals (_$backingData, etc.)
            if label.hasPrefix("_$") { continue }
            let cleaned = label.hasPrefix("_") ? String(label.dropFirst()) : label
            result.append((cleaned, formatValue(child.value)))
        }

        return result.sorted { $0.0 < $1.0 }
    }

    // MARK: - Helpers

    private func formatValue(_ value: Any) -> String {
        if let optional = value as? any _OptionalProtocol {
            guard let wrapped = optional.wrappedValue else { return "nil" }
            return formatValue(wrapped)
        }
        switch value {
        case let date as Date:
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium
            return formatter.string(from: date)
        case let data as Data:
            return "\(data.count) bytes"
        case let url as URL:
            return url.absoluteString
        case let uuid as UUID:
            return uuid.uuidString
        default:
            let s = String(describing: value)
            return s.count > 80 ? String(s.prefix(77)) + "..." : s
        }
    }
}

// MARK: - Internal Optional helper

private protocol _OptionalProtocol {
    var wrappedValue: Any? { get }
}
extension Optional: _OptionalProtocol {
    var wrappedValue: Any? {
        switch self {
        case .none: return nil
        case .some(let v): return v
        }
    }
}

#endif
