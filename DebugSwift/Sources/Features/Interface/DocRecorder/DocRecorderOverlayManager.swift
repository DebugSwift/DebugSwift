//
//  DocRecorderOverlayManager.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/05/26.
//

import Combine
import SwiftUI
import UIKit

@MainActor
final class DocRecorderOverlayManager {
    static let shared = DocRecorderOverlayManager()

    private var window: DocRecorderPassthroughWindow?
    private var session: RecordingSession?
    private var viewModel: DocRecorderViewModel?
    private var capturer: ScreenshotCapturer?
    private var interceptor: InteractionInterceptor?
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    var isVisible: Bool { window != nil }

    func show() {
        guard window == nil else { return }

        guard
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive })
        else { return }

        let session = RecordingSession()
        let capturer = ScreenshotCapturer()
        let viewModel = DocRecorderViewModel(session: session)

        self.session = session
        self.capturer = capturer
        self.viewModel = viewModel

        let interceptor = InteractionInterceptor(session: session, capturer: capturer)
        self.interceptor = interceptor
        interceptor.start()

        viewModel.onStop = { [weak self] in
            self?.handleStop()
        }

        if #available(iOS 14.0, *) {
            showSwiftUIOverlay(viewModel: viewModel, windowScene: windowScene)
        } else {
            showFallbackOverlay(viewModel: viewModel, windowScene: windowScene)
        }
    }

    @available(iOS 14.0, *)
    private func showSwiftUIOverlay(viewModel: DocRecorderViewModel, windowScene: UIWindowScene) {
        let overlayView = DocRecorderOverlayView(viewModel: viewModel)

        let host = UIHostingController(rootView: overlayView)
        host.view.backgroundColor = .clear

        let floatingWindow = DocRecorderPassthroughWindow(windowScene: windowScene)
        floatingWindow.frame = UIScreen.main.bounds
        floatingWindow.backgroundColor = .clear
        floatingWindow.windowLevel = .alert + 3
        floatingWindow.rootViewController = host
        floatingWindow.makeKeyAndVisible()

        window = floatingWindow

        viewModel.updateVisibleFrame(.zero)

        startObservingButtonFrameUpdates(viewModel: viewModel)
    }

    private func showFallbackOverlay(viewModel: DocRecorderViewModel, windowScene: UIWindowScene) {
        let floatingWindow = DocRecorderPassthroughWindow(windowScene: windowScene)
        floatingWindow.frame = UIScreen.main.bounds
        floatingWindow.backgroundColor = .clear
        floatingWindow.windowLevel = .alert + 3

        let stopButton = UIButton(type: .system)
        stopButton.setTitle("⏹ Stop Recording", for: .normal)
        stopButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        stopButton.setTitleColor(.white, for: .normal)
        stopButton.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        stopButton.layer.cornerRadius = 22
        stopButton.frame = CGRect(x: UIScreen.main.bounds.width - 200, y: UIScreen.main.bounds.height - 100, width: 180, height: 44)
        stopButton.addTarget(self, action: #selector(fallbackStopTapped), for: .touchUpInside)

        floatingWindow.addSubview(stopButton)
        floatingWindow.touchableFrame = stopButton.frame
        floatingWindow.makeKeyAndVisible()

        window = floatingWindow
    }

    @objc private func fallbackStopTapped() {
        handleStop()
    }

    func hide() {
        interceptor?.stop()
        interceptor = nil
        window?.isHidden = true
        window = nil
        cancellables.removeAll()
        viewModel?.updateVisibleFrame(.zero)
        session?.clear()
        session = nil
        viewModel = nil
        capturer = nil
    }

    private func handleStop() {
        guard let session else {
            hide()
            return
        }

        guard !session.steps.isEmpty else {
            hide()
            return
        }

        _ = RecordingSessionStorage.shared.saveRecording(steps: session.steps)
        hide()
    }

    private func startObservingButtonFrameUpdates(viewModel: DocRecorderViewModel) {
        viewModel.$buttonFrame
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] frame in
                guard let window = self?.window else { return }
                window.touchableFrame = frame
            }
            .store(in: &cancellables)
    }
}
