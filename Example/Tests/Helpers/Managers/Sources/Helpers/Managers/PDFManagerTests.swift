//
//  PDFManagerTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/2024.
//

import XCTest
@testable import DebugSwift

final class PDFManagerTests: XCTestCase {

    @available(iOS 13.0, *)
    func testGeneratePDFWithAllParameters() {
        // Given
        let title = "Test Title"
        let body = "Test Body"
        let image = UIImage(systemName: "star")
        let logs = "Test Logs"

        // When
        let pdfData = PDFManager.generatePDF(title: title, body: body, image: image, logs: logs)

        // Then
        XCTAssertNotNil(pdfData, "PDF data should not be nil")
    }

    func testGeneratePDFWithoutImage() {
        // Given
        let title = "Test Title"
        let body = "Test Body"
        let image: UIImage? = nil
        let logs = "Test Logs"

        // When
        let pdfData = PDFManager.generatePDF(title: title, body: body, image: image, logs: logs)

        // Then
        XCTAssertNotNil(pdfData, "PDF data should not be nil")
    }

    @available(iOS 13.0, *)
    func testGeneratePDFWithoutLogs() {
        // Given
        let title = "Test Title"
        let body = "Test Body"
        let image = UIImage(systemName: "star")
        let logs = ""

        // When
        let pdfData = PDFManager.generatePDF(title: title, body: body, image: image, logs: logs)

        // Then
        XCTAssertNotNil(pdfData, "PDF data should not be nil")
    }

    func testGeneratePDFWithEmptyParameters() {
        // Given
        let title = ""
        let body = ""
        let image: UIImage? = nil
        let logs = ""

        // When
        let pdfData = PDFManager.generatePDF(title: title, body: body, image: image, logs: logs)

        // Then
        XCTAssertNotNil(pdfData, "PDF data should not be nil")
    }

    func testSavePDFDataSuccessfully() {
        // Given
        let pdfData = Data(repeating: 0, count: 1024)
        let fileName = "test.pdf"

        // When
        let fileURL = PDFManager.savePDFData(pdfData, fileName: fileName)

        // Then
        XCTAssertNotNil(fileURL, "File URL should not be nil")
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL!.path), "File should exist at the given path")
    }

    func testSavePDFDataFailure() {
        // Given
        let pdfData = Data(repeating: 0, count: 1024)
        let fileName = ""

        // When
        let fileURL = PDFManager.savePDFData(pdfData, fileName: fileName)

        // Then
        XCTAssertNil(fileURL, "File URL should be nil for an invalid file name")
    }
}
