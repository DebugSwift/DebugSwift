//
//  App.Controller.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class AppViewController: BaseController {

    override init() {
        super.init()
        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .purple
    }

    func setup() {
        title = "App"
        tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(named: "app"),
            tag: 4
        )
    }
}
