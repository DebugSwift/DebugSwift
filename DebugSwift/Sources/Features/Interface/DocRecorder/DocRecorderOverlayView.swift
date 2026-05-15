//
//  DocRecorderOverlayView.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/05/26.
//

import SwiftUI

@available(iOS 14.0, *)
struct DocRecorderOverlayView: View {
    @ObservedObject var viewModel: DocRecorderViewModel
    @State private var currentPosition: CGPoint?
    @State private var dragStartPosition: CGPoint?
    @State private var lastReportedFrame: CGRect = .zero
    @State private var buttonSize: CGSize = .zero

    private let horizontalPadding: CGFloat = 20.0
    private let verticalPadding: CGFloat = 8.0

    var body: some View {
        GeometryReader { proxy in
            let containerSize = proxy.size
            let effectiveButtonSize = buttonSize
            let defaultPosition = makeDefaultPosition(in: containerSize, buttonSize: effectiveButtonSize)
            let resolvedPosition = currentPosition ?? defaultPosition

            ZStack {
                Color.clear
                floatingControls
                    .position(resolvedPosition)
                    .simultaneousGesture(
                        dragGesture(
                            in: containerSize,
                            buttonSize: effectiveButtonSize,
                            defaultPosition: defaultPosition
                        )
                    )
            }
            .ignoresSafeArea()
            .onAppear {
                let resolvedPosition = currentPosition ?? defaultPosition
                currentPosition = resolvedPosition
                reportTouchableFrame(for: resolvedPosition, buttonSize: effectiveButtonSize)
            }
            .onChange(of: proxy.size) { newSize in
                let defaultPosition = makeDefaultPosition(in: newSize, buttonSize: effectiveButtonSize)
                let updated = clamp(
                    currentPosition ?? defaultPosition, in: newSize, buttonSize: effectiveButtonSize
                )
                currentPosition = updated
                reportTouchableFrame(for: updated, buttonSize: effectiveButtonSize)
            }
            .onChange(of: buttonSize) { newSize in
                let defaultPosition = makeDefaultPosition(in: containerSize, buttonSize: newSize)
                let updated = clamp(
                    currentPosition ?? defaultPosition, in: containerSize, buttonSize: newSize
                )
                currentPosition = updated
                reportTouchableFrame(for: updated, buttonSize: newSize)
            }
        }
    }

    private var floatingControls: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.togglePaused()
            } label: {
                Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }

            if viewModel.stepCount > 0 {
                Text("\(viewModel.stepCount)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
            }

            Button {
                viewModel.stop()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.8))
                .shadow(radius: 8)
        )
        .background(
            GeometryReader { buttonProxy in
                Color.clear
                    .preference(key: ButtonSizePreferenceKey.self, value: buttonProxy.size)
            }
        )
        .onPreferenceChange(ButtonSizePreferenceKey.self) { size in
            guard size != .zero else { return }
            if buttonSize != size {
                buttonSize = size
            }
        }
    }

    private func dragGesture(
        in size: CGSize,
        buttonSize: CGSize,
        defaultPosition: CGPoint
    ) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let start = dragStartPosition ?? (currentPosition ?? defaultPosition)
                dragStartPosition = start
                let translated = CGPoint(
                    x: start.x + value.translation.width,
                    y: start.y + value.translation.height
                )
                let clampedPosition = clamp(translated, in: size, buttonSize: buttonSize)
                currentPosition = clampedPosition
                if let currentPosition {
                    reportTouchableFrame(for: currentPosition, buttonSize: buttonSize)
                }
            }
            .onEnded { _ in
                let position = currentPosition ?? defaultPosition
                let clampedPosition = clamp(position, in: size, buttonSize: buttonSize)
                currentPosition = clampedPosition
                if let currentPosition {
                    reportTouchableFrame(for: currentPosition, buttonSize: buttonSize)
                }
                dragStartPosition = nil
            }
    }

    private func clamp(_ position: CGPoint, in size: CGSize, buttonSize: CGSize) -> CGPoint {
        let horizontalRadius: CGFloat = buttonSize.width / 2.0
        let verticalRadius: CGFloat = buttonSize.height / 2.0
        let minX: CGFloat = horizontalRadius + horizontalPadding
        let maxX: CGFloat = max(
            horizontalRadius + horizontalPadding, size.width - horizontalRadius - horizontalPadding
        )
        let minY: CGFloat = verticalRadius + verticalPadding
        let maxY: CGFloat = max(
            verticalRadius + verticalPadding, size.height - verticalRadius - verticalPadding
        )

        let clampedX: CGFloat = min(max(position.x, minX), maxX)
        let clampedY: CGFloat = min(max(position.y, minY), maxY)
        return CGPoint(x: clampedX, y: clampedY)
    }

    private func makeDefaultPosition(in size: CGSize, buttonSize: CGSize) -> CGPoint {
        let horizontalRadius = buttonSize.width / 2.0
        let verticalRadius = buttonSize.height / 2.0
        return CGPoint(
            x: size.width - horizontalRadius - horizontalPadding,
            y: size.height - verticalRadius - verticalPadding
        )
    }

    private func reportTouchableFrame(for position: CGPoint, buttonSize: CGSize) {
        let frame = CGRect(
            x: position.x - (buttonSize.width / 2.0),
            y: position.y - (buttonSize.height / 2.0),
            width: buttonSize.width,
            height: buttonSize.height
        )

        guard frame != lastReportedFrame else { return }
        lastReportedFrame = frame
        viewModel.updateVisibleFrame(frame)
    }
}

private struct ButtonSizePreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}
