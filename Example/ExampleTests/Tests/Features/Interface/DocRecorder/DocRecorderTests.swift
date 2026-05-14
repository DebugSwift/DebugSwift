//
//  DocRecorderTests.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/05/26.
//

import XCTest
import UIKit
@testable import DebugSwift

@MainActor
final class DocRecorderTests: XCTestCase {

    // MARK: - RecordingSession Tests

    func test_RecordingSession_addStep_addsStepWhenNotPaused() {
        let session = RecordingSession()
        let screenshot = UIImage()
        let step = RecordingSession.Step(
            index: 1,
            screenshot: screenshot,
            annotatedImage: screenshot,
            interactionType: .tap(viewDescription: "Button"),
            location: CGPoint(x: 100, y: 100),
            timestamp: Date()
        )

        session.addStep(step)

        XCTAssertEqual(session.steps.count, 1)
        XCTAssertEqual(session.stepCounter, 1)
    }

    func test_RecordingSession_addStep_doesNotAddWhenPaused() {
        let session = RecordingSession()
        session.pause()
        let screenshot = UIImage()
        let step = RecordingSession.Step(
            index: 1,
            screenshot: screenshot,
            annotatedImage: screenshot,
            interactionType: .tap(viewDescription: "Button"),
            location: CGPoint(x: 100, y: 100),
            timestamp: Date()
        )

        session.addStep(step)

        XCTAssertEqual(session.steps.count, 0)
    }

    func test_RecordingSession_clear_removesAllSteps() {
        let session = RecordingSession()
        let screenshot = UIImage()
        let step = RecordingSession.Step(
            index: 1,
            screenshot: screenshot,
            annotatedImage: screenshot,
            interactionType: .tap(viewDescription: "Button"),
            location: CGPoint(x: 100, y: 100),
            timestamp: Date()
        )

        session.addStep(step)
        session.clear()

        XCTAssertEqual(session.steps.count, 0)
        XCTAssertEqual(session.stepCounter, 0)
    }

    func test_RecordingSession_pauseResume_togglesState() {
        let session = RecordingSession()

        XCTAssertFalse(session.isPaused)

        session.pause()
        XCTAssertTrue(session.isPaused)

        session.resume()
        XCTAssertFalse(session.isPaused)
    }

    // MARK: - ScrollDirection Tests

    func test_ScrollDirection_arrowDirection_returnsOpposite() {
        XCTAssertEqual(RecordingSession.ScrollDirection.up.arrowDirection, .down)
        XCTAssertEqual(RecordingSession.ScrollDirection.down.arrowDirection, .up)
        XCTAssertEqual(RecordingSession.ScrollDirection.left.arrowDirection, .right)
        XCTAssertEqual(RecordingSession.ScrollDirection.right.arrowDirection, .left)
    }

    // MARK: - ScreenshotCapturer Tests

    func test_ScreenshotCapturer_captureScreenshot_returnsImageWhenHostAppActive() {
        let capturer = ScreenshotCapturer()

        let screenshot = capturer.captureScreenshot()

        XCTAssertNotNil(screenshot)
    }

    func test_ScreenshotCapturer_annotateWithCircle_createsImageWithAnnotation() {
        let capturer = ScreenshotCapturer()
        let originalImage = createTestImage(size: CGSize(width: 100, height: 100), color: .white)

        let annotated = capturer.annotateWithCircle(
            image: originalImage,
            location: CGPoint(x: 50, y: 50),
            stepNumber: 1
        )

        XCTAssertNotNil(annotated)
        XCTAssertEqual(annotated.size, originalImage.size)
    }

    func test_ScreenshotCapturer_annotateWithArrow_createsImageWithAnnotation() {
        let capturer = ScreenshotCapturer()
        let originalImage = createTestImage(size: CGSize(width: 100, height: 100), color: .white)

        let annotated = capturer.annotateWithArrow(
            image: originalImage,
            location: CGPoint(x: 50, y: 50),
            direction: .up
        )

        XCTAssertNotNil(annotated)
        XCTAssertEqual(annotated.size, originalImage.size)
    }

    // MARK: - SavedRecording Tests

    func test_SavedRecording_title_formatsDateCorrectly() {
        let recording = SavedRecording(
            id: UUID(),
            date: Date(),
            imageCount: 3,
            imageFileNames: ["image-001.png", "image-002.png", "image-003.png"]
        )

        XCTAssertFalse(recording.title.isEmpty)
        XCTAssertEqual(recording.imageCount, 3)
    }

    func test_SavedRecording_codable_roundTrips() throws {
        let recording = SavedRecording(
            id: UUID(),
            date: Date(),
            imageCount: 2,
            imageFileNames: ["image-001.png", "image-002.png"]
        )

        let data = try JSONEncoder().encode(recording)
        let decoded = try JSONDecoder().decode(SavedRecording.self, from: data)

        XCTAssertEqual(decoded.id, recording.id)
        XCTAssertEqual(decoded.imageCount, recording.imageCount)
        XCTAssertEqual(decoded.imageFileNames, recording.imageFileNames)
    }

    // MARK: - DocRecorderViewModel Tests

    func test_DocRecorderViewModel_togglePaused_togglesSessionState() {
        let session = RecordingSession()
        let viewModel = DocRecorderViewModel(session: session)

        XCTAssertFalse(viewModel.isPaused)

        viewModel.togglePaused()
        XCTAssertTrue(session.isPaused)

        viewModel.togglePaused()
        XCTAssertFalse(session.isPaused)
    }

    func test_DocRecorderViewModel_stop_callsOnStop() {
        let session = RecordingSession()
        let viewModel = DocRecorderViewModel(session: session)
        var stopCalled = false
        viewModel.onStop = { stopCalled = true }

        viewModel.stop()

        XCTAssertTrue(stopCalled)
    }

    // MARK: - Helper Methods

    private func createTestImage(size: CGSize, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
