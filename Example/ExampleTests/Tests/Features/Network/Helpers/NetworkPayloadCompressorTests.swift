//
//  NetworkPayloadCompressorTests.swift
//  DebugSwift
//
//  Created by Adjie Satryo on 01/10/26.
//

import XCTest
@testable import DebugSwift

final class NetworkPayloadCompressorTests: XCTestCase {
    private let sampleJSON = """
    {
        "status": "success",
        "code": 200,
        "message": "Transactions fetched successfully",
        "data": [
            {
                "id": "tx_1234567890",
                "amount": 150000.0,
                "currency": "IDR",
                "description": "Payment A"
            },
            {
                "id": "tx_1234567891",
                "amount": 45000.0,
                "currency": "IDR",
                "description": "Payment B"
            }
        ]
    }
    """

    func testRoundTripAllMethods_preservesExactData() {
        guard let originalData = sampleJSON.data(using: .utf8) else {
            XCTFail("Failed to convert sample JSON to Data")
            return
        }

        for method in NetworkPayloadCompressionMethod.allCases {
            let compressed = originalData.compressedPayload(using: method)
            XCTAssertFalse(compressed.isEmpty)

            let decompressed = compressed.decompressedPayload()
            XCTAssertEqual(decompressed, originalData)

            let helperDecompressed = DebugSwift.Network.uncompressPayload(compressed)
            XCTAssertEqual(helperDecompressed, originalData)
        }
    }

    func testCompressionRatio_isEffectiveForTextJSON() {
        guard let originalData = sampleJSON.data(using: .utf8) else {
            XCTFail("Failed to convert sample JSON to Data")
            return
        }

        let lzfse = originalData.compressedPayload(using: .lzfse)
        XCTAssertLessThan(lzfse.count, originalData.count)
    }

    func testEmptyData_handledGracefully() {
        let empty = Data()
        for method in NetworkPayloadCompressionMethod.allCases {
            let compressed = empty.compressedPayload(using: method)
            XCTAssertTrue(compressed.isEmpty)
            XCTAssertTrue(compressed.decompressedPayload().isEmpty)
        }
    }

    func testBackwardCompatibility_legacyRawDataWithoutHeader_returnsAsIs() {
        guard let rawLegacyData = "Legacy raw payload without magic header".data(using: .utf8) else {
            return
        }

        let result = rawLegacyData.decompressedPayload()
        XCTAssertEqual(result, rawLegacyData)
    }
}
