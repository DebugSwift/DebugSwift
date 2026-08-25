//
//  DocRecorderPassthroughWindow.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/05/26.
//

import UIKit

final class DocRecorderPassthroughWindow: UIWindow {
    var touchableFrame: CGRect = .zero

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        touchableFrame.contains(point)
    }
}
