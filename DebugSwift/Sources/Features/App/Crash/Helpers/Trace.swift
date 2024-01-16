//
//  Trace.swift
//  DebugSwift
//
//  Created by Matheus Gois on 20/12/23.
//

import Foundation
import MachO

enum Trace {
    static func classNameFromSymbol(_ symbol: String) -> String? {
        let pattern = "\\$s(\\S+)\\d+"

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: symbol.utf16.count)

            if let match = regex.firstMatch(in: symbol, options: [], range: range) {
                let classNameRange = Range(match.range(at: 1), in: symbol)
                if let className = classNameRange.flatMap({ String(symbol[$0]) }) {
                    return className
                }
            }
        } catch {
            Debug.print("Error creating regex: \(error)")
        }

        return nil
    }

    static func fileInfoFromSymbol(_ symbol: String) -> (file: String, line: Int, function: String)? {
        let pattern = "\\s+(\\S+\\.swift):(\\d+)\\s+(\\S+\\()"

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: symbol.utf16.count)

            if let match = regex.firstMatch(in: symbol, options: [], range: range) {
                let fileRange = Range(match.range(at: 1), in: symbol)
                let lineRange = Range(match.range(at: 2), in: symbol)
                let functionRange = Range(match.range(at: 3), in: symbol)

                if let file = fileRange.flatMap({ String(symbol[$0]) }),
                   let lineString = lineRange.flatMap({ String(symbol[$0]) }),
                   let line = Int(lineString),
                   let function = functionRange.flatMap({ String(symbol[$0]) }) {
                    return (file, line, function)
                }
            }
        } catch {
            Debug.print("Error creating regex: \(error)")
        }

        return nil
    }

    static func binaryInformation() -> String {
        var binaryInfo = ""

        for imageIndex in 0..<_dyld_image_count() {
            if let imageNamePtr = _dyld_get_image_name(imageIndex) {
                let imageName = String(cString: imageNamePtr)
                let slideAddress = slideAddressForImageIndex(imageIndex)
                binaryInfo += "\(String(format: "0x%0x", slideAddress)) - \(imageName):\n"
            }
        }

        return binaryInfo
    }

    static func slideAddressForImageIndex(_ index: UInt32) -> Int64 {
        return Int64(_dyld_get_image_vmaddr_slide(index))
    }
}
