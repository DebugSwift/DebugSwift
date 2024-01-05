//
//  SnapshotActionSheetUtils.swift
//  InAppViewDebugger
//
//  Created by Indragie Karunaratne on 4/9/19.
//  Copyright © 2019 Indragie Karunaratne. All rights reserved.
//

import UIKit

func makeActionSheet(snapshot: Snapshot, sourceView: UIView, sourcePoint: CGPoint, focusAction: @escaping (Snapshot) -> Void) -> UIAlertController {
    let actionSheet = UIAlertController(title: nil, message: snapshot.element.description, preferredStyle: .actionSheet)
    actionSheet.addAction(UIAlertAction(title: NSLocalizedString("Focus", comment: "Focus on the hierarchy associated with this element"), style: .default) { _ in
        focusAction(snapshot)
    })
    actionSheet.addAction(UIAlertAction(title: NSLocalizedString("Log Description", comment: "Log the description of this element"), style: .default) { _ in
        print(snapshot.element)
    })
    let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel the action"), style: .cancel, handler: nil)
    actionSheet.addAction(cancel)
    actionSheet.preferredAction = cancel
    actionSheet.popoverPresentationController?.sourceView = sourceView
    actionSheet.popoverPresentationController?.sourceRect = CGRect(origin: sourcePoint, size: .zero)
    return actionSheet
}
