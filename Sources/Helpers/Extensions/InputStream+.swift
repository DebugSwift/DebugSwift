//
//  InputStream+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

extension InputStream {
    func toData() -> Data {
        open()
        defer { close() }

        var data = Data()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)

        while hasBytesAvailable {
            let bytesRead = read(buffer, maxLength: bufferSize)
            if bytesRead > 0 {
                data.append(buffer, count: bytesRead)
            } else if bytesRead < 0 {
                // Handle error or break the loop accordingly
                break
            }
        }

        buffer.deallocate()

        return data
    }
}
