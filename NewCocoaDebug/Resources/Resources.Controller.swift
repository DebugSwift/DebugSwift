//
//  Resources.Controller.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class ResourcesViewController: BaseController {

    override init() {
        super.init()
        setupTabBar()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blue
        setup()
    }

    func setup() {
    }

    func setupTabBar() {
        title = "Resources"
        if #available(iOS 13.0, *) {
            tabBarItem = UITabBarItem(
                title: title,
                image: UIImage(systemName: "doc.richtext"),
                tag: 2
            )
        } else {
            // Fallback on earlier versions
        }
    }

}
