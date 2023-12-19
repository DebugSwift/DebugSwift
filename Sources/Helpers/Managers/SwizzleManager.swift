//
//  SwizzleManager.swift
//  DebugSwift
//
//  Created by Matheus Gois on 18/12/23.
//

import Foundation

struct SwizzleManager {
    static func swizzle(
        _ classType: AnyClass,
        originalSelector: Selector,
        swizzledSelector: Selector
    ) {
        let originalMethod = class_getInstanceMethod(classType, originalSelector)
        let swizzledMethod = class_getInstanceMethod(classType, swizzledSelector)

        guard let origMethod = originalMethod, let swizzledMethod = swizzledMethod else {
            fatalError("Failed to retrieve methods for swizzling.")
        }

        let didAddMethod = class_addMethod(
            classType, originalSelector, method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
        )

        if didAddMethod {
            class_replaceMethod(
                classType, swizzledSelector, method_getImplementation(origMethod),
                method_getTypeEncoding(origMethod)
            )
        } else {
            method_exchangeImplementations(origMethod, swizzledMethod)
        }
    }
}
