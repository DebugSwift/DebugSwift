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
        tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(named: "speedometer"),
            tag: 1
        )
    }
}
