//
//  DocRecorderViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/05/26.
//

import Combine
import Foundation
import UIKit

@MainActor
final class DocRecorderViewModel: ObservableObject {
    @Published var isPaused: Bool = false
    @Published var stepCount: Int = 0
    @Published var buttonFrame: CGRect = .zero

    var onStop: (() -> Void)?

    private let session: RecordingSession
    private var cancellables = Set<AnyCancellable>()

    init(session: RecordingSession) {
        self.session = session

        session.$isPaused
            .sink { [weak self] value in self?.isPaused = value }
            .store(in: &cancellables)

        session.$steps
            .map { $0.count }
            .sink { [weak self] value in self?.stepCount = value }
            .store(in: &cancellables)
    }

    func togglePaused() {
        if isPaused {
            session.resume()
        } else {
            session.pause()
        }
    }

    func stop() {
        onStop?()
    }

    func updateVisibleFrame(_ frame: CGRect) {
        buttonFrame = frame
    }
}
