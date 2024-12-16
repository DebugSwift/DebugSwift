//
//  ViewControllerUtils.swift
//  InAppViewDebugger
//
//  Created by Indragie Karunaratne on 4/4/19.
//  Copyright © 2019 Indragie Karunaratne. All rights reserved.
//

import UIKit

func getNearestAncestorViewController(responder: UIResponder) -> UIViewController? {
    if let viewController = responder as? UIViewController {
        return viewController
    }
    if let nextResponder = responder.next {
        return getNearestAncestorViewController(responder: nextResponder)
    }
    return nil
}
