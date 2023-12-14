//
//  Performance.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class PerformanceViewController: BaseController {
    override init() {
        super.init()
        setup()
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green
    }

    func setup() {
        title = "Performance"
        if #available(iOS 13.0, *) {
            tabBarItem = UITabBarItem(
                title: title,
                image: UIImage(systemName: "speedometer"),
                tag: 1
            )
        } else {
            // Fallback on earlier versions
        }
    }
}
