//
//  ClassExplorer.ViewModel.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import Foundation
import ObjectiveC

final class ClassExplorerViewModel {
    
    // MARK: - Types
    
    enum Section: Int, CaseIterable {
        case classInfo
        case properties
        case methods
        case instanceState
    }
    
    struct PropertyInfo {
        let name: String
        let type: String
        let attributes: String
        
        var description: String {
            "\(name): \(type) [\(attributes)]"
        }
    }
    
    struct MethodInfo {
        let name: String
        let returnType: String
        let argumentTypes: [String]
        let isClassMethod: Bool
        
        var description: String {
            let prefix = isClassMethod ? "+" : "-"
            let args = argumentTypes.joined(separator: ", ")
            return "\(prefix) \(name)(\(args)) -> \(returnType)"
        }
    }
    
    struct InstanceProperty {
        let name: String
        let value: String
    }
    
    // MARK: - Properties
    
    private let className: String
    private var classObject: AnyClass?
    private var instance: AnyObject?
    
    private(set) var classInfo: [(key: String, value: String)] = []
    private(set) var properties: [PropertyInfo] = []
    private(set) var methods: [MethodInfo] = []
    private(set) var instanceProperties: [InstanceProperty] = []
    
    var canCreateInstance: Bool {
        guard let cls = classObject else { return false }
        
        // Check if it's an NSObject subclass
        guard class_conformsToProtocol(cls, NSObjectProtocol.self) else { return false }
        
        // Check if class responds to both alloc and init
        guard class_respondsToSelector(cls, NSSelectorFromString("alloc")),
              class_respondsToSelector(cls, NSSelectorFromString("init")) else { return false }
        
        // Skip certain known problematic classes
        let className = String(cString: class_getName(cls))
        let problemClasses = [
            "NSProxy",
            "NSInvocation", 
            "NSMethodSignature",
            "NSConnection",
            "NSDistantObject"
        ]
        
        for problemClass in problemClasses {
            if className.contains(problemClass) {
                return false
            }
        }
        
        // Filter out private classes (starting with underscore)
        if className.hasPrefix("_") {
            return false
        }
        
        // Additional safety check: verify we can get the method implementations
        let allocSelector = NSSelectorFromString("alloc")
        
        // Check if we can get the alloc method
        guard class_getClassMethod(cls, allocSelector) != nil else { return false }
        
        // For a more thorough check, we could try to allocate, but that's risky
        // So we'll just verify the methods exist
        return true
    }
    
    // MARK: - Initialization
    
    init(className: String) {
        self.className = className
        self.classObject = NSClassFromString(className)
    }
    
    // MARK: - Public Methods
    
    func loadClassInfo() {
        guard let cls = classObject else { return }
        
        loadBasicClassInfo(cls)
        loadProperties(cls)
        loadMethods(cls)
    }
    
    func createInstance() {
        guard let cls = classObject as? NSObject.Type else { return }
        
        // Use runtime functions for safer instantiation
        let allocSelector = NSSelectorFromString("alloc")
        let initSelector = NSSelectorFromString("init")
        
        guard cls.responds(to: allocSelector) else {
            print("Class \(className) does not respond to alloc")
            return
        }
        
        // Get the alloc method implementation
        guard let allocMethod = class_getClassMethod(cls, allocSelector) else {
            print("Unable to get alloc method for \(className)")
            return
        }
        
        // Call alloc using method implementation
        let allocImp = method_getImplementation(allocMethod)
        typealias AllocFunction = @convention(c) (AnyClass, Selector) -> NSObject
        let allocFunc = unsafeBitCast(allocImp, to: AllocFunction.self)
        let allocatedInstance = allocFunc(cls, allocSelector)
        
        // Check if the allocated instance responds to init
        guard allocatedInstance.responds(to: initSelector) else {
            print("Allocated instance of \(className) does not respond to init")
            return
        }
        
        // Get the init method implementation
        guard let initMethod = class_getInstanceMethod(type(of: allocatedInstance), initSelector) else {
            print("Unable to get init method for \(className)")
            return
        }
        
        // Call init using method implementation
        let initImp = method_getImplementation(initMethod)
        typealias InitFunction = @convention(c) (NSObject, Selector) -> NSObject
        let initFunc = unsafeBitCast(initImp, to: InitFunction.self)
        let initializedInstance = initFunc(allocatedInstance, initSelector)
        
        instance = initializedInstance
        loadInstanceState()
        print("Successfully created instance of \(className)")
    }
    
    // MARK: - Private Methods
    
    private func loadBasicClassInfo(_ cls: AnyClass) {
        var info: [(key: String, value: String)] = []
        
        // Class name
        info.append(("Class", String(cString: class_getName(cls))))
        
        // Superclass
        if let superclass = class_getSuperclass(cls) {
            info.append(("Superclass", String(cString: class_getName(superclass))))
        }
        
        // Instance size
        let instanceSize = class_getInstanceSize(cls)
        info.append(("Instance Size", "\(instanceSize) bytes"))
        
        // Protocols
        var protocolCount: UInt32 = 0
        if let protocols = class_copyProtocolList(cls, &protocolCount) {
            // AutoreleasingUnsafeMutablePointer is automatically managed by ARC
            
            var protocolNames: [String] = []
            for i in 0..<Int(protocolCount) {
                let proto = protocols[i]
                protocolNames.append(String(cString: protocol_getName(proto)))
            }
            
            if !protocolNames.isEmpty {
                info.append(("Protocols", protocolNames.joined(separator: ", ")))
            }
        }
        
        // Image name
        if let imageName = class_getImageName(cls) {
            let imageNameString = String(cString: imageName)
            info.append(("Image", (imageNameString as NSString).lastPathComponent))
        }
        
        classInfo = info
    }
    
    private func loadProperties(_ cls: AnyClass) {
        var propertyList: [PropertyInfo] = []
        
        var propertyCount: UInt32 = 0
        if let properties = class_copyPropertyList(cls, &propertyCount) {
            defer { free(properties) }
            
            for i in 0..<Int(propertyCount) {
                let property = properties[i]
                let name = String(cString: property_getName(property))
                
                var type = "Unknown"
                var attributes = ""
                
                if let attributesCString = property_getAttributes(property) {
                    let attributesString = String(cString: attributesCString)
                    attributes = parsePropertyAttributes(attributesString)
                    type = extractTypeFromAttributes(attributesString)
                }
                
                propertyList.append(PropertyInfo(
                    name: name,
                    type: type,
                    attributes: attributes
                ))
            }
        }
        
        self.properties = propertyList.sorted { $0.name < $1.name }
    }
    
    private func loadMethods(_ cls: AnyClass) {
        var methodList: [MethodInfo] = []
        
        // Instance methods
        var methodCount: UInt32 = 0
        if let methods = class_copyMethodList(cls, &methodCount) {
            defer { free(methods) }
            
            for i in 0..<Int(methodCount) {
                let method = methods[i]
                let selector = method_getName(method)
                let name = NSStringFromSelector(selector)
                
                let methodInfo = createMethodInfo(
                    method: method,
                    name: name,
                    isClassMethod: false
                )
                methodList.append(methodInfo)
            }
        }
        
        // Class methods
        if let metaClass = object_getClass(cls) {
            methodCount = 0
            if let methods = class_copyMethodList(metaClass, &methodCount) {
                defer { free(methods) }
                
                for i in 0..<Int(methodCount) {
                    let method = methods[i]
                    let selector = method_getName(method)
                    let name = NSStringFromSelector(selector)
                    
                    // Skip meta methods
                    if name.hasPrefix(".") { continue }
                    
                    let methodInfo = createMethodInfo(
                        method: method,
                        name: name,
                        isClassMethod: true
                    )
                    methodList.append(methodInfo)
                }
            }
        }
        
        self.methods = methodList.sorted { $0.name < $1.name }
    }
    
    private func loadInstanceState() {
        guard let instance = instance else { return }
        
        var propertyList: [InstanceProperty] = []
        
        // Get values for all properties
        for property in properties {
            let value = getPropertyValue(instance: instance, propertyName: property.name)
            propertyList.append(InstanceProperty(
                name: property.name,
                value: value
            ))
        }
        
        self.instanceProperties = propertyList
    }
    
    // MARK: - Helper Methods
    
    private func parsePropertyAttributes(_ attributes: String) -> String {
        var parsed: [String] = []
        
        if attributes.contains(",R") { parsed.append("readonly") }
        if attributes.contains(",C") { parsed.append("copy") }
        if attributes.contains(",&") { parsed.append("strong") }
        if attributes.contains(",N") { parsed.append("nonatomic") }
        if attributes.contains(",W") { parsed.append("weak") }
        
        return parsed.joined(separator: ", ")
    }
    
    private func extractTypeFromAttributes(_ attributes: String) -> String {
        // Extract type from property attributes
        if let typeStart = attributes.firstIndex(of: "T"),
           let typeEnd = attributes.firstIndex(of: ",") {
            let typeString = String(attributes[attributes.index(after: typeStart)..<typeEnd])
            return parseTypeEncoding(typeString)
        }
        return "Unknown"
    }
    
    private func parseTypeEncoding(_ encoding: String) -> String {
        if encoding.hasPrefix("@\"") && encoding.hasSuffix("\"") {
            // Object type
            return String(encoding.dropFirst(2).dropLast(1))
        }
        
        // Basic type encodings
        switch encoding {
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
        case "B": return "bool"
        case "v": return "void"
        case "*": return "char *"
        case "@": return "id"
        case "#": return "Class"
        case ":": return "SEL"
        default: return encoding
        }
    }
    
    private func createMethodInfo(method: Method, name: String, isClassMethod: Bool) -> MethodInfo {
        let returnType = parseMethodTypeEncoding(method_copyReturnType(method))
        
        var argumentTypes: [String] = []
        let argCount = method_getNumberOfArguments(method)
        
        // Skip self and _cmd
        for i in 2..<argCount {
            if let argType = method_copyArgumentType(method, i) {
                argumentTypes.append(parseMethodTypeEncoding(argType))
            }
        }
        
        return MethodInfo(
            name: name,
            returnType: returnType,
            argumentTypes: argumentTypes,
            isClassMethod: isClassMethod
        )
    }
    
    private func parseMethodTypeEncoding(_ encoding: UnsafeMutablePointer<CChar>?) -> String {
        guard let encoding = encoding else { return "Unknown" }
        defer { free(encoding) }
        
        let typeString = String(cString: encoding)
        return parseTypeEncoding(typeString)
    }
    
    private func getPropertyValue(instance: AnyObject, propertyName: String) -> String {
        let mirror = Mirror(reflecting: instance)
        
        for child in mirror.children {
            if child.label == propertyName {
                if let value = child.value as? CustomStringConvertible {
                    return value.description
                } else {
                    return String(describing: child.value)
                }
            }
        }
        
        // Try using KVC
        if instance.responds(to: NSSelectorFromString(propertyName)) {
            if let value = instance.value(forKey: propertyName) {
                return String(describing: value)
            }
        }
        
        return "N/A"
    }
} 