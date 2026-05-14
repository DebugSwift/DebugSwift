//
//  InteractionInterceptor.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/05/26.
//

import Combine
import Foundation
import UIKit

@MainActor
final class InteractionInterceptor {
    private let session: RecordingSession
    private let capturer: ScreenshotCapturer
    private var lastCaptureTime: Date = .distantPast
    private let debounceInterval: TimeInterval = 0.15
    private var touchStartLocation: CGPoint?
    private var scrollStartLocation: CGPoint?
    private var cancellables = Set<AnyCancellable>()

    fileprivate static var sharedInterceptor: InteractionInterceptor?
    private static var hasSwizzledGlobally = false

    init(session: RecordingSession, capturer: ScreenshotCapturer) {
        self.session = session
        self.capturer = capturer
        Self.sharedInterceptor = self
        setupTextFieldObservers()
    }

    func start() {
        guard !Self.hasSwizzledGlobally else { return }
        swizzleUIWindowSendEvent()
        Self.hasSwizzledGlobally = true
    }

    func stop() {
        Self.sharedInterceptor = nil
        cancellables.removeAll()
    }

    private func swizzleUIWindowSendEvent() {
        guard let originalMethod = class_getInstanceMethod(
            UIWindow.self, #selector(UIWindow.sendEvent(_:))
        ),
            let swizzledMethod = class_getInstanceMethod(
                UIWindow.self, #selector(UIWindow.docRec_sendEvent(_:))
            )
        else {
            return
        }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    private func setupTextFieldObservers() {
        NotificationCenter.default.publisher(for: UITextField.textDidEndEditingNotification)
            .sink { [weak self] notification in
                self?.handleTextFieldDidEndEditing(notification)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UITextView.textDidEndEditingNotification)
            .sink { [weak self] notification in
                self?.handleTextViewDidEndEditing(notification)
            }
            .store(in: &cancellables)
    }

    private func handleTextFieldDidEndEditing(_ notification: Notification) {
        guard let textField = notification.object as? UITextField,
              let window = textField.window else { return }

        let fieldDescription = textField.placeholder ?? textField.accessibilityLabel ?? "Text Field"
        let locationInWindow = textField.convert(
            CGPoint(x: textField.bounds.midX, y: textField.bounds.midY), to: window
        )

        captureInteraction(
            type: .textInput(fieldDescription: fieldDescription),
            location: locationInWindow
        )
    }

    private func handleTextViewDidEndEditing(_ notification: Notification) {
        guard let textView = notification.object as? UITextView,
              let window = textView.window else { return }

        let fieldDescription = textView.accessibilityLabel ?? "Text View"
        let locationInWindow = textView.convert(
            CGPoint(x: textView.bounds.midX, y: textView.bounds.midY), to: window
        )

        captureInteraction(
            type: .textInput(fieldDescription: fieldDescription),
            location: locationInWindow
        )
    }

    fileprivate func handleTouch(_ touch: UITouch, in window: UIWindow) {
        guard !session.isPaused else { return }

        let location = touch.location(in: window)

        switch touch.phase {
        case .began:
            touchStartLocation = location
            scrollStartLocation = location

        case .moved:
            if let start = scrollStartLocation {
                let distance = hypot(location.x - start.x, location.y - start.y)
                if distance > 10 {
                    touchStartLocation = nil
                }
            }

        case .ended:
            if let start = touchStartLocation {
                let distance = hypot(location.x - start.x, location.y - start.y)
                if distance < 10 {
                    handleTap(at: location)
                }
            } else if let start = scrollStartLocation {
                let distance = hypot(location.x - start.x, location.y - start.y)
                if distance > 30 {
                    handleScroll(from: start, to: location)
                }
            }

            touchStartLocation = nil
            scrollStartLocation = nil

        case .cancelled:
            touchStartLocation = nil
            scrollStartLocation = nil

        default:
            break
        }
    }

    private func handleTap(at location: CGPoint) {
        guard shouldCapture() else { return }

        let viewDescription = findViewDescription(at: location)
        captureInteraction(
            type: .tap(viewDescription: viewDescription),
            location: location
        )
    }

    private func handleScroll(from start: CGPoint, to end: CGPoint) {
        guard shouldCapture() else { return }

        let deltaX = end.x - start.x
        let deltaY = end.y - start.y

        let direction: RecordingSession.ScrollDirection
        if abs(deltaX) > abs(deltaY) {
            direction = deltaX > 0 ? .right : .left
        } else {
            direction = deltaY > 0 ? .down : .up
        }

        captureInteraction(
            type: .scroll(direction: direction),
            location: start
        )
    }

    private func findViewDescription(at location: CGPoint) -> String {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
            let window = windowScene.windows.first(where: { $0.isKeyWindow })
        else {
            return "Unknown View"
        }

        if let hitView = window.hitTest(location, with: nil) {
            if let accessibilityLabel = hitView.accessibilityLabel, !accessibilityLabel.isEmpty {
                return accessibilityLabel
            }
            return String(describing: type(of: hitView))
        }

        return "Unknown View"
    }

    private func shouldCapture() -> Bool {
        let now = Date()
        guard now.timeIntervalSince(lastCaptureTime) >= debounceInterval else {
            return false
        }
        lastCaptureTime = now
        return true
    }

    private func captureInteraction(type: RecordingSession.InteractionType, location: CGPoint) {
        guard let screenshot = capturer.captureScreenshot() else { return }

        let stepNumber = session.stepCounter + 1
        let annotatedImage: UIImage

        switch type {
        case .tap:
            annotatedImage = capturer.annotateWithCircle(
                image: screenshot,
                location: location,
                stepNumber: stepNumber
            )
        case let .scroll(direction):
            annotatedImage = capturer.annotateWithArrow(
                image: screenshot,
                location: location,
                direction: direction
            )
        case .textInput:
            annotatedImage = capturer.annotateWithCircle(
                image: screenshot,
                location: location,
                stepNumber: stepNumber
            )
        }

        let step = RecordingSession.Step(
            index: stepNumber,
            screenshot: screenshot,
            annotatedImage: annotatedImage,
            interactionType: type,
            location: location,
            timestamp: Date()
        )

        session.addStep(step)
    }
}

// MARK: - UIWindow Swizzle

extension UIWindow {
    @objc func docRec_sendEvent(_ event: UIEvent) {
        let isRecorderWindow = self is DocRecorderPassthroughWindow || windowLevel == .alert + 3

        if !isRecorderWindow,
           event.type == .touches,
           let interceptor = InteractionInterceptor.sharedInterceptor,
           let touches = event.allTouches {
            for touch in touches {
                interceptor.handleTouch(touch, in: self)
            }
        }
        docRec_sendEvent(event)
    }
}
