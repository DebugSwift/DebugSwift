//
//  PDFManager.swift
//  DebugSwift
//
//  Created by Matheus Gois on 20/12/23.
//

import PDFKit
import UIKit

enum PDFManager {

    static func generatePDF(
        title: String,
        body: String,
        image: UIImage?,
        logs: String
    ) -> Data? {

        let bounds = UIScreen.main.bounds
        let pdfSize = CGSize(width: 610, height: 790)

        let pdfDocument = PDFDocument()
        let pdfPage = PDFPage.createPage(color: .white, size: pdfSize)
        pdfDocument.insert(pdfPage, at: .zero)

        // Add title
        let titleBounds = CGRect(
            x: .zero,
            y: pdfSize.height - 30,
            width: pdfSize.width,
            height: 30
        )
        let titleAnnotation = PDFAnnotation.createTextAnnotation(
            text: title,
            bounds: titleBounds,
            fontSize: 20,
            alignment: .center
        )
        pdfPage.addAnnotation(titleAnnotation)

        // Body
        let bodyBounds = CGRect(
            x: 50,
            y: .zero,
            width: pdfSize.width - 50,
            height: pdfSize.height - 40
        )
        let bodyAnnotation = PDFAnnotation.createTextAnnotation(
            text: body,
            bounds: bodyBounds,
            fontSize: 8,
            alignment: .left
        )

        pdfPage.addAnnotation(bodyAnnotation)

        // Add image
        if let image {
            let screenWidth = bounds.size.width / 1.3
            let screenHeight = bounds.size.height / 1.3

            let pdfPage2 = PDFPage.createPage(color: .white, size: pdfSize)

            // Add title to the page
            let titleBounds = CGRect(
                x: .zero,
                y: .zero,
                width: pdfSize.width,
                height: pdfSize.height
            )
            let titleAnnotation = PDFAnnotation.createTextAnnotation(
                text: "screenshot".localized(),
                bounds: titleBounds,
                fontSize: 20,
                alignment: .center
            )
            pdfPage2.addAnnotation(titleAnnotation)

            // Add Image

            let imageRect = CGRect(x: 145, y: .zero, width: screenWidth, height: screenHeight)
            let imageAnnotation = ImageAnnotation(imageBounds: imageRect, image: image)
            pdfPage2.addAnnotation(imageAnnotation)

            pdfDocument.insert(pdfPage2, at: 1)
        }

        // Add logs
        if !logs.isEmpty {
            let pdfPage3 = PDFPage.createPage(color: .white, size: pdfSize)
            pdfDocument.insert(pdfPage3, at: 2)

            // Add title
            let titleBounds = CGRect(
                x: .zero,
                y: pdfSize.height - 30,
                width: pdfSize.width,
                height: 30
            )
            let titleAnnotation = PDFAnnotation.createTextAnnotation(
                text: "logs".localized(),
                bounds: titleBounds,
                fontSize: 20,
                alignment: .center
            )
            pdfPage3.addAnnotation(titleAnnotation)

            // Body
            let bodyBounds = CGRect(
                x: 50,
                y: .zero,
                width: pdfSize.width - 50,
                height: pdfSize.height - 40
            )
            let bodyAnnotation = PDFAnnotation.createTextAnnotation(
                text: logs,
                bounds: bodyBounds,
                fontSize: 6,
                alignment: .left
            )

            pdfPage3.addAnnotation(bodyAnnotation)
        }

        // Convert PDF document to data
        return pdfDocument.dataRepresentation()
    }

    static func savePDFData(_ pdfData: Data, fileName: String) -> URL? {
        // Get the documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first

        // Create a file URL for the PDF
        let fileURL = documentsDirectory?.appendingPathComponent(fileName)

        do {
            // Write the PDF data to the file
            try pdfData.write(to: fileURL!)
            return fileURL
        } catch {
            Debug.print("Error saving PDF data: \(error)")
            return nil
        }
    }
}

private final class ImageAnnotation: PDFAnnotation {

    private var _image: UIImage?

    init(imageBounds: CGRect, image: UIImage?) {
        self._image = image
        super.init(bounds: imageBounds, forType: .stamp, withProperties: nil)
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        guard let cgImage = _image?.cgImage else {
            return
        }

        let drawingBox = page?.bounds(for: box)
        let imageBounds = bounds.applying(
            CGAffineTransform(
                translationX: (drawingBox?.origin.x)! * -1.0,
                y: (drawingBox?.origin.y)! * -1.0
            )
        )

        // Draw the image
        context.draw(cgImage, in: imageBounds)

        // Add a border around the image
        let borderWidth: CGFloat = 10
        context.setStrokeColor(UIColor.black.cgColor) // Set border color
        context.setLineWidth(borderWidth)
        context.addRect(imageBounds.insetBy(dx: -borderWidth / 2, dy: -borderWidth / 2))
        context.strokePath()
    }
}

extension PDFAnnotation {
    static func createTextAnnotation(
        text: String,
        bounds: CGRect,
        fontSize: CGFloat,
        alignment: NSTextAlignment
    ) -> PDFAnnotation {
        let annotation = PDFAnnotation(bounds: bounds, forType: .widget, withProperties: nil)
        annotation.widgetFieldType = .text
        annotation.font = UIFont.systemFont(ofSize: fontSize)
        annotation.fontColor = .black
        annotation.backgroundColor = .clear
        annotation.isMultiline = true
        annotation.widgetStringValue = text
        annotation.alignment = alignment

        return annotation
    }
}

extension PDFPage {
    static func createPage(color: UIColor, size: CGSize) -> PDFPage {
        let page = PDFPage()

        return page
    }
}
