//
//  AIError.swift
//  DebugSwift
//

#if DEBUG
import Foundation

public enum AIError: Error, Equatable, Sendable {
  case notBootstrapped
  case unknownFeature(String)
}
#endif
