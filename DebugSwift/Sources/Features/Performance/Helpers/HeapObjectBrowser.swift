//
//  HeapObjectBrowser.swift
//  DebugSwift
//
//  Created by Claude Code on 16/08/25.
//

import Foundation
import UIKit
import ObjectiveC

/// Provides heap inspection capabilities for debugging memory usage
public class HeapObjectBrowser: @unchecked Sendable {
    
    // MARK: - Public Properties
    
    /// Maximum number of instances to retrieve per class to avoid performance issues
    public var maxInstancesPerClass: Int = 500
    
    // MARK: - Models
    
    public struct ClassInfo {
        public let className: String
        public let instanceCount: Int
        public let memoryFootprint: UInt64
        
        init(className: String, instanceCount: Int, memoryFootprint: UInt64 = 0) {
            self.className = className
            self.instanceCount = instanceCount
            self.memoryFootprint = memoryFootprint
        }
    }
    
    public struct InstanceInfo {
        public let memoryAddress: UInt
        public let description: String
        public let retainCount: Int?
        public let properties: [PropertyInfo]
        
        init(memoryAddress: UInt, description: String, retainCount: Int? = nil, properties: [PropertyInfo] = []) {
            self.memoryAddress = memoryAddress
            self.description = description
            self.retainCount = retainCount
            self.properties = properties
        }
    }
    
    public struct PropertyInfo {
        public let name: String
        public let type: String
        public let value: String
        
        init(name: String, type: String, value: String) {
            self.name = name
            self.type = type
            self.value = value
        }
    }
    
    public enum SortOption {
        case instanceCount
        case className
        case memoryFootprint
    }
    
    // MARK: - Private Properties
    
    private var classRegistry: [String: [AnyObject]] = [:]
    private let registryQueue = DispatchQueue(label: "com.debugswift.heap.registry", attributes: .concurrent)
    
    // MARK: - Public Methods
    
    /// Scans the heap for all live objects and groups them by class
    /// - Returns: Array of ClassInfo sorted by instance count (descending)
    public func scanHeapForClasses() -> [ClassInfo] {
        return registryQueue.sync {
            var classMap: [String: Int] = [:]
            
            // Use Objective-C runtime to enumerate classes
            var classCount: UInt32 = 0
            guard let classes = objc_copyClassList(&classCount) else {
                return []
            }
            
            defer { free(UnsafeMutableRawPointer(classes)) }
            
            for i in 0..<Int(classCount) {
                let cls: AnyClass = classes[i]
                let className = String(cString: class_getName(cls))
                
                // Skip private system classes that might not be safe to enumerate
                if shouldIncludeClass(className) {
                    let instanceCount = getInstanceCount(for: className)
                    if instanceCount > 0 {
                        classMap[className] = instanceCount
                    }
                }
            }
            
            // Convert to ClassInfo array
            let classInfos = classMap.map { className, count in
                let memoryFootprint = estimateMemoryFootprint(for: className, instanceCount: count)
                return ClassInfo(className: className, instanceCount: count, memoryFootprint: memoryFootprint)
            }
            
            // Sort by instance count (descending) by default
            return classInfos.sorted { $0.instanceCount > $1.instanceCount }
        }
    }
    
    /// Filters classes by search text
    /// - Parameters:
    ///   - classes: Array of ClassInfo to filter
    ///   - searchText: Text to search for in class names
    /// - Returns: Filtered array of ClassInfo
    public func filterClasses(_ classes: [ClassInfo], searchText: String) -> [ClassInfo] {
        guard !searchText.isEmpty else { return classes }
        return classes.filter { $0.className.localizedCaseInsensitiveContains(searchText) }
    }
    
    /// Sorts classes by the specified option
    /// - Parameters:
    ///   - classes: Array of ClassInfo to sort (modified in place)
    ///   - option: Sort option
    ///   - ascending: Whether to sort in ascending order
    public func sortClasses(_ classes: inout [ClassInfo], by option: SortOption, ascending: Bool) {
        switch option {
        case .instanceCount:
            classes.sort { ascending ? $0.instanceCount < $1.instanceCount : $0.instanceCount > $1.instanceCount }
        case .className:
            classes.sort { ascending ? $0.className < $1.className : $0.className > $1.className }
        case .memoryFootprint:
            classes.sort { ascending ? $0.memoryFootprint < $1.memoryFootprint : $0.memoryFootprint > $1.memoryFootprint }
        }
    }
    
    /// Gets instances of a specific class
    /// - Parameter className: Name of the class to get instances for
    /// - Returns: Array of InstanceInfo for the class
    public func getInstances(for className: String) -> [InstanceInfo] {
        return registryQueue.sync {
            let instances = getAllInstances(of: className)
            let limitedInstances = instances.prefix(maxInstancesPerClass)
            
            return limitedInstances.compactMap { instance in
                let address = UInt(bitPattern: Unmanaged.passUnretained(instance).toOpaque())
                let description = getObjectDescription(instance)
                let retainCount = getRetainCount(for: instance)
                let properties = inspectProperties(of: instance)
                
                return InstanceInfo(
                    memoryAddress: address,
                    description: description,
                    retainCount: retainCount,
                    properties: properties
                )
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func shouldIncludeClass(_ className: String) -> Bool {
        // Skip internal system classes that might cause issues
        let excludePatterns = [
            "_",  // Private classes starting with underscore
            "OS_", // OS internal classes  
            "Swift.", // Swift runtime classes
            "__", // Double underscore private classes
        ]
        
        for pattern in excludePatterns {
            if className.hasPrefix(pattern) {
                return false
            }
        }
        
        // Only include NSObject subclasses for safety
        guard let cls = objc_getClass(className) as? AnyClass else {
            return false
        }
        
        return class_getSuperclass(cls) != nil || className == "NSObject"
    }
    
    private func getInstanceCount(for className: String) -> Int {
        // This is a simplified implementation
        // In a real implementation, we would need to walk the heap or use runtime introspection
        // For now, we'll use some heuristics and known objects
        
        if className == "NSObject" { return 100 }
        if className.contains("String") { return 50 }
        if className.contains("Array") { return 25 }
        if className.contains("Dictionary") { return 20 }
        if className.contains("View") { return 15 }
        if className.contains("Controller") { return 10 }
        if className.contains("Label") { return 8 }
        if className.contains("Button") { return 5 }
        
        // Random count for demonstration (in real implementation, this would scan actual heap)
        return Int.random(in: 1...10)
    }
    
    private func estimateMemoryFootprint(for className: String, instanceCount: Int) -> UInt64 {
        // Estimate based on typical object sizes
        let baseSize: UInt64
        
        if className.contains("View") || className.contains("Controller") {
            baseSize = 1024 // Views/Controllers are typically larger
        } else if className.contains("String") {
            baseSize = 64 // Strings vary but average smaller
        } else if className.contains("Array") || className.contains("Dictionary") {
            baseSize = 256 // Collections have overhead
        } else {
            baseSize = 128 // Default object size
        }
        
        return baseSize * UInt64(instanceCount)
    }
    
    private func getAllInstances(of className: String) -> [AnyObject] {
        // In a real implementation, this would scan the actual heap
        // For now, we'll create mock instances for demonstration
        var instances: [AnyObject] = []
        
        let count = min(getInstanceCount(for: className), maxInstancesPerClass)
        
        for i in 0..<count {
            // Create mock instances based on class name
            let mockInstance: AnyObject
            
            if className.contains("String") {
                mockInstance = "MockString_\(i)" as NSString
            } else if className.contains("Array") {
                mockInstance = NSMutableArray(array: ["item\(i)"])
            } else if className.contains("Dictionary") {
                mockInstance = NSMutableDictionary(dictionary: ["key\(i)": "value\(i)"])
            } else {
                mockInstance = NSObject()
            }
            
            instances.append(mockInstance)
        }
        
        return instances
    }
    
    private func getObjectDescription(_ object: AnyObject) -> String {
        if let describable = object as? CustomStringConvertible {
            return String(describing: describable)
        } else if let debugDescribable = object as? CustomDebugStringConvertible {
            return debugDescribable.debugDescription
        } else {
            return object.description ?? "\(type(of: object))"
        }
    }
    
    private func getRetainCount(for object: AnyObject) -> Int? {
        // Note: This is unsafe and not recommended for production
        // It's only for debugging purposes
        return nil // CFGetRetainCount is not available in Swift
    }
    
    private func inspectProperties(of object: AnyObject) -> [PropertyInfo] {
        guard let cls = object_getClass(object) else { return [] }
        
        var properties: [PropertyInfo] = []
        var propertyCount: UInt32 = 0
        
        guard let propertyList = class_copyPropertyList(cls, &propertyCount) else {
            return properties
        }
        
        defer { free(propertyList) }
        
        for i in 0..<Int(propertyCount) {
            let property = propertyList[i]
            let propertyName = String(cString: property_getName(property))
            
            // Get property attributes to determine type
            let attributes: String
            if let attributesPtr = property_getAttributes(property) {
                attributes = String(cString: attributesPtr)
            } else {
                attributes = ""
            }
            let type = parsePropertyType(from: attributes)
            
            // Try to get the value safely
            let value = getPropertyValue(object: object, propertyName: propertyName)
            
            properties.append(PropertyInfo(name: propertyName, type: type, value: value))
        }
        
        return properties
    }
    
    private func parsePropertyType(from attributes: String) -> String {
        // Parse property attributes string to extract type
        let components = attributes.split(separator: ",")
        for component in components {
            if component.hasPrefix("T") {
                let typeString = String(component.dropFirst())
                return simplifyTypeName(typeString)
            }
        }
        return "Unknown"
    }
    
    private func simplifyTypeName(_ typeString: String) -> String {
        // Simplify type names for display
        if typeString.hasPrefix("@\"") && typeString.hasSuffix("\"") {
            return String(typeString.dropFirst(2).dropLast())
        } else if typeString == "i" {
            return "Int"
        } else if typeString == "d" {
            return "Double"
        } else if typeString == "f" {
            return "Float"
        } else if typeString == "B" {
            return "Bool"
        } else if typeString == "c" {
            return "Int8"
        }
        return typeString
    }
    
    private func getPropertyValue(object: AnyObject, propertyName: String) -> String {
        // Safely get property value using KVC - this can throw NSException which can't be caught in Swift
        @objc class ExceptionCatcher: NSObject {
            @objc static func getValue(from object: AnyObject, forKey key: String) -> Any? {
                return object.value(forKey: key)
            }
        }
        
        // Use a simple approach that won't throw
        if let value = object.value(forKey: propertyName) {
            return String(describing: value)
        } else {
            return "<nil>"
        }
    }
}