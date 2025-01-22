//
//  MenuViewController.swift
//  HyperionSwift
//
//  Created by Matheus Gois on 02/01/25.
//

import UIKit

public protocol UIViewAnimating {
    static func animate(
        withDuration duration: TimeInterval,
        animations: @escaping () -> Void,
        completion: ((Bool) -> Void)?
    )
}

extension UIView: UIViewAnimating {}
