//
//  CwlDemangle.swift
//  CwlDemangle
//
//  Created by Matt Gallagher on 2017/11/17.
//  Copyright © 2017 Matt Gallagher. All rights reserved.
//

import Foundation

/// This is likely to be the primary entry point to this file. Pass a string containing a Swift mangled symbol or type, get a parsed SwiftSymbol structure which can then be directly examined or printed.
///
/// - Parameters:
///   - mangled: the string to be parsed ("isType` is false, the string should start with a Swift Symbol prefix, _T, _$S or $S).
///   - isType: if true, no prefix is parsed and, on completion, the first item on the parse stack is returned.
/// - Returns: the successfully parsed result
/// - Throws: a SwiftSymbolParseError error that contains parse position when the error occurred.
internal func parseMangledSwiftSymbol(_ mangled: String, isType: Bool = false) throws -> SwiftSymbol {
    return try parseMangledSwiftSymbol(mangled.unicodeScalars, isType: isType)
}

/// Pass a collection of `UnicodeScalars` containing a Swift mangled symbol or type, get a parsed SwiftSymbol structure which can then be directly examined or printed.
///
/// - Parameters:
///   - mangled: the collection of `UnicodeScalars` to be parsed ("isType` is false, the string should start with a Swift Symbol prefix, _T, _$S or $S).
///   - isType: if true, no prefix is parsed and, on completion, the first item on the parse stack is returned.
/// - Returns: the successfully parsed result
/// - Throws: a SwiftSymbolParseError error that contains parse position when the error occurred.
internal func parseMangledSwiftSymbol<C: Collection>(_ mangled: C, isType: Bool = false, symbolicReferenceResolver: ((Int32, Int) throws -> SwiftSymbol)? = nil) throws -> SwiftSymbol where C.Iterator.Element == UnicodeScalar {
    var demangler = Demangler(scalars: mangled)
    demangler.symbolicReferenceResolver = symbolicReferenceResolver
    if isType {
        return try demangler.demangleType()
    } else if getManglingPrefixLength(mangled) != 0 {
        return try demangler.demangleSymbol()
    } else {
        return try demangler.demangleSwift3TopLevelSymbol()
    }
}

extension SwiftSymbol: CustomStringConvertible {
    /// Overridden method to allow simple printing with default options
    var description: String {
        var printer = SymbolPrinter()
        _ = printer.printName(self)
        return printer.target
    }

    /// Prints `SwiftSymbol`s to a String with the full set of printing options.
    ///
    /// - Parameter options: an option set containing the different `DemangleOptions` from the Swift project.
    /// - Returns: `self` printed to a string according to the specified options.
    func print(using options: SymbolPrintOptions = .default) -> String {
        var printer = SymbolPrinter(options: options)
        _ = printer.printName(self)
        return printer.target
    }
}

// MARK: Demangle.h

/// These options mimic those used in the Swift project. Check that project for details.
internal struct SymbolPrintOptions: OptionSet {
    let rawValue: Int

    static let synthesizeSugarOnTypes = SymbolPrintOptions(rawValue: 1 << 0)
    static let displayDebuggerGeneratedModule = SymbolPrintOptions(rawValue: 1 << 1)
    static let qualifyEntities = SymbolPrintOptions(rawValue: 1 << 2)
    static let displayExtensionContexts = SymbolPrintOptions(rawValue: 1 << 3)
    static let displayUnmangledSuffix = SymbolPrintOptions(rawValue: 1 << 4)
    static let displayModuleNames = SymbolPrintOptions(rawValue: 1 << 5)
    static let displayGenericSpecializations = SymbolPrintOptions(rawValue: 1 << 6)
    static let displayProtocolConformances = SymbolPrintOptions(rawValue: 1 << 5)
    static let displayWhereClauses = SymbolPrintOptions(rawValue: 1 << 8)
    static let displayEntityTypes = SymbolPrintOptions(rawValue: 1 << 9)
    static let shortenPartialApply = SymbolPrintOptions(rawValue: 1 << 10)
    static let shortenThunk = SymbolPrintOptions(rawValue: 1 << 11)
    static let shortenValueWitness = SymbolPrintOptions(rawValue: 1 << 12)
    static let shortenArchetype = SymbolPrintOptions(rawValue: 1 << 13)
    static let showPrivateDiscriminators = SymbolPrintOptions(rawValue: 1 << 14)
    static let showFunctionArgumentTypes = SymbolPrintOptions(rawValue: 1 << 15)

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static let `default`: SymbolPrintOptions = [.displayDebuggerGeneratedModule, .qualifyEntities, .displayExtensionContexts, .displayUnmangledSuffix, .displayModuleNames, .displayGenericSpecializations, .displayProtocolConformances, .displayWhereClauses, .displayEntityTypes, .showPrivateDiscriminators, .showFunctionArgumentTypes]
    static let simplified: SymbolPrintOptions = [.synthesizeSugarOnTypes, .qualifyEntities, .shortenPartialApply, .shortenThunk, .shortenValueWitness, .shortenArchetype]
}

internal enum FunctionSigSpecializationParamKind: UInt32 {
    case constantPropFunction = 0
    case constantPropGlobal = 1
    case constantPropInteger = 2
    case constantPropFloat = 3
    case constantPropString = 4
    case closureProp = 5
    case boxToValue = 6
    case boxToStack = 7
    case dead = 64
    case ownedToGuaranteed = 128
    case sroa = 256
}

internal enum SpecializationPass {
    case allocBoxToStack
    case closureSpecializer
    case capturePromotion
    case capturePropagation
    case functionSignatureOpts
    case genericSpecializer
}

internal enum Directness: UInt32, CustomStringConvertible {
    case direct = 0
    case indirect = 1

    var description: String {
        switch self {
        case .direct: return "direct"
        case .indirect: return "indirect"
        }
    }
}

internal enum DemangleFunctionEntityArgs {
    case none, typeAndMaybePrivateName, typeAndIndex, index
}

internal enum DemangleGenericRequirementTypeKind {
    case generic, assoc, compoundAssoc, substitution
}

internal enum DemangleGenericRequirementConstraintKind {
    case `protocol`, baseClass, sameType, layout
}

internal enum ValueWitnessKind: UInt32, CustomStringConvertible {
    case allocateBuffer = 0
    case assignWithCopy = 1
    case assignWithTake = 2
    case deallocateBuffer = 3
    case destroy = 4
    case destroyArray = 5
    case destroyBuffer = 6
    case initializeBufferWithCopyOfBuffer = 7
    case initializeBufferWithCopy = 8
    case initializeWithCopy = 9
    case initializeBufferWithTake = 10
    case initializeWithTake = 11
    case projectBuffer = 12
    case initializeBufferWithTakeOfBuffer = 13
    case initializeArrayWithCopy = 14
    case initializeArrayWithTakeFrontToBack = 15
    case initializeArrayWithTakeBackToFront = 16
    case storeExtraInhabitant = 17
    case getExtraInhabitantIndex = 18
    case getEnumTag = 19
    case destructiveProjectEnumData = 20
    case destructiveInjectEnumTag = 21
    case getEnumTagSinglePayload = 22
    case storeEnumTagSinglePayload = 23

    init?(code: String) {
        switch code {
        case "al": self = .allocateBuffer
        case "ca": self = .assignWithCopy
        case "ta": self = .assignWithTake
        case "de": self = .deallocateBuffer
        case "xx": self = .destroy
        case "XX": self = .destroyBuffer
        case "Xx": self = .destroyArray
        case "CP": self = .initializeBufferWithCopyOfBuffer
        case "Cp": self = .initializeBufferWithCopy
        case "cp": self = .initializeWithCopy
        case "Tk": self = .initializeBufferWithTake
        case "tk": self = .initializeWithTake
        case "pr": self = .projectBuffer
        case "TK": self = .initializeBufferWithTakeOfBuffer
        case "Cc": self = .initializeArrayWithCopy
        case "Tt": self = .initializeArrayWithTakeFrontToBack
        case "tT": self = .initializeArrayWithTakeBackToFront
        case "xs": self = .storeExtraInhabitant
        case "xg": self = .getExtraInhabitantIndex
        case "ug": self = .getEnumTag
        case "up": self = .destructiveProjectEnumData
        case "ui": self = .destructiveInjectEnumTag
        case "et": self = .getEnumTagSinglePayload
        case "st": self = .storeEnumTagSinglePayload
        default: return nil
        }
    }

    var description: String {
        switch self {
        case .allocateBuffer: return "allocateBuffer"
        case .assignWithCopy: return "assignWithCopy"
        case .assignWithTake: return "assignWithTake"
        case .deallocateBuffer: return "deallocateBuffer"
        case .destroy: return "destroy"
        case .destroyBuffer: return "destroyBuffer"
        case .initializeBufferWithCopyOfBuffer: return "initializeBufferWithCopyOfBuffer"
        case .initializeBufferWithCopy: return "initializeBufferWithCopy"
        case .initializeWithCopy: return "initializeWithCopy"
        case .initializeBufferWithTake: return "initializeBufferWithTake"
        case .initializeWithTake: return "initializeWithTake"
        case .projectBuffer: return "projectBuffer"
        case .initializeBufferWithTakeOfBuffer: return "initializeBufferWithTakeOfBuffer"
        case .destroyArray: return "destroyArray"
        case .initializeArrayWithCopy: return "initializeArrayWithCopy"
        case .initializeArrayWithTakeFrontToBack: return "initializeArrayWithTakeFrontToBack"
        case .initializeArrayWithTakeBackToFront: return "initializeArrayWithTakeBackToFront"
        case .storeExtraInhabitant: return "storeExtraInhabitant"
        case .getExtraInhabitantIndex: return "getExtraInhabitantIndex"
        case .getEnumTag: return "getEnumTag"
        case .destructiveProjectEnumData: return "destructiveProjectEnumData"
        case .destructiveInjectEnumTag: return "destructiveInjectEnumTag"
        case .getEnumTagSinglePayload: return "getEnumTagSinglePayload"
        case .storeEnumTagSinglePayload: return "storeEnumTagSinglePayload"
        }
    }
}

internal struct SwiftSymbol {
    let kind: Kind
    var children: [SwiftSymbol]
    let contents: Contents

    enum Contents {
        case none
        case index(UInt32)
        case name(String)
    }

    init(kind: Kind, children: [SwiftSymbol] = [], contents: Contents = .none) {
        self.kind = kind
        self.children = children
        self.contents = contents
    }

    fileprivate init(kind: Kind, child: SwiftSymbol) {
        self.init(kind: kind, children: [child], contents: .none)
    }

    fileprivate init(typeWithChildKind: Kind, childChild: SwiftSymbol) {
        self.init(kind: .type, children: [SwiftSymbol(kind: typeWithChildKind, children: [childChild])], contents: .none)
    }

    fileprivate init(typeWithChildKind: Kind, childChildren: [SwiftSymbol]) {
        self.init(kind: .type, children: [SwiftSymbol(kind: typeWithChildKind, children: childChildren)], contents: .none)
    }

    fileprivate init(swiftStdlibTypeKind: Kind, name: String) {
        self.init(kind: .type, children: [SwiftSymbol(kind: swiftStdlibTypeKind, children: [
            SwiftSymbol(kind: .module, contents: .name(stdlibName)),
            SwiftSymbol(kind: .identifier, contents: .name(name))
        ])], contents: .none)
    }

    fileprivate init(swiftBuiltinType: Kind, name: String) {
        self.init(kind: .type, children: [SwiftSymbol(kind: swiftBuiltinType, contents: .name(name))])
    }

    fileprivate var text: String? {
        switch contents {
        case .name(let s): return s
        default: return nil
        }
    }

    fileprivate var index: UInt32? {
        switch contents {
        case .index(let i): return i
        default: return nil
        }
    }

    fileprivate func changeChild(_ newChild: SwiftSymbol?, atIndex: Int) -> SwiftSymbol {
        guard children.indices.contains(atIndex) else { return self }

        var modifiedChildren = children
        if let nc = newChild {
            modifiedChildren[atIndex] = nc
        } else {
            modifiedChildren.remove(at: atIndex)
        }
        return SwiftSymbol(kind: kind, children: modifiedChildren, contents: contents)
    }

    fileprivate func changeKind(_ newKind: Kind, additionalChildren: [SwiftSymbol] = []) -> SwiftSymbol {
        if case .name(let text) = contents {
            return SwiftSymbol(kind: newKind, children: children + additionalChildren, contents: .name(text))
        } else if case .index(let i) = contents {
            return SwiftSymbol(kind: newKind, children: children + additionalChildren, contents: .index(i))
        } else {
            return SwiftSymbol(kind: newKind, children: children + additionalChildren, contents: .none)
        }
    }
}

// MARK: DemangleNodes.def

internal extension SwiftSymbol {
    enum Kind {
        case allocator
        case anonymousContext
        case anonymousDescriptor
        case argumentTuple
        case associatedType
        case associatedTypeGenericParamRef
        case associatedTypeMetadataAccessor
        case associatedTypeRef
        case associatedTypeWitnessTableAccessor
        case assocTypePath
        case autoClosureType
        case boundGenericClass
        case boundGenericEnum
        case boundGenericOtherNominalType
        case boundGenericStructure
        case builtinTypeName
        case cFunctionPointer
        case `class`
        case classMetadataBaseOffset
        case constructor
        case coroutineContinuationPrototype
        case curryThunk
        case deallocator
        case declContext
        case defaultArgumentInitializer
        case dependentAssociatedTypeRef
        case dependentGenericConformanceRequirement
        case dependentGenericLayoutRequirement
        case dependentGenericParamCount
        case dependentGenericParamType
        case dependentGenericSameTypeRequirement
        case dependentGenericSignature
        case dependentGenericType
        case dependentMemberType
        case dependentPseudogenericSignature
        case destructor
        case didSet
        case directMethodReferenceAttribute
        case directness
        case dispatchThunk
        case dynamicAttribute
        case dynamicSelf
        case emptyList
        case `enum`
        case enumCase
        case errorType
        case escapingAutoClosureType
        case existentialMetatype
        case explicitClosure
        case `extension`
        case extensionDescriptor
        case fieldOffset
        case firstElementMarker
        case fullTypeMetadata
        case function
        case functionSignatureSpecialization
        case functionSignatureSpecializationParam
        case functionSignatureSpecializationParamKind
        case functionSignatureSpecializationParamPayload
        case functionType
        case genericPartialSpecialization
        case genericPartialSpecializationNotReAbstracted
        case genericProtocolWitnessTable
        case genericProtocolWitnessTableInstantiationFunction
        case genericSpecialization
        case genericSpecializationNotReAbstracted
        case genericSpecializationParam
        case genericTypeMetadataPattern
        case genericTypeParamDecl
        case getter
        case global
        case globalGetter
        case identifier
        case implConvention
        case implErrorResult
        case implEscaping
        case implFunctionAttribute
        case implFunctionType
        case implicitClosure
        case implParameter
        case implResult
        case index
        case infixOperator
        case initializer
        case inOut
        case iVarDestroyer
        case iVarInitializer
        case keyPathEqualsThunkHelper
        case keyPathGetterThunkHelper
        case keyPathHashThunkHelper
        case keyPathSetterThunkHelper
        case labelList
        case lazyProtocolWitnessTableAccessor
        case lazyProtocolWitnessTableCacheVariable
        case localDeclName
        case materializeForSet
        case mergedFunction
        case metaclass
        case metatype
        case metatypeRepresentation
        case module
        case moduleDescriptor
        case nativeOwningAddressor
        case nativeOwningMutableAddressor
        case nativePinningAddressor
        case nativePinningMutableAddressor
        case noEscapeFunctionType
        case nominalTypeDescriptor
        case nonObjCAttribute
        case number
        case objCAttribute
        case objCBlock
        case otherNominalType
        case outlinedAssignWithCopy
        case outlinedAssignWithTake
        case outlinedBridgedMethod
        case outlinedConsume
        case outlinedCopy
        case outlinedDestroy
        case outlinedInitializeWithCopy
        case outlinedInitializeWithTake
        case outlinedRelease
        case outlinedRetain
        case outlinedVariable
        case owned
        case owningAddressor
        case owningMutableAddressor
        case partialApplyForwarder
        case partialApplyObjCForwarder
        case postfixOperator
        case prefixOperator
        case privateDeclName
        case propertyDescriptor
        case `protocol`
        case protocolConformance
        case protocolConformanceDescriptor
        case protocolDescriptor
        case protocolList
        case protocolListWithAnyObject
        case protocolListWithClass
        case protocolRequirementArray
        case protocolWitness
        case protocolWitnessTable
        case protocolWitnessTableAccessor
        case protocolWitnessTablePattern
        case qualifiedArchetype
        case reabstractionThunk
        case reabstractionThunkHelper
        case reflectionMetadataAssocTypeDescriptor
        case reflectionMetadataBuiltinDescriptor
        case reflectionMetadataFieldDescriptor
        case reflectionMetadataSuperclassDescriptor
        case relatedEntityDeclName
        case resilientProtocolWitnessTable
        case retroactiveConformance
        case returnType
        case setter
        case shared
        case silBoxImmutableField
        case silBoxLayout
        case silBoxMutableField
        case silBoxType
        case silBoxTypeWithLayout
        case specializationIsFragile
        case specializationPassID
        case `static`
        case structure
        case `subscript`
        case suffix
        case symbolicReference
        case thinFunctionType
        case throwsAnnotation
        case tuple
        case tupleElement
        case tupleElementName
        case type
        case typeAlias
        case typeList
        case typeMangling
        case typeMetadata
        case typeMetadataAccessFunction
        case typeMetadataCompletionFunction
        case typeMetadataInstantiationCache
        case typeMetadataInstantiationFunction
        case typeMetadataLazyCache
        case uncurriedFunctionType
        case unmanaged
        case unowned
        case unresolvedSymbolicReference
        case unsafeAddressor
        case unsafeMutableAddressor
        case valueWitness
        case valueWitnessTable
        case variable
        case variadicMarker
        case vTableAttribute // note: old mangling only
        case vTableThunk
        case weak
        case willSet
    }
}

// MARK: Demangler.h

fileprivate let stdlibName = "Swift"
fileprivate let objcModule = "__C"
fileprivate let cModule = "__C_Synthesized"
fileprivate let lldbExpressionsModuleNamePrefix = "__lldb_expr_"
fileprivate let maxRepeatCount = 2048
fileprivate let maxNumWords = 26

fileprivate struct Demangler<C> where C: Collection, C.Iterator.Element == UnicodeScalar {
    var scanner: ScalarScanner<C>
    var nameStack: [SwiftSymbol] = []
    var substitutions: [SwiftSymbol] = []
    var words: [String] = []
    var symbolicReferences: [Int32] = []
    var isOldFunctionTypeMangling: Bool = false
    var symbolicReferenceResolver: ((Int32, Int) throws -> SwiftSymbol)? = nil

    init(scalars: C) {
        scanner = ScalarScanner(scalars: scalars)
    }
}

// MARK: Demangler.cpp

fileprivate func getManglingPrefixLength<C: Collection>(_ scalars: C) -> Int where C.Iterator.Element == UnicodeScalar {
    var scanner = ScalarScanner(scalars: scalars)
    if scanner.conditional(string: "_T0") || scanner.conditional(string: "_$S") || scanner.conditional(string: "_$s") {
        return 3
    } else if scanner.conditional(string: "$S") || scanner.conditional(string: "$s") {
        return 2
    }

    return 0
}

fileprivate extension SwiftSymbol.Kind {
    var isDeclName: Bool {
        switch self {
        case .identifier, .localDeclName, .privateDeclName, .relatedEntityDeclName: fallthrough
        case .prefixOperator, .postfixOperator, .infixOperator: fallthrough
        case .unresolvedSymbolicReference, .symbolicReference: return true
        default: return false
        }
    }

    var isContext: Bool {
        switch self {
        case .allocator, .anonymousContext, .class, .constructor, .curryThunk, .deallocator, .defaultArgumentInitializer: fallthrough
        case .destructor, .didSet, .dispatchThunk, .enum, .explicitClosure, .extension, .function: fallthrough
        case .getter, .globalGetter, .iVarInitializer, .iVarDestroyer, .implicitClosure: fallthrough
        case .initializer, .materializeForSet, .module, .nativeOwningAddressor: fallthrough
        case .nativeOwningMutableAddressor, .nativePinningAddressor, .nativePinningMutableAddressor: fallthrough
        case .otherNominalType, .owningAddressor, .owningMutableAddressor, .protocol, .setter, .static: fallthrough
        case .structure, .subscript, .symbolicReference, .typeAlias, .unresolvedSymbolicReference, .unsafeAddressor, .unsafeMutableAddressor: fallthrough
        case .variable, .willSet: return true
        default: return false
        }
    }

    var isAnyGeneric: Bool {
        switch self {
        case .structure, .class, .enum, .protocol, .otherNominalType, .typeAlias, .symbolicReference, .unresolvedSymbolicReference: return true
        default: return false
        }
    }

    var isEntity: Bool {
        return self == .type || isContext
    }

    var isRequirement: Bool {
        switch self {
        case .dependentGenericSameTypeRequirement, .dependentGenericLayoutRequirement: fallthrough
        case .dependentGenericConformanceRequirement: return true
        default: return false
        }
    }

    var isFunctionAttr: Bool {
        switch self {
        case .functionSignatureSpecialization, .genericSpecialization: fallthrough
        case .genericSpecializationNotReAbstracted, .genericPartialSpecialization: fallthrough
        case .genericPartialSpecializationNotReAbstracted, .objCAttribute, .nonObjCAttribute: fallthrough
        case .dynamicAttribute, .directMethodReferenceAttribute, .vTableAttribute, .partialApplyForwarder: fallthrough
        case .partialApplyObjCForwarder, .outlinedVariable, .outlinedBridgedMethod, .mergedFunction: return true
        default: return false
        }
    }
}

fileprivate extension Demangler {
    func require<T>(_ optional: Optional<T>) throws -> T {
        if let v = optional {
            return v
        } else {
            throw failure
        }
    }

    func require(_ value: Bool) throws {
        if !value {
            throw failure
        }
    }

    var failure: Error {
        return scanner.unexpectedError()
    }

    mutating func readManglingPrefix() throws {
        switch (try scanner.readScalar(), try scanner.readScalar()) {
        case ("_", "T"): try scanner.match(scalar: "0")
        case ("_", "$") where scanner.conditional(scalar: "S"): return
        case ("_", "$") where scanner.conditional(scalar: "s"): return
        case ("$", "S"): return
        case ("$", "s"): return
        default: throw scanner.unexpectedError()
        }
    }

    mutating func reset() {
        nameStack = []
        substitutions = []
        words = []
        scanner.reset()
    }

    mutating func popTopLevelInto(_ parent: inout SwiftSymbol) throws {
        while var funcAttr = pop(where: { $0.isFunctionAttr }) {
            switch funcAttr.kind {
            case .partialApplyForwarder, .partialApplyObjCForwarder:
                try popTopLevelInto(&funcAttr)
                parent.children.append(funcAttr)
                return
            default:
                parent.children.append(funcAttr)
            }
        }
        for name in nameStack {
            switch name.kind {
            case .type: parent.children.append(try require(name.children.first))
            default: parent.children.append(name)
            }
        }

        try require(parent.children.count != 0)
    }

    mutating func demangleSymbol() throws -> SwiftSymbol {
        reset()

        if scanner.conditional(string: "_Tt") {
            return try demangleObjCTypeName()
        } else if scanner.conditional(string: "_T") {
            isOldFunctionTypeMangling = true
            try scanner.backtrack(count: 2)
        }

        try readManglingPrefix()
        try parseAndPushNames()

        var topLevel = SwiftSymbol(kind: .global)
        try popTopLevelInto(&topLevel)
        return topLevel
    }

    mutating func demangleType() throws -> SwiftSymbol {
        reset()

        try parseAndPushNames()
        if let result = pop() {
            return result
        }

        return SwiftSymbol(kind: .suffix, children: [], contents: .name(String(String.UnicodeScalarView(scanner.scalars))))
    }

    mutating func parseAndPushNames() throws {
        while !scanner.isAtEnd {
            nameStack.append(try demangleOperator())
        }
    }

    mutating func demangleOperator() throws -> SwiftSymbol {
        switch try scanner.readScalar() {
        case "\u{1}": return SwiftSymbol(kind: .unresolvedSymbolicReference)
        case "A": return try demangleMultiSubstitutions()
        case "B": return try demangleBuiltinType()
        case "C": return try demangleAnyGenericType(kind: .class)
        case "D": return SwiftSymbol(kind: .typeMangling, child: try require(pop(kind: .type)))
        case "E": return try demangleExtensionContext()
        case "F": return try demanglePlainFunction()
        case "G": return try demangleBoundGenericType()
        case "I": return try demangleImplFunctionType()
        case "K": return SwiftSymbol(kind: .throwsAnnotation)
        case "L": return try demangleLocalIdentifier()
        case "M": return try demangleMetatype()
        case "N": return SwiftSymbol(kind: .typeMetadata, child: try require(pop(kind: .type)))
        case "O": return try demangleAnyGenericType(kind: .enum)
        case "P": return try demangleAnyGenericType(kind: .protocol)
        case "Q": return try demangleArchetype()
        case "R": return try demangleGenericRequirement()
        case "S": return try demangleStandardSubstitution()
        case "T": return try demangleThunkOrSpecialization()
        case "V": return try demangleAnyGenericType(kind: .structure)
        case "W": return try demangleWitness()
        case "X": return try demangleSpecialType()
        case "Z": return SwiftSymbol(kind: .static, child: try require(pop(where: { $0.isEntity })))
        case "a": return try demangleAnyGenericType(kind: .typeAlias)
        case "c": return try require(popFunctionType(kind: .functionType))
        case "d": return SwiftSymbol(kind: .variadicMarker)
        case "f": return try demangleFunctionEntity()
        case "g": return try demangleRetroactiveConformance()
        case "h": return SwiftSymbol(typeWithChildKind: .shared, childChild: try require(popTypeAndGetChild()))
        case "i": return try demangleSubscript()
        case "l": return try demangleGenericSignature(hasParamCounts: false)
        case "m": return SwiftSymbol(typeWithChildKind: .metatype, childChild: try require(pop(kind: .type)))
        case "n": return SwiftSymbol(kind: .owned, child: try popTypeAndGetChild())
        case "o": return try demangleOperatorIdentifier();
        case "p": return try demangleProtocolListType();
        case "q": return SwiftSymbol(kind: .type, child: try demangleGenericParamIndex())
        case "r": return try demangleGenericSignature(hasParamCounts: true)
        case "s": return SwiftSymbol(kind: .module, contents: .name(stdlibName))
        case "t": return try popTuple()
        case "u": return try demangleGenericType()
        case "v": return try demangleVariable()
        case "w": return try demangleValueWitness()
        case "x": return SwiftSymbol(kind: .type, child: try getDependentGenericParamType(depth: 0, index: 0))
        case "y": return SwiftSymbol(kind: .emptyList)
        case "z": return SwiftSymbol(typeWithChildKind: .inOut, childChild: try require(popTypeAndGetChild()))
        case "_": return SwiftSymbol(kind: .firstElementMarker)
        case ".":
            try scanner.backtrack()
            return SwiftSymbol(kind: .suffix, contents: .name(scanner.remainder()))
        default:
            try scanner.backtrack()
            return try demangleIdentifier()
        }
    }

    mutating func demangleNatural() -> UInt32? {
        if let value = scanner.conditionalInt() {
            return UInt32(value)
        }
        return nil
    }

    mutating func demangleIndex() throws -> UInt32 {
        if scanner.conditional(scalar: "_") {
            return 0
        }
        let value = try require(demangleNatural())
        try scanner.match(scalar: "_")
        return value + 1
    }

    mutating func demangleIndexAsName() throws -> SwiftSymbol {
        return SwiftSymbol(kind: .number, contents: .index(try demangleIndex()))
    }

    mutating func demangleMultiSubstitutions() throws -> SwiftSymbol {
        var repeatCount: UInt32 = 0
        while true {
            let c = try scanner.readScalar()
            if c.isLower {
                let nd = try pushMultiSubstitutions(repeatCount: repeatCount, index: Int(c.value - UnicodeScalar("a").value))
                nameStack.append(nd)
                repeatCount = 0
                continue
            } else if c.isUpper {
                return try pushMultiSubstitutions(repeatCount: repeatCount, index: Int(c.value - UnicodeScalar("A").value))
            } else if c == "_" {
                let idx = Int(repeatCount + 27)
                return try require(substitutions.at(idx))
            } else {
                try scanner.backtrack()
                repeatCount = demangleNatural() ?? 0
            }
        }
    }

    mutating func pushMultiSubstitutions(repeatCount: UInt32, index: Int) throws -> SwiftSymbol {
        try require(repeatCount <= maxRepeatCount)
        let nd = try require(substitutions.at(index))
        if repeatCount > 1 {
            for _ in 0..<(repeatCount - 1) {
                nameStack.append(nd)
            }
        }
        return nd
    }

    mutating func pop() -> SwiftSymbol? {
        return nameStack.popLast()
    }

    mutating func pop(kind: SwiftSymbol.Kind) -> SwiftSymbol? {
        return nameStack.last?.kind == kind ? pop() : nil
    }

    mutating func pop(where cond: (SwiftSymbol.Kind) -> Bool) -> SwiftSymbol? {
        return nameStack.last.map({ cond($0.kind) }) == true ? pop() : nil
    }

    mutating func popFunctionType(kind: SwiftSymbol.Kind) throws -> SwiftSymbol {
        var name = SwiftSymbol(kind: kind)
        if let ta = pop(kind: .throwsAnnotation) {
            name.children.append(ta)
        }
        name.children.append(try popFunctionParams(kind: .argumentTuple))
        name.children.append(try popFunctionParams(kind: .returnType))
        return SwiftSymbol(kind: .type, child: name)
    }

    mutating func popFunctionParams(kind: SwiftSymbol.Kind) throws -> SwiftSymbol {
        let paramsType: SwiftSymbol
        if pop(kind: .emptyList) != nil {
            return SwiftSymbol(kind: kind, child: SwiftSymbol(kind: .type, child: SwiftSymbol(kind: .tuple)))
        } else {
            paramsType = try require(pop(kind: .type))
        }

        if kind == .argumentTuple {
            let params = try require(paramsType.children.first)
            let numParams = params.kind == .tuple ? params.children.count : 1
            return SwiftSymbol(kind: kind, children: [paramsType], contents: .index(UInt32(numParams)))
        } else {
            return SwiftSymbol(kind: kind, children: [paramsType])
        }
    }

    mutating func getLabel(params: inout SwiftSymbol, idx: Int) throws -> SwiftSymbol {
        if isOldFunctionTypeMangling {
            let param = try require(params.children.at(idx))
            if let label = param.children.enumerated().first(where: { $0.element.kind == .tupleElementName }) {
                params.children[idx].children.remove(at: label.offset)
                return SwiftSymbol(kind: .identifier, contents: .name(label.element.text ?? ""))
            }
            return SwiftSymbol(kind: .firstElementMarker)
        }
        return try require(pop())
    }

    mutating func popFunctionParamLabels(type: SwiftSymbol) throws -> (type: SwiftSymbol, labelList: SwiftSymbol)? {
        if !isOldFunctionTypeMangling && pop(kind: .emptyList) != nil {
            return (type: type, labelList: SwiftSymbol(kind: .labelList))
        }

        guard type.kind == .type else { return nil }

        let topFuncType = try require(type.children.first)
        let funcType: SwiftSymbol
        if topFuncType.kind == .dependentGenericType {
            funcType = try require(topFuncType.children.at(1)?.children.first)
        } else {
            funcType = topFuncType
        }

        guard funcType.kind == .functionType || funcType.kind == .noEscapeFunctionType else { return nil }

        var parameterType = try require(funcType.children.first)
        if parameterType.kind == .throwsAnnotation {
            parameterType = try require(funcType.children.at(1))
        }

        try require(parameterType.kind == .argumentTuple)
        guard let index = parameterType.index else { return nil }

        let possibleTupleType = parameterType.children.first
        let possibleTuple = possibleTupleType?.children.first
        if isOldFunctionTypeMangling && possibleTuple?.kind != .tuple {
            return (type: type, labelList: SwiftSymbol(kind: .labelList))
        }
        let tupleType = try require(possibleTupleType)
        var tuple = try require(possibleTuple)

        var hasLabels = false
        var children = [SwiftSymbol]()
        for i in 0..<index {
            let label = try getLabel(params: &tuple, idx: Int(i))
            try require(label.kind == .identifier || label.kind == .firstElementMarker)
            children.append(label)
            hasLabels = hasLabels || (label.kind != .firstElementMarker)
        }

        if !hasLabels {
            return (type: type, labelList: SwiftSymbol(kind: .labelList))
        }

        let modifiedTupleType = tupleType.changeChild(tuple, atIndex: 0)
        let modifiedParameterType = parameterType.changeChild(modifiedTupleType, atIndex: 0)
        var modifiedFuncType = funcType.changeChild(modifiedParameterType, atIndex: funcType.children.first?.kind == .throwsAnnotation ? 1 : 0)
        if type.children.first?.kind == .dependentGenericType {
            let modifiedDependentType = try require(topFuncType.children.at(1)).changeChild(modifiedFuncType, atIndex: 0)
            modifiedFuncType = modifiedDependentType.changeChild(modifiedDependentType, atIndex: 1)
        }
        let modifiedType = type.changeChild(modifiedFuncType, atIndex: 0)

        return (type: modifiedType, labelList: SwiftSymbol(kind: .labelList, children: isOldFunctionTypeMangling ? children : children.reversed()))
    }

    mutating func popTuple() throws -> SwiftSymbol {
        var children: [SwiftSymbol] = []
        if pop(kind: .emptyList) == nil {
            var firstElem = false
            repeat {
                firstElem = pop(kind: .firstElementMarker) != nil
                var elemChildren: [SwiftSymbol] = pop(kind: .variadicMarker).map { [$0] } ?? []
                if let ident = pop(kind: .identifier), case .name(let text) = ident.contents {
                    elemChildren.append(SwiftSymbol(kind: .tupleElementName, contents: .name(text)))
                }
                elemChildren.append(try require(pop(kind: .type)))
                children.insert(SwiftSymbol(kind: .tupleElement, children: elemChildren), at: 0)
            } while (!firstElem)
        }
        return SwiftSymbol(typeWithChildKind: .tuple, childChildren: children)
    }

    mutating func popTypeList() throws -> SwiftSymbol {
        var children: [SwiftSymbol] = []
        if pop(kind: .emptyList) == nil {
            var firstElem = false
            repeat {
                firstElem = pop(kind: .firstElementMarker) != nil
                children.insert(try require(pop(kind: .type)), at: 0)
            } while (!firstElem)
        }
        return SwiftSymbol(kind: .typeList, children: children)
    }

    mutating func popProtocol() throws -> SwiftSymbol {
        let name = try require(pop { $0.isDeclName })
        let context = try popContext()
        return SwiftSymbol(typeWithChildKind: .protocol, childChildren: [context, name])
    }

    mutating func popModule() -> SwiftSymbol? {
        if let ident = pop(kind: .identifier) {
            return ident.changeKind(.module)
        } else {
            return pop(kind: .module)
        }
    }

    mutating func popContext() throws -> SwiftSymbol {
        if let mod = popModule() {
            return mod
        } else if let type = pop(kind: .type) {
            let child = try require(type.children.first)
            try require(child.kind.isContext)
            return child
        }
        return try require(pop { $0.isContext })
    }

    mutating func popTypeAndGetChild() throws -> SwiftSymbol {
        return try require(pop(kind: .type)?.children.first)
    }

    mutating func popTypeAndGetAnyGeneric() throws -> SwiftSymbol {
        let child = try popTypeAndGetChild()
        try require(child.kind.isAnyGeneric)
        return child
    }

    mutating func popAssociatedTypeName() throws -> SwiftSymbol {
        let proto = pop(kind: .type)
        let id = try require(pop(kind: .identifier))
        var result = id.changeKind(.dependentAssociatedTypeRef)
        if let p = proto {
            try require(p.children.first?.kind == .protocol)
            result.children.append(p)
        }
        return result
    }

    mutating func popAssociatedTypePath() throws -> SwiftSymbol {
        var firstElem = false
        var assocTypePath = [SwiftSymbol]()
        repeat {
            firstElem = pop(kind: .firstElementMarker) != nil
            assocTypePath.append(try require(pop { $0.isDeclName }))
        } while !firstElem
        return SwiftSymbol(kind: .assocTypePath, children: assocTypePath.reversed())
    }

    mutating func popProtocolConformance() throws -> SwiftSymbol {
        let genSig = pop(kind: .dependentGenericSignature)
        let module = try require(popModule())
        let proto = try popProtocol()
        var type = pop(kind: .type)
        var ident: SwiftSymbol? = nil
        if type == nil {
            ident = pop(kind: .identifier)
            type = pop(kind: .type)
        }
        if let gs = genSig {
            type = SwiftSymbol(typeWithChildKind: .dependentGenericType, childChildren: [gs, try require(type)])
        }
        var children = [try require(type), proto, module]
        if let i = ident {
            children.append(i)
        }
        return SwiftSymbol(kind: .protocolConformance, children: children)
    }

    mutating func getDependentGenericParamType(depth: Int, index: Int) throws -> SwiftSymbol {
        try require(depth >= 0 && index >= 0)
        var charIndex = index
        var name = ""
        repeat {
            name.unicodeScalars.append(try require(UnicodeScalar(UnicodeScalar("A").value + UInt32(charIndex % 26))))
            charIndex /= 26
        } while charIndex != 0
        if depth != 0 {
            name.unicodeScalars.append(try require(UnicodeScalar(depth)))
        }

        return SwiftSymbol(kind: .dependentGenericParamType, children: [
            SwiftSymbol(kind: .index, contents: .index(UInt32(depth))),
            SwiftSymbol(kind: .index, contents: .index(UInt32(index)))
        ], contents: .name(name))
    }

    mutating func demangleStandardSubstitution() throws -> SwiftSymbol {
        switch try scanner.readScalar() {
        case "o": return SwiftSymbol(kind: .module, contents: .name(objcModule))
        case "C": return SwiftSymbol(kind: .module, contents: .name(cModule))
        case "g":
            let op = SwiftSymbol(typeWithChildKind: .boundGenericEnum, childChildren: [
                SwiftSymbol(swiftStdlibTypeKind: .enum, name: "Optional"),
                SwiftSymbol(kind: .typeList, child: try require(pop(kind: .type)))
            ])
            substitutions.append(op)
            return op
        default:
            try scanner.backtrack()
            let repeatCount = demangleNatural() ?? 0
            try require(repeatCount <= maxRepeatCount)
            let nd: SwiftSymbol
            switch try scanner.readScalar() {
            case "a": nd = SwiftSymbol(swiftStdlibTypeKind: .structure, name: "Array")
            case "b": nd = SwiftSymbol(swiftStdlibTypeKind: .structure, name: "Bool")
            case "c": nd = SwiftSymbol(swiftStdlibTypeKind: .structure, name: "UnicodeScalar")
            case "d": nd = SwiftSymbol(swiftStdlibTypeKind: .structure, name: "Double")
            case "f": nd = SwiftSymbol(swiftStdlibTypeKind: .structure, name: "Float")
            case "i": nd = SwiftSymbol(swiftStdlibTypeKind: .structure, name: "Int")
            case "V": nd = SwiftSymbol(swiftStdlibTypeKind: .structure, name: "UnsafeRawPointer")
            case "v": nd = SwiftSymbol(swiftStdlibTypeKind: .structure, name: "UnsafeMutableRawPointer")
            case "P": nd = SwiftSymbol(swiftStdlibTypeKind: .structure, name: "UnsafePointer")
            case "p": nd = SwiftSymbol(swiftStdlibTypeKind: .structure, name: "UnsafeMutablePointer")
            case "q": nd = SwiftSymbol(swiftStdlibTypeKind: .enum, name: "Optional")
            case "Q": nd = SwiftSymbol(swiftStdlibTypeKind: .enum, name: "ImplicitlyUnwrappedOptional")
            case "R": nd = SwiftSymbol(swiftStdlibTypeKind: .structure, name: "UnsafeBufferPointer")
            case "r": nd = SwiftSymbol(swiftStdlibTypeKind: .structure, name: "UnsafeMutableBufferPointer")
            case "S": nd = SwiftSymbol(swiftStdlibTypeKind: .structure, name: "String")
            case "u": nd = SwiftSymbol(swiftStdlibTypeKind: .structure, name: "UInt")
            default: throw failure
            }
            if repeatCount > 1 {
                for _ in 0..<(repeatCount - 1) {
                    nameStack.append(nd)
                }
            }
            return nd
        }
    }

    mutating func demangleIdentifier() throws -> SwiftSymbol {
        var hasWordSubs = false
        var isPunycoded = false
        let c = try scanner.read(where: { $0.isDigit })
        if c == "0" {
            if try scanner.readScalar() == "0" {
                isPunycoded = true
            } else {
                try scanner.backtrack()
                hasWordSubs = true
            }
        } else {
            try scanner.backtrack()
        }

        var identifier = ""
        repeat {
            while hasWordSubs && scanner.peek()?.isLetter == true {
                let c = try scanner.readScalar()
                var wordIndex = 0
                if c.isLower {
                    wordIndex = Int(c.value - UnicodeScalar("a").value)
                } else {
                    wordIndex = Int(c.value - UnicodeScalar("A").value)
                    hasWordSubs = false
                }
                try require(wordIndex < maxNumWords)
                identifier.append(try require(words.at(wordIndex)))
            }
            if scanner.conditional(scalar: "0") {
                break
            }
            let numChars = try require(demangleNatural())
            try require(numChars > 0)
            if isPunycoded {
                _ = scanner.conditional(scalar: "_")
            }
            let text = try scanner.readScalars(count: Int(numChars))
            if isPunycoded {
                identifier.append(decodeSwiftPunycode(text))
            } else {
                identifier.append(text)
                var word: String?
                for c in text.unicodeScalars {
                    if word == nil, !c.isDigit && c != "_" && words.count < maxNumWords {
                        word = "\(c)"
                    } else if let w = word {
                        if (c == "_") || (w.unicodeScalars.last?.isUpper == false && c.isUpper) {
                            if w.unicodeScalars.count >= 2 {
                                words.append(w)
                            }
                            if !c.isDigit && c != "_" && words.count < maxNumWords {
                                word = "\(c)"
                            } else {
                                word = nil
                            }
                        } else {
                            word?.unicodeScalars.append(c)
                        }
                    }
                }
                if let w = word, w.unicodeScalars.count >= 2 {
                    words.append(w)
                }
            }
        } while hasWordSubs
        try require(!identifier.isEmpty)
        let result = SwiftSymbol(kind: .identifier, contents: .name(identifier))
        substitutions.append(result)
        return result
    }

    mutating func demangleOperatorIdentifier() throws -> SwiftSymbol {
        let ident = try require(pop(kind: .identifier))
        let opCharTable = Array("& @/= >    <*!|+?%-~   ^ .".unicodeScalars)

        var str = ""
        for c in (try require(ident.text)).unicodeScalars {
            if !c.isASCII {
                str.unicodeScalars.append(c)
            } else {
                try require(c.isLower)
                let o = try require(opCharTable.at(Int(c.value - UnicodeScalar("a").value)))
                try require(o != " ")
                str.unicodeScalars.append(o)
            }
        }
        switch try scanner.readScalar() {
        case "i": return SwiftSymbol(kind: .infixOperator, contents: .name(str))
        case "p": return SwiftSymbol(kind: .prefixOperator, contents: .name(str))
        case "P": return SwiftSymbol(kind: .postfixOperator, contents: .name(str))
        default: throw failure
        }
    }

    mutating func demangleLocalIdentifier() throws -> SwiftSymbol {
        let c = try scanner.readScalar()
        switch c {
        case "L":
            let discriminator = try require(pop(kind: .identifier))
            let name = try require(pop(where: { $0.isDeclName }))
            return SwiftSymbol(kind: .privateDeclName, children: [discriminator, name])
        case "l":
            let discriminator = try require(pop(kind: .identifier))
            return SwiftSymbol(kind: .privateDeclName, children: [discriminator])
        case "a"..."j", "A"..."J":
            return SwiftSymbol(kind: .relatedEntityDeclName, children: [try require(pop())], contents: .name(String(c)))
        default:
            try scanner.backtrack()
            let discriminator = try demangleIndexAsName()
            let name = try require(pop(where: { $0.isDeclName }))
            return SwiftSymbol(kind: .localDeclName, children: [discriminator, name])
        }
    }

    mutating func demangleBuiltinType() throws -> SwiftSymbol {
        switch try scanner.readScalar() {
        case "b": return SwiftSymbol(swiftBuiltinType: .builtinTypeName, name: "Builtin.BridgeObject")
        case "B": return SwiftSymbol(swiftBuiltinType: .builtinTypeName, name: "Builtin.UnsafeValueBuffer")
        case "f":
            let size = try demangleIndex() - 1
            try require(size > 0)
            return SwiftSymbol(swiftBuiltinType: .builtinTypeName, name: "Builtin.Float\(size)")
        case "i":
            let size = try demangleIndex() - 1
            try require(size > 0)
            return SwiftSymbol(swiftBuiltinType: .builtinTypeName, name: "Builtin.Int\(size)")
        case "v":
            let elts = try demangleIndex() - 1
            try require(elts > 0)
            let eltType = try popTypeAndGetChild()
            let text = try require(eltType.text)
            try require(eltType.kind == .builtinTypeName && text.starts(with: "Builtin.") == true)
            let name = text["Builtin.".endIndex...]
            return SwiftSymbol(swiftBuiltinType: .builtinTypeName, name: "Builtin.Vec\(elts)x\(name)")
        case "O": return SwiftSymbol(swiftBuiltinType: .builtinTypeName, name: "Builtin.UnknownObject")
        case "o": return SwiftSymbol(swiftBuiltinType: .builtinTypeName, name: "Builtin.NativeObject")
        case "p": return SwiftSymbol(swiftBuiltinType: .builtinTypeName, name: "Builtin.RawPointer")
        case "t": return SwiftSymbol(swiftBuiltinType: .builtinTypeName, name: "Builtin.SILToken")
        case "w": return SwiftSymbol(swiftBuiltinType: .builtinTypeName, name: "Builtin.Word")
        default: throw failure
        }
    }

    mutating func demangleAnyGenericType(kind: SwiftSymbol.Kind) throws -> SwiftSymbol {
        let name = try require(pop(where: { $0.isDeclName }))
        let ctx = try popContext()
        let type = SwiftSymbol(typeWithChildKind: kind, childChildren: [ctx, name])
        substitutions.append(type)
        return type
    }

    mutating func demangleExtensionContext() throws -> SwiftSymbol {
        let genSig = pop(kind: .dependentGenericSignature)
        let module = try require(popModule())
        let type = try popTypeAndGetAnyGeneric()
        if let g = genSig {
            return SwiftSymbol(kind: .extension, children: [module, type, g])
        } else {
            return SwiftSymbol(kind: .extension, children: [module, type])
        }
    }

    mutating func demanglePlainFunction() throws -> SwiftSymbol {
        let genSig = pop(kind: .dependentGenericSignature)
        var type = try popFunctionType(kind: .functionType)
        let possibleModifiedTypeAndLabelList = try popFunctionParamLabels(type: type)

        if let g = genSig {
            type = SwiftSymbol(typeWithChildKind: .dependentGenericType, childChildren: [g, type])
        }
        let name = try require(pop(where: { $0.isDeclName }))
        let ctx = try popContext()
        if let (modifiedType, labelList) = possibleModifiedTypeAndLabelList {
            return SwiftSymbol(kind: .function, children: [ctx, name, labelList, modifiedType])
        }
        return SwiftSymbol(kind: .function, children: [ctx, name, type])
    }

    mutating func demangleRetroactiveConformance() throws -> SwiftSymbol {
        let index = try demangleIndexAsName()
        let conformance = try popProtocolConformance()
        return SwiftSymbol(kind: .retroactiveConformance, children: [index, conformance])
    }

    mutating func demangleBoundGenericType() throws -> SwiftSymbol {
        var retroactiveConformances: [SwiftSymbol] = []
        while let conformance = pop(kind: .retroactiveConformance) {
            retroactiveConformances.append(conformance)
        }

        var array = [SwiftSymbol]()
        while true {
            var children = [SwiftSymbol]()
            while let t = pop(kind: .type) {
                children.append(t)
            }
            array.append(SwiftSymbol(kind: .typeList, children: children.reversed()))

            if pop(kind: .emptyList) != nil {
                break
            } else {
                _ = try require(pop(kind: .firstElementMarker))
            }
        }
        let nominal = try popTypeAndGetAnyGeneric()
        var children = [try demangleBoundGenericArgs(nominal: nominal, array: array, index: 0)]
        if !retroactiveConformances.isEmpty {
            children.append(SwiftSymbol(kind: .typeList, children: retroactiveConformances.reversed()))
        }
        let type = SwiftSymbol(kind: .type, children: children)
        substitutions.append(type)
        return type
    }

    mutating func demangleBoundGenericArgs(nominal: SwiftSymbol, array: [SwiftSymbol], index: Int) throws -> SwiftSymbol {

        if nominal.kind == .symbolicReference || nominal.kind == .unresolvedSymbolicReference {
            let remaining = array.reversed().flatMap { $0.children }
            return SwiftSymbol(kind: .boundGenericOtherNominalType, children: [SwiftSymbol(kind: .type, child: nominal), SwiftSymbol(kind: .typeList, children: remaining)])
        }

        try require(nominal.children.count >= 2)
        let args = try require(array.at(index))
        let context = try require(nominal.children.first)

        let n: SwiftSymbol
        if index + 1 < array.count {
            var boundParent: SwiftSymbol
            if context.kind == .extension {
                let p = try demangleBoundGenericArgs(nominal: try require(context.children.at(1)), array: array, index: index + 1)
                boundParent = SwiftSymbol(kind: .extension, children: [try require(context.children.first), p])
                if let thirdChild = context.children.at(2) {
                    boundParent.children.append(thirdChild)
                }
            } else {
                boundParent = try demangleBoundGenericArgs(nominal: context, array: array, index: index + 1)
            }
            n = SwiftSymbol(kind: nominal.kind, children: [boundParent, try require(nominal.children.at(1))])
        } else {
            n = nominal
        }

        if args.children.count == 0 {
            return n
        }

        let kind: SwiftSymbol.Kind
        switch n.kind {
        case .class: kind = .boundGenericClass
        case .structure: kind = .boundGenericStructure
        case .enum: kind = .boundGenericEnum
        case .otherNominalType: kind = .boundGenericOtherNominalType
        default: throw failure
        }

        return SwiftSymbol(kind: kind, children: [SwiftSymbol(kind: .type, child: n), args])
    }

    mutating func demangleImplParamConvention() throws -> SwiftSymbol? {
        let attr: String
        switch try scanner.readScalar() {
        case "i": attr = "@in"
        case "c": attr = "@in_constant"
        case "l": attr = "@inout"
        case "b": attr = "@inout_aliasable"
        case "n": attr = "@in_guaranteed"
        case "x": attr = "@owned"
        case "g": attr = "@guaranteed"
        case "e": attr = "@deallocating"
        case "y": attr = "@unowned"
        default:
            try scanner.backtrack()
            return nil
        }
        return SwiftSymbol(kind: .implParameter, child: SwiftSymbol(kind: .implConvention, contents: .name(attr)))
    }

    mutating func demangleImplResultConvention(kind: SwiftSymbol.Kind) throws -> SwiftSymbol? {
        let attr: String
        switch try scanner.readScalar() {
        case "r": attr = "@out"
        case "o": attr = "@owned"
        case "d": attr = "@unowned"
        case "u": attr = "@unowned_inner_pointer"
        case "a": attr = "@autoreleased"
        default:
            try scanner.backtrack()
            return nil
        }
        return SwiftSymbol(kind: kind, child: SwiftSymbol(kind: .implConvention, contents: .name(attr)))
    }

    mutating func demangleImplFunctionType() throws -> SwiftSymbol {
        var typeChildren = [SwiftSymbol]()
        var genSig = pop(kind: .dependentGenericSignature)
        if let g = genSig, scanner.conditional(scalar: "P") {
            genSig = g.changeKind(.dependentPseudogenericSignature)
        }
        if scanner.conditional(scalar: "e") {
            typeChildren.append(SwiftSymbol(kind: .implEscaping))
        }

        let cAttr: String
        switch try scanner.readScalar() {
        case "y": cAttr = "@callee_unowned"
        case "g": cAttr = "@callee_guaranteed"
        case "x": cAttr = "@callee_owned"
        case "t": cAttr = "@convention(thin)"
        default: throw failure
        }
        typeChildren.append(SwiftSymbol(kind: .implConvention, contents: .name(cAttr)))

        let fAttr: String?
        switch try scanner.readScalar() {
        case "B": fAttr = "@convention(block)"
        case "C": fAttr = "@convention(c)"
        case "M": fAttr = "@convention(method)"
        case "O": fAttr = "@convention(objc_method)"
        case "K": fAttr = "@convention(closure)"
        case "W": fAttr = "@convention(witness_method)"
        default:
            try scanner.backtrack()
            fAttr = nil
        }
        if let fa = fAttr {
            typeChildren.append(SwiftSymbol(kind: .implFunctionAttribute, contents: .name(fa)))
        }

        if let g = genSig {
            typeChildren.append(g)
        }

        var numTypesToAdd = 0
        while let param = try demangleImplParamConvention() {
            typeChildren.append(param)
            numTypesToAdd += 1
        }
        while let result = try demangleImplResultConvention(kind: .implResult) {
            typeChildren.append(result)
            numTypesToAdd += 1
        }
        if scanner.conditional(scalar: "z") {
            typeChildren.append(try require(demangleImplResultConvention(kind: .implErrorResult)))
            numTypesToAdd += 1
        }
        try scanner.match(scalar: "_")
        for i in 0..<numTypesToAdd {
            try require(typeChildren.indices.contains(typeChildren.count - i - 1))
            typeChildren[typeChildren.count - i - 1].children.append(try require(pop(kind: .type)))
        }

        return SwiftSymbol(typeWithChildKind: .implFunctionType, childChildren: typeChildren)
    }

    mutating func demangleMetatype() throws -> SwiftSymbol {
        switch try scanner.readScalar() {
        case "c": return SwiftSymbol(kind: .protocolConformanceDescriptor, child: try require(popProtocolConformance()))
        case "f": return SwiftSymbol(kind: .fullTypeMetadata, child: try require(pop(kind: .type)))
        case "P": return SwiftSymbol(kind: .genericTypeMetadataPattern, child: try require(pop(kind: .type)))
        case "a": return SwiftSymbol(kind: .typeMetadataAccessFunction, child: try require(pop(kind: .type)))
        case "I": return SwiftSymbol(kind: .typeMetadataInstantiationCache, child: try require(pop(kind: .type)))
        case "i": return SwiftSymbol(kind: .typeMetadataInstantiationFunction, child: try require(pop(kind: .type)))
        case "r": return SwiftSymbol(kind: .typeMetadataCompletionFunction, child: try require(pop(kind: .type)))
        case "L": return SwiftSymbol(kind: .typeMetadataLazyCache, child: try require(pop(kind: .type)))
        case "m": return SwiftSymbol(kind: .metaclass, child: try require(pop(kind: .type)))
        case "n": return SwiftSymbol(kind: .nominalTypeDescriptor, child: try require(pop(kind: .type)))
        case "o": return SwiftSymbol(kind: .classMetadataBaseOffset, child: try require(pop(kind: .type)))
        case "p": return SwiftSymbol(kind: .protocolDescriptor, child: try popProtocol())
        case "B": return SwiftSymbol(kind: .reflectionMetadataBuiltinDescriptor, child: try require(pop(kind: .type)))
        case "F": return SwiftSymbol(kind: .reflectionMetadataFieldDescriptor, child: try require(pop(kind: .type)))
        case "A": return SwiftSymbol(kind: .reflectionMetadataAssocTypeDescriptor, child: try popProtocolConformance())
        case "C":
            let t = try require(pop(kind: .type))
            try require(t.children.first?.kind.isAnyGeneric == true)
            return SwiftSymbol(kind: .reflectionMetadataSuperclassDescriptor, child: try require(t.children.first))
        case "V": return SwiftSymbol(kind: .propertyDescriptor, child: try require(pop { $0.isEntity }))
        case "X": return try demanglePrivateContextDescriptor()
        default: throw failure
        }
    }

    mutating func demanglePrivateContextDescriptor() throws -> SwiftSymbol {
        switch try scanner.readScalar() {
        case "E": return SwiftSymbol(kind: .extensionDescriptor, child: try popContext())
        case "M": return SwiftSymbol(kind: .moduleDescriptor, child: try require(popModule()))
        case "Y":
            let discriminator = try require(pop())
            let context = try popContext()
            return SwiftSymbol(kind: .anonymousDescriptor, children: [context, discriminator])
        case "X": return SwiftSymbol(kind: .anonymousDescriptor, child: try popContext())
        case "A":
            let path = try require(popAssociatedTypePath())
            let base = try require(pop(kind: .type))
            return SwiftSymbol(kind: .associatedTypeGenericParamRef, children: [base, path])
        default: throw failure
        }
    }

    mutating func demangleArchetype() throws -> SwiftSymbol {
        switch try scanner.readScalar() {
        case "a":
            let ident = try require(pop(kind: .identifier))
            let arch = try popTypeAndGetChild()
            let assoc = SwiftSymbol(typeWithChildKind: .associatedTypeRef, childChildren: [arch, ident])
            substitutions.append(assoc)
            return assoc
        case "q":
            let idx = try demangleIndexAsName()
            let ctx = try popContext()
            let declCtx = SwiftSymbol(kind: .declContext, child: ctx)
            return SwiftSymbol(typeWithChildKind: .qualifiedArchetype, childChildren: [idx, declCtx])
        case "y":
            let t = try demangleAssociatedTypeSimple(index: demangleGenericParamIndex())
            substitutions.append(t)
            return t
        case "z":
            let t = try demangleAssociatedTypeSimple(index: getDependentGenericParamType(depth: 0, index: 0))
            substitutions.append(t)
            return t
        case "Y":
            let t = try demangleAssociatedTypeCompound(index: demangleGenericParamIndex())
            substitutions.append(t)
            return t
        case "Z":
            let t = try demangleAssociatedTypeCompound(index: getDependentGenericParamType(depth: 0, index: 0))
            substitutions.append(t)
            return t
        default: throw failure
        }
    }

    mutating func demangleAssociatedTypeSimple(index: SwiftSymbol) throws -> SwiftSymbol {
        let gpi = SwiftSymbol(kind: .type, child: index)
        let atName = try popAssociatedTypeName()
        return SwiftSymbol(typeWithChildKind: .dependentMemberType, childChildren: [gpi, atName])
    }

    mutating func demangleAssociatedTypeCompound(index: SwiftSymbol) throws -> SwiftSymbol {
        var assocTypeNames = [SwiftSymbol]()
        var firstElem = false
        repeat {
            firstElem = pop(kind: .firstElementMarker) != nil
            assocTypeNames.append(try popAssociatedTypeName())
        } while !firstElem

        var base = index
        while let assocType = assocTypeNames.popLast() {
            base = SwiftSymbol(kind: .dependentMemberType, children: [SwiftSymbol(kind: .type, child: base), assocType])
        }
        return SwiftSymbol(kind: .type, child: base)
    }

    mutating func demangleGenericParamIndex() throws -> SwiftSymbol {
        if scanner.conditional(scalar: "d") {
            let depth = try demangleIndex() + 1
            let index = try demangleIndex()
            return try getDependentGenericParamType(depth: Int(depth), index: Int(index))
        } else if scanner.conditional(scalar: "z") {
            return try getDependentGenericParamType(depth: 0, index: 0)
        } else {
            return try getDependentGenericParamType(depth: 0, index: Int(demangleIndex() + 1))
        }
    }

    mutating func demangleThunkOrSpecialization() throws -> SwiftSymbol {
        let c = try scanner.readScalar()
        switch c {
        case "c": return SwiftSymbol(kind: .curryThunk, child: try require(pop(where: { $0.isEntity })))
        case "j": return SwiftSymbol(kind: .dispatchThunk, child: try require(pop(where: { $0.isEntity })))
        case "o": return SwiftSymbol(kind: .objCAttribute)
        case "O": return SwiftSymbol(kind: .nonObjCAttribute)
        case "D": return SwiftSymbol(kind: .dynamicAttribute)
        case "d": return SwiftSymbol(kind: .directMethodReferenceAttribute)
        case "a": return SwiftSymbol(kind: .partialApplyObjCForwarder)
        case "A": return SwiftSymbol(kind: .partialApplyForwarder)
        case "m": return SwiftSymbol(kind: .mergedFunction)
        case "C": return SwiftSymbol(kind: .coroutineContinuationPrototype, child: try require(pop(kind: .type)))
        case "V":
            let base = try require(pop(where: { $0.isEntity }))
            let derived = try require(pop(where: { $0.isEntity }))
            return SwiftSymbol(kind: .vTableThunk, children: [derived, base])
        case "W":
            let entity = try require(pop(where: { $0.isEntity }))
            let conf = try popProtocolConformance()
            return SwiftSymbol(kind: .protocolWitness, children: [conf, entity])
        case "R", "r":
            let genSig = pop(kind: .dependentGenericSignature)
            let type2 = try require(pop(kind: .type))
            let type1 = try require(pop(kind: .type))
            if let gs = genSig {
                return SwiftSymbol(kind: c == "R" ? .reabstractionThunkHelper : .reabstractionThunk, children: [gs, type1, type2])
            } else {
                return SwiftSymbol(kind: c == "R" ? .reabstractionThunkHelper : .reabstractionThunk, children: [type1, type2])
            }
        case "g": return try demangleGenericSpecialization(kind: .genericSpecialization)
        case "G": return try demangleGenericSpecialization(kind: .genericSpecializationNotReAbstracted)
        case "P", "p":
            var spec = try demangleSpecAttributes(kind: c == "P" ? .genericPartialSpecializationNotReAbstracted : .genericPartialSpecialization)
            let param = SwiftSymbol(kind: .genericSpecializationParam, child: try require(pop(kind: .type)))
            spec.children.append(param)
            return spec
        case "f": return try demangleFunctionSpecialization()
        case "K", "k":
            let nodeKind: SwiftSymbol.Kind = c == "K" ? .keyPathGetterThunkHelper : .keyPathSetterThunkHelper
            var types = [SwiftSymbol]()
            var node = pop(kind: .type)
            while let n = node {
                types.append(n)
                node = pop(kind: .type)
            }
            var result: SwiftSymbol
            if let n = pop() {
                if n.kind == .dependentGenericSignature {
                    let decl = try require(pop())
                    result = SwiftSymbol(kind: nodeKind, children: [decl, n])
                } else {
                    result = SwiftSymbol(kind: nodeKind, child: n)
                }
            } else {
                throw failure
            }
            for t in types {
                result.children.append(t)
            }
            return result
        case "H", "h":
            let nodeKind: SwiftSymbol.Kind = c == "H" ? .keyPathEqualsThunkHelper : .keyPathHashThunkHelper
            var types = [SwiftSymbol]()
            let node = try require(pop())
            var genericSig: SwiftSymbol? = nil
            if node.kind == .dependentGenericSignature {
                genericSig = node
            } else if node.kind == .type {
                types.append(node)
            } else {
                throw failure
            }
            while let n = pop() {
                try require(n.kind == .type)
                types.append(n)
            }
            var result = SwiftSymbol(kind: nodeKind)
            for t in types {
                result.children.append(t)
            }
            if let gs = genericSig {
                result.children.append(gs)
            }
            return result
        case "v": return SwiftSymbol(kind: .outlinedVariable, contents: .index(try demangleIndex()))
        case "e": return SwiftSymbol(kind: .outlinedBridgedMethod, contents: .name(try demangleBridgedMethodParams()))
        default: throw failure
        }
    }

    mutating func demangleBridgedMethodParams() throws -> String {
        if scanner.conditional(scalar: "_") {
            return ""
        }
        var str = ""
        let kind = try scanner.readScalar()
        switch kind {
        case "p", "a", "m": str.unicodeScalars.append(kind)
        default: return ""
        }
        while !scanner.conditional(scalar: "_") {
            let c = try scanner.readScalar()
            try require(c == "n" || c == "b")
            str.unicodeScalars.append(c)
        }
        return str
    }

    mutating func demangleGenericSpecialization(kind: SwiftSymbol.Kind) throws -> SwiftSymbol {
        var spec = try demangleSpecAttributes(kind: kind)
        let list = try popTypeList()
        for t in list.children {
            spec.children.append(SwiftSymbol(kind: .genericSpecializationParam, child: t))
        }
        return spec
    }

    mutating func demangleFunctionSpecialization() throws -> SwiftSymbol {
        var spec = try demangleSpecAttributes(kind: .functionSignatureSpecialization, demangleUniqueId: true)
        var paramIdx: UInt32 = 0
        while !scanner.conditional(scalar: "_") {
            spec.children.append(try demangleFuncSpecParam(index: paramIdx))
            paramIdx += 1
        }
        if !scanner.conditional(scalar: "n") {
            spec.children.append(try demangleFuncSpecParam(index: ~0))
        }

        for paramIndexPair in spec.children.enumerated().reversed() {
            var param = paramIndexPair.element
            guard param.kind == .functionSignatureSpecializationParam else { continue }
            guard let kindName = param.children.first else { continue }
            guard kindName.kind == .functionSignatureSpecializationParamKind, case .index(let i) = kindName.contents, let paramKind = FunctionSigSpecializationParamKind(rawValue: i) else { throw failure }
            switch paramKind {
            case .constantPropFunction, .constantPropGlobal, .constantPropString, .closureProp:
                let fixedChildrenEndIndex = param.children.endIndex
                while let t = pop(kind: .type) {
                    try require(paramKind == .closureProp)
                    param.children.insert(t, at: fixedChildrenEndIndex)
                }
                let name = try require(pop(kind: .identifier))
                var text = try require(name.text)
                if paramKind == .constantPropString, !text.isEmpty, text.first == "_" {
                    text = String(text.dropFirst())
                }
                param.children.insert(SwiftSymbol(kind: .functionSignatureSpecializationParamPayload, contents: .name(text)), at: fixedChildrenEndIndex)
                spec.children[paramIndexPair.offset] = param
            default: break
            }
        }
        return spec
    }

    mutating func demangleFuncSpecParam(index: UInt32) throws -> SwiftSymbol {
        var param = SwiftSymbol(kind: .functionSignatureSpecializationParam, contents: .index(index))
        switch try scanner.readScalar() {
        case "n": break
        case "c": param.children.append(SwiftSymbol(kind: .functionSignatureSpecializationParamKind, contents: .index(FunctionSigSpecializationParamKind.closureProp.rawValue)))
        case "p":
            switch try scanner.readScalar() {
            case "f": param.children.append(SwiftSymbol(kind: .functionSignatureSpecializationParamKind, contents: .index(FunctionSigSpecializationParamKind.constantPropFunction.rawValue)))
            case "g": param.children.append(SwiftSymbol(kind: .functionSignatureSpecializationParamKind, contents: .index(FunctionSigSpecializationParamKind.constantPropGlobal.rawValue)))
            case "i": param.children.append(SwiftSymbol(kind: .functionSignatureSpecializationParamKind, contents: .index(FunctionSigSpecializationParamKind.constantPropInteger.rawValue)))
            case "d": param.children.append(SwiftSymbol(kind: .functionSignatureSpecializationParamKind, contents: .index(FunctionSigSpecializationParamKind.constantPropFloat.rawValue)))
            case "s":
                let encoding: String
                switch try scanner.readScalar() {
                case "b": encoding = "u8"
                case "w": encoding = "u16"
                case "c": encoding = "objc"
                default: throw failure
                }
                param.children.append(SwiftSymbol(kind: .functionSignatureSpecializationParamKind, contents: .index(FunctionSigSpecializationParamKind.constantPropString.rawValue)))
                param.children.append(SwiftSymbol(kind: .functionSignatureSpecializationParamPayload, contents: .name(encoding)))
            default: throw failure
            }
        case "d":
            var value = FunctionSigSpecializationParamKind.dead.rawValue
            if scanner.conditional(scalar: "G") {
                value |= FunctionSigSpecializationParamKind.ownedToGuaranteed.rawValue
            }
            if scanner.conditional(scalar: "X") {
                value |= FunctionSigSpecializationParamKind.sroa.rawValue
            }
            param.children.append(SwiftSymbol(kind: .functionSignatureSpecializationParamKind, contents: .index(value)))
        case "g":
            var value = FunctionSigSpecializationParamKind.ownedToGuaranteed.rawValue
            if scanner.conditional(scalar: "X") {
                value |= FunctionSigSpecializationParamKind.sroa.rawValue
            }
            param.children.append(SwiftSymbol(kind: .functionSignatureSpecializationParamKind, contents: .index(value)))
        case "x":
            param.children.append(SwiftSymbol(kind: .functionSignatureSpecializationParamKind, contents: .index(FunctionSigSpecializationParamKind.sroa.rawValue)))
        case "i":
            param.children.append(SwiftSymbol(kind: .functionSignatureSpecializationParamKind, contents: .index(FunctionSigSpecializationParamKind.boxToValue.rawValue)))
        case "s":
            param.children.append(SwiftSymbol(kind: .functionSignatureSpecializationParamKind, contents: .index(FunctionSigSpecializationParamKind.boxToStack.rawValue)))
        default: throw failure
        }
        return param
    }

    mutating func addFuncSpecParamNumber(param: inout SwiftSymbol, kind: FunctionSigSpecializationParamKind) throws {
        param.children.append(SwiftSymbol(kind: .functionSignatureSpecializationParamKind, contents: .index(kind.rawValue)))
        let str = scanner.readWhile { $0.isDigit }
        try require(!str.isEmpty)
        param.children.append(SwiftSymbol(kind: .functionSignatureSpecializationParamPayload, contents: .name(str)))
    }

    mutating func demangleSpecAttributes(kind: SwiftSymbol.Kind, demangleUniqueId: Bool = false) throws -> SwiftSymbol {
        let isFragile = scanner.conditional(scalar: "q")
        let passId = try scanner.readScalar().value - UnicodeScalar("0").value
        try require((0...9).contains(passId))
        let contents = demangleUniqueId ? (demangleNatural().map { SwiftSymbol.Contents.index($0) } ?? SwiftSymbol.Contents.none) : SwiftSymbol.Contents.none
        var specName = SwiftSymbol(kind: kind, contents: contents)
        if isFragile {
            specName.children.append(SwiftSymbol(kind: .specializationIsFragile))
        }
        specName.children.append(SwiftSymbol(kind: .specializationPassID, contents: .index(passId)))
        return specName
    }

    mutating func demangleWitness() throws -> SwiftSymbol {
        switch try scanner.readScalar() {
        case "C": return SwiftSymbol(kind: .enumCase, child: try require(pop(where: { $0.isEntity })))
        case "V": return SwiftSymbol(kind: .valueWitnessTable, child: try require(pop(kind: .type)))
        case "v":
            let directness: UInt32
            switch try scanner.readScalar() {
            case "d": directness = Directness.direct.rawValue
            case "i": directness = Directness.indirect.rawValue
            default: throw failure
            }
            return SwiftSymbol(kind: .fieldOffset, children: [SwiftSymbol(kind: .directness, contents: .index(directness)), try require(pop(where: { $0.isEntity }))])
        case "P": return SwiftSymbol(kind: .protocolWitnessTable, child: try popProtocolConformance())
        case "p": return SwiftSymbol(kind: .protocolWitnessTablePattern, child: try popProtocolConformance())
        case "G": return SwiftSymbol(kind: .genericProtocolWitnessTable, child: try popProtocolConformance())
        case "I": return SwiftSymbol(kind: .genericProtocolWitnessTableInstantiationFunction, child: try popProtocolConformance())
        case "R": return SwiftSymbol(kind: .protocolRequirementArray, child: try popProtocol())
        case "r": return SwiftSymbol(kind: .resilientProtocolWitnessTable, child: try popProtocolConformance())
        case "l":
            let conf = try popProtocolConformance()
            let type = try require(pop(kind: .type))
            return SwiftSymbol(kind: .lazyProtocolWitnessTableAccessor, children: [type, conf])
        case "L":
            let conf = try popProtocolConformance()
            let type = try require(pop(kind: .type))
            return SwiftSymbol(kind: .lazyProtocolWitnessTableCacheVariable, children: [type, conf])
        case "a": return SwiftSymbol(kind: .protocolWitnessTableAccessor, child: try popProtocolConformance())
        case "t":
            let name = try require(pop(where: { $0.isDeclName }))
            let conf = try popProtocolConformance()
            return SwiftSymbol(kind: .associatedTypeMetadataAccessor, children: [conf, name])
        case "T":
            let protoType = try require(pop(kind: .type))
            var assocTypePath = SwiftSymbol(kind: .assocTypePath)
            var firstElem = false
            repeat {
                firstElem = pop(kind: .firstElementMarker) != nil
                let assocType = try require(pop(where: { $0.isDeclName }))
                assocTypePath.children.insert(assocType, at: 0)
            } while !firstElem
            return SwiftSymbol(kind: .associatedTypeWitnessTableAccessor, children: [try popProtocolConformance(), assocTypePath, protoType])
        case "O":
            let sig = pop(kind: .dependentGenericSignature)
            let type = try require(pop(kind: .type))
            let children: [SwiftSymbol] = sig.map { [type, $0] } ?? [type]
            switch try scanner.readScalar() {
            case "y": return SwiftSymbol(kind: .outlinedCopy, children: children)
            case "e": return SwiftSymbol(kind: .outlinedConsume, children: children)
            case "r": return SwiftSymbol(kind: .outlinedRetain, children: children)
            case "s": return SwiftSymbol(kind: .outlinedRelease, children: children)
            case "b": return SwiftSymbol(kind: .outlinedInitializeWithTake, children: children)
            case "c": return SwiftSymbol(kind: .outlinedInitializeWithCopy, children: children)
            case "d": return SwiftSymbol(kind: .outlinedAssignWithTake, children: children)
            case "f": return SwiftSymbol(kind: .outlinedAssignWithCopy, children: children)
            case "h": return SwiftSymbol(kind: .outlinedDestroy, children: children)
            default: throw failure
            }
        default: throw failure
        }
    }

    mutating func demangleSpecialType() throws -> SwiftSymbol {
        let specialChar = try scanner.readScalar()
        switch specialChar {
        case "E": return try popFunctionType(kind: .noEscapeFunctionType)
        case "A": return try popFunctionType(kind: .escapingAutoClosureType)
        case "f": return try popFunctionType(kind: .thinFunctionType)
        case "K": return try popFunctionType(kind: .autoClosureType)
        case "U": return try popFunctionType(kind: .uncurriedFunctionType)
        case "B": return try popFunctionType(kind: .objCBlock)
        case "C": return try popFunctionType(kind: .cFunctionPointer)
        case "o": return SwiftSymbol(typeWithChildKind: .unowned, childChild: try require(pop(kind: .type)))
        case "u": return SwiftSymbol(typeWithChildKind: .unmanaged, childChild: try require(pop(kind: .type)))
        case "w": return SwiftSymbol(typeWithChildKind: .weak, childChild: try require(pop(kind: .type)))
        case "b": return SwiftSymbol(typeWithChildKind: .silBoxType, childChild: try require(pop(kind: .type)))
        case "D": return SwiftSymbol(typeWithChildKind: .dynamicSelf, childChild: try require(pop(kind: .type)))
        case "M":
            let mtr = try demangleMetatypeRepresentation()
            let type = try require(pop(kind: .type))
            return SwiftSymbol(typeWithChildKind: .metatype, childChildren: [mtr, type])
        case "m":
            let mtr = try demangleMetatypeRepresentation()
            let type = try require(pop(kind: .type))
            return SwiftSymbol(typeWithChildKind: .existentialMetatype, childChildren: [mtr, type])
        case "p": return SwiftSymbol(typeWithChildKind: .existentialMetatype, childChild: try require(pop(kind: .type)))
        case "c":
            let superclass = try require(pop(kind: .type))
            let protocols = try demangleProtocolList()
            return SwiftSymbol(typeWithChildKind: .protocolListWithClass, childChildren: [protocols, superclass])
        case "l": return SwiftSymbol(typeWithChildKind: .protocolListWithAnyObject, childChild: try demangleProtocolList())
        case "X", "x":
            var signatureGenericArgs: (SwiftSymbol, SwiftSymbol)? = nil
            if specialChar == "X" {
                signatureGenericArgs = (try require(pop(kind: .dependentGenericSignature)), try popTypeList())
            }

            let fieldTypes = try popTypeList()
            var layout = SwiftSymbol(kind: .silBoxLayout)
            for fieldType in fieldTypes.children {
                try require(fieldType.kind == .type)
                if fieldType.children.first?.kind == .inOut {
                    layout.children.append(SwiftSymbol(kind: .silBoxMutableField, child: SwiftSymbol(kind: .type, child: try require(fieldType.children.first?.children.first))))
                } else {
                    layout.children.append(SwiftSymbol(kind: .silBoxImmutableField, child: fieldType))
                }
            }
            var boxType = SwiftSymbol(kind: .silBoxTypeWithLayout, child: layout)
            if let (signature, genericArgs) = signatureGenericArgs {
                boxType.children.append(signature)
                boxType.children.append(genericArgs)
            }
            return SwiftSymbol(kind: .type, child: boxType)
        case "Y": return try demangleAnyGenericType(kind: .otherNominalType)
        case "Z":
            let types = try popTypeList()
            let name = try require(pop(kind: .identifier))
            let parent = try popContext()
            return SwiftSymbol(kind: .anonymousContext, children: [name, parent, types])
        case "e": return SwiftSymbol(kind: .type, child: SwiftSymbol(kind: .errorType))
        default: throw failure
        }
    }

    mutating func demangleMetatypeRepresentation() throws -> SwiftSymbol {
        let value: String
        switch try scanner.readScalar() {
        case "t": value = "@thin"
        case "T": value = "@thick"
        case "o": value = "@objc_metatype"
        default: throw failure
        }
        return SwiftSymbol(kind: .metatypeRepresentation, contents: .name(value))
    }

    mutating func demangleAccessor(child: SwiftSymbol) throws -> SwiftSymbol {
        let kind: SwiftSymbol.Kind
        switch try scanner.readScalar() {
        case "m": kind = .materializeForSet
        case "s": kind = .setter
        case "g": kind = .getter
        case "G": kind = .globalGetter
        case "w": kind = .willSet
        case "W": kind = .didSet
        case "a":
            switch try scanner.readScalar() {
            case "O": kind = .owningMutableAddressor
            case "o": kind = .nativeOwningMutableAddressor
            case "p": kind = .nativePinningMutableAddressor
            case "u": kind = .unsafeMutableAddressor
            default: throw failure
            }
        case "l":
            switch try scanner.readScalar() {
            case "O": kind = .owningAddressor
            case "o": kind = .nativeOwningAddressor
            case "p": kind = .nativePinningAddressor
            case "u": kind = .unsafeAddressor
            default: throw failure
            }
        case "p": return child
        default: throw failure
        }
        return SwiftSymbol(kind: kind, child: child)
    }

    mutating func demangleFunctionEntity() throws -> SwiftSymbol {
        let argsAndKind: (args: DemangleFunctionEntityArgs, kind: SwiftSymbol.Kind)
        switch try scanner.readScalar() {
        case "D": argsAndKind = (.none, .deallocator)
        case "d": argsAndKind = (.none, .destructor)
        case "E": argsAndKind = (.none, .iVarDestroyer)
        case "e": argsAndKind = (.none, .iVarInitializer)
        case "i": argsAndKind = (.none, .initializer)
        case "C": argsAndKind = (.typeAndMaybePrivateName, .allocator)
        case "c": argsAndKind = (.typeAndMaybePrivateName, .constructor)
        case "U": argsAndKind = (.typeAndIndex, .explicitClosure)
        case "u": argsAndKind = (.typeAndIndex, .implicitClosure)
        case "A": argsAndKind = (.index, .defaultArgumentInitializer)
        case "p": return try demangleEntity(kind: .genericTypeParamDecl)
        default: throw failure
        }

        var children = [SwiftSymbol]()
        switch argsAndKind.args {
        case .none: break
        case .index: children.append(try demangleIndexAsName())
        case .typeAndIndex:
            let index = try demangleIndexAsName()
            let type = try require(pop(kind: .type))
            children += [index, type]
        case .typeAndMaybePrivateName:
            let privateName = pop(kind: .privateDeclName)
            let paramType = try require(pop(kind: .type))
            let possibleModifiedTypeAndLabelList = try popFunctionParamLabels(type: paramType)
            if let (modifiedType, labelList) = possibleModifiedTypeAndLabelList {
                children.append(labelList)
                children.append(modifiedType)
            } else {
                children.append(paramType)
            }
            if let pn = privateName {
                children.append(pn)
            }
        }
        return SwiftSymbol(kind: argsAndKind.kind, children: [try popContext()] + children)
    }

    mutating func demangleEntity(kind: SwiftSymbol.Kind) throws -> SwiftSymbol {
        let type = try require(pop(kind: .type))
        let name = try require(pop(where: { $0.isDeclName }))
        let context = try popContext()
        return SwiftSymbol(kind: kind, children: [context, name, type])
    }

    mutating func demangleVariable() throws -> SwiftSymbol {
        return try demangleAccessor(child: demangleEntity(kind: .variable))
    }

    mutating func demangleSubscript() throws -> SwiftSymbol {
        let privateName = pop(kind: .privateDeclName)
        let type = try require(pop(kind: .type))
        let context = try popContext()
        var ss = SwiftSymbol(kind: .subscript, children: [context, type])
        if let pn = privateName {
            ss.children.append(pn)
        }
        return try demangleAccessor(child: ss)
    }

    mutating func demangleProtocolList() throws -> SwiftSymbol {
        var typeList = SwiftSymbol(kind: .typeList)
        if pop(kind: .emptyList) == nil {
            var firstElem = false
            repeat {
                firstElem = pop(kind: .firstElementMarker) != nil
                typeList.children.insert(try popProtocol(), at: 0)
            } while !firstElem
        }
        return SwiftSymbol(kind: .protocolList, child: typeList)
    }

    mutating func demangleProtocolListType() throws -> SwiftSymbol {
        return SwiftSymbol(kind: .type, child: try demangleProtocolList())
    }

    mutating func demangleGenericSignature(hasParamCounts: Bool) throws -> SwiftSymbol {
        var sig = SwiftSymbol(kind: .dependentGenericSignature)
        if hasParamCounts {
            while !scanner.conditional(scalar: "l") {
                var count: UInt32 = 0
                if !scanner.conditional(scalar: "z") {
                    count = try demangleIndex() + 1
                }
                sig.children.append(SwiftSymbol(kind: .dependentGenericParamCount, contents: .index(count)))
            }
        } else {
            sig.children.append(SwiftSymbol(kind: .dependentGenericParamCount, contents: .index(1)))
        }
        let requirementsIndex = sig.children.endIndex
        while let req = pop(where: { $0.isRequirement }) {
            sig.children.insert(req, at: requirementsIndex)
        }
        return sig
    }

    mutating func demangleGenericRequirement() throws -> SwiftSymbol {
        let constraintAndTypeKinds: (constraint: DemangleGenericRequirementConstraintKind, type: DemangleGenericRequirementTypeKind)
        switch try scanner.readScalar() {
        case "c": constraintAndTypeKinds = (.baseClass, .assoc)
        case "C": constraintAndTypeKinds = (.baseClass, .compoundAssoc)
        case "b": constraintAndTypeKinds = (.baseClass, .generic)
        case "B": constraintAndTypeKinds = (.baseClass, .substitution)
        case "t": constraintAndTypeKinds = (.sameType, .assoc)
        case "T": constraintAndTypeKinds = (.sameType, .compoundAssoc)
        case "s": constraintAndTypeKinds = (.sameType, .generic)
        case "S": constraintAndTypeKinds = (.sameType, .substitution)
        case "m": constraintAndTypeKinds = (.layout, .assoc)
        case "M": constraintAndTypeKinds = (.layout, .compoundAssoc)
        case "l": constraintAndTypeKinds = (.layout, .generic)
        case "L": constraintAndTypeKinds = (.layout, .substitution)
        case "p": constraintAndTypeKinds = (.protocol, .assoc)
        case "P": constraintAndTypeKinds = (.protocol, .compoundAssoc)
        case "Q": constraintAndTypeKinds = (.protocol, .substitution)
        default:
            constraintAndTypeKinds = (.protocol, .generic)
            try scanner.backtrack()
        }

        let constrType: SwiftSymbol
        switch constraintAndTypeKinds.type {
        case .generic: constrType = SwiftSymbol(kind: .type, child: try demangleGenericParamIndex())
        case .assoc:
            constrType = try demangleAssociatedTypeSimple(index: demangleGenericParamIndex())
            substitutions.append(constrType)
        case .compoundAssoc:
            constrType = try demangleAssociatedTypeCompound(index: try demangleGenericParamIndex())
            substitutions.append(constrType)
        case .substitution: constrType = try require(pop(kind: .type))
        }

        switch constraintAndTypeKinds.constraint {
        case .protocol: return SwiftSymbol(kind: .dependentGenericConformanceRequirement, children: [constrType, try popProtocol()])
        case .baseClass: return SwiftSymbol(kind: .dependentGenericConformanceRequirement, children: [constrType, try require(pop(kind: .type))])
        case .sameType: return SwiftSymbol(kind: .dependentGenericSameTypeRequirement, children: [constrType, try require(pop(kind: .type))])
        case .layout:
            let c = try scanner.readScalar()
            var size: SwiftSymbol? = nil
            var alignment: SwiftSymbol? = nil
            switch c {
            case "U", "R", "N", "C", "D", "T": break
            case "E", "M":
                size = try demangleIndexAsName()
                alignment = try demangleIndexAsName()
            case "e", "m":
                size = try demangleIndexAsName()
            default: throw failure
            }
            let name = SwiftSymbol(kind: .identifier, contents: .name(String(String.UnicodeScalarView([c]))))
            var layoutRequirement = SwiftSymbol(kind: .dependentGenericLayoutRequirement, children: [constrType, name])
            if let s = size {
                layoutRequirement.children.append(s)
            }
            if let a = alignment {
                layoutRequirement.children.append(a)
            }
            return layoutRequirement
        }
    }

    mutating func demangleGenericType() throws -> SwiftSymbol {
        let genSig = try require(pop(kind: .dependentGenericSignature))
        let type = try require(pop(kind: .type))
        return SwiftSymbol(typeWithChildKind: .dependentGenericType, childChildren: [genSig, type])
    }

    mutating func demangleValueWitness() throws -> SwiftSymbol {
        let code = try scanner.readScalars(count: 2)
        let kind = try require(ValueWitnessKind(code: code))
        return SwiftSymbol(kind: .valueWitness, children: [try require(pop(kind: .type))], contents: .index(kind.rawValue))
    }

    mutating func demangleObjCTypeName() throws -> SwiftSymbol {
        var type = SwiftSymbol(kind: .type)
        if scanner.conditional(scalar: "C") {
            let module: SwiftSymbol
            if scanner.conditional(scalar: "s") {
                module = SwiftSymbol(kind: .module, contents: .name(stdlibName))
            } else {
                module = try demangleIdentifier().changeKind(.module)
            }
            type.children.append(SwiftSymbol(kind: .class, children: [module, try demangleIdentifier()]))
        } else if scanner.conditional(scalar: "P") {
            let module: SwiftSymbol
            if scanner.conditional(scalar: "s") {
                module = SwiftSymbol(kind: .module, contents: .name(stdlibName))
            } else {
                module = try demangleIdentifier().changeKind(.module)
            }
            type.children.append(SwiftSymbol(kind: .protocolList, child: SwiftSymbol(kind: .typeList, child: SwiftSymbol(kind: .type, child: SwiftSymbol(kind: .protocol, children: [module, try demangleIdentifier()])))))
            try scanner.match(scalar: "_")
        } else {
            throw failure
        }
        try require(scanner.isAtEnd)
        return SwiftSymbol(kind: .global, child: SwiftSymbol(kind: .typeMangling, child: type))
    }
}

// MARK Demangle.cpp (Swift 3)

fileprivate extension Demangler {

    mutating func demangleSwift3TopLevelSymbol() throws -> SwiftSymbol {
        reset()

        try scanner.match(string: "_T")
        var children = [SwiftSymbol]()

        switch (try scanner.readScalar(), try scanner.readScalar()) {
        case ("T", "S"):
            repeat {
                children.append(try demangleSwift3SpecializedAttribute())
                nameStack.removeAll()
            } while scanner.conditional(string: "_TTS")
            try scanner.match(string: "_T")
        case ("T", "o"): children.append(SwiftSymbol(kind: .objCAttribute))
        case ("T", "O"): children.append(SwiftSymbol(kind: .nonObjCAttribute))
        case ("T", "D"): children.append(SwiftSymbol(kind: .dynamicAttribute))
        case ("T", "d"): children.append(SwiftSymbol(kind: .directMethodReferenceAttribute))
        case ("T", "v"): children.append(SwiftSymbol(kind: .vTableAttribute))
        default: try scanner.backtrack(count: 2)
        }

        children.append(try demangleSwift3Global())

        let remainder = scanner.remainder()
        if !remainder.isEmpty {
            children.append(SwiftSymbol(kind: .suffix, contents: .name(remainder)))
        }

        return SwiftSymbol(kind: .global, children: children)
    }

    mutating func demangleSwift3Global() throws -> SwiftSymbol {
        let c1 = try scanner.readScalar()
        let c2 = try scanner.readScalar()
        switch (c1, c2) {
        case ("M", "P"): return SwiftSymbol(kind: .genericTypeMetadataPattern, children: [try demangleSwift3Type()])
        case ("M", "a"): return SwiftSymbol(kind: .typeMetadataAccessFunction, children: [try demangleSwift3Type()])
        case ("M", "L"): return SwiftSymbol(kind: .typeMetadataLazyCache, children: [try demangleSwift3Type()])
        case ("M", "m"): return SwiftSymbol(kind: .metaclass, children: [try demangleSwift3Type()])
        case ("M", "n"): return SwiftSymbol(kind: .nominalTypeDescriptor, children: [try demangleSwift3Type()])
        case ("M", "f"): return SwiftSymbol(kind: .fullTypeMetadata, children: [try demangleSwift3Type()])
        case ("M", "p"): return SwiftSymbol(kind: .protocolDescriptor, children: [try demangleSwift3ProtocolName()])
        case ("M", _):
            try scanner.backtrack()
            return SwiftSymbol(kind: .typeMetadata, children: [try demangleSwift3Type()])
        case ("P", "A"):
            return SwiftSymbol(kind: scanner.conditional(scalar: "o") ? .partialApplyObjCForwarder : .partialApplyForwarder, children: scanner.conditional(string: "__T") ? [try demangleSwift3Global()] : [])
        case ("P", _): throw scanner.unexpectedError()
        case ("t", _):
            try scanner.backtrack()
            return SwiftSymbol(kind: .typeMangling, children: [try demangleSwift3Type()])
        case ("w", _):
            let c3 = try scanner.readScalar()
            let value: UInt32
            switch (c2, c3) {
            case ("a", "l"): value = ValueWitnessKind.allocateBuffer.rawValue
            case ("c", "a"): value = ValueWitnessKind.assignWithCopy.rawValue
            case ("t", "a"): value = ValueWitnessKind.assignWithTake.rawValue
            case ("d", "e"): value = ValueWitnessKind.deallocateBuffer.rawValue
            case ("x", "x"): value = ValueWitnessKind.destroy.rawValue
            case ("X", "X"): value = ValueWitnessKind.destroyBuffer.rawValue
            case ("C", "P"): value = ValueWitnessKind.initializeBufferWithCopyOfBuffer.rawValue
            case ("C", "p"): value = ValueWitnessKind.initializeBufferWithCopy.rawValue
            case ("c", "p"): value = ValueWitnessKind.initializeWithCopy.rawValue
            case ("C", "c"): value = ValueWitnessKind.initializeArrayWithCopy.rawValue
            case ("T", "K"): value = ValueWitnessKind.initializeBufferWithTakeOfBuffer.rawValue
            case ("T", "k"): value = ValueWitnessKind.initializeBufferWithTake.rawValue
            case ("t", "k"): value = ValueWitnessKind.initializeWithTake.rawValue
            case ("T", "t"): value = ValueWitnessKind.initializeArrayWithTakeFrontToBack.rawValue
            case ("t", "T"): value = ValueWitnessKind.initializeArrayWithTakeBackToFront.rawValue
            case ("p", "r"): value = ValueWitnessKind.projectBuffer.rawValue
            case ("X", "x"): value = ValueWitnessKind.destroyArray.rawValue
            case ("x", "s"): value = ValueWitnessKind.storeExtraInhabitant.rawValue
            case ("x", "g"): value = ValueWitnessKind.getExtraInhabitantIndex.rawValue
            case ("u", "g"): value = ValueWitnessKind.getEnumTag.rawValue
            case ("u", "p"): value = ValueWitnessKind.destructiveProjectEnumData.rawValue
            default: throw scanner.unexpectedError()
            }
            return SwiftSymbol(kind: .valueWitness, children: [try demangleSwift3Type()], contents: .index(value))
        case ("W", "V"): return SwiftSymbol(kind: .valueWitnessTable, children: [try demangleSwift3Type()])
        case ("W", "v"): return SwiftSymbol(kind: .fieldOffset, children: [SwiftSymbol(kind: .directness, contents: .index(try scanner.readScalar() == "d" ? 0 : 1)), try demangleSwift3Entity()])
        case ("W", "P"): return SwiftSymbol(kind: .protocolWitnessTable, children: [try demangleSwift3ProtocolConformance()])
        case ("W", "G"): return SwiftSymbol(kind: .genericProtocolWitnessTable, children: [try demangleSwift3ProtocolConformance()])
        case ("W", "I"): return SwiftSymbol(kind: .genericProtocolWitnessTableInstantiationFunction, children: [try demangleSwift3ProtocolConformance()])
        case ("W", "l"): return SwiftSymbol(kind: .lazyProtocolWitnessTableAccessor, children: [try demangleSwift3Type(), try demangleSwift3ProtocolConformance()])
        case ("W", "L"): return SwiftSymbol(kind: .lazyProtocolWitnessTableCacheVariable, children: [try demangleSwift3Type(), try demangleSwift3ProtocolConformance()])
        case ("W", "a"): return SwiftSymbol(kind: .protocolWitnessTableAccessor, children: [try demangleSwift3ProtocolConformance()])
        case ("W", "t"): return SwiftSymbol(kind: .associatedTypeMetadataAccessor, children: [try demangleSwift3ProtocolConformance(), try demangleSwift3DeclName()])
        case ("W", "T"): return SwiftSymbol(kind: .associatedTypeWitnessTableAccessor, children: [try demangleSwift3ProtocolConformance(), try demangleSwift3DeclName(), try demangleSwift3ProtocolName()])
        case ("W", _): throw scanner.unexpectedError()
        case ("T", "W"): return SwiftSymbol(kind: .protocolWitness, children: [try demangleSwift3ProtocolConformance(), try demangleSwift3Entity()])
        case ("T", "R"): fallthrough
        case ("T", "r"): return SwiftSymbol(kind: c2 == "R" ? SwiftSymbol.Kind.reabstractionThunkHelper : SwiftSymbol.Kind.reabstractionThunk, children: scanner.conditional(scalar: "G") ? [try demangleSwift3GenericSignature(), try demangleSwift3Type(), try demangleSwift3Type()] : [try demangleSwift3Type(), try demangleSwift3Type()])
        default:
            try scanner.backtrack(count: 2)
            return try demangleSwift3Entity()
        }
    }

    mutating func demangleSwift3SpecializedAttribute() throws -> SwiftSymbol {
        let c = try scanner.readScalar()
        var children = [SwiftSymbol]()
        if scanner.conditional(scalar: "q") {
            children.append(SwiftSymbol(kind: .specializationIsFragile))
        }
        children.append(SwiftSymbol(kind: .specializationPassID, contents: .index(try scanner.readScalar().value - 48)))
        switch c {
        case "r": fallthrough
        case "g":
            while !scanner.conditional(scalar: "_") {
                var parameterChildren = [SwiftSymbol]()
                parameterChildren.append(try demangleSwift3Type())
                while !scanner.conditional(scalar: "_") {
                    parameterChildren.append(try demangleSwift3ProtocolConformance())
                }
                children.append(SwiftSymbol(kind: .genericSpecializationParam, children: parameterChildren))
            }
            return SwiftSymbol(kind: c == "r" ? .genericSpecializationNotReAbstracted : .genericSpecialization, children: children)
        case "f":
            var count: UInt32 = 0
            while !scanner.conditional(scalar: "_") {
                var paramChildren = [SwiftSymbol]()
                let c = try scanner.readScalar()
                switch (c, try scanner.readScalar()) {
                case ("n", "_"): break
                case ("c", "p"): paramChildren.append(contentsOf: try demangleSwift3FuncSigSpecializationConstantProp())
                case ("c", "l"):
                    paramChildren.append(SwiftSymbol(kind: .functionSignatureSpecializationParamKind, contents: .index(FunctionSigSpecializationParamKind.closureProp.rawValue)))
                    paramChildren.append(SwiftSymbol(kind: .functionSignatureSpecializationParamPayload, contents: try demangleSwift3Identifier().contents))
                    while !scanner.conditional(scalar: "_") {
                        paramChildren.append(try demangleSwift3Type())
                    }
                case ("i", "_"): fallthrough
                case ("k", "_"): paramChildren.append(SwiftSymbol(kind: .functionSignatureSpecializationParamKind, contents: .index(c == "i" ? FunctionSigSpecializationParamKind.boxToValue.rawValue : FunctionSigSpecializationParamKind.boxToStack.rawValue)))
                default:
                    try scanner.backtrack(count: 2)
                    var value: UInt32 = 0
                    value |= scanner.conditional(scalar: "d") ? FunctionSigSpecializationParamKind.dead.rawValue : 0
                    value |= scanner.conditional(scalar: "g") ? FunctionSigSpecializationParamKind.ownedToGuaranteed.rawValue : 0
                    value |= scanner.conditional(scalar: "s") ? FunctionSigSpecializationParamKind.sroa.rawValue : 0
                    try scanner.match(scalar: "_")
                    paramChildren.append(SwiftSymbol(kind: .functionSignatureSpecializationParamKind, contents: .index(value)))
                }
                children.append(SwiftSymbol(kind: .functionSignatureSpecializationParam, children: paramChildren, contents: .index(count)))
                count += 1
            }
            return SwiftSymbol(kind: .functionSignatureSpecialization, children: children)
        default: throw scanner.unexpectedError()
        }
    }

    mutating func demangleSwift3FuncSigSpecializationConstantProp() throws -> [SwiftSymbol] {
        switch (try scanner.readScalar(), try scanner.readScalar()) {
        case ("f", "r"):
            let name = SwiftSymbol(kind: .functionSignatureSpecializationParamPayload, contents: try demangleSwift3Identifier().contents)
            try scanner.match(scalar: "_")
            let kind = SwiftSymbol(kind: .functionSignatureSpecializationParamKind, contents: .index(FunctionSigSpecializationParamKind.constantPropFunction.rawValue))
            return [kind, name]
        case ("g", _):
            try scanner.backtrack()
            let name = SwiftSymbol(kind: .functionSignatureSpecializationParamPayload, contents: try demangleSwift3Identifier().contents)
            try scanner.match(scalar: "_")
            let kind = SwiftSymbol(kind: .functionSignatureSpecializationParamKind, contents: .index(FunctionSigSpecializationParamKind.constantPropGlobal.rawValue))
            return [kind, name]
        case ("i", _):
            try scanner.backtrack()
            let string = try scanner.readUntil(scalar: "_")
            try scanner.match(scalar: "_")
            let name = SwiftSymbol(kind: .functionSignatureSpecializationParamPayload, contents: .name(string))
            let kind = SwiftSymbol(kind: .functionSignatureSpecializationParamKind, contents: .index(FunctionSigSpecializationParamKind.constantPropInteger.rawValue))
            return [kind, name]
        case ("f", "l"):
            let string = try scanner.readUntil(scalar: "_")
            try scanner.match(scalar: "_")
            let name = SwiftSymbol(kind: .functionSignatureSpecializationParamPayload, contents: .name(string))
            let kind = SwiftSymbol(kind: .functionSignatureSpecializationParamKind, contents: .index(FunctionSigSpecializationParamKind.constantPropFloat.rawValue))
            return [kind, name]
        case ("s", "e"):
            var string: String
            switch try scanner.readScalar() {
            case "0": string = "u8"
            case "1": string = "u16"
            default: throw scanner.unexpectedError()
            }
            try scanner.match(scalar: "v")
            let name = SwiftSymbol(kind: .functionSignatureSpecializationParamPayload, contents: try demangleSwift3Identifier().contents)
            let encoding = SwiftSymbol(kind: .functionSignatureSpecializationParamPayload, contents: .name(string))
            let kind = SwiftSymbol(kind: .functionSignatureSpecializationParamKind, contents: .index(FunctionSigSpecializationParamKind.constantPropString.rawValue))
            try scanner.match(scalar: "_")
            return [kind, encoding, name]
        default: throw scanner.unexpectedError()
        }
    }

    mutating func demangleSwift3ProtocolConformance() throws -> SwiftSymbol {
        let type = try demangleSwift3Type()
        let prot = try demangleSwift3ProtocolName()
        let context = try demangleSwift3Context()
        return SwiftSymbol(kind: .protocolConformance, children: [type, prot, context])
    }

    mutating func demangleSwift3ProtocolName() throws -> SwiftSymbol {
        let name: SwiftSymbol
        if scanner.conditional(scalar: "S") {
            let index = try demangleSwift3SubstitutionIndex()
            switch index.kind {
            case .protocol: name = index
            case .module: name = try demangleSwift3ProtocolNameGivenContext(context: index)
            default: throw scanner.unexpectedError()
            }
        } else if scanner.conditional(scalar: "s") {
            let stdlib = SwiftSymbol(kind: .module, contents: .name(stdlibName))
            name = try demangleSwift3ProtocolNameGivenContext(context: stdlib)
        } else {
            name = try demangleSwift3DeclarationName(kind: .protocol)
        }

        return SwiftSymbol(kind: .type, children: [name])
    }

    mutating func demangleSwift3ProtocolNameGivenContext(context: SwiftSymbol) throws -> SwiftSymbol {
        let name = try demangleSwift3DeclName()
        let result = SwiftSymbol(kind: .protocol, children: [context, name])
        nameStack.append(result)
        return result
    }

    mutating func demangleSwift3NominalType() throws -> SwiftSymbol {
        switch try scanner.readScalar() {
        case "S": return try demangleSwift3SubstitutionIndex()
        case "V": return try demangleSwift3DeclarationName(kind: .structure)
        case "O": return try demangleSwift3DeclarationName(kind: .enum)
        case "C": return try demangleSwift3DeclarationName(kind: .class)
        case "P": return try demangleSwift3DeclarationName(kind: .protocol)
        default: throw scanner.unexpectedError()
        }
    }

    mutating func demangleSwift3BoundGenericArgs(nominalType initialNominal: SwiftSymbol) throws -> SwiftSymbol {
        guard var parentOrModule = initialNominal.children.first else { throw scanner.unexpectedError() }

        let nominalType: SwiftSymbol
        switch parentOrModule.kind {
        case .module: fallthrough
        case .function: fallthrough
        case .extension: nominalType = initialNominal
        default:
            parentOrModule = try demangleSwift3BoundGenericArgs(nominalType: parentOrModule)

            guard initialNominal.children.count > 1 else { throw scanner.unexpectedError() }
            nominalType = SwiftSymbol(kind: initialNominal.kind, children: [parentOrModule, initialNominal.children[1]])
        }

        var children = [SwiftSymbol]()
        while !scanner.conditional(scalar: "_") {
            children.append(try demangleSwift3Type())
        }
        if children.isEmpty {
            return nominalType
        }
        let args = SwiftSymbol(kind: .typeList, children: children)
        let unboundType = SwiftSymbol(kind: .type, children: [nominalType])
        switch nominalType.kind {
        case .class: return SwiftSymbol(kind: .boundGenericClass, children: [unboundType, args])
        case .structure: return SwiftSymbol(kind: .boundGenericStructure, children: [unboundType, args])
        case .enum: return SwiftSymbol(kind: .boundGenericEnum, children: [unboundType, args])
        default: throw scanner.unexpectedError()
        }
    }

    mutating func demangleSwift3Entity() throws -> SwiftSymbol {
        let isStatic = scanner.conditional(scalar: "Z")

        let basicKind: SwiftSymbol.Kind
        switch try scanner.readScalar() {
        case "F": basicKind = .function
        case "v": basicKind = .variable
        case "I": basicKind = .initializer
        case "i": basicKind = .subscript
        default:
            try scanner.backtrack()
            return try demangleSwift3NominalType()
        }

        let context = try demangleSwift3Context()
        let kind: SwiftSymbol.Kind
        let hasType: Bool
        var name: SwiftSymbol? = nil
        var wrapEntity: Bool = false

        let c = try scanner.readScalar()
        switch c {
        case "D": (kind, hasType) = (.deallocator, false)
        case "d": (kind, hasType) = (.destructor, false)
        case "e": (kind, hasType) = (.iVarInitializer, false)
        case "E": (kind, hasType) = (.iVarDestroyer, false)
        case "C": (kind, hasType) = (.allocator, true)
        case "c": (kind, hasType) = (.constructor, true)
        case "a": fallthrough
        case "l":
            wrapEntity = true
            switch try scanner.readScalar() {
            case "O": (kind, hasType, name) = (c == "a" ? .owningMutableAddressor : .owningAddressor, true, try demangleSwift3DeclName())
            case "o": (kind, hasType, name) = (c == "a" ? .nativeOwningMutableAddressor : .nativeOwningAddressor, true, try demangleSwift3DeclName())
            case "p": (kind, hasType, name) = (c == "a" ? .nativePinningMutableAddressor : .nativePinningAddressor, true, try demangleSwift3DeclName())
            case "u": (kind, hasType, name) = (c == "a" ? .unsafeMutableAddressor : .unsafeAddressor, true, try demangleSwift3DeclName())
            default: throw scanner.unexpectedError()
            }
        case "g": (kind, hasType, name, wrapEntity) = (.getter, true, try demangleSwift3DeclName(), true)
        case "G": (kind, hasType, name, wrapEntity) = (.globalGetter, true, try demangleSwift3DeclName(), true)
        case "s": (kind, hasType, name, wrapEntity) = (.setter, true, try demangleSwift3DeclName(), true)
        case "m": (kind, hasType, name, wrapEntity) = (.materializeForSet, true, try demangleSwift3DeclName(), true)
        case "w": (kind, hasType, name, wrapEntity) = (.willSet, true, try demangleSwift3DeclName(), true)
        case "W": (kind, hasType, name, wrapEntity) = (.didSet, true, try demangleSwift3DeclName(), true)
        case "U": (kind, hasType, name) = (.explicitClosure, true, SwiftSymbol(kind: .number, contents: .index(try demangleSwift3Index())))
        case "u": (kind, hasType, name) = (.implicitClosure, true, SwiftSymbol(kind: .number, contents: .index(try demangleSwift3Index())))
        case "A" where basicKind == .initializer: (kind, hasType, name) = (.defaultArgumentInitializer, false, SwiftSymbol(kind: .number, contents: .index(try demangleSwift3Index())))
        case "i" where basicKind == .initializer: (kind, hasType) = (.initializer, false)
        case _ where basicKind == .initializer: throw scanner.unexpectedError()
        default:
            try scanner.backtrack()
            (kind, hasType, name) = (basicKind, true, try demangleSwift3DeclName())
        }

        var entity = SwiftSymbol(kind: kind)
        if wrapEntity {
            var isSubscript = false
            switch name?.kind {
            case .some(.identifier):
                if name?.text == "subscript" {
                    isSubscript = true
                    name = nil
                }
            case .some(.privateDeclName):
                if let n = name, let first = n.children.at(0), let second = n.children.at(1), second.text == "subscript" {
                    isSubscript = true
                    name = SwiftSymbol(kind: .privateDeclName, children: [first])
                }
            default: break
            }
            var wrappedEntity: SwiftSymbol
            if isSubscript {
                wrappedEntity = SwiftSymbol(kind: .subscript, child: context)
            } else {
                wrappedEntity = SwiftSymbol(kind: .variable, child: context)
            }
            if !isSubscript, let n = name {
                wrappedEntity.children.append(n)
            }
            if hasType {
                wrappedEntity.children.append(try demangleSwift3Type())
            }
            if isSubscript, let n = name {
                wrappedEntity.children.append(n)
            }
            entity.children.append(wrappedEntity)
        } else {
            entity.children.append(context)
            if let n = name {
                entity.children.append(n)
            }
            if hasType {
                entity.children.append(try demangleSwift3Type())
            }
        }

        return isStatic ? SwiftSymbol(kind: .static, children: [entity]) : entity
    }

    mutating func demangleSwift3DeclarationName(kind: SwiftSymbol.Kind) throws -> SwiftSymbol {
        let result = SwiftSymbol(kind: kind, children: [try demangleSwift3Context(), try demangleSwift3DeclName()])
        nameStack.append(result)
        return result
    }

    mutating func demangleSwift3Context() throws -> SwiftSymbol {
        switch try scanner.readScalar() {
        case "E": return SwiftSymbol(kind: .extension, children: [try demangleSwift3Module(), try demangleSwift3Context()])
        case "e":
            let module = try demangleSwift3Module()
            let signature = try demangleSwift3GenericSignature()
            let type = try demangleSwift3Context()
            return SwiftSymbol(kind: .extension, children: [module, type, signature])
        case "S": return try demangleSwift3SubstitutionIndex()
        case "s": return SwiftSymbol(kind: .module, children: [], contents: .name(stdlibName))
        case "G": return try demangleSwift3BoundGenericArgs(nominalType: demangleSwift3NominalType())
        case "F": fallthrough
        case "I": fallthrough
        case "v": fallthrough
        case "P": fallthrough
        case "Z": fallthrough
        case "C": fallthrough
        case "V": fallthrough
        case "O":
            try scanner.backtrack()
            return try demangleSwift3Entity()
        default:
            try scanner.backtrack()
            return try demangleSwift3Module()
        }
    }

    mutating func demangleSwift3Module() throws -> SwiftSymbol {
        switch try scanner.readScalar() {
        case "S": return try demangleSwift3SubstitutionIndex()
        case "s": return SwiftSymbol(kind: .module, children: [], contents: .name("Swift"))
        default:
            try scanner.backtrack()
            let module = try demangleSwift3Identifier(kind: .module)
            nameStack.append(module)
            return module
        }
    }

    func swiftStdLibType(_ kind: SwiftSymbol.Kind, named: String) -> SwiftSymbol {
        return SwiftSymbol(kind: kind, children: [SwiftSymbol(kind: .module, contents: .name(stdlibName)), SwiftSymbol(kind: .identifier, contents: .name(named))])
    }

    mutating func demangleSwift3SubstitutionIndex() throws -> SwiftSymbol {
        switch try scanner.readScalar() {
        case "o": return SwiftSymbol(kind: .module, contents: .name(objcModule))
        case "C": return SwiftSymbol(kind: .module, contents: .name(cModule))
        case "a": return swiftStdLibType(.structure, named: "Array")
        case "b": return swiftStdLibType(.structure, named: "Bool")
        case "c": return swiftStdLibType(.structure, named: "UnicodeScalar")
        case "d": return swiftStdLibType(.structure, named: "Double")
        case "f": return swiftStdLibType(.structure, named: "Float")
        case "i": return swiftStdLibType(.structure, named: "Int")
        case "V": return swiftStdLibType(.structure, named: "UnsafeRawPointer")
        case "v": return swiftStdLibType(.structure, named: "UnsafeMutableRawPointer")
        case "P": return swiftStdLibType(.structure, named: "UnsafePointer")
        case "p": return swiftStdLibType(.structure, named: "UnsafeMutablePointer")
        case "q": return swiftStdLibType(.enum, named: "Optional")
        case "Q": return swiftStdLibType(.enum, named: "ImplicitlyUnwrappedOptional")
        case "R": return swiftStdLibType(.structure, named: "UnsafeBufferPointer")
        case "r": return swiftStdLibType(.structure, named: "UnsafeMutableBufferPointer")
        case "S": return swiftStdLibType(.structure, named: "String")
        case "u": return swiftStdLibType(.structure, named: "UInt")
        default:
            try scanner.backtrack()
            let index = try demangleSwift3Index()
            if Int(index) >= nameStack.count {
                throw scanner.unexpectedError()
            }
            return nameStack[Int(index)]
        }
    }

    mutating func demangleSwift3GenericSignature(isPseudo: Bool = false) throws -> SwiftSymbol {
        var children = [SwiftSymbol]()
        var c = try scanner.requirePeek()
        while c != "R" && c != "r" {
            children.append(SwiftSymbol(kind: .dependentGenericParamCount, contents: .index(scanner.conditional(scalar: "z") ? 0 : (try demangleSwift3Index() + 1))))
            c = try scanner.requirePeek()
        }
        if children.isEmpty {
            children.append(SwiftSymbol(kind: .dependentGenericParamCount, contents: .index(1)))
        }
        if !scanner.conditional(scalar: "r") {
            try scanner.match(scalar: "R")
            while !scanner.conditional(scalar: "r") {
                children.append(try demangleSwift3GenericRequirement())
            }
        }
        return SwiftSymbol(kind: .dependentGenericSignature, children: children)
    }

    mutating func demangleSwift3GenericRequirement() throws -> SwiftSymbol {
        let constrainedType = try demangleSwift3ConstrainedType()
        if scanner.conditional(scalar: "z") {
            return SwiftSymbol(kind: .dependentGenericSameTypeRequirement, children: [constrainedType, try demangleSwift3Type()])
        }

        if scanner.conditional(scalar: "l") {
            let name: String
            let kind: SwiftSymbol.Kind
            var size = UInt32.max
            var alignment = UInt32.max
            switch try scanner.readScalar() {
            case "U": (kind, name) = (.identifier, "U")
            case "R": (kind, name) = (.identifier, "R")
            case "N": (kind, name) = (.identifier, "N")
            case "T": (kind, name) = (.identifier, "T")
            case "E":
                (kind, name) = (.identifier, "E")
                size = try require(demangleNatural())
                try scanner.match(scalar: "_")
                alignment = try require(demangleNatural())
            case "e":
                (kind, name) = (.identifier, "e")
                size = try require(demangleNatural())
            case "M":
                (kind, name) = (.identifier, "M")
                size = try require(demangleNatural())
                try scanner.match(scalar: "_")
                alignment = try require(demangleNatural())
            case "m":
                (kind, name) = (.identifier, "m")
                size = try require(demangleNatural())
            default: throw failure
            }
            let second = SwiftSymbol(kind: kind, contents: .name(name))
            var reqt = SwiftSymbol(kind: .dependentGenericLayoutRequirement, children: [constrainedType, second])
            if size != UInt32.max {
                reqt.children.append(SwiftSymbol(kind: .number, contents: .index(size)))
                if alignment != UInt32.max {
                    reqt.children.append(SwiftSymbol(kind: .number, contents: .index(alignment)))
                }
            }
            return reqt
        }

        let c = try scanner.requirePeek()
        let constraint: SwiftSymbol
        if c == "C" {
            constraint = try demangleSwift3Type()
        } else if c == "S" {
            try scanner.match(scalar: "S")
            let index = try demangleSwift3SubstitutionIndex()
            let typename: SwiftSymbol
            switch index.kind {
            case .protocol: fallthrough
            case .class: typename = index
            case .module: typename = try demangleSwift3ProtocolNameGivenContext(context: index)
            default: throw scanner.unexpectedError()
            }
            constraint = SwiftSymbol(kind: .type, children: [typename])
        } else {
            constraint = try demangleSwift3ProtocolName()
        }
        return SwiftSymbol(kind: .dependentGenericConformanceRequirement, children: [constrainedType, constraint])
    }

    mutating func demangleSwift3ConstrainedType() throws -> SwiftSymbol {
        if scanner.conditional(scalar: "w") {
            return try demangleSwift3AssociatedTypeSimple()
        } else if scanner.conditional(scalar: "W") {
            return try demangleSwift3AssociatedTypeCompound()
        }
        return try demangleSwift3GenericParamIndex()
    }

    mutating func demangleSwift3AssociatedTypeSimple() throws -> SwiftSymbol {
        let base = try demangleSwift3GenericParamIndex()
        return try demangleSwift3DependentMemberTypeName(base: SwiftSymbol(kind: .type, children: [base]))
    }

    mutating func demangleSwift3AssociatedTypeCompound() throws -> SwiftSymbol {
        var base = try demangleSwift3GenericParamIndex()
        while !scanner.conditional(scalar: "_") {
            let type = SwiftSymbol(kind: .type, children: [base])
            base = try demangleSwift3DependentMemberTypeName(base: type)
        }
        return base
    }

    mutating func demangleSwift3GenericParamIndex() throws -> SwiftSymbol {
        let depth: UInt32
        let index: UInt32
        switch try scanner.readScalar() {
        case "d": (depth, index) = (try demangleSwift3Index() + 1, try demangleSwift3Index())
        case "x": (depth, index) = (0, 0)
        default:
            try scanner.backtrack()
            (depth, index) = (0, try demangleSwift3Index() + 1)
        }
        return SwiftSymbol(kind: .dependentGenericParamType, children: [SwiftSymbol(kind: .index, contents: .index(depth)), SwiftSymbol(kind: .index, contents: .index(index))], contents: .name(archetypeName(index, depth)))
    }

    mutating func demangleSwift3DependentMemberTypeName(base: SwiftSymbol) throws -> SwiftSymbol {
        let associatedType: SwiftSymbol
        if scanner.conditional(scalar: "S") {
            associatedType = try demangleSwift3SubstitutionIndex()
        } else {
            var prot: SwiftSymbol? = nil
            if scanner.conditional(scalar: "P") {
                prot = try demangleSwift3ProtocolName()
            }
            let at = try demangleSwift3Identifier(kind: .dependentAssociatedTypeRef)
            if let p = prot {
                var children = at.children
                children.append(p)
                associatedType = SwiftSymbol(kind: at.kind, children: children, contents: at.contents)
            } else {
                associatedType = at
            }
            nameStack.append(associatedType)
        }

        return SwiftSymbol(kind: .dependentMemberType, children: [base, associatedType])
    }

    mutating func demangleSwift3DeclName() throws -> SwiftSymbol {
        switch try scanner.readScalar() {
        case "L": return SwiftSymbol(kind: .localDeclName, children: [SwiftSymbol(kind: .number, contents: .index(try demangleSwift3Index())), try demangleSwift3Identifier()])
        case "P": return SwiftSymbol(kind: .privateDeclName, children: [try demangleSwift3Identifier(), try demangleSwift3Identifier()])
        default:
            try scanner.backtrack()
            return try demangleSwift3Identifier()
        }
    }

    mutating func demangleSwift3Index() throws -> UInt32 {
        if scanner.conditional(scalar: "_") {
            return 0
        }
        let value = UInt32(try scanner.readInt()) + 1
        try scanner.match(scalar: "_")
        return value
    }

    mutating func demangleSwift3Type() throws -> SwiftSymbol {
        let type: SwiftSymbol
        switch try scanner.readScalar() {
        case "B":
            switch try scanner.readScalar() {
            case "b": type = SwiftSymbol(kind: .builtinTypeName, contents: .name("Builtin.BridgeObject"))
            case "B": type = SwiftSymbol(kind: .builtinTypeName, contents: .name("Builtin.UnsafeValueBuffer"))
            case "f":
                let size = try scanner.readInt()
                try scanner.match(scalar: "_")
                type = SwiftSymbol(kind: .builtinTypeName, contents: .name("Builtin.Float\(size)"))
            case "i":
                let size = try scanner.readInt()
                try scanner.match(scalar: "_")
                type = SwiftSymbol(kind: .builtinTypeName, contents: .name("Builtin.Int\(size)"))
            case "v":
                let elements = try scanner.readInt()
                try scanner.match(scalar: "B")
                let name: String
                let size: String
                let c = try scanner.readScalar()
                switch c {
                case "p": (name, size) = ("xRawPointer", "")
                case "i": fallthrough
                case "f":
                    (name, size) = (c == "i" ? "xInt" : "xFloat", try "\(scanner.readInt())")
                    try scanner.match(scalar: "_")
                default: throw scanner.unexpectedError()
                }
                type = SwiftSymbol(kind: .builtinTypeName, contents: .name("Builtin.Vec\(elements)\(name)\(size)"))
            case "O": type = SwiftSymbol(kind: .builtinTypeName, contents: .name("Builtin.UnknownObject"))
            case "o": type = SwiftSymbol(kind: .builtinTypeName, contents: .name("Builtin.NativeObject"))
            case "t": type = SwiftSymbol(kind: .builtinTypeName, contents: .name("Builtin.SILToken"))
            case "p": type = SwiftSymbol(kind: .builtinTypeName, contents: .name("Builtin.RawPointer"))
            case "w": type = SwiftSymbol(kind: .builtinTypeName, contents: .name("Builtin.Word"))
            default: throw scanner.unexpectedError()
            }
        case "a": type = try demangleSwift3DeclarationName(kind: .typeAlias)
        case "b": type = try demangleSwift3FunctionType(kind: .objCBlock)
        case "c": type = try demangleSwift3FunctionType(kind: .cFunctionPointer)
        case "D": type = SwiftSymbol(kind: .dynamicSelf, children: [try demangleSwift3Type()])
        case "E":
            guard try scanner.readScalars(count: 2) == "RR" else { throw scanner.unexpectedError() }
            type = SwiftSymbol(kind: .errorType, children: [], contents: .name(""))
        case "F": type = try demangleSwift3FunctionType(kind: .functionType)
        case "f": type = try demangleSwift3FunctionType(kind: .uncurriedFunctionType)
        case "G": type = try demangleSwift3BoundGenericArgs(nominalType: demangleSwift3NominalType())
        case "X":
            let c = try scanner.readScalar()
            switch c {
            case "b": type = SwiftSymbol(kind: .silBoxType, children: [try demangleSwift3Type()])
            case "B":
                var signature: SwiftSymbol? = nil
                if scanner.conditional(scalar: "G") {
                    signature = try demangleSwift3GenericSignature(isPseudo: false)
                }
                var layout = SwiftSymbol(kind: .silBoxLayout)
                while !scanner.conditional(scalar: "_") {
                    let kind: SwiftSymbol.Kind
                    switch try scanner.readScalar() {
                    case "m": kind = .silBoxMutableField
                    case "i": kind = .silBoxImmutableField
                    default: throw failure
                    }
                    let type = try demangleType()
                    let field = SwiftSymbol(kind: kind, child: type)
                    layout.children.append(field)
                }
                var genericArgs: SwiftSymbol? = nil
                if signature != nil {
                    var ga = SwiftSymbol(kind: .typeList)
                    while !scanner.conditional(scalar: "_") {
                        let type = try demangleType()
                        ga.children.append(type)
                    }
                    genericArgs = ga
                }
                var boxType = SwiftSymbol(kind: .silBoxTypeWithLayout, child: layout)
                if let s = signature, let ga = genericArgs {
                    boxType.children.append(s)
                    boxType.children.append(ga)
                }
                return boxType
            case "P" where scanner.conditional(scalar: "M"): fallthrough
            case "M":
                let value: String
                switch try scanner.readScalar() {
                case "t": value = "@thick"
                case "T": value = "@thin"
                case "o": value = "@objc_metatype"
                default: throw scanner.unexpectedError()
                }
                type = SwiftSymbol(kind: c == "P" ? .existentialMetatype : .metatype, children: [SwiftSymbol(kind: .metatypeRepresentation, contents: .name(value)), try demangleSwift3Type()])
            case "P":
                var children = [SwiftSymbol]()
                while !scanner.conditional(scalar: "_") {
                    children.append(try demangleSwift3ProtocolName())
                }
                type = SwiftSymbol(kind: .protocolList, children: [SwiftSymbol(kind: .typeList)])
            case "f": type = try demangleSwift3FunctionType(kind: .thinFunctionType)
            case "o": type = SwiftSymbol(kind: .unowned, children: [try demangleSwift3Type()])
            case "u": type = SwiftSymbol(kind: .unmanaged, children: [try demangleSwift3Type()])
            case "w": type = SwiftSymbol(kind: .weak, children: [try demangleSwift3Type()])
            case "F":
                var children = [SwiftSymbol]()
                children.append(SwiftSymbol(kind: .implConvention, contents: .name(try demangleSwift3ImplConvention(kind: .implConvention))))
                if scanner.conditional(scalar: "C") {
                    let name: String
                    switch try scanner.readScalar() {
                    case "b": name = "@convention(block)"
                    case "c": name = "@convention(c)"
                    case "m": name = "@convention(method)"
                    case "O": name = "@convention(objc_method)"
                    case "w": name = "@convention(witness_method)"
                    default: throw scanner.unexpectedError()
                    }
                    children.append(SwiftSymbol(kind: .implFunctionAttribute, contents: .name(name)))
                }
                if scanner.conditional(scalar: "G") {
                    children.append(try demangleSwift3GenericSignature(isPseudo: false))
                } else if scanner.conditional(scalar: "g") {
                    children.append(try demangleSwift3GenericSignature(isPseudo: true))
                }
                try scanner.match(scalar: "_")
                while !scanner.conditional(scalar: "_") {
                    children.append(try demangleSwift3ImplParameterOrResult(kind: .implParameter))
                }
                while !scanner.conditional(scalar: "_") {
                    children.append(try demangleSwift3ImplParameterOrResult(kind: .implResult))
                }
                type = SwiftSymbol(kind: .implFunctionType, children: children)
            default: throw scanner.unexpectedError()
            }
        case "K": type = try demangleSwift3FunctionType(kind: .autoClosureType)
        case "M": type = SwiftSymbol(kind: .metatype, children: [try demangleSwift3Type()])
        case "P" where scanner.conditional(scalar: "M"): type = SwiftSymbol(kind: .existentialMetatype, children: [try demangleSwift3Type()])
        case "P":
            var children = [SwiftSymbol]()
            while !scanner.conditional(scalar: "_") {
                children.append(try demangleSwift3ProtocolName())
            }
            type = SwiftSymbol(kind: .protocolList, children: [SwiftSymbol(kind: .typeList, children: children)])
        case "Q": type = try demangleSwift3ArchetypeType()
        case "q":
            let c = try scanner.requirePeek()
            if c != "d" && c != "_" && c < "0" && c > "9" {
                type = try demangleSwift3DependentMemberTypeName(base: demangleSwift3Type())
            } else {
                type = try demangleSwift3GenericParamIndex()
            }
        case "x": type = SwiftSymbol(kind: .dependentGenericParamType, children: [SwiftSymbol(kind: .index, contents: .index(0)), SwiftSymbol(kind: .index, contents: .index(0))], contents: .name(archetypeName(0, 0)))
        case "w": type = try demangleSwift3AssociatedTypeSimple()
        case "W": type = try demangleSwift3AssociatedTypeCompound()
        case "R": type = SwiftSymbol(kind: .inOut, children: try demangleSwift3Type().children)
        case "S": type = try demangleSwift3SubstitutionIndex()
        case "T": type = try demangleSwift3Tuple(variadic: false)
        case "t": type = try demangleSwift3Tuple(variadic: true)
        case "u": type = SwiftSymbol(kind: .dependentGenericType, children: [try demangleSwift3GenericSignature(), try demangleSwift3Type()])
        case "C": type = try demangleSwift3DeclarationName(kind: .class)
        case "V": type = try demangleSwift3DeclarationName(kind: .structure)
        case "O": type = try demangleSwift3DeclarationName(kind: .enum)
        default: throw scanner.unexpectedError()
        }
        return SwiftSymbol(kind: .type, children: [type])
    }

    mutating func demangleSwift3ArchetypeType() throws -> SwiftSymbol {
        switch try scanner.readScalar() {
        case "Q":
            let result = SwiftSymbol(kind: .associatedTypeRef, children: [try demangleSwift3ArchetypeType(), try demangleSwift3Identifier()])
            nameStack.append(result)
            return result
        case "S":
            let index = try demangleSwift3SubstitutionIndex()
            let result = SwiftSymbol(kind: .associatedTypeRef, children: [index, try demangleSwift3Identifier()])
            nameStack.append(result)
            return result
        case "s":
            let root = SwiftSymbol(kind: .module, contents: .name(stdlibName))
            let result = SwiftSymbol(kind: .associatedTypeRef, children: [root, try demangleSwift3Identifier()])
            nameStack.append(result)
            return result
        case "q":
            let index = SwiftSymbol(kind: .index, contents: .index(try demangleSwift3Index()))
            let context = try demangleSwift3Context()
            let declContext = SwiftSymbol(kind: .declContext, children: [context])
            return SwiftSymbol(kind: .qualifiedArchetype, children: [index, declContext])
        default: throw scanner.unexpectedError()
        }
    }

    mutating func demangleSwift3ImplConvention(kind: SwiftSymbol.Kind) throws -> String {
        switch (try scanner.readScalar(), (kind == .implErrorResult ? .implResult : kind)) {
        case ("a", .implResult): return "@autoreleased"
        case ("d", .implConvention): return "@callee_unowned"
        case ("d", _): return "@unowned"
        case ("D", .implResult): return "@unowned_inner_pointer"
        case ("g", .implParameter): return "@guaranteed"
        case ("e", .implParameter): return "@deallocating"
        case ("g", .implConvention): return "@callee_guaranteed"
        case ("i", .implParameter): return "@in"
        case ("i", .implResult): return "@out"
        case ("l", .implParameter): return "@inout"
        case ("o", .implConvention): return "@callee_owned"
        case ("o", _): return "@owned"
        case ("t", .implConvention): return "@convention(thin)"
        default: throw scanner.unexpectedError()
        }
    }

    mutating func demangleSwift3ImplParameterOrResult(kind: SwiftSymbol.Kind) throws -> SwiftSymbol {
        var k: SwiftSymbol.Kind
        if scanner.conditional(scalar: "z") {
            if case .implResult = kind {
                k = .implErrorResult
            } else {
                throw scanner.unexpectedError()
            }
        } else {
            k = kind
        }

        let convention = try demangleSwift3ImplConvention(kind: k)
        let type = try demangleSwift3Type()
        let conventionNode = SwiftSymbol(kind: .implConvention, contents: .name(convention))
        return SwiftSymbol(kind: k, children: [conventionNode, type])
    }

    mutating func demangleSwift3Tuple(variadic: Bool) throws -> SwiftSymbol {
        var children = [SwiftSymbol]()
        while !scanner.conditional(scalar: "_") {
            var elementChildren = [SwiftSymbol]()
            let peek = try scanner.requirePeek()
            if (peek >= "0" && peek <= "9") || peek == "o" {
                elementChildren.append(try demangleSwift3Identifier(kind: .tupleElementName))
            }
            elementChildren.append(try demangleSwift3Type())
            children.append(SwiftSymbol(kind: .tupleElement, children: elementChildren))
        }
        if variadic, var last = children.popLast() {
            last.children.insert(SwiftSymbol(kind: .variadicMarker), at: 0)
            children.append(last)
        }
        return SwiftSymbol(kind: .tuple, children: children)
    }

    mutating func demangleSwift3FunctionType(kind: SwiftSymbol.Kind) throws -> SwiftSymbol {
        var children = [SwiftSymbol]()
        if scanner.conditional(scalar: "z") {
            children.append(SwiftSymbol(kind: .throwsAnnotation))
        }
        children.append(SwiftSymbol(kind: .argumentTuple, children: [try demangleSwift3Type()]))
        children.append(SwiftSymbol(kind: .returnType, children: [try demangleSwift3Type()]))
        return SwiftSymbol(kind: kind, children: children)
    }

    mutating func demangleSwift3Identifier(kind: SwiftSymbol.Kind? = nil) throws -> SwiftSymbol {
        let isPunycode = scanner.conditional(scalar: "X")
        let k: SwiftSymbol.Kind
        let isOperator: Bool
        if scanner.conditional(scalar: "o") {
            guard kind == nil else { throw scanner.unexpectedError() }
            switch try scanner.readScalar() {
            case "p": (isOperator, k) = (true, .prefixOperator)
            case "P": (isOperator, k) = (true, .postfixOperator)
            case "i": (isOperator, k) = (true, .infixOperator)
            default: throw scanner.unexpectedError()
            }
        } else {
            (isOperator, k) = (false, kind ?? SwiftSymbol.Kind.identifier)
        }

        var identifier = try scanner.readScalars(count: scanner.readInt())
        if isPunycode {
            identifier = decodeSwiftPunycode(identifier)
        }
        if isOperator {
            let source = identifier
            identifier = ""
            for scalar in source.unicodeScalars {
                switch scalar {
                case "a": identifier.unicodeScalars.append("&" as UnicodeScalar)
                case "c": identifier.unicodeScalars.append("@" as UnicodeScalar)
                case "d": identifier.unicodeScalars.append("/" as UnicodeScalar)
                case "e": identifier.unicodeScalars.append("=" as UnicodeScalar)
                case "g": identifier.unicodeScalars.append(">" as UnicodeScalar)
                case "l": identifier.unicodeScalars.append("<" as UnicodeScalar)
                case "m": identifier.unicodeScalars.append("*" as UnicodeScalar)
                case "n": identifier.unicodeScalars.append("!" as UnicodeScalar)
                case "o": identifier.unicodeScalars.append("|" as UnicodeScalar)
                case "p": identifier.unicodeScalars.append("+" as UnicodeScalar)
                case "q": identifier.unicodeScalars.append("?" as UnicodeScalar)
                case "r": identifier.unicodeScalars.append("%" as UnicodeScalar)
                case "s": identifier.unicodeScalars.append("-" as UnicodeScalar)
                case "t": identifier.unicodeScalars.append("~" as UnicodeScalar)
                case "x": identifier.unicodeScalars.append("^" as UnicodeScalar)
                case "z": identifier.unicodeScalars.append("." as UnicodeScalar)
                default:
                    if scalar.value >= 128 {
                        identifier.unicodeScalars.append(scalar)
                    } else {
                        throw scanner.unexpectedError()
                    }
                }
            }
        }

        return SwiftSymbol(kind: k, children: [], contents: .name(identifier))
    }
}

fileprivate func archetypeName(_ index: UInt32, _ depth: UInt32) -> String {
    var result = ""
    var i = index
    repeat {
        result.unicodeScalars.append(UnicodeScalar(("A" as UnicodeScalar).value + i % 26)!)
        i /= 26
    } while i > 0
    if depth != 0 {
        result += depth.description
    }
    return result
}

// MARK: Punycode.h

/// Rough adaptation of the pseudocode from 6.2 "Decoding procedure" in RFC3492
fileprivate func decodeSwiftPunycode(_ value: String) -> String {
    let input = value.unicodeScalars
    var output = [UnicodeScalar]()

    var pos = input.startIndex

    // Unlike RFC3492, Swift uses underscore for delimiting
    if let ipos = input.firstIndex(of: "_" as UnicodeScalar) {
        output.append(contentsOf: input[input.startIndex..<ipos].map { UnicodeScalar($0) })
        pos = input.index(ipos, offsetBy: 1)
    }

    // Magic numbers from RFC3492
    var n = 128
    var i = 0
    var bias = 72
    let symbolCount = 36
    let alphaCount = 26
    while pos != input.endIndex {
        let oldi = i
        var w = 1
        for k in stride(from: symbolCount, to: Int.max, by: symbolCount) {
            // Unlike RFC3492, Swift uses letters A-J for values 26-35
            let digit = input[pos] >= UnicodeScalar("a") ? Int(input[pos].value - UnicodeScalar("a").value) : Int((input[pos].value - UnicodeScalar("A").value) + UInt32(alphaCount))

            if pos != input.endIndex {
                pos = input.index(pos, offsetBy: 1)
            }

            i = i + (digit * w)
            let t = max(min(k - bias, alphaCount), 1)
            if (digit < t) {
                break
            }
            w = w * (symbolCount - t)
        }

        // Bias adaptation function
        var delta = (i - oldi) / ((oldi == 0) ? 700 : 2)
        delta = delta + delta / (output.count + 1)
        var k = 0
        while (delta > 455) {
            delta = delta / (symbolCount - 1)
            k = k + symbolCount
        }
        k += (symbolCount * delta) / (delta + symbolCount + 2)

        bias = k
        n = n + i / (output.count + 1)
        i = i % (output.count + 1)
        output.insert(UnicodeScalar(n)!, at: i)
        i += 1
    }
    return String(output.map { Character($0) })
}

// MARK: NodePrinter.cpp

fileprivate extension TextOutputStream {
    mutating func write<S: Sequence, T: Sequence>(sequence: S, labels: T, render: (inout Self, S.Iterator.Element) -> ()) where T.Iterator.Element == String? {
        var lg = labels.makeIterator()
        if let maybePrefix = lg.next(), let prefix = maybePrefix {
            write(prefix)
        }
        for e in sequence {
            render(&self, e)
            if let maybeLabel = lg.next(), let label = maybeLabel {
                write(label)
            }
        }
    }

    mutating func write<S: Sequence>(sequence: S, prefix: String? = nil, separator: String? = nil, suffix: String? = nil, render: (inout Self, S.Iterator.Element) -> ()) {
        if let p = prefix {
            write(p)
        }
        var first = true
        for e in sequence {
            if !first, let s = separator {
                write(s)
            }
            render(&self, e)
            first = false
        }
        if let s = suffix {
            write(s)
        }
    }

    mutating func write<T>(optional: Optional<T>, prefix: String? = nil, suffix: String? = nil, render: (inout Self, T) -> ()) {
        if let p = prefix {
            write(p)
        }
        if let e = optional {
            render(&self, e)
        }
        if let s = suffix {
            write(s)
        }
    }

    mutating func write<T>(value: T, prefix: String? = nil, suffix: String? = nil, render: (inout Self, T) -> ()) {
        if let p = prefix {
            write(p)
        }
        render(&self, value)
        if let s = suffix {
            write(s)
        }
    }
}

fileprivate extension SwiftSymbol.Kind {
    var isExistentialType: Bool {
        switch self {
        case .existentialMetatype, .protocolList, .protocolListWithClass, .protocolListWithAnyObject: return true
        default: return false
        }
    }

    var isSimpleType: Bool {
        switch self {
        case .associatedType: fallthrough
        case .associatedTypeRef: fallthrough
        case .boundGenericClass: fallthrough
        case .boundGenericEnum: fallthrough
        case .boundGenericStructure: fallthrough
        case .boundGenericOtherNominalType: fallthrough
        case .builtinTypeName: fallthrough
        case .class: fallthrough
        case .dependentGenericType: fallthrough
        case .dependentMemberType: fallthrough
        case .dependentGenericParamType: fallthrough
        case .dynamicSelf: fallthrough
        case .enum: fallthrough
        case .errorType: fallthrough
        case .existentialMetatype: fallthrough
        case .metatype: fallthrough
        case .metatypeRepresentation: fallthrough
        case .module: fallthrough
        case .tuple: fallthrough
        case .protocol: fallthrough
        case .qualifiedArchetype: fallthrough
        case .returnType: fallthrough
        case .silBoxType: fallthrough
        case .silBoxTypeWithLayout: fallthrough
        case .structure: fallthrough
        case .otherNominalType: fallthrough
        case .tupleElementName: fallthrough
        case .type: fallthrough
        case .typeAlias: fallthrough
        case .typeList: fallthrough
        case .labelList: fallthrough
        case .symbolicReference: fallthrough
        case .unresolvedSymbolicReference: return true
        default: return false
        }
    }
}

fileprivate extension SwiftSymbol {
    var needSpaceBeforeType: Bool {
        switch self.kind {
        case .type: return children.first?.needSpaceBeforeType ?? false
        case .functionType, .noEscapeFunctionType, .uncurriedFunctionType, .dependentGenericType: return false
        default: return true
        }
    }

    func isIdentifier(desired: String) -> Bool {
        return kind == .identifier && text == desired
    }

    var isSwiftModule: Bool {
        return kind == .module && text == stdlibName
    }
}

fileprivate enum SugarType {
    case none
    case optional
    case implicitlyUnwrappedOptional
    case array
    case dictionary
}

fileprivate enum TypePrinting {
    case noType
    case withColon
    case functionStyle
}

fileprivate struct SymbolPrinter {
    var target: String
    var specializationPrefixPrinted: Bool
    let options: SymbolPrintOptions

    init(options: SymbolPrintOptions = .default) {
        self.target = ""
        self.specializationPrefixPrinted = false
        self.options = options
    }

    mutating func printOptional(_ optional: SwiftSymbol?, prefix: String? = nil, suffix: String? = nil, asPrefixContext: Bool = false) -> SwiftSymbol? {
        guard let o = optional else { return nil }
        prefix.map { target.write($0) }
        let r = printName(o)
        suffix.map { target.write($0) }
        return r
    }

    mutating func printFirstChild(_ ofName: SwiftSymbol, prefix: String? = nil, suffix: String? = nil, asPrefixContext: Bool = false) {
        _ = printOptional(ofName.children.at(0), prefix: prefix, suffix: suffix)
    }

    mutating func printSequence<S>(_ names: S, prefix: String? = nil, suffix: String? = nil, separator: String? = nil) where S: Sequence, S.Element == SwiftSymbol {
        var isFirst = true
        prefix.map { target.write($0) }
        for c in names {
            if let s = separator, !isFirst {
                target.write(s)
            } else {
                isFirst = false
            }
            _ = printName(c)
        }
        suffix.map { target.write($0) }
    }

    mutating func printChildren(_ ofName: SwiftSymbol, prefix: String? = nil, suffix: String? = nil, separator: String? = nil) {
        printSequence(ofName.children, prefix: prefix, suffix: suffix, separator: separator)
    }

    mutating func printName(_ name: SwiftSymbol, asPrefixContext: Bool = false) -> SwiftSymbol? {
        switch name.kind {
        case .static: printFirstChild(name, prefix: "static ")
        case .curryThunk: printFirstChild(name, prefix: "curry thunk of ")
        case .dispatchThunk: printFirstChild(name, prefix: "dispatch thunk of ")
        case .outlinedBridgedMethod: target.write("outlined bridged method (\(name.text ?? "")) of ")
        case .outlinedCopy: printFirstChild(name, prefix: "outlined copy of ")
        case .outlinedConsume: printFirstChild(name, prefix: "outlined consume of ")
        case .outlinedRetain: printFirstChild(name, prefix: "outlined retain of ")
        case .outlinedRelease: printFirstChild(name, prefix: "outlined release of ")
        case .outlinedInitializeWithTake: printFirstChild(name, prefix: "outlined init with take of ")
        case .outlinedInitializeWithCopy: printFirstChild(name, prefix: "outlined init with copy of ")
        case .outlinedAssignWithTake: printFirstChild(name, prefix: "outlined assign with take of ")
        case .outlinedAssignWithCopy: name.children.at(0)?.index.map { target.write("outlined variable #\($0) of ") }
        case .outlinedDestroy: target.write("outlined destroy of ")
        case .outlinedVariable: target.write("outlined variable #\(name.index ?? 0) of ")
        case .directness: name.index.flatMap { Directness(rawValue: $0)?.description }.map { target.write("\($0) ") }
        case .anonymousContext:
            if options.contains(.qualifyEntities) && options.contains(.displayExtensionContexts) {
                _ = printOptional(name.children.at(1))
                target.write(".(unknown context at " + (name.children.first?.text ?? "") + ")")
                if let second = name.children.at(2), !second.children.isEmpty {
                    target.write("<")
                    _ = printName(second)
                    target.write(">")
                }
            }
        case .extension:
            if options.contains(.qualifyEntities) && options.contains(.displayExtensionContexts) {
                printFirstChild(name, prefix: "(extension in ", suffix: "):", asPrefixContext: true)
            }
            printSequence(name.children.slice(1, 3))
        case .variable: return printEntity(name, asPrefixContext: asPrefixContext, typePrinting: .withColon, hasName: true)
        case .function: return printEntity(name, asPrefixContext: asPrefixContext, typePrinting: .functionStyle, hasName: true)
        case .subscript: return printEntity(name, asPrefixContext: asPrefixContext, typePrinting: .functionStyle, hasName: true, overwriteName: "subscript")
        case .genericTypeParamDecl: return printEntity(name, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: true)
        case .explicitClosure: return printEntity(name, asPrefixContext: asPrefixContext, typePrinting: options.contains(.showFunctionArgumentTypes) ? .functionStyle : .noType, hasName: false, extraName: "closure #", extraIndex: (name.children.at(1)?.index ?? 0) + 1)
        case .implicitClosure: return printEntity(name, asPrefixContext: asPrefixContext, typePrinting: options.contains(.showFunctionArgumentTypes) ? .functionStyle : .noType, hasName: false, extraName: "implicit closure #", extraIndex: (name.children.at(1)?.index ?? 0) + 1)
        case .global: printChildren(name)
        case .suffix:
            if options.contains(.displayUnmangledSuffix) {
                target.write(" with unmangled suffix ")
                quotedString(name.text ?? "")
            }
        case .initializer: return printEntity(name, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: false, extraName: "variable initialization expression")
        case .defaultArgumentInitializer: return printEntity(name, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: false, extraName: "default argument \(name.children.at(1)?.index ?? 0)")
        case .declContext: printFirstChild(name)
        case .type: printFirstChild(name)
        case .typeMangling: printFirstChild(name)
        case .class: fallthrough
        case .structure: fallthrough
        case .enum: fallthrough
        case .protocol: fallthrough
        case .typeAlias: return printEntity(name, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: true)
        case .otherNominalType: return printEntity(name, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: true)
        case .localDeclName: _ = printOptional(name.children.at(1), suffix: " #\((name.children.at(0)?.index ?? 0) + 1)")
        case .privateDeclName:
            _ = printOptional(name.children.at(1), prefix: options.contains(.showPrivateDiscriminators) ? "(" : nil)
            target.write(options.contains(.showPrivateDiscriminators) ? "\(name.children.count > 1 ? " " : "(")in \(name.children.at(0)?.text ?? ""))" : "")
        case .relatedEntityDeclName: printFirstChild(name, prefix: "related decl '\(name.text ?? "")' for ")
        case .module:
            if options.contains(.displayModuleNames) {
                target.write(name.text ?? "")
            }
        case .identifier:
            target.write(name.text ?? "")
        case .index: target.write("\(name.index ?? 0)")
        case .noEscapeFunctionType: printFunctionType(name)
        case .escapingAutoClosureType:
            target.write("@autoclosure ")
            printFunctionType(name)
        case .autoClosureType:
            target.write("@autoclosure ")
            printFunctionType(name)
        case .thinFunctionType:
            target.write("@convention(thin) ")
            printFunctionType(name)
        case .functionType: fallthrough
        case .uncurriedFunctionType: printFunctionType(name)
        case .argumentTuple:
            printFunctionParameters(labelList: nil, parameterType: name, showTypes: options.contains(.showFunctionArgumentTypes))
        case .tuple: printChildren(name, prefix: "(", suffix: ")", separator: ", ")
        case .tupleElement:
            if let label = name.children.first(where: { $0.kind == .tupleElementName }) {
                target.write("\(label.text ?? ""): ")
            }
            guard let type = name.children.first(where: { $0.kind == .type }) else { break }
            _ = printName(type)
            if let _ = name.children.first(where: { $0.kind == .variadicMarker }) {
                target.write("...")
            }
        case .tupleElementName: target.write("\(name.text ?? ""): ")
        case .returnType:
            target.write(" -> ")
            if name.children.isEmpty, let t = name.text {
                target.write(t)
            } else {
                printChildren(name)
            }
        case .retroactiveConformance:
            if name.children.count == 2 {
                printChildren(name, prefix: "retroactive @ ")
            }
        case .weak: printFirstChild(name, prefix: "weak ")
        case .unowned: printFirstChild(name, prefix: "unowned ")
        case .unmanaged: printFirstChild(name, prefix: "unowned(unsafe) ")
        case .inOut: printFirstChild(name, prefix: "inout ")
        case .shared: printFirstChild(name, prefix: "__shared ")
        case .owned: printFirstChild(name, prefix: "__owned ")
        case .nonObjCAttribute: target.write("@nonobjc ")
        case .objCAttribute: target.write("@objc ")
        case .directMethodReferenceAttribute: target.write("super ")
        case .dynamicAttribute: target.write("dynamic ")
        case .vTableAttribute: target.write("override ")
        case .functionSignatureSpecialization: printSpecializationPrefix(name, description: "function signature specialization")
        case .genericPartialSpecialization: printSpecializationPrefix(name, description: "generic partial specialization", paramPrefix: "Signature = ")
        case .genericPartialSpecializationNotReAbstracted: printSpecializationPrefix(name, description: "generic not re-abstracted partial specialization", paramPrefix: "Signature = ")
        case .genericSpecialization: printSpecializationPrefix(name, description: "generic specialization")
        case .genericSpecializationNotReAbstracted: printSpecializationPrefix(name, description: "generic not re-abstracted specialization")
        case .specializationIsFragile: target.write("preserving fragile attribute")
        case .genericSpecializationParam:
            printFirstChild(name)
            _ = printOptional(name.children.at(1), prefix: " with ")
            name.children.slice(2, name.children.endIndex).forEach {
                target.write(" and ")
                _ = printName($0)
            }
        case .functionSignatureSpecializationParam:
            target.write("Arg[\(name.index ?? 0)] = ")
            var idx = printFunctionSigSpecializationParam(name, index: 0)
            while idx < name.children.count {
                target.write(" and ")
                idx = printFunctionSigSpecializationParam(name, index: idx)
            }
        case .functionSignatureSpecializationParamPayload:
            target.write((try? parseMangledSwiftSymbol(name.text ?? "").description) ?? (name.text ?? ""))
        case .functionSignatureSpecializationParamKind:
            let raw = name.index ?? 0
            switch FunctionSigSpecializationParamKind(rawValue: raw) {
            case .some(.boxToValue): target.write("Value Promoted from Box")
            case .some(.boxToStack): target.write("Stack Promoted from Box")
            case .some(.constantPropFunction): target.write("Constant Propagated Function")
            case .some(.constantPropGlobal): target.write("Constant Propagated Global")
            case .some(.constantPropInteger): target.write("Constant Propagated Integer")
            case .some(.constantPropFloat): target.write("Constant Propagated Float")
            case .some(.constantPropString): target.write("Constant Propagated String")
            case .some(.closureProp): target.write("Closure Propagated")
            default:
                if raw & FunctionSigSpecializationParamKind.dead.rawValue != 0 {
                    target.write("Dead")
                }
                if raw & FunctionSigSpecializationParamKind.ownedToGuaranteed.rawValue != 0 {
                    if raw & FunctionSigSpecializationParamKind.dead.rawValue != 0 {
                        target.write(" and ")
                    }
                    target.write("Owned To Guaranteed")
                }
                if raw & FunctionSigSpecializationParamKind.sroa.rawValue != 0 {
                    if raw & (FunctionSigSpecializationParamKind.ownedToGuaranteed.rawValue | FunctionSigSpecializationParamKind.dead.rawValue) != 0 {
                        target.write(" and ")
                    }
                    target.write("Exploded")
                }
            }
        case .specializationPassID: target.write("\(name.index ?? 0)")
        case .builtinTypeName: target.write(name.text ?? "")
        case .number: target.write("\(name.index ?? 0)")
        case .infixOperator: target.write("\(name.text ?? "") infix")
        case .prefixOperator: target.write("\(name.text ?? "") prefix")
        case .postfixOperator: target.write("\(name.text ?? "") postfix")
        case .lazyProtocolWitnessTableAccessor:
            _ = printOptional(name.children.at(0), prefix: "lazy protocol witness table accessor for type ")
            _ = printOptional(name.children.at(1), prefix: " and conformance ")
        case .lazyProtocolWitnessTableCacheVariable:
            _ = printOptional(name.children.at(0), prefix: "lazy protocol witness table cache variable for type ")
            _ = printOptional(name.children.at(1), prefix: " and conformance ")
        case .protocolWitnessTableAccessor: printFirstChild(name, prefix: "protocol witness table accessor for ")
        case .protocolWitnessTable: printFirstChild(name, prefix: "protocol witness table for ")
        case .protocolWitnessTablePattern: printFirstChild(name, prefix: "protocol witness table pattern for ")
        case .genericProtocolWitnessTable: printFirstChild(name, prefix: "generic protocol witness table for ")
        case .genericProtocolWitnessTableInstantiationFunction: printFirstChild(name, prefix: "instantiation function for generic protocol witness table for ")
        case .resilientProtocolWitnessTable:
            target.write("resilient protocol witness table for ")
            printFirstChild(name)
        case .vTableThunk:
            _ = printOptional(name.children.at(1), prefix: "vtable thunk for ")
            _ = printOptional(name.children.at(0), prefix: " dispatching to ")
        case .protocolWitness:
            _ = printOptional(name.children.at(1), prefix: "protocol witness for ")
            _ = printOptional(name.children.at(0), prefix: " in conformance ")
        case .partialApplyForwarder:
            target.write("partial apply\(options.contains(.shortenPartialApply) ? "" : " forwarder")")
            printFirstChild(name, prefix: " for ")
        case .partialApplyObjCForwarder:
            target.write("partial apply\(options.contains(.shortenPartialApply) ? "" : " ObjC forwarder")")
            printFirstChild(name, prefix: " for ")
        case .keyPathGetterThunkHelper:
            printFirstChild(name, prefix: "key path getter for ", suffix: " : ")
            _ = printOptional(name.children.at(1))
            _ = printOptional(name.children.at(2))
        case .keyPathSetterThunkHelper:
            printFirstChild(name, prefix: "key path setter for ", suffix: " : ")
            _ = printOptional(name.children.at(1))
            _ = printOptional(name.children.at(2))
        case .keyPathEqualsThunkHelper: fallthrough
        case .keyPathHashThunkHelper:
            target.write("key path index \(name.kind == .keyPathEqualsThunkHelper ? "equality" : "hash") operator for ")
            var dropLast = false
            if let lastChild = name.children.last, lastChild.kind == .dependentGenericSignature {
                _ = printName(lastChild)
                dropLast = true
            }
            printSequence(dropLast ? Array(name.children.dropLast()) : name.children, prefix: "(", suffix: ")", separator: ", ")
        case .fieldOffset:
            printFirstChild(name)
            _ = printOptional(name.children.at(1), prefix: "field offset for ", asPrefixContext: true)
        case .enumCase:
            target.write("enum case for ")
            printFirstChild(name, asPrefixContext: false)
        case .reabstractionThunk: fallthrough
        case .reabstractionThunkHelper:
            if options.contains(.shortenThunk) {
                _ = printOptional(name.children.at(name.children.count - 2), prefix: "thunk for ")
                break
            }
            target.write("reabstraction thunk ")
            target.write(name.kind == .reabstractionThunkHelper ? "helper " : "")
            _ = printOptional(name.children.first { $0.kind == .dependentGenericSignature }, suffix: " ")
            _ = printOptional(name.children.at(name.children.count - 2), prefix: "from ")
            _ = printOptional(name.children.at(name.children.count - 1), prefix: " to ")
        case .mergedFunction: target.write(!options.contains(.shortenThunk) ? "merged " : "")
        case .symbolicReference: target.write("symbolic reference \(name.index ?? 0)")
        case .unresolvedSymbolicReference: target.write("$\(name.index ?? 0)")
        case .genericTypeMetadataPattern: printFirstChild(name, prefix: "generic type metadata pattern for ")
        case .metaclass: printFirstChild(name, prefix: "metaclass for ")
        case .protocolConformanceDescriptor: printFirstChild(name, prefix: "protocol conformance descriptor for ")
        case .protocolDescriptor: printFirstChild(name, prefix: "protocol descriptor for ")
        case .protocolRequirementArray: printFirstChild(name, prefix: "protocol requirement array for ")
        case .fullTypeMetadata: printFirstChild(name, prefix: "full type metadata for ")
        case .typeMetadata: printFirstChild(name, prefix: "type metadata for ")
        case .typeMetadataAccessFunction: printFirstChild(name, prefix: "type metadata accessor for ")
        case .typeMetadataInstantiationCache: printFirstChild(name, prefix: "type metadata instantiation cache for ")
        case .typeMetadataInstantiationFunction: printFirstChild(name, prefix: "type metadata instantiation cache for ")
        case .typeMetadataCompletionFunction: printFirstChild(name, prefix: "type metadata completion function for ")
        case .typeMetadataLazyCache: printFirstChild(name, prefix: "lazy cache variable for type metadata for ")
        case .associatedTypeMetadataAccessor:
            _ = printOptional(name.children.at(1), prefix: "associated type metadata accessor for ")
            _ = printOptional(name.children.at(0), prefix: " in ")
        case .associatedTypeWitnessTableAccessor:
            _ = printOptional(name.children.at(1), prefix: "associated type witness table accessor for ")
            _ = printOptional(name.children.at(2), prefix: " : ")
            _ = printOptional(name.children.at(0), prefix: " in ")
        case .classMetadataBaseOffset: printFirstChild(name, prefix: "class metadata base offset for ")
        case .propertyDescriptor: printFirstChild(name, prefix: "property descriptor for ")
        case .nominalTypeDescriptor: printFirstChild(name, prefix: "nominal type descriptor for ")
        case .coroutineContinuationPrototype: printFirstChild(name, prefix: "coroutine continuation prototype for ")
        case .valueWitness:
            target.write(ValueWitnessKind(rawValue: name.index ?? 0)?.description ?? "")
            target.write(options.contains(.shortenValueWitness) ? " for " : " value witness for ")
            printFirstChild(name)
        case .valueWitnessTable:
            printFirstChild(name, prefix: "value witness table for ")
        case .boundGenericClass: fallthrough
        case .boundGenericStructure: fallthrough
        case .boundGenericEnum: fallthrough
        case .boundGenericOtherNominalType: printBoundGeneric(name)
        case .dynamicSelf: target.write("Self")
        case .cFunctionPointer:
            target.write("@convention(c) ")
            printFunctionType(name)
        case .objCBlock:
            target.write("@convention(block) ")
            printFunctionType(name)
        case .silBoxType:
            target.write("@box ")
            printFirstChild(name)
        case .metatype:
            if name.children.count == 2 {
                printFirstChild(name, suffix: " ")
            }
            guard let type = name.children.at(name.children.count == 2 ? 1 : 0)?.children.first else { return nil }
            let needParens = !type.kind.isSimpleType
            target.write(needParens ? "(" : "")
            _ = printName(type)
            target.write(needParens ? ")" : "")
            target.write(type.kind.isExistentialType ? ".Protocol" : ".Type")
        case .existentialMetatype:
            if name.children.count == 2 {
                printFirstChild(name, suffix: " ")
            }
            _ = printOptional(name.children.at(name.children.count == 2 ? 1 : 0), suffix: ".Type")
        case .metatypeRepresentation: target.write(name.text ?? "")
        case .associatedTypeRef:
            printFirstChild(name)
            target.write(".\(name.children.at(1)?.text ?? "")")
        case .protocolList:
            guard let typeList = name.children.first else { return nil }
            if typeList.children.isEmpty {
                target.write("Any")
            } else {
                printChildren(typeList, separator: " & ")
            }
        case .protocolListWithClass:
            guard name.children.count >= 2 else { return nil }
            _ = printOptional(name.children.at(1), suffix: " & ")
            if let protocolsTypeList = name.children.first?.children.first {
                printChildren(protocolsTypeList, separator: " & ")
            }
        case .protocolListWithAnyObject:
            guard let prot = name.children.first, let protocolsTypeList = prot.children.first else { return nil }
            if protocolsTypeList.children.count > 0 {
                printChildren(protocolsTypeList, suffix: " & ", separator: " & ")
            }
            if options.contains(.qualifyEntities) {
                target.write("Swift.")
            }
            target.write("AnyObject")
        case .associatedType: return nil
        case .qualifiedArchetype:
            if options.contains(.shortenArchetype) {
                target.write("(archetype)")
                return nil
            }
            if name.children.count < 2 {
                return nil
            }
            target.write("(archetype \(name.children.first?.index ?? 0) of ")
            _ = printOptional(name.children.at(1), suffix: ")")
        case .owningAddressor: return printAbstractStorage(name.children.first, asPrefixContext: asPrefixContext, extraName: "owningAddressor")
        case .owningMutableAddressor: return printAbstractStorage(name.children.first, asPrefixContext: asPrefixContext, extraName: "owningMutableAddressor")
        case .nativeOwningAddressor: return printAbstractStorage(name.children.first, asPrefixContext: asPrefixContext, extraName: "nativeOwningAddressor")
        case .nativeOwningMutableAddressor: return printAbstractStorage(name.children.first, asPrefixContext: asPrefixContext, extraName: "nativeOwningMutableAddressor")
        case .nativePinningAddressor: return printAbstractStorage(name.children.first, asPrefixContext: asPrefixContext, extraName: "nativePinningAddressor")
        case .nativePinningMutableAddressor: return printAbstractStorage(name.children.first, asPrefixContext: asPrefixContext, extraName: "nativePinningMutableAddressor")
        case .unsafeAddressor: return printAbstractStorage(name.children.first, asPrefixContext: asPrefixContext, extraName: "unsafeAddressor")
        case .unsafeMutableAddressor: return printAbstractStorage(name.children.first, asPrefixContext: asPrefixContext, extraName: "unsafeMutableAddressor")
        case .globalGetter: return printAbstractStorage(name.children.first, asPrefixContext: asPrefixContext, extraName: "getter")
        case .getter: return printAbstractStorage(name.children.first, asPrefixContext: asPrefixContext, extraName: "getter")
        case .setter: return printAbstractStorage(name.children.first, asPrefixContext: asPrefixContext, extraName: "setter")
        case .materializeForSet: return printAbstractStorage(name.children.first, asPrefixContext: asPrefixContext, extraName: "materializeForSet")
        case .willSet: return printAbstractStorage(name.children.first, asPrefixContext: asPrefixContext, extraName: "willset")
        case .didSet: return printAbstractStorage(name.children.first, asPrefixContext: asPrefixContext, extraName: "didset")
        case .allocator:
            return printEntity(name, asPrefixContext: asPrefixContext, typePrinting: .functionStyle, hasName: false, extraName: (name.children.first?.kind == .class) ? "__allocating_init" : "init")
        case .constructor:
            return printEntity(name, asPrefixContext: asPrefixContext, typePrinting: .functionStyle, hasName: name.children.count > 2, extraName: "init")
        case .destructor:
            return printEntity(name, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: false, extraName: "deinit")
        case .deallocator:
            return printEntity(name, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: false, extraName: (name.children.first?.kind == .class) ? "__deallocating_deinit" : "deinit")
        case .iVarInitializer:
            return printEntity(name, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: false, extraName: "__ivar_initializer")
        case .iVarDestroyer:
            return printEntity(name, asPrefixContext: asPrefixContext, typePrinting: .noType, hasName: false, extraName: "__ivar_destroyer")
        case .protocolConformance:
            if name.children.count == 4 {
                _ = printOptional(name.children.at(2), prefix: "property behavior storage of ")
                _ = printOptional(name.children.at(0), prefix: " in ")
                _ = printOptional(name.children.at(1), prefix: " : ")
            } else {
                printFirstChild(name)
                if options.contains(.displayProtocolConformances) {
                    _ = printOptional(name.children.at(1), prefix: " : ")
                    _ = printOptional(name.children.at(2), prefix: " in ")
                }
            }
        case .typeList: printChildren(name)
        case .labelList: break
        case .implEscaping: target.write("@escaping")
        case .implConvention: target.write(name.text ?? "")
        case .implFunctionAttribute: target.write(name.text ?? "")
        case .implErrorResult:
            target.write("@error ")
            fallthrough
        case .implParameter: fallthrough
        case .implResult:
            printChildren(name, separator: " ")
        case .implFunctionType: printImplFunctionType(name)
        case .errorType: target.write("<ERROR TYPE>")
        case .dependentPseudogenericSignature: fallthrough
        case .dependentGenericSignature:
            target.write("<")
            var lastDepth = 0
            for (depth, c) in name.children.enumerated() {
                guard c.kind == .dependentGenericParamCount else { break }
                lastDepth = depth
                target.write(depth == 0 ? "" : "><")

                let count = name.children.at(depth)?.index ?? 0
                for index in 0..<count {
                    target.write(index != 0 ? ", " : "")
                    target.write(archetypeName(UInt32(index), UInt32(depth)))
                }
            }

            if lastDepth != name.children.count - 1 {
                if options.contains(.displayWhereClauses) {
                    printSequence(name.children.slice(lastDepth + 1, name.children.endIndex), prefix: " where ", separator: ", ")
                }
            }
            target.write(">")
        case .dependentGenericParamCount: return nil
        case .dependentGenericConformanceRequirement:
            printFirstChild(name)
            _ = printOptional(name.children.at(1), prefix: ": ")
        case .dependentGenericLayoutRequirement:
            guard let layout = name.children.at(1), let c = layout.text?.unicodeScalars.first else { return nil }
            printFirstChild(name, suffix: ": ")
            switch c {
            case "U": target.write("_UnknownLayout")
            case "R": target.write("_RefCountedObject")
            case "N": target.write("_NativeRefCountedObject")
            case "C": target.write("AnyObject")
            case "D": target.write("_NativeClass")
            case "T": target.write("_Trivial")
            case "E", "e": target.write("_Trivial")
            case "M", "m": target.write("_TrivialAtMost")
            default: break
            }
            if name.children.count > 2 {
                _ = printOptional(name.children.at(2), prefix: "(")
                _ = printOptional(name.children.at(3), prefix: ", ")
                target.write(")")
            }
        case .dependentGenericSameTypeRequirement:
            printFirstChild(name)
            _ = printOptional(name.children.at(1), prefix: " == ")
        case .dependentGenericParamType: target.write(name.text ?? "")
        case .dependentGenericType:
            guard let depType = name.children.at(1) else { return nil }
            printFirstChild(name)
            _ = printOptional(depType, prefix: depType.needSpaceBeforeType ? " " : "")
        case .dependentMemberType:
            printFirstChild(name)
            target.write(".")
            _ = printOptional(name.children.at(1))
        case .dependentAssociatedTypeRef: target.write(name.text ?? "")
        case .reflectionMetadataBuiltinDescriptor: printFirstChild(name, prefix: "reflection metadata builtin descriptor ")
        case .reflectionMetadataFieldDescriptor: printFirstChild(name, prefix: "reflection metadata field descriptor ")
        case .reflectionMetadataAssocTypeDescriptor: printFirstChild(name, prefix: "reflection metadata associated type descriptor ")
        case .reflectionMetadataSuperclassDescriptor: printFirstChild(name, prefix: "reflection metadata superclass descriptor ")
        case .throwsAnnotation: target.write(" throws ")
        case .emptyList: target.write(" empty-list ")
        case .firstElementMarker: target.write(" first-element-marker ")
        case .variadicMarker: target.write(" variadic-marker ")
        case .silBoxTypeWithLayout:
            guard let layout = name.children.first else { return nil }
            _ = printOptional(name.children.at(1), suffix: " ")
            _ = printName(layout)
            if let genericArgs = name.children.at(2) {
                printSequence(genericArgs.children, prefix: " <", suffix: ">", separator: ", ")
            }
        case .silBoxLayout: printSequence(name.children, prefix: "{\(name.children.isEmpty ? "" : " ")", suffix: " }", separator: ", ")
        case .silBoxImmutableField: fallthrough
        case .silBoxMutableField: printFirstChild(name, prefix: name.kind == .silBoxImmutableField ? "let " : "var ")
        case .assocTypePath: printChildren(name, separator: ".")
        case .moduleDescriptor: printFirstChild(name, prefix: "module descriptor ")
        case .anonymousDescriptor: printFirstChild(name, prefix: "anonymous descriptor ")
        case .extensionDescriptor: printFirstChild(name, prefix: "extension descriptor ")
        case .associatedTypeGenericParamRef: printChildren(name, prefix: "generic parameter reference for associated type ")
        }

        return nil
    }

    mutating func printAbstractStorage(_ name: SwiftSymbol?, asPrefixContext: Bool, extraName: String) -> SwiftSymbol? {
        guard let n = name else { return nil }
        switch n.kind {
        case .variable: return printEntity(n, asPrefixContext: asPrefixContext, typePrinting: .withColon, hasName: true, extraName: extraName)
        case .subscript: return printEntity(n, asPrefixContext: asPrefixContext, typePrinting: .withColon, hasName: false, extraName: extraName, extraIndex: nil, overwriteName: "subscript")
        default: return nil
        }
    }

    mutating func printEntityType(name: SwiftSymbol, type: SwiftSymbol) {
        if let labelList = name.children.first(where: { $0.kind == .labelList }) {
            var t = type
            if type.kind == .dependentGenericType {
                _ = printOptional(type.children.first)
                if let dt = type.children.at(1) {
                    if dt.needSpaceBeforeType {
                        target.write(" ")
                    }
                    t = dt
                }
            }
            printFunctionType(labelList: labelList, t)
        } else {
            _ = printName(type)
        }
    }

    mutating func printEntity(_ name: SwiftSymbol, asPrefixContext: Bool, typePrinting: TypePrinting, hasName: Bool, extraName: String? = nil, extraIndex: UInt32? = nil, overwriteName: String? = nil) -> SwiftSymbol? {
        let multiWordName = extraName?.contains(" ") == true || (hasName && name.children.at(1)?.kind == .localDeclName)
        if asPrefixContext && (typePrinting != .noType || multiWordName) {
            return name
        }

        guard let context = name.children.first else { return nil }
        var postfixContext: SwiftSymbol? = nil
        if shouldPrintContext(context) {
            if multiWordName {
                postfixContext = context
            } else {
                let currentPos = target.count
                postfixContext = printName(context, asPrefixContext: true)
                if target.count != currentPos {
                    target.write(".")
                }
            }
        }

        var extraNameConsumed = extraName == nil
        if hasName || overwriteName != nil {
            if !extraNameConsumed && multiWordName {
                target.write("\(extraName ?? "") of ")
                extraNameConsumed = true
            }
            let currentPos = target.count
            if let o = overwriteName {
                target.write(o)
            } else {
                if let one = name.children.at(1) {
                    if one.kind != .privateDeclName {
                        _ = printName(one)
                    }
                    if let pdn = name.children.first(where: { $0.kind == .privateDeclName }) {
                        _ = printName(pdn)
                    }
                }
            }
            if target.count != currentPos && !extraNameConsumed {
                target.write(".")
            }
        }
        if !extraNameConsumed {
            target.write(extraName ?? "")
            if let ei = extraIndex {
                target.write("\(ei)")
            }
        }
        if typePrinting != .noType {
            guard var type = name.children.first(where: { $0.kind == .type }) else { return nil }
            if type.kind != .type {
                guard let nextType = name.children.at(2) else { return nil }
                type = nextType
            }
            guard type.kind == .type, let firstChild = type.children.first else { return nil }
            type = firstChild
            var typePr = typePrinting
            if typePr == .functionStyle {
                var t = type
                while t.kind == .dependentGenericType, let next = t.children.at(1)?.children.at(0) {
                    t = next
                }
                switch t.kind {
                case .functionType, .uncurriedFunctionType, .cFunctionPointer, .thinFunctionType: break
                default: typePr = .withColon
                }
            }
            if typePr == .withColon {
                if options.contains(.displayEntityTypes) {
                    target.write(" : ")
                    printEntityType(name: name, type: type)
                }
            } else {
                if multiWordName || type.needSpaceBeforeType {
                    target.write(" ")
                }
                printEntityType(name: name, type: type)
            }
        }
        if !asPrefixContext, let pfc = postfixContext {
            if name.kind == .defaultArgumentInitializer || name.kind == .initializer {
                target.write(" of ")
            } else {
                target.write(" in ")
            }
            _ = printName(pfc)
            return nil
        }
        return postfixContext
    }

    func shouldPrintContext(_ name: SwiftSymbol) -> Bool {
        if !options.contains(.qualifyEntities) {
            return false
        }

        if name.kind == .module && name.text?.starts(with: lldbExpressionsModuleNamePrefix) == true {
            return options.contains(.displayDebuggerGeneratedModule)
        }

        return true
    }

    mutating func printFunctionSigSpecializationParam(_ name: SwiftSymbol, index: Int) -> Int {
        guard let firstChild = name.children.at(index), let v = firstChild.index else { return index + 1 }
        switch v {
        case FunctionSigSpecializationParamKind.boxToValue.rawValue, FunctionSigSpecializationParamKind.boxToStack.rawValue:
            _ = printOptional(name.children.at(index))
            return index + 1
        case FunctionSigSpecializationParamKind.constantPropFunction.rawValue: fallthrough
        case FunctionSigSpecializationParamKind.constantPropGlobal.rawValue:
            target.write("[")
            _ = printOptional(name.children.at(index))
            target.write(" : ")
            guard let t = name.children.at(index + 1)?.text else { return index + 1 }
            let demangedName = (try? parseMangledSwiftSymbol(t))?.description ?? ""
            if demangedName.isEmpty {
                target.write(t)
            } else {
                target.write(demangedName)
            }
            target.write("]")
            return index + 2
        case FunctionSigSpecializationParamKind.constantPropInteger.rawValue: fallthrough
        case FunctionSigSpecializationParamKind.constantPropFloat.rawValue:
            target.write("[")
            _ = printOptional(name.children.at(index))
            target.write(" : ")
            _ = printOptional(name.children.at(index + 1))
            target.write("]")
            return index + 2
        case FunctionSigSpecializationParamKind.constantPropString.rawValue:
            target.write("[")
            _ = printOptional(name.children.at(index))
            target.write(" : ")
            _ = printOptional(name.children.at(index + 1))
            target.write("'")
            _ = printOptional(name.children.at(index + 2))
            target.write("'")
            target.write("]")
            return index + 3
        case FunctionSigSpecializationParamKind.closureProp.rawValue:
            target.write("[")
            _ = printOptional(name.children.at(index))
            target.write(" : ")
            _ = printOptional(name.children.at(index + 1))
            target.write(", Argument Types : [")
            var idx = index + 2
            while idx < name.children.count, let c = name.children.at(idx), c.kind == .type {
                _ = printName(c)
                idx += 1
                if idx < name.children.count && name.children.at(idx)?.text != nil {
                    target.write(", ")
                }
            }
            target.write("]")
            return idx
        default:
            _ = printOptional(name.children.at(index))
            return index + 1
        }
    }

    mutating func printSpecializationPrefix(_ name: SwiftSymbol, description: String, paramPrefix: String = "") {
        if !options.contains(.displayGenericSpecializations) {
            if !specializationPrefixPrinted {
                target.write("specialized ")
                specializationPrefixPrinted = true
            }
            return
        }
        target.write("\(description) <")
        var separator = ""
        for c in name.children {
            switch c.kind {
            case .specializationPassID: break
            case .specializationIsFragile:
                target.write(separator)
                separator = ", "
                _ = printName(c)
            default:
                if !c.children.isEmpty {
                    target.write(separator)
                    target.write(paramPrefix)
                    separator = ", "
                    _ = printName(c)
                }
            }
        }
        target.write("> of ")
    }

    mutating func printFunctionParameters(labelList: SwiftSymbol?, parameterType: SwiftSymbol, showTypes: Bool) {
        guard parameterType.kind == .argumentTuple else { return }
        guard let t = parameterType.children.first, t.kind == .type else { return }
        guard let parameters = t.children.first else { return }

        if parameters.kind != .tuple {
            if showTypes {
                target.write("(")
                _ = printName(parameters)
                target.write(")")
            } else {
                target.write("(_:)")
            }
            return
        }

        target.write("(")
        for tuple in parameters.children.enumerated() {
            if let label = labelList?.children.at(tuple.offset) {
                target.write("\(label.kind == .identifier ? (label.text ?? "") : "_"):")
                if showTypes {
                    target.write(" ")
                }
            } else if !showTypes {
                if let label = tuple.element.children.first(where: { $0.kind == .tupleElementName }) {
                    target.write("\(label.text ?? ""):")
                } else {
                    target.write("_:")
                }
            }

            if showTypes {
                _ = printName(tuple.element)
                if tuple.offset != parameters.children.count - 1 {
                    target.write(", ")
                }
            }
        }
        target.write(")")
    }

    mutating func printFunctionType(labelList: SwiftSymbol? = nil, _ name: SwiftSymbol) {
        let startIndex = name.children.first?.kind == .throwsAnnotation ? 1 : 0
        guard let parameterType = name.children.at(startIndex) else { return }
        printFunctionParameters(labelList: labelList, parameterType: parameterType, showTypes: options.contains(.showFunctionArgumentTypes))
        if !options.contains(.showFunctionArgumentTypes) {
            return
        }
        if startIndex == 1 {
            target.write(" throws")
        }
        _ = printOptional(name.children.at(startIndex + 1))
    }

    mutating func printBoundGenericNoSugar(_ name: SwiftSymbol) {
        guard let typeList = name.children.at(1) else { return }
        printFirstChild(name)
        printChildren(typeList, prefix: "<", suffix: ">", separator: ", ")
    }

    func findSugar(_ name: SwiftSymbol) -> SugarType {
        guard let firstChild = name.children.at(0) else { return .none }
        if name.children.count == 1, firstChild.kind == .type { return findSugar(firstChild) }

        guard name.kind == .boundGenericEnum || name.kind == .boundGenericStructure else { return .none }
        guard let secondChild = name.children.at(1) else { return .none }
        guard name.children.count == 2 else { return .none }

        guard let unboundType = firstChild.children.first, unboundType.children.count > 1 else { return .none }
        let typeArgs = secondChild

        let c0 = unboundType.children.at(0)
        let c1 = unboundType.children.at(1)

        if name.kind == .boundGenericEnum {
            if c1?.isIdentifier(desired: "Optional") == true && typeArgs.children.count == 1 && c0?.isSwiftModule == true {
                return .optional
            }
            if c1?.isIdentifier(desired: "ImplicitlyUnwrappedOptional") == true && typeArgs.children.count == 1 && c0?.isSwiftModule == true {
                return .implicitlyUnwrappedOptional
            }
            return .none
        }
        if c1?.isIdentifier(desired: "Array") == true && typeArgs.children.count == 1 && c0?.isSwiftModule == true {
            return .array
        }
        if c1?.isIdentifier(desired: "Dictionary") == true && typeArgs.children.count == 2 && c0?.isSwiftModule == true {
            return .dictionary
        }
        return .none
    }

    mutating func printBoundGeneric(_ name: SwiftSymbol) {
        guard name.children.count >= 2 else { return }
        guard name.children.count == 2, options.contains(.synthesizeSugarOnTypes), name.kind != .boundGenericClass else {
            printBoundGenericNoSugar(name)
            return
        }

        let sugarType = findSugar(name)
        switch sugarType {
        case .optional, .implicitlyUnwrappedOptional:
            if let type = name.children.at(1)?.children.at(0) {
                let needParens = !type.kind.isSimpleType
                _ = printOptional(type, prefix: needParens ? "(" : "", suffix: needParens ? ")" : "")
                target.write(sugarType == .optional ? "?" : "!")
            }
        case .array, .dictionary:
            _ = printOptional(name.children.at(1)?.children.at(0), prefix: "[")
            if sugarType == .dictionary {
                _ = printOptional(name.children.at(1)?.children.at(1), prefix: " : ")
            }
            target.write("]")
        default: printBoundGenericNoSugar(name)
        }
    }

    mutating func printImplFunctionType(_ name: SwiftSymbol) {
        enum State {
            case attrs, inputs, results
        }

        var curState: State = .attrs
        childLoop: for c in name.children {
            if c.kind == .implParameter {
                switch curState {
                case .inputs: target.write(", ")
                case .attrs: target.write("(")
                case .results: break childLoop
                }
                curState = .inputs
                _ = printName(c)
            } else if c.kind == .implResult || c.kind == .implErrorResult {
                switch curState {
                case .inputs: target.write(") -> (")
                case .attrs: target.write("() -> (")
                case .results: target.write(", ")
                }
                curState = .results
                _ = printName(c)
            } else {
                _ = printName(c)
                target.write(" ")
            }
        }
        switch curState {
        case .inputs: target.write(") -> ()")
        case .attrs: target.write("() -> ()")
        case .results: target.write(")")
        }
    }

    mutating func quotedString(_ value: String) {
        target.write("\"")
        for c in value.unicodeScalars {
            switch c {
            case "\\": target.write("\\\\")
            case "\t": target.write("\\t")
            case "\n": target.write("\\n")
            case "\r": target.write("\\r")
            case "\"": target.write("\\\"")
            case "\0": target.write("\\0")
            default:
                if c < UnicodeScalar(0x20) || c == UnicodeScalar(0x7f) {
                    target.write("\\x")
                    target.write(String(describing: ((c.value >> 4) > 9) ? UnicodeScalar(c.value + UnicodeScalar("A").value) : UnicodeScalar(c.value + UnicodeScalar("0").value)))
                } else {
                    target.write(String(c))
                }
            }
        }
        target.write("\"")
    }
}

// MARK: ScalarScanner.swift

/// A type for representing the different possible failure conditions when using ScalarScanner
internal enum SwiftSymbolParseError: Error {
    /// Attempted to convert the buffer to UnicodeScalars but the buffer contained invalid data
    case utf8ParseError

    /// The scalar at the specified index doesn't match the expected grammar
    case unexpected(at: Int)

    /// Expected `wanted` at offset `at`
    case matchFailed(wanted: String, at: Int)

    /// Expected numerals at offset `at`
    case expectedInt(at: Int)

    /// Attempted to read `count` scalars from position `at` but hit the end of the sequence
    case endedPrematurely(count: Int, at: Int)

    /// Unable to find search patter `wanted` at or after `after` in the sequence
    case searchFailed(wanted: String, after: Int)
}

/// NOTE: This extension is fileprivate to avoid clashing with CwlUtils (from which it is taken). If you want to use these functions outside this file, consider including CwlUtils.
fileprivate extension UnicodeScalar {
    /// Tests if the scalar is within a range
    func isInRange(_ range: ClosedRange<UnicodeScalar>) -> Bool {
        return range.contains(self)
    }

    /// Tests if the scalar is a plain ASCII digit
    var isDigit: Bool {
        return ("0"..."9").contains(self)
    }

    /// Tests if the scalar is a plain ASCII English alphabet lowercase letter
    var isLower: Bool {
        return ("a"..."z").contains(self)
    }

    /// Tests if the scalar is a plain ASCII English alphabet uppercase letter
    var isUpper: Bool {
        return ("A"..."Z").contains(self)
    }

    /// Tests if the scalar is a plain ASCII English alphabet letter
    var isLetter: Bool {
        return isLower || isUpper
    }
}

/// NOTE: This struct is fileprivate to avoid clashing with CwlUtils (from which it is taken). If you want to use this struct outside this file, consider including CwlUtils.
///
/// A structure for traversing a `String.UnicodeScalarView`.
///
/// **UNICODE WARNING**: this struct ignores all Unicode combining rules and parses each scalar individually. The rules for parsing must allow combined characters to be parsed separately or better yet, forbid combining characters at critical parse locations. If your data structure does not include these types of rule then you should be iterating over the `Character` elements in a `String` rather than using this struct.
fileprivate struct ScalarScanner<C: Collection> where C.Iterator.Element == UnicodeScalar {
    /// The underlying storage
    let scalars: C

    /// Current scanning index
    var index: C.Index

    /// Number of scalars consumed up to `index` (since String.UnicodeScalarView.Index is not a RandomAccessIndex, this makes determining the position *much* easier)
    var consumed: Int

    /// Construct from a String.UnicodeScalarView and a context value
    init(scalars: C) {
        self.scalars = scalars
        self.index = self.scalars.startIndex
        self.consumed = 0
    }

    /// Sets the index back to the beginning and clears the consumed count
    mutating func reset() {
        index = scalars.startIndex
        consumed = 0
    }

    /// Throw if the scalars at the current `index` don't match the scalars in `value`. Advance the `index` to the end of the match.
    /// WARNING: `string` is used purely for its `unicodeScalars` property and matching is purely based on direct scalar comparison (no decomposition or normalization is performed).
    mutating func match(string: String) throws {
        let (newIndex, newConsumed) = try string.unicodeScalars.reduce((index: index, count: 0)) { (tuple: (index: C.Index, count: Int), scalar: UnicodeScalar) in
            if tuple.index == self.scalars.endIndex || scalar != self.scalars[tuple.index] {
                throw SwiftSymbolParseError.matchFailed(wanted: string, at: consumed)
            }
            return (index: self.scalars.index(after: tuple.index), count: tuple.count + 1)
        }
        index = newIndex
        consumed += newConsumed
    }

    /// Throw if the scalars at the current `index` don't match the scalars in `value`. Advance the `index` to the end of the match.
    mutating func match(scalar: UnicodeScalar) throws {
        if index == scalars.endIndex || scalars[index] != scalar {
            throw SwiftSymbolParseError.matchFailed(wanted: String(scalar), at: consumed)
        }
        index = self.scalars.index(after: index)
        consumed += 1
    }

    /// Throw if the scalars at the current `index` don't match the scalars in `value`. Advance the `index` to the end of the match.
    mutating func match(where test: @escaping (UnicodeScalar) -> Bool) throws {
        if index == scalars.endIndex || !test(scalars[index]) {
            throw SwiftSymbolParseError.matchFailed(wanted: String(describing: test), at: consumed)
        }
        index = self.scalars.index(after: index)
        consumed += 1
    }

    /// Throw if the scalars at the current `index` don't match the scalars in `value`. Advance the `index` to the end of the match.
    mutating func read(where test: @escaping (UnicodeScalar) -> Bool) throws -> UnicodeScalar {
        if index == scalars.endIndex || !test(scalars[index]) {
            throw SwiftSymbolParseError.matchFailed(wanted: String(describing: test), at: consumed)
        }
        let s = scalars[index]
        index = self.scalars.index(after: index)
        consumed += 1
        return s
    }

    /// Consume scalars from the contained collection, up to but not including the first instance of `scalar` found. `index` is advanced to immediately before `scalar`. Returns all scalars consumed prior to `scalar` as a `String`. Throws if `scalar` is never found.
    mutating func readUntil(scalar: UnicodeScalar) throws -> String {
        var i = index
        let previousConsumed = consumed
        try skipUntil(scalar: scalar)

        var result = ""
        result.reserveCapacity(consumed - previousConsumed)
        while i != index {
            result.unicodeScalars.append(scalars[i])
            i = scalars.index(after: i)
        }

        return result
    }

    /// Consume scalars from the contained collection, up to but not including the first instance of `string` found. `index` is advanced to immediately before `string`. Returns all scalars consumed prior to `string` as a `String`. Throws if `string` is never found.
    /// WARNING: `string` is used purely for its `unicodeScalars` property and matching is purely based on direct scalar comparison (no decomposition or normalization is performed).
    mutating func readUntil(string: String) throws -> String {
        var i = index
        let previousConsumed = consumed
        try skipUntil(string: string)

        var result = ""
        result.reserveCapacity(consumed - previousConsumed)
        while i != index {
            result.unicodeScalars.append(scalars[i])
            i = scalars.index(after: i)
        }

        return result
    }

    /// Consume scalars from the contained collection, up to but not including the first instance of any character in `set` found. `index` is advanced to immediately before `string`. Returns all scalars consumed prior to `string` as a `String`. Throws if no matching characters are ever found.
    mutating func readUntil(set inSet: Set<UnicodeScalar>) throws -> String {
        var i = index
        let previousConsumed = consumed
        try skipUntil(set: inSet)

        var result = ""
        result.reserveCapacity(consumed - previousConsumed)
        while i != index {
            result.unicodeScalars.append(scalars[i])
            i = scalars.index(after: i)
        }

        return result
    }

    /// Peeks at the scalar at the current `index`, testing it with function `f`. If `f` returns `true`, the scalar is appended to a `String` and the `index` increased. The `String` is returned at the end.
    mutating func readWhile(true test: (UnicodeScalar) -> Bool) -> String {
        var string = ""
        while index != scalars.endIndex {
            if !test(scalars[index]) {
                break
            }
            string.unicodeScalars.append(scalars[index])
            index = self.scalars.index(after: index)
            consumed += 1
        }
        return string
    }

    /// Repeatedly peeks at the scalar at the current `index`, testing it with function `f`. If `f` returns `true`, the `index` increased. If `false`, the function returns.
    mutating func skipWhile(true test: (UnicodeScalar) -> Bool) {
        while index != scalars.endIndex {
            if !test(scalars[index]) {
                return
            }
            index = self.scalars.index(after: index)
            consumed += 1
        }
    }

    /// Consume scalars from the contained collection, up to but not including the first instance of `scalar` found. `index` is advanced to immediately before `scalar`. Throws if `scalar` is never found.
    mutating func skipUntil(scalar: UnicodeScalar) throws {
        var i = index
        var c = 0
        while i != scalars.endIndex && scalars[i] != scalar {
            i = self.scalars.index(after: i)
            c += 1
        }
        if i == scalars.endIndex {
            throw SwiftSymbolParseError.searchFailed(wanted: String(scalar), after: consumed)
        }
        index = i
        consumed += c
    }

    /// Consume scalars from the contained collection, up to but not including the first instance of any scalar from `set` is found. `index` is advanced to immediately before `scalar`. Throws if `scalar` is never found.
    mutating func skipUntil(set inSet: Set<UnicodeScalar>) throws {
        var i = index
        var c = 0
        while i != scalars.endIndex && !inSet.contains(scalars[i]) {
            i = self.scalars.index(after: i)
            c += 1
        }
        if i == scalars.endIndex {
            throw SwiftSymbolParseError.searchFailed(wanted: "One of: \(inSet.sorted())", after: consumed)
        }
        index = i
        consumed += c
    }

    /// Consume scalars from the contained collection, up to but not including the first instance of `string` found. `index` is advanced to immediately before `string`. Throws if `string` is never found.
    /// WARNING: `string` is used purely for its `unicodeScalars` property and matching is purely based on direct scalar comparison (no decomposition or normalization is performed).
    mutating func skipUntil(string: String) throws {
        let match = string.unicodeScalars
        guard let first = match.first else { return }
        if match.count == 1 {
            return try skipUntil(scalar: first)
        }
        var i = index
        var j = index
        var c = 0
        var d = 0
        let remainder = match[match.index(after: match.startIndex)..<match.endIndex]
        outerLoop: repeat {
            while scalars[i] != first {
                if i == scalars.endIndex {
                    throw SwiftSymbolParseError.searchFailed(wanted: String(match), after: consumed)
                }
                i = self.scalars.index(after: i)
                c += 1

                // Track the last index and consume count before hitting the match
                j = i
                d = c
            }
            i = self.scalars.index(after: i)
            c += 1
            for s in remainder {
                if i == self.scalars.endIndex {
                    throw SwiftSymbolParseError.searchFailed(wanted: String(match), after: consumed)
                }
                if scalars[i] != s {
                    continue outerLoop
                }
                i = self.scalars.index(after: i)
                c += 1
            }
            break
        } while true
        index = j
        consumed += d
    }

    /// Attempt to advance the `index` by count, returning `false` and `index` unchanged if `index` would advance past the end, otherwise returns `true` and `index` is advanced.
    mutating func skip(count: Int = 1) throws {
        if count == 1 && index != scalars.endIndex {
            index = scalars.index(after: index)
            consumed += 1
        } else {
            var i = index
            var c = count
            while c > 0 {
                if i == scalars.endIndex {
                    throw SwiftSymbolParseError.endedPrematurely(count: count, at: consumed)
                }
                i = self.scalars.index(after: i)
                c -= 1
            }
            index = i
            consumed += count
        }
    }

    /// Attempt to advance the `index` by count, returning `false` and `index` unchanged if `index` would advance past the end, otherwise returns `true` and `index` is advanced.
    mutating func backtrack(count: Int = 1) throws {
        if count <= consumed {
            if count == 1 {
                index = scalars.index(index, offsetBy: -1)
                consumed -= 1
            } else {
                let limit = consumed - count
                while consumed != limit {
                    index = scalars.index(index, offsetBy: -1)
                    consumed -= 1
                }
            }
        } else {
            throw SwiftSymbolParseError.endedPrematurely(count: -count, at: consumed)
        }
    }

    /// Returns all content after the current `index`. `index` is advanced to the end.
    mutating func remainder() -> String {
        var string: String = ""
        while index != scalars.endIndex {
            string.unicodeScalars.append(scalars[index])
            index = scalars.index(after: index)
            consumed += 1
        }
        return string
    }

    /// If the next scalars after the current `index` match `value`, advance over them and return `true`, otherwise, leave `index` unchanged and return `false`.
    /// WARNING: `string` is used purely for its `unicodeScalars` property and matching is purely based on direct scalar comparison (no decomposition or normalization is performed).
    mutating func conditional(string: String) -> Bool {
        var i = index
        var c = 0
        for s in string.unicodeScalars {
            if i == scalars.endIndex || s != scalars[i] {
                return false
            }
            i = self.scalars.index(after: i)
            c += 1
        }
        index = i
        consumed += c
        return true
    }

    /// If the next scalar after the current `index` match `value`, advance over it and return `true`, otherwise, leave `index` unchanged and return `false`.
    mutating func conditional(scalar: UnicodeScalar) -> Bool {
        if index == scalars.endIndex || scalar != scalars[index] {
            return false
        }
        index = self.scalars.index(after: index)
        consumed += 1
        return true
    }

    /// If the next scalar after the current `index` match `value`, advance over it and return `true`, otherwise, leave `index` unchanged and return `false`.
    mutating func conditional(where test: (UnicodeScalar) -> Bool) -> UnicodeScalar? {
        if index == scalars.endIndex || !test(scalars[index]) {
            return nil
        }
        let s = scalars[index]
        index = self.scalars.index(after: index)
        consumed += 1
        return s
    }

    /// If the `index` is at the end, throw, otherwise, return the next scalar at the current `index` without advancing `index`.
    func requirePeek() throws -> UnicodeScalar {
        if index == scalars.endIndex {
            throw SwiftSymbolParseError.endedPrematurely(count: 1, at: consumed)
        }
        return scalars[index]
    }

    /// If `index` + `ahead` is within bounds, return the scalar at that location, otherwise return `nil`. The `index` will not be changed in any case.
    func peek(skipCount: Int = 0) -> UnicodeScalar? {
        var i = index
        var c = skipCount
        while c > 0 && i != scalars.endIndex {
            i = self.scalars.index(after: i)
            c -= 1
        }
        if i == scalars.endIndex {
            return nil
        }
        return scalars[i]
    }

    /// If the `index` is at the end, throw, otherwise, return the next scalar at the current `index`, advancing `index` by one.
    mutating func readScalar() throws -> UnicodeScalar {
        if index == scalars.endIndex {
            throw SwiftSymbolParseError.endedPrematurely(count: 1, at: consumed)
        }
        let result = scalars[index]
        index = self.scalars.index(after: index)
        consumed += 1
        return result
    }

    /// Throws if scalar at the current `index` is not in the range `"0"` to `"9"`. Consume scalars `"0"` to `"9"` until a scalar outside that range is encountered. Return the integer representation of the value scanned, interpreted as a base 10 integer. `index` is advanced to the end of the number.
    mutating func readInt() throws -> Int {
        let result = conditionalInt()
        guard let r = result else {
            throw SwiftSymbolParseError.expectedInt(at: consumed)
        }
        return r
    }

    /// Throws if scalar at the current `index` is not in the range `"0"` to `"9"`. Consume scalars `"0"` to `"9"` until a scalar outside that range is encountered. Return the integer representation of the value scanned, interpreted as a base 10 integer. `index` is advanced to the end of the number.
    mutating func conditionalInt() -> Int? {
        var result = 0
        var i = index
        var c = 0
        while i != scalars.endIndex && scalars[i].isDigit {
            let digit = Int(scalars[i].value - UnicodeScalar("0").value)
            // Avoid overflow
            if (Int.max - digit) / 10 < result {
                return nil
            }
            result = result * 10 + digit
            i = self.scalars.index(after: i)
            c += 1
        }
        if i == index {
            return nil
        }
        index = i
        consumed += c
        return result
    }

    /// Consume and return `count` scalars. `index` will be advanced by count. Throws if end of `scalars` occurs before consuming `count` scalars.
    mutating func readScalars(count: Int) throws -> String {
        var result = String()
        result.reserveCapacity(count)
        var i = index
        for _ in 0..<count {
            if i == scalars.endIndex {
                throw SwiftSymbolParseError.endedPrematurely(count: count, at: consumed)
            }
            result.unicodeScalars.append(scalars[i])
            i = self.scalars.index(after: i)
        }
        index = i
        consumed += count
        return result
    }

    /// Returns a throwable error capturing the current scanner progress point.
    func unexpectedError() -> SwiftSymbolParseError {
        return SwiftSymbolParseError.unexpected(at: consumed)
    }

    var isAtEnd: Bool {
        return index == scalars.endIndex
    }
}

fileprivate extension Array {
    func at(_ index: Int) -> Element? {
        return self.indices.contains(index) ? self[index] : nil
    }

    func slice(_ from: Int, _ to: Int) -> ArraySlice<Element> {
        if from > to || from > self.endIndex || to < self.startIndex {
            return ArraySlice()
        } else {
            return self[(from > self.startIndex ? from : self.startIndex)..<(to < self.endIndex ? to : self.endIndex)]
        }
    }
}
