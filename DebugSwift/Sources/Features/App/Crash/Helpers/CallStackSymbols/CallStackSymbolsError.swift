//
//  CallStackSymbolsError.swift
//  
//
//  Created by Naruki Chigira on 2021/07/23.
//

import Foundation

/// Errors will occur when getting DLADDRs.
public enum CallStackSymbolsError: Error {
    /// Failed to parse call stack symbol.
    case failedToParseCallStackSymbol(String)
}
