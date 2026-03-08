//
//  MeasurementLineView.swift
//  HyperionSwift
//
//  Created by Matheus Gois on 02/01/25.
//

import Foundation
import UIKit

@MainActor
class MeasurementsView: UIView {
    private let styleManager = StyleManager()
    private lazy var measurementLabelFactory = MeasurementElementsFactory(styleManager: styleManager)
    private lazy var measurementManager = MeasurementManager(
        delegate: delegate,
        measurementFactory: measurementLabelFactory,
        styleManager: styleManager
    )

    private weak var delegate: MeasurementViewDelegate?

    private var selectedView: UIView?
    private var compareView: UIView?

    required init(delegate: MeasurementViewDelegate?) {
        super.init(frame: .zero)
        self.delegate = delegate
        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupGestures()
        measurementManager.setup()
        
        // Make sure this view can receive touches but is transparent
        backgroundColor = UIColor.clear
        isUserInteractionEnabled = true
    }

    public func viewSelected(_ selection: UIView) {
        handleViewSelection(selection)
    }

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapGesture(_:)))
        // Only capture taps, don't interfere with scrolling
        tap.cancelsTouchesInView = true
        tap.delaysTouchesBegan = false
        tap.delaysTouchesEnded = false
        addGestureRecognizer(tap)
        
        isUserInteractionEnabled = true
    }

    @objc private func tapGesture(_ tapGesture: UITapGestureRecognizer) {
        guard let attachedWindow = delegate?.attachedWindow else {
            measurementManager.reset()
            return
        }

        let point = tapGesture.location(in: self)
        let pointInAttachedWindow = convert(point, to: attachedWindow)
        let selectedViews = ViewHelper.findSubviews(in: attachedWindow, intersectingPoint: pointInAttachedWindow)
        
        // Group views by area and select the last one from the smallest area group
        // Views are ordered from most general to most specific during traversal
        guard !selectedViews.isEmpty else {
            handleViewSelection(nil)
            return
        }
        
        let viewsWithAreas = selectedViews.map { view in
            (view: view, area: view.frame.width * view.frame.height)
        }
        
        let minArea = viewsWithAreas.map(\.area).min() ?? 0
        let viewsWithMinArea = viewsWithAreas.filter { $0.area == minArea }
        
        // Select the last view with minimum area (most specific)
        let mostSpecificView = viewsWithMinArea.last?.view

        handleViewSelection(mostSpecificView)
    }

    private func handleViewSelection(_ selection: UIView?) {
        if selection == compareView {
            compareView = nil
            measurementManager.clearCompareStyling()
        } else if selectedView == nil {
            selectedView = selection
            measurementManager.clearSelectedStyling()
            measurementManager.addBorder(in: self, forSelected: selectedView)
        } else if selection == selectedView {
            selectedView = nil
            compareView = nil
            measurementManager.clearCompareStyling()
            measurementManager.clearSelectedStyling()
        } else {
            compareView = selection
            measurementManager.clearCompareStyling()
            measurementManager.addBorder(in: self, forCompare: compareView)
        }

        displayMeasurementViews(for: selectedView, comparedTo: compareView ?? selectedView?.superview)
    }

    func interactionViewWillTransition(to _: CGSize, with _: UIViewControllerTransitionCoordinator) {
        measurementManager.clearAllStyling()
    }

    func interactionViewDidTransition(to _: CGSize) {
        if let selectedView = selectedView {
            measurementManager.addBorder(in: self, forSelected: selectedView)
            if compareView != nil {
                measurementManager.addBorder(in: self, forCompare: compareView)
            }
            displayMeasurementViews(for: selectedView, comparedTo: compareView ?? selectedView.superview)
        }
    }

    private func displayMeasurementViews(for selectedView: UIView?, comparedTo compareView: UIView?) {

        measurementManager.clearMeasurementViews()

        guard let selectedView = selectedView else { return }

        let globalSelectedRect = selectedView.superview?.convert(selectedView.frame, to: self)
        let globalComparisonViewRect = compareView?.superview?.convert(compareView?.frame ?? CGRect.zero, to: self)

        let viewsToMeasure: (UIView, UIView)
        if measurementManager.frame(globalSelectedRect, insideFrame: globalComparisonViewRect) {
            viewsToMeasure = (selectedView, compareView ?? selectedView)
        } else {
            viewsToMeasure = (compareView ?? selectedView, selectedView)
        }

        placeMeasurements(for: viewsToMeasure)
    }

    private func placeMeasurements(for views: (UIView, UIView)) {
        let (view1, view2) = views

        measurementManager.placeTopMeasurementBetweenSelectedView(in: self, view1, comparisonView: view2)
        measurementManager.placeBottomMeasurementBetweenSelectedView(in: self, view1, comparisonView: view2)
        measurementManager.placeLeftMeasurementBetweenSelectedView(in: self, view1, comparisonView: view2)
        measurementManager.placeRightMeasurementBetweenSelectedView(in: self, view1, comparisonView: view2)
    }
}
