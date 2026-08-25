//
//  SnapshotActionSheetUtils.swift
//  InAppViewDebugger
//
//  Created by Indragie Karunaratne on 4/9/19.
//  Copyright © 2019 Indragie Karunaratne. All rights reserved.
//

import UIKit

/// Presents an action sheet for the given snapshot with various options
/// to operate on the element. The action sheet is presented from the given
/// source view and source point.
///
/// - Parameters:
///   - snapshot: The snapshot to present the action sheet for.
///   - sourceView: The view to present the action sheet from.
///   - sourcePoint: The point (in the source view's coordinate system) to
/// present the action sheet from.
///   - onFocus: A closure that will be called when the user selects the
/// 'Focus' option from the action sheet.
@MainActor
func actionSheet(
    for snapshot: Snapshot,
    from sourceView: UIView,
    at sourcePoint: CGPoint,
    onFocus: @escaping () -> Void
) -> UIAlertController {
    let actionSheet = UIAlertController(
        title: snapshot.element.title,
        message: snapshot.element.shortDescription,
        preferredStyle: .actionSheet
    )

    actionSheet.addAction(UIAlertAction(title: NSLocalizedString("Focus", comment: "Focus on the hierarchy associated with this element"), style: .default) { _ in
        onFocus()
    })

    actionSheet.addAction(UIAlertAction(title: NSLocalizedString("Show More Info", comment: "Log the description of this element"), style: .default) { _ in
        Task { @MainActor in
            UIApplication.topViewController()?.navigationController?.pushViewController(
                DebuggerDetailViewController(snapshot: snapshot),
                animated: true
            )
        }
    })

    let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel the action"), style: .cancel, handler: nil)
    actionSheet.addAction(cancel)
    actionSheet.preferredAction = cancel
    actionSheet.popoverPresentationController?.sourceView = sourceView
    actionSheet.popoverPresentationController?.sourceRect = CGRect(origin: sourcePoint, size: .zero)

    return actionSheet
}
