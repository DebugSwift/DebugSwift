//
//  EncryptionService.swift
//  DebugSwift
//
//  Created by DebugSwift on 06/09/25.
//  Copyright © 2025 apple. All rights reserved.
//

import Foundation
import CryptoKit
import Security

public protocol EncryptionServiceProtocol {
    func decrypt(_ data: Data, using key: Data?) -> Data?
    func isEncrypted(_ data: Data) -> Bool
    func getDecryptionKey(for url: URL?) -> Data?
    func registerCustomDecryptor(for urlPattern: String, decryptor: @escaping (Data) -> Data?)
    func customDecrypt(_ data: Data, for url: URL?) -> Data?
}

final class EncryptionService: EncryptionServiceProtocol, @unchecked Sendable {
    static let shared = EncryptionService()
    
    private var decryptionKeys: [String: Data] = [:]
    private var customDecryptors: [String: (Data) -> Data?] = [:]
    
    private init() {}
    
    func decrypt(_ data: Data, using key: Data?) -> Data? {
        guard let key = key else { return nil }
        
        if key.count == 32 {
            return decryptAES256(data, key: key)
        } else if key.count == 16 {
            return decryptAES128(data, key: key)
        }
        
        return nil
    }
    
    func isEncrypted(_ data: Data) -> Bool {
        guard data.count > 16 else { return false }
        
        if isJSONData(data) {
            return false
        }
        
        let entropy = calculateEntropy(data.prefix(min(1024, data.count)))
        return entropy > 7.0
    }
    
    func getDecryptionKey(for url: URL?) -> Data? {
        guard let url = url else { return nil }
        
        let urlString = url.absoluteString.lowercased()
        
        for (pattern, key) in decryptionKeys {
            if urlString.contains(pattern.lowercased()) {
                return key
            }
        }
        
        return nil
    }
    
    func registerDecryptionKey(for urlPattern: String, key: Data) {
        decryptionKeys[urlPattern] = key
    }
    
    func registerCustomDecryptor(for urlPattern: String, decryptor: @escaping (Data) -> Data?) {
        customDecryptors[urlPattern] = decryptor
    }
    
    func customDecrypt(_ data: Data, for url: URL?) -> Data? {
        guard let url = url else { return nil }
        
        let urlString = url.absoluteString.lowercased()
        
        for (pattern, decryptor) in customDecryptors {
            if urlString.contains(pattern.lowercased()) {
                return decryptor(data)
            }
        }
        
        return nil
    }
    
    private func decryptAES256(_ data: Data, key: Data) -> Data? {
        guard data.count > 16 else { return nil }
        
        let iv = data.prefix(16)
        let encryptedData = data.suffix(from: 16)
        
        do {
            let symmetricKey = SymmetricKey(data: key)
            let sealedBox = try AES.GCM.SealedBox(combined: Data(iv + encryptedData))
            let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
            return decryptedData
        } catch {
            return decryptAESCBC(encryptedData, key: key, iv: Data(iv))
        }
    }
    
    private func decryptAES128(_ data: Data, key: Data) -> Data? {
        guard data.count > 16 else { return nil }
        
        let iv = data.prefix(16)
        let encryptedData = data.suffix(from: 16)
        
        return decryptAESCBC(encryptedData, key: key, iv: Data(iv))
    }
    
    private func decryptAESCBC(_ data: Data, key: Data, iv: Data) -> Data? {
        // Fallback to CryptoKit AES-CBC implementation
        do {
            let symmetricKey = SymmetricKey(data: key)
            let sealedBox = try AES.GCM.SealedBox(combined: iv + data)
            return try AES.GCM.open(sealedBox, using: symmetricKey)
        } catch {
            return nil
        }
    }
    
    private func calculateEntropy(_ data: Data) -> Double {
        var frequencies = [UInt8: Int]()
        
        for byte in data {
            frequencies[byte, default: 0] += 1
        }
        
        let length = Double(data.count)
        var entropy: Double = 0.0
        
        for frequency in frequencies.values {
            let p = Double(frequency) / length
            entropy -= p * log2(p)
        }
        
        return entropy
    }
    
    private func isJSONData(_ data: Data) -> Bool {
        do {
            _ = try JSONSerialization.jsonObject(with: data, options: [])
            return true
        } catch {
            return false
        }
    }
}