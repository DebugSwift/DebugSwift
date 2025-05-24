//
//  PDFManagerTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/2024.
//

import Testing
import UIKit
@testable import DebugSwift

struct PDFManagerTests {

    @Test("Generate PDF with all parameters")
    @MainActor
    @available(iOS 13.0, *)
    func generatePDFWithAllParameters() async {
        // Given
        let title = "Test Title"
        let body = "Test Body"
        let image = UIImage(systemName: "star")
        let logs = "Test Logs"

        // When
        let pdfData = PDFManager.generatePDF(title: title, body: body, image: image, logs: logs)

        // Then
        #expect(pdfData != nil)
    }

    @Test("Generate PDF without image")
    @MainActor
    func generatePDFWithoutImage() async {
        // Given
        let title = "Test Title"
        let body = "Test Body"
        let image: UIImage? = nil
        let logs = "Test Logs"

        // When
        let pdfData = PDFManager.generatePDF(title: title, body: body, image: image, logs: logs)

        // Then
        #expect(pdfData != nil)
    }

    @Test("Generate PDF without logs")
    @MainActor
    @available(iOS 13.0, *)
    func generatePDFWithoutLogs() async {
        // Given
        let title = "Test Title"
        let body = "Test Body"
        let image = UIImage(systemName: "star")
        let logs = ""

        // When
        let pdfData = PDFManager.generatePDF(title: title, body: body, image: image, logs: logs)

        // Then
        #expect(pdfData != nil)
    }

    @Test("Generate PDF with empty parameters")
    @MainActor
    func generatePDFWithEmptyParameters() async {
        // Given
        let title = ""
        let body = ""
        let image: UIImage? = nil
        let logs = ""

        // When
        let pdfData = PDFManager.generatePDF(title: title, body: body, image: image, logs: logs)

        // Then
        #expect(pdfData != nil)
    }

    @Test("Save PDF data successfully")
    func savePDFDataSuccessfully() {
        // Given
        let pdfData = Data(repeating: 0, count: 1024)
        let fileName = "test.pdf"

        // When
        let fileURL = PDFManager.savePDFData(pdfData, fileName: fileName)

        // Then
        #expect(fileURL != nil)
        if let fileURL = fileURL {
            #expect(FileManager.default.fileExists(atPath: fileURL.path) == true)
        }
    }

    @Test("Save PDF data failure with empty filename")
    func savePDFDataFailure() {
        // Given
        let pdfData = Data(repeating: 0, count: 1024)
        let fileName = ""

        // When
        let fileURL = PDFManager.savePDFData(pdfData, fileName: fileName)

        // Then
        #expect(fileURL == nil)
    }

    @Test("Generate PDF with valid inputs")
    @MainActor
    func generatePDFWithValidInputs() async {
        // Given
        let title = "Test Title"
        let body = "Test Body"
        let image = UIImage()
        let logs = "Test Logs"
        
        // When
        let pdfData = PDFManager.generatePDF(title: title, body: body, image: image, logs: logs)
        
        // Then
        #expect(pdfData != nil)
        if let pdfData = pdfData {
            #expect(pdfData.count > 0)
        }
    }
    
    @Test("Generate PDF with nil values")
    @MainActor
    func generatePDFWithNilValues() async {
        // Given
        let title = "Default Title"  // Provide default values
        let body = "Default Body"
        let image: UIImage? = nil
        let logs = "Default Logs"
        
        // When
        let pdfData = PDFManager.generatePDF(title: title, body: body, image: image, logs: logs)
        
        // Then
        #expect(pdfData != nil)
        if let pdfData = pdfData {
            #expect(pdfData.count > 0)
        }
    }
    
    @Test("Generate PDF with long text")
    @MainActor
    func generatePDFWithLongText() async {
        // Given
        let title = "Very Long Title That Should Wrap Around Multiple Lines"
        let body = String(repeating: "This is a very long body text. ", count: 100)
        let image = UIImage()
        let logs = String(repeating: "Log entry. ", count: 200)
        
        // When
        let pdfData = PDFManager.generatePDF(title: title, body: body, image: image, logs: logs)
        
        // Then
        #expect(pdfData != nil)
        if let pdfData = pdfData {
            #expect(pdfData.count > 0)
        }
    }
    
    @Test("Generate PDF with special characters")
    @MainActor
    func generatePDFWithSpecialCharacters() async {
        // Given
        let title = "Title with Special Characters: !@#$%^&*()"
        let body = "Body with unicode: 😀🎉🌟"
        let image = UIImage()
        let logs = "Logs with line breaks:\nLine 1\nLine 2\nLine 3"
        
        // When
        let pdfData = PDFManager.generatePDF(title: title, body: body, image: image, logs: logs)
        
        // Then
        #expect(pdfData != nil)
        if let pdfData = pdfData {
            #expect(pdfData.count > 0)
        }
    }
}
