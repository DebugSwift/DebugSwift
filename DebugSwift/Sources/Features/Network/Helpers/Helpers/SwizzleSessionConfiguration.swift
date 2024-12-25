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
        
        swizzleProtocolSetter()

        let defaultSessionConfiguration = class_getClassMethod(
            URLSessionConfiguration.self,
            #selector(getter: URLSessionConfiguration.default)
        )
        let swizzledDefaultSessionConfiguration = class_getClassMethod(
            URLSessionConfiguration.self,
            #selector(getter: URLSessionConfiguration.swizzledDefaultSessionConfiguration)
        )

        method_exchangeImplementations(defaultSessionConfiguration!, swizzledDefaultSessionConfiguration!)

        let ephemeralSessionConfiguration = class_getClassMethod(
            URLSessionConfiguration.self,
            #selector(getter: URLSessionConfiguration.ephemeral)
        )
        let swizzledEphemeralSessionConfiguration = class_getClassMethod(
            URLSessionConfiguration.self,
            #selector(getter: URLSessionConfiguration.swizzledEphemeralSessionConfiguration)
        )

        method_exchangeImplementations(ephemeralSessionConfiguration!, swizzledEphemeralSessionConfiguration!)
    }
    
    private static func swizzleProtocolSetter() {
        let defaultInstance = URLSessionConfiguration.default
        let ephemeralInstance =  URLSessionConfiguration.ephemeral
        
        let aClassDefault: AnyClass = object_getClass(defaultInstance)!
        let aClassEphemeral: AnyClass = object_getClass(ephemeralInstance)!
        
        let origSelector = #selector(setter: URLSessionConfiguration.protocolClasses)
        let newSelector = #selector(setter: URLSessionConfiguration.protocolClasses_Swizzled)
        
        let origMethodDefault = class_getInstanceMethod(aClassDefault, origSelector)!
        let origMethodEphemeral = class_getInstanceMethod(aClassEphemeral, origSelector)!
       
        let newMethodDefault = class_getInstanceMethod(aClassDefault, newSelector)!
        let newMethodEphemeral = class_getInstanceMethod(aClassEphemeral, newSelector)!
        
        method_exchangeImplementations(origMethodDefault, newMethodDefault)
        method_exchangeImplementations(origMethodEphemeral, newMethodEphemeral)
    }
    
    @objc private var protocolClasses_Swizzled: [AnyClass]? {
        get {
            // Unused, but required for compiler
            return self.protocolClasses_Swizzled
        }
        set {
            guard let newTypes = newValue else { self.protocolClasses_Swizzled = nil; return }
            
            var types = [AnyClass]()
            
            // de-dup
            for newType in newTypes {
                if !types.contains(where: { $0 == newType }) {
                    types.append(newType)
                }
            }
            
            // Ensure custom protocol is still in there:
            if !types.contains(where: { $0 == CustomHTTPProtocol.self }) {
              types.insert(CustomHTTPProtocol.self, at: 0)
            }
            
            self.protocolClasses_Swizzled = types
        }
    }

    @objc
    private class var swizzledDefaultSessionConfiguration: URLSessionConfiguration {
        get {
            let configuration =  URLSessionConfiguration.swizzledDefaultSessionConfiguration
            configuration.protocolClasses?.insert(CustomHTTPProtocol.self, at: .zero)
            return configuration
        }
    }
    
    @objc
    private class var swizzledEphemeralSessionConfiguration: URLSessionConfiguration {
        get {
            let configuration = URLSessionConfiguration.swizzledEphemeralSessionConfiguration
            configuration.protocolClasses?.insert(CustomHTTPProtocol.self, at: .zero)
            return configuration
        }
    }
}
