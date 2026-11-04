//
//  ViewHelperTests.swift
//  DebugSwift
//
//  Created by Renogy_YX on 2026/11/4.
//

import UIKit
import XCTest
@testable import DebugSwift

/// 通过 UIKit 的透传契约复现整屏系统容器，不依赖私有类名或特定 iOS 版本。
@MainActor
final class ViewHelperTests: XCTestCase {
    private func makeRoot() -> UIView {
        UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
    }

    private func addLabel(to view: UIView, frame: CGRect) -> UILabel {
        let label = UILabel(frame: frame)
        label.text = "Measurement target"
        view.addSubview(label)
        return label
    }

    func testFullScreenPassThroughContainerDoesNotMaskBusinessLabel() {
        let root = makeRoot()
        let label = addLabel(to: root, frame: CGRect(x: 20, y: 120, width: 120, height: 30))
        let overlay = PassThroughMeasurementTestView(frame: root.bounds)
        root.addSubview(overlay)

        let selected = ViewHelper.findSubviews(in: root, intersectingPoint: CGPoint(x: 40, y: 135))

        XCTAssertTrue(selected.first === label)
        XCTAssertFalse(selected.contains { $0 === overlay })
    }

    func testNestedPassThroughContainersDoNotMaskBusinessLabel() {
        let root = makeRoot()
        let label = addLabel(to: root, frame: CGRect(x: 20, y: 120, width: 120, height: 30))
        let container = PassThroughMeasurementTestView(frame: root.bounds)
        container.addSubview(PassThroughMeasurementTestView(frame: container.bounds))
        root.addSubview(container)

        XCTAssertTrue(ViewHelper.findSubviews(in: root, intersectingPoint: CGPoint(x: 40, y: 135)).first === label)
    }

    func testVisibleDecorationInsidePassThroughContainerRemainsInspectable() {
        let root = makeRoot()
        let overlay = PassThroughMeasurementTestView(frame: root.bounds)
        let label = addLabel(to: overlay, frame: CGRect(x: 20, y: 120, width: 120, height: 30))
        root.addSubview(overlay)

        let selected = ViewHelper.findSubviews(in: root, intersectingPoint: CGPoint(x: 40, y: 135))

        XCTAssertTrue(selected.first === label)
        XCTAssertFalse(selected.contains { $0 === overlay })
    }

    func testDisabledContainerAndLabelRemainInspectable() {
        let root = makeRoot()
        let container = UIView(frame: root.bounds)
        container.isUserInteractionEnabled = false
        root.addSubview(container)
        let label = addLabel(to: container, frame: CGRect(x: 20, y: 120, width: 120, height: 30))

        XCTAssertTrue(ViewHelper.findSubviews(in: root, intersectingPoint: CGPoint(x: 40, y: 135)).first === label)
    }

    func testInteractiveOverlayRemainsInFront() {
        let root = makeRoot()
        _ = addLabel(to: root, frame: root.bounds)
        let overlay = UIView(frame: root.bounds)
        let button = UIButton(frame: CGRect(x: 20, y: 120, width: 120, height: 30))
        overlay.addSubview(button)
        root.addSubview(overlay)

        XCTAssertTrue(ViewHelper.findSubviews(in: root, intersectingPoint: CGPoint(x: 40, y: 135)).first === button)
    }

    func testHiddenAndTransparentBranchesAreExcluded() {
        let root = makeRoot()
        let label = addLabel(to: root, frame: root.bounds)
        let hidden = UIView(frame: root.bounds)
        _ = addLabel(to: hidden, frame: hidden.bounds)
        hidden.isHidden = true
        root.addSubview(hidden)
        let transparent = UIView(frame: root.bounds)
        _ = addLabel(to: transparent, frame: transparent.bounds)
        transparent.alpha = 0.005
        root.addSubview(transparent)

        XCTAssertTrue(ViewHelper.findSubviews(in: root, intersectingPoint: CGPoint(x: 40, y: 135)).first === label)
    }

    func testChildrenOutsideClippingAncestorAreExcluded() {
        let root = makeRoot()
        let label = addLabel(to: root, frame: root.bounds)
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        container.clipsToBounds = true
        _ = addLabel(to: container, frame: CGRect(x: 100, y: 100, width: 40, height: 40))
        root.addSubview(container)

        XCTAssertTrue(ViewHelper.findSubviews(in: root, intersectingPoint: CGPoint(x: 110, y: 110)).first === label)
    }

    func testVisibleOverflowOutsideNonClippingAncestorRemainsInspectable() {
        let root = makeRoot()
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        let label = addLabel(to: container, frame: CGRect(x: 100, y: 100, width: 40, height: 40))
        root.addSubview(container)

        XCTAssertTrue(ViewHelper.findSubviews(in: root, intersectingPoint: CGPoint(x: 110, y: 110)).first === label)
    }

    func testRotatedViewDoesNotSelectEmptyCornerOfBoundingFrame() {
        let root = makeRoot()
        let label = addLabel(to: root, frame: CGRect(x: 70, y: 70, width: 30, height: 30))
        let rotated = UIView(frame: CGRect(x: 100, y: 100, width: 100, height: 100))
        rotated.transform = CGAffineTransform(rotationAngle: .pi / 4)
        root.addSubview(rotated)
        let point = CGPoint(x: 82, y: 82)

        XCTAssertFalse(ViewHelper.view(rotated, surroundsPoint: point, relativeTo: root))
        XCTAssertTrue(ViewHelper.findSubviews(in: root, intersectingPoint: point).first === label)
    }

    func testScrolledBoundsStillSelectChildLabel() {
        let root = makeRoot()
        let scroll = UIScrollView(frame: CGRect(x: 20, y: 100, width: 200, height: 100))
        scroll.contentSize = CGSize(width: 200, height: 500)
        scroll.contentOffset = CGPoint(x: 0, y: 80)
        let label = addLabel(to: scroll, frame: CGRect(x: 0, y: 100, width: 100, height: 20))
        root.addSubview(scroll)

        XCTAssertTrue(ViewHelper.findSubviews(in: root, intersectingPoint: CGPoint(x: 30, y: 125)).first === label)
    }

    func testMeasurementOverlaySubtreeIsExcluded() {
        let root = makeRoot()
        let label = addLabel(to: root, frame: root.bounds)
        let overlay = MeasurementsView(delegate: nil)
        overlay.frame = root.bounds
        _ = addLabel(to: overlay, frame: overlay.bounds)
        root.addSubview(overlay)

        XCTAssertTrue(ViewHelper.findSubviews(in: root, intersectingPoint: CGPoint(x: 40, y: 135)).first === label)
    }
}

/// 与系统浮动导航容器一样，保留整屏 bounds，但空白区域不接收点击。
private final class PassThroughMeasurementTestView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { nil }
}
