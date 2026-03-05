//
//  ObjectIntrospector.swift
//  DebugSwift
//
//  Created by DebugSwift on 2025.
//

import Foundation
import ObjectiveC
import UIKit

// MARK: - Data Models

struct ObjectProperty {
    let name: String
    let typeName: String
    let value: String
    let rawValue: Any?
    let isReadOnly: Bool
}

struct ObjectMethod {
    let name: String
    let argumentCount: Int
}

struct ObjectIvar {
    let name: String
    let typeName: String
    let value: String
    let rawValue: Any?
}

struct ObjectIdentity {
    let className: String
    let memoryAddress: String
    let isObjCClass: Bool
    let superclassChain: [String]
}

// MARK: - Section Types

enum ObjectExplorerSection: Int, CaseIterable {
    case identity
    case properties
    case ivars
    case methods
    case superclass

    var title: String {
        switch self {
        case .identity:
            return "Identity"
        case .properties:
            return "Properties"
        case .ivars:
            return "Ivars"
        case .methods:
            return "Methods"
        case .superclass:
            return "Superclass Chain"
        }
    }
}

// MARK: - Introspector

@MainActor
final class ObjectIntrospector {
    let object: Any
    private let mirror: Mirror

    private(set) var identity: ObjectIdentity
    private(set) var properties: [ObjectProperty] = []
    private(set) var ivars: [ObjectIvar] = []
    private(set) var methods: [ObjectMethod] = []

    init(object: Any) {
        self.object = object
        self.mirror = Mirror(reflecting: object)
        self.identity = ObjectIntrospector.buildIdentity(for: object, mirror: mirror)
        self.properties = ObjectIntrospector.buildProperties(for: object, mirror: mirror)
        self.ivars = ObjectIntrospector.buildIvars(for: object)
        self.methods = ObjectIntrospector.buildMethods(for: object)
    }

    // MARK: - Identity

    private static func buildIdentity(for object: Any, mirror: Mirror) -> ObjectIdentity {
        let className: String
        let address: String
        let isObjC: Bool

        if let nsObject = object as? NSObject {
            className = NSStringFromClass(type(of: nsObject))
            address = String(format: "%p", unsafeBitCast(nsObject, to: Int.self))
            isObjC = true
        } else {
            className = String(describing: type(of: object))
            address = "N/A (value type)"
            isObjC = false
        }

        var superclassChain: [String] = []
        if let nsObject = object as? NSObject {
            var currentClass: AnyClass? = type(of: nsObject).superclass()
            while let cls = currentClass {
                superclassChain.append(NSStringFromClass(cls))
                currentClass = cls.superclass()
            }
        } else {
            var currentMirror = mirror.superclassMirror
            while let m = currentMirror {
                superclassChain.append(String(describing: m.subjectType))
                currentMirror = m.superclassMirror
            }
        }

        return ObjectIdentity(
            className: className,
            memoryAddress: address,
            isObjCClass: isObjC,
            superclassChain: superclassChain
        )
    }

    // MARK: - Properties (Swift Mirror + ObjC Runtime)

    private static func buildProperties(for object: Any, mirror: Mirror) -> [ObjectProperty] {
        var result: [ObjectProperty] = []
        var seenNames: Set<String> = []

        // Swift Mirror children
        for child in mirror.children {
            let name = child.label ?? "(unnamed)"
            let typeName = String(describing: type(of: child.value))
            let value = String(describing: child.value)
            result.append(ObjectProperty(
                name: name,
                typeName: typeName,
                value: value,
                rawValue: child.value,
                isReadOnly: true
            ))
            seenNames.insert(name)
            // Also track underscore-prefixed backing storage names
            if name.hasPrefix("_") {
                seenNames.insert(String(name.dropFirst()))
            } else {
                seenNames.insert("_" + name)
            }
        }

        // ObjC properties (for NSObject subclasses)
        if let nsObject = object as? NSObject {
            let objcProps = getObjCProperties(for: type(of: nsObject))
            for prop in objcProps {
                // Avoid duplicates with Swift mirror using O(1) lookup
                guard !seenNames.contains(prop.name) else { continue }
                seenNames.insert(prop.name)

                let (value, rawValue) = safeValueForKey(prop.name, on: nsObject)
                result.append(ObjectProperty(
                    name: prop.name,
                    typeName: prop.typeName,
                    value: value,
                    rawValue: rawValue,
                    isReadOnly: prop.isReadOnly
                ))
            }
        }

        return result.sorted { $0.name < $1.name }
    }

    // MARK: - Ivars (ObjC Runtime only)

    private static func buildIvars(for object: Any) -> [ObjectIvar] {
        guard let nsObject = object as? NSObject else { return [] }

        var result: [ObjectIvar] = []
        var count: UInt32 = 0

        guard let ivarList = class_copyIvarList(type(of: nsObject), &count) else {
            return result
        }
        defer { free(ivarList) }

        for i in 0..<Int(count) {
            let ivar = ivarList[i]
            let name = ivar_getName(ivar).map { String(cString: $0) } ?? "(unknown)"
            let typeEncoding = ivar_getTypeEncoding(ivar).map { String(cString: $0) } ?? "?"
            let typeName = decodeObjCType(typeEncoding)

            let (value, rawValue) = safeValueForKey(name, on: nsObject)

            result.append(ObjectIvar(
                name: name,
                typeName: typeName,
                value: value,
                rawValue: rawValue
            ))
        }

        return result.sorted { $0.name < $1.name }
    }

    // MARK: - Methods (ObjC Runtime only)

    private static func buildMethods(for object: Any) -> [ObjectMethod] {
        guard let nsObject = object as? NSObject else { return [] }

        var result: [ObjectMethod] = []
        var count: UInt32 = 0

        guard let methodList = class_copyMethodList(type(of: nsObject), &count) else {
            return result
        }
        defer { free(methodList) }

        for i in 0..<Int(count) {
            let method = methodList[i]
            let selector = method_getName(method)
            let name = NSStringFromSelector(selector)
            let argCount = Int(method_getNumberOfArguments(method)) - 2 // subtract self + _cmd

            result.append(ObjectMethod(
                name: name,
                argumentCount: max(0, argCount)
            ))
        }

        return result.sorted { $0.name < $1.name }
    }

    // MARK: - Safe Value Access

    /// Known KVC-incompatible keys that may crash when accessed via value(forKey:).
    private static let unsafeKeyPrefixes = ["_", "accessibility"]
    private static let unsafeKeys: Set<String> = [
        "scriptingProperties", "classForArchiver", "classForKeyedArchiver",
        "classForPortCoder", "autoContentAccessingProxy", "observationInfo"
    ]

    private static func safeValueForKey(_ key: String, on nsObject: NSObject) -> (String, Any?) {
        // Skip keys known to be problematic with KVC
        if unsafeKeys.contains(key) {
            return ("<skipped>", nil)
        }

        // Check if the object responds to the getter selector to avoid crashes
        let getterSelector = NSSelectorFromString(key)
        guard nsObject.responds(to: getterSelector) else {
            return ("<no getter>", nil)
        }

        // Attempt KVC access - responds(to:) ensures the getter exists
        guard let val = nsObject.value(forKey: key) else {
            return ("nil", nil)
        }
        return (String(describing: val), val)
    }

    // MARK: - ObjC Property Helpers

    private struct ObjCPropertyInfo {
        let name: String
        let typeName: String
        let isReadOnly: Bool
    }

    private static func getObjCProperties(for cls: AnyClass) -> [ObjCPropertyInfo] {
        var result: [ObjCPropertyInfo] = []
        var count: UInt32 = 0

        guard let propertyList = class_copyPropertyList(cls, &count) else {
            return result
        }
        defer { free(propertyList) }

        for i in 0..<Int(count) {
            let property = propertyList[i]
            let name = String(cString: property_getName(property))
            let attributes = property_getAttributes(property).map { String(cString: $0) } ?? ""

            let typeName = parsePropertyType(from: attributes)
            let isReadOnly = attributes.contains(",R")

            result.append(ObjCPropertyInfo(
                name: name,
                typeName: typeName,
                isReadOnly: isReadOnly
            ))
        }

        return result
    }

    private static func parsePropertyType(from attributes: String) -> String {
        // ObjC property attributes format: T@"NSString",R,N,V_propertyName
        guard attributes.hasPrefix("T") else { return "id" }

        let typeString = String(attributes.dropFirst()) // drop "T"
        let endIndex = typeString.firstIndex(of: ",") ?? typeString.endIndex
        let rawType = String(typeString[typeString.startIndex..<endIndex])

        if rawType.hasPrefix("@\"") && rawType.hasSuffix("\"") {
            // Object type: @"NSString" -> NSString
            return String(rawType.dropFirst(2).dropLast())
        }

        return decodeObjCType(rawType)
    }

    private static func decodeObjCType(_ encoded: String) -> String {
        switch encoded {
        case "c": return "char"
        case "i": return "int"
        case "s": return "short"
        case "l": return "long"
        case "q": return "long long"
        case "C": return "unsigned char"
        case "I": return "unsigned int"
        case "S": return "unsigned short"
        case "L": return "unsigned long"
        case "Q": return "unsigned long long"
        case "f": return "float"
        case "d": return "double"
        case "B": return "Bool"
        case "v": return "void"
        case "*": return "char *"
        case "@": return "id"
        case "#": return "Class"
        case ":": return "SEL"
        default:
            if encoded.hasPrefix("@\"") && encoded.hasSuffix("\"") {
                return String(encoded.dropFirst(2).dropLast())
            }
            return encoded
        }
    }

    // MARK: - Section Data

    func numberOfRows(for section: ObjectExplorerSection) -> Int {
        switch section {
        case .identity:
            return 2 // class name + memory address
        case .properties:
            return properties.count
        case .ivars:
            return ivars.count
        case .methods:
            return methods.count
        case .superclass:
            return identity.superclassChain.count
        }
    }

    func availableSections() -> [ObjectExplorerSection] {
        ObjectExplorerSection.allCases.filter { numberOfRows(for: $0) > 0 }
    }
}
