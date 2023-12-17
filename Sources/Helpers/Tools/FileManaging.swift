//
//  FileManaging.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

protocol FileManaging {
    func contentsOfDirectory(atPath path: String) throws -> [String]
    func fileExists(atPath path: String, isDirectory: inout ObjCBool) -> Bool
    func removeItem(atPath path: String) throws
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any]
}

class FileManagerHelper: FileManaging {
    func contentsOfDirectory(atPath path: String) throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: path)
    }

    func fileExists(atPath path: String, isDirectory: inout ObjCBool) -> Bool {
        FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
    }

    func removeItem(atPath path: String) throws {
        try FileManager.default.removeItem(atPath: path)
    }

    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        try FileManager.default.attributesOfItem(atPath: path)
    }
}
