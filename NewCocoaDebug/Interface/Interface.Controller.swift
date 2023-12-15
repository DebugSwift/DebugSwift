//
//  Interface.Controller.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class InterfaceViewController: BaseController {

    override init() {
        super.init()
        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .yellow
    }

    func setup() {
        title = "Interface"
        tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(named: "square.grid.2x2"),
            tag: 3
        )
    }
}
