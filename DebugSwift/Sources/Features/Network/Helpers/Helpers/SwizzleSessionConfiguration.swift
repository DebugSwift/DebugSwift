//
//  SwizzleSessionConfiguration.swift
//  DebugSwift
//
//  Created by Matheus Gois on 18/12/23.
//

import Foundation

extension URLSessionConfiguration {
    @objc
    static func swizzleMethods() {
        guard self == URLSessionConfiguration.self else {
            return
        }
        
        swizzleDefaultSessionConfiguration()
        swizzleEphemeralSessionConfiguration()
    }
}


//MARK: - Private Helper functions
private extension URLSessionConfiguration {
    static func swizzleDefaultSessionConfiguration() {
        swizzleSessionConfigurationClassMethod(
            original: #selector(getter: URLSessionConfiguration.default),
            swizzled: #selector(getter: URLSessionConfiguration.swizzledDefaultSessionConfiguration))
        
        swizzleProtocolSetterMethod(of: URLSessionConfiguration.default)
    }
    
    static func swizzleEphemeralSessionConfiguration() {
        swizzleSessionConfigurationClassMethod(
            original: #selector(getter: URLSessionConfiguration.ephemeral),
            swizzled: #selector(getter: URLSessionConfiguration.swizzledEphemeralSessionConfiguration))
        
        swizzleProtocolSetterMethod(of: URLSessionConfiguration.ephemeral)
    }
    
    static func swizzleSessionConfigurationClassMethod(original: Selector, swizzled: Selector) {
        guard
            let sessionConfiguration = class_getClassMethod(
                URLSessionConfiguration.self,
                original),
            
                let swizzledSessionConfiguration = class_getClassMethod(
                    URLSessionConfiguration.self,
                    swizzled)
        else { return }
        
        method_exchangeImplementations(sessionConfiguration, swizzledSessionConfiguration)
    }
    
    static func swizzleProtocolSetterMethod(of objClass: Any) {
        let originalSelector = #selector(setter: URLSessionConfiguration.protocolClasses)
        let swizzledSelector = #selector(setter: URLSessionConfiguration.protocolClasses_Swizzled)
        
        guard
            let aclass = object_getClass(objClass),
            let original = class_getInstanceMethod(aclass, originalSelector),
            let swizzled = class_getInstanceMethod(aclass, swizzledSelector)
        else { return }
        
        method_exchangeImplementations(original, swizzled)
    }
    
    @objc
    var protocolClasses_Swizzled: [AnyClass]? {
        get {
            // Unused, but required for compiler
            return self.protocolClasses_Swizzled
        }
        set {
            guard let newTypes = newValue else {
                self.protocolClasses_Swizzled = nil
                return
            }
            
            var types = [AnyClass]()
            
            // de-dup
            for newType in newTypes {
                if !types.contains(where: { $0 == newType }) {
                    types.append(newType)
                }
            }
            
            // Only add CustomHTTPProtocol if explicitly requested or if no protocols specified
            // This prevents forcing HTTP protocol on WebSocket configurations
            if !types.contains(where: { $0 == CustomHTTPProtocol.self }) {
                types.insert(CustomHTTPProtocol.self, at: 0)
            }
            
            self.protocolClasses_Swizzled = types
        }
    }
    
    @objc
    class var swizzledDefaultSessionConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.swizzledDefaultSessionConfiguration
        // Only add CustomHTTPProtocol to default configurations that don't already have protocols specified
        configuration.protocolClasses?.insert(CustomHTTPProtocol.self, at: .zero)
        return configuration
    }
    
    @objc
    class var swizzledEphemeralSessionConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.swizzledEphemeralSessionConfiguration
        // Only add CustomHTTPProtocol to ephemeral configurations that don't already have protocols specified
        configuration.protocolClasses?.insert(CustomHTTPProtocol.self, at: .zero)
        return configuration
    }
}
